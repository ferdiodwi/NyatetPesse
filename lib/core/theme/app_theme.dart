import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: Color(0xFF000666),
        onPrimary: Color(0xFFFFFFFF),
        primaryContainer: Color(0xFF1a237e),
        onPrimaryContainer: Color(0xFF8690ee),
        secondary: Color(0xFF1b6d24),
        onSecondary: Color(0xFFFFFFFF),
        secondaryContainer: Color(0xFFa0f399),
        onSecondaryContainer: Color(0xFF217128),
        error: Color(0xFFba1a1a),
        onError: Color(0xFFFFFFFF),
        errorContainer: Color(0xFFffdad6),
        onErrorContainer: Color(0xFF93000a),
        background: Color(0xFFf8f9fa),
        onBackground: Color(0xFF191c1d),
        surface: Color(0xFFf8f9fa),
        onSurface: Color(0xFF191c1d),
        surfaceVariant: Color(0xFFe1e3e4),
        onSurfaceVariant: Color(0xFF454652),
        outline: Color(0xFF767683),
      ),
      fontFamily: 'Inter', // Note: ensure fonts are configured in pubspec later if needed
      scaffoldBackgroundColor: const Color(0xFFf8f9fa),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFf8f9fa),
        foregroundColor: Color(0xFF000666),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF191c1d)),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: Color(0xFF191c1d)),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Color(0xFF191c1d)),
        labelSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.5, color: Color(0xFF454652)),
      ),
    );
  }
}
