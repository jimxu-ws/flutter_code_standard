import 'dart:js_interop';

import 'package:web/web.dart';

import 'window_focus_manager.dart';


/// Set up focus listener for web platform
void setupFocusListener(WindowFocusManager manager) {
  WebFocusObserver(manager);
}

/// Web-specific focus observer implementation
class WebFocusObserver {
  factory WebFocusObserver(WindowFocusManager manager) {
    _instance ??= WebFocusObserver._(manager);
    return _instance!;
  }

  WebFocusObserver._(this._manager) {
    _setupFocusListener();
  }
  EventListener? _focusListener;
  EventListener? _blurListener;
  final WindowFocusManager _manager;
  static WebFocusObserver? _instance;

  void _setupFocusListener() {
    // Bind listeners using JS interop.
    _focusListener = ((Event event) => _manager.handleFocusChange(hasFocus: true)).toJS;
    _blurListener = ((Event event) => _manager.handleFocusChange(hasFocus: false)).toJS;
    window.addEventListener('focus', _focusListener);
    window.addEventListener('blur', _blurListener);
  }
}

