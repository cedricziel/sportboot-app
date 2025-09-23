import 'dart:async';
import 'package:flutter/foundation.dart';

/// A simple in-memory cache service for database query results
class CacheService {
  static const Duration defaultCacheDuration = Duration(minutes: 5);

  final Map<String, _CacheEntry> _cache = {};
  final Duration _defaultDuration;
  Timer? _cleanupTimer;

  CacheService({Duration? defaultDuration})
    : _defaultDuration = defaultDuration ?? defaultCacheDuration {
    // Start periodic cleanup
    _startCleanupTimer();
  }

  /// Get a value from the cache
  T? get<T>(String key) {
    final entry = _cache[key];
    if (entry == null) return null;

    if (entry.isExpired) {
      _cache.remove(key);
      return null;
    }

    return entry.value as T?;
  }

  /// Store a value in the cache
  void set<T>(String key, T value, {Duration? duration}) {
    final expiry = DateTime.now().add(duration ?? _defaultDuration);
    _cache[key] = _CacheEntry(value: value, expiry: expiry);
  }

  /// Get a value from cache or compute it if not present
  Future<T> getOrCompute<T>(
    String key,
    Future<T> Function() compute, {
    Duration? duration,
  }) async {
    final cached = get<T>(key);
    if (cached != null) {
      debugPrint('[Cache] Hit for key: $key');
      return cached;
    }

    debugPrint('[Cache] Miss for key: $key, computing...');
    final value = await compute();
    set(key, value, duration: duration);
    return value;
  }

  /// Invalidate a specific cache entry
  void invalidate(String key) {
    _cache.remove(key);
  }

  /// Invalidate all cache entries matching a pattern
  void invalidatePattern(String pattern) {
    final regex = RegExp(pattern);
    _cache.removeWhere((key, _) => regex.hasMatch(key));
  }

  /// Clear all cache entries
  void clear() {
    _cache.clear();
  }

  /// Get cache statistics
  Map<String, dynamic> getStats() {
    final now = DateTime.now();
    var validCount = 0;
    var expiredCount = 0;

    for (final entry in _cache.values) {
      if (entry.expiry.isAfter(now)) {
        validCount++;
      } else {
        expiredCount++;
      }
    }

    return {
      'totalEntries': _cache.length,
      'validEntries': validCount,
      'expiredEntries': expiredCount,
    };
  }

  void _startCleanupTimer() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _removeExpiredEntries(),
    );
  }

  void _removeExpiredEntries() {
    final now = DateTime.now();
    _cache.removeWhere((_, entry) => entry.expiry.isBefore(now));
    debugPrint(
      '[Cache] Cleanup completed. Remaining entries: ${_cache.length}',
    );
  }

  void dispose() {
    _cleanupTimer?.cancel();
    _cache.clear();
  }
}

/// Internal class to represent a cache entry
class _CacheEntry {
  final dynamic value;
  final DateTime expiry;

  _CacheEntry({required this.value, required this.expiry});

  bool get isExpired => DateTime.now().isAfter(expiry);
}
