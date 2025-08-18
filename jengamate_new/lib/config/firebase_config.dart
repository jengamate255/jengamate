import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Import all environment-specific configurations
import '../firebase_options.dart' as fallback;

/// Firebase configuration manager for different environments
class FirebaseConfig {
  /// Get Firebase options based on platform and environment
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      final web = _getWebOptions();
      if (_isValid(web)) return web;
      return fallback.DefaultFirebaseOptions.currentPlatform;
    }
    
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        final android = _getAndroidOptions();
        return _isValid(android)
            ? android
            : fallback.DefaultFirebaseOptions.currentPlatform;
      case TargetPlatform.iOS:
        final ios = _getiOSOptions();
        return _isValid(ios)
            ? ios
            : fallback.DefaultFirebaseOptions.currentPlatform;
      case TargetPlatform.macOS:
        final mac = _getMacOSOptions();
        return _isValid(mac)
            ? mac
            : fallback.DefaultFirebaseOptions.currentPlatform;
      case TargetPlatform.windows:
        final win = _getWindowsOptions();
        return _isValid(win)
            ? win
            : fallback.DefaultFirebaseOptions.currentPlatform;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'Firebase configuration not available for Linux platform',
        );
      default:
        return fallback.DefaultFirebaseOptions.currentPlatform;
    }
  }

  /// Get web platform configuration from environment
  static FirebaseOptions _getWebOptions() {
    // IMPORTANT: Do NOT hardcode web credentials in source.
    // Provide values via --dart-define/--dart-define-from-file
    // Example (Flutter 3.10+):
    //   flutter run -d chrome \
    //     --dart-define=FIREBASE_WEB_API_KEY=... \
    //     --dart-define=FIREBASE_WEB_APP_ID=... \
    //     --dart-define=FIREBASE_MESSAGING_SENDER_ID=... \
    //     --dart-define=FIREBASE_PROJECT_ID=... \
    //     --dart-define=FIREBASE_AUTH_DOMAIN=... \
    //     --dart-define=FIREBASE_STORAGE_BUCKET=... \
    //     --dart-define=FIREBASE_MEASUREMENT_ID=...
    return FirebaseOptions(
      apiKey: dotenv.env['FIREBASE_WEB_API_KEY'] ?? '',
      appId: dotenv.env['FIREBASE_WEB_APP_ID'] ?? '',
      messagingSenderId:
          dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '',
      projectId: dotenv.env['FIREBASE_PROJECT_ID'] ?? '',
      authDomain: dotenv.env['FIREBASE_AUTH_DOMAIN'] ?? '',
      storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? '',
      measurementId: dotenv.env['FIREBASE_MEASUREMENT_ID'] ?? '',
    );
  }

  /// Get Android platform configuration from environment
  static FirebaseOptions _getAndroidOptions() {
    return FirebaseOptions(
      apiKey: dotenv.env['FIREBASE_ANDROID_API_KEY'] ?? '',
      appId: dotenv.env['FIREBASE_ANDROID_APP_ID'] ?? '',
      messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '',
      projectId: dotenv.env['FIREBASE_PROJECT_ID'] ?? '',
      storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? '',
    );
  }

  /// Get iOS platform configuration from environment
  static FirebaseOptions _getiOSOptions() {
    return FirebaseOptions(
      apiKey: dotenv.env['FIREBASE_IOS_API_KEY'] ?? '',
      appId: dotenv.env['FIREBASE_IOS_APP_ID'] ?? '',
      messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '',
      projectId: dotenv.env['FIREBASE_PROJECT_ID'] ?? '',
      storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? '',
      iosBundleId: dotenv.env['FIREBASE_IOS_BUNDLE_ID'] ?? '',
    );
  }

  /// Get macOS platform configuration from environment
  static FirebaseOptions _getMacOSOptions() {
    return FirebaseOptions(
      apiKey: dotenv.env['FIREBASE_MACOS_API_KEY'] ?? '',
      appId: dotenv.env['FIREBASE_MACOS_APP_ID'] ?? '',
      messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '',
      projectId: dotenv.env['FIREBASE_PROJECT_ID'] ?? '',
      storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? '',
      iosBundleId: dotenv.env['FIREBASE_MACOS_BUNDLE_ID'] ?? '',
    );
  }

  /// Get Windows platform configuration from environment
  static FirebaseOptions _getWindowsOptions() {
    return FirebaseOptions(
      apiKey: dotenv.env['FIREBASE_WINDOWS_API_KEY'] ?? '',
      appId: dotenv.env['FIREBASE_WINDOWS_APP_ID'] ?? '',
      messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '',
      projectId: dotenv.env['FIREBASE_PROJECT_ID'] ?? '',
      authDomain: dotenv.env['FIREBASE_AUTH_DOMAIN'] ?? '',
      storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? '',
      measurementId: dotenv.env['FIREBASE_MEASUREMENT_ID'] ?? '',
    );
  }

  /// Validate that all required environment variables are set
  static bool validateConfiguration() {
    try {
      final config = currentPlatform;
      return _isValid(config);
    } catch (e) {
      debugPrint('Firebase configuration validation failed: $e');
      return false;
    }
  }

  static bool _isValid(FirebaseOptions config) {
    return config.apiKey.isNotEmpty &&
        config.appId.isNotEmpty &&
        config.projectId.isNotEmpty;
  }

  /// Get configuration summary for debugging (without exposing keys)
  static Map<String, String> getConfigurationSummary() {
    try {
      final config = currentPlatform;
      return {
        'platform': defaultTargetPlatform.toString(),
        'projectId': config.projectId,
        'messagingSenderId': config.messagingSenderId,
        'hasApiKey': config.apiKey.isNotEmpty ? 'true' : 'false',
        'hasAppId': config.appId.isNotEmpty ? 'true' : 'false',
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}
