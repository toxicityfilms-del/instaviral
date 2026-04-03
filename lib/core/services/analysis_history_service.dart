import 'dart:convert';
import 'dart:math';

import 'package:reelboost_ai/models/post_analysis_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _prefsKey = 'reelboost_analysis_history_v1';
const _maxEntries = 50;

class AnalysisHistoryEntry {
  AnalysisHistoryEntry({
    required this.id,
    required this.createdAtMs,
    required this.source,
    required this.title,
    required this.result,
    this.pinned = false,
  });

  final String id;
  final int createdAtMs;
  /// `post_analyze` | `media_analyze`
  final String source;
  final String title;
  final PostAnalysisResult result;
  final bool pinned;

  AnalysisHistoryEntry copyWith({bool? pinned}) {
    return AnalysisHistoryEntry(
      id: id,
      createdAtMs: createdAtMs,
      source: source,
      title: title,
      result: result,
      pinned: pinned ?? this.pinned,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAtMs': createdAtMs,
        'source': source,
        'title': title,
        'pinned': pinned,
        'result': result.toJson(),
      };

  factory AnalysisHistoryEntry.fromJson(Map<String, dynamic> json) {
    return AnalysisHistoryEntry(
      id: json['id'] as String? ?? '',
      createdAtMs: (json['createdAtMs'] as num?)?.toInt() ?? 0,
      source: json['source'] as String? ?? '',
      title: json['title'] as String? ?? '',
      pinned: json['pinned'] as bool? ?? false,
      result: PostAnalysisResult.fromJson(Map<String, dynamic>.from(json['result'] as Map? ?? {})),
    );
  }
}

class AnalysisHistoryService {
  AnalysisHistoryService._();

  static String _trimTitle(String raw) {
    final t = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (t.isEmpty) return 'Analysis';
    return t.length > 72 ? '${t.substring(0, 72)}…' : t;
  }

  static Future<List<AnalysisHistoryEntry>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      final out = list
          .map((e) => AnalysisHistoryEntry.fromJson(Map<String, dynamic>.from(e as Map)))
          .where((e) => e.id.isNotEmpty)
          .toList();
      out.sort((a, b) {
        if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
        return b.createdAtMs.compareTo(a.createdAtMs);
      });
      return out;
    } catch (_) {
      return [];
    }
  }

  static Future<void> _save(List<AnalysisHistoryEntry> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode(items.map((e) => e.toJson()).toList()),
    );
  }

  static Future<void> add({
    required String source,
    required String title,
    required PostAnalysisResult result,
  }) async {
    final items = await load();
    final id = '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1 << 20)}';
    items.insert(
      0,
      AnalysisHistoryEntry(
        id: id,
        createdAtMs: DateTime.now().millisecondsSinceEpoch,
        source: source,
        title: _trimTitle(title),
        result: result,
        pinned: false,
      ),
    );
    while (items.length > _maxEntries) {
      items.removeLast();
    }
    await _save(items);
  }

  static Future<void> setPinned(String id, bool pinned) async {
    final items = await load();
    final i = items.indexWhere((e) => e.id == id);
    if (i < 0) return;
    items[i] = items[i].copyWith(pinned: pinned);
    items.sort((a, b) {
      if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
      return b.createdAtMs.compareTo(a.createdAtMs);
    });
    await _save(items);
  }

  static Future<void> remove(String id) async {
    final items = await load();
    items.removeWhere((e) => e.id == id);
    await _save(items);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }
}
