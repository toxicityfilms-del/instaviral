import 'package:flutter/material.dart';
import 'package:reelboost_ai/core/l10n/app_strings.dart';
import 'package:reelboost_ai/core/theme/app_theme.dart';
import 'package:reelboost_ai/core/utils/analysis_comparison.dart';
import 'package:reelboost_ai/models/post_analysis_models.dart';

/// Before vs after analysis: score improvement % and key suggestion fields.
class AnalysisComparisonPanel extends StatelessWidget {
  const AnalysisComparisonPanel({
    super.key,
    required this.before,
    required this.after,
    required this.strings,
    required this.showPremiumSuggestionFields,
    required this.onShareComparison,
  });

  final PostAnalysisResult before;
  final PostAnalysisResult after;
  final AppStrings strings;
  final bool showPremiumSuggestionFields;
  final VoidCallback onShareComparison;

  static const Color _positiveGreen = Color(0xFF4ADE80);
  static const Color _negativeRed = Color(0xFFF87171);

  static String _clip(String s, {int max = 140}) {
    final t = s.trim();
    if (t.isEmpty) return '—';
    if (t.length <= max) return t;
    return '${t.substring(0, max)}…';
  }

  @override
  Widget build(BuildContext context) {
    final cmp = compareScores(before, after);
    final rel = cmp.relativePercentVsBefore;
    final fg = AppTheme.onCardPrimary(context);
    final muted = AppTheme.onCardSecondary(context);

    final isPositive = cmp.delta > 0;
    final isNegative = cmp.delta < 0;
    final deltaZero = cmp.delta == 0;

    // Headline always uses "%" so copy matches "🚀 … +XX%". When last score was 0,
    // [relativePercentVsBefore] is null — delta is shown as score points on the /100 scale.
    final amountDisplay = rel != null
        ? '${cmp.delta >= 0 ? '+' : ''}${rel.toStringAsFixed(0)}%'
        : '${cmp.delta >= 0 ? '+' : ''}${cmp.delta}%';

    final Color metricColor = isPositive
        ? _positiveGreen
        : isNegative
            ? _negativeRed
            : muted;

    final headline = deltaZero
        ? strings.comparisonScoreFlatHeadline
        : isPositive
            ? strings.comparisonImproveHeadline(amountDisplay)
            : strings.comparisonDeclineHeadline(amountDisplay);

    final String metricSubtitle = rel != null ? strings.comparisonVsLast : strings.comparisonPointsVsLast;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: isPositive
              ? [
                  const Color(0x4022C55E),
                  AppTheme.accent2.withValues(alpha: 0.1),
                ]
              : [
                  AppTheme.accent.withValues(alpha: 0.22),
                  AppTheme.accent2.withValues(alpha: 0.12),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: isPositive ? const Color(0x774ADE80) : Colors.white.withValues(alpha: 0.12),
          width: isPositive ? 1.5 : 1,
        ),
        boxShadow: isPositive
            ? [
                BoxShadow(
                  color: const Color(0x5522C55E),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
                ...AppTheme.cardShadow,
              ]
            : AppTheme.cardShadow,
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.compare_arrows_rounded, color: AppTheme.accent2.withValues(alpha: 0.95), size: 26),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  strings.comparisonTitle,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: fg,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _ComparisonImprovementHero(
            text: headline,
            color: metricColor,
            subtlePulse: isPositive && !deltaZero,
            compact: deltaZero,
          ),
          if (isPositive && !deltaZero) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF15803D), Color(0xFF22C55E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
                  boxShadow: [
                    BoxShadow(
                      color: _positiveGreen.withValues(alpha: 0.45),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  strings.comparisonImprovedBadge,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: 0.2,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            metricSubtitle,
            style: TextStyle(color: muted, fontSize: 13, height: 1.3),
          ),
          const SizedBox(height: 14),
          _ComparisonSharePreviewCard(
            before: before,
            after: after,
            strings: strings,
            muted: muted,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onShareComparison,
              icon: const Icon(Icons.share_rounded, size: 20),
              label: Text(strings.actionShareComparisonResult),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.accent2.withValues(alpha: 0.95),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _ComparePairRow(
            strings: strings,
            label: strings.comparisonViralScore,
            before: '${before.score}',
            after: '${after.score}',
            fg: fg,
            muted: muted,
            highlightAfter: isPositive,
          ),
          if (showPremiumSuggestionFields) ...[
            const SizedBox(height: 12),
            _ComparePairRow(
              strings: strings,
              label: strings.comparisonHook,
              before: _clip(hookLine(before)),
              after: _clip(hookLine(after)),
              fg: fg,
              muted: muted,
            ),
            const SizedBox(height: 12),
            _ComparePairRow(
              strings: strings,
              label: strings.comparisonCaption,
              before: _clip(primaryCaptionForCompare(before)),
              after: _clip(primaryCaptionForCompare(after)),
              fg: fg,
              muted: muted,
            ),
          ],
          const SizedBox(height: 12),
          _ComparePairRow(
            strings: strings,
            label: strings.viralBestTimeTitle,
            before: _clip(before.bestTime.trim().isEmpty ? '—' : before.bestTime.trim()),
            after: _clip(after.bestTime.trim().isEmpty ? '—' : after.bestTime.trim()),
            fg: fg,
            muted: muted,
          ),
          const SizedBox(height: 12),
          _ComparePairRow(
            strings: strings,
            label: strings.viralAudioSuggestionTitle,
            before: _clip(before.audio.trim().isEmpty ? '—' : before.audio.trim()),
            after: _clip(after.audio.trim().isEmpty ? '—' : after.audio.trim()),
            fg: fg,
            muted: muted,
          ),
          if (showPremiumSuggestionFields) ...[
            const SizedBox(height: 12),
            _ComparePairRow(
              strings: strings,
              label: strings.comparisonTipsCount,
              before: tipsSummary(before),
              after: tipsSummary(after),
              fg: fg,
              muted: muted,
            ),
          ],
        ],
      ),
    );
  }
}

/// Mirrors the PNG built in [renderComparisonSharePng] (before / after / improvement).
class _ComparisonSharePreviewCard extends StatelessWidget {
  const _ComparisonSharePreviewCard({
    required this.before,
    required this.after,
    required this.strings,
    required this.muted,
  });

  final PostAnalysisResult before;
  final PostAnalysisResult after;
  final AppStrings strings;
  final Color muted;

  static const Color _positiveGreen = Color(0xFF4ADE80);
  static const Color _negativeRed = Color(0xFFF87171);

  @override
  Widget build(BuildContext context) {
    final cmp = compareScores(before, after);
    final isPositive = cmp.delta > 0;
    final isNegative = cmp.delta < 0;
    final improvement = formatComparisonImprovementDisplay(before, after);
    final impColor = isPositive
        ? _positiveGreen
        : isNegative
            ? _negativeRed
            : muted;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.07),
            AppTheme.accent.withValues(alpha: 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accent2.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            strings.comparisonSharePreviewTitle,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: muted,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _PreviewMetric(
                  label: strings.comparisonBefore,
                  value: '${before.score}',
                  alignEnd: false,
                  muted: muted,
                ),
              ),
              Container(
                width: 1,
                height: 52,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                color: Colors.white.withValues(alpha: 0.1),
              ),
              Expanded(
                child: _PreviewMetric(
                  label: strings.comparisonAfter,
                  value: '${after.score}',
                  alignEnd: true,
                  muted: muted,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Colors.white.withValues(alpha: 0.08)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                strings.comparisonShareImprovementLabel,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onCardPrimary(context).withValues(alpha: 0.88),
                ),
              ),
              Text(
                improvement,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  color: impColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PreviewMetric extends StatelessWidget {
  const _PreviewMetric({
    required this.label,
    required this.value,
    required this.alignEnd,
    required this.muted,
  });

  final String label;
  final String value;
  final bool alignEnd;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    final fg = AppTheme.onCardPrimary(context);
    return Column(
      crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: muted),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            height: 1.05,
            color: fg.withValues(alpha: 0.96),
          ),
        ),
      ],
    );
  }
}

class _ComparisonImprovementHero extends StatefulWidget {
  const _ComparisonImprovementHero({
    required this.text,
    required this.color,
    required this.subtlePulse,
    required this.compact,
  });

  final String text;
  final Color color;
  final bool subtlePulse;
  final bool compact;

  @override
  State<_ComparisonImprovementHero> createState() => _ComparisonImprovementHeroState();
}

class _ComparisonImprovementHeroState extends State<_ComparisonImprovementHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );
    if (widget.subtlePulse) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_ComparisonImprovementHero oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.subtlePulse) {
      if (!_controller.isAnimating) {
        _controller.repeat(reverse: true);
      }
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = widget.compact
        ? 20.0
        : widget.subtlePulse
            ? 34.0
            : 26.0;
    final letter = widget.compact ? -0.2 : -0.55;

    List<Shadow> shadowsFor(double glowT) {
      if (widget.compact) {
        return [];
      }
      if (widget.subtlePulse) {
        return [
          Shadow(
            color: const Color(0xFF4ADE80).withValues(alpha: 0.38 + glowT * 0.2),
            blurRadius: 18 + glowT * 16,
            offset: const Offset(0, 4),
          ),
          Shadow(
            color: const Color(0xFF22C55E).withValues(alpha: 0.22 + glowT * 0.14),
            blurRadius: 26 + glowT * 12,
            offset: Offset(0, 7 + glowT * 2),
          ),
          Shadow(
            color: const Color(0xFF86EFAC).withValues(alpha: 0.12 + glowT * 0.1),
            blurRadius: 32 + glowT * 8,
            offset: const Offset(0, 0),
          ),
          Shadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ];
      }
      return [
        Shadow(
          color: widget.color.withValues(alpha: 0.35),
          blurRadius: 12,
          offset: const Offset(0, 3),
        ),
        Shadow(
          color: Colors.black.withValues(alpha: 0.35),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];
    }

    final textStyle = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w900,
      height: 1.18,
      color: widget.color,
      letterSpacing: letter,
    );

    if (!widget.subtlePulse) {
      return Text(
        widget.text,
        style: textStyle.copyWith(shadows: shadowsFor(0)),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_controller.value);
        final scale = 1.0 + t * 0.018;
        return Transform.scale(
          scale: scale,
          alignment: Alignment.centerLeft,
          child: Text(
            widget.text,
            style: textStyle.copyWith(shadows: shadowsFor(t)),
          ),
        );
      },
    );
  }
}

class _ComparePairRow extends StatelessWidget {
  const _ComparePairRow({
    required this.strings,
    required this.label,
    required this.before,
    required this.after,
    required this.fg,
    required this.muted,
    this.highlightAfter = false,
  });

  final AppStrings strings;
  final String label;
  final String before;
  final String after;
  final Color fg;
  final Color muted;
  final bool highlightAfter;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 12,
            letterSpacing: 0.3,
            color: muted,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _Cell(
                tag: strings.comparisonBefore,
                text: before,
                fg: fg,
                muted: muted,
                alignEnd: false,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Cell(
                tag: strings.comparisonAfter,
                text: after,
                fg: fg,
                muted: muted,
                alignEnd: true,
                accentPositive: highlightAfter,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.tag,
    required this.text,
    required this.fg,
    required this.muted,
    required this.alignEnd,
    this.accentPositive = false,
  });

  final String tag;
  final String text;
  final Color fg;
  final Color muted;
  final bool alignEnd;
  final bool accentPositive;

  @override
  Widget build(BuildContext context) {
    final borderColor = accentPositive ? const Color(0x554ADE80) : Colors.white.withValues(alpha: 0.08);
    final fill = accentPositive ? const Color(0x1822C55E) : Colors.white.withValues(alpha: 0.06);

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: fill,
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(tag, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: muted)),
          const SizedBox(height: 4),
          Text(
            text,
            textAlign: alignEnd ? TextAlign.right : TextAlign.left,
            style: TextStyle(
              color: accentPositive ? const Color(0xFFBEF264) : fg,
              height: 1.35,
              fontSize: 13,
              fontWeight: accentPositive ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
