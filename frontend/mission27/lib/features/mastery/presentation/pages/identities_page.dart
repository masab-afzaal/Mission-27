import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/widgets/m27_button.dart';
import '../../../../shared/widgets/m27_card.dart';

final identitiesProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get('/identities');
  return res.data as List<dynamic>;
});

class IdentitiesPage extends ConsumerWidget {
  const IdentitiesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final identitiesAsync = ref.watch(identitiesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Identity Personas', style: AppTypography.titleLarge),
            Text('Who you are becoming, action by action', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
          ],
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => ref.invalidate(identitiesProvider),
        child: identitiesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (list) {
            if (list.isEmpty) return const _EmptyIdentities();
            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              itemBuilder: (context, idx) {
                final item = list[idx];
                return _IdentityCard(identity: item).animate().fadeIn(delay: (idx * 100).ms);
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.black),
        label: Text('New Identity', style: AppTypography.labelMedium.copyWith(color: Colors.black)),
        onPressed: () => _showCreateDialog(context, ref),
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const _CreateIdentitySheet(),
    ).then((_) => ref.invalidate(identitiesProvider));
  }
}

class _EmptyIdentities extends StatelessWidget {
  const _EmptyIdentities();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('👑', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text('Build Identity Personas', style: AppTypography.titleSmall),
            const SizedBox(height: 8),
            Text(
              'Habits are not just actions; they build your identity. Define personas like "Software Innovator" or "Dedicated Athlete" and log actions to level them up.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _IdentityCard extends ConsumerStatefulWidget {
  final Map<String, dynamic> identity;
  const _IdentityCard({required this.identity});

  @override
  ConsumerState<_IdentityCard> createState() => _IdentityCardState();
}

class _IdentityCardState extends ConsumerState<_IdentityCard> {
  bool _logging = false;

  Future<void> _logAction() async {
    setState(() => _logging = true);
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/identities/${widget.identity['id']}/action', data: {'count': 1});
      ref.invalidate(identitiesProvider);
    } catch (_) {
    } finally {
      setState(() => _logging = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strength = (widget.identity['strength_score'] as num?)?.toDouble() ?? 0.0;
    final actions = widget.identity['total_actions'] as int? ?? 0;
    final colorHex = widget.identity['color_hex'] as String? ?? '#6C63FF';
    
    // Parse color safely
    Color color;
    try {
      color = Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
    } catch (_) {
      color = AppColors.primary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: M27Card(
        borderColor: color.withOpacity(0.3),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                  child: Center(
                    child: Text(
                      widget.identity['icon'] ?? '👤',
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.identity['identity_name'] ?? '', style: AppTypography.titleSmall),
                      Text('$actions actions logged', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Text(
                  '${strength.toStringAsFixed(0)}%',
                  style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: strength / 100,
                backgroundColor: color.withOpacity(0.12),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color.withOpacity(0.15),
                    foregroundColor: color,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _logging ? null : _logAction,
                  icon: _logging 
                      ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.bolt_rounded, size: 14),
                  label: const Text('Prove Identity', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateIdentitySheet extends ConsumerStatefulWidget {
  const _CreateIdentitySheet();

  @override
  ConsumerState<_CreateIdentitySheet> createState() => _CreateIdentitySheetState();
}

class _CreateIdentitySheetState extends ConsumerState<_CreateIdentitySheet> {
  final _nameCtrl = TextEditingController();
  String _selectedEmoji = '🎨';
  String _selectedColor = '#6C63FF';
  bool _saving = false;

  static const _emojis = ['🎨', '🧠', '🏋️', '📚', '🕌', '💻', '💼', '🚀', '🔥', '🌱', '🤝', '💤'];
  static const _colors = ['#6C63FF', '#00D4FF', '#00E676', '#FF5252', '#FFFFB347', '#AB47BC', '#EC407A'];

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    setState(() => _saving = true);
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/identities', data: {
        'identity_name': name,
        'icon': _selectedEmoji,
        'color_hex': _selectedColor,
      });
      Navigator.pop(context);
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create identity persona')),
      );
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Establish New Identity', style: AppTypography.titleLarge),
          const SizedBox(height: 20),
          Text('Identity Persona Name', style: AppTypography.labelLarge.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: TextField(
              controller: _nameCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'e.g. AI Mastery Seeker, Muslim Devotee...',
                hintStyle: TextStyle(color: AppColors.textTertiary),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          Text('Select Icon', style: AppTypography.labelLarge.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _emojis.map((e) {
              final sel = e == _selectedEmoji;
              return GestureDetector(
                onTap: () => setState(() => _selectedEmoji = e),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: sel ? AppColors.primary.withOpacity(0.15) : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                    border: sel ? Border.all(color: AppColors.primary) : null,
                  ),
                  child: Text(e, style: const TextStyle(fontSize: 20)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          Text('Select Primary Color', style: AppTypography.labelLarge.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _colors.map((c) {
              final sel = c == _selectedColor;
              final parsedColor = Color(int.parse(c.replaceFirst('#', '0xFF')));
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = c),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: parsedColor,
                  child: sel ? const Icon(Icons.check_rounded, color: Colors.black, size: 16) : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          M27Button(label: 'Establish Persona', onPressed: _submit, isLoading: _saving, isFullWidth: true),
        ],
      ),
    );
  }
}
