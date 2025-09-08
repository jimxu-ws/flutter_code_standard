import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'riverpod_extensions.dart';

/// 缓存事件类型
enum CacheEventType {
  /// 数据获取成功
  dataReceived,
  /// 开始加载
  loadingStarted,
  /// 发生错误
  errorOccurred,
  /// 缓存失效
  cacheInvalidated,
  /// 缓存清除
  cacheCleared,
  /// 后台刷新开始
  backgroundRefreshStarted,
  /// 后台刷新完成
  backgroundRefreshCompleted,
}

/// 缓存事件数据
class CacheEvent<T> {
  final CacheEventType type;
  final T? data;
  final Object? error;
  final String cacheKey;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  CacheEvent({
    required this.type,
    required this.cacheKey,
    this.data,
    this.error,
    DateTime? timestamp,
    this.metadata,
  }) : timestamp = timestamp ?? DateTime.now();

  /// 是否是成功事件
  bool get isSuccess => type == CacheEventType.dataReceived && data != null;

  /// 是否是错误事件
  bool get isError => type == CacheEventType.errorOccurred && error != null;

  /// 是否是加载事件
  bool get isLoading => type == CacheEventType.loadingStarted;

  @override
  String toString() => 'CacheEvent(type: $type, key: $cacheKey, hasData: ${data != null}, hasError: ${error != null})';
}

/// 事件驱动的缓存管理器
/// 
/// 通过注册事件监听器来统一处理所有缓存相关的状态变化
/// 
/// Example:
/// ```dart
/// @riverpod
/// class PayrollCheck extends _$PayrollCheck {
///   late final _cacheManager = ref.eventDrivenCache<Result<GetPayrollResponse>>(
///     fetchFn: () => ref.read(apiClientProvider).getPayroll(),
///     cacheKey: 'payroll-data',
///     onEvent: _handleCacheEvent,
///   );
/// 
///   void _handleCacheEvent(CacheEvent<Result<GetPayrollResponse>> event) {
///     switch (event.type) {
///       case CacheEventType.dataReceived:
///         state = state.copyWith(
///           checkPayrollResult: event.data,
///           employeesList: event.data?.response?.employees,
///         );
///         break;
///       case CacheEventType.loadingStarted:
///         state = state.copyWith(checkPayrollResult: Result.pending());
///         break;
///       case CacheEventType.errorOccurred:
///         state = state.copyWith(checkPayrollResult: Result.fail());
///         break;
///     }
///   }
/// 
///   Future<void> getPayroll() => _cacheManager.fetch();
/// }
/// ```
class EventDrivenCacheManager<T> {
  final SmartCachedFetcher<T> _fetcher;
  final void Function(CacheEvent<T> event) onEvent;
  final String cacheKey;

  EventDrivenCacheManager({
    required Ref ref,
    required Future<T> Function() fetchFn,
    required this.onEvent,
    required this.cacheKey,
    Duration staleTime = const Duration(minutes: 5),
    Duration cacheTime = const Duration(minutes: 30),
    bool enableBackgroundRefresh = true,
    bool enableWindowFocusRefresh = true,
    bool cacheErrors = false,
  }) : _fetcher = SmartCachedFetcher<T>(
          ref: ref,
          fetchFn: fetchFn,
          onData: (data) => onEvent(CacheEvent<T>(
            type: CacheEventType.dataReceived,
            cacheKey: cacheKey,
            data: data,
          )),
          onLoading: () => onEvent(CacheEvent<T>(
            type: CacheEventType.loadingStarted,
            cacheKey: cacheKey,
          )),
          onError: (error) => onEvent(CacheEvent<T>(
            type: CacheEventType.errorOccurred,
            cacheKey: cacheKey,
            error: error,
          )),
          cacheKey: cacheKey,
          staleTime: staleTime,
          cacheTime: cacheTime,
          enableBackgroundRefresh: enableBackgroundRefresh,
          enableWindowFocusRefresh: enableWindowFocusRefresh,
          cacheErrors: cacheErrors,
        );

  /// 获取数据
  Future<void> fetch({bool forceRefresh = false}) async {
    await _fetcher.fetch(forceRefresh: forceRefresh);
  }

  /// 刷新数据
  Future<void> refresh() async {
    _emitEvent(CacheEventType.backgroundRefreshStarted);
    try {
      await _fetcher.refresh();
      _emitEvent(CacheEventType.backgroundRefreshCompleted);
    } catch (error) {
      onEvent(CacheEvent<T>(
        type: CacheEventType.errorOccurred,
        cacheKey: cacheKey,
        error: error,
        metadata: {'source': 'refresh'},
      ));
    }
  }

  /// 清除缓存
  void clearCache() {
    _fetcher.clearCache();
    _emitEvent(CacheEventType.cacheCleared);
  }

  /// 使缓存失效
  void invalidateCache() {
    // 这里可以添加失效逻辑
    _emitEvent(CacheEventType.cacheInvalidated);
  }

  /// 获取缓存数据
  T? getCached() => _fetcher.getCached();

  /// 检查是否有缓存
  bool get isCached => _fetcher.isCached;

  /// 检查数据是否过期
  bool get isStale => _fetcher.isStale;

  /// 检查是否正在获取数据
  bool get isFetching => _fetcher.isFetching;

  /// 获取缓存键
  String get key => cacheKey;

  /// 窗口聚焦事件处理
  void onWindowFocus() {
    _fetcher.onWindowFocus();
  }

  /// 应用恢复事件处理
  void onAppResume() {
    _fetcher.onAppResume();
  }

  /// 发出事件
  void _emitEvent(CacheEventType type, {T? data, Object? error, Map<String, dynamic>? metadata}) {
    onEvent(CacheEvent<T>(
      type: type,
      cacheKey: cacheKey,
      data: data,
      error: error,
      metadata: metadata,
    ));
  }
}

/// 多事件监听器管理器
/// 
/// 支持注册多个事件监听器，可以按事件类型或缓存键过滤
class MultiEventCacheManager<T> {
  late final EventDrivenCacheManager<T> _manager;
  final List<CacheEventListener<T>> _listeners = [];

  MultiEventCacheManager({
    required Ref ref,
    required Future<T> Function() fetchFn,
    required String cacheKey,
    Duration staleTime = const Duration(minutes: 5),
    Duration cacheTime = const Duration(minutes: 30),
    bool enableBackgroundRefresh = true,
    bool enableWindowFocusRefresh = true,
    bool cacheErrors = false,
  }) {
    _manager = EventDrivenCacheManager<T>(
      ref: ref,
      fetchFn: fetchFn,
      onEvent: _notifyListeners,
      cacheKey: cacheKey,
      staleTime: staleTime,
      cacheTime: cacheTime,
      enableBackgroundRefresh: enableBackgroundRefresh,
      enableWindowFocusRefresh: enableWindowFocusRefresh,
      cacheErrors: cacheErrors,
    );
  }

  /// 添加事件监听器
  void addEventListener(CacheEventListener<T> listener) {
    _listeners.add(listener);
  }

  /// 移除事件监听器
  void removeEventListener(CacheEventListener<T> listener) {
    _listeners.remove(listener);
  }

  /// 通知所有监听器
  void _notifyListeners(CacheEvent<T> event) {
    for (final listener in _listeners) {
      if (listener.shouldHandle(event)) {
        listener.onEvent(event);
      }
    }
  }

  // 代理所有 manager 方法
  Future<void> fetch({bool forceRefresh = false}) => _manager.fetch(forceRefresh: forceRefresh);
  Future<void> refresh() => _manager.refresh();
  void clearCache() => _manager.clearCache();
  void invalidateCache() => _manager.invalidateCache();
  T? getCached() => _manager.getCached();
  bool get isCached => _manager.isCached;
  bool get isStale => _manager.isStale;
  bool get isFetching => _manager.isFetching;
  String get key => _manager.key;
  void onWindowFocus() => _manager.onWindowFocus();
  void onAppResume() => _manager.onAppResume();
}

/// 缓存事件监听器
abstract class CacheEventListener<T> {
  /// 是否应该处理这个事件
  bool shouldHandle(CacheEvent<T> event);

  /// 处理事件
  void onEvent(CacheEvent<T> event);
}

/// 基于事件类型的监听器
class EventTypeListener<T> extends CacheEventListener<T> {
  final Set<CacheEventType> eventTypes;
  final void Function(CacheEvent<T> event) callback;

  EventTypeListener({
    required this.eventTypes,
    required this.callback,
  });

  @override
  bool shouldHandle(CacheEvent<T> event) => eventTypes.contains(event.type);

  @override
  void onEvent(CacheEvent<T> event) => callback(event);
}

/// 基于缓存键的监听器
class CacheKeyListener<T> extends CacheEventListener<T> {
  final Set<String> cacheKeys;
  final void Function(CacheEvent<T> event) callback;

  CacheKeyListener({
    required this.cacheKeys,
    required this.callback,
  });

  @override
  bool shouldHandle(CacheEvent<T> event) => cacheKeys.contains(event.cacheKey);

  @override
  void onEvent(CacheEvent<T> event) => callback(event);
}

/// Riverpod 扩展方法
extension EventDrivenCacheExtension on Ref {
  /// 创建事件驱动的缓存管理器
  EventDrivenCacheManager<T> eventDrivenCache<T>({
    required Future<T> Function() fetchFn,
    required void Function(CacheEvent<T> event) onEvent,
    String? cacheKey,
    Duration staleTime = const Duration(minutes: 5),
    Duration cacheTime = const Duration(minutes: 30),
    bool enableBackgroundRefresh = true,
    bool enableWindowFocusRefresh = true,
    bool cacheErrors = false,
  }) {
    return EventDrivenCacheManager<T>(
      ref: this,
      fetchFn: fetchFn,
      onEvent: onEvent,
      cacheKey: cacheKey ?? 'event-cache-${fetchFn.hashCode}',
      staleTime: staleTime,
      cacheTime: cacheTime,
      enableBackgroundRefresh: enableBackgroundRefresh,
      enableWindowFocusRefresh: enableWindowFocusRefresh,
      cacheErrors: cacheErrors,
    );
  }

  /// 创建多事件监听器缓存管理器
  MultiEventCacheManager<T> multiEventCache<T>({
    required Future<T> Function() fetchFn,
    String? cacheKey,
    Duration staleTime = const Duration(minutes: 5),
    Duration cacheTime = const Duration(minutes: 30),
    bool enableBackgroundRefresh = true,
    bool enableWindowFocusRefresh = true,
    bool cacheErrors = false,
  }) {
    return MultiEventCacheManager<T>(
      ref: this,
      fetchFn: fetchFn,
      cacheKey: cacheKey ?? 'multi-event-cache-${fetchFn.hashCode}',
      staleTime: staleTime,
      cacheTime: cacheTime,
      enableBackgroundRefresh: enableBackgroundRefresh,
      enableWindowFocusRefresh: enableWindowFocusRefresh,
      cacheErrors: cacheErrors,
    );
  }
}
