import 'package:core_interface/core_interface.dart';
import 'package:go_router/go_router.dart';

/// 核心模块路由注册器
/// 
/// 负责注册应用级别的核心路由，例如闪屏页、引导页等（当前为空）
class CoreRouteRegister implements RouteRegister {
  @override
  String get moduleName => 'core';

  @override
  int get priority => -1; // 可以设置一个较低的优先级

  @override
  void registerRoutes(List<GoRoute> routes) {
    // 当前没有核心路由，此方法为空
    // 未来可以添加闪屏页、引导页等路由
  }
}
