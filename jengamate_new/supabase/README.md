# JengaMate Supabase Backend

Complete Supabase backend configuration for JengaMate B2B procurement platform.

## 📁 Project Structure

```
supabase/
├── config.toml              # Supabase project configuration
├── migrations/              # Database schema migrations
│   ├── 20241201000001_initial_schema.sql
│   └── 20241201000002_rls_policies.sql
├── functions/               # Edge Functions
│   ├── exchange-firebase-token/
│   └── order-webhook/
├── buckets/                 # Storage bucket configuration
│   └── bucket_config.json
└── README.md               # This file
```

## 🚀 Quick Setup

### Prerequisites

1. **Supabase CLI**: Install the Supabase CLI
   ```bash
   npm install supabase --save-dev
   # or
   npx supabase --version
   ```

2. **Supabase Account**: Create account at [supabase.com](https://supabase.com)

3. **Firebase Integration** (optional): Set up Firebase project for authentication

### Automated Setup

Run the setup script from your project root:

**Windows:**
```cmd
scripts\setup_supabase_backend.bat
```

**Linux/macOS:**
```bash
chmod +x scripts/setup_supabase_backend.sh
./scripts/setup_supabase_backend.sh
```

### Manual Setup

If you prefer manual setup:

1. **Login to Supabase:**
   ```bash
   supabase login
   ```

2. **Link your project:**
   ```bash
   supabase link --project-ref YOUR_PROJECT_REF
   ```

3. **Apply migrations:**
   ```bash
   supabase db push
   ```

4. **Deploy Edge Functions:**
   ```bash
   supabase functions deploy exchange-firebase-token
   supabase functions deploy order-webhook
   ```

5. **Set up storage:**
   ```bash
   supabase storage create payment_proofs --public=false
   supabase storage create product_images --public=true
   supabase storage create profile_images --public=false
   ```

## 🗄️ Database Schema

### Core Tables

#### `profiles`
Extends Supabase `auth.users` with additional business data:
- User roles (engineer, supplier, admin, super_admin)
- Company information
- Contact details
- Profile settings

#### `categories`
Product categorization system:
- Hierarchical categories (parent/child relationships)
- Category images and metadata
- Active/inactive status

#### `products`
Product catalog with comprehensive specifications:
- Supplier relationship
- Pricing and inventory
- Product specifications (JSONB)
- Media attachments
- SEO optimization fields

#### `orders` & `order_items`
Complete order management system:
- Order lifecycle tracking
- Payment integration
- Shipping information
- Order items with specifications

#### `payments` & `financial_transactions`
Financial transaction management:
- Multiple payment methods
- Transaction status tracking
- Financial reporting
- Audit trails

#### `rfq` & `quotations`
Request for Quotation system:
- RFQ lifecycle management
- Supplier quotations
- Price negotiations
- Contract management

### Supporting Tables

#### Communication
- `chat_rooms` & `chat_messages` - Real-time messaging
- `notifications` - Push notifications and alerts
- `inquiries` - Customer support tickets

#### Analytics & Reviews
- `product_reviews` - Customer feedback system
- `commission_tiers` & `user_commissions` - Revenue sharing
- `audit_log` - System audit trail
- `system_config` - Platform configuration

## 🔒 Row Level Security (RLS)

Comprehensive security policies ensure data privacy:

### User Data Isolation
- Users can only access their own data
- Suppliers can access their products and orders
- Admins have elevated access for management

### Business Logic Security
- Payment proofs secured per user
- Product images publicly accessible
- Profile images private to owners

### Administrative Controls
- Admin-only access to sensitive data
- Audit logging for all changes
- System configuration management

## 🪣 Storage Configuration

### Buckets

#### `payment_proofs` (Private)
- **Purpose**: Store payment verification documents
- **Access**: User-specific folder isolation
- **File Types**: PDF, JPG, PNG
- **Size Limit**: 10MB

#### `product_images` (Public)
- **Purpose**: Product catalog images
- **Access**: Public read access
- **File Types**: JPG, PNG, WebP
- **Size Limit**: 5MB

#### `profile_images` (Private)
- **Purpose**: User profile pictures
- **Access**: Owner-only access
- **File Types**: JPG, PNG, WebP
- **Size Limit**: 2MB

## ⚡ Edge Functions

### `exchange-firebase-token`
Firebase authentication integration:
- Exchanges Firebase ID tokens for Supabase sessions
- Automatic user creation/sync
- Cross-platform authentication support

**Usage:**
```typescript
const response = await fetch('/functions/v1/exchange-firebase-token', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ firebaseIdToken })
});
```

### `order-webhook`
Order lifecycle management:
- Automated order status updates
- Payment processing notifications
- Commission calculations
- Real-time notifications

**Webhook Events:**
- `order_created` - New order notifications
- `payment_received` - Payment confirmations
- `order_shipped` - Shipping updates
- `order_delivered` - Delivery confirmations

## 🔧 Configuration

### Environment Variables

Set these in your Supabase project dashboard:

```bash
# Firebase Integration (for exchange-firebase-token function)
FIREBASE_PROJECT_ID=your_firebase_project_id
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxxxx@your-project.iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY=-----BEGIN PRIVATE KEY-----\n...

# Supabase URLs (auto-configured)
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key

# Email Configuration (optional)
SMTP_HOST=smtp.sendgrid.net
SMTP_PORT=587
SMTP_USER=apikey
SMTP_PASS=your_sendgrid_api_key
```

### Authentication Setup

1. **Enable Authentication:**
   ```bash
   supabase auth update --enable-signup=true --minimum-password-length=6
   ```

2. **Configure Providers** (optional):
   - Google OAuth
   - GitHub OAuth
   - Custom providers

3. **Email Templates:**
   - Customize signup confirmation emails
   - Password reset templates
   - Welcome emails

## 📊 Real-time Features

### Enabled Tables
Real-time subscriptions are enabled for:
- `orders` - Order status updates
- `payments` - Payment confirmations
- `chat_messages` - Real-time messaging
- `notifications` - Push notifications
- `product_reviews` - Review updates

### Usage Example
```typescript
// Subscribe to order updates
const subscription = supabase
  .channel('order_updates')
  .on('postgres_changes',
    { event: '*', schema: 'public', table: 'orders' },
    (payload) => {
      console.log('Order updated:', payload);
    }
  )
  .subscribe();
```

## 🔍 Monitoring & Debugging

### Database Monitoring
```bash
# Check migration status
supabase db diff

# View database logs
supabase db logs

# Reset database (development)
supabase db reset
```

### Function Monitoring
```bash
# View function logs
supabase functions logs exchange-firebase-token
supabase functions logs order-webhook

# Deploy function updates
supabase functions deploy exchange-firebase-token
```

### Storage Monitoring
```bash
# List buckets
supabase storage ls

# Check bucket contents
supabase storage ls payment_proofs
```

## 🚀 Deployment

### Production Deployment

1. **Create Production Project:**
   ```bash
   supabase projects create "JengaMate Production"
   ```

2. **Deploy Schema:**
   ```bash
   supabase db push --project-ref YOUR_PROD_PROJECT_REF
   ```

3. **Deploy Functions:**
   ```bash
   supabase functions deploy --project-ref YOUR_PROD_PROJECT_REF
   ```

4. **Configure Environment:**
   - Set production environment variables
   - Configure production auth settings
   - Set up production storage buckets

### Backup & Recovery

```bash
# Create database backup
supabase db dump > backup.sql

# Restore from backup
supabase db restore < backup.sql
```

## 🧪 Testing

### Local Development
```bash
# Start local Supabase stack
supabase start

# Run database tests
supabase test db

# Test functions locally
supabase functions serve
```

### Integration Testing
```bash
# Test authentication flow
curl -X POST http://localhost:54321/functions/v1/exchange-firebase-token \
  -H "Content-Type: application/json" \
  -d '{"firebaseIdToken":"your_token"}'
```

## 📚 API Reference

### REST API Endpoints
All tables are automatically exposed via REST API at:
```
https://your-project.supabase.co/rest/v1/
```

### GraphQL (Optional)
Enable GraphQL for advanced queries:
```bash
supabase db push --enable-graphql
```

### Realtime API
Subscribe to real-time changes:
```javascript
const channel = supabase.channel('table_changes')
  .on('postgres_changes', {
    event: '*',
    schema: 'public',
    table: 'orders'
  }, callback)
  .subscribe()
```

## 🆘 Troubleshooting

### Common Issues

1. **Migration Errors:**
   ```bash
   # Check migration status
   supabase migration list

   # Reset and reapply
   supabase db reset
   supabase db push
   ```

2. **Function Deployment Issues:**
   ```bash
   # Check function logs
   supabase functions logs FUNCTION_NAME --follow

   # Redeploy function
   supabase functions deploy FUNCTION_NAME
   ```

3. **RLS Policy Issues:**
   ```sql
   -- Check active policies
   SELECT * FROM pg_policies WHERE schemaname = 'public';
   ```

4. **Storage Permission Issues:**
   ```bash
   # Check bucket policies
   supabase storage ls BUCKET_NAME --recursive
   ```

## 📞 Support

- **Supabase Documentation**: [supabase.com/docs](https://supabase.com/docs)
- **Community Forum**: [supabase.com/community](https://supabase.com/community)
- **GitHub Issues**: [github.com/supabase/supabase](https://github.com/supabase/supabase)

## 🔄 Updates

To update your Supabase backend:

1. Pull latest changes
2. Apply new migrations: `supabase db push`
3. Deploy updated functions: `supabase functions deploy`
4. Update storage configuration if needed

---

**🎉 Your JengaMate backend is now fully configured with Supabase!**

The setup includes enterprise-grade security, real-time features, comprehensive APIs, and automated workflows. Your B2B procurement platform is ready for production deployment.
