import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/widgets/m27_button.dart';
import '../../../../shared/widgets/m27_card.dart';

part 'habits_page.g.dart';

// ── Models ──────────────────────────────────────────────────────────────────

class HabitEntity {
  final String id;
  final String name;
  final String domain;
  final String category;
  final int currentStreak;
  final int longestStreak;
  final double consistencyPercent;
  final int xpPerCompletion;
  final int totalCompletions;

  const HabitEntity({
    required this.id,
    required this.name,
    required this.domain,
    required this.category,
    required this.currentStreak,
    required this.longestStreak,
    required this.consistencyPercent,
    required this.xpPerCompletion,
    required this.totalCompletions,
  });

  factory HabitEntity.fromJson(Map<String, dynamic> json) => HabitEntity(
        id: json['id'] as String,
        name: json['name'] as String,
        domain: json['domain'] as String,
        category: json['category'] as String,
        currentStreak: json['current_streak'] as int? ?? 0,
        longestStreak: json['longest_streak'] as int? ?? 0,
        consistencyPercent: (json['consistency_percent'] as num?)?.toDouble() ?? 0.0,
        xpPerCompletion: json['xp_per_completion'] as int? ?? 10,
        totalCompletions: json['total_completions'] as int? ?? 0,
      );
}

class TodayHabitStatus {
  final HabitEntity habit;
  final bool completedToday;
  final String? logId;

  const TodayHabitStatus({required this.habit, required this.completedToday, this.logId});

  factory TodayHabitStatus.fromJson(Map<String, dynamic> json) => TodayHabitStatus(
        habit: HabitEntity.fromJson(json['habit'] as Map<String, dynamic>),
        completedToday: json['completed_today'] as bool? ?? false,
        logId: json['log_id'] as String?,
      );
}

// ── Providers ─────────────────────────────────────────────────────────────────

@riverpod
Future<List<TodayHabitStatus>> todayHabits(Ref ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/habits/today');
  final list = response.data as List<dynamic>;
  return list.map((e) => TodayHabitStatus.fromJson(e as Map<String, dynamic>)).toList();
}

// ── Page ─────────────────────────────────────────────────────────────────────

class HabitsPage extends ConsumerWidget {
  const HabitsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(todayHabitsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Habits', style: AppTypography.titleLarge),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.primary),
            onPressed: () => _showCreateHabitSheet(context, ref),
          ),
        ],
      ),
      body: habitsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (habits) => RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.surface,
          onRefresh: () => ref.refresh(todayHabitsProvider.future),
          child: habits.isEmpty
              ? const _EmptyState()
              : CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverToBoxAdapter(child: _SummaryBanner(habits: habits)),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (_, i) => _HabitCheckTile(
                            status: habits[i],
                            onToggle: () => _toggleHabit(ref, habits[i]),
                          ).animate().fadeIn(delay: Duration(milliseconds: i * 50), duration: 350.ms).slideX(begin: 0.05),
                          childCount: habits.length,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Future<void> _toggleHabit(WidgetRef ref, TodayHabitStatus status) async {
    final dio = ref.read(dioProvider);
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    try {
      await dio.post('/habits/${status.habit.id}/logs', data: {
        'logged_date': todayStr,
        'completed': !status.completedToday,
      });
      ref.invalidate(todayHabitsProvider);
    } catch (_) {}
  }

  void _showCreateHabitSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _CreateHabitSheet(onCreated: () => ref.invalidate(todayHabitsProvider)),
    );
  }
}

class _SummaryBanner extends StatelessWidget {
  final List<TodayHabitStatus> habits;
  const _SummaryBanner({required this.habits});

  @override
  Widget build(BuildContext context) {
    final done = habits.where((h) => h.completedToday).length;
    final total = habits.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withOpacity(0.3), AppColors.secondary.withOpacity(0.1)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Today's Progress", style: AppTypography.labelLarge.copyWith(color: AppColors.textSecondary)),
                Text('$done / $total completed', style: AppTypography.headlineSmall.copyWith(color: AppColors.textPrimary)),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: total > 0 ? done / total : 0,
                    backgroundColor: AppColors.primary.withOpacity(0.15),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${total > 0 ? ((done / total) * 100).toStringAsFixed(0) : 0}%',
            style: AppTypography.headlineMedium.copyWith(color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

class _HabitCheckTile extends StatefulWidget {
  final TodayHabitStatus status;
  final Future<void> Function() onToggle;

  _HabitCheckTile({required this.status, required this.onToggle});

  @override
  State<_HabitCheckTile> createState() => _HabitCheckTileState();
}

class _HabitCheckTileState extends State<_HabitCheckTile> {
  bool _toggling = false;

  Future<void> _handleTap() async {
    if (_toggling) return;
    setState(() => _toggling = true);
    try {
      await widget.onToggle();
    } finally {
      if (mounted) setState(() => _toggling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.status.habit;
    final done = widget.status.completedToday;

    return GestureDetector(
      onTap: _toggling ? null : _handleTap,
      child: AnimatedContainer(
        duration: 200.ms,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: done ? AppColors.success.withOpacity(0.08) : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: done ? AppColors.success.withOpacity(0.4) : AppColors.border),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: 200.ms,
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: done ? AppColors.success : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: done ? AppColors.success : AppColors.border, width: 1.5),
              ),
              child: done ? const Icon(Icons.check_rounded, color: Colors.white, size: 16) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(h.name, style: AppTypography.labelLarge.copyWith(
                    color: done ? AppColors.textSecondary : AppColors.textPrimary,
                    decoration: done ? TextDecoration.lineThrough : null,
                  )),
                  Row(
                    children: [
                      Text(h.domain, style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary)),
                      if (h.currentStreak > 0) ...[
                        const SizedBox(width: 8),
                        const Text('🔥', style: TextStyle(fontSize: 10)),
                        Text(' ${h.currentStreak}d', style: AppTypography.labelSmall.copyWith(color: AppColors.accent)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('+${h.xpPerCompletion} XP', style: AppTypography.labelSmall.copyWith(color: AppColors.accent)),
                Text('${h.consistencyPercent.toStringAsFixed(0)}%', style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('✅', style: TextStyle(fontSize: 48)),
          SizedBox(height: 12),
          Text('No habits yet', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
          SizedBox(height: 6),
          Text('Build your daily system', style: TextStyle(color: AppColors.textTertiary, fontSize: 13)),
        ],
      ),
    );
  }
}

// ── Create habit sheet ────────────────────────────────────────────────────────

class _CreateHabitSheet extends ConsumerStatefulWidget {
  final VoidCallback onCreated;
  const _CreateHabitSheet({required this.onCreated});

  @override
  ConsumerState<_CreateHabitSheet> createState() => _CreateHabitSheetState();
}

class _CreateHabitSheetState extends ConsumerState<_CreateHabitSheet> {
  final _nameCtrl = TextEditingController();
  String _category = 'study';
  String _domain = 'AI Engineering';
  bool _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/habits', data: {
        'name': _nameCtrl.text.trim(),
        'category': _category,
        'domain': _domain,
        'frequency': 'daily',
        'xp_per_completion': 10,
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
          Text('New Habit', style: AppTypography.titleLarge),
          const SizedBox(height: 20),
          TextField(
            controller: _nameCtrl,
            autofocus: true,
            style: AppTypography.bodyMedium,
            decoration: const InputDecoration(hintText: 'Habit name (e.g. Study IELTS Reading)'),
          ),
          const SizedBox(height: 16),
          _DropdownField('Category', _category, ['study', 'health', 'social', 'career', 'ielts', 'ai_engineering', 'research', 'sports', 'personal'], (v) => setState(() => _category = v!)),
          const SizedBox(height: 10),
          _DropdownField('Domain', _domain, ['AI Engineering', 'Computer Science', 'IELTS', 'Health & Fitness', 'Sports', 'Research', 'Social Life', 'Career', 'Personal Development'], (v) => setState(() => _domain = v!)),
          const SizedBox(height: 24),
          M27Button(label: 'Create Habit', onPressed: _submit, isLoading: _isLoading, isFullWidth: true),
        ],
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _DropdownField(this.label, this.value, this.items, this.onChanged);

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
