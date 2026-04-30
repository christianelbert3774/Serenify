import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // === DARK THEME COLOR PALETTE ===
  // Deep navy/slate — calm, immersive, premium
  static const _darkBg = Color(0xFF0D1117);
  static const _darkSurface = Color(0xFF161B22);
  static const _darkBorder = Color(0xFF30363D);
  static const _darkTextPrimary = Color(0xFFE6EDF3);
  static const _darkTextSecondary = Color(0xFF8B949E);
  static const _darkAccent = Color(0xFF7C8AFF);
  static const _darkAccentSoft = Color(0xFF2D3250);

  // === LIGHT THEME COLOR PALETTE ===
  // Warm cream/soft white — gentle, airy
  static const _lightBg = Color(0xFFF6F5F0);
  static const _lightSurface = Color(0xFFFFFFFF);
  static const _lightBorder = Color(0xFFE0DDD5);
  static const _lightTextPrimary = Color(0xFF1A1A2E);
  static const _lightTextSecondary = Color(0xFF6B6B7B);
  static const _lightAccent = Color(0xFF5B63D3);
  static const _lightAccentSoft = Color(0xFFE8E7F5);


  // =============================
  //  DARK THEME
  // =============================
  static ThemeData dark() {
    final textTheme = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: _darkBg,
      textTheme: textTheme,
      colorScheme: const ColorScheme.dark(
        surface: _darkSurface,
        primary: _darkAccent,
        onPrimary: Colors.white,
        onSurface: _darkTextPrimary,
        outline: _darkBorder,
        secondaryContainer: _darkAccentSoft,
        onSecondaryContainer: _darkAccent,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: _darkBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: _darkTextPrimary,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: _darkTextSecondary),
      ),
      cardTheme: CardThemeData(
        color: _darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _darkBorder, width: 0.5),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: _darkAccent,
        inactiveTrackColor: _darkBorder,
        thumbColor: _darkAccent,
        overlayColor: _darkAccent.withValues(alpha: 0.15),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return _darkAccent;
          return _darkTextSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return _darkAccentSoft;
          return _darkBorder;
        }),
      ),
      dividerTheme: const DividerThemeData(
        color: _darkBorder,
        thickness: 0.5,
      ),
    );
  }

  // =============================
  //  LIGHT THEME
  // =============================
  static ThemeData light() {
    final textTheme = GoogleFonts.interTextTheme(ThemeData.light().textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: _lightBg,
      textTheme: textTheme,
      colorScheme: const ColorScheme.light(
        surface: _lightSurface,
        primary: _lightAccent,
        onPrimary: Colors.white,
        onSurface: _lightTextPrimary,
        outline: _lightBorder,
        secondaryContainer: _lightAccentSoft,
        onSecondaryContainer: _lightAccent,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: _lightBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: _lightTextPrimary,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: _lightTextSecondary),
      ),
      cardTheme: CardThemeData(
        color: _lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _lightBorder, width: 0.5),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: _lightAccent,
        inactiveTrackColor: _lightBorder,
        thumbColor: _lightAccent,
        overlayColor: _lightAccent.withValues(alpha: 0.15),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return _lightAccent;
          return _lightTextSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return _lightAccentSoft;
          return _lightBorder;
        }),
      ),
      dividerTheme: const DividerThemeData(
        color: _lightBorder,
        thickness: 0.5,
      ),
    );
  }
}
