// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'social_page.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(socialInteractions)
final socialInteractionsProvider = SocialInteractionsProvider._();

final class SocialInteractionsProvider extends $FunctionalProvider<
        AsyncValue<List<SocialInteractionEntity>>,
        List<SocialInteractionEntity>,
        FutureOr<List<SocialInteractionEntity>>>
    with
        $FutureModifier<List<SocialInteractionEntity>>,
        $FutureProvider<List<SocialInteractionEntity>> {
  SocialInteractionsProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'socialInteractionsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$socialInteractionsHash();

  @$internal
  @override
  $FutureProviderElement<List<SocialInteractionEntity>> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<SocialInteractionEntity>> create(Ref ref) {
    return socialInteractions(ref);
  }
}

String _$socialInteractionsHash() =>
    r'57ac87f3186af27001e28d33f5e5a6e8cc7baa77';

@ProviderFor(socialHealth)
final socialHealthProvider = SocialHealthProvider._();

final class SocialHealthProvider extends $FunctionalProvider<
        AsyncValue<SocialHealthEntity>,
        SocialHealthEntity,
        FutureOr<SocialHealthEntity>>
    with
        $FutureModifier<SocialHealthEntity>,
        $FutureProvider<SocialHealthEntity> {
  SocialHealthProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'socialHealthProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$socialHealthHash();

  @$internal
  @override
  $FutureProviderElement<SocialHealthEntity> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<SocialHealthEntity> create(Ref ref) {
    return socialHealth(ref);
  }
}

String _$socialHealthHash() => r'b72ad3baa1551c75d4ea0c69621ddd9911372fe9';
