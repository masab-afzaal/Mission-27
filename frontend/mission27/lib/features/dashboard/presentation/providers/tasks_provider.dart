import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

part 'tasks_provider.g.dart';

class TaskEntity {
  final String id;
  final String title;
  final String? description;
  final String? goalId;
  final String? deadline;
  final bool isCompleted;
  final int estimatedMinutes;
  final int actualMinutes;
  final String? domain;
  final int xpReward;

  const TaskEntity({
    required this.id,
    required this.title,
    this.description,
    this.goalId,
    this.deadline,
    required this.isCompleted,
    required this.estimatedMinutes,
    required this.actualMinutes,
    this.domain,
    required this.xpReward,
  });

  factory TaskEntity.fromJson(Map<String, dynamic> json) => TaskEntity(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        goalId: json['goal_id'] as String?,
        deadline: json['deadline'] as String?,
        isCompleted: json['is_completed'] as bool,
        estimatedMinutes: json['estimated_minutes'] as int? ?? 0,
        actualMinutes: json['actual_minutes'] as int? ?? 0,
        domain: json['domain'] as String?,
        xpReward: json['xp_reward'] as int? ?? 10,
      );
}

@riverpod
class TodayTasks extends _$TodayTasks {
  @override
  FutureOr<List<TaskEntity>> build() async {
    final dio = ref.watch(dioProvider);
    final response = await dio.get('/tasks', queryParameters: {'today': true});
    final list = response.data as List<dynamic>;
    return list.map((e) => TaskEntity.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> toggleTask(String taskId, bool isCompleted) async {
    final dio = ref.read(dioProvider);
    state = const AsyncLoading();
    try {
      await dio.patch('/tasks/$taskId', data: {'is_completed': isCompleted});
      ref.invalidateSelf();
      // Since toggleTask impacts user XP and possibly Goal progress, we refresh auth state and dashboard
      ref.invalidate(authStateProvider);
    } catch (e, stack) {
      state = AsyncError(e, stack);
    }
  }

  Future<void> createTask({
    required String title,
    String? description,
    String? goalId,
    String? deadline,
    int? estimatedMinutes,
    String? domain,
  }) async {
    final dio = ref.read(dioProvider);
    state = const AsyncLoading();
    try {
      await dio.post('/tasks', data: {
        'title': title,
        'description': description,
        'goal_id': goalId,
        'deadline': deadline,
        'estimated_minutes': estimatedMinutes,
        'domain': domain,
      });
      ref.invalidateSelf();
    } catch (e, stack) {
      state = AsyncError(e, stack);
    }
  }

  Future<void> deleteTask(String taskId) async {
    final dio = ref.read(dioProvider);
    state = const AsyncLoading();
    try {
      await dio.delete('/tasks/$taskId');
      ref.invalidateSelf();
    } catch (e, stack) {
      state = AsyncError(e, stack);
    }
  }
}

@riverpod
Future<List<TaskEntity>> goalTasks(Ref ref, String goalId) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/tasks', queryParameters: {'goal_id': goalId});
  final list = response.data as List<dynamic>;
  return list.map((e) => TaskEntity.fromJson(e as Map<String, dynamic>)).toList();
}
