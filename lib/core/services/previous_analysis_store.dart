import 'dart:convert';

import 'package:reelboost_ai/models/post_analysis_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persisted snapshot of the last successful analysis per flow (for before/after UI).
class PreviousAnalysisStore {
  PreviousAnalysisStore._();

  static const String sourcePostAnalyzer = 'post_analyze';
  static const String sourceMediaAnalyzer = 'media_analyze';

  static const String _keyPost = 'reelboost_previous_analysis_post_analyze_v1';
  static const String _keyMedia = 'reelboost_previous_analysis_media_analyze_v1';

  static String _prefsKey(String source) {
    switch (source) {
      case sourcePostAnalyzer:
        return _keyPost;
      case sourceMediaAnalyzer:
        return _keyMedia;
      default:
        return 'reelboost_previous_analysis_${source}_v1';
    }
  }

  static Future<PostAnalysisResult?> load(String source) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey(source));
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return PostAnalysisResult.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  static Future<void> save(String source, PostAnalysisResult result) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey(source), jsonEncode(result.toJson()));
  }
}
