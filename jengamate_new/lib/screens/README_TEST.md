# Supabase Test Screen

A comprehensive test widget for verifying Supabase backend connectivity and file upload functionality.

## 📍 Access

**For Admin Users Only:**
1. Open the app drawer (hamburger menu)
2. Look for the "Debug section" at the bottom
3. Tap "Supabase Test"

**Direct Navigation:**
```dart
context.go('/test-supabase');
```

## 🧪 Test Features

### 1. Connection Test
- ✅ **Database Query**: Tests basic database connectivity
- ✅ **Real-time Connection**: Verifies WebSocket connection
- ✅ **Authentication**: Confirms auth system is working
- 📊 **Performance Monitoring**: Tracks test execution time

### 2. File Upload Test
- ✅ **Automatic Test**: Generates and uploads a 1x1 pixel test image
- ✅ **Public URL Generation**: Verifies file accessibility
- ✅ **Download Verification**: Confirms file integrity
- ✅ **Cleanup**: Automatically removes test files
- 📊 **Performance Tracking**: Monitors upload/download speeds

### 3. Manual File Upload
- 📸 **Image Picker**: Select images from device gallery
- ☁️ **Supabase Upload**: Upload to product_images bucket
- ✅ **Success Feedback**: Visual confirmation of uploads
- 🗑️ **Auto-cleanup**: Test files are cleaned up after verification

## 🎯 Test Results

### Success Indicators
```
✅ All tests passed! Your Supabase setup is working correctly.
```

### Individual Test Status
- **Connection Test**: `✅ Connected` / `❌ Failed`
- **Upload Test**: `✅ Upload Successful` / `❌ Upload Failed`
- **Details**: Specific error messages and success confirmations

## 🔧 Troubleshooting

### Connection Test Fails
- Check internet connectivity
- Verify Supabase project is active
- Confirm environment variables are set
- Check Supabase service initialization

### Upload Test Fails
- Verify storage bucket permissions
- Check Row Level Security policies
- Confirm file size limits
- Validate MIME type restrictions

### Manual Upload Issues
- Ensure gallery permissions are granted
- Check file size (must be under 5MB)
- Verify image format (JPG, PNG, WebP supported)

## 📊 Performance Metrics

The test screen integrates with the Performance Monitor to track:

- **Connection Test Duration**: Database + Real-time test time
- **Upload Test Duration**: File upload + verification time
- **Success Rates**: Historical test success percentages
- **Error Patterns**: Common failure modes

## 🔄 Test Flow

```
1. Run Connection Test → Database + Real-time verification
2. Run Upload Test → Automatic file upload test
3. Manual Upload → User-selected file upload
4. View Results → Comprehensive test summary
5. Reset Tests → Clear results and start over
```

## 🛡️ Security

- **Admin Only Access**: Only admin users can access the test screen
- **Test Data Isolation**: All test files are properly isolated
- **Auto Cleanup**: Test files are automatically removed
- **Audit Logging**: All test operations are logged

## 📱 Responsive Design

- **Mobile Optimized**: Touch-friendly interface
- **Tablet Support**: Adaptive layout for larger screens
- **Desktop Ready**: Full keyboard and mouse support
- **Dark Mode**: Automatic theme adaptation

## 🔗 Integration

### Performance Monitoring
```dart
final operationId = PerformanceMonitor().startOperation('supabase_connection_test');
// ... test logic ...
PerformanceMonitor().endOperation(operationId);
```

### Error Logging
```dart
Logger.log('✅ Supabase connection test successful');
Logger.logError('❌ Supabase connection test failed', error, stackTrace);
```

### Service Integration
```dart
final supabaseService = context.read<SupabaseService>();
final client = supabaseService.client;
```

## 🚀 Quick Start

1. **Login as Admin**: Ensure you're logged in with admin privileges
2. **Access Test Screen**: Use the drawer menu or direct navigation
3. **Run Tests**: Click individual test buttons or "Run All Tests"
4. **Check Results**: Review the test summary at the bottom
5. **Manual Testing**: Try uploading your own images

## 📋 Prerequisites

- **Admin Role**: Must be logged in as an administrator
- **Internet Connection**: Required for Supabase connectivity
- **Supabase Setup**: Backend must be properly configured
- **Permissions**: Gallery access for manual uploads (optional)

---

**🎉 Ready to test your Supabase backend connectivity and file uploads!**

The test screen provides comprehensive diagnostics for ensuring your Supabase integration is working correctly across all features.
