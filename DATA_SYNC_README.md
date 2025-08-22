# Data Synchronization System

This system provides a comprehensive solution for synchronizing dummy data structures with your Firestore database, ensuring consistency between your application code and database state.

## Overview

The data synchronization system consists of three main components:

1. **DataSyncService** - Handles the actual synchronization of data
2. **DynamicDataService** - Provides dynamic data access with caching
3. **DataSyncManagementScreen** - Admin interface for managing sync operations

## Features

- **Automatic Sync Detection**: Automatically detects when data synchronization is needed
- **Incremental Updates**: Only updates data that has changed
- **Fallback Support**: Provides fallback values if the service fails
- **Real-time Validation**: Validates data against database rules
- **Admin Management**: Provides admin interface for manual sync operations

## Data Types Synchronized

### 1. Commission Tiers
- **Engineer Tiers**: Bronze, Silver, Gold, Platinum
- **Supplier Tiers**: Bronze, Silver, Gold, Platinum
- Each tier includes: minProducts, minTotalValue, ratePercent, badgeText, badgeColor

### 2. System Configuration
- Order statuses
- Inquiry statuses
- Priorities
- Content types
- Severity levels
- RFQ statuses and types

### 3. Categories
- Electronics, Construction, Automotive, Industrial
- Agriculture, Healthcare, Textiles, Food & Beverage

### 4. Role Permissions
- Super Admin, Admin, Moderator, User, Guest
- Each role has specific permissions and descriptions

## Usage

### 1. Automatic Initialization

The system automatically initializes when you first use the `DynamicDataService`:

```dart
final dynamicDataService = DynamicDataService();
await dynamicDataService.initialize();
```

### 2. Accessing Dynamic Data

```dart
// Get order statuses
List<String> orderStatuses = dynamicDataService.getOrderStatuses();

// Get inquiry statuses
List<String> inquiryStatuses = dynamicDataService.getInquiryStatuses();

// Get priorities
List<String> priorities = dynamicDataService.getPriorities();

// Get categories
List<Map<String, dynamic>> categories = await dynamicDataService.getCategories();

// Get commission tiers for a role
List<Map<String, dynamic>> tiers = await dynamicDataService.getCommissionTiers('engineer');
```

### 3. Manual Sync Operations

```dart
final dataSyncService = DataSyncService();

// Check if sync is needed
bool needsSync = await dataSyncService.isSyncNeeded();

// Perform full sync
await dataSyncService.syncAllData();

// Force sync regardless of last sync time
await dataSyncService.forceSync();
```

### 4. Force Refresh

```dart
final dynamicDataService = DynamicDataService();

// Force refresh and sync
await dynamicDataService.forceRefresh();
```

## Database Collections

The system creates and manages the following Firestore collections:

- `commission_tiers` - Commission tier definitions
- `categories` - Product categories
- `system_config` - System configuration data
- `role_permissions` - Role-based permissions

## Firestore Rules

The system works with the existing Firestore security rules. Make sure your rules allow:

- Read access to `commission_tiers`, `categories`, `system_config` for authenticated users
- Write access to these collections for admin users only

## Admin Interface

The `DataSyncManagementScreen` provides an admin interface for:

- Viewing sync status
- Manually triggering sync operations
- Viewing current system configuration
- Monitoring categories and commission tiers

## Error Handling

The system includes comprehensive error handling:

- **Fallback Values**: If the service fails, fallback to hardcoded values
- **Logging**: All operations are logged for debugging
- **User Feedback**: Users are notified of sync status and errors

## Performance Considerations

- **Caching**: Frequently accessed data is cached to reduce database calls
- **Incremental Updates**: Only changed data is updated during sync
- **Background Operations**: Sync operations run in the background

## Troubleshooting

### Common Issues

1. **Sync Fails**: Check Firebase permissions and network connectivity
2. **Data Not Loading**: Verify the service is properly initialized
3. **Permission Errors**: Ensure user has appropriate role permissions

### Debug Information

Enable debug logging to see detailed sync operations:

```dart
// Check sync status
bool needsSync = await dataSyncService.isSyncNeeded();
print('Sync needed: $needsSync');

// Get system config
final config = await dataSyncService.getSystemConfig();
print('System config: $config');
```

## Migration from Hardcoded Data

To migrate existing screens from hardcoded data:

1. **Import the service**:
```dart
import 'package:jengamate/services/dynamic_data_service.dart';
```

2. **Initialize the service**:
```dart
final dynamicDataService = DynamicDataService();
await dynamicDataService.initialize();
```

3. **Replace hardcoded lists**:
```dart
// Before
final List<String> statuses = ['PENDING', 'PROCESSING', 'SHIPPED'];

// After
List<String> statuses = dynamicDataService.getOrderStatuses();
```

4. **Add fallback values**:
```dart
List<String> statuses = [];
try {
  await dynamicDataService.initialize();
  statuses = dynamicDataService.getOrderStatuses();
} catch (e) {
  // Fallback to default values
  statuses = ['PENDING', 'PROCESSING', 'SHIPPED'];
}
```

## Database Initialization Script

Use the Node.js script to initialize your database:

```bash
cd scripts
npm install firebase-admin
node init_database.js
```

**Note**: Update the Firebase configuration in the script before running.

## Best Practices

1. **Initialize Early**: Initialize the service in your app's startup
2. **Handle Errors**: Always provide fallback values for critical data
3. **Monitor Sync Status**: Check sync status before critical operations
4. **Regular Maintenance**: Periodically review and update sync data
5. **Backup Data**: Keep backups of your sync configuration

## Security Considerations

- Only admin users should have write access to sync collections
- Validate all data before syncing to prevent injection attacks
- Monitor sync operations for suspicious activity
- Use Firebase Auth rules to restrict access appropriately

## Future Enhancements

- **Webhook Support**: Trigger sync operations via webhooks
- **Scheduled Sync**: Automatically sync data at regular intervals
- **Conflict Resolution**: Handle conflicts between local and remote data
- **Version Control**: Track changes to sync data over time
- **Multi-Environment Support**: Sync data across different environments