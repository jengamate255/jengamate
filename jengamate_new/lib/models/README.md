# Models Directory

This directory contains all the data models and business entities for JengaMate, organized by domain and functionality.

## 📁 Structure

### Core Business Models
- `user_model.dart` - User account and profile data
- `product_model.dart` - Product information and specifications
- `order_model.dart` - Order data and lifecycle
- `category_model.dart` - Product categorization
- `inquiry.dart` & `inquiry_model.dart` - Customer inquiries

### Communication Models
- `chat_message_model.dart` - Chat message data
- `chat_room_model.dart` - Chat room/conversation data
- `notification_model.dart` - Push notifications and alerts

### Financial Models
- `payment_model.dart` - Payment transaction data
- `financial_transaction_model.dart` - Financial records
- `commission_model.dart` - Commission calculations
- `commission_tier_model.dart` - Commission tier definitions
- `withdrawal_model.dart` - Withdrawal requests

### RFQ System Models
- `rfq_model.dart` - Request for Quotation data
- `quotation_model.dart` - Quote responses and pricing

### Admin & Content Models
- `admin_user_activity.dart` - Admin activity tracking
- `audit_log_model.dart` - System audit logs
- `content_moderation_model.dart` - Content moderation data
- `system_config_model.dart` - System configuration

### Enums Directory
- `order_enums.dart` - Order status, types, priorities
- `payment_enums.dart` - Payment methods and statuses
- `message_enums.dart` - Message types and priorities
- `user_role.dart` - User roles and permissions
- `transaction_enums.dart` - Transaction types and statuses

## 🔧 Key Features

### Data Validation
All models include:
- **Type safety** with proper Dart types
- **Required field validation**
- **Default values** for optional fields
- **Factory constructors** for data parsing

### Serialization Support
Models provide:
- **fromMap()** - Parse from Firestore/Supabase data
- **fromFirestore()** - Firebase-specific parsing
- **toMap()** - Convert to database format
- **toJson()** - JSON serialization support

### Business Logic
Models include:
- **Computed properties** (getters)
- **Helper methods** for common operations
- **Validation logic** for data integrity
- **Extension methods** for additional functionality

## 📖 Usage Examples

### Creating Models
```dart
// From Firestore data
final user = UserModel.fromFirestore(doc);

// From manual data
final product = ProductModel(
  id: 'prod_123',
  name: 'Construction Material',
  price: 299.99,
  categoryId: 'materials',
);

// From JSON/map data
final order = OrderModel.fromMap(orderData);
```

### Serialization
```dart
// To Firestore format
final data = user.toMap();

// To JSON for API calls
final json = user.toJson();
```

### Business Logic
```dart
// Computed properties
final totalPrice = order.totalAmount;
final displayName = user.displayName;
final isActive = product.isAvailable;

// Helper methods
final canEdit = user.canEdit(product);
final formattedPrice = product.formattedPrice;
```

## 🔄 Data Flow

```
Firestore/Supabase → fromMap()/fromFirestore() → Model Instance
Model Instance → toMap()/toJson() → Database/API
```

## 🏗️ Architecture Patterns

### Factory Pattern
```dart
factory UserModel.fromFirestore(DocumentSnapshot doc) {
  final data = doc.data() as Map<String, dynamic>;
  return UserModel.fromMap(data);
}
```

### Builder Pattern (for complex models)
```dart
UserModel copyWith({
  String? name,
  String? email,
  UserRole? role,
}) {
  return UserModel(
    uid: uid,
    name: name ?? this.name,
    email: email ?? this.email,
    role: role ?? this.role,
  );
}
```

### Extension Methods
```dart
extension UserModelExtensions on UserModel {
  String get displayName => '$firstName $lastName';
  bool get isAdmin => role == UserRole.admin;
}
```

## 🧪 Testing

Models include:
- **Factory constructor tests** for data parsing
- **Serialization tests** for toMap/toJson
- **Validation tests** for business logic
- **Edge case tests** for error conditions

## 📋 Best Practices

### Model Design
- Keep models focused on data representation
- Use immutable patterns where possible
- Include comprehensive documentation
- Follow consistent naming conventions

### Field Organization
- Required fields first in constructors
- Optional fields with sensible defaults
- Computed properties at the end
- Helper methods in extensions

### Error Handling
- Validate input data in factory constructors
- Provide meaningful error messages
- Handle null/undefined data gracefully
- Use custom exceptions for business logic errors

### Performance
- Use const constructors for static data
- Minimize object creation in getters
- Cache computed values when appropriate
- Avoid expensive operations in frequently called methods
