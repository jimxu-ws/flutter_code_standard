# Flutter 开发规范

## 📋 目录

- [1. 类，函数与变量](#1-类函数与变量)
  - [1.1 命名](#11-命名)
- [2. 页面规范](#2-页面规范)
  - [2.1 SafeArea 使用](#21-safearea-使用)
  - [2.2 页面埋点](#22-页面埋点)
- [3. 状态管理规范](#3-状态管理规范)
  - [3.1 状态管理选择原则](#31-状态管理选择原则)
    - [3.1.1 状态管理选择示例](#311-状态管理选择示例)
    - [3.1.2 状态管理选择决策树](#312-状态管理选择决策树)
    - [3.1.3 最佳实践总结](#313-最佳实践总结)
  - [3.2 Provider 设计原则](#32-provider-设计原则)
  - [3.3 异步状态管理规范](#33-异步状态管理规范)
    - [3.3.1 FutureProvider 使用规范](#331-futureprovider-使用规范)
    - [3.3.2 AsyncNotifier 使用规范](#332-asynctifier-使用规范)
    - [3.3.3 避免 "Future already completed" 错误的规范](#333-避免-future-already-completed-错误的规范)
    - [3.3.4 常见错误预防清单](#334-常见错误预防清单)
    - [3.3.5 调试技巧](#335-调试技巧)
  - [3.4 Hooks 使用规范](#34-hooks-使用规范)
  - [3.5 WidgetRef 和 Ref 使用规范](#35-widgetref-和-ref-使用规范)
    - [3.5.1 Context 传递注意事项](#351-context-传递注意事项)
    - [3.5.2 正确的使用方式](#352-正确的使用方式)
    - [3.5.3 错误的使用方式](#353-错误的使用方式)
    - [3.5.4 在 Notifier 中正确使用 Ref](#354-在-notifier-中正确使用-ref)
    - [3.5.5 异步操作中的 Ref 使用](#355-异步操作中的-ref-使用)
    - [3.5.6 常见陷阱和解决方案](#356-常见陷阱和解决方案)
    - [3.5.7 最佳实践总结](#357-最佳实践总结)
    - [3.5.8 关于 `await ref.read(xxxProvider.future)` 的安全性问题](#358-关于-await-refreadxxxproviderfuture-的安全性问题)
    - [3.5.9 重要概念澄清：为什么 Notifier 中可以使用 ref？](#359-重要概念澄清为什么-notifier-中可以使用-ref)
  - [3.6 Riverpod 在特殊场景下的使用规范](#36-riverpod-在特殊场景下的使用规范)
    - [3.6.1 Method Channel 和原生插件场景](#361-method-channel-和原生插件场景)
    - [3.6.2 模块化隔离下Riverpod最佳实践](#362-模块化隔离下riverpod最佳实践)
      - [3.6.2.1 分层架构设计](#3621-分层架构设计)
      - [3.6.2.2 模块化下的状态更新和 App Rebuild 规范](#3622-模块化下的状态更新和-app-rebuild-规范)
      - [3.6.2.3 模块化状态管理最佳实践](#3623-模块化状态管理最佳实践)
    - [3.6.3 特殊场景使用规范总结](#363-特殊场景使用规范总结)
- [4. 数据模型规范](#4-数据模型规范)
  - [4.1 推荐库](#41-推荐库)
  - [4.2 JSON 序列化类型安全和错误处理规范](#42-json-序列化类型安全和错误处理规范)
- [5. 异常处理规范](#5-异常处理规范)
  - [5.1 异常处理架构](#51-异常处理架构)
  - [5.2 异常分类和层次结构](#52-异常分类和层次结构)
  - [5.3 何时应该 throw Exception](#53-何时应该-throw-exception)
    - [5.3.1 异常使用规范总结](#531-异常使用规范总结)
- [6. 代码质量规范](#6-代码质量规范)
  - [6.1 代码风格](#61-代码风格)
  - [6.2 注释规范](#62-注释规范)
  - [6.3 测试规范](#63-测试规范)
- [7. 性能优化规范](#7-性能优化规范)
  - [7.1 Widget优化](#71-widget优化)
  - [7.2 状态管理优化](#72-状态管理优化)
- [8. 安全规范](#8-安全规范)
  - [8.1 数据安全](#81-数据安全)
  - [8.2 输入验证](#82-输入验证)
- [9. 版本控制规范](#9-版本控制规范)
  - [9.1 提交信息](#91-提交信息)
  - [9.2 分支管理](#92-分支管理)
- [10. 部署规范](#10-部署规范)
  - [10.1 构建配置](#101-构建配置)
  - [10.2 发布流程](#102-发布流程)

---

## 📖 正文
## 1. 类，函数与变量
### 1.1 命名
- **必须**：命名要self explain，私有函数或变量用_开头以保证私有。
- **自定义Widget**：必须有 `Widget` 后缀
  - ✅ `CustomButtonWidget`
  - ❌ `CustomButton`
- **生成Widget的函数**：需要有 `build` 前缀
  - ✅ `Widget buildCustomButton()`
  - ❌ `Widget customButton()`

## 2. 页面规范
### 2.1 SafeArea 使用
- **必须**：所有页面都要添加 SafeArea，避免不同机型（刘海屏、挖孔屏等）的布局差异导致的bug。可以通过继承基类实现
- **示例**：
```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// BaseScreen 是所有页面的基类
/// 提供 Scaffold、状态栏控制，并通过抽象方法获取 pageUnit
abstract class BaseScreen extends HookConsumerWidget {
  const BaseScreen({super.key});

  /// 子类必须实现，返回页面标识，可以做一些页面的统计
  String get pageUnit;

  /// 状态栏颜色，默认透明
  Color get statusBarColor => Theme.transparent;

  /// 状态栏亮暗模式，默认 dark
  Brightness get statusBarBrightness => Theme.dark;

  /// 子类必须实现页面主体
  Widget buildBody(BuildContext context, WidgetRef ref);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useEffect(() {
        //track point
    })
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: statusBarColor,
        statusBarIconBrightness: statusBarBrightness == Theme.dark
            ? Theme.light
            : Theme.dark,
        statusBarBrightness: statusBarBrightness,
      ),
      child: Scaffold(
        body: SafeArea(
          child: buildBody(context, ref),
        ),
      ),
    );
  }
}

class HomeScreen extends BaseScreen {
  const HomeScreen({super.key});

  @override
  String get pageUnit => 'home_page';

  // statusBarColor 默认透明，不需要覆盖

  @override
  Brightness get statusBarBrightness => Theme.light;

  @override
  Widget buildBody(BuildContext context, WidgetRef ref) {
    return Center(
      child: Text('Home Page'),
    );
  }
}
```
### 2.2 页面埋点
- **必须**：所有页面通过继承基类实现默认的埋点逻辑

## 2. 项目结构组织

### 2.1 文件夹组织
按功能模块组织代码，推荐以下结构：
```
lib/
├── screens/          # 页面级组件
├── widgets/          # 可复用组件
├── hooks/            # 自定义hooks
├── services/         # 业务服务层
├── providers/        # 状态管理
├── models/           # 数据模型
├── utils/            # 工具函数
└── constants/        # 常量定义
```

## 3. 状态管理规范

### 3.1 状态管理选择原则
- **跨页面状态**：使用 Provider
- **单页面内状态**：使用 Hooks
- **注意事项**：这两种方案都必须是和状态有关的，避免没有管理状态的Provider或者Hooks；禁止使用其他状态管理方案

#### 3.1.1 状态管理选择示例

##### ✅ 正确：跨页面状态使用 Provider
```dart
// 用户信息 - 跨页面共享状态
final userProvider = StateNotifierProvider<UserNotifier, User?>((ref) {
  return UserNotifier();
});

class UserNotifier extends StateNotifier<User?> {
  UserNotifier() : super(null);
  
  void login(User user) {
    state = user;
  }
  
  void logout() {
    state = null;
  }
}

// 在登录页面使用
class LoginPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () {
        // 更新用户状态，其他页面会自动响应
        ref.read(userProvider.notifier).login(User(id: '1', name: 'John'));
        Navigator.pushReplacementNamed(context, '/home');
      },
      child: Text('Login'),
    );
  }
}

// 在首页使用
class HomePage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    
    if (user == null) {
      return Text('Please login');
    }
    
    return Column(
      children: [
        Text('Welcome, ${user.name}!'),
        ElevatedButton(
          onPressed: () {
            // 登出后，所有监听用户状态的页面都会更新
            ref.read(userProvider.notifier).logout();
            Navigator.pushReplacementNamed(context, '/login');
          },
          child: Text('Logout'),
        ),
      ],
    );
  }
}
```

##### ✅ 正确：单页面内状态使用 Hooks
```dart
// 表单输入状态 - 仅在当前页面使用
class LoginForm extends HookWidget {
  @override
  Widget build(BuildContext context) {
    // 使用 Hooks 管理表单状态
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();
    final isPasswordVisible = useState(false);
    final isLoading = useState(false);
    
    // 表单验证状态
    final emailError = useState<String?>(null);
    final passwordError = useState<String?>(null);
    
    // 清理资源
    useEffect(() {
      return () {
        emailController.dispose();
        passwordController.dispose();
      };
    }, []);
    
    return Column(
      children: [
        TextField(
          controller: emailController,
          decoration: InputDecoration(
            labelText: 'Email',
            errorText: emailError.value,
          ),
          onChanged: (value) {
            // 实时验证
            if (value.isEmpty) {
              emailError.value = 'Email is required';
            } else if (!value.contains('@')) {
              emailError.value = 'Invalid email format';
            } else {
              emailError.value = null;
            }
          },
        ),
        TextField(
          controller: passwordController,
          obscureText: !isPasswordVisible.value,
          decoration: InputDecoration(
            labelText: 'Password',
            errorText: passwordError.value,
            suffixIcon: IconButton(
              icon: Icon(
                isPasswordVisible.value ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () {
                isPasswordVisible.value = !isPasswordVisible.value;
              },
            ),
          ),
        ),
        ElevatedButton(
          onPressed: isLoading.value ? null : () async {
            isLoading.value = true;
            // 模拟登录
            await Future.delayed(Duration(seconds: 2));
            isLoading.value = false;
          },
          child: isLoading.value 
            ? CircularProgressIndicator() 
            : Text('Login'),
        ),
      ],
    );
  }
}
```

##### ❌ 错误：不恰当的状态管理使用

###### 错误示例1：没有管理状态的 Provider
```dart
// ❌ 错误：Provider 没有管理状态，只是返回静态数据
final staticDataProvider = Provider<String>((ref) {
  return 'This is static data'; // 没有状态变化
});

// ❌ 错误：Provider 没有状态管理，只是工具函数
final utilityProvider = Provider<UtilityService>((ref) {
  return UtilityService(); // 没有状态，只是服务实例
});
```

###### 错误示例2：没有管理状态的 Hooks
```dart
class MyWidget extends HookWidget {
  @override
  Widget build(BuildContext context) {
    // ❌ 错误：useState 没有实际使用状态变化
    final unusedState = useState(0);
    
    // ❌ 错误：useEffect 没有依赖，总是执行
    useEffect(() {
      print('This will always run');
    }, []); // 空依赖数组
    
    return Text('Hello World');
  }
}
```

###### 错误示例3：在单页面内使用 Provider 管理简单状态
```dart
// ❌ 错误：简单的表单状态使用 Provider 过度设计
final formStateProvider = StateNotifierProvider<FormStateNotifier, FormState>((ref) {
  return FormStateNotifier();
});

class FormStateNotifier extends StateNotifier<FormState> {
  FormStateNotifier() : super(FormState.initial());
  
  void updateEmail(String email) {
    state = state.copyWith(email: email);
  }
  
  void updatePassword(String password) {
    state = state.copyWith(password: password);
  }
}

// 这种简单状态更适合使用 Hooks
```

#### 3.1.2 状态管理选择决策树

```
需要状态管理？
├─ 是
│  ├─ 状态需要在多个页面间共享？
│  │  ├─ 是 → 使用 Provider ✅
│  │  └─ 否 → 使用 Hooks ✅
│  └─ 状态复杂程度？
│     ├─ 简单（表单输入、UI 状态）→ 使用 Hooks ✅
│     └─ 复杂（业务逻辑、数据流）→ 使用 Provider ✅
└─ 否
   └─ 不需要状态管理，使用普通 Widget ❌
```

#### 3.1.3 最佳实践总结

##### 🎯 Provider 适用场景
- **用户认证状态**：登录、登出、用户信息
- **应用配置**：主题、语言、设置
- **全局数据**：购物车、待办事项、通知
- **复杂业务逻辑**：数据流、状态机、缓存管理

##### 🎯 Hooks 适用场景
- **表单状态**：输入验证、提交状态
- **UI 状态**：展开/收起、显示/隐藏
- **动画状态**：进度条、加载动画
- **临时状态**：页面内临时数据

##### 🚫 避免场景
- **静态数据**：不需要状态管理的静态信息
- **工具函数**：没有状态的纯函数服务
- **过度设计**：简单状态使用复杂的状态管理
- **混合使用**：同一功能模块混用多种状态管理方案

### 3.2 Provider 设计原则
- **职责单一**：Provider 应该只包含：
  - `state`：状态数据
  - `side effects`：副作用操作（如API调用、本地存储等）
- **避免包含**：UI构建逻辑，某些状态的getter等，状态的getter可以通过hooks来实现
- **生命周期**：如无必要，不要keepAlive
- **Mock友好**：设计时要考虑如何mock这个状态，便于后期测试

### 3.3 异步状态管理规范
- **避免重复调用**：确保异步操作不会被重复触发
- **状态重置**：在开始新的异步操作前，先重置状态
- **错误处理**：正确处理异步操作的错误状态
- **生命周期管理**：在组件销毁时取消未完成的异步操作

#### 3.3.1 FutureProvider 使用规范
```dart
// ✅ 正确：使用 ref.watch 而不是 ref.read
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncValue = ref.watch(myFutureProvider);
    
    return asyncValue.when(
      data: (data) => Text('Data: $data'),
      loading: () => CircularProgressIndicator(),
      error: (error, stack) => Text('Error: $error'),
    );
  }
}

// ❌ 错误：在 build 方法中调用 ref.read
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 这会导致重复调用和状态混乱
    ref.read(myFutureProvider);
    return Container();
  }
}
```

#### 3.3.2 AsyncNotifier 使用规范
```dart
class UserNotifier extends AsyncNotifier<User> {
  @override
  Future<User> build() async {
    // 初始化时加载数据
    return await _fetchUser();
  }

  Future<void> refreshUser() async {
    // ✅ 正确：先设置状态为加载中
    state = const AsyncValue.loading();
    
    try {
      // 获取新数据
      final user = await _fetchUser();
      state = AsyncValue.data(user);
    } catch (error, stackTrace) {
      // 错误处理
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateUser(User user) async {
    // ✅ 正确：使用 copyWith 更新状态
    state = state.whenData((currentUser) => user);
    
    try {
      await _updateUserOnServer(user);
      // 更新成功后刷新数据
      await refreshUser();
    } catch (error, stackTrace) {
      // 恢复原状态
      state = AsyncValue.error(error, stackTrace);
    }
  }
}
```

#### 3.3.3 避免 "Future already completed" 错误的规范

##### 方案一：使用 mounted 属性（推荐）
```dart
class UserNotifier extends AsyncNotifier<User> {
  @override
  Future<User> build() async {
    return await _fetchUser();
  }

  Future<void> refreshUser() async {
    // ✅ 使用 mounted 检查组件是否还在树中
    if (!mounted) return;
    
    state = const AsyncValue.loading();
    
    try {
      final user = await _fetchUser();
      
      // ✅ 再次检查是否还在树中
      if (!mounted) return;
      
      state = AsyncValue.data(user);
    } catch (error, stackTrace) {
      if (!mounted) return;
      state = AsyncValue.error(error, stackTrace);
    }
  }
}
```

##### 方案二：使用 CancelToken 模式
```dart
class UserNotifier extends AsyncNotifier<User> {
  CancelToken? _cancelToken;
  
  @override
  Future<User> build() async {
    return await _fetchUser();
  }

  @override
  void dispose() {
    _cancelToken?.cancel('Notifier disposed');
    super.dispose();
  }

  Future<void> refreshUser() async {
    // 取消之前的请求
    _cancelToken?.cancel('New request started');
    _cancelToken = CancelToken();
    
    state = const AsyncValue.loading();
    
    try {
      final user = await _fetchUserWithCancelToken(_cancelToken!);
      
      if (!mounted) return;
      state = AsyncValue.data(user);
    } catch (error, stackTrace) {
      if (error is CancelException) return; // 忽略取消异常
      if (!mounted) return;
      state = AsyncValue.error(error, stackTrace);
    }
  }
  
  Future<User> _fetchUserWithCancelToken(CancelToken token) async {
    // 模拟带取消令牌的API调用
    await Future.delayed(Duration(seconds: 2));
    token.throwIfCancelled();
    return User(id: '1', name: 'John');
  }
}
```

##### 方案三：使用 Riverpod 内置的 ref.onDispose
```dart
class UserNotifier extends AsyncNotifier<User> {
  bool _isDisposed = false;
  
  @override
  Future<User> build() async {
    // 在 build 方法中注册销毁回调
    ref.onDispose(() {
      _isDisposed = true;
    });
    
    return await _fetchUser();
  }

  Future<void> refreshUser() async {
    if (_isDisposed) return;
    
    state = const AsyncValue.loading();
    
    try {
      final user = await _fetchUser();
      
      if (_isDisposed) return;
      state = AsyncValue.data(user);
    } catch (error, stackTrace) {
      if (_isDisposed) return;
      state = AsyncValue.error(error, stackTrace);
    }
  }
}
```

##### 方案四：使用 AutoDispose 修饰符（推荐）
```dart
// Riverpod 2.x 版本使用方式
final userProvider = StateNotifierProvider.autoDispose<UserNotifier, AsyncValue<User>>((ref) {
  return UserNotifier();
});

class UserNotifier extends StateNotifier<AsyncValue<User>> {
  UserNotifier() : super(const AsyncValue.loading());
  
  Future<void> refreshUser() async {
    state = const AsyncValue.loading();
    
    try {
      final user = await _fetchUser();
      state = AsyncValue.data(user);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

// Riverpod 3.x 版本使用方式（如果支持）
@riverpod
class UserNotifier extends _$UserNotifier {
  @override
  Future<User> build() async {
    return await _fetchUser();
  }

  Future<void> refreshUser() async {
    state = const AsyncValue.loading();
    
    try {
      final user = await _fetchUser();
      state = AsyncValue.data(user);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

// 使用方式
final userProvider = userNotifierProvider.autoDispose;
```

##### 最佳实践总结
- **Riverpod 2.x**：优先使用 `mounted` 属性 + `StateNotifierProvider.autoDispose`
- **Riverpod 3.x**：可以使用 `@riverpod` 注解 + `autoDispose` 修饰符
- **通用方案**：使用 `mounted` 属性检查，简单有效且对注解友好
- **复杂场景**：结合使用 `CancelToken` 模式
- **避免手动管理 disposed 状态**：容易出错且对注解不友好

##### 版本兼容性说明
- **Riverpod 2.x**：支持 `StateNotifierProvider.autoDispose` 和 `FutureProvider.autoDispose`
- **Riverpod 3.x**：支持 `@riverpod` 注解和 `autoDispose` 修饰符
- **Flutter Hooks**：所有版本都支持 `mounted` 属性检查

### 3.4 Hooks 使用规范
- **最佳实践**：遵循 Flutter Hooks 的使用规则
- **适用场景**：带状态依赖的单页面简单逻辑封装
- **示例**：
```dart
class MyWidget extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final counter = useState(0);
    final isLoading = useState(false);
    
    useEffect(() {
      // 副作用逻辑
      return () {
        // 清理逻辑
      };
    }, [counter.value]);
    
    return Column(
      children: [
        Text('Count: ${counter.value}'),
        ElevatedButton(
          onPressed: () => counter.value++,
          child: Text('Increment'),
        ),
      ],
    );
  }
}
```

#### 3.4.1 Flutter Hooks 使用陷阱和注意事项

##### 🚨 陷阱一：Hooks 调用顺序问题
```dart
class BadHooksWidget extends HookWidget {
  @override
  Widget build(BuildContext context) {
    // ❌ 错误：条件性调用 Hooks
    if (someCondition) {
      final counter = useState(0); // 这会导致 Hooks 顺序不一致
    }
    
    final isLoading = useState(false);
    
    // ❌ 错误：在循环中调用 Hooks
    for (int i = 0; i < 3; i++) {
      final state = useState(i); // 这会导致 Hooks 顺序不一致
    }
    
    return Container();
  }
}

// ✅ 正确：Hooks 调用顺序一致
class GoodHooksWidget extends HookWidget {
  @override
  Widget build(BuildContext context) {
    // 所有 Hooks 都在顶层调用，顺序一致
    final counter = useState(0);
    final isLoading = useState(false);
    final items = useState<List<int>>([]);
    
    // 条件逻辑在 Hooks 调用之后
    if (someCondition) {
      // 使用已定义的 Hooks
      counter.value = 10;
    }
    
    return Container();
  }
}
```

##### 🚨 陷阱二：useEffect 依赖数组问题
```dart
class BadEffectWidget extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final counter = useState(0);
    final user = useState<User?>(null);
    
    // ❌ 错误：空依赖数组，但使用了外部变量
    useEffect(() {
      fetchUser(counter.value); // 使用了 counter.value 但没有在依赖数组中
    }, []); // 空依赖数组
    
    // ❌ 错误：依赖数组包含对象，可能导致无限循环
    useEffect(() {
      updateUser(user.value);
    }, [user.value]); // user.value 是对象，每次都是新的引用
    
    // ✅ 正确：明确的依赖数组
    useEffect(() {
      if (counter.value > 0) {
        fetchUser(counter.value);
      }
    }, [counter.value]); // 明确依赖 counter.value
    
    // ✅ 正确：使用 useMemoized 避免对象引用问题
    final userKey = useMemoized(() => user.value?.id, [user.value?.id]);
    useEffect(() {
      if (userKey != null) {
        updateUser(user.value!);
      }
    }, [userKey]); // 依赖 userKey 而不是整个 user 对象
    
    return Container();
  }
}
```

##### 🚨 陷阱三：useState 初始化和更新问题
```dart
class BadStateWidget extends HookWidget {
  @override
  Widget build(BuildContext context) {
    // ❌ 错误：在 build 方法中直接调用函数初始化
    final expensiveData = useState(expensiveCalculation()); // 每次 build 都会执行
    
    // ❌ 错误：在 useState 中创建新对象
    final user = useState(User(name: 'John', age: 25)); // 每次 build 都创建新对象
    
    // ✅ 正确：使用 useMemoized 延迟初始化
    final expensiveData = useMemoized(() => expensiveCalculation(), []);
    
    // ✅ 正确：使用 useMemoized 避免重复创建对象
    final user = useMemoized(() => User(name: 'John', age: 25), []);
    
    // ✅ 正确：使用 useState 的懒初始化
    final expensiveData = useState<ExpensiveData?>(null);
    useEffect(() {
      expensiveData.value = expensiveCalculation();
    }, []);
    
    return Container();
  }
}
```

##### 🚨 陷阱四：资源清理和内存泄漏
```dart
class BadCleanupWidget extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final controller = useTextEditingController();
    
    // ❌ 错误：没有清理资源
    useEffect(() {
      controller.addListener(() {
        // 监听器逻辑
      });
      // 没有返回清理函数
    }, []);
    
    // ✅ 正确：返回清理函数
    useEffect(() {
      controller.addListener(() {
        // 监听器逻辑
      });
      
      return () {
        controller.removeListener(() {
          // 清理监听器
        });
        controller.dispose(); // 清理控制器
      };
    }, []);
    
    return Container();
  }
}
```

##### 🚨 陷阱五：异步操作中的状态更新
```dart
class BadAsyncWidget extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final isLoading = useState(false);
    final data = useState<String?>(null);
    
    // ❌ 错误：在异步操作中直接更新状态，可能导致组件已销毁
    Future<void> fetchData() async {
      isLoading.value = true;
      try {
        await Future.delayed(Duration(seconds: 2));
        data.value = 'Fetched data'; // 组件可能已经销毁
      } finally {
        isLoading.value = false; // 组件可能已经销毁
      }
    }
    
    // ✅ 正确：使用 mounted 检查
    Future<void> fetchData() async {
      isLoading.value = true;
      try {
        await Future.delayed(Duration(seconds: 2));
        
        // 检查组件是否还在树中
        if (mounted) {
          data.value = 'Fetched data';
        }
      } finally {
        if (mounted) {
          isLoading.value = false;
        }
      }
    }
    
    return Container();
  }
}
```

#### 3.4.2 Hooks 最佳实践总结

##### ✅ 必须遵循的规则
1. **Hooks 调用顺序一致**：不要在条件语句、循环或嵌套函数中调用 Hooks
2. **Hooks 只在顶层调用**：确保 Hooks 在每次 render 时都以相同的顺序被调用
3. **正确的依赖数组**：useEffect 的依赖数组要包含所有使用的外部变量
4. **资源清理**：useEffect 要返回清理函数，避免内存泄漏
5. **状态更新检查**：异步操作中更新状态前检查组件是否还在树中

##### 🔧 性能优化技巧
```dart
class OptimizedHooksWidget extends HookWidget {
  @override
  Widget build(BuildContext context) {
    // 使用 useMemoized 避免重复计算
    final expensiveValue = useMemoized(() {
      return expensiveCalculation();
    }, []);
    
    // 使用 useCallback 避免函数重新创建
    final onPressed = useCallback(() {
      // 处理逻辑
    }, []);
    
    // 使用 useValueChanged 监听值变化
    useValueChanged(counter.value, (oldValue, newValue) {
      print('Counter changed from $oldValue to $newValue');
    });
    
    return Container();
  }
}
```

##### 🚫 常见错误模式
- **条件性 Hooks 调用**：在 if 语句中调用 Hooks
- **循环中调用 Hooks**：在 for 循环中调用 Hooks
- **空依赖数组误用**：useEffect 使用了外部变量但依赖数组为空
- **对象依赖问题**：依赖数组中包含对象引用
- **资源未清理**：useEffect 没有返回清理函数
- **异步状态更新**：在已销毁的组件上更新状态

#### 3.3.4 常见错误预防清单
- **✅ 正确做法**：
  - 在 `build` 方法中使用 `ref.watch` 监听状态变化
  - 在事件回调中使用 `ref.read` 调用方法
  - 异步操作前检查组件是否已被销毁
  - 使用 `AsyncValue.loading()` 设置加载状态
  - 正确处理异步操作的错误状态

- **❌ 错误做法**：
  - 在 `build` 方法中调用 `ref.read`
  - 在异步操作完成后不检查组件状态
  - 重复设置相同的状态值
  - 在已销毁的组件上更新状态
  - 忽略异步操作的错误处理

### 3.4 Hooks 使用规范
- **最佳实践**：遵循 Flutter Hooks 的使用规则
- **适用场景**：带状态依赖的简单逻辑封装
- **示例**：
```dart
class MyWidget extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final counter = useState(0);
    final isLoading = useState(false);
    
    useEffect(() {
      // 副作用逻辑
      return () {
        // 清理逻辑
      };
    }, [counter.value]);
    
    return Column(
      children: [
        Text('Count: ${counter.value}'),
        ElevatedButton(
          onPressed: () => counter.value++,
          child: Text('Increment'),
        ),
      ],
    );
  }
}
```

### 3.5 WidgetRef 和 Ref 使用规范

#### 3.5.1 Context 传递注意事项
- **✅ 正确做法**：在 Widget 的 build 方法中直接使用 ref 参数
- **❌ 错误做法**：将 ref 传递给其他方法或存储为实例变量
- **生命周期**：ref 只在 build 方法执行期间有效

#### 3.5.2 正确的使用方式
```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ✅ 正确：在 build 方法中直接使用 ref
    final user = ref.watch(userProvider);
    
    return Column(
      children: [
        Text('User: ${user.name}'),
        ElevatedButton(
          onPressed: () {
            // ✅ 正确：在事件回调中使用 ref.read
            ref.read(userNotifierProvider.notifier).refreshUser();
          },
          child: Text('Refresh'),
        ),
      ],
    );
  }
}
```

#### 3.5.3 错误的使用方式
```dart
class MyWidget extends ConsumerWidget {
  // ❌ 错误：不要将 ref 存储为实例变量
  late WidgetRef _ref;
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ❌ 错误：不要将 ref 赋值给实例变量
    _ref = ref;
    
    return ElevatedButton(
      onPressed: () {
        // ❌ 错误：使用存储的 ref 可能导致问题
        _ref.read(userNotifierProvider.notifier).refreshUser();
      },
      child: Text('Refresh'),
    );
  }
}
```

#### 3.5.4 在 Notifier 中正确使用 Ref
```dart
class UserNotifier extends AsyncNotifier<User> {
  @override
  Future<User> build() async {
    // ✅ 正确：在 build 方法中可以使用 ref
    final apiService = ref.read(apiServiceProvider);
    return await apiService.fetchUser();
  }

  Future<void> refreshUser() async {
    // ✅ 正确：在 Notifier 的方法中可以使用 ref
    // 这是因为 Notifier 本身持有 ref 的引用，而不是从外部传入的
    final apiService = ref.read(apiServiceProvider);
    
    state = const AsyncValue.loading();
    try {
      final user = await apiService.fetchUser();
      state = AsyncValue.data(user);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}
```

#### 3.5.5 异步操作中的 Ref 使用
```dart
class UserNotifier extends AsyncNotifier<User> {
  @override
  Future<User> build() async {
    return await _fetchUser();
  }

  Future<void> refreshUser() async {
    state = const AsyncValue.loading();
    
    try {
      // ✅ 正确：在异步操作开始前获取需要的依赖
      final apiService = ref.read(apiServiceProvider);
      final user = await apiService.fetchUser();
      
      // ✅ 正确：在异步操作完成后检查状态
      if (!mounted) return;
      
      state = AsyncValue.data(user);
    } catch (error, stackTrace) {
      if (!mounted) return;
      state = AsyncValue.error(error, stackTrace);
    }
  }
}
```

#### 3.5.6 常见陷阱和解决方案
```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder(
      future: _someAsyncOperation(ref), // ❌ 错误：传递 ref 给异步操作
      builder: (context, snapshot) {
        return Container();
      },
    );
  }
  
  // ❌ 错误：异步方法不应该接收 ref 参数
  Future<void> _someAsyncOperation(WidgetRef ref) async {
    // 这里使用 ref 可能不安全
  }
}

// ✅ 正确：使用 ref.read 在同步代码中获取数据
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder(
      future: _someAsyncOperation(), // ✅ 不传递 ref
      builder: (context, snapshot) {
        return Container();
      },
    );
  }
  
  // ✅ 正确：异步方法不依赖 ref
  Future<void> _someAsyncOperation() async {
    // 异步逻辑
  }
}
```

#### 3.5.7 最佳实践总结
- **ref 只在 build 方法中有效**：不要存储或传递 ref
- **异步操作前获取依赖**：使用 `ref.read` 在异步操作开始前获取所需数据
- **检查组件状态**：在异步操作完成后使用 `mounted` 检查组件状态
- **避免闭包陷阱**：不要在异步回调中直接使用 ref
- **使用 Provider 依赖**：通过 Provider 的依赖关系而不是直接传递 ref

#### 3.5.8 关于 `await ref.read(xxxProvider.future)` 的安全性问题

##### ⚠️ 潜在的安全问题
```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () async {
        // ⚠️ 潜在问题：ref.read(xxxProvider.future) 可能不安全
        try {
          final result = await ref.read(userProvider.future);
          // 这里使用 result 可能不安全
          print('User: ${result.name}');
        } catch (e) {
          print('Error: $e');
        }
      },
      child: Text('Get User'),
    );
  }
}
```

##### 🚨 主要风险
1. **Provider 状态变化**：Provider 可能在 await 期间被销毁或重建
2. **组件生命周期**：Widget 可能在 await 期间被销毁
3. **状态不一致**：获取的数据可能与当前 Provider 状态不一致
4. **内存泄漏**：可能导致不必要的内存占用

##### ✅ 安全的替代方案

###### 方案一：使用 ref.watch 监听状态变化
```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ✅ 正确：使用 ref.watch 监听状态变化
    final userAsync = ref.watch(userProvider);
    
    return userAsync.when(
      data: (user) => Text('User: ${user.name}'),
      loading: () => CircularProgressIndicator(),
      error: (error, stack) => Text('Error: $error'),
    );
  }
}
```

###### 方案二：在异步操作开始前获取数据
```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () async {
        // ✅ 正确：在异步操作开始前获取数据
        final userNotifier = ref.read(userProvider.notifier);
        final currentUser = ref.read(userProvider).value;
        
        if (currentUser != null) {
          // 使用当前数据
          print('Current user: ${currentUser.name}');
        }
        
        // 触发异步操作
        await userNotifier.refreshUser();
      },
      child: Text('Refresh User'),
    );
  }
}
```

###### 方案三：使用 Notifier 方法
```dart
class UserNotifier extends AsyncNotifier<User> {
  @override
  Future<User> build() async {
    return await _fetchUser();
  }

  Future<void> refreshUser() async {
    state = const AsyncValue.loading();
    
    try {
      final user = await _fetchUser();
      
      // ✅ 正确：在 Notifier 中安全地更新状态
      if (!mounted) return;
      state = AsyncValue.data(user);
    } catch (error, stackTrace) {
      if (!mounted) return;
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

// 使用方式
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () {
        // ✅ 正确：调用 Notifier 方法，让 Notifier 处理异步逻辑
        ref.read(userProvider.notifier).refreshUser();
      },
      child: Text('Refresh User'),
    );
  }
}
```

##### 🎯 最佳实践总结

###### ✅ 推荐的做法
- **使用 ref.watch**：监听 Provider 状态变化，自动重建 UI
- **在 Notifier 中处理异步逻辑**：让 Notifier 负责状态管理和异步操作
- **异步操作前获取数据**：在异步操作开始前使用 `ref.read` 获取当前数据
- **使用 mounted 检查**：在异步操作完成后检查组件状态

###### ❌ 不规范的做法（应避免）
- **await ref.read(xxxProvider.future)**：❌ **不规范**，可能导致状态不一致和生命周期问题
- **在异步回调中直接使用 ref**：❌ **不规范**，ref 可能已经无效
- **存储 Provider 的 future**：❌ **不规范**，future 可能与当前 Provider 状态不匹配

###### 🔍 何时可以使用 ref.read(xxxProvider.future)
- **同步代码中**：需要立即获取当前值（但要注意生命周期）
- **调试目的**：临时用于调试，生产环境应避免
- **短期同步操作**：仅在同步上下文中使用，不涉及 await

##### 🚨 重要提醒：为什么 `await ref.read(xxxProvider.future)` 不规范？

1. **违反 Riverpod 设计原则**：Riverpod 设计为响应式状态管理，不是传统的异步数据获取
2. **生命周期管理混乱**：await 期间 Provider 状态可能发生变化
3. **状态不一致风险**：获取的数据可能与当前 UI 状态不匹配
4. **调试困难**：难以追踪数据来源和状态变化
5. **性能问题**：可能导致不必要的重建和内存占用

##### 📋 规范的替代方案对比

| 不规范用法 | 规范替代方案 | 优势 |
|-----------|-------------|------|
| `await ref.read(userProvider.future)` | `ref.watch(userProvider)` | 响应式、自动重建、生命周期安全 |
| `await ref.read(userProvider.future)` | `ref.read(userProvider.notifier).refreshUser()` | 状态管理集中、生命周期安全 |
| `await ref.read(userProvider.future)` | 在 Notifier 中处理异步逻辑 | 职责分离、状态一致性 |

### 3.6 Riverpod 在特殊场景下的使用规范

#### 3.6.1 Method Channel 和原生插件场景

##### 🚨 问题分析
Riverpod 在以下场景中确实存在局限性：
- **Method Channel 调用**：无法直接获取 ref
- **原生插件集成**：插件内部无法访问 Riverpod 上下文
- **模块化隔离**：跨模块的 Provider 依赖复杂
- **第三方库集成**：外部库无法感知 Riverpod 状态


#### 3.6.2 模块化隔离下Riverpod最佳实践

##### 🏗️ 分层架构设计
```dart
// 基础设施层（不依赖 Riverpod）
abstract class INativePluginService {
  Future<String> callMethod(String method, Map<String, dynamic> arguments);
}

class NativePluginService implements INativePluginService {
  static const MethodChannel _channel = MethodChannel('native_plugin');
  
  @override
  Future<String> callMethod(String method, Map<String, dynamic> arguments) async {
    try {
      final result = await _channel.invokeMethod(method, arguments);
      return result.toString();
    } catch (e) {
      throw Exception('Native method call failed: $e');
    }
  }
}

// 业务逻辑层（可选使用 Riverpod）
class UserService {
  final INativePluginService _nativePlugin;
  
  UserService(this._nativePlugin);
  
  Future<User> fetchUser() async {
    final userData = await _nativePlugin.callMethod('getUser', {});
    return User.fromJson(jsonDecode(userData));
  }
}

// 表现层（使用 Riverpod）
final userServiceProvider = Provider<UserService>((ref) {
  final nativePlugin = GlobalServices.instance.nativePlugin;
  return UserService(nativePlugin);
});

final userProvider = AsyncNotifierProvider<UserNotifier, User>(() {
  return UserNotifier();
});
```

#### 3.6.3 特殊场景使用规范总结

##### ✅ 推荐方案
- **Service Locator 模式**：适合全局服务访问
- **Provider 包装器**：适合需要 Provider 生命周期的场景
- **混合架构**：根据具体需求选择合适的方案
- **分层设计**：基础设施层不依赖 Riverpod

##### ❌ 避免方案
- **强制使用 Riverpod**：在不适用的场景下强制使用
- **全局 Provider**：过度使用全局状态管理
- **紧耦合**：模块间过度依赖

##### 🎯 选择原则
1. **需要状态管理**：使用 Riverpod
2. **需要全局访问**：使用 Service Locator
3. **原生插件调用**：直接使用服务类
4. **模块隔离**：使用接口抽象和依赖注入

#### 3.5.8 重要概念澄清：为什么 Notifier 中可以使用 ref？

**关键区别**：
1. **Widget 中的 ref**：通过 `build` 方法参数传入，只在 build 执行期间有效
2. **Notifier 中的 ref**：Notifier 类本身持有 ref 的引用，在整个生命周期内都有效

**具体说明**：
```dart
// Widget 中的 ref - 通过参数传入，生命周期受限
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ref 只在 build 方法执行期间有效
    return ElevatedButton(
      onPressed: () {
        // ✅ 可以在这里使用 ref，因为这是同步的回调
        ref.read(userProvider.notifier).refreshUser();
      },
      child: Text('Refresh'),
    );
  }
}

// Notifier 中的 ref - 类本身持有，生命周期与 Notifier 一致
class UserNotifier extends AsyncNotifier<User> {
  // Notifier 类持有 ref 的引用
  // 这个 ref 在 Notifier 的整个生命周期内都有效
  
  @override
  Future<User> build() async {
    // ✅ 可以使用 ref
    return await ref.read(apiServiceProvider).fetchUser();
  }

  Future<void> refreshUser() async {
    // ✅ 可以使用 ref，因为 Notifier 本身持有 ref 引用
    final apiService = ref.read(apiServiceProvider);
    
    // 异步操作...
    final user = await apiService.fetchUser();
    
    // 更新状态
    state = AsyncValue.data(user);
  }
}
```

**总结**：
- **Widget 中**：ref 是临时参数，不要存储或传递给其他方法
- **Notifier 中**：ref 是类的成员，可以在任何方法中使用
- **异步方法**：在 Notifier 的异步方法中使用 ref 是安全的，因为 ref 的生命周期与 Notifier 一致

### 3.6 BuildContext 使用规范

#### 3.6.1 Context 传递注意事项
- **✅ 正确做法**：在 Widget 的 build 方法中直接使用 context 参数
- **❌ 错误做法**：将 context 传递给其他方法或存储为实例变量
- **生命周期**：context 只在 build 方法执行期间有效
- **作用域**：context 包含当前 Widget 在树中的位置信息

#### 3.6.2 正确的使用方式
```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // ✅ 正确：在 build 方法中直接使用 context
    return Scaffold(
      appBar: AppBar(
        title: Text('My Widget'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              // ✅ 正确：在事件回调中使用 context
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // ✅ 正确：在事件回调中使用 context
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Hello'),
                content: Text('This is a dialog'),
              ),
            );
          },
          child: Text('Show Dialog'),
        ),
      ),
    );
  }
}
```

#### 3.6.3 错误的使用方式
```dart
class MyWidget extends StatefulWidget {
  @override
  _MyWidgetState createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  // ❌ 错误：不要将 context 存储为实例变量
  late BuildContext _context;
  
  @override
  Widget build(BuildContext context) {
    // ❌ 错误：不要将 context 赋值给实例变量
    _context = context;
    
    return ElevatedButton(
      onPressed: () {
        // ❌ 错误：使用存储的 context 可能导致问题
        Navigator.pushNamed(_context, '/settings');
      },
      child: Text('Navigate'),
    );
  }
}
```

#### 3.6.4 在异步操作中正确使用 Context
```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        // ✅ 正确：在异步操作开始前获取 context
        final navigator = Navigator.of(context);
        final theme = Theme.of(context);
        
        // 异步操作
        await Future.delayed(Duration(seconds: 2));
        
        // ✅ 正确：使用之前获取的引用，而不是直接使用 context
        navigator.pushNamed('/result');
        
        // ✅ 正确：使用之前获取的引用
        final color = theme.primaryColor;
      },
      child: Text('Async Operation'),
    );
  }
}
```

#### 3.6.5 Context 在 Notifier 中的使用
```dart
class UserNotifier extends AsyncNotifier<User> {
  @override
  Future<User> build() async {
    return await _fetchUser();
  }

  Future<void> showUserDialog(BuildContext context) async {
    // ✅ 正确：通过参数传入 context
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('User Info'),
        content: Text('User: ${state.value?.name}'),
      ),
    );
  }
}

// 使用方式
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () {
        // ✅ 正确：将 context 传递给 Notifier 方法
        ref.read(userNotifierProvider.notifier).showUserDialog(context);
      },
      child: Text('Show User Dialog'),
    );
  }
}
```

#### 3.6.6 常见陷阱和解决方案
```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _someAsyncOperation(context), // ❌ 错误：传递 context 给异步操作
      builder: (context, snapshot) {
        return Container();
      },
    );
  }
  
  // ❌ 错误：异步方法不应该接收 context 参数
  Future<void> _someAsyncOperation(BuildContext context) async {
    // 这里使用 context 可能不安全
    Navigator.pushNamed(context, '/result');
  }
}

// ✅ 正确：使用 context 在同步代码中获取数据
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _someAsyncOperation(), // ✅ 不传递 context
      builder: (context, snapshot) {
        return Container();
      },
    );
  }
  
  // ✅ 正确：异步方法不依赖 context
  Future<void> _someAsyncOperation() async {
    // 异步逻辑
  }
}
```

#### 3.6.7 Context 的最佳实践
```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // ✅ 正确：在 build 方法开始时就获取常用的引用
    final navigator = Navigator.of(context);
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Container(
        width: mediaQuery.size.width,
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () {
                // ✅ 使用之前获取的引用
                navigator.pushNamed('/page1');
              },
              child: Text('Page 1'),
            ),
            ElevatedButton(
              onPressed: () {
                // ✅ 使用之前获取的引用
                navigator.pushNamed('/page2');
              },
              child: Text('Page 2'),
            ),
          ],
        ),
      ),
    );
  }
}
```

#### 3.6.8 BuildContext 最佳实践总结
- **context 只在 build 方法中有效**：不要存储或传递 context
- **异步操作前获取引用**：使用 `Navigator.of(context)` 等在异步操作开始前获取引用
- **避免在异步回调中使用 context**：context 在异步操作完成后可能无效
- **通过参数传递 context**：在 Notifier 中需要 context 时，通过方法参数传入
- **获取常用引用**：在 build 方法开始时就获取常用的引用，避免重复调用
- **检查 context 有效性**：在异步操作中使用 context 前检查其有效性

## 4. 数据模型规范

### 4.1 推荐库
- **数据类**：使用 `freezed` 库，对于状态模型，推荐使用 `freezed`；其他模型，如果不是“不可变”，推荐使用 `json_annotation`或者手写
- **JSON序列化**：使用 `json_serializable` 库
- **强类型校验**：所有JSON转换必须有强类型校验
```yaml
      json_serializable:
        options:
          # 启用运行时类型检查（推荐开发时开启）
          checked: true

          # 显式调用对象的 toJson() 方法（处理嵌套对象/集合时很重要）
          explicit_to_json: true

          # 禁止 JSON 中出现未定义的字段（反序列化时抛出异常）
          disallow_unrecognized_keys: true

          # 生成 fromJson 工厂方法
          create_factory: true

          # 生成 toJson 方法
          create_to_json: true
```

### 4.2 JSON 序列化类型安全和错误处理规范

#### 4.2.1 类型安全配置
```yaml
# build.yaml 配置
targets:
  $default:
    builders:
      json_serializable:
        options:
          # 启用运行时类型检查（推荐开发时开启）
          checked: true
          
          # 显式调用对象的 toJson() 方法
          explicit_to_json: true
          
          # 禁止 JSON 中出现未定义的字段（反序列化时抛出异常）
          disallow_unrecognized_keys: true
          
          # 生成 fromJson 工厂方法
          create_factory: true
          
          # 生成 toJson 方法
          create_to_json: true
          
          # 启用字段重命名支持
          field_rename: snake
          
          # 启用空安全
          include_if_null: false
```

#### 4.2.2 类型安全的模型定义
```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

@freezed
class UserModel with _$UserModel {
  const factory UserModel({
    required String id,
    required String name,
    required String email,
    
    // 使用 JsonKey 进行字段映射和验证
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'is_active', defaultValue: true) required bool isActive,
    @JsonKey(name: 'age', fromJson: _parseAge, toJson: _serializeAge) required int age,
    
    // 可空字段
    String? avatar,
    @JsonKey(name: 'last_login') DateTime? lastLogin,
    
    // 枚举类型
    @JsonKey(name: 'user_type') required UserType userType,
    
    // 嵌套对象
    required UserProfile profile,
    
    // 集合类型
    @JsonKey(name: 'permissions') required List<String> permissions,
    
    // Map 类型
    @JsonKey(name: 'metadata') required Map<String, dynamic> metadata,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
      
  // 自定义解析方法
  static int _parseAge(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
  
  static int _serializeAge(int age) => age;
}

// 枚举类型
enum UserType {
  @JsonValue('admin') admin,
  @JsonValue('user') user,
  @JsonValue('guest') guest,
}

// 嵌套对象
@freezed
class UserProfile with _$UserProfile {
  const factory UserProfile({
    required String firstName,
    required String lastName,
    String? bio,
  }) = _UserProfile;

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);
}
```

#### 4.2.3 错误处理和调试
```dart
// 安全的 JSON 解析
class SafeJsonParser {
  static T? safeParse<T>({
    required Map<String, dynamic> json,
    required T Function(Map<String, dynamic>) fromJson,
    String? context,
  }) {
    try {
      return fromJson(json);
    } on FormatException catch (e) {
      _logParseError(e, json, context, 'FormatException');
      return null;
    } on TypeError catch (e) {
      _logParseError(e, json, context, 'TypeError');
      return null;
    } on Exception catch (e) {
      _logParseError(e, json, context, 'Exception');
      return null;
    }
  }
  
  static void _logParseError(
    dynamic error,
    Map<String, dynamic> json,
    String? context,
    String errorType,
  ) {
    print('''
🚨 JSON Parse Error: $errorType
📍 Context: ${context ?? 'Unknown'}
📄 JSON Data: ${_formatJson(json)}
❌ Error: $error
🔍 Stack Trace: ${StackTrace.current}
''');
  }
  
  static String _formatJson(Map<String, dynamic> json) {
    try {
      return const JsonEncoder.withIndent('  ').convert(json);
    } catch (e) {
      return json.toString();
    }
  }
}

// 使用示例
class UserService {
  Future<UserModel?> parseUserFromJson(Map<String, dynamic> json) async {
    return SafeJsonParser.safeParse(
      json: json,
      fromJson: UserModel.fromJson,
      context: 'UserService.parseUserFromJson',
    );
  }
}
```

## 5. 异常处理规范
### 5.1 异常处理架构
1. **WSError**
   - 用于网络请求异常
   - 对网络请求的异常进行分类
2. **Result**
   - 用于网络请求结果包装
   - 包含 WSError 或 Exception
3. **自定义异常**
   - AppException 作为基础异常类
   - 所有自定义 Exception 必须继承自 AppException

### 5.2 自定义异常
```dart
// 基础异常类
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  
  const AppException(this.message, {this.code, this.originalError});
  
  @override
  String toString() => 'AppException: ${code ?? 'NO_CODE'} - $message';
}

// 业务异常
class BusinessException extends AppException {
  final String businessCode;
  
  const BusinessException(
    String message, {
    required this.businessCode,
    super.originalError,
  }) : super(message, code: businessCode);
  
  @override
  String toString() => 'BusinessException: $businessCode - $message';
}

// 验证异常
class ValidationException extends AppException {
  final Map<String, String> fieldErrors;
  
  const ValidationException(
    String message, {
    required this.fieldErrors,
    super.originalError,
  }) : super(message, code: 'VALIDATION_ERROR');
  
  @override
  String toString() => 'ValidationException: $message\nField errors: $fieldErrors';
}
```

### 5.3 何时应该 throw Exception
```dart
class UserService {
  // ✅ 正确：明确的错误情况
  Future<User> getUser(String userId) async {
    if (userId.isEmpty) {
      throw ValidationException(
        'User ID cannot be empty',
        fieldErrors: {'userId': 'User ID is required'},
      );
    }
    
    try {
      final response = await _apiClient.get('/users/$userId');
      return User.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw BusinessException(
          'User not found',
          businessCode: 'USER_NOT_FOUND',
          originalError: e,
        );
      }
      throw NetworkException(
        'Failed to fetch user',
        statusCode: e.response?.statusCode,
        endpoint: '/users/$userId',
        originalError: e,
      );
    }
  }
  
  // ❌ 错误：不应该随意 throw Exception
  Future<void> updateUser(User user) async {
    // 不要这样做：随意抛出异常
    if (user.name.length < 2) {
      throw Exception('Name too short'); // 不明确的异常类型
    }
    
    // 应该这样做：使用明确的异常类型
    if (user.name.length < 2) {
      throw ValidationException(
        'Name must be at least 2 characters long',
        fieldErrors: {'name': 'Name too short'},
      );
    }
  }
}
```

#### 5.3.1 异常使用规范总结

##### ✅ 应该 throw Exception 的情况
- **明确的错误条件**：如参数验证失败、业务规则违反
- **外部服务错误**：如网络请求失败、API 返回错误
- **资源不可用**：如文件不存在、权限不足
- **状态不一致**：如对象状态不符合预期

##### ❌ 不应该 throw Exception 的情况
- **正常的业务流程**：如用户取消操作、数据为空
- **可恢复的错误**：如网络重试、临时服务不可用
- **用户输入错误**：应该通过验证提示而不是异常
- **性能问题**：如加载时间过长、内存使用过高

##### 🎯 最佳实践
- **提供有意义的错误信息**：包含错误代码、字段错误等详细信息
- **记录异常日志**：包含上下文信息便于调试
- **用户友好的错误提示**：将技术异常转换为用户可理解的提示

## 6. 代码质量规范

### 6.1 代码风格
- 遵循 Dart 官方代码规范
- 遵循 Flutter lint 规则
- 使用 `dart format` 工具格式化代码
- 使用 `dart analyze` 进行静态分析

### 6.2 注释规范
- **公共API**：必须添加文档注释
- **复杂逻辑**：添加必要的行内注释
- **TODO注释**：标记待完成的功能

### 6.3 测试规范
- **单元测试**：核心业务逻辑必须有单元测试
- **Widget测试**：重要UI组件要有Widget测试
- **集成测试**：关键用户流程要有集成测试

## 7. 性能优化规范

### 7.1 Widget优化
- 合理使用 `const` 构造函数
- 避免在 `build` 方法中创建新对象
- 使用 `ListView.builder` 处理长列表

### 7.2 状态管理优化
- 避免不必要的状态更新
- 及时释放资源，避免内存泄漏

## 8. 安全规范

### 8.1 数据安全
- 敏感信息不硬编码在代码中
- 使用环境变量或配置文件管理敏感配置
- 网络请求使用HTTPS

### 8.2 输入验证
- 所有用户输入都要进行验证
- 防止SQL注入、XSS等安全漏洞
- 文件上传要验证文件类型和大小

## 9. 版本控制规范

### 9.1 提交信息
- 使用清晰的提交信息格式
- 每个提交只做一件事
- 提交前进行代码审查

### 9.2 分支管理
- 主分支保持稳定
- 功能开发使用功能分支
- 及时合并和清理分支

## 10. 部署规范

### 10.1 构建配置
- 区分开发、测试、生产环境
- 使用不同的配置文件
- 构建产物要进行签名

### 10.2 发布流程
- 自动化构建和测试
- 版本号管理规范
- 发布前进行充分测试

---

## 总结

本规范基于Flutter开发的最佳实践和团队经验制定，旨在提高代码质量、开发效率和团队协作。所有团队成员都应该遵循这些规范，并在实践中不断完善和优化。

如有疑问或建议，请及时与团队讨论并更新本规范文档。
