import 'package:activefriends/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static final light = _build(
    brightness: Brightness.light,
    background: const Color(0xFFF4F3EF),
    surface: Colors.white,
    primary: const Color(0xFF14827B),
    primarySoft: const Color(0xFFE3F1EE),
    textPrimary: const Color(0xFF26241F),
    colors: const AppColors(
      accent: Color(0xFFE07A62),
      accentSoft: Color(0xFFFBEBE4),
      gold: Color(0xFFC79A17),
      danger: Color(0xFFB3392E),
      surfaceAlt: Color(0xFFF7F6F2),
      border: Color(0xFFE2DFD8),
      textMuted: Color(0xFF6E6C66),
      textFaint: Color(0xFFA9A7A1),
    ),
  );

  static final dark = _build(
    brightness: Brightness.dark,
    background: const Color(0xFF1B1916),
    surface: const Color(0xFF232119),
    primary: const Color(0xFF5BC9BC),
    primarySoft: const Color(0xFF1F332F),
    textPrimary: const Color(0xFFDEDCD7),
    colors: const AppColors(
      accent: Color(0xFFEC927C),
      accentSoft: Color(0xFF3E2B23),
      gold: Color(0xFFE2B93B),
      danger: Color(0xFFD85C50),
      surfaceAlt: Color(0xFF2A2820),
      border: Color(0xFF3D3A31),
      textMuted: Color(0xFF918F87),
      textFaint: Color(0xFF615F57),
    ),
  );

  static ThemeData _build({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color primary,
    required Color primarySoft,
    required Color textPrimary,
    required AppColors colors,
  }) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: brightness == Brightness.light ? Colors.white : const Color(0xFF102A27),
      primaryContainer: primarySoft,
      onPrimaryContainer: textPrimary,
      secondary: primary,
      onSecondary: brightness == Brightness.light ? Colors.white : const Color(0xFF102A27),
      error: colors.danger,
      onError: Colors.white,
      surface: surface,
      onSurface: textPrimary,
      onSurfaceVariant: colors.textMuted,
      outline: colors.border,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      extensions: [colors],
      textTheme: Typography.material2021().black.apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
        fontFamily: 'sans-serif',
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: colors.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceAlt,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colors.border),
        ),
      ),
    );
  }
}