import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

class ContributionHeatmap extends StatelessWidget {
  final Map<DateTime, int> dataset;
  final Color baseColor;
  final int maxValue;

  const ContributionHeatmap({
    super.key,
    required this.dataset,
    this.baseColor = AppColors.primary,
    this.maxValue = 5,
  });

  // Calculate clean date key ignoring hours/minutes
  DateTime _dateOnly(DateTime dt) {
    return DateTime(dt.year, dt.month, dt.day);
  }

  Color _getColor(int val) {
    if (val == 0) return AppColors.border.withOpacity(0.4);
    final pct = (val / maxValue).clamp(0.0, 1.0);
    return baseColor.withOpacity(0.2 + pct * 0.8);
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    // Go back exactly 26 weeks (half a year) or 52 weeks (full year).
    // Let's do 20 weeks for mobile screen width constraints, or allow scrolling.
    // 26 weeks of columns
    final totalWeeks = 26;
    final startDate = today.subtract(Duration(days: totalWeeks * 7));
    
    // Find the first day (aligned to Sunday, where weekday = 7 in Dart or 0 based)
    // Sunday is 7, Monday is 1...
    // Let's align startDate to the preceding Sunday
    final startOffset = startDate.weekday == 7 ? 0 : startDate.weekday;
    final alignedStart = _dateOnly(startDate.subtract(Duration(days: startOffset)));

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: totalWeeks + 1,
        itemBuilder: (context, weekIdx) {
          return Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(7, (dayIdx) {
                final currentDay = alignedStart.add(Duration(days: weekIdx * 7 + dayIdx));
                final val = dataset[_dateOnly(currentDay)] ?? 0;
                
                return Tooltip(
                  message: '${currentDay.year}-${currentDay.month.toString().padLeft(2, '0')}-${currentDay.day.toString().padLeft(2, '0')}: $val logs',
                  child: Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(bottom: 3),
                    decoration: BoxDecoration(
                      color: _getColor(val),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          );
        },
      ),
    );
  }
}
