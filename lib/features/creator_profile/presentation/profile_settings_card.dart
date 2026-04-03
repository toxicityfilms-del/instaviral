import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reelboost_ai/core/l10n/app_strings.dart';
import 'package:reelboost_ai/core/notifications/local_notifications_service.dart';
import 'package:reelboost_ai/core/settings/app_settings.dart';
import 'package:reelboost_ai/core/theme/app_theme.dart';
import 'package:reelboost_ai/widgets/app_card.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

const _kReminderH = 'post_reminder_hour_v1';
const _kReminderM = 'post_reminder_minute_v1';

class ProfileSettingsCard extends ConsumerWidget {
  const ProfileSettingsCard({super.key});

  static Future<void> _pickReminder(BuildContext context, WidgetRef ref) async {
    final s = ref.read(appStringsProvider);
    await LocalNotificationsService.requestPermissionIfSupported();
    final p = await SharedPreferences.getInstance();
    final h = p.getInt(_kReminderH);
    final m = p.getInt(_kReminderM);
    final initial = h != null && m != null ? TimeOfDay(hour: h, minute: m) : TimeOfDay.now();
    if (!context.mounted) return;
    final t = await showTimePicker(context: context, initialTime: initial);
    if (t == null || !context.mounted) return;
    await LocalNotificationsService.scheduleDailyPostingReminder(
      time: t,
      title: s.reminderNotifTitle,
      body: s.reminderNotifBody,
    );
    await p.setInt(_kReminderH, t.hour);
    await p.setInt(_kReminderM, t.minute);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.snackReminderScheduled)));
    }
  }

  static Future<void> _cancelReminder(BuildContext context, WidgetRef ref) async {
    await LocalNotificationsService.cancelDailyPostingReminder();
    final p = await SharedPreferences.getInstance();
    await p.remove(_kReminderH);
    await p.remove(_kReminderM);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ref.read(appStringsProvider).snackReminderCancelled)),
      );
    }
  }

  static Future<void> _openFeedback(AppStrings s) async {
    final uri = Uri.parse(
      'mailto:feedback@reelboost.app?subject=${Uri.encodeComponent('ReelBoost feedback')}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final settings = ref.watch(appSettingsProvider);

    return AppCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.tune_rounded, color: AppTheme.accent2.withValues(alpha: 0.95), size: 22),
              const SizedBox(width: 10),
              Text(
                s.settingsAppearance,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(s.settingsSectionTheme, style: _label(context)),
          const SizedBox(height: 6),
          SegmentedButton<ThemeMode>(
            segments: [
              ButtonSegment(value: ThemeMode.system, label: Text(s.settingsThemeSystemShort)),
              ButtonSegment(value: ThemeMode.dark, label: Text(s.settingsThemeDarkShort)),
              ButtonSegment(value: ThemeMode.light, label: Text(s.settingsThemeLightShort)),
            ],
            selected: {settings.themeMode},
            onSelectionChanged: (set) {
              ref.read(appSettingsProvider.notifier).setThemeMode(set.first);
            },
          ),
          const SizedBox(height: 16),
          Text(s.settingsLanguage, style: _label(context)),
          const SizedBox(height: 6),
          SegmentedButton<AppLocaleCode>(
            segments: [
              ButtonSegment(value: AppLocaleCode.en, label: Text(s.settingsLanguageEn)),
              ButtonSegment(value: AppLocaleCode.hi, label: Text(s.settingsLanguageHi)),
            ],
            selected: {settings.localeCode},
            onSelectionChanged: (set) {
              ref.read(appSettingsProvider.notifier).setLocale(set.first);
            },
          ),
          const SizedBox(height: 18),
          Text(s.settingsPrivacy, style: _label(context)),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(s.settingsAnalyticsOptIn),
            subtitle: Text(s.settingsAnalyticsOptInSub, style: TextStyle(color: AppTheme.onCardSecondary(context), fontSize: 12)),
            value: settings.analyticsOptIn,
            onChanged: (v) => ref.read(appSettingsProvider.notifier).setAnalyticsOptIn(v),
          ),
          const Divider(height: 24),
          Text(s.settingsReminder, style: _label(context)),
          const SizedBox(height: 4),
          Text(s.settingsReminderSub, style: TextStyle(color: AppTheme.onCardSecondary(context), fontSize: 12, height: 1.35)),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.alarm_add_rounded),
            title: Text(s.settingsSetDailyReminder),
            onTap: () => _pickReminder(context, ref),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.alarm_off_rounded),
            title: Text(s.settingsCancelReminder),
            onTap: () => _cancelReminder(context, ref),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.mail_outline_rounded),
            title: Text(s.settingsFeedback),
            subtitle: Text(s.settingsFeedbackSub, style: TextStyle(color: AppTheme.onCardSecondary(context), fontSize: 12)),
            onTap: () => _openFeedback(s),
          ),
        ],
      ),
    );
  }

  static TextStyle _label(BuildContext context) {
    return TextStyle(
      color: AppTheme.onCardSecondary(context),
      fontSize: 12,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.3,
    );
  }
}
