import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';

class M27Card extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderRadius;
  final List<BoxShadow>? shadows;

  const M27Card({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius = 16,
    this.shadows,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor ?? AppColors.surface,
      borderRadius: BorderRadius.circular(borderRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(borderRadius),
        onTap: onTap,
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: borderColor ?? AppColors.border),
            boxShadow: shadows,
          ),
          child: child,
        ),
      ),
    );
  }
}

class M27ScoreCard extends StatelessWidget {
  final String label;
  final double score;
  final Color color;
  final IconData icon;
  final String? trend;

  const M27ScoreCard({
    super.key,
    required this.label,
    required this.score,
    required this.color,
    required this.icon,
    this.trend,
  });

  @override
  Widget build(BuildContext context) {
    return M27Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              if (trend != null)
                Text(
                  trend!,
                  style: AppTypography.labelSmall.copyWith(
                    color: trend!.startsWith('+') ? AppColors.success : AppColors.error,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${score.toStringAsFixed(0)}',
            style: AppTypography.headlineSmall.copyWith(color: color, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(label, style: AppTypography.labelSmall),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score / 100,
              backgroundColor: color.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
}
