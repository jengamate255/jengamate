-- QUICK FIX: Add missing columns and fix RLS policies
-- Run this script in your Supabase SQL editor
-- This is a simpler version that focuses on the most critical fixes

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

-- Step 2: Add missing columns that are causing immediate errors
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true;
ALTER TABLE categories ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true;
ALTER TABLE categories ADD COLUMN IF NOT EXISTS sort_order INTEGER DEFAULT 0;
ALTER TABLE products ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true;
ALTER TABLE payments ADD COLUMN IF NOT EXISTS method payment_method DEFAULT 'mpesa';
ALTER TABLE payments ADD COLUMN IF NOT EXISTS status payment_status DEFAULT 'pending';
ALTER TABLE orders ADD COLUMN IF NOT EXISTS status order_status DEFAULT 'pending';
ALTER TABLE orders ADD COLUMN IF NOT EXISTS priority TEXT DEFAULT 'normal';

-- Step 3: Create is_admin function to fix RLS recursion
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

-- Step 4: Drop and recreate critical RLS policies
DROP POLICY IF EXISTS "Admins can view all profiles" ON profiles;
DROP POLICY IF EXISTS "Admins can view all orders" ON orders;
DROP POLICY IF EXISTS "Admins can view all payments" ON payments;

CREATE POLICY "Admins can view all profiles"
ON profiles FOR SELECT
TO authenticated
USING (is_admin(auth.uid()));

CREATE POLICY "Admins can view all orders"
ON orders FOR SELECT
TO authenticated
USING (is_admin(auth.uid()));

CREATE POLICY "Admins can view all payments"
ON payments FOR SELECT
TO authenticated
USING (is_admin(auth.uid()));

-- Step 5: Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_profiles_is_active ON profiles(is_active);
CREATE INDEX IF NOT EXISTS idx_categories_is_active ON categories(is_active);
CREATE INDEX IF NOT EXISTS idx_products_is_active ON products(is_active);
