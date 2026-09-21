/// AarogyaMP — App Theme (Milestone 0 stub)
/// Person C owns this file.
///
/// Risk level colors MUST match Reference §6 Risk Level Bands:
///   EMERGENCY → Red, full-screen
///   HIGH       → Orange
///   MODERATE   → Yellow
///   LOW        → Green
///
/// TODO (M1 — Person C): Build full design system with colors, typography, spacing.

import 'package:flutter/material.dart';

class AppTheme {
  // ── Risk level colors (per Reference §6) ────────────────────
  static const Color riskEmergency = Color(0xFFD32F2F);   // Red
  static const Color riskHigh = Color(0xFFF57C00);        // Orange
  static const Color riskModerate = Color(0xFFF9A825);    // Yellow
  static const Color riskLow = Color(0xFF388E3C);         // Green

  // ── Brand colors (placeholder — Person C to define in M1) ──
  static const Color primary = Color(0xFF1E88E5);
  static const Color primaryDark = Color(0xFF1565C0);
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Colors.white;

  // ── Light theme ─────────────────────────────────────────────
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: primary),
        scaffoldBackgroundColor: background,
      );

  // ── Dark theme ──────────────────────────────────────────────
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          brightness: Brightness.dark,
        ),
      );
}
