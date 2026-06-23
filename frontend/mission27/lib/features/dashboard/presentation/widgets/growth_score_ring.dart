import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';

class GrowthScoreRing extends StatelessWidget {
  final double score;
  final double size;

  const GrowthScoreRing({super.key, required this.score, this.size = 160});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(score: score),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                score.toStringAsFixed(0),
                style: AppTypography.scoreDisplay.copyWith(fontSize: size * 0.25),
              ),
              Text(
                'GROWTH',
                style: AppTypography.scoreLabel.copyWith(fontSize: size * 0.07),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double score;
  const _RingPainter({required this.score});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    const strokeWidth = 10.0;

    final trackPaint = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    final sweep = 2 * math.pi * (score.clamp(0.0, 100.0) / 100);
    if (sweep > 0.001) {
      final gradient = SweepGradient(
        colors: [AppColors.primary, AppColors.secondary],
        startAngle: -math.pi / 2,
        endAngle: -math.pi / 2 + sweep,
      );

      final arcRect = Rect.fromCircle(center: center, radius: radius);
      final progressPaint = Paint()
        ..shader = gradient.createShader(arcRect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(arcRect, -math.pi / 2, sweep, false, progressPaint);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.score != score;
}
