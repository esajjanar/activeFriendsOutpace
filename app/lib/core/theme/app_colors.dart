import 'package:flutter/material.dart';

@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.accent,
    required this.accentSoft,
    required this.gold,
    required this.danger,
    required this.surfaceAlt,
    required this.border,
    required this.textMuted,
    required this.textFaint,
  });

  final Color accent;
  final Color accentSoft;
  final Color gold;
  final Color danger;
  final Color surfaceAlt;
  final Color border;
  final Color textMuted;
  final Color textFaint;

  @override
  AppColors copyWith({
    Color? accent,
    Color? accentSoft,
    Color? gold,
    Color? danger,
    Color? surfaceAlt,
    Color? border,
    Color? textMuted,
    Color? textFaint,
  }) {
    return AppColors(
      accent: accent ?? this.accent,
      accentSoft: accentSoft ?? this.accentSoft,
      gold: gold ?? this.gold,
      danger: danger ?? this.danger,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      border: border ?? this.border,
      textMuted: textMuted ?? this.textMuted,
      textFaint: textFaint ?? this.textFaint,
    );
  }

  @override
  AppColors lerp(AppColors? other, double t) => other ?? this;
}