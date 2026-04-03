import 'package:flutter/foundation.dart';

/// AdMob is supported on Android and iOS builds only.
bool get supportsMobileAds =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);
