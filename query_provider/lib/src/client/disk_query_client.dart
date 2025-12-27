import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../options/query_options.dart';
import 'query_client.dart';

class DiskQueryClient extends QueryClient {
  DiskQueryClient({
    super.container,
  }) : super(cache: getCache(strategy: QueryCacheStrategy.disk));

  // Private constructor for singleton
  DiskQueryClient._internal()
      : super(cache: getCache(strategy: QueryCacheStrategy.disk));

  // Singleton instance
  static DiskQueryClient? _instance;
  static DiskQueryClient get instance =>
      _instance ??= DiskQueryClient._internal();
}

/// Global query client provider - Singleton pattern with auto container setup
final diskQueryClientProvider = Provider<QueryClient>((ref) {
  // Create a singleton instance and automatically set the container
  final client = QueryClient.instance;

  // Automatically set the container for provider invalidation support
  QueryClient.setContainer(ref.container);

  ref.onDispose(client.dispose);
  return client;
});

class Disk2LevelQueryClient extends QueryClient {
  Disk2LevelQueryClient({
    super.container,
  }) : super(cache: getCache(strategy: QueryCacheStrategy.disk2Level));

  // Private constructor for singleton
  Disk2LevelQueryClient._internal()
      : super(cache: getCache(strategy: QueryCacheStrategy.disk2Level));

  // Singleton instance
  static Disk2LevelQueryClient? _instance;
  static Disk2LevelQueryClient get instance =>
      _instance ??= Disk2LevelQueryClient._internal();
}

/// Global query client provider - Singleton pattern with auto container setup
final disk2LevelQueryClientProvider = Provider<QueryClient>((ref) {
  // Create a singleton instance and automatically set the container
  final client = Disk2LevelQueryClient.instance;

  // Automatically set the container for provider invalidation support
  QueryClient.setContainer(ref.container);

  ref.onDispose(client.dispose);
  return client;
});
