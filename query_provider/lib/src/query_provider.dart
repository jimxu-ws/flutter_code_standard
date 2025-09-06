import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';

import 'query_state.dart';
import 'query_options.dart';
import 'query_client.dart';

/// A function that fetches data for a query
typedef QueryFunction<T> = Future<T> Function();

/// A function that fetches data with parameters
typedef QueryFunctionWithParams<T, P> = Future<T> Function(P params);

/// Cache entry for storing query data and metadata
@immutable
class QueryCacheEntry<T> {
  const QueryCacheEntry({
    required this.data,
    required this.fetchedAt,
    required this.options,
  });

  final T data;
  final DateTime fetchedAt;
  final QueryOptions<T> options;

  bool get isStale {
    final now = DateTime.now();
    return now.difference(fetchedAt) > options.staleTime;
  }

  bool get shouldEvict {
    final now = DateTime.now();
    return now.difference(fetchedAt) > options.cacheTime;
  }

  QueryCacheEntry<T> copyWith({
    T? data,
    DateTime? fetchedAt,
    QueryOptions<T>? options,
  }) {
    return QueryCacheEntry<T>(
      data: data ?? this.data,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      options: options ?? this.options,
    );
  }
}

/// Notifier for managing query state
class QueryNotifier<T> extends StateNotifier<QueryState<T>>
    with QueryClientMixin {
  QueryNotifier({
    required this.queryFn,
    required this.options,
    required this.queryKey,
    required Ref ref,
  }) : super(const QueryIdle()) {
    _initialize();
  }

  final QueryFunction<T> queryFn;
  final QueryOptions<T> options;
  final String queryKey;

  Timer? _refetchTimer;
  int _retryCount = 0;

  void _initialize() {
    if (options.enabled && options.refetchOnMount) {
      _fetch();
    }

    // Set up automatic refetching if configured
    if (options.refetchInterval != null) {
      _scheduleRefetch();
    }
  }

  /// Fetch data
  Future<void> _fetch() async {
    if (!options.enabled) return;

    // Check cache first
    final cachedEntry = _getCachedEntry();
    if (cachedEntry != null && !cachedEntry.isStale) {
      state = QuerySuccess(cachedEntry.data, fetchedAt: cachedEntry.fetchedAt);
      return;
    }

    // Determine loading state
    if (state.hasData && options.keepPreviousData) {
      state = QueryRefetching(state.data as T, fetchedAt: cachedEntry?.fetchedAt);
    } else {
      state = const QueryLoading();
    }

    try {
      final data = await queryFn();
      final now = DateTime.now();
      
      // Cache the result
      _setCachedEntry(QueryCacheEntry(
        data: data,
        fetchedAt: now,
        options: options,
      ));

      state = QuerySuccess(data, fetchedAt: now);
      _retryCount = 0;

      // Call success callback
      options.onSuccess?.call(data);
    } catch (error, stackTrace) {
      if (_retryCount < options.retry) {
        _retryCount++;
        await Future.delayed(options.retryDelay);
        return _fetch();
      }

      state = QueryError(error, stackTrace: stackTrace);
      _retryCount = 0;

      // Call error callback
      options.onError?.call(error, stackTrace);
    }
  }

  /// Refetch the query
  Future<void> refetch() => _fetch();

  /// Invalidate and refetch
  Future<void> invalidate() {
    _clearCache();
    return _fetch();
  }

  void _scheduleRefetch() {
    _refetchTimer?.cancel();
    if (options.refetchInterval != null) {
      _refetchTimer = Timer.periodic(options.refetchInterval!, (_) {
        if (options.enabled) {
          _fetch();
        }
      });
    }
  }

  QueryCacheEntry<T>? _getCachedEntry() {
    // In a real implementation, this would use a global cache
    // For now, we'll use a simple in-memory approach
    return null;
  }

  void _setCachedEntry(QueryCacheEntry<T> entry) {
    // In a real implementation, this would store in a global cache
  }

  void _clearCache() {
    // In a real implementation, this would clear from global cache
  }

  @override
  void dispose() {
    _refetchTimer?.cancel();
    super.dispose();
  }
}

/// Provider for creating queries
StateNotifierProvider<QueryNotifier<T>, QueryState<T>> queryProvider<T>({
  required String name,
  required QueryFunction<T> queryFn,
  QueryOptions<T> options = const QueryOptions(),
}) {
  return StateNotifierProvider<QueryNotifier<T>, QueryState<T>>(
    (ref) => QueryNotifier<T>(
      queryFn: queryFn,
      options: options,
      queryKey: name,
      ref: ref,
    ),
    name: name,
  );
}

/// Provider family for creating queries with parameters
StateNotifierProviderFamily<QueryNotifier<T>, QueryState<T>, P> queryProviderFamily<T, P>({
  required String name,
  required QueryFunctionWithParams<T, P> queryFn,
  QueryOptions<T> options = const QueryOptions(),
}) {
  return StateNotifierProvider.family<QueryNotifier<T>, QueryState<T>, P>(
    (ref, param) => QueryNotifier<T>(
      queryFn: () => queryFn(param),
      options: options,
      queryKey: '$name-$param',
      ref: ref,
    ),
    name: name,
  );
}

/// Convenience function for creating parameterized queries with constant parameters
StateNotifierProvider<QueryNotifier<T>, QueryState<T>> queryProviderWithParams<T, P>({
  required String name,
  required P params, // Should be const for best practices
  required QueryFunctionWithParams<T, P> queryFn,
  QueryOptions<T> options = const QueryOptions(),
}) {
  return StateNotifierProvider<QueryNotifier<T>, QueryState<T>>(
    (ref) => QueryNotifier<T>(
      queryFn: () => queryFn(params),
      options: options,
      queryKey: '$name-$params',
      ref: ref,
    ),
    name: '$name-$params',
  );
}

/// Extension methods for easier query usage
extension QueryStateExtensions<T> on QueryState<T> {
  /// Execute a callback when the query has data
  R? when<R>({
    R Function()? idle,
    R Function()? loading,
    R Function(T data)? success,
    R Function(Object error, StackTrace? stackTrace)? error,
    R Function(T data)? refetching,
  }) {
    return switch (this) {
      QueryIdle<T>() => idle?.call(),
      QueryLoading<T>() => loading?.call(),
      QuerySuccess<T> successState => success?.call(successState.data),
      QueryError<T> errorState => error?.call(errorState.error, errorState.stackTrace),
      QueryRefetching<T> refetchingState => refetching?.call(refetchingState.previousData),
    };
  }

  /// Map the data if the query is successful
  QueryState<R> map<R>(R Function(T data) mapper) {
    return switch (this) {
      QuerySuccess<T> success => QuerySuccess(mapper(success.data), fetchedAt: success.fetchedAt),
      QueryRefetching<T> refetching => QueryRefetching(mapper(refetching.previousData), fetchedAt: refetching.fetchedAt),
      QueryIdle<T>() => QueryIdle<R>(),
      QueryLoading<T>() => QueryLoading<R>(),
      QueryError<T> error => QueryError<R>(error.error, stackTrace: error.stackTrace),
    };
  }
}
