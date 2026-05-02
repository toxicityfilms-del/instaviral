import 'package:reelboost_ai/models/post_analysis_models.dart';

/// Score delta and optional relative change vs previous analysis.
class AnalysisScoreComparison {
  const AnalysisScoreComparison({
    required this.beforeScore,
    required this.afterScore,
  });

  final int beforeScore;
  final int afterScore;

  int get delta => afterScore - beforeScore;

  /// Percent change relative to [beforeScore]; null if previous score was 0.
  double? get relativePercentVsBefore {
    if (beforeScore <= 0) return null;
    return ((afterScore - beforeScore) / beforeScore) * 100;
  }
}

AnalysisScoreComparison compareScores(PostAnalysisResult before, PostAnalysisResult after) {
  return AnalysisScoreComparison(
    beforeScore: before.score,
    afterScore: after.score,
  );
}

/// Same formatting as the comparison share PNG headline row (+18%, +5%, −3%, …).
String formatComparisonImprovementDisplay(PostAnalysisResult before, PostAnalysisResult after) {
  final cmp = compareScores(before, after);
  final rel = cmp.relativePercentVsBefore;
  return rel != null
      ? '${cmp.delta >= 0 ? '+' : ''}${rel.toStringAsFixed(0)}%'
      : '${cmp.delta >= 0 ? '+' : ''}${cmp.delta}%';
}

String primaryCaptionForCompare(PostAnalysisResult r) {
  final cap = r.improvedCaption.trim().isNotEmpty ? r.improvedCaption : r.caption;
  return cap.trim();
}

String hookLine(PostAnalysisResult r) => r.hook.trim();

String tipsSummary(PostAnalysisResult r) {
  final n = r.engagementTips.where((e) => e.trim().isNotEmpty).length;
  return '$n';
}
