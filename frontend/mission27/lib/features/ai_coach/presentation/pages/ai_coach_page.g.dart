// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_coach_page.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(coachReport)
final coachReportProvider = CoachReportProvider._();

final class CoachReportProvider extends $FunctionalProvider<
        AsyncValue<CoachReport>, CoachReport, FutureOr<CoachReport>>
    with $FutureModifier<CoachReport>, $FutureProvider<CoachReport> {
  CoachReportProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'coachReportProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$coachReportHash();

  @$internal
  @override
  $FutureProviderElement<CoachReport> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<CoachReport> create(Ref ref) {
    return coachReport(ref);
  }
}

String _$coachReportHash() => r'8fc884eeada2379fa120f9bf168840a0af058155';
