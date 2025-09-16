-- JengaMate Initial Database Schema
-- This migration creates the core tables for the JengaMate B2B procurement platform

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Create custom types
CREATE TYPE user_role AS ENUM ('engineer', 'supplier', 'admin', 'super_admin');
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

CREATE TYPE payment_method AS ENUM ('mpesa', 'creditCard', 'bankTransfer', 'paypal', 'cash', 'cheque', 'mobileMoney');
CREATE TYPE payment_status AS ENUM (
  'pending', 'processing', 'verified', 'rejected', 'cancelled',
  'refunded', 'partiallyRefunded', 'awaitingVerification',
  'verificationFailed', 'timeout', 'expired', 'disputed',
  'chargeback', 'pendingApproval', 'approved', 'denied',
  'onHold', 'underReview', 'completed', 'failed', 'retry',
  'scheduled', 'inProgress', 'paused', 'stopped', 'authorized',
  'captured', 'voided', 'settled', 'unsettled', 'unknown'
);

CREATE TYPE transaction_type AS ENUM (
  'product', 'service', 'standard', 'urgent', 'bulk', 'quotation',
  'rfq', 'custom', 'subscription', 'rental', 'lease', 'warranty',
  'support', 'consultation', 'training', 'installation', 'repair',
  'maintenance', 'delivery', 'pickup', 'returned', 'exchange',
  'refund', 'credit', 'debit', 'invoice', 'receipt', 'statement',
  'report', 'document', 'file', 'image', 'video', 'audio', 'text',
  'chat', 'message', 'notification', 'alert', 'event', 'task',
  'project', 'milestone', 'phase', 'stage', 'step', 'item',
  'lineItem', 'bundle', 'package', 'kit', 'assembly', 'component',
  'part', 'material', 'labor', 'expense', 'discount', 'tax',
  'shipping', 'handling', 'fee', 'charge', 'adjustment', 'deposit',
  'withdrawal', 'transfer', 'payment', 'refundPayment', 'commission',
  'bonus', 'penalty', 'fine', 'interest', 'rebate', 'coupon',
  'voucher', 'giftCard', 'loyaltyPoint', 'reward', 'referral',
  'affiliate', 'advertisement', 'campaign', 'promotion', 'offer',
  'deal', 'sale', 'purchase', 'order', 'quote', 'inquiry', 'request',
  'response', 'feedback', 'review', 'rating', 'comment', 'post',
  'article', 'blog', 'page', 'site', 'website', 'application',
  'software', 'hardware', 'device', 'system', 'network', 'server',
  'database', 'cloud', 'api', 'integration', 'plugin', 'module',
  'library', 'framework', 'platform', 'tool', 'utility', 'script',
  'code', 'data', 'information', 'content', 'media', 'asset',
  'resource', 'documentType', 'reportType', 'transactionType',
  'paymentType', 'messageType', 'notificationType', 'alertType',
  'eventType', 'taskType', 'projectType', 'milestoneType', 'phaseType',
  'stageType', 'stepType', 'itemType', 'lineItemType', 'bundleType',
  'packageType', 'kitType', 'assemblyType', 'componentType', 'partType',
  'materialType', 'laborType', 'expenseType', 'discountType', 'taxType',
  'shippingType', 'handlingType', 'feeType', 'chargeType',
  'adjustmentType', 'depositType', 'withdrawalType', 'transferType',
  'paymentRefundType', 'commissionType', 'bonusType', 'penaltyType',
  'fineType', 'interestType', 'rebateType', 'couponType', 'voucherType',
  'giftCardType', 'loyaltyPointType', 'rewardType', 'referralType',
  'affiliateType', 'advertisementType', 'campaignType', 'promotionType',
  'offerType', 'dealType', 'saleType', 'purchaseType', 'orderType',
  'quoteType', 'inquiryType', 'requestType', 'responseType',
  'feedbackType', 'reviewType', 'ratingType', 'commentType', 'postType',
  'articleType', 'blogType', 'pageType', 'siteType', 'websiteType',
  'applicationType', 'softwareType', 'hardwareType', 'deviceType',
  'systemType', 'networkType', 'serverType', 'databaseType', 'cloudType',
  'apiType', 'integrationType', 'pluginType', 'moduleType', 'libraryType',
  'frameworkType', 'platformType', 'toolType', 'utilityType', 'scriptType',
  'codeType', 'dataType', 'informationType', 'contentType', 'mediaType',
  'assetType', 'resourceType', 'unknown'
);

-- Create profiles table (extends Supabase auth.users)
CREATE TABLE profiles (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  firebase_uid TEXT UNIQUE,
  email TEXT,
  phone TEXT,
  first_name TEXT,
  last_name TEXT,
  company_name TEXT,
  company_address TEXT,
  company_phone TEXT,
  role user_role DEFAULT 'engineer',
  is_active BOOLEAN DEFAULT true,
  avatar_url TEXT,
  bio TEXT,
  location TEXT,
  website TEXT,
  linkedin_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create categories table
CREATE TABLE categories (
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

-- Create products table
CREATE TABLE products (
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

-- Create orders table
CREATE TABLE orders (
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

-- Create order_items table
CREATE TABLE order_items (
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

-- Create payments table
CREATE TABLE payments (
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

-- Create financial_transactions table
CREATE TABLE financial_transactions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  type transaction_type NOT NULL,
  amount DECIMAL(12,2) NOT NULL,
  currency TEXT DEFAULT 'TZS',
  description TEXT,
  reference_id TEXT,
  order_id UUID REFERENCES orders(id) ON DELETE SET NULL,
  status TEXT DEFAULT 'completed',
  processed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create rfq (Request for Quotation) table
CREATE TABLE rfq (
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

-- Create quotations table
CREATE TABLE quotations (
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

-- Create inquiry table
CREATE TABLE inquiries (
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

-- Create commission_tiers table
CREATE TABLE commission_tiers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  level INTEGER UNIQUE NOT NULL,
  min_sales DECIMAL(12,2) DEFAULT 0,
  max_sales DECIMAL(12,2),
  commission_rate DECIMAL(5,4) NOT NULL, -- e.g., 0.05 for 5%
  bonus_amount DECIMAL(10,2) DEFAULT 0,
  requirements TEXT[] DEFAULT '{}',
  benefits TEXT[] DEFAULT '{}',
  color TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create user_commissions table
CREATE TABLE user_commissions (
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

-- Create product_reviews table
CREATE TABLE product_reviews (
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

-- Create chat_rooms table
CREATE TABLE chat_rooms (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT,
  type TEXT DEFAULT 'direct', -- 'direct', 'group', 'support'
  created_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  is_active BOOLEAN DEFAULT true,
  last_message_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create chat_room_participants table
CREATE TABLE chat_room_participants (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  room_id UUID REFERENCES chat_rooms(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  role TEXT DEFAULT 'member', -- 'admin', 'member'
  joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(room_id, user_id)
);

-- Create chat_messages table
CREATE TABLE chat_messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  room_id UUID REFERENCES chat_rooms(id) ON DELETE CASCADE NOT NULL,
  sender_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  content TEXT NOT NULL,
  message_type TEXT DEFAULT 'text', -- 'text', 'image', 'file'
  metadata JSONB DEFAULT '{}',
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create audit_log table
CREATE TABLE audit_log (
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

-- Create system_config table
CREATE TABLE system_config (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  key TEXT UNIQUE NOT NULL,
  value JSONB,
  description TEXT,
  is_public BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX idx_profiles_firebase_uid ON profiles(firebase_uid);
CREATE INDEX idx_profiles_email ON profiles(email);
CREATE INDEX idx_profiles_role ON profiles(role);
CREATE INDEX idx_profiles_is_active ON profiles(is_active);

CREATE INDEX idx_products_supplier_id ON products(supplier_id);
CREATE INDEX idx_products_category_id ON products(category_id);
CREATE INDEX idx_products_is_active ON products(is_active);
CREATE INDEX idx_products_price ON products(price);
CREATE INDEX idx_products_created_at ON products(created_at);

CREATE INDEX idx_orders_customer_id ON orders(customer_id);
CREATE INDEX idx_orders_supplier_id ON orders(supplier_id);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_payment_status ON orders(payment_status);
CREATE INDEX idx_orders_created_at ON orders(created_at);

CREATE INDEX idx_order_items_order_id ON order_items(order_id);
CREATE INDEX idx_order_items_product_id ON order_items(product_id);

CREATE INDEX idx_payments_order_id ON payments(order_id);
CREATE INDEX idx_payments_user_id ON payments(user_id);
CREATE INDEX idx_payments_status ON payments(status);
CREATE INDEX idx_payments_transaction_id ON payments(transaction_id);

CREATE INDEX idx_financial_transactions_user_id ON financial_transactions(user_id);
CREATE INDEX idx_financial_transactions_type ON financial_transactions(type);
CREATE INDEX idx_financial_transactions_created_at ON financial_transactions(created_at);

CREATE INDEX idx_rfq_requester_id ON rfq(requester_id);
CREATE INDEX idx_rfq_status ON rfq(status);
CREATE INDEX idx_rfq_deadline ON rfq(deadline);

CREATE INDEX idx_quotations_rfq_id ON quotations(rfq_id);
CREATE INDEX idx_quotations_supplier_id ON quotations(supplier_id);
CREATE INDEX idx_quotations_status ON quotations(status);

CREATE INDEX idx_inquiries_user_id ON inquiries(user_id);
CREATE INDEX idx_inquiries_status ON inquiries(status);
CREATE INDEX idx_inquiries_assigned_to ON inquiries(assigned_to);

CREATE INDEX idx_user_commissions_user_id ON user_commissions(user_id);
CREATE INDEX idx_user_commissions_tier_id ON user_commissions(tier_id);
CREATE INDEX idx_user_commissions_status ON user_commissions(status);

CREATE INDEX idx_product_reviews_product_id ON product_reviews(product_id);
CREATE INDEX idx_product_reviews_user_id ON product_reviews(user_id);
CREATE INDEX idx_product_reviews_rating ON product_reviews(rating);

CREATE INDEX idx_chat_rooms_type ON chat_rooms(type);
CREATE INDEX idx_chat_rooms_is_active ON chat_rooms(is_active);
CREATE INDEX idx_chat_rooms_last_message_at ON chat_rooms(last_message_at);

CREATE INDEX idx_chat_messages_room_id ON chat_messages(room_id);
CREATE INDEX idx_chat_messages_sender_id ON chat_messages(sender_id);
CREATE INDEX idx_chat_messages_created_at ON chat_messages(created_at);

CREATE INDEX idx_audit_log_user_id ON audit_log(user_id);
CREATE INDEX idx_audit_log_action ON audit_log(action);
CREATE INDEX idx_audit_log_resource_type ON audit_log(resource_type);
CREATE INDEX idx_audit_log_created_at ON audit_log(created_at);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Add updated_at triggers to relevant tables
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_categories_updated_at BEFORE UPDATE ON categories FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_products_updated_at BEFORE UPDATE ON products FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_orders_updated_at BEFORE UPDATE ON orders FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_order_items_updated_at BEFORE UPDATE ON order_items FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_payments_updated_at BEFORE UPDATE ON payments FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_financial_transactions_updated_at BEFORE UPDATE ON financial_transactions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_rfq_updated_at BEFORE UPDATE ON rfq FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_quotations_updated_at BEFORE UPDATE ON quotations FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_inquiries_updated_at BEFORE UPDATE ON inquiries FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_commission_tiers_updated_at BEFORE UPDATE ON commission_tiers FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_user_commissions_updated_at BEFORE UPDATE ON user_commissions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_product_reviews_updated_at BEFORE UPDATE ON product_reviews FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_chat_rooms_updated_at BEFORE UPDATE ON chat_rooms FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_chat_messages_updated_at BEFORE UPDATE ON chat_messages FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_system_config_updated_at BEFORE UPDATE ON system_config FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Insert default commission tiers
INSERT INTO commission_tiers (name, level, min_sales, max_sales, commission_rate, bonus_amount, requirements, benefits, color) VALUES
('Bronze', 1, 0, 1000000, 0.02, 0, '{"Complete profile", "Make first purchase"}', '{"Basic support", "Monthly newsletter"}', '#CD7F32'),
('Silver', 2, 1000000, 5000000, 0.03, 5000, '{"Verified supplier", "5+ successful orders"}', '{"Priority support", "Quarterly reports"}', '#C0C0C0'),
('Gold', 3, 5000000, 15000000, 0.05, 15000, '{"Premium member", "10+ successful orders", "Positive reviews"}', '{"Dedicated account manager", "Custom reports", "Early access"}', '#FFD700'),
('Platinum', 4, 15000000, 50000000, 0.07, 50000, '{"Elite member", "25+ successful orders", "Consistent high ratings"}', '{"VIP support", "Strategic consulting", "Beta features"}', '#E5E4E2'),
('Diamond', 5, 50000000, NULL, 0.10, 150000, '{"Top tier member", "50+ successful orders", "Industry leader"}', '{"Executive support", "Custom solutions", "Exclusive partnerships"}', '#B9F2FF');

-- Insert default system configuration
INSERT INTO system_config (key, value, description, is_public) VALUES
('platform_name', '"JengaMate"', 'Platform display name', true),
('platform_version', '"1.0.0"', 'Current platform version', true),
('support_email', '"support@jengamate.com"', 'Support contact email', true),
('currency_default', '"TZS"', 'Default currency code', true),
('commission_enabled', 'true', 'Whether commission system is enabled', false),
('maintenance_mode', 'false', 'Whether platform is in maintenance mode', true),
('max_file_size_mb', '10', 'Maximum file upload size in MB', true),
('session_timeout_hours', '24', 'User session timeout in hours', false),
('enable_notifications', 'true', 'Whether push notifications are enabled', false),
('require_email_verification', 'false', 'Whether email verification is required', false);
