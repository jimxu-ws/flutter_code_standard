import 'package:core_interface/core_interface.dart';
import 'package:go_router/go_router.dart';
import 'package:injectable/injectable.dart';
import '../screens/login_screen.dart';
import 'user_routes.dart';

/// 用户模块路由注册器
/// 
/// 负责注册用户模块的所有路由
class UserRouteRegister implements RouteRegister {
  @override
  String get moduleName => 'user_module';
  
  @override
  int get priority => 10; // 用户模块优先级较高
  
  @override
  void registerRoutes(List<GoRoute> routes) {
    print('[UserRouteRegister] Registering user module routes...');
    
    // 登录页面
    routes.add(
      GoRoute(
        path: '/login',
        name: UserRoutes.login,
        builder: (context, state) {
          return const LoginScreen();
        },
      ),
    );
    
    print('[UserRouteRegister] ✅ Registered ${routes.length} routes');
  }
}
