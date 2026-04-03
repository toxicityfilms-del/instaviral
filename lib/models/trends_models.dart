class TrendIdea {
  const TrendIdea({
    required this.title,
    required this.niche,
    required this.difficulty,
  });

  final String title;
  final String niche;
  final String difficulty;

  factory TrendIdea.fromJson(Map<String, dynamic> json) {
    return TrendIdea(
      title: json['title'] as String? ?? '',
      niche: json['niche'] as String? ?? '',
      difficulty: json['difficulty'] as String? ?? '',
    );
  }
}

class TrendSound {
  const TrendSound({
    required this.name,
    required this.mood,
    required this.note,
  });

  final String name;
  final String mood;
  final String note;

  factory TrendSound.fromJson(Map<String, dynamic> json) {
    return TrendSound(
      name: json['name'] as String? ?? '',
      mood: json['mood'] as String? ?? '',
      note: json['note'] as String? ?? '',
    );
  }
}

class TrendsPayload {
  const TrendsPayload({
    required this.updatedAt,
    required this.source,
    required this.ideas,
    required this.sounds,
  });

  final String updatedAt;
  final String source;
  final List<TrendIdea> ideas;
  final List<TrendSound> sounds;

  factory TrendsPayload.fromJson(Map<String, dynamic> json) {
    return TrendsPayload(
      updatedAt: json['updatedAt'] as String? ?? '',
      source: json['source'] as String? ?? '',
      ideas: (json['ideas'] as List<dynamic>? ?? [])
          .map((e) => TrendIdea.fromJson(e as Map<String, dynamic>))
          .toList(),
      sounds: (json['sounds'] as List<dynamic>? ?? [])
          .map((e) => TrendSound.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
