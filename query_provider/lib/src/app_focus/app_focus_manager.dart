import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/log.dart';

/// Manages app lifecycle state and window focus for query refetching
class AppFocusManager extends ChangeNotifier with WidgetsBindingObserver {
  
  /// Singleton instance
  factory AppFocusManager() {
    _instance ??= AppFocusManager._();
    return _instance!;
  }
  
  AppFocusManager._() {
    WidgetsBinding.instance.addObserver(this);
  }
  static AppFocusManager? _instance;
  
  AppLifecycleState _state = AppLifecycleState.resumed;
  final Set<VoidCallback> _onResumeCallbacks = {};
  final Set<VoidCallback> _onPauseCallbacks = {};
  
  /// Current app lifecycle state
  AppLifecycleState get state => _state;
  
  /// Whether the app is currently in foreground
  bool get isInForeground => _state == AppLifecycleState.resumed;
  
  /// Whether the app is currently in background
  bool get isInBackground => !isInForeground;

  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final previousState = _state;
    _state = state;
    
    // Notify listeners of state change
    notifyListeners();
    
    // Handle transitions
    if (previousState != AppLifecycleState.resumed && 
        state == AppLifecycleState.resumed) {
      // App came to foreground
      _notifyResumeCallbacks();
    } else if (previousState == AppLifecycleState.resumed && 
               state != AppLifecycleState.resumed) {
      // App went to background
      _notifyPauseCallbacks();
    }
  }
  
  /// Register callback for when app resumes (comes to foreground)
  void addOnResumeCallback(VoidCallback callback) {
    _onResumeCallbacks.add(callback);
  }
  
  /// Register callback for when app pauses (goes to background)
  void addOnPauseCallback(VoidCallback callback) {
    _onPauseCallbacks.add(callback);
  }
  
  /// Remove resume callback
  void removeOnResumeCallback(VoidCallback callback) {
    _onResumeCallbacks.remove(callback);
  }
  
  /// Remove pause callback
  void removeOnPauseCallback(VoidCallback callback) {
    _onPauseCallbacks.remove(callback);
  }
  
  void _notifyResumeCallbacks() {
    for (final callback in _onResumeCallbacks) {
      try {
        callback();
      } catch (e) {
        // Ignore callback errors to prevent cascade failures
        Log.info('Error in app resume callback: $e');
      }
    }
  }
  
  void _notifyPauseCallbacks() {
    for (final callback in _onPauseCallbacks) {
      try {
        callback();
      } catch (e) {
        // Ignore callback errors to prevent cascade failures
        Log.info('Error in app pause callback: $e');
      }
    }
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _onResumeCallbacks.clear();
    _onPauseCallbacks.clear();
    super.dispose();
  }
}

/// Provider for app lifecycle state
final appLifecycleProvider = ChangeNotifierProvider<AppFocusManager>((ref) {
  return AppFocusManager();
});

/// Provider for current app lifecycle state
final appLifecycleStateProvider = Provider<AppLifecycleState>((ref) {
  final manager = ref.watch(appLifecycleProvider);
  return manager.state;
});

/// Provider for whether app is in foreground
final isAppInForegroundProvider = Provider<bool>((ref) {
  final manager = ref.watch(appLifecycleProvider);
  return manager.isInForeground;
});
