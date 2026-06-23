// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'knowledge_page.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(knowledgeNotes)
final knowledgeNotesProvider = KnowledgeNotesFamily._();

final class KnowledgeNotesProvider extends $FunctionalProvider<
        AsyncValue<List<NoteEntity>>,
        List<NoteEntity>,
        FutureOr<List<NoteEntity>>>
    with $FutureModifier<List<NoteEntity>>, $FutureProvider<List<NoteEntity>> {
  KnowledgeNotesProvider._(
      {required KnowledgeNotesFamily super.from,
      required String? super.argument})
      : super(
          retry: null,
          name: r'knowledgeNotesProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$knowledgeNotesHash();

  @override
  String toString() {
    return r'knowledgeNotesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<NoteEntity>> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<NoteEntity>> create(Ref ref) {
    final argument = this.argument as String?;
    return knowledgeNotes(
      ref,
      argument,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is KnowledgeNotesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$knowledgeNotesHash() => r'a3b24f9ec01f75a62ba15c8e27143f8281bd7b6c';

final class KnowledgeNotesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<NoteEntity>>, String?> {
  KnowledgeNotesFamily._()
      : super(
          retry: null,
          name: r'knowledgeNotesProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  KnowledgeNotesProvider call(
    String? search,
  ) =>
      KnowledgeNotesProvider._(argument: search, from: this);

  @override
  String toString() => r'knowledgeNotesProvider';
}
