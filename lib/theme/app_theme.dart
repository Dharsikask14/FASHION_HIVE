import 'package:flutter/material.dart';

class AppTheme {
  // ── Navy · Gold · Aqua · Teal · Sand — Medium Saturation Palette ─────────
  // Primary:   Medium Navy (confident, professional, readable)
  static const Color primary        = Color(0xFF2E5B8A); // Medium Navy
  static const Color primaryDark    = Color(0xFF1C3F66); // Deep Navy (headers)
  static const Color primaryLight   = Color(0xFFDEEAF5); // Pale Navy tint (chips)

  // Secondary: Warm Gold (premium, highlights, CTAs)
  static const Color secondary      = Color(0xFFBF9430); // Medium Gold
  static const Color secondaryLight = Color(0xFFF5E9C6); // Light Gold tint

  // Accent:    Aqua / Teal (fresh, modern, badges)
  static const Color accent         = Color(0xFF2A8F8F); // Medium Teal/Aqua
  static const Color accentLight    = Color(0xFFD0EFEF); // Pale Aqua tint

  // Sand:      Warm neutral (backgrounds, cards)
  static const Color sand           = Color(0xFFF2EAD8); // Medium Sand bg
  static const Color sandDark       = Color(0xFFE0D4BC); // Sand divider/border
  static const Color sandLight      = Color(0xFFFAF7F1); // Near-white sand

  // Surfaces
  static const Color background     = Color(0xFFF0EDE6); // Warm sand bg
  static const Color surface        = Color(0xFFFFFFFF); // White cards
  static const Color surfaceVariant = Color(0xFFF7F4EE); // Pale sand inputs
  static const Color surfaceDark    = Color(0xFFE5DFD3); // Sand grey divider

  // Text
  static const Color textPrimary    = Color(0xFF1E2B3A); // Dark navy-grey
  static const Color textSecondary  = Color(0xFF5A6B7D); // Medium slate
  static const Color textLight      = Color(0xFF9AABBF); // Light slate hints
  static const Color divider        = Color(0xFFD8D0C2); // Sand divider

  // Status
  static const Color success        = Color(0xFF2A7A5A); // Teal-green
  static const Color warning        = Color(0xFFBF7E20); // Gold-amber
  static const Color error          = Color(0xFFC0392B); // Muted red
  static const Color sale           = Color(0xFFC0392B); // Sale badge

  // Logo
  static const Color logoOutline    = Color(0xFF2E5B8A);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Poppins',
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: secondary,
        surface: surface,
        error: error,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
          fontFamily: 'Poppins',
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: textLight,
        type: BottomNavigationBarType.fixed,
        elevation: 10,
        selectedLabelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
        unselectedLabelStyle: TextStyle(fontSize: 10),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary),
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: error, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: textLight, fontSize: 14),
        labelStyle: const TextStyle(color: textSecondary, fontSize: 14),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 1,
        shadowColor: const Color(0x1A000000),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: EdgeInsets.zero,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceVariant,
        selectedColor: primary,
        labelStyle: const TextStyle(fontSize: 12, color: textPrimary),
        secondaryLabelStyle: const TextStyle(fontSize: 12, color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
    );
  }
}
