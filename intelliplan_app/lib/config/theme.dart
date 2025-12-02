import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Color Palette - Updated to match design specs
  // Background colors
  static const Color bgBase = Color(0xFF121212);          // bg/base
  static const Color surfaceHigh = Color(0xFF2C2C2C);     // surface/high
  static const Color surfaceAlt = Color(0xFF1E1E1E);      // surface/alt
  static const Color inputBg = Color(0xFF2A2A2A);         // input backgrounds
  
  // Accent colors
  static const Color accentPrimary = Color(0xFF7F5AF0);   // accent/primary (violet)
  static const Color accentSuccess = Color(0xFF2CB67D);   // accent/success (green)
  static const Color accentAlert = Color(0xFFF25F4C);     // accent/alert (red)
  static const Color accentWarning = Color(0xFFFF9F43);   // accent/warning (orange)
  
  // Text colors
  static const Color textPrimary = Color(0xFFFFFFFF);     // white
  static const Color textSecondary = Color(0xFFA1A1A1);   // gray
  static const Color textHint = Color(0xFFA1A1A1);        // hints/placeholders
  
  // Subject colors (for chips)
  static const Color subjectMath = Color(0xFF4A90E2);     // blue
  static const Color subjectEnglish = Color(0xFF2CB67D);  // green
  static const Color subjectScience = Color(0xFFFF9F43);  // orange
  static const Color subjectHistory = Color(0xFFF25F4C);  // red
  
  // Legacy color mappings (for compatibility)
  static const Color primaryColor = accentPrimary;
  static const Color secondaryColor = accentSuccess;
  static const Color accentColor = accentAlert;
  static const Color backgroundColor = bgBase;
  static const Color darkBackgroundColor = bgBase;
  static const Color cardColor = surfaceHigh;
  static const Color darkCardColor = surfaceHigh;
  static const Color textPrimaryColor = textPrimary;
  static const Color textSecondaryColor = textSecondary;

  // Light Theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: backgroundColor,
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: cardColor,
      error: accentColor,
    ),
    
    // Text Theme - Enhanced font sizes for better readability
    textTheme: TextTheme(
      displayLarge: GoogleFonts.poppins(
        fontSize: 36, // Increased from 32
        fontWeight: FontWeight.bold,
        color: textPrimaryColor,
      ),
      displayMedium: GoogleFonts.poppins(
        fontSize: 32, // Increased from 28
        fontWeight: FontWeight.bold,
        color: textPrimaryColor,
      ),
      headlineMedium: GoogleFonts.poppins(
        fontSize: 26, // Increased from 24
        fontWeight: FontWeight.w600,
        color: textPrimaryColor,
      ),
      titleLarge: GoogleFonts.poppins(
        fontSize: 22, // Increased from 20
        fontWeight: FontWeight.w600,
        color: textPrimaryColor,
      ),
      titleMedium: GoogleFonts.poppins(
        fontSize: 18, // Added for medium titles
        fontWeight: FontWeight.w600,
        color: textPrimaryColor,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 18, // Increased from 16
        color: textPrimaryColor,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 16, // Increased from 14
        color: textSecondaryColor,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 14, // Added for small text
        color: textSecondaryColor,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 16, // Button text
        fontWeight: FontWeight.w600,
        color: textPrimaryColor,
      ),
    ),
    
    // AppBar Theme - Increased font size
    appBarTheme: AppBarTheme(
      elevation: 0,
      backgroundColor: backgroundColor,
      foregroundColor: textPrimaryColor,
      centerTitle: true,
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 22, // Increased from 20
        fontWeight: FontWeight.w600,
        color: textPrimaryColor,
      ),
    ),
    
    // Card Theme
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: cardColor,
    ),
    
    // Elevated Button Theme - Increased font size
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: GoogleFonts.poppins(
          fontSize: 18, // Increased from 16
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    
    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: cardColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
  );

  // Dark Theme - Primary theme matching design specs
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: accentPrimary,
    scaffoldBackgroundColor: bgBase,
    colorScheme: const ColorScheme.dark(
      primary: accentPrimary,
      secondary: accentSuccess,
      surface: surfaceHigh,
      error: accentAlert,
      background: bgBase,
    ),
    
    // Text Theme - Using specified fonts: Poppins (titles), Inter (body), Manrope (labels), DM Sans (inputs)
    textTheme: TextTheme(
      // Display styles - Poppins Bold for headers
      displayLarge: GoogleFonts.poppins(
        fontSize: 36,
        fontWeight: FontWeight.bold,
        color: textPrimary,
      ),
      displayMedium: GoogleFonts.poppins(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: textPrimary,
      ),
      // Headlines - Poppins Bold/SemiBold
      headlineMedium: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: textPrimary,
      ),
      headlineSmall: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: textPrimary,
      ),
      // Titles - Poppins Bold
      titleLarge: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: textPrimary,
      ),
      titleMedium: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      // Body text - Inter Regular/Medium
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        color: textPrimary,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        color: textPrimary,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        color: textSecondary,
      ),
      // Labels - Manrope Medium
      labelLarge: GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textSecondary,
      ),
      labelMedium: GoogleFonts.manrope(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: textSecondary,
      ),
      labelSmall: GoogleFonts.manrope(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: textSecondary,
      ),
    ),
    
    // AppBar Theme
    appBarTheme: AppBarTheme(
      elevation: 0,
      backgroundColor: bgBase,
      foregroundColor: textPrimary,
      centerTitle: true,
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: textPrimary,
      ),
    ),
    
    // Card Theme - surface/high with 16dp radius
    cardTheme: CardThemeData(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: surfaceHigh,
    ),
    
    // Elevated Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accentPrimary,
        foregroundColor: textPrimary,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    
    // Input Decoration Theme - inputs bg #2A2A2A, focus border #7F5AF0
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: inputBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: accentPrimary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: GoogleFonts.dmSans(
        fontSize: 16,
        color: textPrimary,
      ),
      hintStyle: GoogleFonts.dmSans(
        fontSize: 16,
        color: textHint,
      ),
      prefixIconColor: textSecondary,
      suffixIconColor: textSecondary,
    ),
  );
}
