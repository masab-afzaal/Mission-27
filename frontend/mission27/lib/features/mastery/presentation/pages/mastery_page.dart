import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/network/api_client.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../shared/widgets/m27_button.dart';
import '../../../../shared/widgets/m27_card.dart';

part 'mastery_page.g.dart';

// ---------------------------------------------------------------------------
// Domain constants
// ---------------------------------------------------------------------------

const _aiDomain = 'ai_engineering';
const _csDomain = 'cs_foundations';

// ---------------------------------------------------------------------------
// Entities
// ---------------------------------------------------------------------------

class SkillAreaEntity {
  final String id;
  final String name;
  final String domain;
  final double masteryPercent;
  final int totalSessions;
  final double targetHours;

  const SkillAreaEntity({
    required this.id,
    required this.name,
    required this.domain,
    required this.masteryPercent,
    required this.totalSessions,
    this.targetHours = 100,
  });

  factory SkillAreaEntity.fromJson(Map<String, dynamic> j) => SkillAreaEntity(
        id: j['id'] as String,
        name: j['name'] as String,
        domain: j['domain'] as String,
        masteryPercent: (j['mastery_percent'] as num).toDouble(),
        totalSessions: (j['total_sessions'] as int?) ?? 0,
        targetHours: (j['target_hours'] as num?)?.toDouble() ?? 100,
      );
}

class SkillTopicEntity {
  final String id;
  final String name;
  final bool isCompleted;
  final int studyMinutes;

  const SkillTopicEntity({
    required this.id,
    required this.name,
    required this.isCompleted,
    required this.studyMinutes,
  });

  factory SkillTopicEntity.fromJson(Map<String, dynamic> j) => SkillTopicEntity(
        id: j['id'] as String,
        name: j['name'] as String,
        isCompleted: (j['is_completed'] as bool?) ?? false,
        studyMinutes: (j['study_minutes'] as int?) ?? 0,
      );
}

class MasteryStatsEntity {
  final int totalStudyMinutes;
  final int currentStreak;
  final double averageMastery;
  final int completedTopics;
  final int totalTopics;

  const MasteryStatsEntity({
    required this.totalStudyMinutes,
    required this.currentStreak,
    required this.averageMastery,
    required this.completedTopics,
    required this.totalTopics,
  });

  factory MasteryStatsEntity.fromJson(Map<String, dynamic> j) =>
      MasteryStatsEntity(
        totalStudyMinutes: (j['total_study_minutes'] as int?) ?? 0,
        currentStreak: (j['current_streak'] as int?) ?? 0,
        averageMastery: (j['average_mastery'] as num?)?.toDouble() ?? 0,
        completedTopics: (j['completed_topics'] as int?) ?? 0,
        totalTopics: (j['total_topics'] as int?) ?? 0,
      );
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

@riverpod
Future<List<SkillAreaEntity>> skillAreas(Ref ref, String domain) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get('/mastery/skills', queryParameters: {'domain': domain});
  final items = res.data as List? ?? [];
  return items.map((e) => SkillAreaEntity.fromJson(e as Map<String, dynamic>)).toList();
}

@riverpod
Future<MasteryStatsEntity> masteryStats(Ref ref) async {
  final dio = ref.watch(dioProvider);
  try {
    final res = await dio.get('/mastery/stats');
    return MasteryStatsEntity.fromJson(res.data as Map<String, dynamic>);
  } catch (_) {
    return const MasteryStatsEntity(
      totalStudyMinutes: 0,
      currentStreak: 0,
      averageMastery: 0,
      completedTopics: 0,
      totalTopics: 0,
    );
  }
}

// ---------------------------------------------------------------------------
// Page
// ---------------------------------------------------------------------------

class MasteryPage extends ConsumerStatefulWidget {
  const MasteryPage({super.key});

  @override
  ConsumerState<MasteryPage> createState() => _MasteryPageState();
}

class _MasteryPageState extends ConsumerState<MasteryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(masteryStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            backgroundColor: AppColors.background,
            pinned: true,
            expandedHeight: 200,
            flexibleSpace: FlexibleSpaceBar(
              background: _Header(statsAsync: statsAsync),
            ),
            bottom: TabBar(
              controller: _tab,
              labelStyle: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600),
              unselectedLabelStyle: AppTypography.labelMedium,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textTertiary,
              indicatorColor: AppColors.primary,
              indicatorSize: TabBarIndicatorSize.label,
              tabs: const [
                Tab(text: 'AI Engineering'),
                Tab(text: 'CS Foundations'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tab,
          children: [
            _DomainTab(domain: _aiDomain),
            _DomainTab(domain: _csDomain),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showLogSessionSheet(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.timer_outlined, color: Colors.black),
        label: Text('Log Study', style: AppTypography.labelMedium.copyWith(color: Colors.black)),
      ),
    );
  }

  void _showLogSessionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LogSessionSheet(onSaved: () {
        ref.invalidate(masteryStatsProvider);
        ref.invalidate(skillAreasProvider(_aiDomain));
        ref.invalidate(skillAreasProvider(_csDomain));
      }),
    );
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  final AsyncValue<MasteryStatsEntity> statsAsync;

  const _Header({required this.statsAsync});

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
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Mastery System', style: AppTypography.displaySmall),
          const SizedBox(height: 4),
          Text('AI Engineering & CS Foundations',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          statsAsync.when(
            loading: () => const SizedBox(height: 40, child: Center(child: CircularProgressIndicator())),
            error: (_, __) => const SizedBox.shrink(),
            data: (stats) => Row(
              children: [
                _StatChip(
                  icon: Icons.access_time_rounded,
                  label: '${(stats.totalStudyMinutes / 60).toStringAsFixed(0)}h',
                  color: AppColors.aiEngineering,
                ),
                const SizedBox(width: 10),
                _StatChip(
                  icon: Icons.local_fire_department_rounded,
                  label: '${stats.currentStreak}d streak',
                  color: AppColors.habit,
                ),
                const SizedBox(width: 10),
                _StatChip(
                  icon: Icons.check_circle_outline_rounded,
                  label: '${stats.completedTopics}/${stats.totalTopics}',
                  color: AppColors.success,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatChip({required this.icon, required this.label, required this.color});

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
// Domain Tab
// ---------------------------------------------------------------------------

class _DomainTab extends ConsumerWidget {
  final String domain;
  const _DomainTab({required this.domain});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skillsAsync = ref.watch(skillAreasProvider(domain));

    return skillsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Could not load skills', style: AppTypography.bodyMedium),
            const SizedBox(height: 8),
            M27Button(label: 'Retry', onPressed: () => ref.invalidate(skillAreasProvider(domain))),
          ],
        ),
      ),
      data: (skills) {
        if (skills.isEmpty) return _EmptyState(domain: domain);
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: skills.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) => _SkillAreaCard(skill: skills[i]),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String domain;
  const _EmptyState({required this.domain});

  @override
  Widget build(BuildContext context) {
    final label = domain == _aiDomain ? 'AI Engineering' : 'CS Foundations';
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.school_outlined, size: 48, color: AppColors.textTertiary),
          const SizedBox(height: 12),
          Text('No $label skills yet', style: AppTypography.titleSmall),
          const SizedBox(height: 4),
          Text('Log a study session to track progress', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Skill Area Card
// ---------------------------------------------------------------------------

class _SkillAreaCard extends StatelessWidget {
  final SkillAreaEntity skill;
  const _SkillAreaCard({required this.skill});

  @override
  Widget build(BuildContext context) {
    final color = skill.domain == _aiDomain ? AppColors.aiEngineering : AppColors.csFoundations;

    return M27Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  skill.domain == _aiDomain ? Icons.memory_rounded : Icons.code_rounded,
                  size: 18,
                  color: color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(skill.name, style: AppTypography.titleSmall),
                    Text('${skill.totalSessions} sessions',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Text(
                '${skill.masteryPercent.toStringAsFixed(0)}%',
                style: AppTypography.scoreDisplay.copyWith(fontSize: 20, color: color),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: skill.masteryPercent / 100,
              backgroundColor: color.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _MasteryBadge(percent: skill.masteryPercent),
            ],
          ),
        ],
      ),
    );
  }
}

class _MasteryBadge extends StatelessWidget {
  final double percent;
  const _MasteryBadge({required this.percent});

  @override
  Widget build(BuildContext context) {
    final String label;
    final Color color;

    if (percent >= 80) {
      label = 'Expert';
      color = const Color(0xFFFFD700);
    } else if (percent >= 60) {
      label = 'Advanced';
      color = AppColors.primary;
    } else if (percent >= 40) {
      label = 'Intermediate';
      color = AppColors.success;
    } else if (percent >= 20) {
      label = 'Beginner';
      color = AppColors.warning;
    } else {
      label = 'Novice';
      color = AppColors.textTertiary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label, style: AppTypography.labelSmall.copyWith(color: color, fontSize: 10)),
    );
  }
}

// ---------------------------------------------------------------------------
// Log Session Sheet
// ---------------------------------------------------------------------------

const _durationOptions = [15, 30, 45, 60, 90, 120, 180, 240];

class _LogSessionSheet extends ConsumerStatefulWidget {
  final VoidCallback onSaved;
  const _LogSessionSheet({required this.onSaved});

  @override
  ConsumerState<_LogSessionSheet> createState() => _LogSessionSheetState();
}

class _LogSessionSheetState extends ConsumerState<_LogSessionSheet> {
  String _selectedDomain = _aiDomain;
  List<SkillAreaEntity> _existingSkills = [];
  bool _loadingSkills = true;

  // Autocomplete state: if user selects existing skill, _selectedSkill is set.
  // If they type a new name, _selectedSkill stays null.
  SkillAreaEntity? _selectedSkill;

  // Target hours text field — only shown when creating a new skill
  final _targetHoursCtrl = TextEditingController(text: '100');

  int _durationMinutes = 60;
  bool _loading = false;

  // Controller ref needed to clear the autocomplete field
  TextEditingController? _autocompleteFieldCtrl;

  @override
  void initState() {
    super.initState();
    _fetchSkills();
  }

  @override
  void dispose() {
    _targetHoursCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchSkills() async {
    setState(() { _loadingSkills = true; _selectedSkill = null; });
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.get('/mastery/skills', queryParameters: {'domain': _selectedDomain});
      final items = (res.data as List? ?? [])
          .map((e) => SkillAreaEntity.fromJson(e as Map<String, dynamic>))
          .toList();
      if (mounted) setState(() { _existingSkills = items; _loadingSkills = false; });
    } catch (_) {
      if (mounted) setState(() { _existingSkills = []; _loadingSkills = false; });
    }
  }

  String get _currentText => _autocompleteFieldCtrl?.text.trim() ?? '';

  bool get _canSave => _currentText.isNotEmpty;

  Future<void> _save() async {
    final topicName = _selectedSkill?.name ?? _currentText;
    if (topicName.isEmpty) return;

    final isNew = _selectedSkill == null;
    final targetHours = isNew ? (double.tryParse(_targetHoursCtrl.text) ?? 100.0) : null;

    setState(() => _loading = true);
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/mastery/sessions', data: {
        'topic_name': topicName,
        'domain': _selectedDomain,
        'duration_minutes': _durationMinutes,
        if (isNew && targetHours != null) 'target_hours': targetHours,
      });
      if (mounted) {
        widget.onSaved();
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to log session')),
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
            Center(child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
            )),
            const SizedBox(height: 20),
            Text('Log Study Session', style: AppTypography.titleMedium),
            const SizedBox(height: 20),

            // Domain
            Text('Domain', style: AppTypography.labelMedium.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: _DomainChip(
                label: 'AI Engineering', selected: _selectedDomain == _aiDomain,
                color: AppColors.aiEngineering,
                onTap: () { setState(() => _selectedDomain = _aiDomain); _fetchSkills(); },
              )),
              const SizedBox(width: 10),
              Expanded(child: _DomainChip(
                label: 'CS Foundations', selected: _selectedDomain == _csDomain,
                color: AppColors.csFoundations,
                onTap: () { setState(() => _selectedDomain = _csDomain); _fetchSkills(); },
              )),
            ]),
            const SizedBox(height: 20),

            // Skill autocomplete
            Text('Topic / Skill', style: AppTypography.labelMedium.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            if (_loadingSkills)
              const Center(child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: CircularProgressIndicator(),
              ))
            else
              Autocomplete<SkillAreaEntity>(
                optionsBuilder: (TextEditingValue value) {
                  if (value.text.isEmpty) return _existingSkills;
                  return _existingSkills.where(
                    (s) => s.name.toLowerCase().contains(value.text.toLowerCase()),
                  );
                },
                displayStringForOption: (s) => s.name,
                onSelected: (s) => setState(() => _selectedSkill = s),
                fieldViewBuilder: (ctx, ctrl, focusNode, onSubmit) {
                  _autocompleteFieldCtrl = ctrl;
                  return TextField(
                    controller: ctrl,
                    focusNode: focusNode,
                    style: AppTypography.bodyMedium,
                    onChanged: (_) { if (mounted) setState(() => _selectedSkill = null); },
                    decoration: InputDecoration(
                      hintText: _existingSkills.isEmpty
                          ? 'e.g. Transformer Architecture'
                          : 'Type to search or add new...',
                      hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textTertiary),
                      filled: true,
                      fillColor: AppColors.cardBackground,
                      suffixIcon: _selectedSkill != null
                          ? const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18)
                          : null,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  );
                },
                optionsViewBuilder: (ctx, onSelected, options) {
                  if (options.isEmpty) return const SizedBox.shrink();
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 6,
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: MediaQuery.of(ctx).size.width - 40,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: ListView.separated(
                            shrinkWrap: true,
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            itemCount: options.length,
                            separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
                            itemBuilder: (_, i) {
                              final skill = options.elementAt(i);
                              return InkWell(
                                onTap: () => onSelected(skill),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                                  child: Row(children: [
                                    Expanded(child: Text(skill.name, style: AppTypography.bodyMedium)),
                                    Text(
                                      '${skill.masteryPercent.toStringAsFixed(0)}%  •  ${skill.targetHours.toStringAsFixed(0)}h',
                                      style: const TextStyle(color: AppColors.textTertiary, fontSize: 11),
                                    ),
                                  ]),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

            // Target hours — only when creating a new skill (no match selected)
            if (!_loadingSkills && _selectedSkill == null) ...[
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: Text('Target hours to master',
                    style: AppTypography.labelMedium.copyWith(color: AppColors.textSecondary))),
                SizedBox(
                  width: 90,
                  child: TextField(
                    controller: _targetHoursCtrl,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: AppTypography.labelMedium.copyWith(color: AppColors.primary),
                    decoration: InputDecoration(
                      suffixText: 'h',
                      suffixStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
                      filled: true,
                      fillColor: AppColors.cardBackground,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary)),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 4),
              Text('Mastery % = hours studied ÷ target hours',
                  style: const TextStyle(color: AppColors.textTertiary, fontSize: 11)),
            ],

            const SizedBox(height: 16),

            // Duration
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text("Today's study time", style: AppTypography.labelMedium.copyWith(color: AppColors.textSecondary)),
              DropdownButton<int>(
                value: _durationMinutes,
                dropdownColor: AppColors.surface,
                style: AppTypography.labelMedium.copyWith(color: AppColors.primary),
                underline: const SizedBox.shrink(),
                items: _durationOptions.map((m) {
                  final label = m < 60 ? '${m}min' : (m % 60 == 0 ? '${m ~/ 60}h' : '${m ~/ 60}h ${m % 60}min');
                  return DropdownMenuItem(
                    value: m,
                    child: Text(label, style: AppTypography.labelMedium.copyWith(color: AppColors.primary)),
                  );
                }).toList(),
                onChanged: (v) { if (v != null) setState(() => _durationMinutes = v); },
              ),
            ]),
            const SizedBox(height: 20),

            M27Button(
              label: 'Log Session',
              onPressed: (_loading || !_canSave) ? null : _save,
              variant: M27ButtonVariant.primary,
              isLoading: _loading,
            ),
          ],
        ),
      ),
    );
  }
}

class _DomainChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _DomainChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.15) : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? color : AppColors.border, width: selected ? 1.5 : 1),
        ),
        child: Center(
          child: Text(label, style: AppTypography.labelMedium.copyWith(
            color: selected ? color : AppColors.textSecondary,
          )),
        ),
      ),
    );
  }
}
