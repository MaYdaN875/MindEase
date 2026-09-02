import 'package:flutter/material.dart';

class AppTheme {
  // Brand Color Constants (SereneMind)
  static const Color primary = Color(0xFF19E5E6); // Primary Cyan-Mint (#19e5e6)
  static const Color primaryDark = Color(0xFF006A6A); // Deep Teal (#006a6a)
  static const Color primaryMuted = Color(0x1A19E5E6); // 10% opacity primary
  
  static const Color secondary = Color(0xFF2E6767);
  static const Color secondaryContainer = Color(0xFFB1EAEA);
  static const Color onSecondaryContainer = Color(0xFF336B6B);
  
  static const Color tertiary = Color(0xFF7A5900);
  static const Color tertiaryContainer = Color(0xFFFFC648);
  static const Color tertiaryFixedDim = Color(0xFFF6BE40);
  static const Color onTertiaryContainer = Color(0xFF725300);
  
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);
  
  // Light Mode Surfaces & Text
  static const Color bgLight = Color(0xFFF6F8F8);
  static const Color surfaceLight = Color(0xFFF3FBFA);
  static const Color cardLight = Colors.white;
  static const Color surfaceContainerLow = Color(0xFFEDF5F4);
  static const Color surfaceContainer = Color(0xFFE8EFEF);
  static const Color surfaceContainerHigh = Color(0xFFE2EAE9);
  static const Color surfaceContainerHighest = Color(0xFFDCE4E3);
  
  static const Color textDark = Color(0xFF0F172A); // slate-900
  static const Color textMediumLight = Color(0xFF475569); // slate-600
  static const Color textSecondaryLight = Color(0xFF64748B); // slate-500
  static const Color borderLight = Color(0xFFE2E8F0); // slate-200
  static const Color borderSubtleLight = Color(0xFFBACAC9); // outline-variant

  // Dark Mode Surfaces & Text
  static const Color bgDark = Color(0xFF112121);
  static const Color surfaceDark = Color(0xFF151D1D);
  static const Color cardDark = Color(0xFF1E293B); // slate-800
  static const Color headerDark = Color(0xFF0F172A); // slate-900
  static const Color inverseSurface = Color(0xFF2A3232);
  
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
        secondary: secondary,
        surface: cardLight,
        error: error,
        onPrimary: textDark,
        onSecondary: Colors.white,
        onSurface: textDark,
        onError: Colors.white,
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
        error: error,
        onPrimary: textDark,
        onSecondary: Colors.white,
        onSurface: textLight,
        onError: Colors.white,
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
