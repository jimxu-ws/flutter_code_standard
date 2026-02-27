# Flutter Coding Standard

---

# **1. 类，函数与变量**

## **1.1 命名**

- **必须**：命名要self explain，私有函数或变量用_开头以保证私有。
- **自定义Widget**：必须有 `Widget` 后缀
    - ✅ `CustomButtonWidget`
    - ❌ `CustomButton`
- **生成Widget的函数**：需要有 `build` 前缀
    - ✅ `Widget buildCustomButton()`
    - ❌ `Widget customButton()`
- 布尔参数使用 `is`、`has`、`should` 前缀
- 回调函数使用 `on` 前缀
- 私有变量使用 `_` 前缀// 布尔参数

```dart
bool isLoading = false;
bool hasError = false;
bool shouldRefresh = true;

// 回调函数
final VoidCallback onPressed;
final ValueChanged<String> onChanged;

// 私有变量
final _controller = TextEditingController();
```

- 接口文件以`i`开头，e.g. `i_app_tracker.dart`；类似得，接口定义`I`开头，如：`*IAppTracker*`
- **Freezed 模型**: 必须使用 `.f.dart` 后缀
    - 生成文件: `.f.freezed.dart` 和 `.f.g.dart`
    - **一个文件一个模型**: 每个 `.f.dart` 文件只包含一个 freezed 模型
    - **文件名与模型名一致**: 文件名必须与模型类名相同（snake_case vs PascalCase）
    - **枚举单独存放**: 枚举类型应该放在独立的 `.dart` 文件中，可以被多个模型共享
    - ✅ 正确: `role.f.dart` 包含 `class Role`
    - ✅ 正确: `calendar_params.f.dart` 包含 `class CalendarParams`
    - ✅ 正确: `task_status.dart` 包含 `enum TaskStatus`
    - ❌ 错误: `models.f.dart` 包含多个模型
    - ❌ 错误: `user_data.f.dart` 包含 `class UserProfile`
    - ❌ 错误: `task.f.dart` 同时包含 `class Task` 和 `class CreateTaskRequest`
- **Riverpod Providers**: 必须使用 `.r.dart` 后缀
    - 生成文件: `.r.g.dart`
    - **一个文件一个 Provider**: 每个 `.r.dart` 文件只包含一个 provider
    - **文件名与 Provider 名一致**: 文件名必须与 provider 名称相同（snake_case vs camelCase）
    - ✅ 正确: `roles.r.dart` 包含 `rolesProvider`
    - ✅ 正确: `manager_shifts.r.dart` 包含 `managerShiftsProvider`
    - ❌ 错误: `providers.r.dart` 包含多个 providers
    - ❌ 错误: `user_data.r.dart` 包含 `profileProvider`

# **2. UI开发规范**

## 2.1 页面常规要素

### **1. SafeArea 使用**

- **必须**：所有页面都要添加 SafeArea，避免不同机型（刘海屏、挖孔屏等）的布局差异导致的bug。可以通过继承基类实现
- **示例**：

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// BaseScreen 是所有页面的基类/// 提供 Scaffold、状态栏控制，并通过抽象方法获取 pageUnitabstract class BaseScreen extends HookConsumerWidget {
  const BaseScreen({super.key});

/// 子类必须实现，返回页面标识，可以做一些页面的统计String get pageUnit;

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

// statusBarColor 默认透明，不需要覆盖@override
  Brightness get statusBarBrightness => Theme.light;

  @override
  Widget buildBody(BuildContext context, WidgetRef ref) {
    return Center(
      child: Text('Home Page'),
    );
  }
}

```

### **2. 页面埋点**

- **必须**：所有页面通过继承基类实现默认的埋点逻辑

## **2.2 组件设计原则**

### **单一职责原则**

每个组件应该只负责一个功能，避免混合展示逻辑和业务逻辑：

```dart
// ❌ 错误：混合了业务逻辑
class UserProfileWidget extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 不应该在 Widget 中直接调用 API
    final user = useState<User?>(null);

    useEffect(() {
      ApiClient().getUser().then((data) => user.value = data);
      return null;
    }, []);

    return Text(user.value?.name ?? '');
  }
}

// ✅ 正确：通过 Provider 分离业务逻辑
class UserProfileWidget extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);

    return userAsync.when(
      data: (user) => Text(user.name),
      loading: () => CircularProgressIndicator(),
      error: (error, _) => Text('Error: $error'),
    );
  }
}

```

### **分离构建逻辑**

同时注意开闭原则，方法函数该私有则应私有

```dart
class ComplexWidget extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. 获取依赖和状态
    final theme = Theme.of(context);
    final dataAsync = ref.watch(dataProvider);

    // 2. 处理 Hooks
    final selectedIndex = useState(0);
    final animation = useAnimationController(
      duration: const Duration(milliseconds: 300),
    );

    // 3. 构建 UI
    return dataAsync.when(
      data: (data) => _buildContent(
        context: context,
        data: data,
        selectedIndex: selectedIndex.value,
        animation: animation,
      ),
      loading: () => _buildLoading(),
      error: (error, _) => _buildError(error),
    );
  }

  // 分离的构建方法
  Widget _buildContent({
    required BuildContext context,
    required DataModel data,
    required int selectedIndex,
    required AnimationController animation,
  }) {
    return Column(
      children: [
        _buildHeader(data.title),
        _buildBody(data.items, selectedIndex),
        _buildFooter(animation),
      ],
    );
  }

  Widget _buildHeader(String title) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Text(title, style: const TextStyle(fontSize: 20)),
    );
  }

  Widget _buildBody(List<Item> items, int selectedIndex) {
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) => _buildItem(
        item: items[index],
        isSelected: index == selectedIndex,
      ),
    );
  }

  Widget _buildItem({required Item item, required bool isSelected}) {
    return ListTile(
      title: Text(item.name),
      selected: isSelected,
    );
  }

  Widget _buildFooter(AnimationController animation) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) => Container(
        height: 50 * animation.value,
        color: Colors.blue,
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildError(Object error) {
    return Center(child: Text('Error: $error'));
  }
}

```

### **响应式布局**

**使用 LayoutBuilder 适配不同屏幕**

```dart
class ResponsiveWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 1200) {
          return _buildDesktopLayout();
        } else if (constraints.maxWidth > 600) {
          return _buildTabletLayout();
        } else {
          return _buildMobileLayout();
        }
      },
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        Expanded(flex: 1, child: _buildSidebar()),
        Expanded(flex: 3, child: _buildMainContent()),
      ],
    );
  }

  Widget _buildTabletLayout() {
    return Column(
      children: [
        _buildCompactHeader(),
        Expanded(child: _buildMainContent()),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return _buildMainContent();
  }

  Widget _buildSidebar() => Container();
  Widget _buildMainContent() => Container();
  Widget _buildCompactHeader() => Container();
}

```

## 2.3 页面纵向架构(MVVM)

![image.png](Flutter%20Coding%20Standard/image.png)

1. Provider only works for UI/Screen
2. If the ViewModel is complex, and need some arrangement from Services’ response, please add Repository to arrange the ViewModel for Provider
3. UI/Screen will trigger the CRUD of database or file via Repository or Provider’s side effect functions
4. Please sort out the dependencies of Provider before implementation

# **3. 项目结构组织**

## **3.1 功能化组织**

按业务功能子模块组织代码。package之间避免循环依赖。代码放置位置合理，保证内聚。

## **3.2 文件夹组织**

Package内按功能模块组织代码，推荐以下结构：

```
lib/xxx modules
├── screens/          # 页面级组件
├── widgets/          # 可复用组件
├── hooks/            # 自定义hooks
├── repositories/       # repository,做端上数据编排加工或业务逻辑，持久化缓存，最终生成im
|                       mutable 
|                       
|                     # ViewModel供provider进行状态管理并给ui呈现。但如果services层直接
|                     # 可给出viewModel，则可选
├── services/         # 业务服务层
├── providers/        # 状态管理
├── models/           # 数据模型
├── utils/            # 工具函数
└── constants/        # 常量定义

```

## 3.3 各层级关系

[参考MVVM](https://www.notion.so/Flutter-Coding-Standard-262a1747bfd180baae2acf669822953a?pvs=21)

# **4. 状态管理规范**

## **4.1 状态管理原则**

### 何时使用Provider

凡是需要状态的地方，才能选择使用Provider进行状态管理，但还需视是否复杂而选择hooks方案。

- **跨页面状态**：使用 Provider
- **单页面内状态**：优先使用 Hooks，复杂情形也可以使用Provider
- **注意事项**：这两种方案都`必须是和UI状态有关的`，禁止使用其他状态管理方案；
    - 避免没有管理状态的Provider或者Hooks；
    - Provider只应该有build及side effect函数，不应该含有其他逻辑。
    - 选择性的状态管理优先使用FamilyProvider：即带参数的Provider

### **Provider设计原则**

- **职责单一**：Provider 应该只包含：
    - `state`：状态数据
    - `side effects`：副作用操作（如API调用、本地存储等）
    - 其他函数如果和state无关，应该封装为私有函数! 或者通过外部hook封装
        - 避免包含UI构建逻辑，某些状态的getter等，状态的getter可以通过hooks来实现
- **开闭原则**：函数该私有则应私有
- **目的明确**：所有Provider仅用于UI的ViewModel状态管理。如无必要，切勿使用Provider。
    - 不要用于响应式场景
    - 非响应式场景更不能用Provider
- **生命周期**：如无必要，不要keepAlive
- **Mock友好**：设计时要考虑如何mock这个状态，便于后期测试
- **依赖清晰**：在实现之前梳理好各个Provider以及UI之间的依赖关系，避免依赖混乱，如`循环依赖`，引起难以发现的问题；此处，有如下经验：
    - UI如无必要使用provider的响应式更新，则不应使用Provider
    - 慎用watch和listen，使用时思考是否可能导致循环依赖

### 为什么要求Provider的成员函数必须是side effect函数

在 Riverpod 生态中，有一个官方推荐的 linter 包：`riverpod_lint`。

它包含一条规则（默认开启）：

> notifier_method_must_be_side_effect
> 
> 
> *"Methods in a Notifier/AsyncNotifier should only be used to trigger side-effects. Pure methods should be private or moved elsewhere."*
> 

### 它的逻辑是：

- `Notifier` / `AsyncNotifier` 的主要职责是 **管理状态 + 处理副作用**（如加载数据、修改 state、调用 API）。
- 如果你在 `Notifier` 中定义了一个 **纯计算函数**（如 `String get fullName => '$firstName $lastName'`），它：
    - 不改变状态
    - 不触发外部行为
    - 只是基于当前状态做计算
- 那么这个函数**不属于“状态变更逻辑”**，放在 `Notifier` 中会模糊其职责。
- 如果其不是side effect函数，开发者误以为调用某个 public 方法会触发刷新（实际不会）

因此，lint 建议：

- 要么将其设为 **`private`**（如 `_getFullName()`）
- 要么将其移到 **UI 层** 或 **独立的工具类/扩展中**

总结一下，所有public函数是side effect函数的优点：

| 优点 | 说明 |
| --- | --- |
| **1. 职责单一（Single Responsibility）** | `Notifier` 只负责“状态变更”和“副作用”，计算逻辑外移，结构更清晰 |
| **2. 提升可测试性** | 纯函数可独立测试；Notifier 测试聚焦于状态流转 |
| **3. 避免误用** | 防止开发者误以为调用某个 public 方法会触发刷新（实际不会） |
| **4. 与 `ref.watch` 语义一致** | UI 应通过 `watch(provider)` 获取状态，再自行计算派生值 |

### ❌ 在 if 里面写 watch 是不合理的！

**这是一个严重的错误，违反了 Riverpod 的核心规则。**

**问题分析**

```dart
// ❌ 错误示例 - 你截图中的代码
if (isIdentityV2Enable) {
final currentRoleAndLocationsResult = ref.watch(
wsIdentityMeDataProvider.select(...)
);
}
```

**为什么不合理？**

1. 违反 Riverpod 规则 ⚠️
    - ref.watch() 必须在 build() 方法的顶层调用
    - 不能在条件语句、循环、回调函数中使用
2. 不一致的依赖追踪 💥
// 第一次构建：isIdentityV2Enable = true
// -> 创建了对 wsIdentityMeDataProvider 的监听

      // 第二次构建：isIdentityV2Enable = false

      // -> 没有创建监听
      // -> Riverpod 无法正确管理这种动态依赖！

1. 可能导致内存泄漏 🐛
    - 条件性的 watch 可能不会被正确清理
    - 监听关系混乱
2. 运行时可能报错 💣
Error: Bad state: Cannot add new listeners after calling `dispose`

## **4.2 状态管理选择示例**

### **✅ 正确：跨页面状态使用 Provider**

```dart
// 用户信息 - 跨页面共享状态final userProvider = StateNotifierProvider<UserNotifier, User?>((ref) {
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

// 在登录页面使用class LoginPage extends ConsumerWidget {
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

// 在首页使用class HomePage extends ConsumerWidget {
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

### **✅ 正确：单页面内状态使用 Hooks**

```dart
// 表单输入状态 - 仅在当前页面使用class LoginForm extends HookWidget {
  @override
  Widget build(BuildContext context) {
// 使用 Hooks 管理表单状态final emailController = useTextEditingController();
    final passwordController = useTextEditingController();
    final isPasswordVisible = useState(false);
    final isLoading = useState(false);

// 表单验证状态final emailError = useState<String?>(null);
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
// 实时验证if (value.isEmpty) {
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
// 模拟登录await Future.delayed(Duration(seconds: 2));
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

### **✅ 正确：选择性状态使用Family Provider**

**Family Provider 标准形式**

```dart
typedef RolesParams = ({
  String locationId,
  String? search,
});

@riverpod
class Roles extends _$Roles {
  @override
  Future<List<Role>> build(RolesParams arg) async {
    ref.cacheFor(const Duration(minutes: 2));
    return _fetchRoles(arg.locationId, arg.search);
  }
}

```

### **❌ 错误：不恰当的状态管理使用**

**错误示例1：没有管理状态的 Provider**

```dart
// ❌ 错误：Provider 没有管理状态，只是返回静态数据final staticDataProvider = Provider<String>((ref) {
  return 'This is static data';// 没有状态变化
});

// ❌ 错误：Provider 没有状态管理，只是工具函数final utilityProvider = Provider<UtilityService>((ref) {
  return UtilityService();// 没有状态，只是服务实例
});

```

**错误示例2：没有管理状态的 Hooks**

```dart
class MyWidget extends HookWidget {
  @override
  Widget build(BuildContext context) {
// ❌ 错误：useState 没有实际使用状态变化final unusedState = useState(0);

// ❌ 错误：useEffect 没有依赖，总是执行
    useEffect(() {
      print('This will always run');
    }, []);// 空依赖数组

    return Text('Hello World');
  }
}

```

## **4.3. 状态管理选择决策树**

```
需要状态管理？
├─ 是
│  ├─ 状态需要在多个页面间共享？
│  │  ├─ 是 → 使用 Provider ✅
│  │  └─ 否 → 使用 Hooks/ChangeNotifier ✅
│  └─ 状态复杂程度？
│     ├─ 简单（表单输入、UI 状态）→ 使用 Hooks ✅
│     └─ 复杂（业务逻辑、数据流）→ 使用 Provider ✅
|                                    |
|                                    └─是否是选择性状态管理→ 使用 Familiy Provider ✅
└─ 否
   └─ 不需要状态管理，使用普通 Widget ❌

```

## **4.4 Hooks 使用规范**

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
// 副作用逻辑return () {
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

### **Flutter Hooks 使用陷阱和注意事项**

**🚨 陷阱一：Hooks 调用顺序问题**

```dart
class BadHooksWidget extends HookWidget {
  @override
  Widget build(BuildContext context) {
// ❌ 错误：条件性调用 Hooksif (someCondition) {
      final counter = useState(0);// 这会导致 Hooks 顺序不一致
    }

    final isLoading = useState(false);

// ❌ 错误：在循环中调用 Hooksfor (int i = 0; i < 3; i++) {
      final state = useState(i);// 这会导致 Hooks 顺序不一致
    }

    return Container();
  }
}

// ✅ 正确：Hooks 调用顺序一致class GoodHooksWidget extends HookWidget {
  @override
  Widget build(BuildContext context) {
// 所有 Hooks 都在顶层调用，顺序一致final counter = useState(0);
    final isLoading = useState(false);
    final items = useState<List<int>>([]);

// 条件逻辑在 Hooks 调用之后if (someCondition) {
// 使用已定义的 Hooks
      counter.value = 10;
    }

    return Container();
  }
}

```

**🚨 陷阱二：useEffect 依赖数组问题**

```dart
class BadEffectWidget extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final counter = useState(0);
    final user = useState<User?>(null);

// ❌ 错误：空依赖数组，但使用了外部变量
    useEffect(() {
      fetchUser(counter.value);// 使用了 counter.value 但没有在依赖数组中
    }, []);// 空依赖数组

// ✅ 正确：明确的依赖数组
    useEffect(() {
      if (counter.value > 0) {
        fetchUser(counter.value);
      }
    }, [counter.value]);// 明确依赖 counter.valuereturn Container();
  }
}

```

**🚨 陷阱三：useState 初始化和更新问题**

```dart
class BadStateWidget extends HookWidget {
  @override
  Widget build(BuildContext context) {
// ❌ 错误：在 build 方法中直接调用函数初始化final expensiveData = useState(expensiveCalculation());// 每次 build 都会执行

// ❌ 错误：在 useState 中创建新对象final user = useState(User(name: 'John', age: 25));// 每次 build 都创建新对象

// ✅ 正确：使用 useMemoized 延迟初始化final expensiveData = useMemoized(() => expensiveCalculation(), []);

// ✅ 正确：使用 useMemoized 避免重复创建对象final user = useMemoized(() => User(name: 'John', age: 25), []);

// ✅ 正确：使用 useState 的懒初始化final expensiveData = useState<ExpensiveData?>(null);
    useEffect(() {
      expensiveData.value = expensiveCalculation();
    }, []);

    return Container();
  }
}

```

**🚨 陷阱四：资源清理和内存泄漏**

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
        controller.dispose();// 清理控制器
      };
    }, []);

    return Container();
  }
}

```

**🚨 陷阱五：异步操作中的状态更新**

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
        data.value = 'Fetched data';// 组件可能已经销毁
      } finally {
        isLoading.value = false;// 组件可能已经销毁
      }
    }

// ✅ 正确：使用 mounted 检查
    Future<void> fetchData() async {
      isLoading.value = true;
      try {
        await Future.delayed(Duration(seconds: 2));

// 检查组件是否还在树中if (mounted) {
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

### **Hooks 最佳实践总结**

**✅ 必须遵循的规则**

1. **Hooks 调用顺序一致**：不要在条件语句、循环或嵌套函数中调用 Hooks
2. **Hooks 只在顶层调用**：确保 Hooks 在每次 render 时都以相同的顺序被调用
3. **正确的依赖数组**：useEffect 的依赖数组要包含所有使用的外部变量
4. **Keys是immutable的性能最佳**：useMemoized uses **value equality** (identical()) to compare keys, not **reference** equality。Provider也是一样的。
    
    **For Riverpod family parameters:**
    
    - ✅ **Container must be immutable** (const, List.unmodifiable, Map.unmodifiable)
    - ✅ **Contents should be immutable** for safety
    - ✅ **Use Freezed classes** for complex parameters
    - ✅ **Use primitive types** when possible
    - ✅ **Use records** for multiple simple parameters, **Records are immutable in Dart!** This is one of their key features and makes them excellent for use as Riverpod family provider parameters
    - **即使 List 里全是 immutable 对象，`list1 == list2` 默认仍然是 `false`（引用比较），除非你使用 `listEquals` 或 `DeepCollectionEquality`。**
    
    **The key principle:** If you can modify the collection or its contents after creating the parameter, Riverpod won't detect those changes, leading to stale cache entries.
    
5. **资源清理**：useEffect 要返回清理函数，避免内存泄漏
6. **状态更新检查**：异步操作中更新状态前检查组件是否还在树中

**🔧 性能优化技巧**

```dart
class OptimizedHooksWidget extends HookWidget {
  @override
  Widget build(BuildContext context) {
// 使用 useMemoized 避免重复计算final expensiveValue = useMemoized(() {
      return expensiveCalculation();
    }, []);

// 使用 useCallback 避免函数重新创建final onPressed = useCallback(() {
// 处理逻辑
    }, []);

// 使用 useValueChanged 监听值变化
    useValueChanged(counter.value, (oldValue, newValue) {
      print('Counter changed from $oldValue to $newValue');
    });

    return Container();
  }
}

// ❌ Problematic - list changes but reference stays the same
final mutableList = <int>[1, 2, 3];
useMemoized(() => compute(), [mutableList]);

// Later...
mutableList.add(4); // useMemoized won't detect this change!

// ✅ Better - use immutable lists
final immutableList = const <int>[1, 2, 3];
useMemoized(() => compute(), [immutableList]);
```

**🚫 常见错误模式**

- **条件性 Hooks 调用**：在 if 语句中调用 Hooks
- **循环中调用 Hooks**：在 for 循环中调用 Hooks
- **空依赖数组误用**：useEffect 使用了外部变量但依赖数组为空
- **对象依赖问题**：依赖数组中包含对象引用
- **资源未清理**：useEffect 没有返回清理函数
- **异步状态更新**：在已销毁的组件上更新状态

## **4.5 异步状态管理规范**

- **避免重复调用**：确保异步操作不会被重复触发
- **状态重置**：在开始新的异步操作前，先重置状态
- **错误处理**：正确处理异步操作的错误状态
- **生命周期管理**：在组件销毁时取消未完成的异步操作

### **FutureProvider 使用规范**

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

#### 3.3.2 AsyncNotifier 使用规范
```dart
class UserNotifier extends AsyncNotifier<User> {
  @override
  Future<User> build() async {
// 初始化时加载数据return await _fetchUser();
  }

  Future<void> refreshUser() async {
// ✅ 正确：先设置状态为加载中
    state = const AsyncValue.loading();

    try {
// 获取新数据final user = await _fetchUser();
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
// 更新成功后刷新数据await refreshUser();
    } catch (error, stackTrace) {
// 恢复原状态
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

```

### **避免 "Future already completed" 错误的规范**

**方案一：使用 CancelToken 模式**

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
      if (error is CancelException) return;// 忽略取消异常if (!mounted) return;
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<User> _fetchUserWithCancelToken(CancelToken token) async {
// 模拟带取消令牌的API调用await Future.delayed(Duration(seconds: 2));
    token.throwIfCancelled();
    return User(id: '1', name: 'John');
  }
}

```

**方案二：使用 Riverpod 内置的 ref.onDispose**

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

### 如何获取AsyncProvider的Value

- **✅ 正确做法**：

```dart
final value = ref.read(myAsyncProvider).valueOrNull;
或者先通过hasValue判断后，通过value获取：
final asyncValue = ref.read(myAsyncProvider);
if(asyncValue.hasValue){
	final asyncValue = asyncValue.value;
}
```

- **❌ 错误做法**：直接取value值可能会抛异常。

可参考开发文档，value在state有error的情况下会抛异常；同时注意value可能是之前缓存的值

```dart
final asyncValue = ref.read(myAsyncProvider).value;
```

## **4.6 WidgetRef，Ref使用规范**

### **WidgetRef 传递注意事项**

- **✅ 正确做法**：在 Widget 的 build 方法中直接使用 ref 参数
- **❌ 错误做法**：将 ref 通过参数传递给其他方法或存储为某个类的实例变量
- **生命周期**：ref 只在 build 方法执行期间有效

**正确的使用方式**

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

**错误的使用方式**

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

### **遇到Ref在函数中使用，应该怎么办？**

基于对Ref的extension 或 hook来实现，例如

```dart
extension WidgetRefQueryExtensions on WidgetRef {
  /// Create a smart cached data fetcher with stale-while-revalidate strategy (for hooks)
  SmartCachedFetcher<T> cachedFetcher<T>({
    required Future<T> Function() fetchFn,
    required void Function(T data) onData,
    required void Function() onLoading,
    required void Function(Object error) onError,
    String? cacheKey,
    Duration staleTime = const Duration(minutes: 5),
    Duration cacheTime = const Duration(minutes: 30),
    bool enableBackgroundRefresh = true,
    bool enableWindowFocusRefresh = true,
    bool cacheErrors = false,
  }) {
    return SmartCachedFetcher<T>(
      ref: this,
      fetchFn: fetchFn,
      onData: onData,
      onLoading: onLoading,
      onError: onError,
      cacheKey: cacheKey ?? 'smart-cache-${fetchFn.hashCode}',
      staleTime: staleTime,
      cacheTime: cacheTime,
      enableBackgroundRefresh: enableBackgroundRefresh,
      enableWindowFocusRefresh: enableWindowFocusRefresh,
      cacheErrors: cacheErrors,
    );
  }
  
```

### **Notifier 中正确使用 Ref**

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

### AsyncNotifier**异步操作中的 Ref 使用**

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

### **常见陷阱和解决方案**

```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder(
      future: _someAsyncOperation(ref),// ❌ 错误：传递 ref 给异步操作
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
      future: _someAsyncOperation(),// ✅ 不传递 ref
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

**最佳实践总结**

- **ref 只在 build 方法中有效**：不要存储或传递 ref
- **异步操作前获取依赖**：使用 `ref.read` 在异步操作开始前获取所需数据
- **检查组件状态**：在异步操作完成后使用 `mounted` 检查组件状态
- **避免闭包陷阱**：不要在异步回调中直接使用 ref
- **使用 Provider 依赖**：通过 Provider 的依赖关系而不是直接传递 ref

### **重要概念澄清：为什么 Notifier 中可以使用 ref？**

**关键区别**：

1. **Widget 中的 ref**：通过 `build` 方法参数传入，只在 build 执行期间有效
2. **Notifier 中的 ref**：Notifier 类本身持有 ref 的引用，在整个生命周期内都有效

**具体说明**：

```dart
// Widget 中的 ref - 通过参数传入，生命周期受限class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
// ref 只在 build 方法执行期间有效return ElevatedButton(
      onPressed: () {
// ✅ 可以在这里使用 ref，因为这是同步的回调
        ref.read(userProvider.notifier).refreshUser();
      },
      child: Text('Refresh'),
    );
  }
}

// Notifier 中的 ref - 类本身持有，生命周期与 Notifier 一致class UserNotifier extends AsyncNotifier<User> {
// Notifier 类持有 ref 的引用// 这个 ref 在 Notifier 的整个生命周期内都有效

  @override
  Future<User> build() async {
// ✅ 可以使用 return await ref.read(apiServiceProvider).fetchUser();
  }

  Future<void> refreshUser() async {
// ✅ 可以使用 ref，因为 Notifier 本身持有 ref 引用final apiService = ref.read(apiServiceProvider);

// 异步操作...final user = await apiService.fetchUser();

// 更新状态
    state = AsyncValue.data(user);
  }
}

```

**总结**：

- **Widget 中**：ref 是临时参数，不要存储或传递给其他方法
- **Notifier 中**：ref 是类的成员，可以在任何方法中使用
- **异步方法**：在 Notifier 的异步方法中使用 ref 是安全的，因为 ref 的生命周期与 Notifier 一致

## **4.7 BuildContext 使用规范**

### **Context 传递注意事项**

- **✅ 正确做法**：在 Widget 的 build 方法中直接使用 context 参数
- **❌ 错误做法**：将 context 传递给其他方法或存储为实例变量
- **生命周期**：context 只在 build 方法执行期间有效
- **作用域**：context 包含当前 Widget 在树中的位置信息

### **正确的使用方式**

```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
// ✅ 正确：在 build 方法中直接使用 contextreturn Scaffold(
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

### **错误的使用方式**

```dart
class MyWidget extends StatefulWidget {
  @override
  _MyWidgetState createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
// ❌ 错误：不要将 context 存储为实例变量late BuildContext _context;

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

### **在异步操作中正确使用 Context**

```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
// ✅ 正确：在异步操作开始前获取 contextfinal navigator = Navigator.of(context);
        final theme = Theme.of(context);

// 异步操作await Future.delayed(Duration(seconds: 2));

// ✅ 正确：使用之前获取的引用，而不是直接使用 context
        navigator.pushNamed('/result');

// ✅ 正确：使用之前获取的引用final color = theme.primaryColor;
      },
      child: Text('Async Operation'),
    );
  }
}

```

### **Context 在 Notifier 中的使用**

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

// 使用方式class MyWidget extends ConsumerWidget {
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

### **常见陷阱和解决方案**

```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _someAsyncOperation(context),// ❌ 错误：传递 context 给异步操作
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

// ✅ 正确：使用 context 在同步代码中获取数据class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _someAsyncOperation(),// ✅ 不传递 context
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

### **Context 的最佳实践**

```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
// ✅ 正确：在 build 方法开始时就获取常用的引用final navigator = Navigator.of(context);
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

### **BuildContext 最佳实践总结**

- **context 只在 build 方法中有效**：不要存储或传递 context
- **异步操作前获取引用**：使用 `Navigator.of(context)` 等在异步操作开始前获取引用
- **避免在异步回调中使用 context**：context 在异步操作完成后可能无效
- **通过参数传递 context**：在 Notifier 中需要 context 时，通过方法参数传入
- **获取常用引用**：在 build 方法开始时就获取常用的引用，避免重复调用
- **检查 context 有效性**：在异步操作中使用 context 前检查其有效性

## **4.8 不要在 `build` 方法中直接调用 watch的provider的side-effect**

### ❌ 错误示例：

```dart
Widget build(BuildContext context, WidgetRef ref) {
  // 危险！每次 rebuild 都会调用
  ref.read(apiProvider).fetchData(); // ❌ 不要这样做！

  final data = ref.watch(dataProvider);
  return Text(data.toString());
}
```

```dart
    final isIdentityV2Enable = WSIdentityV2UpdateManager().isIdentityV2Enable();
    if (isIdentityV2Enable) {
      final currentRoleAndLocationsResult = ref.watch(
        wsIdentityMeDataProvider.select(
          (data) => data?.company?.roleAndLocation,
        ),
      );**//**❌ **NOTES: should not call watch inside branch condition**
      var currentRoleAndLocations = currentRoleAndLocationsResult?.data;
      if (currentRoleAndLocationsResult?.errorCode != 0 &&
          (currentRoleAndLocations == null ||
              currentRoleAndLocations.isEmpty)) {
        final newIdentity = await ref
            .read(wsIdentityProvider.notifier)
            .refreshAndSaveData(IdentityDataType.roleAndLocations);
        currentRoleAndLocations = newIdentity?.company?.roleAndLocation?.data;
      }
```

### 为什么不行？

- 这里不仅仅指UI Widget的`build`函数
- `build` 方法应是 **纯函数**：只负责 UI 构建，不应产生副作用。
- `build` 可能被频繁调用（父 widget rebuild、布局变化等），导致：
    - 多次网络请求
    - 重复埋点上报
    - 内存泄漏或竞态条件
    - 如果调用了被watch的provider，会导致死循环
- 非Async Provider的build内不能直接修改state

## 4.9 ⚠️ 特别注意：避免在副作用中异步使用过期的 `ref`

如果你在 `useEffect` 中启动异步操作，确保使用最新的 `ref`（通常没问题，因为闭包捕获的是当前 `ref`）。但如果操作耗时很长，建议检查 `mounted`（HookWidget 用 `useIsMounted`）：

```dart
final isMounted = useIsMounted();

useEffect(() {
  ref.read(apiProvider).fetchData().then((result) {
    if (isMounted()) {
      // 安全更新状态
      ref.read(someStateProvider.notifier).update(result);
    }
  });
  return null;
}, const []);
```

## 4.10 其他注意事项

### **关于 `await ref.read(xxxProvider.future)` 的安全性问题**

**⚠️ 潜在的安全问题**

```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () async {
        // ⚠️ 潜在问题：ref.read(xxxProvider.future) 可能不安全，不过这里做了异常处理，至
        // 少不会白屏
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

**🚨 主要风险**

1. 可能抛异常，没有做好处理
2. **~~组件生命周期**：Widget 可能在 await 期间被销毁~~
3. **~~状态不一致**：获取的数据可能与当前 Provider 状态不一致~~
4. **~~内存泄漏**：可能导致不必要的内存占用~~

**✅ 安全的替代方案**

**方案一：使用Watch监听变化并通过**AsyncValue.when解析数据或处理异常

```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
// ✅ 正确：使用watch和AsyncValue.when解析数据，处理异常
		final userAsync = ref.watch(userProvider);

    return userAsync.when(
      data: (user) => Text('User: ${user.name}'),
      loading: () => CircularProgressIndicator(),
      error: (error, stack) => Text('Error: $error'),
    );
  }
}

```

**方案二：做好异常处理**

```dart
final AsyncValue<String> asyncValue = ref.read(managerScheduleProvider(arg.locationId));

try {
  final String scheduleId = await asyncValue.future;
  // 成功处理
} on HttpException {
  // 处理网络错误
} on TimeoutException {
  // 超时
} catch (e) {
  // 其他错误
  print('加载失败: $e');
}
```

**方案三：在异步操作开始前获取数据**

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
// 使用当前数据print('Current user: ${currentUser.name}');
        }

// 触发异步操作await userNotifier.refreshUser();
      },
      child: Text('Refresh User'),
    );
  }
}

```

**🎯 最佳实践总结**

**✅ 推荐的做法**

- **使用 ref.watch**：监听 Provider 状态变化，自动重建 UI
- **在 Notifier 中处理异步逻辑**：让 Notifier 负责状态管理和异步操作
- **异步操作前获取数据**：在异步操作开始前使用 `ref.read` 获取当前数据
- **使用 mounted 检查**：在异步操作完成后检查组件状态

**❌ 不规范的做法（应避免）**

- **await ref.read(xxxProvider.future)**：❌ **不规范**，可能导致状态不一致和生命周期问题
- **在异步回调中直接使用 ref**：❌ **不规范**，ref 可能已经无效
- **存储 Provider 的 future**：❌ **不规范**，future 可能与当前 Provider 状态不匹配

**🔍 何时可以使用 ref.read(xxxProvider.future)**

- **同步代码中**：需要立即获取当前值（但要注意生命周期）
- **调试目的**：临时用于调试，生产环境应避免
- **短期同步操作**：仅在同步上下文中使用，不涉及 await

**🚨 重要提醒：为什么 `await ref.read(xxxProvider.future)` 不规范？**

1. **违反 Riverpod 设计原则**：Riverpod 设计为响应式状态管理，不是传统的异步数据获取
2. **生命周期管理混乱**：await 期间 Provider 状态可能发生变化
3. **状态不一致风险**：获取的数据可能与当前 UI 状态不匹配
4. **调试困难**：难以追踪数据来源和状态变化
5. **性能问题**：可能导致不必要的重建和内存占用

**📋 规范的替代方案对比**

| 不规范用法 | 规范替代方案 | 优势 |
| --- | --- | --- |
| `await ref.read(userProvider.future)` | `ref.watch(userProvider)` | 响应式、自动重建、生命周期安全 |
| `await ref.read(userProvider.future)` | `ref.read(userProvider.notifier).refreshUser()` | 状态管理集中、生命周期安全 |
| `await ref.read(userProvider.future)` | 在 Notifier 中处理异步逻辑 | 职责分离、状态一致性 |

### 在build函数最顶层使用watch，不要在子函数中使用watch

在 Flutter + Riverpod 中，**不建议**在 `build` 方法的**子函数（sub-function）内部调用 `ref.watch()`**。这是 Riverpod 的一个关键使用原则。

---

✅ 正确做法：**只在 build 方法顶层或 Widget 构建闭包中直接使用 `ref.watch()`**

**❌ 错误示例（不要这样做）：**

```

1class MyWidget extends ConsumerWidget {
2  @override
3  Widget build(BuildContext context, WidgetRef ref) {
4    return ElevatedButton(
5      onPressed: () {
6// ❌ 危险！在事件回调中使用 ref.watch()7        final value = ref.watch(myProvider);
8        print(value);
9      },
10      child: Text('Click me'),
11    );
12  }
13}
```

或者：

```
1class MyWidget extends ConsumerWidget {
2  void _helperFunction(WidgetRef ref) {
3    // ❌ 不要在 build 外部或子函数中调用 ref.watch()---如果100%情形下子函数能被build函
     // 数调到，可用但不推荐
4    final data = ref.watch(someProvider);// 这不会被 Riverpod 正确追踪依赖！
5  }
67  @override
8   Widget build(BuildContext context, WidgetRef ref) {
9    _helperFunction(ref);// ❌ 避免这样传递 ref 并在子函数中 watch
10    return Container();
11  }
12}
```

---

🚫 为什么不能在子函数中 `ref.watch()`？

1. **Riverpod 无法正确建立依赖关系**
    
    `ref.watch(provider)` 必须在 **构建过程中同步调用**，Riverpod 才能知道“这个 widget 依赖于该 provider”。如果在异步回调、嵌套函数、或延迟执行的代码中调用，Riverpod **不会监听变化**，也不会触发 rebuild。
    
2. **可能导致状态不一致或内存泄漏**
    
    在 `onPressed` 等回调中调用 `ref.watch()` 只会获取**当前快照值**，但不会订阅更新。更严重的是，如果误以为它会自动更新，会导致 UI 与状态不同步。
    
3. **违反响应式编程原则**
    
    响应式状态应在声明式构建中消费，而不是在命令式逻辑中“拉取”。
    

---

✅ 正确替代方案

**场景 1：你需要在按钮点击时读取最新状态**

→ 使用 `ref.read()`（只读一次，不监听）

```
Dart编辑

1ElevatedButton(
2  onPressed: () {
3    final value = ref.read(myProvider);// ✅ 安全，只读当前值4    print(value);
5  },
6  child: Text('Get current value'),
7)
```

> ✅ ref.read() 是安全的，可以在任何地方使用（回调、异步函数等），因为它不建立监听。
> 

---

**场景 2：你需要在构建时根据状态生成 UI，并在回调中使用该状态**

→ 在 `build` 中 `watch`，然后将值传入回调

```
Dart编辑

1@override
2Widget build(BuildContext context, WidgetRef ref) {
3  final user = ref.watch(userProvider);// ✅ 在 build 顶层 watch
4
5  return ElevatedButton(
6    onPressed: () {
7      // 使用已 watch 的值
8      print(user.name);
9    },
10    child: Text('Hello ${user.name}'),
11  );
12}
```

> ✅ 这样既保证了监听，又避免了在回调中错误地调用 watch。
> 

---

**场景 3：逻辑复杂，想提取辅助函数？**

→ 让辅助函数**接收状态值作为参数**，而不是接收 `ref`

```

1String _formatUserName(User user) {
2  return 'Hi, ${user.name.toUpperCase()}!';
3}
4
5@override
6Widget build(BuildContext context, WidgetRef ref) {
7  final user = ref.watch(userProvider);
8  final displayName = _formatUserName(user);// ✅ 传值，不传 ref
9  return Text(displayName);
10}
```

---

**总结**

| 位置 | 能否使用 `ref.watch()` | 推荐做法 |
| --- | --- | --- |
| `build` 方法顶层（ConsumerWidget） | ✅ 是 | 直接使用 |
| 子函数 / 辅助函数（在 build 内调用） | ❌ 否 | 改为传入已 watch 的值 |
| 事件回调（如 `onPressed`） | ❌ 否 | 使用 `ref.read()` |
| 异步函数 / Future / Timer | ❌ 否 | 使用 `ref.read()` |

> 🔑 核心原则：ref.watch() 必须在 widget 构建过程中同步、直接调用，才能被 Riverpod 正确追踪依赖。
> 

---

如果你有具体代码场景，我可以帮你重构！

## **4.11 Riverpod 在特殊场景下的使用规范**

### **Method Channel 和原生插件场景**

**🚨 问题分析**

Riverpod 在以下场景中确实存在局限性：

- **Method Channel 调用**：无法直接获取 ref
- **原生插件集成**：插件内部无法访问 Riverpod 上下文
- **模块化隔离**：跨模块的 Provider 依赖复杂
- **第三方库集成**：外部库无法感知 Riverpod 状态

### **模块化隔离下Riverpod最佳实践**

**🏗️ 分层架构设计**

```dart
// 基础设施层（不依赖 Riverpod）abstract class INativePluginService {
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

// 业务逻辑层（可选使用 Riverpod）class UserService {
  final INativePluginService _nativePlugin;

  UserService(this._nativePlugin);

  Future<User> fetchUser() async {
    final userData = await _nativePlugin.callMethod('getUser', {});
    return User.fromJson(jsonDecode(userData));
  }
}

// 表现层（使用 Riverpod）final userServiceProvider = Provider<UserService>((ref) {
  final nativePlugin = GlobalServices.instance.nativePlugin;
  return UserService(nativePlugin);
});

final userProvider = AsyncNotifierProvider<UserNotifier, User>(() {
  return UserNotifier();
});

```

### **特殊场景使用规范总结**

**✅ 推荐方案**

- **Service Locator 模式**：适合全局服务访问
- **Provider 包装器**：适合需要 Provider 生命周期的场景
- **混合架构**：根据具体需求选择合适的方案
- **分层设计**：基础设施层不依赖 Riverpod

**❌ 避免方案**

- **强制使用 Riverpod**：在不适用的场景下强制使用
- **全局 Provider**：过度使用全局状态管理
- **紧耦合**：模块间过度依赖

**🎯 选择原则**

1. **需要状态管理**：使用 Riverpod
2. **需要全局访问**：使用 Service Locator
3. **原生插件调用**：直接使用服务类
4. **模块隔离**：使用接口抽象和依赖注入

# **5. 数据模型规范**

## **5.1 推荐库**

- **数据类**：使用 `freezed` 库，对于状态模型，推荐使用 `freezed`；其他模型，如果不是“不可变”，推荐使用 `json_annotation`或者手写
- **JSON序列化**：使用 `json_serializable` 库
- **强类型校验**：所有JSON转换必须有强类型校验

## **5.2 JSON 序列化类型安全和错误处理规范**

### **类型安全配置**

```yaml
# build.yaml 配置targets:
  $default:
    builders:
      json_serializable:
        options:
# 启用运行时类型检查（推荐开发时开启）checked: true

# 显式调用对象的 toJson() 方法explicit_to_json: true

# 禁止 JSON 中出现未定义的字段（反序列化时抛出异常）disallow_unrecognized_keys: true

# 生成 fromJson 工厂方法create_factory: true

# 生成 toJson 方法create_to_json: true

# 启用字段重命名支持field_rename: snake

# 启用空安全include_if_null: false

```

## **5.3 Freeze类型安全Immutable的模型定义**

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

## **5.4 错误处理和调试**

```dart
// 安全的 JSON 解析class SafeJsonParser {
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

// 使用示例class UserService {
  Future<UserModel?> parseUserFromJson(Map<String, dynamic> json) async {
    return SafeJsonParser.safeParse(
      json: json,
      fromJson: UserModel.fromJson,
      context: 'UserService.parseUserFromJson',
    );
  }
}

```

# **6. 异常处理规范**

## **6.1 异常处理架构**

1. **WSError [Exceptions and Network Errors](https://www.notion.so/Exceptions-and-Network-Errors-253a1747bfd18091be8ad1b1f9ccb264?pvs=21)** 
    - 用于网络请求异常
    - 对网络请求的异常进行分类
2. **Result**
    - 用于网络请求结果包装
    - 包含 WSError 或 Exception
3. **自定义异常**
    - **一般情况下业务无需自定义异常，也不鼓励自定义异常。只需要handle上面的Result并在错误情形下做Error Message的透出**
    - AppException 作为基础异常类
    - 所有自定义 Exception 必须继承自 AppException

## **6.2 自定义异常**

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

## **6.3 何时应该 throw Exception**

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
// 不要这样做：随意抛出异常if (user.name.length < 2) {
      throw Exception('Name too short');// 不明确的异常类型
    }

// 应该这样做：使用明确的异常类型if (user.name.length < 2) {
      throw ValidationException(
        'Name must be at least 2 characters long',
        fieldErrors: {'name': 'Name too short'},
      );
    }
  }
}

```

## **6.4 异常使用规范总结**

### **✅ 应该 throw Exception 的情况**

- **明确的错误条件**：如参数验证失败、业务规则违反
- **外部服务错误**：如网络请求失败、API 返回错误
- **资源不可用**：如文件不存在、权限不足
- **状态不一致**：如对象状态不符合预期

### **❌ 不应该 throw Exception 的情况**

- **正常的业务流程**：如用户取消操作、数据为空
- **可恢复的错误**：如网络重试、临时服务不可用
- **用户输入错误**：应该通过验证提示而不是异常
- **性能问题**：如加载时间过长、内存使用过高
- **同步的Provider中抛异常需要在外try catch，否则会白屏**

### **🎯 最佳实践**

- **提供有意义的错误信息**：包含错误代码、字段错误等详细信息
- **记录异常日志**：包含上下文信息便于调试
- **用户友好的错误提示**：将技术异常转换为用户可理解的提示

# **7. 代码质量规范**

## **7.1 代码风格**

- 遵循 Dart 官方代码规范
- 遵循 Flutter lint 规则
- 使用 `dart format` 工具格式化代码
- 使用 `dart analyze` 进行静态分析
- 保持方法简短，每个方法只做一件事
- 复杂逻辑拆分到私有方法中

## **7.2 注释规范**

- **公共API**：必须添加文档注释
- **复杂逻辑**：添加必要的行内注释
- **TODO注释**：标记待完成的功能

## **7.3 测试规范**

- **单元测试**：核心业务逻辑必须有单元测试
- **Widget测试**：重要UI组件要有Widget测试
- **集成测试**：关键用户流程要有集成测试

# **8. 性能优化规范**

## **8.1 Widget优化**

- 合理使用 `const` 构造函数
- 避免在 `build` 方法中创建新对象
- 使用 `ListView.builder` 处理长列表

## **8.2 状态管理优化**

- 避免不必要的状态更新
- 及时释放资源，避免内存泄漏
- 使用 `ref.watch` 只监听需要的数据
- 使用 `select` 来监听部分状态
- 合理使用 `keepAlive` 参数

# **9. 安全规范**

## **9.1 数据安全**

- 敏感信息不硬编码在代码中
- 使用环境变量或配置文件管理敏感配置
- 网络请求使用HTTPS

## **9.2 输入验证**

- 所有用户输入都要进行验证
- 防止SQL注入、XSS等安全漏洞
- 文件上传要验证文件类型和大小

# **10. 版本控制规范**

## **10.1 提交信息**

- 使用清晰的提交信息格式
- 每个提交只做一件事
- 提交前进行代码审查

## **10.2 分支管理**

- 主分支保持稳定
- 功能开发使用功能分支
- 及时合并和清理分支

# **11. 总结**

本规范基于Flutter开发的最佳实践和团队经验制定，旨在提高代码质量、开发效率和团队协作。所有团队成员都应该遵循这些规范，并在实践中不断完善和优化。

如有疑问或建议，请及时与团队讨论并更新本规范文档。

[Good or Bad Code](https://www.notion.so/Good-or-Bad-Code-26aa1747bfd1800d92a7c158e4bf38f0?pvs=21)

# 12. 参考

[Flutter Pitfalls](https://www.notion.so/Flutter-Pitfalls-1ada1747bfd18061b47ed8893ad7de33?pvs=21)