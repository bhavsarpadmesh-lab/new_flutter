import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  Future<void> init() async {
    tzdata.initializeTimeZones();
    _useDeviceTimeZone();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(
      const InitializationSettings(android: android),
    );
  }

  /// `initializeTimeZones()` leaves `tz.local` set to UTC. Scheduling against
  /// it meant a reminder set for 07:00 fired at the UTC equivalent — 12:30 in
  /// IST, for example. Match the device's current offset instead.
  void _useDeviceTimeZone() {
    final offsetMs = DateTime.now().timeZoneOffset.inMilliseconds;
    if (offsetMs == 0) {
      tz.setLocalLocation(tz.UTC);
      return;
    }
    for (final location in tz.timeZoneDatabase.locations.values) {
      if (location.currentTimeZone.offset == offsetMs) {
        tz.setLocalLocation(location);
        return;
      }
    }
    tz.setLocalLocation(tz.UTC);
  }

  /// True if the app may post notifications right now.
  Future<bool> areEnabled() async {
    return await _android?.areNotificationsEnabled() ?? true;
  }

  /// Asks for notification permission, but only if it isn't already granted.
  /// Android 13+ requires this at runtime — declaring POST_NOTIFICATIONS in
  /// the manifest is not enough, which is why reminders never appeared.
  Future<bool> ensurePermission() async {
    final android = _android;
    if (android == null) return true;

    if (await android.areNotificationsEnabled() ?? false) return true;
    return await android.requestNotificationsPermission() ?? false;
  }

  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
  }) async {
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOfTime(time),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'habit_reminders',
          'Habit Reminders',
          channelDescription: 'Daily reminders for your habits',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      // Inexact is the right mode for a daily nudge: it survives Doze, needs no
      // extra permission, and avoids USE_EXACT_ALARM, which Google Play limits
      // to alarm clock and calendar apps.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  tz.TZDateTime _nextInstanceOfTime(TimeOfDay time) {
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
    return scheduled;
  }

  Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id);
  }
}
