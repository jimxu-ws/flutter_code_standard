import 'package:flutter/widgets.dart';

import 'window_focus_manager.dart';

/// Set up focus listener for desktop platform
void setupFocusListener(WindowFocusManager manager) {
  // For desktop platforms, we can use platform-specific methods
  // This is a simplified implementation
  // Listen to app lifecycle changes which can indicate focus changes on desktop
  WidgetsBinding.instance.addObserver(DesktopFocusObserver(manager));
}

/// Observer for desktop focus detection
class DesktopFocusObserver with WidgetsBindingObserver {
  DesktopFocusObserver(this._manager);
  final WindowFocusManager _manager;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // On desktop, app lifecycle changes can indicate window focus changes
    switch (state) {
      case AppLifecycleState.resumed:
        _manager.handleFocusChange(hasFocus: true);
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _manager.handleFocusChange(hasFocus: false);
        break;
      case AppLifecycleState.hidden:
        _manager.handleFocusChange(hasFocus: false);
        break;
    }
  }
}