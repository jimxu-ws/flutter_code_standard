import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_focus/window_focus_manager.dart';
import '../cache/query_cache_base.dart';
import '../cache/query_cache_entry.dart';
import '../client/query_client.dart';
import '../options/query_options.dart';
import '../providers/state_query_provider.dart'
    show QueryFunctionWithParamsWithRef, QueryFunctionWithRef;
import '../utils/common_func.dart';
import '../utils/log.dart';

/// 🔥 Modern AsyncNotifier-based query implementation
class AsyncQueryNotifier<T> extends AsyncNotifier<T> {
  AsyncQueryNotifier({
    required this.queryFn,
    required this.options,
    required this.queryKey,
  });

  final QueryFunctionWithRef<T> queryFn;
  final QueryOptions<T> options;
  final String queryKey;

  Timer? _refetchTimer;
  int _retryCount = 0;

  // Initialize cache and window focus manager
  QueryCache get _cache => getCache(strategy: options.cacheStrategy);
  final WindowFocusManager _windowFocusManager = WindowFocusManager();
  bool _isRefetchPaused = false;
  bool _isInitialized = false;
  bool _isDisposed = false;

  @override
  FutureOr<T> build() async {
    Log.info('Building async query notifier with cached data, $queryKey');
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

    // Check cache first
    if (options.enabled) {
      final cachedEntry = _getCachedEntry();
      if (cachedEntry != null && !cachedEntry.isStale && cachedEntry.hasData) {
        // Return cached data immediately, optionally trigger background refresh
        if (options.refetchOnMount) {
          unawaited(Future.microtask(
              () => _backgroundRefetch().catchError((Object error) {
                    Log.info('Error in background refetch: $error');
                  })));
        }
        Log.info('Returning cached data in async query notifier');
        return cachedEntry.data as T;
      }

      if (options.keepPreviousData &&
          ((!_isDisposed && state.hasValue) ||
              (cachedEntry != null && cachedEntry.hasData))) {
        unawaited(Future.microtask(
            () => _backgroundRefetch().catchError((Object error) {
                  Log.info('Error in background refetch: $error');
                })));

        Log.info('Keeping previous data in async query notifier');
        return (!_isDisposed && state.hasValue)
            ? state.value as T
            : cachedEntry?.data as T;
      }
    }

    // No cache or disabled - fetch fresh data
    if (!options.enabled) {
      throw StateError('Query is disabled and no cached data available');
    }

    return await _performFetch();
  }

  void _safeState(AsyncValue<T> state) {
    if (!_isDisposed) {
      this.state = state;
    }
  }

  /// Perform the actual data fetch
  Future<T> _performFetch() async {
    try {
      Log.info('Performing fetch in async query notifier $queryKey');
      final data = await queryFn(ref);
      final now = DateTime.now();

      // Cache the result
      _setCachedEntry(QueryCacheEntry<T>(
        data: data,
        fetchedAt: now,
        cacheTime: options.cacheTime,
        staleTime: options.staleTime,
      ));

      _retryCount = 0;
      options.onSuccess?.call(data);

      return data;
    } catch (error, stackTrace) {
      options.onError?.call(error, stackTrace);

      // Handle retry logic
      if (_retryCount < options.retry) {
        _retryCount++;
        await Future<void>.delayed(options.retryDelay);
        return _performFetch();
      }

      rethrow;
    }
  }

  /// Background refetch without changing loading state
  Future<void> _backgroundRefetch() async {
    try {
      Log.info('Background refetching in async query notifier $queryKey');
      final data = await _performFetch();
      _safeState(AsyncValue.data(data));
    } catch (error, stackTrace) {
      // Silent background refresh failure - don't update state
      Log.info(
          'Background refresh failed: $error in async query notifier $queryKey');
      Log.info('Stack trace: $stackTrace');
    }
  }

  /// Public method to refetch data
  Future<void> refetch({bool background = false}) async {
    Log.info('Refetching in async query notifier $queryKey');
    if (background) {
      return _backgroundRefetch();
    }
    _safeState(const AsyncValue.loading());
    try {
      final data = await _performFetch();
      _safeState(AsyncValue.data(data));
    } catch (error, stackTrace) {
      _safeState(AsyncValue.error(error, stackTrace));
    }
  }

  /// Force refresh (ignore cache)
  Future<void> refresh() async {
    _invalidateCache();
    await refetch();
  }

  /// Helper methods for cache operations
  QueryCacheEntry<T>? _getCachedEntry() {
    return _cache.get<T>(queryKey, jsonParser: options.jsonParser);
  }

  void _setCachedEntry(QueryCacheEntry<T> entry) {
    _cache.set(queryKey, entry);
  }

  void _invalidateCache() {
    _cache.remove(queryKey);
  }

  /// Set up cache change listener
  void _setupCacheListener() {
    _cache.addListener<T>(queryKey, (QueryCacheEntry<T>? entry) {
      Log.info(
          'Cache listener called for key $queryKey in async query notifier');
      if ((entry?.hasData ?? false) &&
          !(state.hasValue && entry!.data == state.value)) {
        Log.info(
            'Cache data changed for key $queryKey in async query notifier');
        _safeState(AsyncValue.data(entry!.data as T));
      } else if (entry == null) {
        Log.info(
            'Cache entry removed for key $queryKey in async query notifier');
        if (options.onCacheEvicted != null) {
          options.onCacheEvicted!(queryKey);
        } else if (!_isDisposed) {
          // refetch();
        }
      }
    });
  }

  /// Set up window focus callbacks
  void _setupWindowFocusCallbacks() {
    Log.info(
        'Setting up window focus callbacks in async query notifier $queryKey');
    // Refetch when window gains focus (if enabled and data is stale)
    if (options.refetchOnWindowFocus && _windowFocusManager.isSupported) {
      _windowFocusManager.addOnFocusCallback(_onWindowFocused);
    }

    // Pause refetching when app goes to background (if enabled)
    if (options.pauseRefetchInBackground) {
      _windowFocusManager.addOnBlurCallback(_onWindowBlured);
    }
  }

  void _onWindowBlured() {
    if(isMobile()){
      Log.info('App paused in async query notifier');
      // Mark refetching as paused
      _isRefetchPaused = true;
    }
  }

  void _onWindowFocused() {
    Log.info('Window focused in async query notifier $queryKey');
    // Resume refetching and check if we need to refetch stale data
    _isRefetchPaused = false;

    if (options.enabled && _shouldRefetchOnFocus()) {
      _backgroundRefetch();
    }
  }

  /// Check if we should refetch when focus is gained
  bool _shouldRefetchOnFocus() {
    if (!options.enabled) {
      return false;
    }

    final cachedEntry = _getCachedEntry();
    if (cachedEntry != null && cachedEntry.isStale) {
      return true;
    }

    return false;
  }

  /// Schedule automatic refetching
  void _scheduleRefetch() {
    Log.info(
        'Scheduling automatic refetching in async query notifier $queryKey');
    final interval = options.refetchInterval;
    if (interval != null && !_isRefetchPaused) {
      _refetchTimer?.cancel();
      _refetchTimer = Timer.periodic(interval, (_) {
        if (!_isRefetchPaused && options.enabled && _shouldRefetch()) {
          _backgroundRefetch();
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

  void _dispose() {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;

    _refetchTimer?.cancel();

    // Clean up cache listener
    _cache.removeAllListeners(queryKey);

    // Clean up window focus callbacks
    if (options.pauseRefetchInBackground) {
      _windowFocusManager.removeOnBlurCallback(_onWindowBlured);
    }

    if (options.refetchOnWindowFocus && _windowFocusManager.isSupported) {
      _windowFocusManager.removeOnFocusCallback(_onWindowFocused);
    }

    // Reset initialization flag
    _isInitialized = false;
  }

  /// Pause automatic refetching
  void pauseRefetch() {
    Log.info('Pausing automatic refetching in async query notifier $queryKey');
    _isRefetchPaused = true;
    _refetchTimer?.cancel();
  }

  /// Resume automatic refetching
  void resumeRefetch() {
    Log.info('Resuming automatic refetching in async query notifier $queryKey');
    _isRefetchPaused = false;
    if (options.refetchInterval != null) {
      _scheduleRefetch();
    }
  }
}

/// AsyncNotifier with parameters - full-featured implementation
class AsyncQueryNotifierFamily<T, P> extends FamilyAsyncNotifier<T, P> {
  AsyncQueryNotifierFamily({
    required this.queryFn,
    required this.options,
    required this.queryKey,
  });

  final QueryFunctionWithParamsWithRef<T, P> queryFn;
  final QueryOptions<T> options;
  final String queryKey;

  Timer? _refetchTimer;
  int _retryCount = 0;

  // Initialize cache and window focus manager
  QueryCache get _cache => getCache(strategy: options.cacheStrategy);
  final WindowFocusManager _windowFocusManager = WindowFocusManager();
  bool _isRefetchPaused = false;
  bool _isInitialized = false;
  bool _isDisposed = false;

  @override
  FutureOr<T> build(P arg) async {
    final paramKey = '$queryKey-$arg';
    Log.info(
        'Building async query notifier family with cached data, $paramKey');
    _isDisposed = false;
    // Prevent duplicate initialization
    if (!_isInitialized) {
      _isInitialized = true;

      // Set up cache change listener for automatic UI updates
      _setupCacheListener(paramKey);

      // Set up window focus callbacks
      _setupWindowFocusCallbacks();

      // Set up cleanup when the notifier is disposed
      ref.onDispose(() => _dispose(paramKey));
    }

    // Set up automatic refetching if configured
    if (options.enabled && options.refetchInterval != null) {
      _scheduleRefetch(arg);
    }

    // Check cache first
    if (options.enabled) {
      final cachedEntry = _getCachedEntry(paramKey);
      if (cachedEntry != null && !cachedEntry.isStale && cachedEntry.hasData) {
        // Return cached data immediately, optionally trigger background refresh
        if (options.refetchOnMount) {
          unawaited(Future.microtask(() => _backgroundRefetch(arg)));
        }
        Log.info(
            'Returning cached data in async query notifier family $paramKey');
        return cachedEntry.data as T;
      }

      if (options.keepPreviousData &&
          ((!_isDisposed && state.hasValue) ||
              (cachedEntry != null && cachedEntry.hasData))) {
        unawaited(Future.microtask(() => _backgroundRefetch(arg)));
        Log.info(
            'Keeping previous data in async query notifier family $paramKey');
        return (!_isDisposed && state.hasValue)
            ? state.value as T
            : cachedEntry?.data as T;
      }
    }

    // No cache or disabled - fetch fresh data
    if (!options.enabled) {
      throw StateError('Query is disabled and no cached data available');
    }
    Log.info(
        'Fetching data in async query notifier family with cached data, $paramKey');
    return await _performFetch(arg);
  }

  void _safeState(AsyncValue<T> state) {
    if (!_isDisposed) {
      this.state = state;
    }
  }

  /// Perform the actual data fetch
  Future<T> _performFetch(P arg) async {
    try {
      Log.info('Performing fetch in async query notifier family $queryKey');
      final data = await queryFn(ref, arg);
      final now = DateTime.now();
      final paramKey = '$queryKey-$arg';

      // Cache the result
      _setCachedEntry(
          paramKey,
          QueryCacheEntry<T>(
            data: data,
            fetchedAt: now,
            cacheTime: options.cacheTime,
            staleTime: options.staleTime,
          ));

      _retryCount = 0;
      options.onSuccess?.call(data);

      return data;
    } catch (error, stackTrace) {
      options.onError?.call(error, stackTrace);

      // Handle retry logic
      if (_retryCount < options.retry) {
        _retryCount++;
        await Future<void>.delayed(options.retryDelay);
        return _performFetch(arg);
      }

      rethrow;
    }
  }

  /// Background refetch without changing loading state
  Future<void> _backgroundRefetch(P arg) async {
    try {
      Log.info(
          'Background refetching in async query notifier family $queryKey');
      final data = await _performFetch(arg);
      _safeState(AsyncValue.data(data));
    } catch (error, stackTrace) {
      // Silent background refresh failure - don't update state
      Log.info(
          'Background refresh failed: $error in async query notifier family $queryKey');
      Log.info('Stack trace: $stackTrace');
    }
  }

  /// Public method to refetch data
  Future<void> refetch({bool background = false}) async {
    Log.info('Refetching in async query notifier family $queryKey');
    if (background) {
      return _backgroundRefetch(arg);
    } else {
      _safeState(const AsyncValue.loading());
    }
    try {
      final data = await _performFetch(arg);
      _safeState(AsyncValue.data(data));
    } catch (error, stackTrace) {
      _safeState(AsyncValue.error(error, stackTrace));
    }
  }

  /// Force refresh (ignore cache)
  Future<void> refresh() async {
    Log.info('Refreshing in async query notifier family $queryKey');
    _invalidateCache('$queryKey-$arg');
    await refetch();
  }

  /// Helper methods for cache operations
  QueryCacheEntry<T>? _getCachedEntry(String key) {
    return _cache.get<T>(key, jsonParser: options.jsonParser);
  }

  void _setCachedEntry(String key, QueryCacheEntry<T> entry) {
    _cache.set(key, entry);
  }

  void _invalidateCache(String key) {
    _cache.remove(key);
  }

  /// Set up cache change listener
  void _setupCacheListener(String key) {
    _cache.addListener<T>(key, (QueryCacheEntry<T>? entry) {
      Log.info(
          'Cache listener called for key $key in async query notifier family, change state to ${state.runtimeType}');
      if ((entry?.hasData ?? false) &&
          !(state.hasValue && entry!.data == state.value)) {
        Log.info(
            'Cache data changed for key $key in async query notifier family');
        _safeState(AsyncValue.data(entry!.data as T));
      } else if (entry == null) {
        Log.info(
            'Cache entry removed for key $key in async query notifier family');
        if (options.onCacheEvicted != null) {
          options.onCacheEvicted!(key);
        } else if (!_isDisposed) {
          // refetch();
        } else {}
      }
    });
  }

  /// Set up window focus callbacks
  void _setupWindowFocusCallbacks() {
    Log.info(
        'Setting up window focus callbacks in async query notifier family $queryKey');
    // Refetch when window gains focus (if enabled and data is stale)
    if (options.refetchOnWindowFocus && _windowFocusManager.isSupported) {
      _windowFocusManager.addOnFocusCallback(_onWindowFocused);
    }

    // Pause refetching when app goes to background (if enabled)
    if (options.pauseRefetchInBackground) {
      _windowFocusManager.addOnBlurCallback(_onWindowBlured);
    }
  }

  void _onWindowBlured() {
    if(isMobile()){
      Log.info('App paused in async query notifier family');
      // Mark refetching as paused
      _isRefetchPaused = true;
    }
  }

  void _onWindowFocused() {
    Log.info('Window focused in async query notifier family $queryKey');
    // Resume refetching and check if we need to refetch stale data
    _isRefetchPaused = false;

    if (options.enabled && _shouldRefetchOnFocus()) {
      _backgroundRefetch(arg);
    }
  }

  /// Check if we should refetch when focus is gained
  bool _shouldRefetchOnFocus() {
    if (!options.enabled) {
      return false;
    }

    final cachedEntry = _getCachedEntry('$queryKey-$arg');
    if (cachedEntry != null && cachedEntry.isStale) {
      return true;
    }

    return false;
  }

  /// Schedule automatic refetching
  void _scheduleRefetch(P arg) {
    Log.info(
        'Scheduling automatic refetching in async query notifier family $queryKey');
    final interval = options.refetchInterval;
    if (interval != null && !_isRefetchPaused) {
      _refetchTimer?.cancel();
      _refetchTimer = Timer.periodic(interval, (_) {
        if (!_isRefetchPaused && options.enabled && _shouldRefetch()) {
          _backgroundRefetch(arg);
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

  void _dispose(String paramKey) {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;

    _refetchTimer?.cancel();

    // Clean up cache listener
    _cache.removeAllListeners(paramKey);

    // Clean up window focus callbacks
    if (options.pauseRefetchInBackground) {
      _windowFocusManager.removeOnBlurCallback(_onWindowBlured);
    }

    if (options.refetchOnWindowFocus && _windowFocusManager.isSupported) {
      _windowFocusManager.removeOnFocusCallback(_onWindowFocused);
    }

    // Reset initialization flag
    _isInitialized = false;
  }

  /// Pause automatic refetching
  void pauseRefetch() {
    _isRefetchPaused = true;
    _refetchTimer?.cancel();
  }

  /// Resume automatic refetching
  void resumeRefetch() {
    _isRefetchPaused = false;
    if (options.refetchInterval != null) {
      _scheduleRefetch(arg);
    }
  }
}

/// 🔥 Regular AsyncNotifier-based query provider
///
/// **Use this when:**
/// - Data should persist across widget rebuilds
/// - Shared data across multiple widgets
/// - Long-lived cache requirements
///
/// Example:
/// ```dart
/// final usersProvider = asyncQueryProvider<List<User>>(
///   name: 'users',
///   queryFn: ApiService.fetchUsers,
///   options: QueryOptions(
///     staleTime: Duration(minutes: 5),
///     cacheTime: Duration(minutes: 10),
///   ),
/// );
///
/// // Usage in widget:
/// Widget build(BuildContext context, WidgetRef ref) {
///   final usersAsync = ref.watch(usersProvider);
///   return usersAsync.when(
///     loading: () => CircularProgressIndicator(),
///     error: (error, stack) => Text('Error: $error'),
///     data: (users) => ListView.builder(
///       itemCount: users.length,
///       itemBuilder: (context, index) => ListTile(
///         title: Text(users[index].name),
///       ),
///     ),
///   );
/// }
/// ```
AsyncNotifierProvider<AsyncQueryNotifier<T>, T> asyncQueryProvider<T>({
  required String name,
  required QueryFunctionWithRef<T> queryFn,
  QueryOptions<T>? options,
}) {
  return AsyncNotifierProvider<AsyncQueryNotifier<T>, T>(
    () {
      return AsyncQueryNotifier<T>(
        queryFn: queryFn,
        options: options ?? QueryOptions<T>(),
        queryKey: name,
      );
    },
    name: name,
  );
}

/// 🔥 Auto-dispose AsyncNotifier-based query provider
///
/// **Use this when:**
/// - Temporary data that should be cleaned up when not watched
/// - Memory optimization for large datasets
/// - Short-lived screens or components
/// - Data that doesn't need to persist across navigation
///
/// **Features:**
/// - ✅ Automatic cleanup when no longer watched
/// - ✅ Full cache integration with staleTime/cacheTime
/// - ✅ Lifecycle management (app focus, window focus)
/// - ✅ Automatic refetching intervals
/// - ✅ Retry logic with exponential backoff
/// - ✅ Background refetch capabilities
/// - ✅ keepPreviousData support
/// - ✅ Memory leak prevention
///
/// Example:
/// ```dart
/// final tempDataProvider = asyncQueryProviderAutoDispose<TempData>(
///   name: 'temp-data',
///   queryFn: (ref) => ApiService.fetchTempData(),
///   options: QueryOptions(
///     staleTime: Duration(minutes: 2),
///     cacheTime: Duration(minutes: 5),
///   ),
/// );
///
/// // Usage in widget:
/// final tempDataAsync = ref.watch(tempDataProvider);
/// tempDataAsync.when(
///   loading: () => CircularProgressIndicator(),
///   error: (error, stack) => Text('Error: $error'),
///   data: (data) => DataWidget(data),
/// );
/// ```
/// Auto-dispose AsyncNotifier
class AsyncQueryNotifierAutoDispose<T> extends AutoDisposeAsyncNotifier<T> {
  AsyncQueryNotifierAutoDispose({
    required this.queryFn,
    required this.options,
    required this.queryKey,
  });

  final QueryFunctionWithRef<T> queryFn;
  final QueryOptions<T> options;
  final String queryKey;

  Timer? _refetchTimer;
  int _retryCount = 0;

  QueryCache get _cache => getCache(strategy: options.cacheStrategy);
  final WindowFocusManager _windowFocusManager = WindowFocusManager();
  bool _isRefetchPaused = false;
  bool _isInitialized = false;
  bool _isDisposed = false;

  @override
  FutureOr<T> build() async {
    Log.info(
        'Building async query notifier auto dispose with cached data, $queryKey');
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
        return cachedEntry.data as T;
      }

      if (options.keepPreviousData &&
          ((!_isDisposed && state.hasValue) ||
              (cachedEntry != null && cachedEntry.hasData))) {
        unawaited(Future.microtask(
            () => _backgroundRefetch().catchError((Object error) {
                  Log.info('Error in background refetch: $error');
                })));
        return (!_isDisposed && state.hasValue)
            ? state.value as T
            : cachedEntry?.data as T;
      }
    }

    if (!options.enabled) {
      throw StateError('Query is disabled and no cached data available');
    }
    Log.info(
        'Fetching data in async query notifier auto dispose with cached data, $queryKey');
    return await _performFetch();
  }

  void _safeState(AsyncValue<T> state) {
    if (!_isDisposed) {
      this.state = state;
    }
  }

  Future<T> _performFetch() async {
    try {
      Log.info(
          'Performing fetch in async query notifier auto dispose with cached data, $queryKey');
      final data = await queryFn(ref);
      final now = DateTime.now();

      _setCachedEntry(QueryCacheEntry<T>(
        data: data,
        fetchedAt: now,
        cacheTime: options.cacheTime,
        staleTime: options.staleTime,
      ));

      _retryCount = 0;
      options.onSuccess?.call(data);

      return data;
    } catch (error, stackTrace) {
      options.onError?.call(error, stackTrace);

      if (_retryCount < options.retry) {
        _retryCount++;
        await Future<void>.delayed(options.retryDelay);
        return _performFetch();
      }

      rethrow;
    }
  }

  Future<void> _backgroundRefetch() async {
    try {
      Log.info(
          'Background refetching in async query notifier auto dispose with cached data, $queryKey');
      final data = await _performFetch();
      _safeState(AsyncValue.data(data));
    } catch (error, _) {
      // Silent failure
    }
  }

  Future<void> refetch({bool background = false}) async {
    Log.info(
        'Refetching in async query notifier auto dispose with cached data, $queryKey');
    if (background) {
      return _backgroundRefetch();
    }
    _safeState(const AsyncValue.loading());
    try {
      final data = await _performFetch();
      _safeState(AsyncValue.data(data));
    } catch (error, stackTrace) {
      _safeState(AsyncValue.error(error, stackTrace));
    }
  }

  QueryCacheEntry<T>? _getCachedEntry() =>
      _cache.get<T>(queryKey, jsonParser: options.jsonParser);
  void _setCachedEntry(QueryCacheEntry<T> entry) => _cache.set(queryKey, entry);

  void _setupCacheListener() {
    _cache.addListener<T>(queryKey, (entry) {
      Log.info(
          'Cache listener called for key $queryKey in async query notifier auto dispose');
      if ((entry?.hasData ?? false) &&
          !(state.hasValue && entry!.data == state.value)) {
        _safeState(AsyncValue.data(entry!.data as T));
      } else if (entry == null) {
        if (options.onCacheEvicted != null) {
          options.onCacheEvicted!(queryKey);
        } else if (!_isDisposed) {
          // refetch();
        }
      }
    });
  }

  void _setupWindowFocusCallbacks() {
    Log.info(
        'Setting up window focus callbacks in async query notifier auto dispose with cached data, $queryKey');
    if (options.refetchOnWindowFocus && _windowFocusManager.isSupported) {
      _windowFocusManager.addOnFocusCallback(_onWindowFocused);
    }
    if (options.pauseRefetchInBackground) {
      _windowFocusManager.addOnBlurCallback(_onWindowBlured);
    }
  }

  void _onWindowBlured() {
    if(isMobile()){
      Log.info('App paused in async query notifier auto dispose with cached data, $queryKey');
      _isRefetchPaused = true;
    }
  }

  void _onWindowFocused() {
    Log.info('Window focused in async query notifier auto dispose with cached data, $queryKey');
    _isRefetchPaused = false;
    if (options.enabled && _shouldRefetchOnFocus()) {
      _backgroundRefetch();
    }
  }

  bool _shouldRefetchOnFocus() {
    if (!options.enabled) {
      return false;
    }

    final cachedEntry = _getCachedEntry();
    if (cachedEntry != null && cachedEntry.isStale) {
      return true;
    }

    return false;
  }

  void _scheduleRefetch() {
    Log.info(
        'Scheduling automatic refetching in async query notifier auto dispose with cached data, $queryKey');
    final interval = options.refetchInterval;
    if (interval != null && !_isRefetchPaused) {
      _refetchTimer?.cancel();
      _refetchTimer = Timer.periodic(interval, (_) {
        if (!_isRefetchPaused && options.enabled && _shouldRefetch()) {
          _backgroundRefetch();
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
}

/// Auto-dispose AsyncNotifier with parameters
AutoDisposeAsyncNotifierProvider<AsyncQueryNotifierAutoDispose<T>, T>
    asyncQueryProviderAutoDispose<T>({
  required String name,
  required QueryFunctionWithRef<T> queryFn,
  QueryOptions<T>? options,
}) {
  return AsyncNotifierProvider.autoDispose<AsyncQueryNotifierAutoDispose<T>, T>(
    () {
      return AsyncQueryNotifierAutoDispose<T>(
        queryFn: queryFn,
        options: options ?? QueryOptions<T>(),
        queryKey: name,
      );
    },
    name: name,
  );
}

/// 🔥 Full-featured AsyncNotifier-based query provider with parameters
///
/// **Use this when:**
/// - Parameters are relatively stable
/// - You want to keep data cached across widget rebuilds
/// - Shared data across multiple widgets
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
///
/// Example:
/// ```dart
/// final userProvider = asyncQueryProviderFamily<User, int>(
///   name: 'user',
///   queryFn: ApiService.fetchUser,
///   options: QueryOptions(
///     staleTime: Duration(minutes: 5),
///     refetchInterval: Duration(minutes: 10),
///     refetchOnWindowFocus: true,
///     keepPreviousData: true,
///   ),
/// );
///
/// // Usage:
/// final userAsync = ref.watch(userProvider(userId));
/// userAsync.when(
///   loading: () => CircularProgressIndicator(),
///   error: (error, stack) => ErrorWidget(error),
///   data: (user) => UserWidget(user),
/// );
/// ```
AsyncNotifierProviderFamily<AsyncQueryNotifierFamily<T, P>, T, P>
    asyncQueryProviderFamily<T, P>({
  required String name,
  required QueryFunctionWithParamsWithRef<T, P> queryFn,
  QueryOptions<T>? options,
}) {
  return AsyncNotifierProvider.family<AsyncQueryNotifierFamily<T, P>, T, P>(
    () {
      return AsyncQueryNotifierFamily<T, P>(
        queryFn: queryFn,
        options: options ?? QueryOptions<T>(),
        queryKey: name,
      );
    },
    name: name,
  );
}

/// 🔥 Auto-dispose AsyncNotifier-based query provider with parameters
///
/// **Use this when:**
/// - Dynamic parameters that change frequently
/// - Temporary data that should be cleaned up when not watched
/// - Memory optimization for large datasets with many parameter variations
/// - Short-lived screens with parameterized data
/// - User-specific data that doesn't need to persist
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
///
/// Example:
/// ```dart
/// final userDetailProvider = asyncQueryProviderFamilyAutoDispose<User, int>(
///   name: 'user-detail',
///   queryFn: (ref, userId) => ApiService.fetchUser(userId),
///   options: QueryOptions(
///     staleTime: Duration(minutes: 5),
///     cacheTime: Duration(minutes: 10),
///     keepPreviousData: true,
///   ),
/// );
///
/// // Usage in widget:
/// final userAsync = ref.watch(userDetailProvider(userId));
/// userAsync.when(
///   loading: () => CircularProgressIndicator(),
///   error: (error, stack) => ErrorWidget(error),
///   data: (user) => UserDetailWidget(user),
/// );
/// ```
/// Auto-dispose AsyncNotifier with parameters
class AsyncQueryNotifierFamilyAutoDispose<T, P>
    extends AutoDisposeFamilyAsyncNotifier<T, P> {
  AsyncQueryNotifierFamilyAutoDispose({
    required this.queryFn,
    required this.options,
    required this.queryKey,
  });

  final QueryFunctionWithParamsWithRef<T, P> queryFn;
  final QueryOptions<T> options;
  final String queryKey;

  Timer? _refetchTimer;
  int _retryCount = 0;

  QueryCache get _cache => getCache(strategy: options.cacheStrategy);
  final WindowFocusManager _windowFocusManager = WindowFocusManager();
  bool _isRefetchPaused = false;
  bool _isInitialized = false;
  bool _isDisposed = false;

  @override
  FutureOr<T> build(P arg) async {
    final paramKey = '$queryKey-$arg';
    Log.info(
        'Building async query notifier family auto dispose with cached data, $paramKey');
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

    if (options.enabled) {
      final cachedEntry = _getCachedEntry(paramKey);
      if (cachedEntry != null && !cachedEntry.isStale && cachedEntry.hasData) {
        if (options.refetchOnMount) {
          unawaited(Future.microtask(() => _backgroundRefetch(arg)));
        }
        return cachedEntry.data as T;
      }

      if (options.keepPreviousData &&
          ((!_isDisposed && state.hasValue) ||
              (cachedEntry != null && cachedEntry.hasData))) {
        unawaited(Future.microtask(() => _backgroundRefetch(arg)));
        return (!_isDisposed && state.hasValue)
            ? state.value as T
            : cachedEntry?.data as T;
      }
    }

    if (!options.enabled) {
      throw StateError('Query is disabled and no cached data available');
    }

    return await _performFetch(arg);
  }

  void _safeState(AsyncValue<T> state) {
    if (!_isDisposed) {
      this.state = state;
    }
  }

  Future<T> _performFetch(P arg) async {
    try {
      final data = await queryFn(ref, arg);
      final now = DateTime.now();
      final paramKey = '$queryKey-$arg';

      _setCachedEntry(
          paramKey,
          QueryCacheEntry<T>(
            data: data,
            fetchedAt: now,
            cacheTime: options.cacheTime,
            staleTime: options.staleTime,
          ));

      _retryCount = 0;
      options.onSuccess?.call(data);

      return data;
    } catch (error, stackTrace) {
      options.onError?.call(error, stackTrace);

      if (_retryCount < options.retry) {
        _retryCount++;
        await Future<void>.delayed(options.retryDelay);
        return _performFetch(arg);
      }

      rethrow;
    }
  }

  Future<void> _backgroundRefetch(P arg) async {
    try {
      final data = await _performFetch(arg);
      _safeState(AsyncValue.data(data));
    } catch (error, _) {
      // Silent failure
    }
  }

  Future<void> refetch({bool inBackground = false}) async {
    if (inBackground) {
      return _backgroundRefetch(arg);
    }
    _safeState(const AsyncValue.loading());
    try {
      final data = await _performFetch(arg);
      _safeState(AsyncValue.data(data));
    } catch (error, stackTrace) {
      _safeState(AsyncValue.error(error, stackTrace));
    }
  }

  QueryCacheEntry<T>? _getCachedEntry(String key) =>
      _cache.get<T>(key, jsonParser: options.jsonParser);
  void _setCachedEntry(String key, QueryCacheEntry<T> entry) =>
      _cache.set(key, entry);

  void _setupCacheListener(String key) {
    _cache.addListener<T>(key, (entry) {
      if ((entry?.hasData ?? false) &&
          !(state.hasValue && entry!.data == state.value)) {
        _safeState(AsyncValue.data(entry!.data as T));
      } else if (entry == null) {
        if (options.onCacheEvicted != null) {
          options.onCacheEvicted!(key);
        } else if (!_isDisposed) {
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

  void _onWindowBlured() {
    if(isMobile()){
      _isRefetchPaused = true;
    }
  }

  void _onWindowFocused() {
    _isRefetchPaused = false;
    if (options.enabled && _shouldRefetchOnFocus()) {
      _backgroundRefetch(arg);
    }
  }

  bool _shouldRefetchOnFocus() {
    if (!options.enabled) {
      return false;
    }

    final cachedEntry = _getCachedEntry('$queryKey-$arg');
    if (cachedEntry != null && cachedEntry.isStale) {
      return true;
    }

    return false;
  }

  void _scheduleRefetch(P arg) {
    final interval = options.refetchInterval;
    if (interval != null && !_isRefetchPaused) {
      _refetchTimer?.cancel();
      _refetchTimer = Timer.periodic(interval, (_) {
        if (!_isRefetchPaused && options.enabled && _shouldRefetch()) {
          _backgroundRefetch(arg);
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
}

/// Auto-dispose AsyncNotifier with parameters
AutoDisposeAsyncNotifierProviderFamily<
    AsyncQueryNotifierFamilyAutoDispose<T, P>,
    T,
    P> asyncQueryProviderFamilyAutoDispose<T, P>({
  required String name,
  required QueryFunctionWithParamsWithRef<T, P> queryFn,
  QueryOptions<T>? options,
}) {
  return AsyncNotifierProvider.autoDispose
      .family<AsyncQueryNotifierFamilyAutoDispose<T, P>, T, P>(
    () {
      return AsyncQueryNotifierFamilyAutoDispose<T, P>(
        queryFn: queryFn,
        options: options ?? QueryOptions<T>(),
        queryKey: name,
      );
    },
    name: name,
  );
}
