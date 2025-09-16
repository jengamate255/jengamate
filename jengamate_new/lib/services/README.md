# Services Directory

This directory contains all the business logic services for JengaMate, handling data operations, external integrations, and complex workflows.

## 📁 Structure

### Core Services

#### `auth_service.dart`
- Firebase Authentication integration
- User registration and login
- Password reset functionality
- OTP verification for phone auth
- Session management

#### `database_service.dart`
- Firestore database operations
- CRUD operations for all entities
- Query optimization and caching
- Real-time data synchronization
- Batch operations support

### Business Logic Services

#### `order_service.dart`
- Order creation and management
- Order status updates and tracking
- Order validation and business rules
- Order analytics and reporting

#### `payment_service.dart`
- Payment processing integration
- Multiple payment method support
- Payment verification and security
- Refund and chargeback handling
- Payment analytics

#### `quotation_service.dart`
- RFQ (Request for Quotation) processing
- Quote creation and management
- Price calculations and validation
- Quote approval workflows

#### `commission_tier_service.dart`
- Commission calculation logic
- Tier-based pricing models
- Referral program management
- Commission payment processing

### Communication Services

#### `chat_service.dart`
- Real-time messaging functionality
- Chat room management
- Message encryption and security
- File sharing in chats

#### `notification_service.dart`
- Push notification management
- Email notification templates
- Notification scheduling
- User preference management

#### `notification_trigger_service.dart`
- Automated notification triggers
- Event-based notifications
- Workflow notifications
- Admin alert system

### Content & Media Services

#### `product_service.dart`
- Product catalog management
- Product search and filtering
- Product analytics and insights
- Inventory management

#### `product_interaction_service.dart`
- Product view tracking
- User interaction analytics
- Recommendation engine
- Product performance metrics

### Storage Services

#### `storage_service.dart`
- Firebase Storage integration
- File upload and download
- Image optimization and resizing
- Secure file access control

#### `hybrid_storage_service.dart`
- Unified storage interface
- Firebase + Supabase integration
- Automatic failover and redundancy
- Storage optimization

#### `supabase_storage_service.dart`
- Supabase Storage integration
- Alternative storage backend
- High-availability file storage

### Administrative Services

#### `admin_analytics_service.dart`
- Administrative dashboard data
- System performance metrics
- User behavior analytics
- Business intelligence reports

#### `admin_notification_service.dart`
- Admin-specific notifications
- System alerts and warnings
- Administrative communication
- Escalation workflows

#### `audit_service.dart` & `audit_log_service.dart`
- System audit trail
- User activity logging
- Compliance and security logging
- Audit report generation

### Utility Services

#### `role_service.dart`
- User role and permission management
- Access control logic
- Role-based feature access
- Permission validation

#### `supplier_matching_service.dart`
- Supplier discovery and matching
- RFQ distribution to suppliers
- Supplier performance tracking
- Automated supplier selection

#### `theme_service.dart`
- Dynamic theme management
- User preference storage
- Theme customization
- Accessibility settings

## 🔧 Key Features

### Service Architecture

#### Dependency Injection
```dart
// Services use dependency injection for testability
class OrderService {
  final DatabaseService _database;
  final PaymentService _payment;

  OrderService(this._database, this._payment);
}
```

#### Error Handling
```dart
// Comprehensive error handling with custom exceptions
try {
  await _database.createOrder(orderData);
} on DatabaseException catch (e) {
  Logger.logError('Failed to create order', e);
  throw BusinessLogicException('Order creation failed: ${e.message}');
}
```

#### Transaction Management
```dart
// Atomic operations for data consistency
await _firestore.runTransaction((transaction) async {
  // Multiple database operations
  final orderRef = await transaction.set(orderCollection.doc(), orderData);
  await transaction.update(userRef, {'orderCount': FieldValue.increment(1)});
});
```

### Service Patterns

#### Repository Pattern
```dart
class UserRepository {
  final DatabaseService _database;

  Future<UserModel?> getUser(String uid) async {
    final doc = await _database.getDocument('users', uid);
    return doc != null ? UserModel.fromFirestore(doc) : null;
  }
}
```

#### Service Layer Pattern
```dart
class OrderProcessingService {
  // Business logic orchestration
  Future<OrderResult> processOrder(OrderRequest request) async {
    // Validate order
    // Process payment
    // Update inventory
    // Send notifications
    // Return result
  }
}
```

## 📖 Usage Examples

### Service Initialization
```dart
// Initialize core services
final authService = AuthService();
final databaseService = DatabaseService();
final storageService = StorageService();

// Initialize business services
final orderService = OrderService(databaseService);
final paymentService = PaymentService(databaseService, storageService);
```

### Service Usage
```dart
// Using services in widgets/screens
class OrderScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final orderService = context.read<OrderService>();
    final paymentService = context.read<PaymentService>();

    return ElevatedButton(
      onPressed: () async {
        try {
          final result = await orderService.createOrder(orderData);
          await paymentService.processPayment(result.orderId, paymentData);
          context.go('/order-success');
        } catch (e) {
          context.showErrorSnackBar(e.toString());
        }
      },
      child: const Text('Place Order'),
    );
  }
}
```

### Error Handling
```dart
// Using custom exceptions
try {
  await paymentService.processPayment(orderId, paymentData);
} on PaymentException catch (e) {
  // Handle payment-specific errors
  showPaymentErrorDialog(e.message);
} on NetworkException catch (e) {
  // Handle network errors
  showRetryDialog();
} catch (e) {
  // Handle unexpected errors
  Logger.logError('Unexpected error', e);
  showGenericErrorDialog();
}
```

## 🔄 Service Communication

### Service Dependencies
```
AuthService ← DatabaseService
OrderService ← DatabaseService, PaymentService, NotificationService
PaymentService ← DatabaseService, StorageService
```

### Data Flow
```
UI → Service → Database/External API → Service → UI
```

## 🧪 Testing

Services include:
- **Unit tests** for individual methods
- **Integration tests** for service interactions
- **Mock services** for isolated testing
- **End-to-end tests** for complete workflows

## 📋 Best Practices

### Service Design
- Single Responsibility Principle
- Dependency injection for testability
- Comprehensive error handling
- Async operation support

### Performance
- Efficient database queries
- Caching strategies
- Batch operations for bulk updates
- Lazy loading for large datasets

### Security
- Input validation and sanitization
- Authentication checks
- Authorization verification
- Secure data transmission

### Monitoring
- Operation logging
- Performance metrics
- Error tracking
- Usage analytics

## 🚀 Advanced Features

### Real-time Updates
```dart
// Stream-based real-time data
Stream<List<OrderModel>> getOrderUpdates(String userId) {
  return _database.streamCollection(
    'orders',
    where: {'userId': userId},
  ).map((docs) => docs.map(OrderModel.fromFirestore).toList());
}
```

### Offline Support
```dart
// Offline-first architecture
class OfflineOrderService extends OrderService {
  @override
  Future<OrderResult> createOrder(OrderData data) async {
    if (await _networkService.isOnline()) {
      return super.createOrder(data);
    } else {
      // Queue for later sync
      await _queueService.addToQueue('createOrder', data);
      return OrderResult.queued();
    }
  }
}
```

### Caching Strategies
```dart
class CachedUserService {
  final Map<String, UserModel> _cache = {};
  final Duration _cacheDuration = const Duration(minutes: 5);

  Future<UserModel?> getUser(String uid) async {
    if (_cache.containsKey(uid) && !_isExpired(uid)) {
      return _cache[uid];
    }

    final user = await _database.getUser(uid);
    if (user != null) {
      _cache[uid] = user;
    }
    return user;
  }
}
```
