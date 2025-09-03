import 'package:core_interface/core_interface.dart';
import 'package:go_router/go_router.dart';
import '../screens/home_screen.dart';
import '../screens/error_screen.dart';
import 'home_routes.dart';

/// Home Module Route Registrar
/// 
/// Registers all routes for the home module.
class HomeRouteRegister implements RouteRegister {
  @override
  String get moduleName => 'home';

  @override
  int get priority => 10; // Core functionality, high priority

  @override
  void registerRoutes(List<GoRoute> routes) {
    routes.addAll([
      GoRoute(
        path: '/',
        name: HomeRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/error',
        name: HomeRoutes.error,
        builder: (context, state) => ErrorScreen(
          message: state.extra is String ? state.extra as String : '未知错误',
        ),
      ),
    ]);
  }
}
