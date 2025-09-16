-- ROBUST PAYMENT SYSTEM MIGRATION - MANUAL APPLICATION
-- Copy and paste this entire file into Supabase SQL Editor

-- Create payment_logs table for comprehensive error reporting and monitoring
CREATE TABLE IF NOT EXISTS payment_logs (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    payment_id TEXT,
    event TEXT NOT NULL,
    level TEXT NOT NULL DEFAULT 'INFO' CHECK (level IN ('DEBUG', 'INFO', 'WARN', 'ERROR')),
    error_message TEXT,
    metadata JSONB DEFAULT '{}',
    timestamp TIMESTAMPTZ DEFAULT NOW(),
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_payment_logs_payment_id ON payment_logs(payment_id);
CREATE INDEX IF NOT EXISTS idx_payment_logs_event ON payment_logs(event);
CREATE INDEX IF NOT EXISTS idx_payment_logs_level ON payment_logs(level);
CREATE INDEX IF NOT EXISTS idx_payment_logs_timestamp ON payment_logs(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_payment_logs_user_id ON payment_logs(user_id);

-- Update payments table structure to match new requirements
ALTER TABLE payments ADD COLUMN IF NOT EXISTS order_id TEXT;
ALTER TABLE payments ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id);
ALTER TABLE payments ADD COLUMN IF NOT EXISTS payment_method TEXT DEFAULT 'bank_transfer';
ALTER TABLE payments ADD COLUMN IF NOT EXISTS transaction_id TEXT;
ALTER TABLE payments ADD COLUMN IF NOT EXISTS payment_proof_url TEXT;
ALTER TABLE payments ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'failed', 'cancelled'));
ALTER TABLE payments ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE payments ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE payments ADD COLUMN IF NOT EXISTS metadata JSONB DEFAULT '{}';
ALTER TABLE payments ADD COLUMN IF NOT EXISTS auto_approved BOOLEAN DEFAULT FALSE;

-- Create indexes for payments table
CREATE INDEX IF NOT EXISTS idx_payments_order_id ON payments(order_id);
CREATE INDEX IF NOT EXISTS idx_payments_user_id ON payments(user_id);
CREATE INDEX IF NOT EXISTS idx_payments_status ON payments(status);
CREATE INDEX IF NOT EXISTS idx_payments_created_at ON payments(created_at DESC);

-- Update orders table to support payment tracking
ALTER TABLE orders ADD COLUMN IF NOT EXISTS amount_paid DECIMAL(15,2) DEFAULT 0.00;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- Create indexes for orders table
CREATE INDEX IF NOT EXISTS idx_orders_amount_paid ON orders(amount_paid);
CREATE INDEX IF NOT EXISTS idx_orders_updated_at ON orders(updated_at DESC);

-- Row Level Security (RLS) Policies

-- Enable RLS on all tables
ALTER TABLE payment_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;

-- Payment Logs Policies
-- Users can only see their own payment logs
CREATE POLICY "Users can view their own payment logs" ON payment_logs
    FOR SELECT USING (auth.uid() = user_id);

-- Admins can see all payment logs
CREATE POLICY "Admins can view all payment logs" ON payment_logs
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role IN ('admin', 'super_admin')
        )
    );

-- Users can insert their own payment logs
CREATE POLICY "Users can insert their own payment logs" ON payment_logs
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- System can insert payment logs (for automated logging)
CREATE POLICY "System can insert payment logs" ON payment_logs
    FOR INSERT WITH CHECK (true);

-- Payments Policies
-- Users can view their own payments
CREATE POLICY "Users can view their own payments" ON payments
    FOR SELECT USING (auth.uid() = user_id);

-- Users can create their own payments
CREATE POLICY "Users can create their own payments" ON payments
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can update their own payments (limited to certain fields)
CREATE POLICY "Users can update their own payments" ON payments
    FOR UPDATE USING (auth.uid() = user_id)
    WITH CHECK (
        auth.uid() = user_id
        AND status = 'pending'  -- Only pending payments can be updated
    );

-- Admins can view all payments
CREATE POLICY "Admins can view all payments" ON payments
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role IN ('admin', 'super_admin')
        )
    );

-- Admins can update any payment
CREATE POLICY "Admins can update any payment" ON payments
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role IN ('admin', 'super_admin')
        )
    );

-- Storage bucket setup for payment proofs
-- Create the payment_proofs bucket if it doesn't exist
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'payment_proofs',
    'payment_proofs',
    false,  -- Private bucket
    10485760,  -- 10MB limit
    ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/webp', 'application/pdf']
) ON CONFLICT (id) DO NOTHING;

-- Storage policies for payment_proofs bucket
-- Users can upload to their own folder
CREATE POLICY "Users can upload payment proofs to their folder" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'payment_proofs'
        AND auth.role() = 'authenticated'
        AND (storage.foldername(name))[1] = auth.uid()::text
    );

-- Users can view their own payment proofs
CREATE POLICY "Users can view their own payment proofs" ON storage.objects
    FOR SELECT USING (
        bucket_id = 'payment_proofs'
        AND auth.role() = 'authenticated'
        AND (storage.foldername(name))[1] = auth.uid()::text
    );

-- Admins can view all payment proofs
CREATE POLICY "Admins can view all payment proofs" ON storage.objects
    FOR SELECT USING (
        bucket_id = 'payment_proofs'
        AND EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role IN ('admin', 'super_admin')
        )
    );

-- Users can delete their own payment proofs
CREATE POLICY "Users can delete their own payment proofs" ON storage.objects
    FOR DELETE USING (
        bucket_id = 'payment_proofs'
        AND auth.role() = 'authenticated'
        AND (storage.foldername(name))[1] = auth.uid()::text
    );

-- Create function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updated_at
DROP TRIGGER IF EXISTS update_payments_updated_at ON payments;
CREATE TRIGGER update_payments_updated_at
    BEFORE UPDATE ON payments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_orders_updated_at ON orders;
CREATE TRIGGER update_orders_updated_at
    BEFORE UPDATE ON orders
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Create function to log payment events automatically
CREATE OR REPLACE FUNCTION log_payment_event()
RETURNS TRIGGER AS $$
DECLARE
    event_type TEXT;
    log_level TEXT := 'INFO';
BEGIN
    -- Determine event type
    IF TG_OP = 'INSERT' THEN
        event_type := 'PAYMENT_CREATED';
    ELSIF TG_OP = 'UPDATE' THEN
        IF OLD.status != NEW.status THEN
            event_type := 'PAYMENT_STATUS_CHANGED';
        ELSE
            event_type := 'PAYMENT_UPDATED';
        END IF;
    ELSIF TG_OP = 'DELETE' THEN
        event_type := 'PAYMENT_DELETED';
        log_level := 'WARN';
    END IF;

    -- Insert log entry
    INSERT INTO payment_logs (payment_id, event, level, metadata, user_id)
    VALUES (
        COALESCE(NEW.id, OLD.id),
        event_type,
        log_level,
        jsonb_build_object(
            'operation', TG_OP,
            'old_status', OLD.status,
            'new_status', NEW.status,
            'amount', COALESCE(NEW.amount, OLD.amount),
            'timestamp', NOW()
        ),
        COALESCE(NEW.user_id, OLD.user_id)
    );

    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Create trigger for payment logging
DROP TRIGGER IF EXISTS payment_logging_trigger ON payments;
CREATE TRIGGER payment_logging_trigger
    AFTER INSERT OR UPDATE OR DELETE ON payments
    FOR EACH ROW EXECUTE FUNCTION log_payment_event();

-- Create function to validate payment data
CREATE OR REPLACE FUNCTION validate_payment_data()
RETURNS TRIGGER AS $$
BEGIN
    -- Validate amount is positive
    IF NEW.amount <= 0 THEN
        RAISE EXCEPTION 'Payment amount must be greater than 0';
    END IF;

    -- Validate amount doesn't exceed reasonable limits
    IF NEW.amount > 10000000 THEN
        RAISE EXCEPTION 'Payment amount cannot exceed 10,000,000';
    END IF;

    -- Validate transaction_id is not empty for completed payments
    IF NEW.status = 'completed' AND (NEW.transaction_id IS NULL OR NEW.transaction_id = '') THEN
        RAISE EXCEPTION 'Transaction ID is required for completed payments';
    END IF;

    -- Validate payment_proof_url exists for completed payments
    IF NEW.status = 'completed' AND (NEW.payment_proof_url IS NULL OR NEW.payment_proof_url = '') THEN
        RAISE EXCEPTION 'Payment proof URL is required for completed payments';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for payment validation
DROP TRIGGER IF EXISTS payment_validation_trigger ON payments;
CREATE TRIGGER payment_validation_trigger
    BEFORE INSERT OR UPDATE ON payments
    FOR EACH ROW EXECUTE FUNCTION validate_payment_data();

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_payments_order_user ON payments(order_id, user_id);
CREATE INDEX IF NOT EXISTS idx_payments_status_created ON payments(status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_payment_logs_composite ON payment_logs(payment_id, timestamp DESC, level);

-- Grant necessary permissions
GRANT ALL ON payment_logs TO authenticated;
GRANT ALL ON payments TO authenticated;
GRANT USAGE ON SCHEMA public TO authenticated;

-- Create view for payment analytics (admin only)
CREATE OR REPLACE VIEW payment_analytics AS
SELECT
    DATE_TRUNC('day', created_at) as date,
    COUNT(*) as total_payments,
    COUNT(*) FILTER (WHERE status = 'completed') as completed_payments,
    COUNT(*) FILTER (WHERE status = 'failed') as failed_payments,
    SUM(amount) FILTER (WHERE status = 'completed') as total_amount,
    AVG(amount) FILTER (WHERE status = 'completed') as avg_amount,
    COUNT(DISTINCT user_id) as unique_users
FROM payments
WHERE created_at >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY DATE_TRUNC('day', created_at)
ORDER BY date DESC;

-- Grant access to analytics view for admins only
GRANT SELECT ON payment_analytics TO authenticated;

-- Comments for documentation
COMMENT ON TABLE payment_logs IS 'Comprehensive logging table for payment events and errors';
COMMENT ON TABLE payments IS 'Main payments table with enhanced structure for robust processing';
COMMENT ON COLUMN payments.metadata IS 'Additional payment data stored as JSON';
COMMENT ON COLUMN payments.auto_approved IS 'Whether payment was automatically approved';
COMMENT ON VIEW payment_analytics IS 'Daily payment analytics view for admin dashboard';















