import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract final class AppTypography {
  static const _base = TextStyle(
    fontFamily: 'SF Pro Display',
    color: AppColors.textPrimary,
    letterSpacing: 0,
  );

  // ── Display ─────────────────────────────────────────────────────────────
  static final displayLarge = _base.copyWith(fontSize: 57, fontWeight: FontWeight.w300, letterSpacing: -0.25);
  static final displayMedium = _base.copyWith(fontSize: 45, fontWeight: FontWeight.w300);
  static final displaySmall = _base.copyWith(fontSize: 36, fontWeight: FontWeight.w400);

  // ── Headline ────────────────────────────────────────────────────────────
  static final headlineLarge = _base.copyWith(fontSize: 32, fontWeight: FontWeight.w700);
  static final headlineMedium = _base.copyWith(fontSize: 28, fontWeight: FontWeight.w600);
  static final headlineSmall = _base.copyWith(fontSize: 24, fontWeight: FontWeight.w600);

  // ── Title ───────────────────────────────────────────────────────────────
  static final titleLarge = _base.copyWith(fontSize: 22, fontWeight: FontWeight.w600);
  static final titleMedium = _base.copyWith(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.15);
  static final titleSmall = _base.copyWith(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.1);

  // ── Body ────────────────────────────────────────────────────────────────
  static final bodyLarge = _base.copyWith(fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: 0.5);
  static final bodyMedium = _base.copyWith(fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: 0.25);
  static final bodySmall = _base.copyWith(fontSize: 12, fontWeight: FontWeight.w400, letterSpacing: 0.4);

  // ── Label ───────────────────────────────────────────────────────────────
  static final labelLarge = _base.copyWith(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1);
  static final labelMedium = _base.copyWith(fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.5);
  static final labelSmall = _base.copyWith(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.5);

  // ── Score / Metric (custom) ──────────────────────────────────────────────
  static final scoreDisplay = _base.copyWith(
    fontSize: 48,
    fontWeight: FontWeight.w800,
    letterSpacing: -1,
  );
  static final scoreLabel = _base.copyWith(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.2,
    color: AppColors.textSecondary,
  );
}
