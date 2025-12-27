import '../interface/i_storage.dart';
import '../options/query_global_options.dart';
import '../options/query_options.dart';
import '../utils/log.dart';
import 'query_cache_base.dart';
import 'query_cache_entry.dart';

/// Disk-backed cache implementation for query data.
///
/// This is a **singleton** because disk cache should be shared process-wide.
/// Initialize it once with required dependencies (like [IStorage]) and then
/// reuse the same instance.
class DiskQueryCache extends QueryCache {
  /// Create (once) and/or return the singleton disk cache.
  ///
  /// The first call initializes the singleton with the provided configuration.
  /// Subsequent calls will return the existing instance and ignore the passed
  /// configuration (with assertions in debug mode to catch misconfiguration).
  factory DiskQueryCache() => _instance;
  DiskQueryCache._internal()
      : assert(QueryGlobalOptions().storage != null, 'Storage is not set');
  static final DiskQueryCache _instance = DiskQueryCache._internal();

  /// Maximum number of entries to keep in storage
  final int maxSize = QueryGlobalOptions().cacheMaxSize;

  /// Default storage time for entries without specific options
  final Duration defaultCacheTime = QueryGlobalOptions().defaultDiskCacheTime;

  /// Internal storage storage
  final IStorage storage = QueryGlobalOptions().storage!;

  /// Optional callback for storage events
  final QueryCacheEventCallback? onEvent = QueryGlobalOptions().onEvent;

  /// Cache change listeners by key
  final Map<String, Set<void Function(QueryCacheEntry<dynamic>?)>> _listeners =
      {};

  /// Cache statistics
  int _hitCount = 0;
  int _missCount = 0;
  int _evictionCount = 0;

  /// Get a storage entry by key
  @override
  QueryCacheEntry<T>? get<T>(String key, {JsonParser<T>? jsonParser}) {
    final QueryCacheEntry<dynamic>? entry =
        storage.get<T>(key, jsonParser: jsonParser);

    if (entry == null) {
      _missCount++;
      _emitEvent(QueryCacheEventType.miss, key);
      return null;
    }

    // Check if entry should be evicted
    if (entry.shouldEvict) {
      Log.info('Evicting entry for key $key in query storage');
      storage.remove(key);
      _evictionCount++;
      _emitEvent(QueryCacheEventType.evict, key, entry);
      _missCount++;
      _emitEvent(QueryCacheEventType.miss, key);
      return null;
    }

    _hitCount++;
    _emitEvent(QueryCacheEventType.hit, key, entry);

    return entry as QueryCacheEntry<T>?;
  }

  /// Set a storage entry
  @override
  void set<T>(String key, QueryCacheEntry<T> entry,
      {bool notify = true, bool isError = false}) {
    if (!isError) {
      // for persistent storage, we don't need to store error entries
      storage.set(key, entry);
      _emitEvent(QueryCacheEventType.set, key, entry);

      // Notify listeners of the change
      if (notify) {
        _notifyListeners<T>(key, entry);
      }
    }
  }

  /// Set storage data with automatic entry creation
  @override
  void setData<T>(String key, T data,
      {Duration? cacheTime,
      Duration? staleTime,
      DateTime? fetchedAt,
      bool notify = true}) {
    final entry = QueryCacheEntry<T>(
      data: data,
      fetchedAt: fetchedAt ?? DateTime.now(),
      cacheTime: cacheTime ?? defaultCacheTime,
      staleTime: staleTime ?? defaultCacheTime,
    );
    set(key, entry, notify: notify);
  }

  /// Set storage error with automatic entry creation
  @override
  void setError<T>(
    String key,
    Object error, {
    StackTrace? stackTrace,
    Duration? cacheTime,
    Duration? staleTime,
    DateTime? fetchedAt,
  }) {
    final entry = QueryCacheEntry<T>(
      data: null,
      fetchedAt: fetchedAt ?? DateTime.now(),
      cacheTime: cacheTime ?? defaultCacheTime,
      staleTime: staleTime ?? defaultCacheTime,
      error: error,
      stackTrace: stackTrace,
    );
    set(key, entry, isError: true);
  }

  /// Remove a specific storage entry
  @override
  bool remove(String key, {bool notify = true}) {
    final entry = storage.remove(key);
    if (entry != null) {
      _emitEvent(QueryCacheEventType.evict, key, entry);
      // Notify listeners that entry was removed
      if (notify) {
        _notifyListeners<dynamic>(key, null);
      }
      return true;
    }
    return false;
  }

  /// Clear all storage entries
  @override
  void clear() {
    storage.clear();
  }

  /// Remove entries matching a key pattern
  @override
  int removeByPattern(String pattern, {bool notify = true}) {
    final keysToRemove =
        storage.keys.where((key) => key.contains(pattern)).toList();

    for (final key in keysToRemove) {
      remove(key, notify: notify);
      storage.remove(key);
    }

    return keysToRemove.length;
  }

  /// Remove entries matching a key pattern
  @override
  int markAsStaleByPattern(String pattern) {
    final keysToStale =
        storage.keys.where((key) => key.contains(pattern)).toList();

    for (final key in keysToStale) {
      final entry = storage.getRaw<dynamic>(key);
      if (entry != null) {
        set(key, entry.copyAsStale(), notify: false);
      }
    }

    return keysToStale.length;
  }

  /// Get all storage keys
  @override
  List<String> get keys => storage.keys;

  /// Get storage size
  @override
  int get size => storage.keys.length;

  /// Check if storage contains a key
  @override
  bool containsKey(String key) => storage.containsKey(key);

  /// Get storage statistics
  @override
  QueryCacheStats get stats {
    final staleCount = storage.keys
        .where((key) => storage.getRaw<dynamic>(key)?.isStale ?? false)
        .length;

    return QueryCacheStats(
      totalEntries: size,
      staleEntries: staleCount,
      hitCount: _hitCount,
      missCount: _missCount,
      evictionCount: _evictionCount,
    );
  }

  /// Get next cleanup time (for debugging)
  @override
  DateTime? get nextCleanupTime {
    throw UnimplementedError(
        'nextCleanupTime is not implemented for DiskQueryCache');
  }

  /// Reset statistics
  @override
  void resetStats() {
    _hitCount = 0;
    _missCount = 0;
    _evictionCount = 0;
  }

  /// Manually trigger cleanup of expired entries
  @override
  int cleanup() {
    final keysToRemove = <String>[];

    for (final key in keys) {
      final entry = storage.getRaw<dynamic>(key);
      if (entry?.shouldEvict ?? false) {
        keysToRemove.add(key);
      }
    }

    for (final key in keysToRemove) {
      remove(key);
      storage.remove(key);
    }

    return keysToRemove.length;
  }

  /// Add a listener for storage changes on a specific key
  @override
  void addListener<T>(String key, QueryCacheChangeCallback<T> callback) {
    _listeners.putIfAbsent(
        key, () => <void Function(QueryCacheEntry<dynamic>?)>{});
    _listeners[key]!.add((entry) => callback(entry as QueryCacheEntry<T>?));
  }

  /// Remove a listener for a specific key
  @override
  void removeListener<T>(String key, QueryCacheChangeCallback<T> callback) {
    // Note: This won't work perfectly because we're storing wrapped functions
    // For now, use removeAllListeners instead for cleanup
    if (_listeners[key]?.isEmpty ?? false) {
      _listeners.remove(key);
    }
  }

  /// Remove all listeners for a specific key
  @override
  void removeAllListeners(String key) {
    _listeners.remove(key);
  }

  /// Notify listeners of storage changes
  void _notifyListeners<T>(String key, QueryCacheEntry<T>? entry) {
    final listeners = _listeners[key];
    if (listeners != null) {
      for (final listener in listeners) {
        try {
          // Entry is already cast to dynamic in the stored wrapper function
          listener(entry as QueryCacheEntry<dynamic>?);
        } catch (e) {
          // Ignore listener errors to prevent storage corruption
          Log.info('Cache listener error for key $key: $e');
        }
      }
    }
  }

  /// Emit storage event
  void _emitEvent(QueryCacheEventType type, String key,
      [QueryCacheEntry<dynamic>? entry]) {
    Log.info(
        'Emitting storage event for key $key in query storage, type: $type');
    onEvent?.call(QueryCacheEvent(
      type: type,
      key: key,
      timestamp: DateTime.now(),
      entry: entry,
    ));
  }

  /// Dispose the storage and cleanup resources
  @override
  void dispose() {
    _listeners.clear();
    clear();
  }

  @override
  String toString() => 'DiskQueryCache(size: $size/$maxSize, stats: $stats)';
}
