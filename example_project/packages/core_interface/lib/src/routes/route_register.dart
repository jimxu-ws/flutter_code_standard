import 'package:go_router/go_router.dart';

/// 路由注册接口
/// 
/// 每个模块实现此接口来自注册路由
/// 主应用通过依赖注入自动发现并注册所有路由
abstract class RouteRegister {
  /// 注册模块的路由
  /// 
  /// 参数：
  /// - [routes] 路由列表，模块需要向此列表添加自己的路由
  void registerRoutes(List<GoRoute> routes);
  
  /// 获取模块名称
  /// 
  /// 用于日志记录和调试
  String get moduleName;
  
  /// 获取模块优先级
  /// 
  /// 数值越小优先级越高，用于控制路由注册顺序
  /// 默认返回 100
  int get priority => 100;
}
