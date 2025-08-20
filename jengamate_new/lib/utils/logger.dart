import 'package:flutter/foundation.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
// import 'package:firebase_analytics/firebase_analytics.dart';
// import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// Enhanced logger class with analytics and crash reporting integration
class Logger {
  // static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  // static final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;

  /// Log general information messages
  static void log(String message) {
    if (kDebugMode) {
      print('[INFO] $message');
    }
  }

  /// Log errors with optional analytics and crash reporting
  static void logError(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      print('[ERROR] $message');
      if (error != null) {
        print('  [Exception] $error');
      }
      if (stackTrace != null) {
        print('  [StackTrace] $stackTrace');
      }
    }

    // Firebase Crashlytics integration
    try {
      if (error != null) {
        FirebaseCrashlytics.instance.recordError(error, stackTrace, reason: message);
      } else {
        FirebaseCrashlytics.instance.log(message);
      }
    } catch (e) {
      // Silently fail if Firebase is not configured
      if (kDebugMode) {
        print('[CRASHLYTICS_ERROR] $e');
      }
    }
  }

  /// Log user events for analytics
  static void logEvent(String eventName, {Map<String, Object>? parameters}) {
    if (kDebugMode) {
      print('[EVENT] $eventName: $parameters');
    }

    // Firebase Analytics integration
    try {
      FirebaseAnalytics.instance.logEvent(name: eventName, parameters: parameters);
    } catch (e) {
      // Silently fail if Firebase is not configured
      if (kDebugMode) {
        print('[ANALYTICS_ERROR] $e');
      }
    }
  }

  /// Log user properties for analytics
  static void setUserProperty(String name, String value) {
    if (kDebugMode) {
      print('[USER_PROPERTY] $name: $value');
    }

    // Firebase Analytics integration
    try {
      FirebaseAnalytics.instance.setUserProperty(name: name, value: value);
    } catch (e) {
      // Silently fail if Firebase is not configured
      if (kDebugMode) {
        print('[ANALYTICS_ERROR] $e');
      }
    }
  }

  /// Log screen views
  static void logScreenView(String screenName) {
    if (kDebugMode) {
      print('[SCREEN_VIEW] $screenName');
    }

    // Firebase Analytics integration
    try {
      FirebaseAnalytics.instance.logScreenView(screenName: screenName);
    } catch (e) {
      // Silently fail if Firebase is not configured
      if (kDebugMode) {
        print('[ANALYTICS_ERROR] $e');
      }
    }
  }

  /// Log business events
  static void logBusinessEvent(String event, {
    String? userId,
    double? value,
    String? currency,
    Map<String, Object>? additionalParams,
  }) {
    final params = <String, Object>{
      if (userId != null) 'user_id': userId,
      if (value != null) 'value': value,
      if (currency != null) 'currency': currency,
      ...?additionalParams,
    };

    logEvent(event, parameters: params);
  }
}
