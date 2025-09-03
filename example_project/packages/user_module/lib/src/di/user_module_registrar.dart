import 'package:get_it/get_it.dart';
import 'package:core_interface/core_interface.dart';
import '../services/user_service_impl.dart';
import '../repositories/user_repository_impl.dart';
import '../providers/user_provider.dart';
import '../routes/user_route_register.dart';
import '../routes/user_navigation_service.dart';

/// 用户模块服务注册器
/// 
/// 负责注册用户模块的所有服务到依赖注入容器
class UserModuleRegistrar {
  /// 注册用户模块的所有服务
  static void register() {
    final getIt = GetIt.instance;
    
    print('👤 注册用户模块服务...');
    
    // 注册用户服务实现
    getIt.registerSingleton<IUserService>(UserServiceImpl());
    
    // 注册用户仓库实现
    getIt.registerSingleton<IUserRepository>(UserRepositoryImpl());
    
    // 注册用户状态管理
    getIt.registerSingleton<UserNotifier>(UserNotifier(getIt<IUserService>()));
    
    // 注册路由注册器
    getIt.registerSingleton<RouteRegister>(UserRouteRegister());
    
    // 注册用户导航服务实现
    getIt.registerLazySingleton<IUserNavigator>(() => UserNavigatorImpl());
    
    print('✅ 用户模块服务注册完成');
  }
  
  /// 注册单个服务（可选）
  static void registerService<T extends Object>(T instance) {
    GetIt.instance.registerSingleton<T>(instance);
  }
  
  /// 检查服务是否已注册
  static bool isServiceRegistered<T extends Object>() {
    return GetIt.instance.isRegistered<T>();
  }
  
  /// 获取已注册的服务
  static T getService<T extends Object>() {
    return GetIt.instance<T>();
  }
  
  /// 注销所有用户模块服务
  static void unregister() {
    final getIt = GetIt.instance;
    
    print('🗑️ 注销用户模块服务...');
    
    try {
      if (getIt.isRegistered<IUserService>()) {
        getIt.unregister<IUserService>();
      }
      
      if (getIt.isRegistered<IUserRepository>()) {
        getIt.unregister<IUserRepository>();
      }
      
      if (getIt.isRegistered<UserNotifier>()) {
        getIt.unregister<UserNotifier>();
      }
      
      if (getIt.isRegistered<RouteRegister>()) {
        getIt.unregister<RouteRegister>();
      }
      
      if (getIt.isRegistered<IUserNavigator>()) {
        getIt.unregister<IUserNavigator>();
      }
      
      print('✅ 用户模块服务注销完成');
    } catch (e) {
      print('❌ 用户模块服务注销失败: $e');
    }
  }
}
