import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reelboost_ai/core/analytics/local_analytics.dart';
import 'package:reelboost_ai/core/l10n/app_strings.dart';
import 'package:reelboost_ai/core/providers/app_providers.dart';
import 'package:reelboost_ai/core/theme/app_theme.dart';
import 'package:reelboost_ai/features/checklist/presentation/publish_checklist_screen.dart';
import 'package:reelboost_ai/features/caption/presentation/caption_screen.dart';
import 'package:reelboost_ai/features/hashtag/presentation/hashtag_screen.dart';
import 'package:reelboost_ai/features/ideas/presentation/ideas_screen.dart';
import 'package:reelboost_ai/features/trends/presentation/trends_screen.dart';
import 'package:reelboost_ai/features/post_analyzer/presentation/upload_post_screen.dart';
import 'package:reelboost_ai/features/analyze_media/presentation/analyze_media_screen.dart';
import 'package:reelboost_ai/features/profile/presentation/profile_screen.dart';
import 'package:reelboost_ai/features/viral_score/presentation/viral_score_screen.dart';
import 'package:reelboost_ai/features/workflow/presentation/reel_workflow_screen.dart';
import 'package:reelboost_ai/features/history/presentation/analysis_history_screen.dart';
import 'package:reelboost_ai/core/ads/ad_policy.dart';
import 'package:reelboost_ai/core/ads/home_interstitial.dart';
import 'package:reelboost_ai/widgets/api_status_banner.dart';
import 'package:reelboost_ai/widgets/app_bottom_banner_ad.dart';
import 'package:reelboost_ai/widgets/app_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const String _seenAnalyzeMediaKey = 'seen_analyze_media_feature';
  bool _seenAnalyzeMedia = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authControllerProvider).asData?.value;
      maybeShowHomeInterstitial(user);
      LocalAnalytics.log(ref, 'screen_home');
    });
    _loadSeenAnalyzeMedia();
  }

  Future<void> _loadSeenAnalyzeMedia() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool(_seenAnalyzeMediaKey) ?? false;
    if (!mounted) return;
    setState(() => _seenAnalyzeMedia = seen);
  }

  Future<void> _openAnalyzeMedia(BuildContext context) async {
    if (!_seenAnalyzeMedia) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_seenAnalyzeMediaKey, true);
      if (mounted) setState(() => _seenAnalyzeMedia = true);
    }
    if (!context.mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const AnalyzeMediaScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final scheme = Theme.of(context).colorScheme;
    final auth = ref.watch(authControllerProvider);
    final user = auth.asData?.value;
    final displayName = user == null
        ? s.creatorFallback
        : (user.name.isNotEmpty ? user.name : user.email);
    final subtitle = user != null && user.name.isNotEmpty ? user.email : null;

    final showBannerAd = AdPolicy.showAds(user);

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(gradient: AppTheme.scaffoldGradient(context)),
              child: SafeArea(
                bottom: false,
                child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.appTitle,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            Text(
                              displayName,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            if (subtitle != null && subtitle.isNotEmpty)
                              Text(
                                subtitle,
                                style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.55), fontSize: 13),
                              ),
                          ],
                        ),
                      ),
                      IconButton.filledTonal(
                        tooltip: s.profileTooltip,
                        style: IconButton.styleFrom(
                          backgroundColor: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
                          foregroundColor: scheme.onSurface.withValues(alpha: 0.9),
                        ),
                        onPressed: () {
                          Navigator.of(context).push<void>(
                            MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
                          );
                        },
                        icon: const Icon(Icons.person_rounded),
                      ),
                      IconButton.filledTonal(
                        tooltip: s.logoutTooltip,
                        style: IconButton.styleFrom(
                          backgroundColor: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
                          foregroundColor: scheme.onSurface.withValues(alpha: 0.9),
                        ),
                        onPressed: () async {
                          await ref.read(authControllerProvider.notifier).logout();
                        },
                        icon: const Icon(Icons.logout_rounded),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                  child: const ApiStatusBanner(),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                sliver: SliverToBoxAdapter(
                  child: AppCard(
                    padding: const EdgeInsets.all(22),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: AppTheme.primaryGradient,
                            boxShadow: AppTheme.buttonShadow,
                          ),
                          child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 26),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.growthCockpitTitle,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                s.growthCockpitBody,
                                style: TextStyle(
                                  color: AppTheme.onCardSecondary(context),
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: AppCard(
                          onTap: () => Navigator.of(context).push<void>(
                            MaterialPageRoute<void>(builder: (_) => const ReelWorkflowScreen()),
                          ),
                          padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF5C6BC0).withValues(alpha: 0.22),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFF5C6BC0).withValues(alpha: 0.35)),
                                ),
                                child: const Icon(Icons.route_rounded, color: Color(0xFF9FA8DA), size: 20),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      s.shortcutWorkflow,
                                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, height: 1.2),
                                      maxLines: 2,
                                      softWrap: true,
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      s.shortcutWorkflowSub,
                                      style: TextStyle(
                                        color: AppTheme.onCardSecondary(context),
                                        fontSize: 11,
                                        height: 1.25,
                                      ),
                                      maxLines: 2,
                                      softWrap: true,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppCard(
                          onTap: () => Navigator.of(context).push<void>(
                            MaterialPageRoute<void>(builder: (_) => const AnalysisHistoryScreen()),
                          ),
                          padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF7043).withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFFF7043).withValues(alpha: 0.35)),
                                ),
                                child: const Icon(Icons.history_rounded, color: Color(0xFFFFAB91), size: 20),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      s.shortcutSaved,
                                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, height: 1.2),
                                      maxLines: 2,
                                      softWrap: true,
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      s.shortcutSavedSub,
                                      style: TextStyle(
                                        color: AppTheme.onCardSecondary(context),
                                        fontSize: 11,
                                        height: 1.25,
                                      ),
                                      maxLines: 2,
                                      softWrap: true,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.05,
                  ),
                  delegate: SliverChildListDelegate(
                    [
                      _FeatureTile(
                        icon: Icons.tag_rounded,
                        title: s.tileHashtags,
                        subtitle: s.tileHashtagsSub,
                        color: const Color(0xFF7C4DFF),
                        onTap: () => Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(builder: (_) => const HashtagScreen()),
                        ),
                      ),
                      _FeatureTile(
                        icon: Icons.edit_note_rounded,
                        title: s.tileCaption,
                        subtitle: s.tileCaptionSub,
                        color: const Color(0xFF00BCD4),
                        onTap: () => Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(builder: (_) => const CaptionScreen()),
                        ),
                      ),
                      _FeatureTile(
                        icon: Icons.trending_up_rounded,
                        title: s.tileTrends,
                        subtitle: s.tileTrendsSub,
                        color: const Color(0xFFFF9800),
                        onTap: () => Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(builder: (_) => const TrendsScreen()),
                        ),
                      ),
                      _FeatureTile(
                        icon: Icons.lightbulb_outline_rounded,
                        title: s.tileIdeas,
                        subtitle: s.tileIdeasSub,
                        color: const Color(0xFF4CAF50),
                        onTap: () => Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(builder: (_) => const IdeasScreen()),
                        ),
                      ),
                      _FeatureTile(
                        icon: Icons.analytics_rounded,
                        title: s.tileViralScore,
                        subtitle: s.tileViralScoreSub,
                        color: const Color(0xFFE91E63),
                        onTap: () => Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(builder: (_) => const ViralScoreScreen()),
                        ),
                      ),
                      _FeatureTile(
                        icon: Icons.checklist_rtl_rounded,
                        title: s.tileChecklist,
                        subtitle: s.tileChecklistSub,
                        color: const Color(0xFF78909C),
                        onTap: () => Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(builder: (_) => const PublishChecklistScreen()),
                        ),
                      ),
                      _FeatureTile(
                        icon: Icons.image_search_rounded,
                        title: s.tilePostAnalyzer,
                        subtitle: s.tilePostAnalyzerSub,
                        color: const Color(0xFFAB47BC),
                        onTap: () => Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(builder: (_) => const UploadPostScreen()),
                        ),
                      ),
                      _FeatureTile(
                        icon: Icons.auto_awesome_mosaic_rounded,
                        title: s.tileAnalyzeMedia,
                        subtitle: s.tileAnalyzeMediaSub,
                        color: const Color(0xFF26A69A),
                        badgeText: _seenAnalyzeMedia ? null : s.badgeNew,
                        onTap: () => _openAnalyzeMedia(context),
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
                ),
              ),
            ),
          ),
          AppBottomBannerAd(show: showBannerAd),
        ],
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.badgeText,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final String? badgeText;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withValues(alpha: 0.35)),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const Spacer(),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              letterSpacing: 0.1,
              color: AppTheme.onCardPrimary(context),
            ),
          ),
          if (badgeText != null && badgeText!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: _AnimatedNewBadge(label: badgeText!),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              color: AppTheme.onCardSecondary(context),
              fontSize: 12.5,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedNewBadge extends StatefulWidget {
  const _AnimatedNewBadge({required this.label});

  final String label;

  @override
  State<_AnimatedNewBadge> createState() => _AnimatedNewBadgeState();
}

class _AnimatedNewBadgeState extends State<_AnimatedNewBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final scale = 1.0 + (0.05 * t);
        final opacity = 0.82 + (0.18 * t);
        return Opacity(
          opacity: opacity,
          child: Transform.scale(scale: scale, alignment: Alignment.centerLeft, child: child),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFFFA726).withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFFFA726).withValues(alpha: 0.52)),
        ),
        child: Text(
          '🔥 ${widget.label}',
          style: const TextStyle(
            color: Color(0xFFFFCC80),
            fontWeight: FontWeight.w800,
            fontSize: 10.5,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}
