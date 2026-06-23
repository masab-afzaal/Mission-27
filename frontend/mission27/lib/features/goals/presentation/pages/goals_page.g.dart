// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'goals_page.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(goals)
final goalsProvider = GoalsFamily._();

final class GoalsProvider extends $FunctionalProvider<
        AsyncValue<List<GoalEntity>>,
        List<GoalEntity>,
        FutureOr<List<GoalEntity>>>
    with $FutureModifier<List<GoalEntity>>, $FutureProvider<List<GoalEntity>> {
  GoalsProvider._(
      {required GoalsFamily super.from, required String super.argument})
      : super(
          retry: null,
          name: r'goalsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$goalsHash();

  @override
  String toString() {
    return r'goalsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<GoalEntity>> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<GoalEntity>> create(Ref ref) {
    final argument = this.argument as String;
    return goals(
      ref,
      argument,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is GoalsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$goalsHash() => r'dab52f2923b210b734240df3995df068552166fd';

final class GoalsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<GoalEntity>>, String> {
  GoalsFamily._()
      : super(
          retry: null,
          name: r'goalsProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  GoalsProvider call(
    String timeframe,
  ) =>
      GoalsProvider._(argument: timeframe, from: this);

  @override
  String toString() => r'goalsProvider';
}
