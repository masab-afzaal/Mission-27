import 'dart:math' show max;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/widgets/m27_button.dart';
import '../../../../shared/widgets/m27_card.dart';

import '../../../dashboard/presentation/providers/tasks_provider.dart';

part 'goals_page.g.dart';

// ── Entity ────────────────────────────────────────────────────────────────────

class GoalEntity {
  final String id;
  final String title;
  final String domain;
  final String timeframe;
  final String status;
  final String priority;
  final double progressPercent;
  final int xpReward;
  final List<Map<String, dynamic>> milestones;

  const GoalEntity({
    required this.id,
    required this.title,
    required this.domain,
    required this.timeframe,
    required this.status,
    required this.priority,
    required this.progressPercent,
    required this.xpReward,
    required this.milestones,
  });

  factory GoalEntity.fromJson(Map<String, dynamic> json) => GoalEntity(
        id: json['id'] as String,
        title: json['title'] as String,
        domain: json['domain'] as String,
        timeframe: json['timeframe'] as String,
        status: json['status'] as String,
        priority: json['priority'] as String,
        progressPercent: (json['progress_percent'] as num?)?.toDouble() ?? 0.0,
        xpReward: json['xp_reward'] as int? ?? 50,
        milestones: (json['milestones'] as List<dynamic>?)
                ?.map((e) => e as Map<String, dynamic>)
                .toList() ??
            [],
      );
}

// ── Provider ──────────────────────────────────────────────────────────────────

@riverpod
Future<List<GoalEntity>> goals(Ref ref, String timeframe) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/goals', queryParameters: {
    if (timeframe != 'all') 'timeframe': timeframe,
  });
  final list = response.data as List<dynamic>;
  return list.map((e) => GoalEntity.fromJson(e as Map<String, dynamic>)).toList();
}

// ── Page ──────────────────────────────────────────────────────────────────────

class GoalsPage extends ConsumerStatefulWidget {
  const GoalsPage({super.key});

  @override
  ConsumerState<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends ConsumerState<GoalsPage> {
  String _selectedTimeframe = 'all';
  final _timeframes = ['all', 'annual', 'quarterly', 'monthly', 'weekly', 'daily'];

  @override
  Widget build(BuildContext context) {
    final goalsAsync = ref.watch(goalsProvider(_selectedTimeframe));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text('Goals', style: AppTypography.titleLarge),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.primary),
            onPressed: () => _showCreateGoalSheet(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _TimeframeFilter(
            selected: _selectedTimeframe,
            timeframes: _timeframes,
            onSelect: (t) => setState(() => _selectedTimeframe = t),
          ),
          Expanded(
            child: goalsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text('Error: $e', style: AppTypography.bodyMedium.copyWith(color: AppColors.error)),
              ),
              data: (goals) => goals.isEmpty
                  ? _EmptyState(timeframe: _selectedTimeframe)
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: goals.length,
                      itemBuilder: (_, i) => _GoalCard(
                        goal: goals[i],
                        onLogWork: () => _showLogWorkSheet(context, goals[i]),
                      )
                          .animate()
                          .fadeIn(delay: Duration(milliseconds: i * 60), duration: 400.ms)
                          .slideY(begin: 0.1),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateGoalSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _CreateGoalSheet(
        onCreated: () => ref.invalidate(goalsProvider(_selectedTimeframe)),
      ),
    );
  }

  void _showLogWorkSheet(BuildContext context, GoalEntity goal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LogWorkSheet(
        goal: goal,
        onLogged: () => ref.invalidate(goalsProvider(_selectedTimeframe)),
      ),
    );
  }
}

// ── Timeframe filter ──────────────────────────────────────────────────────────

class _TimeframeFilter extends StatelessWidget {
  final String selected;
  final List<String> timeframes;
  final ValueChanged<String> onSelect;

  const _TimeframeFilter({required this.selected, required this.timeframes, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: timeframes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final t = timeframes[i];
          final isSelected = t == selected;
          return GestureDetector(
            onTap: () => onSelect(t),
            child: AnimatedContainer(
              duration: 200.ms,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(20),
                border: isSelected ? null : Border.all(color: AppColors.border),
              ),
              child: Text(
                t[0].toUpperCase() + t.substring(1),
                style: AppTypography.labelMedium.copyWith(
                  color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Goal card ─────────────────────────────────────────────────────────────────

class _GoalCard extends ConsumerWidget {
  final GoalEntity goal;
  final VoidCallback onLogWork;
  const _GoalCard({required this.goal, required this.onLogWork});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = _statusColor(goal.status);
    final priorityColor = _priorityColor(goal.priority);
    final isComplete = goal.status == 'completed';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: M27Card(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: Text(goal.title, style: AppTypography.titleSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 8),
              _StatusChip(label: goal.status.replaceAll('_', ' '), color: statusColor),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              _Tag(goal.domain, AppColors.primary.withOpacity(0.8)),
              const SizedBox(width: 6),
              _Tag(goal.timeframe, AppColors.secondary.withOpacity(0.8)),
              const SizedBox(width: 6),
              _Tag(goal.priority, priorityColor),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Progress', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary)),
                  Text('${goal.progressPercent.toStringAsFixed(0)}%',
                      style: AppTypography.labelSmall.copyWith(color: AppColors.primary)),
                ]),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: goal.progressPercent / 100,
                    backgroundColor: AppColors.border,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      goal.progressPercent >= 100 ? AppColors.success : AppColors.primary,
                    ),
                    minHeight: 6,
                  ),
                ),
              ])),
              const SizedBox(width: 12),
              Column(children: [
                const Icon(Icons.bolt_rounded, color: AppColors.accent, size: 14),
                Text('${goal.xpReward} XP', style: AppTypography.labelSmall.copyWith(color: AppColors.accent)),
              ]),
            ]),
            const SizedBox(height: 8),
            _GoalTasksList(goal: goal),
            if (!isComplete) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: onLogWork,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                        ),
                        child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.add_task_rounded, size: 14, color: AppColors.primary),
                          SizedBox(width: 4),
                          Text('Log Work', style: TextStyle(
                            color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600,
                          )),
                        ]),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _showAddTaskForGoal(context, ref, goal),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                        ),
                        child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.playlist_add_rounded, size: 16, color: AppColors.accent),
                          SizedBox(width: 4),
                          Text('Add Task', style: TextStyle(
                            color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.w600,
                          )),
                        ]),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showAddTaskForGoal(BuildContext context, WidgetRef ref, GoalEntity goal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddTaskForGoalSheet(goal: goal),
    );
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'completed': return AppColors.success;
      case 'in_progress': return AppColors.primary;
      case 'paused': return AppColors.warning;
      default: return AppColors.textTertiary;
    }
  }

  Color _priorityColor(String p) {
    switch (p) {
      case 'critical': return AppColors.error;
      case 'high': return AppColors.warning;
      case 'medium': return AppColors.primary;
      default: return AppColors.textTertiary;
    }
  }
}

class _GoalTasksList extends ConsumerWidget {
  final GoalEntity goal;
  const _GoalTasksList({required this.goal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(goalTasksProvider(goal.id));

    return tasksAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (e, _) => Text('Error loading tasks: $e', style: const TextStyle(fontSize: 12, color: AppColors.error)),
      data: (tasks) {
        if (tasks.isEmpty) {
          return Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'No tasks created for this goal yet.',
              style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              'TASKS (${tasks.where((t) => t.isCompleted).length}/${tasks.length})',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textTertiary,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            ...tasks.map((task) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 1),
                child: Row(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: task.isCompleted,
                        activeColor: AppColors.success,
                        checkColor: Colors.white,
                        onChanged: (val) async {
                          if (val != null) {
                            await ref.read(todayTasksProvider.notifier).toggleTask(task.id, val);
                            ref.invalidate(goalTasksProvider(goal.id));
                            ref.invalidate(goalsProvider('all'));
                            ref.invalidate(goalsProvider('annual'));
                            ref.invalidate(goalsProvider('quarterly'));
                            ref.invalidate(goalsProvider('monthly'));
                            ref.invalidate(goalsProvider('weekly'));
                            ref.invalidate(goalsProvider('daily'));
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        task.title,
                        style: TextStyle(
                          color: task.isCompleted ? AppColors.textTertiary : AppColors.textPrimary,
                          fontSize: 13,
                          decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

class _AddTaskForGoalSheet extends ConsumerStatefulWidget {
  final GoalEntity goal;
  const _AddTaskForGoalSheet({required this.goal});

  @override
  ConsumerState<_AddTaskForGoalSheet> createState() => _AddTaskForGoalSheetState();
}

class _AddTaskForGoalSheetState extends ConsumerState<_AddTaskForGoalSheet> {
  final _titleCtrl = TextEditingController();
  int _estimatedMinutes = 30;
  bool _submitting = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;
    setState(() => _submitting = true);
    try {
      final now = DateTime.now();
      final deadlineStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      await ref.read(todayTasksProvider.notifier).createTask(
            title: title,
            goalId: widget.goal.id,
            deadline: deadlineStr,
            estimatedMinutes: _estimatedMinutes,
            domain: widget.goal.domain,
          );
      ref.invalidate(goalTasksProvider(widget.goal.id));
      ref.invalidate(goalsProvider('all'));
      ref.invalidate(goalsProvider('annual'));
      ref.invalidate(goalsProvider('quarterly'));
      ref.invalidate(goalsProvider('monthly'));
      ref.invalidate(goalsProvider('weekly'));
      ref.invalidate(goalsProvider('daily'));
      if (mounted) Navigator.pop(context);
    } catch (_) {
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Add Task to Goal', style: AppTypography.titleLarge),
          const SizedBox(height: 4),
          Text(
            widget.goal.title,
            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleCtrl,
            autofocus: true,
            style: AppTypography.bodyMedium,
            decoration: InputDecoration(
              hintText: 'What needs to be done?',
              hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textTertiary),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Estimated Duration', style: AppTypography.labelLarge.copyWith(color: AppColors.textSecondary)),
              DropdownButton<int>(
                value: _estimatedMinutes,
                dropdownColor: AppColors.surface,
                items: [15, 30, 45, 60, 90, 120, 180]
                    .map((m) => DropdownMenuItem(
                          value: m,
                          child: Text('${m}min', style: AppTypography.bodySmall),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _estimatedMinutes = v);
                },
                underline: const SizedBox(),
              ),
            ],
          ),
          const SizedBox(height: 24),
          M27Button(
            label: 'Create Task',
            onPressed: _submit,
            isLoading: _submitting,
            isFullWidth: true,
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(label, style: AppTypography.labelSmall.copyWith(color: color)),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: AppTypography.labelSmall.copyWith(color: color, fontSize: 10)),
    );
  }
}

// ── Log Work sheet ────────────────────────────────────────────────────────────

class _LogWorkSheet extends ConsumerStatefulWidget {
  final GoalEntity goal;
  final VoidCallback onLogged;
  const _LogWorkSheet({required this.goal, required this.onLogged});

  @override
  ConsumerState<_LogWorkSheet> createState() => _LogWorkSheetState();
}

class _LogWorkSheetState extends ConsumerState<_LogWorkSheet> {
  final _whatCtrl = TextEditingController();
  int _durationMinutes = 30;
  int _progressMade = 5;
  bool _loading = false;
  bool _done = false;
  int _xpEarned = 0;

  @override
  void dispose() {
    _whatCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_whatCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/goals/${widget.goal.id}/sessions', data: {
        'what_i_did': _whatCtrl.text.trim(),
        'duration_minutes': _durationMinutes,
        'progress_made': _progressMade.toDouble(),
      });
      final xp = max(10, _durationMinutes ~/ 5);
      widget.onLogged();
      if (mounted) setState(() { _done = true; _xpEarned = xp; _loading = false; });
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to log work')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      margin: EdgeInsets.only(bottom: bottom),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: _done ? _doneView() : _formView(),
    );
  }

  Widget _doneView() => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Text('💪', style: TextStyle(fontSize: 44)),
      const SizedBox(height: 12),
      Text('Session logged!', style: AppTypography.titleMedium),
      const SizedBox(height: 6),
      Text('+$_progressMade% progress  •  +$_xpEarned XP',
          style: const TextStyle(color: AppColors.success, fontSize: 15, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      Text('New progress: ${(widget.goal.progressPercent + _progressMade).clamp(0, 100).toStringAsFixed(0)}%',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      const SizedBox(height: 20),
      SizedBox(width: double.infinity, child: ElevatedButton(
        onPressed: () => Navigator.pop(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text('Done', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
      )),
    ],
  );

  Widget _formView() => SingleChildScrollView(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(child: Container(width: 40, height: 4,
          decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 16),
        Text('Log Work Session', style: AppTypography.titleMedium),
        const SizedBox(height: 4),
        Text(widget.goal.title, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 16),

        // Current progress bar
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Current progress', style: AppTypography.labelMedium.copyWith(color: AppColors.textSecondary)),
          Text('${widget.goal.progressPercent.toStringAsFixed(0)}%',
              style: AppTypography.labelMedium.copyWith(color: AppColors.primary)),
        ]),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: widget.goal.progressPercent / 100,
            backgroundColor: AppColors.border,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            minHeight: 5,
          ),
        ),
        const SizedBox(height: 18),

        // What I did
        Text('What did you work on?', style: AppTypography.labelMedium.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        TextField(
          controller: _whatCtrl,
          autofocus: true,
          style: AppTypography.bodyMedium,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: 'e.g. Finished chapter 3, wrote unit tests...',
            hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textTertiary),
            filled: true,
            fillColor: AppColors.cardBackground,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        const SizedBox(height: 14),

        // Duration + Progress
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Time spent', style: AppTypography.labelMedium.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            DropdownButton<int>(
              value: _durationMinutes,
              dropdownColor: AppColors.surface,
              style: AppTypography.labelMedium.copyWith(color: AppColors.primary),
              underline: const SizedBox.shrink(),
              items: [15, 30, 45, 60, 90, 120, 180].map((m) {
                final label = m < 60 ? '${m}min' : (m % 60 == 0 ? '${m ~/ 60}h' : '${m ~/ 60}h ${m % 60}min');
                return DropdownMenuItem(value: m, child: Text(label, style: AppTypography.labelMedium.copyWith(color: AppColors.primary)));
              }).toList(),
              onChanged: (v) { if (v != null) setState(() => _durationMinutes = v); },
            ),
          ])),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Progress +', style: AppTypography.labelMedium.copyWith(color: AppColors.textSecondary)),
              Text('$_progressMade%', style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w600, fontSize: 14)),
            ]),
            Slider(
              value: _progressMade.toDouble(),
              min: 0, max: 50, divisions: 10,
              activeColor: AppColors.success,
              inactiveColor: AppColors.border,
              onChanged: (v) => setState(() => _progressMade = v.round()),
            ),
            Text('Will reach ${(widget.goal.progressPercent + _progressMade).clamp(0, 100).toStringAsFixed(0)}%',
                style: const TextStyle(color: AppColors.textTertiary, fontSize: 11)),
          ])),
        ]),
        const SizedBox(height: 16),

        M27Button(
          label: 'Log  +${max(10, _durationMinutes ~/ 5)} XP',
          onPressed: _loading ? null : _submit,
          variant: M27ButtonVariant.primary,
          isLoading: _loading,
        ),
      ],
    ),
  );
}

// ── Create Goal sheet ─────────────────────────────────────────────────────────

class _CreateGoalSheet extends ConsumerStatefulWidget {
  final VoidCallback onCreated;
  const _CreateGoalSheet({required this.onCreated});

  @override
  ConsumerState<_CreateGoalSheet> createState() => _CreateGoalSheetState();
}

class _CreateGoalSheetState extends ConsumerState<_CreateGoalSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _timeframe = 'monthly';
  String _priority = 'medium';
  String _domain = 'AI Engineering';
  bool _isLoading = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/goals', data: {
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        'domain': _domain,
        'timeframe': _timeframe,
        'priority': _priority,
        'xp_reward': 50,
      });
      widget.onCreated();
      if (mounted) Navigator.pop(context);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('New Goal', style: AppTypography.titleLarge),
          const SizedBox(height: 20),
          TextField(
            controller: _titleCtrl,
            autofocus: true,
            style: AppTypography.bodyMedium,
            decoration: const InputDecoration(hintText: 'Goal title'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descCtrl,
            style: AppTypography.bodyMedium,
            maxLines: 2,
            decoration: const InputDecoration(hintText: 'Description (optional)'),
          ),
          const SizedBox(height: 16),
          _DropdownRow(
            label: 'Timeframe',
            value: _timeframe,
            items: ['daily', 'weekly', 'monthly', 'quarterly', 'annual'],
            onChanged: (v) => setState(() => _timeframe = v!),
          ),
          const SizedBox(height: 10),
          _DropdownRow(
            label: 'Priority',
            value: _priority,
            items: ['low', 'medium', 'high', 'critical'],
            onChanged: (v) => setState(() => _priority = v!),
          ),
          const SizedBox(height: 24),
          M27Button(
            label: 'Create Goal',
            onPressed: _submit,
            isLoading: _isLoading,
            isFullWidth: true,
          ),
        ],
      ),
    );
  }
}

class _DropdownRow extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _DropdownRow({required this.label, required this.value, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.labelLarge.copyWith(color: AppColors.textSecondary)),
        DropdownButton<String>(
          value: value,
          items: items.map((i) => DropdownMenuItem(value: i, child: Text(i, style: AppTypography.bodySmall))).toList(),
          onChanged: onChanged,
          dropdownColor: AppColors.surfaceVariant,
          underline: const SizedBox(),
        ),
      ],
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String timeframe;
  const _EmptyState({required this.timeframe});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🎯', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text('No ${timeframe == 'all' ? '' : '$timeframe '}goals yet', style: AppTypography.titleSmall),
          const SizedBox(height: 6),
          Text('Tap + to add a goal', style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary)),
        ],
      ),
    );
  }
}
