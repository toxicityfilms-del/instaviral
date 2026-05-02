import 'package:flutter/material.dart';
import 'package:reelboost_ai/core/l10n/app_strings.dart';
import 'package:reelboost_ai/core/theme/app_theme.dart';

/// Eye-catching hint that the next analysis unlocks before/after comparison.
class FirstAnalysisInsightsBanner extends StatefulWidget {
  const FirstAnalysisInsightsBanner({
    super.key,
    required this.strings,
  });

  final AppStrings strings;

  @override
  State<FirstAnalysisInsightsBanner> createState() => _FirstAnalysisInsightsBannerState();
}

class _FirstAnalysisInsightsBannerState extends State<FirstAnalysisInsightsBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fg = AppTheme.onCardPrimary(context);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_controller.value);
        final glow = 0.35 + t * 0.45;
        final scale = 1.0 + t * 0.015;

        return Transform.scale(
          scale: scale,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                colors: [
                  AppTheme.accent.withValues(alpha: 0.18 + t * 0.08),
                  AppTheme.accent2.withValues(alpha: 0.14 + t * 0.06),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                width: 1.5,
                color: Color.lerp(
                  AppTheme.accent2.withValues(alpha: 0.55),
                  AppTheme.accent.withValues(alpha: 0.75),
                  t,
                )!,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accent2.withValues(alpha: glow * 0.45),
                  blurRadius: 14 + t * 10,
                  spreadRadius: t * 1.5,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: AppTheme.accent.withValues(alpha: glow * 0.25),
                  blurRadius: 20 + t * 8,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Row(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.28),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accent2.withValues(alpha: 0.35 + t * 0.2),
                          blurRadius: 10 + t * 6,
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.local_fire_department_rounded,
                        color: Color.lerp(
                          const Color(0xFFFF8A65),
                          const Color(0xFFFFAB40),
                          t,
                        ),
                        size: 26,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.strings.firstAnalysisInsightsHint,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            height: 1.35,
                            color: fg.withValues(alpha: 0.96),
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
