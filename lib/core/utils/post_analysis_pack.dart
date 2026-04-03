import 'package:reelboost_ai/models/post_analysis_models.dart';

/// Single clipboard-friendly block: hook, caption, hashtags, timing, audio.
String postAnalysisCopyPack(PostAnalysisResult r) {
  final tags = r.hashtags.join(' ');
  final buf = StringBuffer()
    ..writeln('HOOK')
    ..writeln(r.hook.trim().isEmpty ? '—' : r.hook.trim())
    ..writeln()
    ..writeln('CAPTION')
    ..writeln(r.caption.trim().isEmpty ? '—' : r.caption.trim())
    ..writeln()
    ..writeln('HASHTAGS')
    ..writeln(tags.trim().isEmpty ? '—' : tags.trim())
    ..writeln()
    ..writeln('BEST TIME')
    ..writeln(r.bestTime.trim().isEmpty ? '—' : r.bestTime.trim())
    ..writeln()
    ..writeln('AUDIO / TREND')
    ..write(r.audio.trim().isEmpty ? '—' : r.audio.trim());
  return buf.toString();
}
