import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reelboost_ai/core/settings/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Opt-in, on-device only: stores short event lines for product debugging (no third party).
class LocalAnalytics {
  static const _kLog = 'local_analytics_events_v1';
  static const _max = 100;

  static Future<void> log(WidgetRef ref, String name) async {
    if (!ref.read(appSettingsProvider).analyticsOptIn) return;
    final p = await SharedPreferences.getInstance();
    final raw = p.getStringList(_kLog) ?? [];
    final stamp = DateTime.now().toIso8601String();
    final next = <String>['${stamp}_$name', ...raw];
    while (next.length > _max) {
      next.removeLast();
    }
    await p.setStringList(_kLog, next);
  }
}
