import 'package:get_it/get_it.dart';
import 'package:core_interface/core_interface.dart';
import 'services/user_service_impl.dart';
import 'routes/user_route_register.dart';

/// 用户模块初始化
/// 
/// 负责注册用户模块的所有服务和路由
class UserModuleInit {
  static bool _isInitialized = false;
  
  /// 初始化用户模块
  static void initialize() {
    if (_isInitialized) {
      print('[UserModule] Already initialized');
      return;
    }
    
    try {
      print('[UserModule] Initializing...');
      
      // 注册用户服务
      GetIt.instance.registerSingleton<IUserService>(UserServiceImpl());
      
      // 注册路由注册器
      GetIt.instance.registerSingleton<RouteRegister>(UserRouteRegister());
      
      _isInitialized = true;
      print('[UserModule] ✅ Initialized successfully');
    } catch (e) {
      print('[UserModule] ❌ Initialization failed: $e');
      rethrow;
    }
  }
  
  /// 检查是否已初始化
  static bool get isInitialized => _isInitialized;
  
  /// 重置初始化状态（主要用于测试）
  static void reset() {
    _isInitialized = false;
  }
}
