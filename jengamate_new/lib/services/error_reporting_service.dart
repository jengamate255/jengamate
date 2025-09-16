import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/logger.dart';

/// Comprehensive error reporting service for advanced monitoring and debugging
class ErrorReportingService {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _errorLogsTable = 'error_logs';
  static const String _performanceLogsTable = 'performance_logs';

  static final ErrorReportingService _instance = ErrorReportingService._internal();
  factory ErrorReportingService() => _instance;
  ErrorReportingService._internal();

  Map<String, dynamic>? _deviceInfo;
  Map<String, dynamic>? _appInfo;

  /// Initialize the error reporting service
  Future<void> initialize() async {
    try {
      await _collectDeviceInfo();
      await _collectAppInfo();
      Logger.log('Error reporting service initialized');
    } catch (e, stackTrace) {
      Logger.logError('Failed to initialize error reporting service', e, stackTrace);
    }
  }

  /// Collect device information for error reports
  Future<void> _collectDeviceInfo() async {
    try {
      _deviceInfo = {
        'platform': kIsWeb ? 'web' : 'mobile',
        'is_web': kIsWeb,
      };
    } catch (e) {
      _deviceInfo = {'error': 'Failed to collect device info: $e'};
    }
  }

  /// Collect app information for error reports
  Future<void> _collectAppInfo() async {
    try {
      _appInfo = {
        'app_name': 'JengaMate',
        'version': '1.0.0',
        'environment': 'development',
      };
    } catch (e) {
      _appInfo = {'error': 'Failed to collect app info: $e'};
    }
  }

  /// Report a general error with comprehensive context
  Future<String?> reportError({
    required String error,
    required String context,
    String? userId,
    String? sessionId,
    StackTrace? stackTrace,
    Map<String, dynamic>? additionalData,
    ErrorSeverity severity = ErrorSeverity.medium,
    ErrorCategory category = ErrorCategory.general,
  }) async {
    try {
      final errorId = _generateErrorId();

      final errorData = {
        'id': errorId,
        'error_message': error,
        'context': context,
        'severity': severity.name,
        'category': category.name,
        'user_id': userId ?? fb_auth.FirebaseAuth.instance.currentUser?.uid,
        'session_id': sessionId,
        'stack_trace': stackTrace?.toString(),
        'device_info': _deviceInfo,
        'app_info': _appInfo,
        'additional_data': additionalData,
        'timestamp': DateTime.now().toIso8601String(),
        'platform': kIsWeb ? 'web' : 'mobile',
        'environment': kDebugMode ? 'debug' : 'production',
      };

      await _supabase.from(_errorLogsTable).insert(errorData);

      Logger.log('Error reported with ID: $errorId');
      return errorId;
    } catch (e, stackTrace) {
      Logger.logError('Failed to report error', e, stackTrace);
      return null;
    }
  }

  /// Report a payment-specific error
  Future<String?> reportPaymentError({
    required String paymentId,
    required String error,
    required PaymentErrorType errorType,
    String? userId,
    String? orderId,
    StackTrace? stackTrace,
    Map<String, dynamic>? paymentData,
    Map<String, dynamic>? additionalContext,
  }) async {
    return reportError(
      error: error,
      context: 'payment_processing',
      userId: userId,
      stackTrace: stackTrace,
      additionalData: {
        'payment_id': paymentId,
        'order_id': orderId,
        'error_type': errorType.name,
        'payment_data': paymentData,
        'processing_context': additionalContext,
      },
      severity: _getPaymentErrorSeverity(errorType),
      category: ErrorCategory.payment,
    );
  }

  /// Report a file upload error
  Future<String?> reportUploadError({
    required String fileName,
    required String bucket,
    required String error,
    String? userId,
    int? fileSize,
    String? mimeType,
    StackTrace? stackTrace,
    Map<String, dynamic>? uploadContext,
  }) async {
    return reportError(
      error: error,
      context: 'file_upload',
      userId: userId,
      stackTrace: stackTrace,
      additionalData: {
        'file_name': fileName,
        'bucket': bucket,
        'file_size': fileSize,
        'mime_type': mimeType,
        'upload_context': uploadContext,
      },
      severity: ErrorSeverity.medium,
      category: ErrorCategory.storage,
    );
  }

  /// Report performance metrics
  Future<void> reportPerformance({
    required String operation,
    required Duration duration,
    String? userId,
    Map<String, dynamic>? metadata,
    PerformanceCategory category = PerformanceCategory.general,
  }) async {
    try {
      final performanceData = {
        'operation': operation,
        'duration_ms': duration.inMilliseconds,
        'category': category.name,
        'user_id': userId ?? fb_auth.FirebaseAuth.instance.currentUser?.uid,
        'metadata': metadata,
        'device_info': _deviceInfo,
        'app_info': _appInfo,
        'timestamp': DateTime.now().toIso8601String(),
        'platform': kIsWeb ? 'web' : 'mobile',
      };

      await _supabase.from(_performanceLogsTable).insert(performanceData);
    } catch (e, stackTrace) {
      Logger.logError('Failed to report performance metrics', e, stackTrace);
    }
  }

  /// Report payment performance metrics
  Future<void> reportPaymentPerformance({
    required String paymentId,
    required String operation,
    required Duration duration,
    String? userId,
    Map<String, dynamic>? performanceData,
  }) async {
    await reportPerformance(
      operation: 'payment_$operation',
      duration: duration,
      userId: userId,
      metadata: {
        'payment_id': paymentId,
        ...?performanceData,
      },
      category: PerformanceCategory.payment,
    );
  }

  /// Get error statistics for monitoring
  Future<Map<String, dynamic>> getErrorStatistics({
    DateTime? startDate,
    DateTime? endDate,
    String? userId,
    ErrorCategory? category,
    ErrorSeverity? severity,
  }) async {
    try {
      var query = _supabase.from(_errorLogsTable).select();

      if (startDate != null) {
        query = query.gte('timestamp', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('timestamp', endDate.toIso8601String());
      }
      if (userId != null) {
        query = query.eq('user_id', userId);
      }
      if (category != null) {
        query = query.eq('category', category.name);
      }
      if (severity != null) {
        query = query.eq('severity', severity.name);
      }

      final errors = await query;
      final errorCount = errors.length;

      // Group by error type
      final errorTypes = <String, int>{};
      for (final error in errors) {
        final context = error['context'] as String? ?? 'unknown';
        errorTypes[context] = (errorTypes[context] ?? 0) + 1;
      }

      // Group by severity
      final severityCount = <String, int>{};
      for (final error in errors) {
        final sev = error['severity'] as String? ?? 'unknown';
        severityCount[sev] = (severityCount[sev] ?? 0) + 1;
      }

      return {
        'total_errors': errorCount,
        'errors_by_context': errorTypes,
        'errors_by_severity': severityCount,
        'period': {
          'start': startDate?.toIso8601String(),
          'end': endDate?.toIso8601String(),
        },
      };
    } catch (e, stackTrace) {
      Logger.logError('Failed to get error statistics', e, stackTrace);
      return {'error': 'Failed to retrieve statistics'};
    }
  }

  /// Get performance statistics
  Future<Map<String, dynamic>> getPerformanceStatistics({
    DateTime? startDate,
    DateTime? endDate,
    String? userId,
    PerformanceCategory? category,
  }) async {
    try {
      var query = _supabase.from(_performanceLogsTable).select();

      if (startDate != null) {
        query = query.gte('timestamp', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('timestamp', endDate.toIso8601String());
      }
      if (userId != null) {
        query = query.eq('user_id', userId);
      }
      if (category != null) {
        query = query.eq('category', category.name);
      }

      final metrics = await query;

      if (metrics.isEmpty) {
        return {'message': 'No performance data available'};
      }

      // Calculate statistics
      final durations = metrics.map((m) => m['duration_ms'] as int).toList();
      durations.sort();

      final avgDuration = durations.reduce((a, b) => a + b) / durations.length;
      final minDuration = durations.first;
      final maxDuration = durations.last;
      final medianDuration = durations[durations.length ~/ 2];

      // Group by operation
      final operations = <String, Map<String, dynamic>>{};
      for (final metric in metrics) {
        final operation = metric['operation'] as String;
        if (!operations.containsKey(operation)) {
          operations[operation] = {
            'count': 0,
            'total_duration': 0,
            'avg_duration': 0,
            'min_duration': double.infinity,
            'max_duration': 0,
          };
        }

        final opData = operations[operation]!;
        final duration = metric['duration_ms'] as int;

        opData['count'] = opData['count'] + 1;
        opData['total_duration'] = opData['total_duration'] + duration;
        opData['min_duration'] = duration < opData['min_duration'] ? duration : opData['min_duration'];
        opData['max_duration'] = duration > opData['max_duration'] ? duration : opData['max_duration'];
        opData['avg_duration'] = opData['total_duration'] / opData['count'];
      }

      return {
        'total_operations': metrics.length,
        'overall_stats': {
          'avg_duration_ms': avgDuration,
          'min_duration_ms': minDuration,
          'max_duration_ms': maxDuration,
          'median_duration_ms': medianDuration,
        },
        'operations': operations,
        'period': {
          'start': startDate?.toIso8601String(),
          'end': endDate?.toIso8601String(),
        },
      };
    } catch (e, stackTrace) {
      Logger.logError('Failed to get performance statistics', e, stackTrace);
      return {'error': 'Failed to retrieve performance statistics'};
    }
  }

  /// Generate unique error ID
  String _generateErrorId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecondsSinceEpoch % 10000;
    return 'ERR_${timestamp}_$random';
  }

  /// Get severity level for payment errors
  ErrorSeverity _getPaymentErrorSeverity(PaymentErrorType errorType) {
    switch (errorType) {
      case PaymentErrorType.proofUploadFailed:
        return ErrorSeverity.medium;
      case PaymentErrorType.validationFailed:
      case PaymentErrorType.databaseError:
        return ErrorSeverity.high;
      case PaymentErrorType.orderNotFound:
      case PaymentErrorType.userNotFound:
        return ErrorSeverity.critical;
      case PaymentErrorType.unexpectedError:
        return ErrorSeverity.critical;
      default:
        return ErrorSeverity.medium;
    }
  }

  /// Clean up old error logs (admin function)
  Future<int> cleanupOldLogs({int daysToKeep = 90}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));

      final deletedErrors = await _supabase
          .from(_errorLogsTable)
          .delete()
          .lt('timestamp', cutoffDate.toIso8601String())
          .select('count');

      final deletedPerformance = await _supabase
          .from(_performanceLogsTable)
          .delete()
          .lt('timestamp', cutoffDate.toIso8601String())
          .select('count');

      final totalDeleted = (deletedErrors as List).length + (deletedPerformance as List).length;

      Logger.log('Cleaned up $totalDeleted old log entries');
      return totalDeleted;
    } catch (e, stackTrace) {
      Logger.logError('Failed to cleanup old logs', e, stackTrace);
      return 0;
    }
  }
}

/// Enums for error reporting
enum ErrorSeverity {
  low,
  medium,
  high,
  critical,
}

enum ErrorCategory {
  general,
  payment,
  storage,
  network,
  authentication,
  validation,
  database,
}

enum PerformanceCategory {
  general,
  payment,
  storage,
  ui,
  network,
}

/// Payment-specific error types
enum PaymentErrorType {
  validationFailed,
  proofUploadFailed,
  databaseError,
  orderNotFound,
  userNotFound,
  unexpectedError,
}
