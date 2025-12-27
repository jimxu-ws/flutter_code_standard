import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:query_provider/query_provider.dart';

import '../models/post.dart';
import '../providers/post_providers.dart';

class PostsScreen extends ConsumerWidget {
  const PostsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final infiniteQuery = ref.readInfiniteQueryResult(postsInfiniteQueryProvider);//postsInfiniteQueryProvider.use(ref);

    return infiniteQuery.state.when(
      idle: () => const Center(child: Text('Loading posts...')),
      loading: () => const Center(child: CircularProgressIndicator()),
      success: (pages, hasNextPage, hasPreviousPage, fetchedAt) => PostsList(
        pages: pages,
        hasNextPage: hasNextPage,
        isFetchingNextPage: infiniteQuery.isFetchingNextPage,
        onLoadMore: infiniteQuery.fetchNextPage,
        onRefresh: infiniteQuery.refetch,
      ),
      refetching: (pages, hasNextPage, hasPreviousPage, fetchedAt) => PostsList(
            pages: pages,
            hasNextPage: hasNextPage,
            isFetchingNextPage: infiniteQuery.isFetchingNextPage,
            onLoadMore: infiniteQuery.fetchNextPage,
            onRefresh: infiniteQuery.refetch,
          ),
      error: (error, stackTrace) => ErrorView(
        error: error,
        onRetry: infiniteQuery.refetch,
      ),
      fetchingNextPage: (pages, hasNextPage, hasPreviousPage, fetchedAt) => PostsList(
        pages: pages,
        hasNextPage: hasNextPage,
        isFetchingNextPage: true,
        onLoadMore: infiniteQuery.fetchNextPage,
        onRefresh: infiniteQuery.refetch,
      ),
      fetchingPreviousPage: (pages, hasNextPage, hasPreviousPage, fetchedAt) => PostsList(
        pages: pages,
        hasNextPage: hasNextPage,
        isFetchingNextPage: false,
        onLoadMore: infiniteQuery.fetchNextPage,
        onRefresh: infiniteQuery.refetch,
      ),
    );
  }
}

class PostsList extends StatefulWidget {
  const PostsList({
    required this.pages, required this.hasNextPage, required this.isFetchingNextPage, required this.onLoadMore, required this.onRefresh, super.key,
  });

  final List<PostPage> pages;
  final bool hasNextPage;
  final bool isFetchingNextPage;
  final Future<void> Function() onLoadMore;
  final Future<void> Function() onRefresh;

  @override
  State<PostsList> createState() => _PostsListState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IterableProperty<PostPage>('pages', pages));
    properties.add(DiagnosticsProperty<bool>('hasNextPage', hasNextPage));
    properties.add(DiagnosticsProperty<bool>('isFetchingNextPage', isFetchingNextPage));
    properties.add(ObjectFlagProperty<Future<void> Function()>.has('onLoadMore', onLoadMore));
    properties.add(ObjectFlagProperty<Future<void> Function()>.has('onRefresh', onRefresh));
  }
}

class _PostsListState extends State<PostsList> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      // Load more when user is 200 pixels from the bottom
      _loadMoreIfNeeded();
    }
  }

  Future<void> _loadMoreIfNeeded() async {
    if (widget.hasNextPage && !widget.isFetchingNextPage && !_isLoadingMore) {
      setState(() {
        _isLoadingMore = true;
      });
      
      try {
        await widget.onLoadMore();
      } finally {
        if (mounted) {
          setState(() {
            _isLoadingMore = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Flatten all posts from all pages
    final allPosts = widget.pages.expand((page) => page.posts).toList();

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: ListView.builder(
        controller: _scrollController,
        itemCount: allPosts.length + (widget.hasNextPage || widget.isFetchingNextPage ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == allPosts.length) {
            // Auto-loading indicator
            return AutoLoadingIndicator(
              isLoading: widget.isFetchingNextPage || _isLoadingMore,
            );
          }

          final post = allPosts[index];
          return PostListTile(post: post);
        },
      ),
    );
  }
}

class PostListTile extends StatelessWidget {
  const PostListTile({required this.post, super.key});

  final Post post;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        title: Text(
          post.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              post.body,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              'By User ${post.userId} • Post #${post.id}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        isThreeLine: true,
        onTap: () {
          _showPostDetails(context, post);
        },
      ),
    );
  }

  void _showPostDetails(BuildContext context, Post post) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(post.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(post.body),
              const SizedBox(height: 16),
              Text(
                'Post ID: ${post.id}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                'Author: User ${post.userId}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Post>('post', post));
  }
}

class AutoLoadingIndicator extends StatelessWidget {
  const AutoLoadingIndicator({
    required this.isLoading, super.key,
  });

  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (!isLoading) {
      // Return a small invisible widget when not loading
      return const SizedBox(height: 16);
    }

    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Center(
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 8),
            Text(
              'Loading more posts...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<bool>('isLoading', isLoading));
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({
    required this.error, required this.onRetry, super.key,
  });

  final Object error;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading posts',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Object>('error', error));
    properties.add(ObjectFlagProperty<Future<void> Function()>.has('onRetry', onRetry));
  }
}
