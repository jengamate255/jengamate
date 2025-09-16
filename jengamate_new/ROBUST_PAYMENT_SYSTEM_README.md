# Robust Payment System

## Overview

This document describes the new robust payment system that addresses the previous issues with payment proof upload failures and provides advanced error reporting, transaction safety, and comprehensive validation.

## Key Features

### 🔒 Transaction Safety
- **Atomic Operations**: Payment records are only created after successful proof upload
- **Rollback Mechanism**: Failed operations are automatically cleaned up
- **Data Integrity**: All payment operations maintain database consistency

### 📊 Advanced Error Reporting
- **Comprehensive Logging**: Every payment event is logged with full context
- **Error Classification**: Errors are categorized by severity and type
- **Performance Monitoring**: Payment processing times and success rates are tracked
- **Real-time Alerts**: Critical errors trigger immediate notifications

### 🔄 Robust Retry Mechanisms
- **Exponential Backoff**: Automatic retry with increasing delays
- **Configurable Attempts**: Customizable retry counts per operation
- **Smart Failure Detection**: Distinguishes between retryable and permanent failures

### ✅ Comprehensive Validation
- **Multi-layer Validation**: Input, business rules, and security validation
- **Risk Assessment**: Automatic risk level calculation
- **Duplicate Detection**: Prevents duplicate payments
- **File Validation**: Comprehensive payment proof validation

### 🗂️ Secure File Storage
- **Supabase Integration**: Uses Supabase Storage for secure file handling
- **User-specific Folders**: Organized file structure by user and order
- **File Type Validation**: Supports images and PDFs with size limits
- **Automatic Compression**: Optimizes images for storage and bandwidth

## Architecture

### Core Components

#### 1. PaymentService (`lib/services/payment_service.dart`)
- Main payment processing service
- Handles payment creation with proof upload
- Provides comprehensive error handling
- Manages payment analytics

#### 2. PaymentProofStorageService (`lib/services/supabase_storage_service.dart`)
- Specialized storage service for payment proofs
- Handles file validation, compression, and upload
- Provides retry mechanisms and error recovery
- Manages secure file organization

#### 3. ErrorReportingService (`lib/services/error_reporting_service.dart`)
- Comprehensive error logging and monitoring
- Performance metrics collection
- Error statistics and analytics
- Device and app information collection

#### 4. PaymentValidationService (`lib/services/payment_validation_service.dart`)
- Multi-layer payment validation
- Business rule enforcement
- Risk assessment and duplicate detection
- Payment integrity verification

#### 5. PaymentScreen (`lib/screens/order/payment_screen.dart`)
- Updated UI with robust error handling
- Real-time processing feedback
- Comprehensive validation feedback
- Retry and recovery options

## Database Schema

### Required Tables

#### payments
```sql
CREATE TABLE payments (
    id TEXT PRIMARY KEY,
    order_id TEXT NOT NULL,
    user_id UUID REFERENCES auth.users(id),
    amount DECIMAL(15,2) NOT NULL,
    payment_method TEXT NOT NULL,
    transaction_id TEXT,
    payment_proof_url TEXT,
    status TEXT NOT NULL DEFAULT 'pending',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    metadata JSONB DEFAULT '{}',
    auto_approved BOOLEAN DEFAULT FALSE
);
```

#### payment_logs
```sql
CREATE TABLE payment_logs (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    payment_id TEXT,
    event TEXT NOT NULL,
    level TEXT NOT NULL DEFAULT 'INFO',
    error_message TEXT,
    metadata JSONB DEFAULT '{}',
    timestamp TIMESTAMPTZ DEFAULT NOW(),
    user_id UUID REFERENCES auth.users(id)
);
```

#### error_logs
```sql
CREATE TABLE error_logs (
    id TEXT PRIMARY KEY,
    error_message TEXT NOT NULL,
    context TEXT NOT NULL,
    severity TEXT NOT NULL,
    category TEXT NOT NULL,
    user_id UUID,
    stack_trace TEXT,
    device_info JSONB,
    app_info JSONB,
    additional_data JSONB,
    timestamp TIMESTAMPTZ DEFAULT NOW()
);
```

#### performance_logs
```sql
CREATE TABLE performance_logs (
    operation TEXT NOT NULL,
    duration_ms INTEGER NOT NULL,
    category TEXT NOT NULL,
    user_id UUID,
    metadata JSONB,
    device_info JSONB,
    app_info JSONB,
    timestamp TIMESTAMPTZ DEFAULT NOW()
);
```

## Setup Instructions

### 1. Database Migration

Run the migration script to create required tables and policies:

```bash
# Execute the migration SQL file
psql -f scripts/robust_payment_system_migration.sql
```

Or run the SQL content in your Supabase SQL editor.

### 2. Supabase Storage Setup

#### Create Payment Proofs Bucket

1. Go to Supabase Dashboard → Storage
2. Create a new bucket named `payment_proofs`
3. Configure bucket settings:
   - **Public**: `false` (private bucket)
   - **File size limit**: `10MB`
   - **Allowed MIME types**: `image/jpeg`, `image/jpg`, `image/png`, `image/webp`, `application/pdf`

#### Storage Policies

Create the following storage policies for the `payment_proofs` bucket:

```sql
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
```

### 3. Environment Configuration

Ensure your Supabase configuration includes:

```dart
// lib/config/supabase_config.dart
const String paymentProofsBucket = 'payment_proofs';
const int maxFileSizeBytes = 10 * 1024 * 1024; // 10MB
const List<String> allowedMimeTypes = [
  'image/jpeg',
  'image/jpg',
  'image/png',
  'image/webp',
  'application/pdf',
];
```

### 4. Dependencies

Add the following dependencies to your `pubspec.yaml`:

```yaml
dependencies:
  supabase_flutter: ^1.10.0
  image_picker: ^1.0.0
  image: ^4.0.0
  device_info_plus: ^9.0.0
  package_info_plus: ^4.0.0
  crypto: ^3.0.0
  mime: ^1.0.0
```

## Usage Examples

### Basic Payment Creation

```dart
final paymentService = PaymentService();
final proofStorage = PaymentProofStorageService(
  supabaseClient: Supabase.instance.client,
);

final result = await paymentService.createPaymentWithProof(
  orderId: 'order_123',
  userId: 'user_456',
  amount: 50000.0,
  paymentMethod: PaymentMethod.bankTransfer,
  transactionId: 'TXN123456789',
  proofBytes: imageBytes, // For web
  proofFile: imageFile,   // For mobile
  proofFileName: 'receipt.jpg',
  maxRetries: 3,
);

if (result.success) {
  print('Payment created: ${result.paymentId}');
  print('Proof uploaded: ${result.proofUrl}');
} else {
  print('Payment failed: ${result.message}');
  // Handle error with specific user messaging
}
```

### Error Reporting Integration

```dart
final errorReporter = ErrorReportingService();

// Initialize (call once at app startup)
await errorReporter.initialize();

// Report payment errors
await errorReporter.reportPaymentError(
  paymentId: 'payment_123',
  error: 'Upload failed',
  errorType: PaymentErrorType.proofUploadFailed,
  userId: 'user_456',
  orderId: 'order_123',
  stackTrace: StackTrace.current,
);

// Get error statistics
final stats = await errorReporter.getErrorStatistics(
  startDate: DateTime.now().subtract(Duration(days: 7)),
  category: ErrorCategory.payment,
);
```

### Payment Validation

```dart
final validator = PaymentValidationService();

final validation = await validator.validatePayment(
  orderId: 'order_123',
  userId: 'user_456',
  amount: 50000.0,
  paymentMethod: PaymentMethod.bankTransfer,
  transactionId: 'TXN123456789',
  proofBytes: imageBytes,
);

if (!validation.isValid) {
  print('Validation failed: ${validation.errors.join(", ")}');
  return;
}

if (validation.warnings.isNotEmpty) {
  print('Warnings: ${validation.warnings.join(", ")}');
}

print('Risk level: ${validation.riskLevel}');
```

## Error Handling

### Error Types and Recovery

#### Payment Errors
- **Validation Failed**: Check input data and retry
- **Proof Upload Failed**: Retry with different file or check connection
- **Database Error**: Contact support, retry later
- **Order/User Not Found**: Verify account and order status

#### Recovery Strategies
- **Automatic Retry**: Built-in exponential backoff for transient failures
- **User Guidance**: Specific error messages with actionable steps
- **Fallback Options**: Alternative payment methods when available
- **Support Escalation**: Critical errors trigger support notifications

### Monitoring and Alerts

#### Real-time Monitoring
- Payment success/failure rates
- Processing time trends
- Error frequency by type
- User experience metrics

#### Alert Triggers
- High error rates (>5% of payments)
- Payment processing delays (>30 seconds)
- Storage quota approaching limits
- Unusual payment patterns

## Security Features

### File Security
- **Secure Upload Paths**: User-specific folder structure
- **File Type Validation**: Only allowed file types accepted
- **Size Limits**: Prevents oversized file uploads
- **Content Validation**: Basic file signature verification

### Data Security
- **Row Level Security**: Users can only access their own data
- **Audit Logging**: All payment operations are logged
- **Data Encryption**: Sensitive data encrypted at rest
- **Access Control**: Role-based permissions for admin functions

### Payment Security
- **Duplicate Prevention**: Transaction ID validation
- **Amount Validation**: Reasonable limits and business rules
- **Timing Validation**: Rate limiting and suspicious pattern detection
- **Integrity Checks**: Payment data hash verification

## Performance Optimization

### File Processing
- **Image Compression**: Automatic resizing and quality optimization
- **Progressive Upload**: Large files uploaded in chunks
- **Caching**: Frequently accessed payment data cached
- **Background Processing**: Non-blocking file operations

### Database Optimization
- **Indexed Queries**: Optimized database indexes
- **Connection Pooling**: Efficient database connections
- **Query Optimization**: Efficient data retrieval patterns
- **Batch Operations**: Bulk operations for analytics

## Testing

### Unit Tests
```dart
void main() {
  group('PaymentService', () {
    test('should create payment with valid proof', () async {
      // Test implementation
    });

    test('should handle upload failures gracefully', () async {
      // Test implementation
    });

    test('should validate payment data correctly', () async {
      // Test implementation
    });
  });
}
```

### Integration Tests
```dart
void main() {
  group('Payment Integration', () {
    test('should complete full payment flow', () async {
      // End-to-end test implementation
    });

    test('should handle network failures', () async {
      // Network resilience test
    });
  });
}
```

## Troubleshooting

### Common Issues

#### Payment Proof Upload Fails
1. Check file size (max 10MB)
2. Verify file type (JPEG, PNG, WebP, PDF)
3. Check network connection
4. Try different file or camera source

#### Payment Validation Errors
1. Verify transaction ID format
2. Check payment amount limits
3. Ensure order belongs to user
4. Validate payment method requirements

#### Database Connection Issues
1. Check Supabase configuration
2. Verify RLS policies
3. Check user authentication
4. Review database permissions

### Debug Mode

Enable debug logging for detailed error information:

```dart
// In debug mode, enable verbose logging
Logger.enableVerboseLogging();

// View payment processing logs
final logs = await errorReporter.getErrorStatistics(
  category: ErrorCategory.payment,
  severity: ErrorSeverity.high,
);
```

## Maintenance

### Regular Tasks

#### Log Cleanup
```sql
-- Clean up old logs (run monthly)
DELETE FROM error_logs
WHERE timestamp < NOW() - INTERVAL '90 days';

DELETE FROM performance_logs
WHERE timestamp < NOW() - INTERVAL '90 days';
```

#### Performance Monitoring
```sql
-- Monitor payment performance
SELECT
    operation,
    AVG(duration_ms) as avg_duration,
    COUNT(*) as total_operations,
    COUNT(*) FILTER (WHERE duration_ms > 30000) as slow_operations
FROM performance_logs
WHERE category = 'payment'
    AND timestamp >= NOW() - INTERVAL '24 hours'
GROUP BY operation;
```

#### Error Analysis
```sql
-- Analyze payment errors
SELECT
    context,
    COUNT(*) as error_count,
    AVG(EXTRACT(EPOCH FROM (NOW() - timestamp))) / 3600 as hours_ago
FROM error_logs
WHERE category = 'payment'
    AND timestamp >= NOW() - INTERVAL '7 days'
GROUP BY context
ORDER BY error_count DESC;
```

## Support

### Getting Help

1. **Check Logs**: Review error logs for specific error details
2. **Validate Configuration**: Ensure all setup steps are completed
3. **Test Connectivity**: Verify Supabase and storage access
4. **Review Documentation**: Check this README for configuration issues

### Contact Information

For technical support or questions about the payment system:
- Create an issue in the project repository
- Include error logs and configuration details
- Provide steps to reproduce the issue

## Changelog

### Version 2.0.0
- Complete rewrite with Supabase integration
- Advanced error reporting and monitoring
- Transaction safety improvements
- Comprehensive validation system
- Robust retry mechanisms
- Secure file storage with compression

### Version 1.0.0
- Initial payment system with Firebase
- Basic payment processing
- Simple file upload functionality
