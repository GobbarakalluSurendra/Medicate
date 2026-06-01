import 'package:flutter/material.dart';

class AppTheme {
  // Curated premium HSL-derived colors
  static const Color primaryTeal = Color(0xFF005B5C);    // HSL(180, 100%, 18%)
  static const Color secondaryCyan = Color(0xFF00B2B2);  // HSL(180, 100%, 35%)
  static const Color lightBg = Color(0xFFF5F9F9);        // HSL(180, 20%, 97%)
  static const Color darkBg = Color(0xFF0C1415);         // HSL(180, 30%, 6%)
  static const Color accentCoral = Color(0xFFFF6F59);    // HSL(8, 100%, 67%)
  
  static const Color textDark = Color(0xFF1E2829);
  static const Color textLight = Color(0xFFE2E8E8);
  static const Color borderGrey = Color(0xFFD0DFDF);
  
  // Dynamic linear gradients for headers and buttons
  static const Gradient primaryGradient = LinearGradient(
    colors: [primaryTeal, Color(0xFF00838F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient accentGradient = LinearGradient(
    colors: [accentCoral, Color(0xFFFF8A65)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient glassmorphicCardGradient = LinearGradient(
    colors: [
      Color(0x22FFFFFF),
      Color(0x0AFFFFFF),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Box shadows
  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      offset: const Offset(0, 8),
      blurRadius: 24,
    ),
  ];

  static List<BoxShadow> tealGlow = [
    BoxShadow(
      color: secondaryCyan.withOpacity(0.3),
      offset: const Offset(0, 6),
      blurRadius: 16,
    ),
  ];

  // Theme data definitions
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primaryTeal,
      scaffoldBackgroundColor: lightBg,
      colorScheme: const ColorScheme.light(
        primary: primaryTeal,
        secondary: secondaryCyan,
        error: accentCoral,
      ),
      useMaterial3: true,
      fontFamily: 'Outfit',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textDark),
        titleTextStyle: TextStyle(
          color: textDark,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: borderGrey, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: borderGrey, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: borderGrey, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryTeal, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: accentCoral, width: 1.5),
        ),
      ),
    );
  }
}
