import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/widgets/m27_button.dart';
import '../../../../shared/widgets/m27_card.dart';

part 'ielts_page.g.dart';

// ── Models ──────────────────────────────────────────────────────────────────

class IELTSProfile {
  final String id;
  final double targetBand;
  final double currentBandEstimate;
  final double readinessScore;
  final double readingBand;
  final double listeningBand;
  final double writingBand;
  final double speakingBand;
  final String? examDate;

  const IELTSProfile({
    required this.id,
    required this.targetBand,
    required this.currentBandEstimate,
    required this.readinessScore,
    required this.readingBand,
    required this.listeningBand,
    required this.writingBand,
    required this.speakingBand,
    this.examDate,
  });

  factory IELTSProfile.fromJson(Map<String, dynamic> json) => IELTSProfile(
        id: json['id'] as String,
        targetBand: (json['target_band'] as num?)?.toDouble() ?? 8.0,
        currentBandEstimate: (json['current_band_estimate'] as num?)?.toDouble() ?? 0.0,
        readinessScore: (json['readiness_score'] as num?)?.toDouble() ?? 0.0,
        readingBand: (json['reading_band'] as num?)?.toDouble() ?? 0.0,
        listeningBand: (json['listening_band'] as num?)?.toDouble() ?? 0.0,
        writingBand: (json['writing_band'] as num?)?.toDouble() ?? 0.0,
        speakingBand: (json['speaking_band'] as num?)?.toDouble() ?? 0.0,
        examDate: json['exam_date'] as String?,
      );
}

class IELTSCommandCenter {
  final IELTSProfile profile;
  final List<Map<String, dynamic>> recentSessions;
  final List<Map<String, dynamic>> recentMockTests;
  final int vocabularyCount;
  final int? daysToExam;
  final double band8Probability;

  const IELTSCommandCenter({
    required this.profile,
    required this.recentSessions,
    required this.recentMockTests,
    required this.vocabularyCount,
    this.daysToExam,
    required this.band8Probability,
  });

  factory IELTSCommandCenter.fromJson(Map<String, dynamic> json) => IELTSCommandCenter(
        profile: IELTSProfile.fromJson(json['profile'] as Map<String, dynamic>),
        recentSessions: (json['recent_sessions'] as List<dynamic>?)
                ?.map((e) => e as Map<String, dynamic>)
                .toList() ??
            [],
        recentMockTests: (json['recent_mock_tests'] as List<dynamic>?)
                ?.map((e) => e as Map<String, dynamic>)
                .toList() ??
            [],
        vocabularyCount: json['vocabulary_count'] as int? ?? 0,
        daysToExam: json['days_to_exam'] as int?,
        band8Probability: (json['band_8_probability'] as num?)?.toDouble() ?? 0.0,
      );
}

// ── Providers ────────────────────────────────────────────────────────────────

@riverpod
Future<IELTSCommandCenter> ieltsCommandCenter(Ref ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/ielts');
  return IELTSCommandCenter.fromJson(response.data as Map<String, dynamic>);
}

final ieltsDueVocabProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get('/ielts/vocabulary/due');
  return response.data as List<dynamic>;
});

// ── Page ─────────────────────────────────────────────────────────────────────

class IELTSPage extends ConsumerWidget {
  const IELTSPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final centerAsync = ref.watch(ieltsCommandCenterProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('IELTS Command Center', style: AppTypography.titleLarge),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.domainIELTS),
            onPressed: () => _showLogSession(context, ref),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(ieltsCommandCenterProvider);
          ref.invalidate(ieltsDueVocabProvider);
        },
        child: centerAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (center) => _IELTSContent(center: center),
        ),
      ),
    );
  }

  void _showLogSession(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _LogSessionSheet(onLogged: () {
        ref.invalidate(ieltsCommandCenterProvider);
        ref.invalidate(ieltsDueVocabProvider);
      }),
    );
  }
}

// ── Content ───────────────────────────────────────────────────────────────────

class _IELTSContent extends ConsumerWidget {
  final IELTSCommandCenter center;
  const _IELTSContent({required this.center});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = center.profile;
    final dueVocabAsync = ref.watch(ieltsDueVocabProvider);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeroCard(center: center).animate().fadeIn(duration: 500.ms),
          const SizedBox(height: 16),
          
          // Speaking Simulator CTA
          M27Card(
            borderColor: AppColors.domainIELTS.withOpacity(0.3),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.mic_rounded, color: AppColors.domainIELTS, size: 28),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('IELTS Speaking Simulator', style: AppTypography.labelLarge),
                      Text('Test your response using AI-grade scoring', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textTertiary, size: 16),
                  onPressed: () => context.go(AppRoutes.ieltsSpeaking),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 80.ms),
          const SizedBox(height: 16),

          Text('Skill Bands', style: AppTypography.titleSmall).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 10),
          _SkillBands(profile: p).animate().fadeIn(delay: 150.ms),
          const SizedBox(height: 20),
          _StatsRow(center: center).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 20),

          // Spaced Repetition Vocab Review & AI Vocab Builder
          dueVocabAsync.when(
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
            data: (dueList) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (dueList.isNotEmpty) ...[
                    Text('Spaced Repetition', style: AppTypography.titleSmall),
                    const SizedBox(height: 10),
                    M27Card(
                      borderColor: AppColors.accent.withOpacity(0.4),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Vocabulary Review', style: AppTypography.labelLarge),
                              Text('${dueList.length} words due for review today', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                            ],
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => _startVocabReview(context, ref, dueList),
                            child: const Text('Review Now'),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 220.ms),
                    const SizedBox(height: 20),
                  ],
                  Text('AI Vocab Flashcard Builder', style: AppTypography.titleSmall),
                  const SizedBox(height: 10),
                  _AIWordGenerator().animate().fadeIn(delay: 240.ms),
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          if (center.recentSessions.isNotEmpty) ...[
            Text('Recent Sessions', style: AppTypography.titleSmall).animate().fadeIn(delay: 250.ms),
            const SizedBox(height: 10),
            ...center.recentSessions.take(5).map((s) => _SessionTile(session: s)).toList(),
          ],
        ],
      ),
    );
  }

  void _startVocabReview(BuildContext context, WidgetRef ref, List<dynamic> dueList) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _VocabReviewDialog(dueList: dueList, onFinished: () {
        ref.invalidate(ieltsCommandCenterProvider);
        ref.invalidate(ieltsDueVocabProvider);
      }),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final IELTSCommandCenter center;
  const _HeroCard({required this.center});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.domainIELTS.withOpacity(0.3), AppColors.secondary.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.domainIELTS.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Current Band', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary)),
                  Text(
                    center.profile.currentBandEstimate.toStringAsFixed(1),
                    style: AppTypography.scoreDisplay.copyWith(color: AppColors.domainIELTS),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Target', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary)),
                  Text(
                    center.profile.targetBand.toStringAsFixed(1),
                    style: AppTypography.headlineMedium.copyWith(color: AppColors.textPrimary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Readiness', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary)),
                        Text('${center.profile.readinessScore.toStringAsFixed(0)}%', style: AppTypography.labelSmall.copyWith(color: AppColors.domainIELTS)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: center.profile.readinessScore / 100,
                        backgroundColor: AppColors.domainIELTS.withOpacity(0.15),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.domainIELTS),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (center.daysToExam != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${center.daysToExam} days to exam',
                style: AppTypography.labelSmall.copyWith(color: AppColors.accent),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SkillBands extends StatelessWidget {
  final IELTSProfile profile;
  const _SkillBands({required this.profile});

  @override
  Widget build(BuildContext context) {
    final skills = [
      ('Reading', profile.readingBand, Icons.menu_book_outlined),
      ('Listening', profile.listeningBand, Icons.headphones_outlined),
      ('Writing', profile.writingBand, Icons.edit_outlined),
      ('Speaking', profile.speakingBand, Icons.mic_outlined),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.8,
      ),
      itemCount: skills.length,
      itemBuilder: (_, i) {
        final (name, band, icon) = skills[i];
        return M27Card(
          borderColor: AppColors.domainIELTS.withOpacity(0.3),
          child: Row(
            children: [
              Icon(icon, color: AppColors.domainIELTS, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(name, style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary)),
                    Text(
                      band.toStringAsFixed(1),
                      style: AppTypography.titleMedium.copyWith(color: AppColors.domainIELTS),
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: band / 9.0,
                        backgroundColor: AppColors.domainIELTS.withOpacity(0.15),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.domainIELTS),
                        minHeight: 3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatsRow extends StatelessWidget {
  final IELTSCommandCenter center;
  const _StatsRow({required this.center});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatBox('Vocabulary', '${center.vocabularyCount}', Icons.abc_rounded),
        const SizedBox(width: 10),
        _StatBox('Band 8 Prob.', '${center.band8Probability.toStringAsFixed(0)}%', Icons.star_outline_rounded),
        const SizedBox(width: 10),
        _StatBox('Mock Tests', '${center.recentMockTests.length}', Icons.assignment_outlined),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _StatBox(this.label, this.value, this.icon);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: M27Card(
        child: Column(
          children: [
            Icon(icon, color: AppColors.domainIELTS, size: 20),
            const SizedBox(height: 4),
            Text(value, style: AppTypography.titleSmall.copyWith(color: AppColors.domainIELTS)),
            Text(label, style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary, fontSize: 10), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  final Map<String, dynamic> session;
  const _SessionTile({required this.session});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.domainIELTS.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.school_outlined, color: AppColors.domainIELTS, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text((session['skill'] as String).toUpperCase(), style: AppTypography.labelLarge),
                Text('${session['duration_minutes']} min • ${session['session_date']}', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          Text('+${session['xp_earned']} XP', style: AppTypography.labelSmall.copyWith(color: AppColors.accent)),
        ],
      ),
    );
  }
}

// ── Log session sheet ─────────────────────────────────────────────────────────

class _LogSessionSheet extends ConsumerStatefulWidget {
  final VoidCallback onLogged;
  const _LogSessionSheet({required this.onLogged});

  @override
  ConsumerState<_LogSessionSheet> createState() => _LogSessionSheetState();
}

class _LogSessionSheetState extends ConsumerState<_LogSessionSheet> {
  String _skill = 'reading';
  int _duration = 60;
  bool _isLoading = false;

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    try {
      final dio = ref.read(dioProvider);
      final now = DateTime.now();
      await dio.post('/ielts/sessions', data: {
        'skill': _skill,
        'duration_minutes': _duration,
        'session_date': '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
        'quality_rating': 3,
      });
      widget.onLogged();
      if (mounted) Navigator.pop(context);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
          Text('Log Study Session', style: AppTypography.titleLarge),
          const SizedBox(height: 20),
          Text('Skill', style: AppTypography.labelLarge.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['reading', 'listening', 'writing', 'speaking', 'vocabulary', 'grammar'].map((s) {
              final selected = s == _skill;
              return GestureDetector(
                onTap: () => setState(() => _skill = s),
                child: AnimatedContainer(
                  duration: 200.ms,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.domainIELTS : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(20),
                    border: selected ? null : Border.all(color: AppColors.border),
                  ),
                  child: Text(s[0].toUpperCase() + s.substring(1), style: AppTypography.labelMedium.copyWith(color: selected ? AppColors.background : AppColors.textSecondary)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Text('Duration: $_duration min', style: AppTypography.labelLarge.copyWith(color: AppColors.textSecondary)),
          Slider(
            value: _duration.toDouble(),
            min: 15,
            max: 240,
            divisions: 15,
            activeColor: AppColors.domainIELTS,
            inactiveColor: AppColors.border,
            onChanged: (v) => setState(() => _duration = v.round()),
          ),
          const SizedBox(height: 20),
          M27Button(label: 'Log Session', onPressed: _submit, isLoading: _isLoading, isFullWidth: true),
        ],
      ),
    );
  }
}

// ── AI Vocabulary Generator Widget ───────────────────────────────────────────

class _AIWordGenerator extends StatefulWidget {
  const _AIWordGenerator();

  @override
  State<_AIWordGenerator> createState() => _AIWordGeneratorState();
}

class _AIWordGeneratorState extends State<_AIWordGenerator> {
  final _controller = TextEditingController();
  bool _loading = false;
  String? _message;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _generate(WidgetRef ref) async {
    final topic = _controller.text.trim();
    if (topic.isEmpty) return;

    setState(() {
      _loading = true;
      _message = null;
    });

    try {
      final dio = ref.read(dioProvider);
      await dio.post('/ielts/vocabulary/generate', data: {'topic': topic});
      
      setState(() {
        _message = 'Successfully generated 10 advanced flashcards!';
        _controller.clear();
      });
      
      ref.invalidate(ieltsCommandCenterProvider);
      ref.invalidate(ieltsDueVocabProvider);
    } catch (e) {
      setState(() => _message = 'Failed to generate words: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        return M27Card(
          borderColor: AppColors.domainIELTS.withOpacity(0.3),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Topic & Subdomain', style: AppTypography.labelLarge.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: TextField(
                  controller: _controller,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'e.g. Environmental Science, Art, Business...',
                    hintStyle: TextStyle(color: AppColors.textTertiary, fontSize: 13),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (_message != null) ...[
                Text(
                  _message!,
                  style: TextStyle(color: _message!.startsWith('Success') ? AppColors.success : AppColors.error, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
              ],
              M27Button(
                label: 'Generate Flashcards',
                onPressed: () => _generate(ref),
                isLoading: _loading,
                isFullWidth: true,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Spaced Repetition Spaced Review Dialog ───────────────────────────────────

class _VocabReviewDialog extends StatefulWidget {
  final List<dynamic> dueList;
  final VoidCallback onFinished;

  const _VocabReviewDialog({required this.dueList, required this.onFinished});

  @override
  State<_VocabReviewDialog> createState() => _VocabReviewDialogState();
}

class _VocabReviewDialogState extends State<_VocabReviewDialog> {
  int _currentIndex = 0;
  bool _revealDefinition = false;
  bool _submitting = false;

  Future<void> _submitQuality(WidgetRef ref, int quality) async {
    if (_submitting) return;
    setState(() => _submitting = true);

    try {
      final dio = ref.read(dioProvider);
      final currentWord = widget.dueList[_currentIndex];
      
      await dio.post('/ielts/vocabulary/review', data: {
        'word_id': currentWord['id'],
        'quality': quality,
      });

      if (_currentIndex + 1 < widget.dueList.length) {
        setState(() {
          _currentIndex++;
          _revealDefinition = false;
        });
      } else {
        widget.onFinished();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Completed all due vocabulary reviews! +XP awarded.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (_) {
    } finally {
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentWord = widget.dueList[_currentIndex];

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Consumer(
        builder: (context, ref, _) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Reviewing (${_currentIndex + 1}/${widget.dueList.length})',
                      style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppColors.textTertiary, size: 18),
                      onPressed: () {
                        widget.onFinished();
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Word Card
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Center(
                    child: Text(
                      currentWord['word'] ?? '',
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.primaryLight),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                if (!_revealDefinition) ...[
                  M27Button(
                    label: 'Reveal Definition',
                    onPressed: () => setState(() => _revealDefinition = true),
                    isFullWidth: true,
                  ),
                ] else ...[
                  // Definition details
                  Text(
                    currentWord['definition'] ?? '',
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, height: 1.4),
                    textAlign: TextAlign.center,
                  ),
                  if (currentWord['example_sentence'] != null && currentWord['example_sentence'].toString().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      '"${currentWord['example_sentence']}"',
                      style: const TextStyle(color: AppColors.textSecondary, fontStyle: FontStyle.italic, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 24),
                  
                  // SM-2 Review Scale
                  Text(
                    'How well did you remember this word?',
                    style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    alignment: WrapAlignment.spaceEvenly,
                    spacing: 6,
                    children: List.generate(6, (idx) {
                      final labels = ['Forgot', 'Incorrect', 'Barely', 'Hard', 'Good', 'Perfect'];
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: _submitting ? null : () => _submitQuality(ref, idx),
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: idx < 3 ? AppColors.error.withOpacity(0.15) : AppColors.success.withOpacity(0.15),
                              child: Text(
                                '$idx',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: idx < 3 ? AppColors.error : AppColors.success,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(labels[idx], style: const TextStyle(fontSize: 8, color: AppColors.textTertiary)),
                        ],
                      );
                    }),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

