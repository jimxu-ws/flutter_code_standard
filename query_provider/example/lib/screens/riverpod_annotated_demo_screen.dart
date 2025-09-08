import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import '../providers/riverpod_annotated_example.dart';  // 需要运行 build_runner 后取消注释
import '../models/user.dart';
import '../models/post.dart';

/// 展示 @riverpod 注解与 QueryProvider 集成的示例
/// 
/// 注意：这个屏幕需要先运行 `dart run build_runner build` 来生成 provider 代码
class RiverpodAnnotatedDemoScreen extends ConsumerWidget {
  const RiverpodAnnotatedDemoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('@riverpod 注解示例,需要运行 build_runner 生成代码'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.code,
              size: 64,
              color: Colors.blue,
            ),
            SizedBox(height: 16),
            Text(
              '🚀 @riverpod 注解示例',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                '这个示例展示了如何将 @riverpod 注解与 QueryProvider 集成：\n\n'
                '✅ 自动缓存和状态管理\n'
                '✅ 乐观更新和错误回滚\n'
                '✅ 智能数据获取\n'
                '✅ 批量操作支持\n\n'
                '要查看完整功能，请运行：\n'
                'dart run build_runner build\n\n'
                '然后取消注释 provider 导入',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ),
            SizedBox(height: 24),
            _BuildInstructions(),
          ],
        ),
      ),
    );
  }
}

class _BuildInstructions extends StatelessWidget {
  const _BuildInstructions();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📝 使用步骤：',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text('1. 运行代码生成：'),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(4.0),
              ),
              child: const Text(
                'dart run build_runner build',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text('2. 取消注释 provider 导入'),
            const SizedBox(height: 8),
            const Text('3. 重新启动应用'),
            const SizedBox(height: 12),
            const Text(
              '💡 提示：',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text(
              '代码生成后，你将看到完整的 @riverpod 注解示例，'
              '包括带缓存的查询、乐观更新的变更操作等。',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 以下是生成代码后可以使用的示例组件
// ============================================================================

/// 用户列表组件（需要生成代码后才能使用）
class _UsersListExample extends ConsumerWidget {
  const _UsersListExample();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 取消注释以下代码（需要先运行 build_runner）：
    // final usersAsync = ref.watch(usersWithCacheProvider);
    // 
    // return usersAsync.when(
    //   loading: () => const Center(child: CircularProgressIndicator()),
    //   error: (error, stack) => Center(
    //     child: Column(
    //       mainAxisAlignment: MainAxisAlignment.center,
    //       children: [
    //         Text('Error: $error'),
    //         ElevatedButton(
    //           onPressed: () => ref.invalidate(usersWithCacheProvider),
    //           child: const Text('Retry'),
    //         ),
    //       ],
    //     ),
    //   ),
    //   data: (users) => RefreshIndicator(
    //     onRefresh: () => ref.refresh(usersWithCacheProvider.future),
    //     child: ListView.builder(
    //       itemCount: users.length,
    //       itemBuilder: (context, index) {
    //         final user = users[index];
    //         return ListTile(
    //           leading: CircleAvatar(
    //             backgroundImage: user.avatar != null 
    //               ? NetworkImage(user.avatar!) 
    //               : null,
    //             child: user.avatar == null ? Text(user.name[0]) : null,
    //           ),
    //           title: Text(user.name),
    //           subtitle: Text(user.email),
    //           trailing: const Icon(Icons.arrow_forward_ios),
    //           onTap: () => _showUserDetail(context, ref, user.id),
    //         );
    //       },
    //     ),
    //   ),
    // );

    return const Center(
      child: Text('需要运行 build_runner 生成代码'),
    );
  }

  void _showUserDetail(BuildContext context, WidgetRef ref, int userId) {
    // showDialog(
    //   context: context,
    //   builder: (context) => _UserDetailDialog(userId: userId),
    // );
  }
}

/// 创建用户按钮组件（需要生成代码后才能使用）
class _CreateUserButtonExample extends ConsumerStatefulWidget {
  const _CreateUserButtonExample();

  @override
  ConsumerState<_CreateUserButtonExample> createState() => _CreateUserButtonExampleState();
}

class _CreateUserButtonExampleState extends ConsumerState<_CreateUserButtonExample> {
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
    return Column(
      children: [
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
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _createUser,
          child: const Text('Create User with Optimistic Update'),
        ),
      ],
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
      // 取消注释以下代码（需要先运行 build_runner）：
      // await ref.read(createUserWithOptimisticProvider({
      //   'name': _nameController.text,
      //   'email': _emailController.text,
      // }).future);

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

/// 帖子列表组件（需要生成代码后才能使用）
class _PostsListExample extends ConsumerWidget {
  const _PostsListExample();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 取消注释以下代码（需要先运行 build_runner）：
    // final postsAsync = ref.watch(postsWithCacheProvider);
    // 
    // return postsAsync.when(
    //   loading: () => const Center(child: CircularProgressIndicator()),
    //   error: (error, stack) => Center(child: Text('Error: $error')),
    //   data: (posts) => ListView.builder(
    //     itemCount: posts.length,
    //     itemBuilder: (context, index) {
    //       final post = posts[index];
    //       return Card(
    //         margin: const EdgeInsets.all(8.0),
    //         child: ListTile(
    //           title: Text(post.title),
    //           subtitle: Text(
    //             post.body,
    //             maxLines: 2,
    //             overflow: TextOverflow.ellipsis,
    //           ),
    //           trailing: PopupMenuButton<String>(
    //             onSelected: (value) async {
    //               switch (value) {
    //                 case 'edit':
    //                   // 使用乐观更新编辑帖子
    //                   await ref.read(updatePostWithOptimisticProvider(post.id, {
    //                     'title': '${post.title} (edited)',
    //                     'body': '${post.body} (edited)',
    //                   }).future);
    //                   break;
    //                 case 'delete':
    //                   // 使用乐观更新删除帖子
    //                   await ref.read(deletePostWithOptimisticProvider(post.id).future);
    //                   break;
    //               }
    //             },
    //             itemBuilder: (context) => [
    //               const PopupMenuItem(value: 'edit', child: Text('Edit')),
    //               const PopupMenuItem(value: 'delete', child: Text('Delete')),
    //             ],
    //           ),
    //         ),
    //       );
    //     },
    //   ),
    // );

    return const Center(
      child: Text('需要运行 build_runner 生成代码'),
    );
  }
}
