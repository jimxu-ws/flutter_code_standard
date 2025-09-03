import 'app_exception.dart';

/// An exception for business logic errors.
class BusinessException extends AppException {
  BusinessException(
    super.message, {
    super.code,
  });

  @override
  bool get isRetryable => false;

  @override
  String get userMessage => message;
}
