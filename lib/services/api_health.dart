import 'package:http/http.dart' as http;

import 'package:reelboost_ai/services/api_log.dart';

/// GET `{origin}/health` (not under `/api`).
class ApiHealth {
  ApiHealth._();

  static const Duration _timeout = Duration(milliseconds: 8000);

  static Future<bool> reachable(String origin) async {
    final base = origin.replaceAll(RegExp(r'/$'), '');
    final uri = Uri.parse('$base/health');
    final headers = <String, String>{};
    if (uri.host.contains('ngrok')) {
      headers['ngrok-skip-browser-warning'] = 'true';
    }
    try {
      final res = await http.get(uri, headers: headers).timeout(_timeout);
      final ok = res.statusCode == 200;
      if (!ok) {
        ApiLog.apiFailure(
          'GET $uri failed: HTTP ${res.statusCode} body=${res.body.length > 500 ? '${res.body.substring(0, 500)}…' : res.body}',
        );
      }
      return ok;
    } catch (e, st) {
      ApiLog.apiFailure('GET $uri failed: $e', e, st);
      return false;
    }
  }
}
