import 'package:flutter/material.dart';

class AppTheme {
  // Theme Color Constants
  static const Color primary = Color(0xFF19E5E6);
  
  // Light Mode Colors
  static const Color bgLight = Color(0xFFF6F8F8);
  static const Color cardLight = Colors.white;
  static const Color textDark = Color(0xFF0F172A); // slate-900
  static const Color textMediumLight = Color(0xFF475569); // slate-600
  static const Color textSecondaryLight = Color(0xFF64748B); // slate-500
  static const Color borderLight = Color(0xFFE2E8F0); // slate-200
  static const Color borderSubtleLight = Color(0xFFF1F5F9); // slate-100
  
  // Dark Mode Colors
  static const Color bgDark = Color(0xFF112121);
  static const Color cardDark = Color(0xFF1E293B); // slate-800
  static const Color headerDark = Color(0xFF0F172A); // slate-900
  static const Color textLight = Color(0xFFF1F5F9); // slate-100
  static const Color textMediumDark = Color(0xFFCBD5E1); // slate-300
  static const Color textSecondaryDark = Color(0xFF94A3B8); // slate-400
  static const Color borderDark = Color(0xFF334155); // slate-700
  static const Color borderSubtleDark = Color(0xFF1E293B); // slate-800

  // Light ThemeData
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primary,
      scaffoldBackgroundColor: bgLight,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: primary,
        surface: cardLight,
        background: bgLight,
        onBackground: textDark,
        onSurface: textDark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bgLight,
        elevation: 0,
        iconTheme: IconThemeData(color: textDark),
        titleTextStyle: TextStyle(
          color: textDark,
          fontFamily: 'Inter',
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      fontFamily: 'Inter',
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: textDark, fontSize: 36, fontWeight: FontWeight.bold, height: 1.2),
        titleLarge: TextStyle(color: textDark, fontSize: 24, fontWeight: FontWeight.bold, height: 1.2),
        titleMedium: TextStyle(color: textDark, fontSize: 18, fontWeight: FontWeight.bold),
        bodyLarge: TextStyle(color: textMediumLight, fontSize: 16, fontWeight: FontWeight.normal),
        bodyMedium: TextStyle(color: textSecondaryLight, fontSize: 14, fontWeight: FontWeight.normal),
        labelLarge: TextStyle(color: textDark, fontSize: 14, fontWeight: FontWeight.bold),
      ),
      dividerTheme: const DividerThemeData(
        color: borderLight,
        thickness: 1,
      ),
    );
  }

  // Dark ThemeData
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primary,
      scaffoldBackgroundColor: bgDark,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: primary,
        surface: cardDark,
        background: bgDark,
        onBackground: textLight,
        onSurface: textLight,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bgDark,
        elevation: 0,
        iconTheme: IconThemeData(color: textLight),
        titleTextStyle: TextStyle(
          color: textLight,
          fontFamily: 'Inter',
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      fontFamily: 'Inter',
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: textLight, fontSize: 36, fontWeight: FontWeight.bold, height: 1.2),
        titleLarge: TextStyle(color: textLight, fontSize: 24, fontWeight: FontWeight.bold, height: 1.2),
        titleMedium: TextStyle(color: textLight, fontSize: 18, fontWeight: FontWeight.bold),
        bodyLarge: TextStyle(color: textMediumDark, fontSize: 16, fontWeight: FontWeight.normal),
        bodyMedium: TextStyle(color: textSecondaryDark, fontSize: 14, fontWeight: FontWeight.normal),
        labelLarge: TextStyle(color: textLight, fontSize: 14, fontWeight: FontWeight.bold),
      ),
      dividerTheme: const DividerThemeData(
        color: borderDark,
        thickness: 1,
      ),
    );
  }
}
