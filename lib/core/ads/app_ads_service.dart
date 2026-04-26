import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:reelboost_ai/core/ads/ad_policy.dart';
import 'package:reelboost_ai/core/ads/ad_unit_ids.dart';
import 'package:reelboost_ai/core/ads/ads_support.dart';
import 'package:reelboost_ai/models/user_model.dart';

/// Loads and shows interstitial / rewarded ads (no-op on unsupported platforms).
abstract final class AppAdsService {
  static Future<void> ensureInitialized() async {
    if (!supportsMobileAds) return;
    if (!AdUnitIds.adsEnabledForCurrentBuild) {
      assert(() {
        debugPrint(
          'TODO(AdMob): Release build missing ADMOB_* dart-defines — ads will not load. '
          'Set ADMOB_BANNER_ID, ADMOB_INTERSTITIAL_ID, ADMOB_REWARDED_ID and ADMOB_APP_ID (Android).',
        );
        return true;
      }());
      return;
    }
    try {
      await MobileAds.instance.initialize();
      if (kDebugMode) {
        await MobileAds.instance.updateRequestConfiguration(
          RequestConfiguration(testDeviceIds: <String>[]),
        );
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('MobileAds init failed: $e\n$st');
      }
    }
  }

  /// Returns true if the user finished the ad and earned the reward.
  /// Free users only; premium users never see rewarded ads here.
  static Future<bool> showRewardedForBonus({UserModel? user}) async {
    if (!AdPolicy.showAds(user)) return false;
    if (!supportsMobileAdsForBuild) return false;
    final completer = Completer<bool>();
    var earned = false;
    RewardedAd.load(
      adUnitId: AdUnitIds.rewarded,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (AdWithoutView a) {
              a.dispose();
              if (!completer.isCompleted) {
                completer.complete(earned);
              }
            },
            onAdFailedToShowFullScreenContent: (AdWithoutView a, AdError e) {
              a.dispose();
              if (!completer.isCompleted) completer.complete(false);
            },
          );
          ad.show(
            onUserEarnedReward: (AdWithoutView a, RewardItem r) {
              earned = true;
            },
          );
        },
        onAdFailedToLoad: (LoadAdError e) {
          if (!completer.isCompleted) completer.complete(false);
        },
      ),
    );
    return completer.future;
  }

  /// Shows an interstitial if [load] succeeded (caller loads first).
  static Future<void> showInterstitial(InterstitialAd ad) async {
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (InterstitialAd a) => a.dispose(),
      onAdFailedToShowFullScreenContent: (InterstitialAd a, AdError e) => a.dispose(),
    );
    await ad.show();
  }

  static Future<InterstitialAd?> loadInterstitial() async {
    if (!supportsMobileAdsForBuild) return null;
    final completer = Completer<InterstitialAd?>();
    InterstitialAd.load(
      adUnitId: AdUnitIds.interstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) => completer.complete(ad),
        onAdFailedToLoad: (LoadAdError e) => completer.complete(null),
      ),
    );
    return completer.future;
  }
}
