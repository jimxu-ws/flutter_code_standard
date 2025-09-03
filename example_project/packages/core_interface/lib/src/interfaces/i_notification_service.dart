/// 通知服务接口
/// 
/// 提供统一的通知功能
abstract class INotificationService {
  /// 显示本地通知
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  });
  
  /// 取消通知
  Future<void> cancelNotification(int id);
  
  /// 取消所有通知
  Future<void> cancelAllNotifications();
  
  /// 获取待处理的通知
  Future<List<PendingNotification>> getPendingNotifications();
  
  /// 检查通知权限
  Future<bool> hasPermission();
  
  /// 请求通知权限
  Future<bool> requestPermission();
}

/// 待处理的通知
class PendingNotification {
  final int id;
  final String title;
  final String body;
  final String? payload;
  
  const PendingNotification({
    required this.id,
    required this.title,
    required this.body,
    this.payload,
  });
}
