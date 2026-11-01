import 'package:flutter/material.dart';

abstract final class ChifaColors {
  static const red = Color(0xFFA62F32);
  static const ink = Color(0xFF28231F);
  static const muted = Color(0xFF80776F);
  static const cream = Color(0xFFF8F5EF);
  static const gold = Color(0xFFC28B3C);
  static const green = Color(0xFF39705A);
}

ThemeData chifaTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: ChifaColors.red,
    primary: ChifaColors.red,
    surface: ChifaColors.cream,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: ChifaColors.cream,
    fontFamily: 'Roboto',
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.1,
        color: ChifaColors.ink,
      ),
      headlineMedium: TextStyle(
        fontSize: 27,
        fontWeight: FontWeight.w800,
        letterSpacing: -.7,
        color: ChifaColors.ink,
      ),
      titleLarge: TextStyle(
        fontSize: 21,
        fontWeight: FontWeight.w700,
        color: ChifaColors.ink,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: ChifaColors.ink,
      ),
      bodyMedium: TextStyle(fontSize: 14, color: ChifaColors.ink),
      bodySmall: TextStyle(fontSize: 12, color: ChifaColors.muted),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: ChifaColors.cream,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.all(18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE7E0D6)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE7E0D6)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: ChifaColors.red, width: 1.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFFE8E1D7),
      thickness: 1,
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: Color(0xFFF5E5DF),
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(
          fontFamily: 'Roboto',
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}
