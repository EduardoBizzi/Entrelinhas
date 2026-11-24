import 'package:flutter/material.dart';

class AppTheme {
  static const forest = Color(0xFF153E35);
  static const paper = Color(0xFFF7F5EE);
  static const gold = Color(0xFFB97B3F);

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(seedColor: forest).copyWith(
      primary: forest,
      secondary: gold,
      surface: const Color(0xFFFFFDF8),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: paper,
      appBarTheme: const AppBarTheme(
        backgroundColor: paper,
        foregroundColor: forest,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Color(0xFFE2E6DC)),
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFD6DDD3)),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 17,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: Color(0xFFFFFDF8),
        indicatorColor: Color(0xFFDDE9D7),
      ),
    );
  }
}
