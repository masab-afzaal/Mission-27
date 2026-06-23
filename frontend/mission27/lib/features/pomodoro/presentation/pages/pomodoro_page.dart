import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/notification_service.dart';
import '../../../dashboard/presentation/providers/tasks_provider.dart';
import '../../../goals/presentation/pages/goals_page.dart';

// ── State ───────────────────────────────────────────────────────────────────

enum PomodoroPhase { idle, work, breakTime }

class PomodoroState {
  final PomodoroPhase phase;
  final int secondsRemaining;
  final int workMinutes;
  final int breakMinutes;
  final int cyclesCompleted;
  final String taskDescription;
  final String? domain;
  final bool isRunning;
  final String? taskId;

  const PomodoroState({
    this.phase = PomodoroPhase.idle,
    this.secondsRemaining = 25 * 60,
    this.workMinutes = 25,
    this.breakMinutes = 5,
    this.cyclesCompleted = 0,
    this.taskDescription = '',
    this.domain,
    this.isRunning = false,
    this.taskId,
  });

  PomodoroState copyWith({
    PomodoroPhase? phase,
    int? secondsRemaining,
    int? workMinutes,
    int? breakMinutes,
    int? cyclesCompleted,
    String? taskDescription,
    String? domain,
    bool? isRunning,
    String? Function()? taskId,
  }) =>
      PomodoroState(
        phase: phase ?? this.phase,
        secondsRemaining: secondsRemaining ?? this.secondsRemaining,
        workMinutes: workMinutes ?? this.workMinutes,
        breakMinutes: breakMinutes ?? this.breakMinutes,
        cyclesCompleted: cyclesCompleted ?? this.cyclesCompleted,
        taskDescription: taskDescription ?? this.taskDescription,
        domain: domain ?? this.domain,
        isRunning: isRunning ?? this.isRunning,
        taskId: taskId != null ? taskId() : this.taskId,
      );

  double get progress {
    final total = phase == PomodoroPhase.work ? workMinutes * 60 : breakMinutes * 60;
    if (total <= 0) return 0;
    return 1.0 - (secondsRemaining / total);
  }
}

class PomodoroNotifier extends Notifier<PomodoroState> {
  Timer? _timer;

  @override
  PomodoroState build() => const PomodoroState();

  void updateTask(String task) => state = state.copyWith(taskDescription: task);
  void updateDomain(String? domain) => state = state.copyWith(domain: domain);
  void updateWorkMinutes(int mins) => state = state.copyWith(
        workMinutes: mins,
        secondsRemaining: mins * 60,
      );

  void updateTaskId(String? taskId, {String? title, String? domain}) {
    state = state.copyWith(
      taskId: () => taskId,
      taskDescription: title ?? state.taskDescription,
      domain: domain ?? state.domain,
    );
  }

  void start() {
    if (state.phase == PomodoroPhase.idle) {
      state = state.copyWith(phase: PomodoroPhase.work, secondsRemaining: state.workMinutes * 60, isRunning: true);
    } else {
      state = state.copyWith(isRunning: true);
    }
    _startTimer();
  }

  void pause() {
    _timer?.cancel();
    state = state.copyWith(isRunning: false);
  }

  void reset() {
    _timer?.cancel();
    state = const PomodoroState();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (state.secondsRemaining > 1) {
      state = state.copyWith(secondsRemaining: state.secondsRemaining - 1);
    } else {
      _timer?.cancel();
      if (state.phase == PomodoroPhase.work) {
        final newCycles = state.cyclesCompleted + 1;
        state = state.copyWith(
          phase: PomodoroPhase.breakTime,
          secondsRemaining: state.breakMinutes * 60,
          cyclesCompleted: newCycles,
          isRunning: false,
        );
        _onWorkComplete();
      } else {
        state = state.copyWith(
          phase: PomodoroPhase.work,
          secondsRemaining: state.workMinutes * 60,
          isRunning: false,
        );
      }
    }
  }

  void _onWorkComplete() {
    // Async log — fire and forget for the tick handler
    _logSession(completed: true);
  }

  Future<void> stopAndLog() async {
    _timer?.cancel();
    if (state.cyclesCompleted > 0 || state.phase == PomodoroPhase.work) {
      await _logSession(completed: false);
    }
    state = const PomodoroState();
  }

  Future<void> _logSession({required bool completed}) async {
    try {
      final dio = ref.read(dioProvider);
      final xpEarned = ((completed ? 10 : 5) * math.max(1, state.cyclesCompleted)).toInt();
      await dio.post('/pomodoro', data: {
        'work_minutes': state.workMinutes,
        'break_minutes': state.breakMinutes,
        'cycles_completed': math.max(1, state.cyclesCompleted),
        'task_description': state.taskDescription.isEmpty ? null : state.taskDescription,
        'domain': state.domain,
        'task_id': state.taskId,
        'is_completed': completed,
      });
      
      // Invalidate tasks/checkins/goals so that all lists update with the new focused minutes
      ref.invalidate(todayTasksProvider);
      if (state.taskId != null) {
        ref.invalidate(goalTasksProvider(state.taskId!));
      }
      ref.invalidate(goalsProvider('all'));
      ref.invalidate(pomodoroStatsProvider);

      if (completed) {
        await NotificationService().showPomodoroComplete(state.cyclesCompleted, xpEarned);
      }
    } catch (_) {}
  }
}

final pomodoroProvider = NotifierProvider<PomodoroNotifier, PomodoroState>(
  PomodoroNotifier.new,
);

// Stats provider
final pomodoroStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  final resp = await dio.get('/pomodoro/stats');
  return resp.data as Map<String, dynamic>;
});

// ── Page ────────────────────────────────────────────────────────────────────

class PomodoroPage extends ConsumerWidget {
  const PomodoroPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('Focus Timer', style: AppTypography.titleLarge),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded, color: AppColors.textSecondary),
            onPressed: () => _showStats(context, ref),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const _TimerRing(),
              const SizedBox(height: 32),
              const _TaskSelectorDropdown(),
              const SizedBox(height: 16),
              const _TaskInput(),
              const SizedBox(height: 16),
              const _DomainSelector(),
              const SizedBox(height: 24),
              const _WorkDurationSelector(),
              const SizedBox(height: 32),
              const _TimerControls(),
              const SizedBox(height: 24),
              const _CycleCounter(),
            ],
          ),
        ),
      ),
    );
  }

  void _showStats(BuildContext context, WidgetRef ref) {
    final container = ProviderScope.containerOf(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => UncontrolledProviderScope(
        container: container,
        child: const _StatsSheet(),
      ),
    );
  }
}

class _TimerRing extends ConsumerWidget {
  const _TimerRing();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pomodoroProvider);
    final isWork = state.phase == PomodoroPhase.work;
    final isBreak = state.phase == PomodoroPhase.breakTime;

    final mins = state.secondsRemaining ~/ 60;
    final secs = state.secondsRemaining % 60;
    final timeStr = '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';

    final phaseColor = isBreak ? const Color(0xFF3CCF7A) : AppColors.primary;
    final phaseLabel = isBreak ? 'BREAK' : (isWork ? 'FOCUS' : 'READY');

    return SizedBox(
      width: 240,
      height: 240,
      child: CustomPaint(
        painter: _RingPainter(progress: state.progress, color: phaseColor),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                phaseLabel,
                style: AppTypography.labelSmall.copyWith(
                  color: phaseColor,
                  letterSpacing: 3,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                timeStr,
                style: AppTypography.scoreDisplay.copyWith(
                  fontSize: 48,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  const _RingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = AppColors.border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10,
    );

    final sweep = 2 * math.pi * progress.clamp(0.0, 1.0);
    if (sweep > 0.001) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        sweep,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress || old.color != color;
}

class _TaskInput extends ConsumerStatefulWidget {
  const _TaskInput();

  @override
  ConsumerState<_TaskInput> createState() => _TaskInputState();
}

class _TaskInputState extends ConsumerState<_TaskInput> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isRunning = ref.watch(pomodoroProvider.select((s) => s.isRunning));
    final selectedTaskId = ref.watch(pomodoroProvider.select((s) => s.taskId));

    ref.listen(pomodoroProvider.select((s) => s.taskDescription), (_, desc) {
      if (_ctrl.text != desc) {
        _ctrl.text = desc;
      }
    });

    return TextField(
      controller: _ctrl,
      enabled: !isRunning && selectedTaskId == null,
      onChanged: (v) => ref.read(pomodoroProvider.notifier).updateTask(v),
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: 'What are you working on?',
        hintStyle: const TextStyle(color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        prefixIcon: const Icon(Icons.edit_outlined, color: AppColors.textTertiary, size: 20),
      ),
    );
  }
}

class _DomainSelector extends ConsumerWidget {
  const _DomainSelector();

  static const _domains = [
    'ai_engineering', 'ielts', 'research', 'goals',
    'health', 'career', 'personal', 'cs_foundations',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(pomodoroProvider.select((s) => s.domain));
    final isRunning = ref.watch(pomodoroProvider.select((s) => s.isRunning));
    final selectedTaskId = ref.watch(pomodoroProvider.select((s) => s.taskId));

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _domains.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final d = _domains[i];
          final active = selected == d;
          return GestureDetector(
            onTap: (isRunning || selectedTaskId != null) ? null : () => ref.read(pomodoroProvider.notifier).updateDomain(active ? null : d),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: active ? AppColors.primary.withOpacity(0.2) : AppColors.surface,
                border: Border.all(color: active ? AppColors.primary : AppColors.border),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                d.replaceAll('_', ' '),
                style: TextStyle(
                  color: active ? AppColors.primary : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TaskSelectorDropdown extends ConsumerWidget {
  const _TaskSelectorDropdown();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(todayTasksProvider);
    final selectedTaskId = ref.watch(pomodoroProvider.select((s) => s.taskId));
    final isRunning = ref.watch(pomodoroProvider.select((s) => s.isRunning));

    return tasksAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (_, __) => const SizedBox.shrink(),
      data: (tasks) {
        final activeTasks = tasks.where((t) => !t.isCompleted).toList();
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButton<String?>(
            value: selectedTaskId,
            hint: const Text('Choose Task to Work On', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
            isExpanded: true,
            underline: const SizedBox(),
            dropdownColor: AppColors.surface,
            disabledHint: selectedTaskId != null
                ? Text(
                    tasks.firstWhere((t) => t.id == selectedTaskId, orElse: () => tasks.first).title,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                  )
                : null,
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('Custom Focus Session (No Task)', style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
              ),
              ...activeTasks.map((t) => DropdownMenuItem<String?>(
                    value: t.id,
                    child: Text(t.title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                  )),
            ],
            onChanged: isRunning
                ? null
                : (v) {
                    if (v == null) {
                      ref.read(pomodoroProvider.notifier).updateTaskId(null, title: '', domain: null);
                    } else {
                      final task = tasks.firstWhere((t) => t.id == v);
                      ref.read(pomodoroProvider.notifier).updateTaskId(v, title: task.title, domain: task.domain);
                    }
                  },
          ),
        );
      },
    );
  }
}

class _WorkDurationSelector extends ConsumerWidget {
  const _WorkDurationSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workMins = ref.watch(pomodoroProvider.select((s) => s.workMinutes));
    final isRunning = ref.watch(pomodoroProvider.select((s) => s.isRunning));

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Work', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        const SizedBox(width: 12),
        for (final mins in [15, 25, 30, 45, 60])
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: isRunning ? null : () => ref.read(pomodoroProvider.notifier).updateWorkMinutes(mins),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: workMins == mins ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$mins',
                  style: TextStyle(
                    color: workMins == mins ? Colors.white : AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(width: 4),
        const Text('min', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      ],
    );
  }
}

class _TimerControls extends ConsumerWidget {
  const _TimerControls();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pomodoroProvider);
    final notifier = ref.read(pomodoroProvider.notifier);

    if (state.phase == PomodoroPhase.idle) {
      return _bigButton(
        label: 'Start Focus',
        icon: Icons.play_arrow_rounded,
        color: AppColors.primary,
        onTap: notifier.start,
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _smallButton(
          icon: Icons.stop_rounded,
          color: AppColors.error,
          onTap: () async => notifier.stopAndLog(),
        ),
        const SizedBox(width: 16),
        _bigButton(
          label: state.isRunning ? 'Pause' : 'Resume',
          icon: state.isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
          color: state.isRunning ? AppColors.accent : AppColors.primary,
          onTap: state.isRunning ? notifier.pause : notifier.start,
        ),
      ],
    );
  }

  Widget _bigButton({required String label, required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
        ]),
      ),
    );
  }

  Widget _smallButton({required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52, height: 52,
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          border: Border.all(color: color),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }
}

class _CycleCounter extends ConsumerWidget {
  const _CycleCounter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cycles = ref.watch(pomodoroProvider.select((s) => s.cyclesCompleted));
    if (cycles == 0) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < math.min(cycles, 8); i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Container(
              width: 12, height: 12,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
        const SizedBox(width: 8),
        Text(
          '$cycles cycle${cycles > 1 ? 's' : ''} completed',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
      ],
    );
  }
}

class _StatsSheet extends ConsumerWidget {
  const _StatsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(pomodoroStatsProvider);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: stats.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text('Error: $e'),
        data: (data) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Focus Stats', style: AppTypography.titleMedium),
            const SizedBox(height: 20),
            Row(children: [
              _stat('Today', '${data['today_sessions']} sessions'),
              const SizedBox(width: 24),
              _stat('Focus', '${data['today_focus_minutes']} min'),
              const SizedBox(width: 24),
              _stat('Streak', '${data['daily_streak']} days'),
            ]),
            const SizedBox(height: 16),
            Row(children: [
              _stat('This Week', '${data['week_sessions']} sessions'),
              const SizedBox(width: 24),
              _stat('Week Focus', '${data['week_focus_minutes']} min'),
            ]),
            const SizedBox(height: 16),
            Row(children: [
              _stat('All Time', '${data['total_sessions']} sessions'),
              const SizedBox(width: 24),
              _stat('Total Focus', '${(data['total_focus_minutes'] as int) ~/ 60}h ${(data['total_focus_minutes'] as int) % 60}m'),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value) => Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
        ]),
      );
}
