import 'dart:io';

import 'package:flutter/foundation.dart';

bool isMobile() {
  return !kIsWeb && (Platform.isAndroid || Platform.isIOS);
}
