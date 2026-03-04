import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Shared accent colors (same in both themes) ───────────────────────────
  static const Color secondary = Color(0xFF00C9A7);
  static const Color accent    = Color(0xFFFF6B35);
  static const Color success   = Color(0xFF00C97A);
  static const Color warning   = Color(0xFFFFB930);
  static const Color error     = Color(0xFFFF4C6A);

  // ── Dark palette ─────────────────────────────────────────────────────────
  static const Color primary        = Color(0xFF0A1628);
  static const Color cardBg         = Color(0xFF111E33);
  static const Color cardBg2        = Color(0xFF1A2A44);
  static const Color textPrimary    = Color(0xFFEEF2FF);
  static const Color textSecondary  = Color(0xFF8B9CC8);
  static const Color divider        = Color(0xFF1E2E4A);

  // ── Light palette ─────────────────────────────────────────────────────────
  static const Color lightPrimary       = Color(0xFFF0F4FF);
  static const Color lightCardBg        = Color(0xFFFFFFFF);
  static const Color lightCardBg2       = Color(0xFFE8EEFF);
  static const Color lightTextPrimary   = Color(0xFF0D1B3E);
  static const Color lightTextSecondary = Color(0xFF5A6B94);
  static const Color lightDivider       = Color(0xFFD6DDEF);

  // ── Dark Theme ────────────────────────────────────────────────────────────
  static ThemeData get darkTheme => _build(
    brightness: Brightness.dark,
    scaffold: primary,
    card: cardBg,
    card2: cardBg2,
    txtPrimary: textPrimary,
    txtSecondary: textSecondary,
    div: divider,
    appBarBg: primary,
    navBg: cardBg,
  );

  // ── Light Theme ───────────────────────────────────────────────────────────
  static ThemeData get lightTheme => _build(
    brightness: Brightness.light,
    scaffold: lightPrimary,
    card: lightCardBg,
    card2: lightCardBg2,
    txtPrimary: lightTextPrimary,
    txtSecondary: lightTextSecondary,
    div: lightDivider,
    appBarBg: lightCardBg,
    navBg: lightCardBg,
  );

  static ThemeData _build({
    required Brightness brightness,
    required Color scaffold,
    required Color card,
    required Color card2,
    required Color txtPrimary,
    required Color txtSecondary,
    required Color div,
    required Color appBarBg,
    required Color navBg,
  }) {
    final isDark = brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: scaffold,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: secondary,
        onPrimary: isDark ? primary : Colors.white,
        secondary: accent,
        onSecondary: Colors.white,
        surface: card,
        onSurface: txtPrimary,
        error: error,
        onError: Colors.white,
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(TextTheme(
        headlineLarge: TextStyle(color: txtPrimary, fontWeight: FontWeight.w700),
        headlineMedium: TextStyle(color: txtPrimary, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(color: txtPrimary, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: txtPrimary, fontWeight: FontWeight.w500),
        titleSmall: TextStyle(color: txtSecondary, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(color: txtPrimary),
        bodyMedium: TextStyle(color: txtSecondary),
        bodySmall: TextStyle(color: txtSecondary),
        labelLarge: TextStyle(color: txtPrimary, fontWeight: FontWeight.w600),
      )),
      appBarTheme: AppBarTheme(
        backgroundColor: appBarBg,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: txtPrimary, fontSize: 20, fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: txtPrimary),
        surfaceTintColor: Colors.transparent,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: navBg,
        selectedItemColor: secondary,
        unselectedItemColor: txtSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: div),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: div),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: secondary, width: 2),
        ),
        labelStyle: TextStyle(color: txtSecondary),
        hintStyle: TextStyle(color: txtSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: secondary,
          foregroundColor: isDark ? primary : Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      dividerTheme: DividerThemeData(color: div, thickness: 1),
    );
  }
}
