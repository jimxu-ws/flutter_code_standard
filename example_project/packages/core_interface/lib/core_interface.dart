/// 核心接口包
/// 
/// 提供所有模块间的通信契约，包括：
/// - 服务接口
/// - 数据模型
/// - 事件定义
/// - 路由注册接口
/// 
/// 版本：1.0.0
/// 兼容性：向后兼容
/// 维护者：@team-core

// 导出所有接口
export 'src/interfaces/i_user_service.dart';
export 'src/interfaces/i_payment_service.dart';
export 'src/interfaces/i_notification_service.dart';
export 'src/interfaces/i_analytics_service.dart';
export 'src/interfaces/i_network_service.dart';
export 'src/interfaces/i_storage_service.dart';
export 'src/interfaces/i_user_navigator.dart';

// 导出所有模型
export 'src/models/user.dart';
export 'src/models/payment.dart';
export 'src/models/notification.dart';

// 导出所有事件
export 'src/events/user_events.dart';
export 'src/events/payment_events.dart';

// 导出路由注册接口
export 'src/routes/route_register.dart';
export 'src/routes/navigation_service.dart';

// 导出异常类
export 'src/exceptions/app_exception.dart';
export 'src/exceptions/validation_exception.dart';
export 'src/exceptions/business_exception.dart';
export 'src/exceptions/navigation_exception.dart';
export 'src/exceptions/network_exception.dart';

// 导出工具类
export 'src/utils/result.dart';
export 'src/utils/ws_error.dart';
