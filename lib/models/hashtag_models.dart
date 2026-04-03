class HashtagBuckets {
  const HashtagBuckets({
    required this.high,
    required this.medium,
    required this.low,
  });

  final List<String> high;
  final List<String> medium;
  final List<String> low;

  List<String> get all => [...high, ...medium, ...low];

  factory HashtagBuckets.fromJson(Map<String, dynamic> json) {
    List<String> list(dynamic v) =>
        (v as List<dynamic>? ?? []).map((e) => e.toString()).toList();
    return HashtagBuckets(
      high: list(json['high']),
      medium: list(json['medium']),
      low: list(json['low']),
    );
  }
}
