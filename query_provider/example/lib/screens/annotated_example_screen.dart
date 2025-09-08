import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/annotated_posts_provider.dart';
import '../models/post.dart';
import '../models/user.dart';

/// 展示如何使用带有 QueryProvider 能力的 @riverpod provider
class AnnotatedExampleScreen extends ConsumerWidget {
  const AnnotatedExampleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('@riverpod + QueryProvider'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Users', icon: Icon(Icons.people)),
              Tab(text: 'Posts', icon: Icon(Icons.article)),
              Tab(text: 'Mutations', icon: Icon(Icons.edit)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            UsersTabAnnotated(),
            PostsTabAnnotated(),
            MutationsTabAnnotated(),
          ],
        ),
      ),
    );
  }
}

/// 使用带有查询能力的用户 provider
class UsersTabAnnotated extends ConsumerWidget {
  const UsersTabAnnotated({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 使用 QueryUtils 创建的 provider，具有 QueryProvider 的所有能力
    final usersState = ref.watch(simpleUsersProvider);

    if (usersState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (usersState.hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: ${usersState.error}'),
            ElevatedButton(
              onPressed: () => ref.invalidate(simpleUsersProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    } else if (usersState.hasData) {
      final users = usersState.data!;
      return RefreshIndicator(
        onRefresh: () async => ref.read(simpleUsersProvider.notifier).refetch(),
        child: ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: user.avatar != null ? NetworkImage(user.avatar!) : null,
                child: user.avatar == null ? Text(user.name[0]) : null,
              ),
              title: Text(user.name),
              subtitle: Text(user.email),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _showUserDetails(context, ref, user.id),
            );
          },
        ),
      );
    } else {
      return const Center(child: Text('No data'));
    }
  }

  void _showUserDetails(BuildContext context, WidgetRef ref, int userId) {
    showDialog(
      context: context,
      builder: (context) => UserDetailDialog(userId: userId),
    );
  }
}

/// 用户详情对话框
class UserDetailDialog extends ConsumerWidget {
  const UserDetailDialog({super.key, required this.userId});

  final int userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 使用简单的用户查询 - 在实际应用中应该是带参数的
    final usersState = ref.watch(simpleUsersProvider);
    
    User? selectedUser;
    if (usersState.hasData) {
      try {
        selectedUser = usersState.data!.firstWhere((user) => user.id == userId);
      } catch (e) {
        selectedUser = usersState.data!.isNotEmpty ? usersState.data!.first : null;
      }
    }

    return AlertDialog(
      title: const Text('User Details'),
      content: usersState.isLoading
        ? const SizedBox(
            height: 100,
            child: Center(child: CircularProgressIndicator()),
          )
        : usersState.hasError
        ? Text('Error: ${usersState.error}')
        : selectedUser != null 
        ? Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Name: ${selectedUser!.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Email: ${selectedUser!.email}'),
              const SizedBox(height: 8),
              if (selectedUser!.avatar != null) ...[
                const Text('Avatar:'),
                const SizedBox(height: 4),
                Image.network(selectedUser!.avatar!, height: 100, width: 100),
              ],
            ],
          )
        : const Text('User not found'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

/// 使用带有查询能力的帖子 provider
class PostsTabAnnotated extends ConsumerWidget {
  const PostsTabAnnotated({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posts = ref.watch(postsNotifierProvider);

    return posts.isEmpty 
      ? const Center(child: Text('No posts available. Tap to load.'))
      : RefreshIndicator(
          onRefresh: () async => ref.read(postsNotifierProvider.notifier).loadPosts(),
          child: ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text(post.title),
                  subtitle: Text(
                    post.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          _showEditPostDialog(context, ref, post);
                          break;
                        case 'delete':
                          _deletePost(context, ref, post.id);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Edit'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
  }

  void _showEditPostDialog(BuildContext context, WidgetRef ref, Post post) {
    final titleController = TextEditingController(text: post.title);
    final bodyController = TextEditingController(text: post.body);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Post'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: bodyController,
              decoration: const InputDecoration(labelText: 'Body'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                // Simulate post update using the notifier
                await ref.read(postsNotifierProvider.notifier).createPost({
                  'title': titleController.text,
                  'body': bodyController.text,
                  'userId': post.userId,
                });
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Post updated successfully!')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to update post: $e')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deletePost(BuildContext context, WidgetRef ref, int postId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                // Simulate post deletion - just remove from local state
                final currentPosts = ref.read(postsNotifierProvider);
                final updatedPosts = currentPosts.where((p) => p.id != postId).toList();
                ref.read(postsNotifierProvider.notifier).state = updatedPosts;
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Post deleted successfully!')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete post: $e')),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

/// 使用变更 provider 的示例
class MutationsTabAnnotated extends ConsumerStatefulWidget {
  const MutationsTabAnnotated({super.key});

  @override
  ConsumerState<MutationsTabAnnotated> createState() => _MutationsTabAnnotatedState();
}

class _MutationsTabAnnotatedState extends ConsumerState<MutationsTabAnnotated> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Create New User',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _createUser,
            child: const Text('Create User'),
          ),
          const SizedBox(height: 32),
          const Text(
            'Features of @riverpod + QueryProvider:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('✅ 自动缓存和状态管理'),
          const Text('✅ 乐观更新和回滚'),
          const Text('✅ 自动重试机制'),
          const Text('✅ 缓存失效和刷新'),
          const Text('✅ 网络状态感知'),
          const Text('✅ 保持 @riverpod 的所有优势'),
        ],
      ),
    );
  }

  void _createUser() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    try {
      // 使用 QueryUtils 创建的 mutation provider
      await ref.read(simpleCreateUserProvider.notifier).mutate({
        'name': _nameController.text,
        'email': _emailController.text,
      });

      _nameController.clear();
      _emailController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User created successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create user: $e')),
        );
      }
    }
  }
}
