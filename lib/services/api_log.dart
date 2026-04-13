import 'dart:developer' as developer;

import 'package:flutter/foundation.dart' show kDebugMode;

/// Tagged logs for API / HTTP (debug-only vs always-on failures).
class ApiLog {
  ApiLog._();

  static const String _name = 'reelboost_api';

  static void network(String message, [Object? error, StackTrace? stackTrace]) {
    if (!kDebugMode) return;
    developer.log(message, name: _name, error: error, stackTrace: stackTrace);
  }

  /// Connection / HTTP failures — logged in debug and release (logcat / Xcode console).
  static void apiFailure(String message, [Object? error, StackTrace? stackTrace]) {
    developer.log(message, name: _name, error: error, stackTrace: stackTrace);
  }

  /// Final resolved REST base after bootstrap (debug builds only).
  static void debugResolvedApiBase(String baseUrl) {
    if (!kDebugMode) return;
    developer.log('Resolved API baseUrl: $baseUrl', name: _name);
  }
}
