/// 埋点服务接口
/// 
/// 提供统一的数据埋点功能
abstract class IAnalyticsService {
  /// 记录事件
  Future<void> trackEvent(String eventName, {Map<String, dynamic>? parameters});
  
  /// 设置用户属性
  Future<void> setUserProperty(String name, String value);
  
  /// 设置用户 ID
  Future<void> setUserId(String userId);
  
  /// 记录页面访问
  Future<void> trackPageView(String pageName, {Map<String, dynamic>? parameters});
  
  /// 记录错误
  Future<void> trackError(String error, {String? stackTrace});
  
  /// 记录性能指标
  Future<void> trackPerformance(String metricName, double value);
  
  /// 启用/禁用埋点
  Future<void> setEnabled(bool enabled);
  
  /// 检查是否已启用
  Future<bool> isEnabled();
}
