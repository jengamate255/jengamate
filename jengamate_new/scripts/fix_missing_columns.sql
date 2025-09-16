-- Fix missing columns and database issues
-- Run this script in your Supabase SQL editor

-- Step 1: Create missing enum types (safely)
DO $$
BEGIN
    -- Create payment_method enum if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'payment_method') THEN
        CREATE TYPE payment_method AS ENUM (
            'mpesa', 'creditCard', 'bankTransfer', 'paypal', 'cash', 'cheque', 'mobileMoney'
        );
    END IF;

    -- Create order_status enum if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'order_status') THEN
        CREATE TYPE order_status AS ENUM (
            'pending', 'processing', 'completed', 'cancelled', 'onHold',
            'shipped', 'delivered', 'returned', 'refunded', 'partiallyRefunded',
            'awaitingPayment', 'paymentFailed', 'disputed', 'draft', 'quoted',
            'accepted', 'rejected', 'invoiced', 'paid', 'partiallyPaid',
            'overdue', 'archived', 'active', 'inactive', 'underReview',
            'approved', 'denied', 'onDelivery', 'readyForPickup',
            'pickupCompleted', 'rescheduled', 'onRoute', 'atLocation',
            'loading', 'unloading', 'inspection', 'maintenance', 'breakdown',
            'repaired', 'dispatched', 'assigned', 'unassigned', 'onSite',
            'offSite', 'onHoldCustomer', 'onHoldSupplier', 'onHoldInternal',
            'escalated', 'resolved', 'closed', 'reopened', 'verified',
            'unverified', 'pendingApproval', 'approvedByCustomer',
            'rejectedByCustomer', 'approvedBySupplier', 'rejectedBySupplier',
            'pendingConfirmation', 'confirmed', 'awaitingConfirmation',
            'confirmationRejected', 'scheduled', 'inProgress', 'paused',
            'stopped', 'failed', 'success', 'warning', 'info', 'debug',
            'trace', 'critical', 'alert', 'emergency', 'notice', 'verbose',
            'silent', 'unknown', 'pendingPayment', 'fullyPaid'
        );
    END IF;

    -- Create payment_status enum if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'payment_status') THEN
        CREATE TYPE payment_status AS ENUM (
            'pending', 'processing', 'verified', 'rejected', 'cancelled',
            'refunded', 'partiallyRefunded', 'awaitingVerification',
            'verificationFailed', 'timeout', 'expired', 'disputed',
            'chargeback', 'pendingApproval', 'approved', 'denied',
            'onHold', 'underReview', 'completed', 'failed', 'retry',
            'scheduled', 'inProgress', 'paused', 'stopped', 'authorized',
            'captured', 'voided', 'settled', 'unsettled', 'unknown'
        );
    END IF;
END $$;

-- Step 2: Add missing columns to existing tables
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS avatar_url TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS bio TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS location TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS website TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS linkedin_url TEXT;

-- Add missing columns to other tables if needed
ALTER TABLE categories ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true;
ALTER TABLE categories ADD COLUMN IF NOT EXISTS sort_order INTEGER DEFAULT 0;

ALTER TABLE products ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true;
ALTER TABLE products ADD COLUMN IF NOT EXISTS is_featured BOOLEAN DEFAULT false;
ALTER TABLE products ADD COLUMN IF NOT EXISTS tags TEXT[] DEFAULT '{}';
ALTER TABLE products ADD COLUMN IF NOT EXISTS seo_title TEXT;
ALTER TABLE products ADD COLUMN IF NOT EXISTS seo_description TEXT;
ALTER TABLE products ADD COLUMN IF NOT EXISTS weight DECIMAL(8,3);
ALTER TABLE products ADD COLUMN IF NOT EXISTS dimensions JSONB;
ALTER TABLE products ADD COLUMN IF NOT EXISTS warranty_period TEXT;
ALTER TABLE products ADD COLUMN IF NOT EXISTS lead_time_days INTEGER;

-- Add missing columns to payments table
ALTER TABLE payments ADD COLUMN IF NOT EXISTS method payment_method DEFAULT 'mpesa';
ALTER TABLE payments ADD COLUMN IF NOT EXISTS status payment_status DEFAULT 'pending';
ALTER TABLE payments ADD COLUMN IF NOT EXISTS transaction_id TEXT;
ALTER TABLE payments ADD COLUMN IF NOT EXISTS proof_url TEXT;
ALTER TABLE payments ADD COLUMN IF NOT EXISTS notes TEXT;
ALTER TABLE payments ADD COLUMN IF NOT EXISTS processed_by UUID REFERENCES profiles(id);

-- Add missing columns to orders table
ALTER TABLE orders ADD COLUMN IF NOT EXISTS status order_status DEFAULT 'pending';
ALTER TABLE orders ADD COLUMN IF NOT EXISTS priority TEXT DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent'));
ALTER TABLE orders ADD COLUMN IF NOT EXISTS tracking_number TEXT;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS estimated_delivery TIMESTAMP WITH TIME ZONE;

-- Step 3: Fix any missing order status values by updating existing records (only if status column exists)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'status') THEN
        EXECUTE 'UPDATE orders SET status = ''pending'' WHERE status NOT IN (
            ''pending'', ''processing'', ''completed'', ''cancelled'', ''onHold'',
            ''shipped'', ''delivered'', ''returned'', ''refunded'', ''partiallyRefunded'',
            ''awaitingPayment'', ''paymentFailed'', ''disputed'', ''draft'', ''quoted'',
            ''accepted'', ''rejected'', ''invoiced'', ''paid'', ''partiallyPaid'',
            ''overdue'', ''archived'', ''active'', ''inactive'', ''underReview'',
            ''approved'', ''denied'', ''onDelivery'', ''readyForPickup'',
            ''pickupCompleted'', ''rescheduled'', ''onRoute'', ''atLocation'',
            ''loading'', ''unloading'', ''inspection'', ''maintenance'', ''breakdown'',
            ''repaired'', ''dispatched'', ''assigned'', ''unassigned'', ''onSite'',
            ''offSite'', ''onHoldCustomer'', ''onHoldSupplier'', ''onHoldInternal'',
            ''escalated'', ''resolved'', ''closed'', ''reopened'', ''verified'',
            ''unverified'', ''pendingApproval'', ''approvedByCustomer'',
            ''rejectedByCustomer'', ''approvedBySupplier'', ''rejectedBySupplier'',
            ''pendingConfirmation'', ''confirmed'', ''awaitingConfirmation'',
            ''confirmationRejected'', ''scheduled'', ''inProgress'', ''paused'',
            ''stopped'', ''failed'', ''success'', ''warning'', ''info'', ''debug'',
            ''trace'', ''critical'', ''alert'', ''emergency'', ''notice'', ''verbose'',
            ''silent'', ''unknown'', ''pendingPayment'', ''fullyPaid''
        )';
    END IF;
END $$;

-- Step 4: Fix any missing payment status values (only if status column exists)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'payments' AND column_name = 'status') THEN
        EXECUTE 'UPDATE payments SET status = ''pending'' WHERE status NOT IN (
            ''pending'', ''processing'', ''verified'', ''rejected'', ''cancelled'',
            ''refunded'', ''partiallyRefunded'', ''awaitingVerification'',
            ''verificationFailed'', ''timeout'', ''expired'', ''disputed'',
            ''chargeback'', ''pendingApproval'', ''approved'', ''denied'',
            ''onHold'', ''underReview'', ''completed'', ''failed'', ''retry'',
            ''scheduled'', ''inProgress'', ''paused'', ''stopped'', ''authorized'',
            ''captured'', ''voided'', ''settled'', ''unsettled'', ''unknown''
        )';
    END IF;
END $$;

-- Step 5: Fix any missing payment method values (only if method column exists)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'payments' AND column_name = 'method') THEN
        EXECUTE 'UPDATE payments SET method = ''mpesa'' WHERE method NOT IN (
            ''mpesa'', ''creditCard'', ''bankTransfer'', ''paypal'', ''cash'', ''cheque'', ''mobileMoney''
        )';
    END IF;
END $$;

-- Step 6: Ensure all required indexes exist
CREATE INDEX IF NOT EXISTS idx_profiles_is_active ON profiles(is_active);
CREATE INDEX IF NOT EXISTS idx_categories_is_active ON categories(is_active);
CREATE INDEX IF NOT EXISTS idx_products_is_active ON products(is_active);
CREATE INDEX IF NOT EXISTS idx_products_is_featured ON products(is_featured);

-- Step 7: Ensure the is_admin function exists
CREATE OR REPLACE FUNCTION is_admin(user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM profiles
    WHERE id = user_id
    AND role IN ('admin', 'super_admin')
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 8: Drop and recreate problematic RLS policies
DROP POLICY IF EXISTS "Admins can view all profiles" ON profiles;
DROP POLICY IF EXISTS "Admins can update any profile" ON profiles;
DROP POLICY IF EXISTS "Admins can view all orders" ON orders;
DROP POLICY IF EXISTS "Admins can update orders" ON orders;
DROP POLICY IF EXISTS "Admins can view all payments" ON payments;
DROP POLICY IF EXISTS "Admins can view all products" ON products;
DROP POLICY IF EXISTS "Admins can manage products" ON products;
DROP POLICY IF EXISTS "Admins can view all inquiries" ON inquiries;
DROP POLICY IF EXISTS "Admins can view all rfq" ON rfq;
DROP POLICY IF EXISTS "Admins can view all quotations" ON quotations;
DROP POLICY IF EXISTS "Admins can view all categories" ON categories;
DROP POLICY IF EXISTS "Admins can manage categories" ON categories;
DROP POLICY IF EXISTS "Admins can view all chat_rooms" ON chat_rooms;
DROP POLICY IF EXISTS "Admins can view all chat_messages" ON chat_messages;
DROP POLICY IF EXISTS "Admins can view all audit_log" ON audit_log;

-- Step 9: Recreate admin policies using the function
CREATE POLICY "Admins can view all profiles"
ON profiles FOR SELECT
TO authenticated
USING (is_admin(auth.uid()));

CREATE POLICY "Admins can update any profile"
ON profiles FOR UPDATE
TO authenticated
USING (is_admin(auth.uid()));

CREATE POLICY "Admins can view all orders"
ON orders FOR SELECT
TO authenticated
USING (is_admin(auth.uid()));

CREATE POLICY "Admins can update orders"
ON orders FOR UPDATE
TO authenticated
USING (is_admin(auth.uid()));

CREATE POLICY "Admins can view all payments"
ON payments FOR SELECT
TO authenticated
USING (is_admin(auth.uid()));

CREATE POLICY "Admins can view all products"
ON products FOR SELECT
TO authenticated
USING (is_admin(auth.uid()));

CREATE POLICY "Admins can manage products"
ON products FOR ALL
TO authenticated
USING (is_admin(auth.uid()));

CREATE POLICY "Admins can view all inquiries"
ON inquiries FOR SELECT
TO authenticated
USING (is_admin(auth.uid()));

CREATE POLICY "Admins can view all rfq"
ON rfq FOR SELECT
TO authenticated
USING (is_admin(auth.uid()));

CREATE POLICY "Admins can view all quotations"
ON quotations FOR SELECT
TO authenticated
USING (is_admin(auth.uid()));

CREATE POLICY "Admins can view all categories"
ON categories FOR SELECT
TO authenticated
USING (is_admin(auth.uid()));

CREATE POLICY "Admins can manage categories"
ON categories FOR ALL
TO authenticated
USING (is_admin(auth.uid()));

CREATE POLICY "Admins can view all chat_rooms"
ON chat_rooms FOR SELECT
TO authenticated
USING (is_admin(auth.uid()));

CREATE POLICY "Admins can view all chat_messages"
ON chat_messages FOR SELECT
TO authenticated
USING (is_admin(auth.uid()));

CREATE POLICY "Admins can view all audit_log"
ON audit_log FOR SELECT
TO authenticated
USING (is_admin(auth.uid()));
