// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ielts_page.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ieltsCommandCenter)
final ieltsCommandCenterProvider = IeltsCommandCenterProvider._();

final class IeltsCommandCenterProvider extends $FunctionalProvider<
        AsyncValue<IELTSCommandCenter>,
        IELTSCommandCenter,
        FutureOr<IELTSCommandCenter>>
    with
        $FutureModifier<IELTSCommandCenter>,
        $FutureProvider<IELTSCommandCenter> {
  IeltsCommandCenterProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'ieltsCommandCenterProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$ieltsCommandCenterHash();

  @$internal
  @override
  $FutureProviderElement<IELTSCommandCenter> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<IELTSCommandCenter> create(Ref ref) {
    return ieltsCommandCenter(ref);
  }
}

String _$ieltsCommandCenterHash() =>
    r'6ba0361d530388ef5e00f7650fdaa1a14a0f8f33';
