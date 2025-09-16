import 'package:flutter/material.dart';
import 'package:jengamate/core/error_handling/app_exceptions.dart';
import 'package:jengamate/ui/shared_components/confirmation_dialog.dart';
import 'package:jengamate/utils/logger.dart';

/// Error boundary widget that catches and handles errors in the widget tree
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget? errorWidget;
  final void Function(Object error, StackTrace? stackTrace)? onError;
  final bool showErrorDialog;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.errorWidget,
    this.onError,
    this.showErrorDialog = true,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;
  StackTrace? _stackTrace;

  @override
  void initState() {
    super.initState();
    // Catch any errors that occur during widget building
    ErrorWidget.builder = (FlutterErrorDetails details) {
      _handleError(details.exception, details.stack);
      return _buildErrorWidget(details.exception);
    };
  }

  void _handleError(Object error, StackTrace? stackTrace) {
    _error = error;
    _stackTrace = stackTrace;

    // Log the error
    Logger.logError('Error caught by ErrorBoundary', error, stackTrace);

    // Call custom error handler if provided
    widget.onError?.call(error, stackTrace);

    // Show error dialog if enabled
    if (widget.showErrorDialog && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showErrorDialog(error);
      });
    }

    setState(() {});
  }

  void _showErrorDialog(Object error) {
    final message = error is AppException
      ? error.message
      : 'An unexpected error occurred. Please try again.';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(Object error) {
    if (widget.errorWidget != null) {
      return widget.errorWidget!;
    }

    final message = error is AppException
      ? error.message
      : 'Something went wrong. Please try again.';

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 48,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _error = null;
                _stackTrace = null;
              });
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return _buildErrorWidget(_error!);
    }

    // Wrap child in error handling
    return Builder(
      builder: (context) {
        try {
          return widget.child;
        } catch (error, stackTrace) {
          _handleError(error, stackTrace);
          return _buildErrorWidget(error);
        }
      },
    );
  }
}

/// Error handling utility functions
class ErrorHandler {
  static String getErrorMessage(Object error) {
    if (error is AppException) {
      return error.message;
    }

    // Handle common Firebase errors
    if (error.toString().contains('permission-denied')) {
      return 'You do not have permission to perform this action.';
    }

    if (error.toString().contains('not-found')) {
      return 'The requested item was not found.';
    }

    if (error.toString().contains('already-exists')) {
      return 'This item already exists.';
    }

    if (error.toString().contains('network-request-failed')) {
      return 'Network error. Please check your connection and try again.';
    }

    // Default error message
    return 'An unexpected error occurred. Please try again.';
  }

  static bool isRetryableError(Object error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('network') ||
           errorString.contains('timeout') ||
           errorString.contains('connection');
  }

  static void logError(Object error, [StackTrace? stackTrace]) {
    Logger.logError('Application Error', error, stackTrace);
  }
}

/// Extension methods for handling errors in async operations
extension ErrorHandlingExtension<T> on Future<T> {
  Future<T> handleError({
    String? customMessage,
    bool showDialog = true,
    BuildContext? context,
  }) async {
    try {
      return await this;
    } catch (error, stackTrace) {
      ErrorHandler.logError(error, stackTrace);

      if (showDialog && context != null) {
        final message = customMessage ?? ErrorHandler.getErrorMessage(error);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            action: ErrorHandler.isRetryableError(error)
              ? SnackBarAction(
                  label: 'Retry',
                  onPressed: () {
                    // Could implement retry logic here
                  },
                )
              : null,
          ),
        );
      }

      rethrow;
    }
  }
}
