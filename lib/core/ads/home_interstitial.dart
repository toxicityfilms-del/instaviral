import 'package:reelboost_ai/core/ads/ad_policy.dart';
import 'package:reelboost_ai/core/ads/ads_support.dart';
import 'package:reelboost_ai/core/ads/app_ads_service.dart';
import 'package:reelboost_ai/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kHomeVisitCount = 'admob_home_visit_count_v1';

/// Shows a full-screen ad at most every 4th home visit (not on visits 1–3) for free users only.
Future<void> maybeShowHomeInterstitial(UserModel? user) async {
  if (!AdPolicy.showAds(user)) return;
  if (!supportsMobileAdsForBuild) return;
  final prefs = await SharedPreferences.getInstance();
  final n = (prefs.getInt(_kHomeVisitCount) ?? 0) + 1;
  await prefs.setInt(_kHomeVisitCount, n);
  if (n < 4 || n % 4 != 0) return;
  final ad = await AppAdsService.loadInterstitial();
  if (ad != null) {
    await AppAdsService.showInterstitial(ad);
  }
}
