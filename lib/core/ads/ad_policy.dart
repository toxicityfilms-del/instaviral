import 'package:reelboost_ai/models/user_model.dart';

/// Rules: **free** users see monetization ads and server-enforced usage limits;
/// **premium** users see **no** ads and get **unlimited** post analysis (and no daily cap).
///
/// Use these helpers on every screen that shows ads or gates features on the free tier
/// so conditions stay aligned with the backend.
abstract final class AdPolicy {
  /// Whether to show banner / interstitial ads (logged-in free users only).
  static bool showAds(UserModel? user) => user != null && !user.isPremium;

  /// Premium subscribers — no usage caps for post-analyze, no monetization ads.
  static bool isPremium(UserModel? user) => user?.isPremium == true;

  /// Free tier: apply daily post-analyze limits (client UI + [assertPostAnalyzeAllowed] on server).
  static bool enforcePostAnalyzeLimits(UserModel? user) => user != null && !user.isPremium;

  /// Rewarded “+1 analysis” is only for free users who can still earn ad bonuses today.
  static bool showRewardedPostAnalyzeOption(UserModel? user) {
    if (!showAds(user)) return false;
    return (user!.postAnalyzeAdRewardsRemaining ?? 0) > 0;
  }
}
