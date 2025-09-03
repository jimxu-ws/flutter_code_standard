import 'app_exception.dart';

/// 验证异常
class ValidationException extends AppException {
  /// 验证失败的字段
  final String? field;
  
  /// 验证规则
  final String? rule;
  
  ValidationException(
    super.message, {
    super.code,
    this.field,
    this.rule,
    super.details,
    super.originalException,
  });
  
  @override
  bool get isRetryable => false;
  
  @override
  String get userMessage => '输入数据有误：$message';
}
