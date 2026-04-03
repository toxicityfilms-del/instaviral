class CaptionResult {
  const CaptionResult({
    required this.caption,
    required this.hooks,
  });

  final String caption;
  final List<String> hooks;

  factory CaptionResult.fromJson(Map<String, dynamic> json) {
    return CaptionResult(
      caption: json['caption'] as String? ?? '',
      hooks: (json['hooks'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
    );
  }
}
