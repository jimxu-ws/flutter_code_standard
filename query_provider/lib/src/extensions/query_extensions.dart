import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../query_state.dart';
import '../query_options.dart';
import '../mutation_options.dart';
import '../query_provider.dart';
import '../mutation_provider.dart';
import '../infinite_query_provider.dart';

/// Extension methods for WidgetRef to make query usage more convenient
extension QueryWidgetRefExtension on WidgetRef {
  /// Watch a query and return its state
  QueryState<T> watchQuery<T>(StateNotifierProvider<QueryNotifier<T>, QueryState<T>> provider) {
    return watch(provider);
  }

  /// Watch a mutation and return its state
  MutationState<T> watchMutation<T, V>(StateNotifierProvider<MutationNotifier<T, V>, MutationState<T>> provider) {
    return watch(provider);
  }

  /// Watch an infinite query and return its state
  InfiniteQueryState<T> watchInfiniteQuery<T, P>(StateNotifierProvider<InfiniteQueryNotifier<T, P>, InfiniteQueryState<T>> provider) {
    return watch(provider);
  }

  /// Read a query notifier for manual operations
  QueryNotifier<T> readQueryNotifier<T>(StateNotifierProvider<QueryNotifier<T>, QueryState<T>> provider) {
    return read(provider.notifier);
  }

  /// Read a mutation notifier for manual operations
  MutationNotifier<T, V> readMutationNotifier<T, V>(StateNotifierProvider<MutationNotifier<T, V>, MutationState<T>> provider) {
    return read(provider.notifier);
  }

  /// Read an infinite query notifier for manual operations
  InfiniteQueryNotifier<T, P> readInfiniteQueryNotifier<T, P>(StateNotifierProvider<InfiniteQueryNotifier<T, P>, InfiniteQueryState<T>> provider) {
    return read(provider.notifier);
  }
}

/// Extension methods for Consumer widgets
extension QueryConsumerExtension on Consumer {
  /// Create a consumer that watches a query
  static Widget query<T>({
    Key? key,
    required StateNotifierProvider<QueryNotifier<T>, QueryState<T>> provider,
    required Widget Function(BuildContext context, QueryState<T> state, Widget? child) builder,
    Widget? child,
  }) {
    return Consumer(
      key: key,
      builder: (context, ref, child) {
        final state = ref.watch(provider);
        return builder(context, state, child);
      },
      child: child,
    );
  }

  /// Create a consumer that watches a mutation
  static Widget mutation<T, V>({
    Key? key,
    required StateNotifierProvider<MutationNotifier<T, V>, MutationState<T>> provider,
    required Widget Function(BuildContext context, MutationState<T> state, Widget? child) builder,
    Widget? child,
  }) {
    return Consumer(
      key: key,
      builder: (context, ref, child) {
        final state = ref.watch(provider);
        return builder(context, state, child);
      },
      child: child,
    );
  }

  /// Create a consumer that watches an infinite query
  static Widget infiniteQuery<T, P>({
    Key? key,
    required StateNotifierProvider<InfiniteQueryNotifier<T, P>, InfiniteQueryState<T>> provider,
    required Widget Function(BuildContext context, InfiniteQueryState<T> state, Widget? child) builder,
    Widget? child,
  }) {
    return Consumer(
      key: key,
      builder: (context, ref, child) {
        final state = ref.watch(provider);
        return builder(context, state, child);
      },
      child: child,
    );
  }
}

/// Extension methods for BuildContext to access query operations
extension QueryBuildContextExtension on BuildContext {
  /// Invalidate queries by pattern
  void invalidateQueries(String pattern) {
    // This would need access to the query client
    // Implementation depends on how you want to expose the query client
  }
}

/// Utility functions for creating common query patterns
class QueryUtils {
  QueryUtils._();

  /// Create a simple data fetching query
  static StateNotifierProvider<QueryNotifier<T>, QueryState<T>> createQuery<T>({
    required String key,
    required Future<T> Function() fetcher,
    QueryOptions<T> options = const QueryOptions(),
  }) {
    return queryProvider<T>(
      name: key,
      queryFn: fetcher,
      options: options,
    );
  }

  /// Create a mutation for data modification
  static StateNotifierProvider<MutationNotifier<TData, TVariables>, MutationState<TData>> createMutation<TData, TVariables>({
    required String key,
    required Future<TData> Function(TVariables variables) mutator,
    MutationOptions<TData, TVariables> options = const MutationOptions(),
  }) {
    return mutationProvider<TData, TVariables>(
      name: key,
      mutationFn: mutator,
      options: options,
    );
  }

  /// Create an infinite query for paginated data
  static StateNotifierProvider<InfiniteQueryNotifier<T, TPageParam>, InfiniteQueryState<T>> createInfiniteQuery<T, TPageParam>({
    required String key,
    required Future<T> Function(TPageParam pageParam) fetcher,
    required TPageParam initialPageParam,
    required InfiniteQueryOptions<T, TPageParam> options,
  }) {
    return infiniteQueryProvider<T, TPageParam>(
      name: key,
      queryFn: fetcher,
      initialPageParam: initialPageParam,
      options: options,
    );
  }
}

/// Mixin for widgets that use queries
mixin QueryMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  /// Convenience method to watch a query
  QueryState<R> watchQuery<R>(StateNotifierProvider<QueryNotifier<R>, QueryState<R>> provider) {
    return ref.watch(provider);
  }

  /// Convenience method to watch a mutation
  MutationState<R> watchMutation<R, V>(StateNotifierProvider<MutationNotifier<R, V>, MutationState<R>> provider) {
    return ref.watch(provider);
  }

  /// Convenience method to watch an infinite query
  InfiniteQueryState<R> watchInfiniteQuery<R, P>(StateNotifierProvider<InfiniteQueryNotifier<R, P>, InfiniteQueryState<R>> provider) {
    return ref.watch(provider);
  }

  /// Convenience method to read a query notifier
  QueryNotifier<R> readQueryNotifier<R>(StateNotifierProvider<QueryNotifier<R>, QueryState<R>> provider) {
    return ref.read(provider.notifier);
  }

  /// Convenience method to read a mutation notifier
  MutationNotifier<R, V> readMutationNotifier<R, V>(StateNotifierProvider<MutationNotifier<R, V>, MutationState<R>> provider) {
    return ref.read(provider.notifier);
  }

  /// Convenience method to read an infinite query notifier
  InfiniteQueryNotifier<R, P> readInfiniteQueryNotifier<R, P>(StateNotifierProvider<InfiniteQueryNotifier<R, P>, InfiniteQueryState<R>> provider) {
    return ref.read(provider.notifier);
  }
}
