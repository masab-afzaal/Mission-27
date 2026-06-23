import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/day_events_widget.dart';
import '../widgets/domino_task_widget.dart';
import '../widgets/growth_score_ring.dart';
import '../widgets/morning_checkin_modal.dart';
import '../widgets/nudge_banner.dart';
import '../widgets/obstacles_log_sheet.dart';
import '../widgets/score_grid.dart';
import '../widgets/timed_tasks_widget.dart';
import '../widgets/trends_chart_widget.dart';
import '../widgets/today_tasks_widget.dart';
import '../widgets/evening_retro_widget.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      MorningCheckInModal.showIfNeeded(context, ref);
      _checkTimeAwareFeatures();
    });
  }

  void _checkTimeAwareFeatures() {
    final hour = DateTime.now().hour;
    // 3 AM Wind-Down: work end transition (2-4 AM)
    if (hour >= 2 && hour <= 4) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) _showWindDown();
      });
    }
    // Slump Zone: 4-6 AM — suggest light activities
    else if (hour >= 4 && hour <= 6) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) _showSlumpZone();
      });
    }
  }

  void _showWindDown() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _WindDownSheet(),
    );
  }

  void _showSlumpZone() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _SlumpZoneSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider).value;
    final user = authState?.user;
    final dashboardAsync = ref.watch(dashboardSummaryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.surface,
          onRefresh: () => ref.refresh(dashboardSummaryProvider.future),
          child: CustomScrollView(
            slivers: [
              _AppBar(
                fullName: user?.fullName.split(' ').first ?? 'Agent',
                level: user?.level ?? 1,
                xp: user?.xpTotal ?? 0,
                onLogout: () => ref.read(authStateProvider.notifier).logout(),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    dashboardAsync.when(
                      loading: () => const _LoadingSkeleton(),
                      error: (e, _) => _ErrorCard(message: e.toString()),
                      data: (summary) => _DashboardContent(summary: summary),
                    ),
                    const SizedBox(height: 24),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppBar extends StatelessWidget {
  final String fullName;
  final int level;
  final int xp;
  final VoidCallback onLogout;

  const _AppBar({
    required this.fullName,
    required this.level,
    required this.xp,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 80,
      floating: true,
      snap: true,
      backgroundColor: AppColors.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: 16,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShaderMask(
            shaderCallback: (b) => AppColors.gradientPrimary.createShader(b),
            child: Text('Mission 27', style: AppTypography.titleLarge),
          ),
          Text(
            'Welcome back, $fullName',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.report_problem_outlined, color: AppColors.warning, size: 20),
          tooltip: 'Log Roadblock',
          onPressed: () => ObstaclesLogSheet.show(context),
        ),
        _LevelBadge(level: level, xp: xp),
        IconButton(
          icon: const Icon(Icons.logout_outlined, color: AppColors.textTertiary, size: 20),
          onPressed: onLogout,
        ),
      ],
    );
  }
}

class _LevelBadge extends StatelessWidget {
  final int level;
  final int xp;

  const _LevelBadge({required this.level, required this.xp});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: AppColors.gradientPrimary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'LVL $level',
        style: AppTypography.labelSmall.copyWith(color: AppColors.textPrimary),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  final dynamic summary;
  const _DashboardContent({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        _GrowthScoreSection(summary: summary)
            .animate()
            .fadeIn(duration: 600.ms)
            .scale(begin: const Offset(0.95, 0.95)),
        const SizedBox(height: 12),
        const NudgeBanner().animate().fadeIn(delay: 150.ms),
        const SizedBox(height: 8),
        // Domino Task
        const DominoTaskWidget().animate().fadeIn(delay: 180.ms),
        const SizedBox(height: 4),
        // Today's Central Tasks
        const TodayTasksWidget().animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 4),
        // Daily Reflection
        const EveningRetroWidget().animate().fadeIn(delay: 220.ms),
        const SizedBox(height: 4),
        Text('Growth Dimensions', style: AppTypography.titleMedium)
            .animate()
            .fadeIn(delay: 240.ms),
        const SizedBox(height: 12),
        ScoreGrid(scores: summary.today)
            .animate()
            .fadeIn(delay: 300.ms)
            .slideY(begin: 0.1),
        // Timed Tasks
        const SizedBox(height: 4),
        const TimedTasksWidget().animate().fadeIn(delay: 340.ms),
        // Day Events
        const SizedBox(height: 4),
        const DayEventsWidget().animate().fadeIn(delay: 360.ms),
        // Trends Chart
        const SizedBox(height: 4),
        const TrendsChartWidget().animate().fadeIn(delay: 400.ms),
        if (summary.neglectedDomains.isNotEmpty) ...[
          const SizedBox(height: 24),
          _NeglectedSection(domains: summary.neglectedDomains)
              .animate()
              .fadeIn(delay: 450.ms),
        ],
        if (summary.activeStreaks.isNotEmpty) ...[
          const SizedBox(height: 24),
          _StreaksSection(streaks: summary.activeStreaks)
              .animate()
              .fadeIn(delay: 500.ms),
        ],
        const SizedBox(height: 24),
        _PredictiveSection(summary: summary)
            .animate()
            .fadeIn(delay: 600.ms),
      ],
    );
  }
}

class _GrowthScoreSection extends StatelessWidget {
  final dynamic summary;
  const _GrowthScoreSection({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          GrowthScoreRing(score: summary.today.growthScore),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Overall Growth', style: AppTypography.titleSmall),
                const SizedBox(height: 4),
                Text(
                  'Level ${summary.userLevel}',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.primary),
                ),
                const SizedBox(height: 12),
                _MiniMetric('Future Alignment', summary.today.futureSelfAlignment, AppColors.success),
                const SizedBox(height: 6),
                _MiniMetric('IELTS Readiness', summary.today.ieltsReadiness, AppColors.domainIELTS),
                const SizedBox(height: 6),
                _MiniMetric('AI Readiness', summary.today.aiReadiness, AppColors.domainAI),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _MiniMetric(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary)),
            Text('${value.toStringAsFixed(0)}%', style: AppTypography.labelSmall.copyWith(color: color)),
          ],
        ),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value / 100,
            backgroundColor: color.withOpacity(0.15),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 4,
          ),
        ),
      ],
    );
  }
}

class _NeglectedSection extends StatelessWidget {
  final List<String> domains;
  const _NeglectedSection({required this.domains});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 16),
            const SizedBox(width: 6),
            Text('Needs Attention', style: AppTypography.titleSmall.copyWith(color: AppColors.warning)),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: domains.map((d) => _DomainChip(label: d)).toList(),
        ),
      ],
    );
  }
}

class _DomainChip extends StatelessWidget {
  final String label;
  const _DomainChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.warning.withOpacity(0.4)),
      ),
      child: Text(label, style: AppTypography.labelSmall.copyWith(color: AppColors.warning)),
    );
  }
}

class _StreaksSection extends StatelessWidget {
  final List<Map<String, dynamic>> streaks;
  const _StreaksSection({required this.streaks});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('🔥', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text('Active Streaks', style: AppTypography.titleSmall),
          ],
        ),
        const SizedBox(height: 8),
        ...streaks.map((s) => _StreakTile(streak: s)).toList(),
      ],
    );
  }
}

class _StreakTile extends StatelessWidget {
  final Map<String, dynamic> streak;
  const _StreakTile({required this.streak});

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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(streak['name'] as String, style: AppTypography.labelLarge),
                Text(streak['domain'] as String, style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary)),
              ],
            ),
          ),
          Text(
            '${streak['streak']} days',
            style: AppTypography.titleSmall.copyWith(color: AppColors.accent),
          ),
        ],
      ),
    );
  }
}

class _PredictiveSection extends StatelessWidget {
  final dynamic summary;
  const _PredictiveSection({required this.summary});

  @override
  Widget build(BuildContext context) {
    final burnout = summary.today.burnoutRisk as double;
    final isolation = summary.today.isolationRisk as double;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Risk Indicators', style: AppTypography.titleSmall),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _RiskCard('Burnout Risk', burnout, Icons.local_fire_department_outlined, AppColors.error)),
            const SizedBox(width: 12),
            Expanded(child: _RiskCard('Isolation Risk', isolation, Icons.signal_wifi_off_outlined, AppColors.warning)),
          ],
        ),
      ],
    );
  }
}

class _RiskCard extends StatelessWidget {
  final String label;
  final double risk;
  final IconData icon;
  final Color color;

  const _RiskCard(this.label, this.risk, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    final safeColor = risk < 30 ? AppColors.success : (risk < 60 ? AppColors.warning : color);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: safeColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: safeColor, size: 18),
          const SizedBox(height: 8),
          Text('${risk.toStringAsFixed(0)}%', style: TextStyle(color: safeColor, fontSize: 22, fontWeight: FontWeight.w800)),
          Text(label, style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
      ],
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 32),
          const SizedBox(height: 8),
          Text('Could not load dashboard', style: AppTypography.titleSmall.copyWith(color: AppColors.error)),
          const SizedBox(height: 4),
          Text(message, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ── 3 AM Wind-Down Sheet ─────────────────────────────────────────────────────

class _WindDownSheet extends StatelessWidget {
  const _WindDownSheet();

  static const _options = [
    {'emoji': '🧘', 'title': '5-min Stretch', 'desc': 'Decompress your body after the grind'},
    {'emoji': '🎧', 'title': 'IELTS Podcast', 'desc': 'Wind down with English listening practice'},
    {'emoji': '📄', 'title': 'Read 1 Abstract', 'desc': 'Light AI research — 5 min read'},
    {'emoji': '😴', 'title': 'Sleep Now', 'desc': 'Recovery is productivity too'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🌙', style: TextStyle(fontSize: 32)),
              const SizedBox(height: 8),
              Text('Job Done. Wind Down.', style: AppTypography.titleMedium),
              const SizedBox(height: 4),
              const Text('3 AM — work is over. Choose your transition ritual:', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 16),
              ..._options.map((o) => GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                  child: Row(children: [
                    Text(o['emoji']!, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 12),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(o['title']!, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                      Text(o['desc']!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ]),
                  ]),
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Slump Zone Sheet ─────────────────────────────────────────────────────────

class _SlumpZoneSheet extends StatelessWidget {
  const _SlumpZoneSheet();

  static const _options = [
    {'emoji': '📖', 'title': 'Vocab Flashcards', 'desc': 'Light IELTS practice — 5 mins'},
    {'emoji': '🤸', 'title': 'Light Stretching', 'desc': 'Get the blood flowing'},
    {'emoji': '🎙️', 'title': 'AI Podcast', 'desc': 'Passive listening — no effort needed'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('😴', style: TextStyle(fontSize: 32)),
              const SizedBox(height: 8),
              Text('Slump Zone (4-6 AM)', style: AppTypography.titleMedium),
              const SizedBox(height: 4),
              const Text('Your biological clock is slow right now. Heavy studying is blocked — try these instead:', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 16),
              ..._options.map((o) => GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                  child: Row(children: [
                    Text(o['emoji']!, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 12),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(o['title']!, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                      Text(o['desc']!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ]),
                  ]),
                ),
              )),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Text('Dismiss', style: TextStyle(color: AppColors.textTertiary, fontSize: 13), textAlign: TextAlign.center),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
