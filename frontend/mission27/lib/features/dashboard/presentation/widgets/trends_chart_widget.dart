import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/network/api_client.dart';

// ── Models ────────────────────────────────────────────────────────────────────

class TrendPoint {
  final DateTime date;
  final int xp;
  final int habitsDone;
  final int habitsTotal;
  TrendPoint.fromJson(Map<String, dynamic> j)
      : date = DateTime.parse(j['date']),
        xp = j['xp'] as int,
        habitsDone = j['habits_done'] as int,
        habitsTotal = j['habits_total'] as int;
}

// ── Providers ─────────────────────────────────────────────────────────────────

final weeklyTrendsProvider = FutureProvider<List<TrendPoint>>((ref) async {
  final resp = await ref.read(dioProvider).get('/dashboard/trends', queryParameters: {'period': 7});
  return (resp.data['days'] as List).map((d) => TrendPoint.fromJson(d)).toList();
});

final monthlyTrendsProvider = FutureProvider<List<TrendPoint>>((ref) async {
  final resp = await ref.read(dioProvider).get('/dashboard/trends', queryParameters: {'period': 30});
  return (resp.data['days'] as List).map((d) => TrendPoint.fromJson(d)).toList();
});

// ── Widget ────────────────────────────────────────────────────────────────────

class TrendsChartWidget extends ConsumerStatefulWidget {
  const TrendsChartWidget({super.key});

  @override
  ConsumerState<TrendsChartWidget> createState() => _TrendsChartWidgetState();
}

class _TrendsChartWidgetState extends ConsumerState<TrendsChartWidget> {
  bool _monthly = false;
  bool _showXp = true;

  @override
  Widget build(BuildContext context) {
    final provider = _monthly ? monthlyTrendsProvider : weeklyTrendsProvider;
    final async = ref.watch(provider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Row(children: [
            const Text('📈', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text('Progress Trends', style: AppTypography.titleMedium),
            const Spacer(),
            _ToggleChip(label: 'XP', selected: _showXp, color: AppColors.primary, onTap: () => setState(() => _showXp = true)),
            const SizedBox(width: 6),
            _ToggleChip(label: 'Habits', selected: !_showXp, color: AppColors.secondary, onTap: () => setState(() => _showXp = false)),
          ]),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            _PeriodBtn(label: '7D', selected: !_monthly, onTap: () => setState(() => _monthly = false)),
            const SizedBox(width: 8),
            _PeriodBtn(label: '30D', selected: _monthly, onTap: () => setState(() => _monthly = true)),
          ]),
        ),
        const SizedBox(height: 12),
        async.when(
          loading: () => const SizedBox(height: 140, child: Center(child: CircularProgressIndicator())),
          error: (_, __) => const SizedBox.shrink(),
          data: (points) => _Chart(points: points, showXp: _showXp),
        ),
        const SizedBox(height: 8),
      ]),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _ToggleChip({required this.label, required this.selected, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: selected ? color.withOpacity(0.15) : Colors.transparent,
        border: Border.all(color: selected ? color : AppColors.border),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(color: selected ? color : AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
    ),
  );
}

class _PeriodBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _PeriodBtn({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Text(label, style: TextStyle(
      color: selected ? AppColors.primary : AppColors.textTertiary,
      fontSize: 12, fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
    )),
  );
}

class _Chart extends StatelessWidget {
  final List<TrendPoint> points;
  final bool showXp;
  const _Chart({required this.points, required this.showXp});

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const SizedBox(height: 120);
    final values = showXp ? points.map((p) => p.xp.toDouble()).toList() : points.map((p) => p.habitsTotal > 0 ? p.habitsDone / p.habitsTotal * 100 : 0.0).toList();
    final maxY = values.reduce((a, b) => a > b ? a : b);
    final effectiveMax = (maxY * 1.2).clamp(10.0, double.infinity);
    final color = showXp ? AppColors.primary : AppColors.secondary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 16, 0),
      child: SizedBox(
        height: 140,
        child: LineChart(LineChartData(
          minY: 0,
          maxY: effectiveMax,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(color: AppColors.border, strokeWidth: 0.5),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32,
                getTitlesWidget: (v, _) => Text(v.toInt().toString(), style: const TextStyle(color: AppColors.textTertiary, fontSize: 9)))),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 22,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= points.length) return const SizedBox();
                  final step = points.length <= 7 ? 1 : 7;
                  if (i % step != 0) return const SizedBox();
                  return Text(DateFormat('M/d').format(points[i].date), style: const TextStyle(color: AppColors.textTertiary, fontSize: 9));
                })),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          lineBarsData: [LineChartBarData(
            spots: List.generate(points.length, (i) => FlSpot(i.toDouble(), values[i])),
            isCurved: true,
            color: color,
            barWidth: 2.5,
            dotData: FlDotData(show: points.length <= 10,
                getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(radius: 3, color: color, strokeWidth: 1.5, strokeColor: AppColors.surface)),
            belowBarData: BarAreaData(show: true, color: color.withOpacity(0.08)),
          )],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) => spots.map((s) {
                final i = s.spotIndex;
                final label = showXp ? '${s.y.toInt()} XP' : '${s.y.toStringAsFixed(0)}%';
                return LineTooltipItem(label, TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12));
              }).toList(),
            ),
          ),
        )),
      ),
    );
  }
}
