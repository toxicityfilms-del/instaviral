import 'package:reelboost_ai/core/config/api_config.dart';
import 'package:reelboost_ai/services/api_runtime.dart';

/// Resolves the REST base URL for Dio ([ApiClient]).
///
/// Resolution order: runtime cache → manual HTTPS override (prefs) →
/// [platformDefaultBaseUrl] ([ApiConfig.apiBaseUrl]).
///
/// Compile-time default is [ApiConfig.apiBaseUrl] via:
/// `const String.fromEnvironment('API_BASE_URL', defaultValue: ApiConfig.apiBaseUrl)`.
class ApiService {
  ApiService._();

  static const String _fromEnv = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: ApiConfig.apiBaseUrl,
  );

  static String get apiBaseFromEnvironment => normalizeApiBase(_fromEnv.trim());

  static bool get usesCompileTimeDefaultApiBase {
    return normalizeApiBase(_fromEnv.trim()) ==
        normalizeApiBase(ApiConfig.apiBaseUrl);
  }

  static String mobileBootstrapDefaultBase() => apiBaseFromEnvironment;

  static String get baseUrl {
    final runtime = ApiRuntime.resolvedApiBase;
    if (runtime != null && runtime.isNotEmpty) {
      return normalizeApiBase(runtime);
    }
    final manual = ApiRuntime.stickyManualApiBase;
    if (manual != null && manual.isNotEmpty) {
      return normalizeApiBase(manual);
    }
    return platformDefaultBaseUrl();
  }

  /// Production default — always [ApiConfig.apiBaseUrl] (HTTPS Railway).
  static String platformDefaultBaseUrl() => normalizeApiBase(ApiConfig.apiBaseUrl);

  /// Single `/api` suffix; coerces `http` → `https`; rejects non-HTTPS results.
  static String normalizeApiBase(String input) {
    var s = input.trim().replaceAll(RegExp(r'/+$'), '');
    if (s.toLowerCase().startsWith('http://')) {
      s = 'https://${s.substring('http://'.length)}';
    }
    while (s.endsWith('/api')) {
      s = s.substring(0, s.length - 4);
      s = s.replaceAll(RegExp(r'/+$'), '');
    }
    final out = '$s/api';
    final u = Uri.tryParse(out);
    if (u == null || u.scheme != 'https') {
      return normalizeApiBase(ApiConfig.apiBaseUrl);
    }
    return out;
  }

  static String originFromApiBase(String apiBase) {
    final s = normalizeApiBase(apiBase);
    if (s.endsWith('/api')) {
      return s.substring(0, s.length - 4);
    }
    return s;
  }
}
