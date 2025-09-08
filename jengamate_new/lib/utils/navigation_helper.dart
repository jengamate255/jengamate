import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';

/// Navigation helper utility for common navigation operations
class NavigationHelper {
  /// Logout the current user and navigate to login screen
  static Future<void> logout(BuildContext context) async {
    try {
      final authService = AuthService();
      await authService.signOut();

      if (context.mounted) {
        // Navigate to login screen - adjust route as needed
        context.go('/login');
      }
    } catch (e) {
      debugPrint('Error during logout: $e');
      // Still navigate to login even if logout fails
      if (context.mounted) {
        context.go('/login');
      }
    }
  }

  /// Navigate to a specific route with error handling
  static void navigateTo(BuildContext context, String route) {
    try {
      context.go(route);
    } catch (e) {
      debugPrint('Navigation error: $e');
    }
  }

  /// Navigate back with error handling
  static void goBack(BuildContext context) {
    try {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      } else {
        // Fallback navigation
        context.go('/');
      }
    } catch (e) {
      debugPrint('Go back error: $e');
    }
  }

  /// Show a confirmation dialog before navigation
  static Future<bool?> showConfirmationDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
  }) async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text(cancelText),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text(confirmText),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );
  }
}