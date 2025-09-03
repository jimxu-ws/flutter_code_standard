/// 用户模块
/// 
/// 提供用户认证、用户信息管理等功能
/// 
/// 主要功能：
/// - 用户登录、注册、登出
/// - 用户信息管理
/// - 用户状态管理
/// - 用户相关路由

///
/// This file exports all the public-facing APIs of the user module.
library user_module;

// 导出服务实现
export 'src/services/user_service_impl.dart';

// 导出路由注册器
export 'src/routes/user_route_register.dart';

// 导出依赖注入配置
export 'src/di/user_module_registrar.dart';

// 导出屏幕组件
export 'src/screens/login_screen.dart';

// 导出用户模块初始化
export 'src/user_module_init.dart';


export 'src/routes/user_navigation_service.dart';
