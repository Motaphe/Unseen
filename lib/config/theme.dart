import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UnseenTheme {
  // Horror Color Palette
  static const Color bloodRed = Color(0xFF8B0000);
  static const Color deepBlood = Color(0xFF4A0000);
  static const Color voidBlack = Color(0xFF0A0A0A);
  static const Color shadowGray = Color(0xFF1A1A1A);
  static const Color ashGray = Color(0xFF2D2D2D);
  static const Color boneWhite = Color(0xFFE8E4E1);
  static const Color sicklyCream = Color(0xFFD4C5B9);
  static const Color ghostWhite = Color(0xFFF5F5F5);
  static const Color toxicGreen = Color(0xFF39FF14);
  static const Color etherealBlue = Color(0xFF4169E1);
  static const Color decayYellow = Color(0xFFB8860B);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: voidBlack,
      colorScheme: const ColorScheme.dark(
        primary: bloodRed,
        secondary: toxicGreen,
        surface: shadowGray,
        error: bloodRed,
        onPrimary: ghostWhite,
        onSecondary: voidBlack,
        onSurface: boneWhite,
        onError: ghostWhite,
      ),

      // App Bar
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.specialElite(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: bloodRed,
          letterSpacing: 2,
        ),
        iconTheme: const IconThemeData(color: boneWhite),
      ),

      // Cards
      cardTheme: CardThemeData(
        color: shadowGray,
        elevation: 8,
        shadowColor: bloodRed.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: bloodRed.withValues(alpha: 0.3), width: 1),
        ),
      ),

      // Elevated Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: bloodRed,
          foregroundColor: ghostWhite,
          elevation: 6,
          shadowColor: bloodRed.withValues(alpha: 0.5),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.specialElite(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ),

      // Text Buttons
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: sicklyCream,
          textStyle: GoogleFonts.specialElite(
            fontSize: 14,
            letterSpacing: 1,
          ),
        ),
      ),

      // Outlined Buttons
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: bloodRed,
          side: const BorderSide(color: bloodRed, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.specialElite(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ashGray,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: bloodRed.withValues(alpha: 0.3), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: bloodRed, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: bloodRed, width: 2),
        ),
        labelStyle: GoogleFonts.specialElite(
          color: sicklyCream,
          fontSize: 14,
        ),
        hintStyle: GoogleFonts.specialElite(
          color: sicklyCream.withValues(alpha: 0.5),
          fontSize: 14,
        ),
        prefixIconColor: bloodRed,
        suffixIconColor: bloodRed,
      ),

      // Text Theme
      textTheme: TextTheme(
        displayLarge: GoogleFonts.creepster(
          fontSize: 48,
          fontWeight: FontWeight.bold,
          color: bloodRed,
          letterSpacing: 4,
        ),
        displayMedium: GoogleFonts.creepster(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: bloodRed,
          letterSpacing: 3,
        ),
        displaySmall: GoogleFonts.creepster(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: bloodRed,
          letterSpacing: 2,
        ),
        headlineLarge: GoogleFonts.specialElite(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: boneWhite,
          letterSpacing: 2,
        ),
        headlineMedium: GoogleFonts.specialElite(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: boneWhite,
          letterSpacing: 1.5,
        ),
        headlineSmall: GoogleFonts.specialElite(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: boneWhite,
          letterSpacing: 1,
        ),
        titleLarge: GoogleFonts.specialElite(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: boneWhite,
        ),
        titleMedium: GoogleFonts.specialElite(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: boneWhite,
        ),
        titleSmall: GoogleFonts.specialElite(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: sicklyCream,
        ),
        bodyLarge: GoogleFonts.specialElite(
          fontSize: 16,
          color: boneWhite,
          height: 1.6,
        ),
        bodyMedium: GoogleFonts.specialElite(
          fontSize: 14,
          color: sicklyCream,
          height: 1.5,
        ),
        bodySmall: GoogleFonts.specialElite(
          fontSize: 12,
          color: sicklyCream.withValues(alpha: 0.8),
          height: 1.4,
        ),
        labelLarge: GoogleFonts.specialElite(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: boneWhite,
          letterSpacing: 1.5,
        ),
        labelMedium: GoogleFonts.specialElite(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: sicklyCream,
          letterSpacing: 1,
        ),
        labelSmall: GoogleFonts.specialElite(
          fontSize: 10,
          color: sicklyCream.withValues(alpha: 0.7),
          letterSpacing: 0.5,
        ),
      ),

      // Icon Theme
      iconTheme: const IconThemeData(
        color: boneWhite,
        size: 24,
      ),

      // Floating Action Button
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: bloodRed,
        foregroundColor: ghostWhite,
        elevation: 8,
      ),

      // Bottom Navigation
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: shadowGray,
        selectedItemColor: bloodRed,
        unselectedItemColor: sicklyCream.withValues(alpha: 0.5),
        type: BottomNavigationBarType.fixed,
        elevation: 16,
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: shadowGray,
        contentTextStyle: GoogleFonts.specialElite(
          color: boneWhite,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: bloodRed, width: 1),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: shadowGray,
        elevation: 16,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: bloodRed.withValues(alpha: 0.5), width: 1),
        ),
        titleTextStyle: GoogleFonts.creepster(
          fontSize: 24,
          color: bloodRed,
          letterSpacing: 2,
        ),
        contentTextStyle: GoogleFonts.specialElite(
          fontSize: 14,
          color: boneWhite,
          height: 1.5,
        ),
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: bloodRed.withValues(alpha: 0.3),
        thickness: 1,
        space: 24,
      ),

      // Progress Indicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: bloodRed,
        circularTrackColor: shadowGray,
        linearTrackColor: shadowGray,
      ),

      // Slider
      sliderTheme: SliderThemeData(
        activeTrackColor: bloodRed,
        inactiveTrackColor: ashGray,
        thumbColor: bloodRed,
        overlayColor: bloodRed.withValues(alpha: 0.2),
      ),

      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return bloodRed;
          return sicklyCream;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return bloodRed.withValues(alpha: 0.5);
          }
          return ashGray;
        }),
      ),

      // Checkbox
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return bloodRed;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(ghostWhite),
        side: const BorderSide(color: bloodRed, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}
