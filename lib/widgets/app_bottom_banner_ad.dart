import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:reelboost_ai/core/ads/ad_unit_ids.dart';
import 'package:reelboost_ai/core/ads/ads_support.dart';

/// Anchored banner fixed height; shows nothing when ads unsupported or [show] is false.
/// Pass `show: AdPolicy.showAds(user)` from the home screen so premium users never see ads.
class AppBottomBannerAd extends StatefulWidget {
  const AppBottomBannerAd({super.key, required this.show});

  final bool show;

  @override
  State<AppBottomBannerAd> createState() => _AppBottomBannerAdState();
}

class _AppBottomBannerAdState extends State<AppBottomBannerAd> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    if (widget.show && supportsMobileAds) {
      _load();
    }
  }

  @override
  void didUpdateWidget(covariant AppBottomBannerAd oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.show && !oldWidget.show && supportsMobileAds) {
      _load();
    }
    if (!widget.show && oldWidget.show) {
      _disposeAd();
    }
  }

  void _load() {
    _disposeAd();
    final ad = BannerAd(
      adUnitId: AdUnitIds.banner,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (mounted) setState(() => _loaded = false);
        },
      ),
    );
    ad.load();
    _ad = ad;
  }

  void _disposeAd() {
    _ad?.dispose();
    _ad = null;
    _loaded = false;
  }

  @override
  void dispose() {
    _disposeAd();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.show || !supportsMobileAds || _ad == null) {
      return const SizedBox.shrink();
    }
    final h = _loaded ? _ad!.size.height.toDouble() : AdSize.banner.height.toDouble();
    return Material(
      color: Colors.black.withValues(alpha: 0.35),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: h,
          width: double.infinity,
          child: _loaded ? AdWidget(ad: _ad!) : const SizedBox.shrink(),
        ),
      ),
    );
  }
}
