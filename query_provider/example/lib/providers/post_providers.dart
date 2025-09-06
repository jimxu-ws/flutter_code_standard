import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:query_provider/query_provider.dart';
import '../models/post.dart';
import '../services/api_service.dart';

/// Infinite query provider for fetching posts with pagination
final postsInfiniteQueryProvider = infiniteQueryProvider<PostPage, int>(
  name: 'posts-infinite',
  queryFn: (pageParam) => ApiService.fetchPosts(page: pageParam),
  initialPageParam: 1,
  options: InfiniteQueryOptions<PostPage, int>(
    getNextPageParam: (lastPage, allPages) {
      return lastPage.hasMore ? lastPage.page + 1 : null;
    },
    staleTime: const Duration(minutes: 2),
    cacheTime: const Duration(minutes: 10),
  ),
);

/// Query provider for fetching posts by user ID
StateNotifierProvider<QueryNotifier<List<Post>>, QueryState<List<Post>>> userPostsQueryProvider(int userId) {
  return queryProvider<List<Post>>(
    name: 'user-posts-$userId',
    queryFn: () => ApiService.fetchUserPosts(userId),
    options: const QueryOptions<List<Post>>(
      staleTime: Duration(minutes: 3),
      cacheTime: Duration(minutes: 10),
    ),
  );
}

/// Mutation provider for creating a new post
final createPostMutationProvider = mutationProvider<Post, Map<String, dynamic>>(
  name: 'create-post',
  mutationFn: ApiService.createPost,
  options: MutationOptions<Post, Map<String, dynamic>>(
    onSuccess: (post, variables) {
      print('Post created successfully: ${post.title}');
      // In a real app, you might invalidate the posts query here
    },
    onError: (error, variables, stackTrace) {
      print('Failed to create post: $error');
    },
  ),
);

/// Mutation provider for updating a post
StateNotifierProvider<MutationNotifier<Post, Map<String, dynamic>>, MutationState<Post>> updatePostMutationProvider(int postId) {
  return mutationProvider<Post, Map<String, dynamic>>(
    name: 'update-post-$postId',
    mutationFn: (variables) => ApiService.updatePost(postId, variables),
    options: MutationOptions<Post, Map<String, dynamic>>(
      onSuccess: (post, variables) {
        print('Post updated successfully: ${post.title}');
        // In a real app, you might invalidate related queries here
      },
      onError: (error, variables, stackTrace) {
        print('Failed to update post: $error');
      },
    ),
  );
}

/// Mutation provider for deleting a post
StateNotifierProvider<MutationNotifier<void, int>, MutationState<void>> deletePostMutationProvider(int postId) {
  return mutationProvider<void, int>(
    name: 'delete-post-$postId',
    mutationFn: (id) => ApiService.deletePost(id),
    options: MutationOptions<void, int>(
      onSuccess: (_, id) {
        print('Post $id deleted successfully');
        // In a real app, you might invalidate the posts query here
      },
      onError: (error, id, stackTrace) {
        print('Failed to delete post $id: $error');
      },
    ),
  );
}
