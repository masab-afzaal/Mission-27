import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/widgets/m27_button.dart';
import '../../../../shared/widgets/m27_card.dart';

part 'knowledge_page.g.dart';

class NoteEntity {
  final String id;
  final String title;
  final String content;
  final String noteType;
  final String? domain;
  final List<String> tags;
  final bool isPinned;
  final String createdAt;

  const NoteEntity({
    required this.id,
    required this.title,
    required this.content,
    required this.noteType,
    this.domain,
    required this.tags,
    required this.isPinned,
    required this.createdAt,
  });

  factory NoteEntity.fromJson(Map<String, dynamic> json) => NoteEntity(
        id: json['id'] as String,
        title: json['title'] as String,
        content: json['content'] as String,
        noteType: json['note_type'] as String,
        domain: json['domain'] as String?,
        tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
        isPinned: json['is_pinned'] as bool? ?? false,
        createdAt: json['created_at'] as String,
      );
}

@riverpod
Future<List<NoteEntity>> knowledgeNotes(Ref ref, String? search) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/knowledge/notes', queryParameters: {
    if (search != null && search.isNotEmpty) 'search': search,
  });
  final list = response.data as List<dynamic>;
  return list.map((e) => NoteEntity.fromJson(e as Map<String, dynamic>)).toList();
}

class KnowledgePage extends ConsumerStatefulWidget {
  const KnowledgePage({super.key});

  @override
  ConsumerState<KnowledgePage> createState() => _KnowledgePageState();
}

class _KnowledgePageState extends ConsumerState<KnowledgePage> {
  final _searchCtrl = TextEditingController();
  String? _search;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(knowledgeNotesProvider(_search));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Knowledge Vault', style: AppTypography.titleLarge),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.domainKnowledge),
            onPressed: () => _showCreateNote(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchCtrl,
              style: AppTypography.bodyMedium,
              decoration: const InputDecoration(
                hintText: 'Search notes...',
                prefixIcon: Icon(Icons.search_rounded, color: AppColors.textTertiary, size: 20),
              ),
              onChanged: (v) => setState(() => _search = v.isEmpty ? null : v),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: notesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const _EmptyVault(),
              data: (notes) => notes.isEmpty
                  ? const _EmptyVault()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: notes.length,
                      itemBuilder: (_, i) => _NoteTile(note: notes[i])
                          .animate()
                          .fadeIn(delay: Duration(milliseconds: i * 40), duration: 350.ms),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateNote(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _CreateNoteSheet(onCreated: () => ref.invalidate(knowledgeNotesProvider(_search))),
    );
  }
}

class _NoteTile extends StatelessWidget {
  final NoteEntity note;
  const _NoteTile({required this.note});

  @override
  Widget build(BuildContext context) {
    return M27Card(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (note.isPinned) ...[const Icon(Icons.push_pin_rounded, color: AppColors.accent, size: 14), const SizedBox(width: 4)],
              Expanded(child: Text(note.title, style: AppTypography.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: AppColors.domainKnowledge.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                child: Text(note.noteType.replaceAll('_', ' '), style: AppTypography.labelSmall.copyWith(color: AppColors.domainKnowledge, fontSize: 10)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(note.content, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
          if (note.tags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              children: note.tags.take(4).map((t) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(4)),
                child: Text('#$t', style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary, fontSize: 10)),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyVault extends StatelessWidget {
  const _EmptyVault();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('🧠', style: TextStyle(fontSize: 48)),
          SizedBox(height: 12),
          Text('Your second brain is empty', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
          SizedBox(height: 6),
          Text('Capture your learnings and ideas', style: TextStyle(color: AppColors.textTertiary, fontSize: 13)),
        ],
      ),
    );
  }
}

class _CreateNoteSheet extends ConsumerStatefulWidget {
  final VoidCallback onCreated;
  const _CreateNoteSheet({required this.onCreated});

  @override
  ConsumerState<_CreateNoteSheet> createState() => _CreateNoteSheetState();
}

class _CreateNoteSheetState extends ConsumerState<_CreateNoteSheet> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  String _noteType = 'learning';
  bool _isLoading = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty || _contentCtrl.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/knowledge/notes', data: {
        'title': _titleCtrl.text.trim(),
        'content': _contentCtrl.text.trim(),
        'note_type': _noteType,
      });
      widget.onCreated();
      if (mounted) Navigator.pop(context);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.viewInsetsOf(context).bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('New Note', style: AppTypography.titleLarge),
          const SizedBox(height: 16),
          TextField(controller: _titleCtrl, autofocus: true, style: AppTypography.bodyMedium, decoration: const InputDecoration(hintText: 'Title')),
          const SizedBox(height: 10),
          TextField(controller: _contentCtrl, style: AppTypography.bodyMedium, maxLines: 4, decoration: const InputDecoration(hintText: 'Write your note...')),
          const SizedBox(height: 12),
          DropdownButton<String>(
            value: _noteType,
            items: ['learning', 'idea', 'research_finding', 'book_summary', 'lesson_learned', 'reflection'].map((t) => DropdownMenuItem(value: t, child: Text(t.replaceAll('_', ' '), style: AppTypography.bodySmall))).toList(),
            onChanged: (v) => setState(() => _noteType = v!),
            dropdownColor: AppColors.surfaceVariant,
            underline: const SizedBox(),
          ),
          const SizedBox(height: 20),
          M27Button(label: 'Save Note', onPressed: _submit, isLoading: _isLoading, isFullWidth: true),
        ],
      ),
    );
  }
}
