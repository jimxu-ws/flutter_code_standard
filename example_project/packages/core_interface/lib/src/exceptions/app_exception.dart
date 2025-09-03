/// 应用异常基类
/// 
/// 所有自定义异常的基类，提供统一的异常处理接口
abstract class AppException implements Exception {
  /// 异常消息
  final String message;
  
  /// 异常代码
  final String? code;
  
  /// 异常详情
  final dynamic details;
  
  /// 原始异常
  final Exception? originalException;
  
  /// 时间戳
  final DateTime timestamp;
  
  AppException(
    this.message, {
    this.code,
    this.details,
    this.originalException,
  }) : timestamp = DateTime.now();
  
  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.write('$runtimeType: $message');
    
    if (code != null) {
      buffer.write(' (Code: $code)');
    }
    
    if (details != null) {
      buffer.write('\nDetails: $details');
    }
    
    if (originalException != null) {
      buffer.write('\nOriginal: $originalException');
    }
    
    buffer.write('\nTimestamp: $timestamp');
    
    return buffer.toString();
  }
  
  /// 获取用户友好的错误消息
  String get userMessage => message;
  
  /// 获取错误类型
  String get errorType => runtimeType.toString();
  
  /// 是否可重试
  bool get isRetryable => false;
  
  /// 是否致命错误
  bool get isFatal => false;
}
