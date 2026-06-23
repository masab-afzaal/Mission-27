import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/widgets/m27_button.dart';
import '../../../../shared/widgets/m27_card.dart';

part 'health_page.g.dart';

class WorkoutLog {
  final String id;
  final String workoutType;
  final String workoutDate;
  final int durationMinutes;
  final int intensityLevel;
  final int xpEarned;

  const WorkoutLog({
    required this.id,
    required this.workoutType,
    required this.workoutDate,
    required this.durationMinutes,
    required this.intensityLevel,
    required this.xpEarned,
  });

  factory WorkoutLog.fromJson(Map<String, dynamic> json) => WorkoutLog(
        id: json['id'] as String,
        workoutType: json['workout_type'] as String,
        workoutDate: json['workout_date'] as String,
        durationMinutes: json['duration_minutes'] as int,
        intensityLevel: json['intensity_level'] as int? ?? 3,
        xpEarned: json['xp_earned'] as int? ?? 0,
      );
}

@riverpod
Future<List<WorkoutLog>> recentWorkouts(Ref ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/health/workouts');
  final list = response.data as List<dynamic>;
  return list.map((e) => WorkoutLog.fromJson(e as Map<String, dynamic>)).toList();
}

class HealthPage extends ConsumerWidget {
  const HealthPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutsAsync = ref.watch(recentWorkoutsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Health & Fitness', style: AppTypography.titleLarge),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.domainHealth),
            onPressed: () => _showLogWorkout(context, ref),
          ),
        ],
      ),
      body: workoutsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _LogWorkoutPrompt(onLog: () => _showLogWorkout(context, ref)),
        data: (workouts) => workouts.isEmpty
            ? _LogWorkoutPrompt(onLog: () => _showLogWorkout(context, ref))
            : _HealthContent(workouts: workouts),
      ),
    );
  }

  void _showLogWorkout(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _LogWorkoutSheet(onLogged: () => ref.invalidate(recentWorkoutsProvider)),
    );
  }
}

class _HealthContent extends StatelessWidget {
  final List<WorkoutLog> workouts;
  const _HealthContent({required this.workouts});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _WeeklyStats(workouts: workouts),
        const SizedBox(height: 20),
        Text('Recent Workouts', style: AppTypography.titleSmall),
        const SizedBox(height: 10),
        ...workouts.take(10).map((w) => _WorkoutTile(workout: w).animate().fadeIn(duration: 400.ms)),
      ],
    );
  }
}

class _WeeklyStats extends StatelessWidget {
  final List<WorkoutLog> workouts;
  const _WeeklyStats({required this.workouts});

  @override
  Widget build(BuildContext context) {
    final totalMins = workouts.fold<int>(0, (s, w) => s + w.durationMinutes);
    final totalXP = workouts.fold<int>(0, (s, w) => s + w.xpEarned);
    return Row(
      children: [
        _StatCard('Workouts', '${workouts.length}', Icons.fitness_center_outlined, AppColors.domainHealth),
        const SizedBox(width: 10),
        _StatCard('Minutes', '$totalMins', Icons.timer_outlined, AppColors.domainSports),
        const SizedBox(width: 10),
        _StatCard('XP Earned', '$totalXP', Icons.bolt_rounded, AppColors.accent),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: M27Card(
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(value, style: AppTypography.titleMedium.copyWith(color: color)),
            Text(label, style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

class _WorkoutTile extends StatelessWidget {
  final WorkoutLog workout;
  const _WorkoutTile({required this.workout});

  @override
  Widget build(BuildContext context) {
    final typeIcons = {
      'gym': Icons.fitness_center_outlined,
      'running': Icons.directions_run_outlined,
      'walking': Icons.directions_walk_outlined,
      'sports': Icons.sports_soccer_outlined,
      'mobility': Icons.self_improvement_outlined,
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: AppColors.domainHealth.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
            child: Icon(typeIcons[workout.workoutType] ?? Icons.fitness_center_outlined, color: AppColors.domainHealth, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(workout.workoutType[0].toUpperCase() + workout.workoutType.substring(1), style: AppTypography.labelLarge),
                Text('${workout.durationMinutes} min • Intensity ${workout.intensityLevel}/5 • ${workout.workoutDate}', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          Text('+${workout.xpEarned} XP', style: AppTypography.labelSmall.copyWith(color: AppColors.accent)),
        ],
      ),
    );
  }
}

class _LogWorkoutPrompt extends StatelessWidget {
  final VoidCallback onLog;
  const _LogWorkoutPrompt({required this.onLog});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('💪', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text('No workouts logged', style: AppTypography.titleSmall),
          const SizedBox(height: 6),
          Text('Track your fitness journey', style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary)),
          const SizedBox(height: 20),
          M27Button(label: 'Log Workout', onPressed: onLog),
        ],
      ),
    );
  }
}

class _LogWorkoutSheet extends ConsumerStatefulWidget {
  final VoidCallback onLogged;
  const _LogWorkoutSheet({required this.onLogged});

  @override
  ConsumerState<_LogWorkoutSheet> createState() => _LogWorkoutSheetState();
}

class _LogWorkoutSheetState extends ConsumerState<_LogWorkoutSheet> {
  String _type = 'gym';
  int _duration = 60;
  int _intensity = 3;
  bool _isLoading = false;

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    try {
      final dio = ref.read(dioProvider);
      final now = DateTime.now();
      final today = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      await dio.post('/health/workouts', data: {
        'workout_date': today,
        'workout_type': _type,
        'duration_minutes': _duration,
        'intensity_level': _intensity,
      });
      widget.onLogged();
      if (mounted) Navigator.pop(context);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.viewInsetsOf(context).bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Log Workout', style: AppTypography.titleLarge),
          const SizedBox(height: 16),
          Text('Type', style: AppTypography.labelLarge.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['gym', 'running', 'walking', 'sports', 'mobility', 'cycling'].map((t) {
              return GestureDetector(
                onTap: () => setState(() => _type = t),
                child: AnimatedContainer(
                  duration: 200.ms,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: _type == t ? AppColors.domainHealth : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(20),
                    border: _type == t ? null : Border.all(color: AppColors.border),
                  ),
                  child: Text(t[0].toUpperCase() + t.substring(1), style: AppTypography.labelMedium.copyWith(color: _type == t ? Colors.white : AppColors.textSecondary)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Text('Duration: $_duration min', style: AppTypography.labelLarge.copyWith(color: AppColors.textSecondary)),
          Slider(value: _duration.toDouble(), min: 15, max: 180, divisions: 11, activeColor: AppColors.domainHealth, inactiveColor: AppColors.border, onChanged: (v) => setState(() => _duration = v.round())),
          Text('Intensity: $_intensity / 5', style: AppTypography.labelLarge.copyWith(color: AppColors.textSecondary)),
          Slider(value: _intensity.toDouble(), min: 1, max: 5, divisions: 4, activeColor: AppColors.domainHealth, inactiveColor: AppColors.border, onChanged: (v) => setState(() => _intensity = v.round())),
          const SizedBox(height: 16),
          M27Button(label: 'Log Workout', onPressed: _submit, isLoading: _isLoading, isFullWidth: true),
        ],
      ),
    );
  }
}
