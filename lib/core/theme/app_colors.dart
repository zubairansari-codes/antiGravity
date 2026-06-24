/// AntiGravity colour palette.
///
/// Deep purple primary (space / anti-gravity feel),
/// warm amber accent, neutral surfaces.
library;

import 'package:flutter/material.dart';

abstract final class AppColors {
  // ── Primary ─────────────────────────────────────────────
  static const Color primary = Color(0xFF6C5CE7);
  static const Color primaryDark = Color(0xFF4834D4);
  static const Color primaryLight = Color(0xFFA29BFE);

  // ── Accent ──────────────────────────────────────────────
  static const Color accent = Color(0xFFFFA502);
  static const Color accentLight = Color(0xFFFFBE76);

  // ── Surfaces ────────────────────────────────────────────
  static const Color surface = Color(0xFFF8F9FA);
  static const Color surfaceVariant = Color(0xFFECECF5);
  static const Color background = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFFFFFFF);

  // ── Text ────────────────────────────────────────────────
  static const Color onSurface = Color(0xFF2D3436);
  static const Color onSurfaceVariant = Color(0xFF636E72);
  static const Color onPrimary = Color(0xFFFFFFFF);

  // ── Status ──────────────────────────────────────────────
  static const Color success = Color(0xFF00B894);
  static const Color error = Color(0xFFFF7675);
  static const Color warning = Color(0xFFFDCB6E);

  // ── Gradients ───────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent, accentLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Voice wave colours ──────────────────────────────────
  static const Color waveActive = primary;
  static const Color waveSpeaking = accent;
  static const Color waveIdle = Color(0xFFDFE6E9);
}
