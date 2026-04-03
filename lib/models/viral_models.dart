class ViralAnalysis {
  const ViralAnalysis({
    required this.score,
    required this.suggestions,
  });

  final int score;
  final List<String> suggestions;

  factory ViralAnalysis.fromJson(Map<String, dynamic> json) {
    return ViralAnalysis(
      score: (json['score'] as num?)?.round() ?? 0,
      suggestions:
          (json['suggestions'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
    );
  }
}
