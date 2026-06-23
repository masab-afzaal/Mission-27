// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'health_page.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(recentWorkouts)
final recentWorkoutsProvider = RecentWorkoutsProvider._();

final class RecentWorkoutsProvider extends $FunctionalProvider<
        AsyncValue<List<WorkoutLog>>,
        List<WorkoutLog>,
        FutureOr<List<WorkoutLog>>>
    with $FutureModifier<List<WorkoutLog>>, $FutureProvider<List<WorkoutLog>> {
  RecentWorkoutsProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'recentWorkoutsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$recentWorkoutsHash();

  @$internal
  @override
  $FutureProviderElement<List<WorkoutLog>> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<WorkoutLog>> create(Ref ref) {
    return recentWorkouts(ref);
  }
}

String _$recentWorkoutsHash() => r'f329eae24a7e325fc5423bdb041df1c6927eb867';
