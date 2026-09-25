// AarogyaMP — App Theme (M1 — Person C)
// Design system from Stitch project 5690353454197586822
// Primary: #087F5B Deep Emerald | Font: Noto Sans | Mode: Light

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppColors {
  // ── Brand ──────────────────────────────────────────────────────
  static const Color primary = Color(0xFF087F5B);
  static const Color primaryDark = Color(0xFF065F44);
  static const Color primaryLight = Color(0xFFDFF5EC);
  static const Color secondary = Color(0xFF0F766E);
  static const Color tertiary = Color(0xFF65A30D); // AYUSH green

  // ── Surfaces ───────────────────────────────────────────────────
  static const Color background = Color(0xFFE7FEFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceContainer = Color(0xFFDCF2F0);
  static const Color surfaceContainerLow = Color(0xFFE1F8F6);
  static const Color surfaceBorder = Color(0xFFDDE7E4);

  // ── On-colors ──────────────────────────────────────────────────
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF0A1F1E);
  static const Color onSurfaceVariant = Color(0xFF3E4943);
  static const Color outline = Color(0xFF6E7A73);
  static const Color outlineVariant = Color(0xFFBDC9C1);

  // ── Risk level badges (Reference §6 — MUST NOT CHANGE) ─────────
  static const Color riskEmergencyText = Color(0xFFDC2626);
  static const Color riskEmergencyBg = Color(0xFFFEF2F2);
  static const Color riskEmergencyBorder = Color(0xFFF87171);

  static const Color riskHighText = Color(0xFFD97706);
  static const Color riskHighBg = Color(0xFFFEF3C7);
  static const Color riskHighBorder = Color(0xFFFBBF24);

  static const Color riskModerateText = Color(0xFF3F6212);
  static const Color riskModerateBg = Color(0xFFF7FEE7);
  static const Color riskModerateBorder = Color(0xFFA3E635);

  static const Color riskLowText = Color(0xFF065F44);
  static const Color riskLowBg = Color(0xFFECFDF5);
  static const Color riskLowBorder = Color(0xFF6EE7B7);

  // ── Emergency SOS screen ───────────────────────────────────────
  static const Color emergencyRed = Color(0xFFDC2626);
  static const Color emergencyRedDark = Color(0xFFB91C1C);
  static const Color emergencyRedBg = Color(0xFFFEF2F2);

  // ── Chat bubbles ───────────────────────────────────────────────
  static const Color chatPatientBubble = Color(0xFF087F5B);
  static const Color chatDoctorBubble = Color(0xFFDCF2F0);
}

class AppTheme {
  static ThemeData get light {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryLight,
      onPrimaryContainer: Color(0xFF002115),
      secondary: AppColors.secondary,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFF99EFE5),
      onSecondaryContainer: Color(0xFF006F67),
      tertiary: AppColors.tertiary,
      onTertiary: Colors.white,
      tertiaryContainer: Color(0xFF4A7C00),
      onTertiaryContainer: Color(0xFFDDFFB2),
      error: Color(0xFFBA1A1A),
      onError: Colors.white,
      errorContainer: Color(0xFFFFDAD6),
      onErrorContainer: Color(0xFF93000A),
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
      surfaceContainerHighest: Color(0xFFD0E7E5),
      onSurfaceVariant: AppColors.onSurfaceVariant,
      outline: AppColors.outline,
      outlineVariant: AppColors.outlineVariant,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: Color(0xFF203433),
      onInverseSurface: Color(0xFFDFF5F3),
      inversePrimary: Color(0xFF78D9AF),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'NotoSans',

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: Color(0x1A172B2A),
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'NotoSans',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.onSurface,
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
      ),

      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.surfaceBorder),
        ),
        margin: EdgeInsets.zero,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          textStyle: const TextStyle(
            fontFamily: 'NotoSans',
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          elevation: 0,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(double.infinity, 48),
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          textStyle: const TextStyle(
            fontFamily: 'NotoSans',
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: AppColors.surfaceBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: AppColors.surfaceBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Color(0xFFBA1A1A)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Color(0xFFBA1A1A), width: 2),
        ),
        labelStyle: const TextStyle(
          fontFamily: 'NotoSans',
          fontSize: 14,
          color: AppColors.onSurfaceVariant,
        ),
        hintStyle: TextStyle(
          fontFamily: 'NotoSans',
          fontSize: 14,
          color: AppColors.onSurfaceVariant.withOpacity(0.7),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.surfaceBorder,
        thickness: 1,
        space: 0,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primaryLight,
        labelStyle: const TextStyle(
          fontFamily: 'NotoSans',
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        side: const BorderSide(color: AppColors.surfaceBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.onSurfaceVariant,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),

      textTheme: const TextTheme(
        displayLarge: TextStyle(fontFamily: 'NotoSans', fontSize: 36, fontWeight: FontWeight.w700),
        displayMedium: TextStyle(fontFamily: 'NotoSans', fontSize: 28, fontWeight: FontWeight.w700),
        headlineLarge: TextStyle(fontFamily: 'NotoSans', fontSize: 30, fontWeight: FontWeight.w700),
        headlineMedium: TextStyle(fontFamily: 'NotoSans', fontSize: 24, fontWeight: FontWeight.w700),
        headlineSmall: TextStyle(fontFamily: 'NotoSans', fontSize: 22, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(fontFamily: 'NotoSans', fontSize: 18, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(fontFamily: 'NotoSans', fontSize: 16, fontWeight: FontWeight.w600),
        titleSmall: TextStyle(fontFamily: 'NotoSans', fontSize: 14, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(fontFamily: 'NotoSans', fontSize: 17, fontWeight: FontWeight.w400),
        bodyMedium: TextStyle(fontFamily: 'NotoSans', fontSize: 15, fontWeight: FontWeight.w400),
        bodySmall: TextStyle(fontFamily: 'NotoSans', fontSize: 13, fontWeight: FontWeight.w400),
        labelLarge: TextStyle(fontFamily: 'NotoSans', fontSize: 15, fontWeight: FontWeight.w600),
        labelMedium: TextStyle(fontFamily: 'NotoSans', fontSize: 13, fontWeight: FontWeight.w600),
        labelSmall: TextStyle(fontFamily: 'NotoSans', fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5),
      ),
    );
  }

  // Dark theme — keep as light variant for this app (healthcare = light only for now)
  static ThemeData get dark => light;
}
