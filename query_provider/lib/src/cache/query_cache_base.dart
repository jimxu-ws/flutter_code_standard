import 'package:flutter/foundation.dart';
import 'package:meta/meta.dart';

import '../options/query_options.dart';
import 'query_cache_entry.dart';


/// Cache statistics for monitoring and debugging
@immutable
class QueryCacheStats {
  const QueryCacheStats({
    required this.totalEntries,
    required this.staleEntries,
    required this.hitCount,
    required this.missCount,
    required this.evictionCount,
  });

  final int totalEntries;
  final int staleEntries;
  final int hitCount;
  final int missCount;
  final int evictionCount;

  double get hitRate => hitCount + missCount > 0 ? hitCount / (hitCount + missCount) : 0.0;

  @override
  String toString() => 'QueryCacheStats('
      'entries: $totalEntries, '
      'stale: $staleEntries, '
      'hitRate: ${(hitRate * 100).toStringAsFixed(1)}%, '
      'evictions: $evictionCount)';
}

/// Event types for cache notifications
enum QueryCacheEventType {
  hit,
  miss,
  set,
  evict,
  clear,
}

/// Cache event for monitoring and debugging
@immutable
class QueryCacheEvent {
  const QueryCacheEvent({
    required this.type,
    required this.key,
    required this.timestamp,
    this.entry,
  });

  final QueryCacheEventType type;
  final String key;
  final DateTime timestamp;
  final QueryCacheEntry<dynamic>? entry;

  @override
  String toString() => 'QueryCacheEvent(${type.name}: $key at $timestamp)';
}

/// Callback for cache events
typedef QueryCacheEventCallback = void Function(QueryCacheEvent event);

/// Callback for cache data changes
typedef QueryCacheChangeCallback<T> = void Function(QueryCacheEntry<T>? entry);

/// In-memory cache implementation for query data
abstract class QueryCache {
  
  /// Get a cache entry by key
  QueryCacheEntry<T>? get<T>(String key, {JsonParser<T>? jsonParser});

  /// Set a cache entry
  void set<T>(String key, QueryCacheEntry<T> entry, {bool notify = true});

  /// Set cache data with automatic entry creation
  void setData<T>(
    String key,
    T data, {
    Duration? cacheTime,
    Duration? staleTime,
    DateTime? fetchedAt,
    bool notify = true
  });

  /// Set cache error with automatic entry creation
  void setError<T>(
    String key,
    Object error, {
    StackTrace? stackTrace,
    Duration? cacheTime,
    Duration? staleTime,
    DateTime? fetchedAt,
  });

  /// Remove a specific cache entry
  bool remove(String key, {bool notify = true});

  /// Clear all cache entries
  void clear();

  /// Remove entries matching a key pattern
  int removeByPattern(String pattern, {bool notify = true});

  /// Remove entries matching a key pattern
  int markAsStaleByPattern(String pattern);

  /// Get all cache keys
  List<String> get keys;

  /// Get cache size
  int get size;

  /// Check if cache contains a key
  bool containsKey(String key);

  /// Get cache statistics
  QueryCacheStats get stats;

  /// Get next cleanup time (for debugging)
  DateTime? get nextCleanupTime;

  /// Reset statistics
  void resetStats();

  /// Manually trigger cleanup of expired entries
  int cleanup();

  /// Add a listener for cache changes on a specific key
  void addListener<T>(String key, QueryCacheChangeCallback<T> callback);

  /// Remove a listener for a specific key
  void removeListener<T>(String key, QueryCacheChangeCallback<T> callback);

  /// Remove all listeners for a specific key
  void removeAllListeners(String key);

  /// Dispose the cache and cleanup resources
  void dispose();
}

