import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLocaleCode { en, hi }

class AppSettings {
  const AppSettings({
    required this.themeMode,
    required this.localeCode,
    required this.analyticsOptIn,
  });

  final ThemeMode themeMode;
  final AppLocaleCode localeCode;
  final bool analyticsOptIn;

  static const initial = AppSettings(
    themeMode: ThemeMode.dark,
    localeCode: AppLocaleCode.en,
    analyticsOptIn: false,
  );

  AppSettings copyWith({
    ThemeMode? themeMode,
    AppLocaleCode? localeCode,
    bool? analyticsOptIn,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      localeCode: localeCode ?? this.localeCode,
      analyticsOptIn: analyticsOptIn ?? this.analyticsOptIn,
    );
  }
}

final appSettingsProvider = NotifierProvider<AppSettingsNotifier, AppSettings>(AppSettingsNotifier.new);

class AppSettingsNotifier extends Notifier<AppSettings> {
  static const _kTheme = 'app_theme_mode_v1';
  static const _kLocale = 'app_locale_code_v1';
  static const _kAnalytics = 'app_analytics_opt_in_v1';

  @override
  AppSettings build() {
    Future.microtask(_load);
    return AppSettings.initial;
  }

  Future<void> _load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final t = p.getString(_kTheme);
      final l = p.getString(_kLocale);
      final a = p.getBool(_kAnalytics) ?? false;
      var tm = ThemeMode.dark;
      if (t == 'light') tm = ThemeMode.light;
      if (t == 'system') tm = ThemeMode.system;
      var lc = AppLocaleCode.en;
      if (l == 'hi') lc = AppLocaleCode.hi;
      state = AppSettings(themeMode: tm, localeCode: lc, analyticsOptIn: a);
    } catch (_) {
      state = AppSettings.initial;
    }
  }

  Future<void> setThemeMode(ThemeMode m) async {
    state = state.copyWith(themeMode: m);
    final p = await SharedPreferences.getInstance();
    final s = switch (m) {
      ThemeMode.light => 'light',
      ThemeMode.system => 'system',
      _ => 'dark',
    };
    await p.setString(_kTheme, s);
  }

  Future<void> setLocale(AppLocaleCode c) async {
    state = state.copyWith(localeCode: c);
    final p = await SharedPreferences.getInstance();
    await p.setString(_kLocale, c == AppLocaleCode.hi ? 'hi' : 'en');
  }

  Future<void> setAnalyticsOptIn(bool v) async {
    state = state.copyWith(analyticsOptIn: v);
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kAnalytics, v);
  }
}
