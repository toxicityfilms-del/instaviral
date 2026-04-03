import 'package:dio/dio.dart';

import 'package:reelboost_ai/services/api_log.dart';
import 'package:reelboost_ai/services/api_service.dart';

typedef TokenGetter = Future<String?> Function();
typedef UnauthorizedHandler = Future<void> Function();

bool _dioIsPublicAuthPath(String path) {
  return path.contains('/auth/login') ||
      path.contains('/auth/signup') ||
      path.contains('/auth/forgot-password') ||
      path.contains('/auth/reset-password');
}

/// Shared Dio client: [ApiService.baseUrl], JSON, `Authorization: Bearer <JWT>`.
///
/// **401** on protected routes triggers [onUnauthorized] (session clear + navigate to login
/// via provider invalidation). Public auth routes are excluded.
class ApiClient {
  ApiClient({
    TokenGetter? getToken,
    UnauthorizedHandler? onUnauthorized,
  })  : _getToken = getToken,
        _onUnauthorized = onUnauthorized {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiService.baseUrl,
        connectTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 120),
        headers: {'Content-Type': 'application/json'},
      ),
    );
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          options.baseUrl = ApiService.baseUrl;
          final getToken = _getToken;
          final t = getToken != null ? await getToken() : null;
          final trimmed = t?.trim();
          if (trimmed != null && trimmed.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $trimmed';
          }
          if (options.uri.host.contains('ngrok')) {
            options.headers['ngrok-skip-browser-warning'] = 'true';
          }
          return handler.next(options);
        },
        onResponse: (response, handler) async {
          await _handle401(response.statusCode, response.requestOptions.path);
          return handler.next(response);
        },
        onError: (e, handler) async {
          await _handle401(e.response?.statusCode, e.requestOptions.path);
          ApiLog.network(
            'Dio ${e.requestOptions.method} ${e.requestOptions.uri}',
            e,
            e.stackTrace,
          );
          return handler.next(e);
        },
      ),
    );
  }

  late final Dio _dio;
  final TokenGetter? _getToken;
  final UnauthorizedHandler? _onUnauthorized;

  Dio get dio => _dio;

  Future<void> _handle401(int? statusCode, String path) async {
    if (statusCode != 401) return;
    if (_dioIsPublicAuthPath(path)) return;
    final fn = _onUnauthorized;
    if (fn == null) return;
    try {
      await fn();
    } catch (err, st) {
      ApiLog.network('onUnauthorized failed', err, st);
    }
  }
}
