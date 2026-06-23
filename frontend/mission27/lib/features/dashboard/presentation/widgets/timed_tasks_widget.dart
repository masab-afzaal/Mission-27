import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';

// ── Model ─────────────────────────────────────────────────────────────────────

class TimedTask {
  final int id;
  final String title;
  final int hour;
  final int minute;
  final bool done;

  const TimedTask({
    required this.id,
    required this.title,
    required this.hour,
    required this.minute,
    this.done = false,
  });

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'hour': hour, 'minute': minute, 'done': done};

  factory TimedTask.fromJson(Map<String, dynamic> j) => TimedTask(
    id: j['id'] as int,
    title: j['title'] as String,
    hour: j['hour'] as int,
    minute: j['minute'] as int,
    done: j['done'] as bool? ?? false,
  );

  TimedTask copyWith({bool? done}) => TimedTask(id: id, title: title, hour: hour, minute: minute, done: done ?? this.done);

  String get timeLabel {
    final h = hour % 12 == 0 ? 12 : hour % 12;
    final m = minute.toString().padLeft(2, '0');
    final ampm = hour < 12 ? 'AM' : 'PM';
    return '$h:$m $ampm';
  }
}

// ── Storage helpers ──────────────────────────────────────────────────────────

const _prefsKey = 'timed_tasks_today';

Future<List<TimedTask>> _loadTasks() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_prefsKey);
  if (raw == null) return [];
  try {
    final list = jsonDecode(raw) as List;
    return list.map((e) => TimedTask.fromJson(e as Map<String, dynamic>)).toList();
  } catch (_) {
    return [];
  }
}

Future<void> _saveTasks(List<TimedTask> tasks) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_prefsKey, jsonEncode(tasks.map((t) => t.toJson()).toList()));
}

// ── Notification scheduler ──────────────────────────────────────────────────

Future<void> _scheduleTaskNotification(TimedTask task) async {
  final plugin = FlutterLocalNotificationsPlugin();
  final now = tz.TZDateTime.now(tz.local);

  // 3 minutes before task time
  var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, task.hour, task.minute)
      .subtract(const Duration(minutes: 3));

  if (scheduled.isBefore(now)) return; // past — skip

  await plugin.zonedSchedule(
    1000 + task.id,
    '⏰ Starting in 3 min',
    task.title,
    scheduled,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'timed_tasks_channel',
        'Timed Tasks',
        channelDescription: 'Reminders 3 minutes before scheduled tasks',
        importance: Importance.max,
        priority: Priority.high,
      ),
    ),
    androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
  );
}

Future<void> _cancelTaskNotification(int taskId) async {
  final plugin = FlutterLocalNotificationsPlugin();
  await plugin.cancel(1000 + taskId);
}

// ── Widget ────────────────────────────────────────────────────────────────────

class TimedTasksWidget extends StatefulWidget {
  const TimedTasksWidget({super.key});

  @override
  State<TimedTasksWidget> createState() => _TimedTasksWidgetState();
}

class _TimedTasksWidgetState extends State<TimedTasksWidget> {
  List<TimedTask> _tasks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final tasks = await _loadTasks();
    if (mounted) setState(() { _tasks = tasks; _loading = false; });
  }

  Future<void> _add(String title, int hour, int minute) async {
    final id = DateTime.now().millisecondsSinceEpoch % 100000;
    final task = TimedTask(id: id, title: title, hour: hour, minute: minute);
    final updated = [..._tasks, task];
    await _saveTasks(updated);
    await _scheduleTaskNotification(task);
    if (mounted) setState(() => _tasks = updated);
  }

  Future<void> _markDone(TimedTask task) async {
    final updated = _tasks.map((t) => t.id == task.id ? t.copyWith(done: true) : t).toList();
    await _saveTasks(updated);
    await _cancelTaskNotification(task.id);
    if (mounted) setState(() => _tasks = updated);
  }

  Future<void> _delete(TimedTask task) async {
    final updated = _tasks.where((t) => t.id != task.id).toList();
    await _saveTasks(updated);
    await _cancelTaskNotification(task.id);
    if (mounted) setState(() => _tasks = updated);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Row(children: [
            const Text('⏰', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text("Today's Schedule", style: AppTypography.titleMedium),
            const Spacer(),
            GestureDetector(
              onTap: () => _showAddSheet(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.add_rounded, color: AppColors.primary, size: 14),
                  SizedBox(width: 2),
                  Text('Add', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: const Text('Notification 3 min before each task', style: TextStyle(color: AppColors.textTertiary, fontSize: 11)),
        ),
        const SizedBox(height: 10),
        if (_loading)
          const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()))
        else if (_tasks.isEmpty)
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 4, 16, 14),
            child: Text('No tasks scheduled. Tap Add to set a timed task.', style: TextStyle(color: AppColors.textTertiary, fontSize: 13)),
          )
        else
          ..._tasks.map((t) => _TaskRow(task: t, onDone: () => _markDone(t), onDelete: () => _delete(t))),
        const SizedBox(height: 8),
      ]),
    );
  }

  void _showAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddTaskSheet(onAdd: _add),
    );
  }
}

class _TaskRow extends StatelessWidget {
  final TimedTask task;
  final VoidCallback onDone, onDelete;
  const _TaskRow({required this.task, required this.onDone, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final taskTime = DateTime(now.year, now.month, now.day, task.hour, task.minute);
    final isPast = taskTime.isBefore(now);
    final isSoon = !isPast && taskTime.difference(now).inMinutes <= 10;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: task.done ? AppColors.success.withOpacity(0.06) : isSoon ? AppColors.accent.withOpacity(0.1) : AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: task.done ? AppColors.success.withOpacity(0.3) : isSoon ? AppColors.accent.withOpacity(0.5) : AppColors.border),
      ),
      child: Row(children: [
        GestureDetector(
          onTap: task.done ? null : onDone,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 22, height: 22,
            decoration: BoxDecoration(
              color: task.done ? AppColors.success : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: task.done ? AppColors.success : AppColors.border, width: 1.5),
            ),
            child: task.done ? const Icon(Icons.check_rounded, color: Colors.white, size: 13) : null,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(task.title,
            style: TextStyle(
              color: task.done ? AppColors.textTertiary : AppColors.textPrimary,
              fontSize: 14, fontWeight: FontWeight.w500,
              decoration: task.done ? TextDecoration.lineThrough : null,
            ),
          ),
          Row(children: [
            Text(task.timeLabel, style: TextStyle(color: isSoon ? AppColors.accent : AppColors.textTertiary, fontSize: 11)),
            if (isSoon) ...[
              const SizedBox(width: 4),
              Text('• Starting soon!', style: const TextStyle(color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ]),
        ])),
        GestureDetector(onTap: onDelete, child: const Icon(Icons.close_rounded, color: AppColors.textTertiary, size: 16)),
      ]),
    );
  }
}

class _AddTaskSheet extends StatefulWidget {
  final Future<void> Function(String title, int hour, int minute) onAdd;
  const _AddTaskSheet({required this.onAdd});

  @override
  State<_AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<_AddTaskSheet> {
  final _titleCtrl = TextEditingController();
  TimeOfDay _time = TimeOfDay.now();
  bool _loading = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 28),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Add Timed Task', style: AppTypography.titleMedium),
        const SizedBox(height: 4),
        const Text("You'll get a notification 3 minutes before.", style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        const SizedBox(height: 16),
        TextField(
          controller: _titleCtrl,
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
          decoration: InputDecoration(
            hintText: 'What do you need to do?',
            hintStyle: const TextStyle(color: AppColors.textTertiary),
            filled: true, fillColor: AppColors.background,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
          ),
        ),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: _pickTime,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.5)),
            ),
            child: Row(children: [
              const Icon(Icons.schedule_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 10),
              Text(_time.format(context), style: const TextStyle(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.w600)),
              const Spacer(),
              const Text('Tap to change', style: TextStyle(color: AppColors.textTertiary, fontSize: 12)),
            ]),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(width: double.infinity, child: ElevatedButton(
          onPressed: _loading || _titleCtrl.text.isEmpty ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _loading
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Schedule Task', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        )),
      ]),
    );
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null && mounted) setState(() => _time = picked);
  }

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;
    setState(() => _loading = true);
    try {
      await widget.onAdd(title, _time.hour, _time.minute);
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
