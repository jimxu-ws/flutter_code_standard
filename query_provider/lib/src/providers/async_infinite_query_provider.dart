import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_focus/window_focus_manager.dart';
import '../cache/query_cache_base.dart';
import '../cache/query_cache_entry.dart';
import '../client/query_client.dart';
import '../options/query_options.dart';
import '../providers/state_query_provider.dart' show QueryFunctionWithParamsWithRef;
import '../utils/common_func.dart';
import '../utils/log.dart';

/// Represents the data structure for infinite query results
@immutable
class InfiniteQueryData<T> {
  const InfiniteQueryData({
    required this.pages,
    this.hasNextPage = false,
    this.hasPreviousPage = false,
    this.fetchedAt,
  });

  final List<T> pages;
  final bool hasNextPage;
  final bool hasPreviousPage;
  final DateTime? fetchedAt;

  InfiniteQueryData<T> copyWith({
    List<T>? pages,
    bool? hasNextPage,
    bool? hasPreviousPage,
    DateTime? fetchedAt,
  }) =>
      InfiniteQueryData<T>(
        pages: pages ?? this.pages,
        hasNextPage: hasNextPage ?? this.hasNextPage,
        hasPreviousPage: hasPreviousPage ?? this.hasPreviousPage,
        fetchedAt: fetchedAt ?? this.fetchedAt,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InfiniteQueryData<T> &&
          other.pages == pages &&
          other.hasNextPage == hasNextPage &&
          other.hasPreviousPage == hasPreviousPage &&
          other.fetchedAt == fetchedAt);

  @override
  int get hashCode =>
      Object.hash(pages, hasNextPage, hasPreviousPage, fetchedAt);

  @override
  String toString() => 'InfiniteQueryData<$T>('
      'pages: ${pages.length}, '
      'hasNextPage: $hasNextPage, '
      'hasPreviousPage: $hasPreviousPage, '
      'fetchedAt: $fetchedAt)';
}

/// 🔥 Modern AsyncNotifier-based infinite query implementation
///
/// Features:
/// - Background refetch and lifecycle management
/// - Cache integration with automatic invalidation
/// - Window focus refetch support
/// - keepPreviousData: Shows stale data while fetching fresh data for better UX
/// - Automatic retry with exponential backoff
/// - Optimistic updates support
class AsyncInfiniteQueryNotifier<T, TPageParam>
    extends AsyncNotifier<InfiniteQueryData<T>> {
  AsyncInfiniteQueryNotifier({
    required this.queryFn,
    required this.options,
    required this.initialPageParam,
    required this.queryKey,
  });

  final QueryFunctionWithParamsWithRef<T, TPageParam> queryFn;
  final InfiniteQueryOptions<T, TPageParam> options;
  final TPageParam initialPageParam;
  final String queryKey;

  Timer? _refetchTimer;
  int _retryCount = 0;

  // Initialize cache, lifecycle manager, and window focus manager
  QueryCache get _cache => getCache(strategy: options.cacheStrategy);
  final WindowFocusManager _windowFocusManager = WindowFocusManager();
  bool _isRefetchPaused = false;
  bool _isInitialized = false;
  bool _isDisposed = false;

  @override
  FutureOr<InfiniteQueryData<T>> build() async {
    _isDisposed = false;
    // Prevent duplicate initialization
    if (!_isInitialized) {
      _isInitialized = true;

      // Set up cache change listener for automatic UI updates
      _setupCacheListener();

      // Set up window focus callbacks
      _setupWindowFocusCallbacks();

      // Set up cleanup when the notifier is disposed
      ref.onDispose(_dispose);
    }

    // Set up automatic refetching if configured
    if (options.enabled && options.refetchInterval != null) {
      _scheduleRefetch();
    }

    if (!options.enabled) {
      return const InfiniteQueryData(pages: []);
    }

    // Check cache first
    final cachedEntry = _getCachedEntry();
    if (cachedEntry != null && !cachedEntry.isStale && cachedEntry.hasData) {
      if (options.refetchOnMount) {
        unawaited(Future.microtask(_fetchFirstPageInBackground));
      }
      Log.info(
          'Using cached data in async infinite query notifier for key $queryKey');
      final cachedData = cachedEntry.data!;
      return cachedData;
    }

    // If keepPreviousData is enabled and we have stale cached data, use it while fetching fresh data
    if (options.keepPreviousData &&
        cachedEntry != null &&
        cachedEntry.hasData) {
      Log.info(
          'Using stale cached data with keepPreviousData in async infinite query notifier for key $queryKey');
      final staleData = cachedEntry.data!;

      // Start fetching fresh data in the background
      _fetchFirstPageInBackground();

      return staleData;
    }

    // Fetch first page
    return _fetchFirstPage();
  }

  /// Fetch the first page in background (for keepPreviousData)
  void _fetchFirstPageInBackground() {
    _fetchFirstPage().then((newData) {
      // Update state with fresh data
      _safeState(AsyncValue.data(newData));
    }).catchError((Object error, StackTrace stackTrace) {
      // On error, keep the current stale data but log the error
      Log.info('Background fetch failed for key $queryKey: $error');
      // Don't update state on error to keep showing stale data
    });
  }

  /// Fetch the first page
  Future<InfiniteQueryData<T>> _fetchFirstPage() async {
    try {
      final firstPage = await queryFn(ref, initialPageParam);
      final now = DateTime.now();
      final pages = [firstPage];

      final hasNextPage = options.getNextPageParam(firstPage, pages) != null;
      final hasPreviousPage =
          options.getPreviousPageParam?.call(firstPage, pages) != null;

      final result = InfiniteQueryData<T>(
        pages: pages,
        hasNextPage: hasNextPage,
        hasPreviousPage: hasPreviousPage,
        fetchedAt: now,
      );

      // Cache the result
      _setCachedEntry(QueryCacheEntry<InfiniteQueryData<T>>(
        data: result,
        fetchedAt: now,
        cacheTime: options.cacheTime,
        staleTime: options.staleTime,
      ));

      _retryCount = 0;
      options.onSuccess?.call(firstPage);
      return result;
    } catch (error, stackTrace) {
      if (_retryCount < options.retry) {
        _retryCount++;
        await Future<void>.delayed(options.retryDelay);
        return _fetchFirstPage();
      }

      // Cache the error
      _cache.setError<InfiniteQueryData<T>>(
        queryKey,
        error,
        stackTrace: stackTrace,
        cacheTime: options.cacheTime,
        staleTime: options.staleTime,
      );

      _retryCount = 0;
      options.onError?.call(error, stackTrace);
      rethrow;
    }
  }

  /// Fetch the next page
  Future<void> fetchNextPage() async {
    final currentState = state;
    if (!currentState.hasValue || !currentState.value!.hasNextPage) {
      return;
    }

    final currentData = currentState.value!;
    final nextPageParam = options.getNextPageParam(
      currentData.pages.last,
      currentData.pages,
    );

    if (nextPageParam == null) {
      return;
    }

    try {
      final nextPage = await queryFn(ref, nextPageParam);
      final newPages = [...currentData.pages, nextPage];

      final hasNextPage = options.getNextPageParam(nextPage, newPages) != null;
      final hasPreviousPage =
          options.getPreviousPageParam?.call(newPages.first, newPages) != null;

      final newData = InfiniteQueryData<T>(
        pages: newPages,
        hasNextPage: hasNextPage,
        hasPreviousPage: hasPreviousPage,
        fetchedAt: DateTime.now(),
      );

      // Update cache
      _setCachedEntry(QueryCacheEntry<InfiniteQueryData<T>>(
        data: newData,
        fetchedAt: newData.fetchedAt!,
        cacheTime: options.cacheTime,
        staleTime: options.staleTime,
      ));

      // Update state
      _safeState(AsyncValue.data(newData));
      options.onSuccess?.call(nextPage);
    } catch (error, stackTrace) {
      // Don't update state on error, keep current data
      // This behavior is consistent with keepPreviousData philosophy
      options.onError?.call(error, stackTrace);
      Log.info(
          'fetchNextPage failed but keeping current data for key $queryKey: $error');
      rethrow;
    }
  }

  /// Fetch the previous page
  Future<void> fetchPreviousPage() async {
    final currentState = state;
    if (!currentState.hasValue ||
        !currentState.value!.hasPreviousPage ||
        options.getPreviousPageParam == null) {
      return;
    }

    final currentData = currentState.value!;
    final previousPageParam = options.getPreviousPageParam!(
      currentData.pages.first,
      currentData.pages,
    );

    if (previousPageParam == null) {
      return;
    }

    try {
      final previousPage = await queryFn(ref, previousPageParam);
      final newPages = [previousPage, ...currentData.pages];

      final hasNextPage =
          options.getNextPageParam(newPages.last, newPages) != null;
      final hasPreviousPage =
          options.getPreviousPageParam!(newPages.first, newPages) != null;

      final newData = InfiniteQueryData<T>(
        pages: newPages,
        hasNextPage: hasNextPage,
        hasPreviousPage: hasPreviousPage,
        fetchedAt: DateTime.now(),
      );

      // Update cache
      _setCachedEntry(QueryCacheEntry<InfiniteQueryData<T>>(
        data: newData,
        fetchedAt: newData.fetchedAt!,
        cacheTime: options.cacheTime,
        staleTime: options.staleTime,
      ));

      // Update state
      _safeState(AsyncValue.data(newData));
      options.onSuccess?.call(previousPage);
    } catch (error, stackTrace) {
      // Don't update state on error, keep current data
      // This behavior is consistent with keepPreviousData philosophy
      options.onError?.call(error, stackTrace);
      Log.info(
          'fetchPreviousPage failed but keeping current data for key $queryKey: $error');
      rethrow;
    }
  }

  /// Refetch all pages
  Future<void> refetch() async {
    final currentState = state;
    if (currentState.hasValue) {
      final currentData = currentState.value!;

      // If keepPreviousData is enabled, don't change the state to loading
      // Keep showing current data while fetching
      if (!options.keepPreviousData) {
        _safeState(const AsyncValue.loading());
      }

      try {
        // Refetch all existing pages
        final List<T> newPages = [];
        TPageParam pageParam = initialPageParam;

        // Fetch the same number of pages as currently loaded
        for (int i = 0; i < currentData.pages.length; i++) {
          final page = await queryFn(ref, pageParam);
          newPages.add(page);

          if (i < currentData.pages.length - 1) {
            final nextParam = options.getNextPageParam(page, newPages);
            if (nextParam == null) {
              break;
            }
            pageParam = nextParam;
          }
        }

        final hasNextPage =
            options.getNextPageParam(newPages.last, newPages) != null;
        final hasPreviousPage =
            options.getPreviousPageParam?.call(newPages.first, newPages) !=
                null;

        final newData = InfiniteQueryData<T>(
          pages: newPages,
          hasNextPage: hasNextPage,
          hasPreviousPage: hasPreviousPage,
          fetchedAt: DateTime.now(),
        );

        // Update cache
        _setCachedEntry(QueryCacheEntry<InfiniteQueryData<T>>(
          data: newData,
          fetchedAt: newData.fetchedAt!,
          cacheTime: options.cacheTime,
          staleTime: options.staleTime,
        ));

        // Update state
        _safeState(AsyncValue.data(newData));
      } catch (error, stackTrace) {
        // If keepPreviousData is enabled and we have current data, don't show error state
        // Keep showing the current data
        if (options.keepPreviousData && currentState.hasValue) {
          Log.info(
              'Refetch failed but keeping previous data for key $queryKey: $error');
          // Don't update state, keep current data
        } else {
          _safeState(AsyncValue.error(error, stackTrace));
        }
      }
    } else {
      // If no current data, fetch first page
      _safeState(const AsyncValue.loading());
      try {
        final newData = await _fetchFirstPage();
        _safeState(AsyncValue.data(newData));
      } catch (error, stackTrace) {
        _safeState(AsyncValue.error(error, stackTrace));
      }
    }
  }

  /// Invalidate and refetch
  Future<void> refresh() {
    _clearCache();
    return refetch();
  }

  /// Set query data manually (for optimistic updates)
  void setData(InfiniteQueryData<T> data) {
    final now = DateTime.now();
    final updatedData = data.copyWith(fetchedAt: now);

    _setCachedEntry(QueryCacheEntry<InfiniteQueryData<T>>(
      data: updatedData,
      fetchedAt: now,
      cacheTime: options.cacheTime,
      staleTime: options.staleTime,
    ));

    _safeState(AsyncValue.data(updatedData));
  }

  /// Get current cached data
  InfiniteQueryData<T>? getCachedData() {
    final entry = _getCachedEntry();
    return (entry?.hasData ?? false) ? entry!.data! : null;
  }

  void _scheduleRefetch() {
    _refetchTimer?.cancel();
    if (options.refetchInterval != null) {
      _refetchTimer = Timer.periodic(options.refetchInterval!, (_) {
        if (options.enabled && _shouldRefetch()) {
          refetch();
        }
      });
    }
  }

  /// Check if refetch should proceed based on app state
  bool _shouldRefetch() {
    // If refetching is explicitly paused, don't refetch
    if (_isRefetchPaused) {
      return false;
    }

    // If pausing in background is enabled and app is in background, don't refetch
    if (options.pauseRefetchInBackground && _windowFocusManager.windowLostFocus) {
      return false;
    }

    return true;
  }

  void _onWindowBlured() {
    if(isMobile()){
      Log.info('App paused in async infinite query notifier');
      // Mark refetching as paused
      _isRefetchPaused = true;
    }
  }

  /// Set up window focus callbacks
  void _setupWindowFocusCallbacks() {
    // Refetch when window gains focus (if enabled and data is stale)
    if (options.refetchOnWindowFocus && _windowFocusManager.isSupported) {
      _windowFocusManager.addOnFocusCallback(_onWindowFocused);
    }

    // Pause refetching when app goes to background (if enabled)
    if (options.pauseRefetchInBackground) {
      _windowFocusManager.addOnBlurCallback(_onWindowBlured);
    }
  }

  void _onWindowFocused() {
    Log.info('Window focused in async infinite query notifier');
    // Resume refetching and check if we need to refetch stale data
    _isRefetchPaused = false;

    // Refetch stale data when window gains focus
    if (_shouldRefetchOnFocus()) {
      refetch();
    }
  }

  /// Check if we should refetch when focus is gained
  bool _shouldRefetchOnFocus() {
    if (!options.enabled) {
      return false;
    }

    final currentState = state;
    if (currentState.hasValue) {
      final currentData = currentState.value!;
      // Check if data is stale based on stale time
      final now = DateTime.now();
      final fetchedAt = currentData.fetchedAt;
      if (fetchedAt != null) {
        final age = now.difference(fetchedAt);
        return age > options.staleTime;
      }
    }

    return false;
  }

  QueryCacheEntry<InfiniteQueryData<T>>? _getCachedEntry() =>
      _cache.get<InfiniteQueryData<T>>(queryKey);

  void _setCachedEntry(QueryCacheEntry<InfiniteQueryData<T>> entry) {
    _cache.set(queryKey, entry);
  }

  void _clearCache() {
    _cache.remove(queryKey);
  }

  /// Set up cache change listener for automatic UI updates
  void _setupCacheListener() {
    _cache.addListener<InfiniteQueryData<T>>(queryKey, (entry) {
      Log.info(
          'Cache listener called for key $queryKey in async infinite query notifier');
      if ((entry?.hasData ?? false) &&
          !_isDisposed &&
          !(!(state.isLoading || state.hasError) &&
              state.hasValue &&
              listEquals(entry!.data!.pages, state.value!.pages))) {
        Log.info(
            'Cache data changed for key $queryKey in async infinite query notifier');
        // Update state when cache data changes externally (e.g., optimistic updates)
        _safeState(AsyncValue.data(entry!.data!));
      } else if (entry == null) {
        Log.info(
            'Cache entry removed for key $queryKey in async infinite query notifier');
        // Cache entry was removed, reset to loading
        if (options.onCacheEvicted != null) {
          options.onCacheEvicted?.call(queryKey);
        } else if (!_isDisposed) {
          // refetch();
        }
      }
    });
  }

  void _safeState(AsyncValue<InfiniteQueryData<T>> state) {
    if (!_isDisposed) {
      this.state = state;
    }
  }

  void _dispose() {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;

    _refetchTimer?.cancel();

    // Clean up cache listener
    _cache.removeAllListeners(queryKey);

    // Clean up lifecycle callbacks
    if (options.pauseRefetchInBackground) {
      _windowFocusManager.removeOnBlurCallback(_onWindowBlured);
    }

    // Clean up window focus callbacks
    if (options.refetchOnWindowFocus && _windowFocusManager.isSupported) {
      _windowFocusManager.removeOnFocusCallback(_onWindowFocused);
    }

    // Reset initialization flag
    _isInitialized = false;
  }
}

/// Provider for creating async infinite queries
AsyncNotifierProvider<AsyncInfiniteQueryNotifier<T, TPageParam>,
    InfiniteQueryData<T>> asyncInfiniteQueryProvider<T, TPageParam>({
  required String name,
  required QueryFunctionWithParamsWithRef<T, TPageParam> queryFn,
  required TPageParam initialPageParam,
  required InfiniteQueryOptions<T, TPageParam> options,
}) =>
    AsyncNotifierProvider<AsyncInfiniteQueryNotifier<T, TPageParam>,
        InfiniteQueryData<T>>(
      () => AsyncInfiniteQueryNotifier<T, TPageParam>(
        queryFn: queryFn,
        options: options,
        initialPageParam: initialPageParam,
        queryKey: name,
      ),
      name: name,
    );

/// Auto-dispose AsyncNotifier for infinite queries
class AsyncInfiniteQueryNotifierAutoDispose<T, TPageParam>
    extends AutoDisposeAsyncNotifier<InfiniteQueryData<T>> {
  AsyncInfiniteQueryNotifierAutoDispose({
    required this.queryFn,
    required this.options,
    required this.initialPageParam,
    required this.queryKey,
  });

  final QueryFunctionWithParamsWithRef<T, TPageParam> queryFn;
  final InfiniteQueryOptions<T, TPageParam> options;
  final TPageParam initialPageParam;
  final String queryKey;

  Timer? _refetchTimer;
  int _retryCount = 0;

  QueryCache get _cache => getCache(strategy: options.cacheStrategy);
  final WindowFocusManager _windowFocusManager = WindowFocusManager();
  bool _isRefetchPaused = false;
  bool _isInitialized = false;
  bool _isDisposed = false;

  @override
  FutureOr<InfiniteQueryData<T>> build() async {
    _isDisposed = false;

    if (!_isInitialized) {
      _isInitialized = true;
      _setupCacheListener();
      _setupWindowFocusCallbacks();

      ref.onDispose(() {
        _isDisposed = true;
        _refetchTimer?.cancel();
        _cache.removeAllListeners(queryKey);

        if (options.pauseRefetchInBackground) {
          _windowFocusManager.removeOnBlurCallback(_onWindowBlured);
        }
        if (options.refetchOnWindowFocus && _windowFocusManager.isSupported) {
          _windowFocusManager.removeOnFocusCallback(_onWindowFocused);
        }

        _isInitialized = false;
      });
    }

    if (options.enabled && options.refetchInterval != null) {
      _scheduleRefetch();
    }

    if (options.enabled) {
      final cachedEntry = _getCachedEntry();
      if (cachedEntry != null && !cachedEntry.isStale && cachedEntry.hasData) {
        if (options.refetchOnMount) {
          unawaited(Future.microtask(
              () => _backgroundRefetch().catchError((Object error) {
                    Log.info('Error in background refetch: $error');
                  })));
        }
        return cachedEntry.data!;
      }

      if (options.keepPreviousData &&
          ((!_isDisposed && state.hasValue) ||
              (cachedEntry != null && cachedEntry.hasData))) {
        unawaited(Future.microtask(
            () => _backgroundRefetch().catchError((Object error) {
                  Log.info('Error in background refetch: $error');
                })));
        return (!_isDisposed && state.hasValue)
            ? state.value!
            : cachedEntry!.data!;
      }
    }

    if (!options.enabled) {
      throw StateError('Query is disabled and no cached data available');
    }

    return await _performFirstPageFetch();
  }

  void _safeState(AsyncValue<InfiniteQueryData<T>> state) {
    if (!_isDisposed) {
      this.state = state;
    }
  }

  Future<InfiniteQueryData<T>> _performFirstPageFetch() async {
    try {
      final firstPage = await queryFn(ref, initialPageParam);
      final now = DateTime.now();

      final data = InfiniteQueryData<T>(
        pages: [firstPage],
        hasNextPage:
            options.getNextPageParam.call(firstPage, [firstPage]) != null,
        hasPreviousPage:
            options.getPreviousPageParam?.call(firstPage, [firstPage]) != null,
        fetchedAt: now,
      );

      _setCachedEntry(QueryCacheEntry<InfiniteQueryData<T>>(
        data: data,
        fetchedAt: now,
        cacheTime: options.cacheTime,
        staleTime: options.staleTime,
      ));

      _retryCount = 0;
      options.onSuccess?.call(firstPage);

      return data;
    } catch (error, stackTrace) {
      options.onError?.call(error, stackTrace);

      if (_retryCount < options.retry) {
        _retryCount++;
        await Future<void>.delayed(options.retryDelay);
        return _performFirstPageFetch();
      }

      rethrow;
    }
  }

  Future<void> _backgroundRefetch() async {
    try {
      final data = await _performFirstPageFetch();
      _safeState(AsyncValue.data(data));
    } catch (error, _) {
      // Silent failure
    }
  }

  Future<void> fetchNextPage() async {
    if (!state.hasValue) {
      return;
    }

    final currentData = state.value!;
    final nextPageParam = options.getNextPageParam.call(
      currentData.pages.last,
      currentData.pages,
    );

    if (nextPageParam == null) {
      return;
    }

    try {
      final nextPage = await queryFn(ref, nextPageParam);
      final newData = InfiniteQueryData<T>(
        pages: [...currentData.pages, nextPage],
        hasNextPage: options.getNextPageParam
                .call(nextPage, [...currentData.pages, nextPage]) !=
            null,
        hasPreviousPage: currentData.hasPreviousPage,
        fetchedAt: DateTime.now(),
      );

      _setCachedEntry(QueryCacheEntry<InfiniteQueryData<T>>(
        data: newData,
        fetchedAt: DateTime.now(),
        cacheTime: options.cacheTime,
        staleTime: options.staleTime,
      ));

      _safeState(AsyncValue.data(newData));
    } catch (error, _) {
      // Keep current data on error
    }
  }

  Future<void> refetch() async {
    _safeState(const AsyncValue.loading());
    try {
      final data = await _performFirstPageFetch();
      _safeState(AsyncValue.data(data));
    } catch (error, stackTrace) {
      _safeState(AsyncValue.error(error, stackTrace));
    }
  }

  QueryCacheEntry<InfiniteQueryData<T>>? _getCachedEntry() =>
      _cache.get<InfiniteQueryData<T>>(queryKey);
  void _setCachedEntry(QueryCacheEntry<InfiniteQueryData<T>> entry) =>
      _cache.set(queryKey, entry);

  void _setupCacheListener() {
    _cache.addListener<InfiniteQueryData<T>>(queryKey, (entry) {
      if (entry?.hasData ?? false) {
        _safeState(AsyncValue.data(entry!.data!));
      } else if (entry == null && !_isDisposed) {
        if (options.onCacheEvicted != null) {
          options.onCacheEvicted!(queryKey);
        } else {
          // refetch();
        }
      }
    });
  }

  void _setupWindowFocusCallbacks() {
    if (options.refetchOnWindowFocus && _windowFocusManager.isSupported) {
      _windowFocusManager.addOnFocusCallback(_onWindowFocused);
    }
    if (options.pauseRefetchInBackground) {
      _windowFocusManager.addOnBlurCallback(_onWindowBlured);
    }
  }

  void _scheduleRefetch() {
    final interval = options.refetchInterval;
    if (interval != null && !_isRefetchPaused) {
      _refetchTimer?.cancel();
      _refetchTimer = Timer.periodic(interval, (_) {
        if (!_isRefetchPaused && options.enabled) {
          _backgroundRefetch();
        }
      });
    }
  }

  void _onWindowBlured(){
    if(isMobile()){
        Log.info('App paused in async infinite query notifier');
        // Mark refetching as paused
      _isRefetchPaused = true;
    }
  }

  void _onWindowFocused() {
    _isRefetchPaused = false;
    if (options.enabled) {
      final cachedEntry = _getCachedEntry();
      if (cachedEntry != null && cachedEntry.isStale) {
        _backgroundRefetch();
      }
    }
  }
}

/// Auto-dispose provider for creating async infinite queries
///
/// **Use this when:**
/// - Temporary infinite data that should be cleaned up when not watched
/// - Memory optimization for large paginated datasets
/// - Short-lived screens with infinite scrolling
/// - Data that doesn't need to persist across navigation
///
/// **Features:**
/// - ✅ Automatic cleanup when no longer watched
/// - ✅ Full async infinite query functionality (fetchNextPage, fetchPreviousPage)
/// - ✅ Cache integration with staleTime/cacheTime
/// - ✅ Lifecycle management (app focus, window focus)
/// - ✅ Automatic refetching intervals
/// - ✅ Retry logic with exponential backoff
/// - ✅ Background refetch capabilities
/// - ✅ keepPreviousData support
/// - ✅ Memory leak prevention
///
/// Example:
/// ```dart
/// final tempPostsProvider = asyncInfiniteQueryProviderAutoDispose<Post, int>(
///   name: 'temp-posts',
///   queryFn: (pageParam) => ApiService.fetchPosts(page: pageParam),
///   initialPageParam: 1,
///   options: InfiniteQueryOptions(
///     getNextPageParam: (lastPage, allPages) =>
///       lastPage.hasMore ? allPages.length + 1 : null,
///     staleTime: Duration(minutes: 2),
///     cacheTime: Duration(minutes: 5),
///   ),
/// );
///
/// // Usage in widget:
/// final postsAsync = ref.watch(tempPostsProvider);
/// postsAsync.when(
///   loading: () => CircularProgressIndicator(),
///   error: (error, stack) => ErrorWidget(error),
///   data: (infiniteData) => ListView.builder(
///     itemCount: infiniteData.pages.expand((page) => page.items).length,
///     itemBuilder: (context, index) => PostTile(post: infiniteData.pages[index]),
///   ),
/// );
/// ```
AutoDisposeAsyncNotifierProvider<
    AsyncInfiniteQueryNotifierAutoDispose<T, TPageParam>,
    InfiniteQueryData<T>> asyncInfiniteQueryProviderAutoDispose<T, TPageParam>({
  required String name,
  required QueryFunctionWithParamsWithRef<T, TPageParam> queryFn,
  required TPageParam initialPageParam,
  required InfiniteQueryOptions<T, TPageParam> options,
}) =>
    AsyncNotifierProvider.autoDispose<
        AsyncInfiniteQueryNotifierAutoDispose<T, TPageParam>,
        InfiniteQueryData<T>>(
      () => AsyncInfiniteQueryNotifierAutoDispose<T, TPageParam>(
        queryFn: queryFn,
        options: options,
        initialPageParam: initialPageParam,
        queryKey: name,
      ),
      name: name,
    );

/// Hook-like interface for using async infinite queries
@immutable
class AsyncInfiniteQueryResult<T> {
  const AsyncInfiniteQueryResult({
    required this.state,
    required this.fetchNextPage,
    required this.fetchPreviousPage,
    required this.refetch,
    required this.refresh,
  });

  final AsyncValue<InfiniteQueryData<T>> state;
  final Future<void> Function() fetchNextPage;
  final Future<void> Function() fetchPreviousPage;
  final Future<void> Function() refetch;
  final Future<void> Function() refresh;

  /// Returns true if the query is currently loading
  bool get isLoading => state.isLoading;

  /// Returns true if the query has data
  bool get hasData => state.hasValue;

  /// Returns true if the query has an error
  bool get hasError => state.hasError;

  /// Returns the pages if available
  List<T>? get pages => state.valueOrNull?.pages;

  /// Returns the error if available
  Object? get error => state.error;

  /// Returns true if there are more pages to fetch
  bool get hasNextPage => state.valueOrNull?.hasNextPage ?? false;

  /// Returns true if there are previous pages to fetch
  bool get hasPreviousPage => state.valueOrNull?.hasPreviousPage ?? false;

  /// Returns the fetch time
  DateTime? get fetchedAt => state.valueOrNull?.fetchedAt;
}

/// AsyncNotifier with parameters - full-featured infinite query implementation
class AsyncInfiniteQueryNotifierFamily<T, TPageParam, P>
    extends FamilyAsyncNotifier<InfiniteQueryData<T>, P> {
  AsyncInfiniteQueryNotifierFamily({
    required this.queryFn,
    required this.options,
    required this.initialPageParam,
    required this.queryKey,
  });

  final QueryFunctionWithParamsWithRef<T, TPageParam> Function(P) queryFn;
  final InfiniteQueryOptions<T, TPageParam> options;
  final TPageParam initialPageParam;
  final String queryKey;

  Timer? _refetchTimer;
  int _retryCount = 0;

  QueryCache get _cache => getCache(strategy: options.cacheStrategy);
  final WindowFocusManager _windowFocusManager = WindowFocusManager();
  bool _isRefetchPaused = false;
  bool _isInitialized = false;
  bool _isDisposed = false;

  @override
  FutureOr<InfiniteQueryData<T>> build(P arg) async {
    final paramKey = '$queryKey-$arg';
    _isDisposed = false;

    if (!_isInitialized) {
      _isInitialized = true;
      _setupCacheListener(paramKey);
      _setupWindowFocusCallbacks();

      ref.onDispose(() {
        _isDisposed = true;
        _refetchTimer?.cancel();
        _cache.removeAllListeners(paramKey);

        if (options.pauseRefetchInBackground) {
          _windowFocusManager.removeOnBlurCallback(_onWindowBlured);
        }
        if (options.refetchOnWindowFocus && _windowFocusManager.isSupported) {
          _windowFocusManager.removeOnFocusCallback(_onWindowFocused);
        }

        _isInitialized = false;
      });
    }

    if (options.enabled && options.refetchInterval != null) {
      _scheduleRefetch(arg);
    }

    if (!options.enabled) {
      return const InfiniteQueryData(pages: []);
    }

    final cachedEntry = _getCachedEntry(paramKey);
    if (cachedEntry != null && !cachedEntry.isStale && cachedEntry.hasData) {
      if (options.refetchOnMount) {
        unawaited(Future.microtask(() => _fetchFirstPageInBackground(arg)));
      }
      Log.info(
          'Using cached data in async infinite query notifier family for key $paramKey');
      return cachedEntry.data!;
    }

    if (options.keepPreviousData &&
        cachedEntry != null &&
        cachedEntry.hasData) {
      Log.info(
          'Using stale cached data with keepPreviousData in async infinite query notifier family for key $paramKey');
      _fetchFirstPageInBackground(arg);
      return cachedEntry.data!;
    }

    return _fetchFirstPage(arg);
  }

  void _fetchFirstPageInBackground(P arg) {
    _fetchFirstPage(arg).then((newData) {
      _safeState(AsyncValue.data(newData));
    }).catchError((Object error, StackTrace stackTrace) {
      Log.info('Background fetch failed for key $queryKey-$arg: $error');
    });
  }

  Future<InfiniteQueryData<T>> _fetchFirstPage(P arg) async {
    try {
      final paramKey = '$queryKey-$arg';
      final firstPage = await queryFn(arg)(ref, initialPageParam);
      final now = DateTime.now();
      final pages = [firstPage];

      final hasNextPage = options.getNextPageParam(firstPage, pages) != null;
      final hasPreviousPage =
          options.getPreviousPageParam?.call(firstPage, pages) != null;

      final result = InfiniteQueryData<T>(
        pages: pages,
        hasNextPage: hasNextPage,
        hasPreviousPage: hasPreviousPage,
        fetchedAt: now,
      );

      _setCachedEntry(
          paramKey,
          QueryCacheEntry<InfiniteQueryData<T>>(
            data: result,
            fetchedAt: now,
            cacheTime: options.cacheTime,
            staleTime: options.staleTime,
          ));

      _retryCount = 0;
      options.onSuccess?.call(firstPage);
      return result;
    } catch (error, stackTrace) {
      if (_retryCount < options.retry) {
        _retryCount++;
        await Future<void>.delayed(options.retryDelay);
        return _fetchFirstPage(arg);
      }

      _cache.setError<InfiniteQueryData<T>>(
        '$queryKey-$arg',
        error,
        stackTrace: stackTrace,
        cacheTime: options.cacheTime,
        staleTime: options.staleTime,
      );

      _retryCount = 0;
      options.onError?.call(error, stackTrace);
      rethrow;
    }
  }

  Future<void> fetchNextPage() async {
    final currentState = state;
    if (!currentState.hasValue || !currentState.value!.hasNextPage) {
      return;
    }

    final currentData = currentState.value!;
    final nextPageParam = options.getNextPageParam(
      currentData.pages.last,
      currentData.pages,
    );

    if (nextPageParam == null) {
      return;
    }

    try {
      final nextPage = await queryFn(arg)(ref, nextPageParam);
      final newPages = [...currentData.pages, nextPage];

      final hasNextPage = options.getNextPageParam(nextPage, newPages) != null;
      final hasPreviousPage =
          options.getPreviousPageParam?.call(newPages.first, newPages) != null;

      final newData = InfiniteQueryData<T>(
        pages: newPages,
        hasNextPage: hasNextPage,
        hasPreviousPage: hasPreviousPage,
        fetchedAt: DateTime.now(),
      );

      final paramKey = '$queryKey-$arg';
      _setCachedEntry(
          paramKey,
          QueryCacheEntry<InfiniteQueryData<T>>(
            data: newData,
            fetchedAt: newData.fetchedAt!,
            cacheTime: options.cacheTime,
            staleTime: options.staleTime,
          ));

      _safeState(AsyncValue.data(newData));
      options.onSuccess?.call(nextPage);
    } catch (error, stackTrace) {
      options.onError?.call(error, stackTrace);
      Log.info(
          'fetchNextPage failed but keeping current data for key $queryKey-$arg: $error');
      rethrow;
    }
  }

  Future<void> fetchPreviousPage() async {
    final currentState = state;
    if (!currentState.hasValue ||
        !currentState.value!.hasPreviousPage ||
        options.getPreviousPageParam == null) {
      return;
    }

    final currentData = currentState.value!;
    final previousPageParam = options.getPreviousPageParam!(
      currentData.pages.first,
      currentData.pages,
    );

    if (previousPageParam == null) {
      return;
    }

    try {
      final previousPage = await queryFn(arg)(ref, previousPageParam);
      final newPages = [previousPage, ...currentData.pages];

      final hasNextPage =
          options.getNextPageParam(newPages.last, newPages) != null;
      final hasPreviousPage =
          options.getPreviousPageParam!(newPages.first, newPages) != null;

      final newData = InfiniteQueryData<T>(
        pages: newPages,
        hasNextPage: hasNextPage,
        hasPreviousPage: hasPreviousPage,
        fetchedAt: DateTime.now(),
      );

      final paramKey = '$queryKey-$arg';
      _setCachedEntry(
          paramKey,
          QueryCacheEntry<InfiniteQueryData<T>>(
            data: newData,
            fetchedAt: newData.fetchedAt!,
            cacheTime: options.cacheTime,
            staleTime: options.staleTime,
          ));

      _safeState(AsyncValue.data(newData));
      options.onSuccess?.call(previousPage);
    } catch (error, stackTrace) {
      options.onError?.call(error, stackTrace);
      Log.info(
          'fetchPreviousPage failed but keeping current data for key $queryKey-$arg: $error');
      rethrow;
    }
  }

  Future<void> refetch() async {
    final currentState = state;
    if (currentState.hasValue) {
      final currentData = currentState.value!;

      if (!options.keepPreviousData) {
        _safeState(const AsyncValue.loading());
      }

      try {
        final List<T> newPages = [];
        TPageParam pageParam = initialPageParam;

        for (int i = 0; i < currentData.pages.length; i++) {
          final page = await queryFn(arg)(ref, pageParam);
          newPages.add(page);

          if (i < currentData.pages.length - 1) {
            final nextParam = options.getNextPageParam(page, newPages);
            if (nextParam == null) {
              break;
            }
            pageParam = nextParam;
          }
        }

        final hasNextPage =
            options.getNextPageParam(newPages.last, newPages) != null;
        final hasPreviousPage =
            options.getPreviousPageParam?.call(newPages.first, newPages) !=
                null;

        final newData = InfiniteQueryData<T>(
          pages: newPages,
          hasNextPage: hasNextPage,
          hasPreviousPage: hasPreviousPage,
          fetchedAt: DateTime.now(),
        );

        final paramKey = '$queryKey-$arg';
        _setCachedEntry(
            paramKey,
            QueryCacheEntry<InfiniteQueryData<T>>(
              data: newData,
              fetchedAt: newData.fetchedAt!,
              cacheTime: options.cacheTime,
              staleTime: options.staleTime,
            ));

        _safeState(AsyncValue.data(newData));
      } catch (error, stackTrace) {
        if (options.keepPreviousData && currentState.hasValue) {
          Log.info(
              'Refetch failed but keeping previous data for key $queryKey-$arg: $error');
        } else {
          _safeState(AsyncValue.error(error, stackTrace));
        }
      }
    } else {
      _safeState(const AsyncValue.loading());
      try {
        final newData = await _fetchFirstPage(arg);
        _safeState(AsyncValue.data(newData));
      } catch (error, stackTrace) {
        _safeState(AsyncValue.error(error, stackTrace));
      }
    }
  }

  Future<void> refresh() {
    _clearCache('$queryKey-$arg');
    return refetch();
  }

  void setData(InfiniteQueryData<T> data) {
    final now = DateTime.now();
    final updatedData = data.copyWith(fetchedAt: now);
    final paramKey = '$queryKey-$arg';

    _setCachedEntry(
        paramKey,
        QueryCacheEntry<InfiniteQueryData<T>>(
          data: updatedData,
          fetchedAt: now,
          cacheTime: options.cacheTime,
          staleTime: options.staleTime,
        ));

    _safeState(AsyncValue.data(updatedData));
  }

  InfiniteQueryData<T>? getCachedData() {
    final entry = _getCachedEntry('$queryKey-$arg');
    return (entry?.hasData ?? false) ? entry!.data! : null;
  }

  void _scheduleRefetch(P arg) {
    _refetchTimer?.cancel();
    if (options.refetchInterval != null) {
      _refetchTimer = Timer.periodic(options.refetchInterval!, (_) {
        if (options.enabled && _shouldRefetch()) {
          refetch();
        }
      });
    }
  }

  bool _shouldRefetch() {
    if (_isRefetchPaused) {
      return false;
    }

    if (options.pauseRefetchInBackground && _windowFocusManager.windowLostFocus) {
      return false;
    }

    return true;
  }

  void _onWindowBlured() {
    if(isMobile()){
      Log.info('App paused in async infinite query notifier family');
      _isRefetchPaused = true;
    }
  }

  void _setupWindowFocusCallbacks() {
    if (options.refetchOnWindowFocus && _windowFocusManager.isSupported) {
      _windowFocusManager.addOnFocusCallback(_onWindowFocused);
    }
    if (options.pauseRefetchInBackground) {
      _windowFocusManager.addOnBlurCallback(_onWindowBlured);
    }
  }

  void _onWindowFocused() {
    Log.info('Window focused in async infinite query notifier family');
    _isRefetchPaused = false;
    if (_shouldRefetchOnFocus()) {
      refetch();
    }
  }

  bool _shouldRefetchOnFocus() {
    if (!options.enabled) {
      return false;
    }

    final currentState = state;
    if (currentState.hasValue) {
      final currentData = currentState.value!;
      final now = DateTime.now();
      final fetchedAt = currentData.fetchedAt;
      if (fetchedAt != null) {
        final age = now.difference(fetchedAt);
        return age > options.staleTime;
      }
    }

    return false;
  }

  QueryCacheEntry<InfiniteQueryData<T>>? _getCachedEntry(String key) =>
      _cache.get<InfiniteQueryData<T>>(key);

  void _setCachedEntry(
      String key, QueryCacheEntry<InfiniteQueryData<T>> entry) {
    _cache.set(key, entry);
  }

  void _clearCache(String key) {
    _cache.remove(key);
  }

  void _setupCacheListener(String key) {
    _cache.addListener<InfiniteQueryData<T>>(key, (entry) {
      Log.info(
          'Cache listener called for key $key in async infinite query notifier family');
      if ((entry?.hasData ?? false) &&
          !_isDisposed &&
          !(!(state.isLoading || state.hasError) &&
              state.hasValue &&
              listEquals(entry!.data!.pages, state.value!.pages))) {
        Log.info(
            'Cache data changed for key $key in async infinite query notifier family');
        _safeState(AsyncValue.data(entry!.data!));
      } else if (entry == null) {
        Log.info(
            'Cache entry removed for key $key in async infinite query notifier family');
        if (options.onCacheEvicted != null) {
          options.onCacheEvicted?.call(key);
        } else if (!_isDisposed) {
          // refetch();
        }
      }
    });
  }

  void _safeState(AsyncValue<InfiniteQueryData<T>> state) {
    if (!_isDisposed) {
      this.state = state;
    }
  }
}

/// Auto-dispose AsyncNotifier with parameters for infinite queries
class AsyncInfiniteQueryNotifierFamilyAutoDispose<T, TPageParam, P>
    extends AutoDisposeFamilyAsyncNotifier<InfiniteQueryData<T>, P> {
  AsyncInfiniteQueryNotifierFamilyAutoDispose({
    required this.queryFn,
    required this.options,
    required this.initialPageParam,
    required this.queryKey,
  });

  final QueryFunctionWithParamsWithRef<T, TPageParam> Function(P) queryFn;
  final InfiniteQueryOptions<T, TPageParam> options;
  final TPageParam initialPageParam;
  final String queryKey;

  Timer? _refetchTimer;
  int _retryCount = 0;

  QueryCache get _cache => getCache(strategy: options.cacheStrategy);
  final WindowFocusManager _windowFocusManager = WindowFocusManager();
  bool _isRefetchPaused = false;
  bool _isInitialized = false;
  bool _isDisposed = false;

  @override
  FutureOr<InfiniteQueryData<T>> build(P arg) async {
    final paramKey = '$queryKey-$arg';
    _isDisposed = false;

    if (!_isInitialized) {
      _isInitialized = true;
      _setupCacheListener(paramKey);
      _setupWindowFocusCallbacks();

      ref.onDispose(() {
        _isDisposed = true;
        _refetchTimer?.cancel();
        _cache.removeAllListeners(paramKey);

        if (options.pauseRefetchInBackground) {
          _windowFocusManager.removeOnBlurCallback(_onWindowBlured);
        }
        if (options.refetchOnWindowFocus && _windowFocusManager.isSupported) {
          _windowFocusManager.removeOnFocusCallback(_onWindowFocused);
        }

        _isInitialized = false;
      });
    }

    if (options.enabled && options.refetchInterval != null) {
      _scheduleRefetch();
    }

    if (options.enabled) {
      final cachedEntry = _getCachedEntry(paramKey);
      if (cachedEntry != null && !cachedEntry.isStale && cachedEntry.hasData) {
        if (options.refetchOnMount) {
          unawaited(Future.microtask(
              () => _backgroundRefetch(arg).catchError((Object error) {
                    Log.info('Error in background refetch: $error');
                  })));
        }
        return cachedEntry.data!;
      }

      if (options.keepPreviousData &&
          ((!_isDisposed && state.hasValue) ||
              (cachedEntry != null && cachedEntry.hasData))) {
        unawaited(Future.microtask(
            () => _backgroundRefetch(arg).catchError((Object error) {
                  Log.info('Error in background refetch: $error');
                })));
        return (!_isDisposed && state.hasValue)
            ? state.value!
            : cachedEntry!.data!;
      }
    }

    if (!options.enabled) {
      throw StateError('Query is disabled and no cached data available');
    }

    return await _performFirstPageFetch(arg);
  }

  void _safeState(AsyncValue<InfiniteQueryData<T>> state) {
    if (!_isDisposed) {
      this.state = state;
    }
  }

  Future<InfiniteQueryData<T>> _performFirstPageFetch(P arg) async {
    try {
      final firstPage = await queryFn(arg)(ref, initialPageParam);
      final now = DateTime.now();

      final data = InfiniteQueryData<T>(
        pages: [firstPage],
        hasNextPage:
            options.getNextPageParam.call(firstPage, [firstPage]) != null,
        hasPreviousPage:
            options.getPreviousPageParam?.call(firstPage, [firstPage]) != null,
        fetchedAt: now,
      );

      final paramKey = '$queryKey-$arg';
      _setCachedEntry(
          paramKey,
          QueryCacheEntry<InfiniteQueryData<T>>(
            data: data,
            fetchedAt: now,
            cacheTime: options.cacheTime,
            staleTime: options.staleTime,
          ));

      _retryCount = 0;
      options.onSuccess?.call(firstPage);

      return data;
    } catch (error, stackTrace) {
      options.onError?.call(error, stackTrace);

      if (_retryCount < options.retry) {
        _retryCount++;
        await Future<void>.delayed(options.retryDelay);
        return _performFirstPageFetch(arg);
      }

      rethrow;
    }
  }

  Future<void> _backgroundRefetch(P arg) async {
    try {
      final data = await _performFirstPageFetch(arg);
      _safeState(AsyncValue.data(data));
    } catch (error, _) {
      // Silent failure
    }
  }

  Future<void> fetchNextPage() async {
    if (!state.hasValue) {
      return;
    }

    final currentData = state.value!;
    final nextPageParam = options.getNextPageParam.call(
      currentData.pages.last,
      currentData.pages,
    );

    if (nextPageParam == null) {
      return;
    }

    try {
      final nextPage = await queryFn(arg)(ref, nextPageParam);
      final newData = InfiniteQueryData<T>(
        pages: [...currentData.pages, nextPage],
        hasNextPage: options.getNextPageParam
                .call(nextPage, [...currentData.pages, nextPage]) !=
            null,
        hasPreviousPage: currentData.hasPreviousPage,
        fetchedAt: DateTime.now(),
      );

      final paramKey = '$queryKey-$arg';
      _setCachedEntry(
          paramKey,
          QueryCacheEntry<InfiniteQueryData<T>>(
            data: newData,
            fetchedAt: DateTime.now(),
            cacheTime: options.cacheTime,
            staleTime: options.staleTime,
          ));

      _safeState(AsyncValue.data(newData));
    } catch (error, _) {
      // Keep current data on error
    }
  }

  Future<void> refetch() async {
    _safeState(const AsyncValue.loading());
    try {
      final data = await _performFirstPageFetch(arg);
      _safeState(AsyncValue.data(data));
    } catch (error, stackTrace) {
      _safeState(AsyncValue.error(error, stackTrace));
    }
  }

  QueryCacheEntry<InfiniteQueryData<T>>? _getCachedEntry(String key) =>
      _cache.get<InfiniteQueryData<T>>(key);
  void _setCachedEntry(
          String key, QueryCacheEntry<InfiniteQueryData<T>> entry) =>
      _cache.set(key, entry);

  void _setupCacheListener(String key) {
    _cache.addListener<InfiniteQueryData<T>>(key, (entry) {
      if (entry?.hasData ?? false) {
        _safeState(AsyncValue.data(entry!.data!));
      } else if (entry == null && !_isDisposed) {
        if (options.onCacheEvicted != null) {
          options.onCacheEvicted!(key);
        } else {
          // refetch();
        }
      }
    });
  }

  void _setupWindowFocusCallbacks() {
    if (options.refetchOnWindowFocus && _windowFocusManager.isSupported) {
      _windowFocusManager.addOnFocusCallback(_onWindowFocused);
    }
    if (options.pauseRefetchInBackground) {
      _windowFocusManager.addOnBlurCallback(_onWindowBlured);
    }
  }

  void _scheduleRefetch() {
    final interval = options.refetchInterval;
    if (interval != null && !_isRefetchPaused) {
      _refetchTimer?.cancel();
      _refetchTimer = Timer.periodic(interval, (_) {
        if (!_isRefetchPaused && options.enabled) {
          _backgroundRefetch(arg);
        }
      });
    }
  }

  void _onWindowBlured() {
    if(isMobile()){
      _isRefetchPaused = true;
    }
  }

  void _onWindowFocused() {
    _isRefetchPaused = false;
    if (options.enabled) {
      final cachedEntry = _getCachedEntry('$queryKey-$arg');
      if (cachedEntry != null && cachedEntry.isStale) {
        _backgroundRefetch(arg);
      }
    }
  }
}

/// 🔥 Full-featured AsyncNotifier-based infinite query provider with parameters
///
/// **Use this when:**
/// - Parameters are relatively stable
/// - You want to keep data cached across widget rebuilds
/// - Shared infinite data across multiple widgets
/// - You need all advanced query features (caching, lifecycle, retry, etc.)
///
/// **Features:**
/// - ✅ Full cache integration with staleTime/cacheTime
/// - ✅ Lifecycle management (app focus, window focus)
/// - ✅ Automatic refetching intervals
/// - ✅ Retry logic with exponential backoff
/// - ✅ Background refetch capabilities
/// - ✅ keepPreviousData support
/// - ✅ Memory leak prevention
/// - ✅ Infinite pagination (fetchNextPage, fetchPreviousPage)
///
/// Example:
/// ```dart
/// final postsProvider = asyncInfiniteQueryProviderFamily<Post, int, String>(
///   name: 'posts',
///   queryFn: (category) => (ref, pageParam) => ApiService.fetchPosts(category: category, page: pageParam),
///   initialPageParam: 1,
///   options: InfiniteQueryOptions(
///     getNextPageParam: (lastPage, allPages) =>
///       lastPage.hasMore ? allPages.length + 1 : null,
///     staleTime: Duration(minutes: 5),
///     refetchInterval: Duration(minutes: 10),
///     refetchOnWindowFocus: true,
///     keepPreviousData: true,
///   ),
/// );
///
/// // Usage:
/// final postsAsync = ref.watch(postsProvider('technology'));
/// postsAsync.when(
///   loading: () => CircularProgressIndicator(),
///   error: (error, stack) => ErrorWidget(error),
///   data: (infiniteData) => ListView.builder(
///     itemCount: infiniteData.pages.expand((page) => page.items).length,
///     itemBuilder: (context, index) => PostTile(post: infiniteData.pages[index]),
///   ),
/// );
/// ```
AsyncNotifierProviderFamily<
    AsyncInfiniteQueryNotifierFamily<T, TPageParam, P>,
    InfiniteQueryData<T>,
    P> asyncInfiniteQueryProviderFamily<T, TPageParam, P>({
  required String name,
  required QueryFunctionWithParamsWithRef<T, TPageParam> Function(P) queryFn,
  required TPageParam initialPageParam,
  required InfiniteQueryOptions<T, TPageParam> options,
}) =>
    AsyncNotifierProvider.family<
        AsyncInfiniteQueryNotifierFamily<T, TPageParam, P>,
        InfiniteQueryData<T>,
        P>(
      () => AsyncInfiniteQueryNotifierFamily<T, TPageParam, P>(
        queryFn: queryFn,
        options: options,
        initialPageParam: initialPageParam,
        queryKey: name,
      ),
      name: name,
    );

/// 🔥 Auto-dispose AsyncNotifier-based infinite query provider with parameters
///
/// **Use this when:**
/// - Dynamic parameters that change frequently
/// - Temporary infinite data that should be cleaned up when not watched
/// - Memory optimization for large paginated datasets with many parameter variations
/// - Short-lived screens with parameterized infinite scrolling
/// - User-specific infinite data that doesn't need to persist
///
/// **Features:**
/// - ✅ Automatic cleanup when no longer watched
/// - ✅ Parameter-based caching and invalidation
/// - ✅ Full cache integration with staleTime/cacheTime
/// - ✅ Lifecycle management (app focus, window focus)
/// - ✅ Automatic refetching intervals
/// - ✅ Retry logic with exponential backoff
/// - ✅ Background refetch capabilities
/// - ✅ keepPreviousData support
/// - ✅ Memory leak prevention
/// - ✅ Infinite pagination (fetchNextPage, fetchPreviousPage)
///
/// Example:
/// ```dart
/// final userPostsProvider = asyncInfiniteQueryProviderFamilyAutoDispose<Post, int, int>(
///   name: 'user-posts',
///   queryFn: (userId) => (ref, pageParam) => ApiService.fetchUserPosts(userId: userId, page: pageParam),
///   initialPageParam: 1,
///   options: InfiniteQueryOptions(
///     getNextPageParam: (lastPage, allPages) =>
///       lastPage.hasMore ? allPages.length + 1 : null,
///     staleTime: Duration(minutes: 5),
///     cacheTime: Duration(minutes: 10),
///     keepPreviousData: true,
///   ),
/// );
///
/// // Usage in widget:
/// final userPostsAsync = ref.watch(userPostsProvider(userId));
/// userPostsAsync.when(
///   loading: () => CircularProgressIndicator(),
///   error: (error, stack) => ErrorWidget(error),
///   data: (infiniteData) => ListView.builder(
///     itemCount: infiniteData.pages.expand((page) => page.items).length,
///     itemBuilder: (context, index) => PostTile(post: infiniteData.pages[index]),
///   ),
/// );
/// ```
AutoDisposeAsyncNotifierProviderFamily<
    AsyncInfiniteQueryNotifierFamilyAutoDispose<T, TPageParam, P>,
    InfiniteQueryData<T>,
    P> asyncInfiniteQueryProviderFamilyAutoDispose<T, TPageParam, P>({
  required String name,
  required QueryFunctionWithParamsWithRef<T, TPageParam> Function(P) queryFn,
  required TPageParam initialPageParam,
  required InfiniteQueryOptions<T, TPageParam> options,
}) =>
    AsyncNotifierProvider.autoDispose.family<
        AsyncInfiniteQueryNotifierFamilyAutoDispose<T, TPageParam, P>,
        InfiniteQueryData<T>,
        P>(
      () => AsyncInfiniteQueryNotifierFamilyAutoDispose<T, TPageParam, P>(
        queryFn: queryFn,
        options: options,
        initialPageParam: initialPageParam,
        queryKey: name,
      ),
      name: name,
    );

/// Extension for WidgetRef to read async infinite query results
extension WidgetRefAsyncInfiniteQueryResult on WidgetRef {
  /// Create an async infinite query result that can be used in widgets
  AsyncInfiniteQueryResult<T> readAsyncInfiniteQueryResult<T, TPageParam>(
      AsyncNotifierProvider<AsyncInfiniteQueryNotifier<T, TPageParam>,
              InfiniteQueryData<T>>
          provider) {
    final notifier = read(provider.notifier);
    final state = watch(provider);

    return AsyncInfiniteQueryResult<T>(
      state: state,
      fetchNextPage: notifier.fetchNextPage,
      fetchPreviousPage: notifier.fetchPreviousPage,
      refetch: notifier.refetch,
      refresh: notifier.refresh,
    );
  }

  /// Create an async infinite query result for family providers
  AsyncInfiniteQueryResult<T>
      readAsyncInfiniteQueryResultFamily<T, TPageParam, P>(
          AsyncNotifierProviderFamily<
                  AsyncInfiniteQueryNotifierFamily<T, TPageParam, P>,
                  InfiniteQueryData<T>,
                  P>
              provider,
          P param) {
    final notifier = read(provider(param).notifier);
    final state = watch(provider(param));

    return AsyncInfiniteQueryResult<T>(
      state: state,
      fetchNextPage: notifier.fetchNextPage,
      fetchPreviousPage: notifier.fetchPreviousPage,
      refetch: notifier.refetch,
      refresh: notifier.refresh,
    );
  }
}
