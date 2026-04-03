import 'package:flutter/foundation.dart' show kDebugMode;

/// Ad unit IDs.
///
/// - In **release**, these must be provided at build time via `--dart-define`:
///   - `ADMOB_BANNER_ID`
///   - `ADMOB_INTERSTITIAL_ID`
///   - `ADMOB_REWARDED_ID`
///
/// - In **debug**, Google test IDs are used as fallback.
abstract final class AdUnitIds {
  static const String _bannerFromEnv = String.fromEnvironment('ADMOB_BANNER_ID', defaultValue: '');
  static const String _interstitialFromEnv =
      String.fromEnvironment('ADMOB_INTERSTITIAL_ID', defaultValue: '');
  static const String _rewardedFromEnv = String.fromEnvironment('ADMOB_REWARDED_ID', defaultValue: '');

  static const String _testBanner = 'ca-app-pub-3940256099942544/6300978111';
  static const String _testInterstitial = 'ca-app-pub-3940256099942544/1033173712';
  static const String _testRewarded = 'ca-app-pub-3940256099942544/5224354917';

  static String get banner {
    final v = _bannerFromEnv.trim();
    if (v.isNotEmpty) return v;
    return kDebugMode ? _testBanner : '';
  }

  static String get interstitial {
    final v = _interstitialFromEnv.trim();
    if (v.isNotEmpty) return v;
    return kDebugMode ? _testInterstitial : '';
  }

  static String get rewarded {
    final v = _rewardedFromEnv.trim();
    if (v.isNotEmpty) return v;
    return kDebugMode ? _testRewarded : '';
  }

  static bool get isConfiguredForRelease =>
      !kDebugMode && banner.isNotEmpty && interstitial.isNotEmpty && rewarded.isNotEmpty;
}
