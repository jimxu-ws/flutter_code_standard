# @riverpod 注解集成指南

## 概述

这个指南展示了如何将 `@riverpod` 注解与 QueryProvider 的缓存、乐观更新等功能完美结合。

## 🚀 快速开始

### 1. 查看示例代码

- **文件位置**: `example/lib/providers/riverpod_annotated_example.dart`
- **UI 示例**: `example/lib/screens/riverpod_annotated_demo_screen.dart`

### 2. 运行代码生成

```bash
cd example
dart run build_runner build
```

### 3. 启用示例

取消注释 `riverpod_annotated_demo_screen.dart` 中的 provider 导入：

```dart
import '../providers/riverpod_annotated_example.dart';  // 取消注释这行
```

## 📝 核心特性

### ✅ 带缓存的查询

```dart
@riverpod
Future<List<User>> usersWithCache(UsersWithCacheRef ref) async {
  final queryClient = ref.queryClient;
  
  // 检查缓存
  final cached = queryClient.getQueryData<List<User>>('users');
  if (cached != null) return cached;
  
  // 获取并缓存数据
  final users = await ApiService.fetchUsers();
  queryClient.setQueryData<List<User>>('users', users);
  return users;
}
```

### ✅ 乐观更新的变更

```dart
@riverpod
Future<User> createUserWithOptimistic(
  CreateUserWithOptimisticRef ref,
  Map<String, dynamic> userData,
) async {
  final queryClient = ref.queryClient;
  
  // 乐观更新
  final currentUsers = queryClient.getQueryData<List<User>>('users');
  if (currentUsers != null) {
    final optimisticUser = User(/* ... */);
    queryClient.setQueryData<List<User>>('users', [...currentUsers, optimisticUser]);
  }

  try {
    final result = await ApiService.createUser(userData);
    ref.invalidateQueries('users'); // 获取真实数据
    return result;
  } catch (error) {
    ref.invalidateQueries('users'); // 回滚
    rethrow;
  }
}
```

### ✅ 智能数据获取

```dart
@riverpod
Future<List<Post>> userPostsWithSmartCache(
  UserPostsWithSmartCacheRef ref,
  int userId,
) async {
  final queryClient = ref.queryClient;
  
  // 先从全局帖子缓存中过滤
  final cachedPosts = queryClient.getQueryData<List<Post>>('posts');
  if (cachedPosts != null) {
    final userPosts = cachedPosts.where((post) => post.userId == userId).toList();
    if (userPosts.isNotEmpty) return userPosts;
  }

  // 没有缓存时才请求 API
  final result = await ApiService.fetchUserPosts(userId);
  queryClient.setQueryData<List<Post>>('user-posts-$userId', result);
  return result;
}
```

## 🎯 UI 中的使用

### 基础查询

```dart
class UsersWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(usersWithCacheProvider);
    
    return usersAsync.when(
      loading: () => CircularProgressIndicator(),
      error: (error, stack) => Text('Error: $error'),
      data: (users) => ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) => ListTile(
          title: Text(users[index].name),
          subtitle: Text(users[index].email),
        ),
      ),
    );
  }
}
```

### 乐观更新变更

```dart
class CreateUserButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () async {
        try {
          // 立即更新 UI，然后同步到服务器
          await ref.read(createUserWithOptimisticProvider({
            'name': 'John Doe',
            'email': 'john@example.com',
          }).future);
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('用户创建成功！')),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('创建失败: $e')),
          );
        }
      },
      child: Text('创建用户'),
    );
  }
}
```

## 🔧 高级功能

### 批量操作

```dart
@riverpod
Future<void> batchUpdatePostsWithCache(
  BatchUpdatePostsWithCacheRef ref,
  List<Map<String, dynamic>> updates,
) async {
  try {
    for (final update in updates) {
      await ApiService.updatePost(update['id'], update['data']);
    }
    
    // 批量操作完成后统一刷新缓存
    ref.invalidateQueries('posts');
    ref.invalidateQueries('user-posts');
  } catch (error) {
    ref.invalidateQueries('posts'); // 确保数据一致性
    rethrow;
  }
}
```

### 条件缓存

```dart
@riverpod
Future<List<User>> activeUsersWithCache(ActiveUsersWithCacheRef ref) async {
  final queryClient = ref.queryClient;
  
  // 优先从全量用户中过滤
  final allUsers = queryClient.getQueryData<List<User>>('users');
  if (allUsers != null) {
    return allUsers.where((user) => user.isActive).toList();
  }
  
  // 没有全量数据时直接请求活跃用户
  return ApiService.fetchActiveUsers();
}
```

## 🎨 主要优势

### 1. **保持 Riverpod 语法**
- ✅ 继续使用熟悉的 `@riverpod` 注解
- ✅ 完整的代码生成支持
- ✅ 类型安全的 provider

### 2. **增强的数据管理**
- ✅ **智能缓存**: 减少不必要的网络请求
- ✅ **乐观更新**: 立即响应用户操作
- ✅ **错误回滚**: 失败时自动恢复状态
- ✅ **批量操作**: 高效处理多个数据变更

### 3. **无缝集成**
- ✅ 使用 `ref.queryClient` 访问缓存
- ✅ 使用 `ref.invalidateQueries()` 刷新数据
- ✅ 所有 QueryProvider 功能都可用

## 📚 完整示例

查看 `example/lib/providers/riverpod_annotated_example.dart` 获取完整的示例代码，包括：

- 带缓存的查询 provider
- 乐观更新的变更 provider  
- 智能数据获取策略
- 批量操作处理
- 错误处理和回滚机制

## 🛠 设置步骤

1. **添加依赖** (已在示例项目中配置)
2. **创建 provider** 使用 `@riverpod` 注解
3. **运行代码生成**: `dart run build_runner build`
4. **在 UI 中使用** 生成的 provider

这样你就可以在享受 `@riverpod` 注解便利性的同时，获得 React Query 级别的数据管理能力！ 🎉
