import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:query_provider/query_provider.dart';
import '../models/post.dart';
import '../models/user.dart';
import '../services/api_service.dart';

// ============================================================================
// 使用 QueryUtils 工具类的示例（不需要代码生成）
// ============================================================================

/// 使用传统方式的无限查询 provider（暂时保持原有实现）
final infinitePostsProvider = infiniteQueryProvider<PostPage, int>(
  name: 'posts-infinite',
  queryFn: (pageParam) => ApiService.fetchPosts(page: pageParam),
  initialPageParam: 1,
  options: InfiniteQueryOptions<PostPage, int>(
    staleTime: const Duration(minutes: 2),
    cacheTime: const Duration(minutes: 10),
    getNextPageParam: (lastPage, allPages) => lastPage.hasMore ? allPages.length + 1 : null,
  ),
);

// ============================================================================
// 使用 QueryUtils 工具类的示例
// ============================================================================

/// 使用 QueryUtils.query 创建查询 provider
final simpleUsersProvider = QueryUtils.query<List<User>>(
  name: 'simple-users',
  queryFn: () => ApiService.fetchUsers(),
  options: const QueryOptions<List<User>>(
    staleTime: Duration(minutes: 5),
    retry: 3,
  ),
);

/// 使用 QueryUtils.mutation 创建变更 provider
final simpleCreateUserProvider = QueryUtils.mutation<User, Map<String, dynamic>>(
  name: 'simple-create-user',
  mutationFn: (userData) => ApiService.createUser(userData),
  options: MutationOptions<User, Map<String, dynamic>>(
    retry: 2,
    onSuccess: (user, _) => print('User ${user.name} created!'),
  ),
);

// ============================================================================
// 使用 QueryCapabilities mixin 的自定义 StateNotifier
// ============================================================================

class PostsNotifier extends StateNotifier<List<Post>> with QueryCapabilities<List<Post>> {
  PostsNotifier() : super([]);

  Future<void> loadPosts() async {
    try {
      final posts = await executeQuery<List<Post>>(
        queryKey: 'posts-custom',
        queryFn: () => ApiService.fetchPosts().then((page) => page.posts),
      );
      state = posts;
    } catch (error) {
      // 处理错误
      print('Failed to load posts: $error');
    }
  }

  Future<void> createPost(Map<String, dynamic> postData) async {
    try {
      final newPost = await ApiService.createPost(postData);
      state = [...state, newPost];
      
      // 使相关查询失效
      invalidateQueries('posts');
    } catch (error) {
      print('Failed to create post: $error');
    }
  }
}

final postsNotifierProvider = StateNotifierProvider<PostsNotifier, List<Post>>((ref) => PostsNotifier());
