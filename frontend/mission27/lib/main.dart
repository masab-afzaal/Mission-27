import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/network/api_client.dart';
import 'core/services/notification_service.dart';
import 'core/storage/app_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final storage = AppStorage(prefs);

  // Init notifications and schedule daily reminders (best-effort — never crash app)
  try {
    final ns = NotificationService();
    await ns.init();
    await ns.scheduleHabitReminder();
    await ns.scheduleMorningCheckin();

    // Schedule 9pm reminder only if check-in not done today
    final today = DateTime.now();
    final todayKey = 'checkin_done_${today.year}_${today.month}_${today.day}';
    final alreadyDone = prefs.getBool(todayKey) == true;
    if (!alreadyDone) {
      await ns.scheduleEveningCheckinReminder();
    }
  } catch (_) {}

  runApp(
    ProviderScope(
      overrides: [
        appStorageProvider.overrideWithValue(storage),
      ],
      child: const Mission27App(),
    ),
  );
}
