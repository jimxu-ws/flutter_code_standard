import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'query_cache.dart';

/// A client for managing query cache and global operations
class QueryClient {
  QueryClient({
    ProviderContainer? container,
    QueryCache? cache,
  })  : _container = container ?? ProviderContainer(),
        _cache = cache ?? getGlobalQueryCache();

  final ProviderContainer _container;
  final QueryCache _cache;
  final Map<String, Timer> _refetchTimers = {};

  /// Invalidate queries by key pattern
  void invalidateQueries(String keyPattern) {
    // Find all providers that match the pattern
    final matchingKeys = _container.getAllProviderElements()
        .where((element) => element.provider.name?.contains(keyPattern) ?? false)
        .map((element) => element.provider)
        .toList();

    for (final provider in matchingKeys) {
      _container.invalidate(provider);
    }
  }

  /// Invalidate all queries
  void invalidateAll() {
    // Invalidate all providers in the container
    final elements = _container.getAllProviderElements();
    for (final element in elements) {
      _container.invalidate(element.provider);
    }
  }

  /// Remove queries from cache by key pattern
  void removeQueries(String keyPattern) {
    // Remove from cache
    final removedCount = _cache.removeByPattern(keyPattern);
    
    // Invalidate matching providers
    invalidateQueries(keyPattern);
    
    // Cancel any associated timers
    _refetchTimers.removeWhere((key, timer) {
      if (key.contains(keyPattern)) {
        timer.cancel();
        return true;
      }
      return false;
    });
  }

  /// Set query data manually in cache
  void setQueryData<T>(String queryKey, T data) {
    _cache.setData(queryKey, data);
  }

  /// Get query data from cache
  T? getQueryData<T>(String queryKey) {
    final entry = _cache.get<T>(queryKey);
    return entry?.hasData == true ? entry!.data as T : null;
  }

  /// Get cache entry with metadata
  QueryCacheEntry<T>? getCacheEntry<T>(String queryKey) {
    return _cache.get<T>(queryKey);
  }

  /// Check if query data exists in cache
  bool hasQueryData(String queryKey) {
    return _cache.containsKey(queryKey);
  }

  /// Get cache statistics
  QueryCacheStats getCacheStats() {
    return _cache.stats;
  }

  /// Clear all cache entries
  void clearCache() {
    _cache.clear();
  }

  /// Cleanup expired cache entries
  int cleanupCache() {
    return _cache.cleanup();
  }

  /// Get all cache keys
  List<String> getCacheKeys() {
    return _cache.keys;
  }

  /// Schedule automatic refetch for a query
  void scheduleRefetch(String key, Duration interval, VoidCallback refetch) {
    _refetchTimers[key]?.cancel();
    _refetchTimers[key] = Timer.periodic(interval, (_) => refetch());
  }

  /// Cancel scheduled refetch
  void cancelRefetch(String key) {
    _refetchTimers[key]?.cancel();
    _refetchTimers.remove(key);
  }

  /// Dispose the client and clean up resources
  void dispose() {
    for (final timer in _refetchTimers.values) {
      timer.cancel();
    }
    _refetchTimers.clear();
    // Note: We don't dispose the container here as it's shared with the widget tree
    // Note: We don't dispose the cache here as it might be shared
  }
}

/// Global query client provider
final queryClientProvider = Provider<QueryClient>((ref) {
  // Use the same container that this provider is running in
  final client = QueryClient(container: ref.container);
  ref.onDispose(client.dispose);
  return client;
});

/// Mixin for providers that support query client operations
mixin QueryClientMixin {
  /// Get the query client from the provider ref
  QueryClient getQueryClient(Ref ref) => ref.read(queryClientProvider);
}
