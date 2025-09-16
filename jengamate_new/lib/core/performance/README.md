# Performance Optimization System

This directory contains comprehensive performance monitoring, optimization, and caching systems for JengaMate, designed to ensure smooth user experience and efficient resource utilization.

## 📁 Structure

### `performance_monitor.dart`
Advanced performance monitoring and optimization service
- Real-time operation tracking
- Performance thresholds and alerting
- Memory usage monitoring
- UI performance optimizations

### `cache_service.dart`
Multi-layered caching system with various strategies
- Memory caching with TTL
- Image caching for media assets
- Request deduplication
- Cache statistics and cleanup

## 🔧 Key Features

### Performance Monitoring

#### Operation Tracking
```dart
// Monitor any async operation
final result = await myAsyncOperation.monitor('database_query');
```

#### Performance Alerts
```dart
// Automatic alerts for slow operations
PerformanceMonitor().events.listen((event) {
  if (event.type == PerformanceEventType.slowOperation) {
    // Handle slow operation alert
    sendPerformanceAlert(event);
  }
});
```

#### Performance Statistics
```dart
// Get comprehensive performance stats
final stats = PerformanceMonitor().getStats();
print('Slow operations: ${stats.slowOperationPercentage}%');
```

### Caching System

#### Memory Caching
```dart
// Cache expensive computations
final user = await CacheService().get(
  'user_${userId}',
  () => databaseService.getUser(userId),
  maxAge: Duration(hours: 1),
);
```

#### Request Deduplication
```dart
// Prevent duplicate network requests
final data = await RequestDeduplicationService().dedupe(
  'products_list',
  () => apiService.getProducts(),
);
```

#### Image Caching
```dart
// Cache images for better performance
ImageCacheService().cacheImage(imageUrl, imageData);
final cachedImage = ImageCacheService().getCachedImage(imageUrl);
```

### Performance Optimizations

#### Function Debouncing
```dart
// Debounce search queries
final debouncedSearch = PerformanceOptimizer.debounce(
  () => performSearch(query),
  Duration(milliseconds: 300),
);
```

#### Function Throttling
```dart
// Throttle scroll events
final throttledScroll = PerformanceOptimizer.throttle(
  () => handleScroll(),
  Duration(milliseconds: 100),
);
```

#### Memoization
```dart
// Cache expensive computations
final result = PerformanceOptimizer.memoize(
  'computation_key',
  () => expensiveComputation(),
);
```

#### Batch Operations
```dart
// Execute multiple operations efficiently
final results = await PerformanceOptimizer.batch(
  futures,
  concurrency: 3,
);
```

## 📖 Usage Examples

### Monitoring Service Operations
```dart
class DatabaseService {
  Future<List<Product>> getProducts() async {
    return await _firestore.collection('products').get()
        .monitor('get_products'); // Automatic monitoring
  }
}
```

### Caching Database Queries
```dart
class ProductService {
  Future<Product> getProduct(String id) async {
    return await CacheService().get(
      'product_$id',
      () => _databaseService.getProduct(id),
      maxAge: Duration(minutes: 30),
    );
  }
}
```

### Optimizing Image Loading
```dart
class ImageWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final imageUrl = ImagePerformanceOptimizer.getResponsiveImageUrl(
      baseUrl,
      context,
    );

    return CachedNetworkImage(
      imageUrl: imageUrl,
      cacheManager: customCacheManager,
    );
  }
}
```

### UI Performance Optimization
```dart
class OptimizedList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return UiPerformanceOptimizer.createOptimizedScrollView(
      children: items.map((item) {
        return UiPerformanceOptimizer.createOptimizedListItem(
          item: item,
          itemBuilder: (item) => ProductCard(item),
          keyExtractor: (item) => item.id,
        );
      }).toList(),
      addRepaintBoundaries: true,
      addAutomaticKeepAlives: true,
    );
  }
}
```

## 🔧 Configuration

### Performance Thresholds
```dart
// Customize performance thresholds
class CustomPerformanceMonitor extends PerformanceMonitor {
  @override
  static const int slowOperationThreshold = 2000; // 2 seconds
  @override
  static const int verySlowOperationThreshold = 10000; // 10 seconds
}
```

### Cache Configuration
```dart
// Configure cache settings
CacheService.defaultMaxAge = Duration(hours: 2);
CacheService.defaultMaxSize = 200;
```

## 📊 Monitoring & Analytics

### Performance Dashboard
```dart
class PerformanceDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final monitor = PerformanceMonitor();
    final cache = CacheService();
    final stats = monitor.getStats();
    final cacheStats = cache.getStats();

    return Column(
      children: [
        Text('Total Operations: ${stats.totalOperations}'),
        Text('Slow Operations: ${stats.slowOperations}'),
        Text('Cache Hit Rate: ${(cacheStats.hitRate * 100).round()}%'),
        // ... more metrics
      ],
    );
  }
}
```

### Error Tracking Integration
```dart
// Integrate with error tracking
PerformanceMonitor().events.listen((event) {
  if (event.type == PerformanceEventType.slowOperation) {
    // Send to error tracking service
    errorTrackingService.trackPerformanceIssue(
      operation: event.metrics.operationName,
      duration: event.metrics.duration?.inMilliseconds ?? 0,
    );
  }
});
```

## 🚀 Advanced Features

### Custom Performance Metrics
```dart
class CustomMetricsCollector {
  static void trackCustomMetric(String name, Map<String, dynamic> data) {
    final monitor = PerformanceMonitor();
    final operationId = monitor.startOperation('custom_$name', data);
    // ... perform operation
    monitor.endOperation(operationId, {'custom_result': 'success'});
  }
}
```

### Performance Testing
```dart
class PerformanceTestSuite {
  static Future<void> runPerformanceTests() async {
    final monitor = PerformanceMonitor();

    // Test database operations
    await _testDatabasePerformance(monitor);

    // Test caching effectiveness
    await _testCachePerformance();

    // Generate performance report
    final stats = monitor.getStats();
    _generatePerformanceReport(stats);
  }
}
```

### Memory Management
```dart
class MemoryManager {
  static void optimizeMemoryUsage() {
    // Clear expired cache entries
    CacheService().cleanup();

    // Clear image cache if needed
    ImageCacheService().clearImageCache();

    // Force garbage collection hint
    // (Note: This is platform-specific)
  }
}
```

## 🧪 Testing

Performance systems include:
- **Unit tests** for individual optimizers
- **Integration tests** for cache effectiveness
- **Performance benchmarks** for operation timing
- **Memory leak tests** for resource management

## 📋 Best Practices

### Monitoring
- Monitor key operations regularly
- Set up alerts for performance degradation
- Track performance trends over time
- Use A/B testing for optimization validation

### Caching
- Cache expensive operations appropriately
- Set reasonable TTL values
- Monitor cache hit rates
- Implement cache invalidation strategies

### Optimization
- Profile before optimizing
- Focus on bottlenecks first
- Measure impact of optimizations
- Balance performance with code complexity

### Memory Management
- Avoid memory leaks in cached data
- Implement proper cleanup mechanisms
- Monitor memory usage patterns
- Use weak references when appropriate

## 🔄 Integration

### With Error Handling
```dart
// Combine performance monitoring with error handling
try {
  final result = await expensiveOperation.monitor('expensive_op');
  return result;
} catch (error) {
  ErrorHandler.logError(error);
  throw AppExceptions.serverError();
}
```

### With Analytics
```dart
// Track performance in analytics
PerformanceMonitor().events.listen((event) {
  analyticsService.trackEvent(
    'performance_metric',
    properties: {
      'operation': event.metrics.operationName,
      'duration_ms': event.metrics.duration?.inMilliseconds,
      'success': event.metrics.metadata['success'] ?? false,
    },
  );
});
```

This performance optimization system provides comprehensive monitoring, caching, and optimization capabilities to ensure JengaMate delivers a smooth, responsive user experience across all devices and network conditions.
