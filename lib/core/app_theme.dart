import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color darkBg = Color(0xFF0A0E12);
  static const Color surface = Color(0xFF161B22);
  static const Color accentGreen = Color(0xFF00E676);
  static const Color accentBlue = Color(0xFF2979FF);
  static const Color accentRed = Color(0xFFFF5252);
  static const Color textMain = Color(0xFFE6EDF3);
  static const Color textDim = Color(0xFF8B949E);

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkBg,
    colorScheme: ColorScheme.dark(
      primary: accentGreen,
      secondary: accentGreen,
      surface: surface,
      onSurface: textMain,
    ),
    textTheme: GoogleFonts.interTextTheme(
      const TextTheme(
        headlineLarge: TextStyle(fontWeight: FontWeight.bold, color: textMain),
        headlineMedium: TextStyle(fontWeight: FontWeight.bold, color: textMain),
        titleLarge: TextStyle(fontWeight: FontWeight.w600, color: textMain),
        bodyLarge: TextStyle(color: textMain),
        bodyMedium: TextStyle(color: textDim),
      ),
    ),
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: textDim.withOpacity(0.1)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: textDim.withOpacity(0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: textDim.withOpacity(0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: accentGreen),
      ),
    ),
  );
}
