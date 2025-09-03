import 'app_exception.dart';

/// 导航异常
///
/// 当路由导航失败时抛出
class NavigationException extends AppException {
  NavigationException(
    super.message, {
    super.code,
  });

  @override
  String get userMessage => '导航时发生错误，请稍后重试。';
}
