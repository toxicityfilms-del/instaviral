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
    required this.score,
    required this.niche,
    required this.hook,
    required this.caption,
    required this.hashtags,
    required this.bestTime,
    required this.audio,
    required this.improvedCaption,
    required this.betterHashtags,
    required this.engagementTips,
  });

  final int score;
  final String niche;
  final String hook;
  final String caption;
  final List<String> hashtags;
  final String bestTime;
  final String audio;
  final String improvedCaption;
  final List<String> betterHashtags;
  final List<String> engagementTips;

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
    final betterRaw = json['betterHashtags'];
    List<String> betterTags;
    if (betterRaw is List) {
      betterTags = betterRaw.map((e) => e.toString()).toList();
    } else if (betterRaw is String) {
      betterTags = betterRaw
          .split(RegExp(r'[\s,]+'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    } else {
      betterTags = [];
    }
    final tipsRaw = json['engagementTips'];
    final tips = tipsRaw is List ? tipsRaw.map((e) => e.toString()).toList() : <String>[];
    return PostAnalysisResult(
      score: (json['score'] as num?)?.round() ?? 0,
      niche: (json['niche'] as String? ?? '').trim(),
      hook: json['hook'] as String? ?? '',
      caption: json['caption'] as String? ?? '',
      hashtags: tags,
      bestTime: json['bestTime'] as String? ?? json['best_time'] as String? ?? '',
      audio: audio,
      improvedCaption: (json['improvedCaption'] as String? ?? '').trim(),
      betterHashtags: betterTags,
      engagementTips: tips,
    );
  }

  Map<String, dynamic> toJson() => {
        'score': score,
        'niche': niche,
        'hook': hook,
        'caption': caption,
        'hashtags': hashtags,
        'bestTime': bestTime,
        'audio': audio,
        'improvedCaption': improvedCaption,
        'betterHashtags': betterHashtags,
        'engagementTips': engagementTips,
      };
}
