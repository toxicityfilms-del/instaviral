import 'package:flutter/foundation.dart';

import 'package:reelboost_ai/core/ads/ad_unit_ids.dart';

/// AdMob is supported on Android and iOS builds only.
bool get supportsMobileAds =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

/// Platform supports ads **and** this build has valid ad unit configuration (release requires dart-defines).
bool get supportsMobileAdsForBuild =>
    supportsMobileAds && AdUnitIds.adsEnabledForCurrentBuild;
