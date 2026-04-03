class PostAnalyzeResponse {
  const PostAnalyzeResponse({
    required this.result,
    required this.isPremium,
    this.postAnalyzeLimit,
    this.postAnalyzeRemaining,
    this.postAnalyzeAdRewardsRemaining,
  });

  final PostAnalysisResult result;
  final bool isPremium;
  final int? postAnalyzeLimit;
  final int? postAnalyzeRemaining;
  final int? postAnalyzeAdRewardsRemaining;
}

class PostAnalysisResult {
  const PostAnalysisResult({
    required this.hook,
    required this.caption,
    required this.hashtags,
    required this.bestTime,
    required this.audio,
  });

  final String hook;
  final String caption;
  final List<String> hashtags;
  final String bestTime;
  final String audio;

  factory PostAnalysisResult.fromJson(Map<String, dynamic> json) {
    final raw = json['hashtags'];
    List<String> tags;
    if (raw is List) {
      tags = raw.map((e) => e.toString()).toList();
    } else if (raw is String) {
      tags = raw.split(RegExp(r'[\s,]+')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    } else {
      tags = [];
    }
    final audio = json['audio'] as String? ??
        json['trendingAudio'] as String? ??
        json['trending_audio'] as String? ??
        '';
    return PostAnalysisResult(
      hook: json['hook'] as String? ?? '',
      caption: json['caption'] as String? ?? '',
      hashtags: tags,
      bestTime: json['bestTime'] as String? ?? json['best_time'] as String? ?? '',
      audio: audio,
    );
  }

  Map<String, dynamic> toJson() => {
        'hook': hook,
        'caption': caption,
        'hashtags': hashtags,
        'bestTime': bestTime,
        'audio': audio,
      };
}
