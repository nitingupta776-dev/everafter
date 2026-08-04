import 'package:flutter/material.dart';

class EverAfterColors {
  static const paper = Color(0xFFF6F1E8);
  static const agedPaper = Color(0xFFE8DDCA);
  static const ink = Color(0xFF2A2725);
  static const warmBrown = Color(0xFF8A6546);
  static const olive = Color(0xFF76826A);
  static const burgundy = Color(0xFF7B4A43);
  static const brass = Color(0xFFB98C48);
  static const catalogLine = Color(0x332A2725);
}

class EverAfterTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: EverAfterColors.burgundy,
        brightness: Brightness.light,
        surface: EverAfterColors.paper,
        primary: EverAfterColors.burgundy,
        secondary: EverAfterColors.olive,
      ),
      scaffoldBackgroundColor: EverAfterColors.paper,
    );

    return base.copyWith(
      textTheme: _textTheme(base.textTheme),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: EverAfterColors.ink,
        elevation: 0,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: EverAfterColors.ink,
          foregroundColor: EverAfterColors.paper,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(6)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          textStyle: const TextStyle(
            fontFamily: 'Georgia',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.6,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: EverAfterColors.ink,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(6)),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Georgia',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  static TextTheme _textTheme(TextTheme base) {
    const displayFamily = 'Georgia';
    const bodyFamily = 'Times New Roman';

    return base.copyWith(
      displayLarge: const TextStyle(
        fontFamily: displayFamily,
        color: EverAfterColors.ink,
        fontSize: 64,
        height: 0.96,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
      displayMedium: const TextStyle(
        fontFamily: displayFamily,
        color: EverAfterColors.ink,
        fontSize: 44,
        height: 1,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
      headlineMedium: const TextStyle(
        fontFamily: displayFamily,
        color: EverAfterColors.ink,
        fontSize: 30,
        height: 1.1,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
      titleLarge: const TextStyle(
        fontFamily: displayFamily,
        color: EverAfterColors.ink,
        fontSize: 22,
        height: 1.1,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
      bodyLarge: const TextStyle(
        fontFamily: bodyFamily,
        color: EverAfterColors.ink,
        fontSize: 18,
        height: 1.46,
        letterSpacing: 0,
      ),
      bodyMedium: const TextStyle(
        fontFamily: bodyFamily,
        color: EverAfterColors.ink,
        fontSize: 15,
        height: 1.45,
        letterSpacing: 0,
      ),
      labelLarge: const TextStyle(
        fontFamily: displayFamily,
        color: EverAfterColors.ink,
        fontSize: 12,
        height: 1.2,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.8,
      ),
      labelSmall: const TextStyle(
        fontFamily: displayFamily,
        color: EverAfterColors.warmBrown,
        fontSize: 10,
        height: 1.2,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.6,
      ),
    );
  }
}
