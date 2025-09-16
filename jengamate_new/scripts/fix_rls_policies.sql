-- Fix for infinite recursion in Supabase RLS policies
-- Run this script in your Supabase SQL editor to fix the circular reference issue

-- Drop existing problematic policies
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

-- Create a function to check admin status without circular reference
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

-- Recreate admin policies using the function
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







