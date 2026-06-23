// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'habits_page.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(todayHabits)
final todayHabitsProvider = TodayHabitsProvider._();

final class TodayHabitsProvider extends $FunctionalProvider<
        AsyncValue<List<TodayHabitStatus>>,
        List<TodayHabitStatus>,
        FutureOr<List<TodayHabitStatus>>>
    with
        $FutureModifier<List<TodayHabitStatus>>,
        $FutureProvider<List<TodayHabitStatus>> {
  TodayHabitsProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'todayHabitsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$todayHabitsHash();

  @$internal
  @override
  $FutureProviderElement<List<TodayHabitStatus>> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<TodayHabitStatus>> create(Ref ref) {
    return todayHabits(ref);
  }
}

String _$todayHabitsHash() => r'69be0a214d1e530b8ae416a0e2f37d30678a5f06';
