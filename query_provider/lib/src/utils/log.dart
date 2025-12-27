import 'package:flutter/foundation.dart';

import '../interface/i_logger.dart';


class Log {
  static IQueryLogger? _logger;
  // ignore: use_setters_to_change_properties
  static void setLogger(IQueryLogger logger) {
    _logger = logger;
  }

  static void info(String message, [Object? error, StackTrace? stackTrace]) {
    if (_logger != null) {
      _logger!.info(message, error, stackTrace);
    } else {
      debugPrint('[INFO] $message, $error, $stackTrace');
    }
  }

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    if (_logger != null) {
      _logger!.error(message, error, stackTrace);
    } else {
      debugPrint('[ERROR] $message, $error, $stackTrace');
    }
  }

  static void warn(String message, [Object? error, StackTrace? stackTrace]) {
    if (_logger != null) {
      _logger!.warn(message, error, stackTrace);
    } else {
      debugPrint('[WARN] $message, $error, $stackTrace');
    }
  }

  static void debug(String message, [Object? error, StackTrace? stackTrace]) {
    if (_logger != null) {
      _logger!.debug(message, error, stackTrace);
    } else {
      debugPrint('[DEBUG] $message, $error, $stackTrace');
    }
  }
}
