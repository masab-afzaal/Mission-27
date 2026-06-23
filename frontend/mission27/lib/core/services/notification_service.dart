import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz_data.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {},
    );

    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> scheduleHabitReminder() async {
    await _plugin.zonedSchedule(
      1,
      'Mission 27',
      'Check your habits before midnight — protect your streak.',
      _nextInstanceOfTime(21, 0), // 9pm
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'habits_channel',
          'Habit Reminders',
          channelDescription: 'Daily habit completion reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> scheduleMorningCheckin() async {
    await _plugin.zonedSchedule(
      2,
      'Mission 27',
      'Good morning — set your intentions for today.',
      _nextInstanceOfTime(8, 0), // 8am
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'checkin_channel',
          'Morning Check-in',
          channelDescription: 'Daily morning intention reminder',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> scheduleEveningCheckinReminder() async {
    await _plugin.zonedSchedule(
      3,
      'Mission 27 — Quick reminder 🌅',
      "You haven't set your intentions yet today. 60 seconds is all it takes.",
      _nextInstanceOfTime(21, 0), // 9pm fallback reminder
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'checkin_channel',
          'Morning Check-in',
          channelDescription: 'Daily morning intention reminder',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> showPomodoroComplete(int cyclesCompleted, int xpEarned) async {
    await _plugin.show(
      100,
      'Pomodoro Complete! 🍅',
      '$cyclesCompleted cycle${cyclesCompleted > 1 ? 's' : ''} done — +$xpEarned XP earned',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'pomodoro_channel',
          'Pomodoro',
          channelDescription: 'Pomodoro session notifications',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  Future<void> showAchievementUnlocked(String name, String icon, int xp) async {
    await _plugin.show(
      200,
      '$icon Achievement Unlocked!',
      '$name — +$xp XP',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'achievements_channel',
          'Achievements',
          channelDescription: 'Achievement unlock notifications',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
