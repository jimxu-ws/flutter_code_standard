import 'app_exception.dart';

/// An exception for network-related errors.
class NetworkException extends AppException {
  NetworkException(
    super.message, {
    super.code,
  });

  @override
  String get userMessage => '网络连接失败，请检查您的网络设置。';
}
