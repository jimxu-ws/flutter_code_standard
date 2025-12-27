import '../cache/query_cache_entry.dart';
import '../options/query_options.dart';

abstract class IStorage {
  QueryCacheEntry<T>? get<T>(String key, {JsonParser<T>? jsonParser});
  QueryCacheEntry<dynamic>? getRaw<T>(String key);
  void set<T>(String key, QueryCacheEntry<T> entry);
  QueryCacheEntry<dynamic>? remove(String key);
  void clear();
  bool containsKey(String key);
  List<String> get keys;
}
