import 'dart:async';
import 'package:flutter/material.dart';
import 'package:jengamate/utils/logger.dart';

/// Performance monitoring and optimization service
class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();

  final Map<String, PerformanceMetrics> _metrics = {};
  final Map<String, Completer<void>> _pendingOperations = {};
  final StreamController<PerformanceEvent> _eventController =
      StreamController<PerformanceEvent>.broadcast();

  // Performance thresholds (in milliseconds)
  static const int slowOperationThreshold = 1000; // 1 second
  static const int verySlowOperationThreshold = 5000; // 5 seconds
  static const int memoryWarningThreshold = 100 * 1024 * 1024; // 100MB

  Stream<PerformanceEvent> get events => _eventController.stream;

  /// Start monitoring an operation
  String startOperation(String operationName, [Map<String, dynamic>? metadata]) {
    final operationId = '${operationName}_${DateTime.now().millisecondsSinceEpoch}';
    final startTime = DateTime.now();

    _metrics[operationId] = PerformanceMetrics(
      operationName: operationName,
      startTime: startTime,
      metadata: metadata ?? {},
    );

    _pendingOperations[operationId] = Completer<void>();

    Logger.log('🚀 Started operation: $operationName ($operationId)');
    return operationId;
  }

  /// End monitoring an operation
  void endOperation(String operationId, [Map<String, dynamic>? resultMetadata]) {
    final metrics = _metrics[operationId];
    if (metrics == null) {
      Logger.log('⚠️  Operation not found: $operationId');
      return;
    }

    final endTime = DateTime.now();
    final duration = endTime.difference(metrics.startTime);

    metrics.endTime = endTime;
    metrics.duration = duration;
    if (resultMetadata != null) {
      metrics.metadata.addAll(resultMetadata);
    }

    _pendingOperations[operationId]?.complete();

    // Log performance warnings
    if (duration.inMilliseconds > verySlowOperationThreshold) {
      Logger.log('🐌 Very slow operation: ${metrics.operationName} took ${duration.inMilliseconds}ms');
      _eventController.add(PerformanceEvent(
        type: PerformanceEventType.slowOperation,
        operationId: operationId,
        metrics: metrics,
        message: 'Very slow operation detected',
      ));
    } else if (duration.inMilliseconds > slowOperationThreshold) {
      Logger.log('🐌 Slow operation: ${metrics.operationName} took ${duration.inMilliseconds}ms');
      _eventController.add(PerformanceEvent(
        type: PerformanceEventType.slowOperation,
        operationId: operationId,
        metrics: metrics,
        message: 'Slow operation detected',
      ));
    } else {
      Logger.log('✅ Operation completed: ${metrics.operationName} in ${duration.inMilliseconds}ms');
    }
  }

  /// Monitor memory usage
  void checkMemoryUsage() {
    // Note: Actual memory monitoring would require platform-specific implementations
    // This is a placeholder for future implementation
    Logger.log('📊 Memory usage monitoring not implemented for this platform');
  }

  /// Get performance statistics
  PerformanceStats getStats() {
    final completedOperations = _metrics.values.where((m) => m.endTime != null).toList();
    final slowOperations = completedOperations
        .where((m) => m.duration!.inMilliseconds > slowOperationThreshold)
        .toList();

    return PerformanceStats(
      totalOperations: _metrics.length,
      completedOperations: completedOperations.length,
      slowOperations: slowOperations.length,
      averageDuration: completedOperations.isEmpty
          ? Duration.zero
          : completedOperations.fold<Duration>(
              Duration.zero,
              (sum, m) => sum + (m.duration ?? Duration.zero),
            ) ~/ completedOperations.length,
    );
  }

  /// Clean up old metrics
  void cleanup([Duration maxAge = const Duration(hours: 1)]) {
    final cutoffTime = DateTime.now().subtract(maxAge);
    _metrics.removeWhere((key, metrics) =>
        metrics.endTime != null && metrics.endTime!.isBefore(cutoffTime));

    Logger.log('🧹 Cleaned up old performance metrics');
  }

  /// Dispose of resources
  void dispose() {
    _eventController.close();
    _pendingOperations.clear();
    _metrics.clear();
  }
}

/// Performance metrics data class
class PerformanceMetrics {
  final String operationName;
  final DateTime startTime;
  DateTime? endTime;
  Duration? duration;
  final Map<String, dynamic> metadata;

  PerformanceMetrics({
    required this.operationName,
    required this.startTime,
    required this.metadata,
  });
}

/// Performance event for monitoring
class PerformanceEvent {
  final PerformanceEventType type;
  final String operationId;
  final PerformanceMetrics metrics;
  final String message;
  final DateTime timestamp;

  PerformanceEvent({
    required this.type,
    required this.operationId,
    required this.metrics,
    required this.message,
  }) : timestamp = DateTime.now();
}

/// Performance event types
enum PerformanceEventType {
  slowOperation,
  memoryWarning,
  networkIssue,
  uiFreeze,
}

/// Performance statistics
class PerformanceStats {
  final int totalOperations;
  final int completedOperations;
  final int slowOperations;
  final Duration averageDuration;

  PerformanceStats({
    required this.totalOperations,
    required this.completedOperations,
    required this.slowOperations,
    required this.averageDuration,
  });

  double get slowOperationPercentage =>
      completedOperations > 0 ? (slowOperations / completedOperations) * 100 : 0;
}

/// Performance monitoring extensions
extension PerformanceExtensions<T> on Future<T> {
  /// Monitor this async operation
  Future<T> monitor(String operationName, [Map<String, dynamic>? metadata]) async {
    final monitor = PerformanceMonitor();
    final operationId = monitor.startOperation(operationName, metadata);

    try {
      final result = await this;
      monitor.endOperation(operationId, {'success': true});
      return result;
    } catch (error, stackTrace) {
      monitor.endOperation(operationId, {
        'success': false,
        'error': error.toString(),
        'hasStackTrace': true,
      });
      rethrow;
    }
  }
}

/// Performance optimization utilities
class PerformanceOptimizer {
  /// Debounce function calls
  static Function debounce(Function func, Duration delay) {
    Timer? timer;
    return () {
      timer?.cancel();
      timer = Timer(delay, () => func());
    };
  }

  /// Throttle function calls
  static Function throttle(Function func, Duration delay) {
    bool canCall = true;
    return () {
      if (canCall) {
        func();
        canCall = false;
        Timer(delay, () => canCall = true);
      }
    };
  }

  /// Memoize expensive computations
  static Map<String, dynamic> _cache = {};
  static T memoize<T>(String key, T Function() computation) {
    if (_cache.containsKey(key)) {
      return _cache[key] as T;
    }

    final result = computation();
    _cache[key] = result;
    return result;
  }

  /// Clear memoization cache
  static void clearCache() {
    _cache.clear();
  }

  /// Batch multiple async operations
  static Future<List<T>> batch<T>(List<Future<T>> futures, {int concurrency = 5}) async {
    final results = <T>[];
    final chunks = _chunkList(futures, concurrency);

    for (final chunk in chunks) {
      final chunkResults = await Future.wait(chunk);
      results.addAll(chunkResults);
    }

    return results;
  }

  static List<List<T>> _chunkList<T>(List<T> list, int chunkSize) {
    final chunks = <List<T>>[];
    for (var i = 0; i < list.length; i += chunkSize) {
      final end = (i + chunkSize < list.length) ? i + chunkSize : list.length;
      chunks.add(list.sublist(i, end));
    }
    return chunks;
  }
}

/// Image performance optimizations
class ImagePerformanceOptimizer {
  /// Get optimal image dimensions based on device pixel ratio
  static Size getOptimalImageSize(BuildContext context, Size originalSize) {
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;
    return Size(
      originalSize.width * pixelRatio,
      originalSize.height * pixelRatio,
    );
  }

  /// Generate responsive image URLs
  static String getResponsiveImageUrl(String baseUrl, BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;

    // Determine image size based on screen width and pixel ratio
    String size = 'small';
    if (screenSize.width > 1200 || pixelRatio > 2.5) {
      size = 'large';
    } else if (screenSize.width > 600 || pixelRatio > 2.0) {
      size = 'medium';
    }

    return '$baseUrl?size=$size';
  }

  /// Preload critical images
  static void preloadCriticalImages(List<String> imageUrls) {
    for (final url in imageUrls) {
      // In a real implementation, this would use platform-specific APIs
      // For now, just log the intent
      Logger.log('📸 Would preload image: $url');
    }
  }
}

/// UI performance optimizations
class UiPerformanceOptimizer {
  /// Create efficient list items with proper keys
  static Widget createOptimizedListItem<T>({
    required T item,
    required Widget Function(T) itemBuilder,
    required Object Function(T) keyExtractor,
  }) {
    return Builder(
      key: ValueKey(keyExtractor(item)),
      builder: (context) => itemBuilder(item),
    );
  }

  /// Wrap widgets with RepaintBoundary for performance
  static Widget withRepaintBoundary(Widget child, {String? debugLabel}) {
    return RepaintBoundary(
      child: child,
    );
  }

  /// Create const widgets where possible
  static Widget createConstIfPossible(Widget child, bool canBeConst) {
    return canBeConst ? child : child;
  }

  /// Optimize scroll performance
  static Widget createOptimizedScrollView({
    required List<Widget> children,
    ScrollPhysics? physics,
    bool addAutomaticKeepAlives = true,
    bool addRepaintBoundaries = true,
    bool addSemanticIndexes = true,
  }) {
    return ListView(
      physics: physics,
      children: children.map((child) {
        Widget optimizedChild = child;

        if (addRepaintBoundaries) {
          optimizedChild = withRepaintBoundary(optimizedChild);
        }

        if (addAutomaticKeepAlives) {
          optimizedChild = AutomaticKeepAlive(
            child: optimizedChild,
          );
        }

        return optimizedChild;
      }).toList(),
    );
  }
}
