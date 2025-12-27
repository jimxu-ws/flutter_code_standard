import '../cache/query_cache_base.dart';
import '../interface/i_logger.dart';
import '../interface/i_storage.dart';

class QueryGlobalOptions {
  factory QueryGlobalOptions() => _instance;
  QueryGlobalOptions._internal();
  static final QueryGlobalOptions _instance = QueryGlobalOptions._internal();

  QueryCacheEventCallback? onEvent;
  int cacheMaxSize = 100;
  IStorage? storage;
  IQueryLogger? logger;
  Duration defaultDiskCacheTime = const Duration(days: 7);
  Duration defaultMemoryCacheTime = const Duration(minutes: 30);

  void init({
    IStorage? storage,
    IQueryLogger? logger,
    QueryCacheEventCallback? onEvent,
    int cacheMaxSize = 100,
    Duration defaultDiskCacheTime = const Duration(days: 7),
    Duration defaultMemoryCacheTime = const Duration(minutes: 30),
  }) {
    this.storage = storage;
    this.logger = logger;
    this.onEvent = onEvent;
    this.cacheMaxSize = cacheMaxSize;
    this.defaultDiskCacheTime = defaultDiskCacheTime;
    this.defaultMemoryCacheTime = defaultMemoryCacheTime;
  }
}
