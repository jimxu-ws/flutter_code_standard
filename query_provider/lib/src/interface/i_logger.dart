
abstract class IQueryLogger {
  void info(String message, [Object? error, StackTrace? stackTrace]);
  void error(String message, [Object? error, StackTrace? stackTrace]);
  void warn(String message, [Object? error, StackTrace? stackTrace]);
  void debug(String message, [Object? error, StackTrace? stackTrace]);
}
