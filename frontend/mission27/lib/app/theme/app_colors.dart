import 'package:flutter/material.dart';

abstract final class AppColors {
  // ── Backgrounds ────────────────────────────────────────────────────────
  static const background = Color(0xFF0A0A0F);
  static const surface = Color(0xFF12121A);
  static const surfaceVariant = Color(0xFF1A1A26);
  static const surfaceElevated = Color(0xFF222232);

  // ── Brand ──────────────────────────────────────────────────────────────
  static const primary = Color(0xFF6C63FF);
  static const primaryLight = Color(0xFF9D97FF);
  static const primaryDark = Color(0xFF4A42CC);

  static const secondary = Color(0xFF00D4FF);
  static const secondaryDark = Color(0xFF009AB8);

  static const accent = Color(0xFFFFB347);
  static const accentDark = Color(0xFFCC8A20);

  // ── Status ─────────────────────────────────────────────────────────────
  static const success = Color(0xFF00E676);
  static const successDark = Color(0xFF00B358);
  static const warning = Color(0xFFFF9800);
  static const warningDark = Color(0xFFCC7700);
  static const error = Color(0xFFFF5252);
  static const errorDark = Color(0xFFCC2E2E);
  static const info = Color(0xFF29B6F6);

  // ── Text ───────────────────────────────────────────────────────────────
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFB0B0C4);
  static const textTertiary = Color(0xFF6B6B85);
  static const textDisabled = Color(0xFF3D3D55);

  // ── Domain Colors (one per growth domain) ──────────────────────────────
  static const domainAI = Color(0xFF6C63FF);
  static const domainCS = Color(0xFF00D4FF);
  static const domainIELTS = Color(0xFF00E676);
  static const domainHealth = Color(0xFFFF5252);
  static const domainSocial = Color(0xFFFFB347);
  static const domainResearch = Color(0xFF29B6F6);
  static const domainCareer = Color(0xFFAB47BC);
  static const domainKnowledge = Color(0xFF26C6DA);
  static const domainPersonal = Color(0xFFEC407A);
  static const domainSports = Color(0xFF66BB6A);

  // ── Semantic aliases for feature pages ────────────────────────────────
  static const aiEngineering = domainAI;
  static const csFoundations = domainCS;
  static const social = domainSocial;
  static const habit = Color(0xFF66BB6A);
  static const cardBackground = surfaceVariant;

  // ── Borders / Dividers ─────────────────────────────────────────────────
  static const border = Color(0xFF2A2A3E);
  static const borderLight = Color(0xFF383856);

  // ── Gradients ──────────────────────────────────────────────────────────
  static const gradientPrimary = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const gradientAccent = LinearGradient(
    colors: [accent, error],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const gradientSuccess = LinearGradient(
    colors: [success, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
