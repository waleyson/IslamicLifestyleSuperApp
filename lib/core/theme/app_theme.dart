import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Islamic Green
  static const Color primaryColor = Color(0xFF1B6B3A);
  // Gold accent
  static const Color accentColor = Color(0xFFD4AF37);

  static TextTheme _buildTextTheme(Brightness brightness) {
    final base = brightness == Brightness.light ? Colors.black : Colors.white;
    return GoogleFonts.outfitTextTheme(
      TextTheme(
        displayLarge: TextStyle(color: base),
        displayMedium: TextStyle(color: base),
        displaySmall: TextStyle(color: base),
        headlineLarge: TextStyle(color: base, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(color: base, fontWeight: FontWeight.bold),
        headlineSmall: TextStyle(color: base, fontWeight: FontWeight.bold),
        titleLarge:
            TextStyle(color: base, fontWeight: FontWeight.w600, fontSize: 18),
        titleMedium: TextStyle(color: base, fontWeight: FontWeight.w600),
        titleSmall: TextStyle(color: base),
        bodyLarge: TextStyle(color: base),
        bodyMedium: TextStyle(color: base),
        bodySmall: TextStyle(color: base.withValues(alpha: 0.7)),
        labelLarge: TextStyle(
            color: base, fontWeight: FontWeight.w600, letterSpacing: 0.5),
        labelSmall: TextStyle(color: base.withValues(alpha: 0.6)),
      ),
    );
  }

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
      primary: primaryColor,
      secondary: accentColor,
      tertiary: const Color(0xFF0D6E6E), // Teal
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: _buildTextTheme(Brightness.light),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          textStyle:
              GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.outfit(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: primaryColor);
          }
          return GoogleFonts.outfit(fontSize: 12);
        }),
      ),
    );
  }

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
      primary: const Color(0xFF4CAF82),
      secondary: accentColor,
      tertiary: const Color(0xFF4DB6AC),
      surface: const Color(0xFF121212),
      surfaceContainerHighest: const Color(0xFF1E1E1E),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: _buildTextTheme(Brightness.dark),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4CAF82),
          foregroundColor: Colors.white,
          textStyle:
              GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF1A1A1A),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.outfit(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: accentColor);
          }
          return GoogleFonts.outfit(fontSize: 12, color: Colors.white60);
        }),
      ),
    );
  }
}
