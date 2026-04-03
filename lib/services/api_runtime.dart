/// Populated during API bootstrap before the app starts. The api service base URL uses the resolved base when set.
class ApiRuntime {
  ApiRuntime._();

  static String? resolvedApiBase;
  static bool healthCheckOk = true;
  static String? bootstrapDetail;

  /// User-entered base from prefs (loaded each [ApiBootstrap.initialize]).
  static String? stickyManualApiBase;

  /// Hot restart / tests when the runtime resolved base is null.
  static void seedForTest({required String baseUrl, bool healthOk = true}) {
    resolvedApiBase = baseUrl;
    healthCheckOk = healthOk;
    bootstrapDetail = null;
    stickyManualApiBase = null;
  }
}
