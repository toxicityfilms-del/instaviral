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

String primaryCaptionForCompare(PostAnalysisResult r) {
  final cap = r.improvedCaption.trim().isNotEmpty ? r.improvedCaption : r.caption;
  return cap.trim();
}

String hookLine(PostAnalysisResult r) => r.hook.trim();

String tipsSummary(PostAnalysisResult r) {
  final n = r.engagementTips.where((e) => e.trim().isNotEmpty).length;
  return '$n';
}
