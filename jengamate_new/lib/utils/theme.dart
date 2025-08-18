import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Define colors based on the new UI
  static const Color primaryColor = Color(0xFF0D47A1); // A deeper blue
  static const Color accentColor = Color(0xFF4CAF50); // Green for success
  static const Color backgroundColor = Color(0xFFF4F6F8);
  static const Color cardColor = Colors.white;
  static const Color textColor = Color(0xFF212121);
  static const Color subTextColor = Color(0xFF757575);
  static const Color pendingColor = Color(0xFFFFA000); // Amber
  static const Color completedColor = Color(0xFF388E3C); // Green
  static const Color warningColor = Color(0xFFFFA000); // Amber
  static const Color infoColor = Color(0xFF2196F3); // Blue
  static const Color successColor = Color(0xFF4CAF50); // Green
  static const Color errorColor = Color(0xFFE53935); // Red
  static const Color secondaryColor = Color(0xFF1976D2); // Secondary color

  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      fontFamily: GoogleFonts.poppins().fontFamily,

      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: textColor),
        titleTextStyle: GoogleFonts.poppins(
          color: textColor,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Text Theme
      textTheme: TextTheme(
        headlineSmall: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
        titleLarge: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
        titleMedium: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: textColor),
        bodyLarge: GoogleFonts.poppins(fontSize: 14, color: textColor),
        bodyMedium: GoogleFonts.poppins(fontSize: 14, color: subTextColor),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 2,
        shadowColor: Colors.black.withAlpha((255 * 0.05).round()),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primaryColor,
        unselectedItemColor: subTextColor,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        elevation: 8,
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        hintStyle: GoogleFonts.poppins(color: subTextColor, fontSize: 14),
      ),
    );
  }
}
