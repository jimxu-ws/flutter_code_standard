以下实现一个 **高度解耦、可扩展、易测试、支持统一拦截** 的 Flutter 路由架构，是大型模块化应用的**最佳实践**。

---

# ✅ 最佳实践：GoRouter + DI 自动注册 + 导航服务接口

> **目标**：  
> - 模块自行注册路由，主项目无感知  
> - 页面跳转通过接口，不依赖具体页面  
> - 支持埋点、权限、动画等统一控制  
> - 完全解耦，支持独立开发与测试

---

## 📋 目录

- [📁 项目结构](#-项目结构)
- [1. 定义核心接口](#1-定义核心接口core_contracts-或主项目)
  - [route_register.dart](#route_registerdart)
  - [navigation_service.dart](#navigation_servicedart)
- [2. 模块实现：以 user_package 为例](#2-模块实现以-user_package-为例)
  - [user_route_register.dart](#user_route_registerdart)
  - [user_navigation.dart](#user_navigationdart可选模块内导航封装)
- [3. 导航服务实现（集成 go_router）](#3-导航服务实现集成-go_router)
- [4. 自动聚合路由（DI 驱动）](#4-自动聚合路由di-驱动)
- [5. DI 配置（injectable）](#5-di-配置injectable)
- [6. 主应用启动](#6-主应用启动)
- [7. 模块内使用导航（完全解耦）](#7-模块内使用导航完全解耦)
- [✅ 优势总结](#-优势总结)
- [🚀 进阶建议](#-进阶建议)
- [结论](#结论)

---

---

## 📁 项目结构

```
myapp/
├── lib/
│   ├── main.dart
│   ├── app_router.dart          # 路由聚合与生成
│   └── services/
│       └── navigation_service.dart  # 导航服务接口
├── packages/
│   ├── user_package/
│   │   ├── lib/user_route_register.dart
│   │   ├── lib/user_navigation.dart
│   │   └── lib/screens/user_screen.dart
│   ├── order_package/
│   │   ├── lib/order_route_register.dart
│   │   ├── lib/order_navigation.dart
│   │   └── lib/screens/order_screen.dart
│   └── core_contracts/
│       └── lib/route_register.dart
├── pubspec.yaml
└── di.config.dart
```

---

## 1. 定义核心接口（`core_contracts` 或主项目）

### `route_register.dart`

```dart
// lib/route_register.dart
import 'package:go_router/go_router.dart';

/// 模块实现此接口来自注册路由
abstract class RouteRegister {
  void registerRoutes(List<GoRoute> routes);
}
```

### `navigation_service.dart`

```dart
// lib/services/navigation_service.dart
abstract class NavigationService {
  Future<void> navigateTo(String routeName, {Map<String, String>? params, Object? extra});
  void goBack();
  void goBackUntil(String routeName);
  Future<void> pushAndRemoveUntil(String newRouteName, String routeNameToRemove);
}
```

---

## 2. 模块实现：以 `user_package` 为例

### `user_route_register.dart`

```dart
// packages/user_package/lib/user_route_register.dart
import 'package:myapp/route_register.dart';
import 'package:go_router/go_router.dart';
import 'screens/user_screen.dart';

@injectable
class UserRouteRegister implements RouteRegister {
  @override
  void registerRoutes(List<GoRoute> routes) {
    routes.add(
      GoRoute(
        path: '/user/:id',
        name: 'user', // 命名路由，用于 navigateTo('user')
        builder: (context, state) {
          final userId = state.pathParameters['id']!;
          return UserScreen(userId: userId);
        },
      ),
    );
  }
}
```

### `user_navigation.dart`（可选：模块内导航封装）

```dart
// packages/user_package/lib/user_navigation.dart
abstract class UserNavigation {
  Future<void> openUserProfile(String userId);
}

class UserNavigationImpl implements UserNavigation {
  final NavigationService _nav;

  UserNavigationImpl(this._nav);

  @override
  Future<void> openUserProfile(String userId) {
    return _nav.navigateTo('user', params: {'id': userId});
  }
}
```

> ✅ 优势：模块内部跳转也通过服务，便于 Mock 测试。

---

## 3. 导航服务实现（集成 go_router）

```dart
// lib/services/go_router_navigation_service.dart
@injectable
class GoRouterNavigationService implements NavigationService {
  final GoRouter _router;

  GoRouterNavigationService(this._router);

  @override
  Future<void> navigateTo(String routeName,
      {Map<String, String>? params, Object? extra}) async {
    final config = _router.routeInformationProvider.value.routeInformation;
    final uri = Uri.parse(config.location!);
    final currentPath = uri.path;

    // 🔔 可在此统一埋点
    print('[Navigation] From: $currentPath, To: $routeName, Params: $params');

    // 🔐 可在此统一权限检查
    // if (!await checkPermission(routeName)) throw PermissionException();

    final path = _resolvePath(routeName, params);
    _router.go(path, extra: extra);
  }

  @override
  void goBack() {
    if (_router.canPop()) _router.pop();
  }

  @override
  void goBackUntil(String routeName) {
    _router.popUntil((route) => route.name == routeName);
  }

  @override
  Future<void> pushAndRemoveUntil(String newRouteName, String routeNameToRemove) async {
    final path = _resolvePath(newRouteName);
    _router.pushAndRemoveUntil(path, (route) => route.name == routeNameToRemove);
  }

  String _resolvePath(String routeName, Map<String, String>? params) {
    // 可从路由表映射，或使用 go_router 的命名路由
    return params != null
        ? '/$routeName/${params.values.first}' // 简化示例
        : '/$routeName';
  }
}
```

---

## 4. 自动聚合路由（DI 驱动）

```dart
// lib/app_router.dart
List<GoRoute> generateRoutes() {
  final routes = <GoRoute>[];
  final registrars = GetIt.I.all<RouteRegister>();

  for (final registrar in registrars) {
    registrar.registerRoutes(routes);
  }

  return routes;
}

GoRouter createAppRouter() {
  final routes = generateRoutes();
  return GoRouter(
    routes: routes,
    // 统一错误处理
    errorBuilder: (context, state) => ErrorScreen(state.error),
    // 可选：全局跳转拦截
    redirect: (context, state) {
      // 例如：未登录跳转登录页
      // if (!authService.isLoggedIn && state.location != '/login') {
      //   return '/login';
      // }
      return null;
    },
  );
}
```

---

## 5. DI 配置（`injectable`）

```dart
// di.config.dart
@injectableInit
void configureDependencies() => $initGetIt(GetIt.instance);

// 手动注册（或使用 @Injectable() 注解）
void setupDependencies() {
  configureDependencies();

  // 注册所有 RouteRegister
  GetIt.I.registerSingleton<RouteRegister>(UserRouteRegister());
  GetIt.I.registerSingleton<RouteRegister>(OrderRouteRegister());

  // 创建 router
  final router = createAppRouter();
  GetIt.I.registerSingleton<GoRouter>(router);

  // 注册导航服务
  GetIt.I.registerSingleton<NavigationService>(
    GoRouterNavigationService(router),
  );
}
```

---

## 6. 主应用启动

```dart
// lib/main.dart
void main() {
  setupDependencies();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final router = GetIt.I<GoRouter>();
    return MaterialApp.router(
      routerConfig: router,
      title: 'Modular App',
    );
  }
}
```

---

## 7. 模块内使用导航（完全解耦）

```dart
// packages/order_package/lib/screens/order_screen.dart
class OrderScreen extends StatelessWidget {
  final NavigationService _nav;

  OrderScreen(this._nav);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        // 通过接口跳转，不 import user_screen
        _nav.navigateTo('user', params: {'id': '123'});
      },
      child: Text('View User'),
    );
  }
}
```

> ✅ 注入方式：
> ```dart
> // 通过构造函数注入（推荐）
> final nav = GetIt.I<NavigationService>();
> return OrderScreen(nav);
> ```

---

## ✅ 优势总结

| 特性 | 实现方式 |
|------|----------|
| **路由解耦** | 模块自注册，DI 自动发现 |
| **跳转解耦** | 通过 `NavigationService` 接口 |
| **统一控制** | 埋点、权限、错误处理集中实现 |
| **可测试** | 可 Mock `NavigationService` 和 `RouteRegister` |
| **可扩展** | 新增模块只需注册 `RouteRegister` |
| **类型安全** | 可结合 `go_router` 命名路由 |

---

## 🚀 进阶建议

1. **路由表中心化（可选）**  
   定义常量：
   ```dart
   abstract class Routes {
     static const String user = 'user';
     static const String order = 'order';
   }
   ```
   避免字符串魔法值。

2. **支持参数类型化**  
   使用 `go_router` 的 `GoRouteData` 或自定义 `RouteArgs`。

3. **动态模块加载**  
   在 Web 或插件化场景，可异步注册路由。

4. **路由权限中间件**  
   在 `redirect` 中统一处理登录态。

---

## 结论

**完美解耦的路由架构**：

- ✅ 模块自治：自己注册路由
- ✅ 依赖倒置：跳转通过接口
- ✅ 统一治理：导航服务集中控制
- ✅ 易于测试与维护

这是大型 Flutter 应用在模块化、微前端、独立仓库场景下的**推荐标准做法**。
