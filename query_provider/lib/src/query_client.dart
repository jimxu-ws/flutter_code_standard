import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A client for managing query cache and global operations
class QueryClient {
  QueryClient({ProviderContainer? container})
      : _container = container ?? ProviderContainer();

  final ProviderContainer _container;
  final Map<String, Timer> _cacheTimers = {};
  final Map<String, Timer> _refetchTimers = {};

  /// Invalidate queries by key pattern
  void invalidateQueries(String keyPattern) {
    // Find all providers that match the pattern
    final matchingKeys = _container.getAllProviderElements()
        .where((element) => element.provider.name?.contains(keyPattern) == true)
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
    invalidateQueries(keyPattern);
    // Cancel any associated timers
    _cacheTimers.removeWhere((key, timer) {
      if (key.contains(keyPattern)) {
        timer.cancel();
        return true;
      }
      return false;
    });
  }

  /// Set query data manually
  void setQueryData<T>(ProviderBase<T> provider, T data) {
    // Note: In a real implementation, you'd need to update the provider's state
    // This would require access to the provider's notifier
    // For now, we'll invalidate the provider to trigger a refetch
    _container.invalidate(provider);
  }

  /// Get query data
  T? getQueryData<T>(ProviderBase<T> provider) {
    try {
      return _container.read(provider);
    } catch (e) {
      return null;
    }
  }

  /// Prefetch a query
  Future<T> prefetchQuery<T>(
    ProviderBase<Future<T>> provider,
  ) async {
    return _container.read(provider);
  }

  /// Schedule cache cleanup for a query
  void scheduleCacheCleanup(String key, Duration cacheTime) {
    _cacheTimers[key]?.cancel();
    _cacheTimers[key] = Timer(cacheTime, () {
      // Remove from cache
      _cacheTimers.remove(key);
    });
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
    for (final timer in _cacheTimers.values) {
      timer.cancel();
    }
    for (final timer in _refetchTimers.values) {
      timer.cancel();
    }
    _cacheTimers.clear();
    _refetchTimers.clear();
    _container.dispose();
  }
}

/// Global query client provider
final queryClientProvider = Provider<QueryClient>((ref) {
  final client = QueryClient();
  ref.onDispose(client.dispose);
  return client;
});

/// Mixin for providers that support query client operations
mixin QueryClientMixin {
  /// Get the query client from the provider ref
  QueryClient getQueryClient(Ref ref) => ref.read(queryClientProvider);
}
