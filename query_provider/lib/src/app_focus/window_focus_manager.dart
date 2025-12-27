import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/log.dart';
import 'focus_observer_desktop.dart'
    if (dart.library.html) 'focus_observer_web.dart';

/// Manages window focus detection for desktop and web platforms
class WindowFocusManager extends ChangeNotifier {
  /// Singleton instance
  factory WindowFocusManager() {
    _instance ??= WindowFocusManager._();
    return _instance!;
  }

  WindowFocusManager._() {
    _initialize();
  }
  static WindowFocusManager? _instance;

  bool _windowHasFocus = true;
  final Set<VoidCallback> _onFocusCallbacks = {};
  final Set<VoidCallback> _onBlurCallbacks = {};

  /// Whether the window currently has focus
  bool get windowHasFocus => _windowHasFocus;
  bool get windowLostFocus => !_windowHasFocus;

  /// Whether window focus detection is supported on this platform
  bool get isSupported {
    if (kIsWeb) {
      return true;
    }
    try {
      return Platform.isWindows ||
          Platform.isMacOS ||
          Platform.isLinux ||
          Platform.isAndroid ||
          Platform.isIOS;
    } catch (_) {
      return false;
    }
  }

  void _initialize() {
    if (!isSupported) {
      return;
    }

    // Listen to window focus events
    setupFocusListener(this);
  }

  /// Handle focus change
  void handleFocusChange({required bool hasFocus}) {
    final previousFocus = _windowHasFocus;
    _windowHasFocus = hasFocus;

    // Notify listeners
    notifyListeners();

    // Handle focus transitions
    if (!previousFocus && hasFocus) {
      // Window gained focus
      _notifyFocusCallbacks();
    } else if (previousFocus && !hasFocus) {
      // Window lost focus
      _notifyBlurCallbacks();
    }
  }

  /// Register callback for when window gains focus
  void addOnFocusCallback(VoidCallback callback) {
    _onFocusCallbacks.add(callback);
  }

  /// Register callback for when window loses focus
  void addOnBlurCallback(VoidCallback callback) {
    _onBlurCallbacks.add(callback);
  }

  /// Remove focus callback
  void removeOnFocusCallback(VoidCallback callback) {
    _onFocusCallbacks.remove(callback);
  }

  /// Remove blur callback
  void removeOnBlurCallback(VoidCallback callback) {
    _onBlurCallbacks.remove(callback);
  }

  void _notifyFocusCallbacks() {
    for (final callback in _onFocusCallbacks) {
      try {
        callback();
      } catch (e) {
        Log.info('Error in window focus callback: $e');
      }
    }
  }

  void _notifyBlurCallbacks() {
    for (final callback in _onBlurCallbacks) {
      try {
        callback();
      } catch (e) {
        Log.info('Error in window blur callback: $e');
      }
    }
  }

  /// Manually trigger focus change (for testing or custom implementations)
  // ignore: avoid_positional_boolean_parameters
  void setWindowFocus(bool hasFocus) {
    handleFocusChange(hasFocus: hasFocus);
  }

  @override
  void dispose() {
    _onFocusCallbacks.clear();
    _onBlurCallbacks.clear();
    super.dispose();
  }
}

/// Provider for window focus manager
final windowFocusManagerProvider = ChangeNotifierProvider<WindowFocusManager>((
  ref,
) {
  return WindowFocusManager();
});

/// Provider for current window focus state
final windowFocusStateProvider = Provider<bool>((ref) {
  final manager = ref.watch(windowFocusManagerProvider);
  return manager.windowHasFocus;
});

/// Provider for whether window focus detection is supported
final windowFocusSupportedProvider = Provider<bool>((ref) {
  return WindowFocusManager().isSupported;
});
