import 'package:go_router/go_router.dart';
import 'package:core_interface/core_interface.dart';

/// GoRouter 导航服务实现
///
/// 基于 GoRouter 的导航服务实现，使用命名路由进行解耦
class GoRouterNavigationService implements NavigationService {
  final GoRouter _router;

  GoRouterNavigationService(this._router);

  @override
  Future<void> navigateTo(
    String routeName, {
    Map<String, String>? params,
    Map<String, String>? queryParams,
    Object? extra,
  }) async {
    try {
      print('[Navigation] Navigating to: $routeName, params: $params, query: $queryParams');
      _router.goNamed(
        routeName,
        pathParameters: params ?? const {},
        queryParameters: queryParams ?? const {},
        extra: extra,
      );
    } catch (e) {
      print('[Navigation] Error: $e');
      throw NavigationException('导航失败：$e');
    }
  }

  @override
  void goBack() {
    try {
      if (_router.canPop()) {
        _router.pop();
      } else {
        // 在根页面无法返回时，可以导航到主页或不执行任何操作
        print('[Navigation] Cannot pop from the current route.');
      }
    } catch (e) {
      print('[Navigation] GoBack error: $e');
      throw NavigationException('返回失败：$e');
    }
  }

  @override
  void goBackUntil(String routeName) {
    try {
      // GoRouter 的 popUntil 功能有限，通常 go/goNamed 更适合这种场景
      _router.goNamed(routeName);
    } catch (e) {
      print('[Navigation] GoBackUntil error: $e');
      throw NavigationException('返回到指定页面失败：$e');
    }
  }

  @override
  Future<void> pushAndRemoveUntil(
    String newRouteName,
    String routeNameToRemove, // GoRouter 中此参数通常不直接使用
  ) async {
    try {
      // goNamed 默认会替换当前路由栈，实现类似效果
      _router.goNamed(newRouteName);
    } catch (e) {
      print('[Navigation] PushAndRemoveUntil error: $e');
      throw NavigationException('导航并清除路由栈失败：$e');
    }
  }

  @override
  Future<void> replace(String routeName, {Map<String, String>? params}) async {
    try {
      _router.pushReplacementNamed(routeName, pathParameters: params ?? const {});
    } catch (e) {
      print('[Navigation] Replace error: $e');
      throw NavigationException('替换页面失败：$e');
    }
  }

  @override
  String? get currentRouteName {
    try {
      // 从当前匹配的路由中获取名称
      final route = _router.routerDelegate.currentConfiguration.matches.last.route;
      return (route is GoRoute) ? route.name : null;
    } catch (e) {
      print('[Navigation] Get current route name error: $e');
      return null;
    }
  }

  @override
  String? get currentRoutePath {
    try {
      return _router.routerDelegate.currentConfiguration.uri.toString();
    } catch (e) {
      print('[Navigation] Get current route path error: $e');
      return null;
    }
  }

  @override
  bool get canGoBack {
    try {
      return _router.canPop();
    } catch (e) {
      print('[Navigation] Can go back error: $e');
      return false;
    }
  }
}
