# JengaMate Production Readiness Guide

> **Generated on:** January 24, 2025  
> **App Version:** 1.0.0+1  
> **Analysis Status:** Complete

## 📊 Executive Summary

JengaMate is a well-architected Flutter application for the construction industry, featuring role-based access control for Engineers, Suppliers, and Admins. The app has a solid foundation but requires several critical improvements before production deployment.

**Current Status:** 🟡 Development Ready → Production Preparation Required  
**Estimated Timeline to Production:** 8-12 weeks  
**Priority Level:** High - Security and configuration issues must be addressed

---

## 🏗️ Current Architecture Overview

### ✅ Strengths
- **Well-structured codebase** with proper separation of concerns
- **Role-based access control** (Engineers, Suppliers, Admins)
- **Firebase integration** with Firestore, Authentication, and Storage
- **Responsive design system** supporting mobile, tablet, and desktop
- **Comprehensive feature set** including orders, inquiries, chat, analytics
- **Provider state management** with proper dependency injection
- **Docker support** for containerized deployment

### 📁 Project Structure
```
jengamate/
├── lib/
│   ├── auth/              # Authentication widgets and logic
│   ├── config/            # Environment and app configuration
│   ├── models/            # Data models and enums
│   ├── screens/           # UI screens organized by feature
│   ├── services/          # Business logic and API services
│   ├── utils/             # Utilities (theme, responsive, logger)
│   └── widgets/           # Reusable UI components
├── test/                  # Unit and widget tests
├── android/               # Android-specific configuration
├── ios/                   # iOS-specific configuration
└── web/                   # Web-specific assets
```

---

## 🔴 Critical Issues (Must Fix Before Production)

### 1. **Firebase Configuration Incomplete**
**File:** [`lib/firebase_options.dart`](lib/firebase_options.dart)  
**Issue:** Only web platform configured, missing Android/iOS configurations

```dart
// Current state - only web configuration exists
static const FirebaseOptions web = FirebaseOptions(
  apiKey: 'AIzaSyCZku_umeY0AXt_IyG6Y898RKHfpL2rw7E', // ⚠️ Exposed API key
  // ... other config
);

// Missing Android/iOS configurations
case TargetPlatform.android:
case TargetPlatform.iOS:
  throw UnsupportedError('DefaultFirebaseOptions have not been configured');
```

**Impact:** App will crash on mobile platforms  
**Priority:** 🔴 Critical

### 2. **Security Vulnerabilities**

#### API Keys Exposed
**File:** [`lib/firebase_options.dart`](lib/firebase_options.dart:35)  
**Issue:** Firebase API key hardcoded in source code

#### Debug Signing in Production
**File:** [`android/app/build.gradle.kts`](android/app/build.gradle.kts:37)  
**Issue:** Release builds using debug signing configuration

```kotlin
buildTypes {
    release {
        // ⚠️ Using debug keys for release builds
        signingConfig = signingConfigs.getByName("debug")
    }
}
```

#### Default Package Name
**File:** [`android/app/build.gradle.kts`](android/app/build.gradle.kts:24)  
**Issue:** Using example package name instead of production name

```kotlin
applicationId = "com.example.jengamate" // ⚠️ Should be production package
```

**Impact:** Security vulnerabilities, app store rejection  
**Priority:** 🔴 Critical

### 3. **Basic Error Handling**
**File:** [`lib/utils/logger.dart`](lib/utils/logger.dart)  
**Issue:** Only console logging, no crash reporting or structured logging

```dart
class Logger {
  static void log(String message) {
    if (kDebugMode) {
      print(message); // ⚠️ Only prints to console
    }
  }
}
```

**Impact:** No visibility into production crashes or errors  
**Priority:** 🔴 Critical

### 4. **Incomplete Environment Configuration**
**Files:** [`lib/config/app_config.dart`](lib/config/app_config.dart), [`lib/config/dev_config.dart`](lib/config/dev_config.dart), [`lib/config/prod_config.dart`](lib/config/prod_config.dart)  
**Issue:** Configuration system exists but not fully implemented

```dart
// Current - minimal configuration
abstract class AppConfig {
  String get appName;
  String get flavorName;
  Environment get environment;
  // ⚠️ Missing: API URLs, feature flags, etc.
}
```

**Impact:** Hardcoded values, difficult environment management  
**Priority:** 🔴 Critical

---

## 🟡 Important Issues (Should Fix)

### 5. **Performance & Optimization**

#### No Pagination
**File:** [`lib/services/database_service.dart`](lib/services/database_service.dart:46-89)  
**Issue:** Large queries without pagination

```dart
Stream<List<Inquiry>> getInquiries(UserModel? user, {String? searchQuery, String? statusFilter}) {
  Query query = _db.collection('inquiries');
  // ⚠️ No limit() or pagination
  return query.snapshots().map((snapshot) => 
    snapshot.docs.map((doc) => Inquiry.fromFirestore(doc)).toList());
}
```

#### No Image Optimization
**Issue:** Missing image compression and caching for uploaded files

#### No Offline Support
**Issue:** No local storage or sync capabilities for offline usage

**Impact:** Poor performance with large datasets, slow loading times  
**Priority:** 🟡 Important

### 6. **Limited Testing Coverage**
**Directory:** [`test/`](test/)  
**Current Tests:**
- `auth_service_test.dart` - Basic auth service tests
- `database_service_test.dart` - Database service tests  
- `login_screen_test.dart` - Login screen widget tests
- `widget_test.dart` - Basic widget tests

**Missing:**
- Integration tests for user flows
- Comprehensive widget tests for all screens
- Performance tests
- Security tests

**Impact:** Higher risk of bugs in production  
**Priority:** 🟡 Important

### 7. **User Experience Gaps**

#### No Loading States
**Issue:** Missing loading indicators and skeleton screens throughout the app

#### Limited Error Messages
**File:** [`lib/services/auth_service.dart`](lib/services/auth_service.dart:69-82)  
**Issue:** Basic error handling with generic messages

```dart
String _handleAuthException(FirebaseAuthException e) {
  switch (e.code) {
    case 'weak-password':
      return 'The password provided is too weak.';
    // ⚠️ Limited error cases covered
    default:
      return 'An unknown error occurred.';
  }
}
```

#### No Push Notifications
**Issue:** Missing Firebase Cloud Messaging implementation

**Impact:** Poor user experience, reduced engagement  
**Priority:** 🟡 Important

---

## 📋 Production Readiness Roadmap

### **Phase 1: Critical Security & Configuration** ⏱️ 2-3 weeks

#### Task 1.1: Complete Firebase Configuration
**Priority:** 🔴 Critical  
**Estimated Time:** 2-3 days

**Steps:**
1. Run `flutterfire configure` to generate complete Firebase configuration
2. Set up separate Firebase projects for dev/staging/production
3. Configure Android and iOS Firebase options
4. Move API keys to environment variables

**Implementation:**
```bash
# Install FlutterFire CLI
npm install -g firebase-tools
dart pub global activate flutterfire_cli

# Configure Firebase for all platforms
flutterfire configure --project=jengamate-dev
flutterfire configure --project=jengamate-staging  
flutterfire configure --project=jengamate-prod
```

**Files to Update:**
- `lib/firebase_options.dart`
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

#### Task 1.2: Set Up Proper App Signing
**Priority:** 🔴 Critical  
**Estimated Time:** 1-2 days

**Steps:**
1. Generate production keystore for Android
2. Configure proper signing in build.gradle.kts
3. Update package name from `com.example.jengamate`
4. Set up iOS certificates and provisioning profiles

**Implementation:**
```bash
# Generate Android keystore
keytool -genkey -v -keystore ~/jengamate-release-key.keystore \
  -alias jengamate -keyalg RSA -keysize 2048 -validity 10000
```

**Files to Update:**
- `android/app/build.gradle.kts`
- `android/key.properties` (create)
- `android/app/src/main/AndroidManifest.xml`

#### Task 1.3: Implement Comprehensive Error Handling
**Priority:** 🔴 Critical  
**Estimated Time:** 3-4 days

**Steps:**
1. Add Firebase Crashlytics dependency
2. Implement global error handling in main.dart
3. Create structured logging system
4. Add error boundaries for critical operations

**Implementation:**
```dart
// Add to pubspec.yaml
dependencies:
  firebase_crashlytics: ^3.4.9

// Update main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Global error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    FirebaseCrashlytics.instance.recordFlutterError(details);
  };
  
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
  
  runApp(const JengamateApp());
}
```

**Files to Update:**
- `pubspec.yaml`
- `lib/main.dart`
- `lib/utils/logger.dart`

#### Task 1.4: Environment Configuration System
**Priority:** 🔴 Critical  
**Estimated Time:** 2-3 days

**Steps:**
1. Implement proper dev/staging/prod configurations
2. Add environment-specific Firebase projects
3. Create build flavors for different environments
4. Add feature flags system

**Implementation:**
```dart
// Enhanced app_config.dart
abstract class AppConfig {
  String get appName;
  String get flavorName;
  Environment get environment;
  String get apiBaseUrl;
  String get firebaseProjectId;
  bool get enableAnalytics;
  bool get enableCrashlytics;
  Map<String, dynamic> get featureFlags;
}

// Environment-specific configs
class ProdConfig implements AppConfig {
  @override
  String get apiBaseUrl => 'https://api.jengamate.com';
  
  @override
  String get firebaseProjectId => 'jengamate-prod';
  
  @override
  bool get enableAnalytics => true;
  
  @override
  Map<String, dynamic> get featureFlags => {
    'enableChat': true,
    'enableNotifications': true,
    'enableOfflineMode': false,
  };
}
```

**Files to Update:**
- `lib/config/app_config.dart`
- `lib/config/dev_config.dart`
- `lib/config/prod_config.dart`
- `lib/main.dart`

### **Phase 2: Enhanced Security & Performance** ⏱️ 3-4 weeks

#### Task 2.1: Strengthen Firestore Security Rules
**Priority:** 🟡 Important  
**Estimated Time:** 3-4 days

**Current Rules Analysis:**
```javascript
// Current firestore.rules - basic role-based access
function getUserRole(userId) {
  return get(/databases/$(database)/documents/users/$(userId)).data.role;
}

match /users/{userId} {
  allow read, update: if request.auth.uid == userId;
  allow create: if request.auth.uid != null;
}
```

**Enhancements Needed:**
1. Add input validation
2. Implement rate limiting
3. Add audit logging for admin actions
4. Strengthen data validation rules

**Implementation:**
```javascript
// Enhanced security rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Input validation functions
    function isValidEmail(email) {
      return email.matches('.*@.*\\..*');
    }
    
    function isValidString(str, minLen, maxLen) {
      return str is string && str.size() >= minLen && str.size() <= maxLen;
    }
    
    // Rate limiting (requires additional setup)
    function isNotRateLimited() {
      return true; // Implement with Cloud Functions
    }
    
    match /users/{userId} {
      allow read, update: if request.auth.uid == userId 
        && isNotRateLimited()
        && validateUserData();
      allow create: if request.auth.uid != null 
        && isValidEmail(request.resource.data.email)
        && isValidString(request.resource.data.name, 2, 50);
        
      function validateUserData() {
        return request.resource.data.keys().hasAll(['name', 'email', 'role'])
          && isValidString(request.resource.data.name, 2, 50)
          && isValidEmail(request.resource.data.email);
      }
    }
    
    // Audit logging for admin actions
    match /audit_logs/{logId} {
      allow create: if request.auth.uid != null;
      allow read: if getUserRole(request.auth.uid) == 'admin';
    }
  }
}
```

#### Task 2.2: Implement Proper Logging & Monitoring
**Priority:** 🟡 Important  
**Estimated Time:** 2-3 days

**Steps:**
1. Replace basic logger with structured logging
2. Add different log levels (debug, info, warning, error)
3. Implement performance monitoring
4. Add custom analytics events

**Implementation:**
```dart
// Enhanced logger.dart
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

enum LogLevel { debug, info, warning, error }

class Logger {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  static final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;
  
  static void log(String message, {
    LogLevel level = LogLevel.info,
    Map<String, dynamic>? parameters,
    String? userId,
  }) {
    // Console logging for debug builds
    if (kDebugMode) {
      print('[${level.name.toUpperCase()}] $message');
      if (parameters != null) {
        print('Parameters: $parameters');
      }
    }
    
    // Send to Firebase based on level
    switch (level) {
      case LogLevel.error:
        _crashlytics.recordError(message, null, fatal: false);
        break;
      case LogLevel.warning:
        _crashlytics.log('WARNING: $message');
        break;
      case LogLevel.info:
        _analytics.logEvent(
          name: 'app_log',
          parameters: {
            'message': message,
            'level': level.name,
            ...?parameters,
          },
        );
        break;
      case LogLevel.debug:
        // Only log in debug mode
        break;
    }
    
    // Set user context
    if (userId != null) {
      _crashlytics.setUserIdentifier(userId);
      _analytics.setUserId(id: userId);
    }
  }
  
  static void logUserAction(String action, {
    Map<String, dynamic>? parameters,
    String? userId,
  }) {
    _analytics.logEvent(
      name: 'user_action',
      parameters: {
        'action': action,
        'timestamp': DateTime.now().toIso8601String(),
        ...?parameters,
      },
    );
    
    log('User action: $action', 
        level: LogLevel.info, 
        parameters: parameters, 
        userId: userId);
  }
  
  static void logPerformance(String operation, Duration duration) {
    _analytics.logEvent(
      name: 'performance_metric',
      parameters: {
        'operation': operation,
        'duration_ms': duration.inMilliseconds,
      },
    );
  }
}
```

#### Task 2.3: Add Input Validation & Sanitization
**Priority:** 🟡 Important  
**Estimated Time:** 4-5 days

**Steps:**
1. Create validation utilities
2. Add form validation throughout the app
3. Sanitize data before Firestore operations
4. Implement client-side and server-side validation

**Implementation:**
```dart
// Create lib/utils/validation.dart
class ValidationUtils {
  static String? validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return 'Email is required';
    }
    
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      return 'Please enter a valid email address';
    }
    
    return null;
  }
  
  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'Password is required';
    }
    
    if (password.length < 8) {
      return 'Password must be at least 8 characters long';
    }
    
    if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(password)) {
      return 'Password must contain uppercase, lowercase, and numbers';
    }
    
    return null;
  }
  
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }
  
  static String sanitizeString(String input) {
    return input.trim()
      .replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML tags
      .replaceAll(RegExp(r'[^\w\s\-\.]'), ''); // Keep only safe characters
  }
  
  static double? validatePrice(String? price) {
    if (price == null || price.isEmpty) return null;
    
    final parsed = double.tryParse(price);
    if (parsed == null || parsed < 0) {
      throw ValidationException('Invalid price format');
    }
    
    return parsed;
  }
}

class ValidationException implements Exception {
  final String message;
  ValidationException(this.message);
  
  @override
  String toString() => 'ValidationException: $message';
}
```

#### Task 2.4: Optimize Database Operations
**Priority:** 🟡 Important  
**Estimated Time:** 5-6 days

**Steps:**
1. Add pagination to all list queries
2. Implement proper indexing strategy
3. Add offline caching with Hive
4. Optimize query performance

**Implementation:**
```dart
// Enhanced database_service.dart with pagination
class DatabaseService {
  static const int defaultPageSize = 20;
  
  Stream<List<Inquiry>> getInquiriesPaginated(
    UserModel? user, {
    String? searchQuery,
    String? statusFilter,
    DocumentSnapshot? lastDocument,
    int limit = defaultPageSize,
  }) {
    Query query = _db.collection('inquiries');
    
    // Apply filters
    if (user != null && user.role == UserRole.engineer) {
      query = query.where('userId', isEqualTo: user.uid);
    }
    
    if (statusFilter != null && statusFilter.isNotEmpty) {
      query = query.where('status', isEqualTo: statusFilter);
    }
    
    // Add ordering and pagination
    query = query.orderBy('createdAt', descending: true);
    
    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }
    
    query = query.limit(limit);
    
    return query.snapshots().map((snapshot) {
      Logger.logPerformance(
        'getInquiriesPaginated', 
        DateTime.now().difference(DateTime.now())
      );
      
      return snapshot.docs.map((doc) => Inquiry.fromFirestore(doc)).toList();
    });
  }
  
  // Add caching layer
  final Map<String, dynamic> _cache = {};
  final Duration _cacheExpiry = const Duration(minutes: 5);
  
  Future<UserModel?> getUserCached(String uid) async {
    final cacheKey = 'user_$uid';
    final cached = _cache[cacheKey];
    
    if (cached != null && 
        DateTime.now().difference(cached['timestamp']) < _cacheExpiry) {
      return cached['data'] as UserModel?;
    }
    
    final user = await getUser(uid);
    _cache[cacheKey] = {
      'data': user,
      'timestamp': DateTime.now(),
    };
    
    return user;
  }
}
```

### **Phase 3: User Experience & Testing** ⏱️ 2-3 weeks

#### Task 3.1: Enhance User Experience
**Priority:** 🟡 Important  
**Estimated Time:** 4-5 days

**Steps:**
1. Add loading states and skeleton screens
2. Implement proper error messages and user feedback
3. Add pull-to-refresh functionality
4. Improve navigation and user flows

**Implementation:**
```dart
// Create lib/widgets/loading_states.dart
class LoadingStateWidget extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? loadingMessage;
  
  const LoadingStateWidget({
    Key? key,
    required this.isLoading,
    required this.child,
    this.loadingMessage,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            if (loadingMessage != null) ...[
              const SizedBox(height: 16),
              Text(loadingMessage!),
            ],
          ],
        ),
      );
    }
    
    return child;
  }
}

// Skeleton loading widget
class SkeletonLoader extends StatelessWidget {
  final double height;
  final double width;
  final BorderRadius? borderRadius;
  
  const SkeletonLoader({
    Key? key,
    required this.height,
    required this.width,
    this.borderRadius,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: borderRadius ?? BorderRadius.circular(4),
      ),
      child: const ShimmerEffect(),
    );
  }
}
```

#### Task 3.2: Implement Push Notifications
**Priority:** 🟡 Important  
**Estimated Time:** 3-4 days

**Steps:**
1. Set up Firebase Cloud Messaging (FCM)
2. Add notification handling for orders, quotes, and messages
3. Implement notification preferences
4. Add local notifications for offline scenarios

**Implementation:**
```dart
// Create lib/services/notification_service.dart
class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();
  
  static Future<void> initialize() async {
    // Request permissions
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      Logger.log('User granted notification permissions');
      
      // Get FCM token
      String? token = await _messaging.getToken();
      if (token != null) {
        await _saveTokenToDatabase(token);
      }
      
      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      
      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);
      
      // Handle notification taps
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
    }
    
    // Initialize local notifications
    await _initializeLocalNotifications();
  }
  
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    Logger.log('Received foreground message: ${message.messageId}');
    
    // Show local notification
    await _showLocalNotification(
      title: message.notification?.title ?? 'New Notification',
      body: message.notification?.body ?? '',
      payload: message.data.toString(),
    );
  }
  
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    Logger.log('Received background message: ${message.messageId}');
  }
  
  static Future<void> _handleNotificationTap(RemoteMessage message) async {
    Logger.log('Notification tapped: ${message.messageId}');
    
    // Navigate based on notification type
    final notificationType = message.data['type'];
    switch (notificationType) {
      case 'new_order':
        NavigationService.navigateTo('/orders/${message.data['orderId']}');
        break;
      case 'new_quote':
        NavigationService.navigateTo('/inquiries/${message.data['inquiryId']}');
        break;
      case 'new_message':
        NavigationService.navigateTo('/chat/${message.data['chatRoomId']}');
        break;
    }
  }
}
```

#### Task 3.3: Add Comprehensive Testing
**Priority:** 🟡 Important  
**Estimated Time:** 6-7 days

**Steps:**
1. Write unit tests for all services and models
2. Add widget tests for critical UI components
3. Implement integration tests for user flows
4. Add performance and load testing

**Implementation:**
```dart
// Enhanced test/auth_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jengamate/services/auth_service.dart';

@GenerateMocks([FirebaseAuth, User, UserCredential])
import 'auth_service_test.mocks.dart';

void main() {
  group('AuthService Tests', () {
    late AuthService authService;
    late MockFirebaseAuth mockFirebaseAuth;
    late MockUser mockUser;
    late MockUserCredential mockUserCredential;
    
    setUp(() {
      mockFirebaseAuth = MockFirebaseAuth();
      mockUser = MockUser();
      mockUserCredential = MockUserCredential();
      authService = AuthService(mockFirebaseAuth);
    });
    
    group('signIn', () {
      test('should return success message on successful sign in', () async {
        // Arrange
        when(mockUserCredential.user).thenReturn(mockUser);
        when(mockUser.uid).thenReturn('test-uid');
        when(mockFirebaseAuth.signInWithEmailAndPassword(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenAnswer((_) async => mockUserCredential);
        
        // Act
        final result = await authService.signIn(
          email: 'test@example.com',
          password: 'password123',
        );
        
        // Assert
        expect(result, equals('Signed in'));
        verify(mockFirebaseAuth.signInWithEmailAndPassword(
          email: 'test@example.com',
          password: 'password123',
        )).called(1);
      });
      
      test('should handle weak password error', () async {
        // Arrange
        when(mockFirebaseAuth.signInWithEmailAndPassword(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenThrow(FirebaseAuthException(
          code: 'weak-password',
          message: 'The password provided is too weak.',
        ));
        
        // Act
        final result = await authService.signIn(
          email: 'test@example.com',
          password: 'weak',
        );
        
        // Assert
        expect(result, equals('The password provided is too weak.'));
      });
    });
    
    group('signUp', () {
      test('should create user and update profile on successful sign up', () async {
        // Arrange
        when(mockUserCredential.user).thenReturn(mockUser);
        when(mockUser.uid).thenReturn('test-uid');
        when(mockUser.updateDisplayName(any)).thenAnswer((_) async {});
        when(mockFirebaseAuth.createUserWithEmailAndPassword(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenAnswer((_) async => mockUserCredential);
        
        // Act
        final result = await authService.signUp(
          email: 'test@example.com',
          password: 'password123',
          displayName: 'Test User',
        );
        
        // Assert
        expect(result, equals('Signed up'));
        verify(mockUser.updateDisplayName('Test User')).called(1);
      });
    });
  });
}

// Integration test example
// test_driver/app_test.dart
import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

void main() {
  group('JengaMate App Integration Tests', () {
    late FlutterDriver driver;
    
    setUpAll(() async {
      driver = await FlutterDriver.connect();
    });
    
    tearDownAll(() async {
      await driver.close();
    });
    
    test('should complete login flow', () async {
      // Find login form elements
      final emailField = find.byValueKey('email_field');
      final passwordField = find.byValueKey('password_field');
      final loginButton = find.byValueKey('login_button');
      
      // Enter credentials
      await driver.tap(emailField);
      await driver.enterText('test@example.com');
      
      await driver.tap(passwordField);
      await driver.enterText('password123');
      
      // Tap login button
      await driver.tap(loginButton);
      
      // Wait for dashboard to appear
      await driver.waitFor(find.byValueKey('dashboard_screen'));
      
      // Verify user is logged in
      expect(await driver.getText(find.byValueKey('welcome_message')), 
             contains('Welcome'));
    });
    
    test('should create new inquiry', () async {
      // Navigate to new inquiry screen
      await driver.tap(find.byValueKey('new_inquiry_button'));
      await driver.waitFor(find.byValueKey('inquiry_form'));
      
      // Fill out form
      await driver.tap(find.byValueKey('project_name_field'));
      await driver.enterText('Test Project');
      
      await driver.tap(find.byValueKey('description_field'));
      await driver.enterText('Test project description');
      
      // Submit form
      await driver.tap(find.byValueKey('submit_inquiry_button'));
      
      // Verify success
      await driver.waitFor(