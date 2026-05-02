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
  });

  final PostAnalysisResult before;
  final PostAnalysisResult after;
  final AppStrings strings;
  final bool showPremiumSuggestionFields;

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

    final headline = rel != null
        ? '${cmp.delta >= 0 ? '+' : ''}${rel.toStringAsFixed(0)}% ${strings.comparisonVsLast}'
        : '${cmp.delta >= 0 ? '+' : ''}${cmp.delta} ${strings.comparisonPointsVsLast}';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: [
            AppTheme.accent.withValues(alpha: 0.22),
            AppTheme.accent2.withValues(alpha: 0.12),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: AppTheme.cardShadow,
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: cmp.delta >= 0 ? const Color(0x3322C55E) : const Color(0x33DC2626),
                  border: Border.all(
                    color: cmp.delta >= 0 ? const Color(0x554ADE80) : const Color(0x55F87171),
                  ),
                ),
                child: Text(
                  headline,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: cmp.delta >= 0 ? const Color(0xFF86EFAC) : const Color(0xFFF87171),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _ComparePairRow(
            strings: strings,
            label: strings.comparisonViralScore,
            before: '${before.score}',
            after: '${after.score}',
            fg: fg,
            muted: muted,
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

class _ComparePairRow extends StatelessWidget {
  const _ComparePairRow({
    required this.strings,
    required this.label,
    required this.before,
    required this.after,
    required this.fg,
    required this.muted,
  });

  final AppStrings strings;
  final String label;
  final String before;
  final String after;
  final Color fg;
  final Color muted;

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
  });

  final String tag;
  final String text;
  final Color fg;
  final Color muted;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withValues(alpha: 0.06),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(tag, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: muted)),
          const SizedBox(height: 4),
          Text(
            text,
            textAlign: alignEnd ? TextAlign.right : TextAlign.left,
            style: TextStyle(color: fg, height: 1.35, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
