// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mastery_page.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(skillAreas)
final skillAreasProvider = SkillAreasFamily._();

final class SkillAreasProvider extends $FunctionalProvider<
        AsyncValue<List<SkillAreaEntity>>,
        List<SkillAreaEntity>,
        FutureOr<List<SkillAreaEntity>>>
    with
        $FutureModifier<List<SkillAreaEntity>>,
        $FutureProvider<List<SkillAreaEntity>> {
  SkillAreasProvider._(
      {required SkillAreasFamily super.from, required String super.argument})
      : super(
          retry: null,
          name: r'skillAreasProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$skillAreasHash();

  @override
  String toString() {
    return r'skillAreasProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<SkillAreaEntity>> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<SkillAreaEntity>> create(Ref ref) {
    final argument = this.argument as String;
    return skillAreas(
      ref,
      argument,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SkillAreasProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$skillAreasHash() => r'd73c067410d0542824afbdd4a93f30c16f9508e3';

final class SkillAreasFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<SkillAreaEntity>>, String> {
  SkillAreasFamily._()
      : super(
          retry: null,
          name: r'skillAreasProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  SkillAreasProvider call(
    String domain,
  ) =>
      SkillAreasProvider._(argument: domain, from: this);

  @override
  String toString() => r'skillAreasProvider';
}

@ProviderFor(masteryStats)
final masteryStatsProvider = MasteryStatsProvider._();

final class MasteryStatsProvider extends $FunctionalProvider<
        AsyncValue<MasteryStatsEntity>,
        MasteryStatsEntity,
        FutureOr<MasteryStatsEntity>>
    with
        $FutureModifier<MasteryStatsEntity>,
        $FutureProvider<MasteryStatsEntity> {
  MasteryStatsProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'masteryStatsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$masteryStatsHash();

  @$internal
  @override
  $FutureProviderElement<MasteryStatsEntity> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<MasteryStatsEntity> create(Ref ref) {
    return masteryStats(ref);
  }
}

String _$masteryStatsHash() => r'6f36373a25b0f997af1ec6c443c948cd0f02a062';
