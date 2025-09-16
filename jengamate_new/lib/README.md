# JengaMate Library

This directory contains the main Flutter application code for JengaMate, organized into logical modules for maintainability and scalability.

## 📁 Directory Structure

### Core Modules

#### `auth/`
Authentication-related screens and components
- Login, registration, OTP verification
- Password reset functionality
- User onboarding flows

#### `config/`
Application configuration and setup
- App routing and navigation
- Theme definitions
- Firebase and Supabase configuration

#### `models/`
Data models and business entities
- User models and authentication data
- Product and category models
- Order and payment models
- RFQ and quotation models
- Admin and system models

#### `screens/`
UI screens organized by feature
- `admin/` - Administrative dashboard and management screens
- `auth/` - Authentication screens
- `dashboard/` - Main dashboard and navigation
- `products/` - Product browsing and management
- `orders/` - Order processing and management
- `rfq/` - Request for Quotation functionality

#### `services/`
Business logic and external service integrations
- Database operations (Firebase Firestore)
- Authentication services
- Payment processing
- File storage (Firebase Storage, Supabase)
- Email and notification services

#### `widgets/`
Reusable UI components
- Custom buttons and form fields
- Loading indicators and error displays
- Navigation components
- Admin-specific widgets

#### `utils/`
Utility functions and helpers
- Logging utilities
- Form validation helpers
- Responsive design utilities
- Navigation helpers

### Specialized Modules

#### `ui/`
Design system and UI components
- `design_system/` - Material Design 3 components
- `shared_components/` - Reusable UI widgets

#### `core/`
Core application functionality
- `error_handling/` - Comprehensive error management

## 🔧 Key Features

### Clean Architecture
- **Separation of Concerns**: Clear boundaries between UI, business logic, and data
- **Dependency Injection**: Provider pattern for state management
- **Repository Pattern**: Abstraction layer for data operations

### Design System
- **Material Design 3**: Modern, accessible design system
- **Responsive Design**: Adaptive layouts for all screen sizes
- **Consistent Theming**: Unified color palette and typography

### Error Handling
- **Structured Exceptions**: Custom exception types for different error scenarios
- **Error Boundaries**: Graceful error recovery in UI
- **Comprehensive Logging**: Detailed error tracking and debugging

### Performance Optimizations
- **Efficient State Management**: Provider-based state updates
- **Image Caching**: Optimized image loading and caching
- **Lazy Loading**: On-demand data loading for better performance

## 📦 Imports

### Main Library Export
```dart
import 'package:jengamate/jengamate.dart';
```

### Modular Imports
```dart
// Specific modules
import 'package:jengamate/models.dart';
import 'package:jengamate/services.dart';
import 'package:jengamate/widgets.dart';

// Individual components
import 'package:jengamate/ui/shared_components/loading_overlay.dart';
import 'package:jengamate/core/error_handling/error_boundary.dart';
```

## 🚀 Getting Started

1. **Import the main library**:
   ```dart
   import 'package:jengamate/jengamate.dart';
   ```

2. **Initialize services**:
   ```dart
   await Firebase.initializeApp();
   await SupabaseService.instance.initialize();
   ```

3. **Use components**:
   ```dart
   // Error boundary
   ErrorBoundary(
     child: MyWidget(),
   )

   // Loading overlay
   child.withLoadingOverlay(isLoading: true)
   ```

## 🔧 Development Guidelines

### Code Organization
- Keep related functionality together
- Use barrel exports for clean imports
- Follow Flutter best practices
- Maintain consistent naming conventions

### Error Handling
- Use custom exceptions for business logic errors
- Wrap async operations with error boundaries
- Provide meaningful error messages to users
- Log errors for debugging

### Performance
- Use const constructors for static widgets
- Implement proper state management
- Optimize image loading and caching
- Minimize rebuilds with proper keys

## 🧪 Testing

- Unit tests in `test/` directory
- Widget tests for UI components
- Integration tests for complex workflows
- Mock data for isolated testing

## 📚 Additional Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Supabase Documentation](https://supabase.com/docs)
- [Material Design Guidelines](https://material.io/design)
