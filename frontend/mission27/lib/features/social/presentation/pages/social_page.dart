import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/network/api_client.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../shared/widgets/m27_button.dart';
import '../../../../shared/widgets/m27_card.dart';

part 'social_page.g.dart';

// ---------------------------------------------------------------------------
// Entities
// ---------------------------------------------------------------------------

class SocialInteractionEntity {
  final String id;
  final String interactionType;
  final String? personName;
  final String? notes;
  final int qualityScore;
  final String createdAt;

  const SocialInteractionEntity({
    required this.id,
    required this.interactionType,
    this.personName,
    this.notes,
    required this.qualityScore,
    required this.createdAt,
  });

  factory SocialInteractionEntity.fromJson(Map<String, dynamic> j) =>
      SocialInteractionEntity(
        id: j['id'] as String,
        interactionType: j['interaction_type'] as String,
        personName: j['person_name'] as String?,
        notes: j['notes'] as String?,
        qualityScore: (j['quality_score'] as int?) ?? 5,
        createdAt: j['created_at'] as String,
      );
}

class SocialHealthEntity {
  final double socialScore;
  final int weeklyInteractions;
  final double averageQuality;
  final int isolationRisk;
  final int meaningfulConnections;

  const SocialHealthEntity({
    required this.socialScore,
    required this.weeklyInteractions,
    required this.averageQuality,
    required this.isolationRisk,
    required this.meaningfulConnections,
  });

  factory SocialHealthEntity.fromJson(Map<String, dynamic> j) =>
      SocialHealthEntity(
        socialScore: (j['social_score'] as num?)?.toDouble() ?? 0,
        weeklyInteractions: (j['weekly_interactions'] as int?) ?? 0,
        averageQuality: (j['average_quality'] as num?)?.toDouble() ?? 0,
        isolationRisk: (j['isolation_risk'] as int?) ?? 0,
        meaningfulConnections: (j['meaningful_connections'] as int?) ?? 0,
      );
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

@riverpod
Future<List<SocialInteractionEntity>> socialInteractions(Ref ref) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get('/social/interactions');
  final items = res.data as List? ?? [];
  return items.map((e) => SocialInteractionEntity.fromJson(e as Map<String, dynamic>)).toList();
}

@riverpod
Future<SocialHealthEntity> socialHealth(Ref ref) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get('/social/health');
  return SocialHealthEntity.fromJson(res.data as Map<String, dynamic>);
}

// ---------------------------------------------------------------------------
// Interaction type constants
// ---------------------------------------------------------------------------

// (key sent to API, icon, display label)
const _interactionTypes = [
  ('conversation', Icons.chat_bubble_outline_rounded, 'Conversation'),
  ('call', Icons.phone_outlined, 'Phone/Video Call'),
  ('meetup', Icons.people_outline_rounded, 'Meetup'),
  ('message', Icons.message_outlined, 'Message'),
  ('collaboration', Icons.handshake_outlined, 'Collaboration'),
  ('event', Icons.event_outlined, 'Event'),
];

// Maps backend enum values returned in GET responses → display icons/labels
const _backendTypeDisplay = {
  'casual_chat': (Icons.chat_bubble_outline_rounded, 'Conversation'),
  'friend_meetup': (Icons.people_outline_rounded, 'Meetup'),
  'family': (Icons.home_outlined, 'Family'),
  'professional_networking': (Icons.work_outline_rounded, 'Networking'),
  'online_community': (Icons.message_outlined, 'Online'),
  'event': (Icons.event_outlined, 'Event'),
  'mentoring': (Icons.school_outlined, 'Mentoring'),
  'collaboration': (Icons.handshake_outlined, 'Collaboration'),
};

// ---------------------------------------------------------------------------
// Page
// ---------------------------------------------------------------------------

class SocialPage extends ConsumerWidget {
  const SocialPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthAsync = ref.watch(socialHealthProvider);
    final interactionsAsync = ref.watch(socialInteractionsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.background,
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: _SocialHeader(healthAsync: healthAsync),
            ),
            title: Text('Social Life', style: AppTypography.titleMedium),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Risk banner
                  healthAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (health) => _IsolationRiskBanner(risk: health.isolationRisk),
                  ),
                  const SizedBox(height: 20),
                  // Stats row
                  healthAsync.when(
                    loading: () => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator())),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (health) => _StatsRow(health: health),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Recent Interactions', style: AppTypography.titleSmall),
                      M27Button(
                        label: '+ Log',
                        onPressed: () => _showLogSheet(context, ref),
                        variant: M27ButtonVariant.ghost,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          interactionsAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(
                child: Text('Failed to load interactions', style: AppTypography.bodyMedium),
              ),
            ),
            data: (interactions) {
              if (interactions.isEmpty) {
                return const SliverFillRemaining(child: _EmptyState());
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: _InteractionTile(interaction: interactions[i]),
                  ),
                  childCount: interactions.length,
                ),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showLogSheet(context, ref),
        backgroundColor: AppColors.social,
        icon: const Icon(Icons.people_alt_outlined, color: Colors.black),
        label: Text('Log Interaction', style: AppTypography.labelMedium.copyWith(color: Colors.black)),
      ),
    );
  }

  void _showLogSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LogInteractionSheet(onSaved: () {
        ref.invalidate(socialInteractionsProvider);
        ref.invalidate(socialHealthProvider);
      }),
    );
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _SocialHeader extends StatelessWidget {
  final AsyncValue<SocialHealthEntity> healthAsync;

  const _SocialHeader({required this.healthAsync});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 80, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Social Health', style: AppTypography.displaySmall),
          const SizedBox(height: 4),
          Text(
            'Remote work makes isolation real. Track it.',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          healthAsync.when(
            loading: () => const CircularProgressIndicator(),
            error: (_, __) => const SizedBox.shrink(),
            data: (health) => Row(
              children: [
                _HeaderChip(
                  icon: Icons.people_rounded,
                  label: '${health.weeklyInteractions} this week',
                  color: AppColors.social,
                ),
                const SizedBox(width: 10),
                _HeaderChip(
                  icon: Icons.star_rounded,
                  label: '${health.averageQuality.toStringAsFixed(1)} quality',
                  color: AppColors.warning,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _HeaderChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label, style: AppTypography.labelSmall.copyWith(color: color)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Isolation risk banner
// ---------------------------------------------------------------------------

class _IsolationRiskBanner extends StatelessWidget {
  final int risk;
  const _IsolationRiskBanner({required this.risk});

  @override
  Widget build(BuildContext context) {
    if (risk < 40) return const SizedBox.shrink();

    final isHigh = risk >= 70;
    final color = isHigh ? AppColors.error : AppColors.warning;
    final title = isHigh ? 'High Isolation Risk ($risk%)' : 'Moderate Isolation Risk ($risk%)';
    final msg = isHigh
        ? 'You have very few social interactions. Reach out to someone today.'
        : 'Your social engagement is low. Try to connect with 2-3 people this week.';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.labelMedium.copyWith(color: color)),
                const SizedBox(height: 2),
                Text(msg, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stats row
// ---------------------------------------------------------------------------

class _StatsRow extends StatelessWidget {
  final SocialHealthEntity health;
  const _StatsRow({required this.health});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: M27ScoreCard(
            label: 'Social Score',
            score: health.socialScore,
            icon: Icons.people_rounded,
            color: AppColors.social,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: M27ScoreCard(
            label: 'Connections',
            score: health.meaningfulConnections.toDouble(),
            icon: Icons.favorite_outline_rounded,
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: M27ScoreCard(
            label: 'This Week',
            score: health.weeklyInteractions.toDouble(),
            icon: Icons.chat_bubble_outline_rounded,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Interaction tile
// ---------------------------------------------------------------------------

class _InteractionTile extends StatelessWidget {
  final SocialInteractionEntity interaction;
  const _InteractionTile({required this.interaction});

  @override
  Widget build(BuildContext context) {
    final backendInfo = _backendTypeDisplay[interaction.interactionType];
    final typeIcon = backendInfo?.$1 ?? Icons.people_outline_rounded;
    final typeLabel = backendInfo?.$2 ?? interaction.interactionType.replaceAll('_', ' ');

    final qualityColor = interaction.qualityScore >= 8
        ? AppColors.success
        : interaction.qualityScore >= 5
            ? AppColors.warning
            : AppColors.error;

    return M27Card(
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.social.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(typeIcon, size: 20, color: AppColors.social),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  interaction.personName ?? 'Anonymous',
                  style: AppTypography.labelMedium,
                ),
                Text(
                  typeLabel,
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
                if (interaction.notes != null && interaction.notes!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    interaction.notes!,
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: qualityColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${interaction.qualityScore}/10',
                  style: AppTypography.labelSmall.copyWith(color: qualityColor),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatDate(interaction.createdAt),
                style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      final now = DateTime.now();
      final diff = now.difference(dt).inDays;
      if (diff == 0) return 'Today';
      if (diff == 1) return 'Yesterday';
      return '${dt.day}/${dt.month}';
    } catch (_) {
      return '';
    }
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.people_outline_rounded, size: 56, color: AppColors.textTertiary),
          const SizedBox(height: 16),
          Text('No interactions logged yet', style: AppTypography.titleSmall),
          const SizedBox(height: 8),
          Text(
            'Remote work makes it easy to go days without\nreal human connection. Log your first interaction.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Log Interaction sheet
// ---------------------------------------------------------------------------

class _LogInteractionSheet extends ConsumerStatefulWidget {
  final VoidCallback onSaved;
  const _LogInteractionSheet({required this.onSaved});

  @override
  ConsumerState<_LogInteractionSheet> createState() => _LogInteractionSheetState();
}

class _LogInteractionSheetState extends ConsumerState<_LogInteractionSheet> {
  final _personCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _type = 'conversation';
  int _quality = 7;
  bool _loading = false;

  @override
  void dispose() {
    _personCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/social/interactions', data: {
        'interaction_type': _type,
        'person_name': _personCtrl.text.trim().isEmpty ? null : _personCtrl.text.trim(),
        'notes': _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        'quality_score': _quality,
      });
      if (mounted) {
        widget.onSaved();
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to log interaction')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: EdgeInsets.only(bottom: bottom),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Log Interaction', style: AppTypography.titleMedium),
            const SizedBox(height: 20),

            // Type selector
            Text('Type', style: AppTypography.labelMedium.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _interactionTypes.map((t) {
                final selected = _type == t.$1;
                return GestureDetector(
                  onTap: () => setState(() => _type = t.$1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.social.withOpacity(0.15) : AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected ? AppColors.social : AppColors.border,
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(t.$2, size: 14, color: selected ? AppColors.social : AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Text(
                          t.$3,
                          style: AppTypography.labelSmall.copyWith(
                            color: selected ? AppColors.social : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Person name
            Text('Person (optional)', style: AppTypography.labelMedium.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            TextField(
              controller: _personCtrl,
              style: AppTypography.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Who did you connect with?',
                hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textTertiary),
                filled: true,
                fillColor: AppColors.cardBackground,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),

            // Notes
            Text('Notes (optional)', style: AppTypography.labelMedium.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            TextField(
              controller: _notesCtrl,
              maxLines: 2,
              style: AppTypography.bodyMedium,
              decoration: InputDecoration(
                hintText: 'What did you talk about?',
                hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textTertiary),
                filled: true,
                fillColor: AppColors.cardBackground,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),

            // Quality
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Interaction Quality', style: AppTypography.labelMedium.copyWith(color: AppColors.textSecondary)),
                Text('$_quality / 10', style: AppTypography.labelMedium.copyWith(color: AppColors.social)),
              ],
            ),
            Slider(
              value: _quality.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              activeColor: AppColors.social,
              inactiveColor: AppColors.border,
              onChanged: (v) => setState(() => _quality = v.round()),
            ),
            const SizedBox(height: 20),

            M27Button(
              label: 'Log Interaction',
              onPressed: _loading ? null : _save,
              variant: M27ButtonVariant.primary,
              isLoading: _loading,
            ),
          ],
        ),
      ),
    );
  }
}
