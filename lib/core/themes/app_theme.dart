// lib/core/themes/app_theme.dart

import 'package:flutter/material.dart';

class AppTheme {
  // Brand Colors based on the new UI/UX design
  static const Color primaryBlue = Color(0xFF2E4A8E);
  static const Color primaryOrange = Color(0xFFF28C28);
  static const Color backgroundColor = Color(0xFFF5F6F8);
  static const Color surfaceColor = Colors.white;
  static const Color textPrimary = Color(0xFF333333);
  static const Color textSecondary = Color(0xFF757575);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Mazzard', // Custom font
      colorScheme: const ColorScheme.light(
        primary: primaryBlue,
        secondary: primaryOrange,
        surface: surfaceColor,
        background: backgroundColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
        onBackground: textPrimary,
      ),
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryOrange,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: MaterialStateProperty.all(primaryOrange),
        headingTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontFamily: 'Mazzard',
        ),
        dataTextStyle: const TextStyle(
          color: textPrimary,
          fontFamily: 'Mazzard',
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Mazzard',
      colorSchemeSeed: primaryBlue,
      brightness: Brightness.dark,
      // Placeholder for dark theme if needed later
    );
  }
}
