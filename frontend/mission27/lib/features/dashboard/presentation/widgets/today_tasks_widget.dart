import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../shared/widgets/m27_button.dart';
import '../providers/tasks_provider.dart';
import '../../../goals/presentation/pages/goals_page.dart';

class TodayTasksWidget extends ConsumerWidget {
  const TodayTasksWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(todayTasksProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                const Text('⚡', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Text("Today's Tasks", style: AppTypography.titleMedium),
                const Spacer(),
                GestureDetector(
                  onTap: () => _showAddTaskSheet(context, ref),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_rounded, color: AppColors.primary, size: 14),
                        SizedBox(width: 2),
                        Text('Add Task', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          tasksAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Failed to load tasks: $e',
                style: TextStyle(color: AppColors.error, fontSize: 13),
              ),
            ),
            data: (tasks) {
              if (tasks.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.fromLTRB(16, 4, 16, 18),
                  child: Text(
                    'No tasks left for today! Great job.',
                    style: TextStyle(color: AppColors.textTertiary, fontSize: 13),
                  ),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  return _TaskRow(task: task);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  void _showAddTaskSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddTaskSheet(),
    );
  }
}

class _TaskRow extends ConsumerStatefulWidget {
  final TaskEntity task;
  const _TaskRow({required this.task});

  @override
  ConsumerState<_TaskRow> createState() => _TaskRowState();
}

class _TaskRowState extends ConsumerState<_TaskRow> {
  bool _showXpAnimation = false;

  @override
  Widget build(BuildContext context) {
    final task = widget.task;

    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: task.isCompleted ? AppColors.success.withOpacity(0.05) : AppColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: task.isCompleted ? AppColors.success.withOpacity(0.3) : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  final isNewCompleted = !task.isCompleted;
                  if (isNewCompleted) {
                    setState(() => _showXpAnimation = true);
                    Future.delayed(const Duration(milliseconds: 1200), () {
                      if (mounted) setState(() => _showXpAnimation = false);
                    });
                  }
                  ref.read(todayTasksProvider.notifier).toggleTask(task.id, isNewCompleted);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: task.isCompleted ? AppColors.success : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: task.isCompleted ? AppColors.success : AppColors.border,
                      width: 1.5,
                    ),
                  ),
                  child: task.isCompleted
                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 13)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        color: task.isCompleted ? AppColors.textTertiary : AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (task.domain != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              task.domain!,
                              style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        if (task.estimatedMinutes > 0) ...[
                          Icon(Icons.timer_outlined, size: 12, color: AppColors.textTertiary),
                          const SizedBox(width: 2),
                          Text(
                            '${task.estimatedMinutes}m est',
                            style: TextStyle(color: AppColors.textTertiary, fontSize: 11),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (task.actualMinutes > 0) ...[
                          Icon(Icons.play_circle_outline, size: 12, color: AppColors.accent),
                          const SizedBox(width: 2),
                          Text(
                            '${task.actualMinutes}m focused',
                            style: const TextStyle(color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.textTertiary),
                onPressed: () => ref.read(todayTasksProvider.notifier).deleteTask(task.id),
              ),
            ],
          ),
        ),
        if (_showXpAnimation)
          Positioned(
            left: 40,
            child: Text(
              '+${task.xpReward} XP',
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.bold,
              ),
            )
                .animate()
                .slideY(begin: 0, end: -2.5, duration: 1000.ms, curve: Curves.easeOut)
                .fadeOut(duration: 800.ms),
          ),
      ],
    );
  }
}

class _AddTaskSheet extends ConsumerStatefulWidget {
  const _AddTaskSheet();

  @override
  ConsumerState<_AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends ConsumerState<_AddTaskSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String? _selectedGoalId;
  int _estimatedMinutes = 30;
  String _domain = 'Career';
  DateTime _deadline = DateTime.now();
  bool _submitting = false;

  final _domains = ['Career', 'Health', 'Social', 'IELTS', 'AI Development', 'Islam', 'Other'];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;

    setState(() => _submitting = true);
    try {
      final deadlineStr = "${_deadline.year}-${_deadline.month.toString().padLeft(2, '0')}-${_deadline.day.toString().padLeft(2, '0')}";
      await ref.read(todayTasksProvider.notifier).createTask(
            title: title,
            description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
            goalId: _selectedGoalId,
            deadline: deadlineStr,
            estimatedMinutes: _estimatedMinutes,
            domain: _domain,
          );
      if (mounted) Navigator.pop(context);
    } catch (_) {
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final goalsAsync = ref.watch(goalsProvider('all'));
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: EdgeInsets.only(bottom: bottom),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: SingleChildScrollView(
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
            Text('Create Task', style: AppTypography.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: _titleCtrl,
              autofocus: true,
              style: AppTypography.bodyMedium,
              decoration: InputDecoration(
                hintText: 'What is the task?',
                hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textTertiary),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              style: AppTypography.bodyMedium,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Description (optional)',
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
            
            // Goal Dropdown
            Text('Link to Goal', style: AppTypography.labelMedium.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            goalsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Text('Could not load goals'),
              data: (goalsList) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButton<String?>(
                  value: _selectedGoalId,
                  hint: const Text('None (Stand-alone Task)', style: TextStyle(color: AppColors.textTertiary, fontSize: 14)),
                  isExpanded: true,
                  underline: const SizedBox(),
                  dropdownColor: AppColors.surface,
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('None (Stand-alone Task)', style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                    ),
                    ...goalsList.map((g) => DropdownMenuItem<String?>(
                          value: g.id,
                          child: Text(g.title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                        )),
                  ],
                  onChanged: (v) => setState(() => _selectedGoalId = v),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Domain & Duration Row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Domain', style: AppTypography.labelMedium.copyWith(color: AppColors.textSecondary)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: DropdownButton<String>(
                          value: _domain,
                          isExpanded: true,
                          underline: const SizedBox(),
                          dropdownColor: AppColors.surface,
                          items: _domains
                              .map((d) => DropdownMenuItem(
                                    value: d,
                                    child: Text(d, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                                  ))
                              .toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => _domain = v);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Est. Duration', style: AppTypography.labelMedium.copyWith(color: AppColors.textSecondary)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: DropdownButton<int>(
                          value: _estimatedMinutes,
                          isExpanded: true,
                          underline: const SizedBox(),
                          dropdownColor: AppColors.surface,
                          items: [15, 30, 45, 60, 90, 120, 180, 240]
                              .map((m) => DropdownMenuItem(
                                    value: m,
                                    child: Text('${m}min', style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                                  ))
                              .toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => _estimatedMinutes = v);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Deadline Date Picker
            Text('Deadline', style: AppTypography.labelMedium.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _deadline,
                  firstDate: DateTime.now().subtract(const Duration(days: 30)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) {
                  setState(() => _deadline = picked);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Text(
                      "${_deadline.year}-${_deadline.month.toString().padLeft(2, '0')}-${_deadline.day.toString().padLeft(2, '0')}",
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    const Text('Change', style: TextStyle(color: AppColors.textTertiary, fontSize: 12)),
                  ],
                ),
              ),
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
      ),
    );
  }
}
