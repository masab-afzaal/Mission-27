import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/network/api_client.dart';

// ── Models ──────────────────────────────────────────────────────────────────

class NamazLog {
  final DateTime logDate;
  final bool fajr, dhuhr, asr, maghrib, isha;
  final int count, xpEarned;

  NamazLog.fromJson(Map<String, dynamic> j)
      : logDate = DateTime.parse(j['log_date']),
        fajr = j['fajr'] as bool,
        dhuhr = j['dhuhr'] as bool,
        asr = j['asr'] as bool,
        maghrib = j['maghrib'] as bool,
        isha = j['isha'] as bool,
        count = j['count'] as int,
        xpEarned = j['xp_earned'] as int;
}

class NamazDayStat {
  final DateTime date;
  final int count;
  NamazDayStat.fromJson(Map<String, dynamic> j)
      : date = DateTime.parse(j['date']),
        count = j['count'] as int;
}

// ── Providers ────────────────────────────────────────────────────────────────

final namazTodayProvider = FutureProvider<NamazLog>((ref) async {
  final resp = await ref.read(dioProvider).get('/namaz/today');
  return NamazLog.fromJson(resp.data);
});

final namazWeeklyProvider = FutureProvider<List<NamazDayStat>>((ref) async {
  final resp = await ref.read(dioProvider).get('/namaz/stats', queryParameters: {'period': 7});
  return (resp.data['days'] as List).map((d) => NamazDayStat.fromJson(d)).toList();
});

final namazMonthlyProvider = FutureProvider<List<NamazDayStat>>((ref) async {
  final resp = await ref.read(dioProvider).get('/namaz/stats', queryParameters: {'period': 30});
  return (resp.data['days'] as List).map((d) => NamazDayStat.fromJson(d)).toList();
});

// ── Page ─────────────────────────────────────────────────────────────────────

class NamazPage extends ConsumerStatefulWidget {
  const NamazPage({super.key});

  @override
  ConsumerState<NamazPage> createState() => _NamazPageState();
}

class _NamazPageState extends ConsumerState<NamazPage> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  bool _updating = false;

  static const _prayers = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];
  static const _prayerLabels = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
  static const _prayerEmojis = ['🌙', '☀️', '🌤️', '🌅', '🌜'];
  static const _prayerTimes = ['Pre-Dawn', 'Noon', 'Afternoon', 'Sunset', 'Night'];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('Namaz Tracker', style: AppTypography.titleLarge),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [Tab(text: 'Today'), Tab(text: 'Weekly'), Tab(text: 'Monthly')],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [_TodayTab(onUpdated: _onUpdated, updating: _updating, onToggle: _toggle), const _WeeklyTab(), const _MonthlyTab()],
      ),
    );
  }

  void _onUpdated() {
    ref.invalidate(namazTodayProvider);
    ref.invalidate(namazWeeklyProvider);
    ref.invalidate(namazMonthlyProvider);
  }

  Future<void> _toggle(NamazLog current, String prayer) async {
    if (_updating) return;
    final updated = <String, bool>{
      'fajr': current.fajr,
      'dhuhr': current.dhuhr,
      'asr': current.asr,
      'maghrib': current.maghrib,
      'isha': current.isha,
    };
    if (updated[prayer] == true) {
      // Once checked, it cannot be unchecked
      return;
    }
    _updating = true; // synchronous guard — prevents double-tap before setState fires
    setState(() {});
    try {
      updated[prayer] = true;
      await ref.read(dioProvider).post('/namaz/log', data: updated);
      ref.invalidate(namazTodayProvider);
      ref.invalidate(namazWeeklyProvider);
      ref.invalidate(namazMonthlyProvider);
    } catch (_) {} finally {
      _updating = false;
      if (mounted) setState(() {});
    }
  }
}

class _TodayTab extends ConsumerWidget {
  final VoidCallback onUpdated;
  final bool updating;
  final Future<void> Function(NamazLog, String) onToggle;

  const _TodayTab({required this.onUpdated, required this.updating, required this.onToggle});

  static const _prayers = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];
  static const _labels = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
  static const _emojis = ['🌙', '☀️', '🌤️', '🌅', '🌜'];
  static const _times = ['Pre-Dawn', 'Noon', 'Afternoon', 'Sunset', 'Night'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(namazTodayProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (log) => SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _RingHeader(count: log.count, xp: log.xpEarned),
            const SizedBox(height: 24),
            ...List.generate(5, (i) {
              final isChecked = [log.fajr, log.dhuhr, log.asr, log.maghrib, log.isha][i];
              return _PrayerTile(
                emoji: _emojis[i],
                label: _labels[i],
                time: _times[i],
                checked: isChecked,
                onTap: (updating || isChecked) ? () {} : () => onToggle(log, _prayers[i]),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _RingHeader extends StatelessWidget {
  final int count;
  final int xp;
  const _RingHeader({required this.count, required this.xp});

  @override
  Widget build(BuildContext context) {
    final pct = count / 5.0;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withOpacity(0.2), AppColors.secondary.withOpacity(0.1)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(children: [
        SizedBox(
          width: 80, height: 80,
          child: Stack(alignment: Alignment.center, children: [
            CircularProgressIndicator(
              value: pct,
              strokeWidth: 8,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
            Text('$count/5', style: AppTypography.titleMedium.copyWith(color: AppColors.primary)),
          ]),
        ),
        const SizedBox(width: 20),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(count == 5 ? '🌟 Alhamdulillah!' : count >= 3 ? '💪 Keep going' : count > 0 ? '🤲 Good start' : "Let's begin",
              style: AppTypography.titleMedium),
          const SizedBox(height: 4),
          Text('$count of 5 prayers today', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          if (xp > 0) Text('+$xp XP earned', style: const TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
      ]),
    );
  }
}

class _PrayerTile extends StatelessWidget {
  final String emoji, label, time;
  final bool checked;
  final VoidCallback onTap;

  const _PrayerTile({required this.emoji, required this.label, required this.time, required this.checked, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: checked ? AppColors.primary.withOpacity(0.12) : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: checked ? AppColors.primary.withOpacity(0.5) : AppColors.border),
        ),
        child: Row(children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(color: checked ? AppColors.primary : AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 15)),
            Text(time, style: const TextStyle(color: AppColors.textTertiary, fontSize: 12)),
          ])),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 26, height: 26,
            decoration: BoxDecoration(
              color: checked ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: checked ? AppColors.primary : AppColors.border, width: 1.5),
            ),
            child: checked ? const Icon(Icons.check_rounded, color: Colors.white, size: 16) : null,
          ),
        ]),
      ),
    );
  }
}

class _WeeklyTab extends ConsumerWidget {
  const _WeeklyTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(namazWeeklyProvider).when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (days) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          _NamazBarChart(days: days, title: 'Last 7 Days'),
          const SizedBox(height: 24),
          _NamazSummary(days: days),
        ]),
      ),
    );
  }
}

class _MonthlyTab extends ConsumerWidget {
  const _MonthlyTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(namazMonthlyProvider).when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (days) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          _NamazMonthlyLineChart(days: days, title: 'Last 30 Days'),
          const SizedBox(height: 24),
          _NamazSummary(days: days),
        ]),
      ),
    );
  }
}

class _NamazMonthlyLineChart extends StatelessWidget {
  final List<NamazDayStat> days;
  final String title;
  const _NamazMonthlyLineChart({required this.days, required this.title});

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) return const SizedBox(height: 160);

    final spots = List.generate(days.length, (i) {
      return FlSpot(i.toDouble(), days[i].count.toDouble());
    });

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: AppTypography.titleMedium),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '30-Day Trend',
                  style: AppTypography.labelSmall.copyWith(color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: 5.2,
                minX: 0,
                maxX: (days.length - 1).toDouble(),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppColors.border.withOpacity(0.3),
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: 1,
                      getTitlesWidget: (v, _) {
                        if (v > 5) return const SizedBox();
                        return Text(
                          '${v.toInt()}',
                          style: const TextStyle(color: AppColors.textTertiary, fontSize: 10),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      interval: 6,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= days.length) return const SizedBox();
                        return Text(
                          DateFormat('d/M').format(days[i].date),
                          style: const TextStyle(color: AppColors.textTertiary, fontSize: 8),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withOpacity(0.25),
                          AppColors.primary.withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) => touchedSpots.map((s) {
                      final i = s.spotIndex;
                      if (i < 0 || i >= days.length) return null;
                      final day = days[i];
                      final dateStr = DateFormat('E, d MMM').format(day.date);
                      return LineTooltipItem(
                        '$dateStr\n${day.count} / 5 Prayers',
                        const TextStyle(
                          color: AppColors.primaryLight,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NamazBarChart extends StatelessWidget {
  final List<NamazDayStat> days;
  final String title;
  const _NamazBarChart({required this.days, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: AppTypography.titleMedium),
        const SizedBox(height: 16),
        SizedBox(
          height: 160,
          child: BarChart(BarChartData(
            maxY: 5,
            minY: 0,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 1,
              getDrawingHorizontalLine: (_) => FlLine(color: AppColors.border, strokeWidth: 0.5),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 20, interval: 1,
                  getTitlesWidget: (v, _) => Text('${v.toInt()}', style: const TextStyle(color: AppColors.textTertiary, fontSize: 10)))),
              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 24,
                  getTitlesWidget: (v, _) {
                    final i = v.toInt();
                    if (i < 0 || i >= days.length) return const SizedBox();
                    if (days.length <= 10 || i % 1 == 0) {
                      return Text(DateFormat('E').format(days[i].date),
                          style: const TextStyle(color: AppColors.textTertiary, fontSize: 9));
                    }
                    return const SizedBox();
                  })),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            barGroups: List.generate(days.length, (i) {
              final pct = days[i].count / 5.0;
              final color = pct == 1.0 ? const Color(0xFF3CCF7A) : pct >= 0.6 ? AppColors.primary : pct > 0 ? AppColors.accent : AppColors.border;
              return BarChartGroupData(x: i, barRods: [
                BarChartRodData(toY: days[i].count.toDouble(), color: color, width: days.length <= 10 ? 16 : 6, borderRadius: BorderRadius.circular(4)),
              ]);
            }),
          )),
        ),
      ]),
    );
  }
}

class _NamazSummary extends StatelessWidget {
  final List<NamazDayStat> days;
  const _NamazSummary({required this.days});

  @override
  Widget build(BuildContext context) {
    final total = days.fold(0, (s, d) => s + d.count);
    final perfect = days.where((d) => d.count == 5).length;
    final avg = days.isEmpty ? 0.0 : total / days.length;
    return Row(children: [
      _Stat('Total', total.toString(), 'prayers'),
      _Stat('Perfect Days', perfect.toString(), 'days'),
      _Stat('Daily Avg', avg.toStringAsFixed(1), 'prayers/day'),
    ]);
  }
}

class _Stat extends StatelessWidget {
  final String label, value, unit;
  const _Stat(this.label, this.value, this.unit);

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Column(children: [
        Text(value, style: AppTypography.headlineSmall.copyWith(color: AppColors.primary)),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11), textAlign: TextAlign.center),
        Text(unit, style: const TextStyle(color: AppColors.textTertiary, fontSize: 10)),
      ]),
    ),
  );
}
