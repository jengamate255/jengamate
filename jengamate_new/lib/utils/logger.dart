import 'package:flutter/foundation.dart';

// A simple logger class to wrap print statements.
class Logger {
  static void log(String message) {
    if (kDebugMode) {
      print('[INFO] $message');
    }
  }

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
  }
}
