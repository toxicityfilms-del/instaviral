/// Production API — single source of truth for the default REST base.
///
/// All HTTP clients must use [ApiService.baseUrl], which resolves from
/// `String.fromEnvironment('API_BASE_URL', defaultValue: ApiConfig.apiBaseUrl)`.
///
/// Override at build time (HTTPS only):
/// `flutter build apk --dart-define=API_BASE_URL=https://other.example.com/api`
abstract final class ApiConfig {
  ApiConfig._();

  /// Live Railway backend (HTTPS). Health: `{apiOrigin}/health`. REST: `{apiOrigin}/api`.
  static const String apiOrigin =
      'https://reelboost-backend-production.up.railway.app';

  /// Default REST base (`{apiOrigin}/api`).
  static const String apiBaseUrl = '$apiOrigin/api';
}
