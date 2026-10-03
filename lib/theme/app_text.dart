import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Body font: Quicksand (rounded, warm). Accent/display font for large
/// numerals & affirmations: Fraunces (soft serif) — matches fonts.css.
class AppText {
  static TextStyle body(AppColors c, {double size = 15, FontWeight? weight, Color? color}) =>
      GoogleFonts.quicksand(
        fontSize: size,
        fontWeight: weight ?? FontWeight.w500,
        color: color ?? c.foreground,
        letterSpacing: -0.1,
      );

  static TextStyle muted(AppColors c, {double size = 13}) =>
      body(c, size: size, color: c.mutedForeground, weight: FontWeight.w400);

  static TextStyle serif(AppColors c, {double size = 26, FontWeight? weight, Color? color}) =>
      GoogleFonts.fraunces(
        fontSize: size,
        fontWeight: weight ?? FontWeight.w500,
        color: color ?? c.foreground,
      );
}

ThemeData buildAppTheme(AppColors c) {
  final base = c.isDark ? ThemeData.dark() : ThemeData.light();
  return base.copyWith(
    scaffoldBackgroundColor: c.background,
    primaryColor: c.primary,
    colorScheme: (c.isDark ? const ColorScheme.dark() : const ColorScheme.light())
        .copyWith(primary: c.primary, surface: c.card, error: c.destructive),
    textTheme: GoogleFonts.quicksandTextTheme(base.textTheme).apply(
      bodyColor: c.foreground,
      displayColor: c.foreground,
    ),
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
  );
}
