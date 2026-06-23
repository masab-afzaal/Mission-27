// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tasks_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(TodayTasks)
final todayTasksProvider = TodayTasksProvider._();

final class TodayTasksProvider
    extends $AsyncNotifierProvider<TodayTasks, List<TaskEntity>> {
  TodayTasksProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'todayTasksProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$todayTasksHash();

  @$internal
  @override
  TodayTasks create() => TodayTasks();
}

String _$todayTasksHash() => r'3d0904aa5021e065d210fd75c47a2a1927c06760';

abstract class _$TodayTasks extends $AsyncNotifier<List<TaskEntity>> {
  FutureOr<List<TaskEntity>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<TaskEntity>>, List<TaskEntity>>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<List<TaskEntity>>, List<TaskEntity>>,
        AsyncValue<List<TaskEntity>>,
        Object?,
        Object?>;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(goalTasks)
final goalTasksProvider = GoalTasksFamily._();

final class GoalTasksProvider extends $FunctionalProvider<
        AsyncValue<List<TaskEntity>>,
        List<TaskEntity>,
        FutureOr<List<TaskEntity>>>
    with $FutureModifier<List<TaskEntity>>, $FutureProvider<List<TaskEntity>> {
  GoalTasksProvider._(
      {required GoalTasksFamily super.from, required String super.argument})
      : super(
          retry: null,
          name: r'goalTasksProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$goalTasksHash();

  @override
  String toString() {
    return r'goalTasksProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<TaskEntity>> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<TaskEntity>> create(Ref ref) {
    final argument = this.argument as String;
    return goalTasks(
      ref,
      argument,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is GoalTasksProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$goalTasksHash() => r'7db7a15d7bae8c5bc7416a1031d80a6e5c499fc0';

final class GoalTasksFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<TaskEntity>>, String> {
  GoalTasksFamily._()
      : super(
          retry: null,
          name: r'goalTasksProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  GoalTasksProvider call(
    String goalId,
  ) =>
      GoalTasksProvider._(argument: goalId, from: this);

  @override
  String toString() => r'goalTasksProvider';
}
