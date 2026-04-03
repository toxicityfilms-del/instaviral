import 'dart:developer' as developer;

import 'package:flutter/foundation.dart' show kDebugMode;

/// Tagged logs for API / HTTP failures (visible in `flutter run` / logcat).
class ApiLog {
  ApiLog._();

  static const String _name = 'reelboost_api';

  static void network(String message, [Object? error, StackTrace? stackTrace]) {
    if (!kDebugMode) return;
    developer.log(message, name: _name, error: error, stackTrace: stackTrace);
  }
}
