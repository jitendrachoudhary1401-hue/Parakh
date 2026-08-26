import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Project PARAKH — Stitch Institutional Minimalism Design System
/// Derived strictly from Stitch generated specifications:
/// - Brand colors: Deep Navy, Slate Gray, Emerald Green, Crimson Alert
/// - Neutral surfaces: High-contrast white & slate-50/200 borders
/// - Typography: Work Sans
/// - Spacing & Radius: 4px soft radius, 1px structural outlines, 20px safe margins
class AppTheme {
  // Primary Palette
  static const Color primary = Color(0xFF031631); // Deep Navy
  static const Color primaryContainer = Color(0xFF1A2B47);
  static const Color primaryLight = Color(0xFFD6E3FF);

  // Secondary Palette
  static const Color secondary = Color(0xFF505F76); // Slate Gray
  static const Color secondaryContainer = Color(0xFFD0E1FB);
  static const Color secondaryLight = Color(0xFFF1F5F9);

  // Functional Colors
  static const Color success = Color(0xFF00A673); // Emerald Green
  static const Color successContainer = Color(0xFFE6F7F0);
  static const Color warning = Color(0xFFD97706); // Amber Warning
  static const Color warningContainer = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFBA1A1A); // Crimson Alert
  static const Color errorContainer = Color(0xFFFFDAD6);

  // Neutral Surfaces & Outlines
  static const Color background = Color(0xFFF7F9FB); // Neutral Slate
  static const Color surface = Color(0xFFFFFFFF); // Pure White
  static const Color surfaceContainerLow = Color(0xFFF8FAFC); // Slate-50
  static const Color surfaceContainer = Color(0xFFECEEF0);
  static const Color outline = Color(0xFFE2E8F0); // Slate-200 (1px structural border)
  static const Color outlineVariant = Color(0xFFCBD5E1);

  // Text Colors
  static const Color textPrimary = Color(0xFF191C1E);
  static const Color textSecondary = Color(0xFF44474D);
  static const Color textMuted = Color(0xFF64748B);

  // Dimensions & Tokens
  static const double radiusSm = 4.0;
  static const double radiusMd = 8.0;
  static const double radiusLg = 12.0;
  static const double radiusPill = 9999.0;
  static const double marginMain = 20.0;
  static const double touchTargetMin = 48.0;

  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.workSansTextTheme();

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: primary,
        onPrimary: Colors.white,
        primaryContainer: primaryContainer,
        onPrimaryContainer: Colors.white,
        secondary: secondary,
        onSecondary: Colors.white,
        secondaryContainer: secondaryContainer,
        onSecondaryContainer: textPrimary,
        error: error,
        onError: Colors.white,
        surface: surface,
        onSurface: textPrimary,
        outline: outline,
        outlineVariant: outlineVariant,
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: GoogleFonts.workSans(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: primary,
          letterSpacing: -0.5,
          height: 1.2,
        ),
        displayMedium: GoogleFonts.workSans(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: primary,
          height: 1.3,
        ),
        headlineSmall: GoogleFonts.workSans(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: primary,
          height: 1.3,
        ),
        titleMedium: GoogleFonts.workSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          height: 1.4,
        ),
        bodyLarge: GoogleFonts.workSans(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: textPrimary,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.workSans(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: textSecondary,
          height: 1.5,
        ),
        labelLarge: GoogleFonts.workSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: primary,
          letterSpacing: 0.5,
        ),
        labelSmall: GoogleFonts.workSans(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: textMuted,
          letterSpacing: 0.5,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: primary),
        titleTextStyle: GoogleFonts.workSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: primary,
        ),
        shape: const Border(
          bottom: BorderSide(color: outline, width: 1),
        ),
      ),
      cardTheme: CardTheme(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          side: const BorderSide(color: outline, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(touchTargetMin),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
          textStyle: GoogleFonts.workSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          elevation: 0,
          minimumSize: const Size.fromHeight(touchTargetMin),
          side: const BorderSide(color: outlineVariant, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
          textStyle: GoogleFonts.workSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: outline, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: outline, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: error, width: 1),
        ),
        labelStyle: GoogleFonts.workSans(fontSize: 13, color: textMuted),
        hintStyle: GoogleFonts.workSans(fontSize: 13, color: textMuted),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        elevation: 0,
        selectedItemColor: primary,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
      ),
      dividerTheme: const DividerThemeData(
        color: outline,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
