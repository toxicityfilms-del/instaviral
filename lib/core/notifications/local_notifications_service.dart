import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

const _dailyReminderId = 91001;
const _androidChannelId = 'reelboost_posting';
const _androidChannelName = 'Posting reminders';

class LocalNotificationsService {
  LocalNotificationsService._();

  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static bool _ready = false;

  static Future<void> init() async {
    if (_ready) return;
    tz_data.initializeTimeZones();
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      try {
        tz.setLocalLocation(tz.getLocation(name));
      } catch (_) {
        tz.setLocalLocation(tz.getLocation('UTC'));
      }
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: darwin, macOS: darwin),
    );
    _ready = true;
  }

  static Future<bool?> requestPermissionIfSupported() async {
    if (kIsWeb) return null;
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return android.requestNotificationsPermission();
    }
    final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      return ios.requestPermissions(alert: true, badge: true, sound: true);
    }
    return null;
  }

  static Future<void> cancelDailyPostingReminder() async {
    await _plugin.cancel(_dailyReminderId);
  }

  /// Repeats every day at [time] in local timezone.
  static Future<void> scheduleDailyPostingReminder({
    required TimeOfDay time,
    required String title,
    required String body,
  }) async {
    await init();
    final android = AndroidNotificationDetails(
      _androidChannelId,
      _androidChannelName,
      channelDescription: 'Nudge to post your reel',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const darwin = DarwinNotificationDetails();
    final details = NotificationDetails(android: android, iOS: darwin, macOS: darwin);

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      _dailyReminderId,
      title,
      body,
      scheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}
