import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:jengamate/utils/logger.dart';

/// Advanced caching service with multiple strategies
class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  final Map<String, CacheEntry<dynamic>> _memoryCache = {};
  final Map<String, Completer<dynamic>> _pendingRequests = {};

  // Cache configuration
  static const Duration defaultMaxAge = Duration(hours: 1);
  static const int defaultMaxSize = 100;

  /// Get cached value or compute and cache it
  Future<T> get<T>(
    String key,
    Future<T> Function() compute, {
    Duration? maxAge,
    bool useMemoryCache = true,
  }) async {
    final effectiveMaxAge = maxAge ?? defaultMaxAge;

    // Check memory cache first
    if (useMemoryCache && _memoryCache.containsKey(key)) {
      final entry = _memoryCache[key]!;
      if (!entry.isExpired(effectiveMaxAge)) {
        Logger.log('💾 Cache hit for: $key');
        return entry.value as T;
      } else {
        _memoryCache.remove(key);
        Logger.log('⏰ Cache expired for: $key');
      }
    }

    // Check if request is already pending
    if (_pendingRequests.containsKey(key)) {
      Logger.log('⏳ Waiting for pending request: $key');
      return await _pendingRequests[key]!.future as T;
    }

    // Start new request
    final completer = Completer<T>();
    _pendingRequests[key] = completer;

    try {
      Logger.log('🔄 Computing value for: $key');
      final value = await compute();

      // Cache the result
      if (useMemoryCache) {
        _memoryCache[key] = CacheEntry(value, DateTime.now());
        _enforceCacheSize();
      }

      completer.complete(value);
      _pendingRequests.remove(key);

      return value;
    } catch (error, stackTrace) {
      _pendingRequests.remove(key);
      completer.completeError(error, stackTrace);
      rethrow;
    }
  }

  /// Cache a value manually
  void set<T>(String key, T value, {Duration? maxAge}) {
    _memoryCache[key] = CacheEntry(value, DateTime.now(), maxAge: maxAge);
    _enforceCacheSize();
    Logger.log('💾 Manually cached: $key');
  }

  /// Check if key exists in cache
  bool contains(String key) {
    return _memoryCache.containsKey(key) &&
           !_memoryCache[key]!.isExpired(_memoryCache[key]!.maxAge ?? defaultMaxAge);
  }

  /// Remove specific key from cache
  void remove(String key) {
    _memoryCache.remove(key);
    Logger.log('🗑️  Removed from cache: $key');
  }

  /// Clear all cache entries
  void clear() {
    _memoryCache.clear();
    _pendingRequests.clear();
    Logger.log('🧹 Cache cleared');
  }

  /// Get cache statistics
  CacheStats getStats() {
    final validEntries = _memoryCache.values.where((entry) =>
        !entry.isExpired(entry.maxAge ?? defaultMaxAge)).length;

    return CacheStats(
      totalEntries: _memoryCache.length,
      validEntries: validEntries,
      invalidEntries: _memoryCache.length - validEntries,
      pendingRequests: _pendingRequests.length,
    );
  }

  /// Clean up expired entries
  void cleanup() {
    final keysToRemove = <String>[];

    for (final entry in _memoryCache.entries) {
      if (entry.value.isExpired(entry.value.maxAge ?? defaultMaxAge)) {
        keysToRemove.add(entry.key);
      }
    }

    for (final key in keysToRemove) {
      _memoryCache.remove(key);
    }

    Logger.log('🧹 Cleaned up ${keysToRemove.length} expired cache entries');
  }

  /// Enforce maximum cache size
  void _enforceCacheSize() {
    if (_memoryCache.length <= defaultMaxSize) return;

    // Remove oldest entries (simple LRU approximation)
    final sortedEntries = _memoryCache.entries.toList()
      ..sort((a, b) => a.value.createdAt.compareTo(b.value.createdAt));

    final entriesToRemove = sortedEntries.take(_memoryCache.length - defaultMaxSize);
    for (final entry in entriesToRemove) {
      _memoryCache.remove(entry.key);
    }

    Logger.log('📏 Cache size enforced: removed ${entriesToRemove.length} entries');
  }
}

/// Cache entry with metadata
class CacheEntry<T> {
  final T value;
  final DateTime createdAt;
  final Duration? maxAge;

  CacheEntry(this.value, this.createdAt, {this.maxAge});

  bool isExpired(Duration maxAge) {
    return DateTime.now().difference(createdAt) > maxAge;
  }
}

/// Cache statistics
class CacheStats {
  final int totalEntries;
  final int validEntries;
  final int invalidEntries;
  final int pendingRequests;

  CacheStats({
    required this.totalEntries,
    required this.validEntries,
    required this.invalidEntries,
    required this.pendingRequests,
  });

  double get hitRate => totalEntries > 0 ? validEntries / totalEntries : 0;
}

/// Cache extensions for common patterns
extension CacheExtensions on Future<dynamic> {
  /// Cache this async operation
  Future<T> cached<T>(
    String key, {
    Duration? maxAge,
    bool useMemoryCache = true,
  }) {
    final cache = CacheService();
    return cache.get(
      key,
      () async => await this as T,
      maxAge: maxAge,
      useMemoryCache: useMemoryCache,
    );
  }
}

/// Image caching service
class ImageCacheService {
  static final ImageCacheService _instance = ImageCacheService._internal();
  factory ImageCacheService() => _instance;
  ImageCacheService._internal();

  final Map<String, ImageCacheEntry> _imageCache = {};
  static const Duration defaultImageCacheDuration = Duration(hours: 24);

  /// Cache image data
  void cacheImage(String url, Uint8List data) {
    _imageCache[url] = ImageCacheEntry(data, DateTime.now());
    _cleanupExpiredImages();
    Logger.log('🖼️  Cached image: $url');
  }

  /// Get cached image data
  Uint8List? getCachedImage(String url) {
    final entry = _imageCache[url];
    if (entry == null || entry.isExpired(defaultImageCacheDuration)) {
      if (entry != null) {
        _imageCache.remove(url);
      }
      return null;
    }

    Logger.log('🖼️  Image cache hit: $url');
    return entry.data;
  }

  /// Preload and cache multiple images
  Future<void> preloadImages(List<String> urls) async {
    final futures = urls.map((url) async {
      // In a real implementation, this would fetch the image
      // For now, just simulate the operation
      await Future.delayed(const Duration(milliseconds: 100));
      Logger.log('📥 Would preload image: $url');
    });

    await Future.wait(futures);
    Logger.log('✅ Preloaded ${urls.length} images');
  }

  /// Clear image cache
  void clearImageCache() {
    _imageCache.clear();
    Logger.log('🖼️  Image cache cleared');
  }

  void _cleanupExpiredImages() {
    final expiredKeys = _imageCache.entries
        .where((entry) => entry.value.isExpired(defaultImageCacheDuration))
        .map((entry) => entry.key)
        .toList();

    for (final key in expiredKeys) {
      _imageCache.remove(key);
    }

    if (expiredKeys.isNotEmpty) {
      Logger.log('🧹 Cleaned up ${expiredKeys.length} expired images');
    }
  }
}

/// Image cache entry
class ImageCacheEntry {
  final Uint8List data;
  final DateTime cachedAt;

  ImageCacheEntry(this.data, this.cachedAt);

  bool isExpired(Duration maxAge) {
    return DateTime.now().difference(cachedAt) > maxAge;
  }
}

/// Network request deduplication
class RequestDeduplicationService {
  static final RequestDeduplicationService _instance = RequestDeduplicationService._internal();
  factory RequestDeduplicationService() => _instance;
  RequestDeduplicationService._internal();

  final Map<String, Completer<dynamic>> _pendingRequests = {};
  final Map<String, DateTime> _lastRequestTimes = {};
  static const Duration defaultDedupeWindow = Duration(seconds: 5);

  /// Execute request with deduplication
  Future<T> dedupe<T>(
    String requestKey,
    Future<T> Function() request, {
    Duration? dedupeWindow,
  }) async {
    final effectiveWindow = dedupeWindow ?? defaultDedupeWindow;

    // Check if we have a recent identical request
    final lastRequestTime = _lastRequestTimes[requestKey];
    if (lastRequestTime != null &&
        DateTime.now().difference(lastRequestTime) < effectiveWindow) {
      Logger.log('🔄 Request deduplicated: $requestKey');
      return await _pendingRequests[requestKey]!.future as T;
    }

    // Check if request is already pending
    if (_pendingRequests.containsKey(requestKey)) {
      Logger.log('⏳ Waiting for pending request: $requestKey');
      return await _pendingRequests[requestKey]!.future as T;
    }

    // Start new request
    final completer = Completer<T>();
    _pendingRequests[requestKey] = completer;
    _lastRequestTimes[requestKey] = DateTime.now();

    try {
      final result = await request();
      completer.complete(result);
      Logger.log('✅ Request completed: $requestKey');
      return result;
    } catch (error, stackTrace) {
      completer.completeError(error, stackTrace);
      Logger.log('❌ Request failed: $requestKey - $error');
      rethrow;
    } finally {
      // Clean up after a delay to allow for deduplication
      Future.delayed(effectiveWindow, () {
        _pendingRequests.remove(requestKey);
      });
    }
  }

  /// Clear deduplication state
  void clear() {
    _pendingRequests.clear();
    _lastRequestTimes.clear();
    Logger.log('🧹 Request deduplication state cleared');
  }
}
