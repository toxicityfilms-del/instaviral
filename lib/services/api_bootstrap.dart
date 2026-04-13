import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:reelboost_ai/core/config/api_config.dart';
import 'package:reelboost_ai/services/api_health.dart';
import 'package:reelboost_ai/services/api_log.dart';
import 'package:reelboost_ai/services/api_runtime.dart';
import 'package:reelboost_ai/services/api_service.dart';

const _prefsKeyApiBase = 'reelboost_api_base_cache';
const _prefsKeyManualApi = 'reelboost_api_base_manual';

bool _startsWithHttps(String s) => s.toLowerCase().startsWith('https://');

/// Non-production hosts (cleared from prefs on startup).
bool _isDisallowedStoredApiUrl(String? raw) {
  if (raw == null || raw.trim().isEmpty) return false;
  final t = raw.trim().toLowerCase();
  if (t.startsWith('http://')) return true;
  final u = Uri.tryParse(t.contains('://') ? t : 'https://$t');
  if (u == null || u.host.isEmpty) {
    return t.contains('localhost') ||
        t.contains('127.0.0.1') ||
        t.contains('10.0.2.2') ||
        t.contains('192.168.');
  }
  final h = u.host.toLowerCase();
  if (h == 'localhost' || h == '10.0.2.2') return true;
  if (h.startsWith('127.')) return true;
  if (h.startsWith('192.168.')) return true;
  if (h.startsWith('10.')) return true;
  return false;
}

Future<void> _purgeInsecureApiPrefs(SharedPreferences prefs) async {
  final manual = prefs.getString(_prefsKeyManualApi);
  final cached = prefs.getString(_prefsKeyApiBase);
  if (_isDisallowedStoredApiUrl(manual)) {
    await prefs.remove(_prefsKeyManualApi);
    ApiLog.network('ApiBootstrap: removed disallowed manual API base');
  }
  if (_isDisallowedStoredApiUrl(cached)) {
    await prefs.remove(_prefsKeyApiBase);
    ApiLog.network('ApiBootstrap: removed disallowed cached API base');
  }
}

String _expectedProductionHost() => Uri.parse(ApiConfig.apiOrigin).host.toLowerCase();

/// Drop cached base if it points at a host other than [ApiConfig.apiOrigin] (stale LAN/ngrok/old deploy).
/// Skipped when using `--dart-define=API_BASE_URL=...` so a custom build target is preserved.
Future<void> _purgeStaleCachedApiBase(SharedPreferences prefs) async {
  if (!ApiService.usesCompileTimeDefaultApiBase) return;
  final cached = prefs.getString(_prefsKeyApiBase)?.trim();
  if (cached == null || cached.isEmpty) return;
  if (_isDisallowedStoredApiUrl(cached)) return;
  try {
    final normalized = ApiService.normalizeApiBase(cached);
    final host = Uri.parse(normalized).host.toLowerCase();
    if (host != _expectedProductionHost()) {
      await prefs.remove(_prefsKeyApiBase);
      ApiLog.network(
        'ApiBootstrap: cleared stale API cache (was $host, expected $_expectedProductionHost())',
      );
    }
  } catch (e, st) {
    ApiLog.apiFailure('ApiBootstrap: stale cache check failed', e, st);
  }
}

/// Runs before `runApp`: picks API base, probes `/health`, caches successes.
class ApiBootstrap {
  ApiBootstrap._();

  static Future<void> initialize() async {
    ApiRuntime.bootstrapDetail = null;
    final prefsEarly = await SharedPreferences.getInstance();
    try {
      await _purgeInsecureApiPrefs(prefsEarly);
      await _purgeStaleCachedApiBase(prefsEarly);
    } catch (e, st) {
      ApiLog.apiFailure('ApiBootstrap: purge prefs failed', e, st);
    }

    var rawManual = prefsEarly.getString(_prefsKeyManualApi)?.trim();
    if (rawManual != null && rawManual.isNotEmpty && !_startsWithHttps(rawManual)) {
      final hostOnly = rawManual.replaceAll(RegExp(r'^\s*'), '');
      rawManual = hostOnly.isEmpty ? null : 'https://$hostOnly';
    }
    ApiRuntime.stickyManualApiBase =
        (rawManual != null && _startsWithHttps(rawManual) && rawManual.length > 12)
            ? rawManual
            : null;

    try {
      final base = await _resolveBaseUrl();
      final origin = ApiService.originFromApiBase(base);
      final ok = await ApiHealth.reachable(origin);
      ApiRuntime.resolvedApiBase = base;
      ApiRuntime.healthCheckOk = ok;
      if (ok) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_prefsKeyApiBase, base);
      } else {
        ApiLog.apiFailure('ApiBootstrap: unreachable $origin/health (base=$base)');
        ApiRuntime.bootstrapDetail =
            'Server not reachable at $origin/health. Check internet, Railway deployment, and server logs.\n\n'
            'Verify Railway env (e.g. MONGO_URI), MongoDB Atlas network access, and deployment health.';
      }
    } catch (e, st) {
      ApiLog.apiFailure('ApiBootstrap.initialize failed', e, st);
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_prefsKeyApiBase);

      if (cached != null && cached.isNotEmpty && !_isDisallowedStoredApiUrl(cached)) {
        ApiRuntime.resolvedApiBase = ApiService.normalizeApiBase(cached);
      } else if (ApiRuntime.stickyManualApiBase != null &&
          ApiRuntime.stickyManualApiBase!.isNotEmpty &&
          !_isDisallowedStoredApiUrl(ApiRuntime.stickyManualApiBase)) {
        ApiRuntime.resolvedApiBase = ApiService.normalizeApiBase(ApiRuntime.stickyManualApiBase!);
      } else {
        ApiRuntime.resolvedApiBase = ApiService.platformDefaultBaseUrl();
      }
      ApiRuntime.healthCheckOk = false;
      ApiRuntime.bootstrapDetail = e.toString();
    } finally {
      ApiLog.debugResolvedApiBase(ApiService.baseUrl);
    }
  }

  static Future<void> saveManualApiBaseAndReinitialize(String raw) async {
    final prefs = await SharedPreferences.getInstance();
    var t = raw.trim();
    if (t.isEmpty) {
      await prefs.remove(_prefsKeyManualApi);
      ApiRuntime.stickyManualApiBase = null;
    } else {
      if (!_startsWithHttps(t)) {
        t = 'https://$t';
      }
      final u = Uri.tryParse(t);
      if (u == null || u.host.isEmpty) {
        throw FormatException(
          'Invalid HTTPS API origin. Example host: ${Uri.parse(ApiConfig.apiOrigin).host}',
        );
      }
      if (u.scheme != 'https') {
        throw FormatException('Only https:// API URLs are allowed.');
      }
      if (_isDisallowedStoredApiUrl(t)) {
        throw FormatException('This URL is not allowed. Use your production HTTPS API host.');
      }
      final afterScheme = t.contains('://') ? t.split('://')[1] : t;
      final authority = afterScheme.split('/')[0];
      if (!authority.contains(':')) {
        t = 'https://${u.host}';
      }
      final normalized = ApiService.normalizeApiBase(t);
      await prefs.setString(_prefsKeyManualApi, normalized);
      ApiRuntime.stickyManualApiBase = normalized;
    }
    ApiRuntime.resolvedApiBase = null;
    await initialize();
  }

  static Future<void> clearManualApiBaseAndReinitialize() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKeyManualApi);
    ApiRuntime.stickyManualApiBase = null;
    ApiRuntime.resolvedApiBase = null;
    await initialize();
  }

  static Future<void> clearCachedApiBaseAndReinitialize() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKeyApiBase);
    ApiRuntime.resolvedApiBase = null;
    await initialize();
  }

  static Future<void> recheckHealth() async {
    final base = ApiService.baseUrl;
    final origin = ApiService.originFromApiBase(base);
    final ok = await ApiHealth.reachable(origin);
    ApiRuntime.healthCheckOk = ok;
    if (ok) {
      ApiRuntime.bootstrapDetail = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKeyApiBase, base);
    } else {
      ApiLog.apiFailure('ApiBootstrap.recheckHealth failed $origin/health');
      ApiRuntime.bootstrapDetail =
          'Still unreachable at $origin/health. Check internet, DNS, and Railway.\n\n'
          'Rebuild with a different base if needed: --dart-define=API_BASE_URL=<https-url>/api';
    }
  }

  static Future<String> _resolveBaseUrl() async {
    if (ApiRuntime.stickyManualApiBase != null && ApiRuntime.stickyManualApiBase!.isNotEmpty) {
      return ApiService.normalizeApiBase(ApiRuntime.stickyManualApiBase!);
    }

    final prefs = await SharedPreferences.getInstance();

    if (kIsWeb || _isDesktop()) {
      return ApiService.platformDefaultBaseUrl();
    }

    final cached = prefs.getString(_prefsKeyApiBase)?.trim();
    if (cached != null && cached.isNotEmpty && !_isDisallowedStoredApiUrl(cached)) {
      return ApiService.normalizeApiBase(cached);
    }

    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      return ApiService.mobileBootstrapDefaultBase();
    }

    return ApiService.platformDefaultBaseUrl();
  }

  static bool _isDesktop() {
    return defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }
}
