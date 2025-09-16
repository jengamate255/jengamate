-- JengaMate Row Level Security Policies
-- This migration sets up comprehensive RLS policies for data security

-- Enable RLS on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE financial_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE rfq ENABLE ROW LEVEL SECURITY;
ALTER TABLE quotations ENABLE ROW LEVEL SECURITY;
ALTER TABLE inquiries ENABLE ROW LEVEL SECURITY;
ALTER TABLE commission_tiers ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_commissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE product_reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_room_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE system_config ENABLE ROW LEVEL SECURITY;

-- ===========================================
-- PROFILES POLICIES
-- ===========================================

-- Users can view their own profile
CREATE POLICY "Users can view own profile"
ON profiles FOR SELECT
TO authenticated
USING (auth.uid() = id);

-- Users can update their own profile
CREATE POLICY "Users can update own profile"
ON profiles FOR UPDATE
TO authenticated
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- Users can insert their own profile
CREATE POLICY "Users can insert own profile"
ON profiles FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = id);

-- Create a function to check admin status without circular reference
CREATE OR REPLACE FUNCTION is_admin(user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM profiles
    WHERE id = user_id
  AND is_admin(id)
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Admins can view all profiles (using function to avoid circular reference)
CREATE POLICY "Admins can view all profiles"
ON profiles FOR SELECT
TO authenticated
USING (
  is_admin(auth.uid())
);

-- Admins can update any profile (using function to avoid circular reference)
CREATE POLICY "Admins can update any profile"
ON profiles FOR UPDATE
TO authenticated
USING (
  is_admin(auth.uid())
);

-- ===========================================
-- CATEGORIES POLICIES
-- ===========================================

-- Everyone can view active categories
CREATE POLICY "Anyone can view active categories"
ON categories FOR SELECT
TO authenticated
USING (is_active = true);

-- Admins can manage categories
CREATE POLICY "Admins can manage categories"
ON categories FOR ALL
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE id = auth.uid()
  AND is_admin(id)
  )
);

-- ===========================================
-- PRODUCTS POLICIES
-- ===========================================

-- Everyone can view active products
CREATE POLICY "Anyone can view active products"
ON products FOR SELECT
TO authenticated
USING (is_active = true);

-- Suppliers can manage their own products
CREATE POLICY "Suppliers can manage own products"
ON products FOR ALL
TO authenticated
USING (supplier_id = auth.uid())
WITH CHECK (supplier_id = auth.uid());

-- Admins can manage all products
CREATE POLICY "Admins can manage all products"
ON products FOR ALL
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE id = auth.uid()
  AND is_admin(id)
  )
);

-- ===========================================
-- ORDERS POLICIES
-- ===========================================

-- Customers can view their own orders
CREATE POLICY "Customers can view own orders"
ON orders FOR SELECT
TO authenticated
USING (customer_id = auth.uid());

-- Suppliers can view orders for their products
CREATE POLICY "Suppliers can view their orders"
ON orders FOR SELECT
TO authenticated
USING (supplier_id = auth.uid());

-- Customers can create orders
CREATE POLICY "Customers can create orders"
ON orders FOR INSERT
TO authenticated
WITH CHECK (customer_id = auth.uid());

-- Customers and suppliers can update their orders (limited fields)
CREATE POLICY "Users can update order status"
ON orders FOR UPDATE
TO authenticated
USING (
  customer_id = auth.uid() OR supplier_id = auth.uid()
)
WITH CHECK (
  customer_id = auth.uid() OR supplier_id = auth.uid()
);

-- Admins can manage all orders
CREATE POLICY "Admins can manage all orders"
ON orders FOR ALL
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE id = auth.uid()
  AND is_admin(id)
  )
);

-- ===========================================
-- ORDER ITEMS POLICIES
-- ===========================================

-- Users can view items from their orders
CREATE POLICY "Users can view their order items"
ON order_items FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM orders
    WHERE orders.id = order_items.order_id
    AND (orders.customer_id = auth.uid() OR orders.supplier_id = auth.uid())
  )
);

-- Users can create order items for their orders
CREATE POLICY "Users can create order items"
ON order_items FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM orders
    WHERE orders.id = order_items.order_id
    AND orders.customer_id = auth.uid()
  )
);

-- Admins can manage all order items
CREATE POLICY "Admins can manage order items"
ON order_items FOR ALL
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE id = auth.uid()
  AND is_admin(id)
  )
);

-- ===========================================
-- PAYMENTS POLICIES
-- ===========================================

-- Users can view their own payments
CREATE POLICY "Users can view own payments"
ON payments FOR SELECT
TO authenticated
USING (user_id = auth.uid());

-- Users can create their own payments
CREATE POLICY "Users can create own payments"
ON payments FOR INSERT
TO authenticated
WITH CHECK (user_id = auth.uid());

-- Users can update their own payments (limited)
CREATE POLICY "Users can update own payments"
ON payments FOR UPDATE
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Admins can view all payments
CREATE POLICY "Admins can view all payments"
ON payments FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE id = auth.uid()
  AND is_admin(id)
  )
);

-- ===========================================
-- FINANCIAL TRANSACTIONS POLICIES
-- ===========================================

-- Users can view their own transactions
CREATE POLICY "Users can view own transactions"
ON financial_transactions FOR SELECT
TO authenticated
USING (user_id = auth.uid());

-- System can create transactions (via service role)
CREATE POLICY "System can create transactions"
ON financial_transactions FOR INSERT
TO service_role
WITH CHECK (true);

-- Admins can view all transactions
CREATE POLICY "Admins can view all transactions"
ON financial_transactions FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE id = auth.uid()
  AND is_admin(id)
  )
);

-- ===========================================
-- RFQ POLICIES
-- ===========================================

-- Users can view public RFQs
CREATE POLICY "Users can view RFQs"
ON rfq FOR SELECT
TO authenticated
USING (status = 'open' OR requester_id = auth.uid());

-- Users can create RFQs
CREATE POLICY "Users can create RFQs"
ON rfq FOR INSERT
TO authenticated
WITH CHECK (requester_id = auth.uid());

-- Users can update their own RFQs
CREATE POLICY "Users can update own RFQs"
ON rfq FOR UPDATE
TO authenticated
USING (requester_id = auth.uid())
WITH CHECK (requester_id = auth.uid());

-- Admins can manage all RFQs
CREATE POLICY "Admins can manage RFQs"
ON rfq FOR ALL
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE id = auth.uid()
  AND is_admin(id)
  )
);

-- ===========================================
-- QUOTATIONS POLICIES
-- ===========================================

-- Users can view quotations for RFQs they created or submitted
CREATE POLICY "Users can view relevant quotations"
ON quotations FOR SELECT
TO authenticated
USING (
  supplier_id = auth.uid() OR
  EXISTS (
    SELECT 1 FROM rfq
    WHERE rfq.id = quotations.rfq_id
    AND rfq.requester_id = auth.uid()
  )
);

-- Suppliers can create quotations for RFQs
CREATE POLICY "Suppliers can create quotations"
ON quotations FOR INSERT
TO authenticated
WITH CHECK (supplier_id = auth.uid());

-- Suppliers can update their own quotations
CREATE POLICY "Suppliers can update own quotations"
ON quotations FOR UPDATE
TO authenticated
USING (supplier_id = auth.uid())
WITH CHECK (supplier_id = auth.uid());

-- Admins can manage all quotations
CREATE POLICY "Admins can manage quotations"
ON quotations FOR ALL
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE id = auth.uid()
  AND is_admin(id)
  )
);

-- ===========================================
-- INQUIRIES POLICIES
-- ===========================================

-- Users can view their own inquiries
CREATE POLICY "Users can view own inquiries"
ON inquiries FOR SELECT
TO authenticated
USING (user_id = auth.uid());

-- Users can create inquiries
CREATE POLICY "Users can create inquiries"
ON inquiries FOR INSERT
TO authenticated
WITH CHECK (user_id = auth.uid());

-- Users can update their own inquiries (limited)
CREATE POLICY "Users can update own inquiries"
ON inquiries FOR UPDATE
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Admins can manage all inquiries
CREATE POLICY "Admins can manage all inquiries"
ON inquiries FOR ALL
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE id = auth.uid()
  AND is_admin(id)
  )
);

-- ===========================================
-- COMMISSION POLICIES
-- ===========================================

-- Everyone can view commission tiers
CREATE POLICY "Anyone can view commission tiers"
ON commission_tiers FOR SELECT
TO authenticated
USING (is_active = true);

-- Users can view their own commissions
CREATE POLICY "Users can view own commissions"
ON user_commissions FOR SELECT
TO authenticated
USING (user_id = auth.uid());

-- Admins can manage commission tiers
CREATE POLICY "Admins can manage commission tiers"
ON commission_tiers FOR ALL
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE id = auth.uid()
  AND is_admin(id)
  )
);

-- Admins can manage user commissions
CREATE POLICY "Admins can manage user commissions"
ON user_commissions FOR ALL
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE id = auth.uid()
  AND is_admin(id)
  )
);

-- ===========================================
-- REVIEWS POLICIES
-- ===========================================

-- Everyone can view product reviews
CREATE POLICY "Anyone can view product reviews"
ON product_reviews FOR SELECT
TO authenticated
USING (true);

-- Users can create reviews for products they've purchased
CREATE POLICY "Users can create reviews"
ON product_reviews FOR INSERT
TO authenticated
WITH CHECK (
  user_id = auth.uid() AND
  EXISTS (
    SELECT 1 FROM orders o
    JOIN order_items oi ON o.id = oi.order_id
    WHERE o.customer_id = auth.uid()
    AND oi.product_id = product_reviews.product_id
    AND o.status IN ('delivered', 'completed')
  )
);

-- Users can update their own reviews
CREATE POLICY "Users can update own reviews"
ON product_reviews FOR UPDATE
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Admins can manage all reviews
CREATE POLICY "Admins can manage reviews"
ON product_reviews FOR ALL
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE id = auth.uid()
  AND is_admin(id)
  )
);

-- ===========================================
-- CHAT POLICIES
-- ===========================================

-- Users can view chat rooms they're participants in
CREATE POLICY "Users can view their chat rooms"
ON chat_rooms FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM chat_room_participants
    WHERE room_id = chat_rooms.id
    AND user_id = auth.uid()
  ) OR created_by = auth.uid()
);

-- Users can create chat rooms
CREATE POLICY "Users can create chat rooms"
ON chat_rooms FOR INSERT
TO authenticated
WITH CHECK (created_by = auth.uid());

-- Users can update chat rooms they created
CREATE POLICY "Users can update own chat rooms"
ON chat_rooms FOR UPDATE
TO authenticated
USING (created_by = auth.uid())
WITH CHECK (created_by = auth.uid());

-- Chat room participants policies
CREATE POLICY "Users can view chat participants"
ON chat_room_participants FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM chat_room_participants crp
    WHERE crp.room_id = chat_room_participants.room_id
    AND crp.user_id = auth.uid()
  )
);

CREATE POLICY "Users can join chat rooms"
ON chat_room_participants FOR INSERT
TO authenticated
WITH CHECK (user_id = auth.uid());

-- Chat messages policies
CREATE POLICY "Users can view messages in their rooms"
ON chat_messages FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM chat_room_participants
    WHERE room_id = chat_messages.room_id
    AND user_id = auth.uid()
  )
);

CREATE POLICY "Users can send messages to their rooms"
ON chat_messages FOR INSERT
TO authenticated
WITH CHECK (
  sender_id = auth.uid() AND
  EXISTS (
    SELECT 1 FROM chat_room_participants
    WHERE room_id = chat_messages.room_id
    AND user_id = auth.uid()
  )
);

-- ===========================================
-- AUDIT LOG POLICIES
-- ===========================================

-- Only admins can view audit logs
CREATE POLICY "Admins can view audit logs"
ON audit_log FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE id = auth.uid()
  AND is_admin(id)
  )
);

-- System can create audit logs
CREATE POLICY "System can create audit logs"
ON audit_log FOR INSERT
TO authenticated
WITH CHECK (true);

-- ===========================================
-- SYSTEM CONFIG POLICIES
-- ===========================================

-- Everyone can view public config
CREATE POLICY "Anyone can view public config"
ON system_config FOR SELECT
TO authenticated
USING (is_public = true);

-- Only admins can manage system config
CREATE POLICY "Admins can manage system config"
ON system_config FOR ALL
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE id = auth.uid()
  AND is_admin(id)
  )
);

-- ===========================================
-- STORAGE POLICIES (for file uploads)
-- ===========================================

-- Enable RLS on storage objects
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Users can upload files to their own folders
CREATE POLICY "Users can upload to own folders"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id IN ('payment_proofs', 'product_images', 'profile_images') AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- Users can view their own files
CREATE POLICY "Users can view own files"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id IN ('payment_proofs', 'product_images', 'profile_images') AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- Users can update their own files
CREATE POLICY "Users can update own files"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id IN ('payment_proofs', 'product_images', 'profile_images') AND
  (storage.foldername(name))[1] = auth.uid()::text
)
WITH CHECK (
  bucket_id IN ('payment_proofs', 'product_images', 'profile_images') AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- Users can delete their own files
CREATE POLICY "Users can delete own files"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id IN ('payment_proofs', 'product_images', 'profile_images') AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- Public read access for product images
CREATE POLICY "Public can view product images"
ON storage.objects FOR SELECT
TO anon
USING (bucket_id = 'product_images');

-- Admins can manage all files
CREATE POLICY "Admins can manage all files"
ON storage.objects FOR ALL
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE id = auth.uid()
  AND is_admin(id)
  )
);
