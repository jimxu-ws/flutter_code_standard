import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:query_provider/query_provider.dart';
import 'package:ws_storage/ws_storage.dart';

import 'examples/background_foreground_example.dart';
import 'screens/home_screen.dart';

class QueryStorage extends BaseStorage{
  factory QueryStorage() => _instance;

  QueryStorage._internal() : super(_appBoxName){
    initBox(_appBoxName);
  }
  static final QueryStorage _instance = QueryStorage._internal();

  static const String _appBoxName = 'query_storage';
}

class EmptyCacheEntry extends QueryCacheEntry<dynamic>{
  const EmptyCacheEntry({required super.data, required super.fetchedAt, required super.cacheTime, required super.staleTime});
  
}

class DiskCache extends IStorage{
  @override
  void clear() {
    QueryStorage().clear();
  }

  @override
  QueryCacheEntry<T>? get<T>(String key, {JsonParser<T>? jsonParser}) {
    final strObj = QueryStorage().getNullable<String>(key);
    if(strObj == null){
      return null;
    }
    try{
      final entry = QueryCacheEntry<T>.fromJson(jsonDecode(strObj) as Map<String, dynamic>, jsonParser: jsonParser);
      return entry;
    }catch(e){
      debugPrint('Error parsing query cache entry from storage: $e');
      return null;
    }
  }

  @override
  List<String> get keys => QueryStorage().getKeys().toList();

  @override
  QueryCacheEntry<dynamic>? remove(String key) {
    final entry = QueryStorage().getNullable<String>(key);
    QueryStorage().remove(key);
    return EmptyCacheEntry(data: entry, fetchedAt: DateTime.now(), cacheTime: Duration.zero, staleTime: Duration.zero);
  }

  @override
  void set<T>(String key, QueryCacheEntry<T> entry) {
    debugPrint('set $key ${entry.toJson()}');
    final strObj = entry.toJson();
    QueryStorage().set(key, jsonEncode(strObj));
  }
  
  @override
  bool containsKey(String key) {
    final strObj = QueryStorage().getNullable<String>(key);
    return strObj != null;
  }
  
  @override
  QueryCacheEntry<dynamic>? getRaw<T>(String key) {
    final strObj = QueryStorage().getNullable<String>(key);
    if(strObj == null){
      return null;
    }
    try{
      final entry = QueryCacheEntry<dynamic>.rawFromJson(jsonDecode(strObj) as Map<String, dynamic>);
      return entry;
    }catch(e){
      debugPrint('Error parsing query cache entry from storage: $e');
      return null;
    }
  }
  
}

class QueryLogger extends IQueryLogger{
  @override
  void debug(String message, [Object? error, StackTrace? stackTrace]) {
    debugPrint('QueryLogger debug: $message');
  }
  
  @override
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    debugPrint('QueryLogger error: $message');
  }
  
  @override
  void info(String message, [Object? error, StackTrace? stackTrace]) {
    debugPrint('QueryLogger info: $message');
  }
  
  @override
  void warn(String message, [Object? error, StackTrace? stackTrace]) {
    debugPrint('QueryLogger warn: $message');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await WSPlatformMMKV().initialize();
  await StorageManager.init();
  QueryGlobalOptions().init(storage: DiskCache(), logger: QueryLogger());
  runApp(
    // Use ProviderScope to ensure all providers share the same container
    // This is critical for QueryClient to properly invalidate providers
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp2 extends StatelessWidget {
  const MyApp2({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BackgroundForegroundExample',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const BackgroundForegroundExample(),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Query Provider Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
