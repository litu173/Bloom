import 'package:flutter/material.dart';

/// Colors mirrored 1:1 from the web app's theme.css so the Flutter build
/// matches the original Figma design exactly in both palettes.
class AppColors {
  final Color background;
  final Color foreground;
  final Color card;
  final Color popover;
  final Color primary;
  final Color primaryForeground;
  final Color secondary;
  final Color secondaryForeground;
  final Color muted;
  final Color mutedForeground;
  final Color accent;
  final Color accentForeground;
  final Color destructive;
  final Color border;
  final Color inputBackground;
  final Color switchBackground;
  final Color calmRose;
  final Color calmPink;
  final Color calmBerry;
  final Color calmMist;
  final Color calmClay;
  final Color calmGreen;
  final Color hero1;
  final Color hero2;
  final Color wheelBand;
  final bool isDark;

  const AppColors({
    required this.background,
    required this.foreground,
    required this.card,
    required this.popover,
    required this.primary,
    required this.primaryForeground,
    required this.secondary,
    required this.secondaryForeground,
    required this.muted,
    required this.mutedForeground,
    required this.accent,
    required this.accentForeground,
    required this.destructive,
    required this.border,
    required this.inputBackground,
    required this.switchBackground,
    required this.calmRose,
    required this.calmPink,
    required this.calmBerry,
    required this.calmMist,
    required this.calmClay,
    required this.calmGreen,
    required this.hero1,
    required this.hero2,
    required this.wheelBand,
    required this.isDark,
  });

  static const dark = AppColors(
    background: Color(0xFF191115),
    foreground: Color(0xFFF4E9EC),
    card: Color(0xFF241A1F),
    popover: Color(0xFF241A1F),
    primary: Color(0xFFF2506E),
    primaryForeground: Color(0xFFFFFFFF),
    secondary: Color(0xFF33232A),
    secondaryForeground: Color(0xFFFFD7E0),
    muted: Color(0xFF2A1E23),
    mutedForeground: Color(0xFFBD97A2),
    accent: Color(0xFF3A2530),
    accentForeground: Color(0xFFFFCDD8),
    destructive: Color(0xFFE0556B),
    border: Color(0x1FFFD6E0),
    inputBackground: Color(0xFF2C2026),
    switchBackground: Color(0xFF4A343D),
    calmRose: Color(0xFFFF6E8C),
    calmPink: Color(0xFFE8637F),
    calmBerry: Color(0xFF8F3350),
    calmMist: Color(0xFF2C1D23),
    calmClay: Color(0xFFF0DCE1),
    calmGreen: Color(0xFFC98AA0),
    hero1: Color(0xFF7A2942),
    hero2: Color(0xFF3A222C),
    wheelBand: Color(0x12FFFFFF),
    isDark: true,
  );

  static const light = AppColors(
    background: Color(0xFFFBF7F1),
    foreground: Color(0xFF5A4D47),
    card: Color(0xFFFFFDFA),
    popover: Color(0xFFFFFDFA),
    primary: Color(0xFFB98A8F),
    primaryForeground: Color(0xFFFFFDFA),
    secondary: Color(0xFFEEF1E9),
    secondaryForeground: Color(0xFF5F6B57),
    muted: Color(0xFFF1E9E6),
    mutedForeground: Color(0xFFA2938C),
    accent: Color(0xFFE9EFE3),
    accentForeground: Color(0xFF5F6B57),
    destructive: Color(0xFFC98A86),
    border: Color(0x1F785F57),
    inputBackground: Color(0xFFF4ECE8),
    switchBackground: Color(0xFFDDD2CC),
    calmRose: Color(0xFFD98F96),
    calmPink: Color(0xFFE8B8BD),
    calmBerry: Color(0xFFB98A8F),
    calmMist: Color(0xFFF6EEF0),
    calmClay: Color(0xFF6F5F57),
    calmGreen: Color(0xFF9DB497),
    hero1: Color(0xFFF3E2E0),
    hero2: Color(0xFFEEF1E9),
    wheelBand: Color(0x17785F57),
    isDark: false,
  );

  static AppColors of(bool dark) => dark ? AppColors.dark : AppColors.light;

  /// Gradient used behind the "next alarm" hero card and wind-down screen.
  LinearGradient get heroGradient => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [hero1, hero2],
      );
}
