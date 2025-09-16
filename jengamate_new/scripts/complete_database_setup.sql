-- COMPLETE DATABASE SETUP SCRIPT
-- This script will create missing tables, indexes, triggers, and data safely
-- Run this in your Supabase SQL editor

-- ===========================================
-- STEP 1: CREATE MISSING TABLES
-- ===========================================

-- Check and create categories table
CREATE TABLE IF NOT EXISTS categories (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  description TEXT,
  parent_id UUID REFERENCES categories(id) ON DELETE CASCADE,
  image_url TEXT,
  is_active BOOLEAN DEFAULT true,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Check and create products table
CREATE TABLE IF NOT EXISTS products (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  supplier_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
  name TEXT NOT NULL,
  description TEXT,
  specifications JSONB DEFAULT '{}',
  price DECIMAL(10,2) NOT NULL,
  currency TEXT DEFAULT 'TZS',
  stock_quantity INTEGER DEFAULT 0,
  min_order_quantity INTEGER DEFAULT 1,
  max_order_quantity INTEGER,
  images TEXT[] DEFAULT '{}',
  is_active BOOLEAN DEFAULT true,
  is_featured BOOLEAN DEFAULT false,
  tags TEXT[] DEFAULT '{}',
  seo_title TEXT,
  seo_description TEXT,
  weight DECIMAL(8,3),
  dimensions JSONB,
  warranty_period TEXT,
  lead_time_days INTEGER,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Check and create orders table
CREATE TABLE IF NOT EXISTS orders (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  order_number TEXT UNIQUE NOT NULL,
  customer_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  supplier_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  status order_status DEFAULT 'pending',
  total_amount DECIMAL(12,2) NOT NULL,
  currency TEXT DEFAULT 'TZS',
  shipping_address JSONB,
  billing_address JSONB,
  notes TEXT,
  payment_method payment_method,
  payment_status payment_status DEFAULT 'pending',
  tracking_number TEXT,
  estimated_delivery_date DATE,
  actual_delivery_date DATE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Check and create order_items table
CREATE TABLE IF NOT EXISTS order_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  order_id UUID REFERENCES orders(id) ON DELETE CASCADE NOT NULL,
  product_id UUID REFERENCES products(id) ON DELETE CASCADE NOT NULL,
  quantity INTEGER NOT NULL,
  unit_price DECIMAL(10,2) NOT NULL,
  total_price DECIMAL(10,2) NOT NULL,
  specifications JSONB DEFAULT '{}',
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Check and create payments table
CREATE TABLE IF NOT EXISTS payments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  order_id UUID REFERENCES orders(id) ON DELETE SET NULL,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  amount DECIMAL(12,2) NOT NULL,
  currency TEXT DEFAULT 'TZS',
  method payment_method NOT NULL,
  status payment_status DEFAULT 'pending',
  transaction_id TEXT UNIQUE,
  reference_number TEXT,
  payment_proof_url TEXT,
  notes TEXT,
  processed_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Check and create rfq table
CREATE TABLE IF NOT EXISTS rfq (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  requester_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
  specifications JSONB DEFAULT '{}',
  quantity INTEGER,
  budget_min DECIMAL(12,2),
  budget_max DECIMAL(12,2),
  currency TEXT DEFAULT 'TZS',
  deadline DATE,
  status TEXT DEFAULT 'open',
  attachments TEXT[] DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Check and create quotations table
CREATE TABLE IF NOT EXISTS quotations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  rfq_id UUID REFERENCES rfq(id) ON DELETE CASCADE NOT NULL,
  supplier_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  price DECIMAL(12,2) NOT NULL,
  currency TEXT DEFAULT 'TZS',
  notes TEXT,
  delivery_days INTEGER,
  validity_days INTEGER DEFAULT 30,
  status TEXT DEFAULT 'pending',
  attachments TEXT[] DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Check and create inquiries table
CREATE TABLE IF NOT EXISTS inquiries (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  category TEXT,
  priority TEXT DEFAULT 'medium',
  status TEXT DEFAULT 'open',
  assigned_to UUID REFERENCES profiles(id) ON DELETE SET NULL,
  resolved_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Check and create commission_tiers table
CREATE TABLE IF NOT EXISTS commission_tiers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  level INTEGER UNIQUE NOT NULL,
  min_sales DECIMAL(12,2) DEFAULT 0,
  max_sales DECIMAL(12,2),
  commission_rate DECIMAL(5,4) NOT NULL,
  bonus_amount DECIMAL(10,2) DEFAULT 0,
  requirements TEXT[] DEFAULT '{}',
  benefits TEXT[] DEFAULT '{}',
  color TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Check and create user_commissions table
CREATE TABLE IF NOT EXISTS user_commissions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  tier_id UUID REFERENCES commission_tiers(id) ON DELETE SET NULL,
  order_id UUID REFERENCES orders(id) ON DELETE SET NULL,
  amount DECIMAL(10,2) NOT NULL,
  status TEXT DEFAULT 'pending',
  paid_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Check and create product_reviews table
CREATE TABLE IF NOT EXISTS product_reviews (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  product_id UUID REFERENCES products(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  rating INTEGER CHECK (rating >= 1 AND rating <= 5),
  title TEXT,
  comment TEXT,
  is_verified_purchase BOOLEAN DEFAULT false,
  helpful_votes INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(product_id, user_id)
);

-- Check and create chat_rooms table
CREATE TABLE IF NOT EXISTS chat_rooms (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT,
  type TEXT DEFAULT 'direct',
  created_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  is_active BOOLEAN DEFAULT true,
  last_message_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Check and create chat_room_participants table
CREATE TABLE IF NOT EXISTS chat_room_participants (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  room_id UUID REFERENCES chat_rooms(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  role TEXT DEFAULT 'member',
  joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(room_id, user_id)
);

-- Check and create chat_messages table
CREATE TABLE IF NOT EXISTS chat_messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  room_id UUID REFERENCES chat_rooms(id) ON DELETE CASCADE NOT NULL,
  sender_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  content TEXT NOT NULL,
  message_type TEXT DEFAULT 'text',
  metadata JSONB DEFAULT '{}',
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Check and create audit_log table
CREATE TABLE IF NOT EXISTS audit_log (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  action TEXT NOT NULL,
  resource_type TEXT NOT NULL,
  resource_id TEXT,
  old_values JSONB,
  new_values JSONB,
  ip_address INET,
  user_agent TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Check and create system_config table
CREATE TABLE IF NOT EXISTS system_config (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  key TEXT UNIQUE NOT NULL,
  value JSONB,
  description TEXT,
  is_public BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ===========================================
-- STEP 2: CREATE INDEXES (IF NOT EXISTS)
-- ===========================================

-- Products indexes
CREATE INDEX IF NOT EXISTS idx_products_supplier_id ON products(supplier_id);
CREATE INDEX IF NOT EXISTS idx_products_category_id ON products(category_id);
CREATE INDEX IF NOT EXISTS idx_products_is_active ON products(is_active);
CREATE INDEX IF NOT EXISTS idx_products_price ON products(price);
CREATE INDEX IF NOT EXISTS idx_products_created_at ON products(created_at);

-- Orders indexes
CREATE INDEX IF NOT EXISTS idx_orders_customer_id ON orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_orders_supplier_id ON orders(supplier_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_payment_status ON orders(payment_status);
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON orders(created_at);

-- Order items indexes
CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_order_items_product_id ON order_items(product_id);

-- Payments indexes
CREATE INDEX IF NOT EXISTS idx_payments_order_id ON payments(order_id);
CREATE INDEX IF NOT EXISTS idx_payments_user_id ON payments(user_id);
CREATE INDEX IF NOT EXISTS idx_payments_status ON payments(status);
CREATE INDEX IF NOT EXISTS idx_payments_transaction_id ON payments(transaction_id);

-- RFQ indexes
CREATE INDEX IF NOT EXISTS idx_rfq_requester_id ON rfq(requester_id);
CREATE INDEX IF NOT EXISTS idx_rfq_status ON rfq(status);
CREATE INDEX IF NOT EXISTS idx_rfq_deadline ON rfq(deadline);

-- Quotations indexes
CREATE INDEX IF NOT EXISTS idx_quotations_rfq_id ON quotations(rfq_id);
CREATE INDEX IF NOT EXISTS idx_quotations_supplier_id ON quotations(supplier_id);
CREATE INDEX IF NOT EXISTS idx_quotations_status ON quotations(status);

-- Inquiries indexes
CREATE INDEX IF NOT EXISTS idx_inquiries_user_id ON inquiries(user_id);
CREATE INDEX IF NOT EXISTS idx_inquiries_status ON inquiries(status);
CREATE INDEX IF NOT EXISTS idx_inquiries_assigned_to ON inquiries(assigned_to);

-- Commissions indexes
CREATE INDEX IF NOT EXISTS idx_user_commissions_user_id ON user_commissions(user_id);
CREATE INDEX IF NOT EXISTS idx_user_commissions_tier_id ON user_commissions(tier_id);
CREATE INDEX IF NOT EXISTS idx_user_commissions_status ON user_commissions(status);

-- Reviews indexes
CREATE INDEX IF NOT EXISTS idx_product_reviews_product_id ON product_reviews(product_id);
CREATE INDEX IF NOT EXISTS idx_product_reviews_user_id ON product_reviews(user_id);
CREATE INDEX IF NOT EXISTS idx_product_reviews_rating ON product_reviews(rating);

-- Chat indexes
CREATE INDEX IF NOT EXISTS idx_chat_rooms_type ON chat_rooms(type);
CREATE INDEX IF NOT EXISTS idx_chat_rooms_is_active ON chat_rooms(is_active);
CREATE INDEX IF NOT EXISTS idx_chat_rooms_last_message_at ON chat_rooms(last_message_at);
CREATE INDEX IF NOT EXISTS idx_chat_messages_room_id ON chat_messages(room_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_sender_id ON chat_messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_created_at ON chat_messages(created_at);

-- Audit log indexes
CREATE INDEX IF NOT EXISTS idx_audit_log_user_id ON audit_log(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_log_action ON audit_log(action);
CREATE INDEX IF NOT EXISTS idx_audit_log_resource_type ON audit_log(resource_type);
CREATE INDEX IF NOT EXISTS idx_audit_log_created_at ON audit_log(created_at);

-- ===========================================
-- STEP 3: CREATE TRIGGERS
-- ===========================================

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Add updated_at triggers to relevant tables (skip if trigger already exists)
DO $$
DECLARE
    table_name TEXT;
BEGIN
    FOREACH table_name IN ARRAY ARRAY[
        'categories', 'products', 'orders', 'order_items', 'payments',
        'rfq', 'quotations', 'inquiries', 'commission_tiers',
        'user_commissions', 'product_reviews', 'chat_rooms',
        'chat_messages', 'system_config'
    ]
    LOOP
        EXECUTE format('DROP TRIGGER IF EXISTS update_%I_updated_at ON %I', table_name, table_name);
        EXECUTE format('CREATE TRIGGER update_%I_updated_at BEFORE UPDATE ON %I FOR EACH ROW EXECUTE FUNCTION update_updated_at_column()', table_name, table_name);
    END LOOP;
END $$;

-- ===========================================
-- STEP 4: INSERT DEFAULT DATA (IF NOT EXISTS)
-- ===========================================

-- Insert commission tiers (only if not already exist)
INSERT INTO commission_tiers (name, level, min_sales, max_sales, commission_rate, bonus_amount, requirements, benefits, color)
SELECT * FROM (VALUES
    ('Bronze', 1, 0, 1000000, 0.02, 0, '{"Complete profile", "Make first purchase"}', '{"Basic support", "Monthly newsletter"}', '#CD7F32'),
    ('Silver', 2, 1000000, 5000000, 0.03, 5000, '{"Verified supplier", "5+ successful orders"}', '{"Priority support", "Quarterly reports"}', '#C0C0C0'),
    ('Gold', 3, 5000000, 15000000, 0.05, 15000, '{"Premium member", "10+ successful orders", "Positive reviews"}', '{"Dedicated account manager", "Custom reports", "Early access"}', '#FFD700'),
    ('Platinum', 4, 15000000, 50000000, 0.07, 50000, '{"Elite member", "25+ successful orders", "Consistent high ratings"}', '{"VIP support", "Strategic consulting", "Beta features"}', '#E5E4E2'),
    ('Diamond', 5, 50000000, NULL, 0.10, 150000, '{"Top tier member", "50+ successful orders", "Industry leader"}', '{"Executive support", "Custom solutions", "Exclusive partnerships"}', '#B9F2FF')
) AS v(name, level, min_sales, max_sales, commission_rate, bonus_amount, requirements, benefits, color)
WHERE NOT EXISTS (
    SELECT 1 FROM commission_tiers WHERE level = v.level
);

-- Insert system configuration (only if not already exist)
INSERT INTO system_config (key, value, description, is_public)
SELECT * FROM (VALUES
    ('platform_name', '"JengaMate"', 'Platform display name', true),
    ('platform_version', '"1.0.0"', 'Current platform version', true),
    ('support_email', '"support@jengamate.com"', 'Support contact email', true),
    ('currency_default', '"TZS"', 'Default currency code', true),
    ('commission_enabled', 'true', 'Whether commission system is enabled', false),
    ('maintenance_mode', 'false', 'Whether platform is in maintenance mode', true),
    ('max_file_size_mb', '10', 'Maximum file upload size in MB', true),
    ('session_timeout_hours', '24', 'User session timeout in hours', false),
    ('enable_notifications', 'true', 'Whether push notifications are enabled', false),
    ('require_email_verification', 'false', 'Whether email verification is required', false)
) AS v(key, value, description, is_public)
WHERE NOT EXISTS (
    SELECT 1 FROM system_config WHERE key = v.key
);

-- ===========================================
-- STEP 5: FIX RLS POLICIES (AFTER TABLES EXIST)
-- ===========================================

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
