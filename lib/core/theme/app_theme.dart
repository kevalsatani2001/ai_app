import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  static const Color scaffoldBackground = Color(0xFF0F0F14);
  static const Color surfaceColor = Color(0xFF1A1A24);
  static const Color userGradientStart = Color(0xFF6366F1);
  static const Color userGradientEnd = Color(0xFF8B5CF6);
  static const Color modelBubbleColor = Color(0xFF232330);
  static const Color accentColor = Color(0xFF818CF8);
  static const Color errorColor = Color(0xFFF87171);
  static const Color onlineColor = Color(0xFF34D399);

  static ThemeData get darkTheme {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: scaffoldBackground,
      colorScheme: const ColorScheme.dark(
        primary: accentColor,
        secondary: userGradientEnd,
        surface: surfaceColor,
        error: errorColor,
      ),
    );

    return base.copyWith(
      textTheme: GoogleFonts.interTextTheme(base.textTheme),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: scaffoldBackground.withValues(alpha: 0.95),
        foregroundColor: Colors.white,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 14,
        ),
        hintStyle: GoogleFonts.inter(
          color: Colors.white38,
          fontSize: 15,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: surfaceColor,
        contentTextStyle: GoogleFonts.inter(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
