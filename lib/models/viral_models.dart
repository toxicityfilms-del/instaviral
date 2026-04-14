class ViralAnalysis {
  const ViralAnalysis({
    required this.score,
    required this.suggestions,
    this.niche,
    this.bestTime = '',
    this.audioSuggestion = '',
  });

  final int score;
  final List<String> suggestions;
  /// Echo of profile niche from request, or null if not sent.
  final String? niche;
  /// Posting-window hint derived from caption + hashtags (+ niche).
  final String bestTime;
  /// Audio direction derived from the same context.
  final String audioSuggestion;

  factory ViralAnalysis.fromJson(Map<String, dynamic> json) {
    return ViralAnalysis(
      score: (json['score'] as num?)?.round() ?? 0,
      suggestions:
          (json['suggestions'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      niche: json['niche'] as String?,
      bestTime: (json['bestTime'] as String? ?? json['best_time'] as String? ?? '').trim(),
      audioSuggestion:
          (json['audioSuggestion'] as String? ?? json['audio_suggestion'] as String? ?? '').trim(),
    );
  }
}
