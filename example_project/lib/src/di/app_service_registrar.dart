import 'package:get_it/get_it.dart';
import 'package:core_interface/core_interface.dart';
import 'package:user_module/user_module.dart';
import 'package:network_module/network_module.dart';
import 'package:storage_module/storage_module.dart';
import 'package:go_router_service_module/go_router_service_module.dart';
import 'package:home_module/home_module.dart';
import '../routes/core_route_register.dart';

/// 应用级别的服务注册器
/// 负责注册所有模块的服务
class AppServiceRegistrar {
  /// 注册所有模块的服务
  static void registerAll() {
    print('🚀 开始注册所有模块服务...');
    final getIt = GetIt.instance;

    // 1. 注册核心服务模块 (网络、存储等)
    print('📦 注册核心服务模块...');
    NetworkModuleRegistrar.register();
    StorageModuleRegistrar.register();
    getIt.registerLazySingleton<RouteRegister>(() => CoreRouteRegister());
    HomeModuleRegistrar.register();

    // 2. 注册功能模块 (用户、支付等)
    print('👤 注册用户模块...');
    UserModuleInit.initialize();

    // 3. 注册路由和导航服务实现
    //    这个模块会负责创建 GoRouter 实例并注册它和 NavigationService
    print('🚦 注册路由服务实现...');
    GoRouterServiceRegistrar.register(); 

    print('✅ 所有模块服务注册完成');
  }
}

/// 简化的服务注册器（推荐使用）
class SimpleServiceRegistrar {
  static void registerAll() {
    // 直接调用各模块的注册器
    // 这种方式更简单直接，但需要确保所有模块都被导入
    
    // 注意：这些调用需要在对应的模块被导入后才能执行
    // UserModuleRegistrar.register();
    // PaymentModuleRegistrar.register();
    // NotificationModuleRegistrar.register();
    // AnalyticsModuleRegistrar.register();
  }
}
