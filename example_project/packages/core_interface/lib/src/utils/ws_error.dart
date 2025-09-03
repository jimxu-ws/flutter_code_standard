/// WebSocket 错误类
/// 
/// 用于处理 WebSocket 连接和通信错误
class WSError {
  /// 错误代码
  final String code;
  
  /// 错误消息
  final String message;
  
  /// 错误详情
  final dynamic details;
  
  /// 时间戳
  final DateTime timestamp;
  
  /// 是否可重试
  final bool isRetryable;
  
  const WSError({
    required this.code,
    required this.message,
    this.details,
    required this.timestamp,
    this.isRetryable = false,
  });
  
  /// 创建网络错误
  factory WSError.network(String message, {dynamic details}) {
    return WSError(
      code: 'NETWORK_ERROR',
      message: message,
      details: details,
      timestamp: DateTime.now(),
      isRetryable: true,
    );
  }
  
  /// 创建连接错误
  factory WSError.connection(String message, {dynamic details}) {
    return WSError(
      code: 'CONNECTION_ERROR',
      message: message,
      details: details,
      timestamp: DateTime.now(),
      isRetryable: true,
    );
  }
  
  /// 创建认证错误
  factory WSError.authentication(String message, {dynamic details}) {
    return WSError(
      code: 'AUTH_ERROR',
      message: message,
      details: details,
      timestamp: DateTime.now(),
      isRetryable: false,
    );
  }
  
  /// 创建协议错误
  factory WSError.protocol(String message, {dynamic details}) {
    return WSError(
      code: 'PROTOCOL_ERROR',
      message: message,
      details: details,
      timestamp: DateTime.now(),
      isRetryable: false,
    );
  }
  
  /// 创建超时错误
  factory WSError.timeout(String message, {dynamic details}) {
    return WSError(
      code: 'TIMEOUT_ERROR',
      message: message,
      details: details,
      timestamp: DateTime.now(),
      isRetryable: true,
    );
  }
  
  /// 创建未知错误
  factory WSError.unknown(String message, {dynamic details}) {
    return WSError(
      code: 'UNKNOWN_ERROR',
      message: message,
      details: details,
      timestamp: DateTime.now(),
      isRetryable: false,
    );
  }
  
  @override
  String toString() {
    return 'WSError(code: $code, message: $message, details: $details, timestamp: $timestamp, isRetryable: $isRetryable)';
  }
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WSError &&
          runtimeType == other.runtimeType &&
          code == other.code &&
          message == other.message &&
          details == other.details &&
          timestamp == other.timestamp &&
          isRetryable == other.isRetryable;
  
  @override
  int get hashCode => Object.hash(code, message, details, timestamp, isRetryable);
}
