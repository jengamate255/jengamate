import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// Console Error Handler - Logs errors to console instead of UI popups
class ConsoleErrorHandler {
  /// Log error to console with full details
  static void logError(String message, Object error, [StackTrace? stackTrace]) {
    if (kDebugMode) {
      developer.log(
        '🐛 ERROR: $message',
        error: error,
        stackTrace: stackTrace,
        level: 900,
        name: 'ConsoleErrorHandler',
      );
      if (stackTrace != null) {
        developer.log(
          '📚 Stack Trace: ${stackTrace.toString()}',
          level: 800,
          name: 'ConsoleErrorHandler',
        );
      }
    } else {
      debugPrint('🐛 ERROR: $message caused by: $error');
      if (stackTrace != null) {
        debugPrint('📚 Stack Trace: $stackTrace');
      }
    }
  }

  /// Log warning to console
  static void logWarning(String message) {
    if (kDebugMode) {
      developer.log(
        '⚠️ WARNING: $message',
        level: 700,
        name: 'ConsoleErrorHandler',
      );
    } else {
      debugPrint('⚠️ WARNING: $message');
    }
  }

  /// Log info message to console
  static void logInfo(String message) {
    if (kDebugMode) {
      developer.log(
        'ℹ️ INFO: $message',
        level: 500,
        name: 'ConsoleErrorHandler',
      );
    } else {
      debugPrint('ℹ️ INFO: $message');
    }
  }

  /// Log success message to console
  static void logSuccess(String message) {
    if (kDebugMode) {
      developer.log(
        '✅ SUCCESS: $message',
        level: 300,
        name: 'ConsoleErrorHandler',
      );
    } else {
      debugPrint('✅ SUCCESS: $message');
    }
  }
}
