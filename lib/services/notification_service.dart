import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/class_entry.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    tz.initializeTimeZones();
    final localTz = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(localTz.identifier));

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(settings);

    // Clear stale notifications that may have incompatible serialized data
    try {
      await _plugin.cancelAll();
    } catch (_) {}

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'uniserve_channel',
        'UniServe Notifications',
        channelDescription: 'Campus notifications and alerts',
        importance: Importance.high,
        priority: Priority.high,
      ),
    );
    await _plugin.show(id, title, body, details);
  }

  static Future<void> scheduleClassReminder(ClassEntry entry) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'class_reminders',
        'Class Reminders',
        channelDescription: 'Reminders 10 minutes before your class starts',
        importance: Importance.high,
        priority: Priority.high,
      ),
    );

    final scheduledTime = _nextOccurrence(entry.dayOfWeek, entry.startTime)
        .subtract(const Duration(minutes: 10));

    await _plugin.zonedSchedule(
      entry.id.hashCode.abs() % 2147483647,
      '${entry.courseName} starts in 10 minutes',
      '${entry.courseCode} · ${entry.room}',
      scheduledTime,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      // ignore: deprecated_member_use
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancelClassReminder(String classId) async {
    await _plugin.cancel(classId.hashCode.abs() % 2147483647);
  }

  static tz.TZDateTime _nextOccurrence(int dayOfWeek, TimeOfDay time) {
    final targetWeekday = dayOfWeek + 1; // dayOfWeek: 0=Mon; DateTime.weekday: 1=Mon
    final now = tz.TZDateTime.now(tz.local);
    var candidate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    while (candidate.weekday != targetWeekday ||
        candidate.subtract(const Duration(minutes: 10)).isBefore(now)) {
      candidate = candidate.add(const Duration(days: 1));
    }
    return candidate;
  }
}
