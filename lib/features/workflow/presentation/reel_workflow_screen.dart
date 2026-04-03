import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reelboost_ai/core/l10n/app_strings.dart';
import 'package:reelboost_ai/core/theme/app_theme.dart';
import 'package:reelboost_ai/features/analyze_media/presentation/analyze_media_screen.dart';
import 'package:reelboost_ai/features/caption/presentation/caption_screen.dart';
import 'package:reelboost_ai/features/hashtag/presentation/hashtag_screen.dart';
import 'package:reelboost_ai/features/ideas/presentation/ideas_screen.dart';
import 'package:reelboost_ai/features/post_analyzer/presentation/upload_post_screen.dart';
import 'package:reelboost_ai/features/profile/presentation/profile_screen.dart';
import 'package:reelboost_ai/widgets/app_card.dart';

/// Ordered path from profile → ideas → copy → analyzers (clarifies Post vs Media).
class ReelWorkflowScreen extends ConsumerWidget {
  const ReelWorkflowScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(s.workflowAppBar)),
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.scaffoldGradient(context)),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              AppCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline_rounded, color: AppTheme.accent.withValues(alpha: 0.95)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            s.workflowTwoAnalyzers,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      s.analyzeMediaCompareTitle,
                      style: TextStyle(color: AppTheme.onCardSecondary(context), height: 1.45),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                s.workflowSuggestedOrder,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              _WorkflowStepTile(
                step: 1,
                title: s.workflowStepProfile,
                subtitle: s.workflowStepProfileSub,
                icon: Icons.person_rounded,
                color: const Color(0xFF7C4DFF),
                onTap: () => Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
                ),
              ),
              _WorkflowStepTile(
                step: 2,
                title: s.workflowStepIdeas,
                subtitle: s.workflowStepIdeasSub,
                icon: Icons.lightbulb_outline_rounded,
                color: const Color(0xFF4CAF50),
                onTap: () => Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(builder: (_) => const IdeasScreen()),
                ),
              ),
              _WorkflowStepTile(
                step: 3,
                title: s.workflowStepCaption,
                subtitle: s.workflowStepCaptionSub,
                icon: Icons.edit_note_rounded,
                color: const Color(0xFF00BCD4),
                onTap: () => Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(builder: (_) => const CaptionScreen()),
                ),
              ),
              _WorkflowStepTile(
                step: 4,
                title: s.workflowStepHashtags,
                subtitle: s.workflowStepHashtagsSub,
                icon: Icons.tag_rounded,
                color: const Color(0xFFAB47BC),
                onTap: () => Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(builder: (_) => const HashtagScreen()),
                ),
              ),
              _WorkflowStepTile(
                step: 5,
                title: s.workflowStepPostAnalyzer,
                subtitle: s.workflowStepPostAnalyzerSub,
                icon: Icons.image_search_rounded,
                color: const Color(0xFFE91E63),
                onTap: () => Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(builder: (_) => const UploadPostScreen()),
                ),
              ),
              _WorkflowStepTile(
                step: 6,
                title: s.workflowStepMedia,
                subtitle: s.workflowStepMediaSub,
                icon: Icons.auto_awesome_mosaic_rounded,
                color: const Color(0xFF26A69A),
                onTap: () => Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(builder: (_) => const AnalyzeMediaScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkflowStepTile extends StatelessWidget {
  const _WorkflowStepTile({
    required this.step,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final int step;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.45)),
              ),
              child: Text(
                '$step',
                style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 16),
              ),
            ),
            const SizedBox(width: 14),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15.5,
                      color: AppTheme.onCardPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 4),
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
            ),
            Icon(Icons.chevron_right_rounded, color: AppTheme.onCardSecondary(context)),
          ],
        ),
      ),
    );
  }
}
