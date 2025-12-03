import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LightModeColors {
  static const lightPrimary = Color(0xFF124676);
  static const lightOnPrimary = Color(0xE50C355C);
  static const lightPrimaryContainer = Color(0xFF43559A);
  static const lightOnPrimaryContainer = Color(0xFF23105F);
  static const lightSecondary = Color(0xFFDC5DA8);
  static const lightOnSecondary = Color(0xFFFFFFFF);
  static const lightTertiary = Color(0xFFFAE870);
  static const lightOnTertiary = Color(0xFFFFFFFF);
  static const lightError = Color(0xFFBA1A1A);
  static const lightOnError = Color(0xFFFFFFFF);
  static const lightErrorContainer = Color(0xFFFFDAD6);
  static const lightOnErrorContainer = Color(0xFF410002);
  static const lightInversePrimary = Color(0xFFC6B3F7);
  static const lightShadow = Color(0xFF000000);
  static const lightSurface = Color(0xFFFAFAFA);
  static const lightOnSurface = Color(0xFF1C1C1C);
  static const lightAppBarBackground = Color(0xFFEAE0FF);
}

class FontSizes {
  static const double displayLarge = 57.0;
  static const double displayMedium = 45.0;
  static const double displaySmall = 36.0;
  static const double headlineLarge = 32.0;
  static const double headlineMedium = 24.0;
  static const double headlineSmall = 22.0;
  static const double titleLarge = 22.0;
  static const double titleMedium = 18.0;
  static const double titleSmall = 16.0;
  static const double labelLarge = 16.0;
  static const double labelMedium = 14.0;
  static const double labelSmall = 12.0;
  static const double bodyLarge = 16.0;
  static const double bodyMedium = 14.0;
  static const double bodySmall = 12.0;
}

ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.light(
      primary: LightModeColors.lightPrimary,
      onPrimary: LightModeColors.lightOnPrimary,
      primaryContainer: LightModeColors.lightPrimaryContainer,
      onPrimaryContainer: LightModeColors.lightTertiary,
      secondary: LightModeColors.lightSecondary,
      onSecondary: LightModeColors.lightOnSecondary,
      tertiary: LightModeColors.lightTertiary,
      onTertiary: LightModeColors.lightOnTertiary,
      error: LightModeColors.lightError,
      onError: LightModeColors.lightOnError,
      errorContainer: LightModeColors.lightErrorContainer,
      onErrorContainer: LightModeColors.lightOnErrorContainer,
      inversePrimary: LightModeColors.lightInversePrimary,
      shadow: LightModeColors.lightShadow,
      surface: LightModeColors.lightSurface,
      onSurface: LightModeColors.lightOnSurface,
    ),
    brightness: Brightness.light,
    scaffoldBackgroundColor: LightModeColors.lightPrimary,
    appBarTheme: AppBarTheme(
      backgroundColor: LightModeColors.lightPrimary,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: LightModeColors.lightTertiary,
        foregroundColor:
            Color.lerp(LightModeColors.lightPrimary, Colors.black, 0.4),
        textStyle: GoogleFonts.bungee(fontSize: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide.none,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        elevation: 0,
        foregroundColor:
            Color.lerp(LightModeColors.lightTertiary, Colors.white, 0.2),
        backgroundColor: LightModeColors.lightSecondary,
        textStyle: GoogleFonts.bungee(fontSize: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: Colors.white,
            width: 12,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: LightModeColors.lightPrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      hintStyle: GoogleFonts.nunitoSans(
        fontSize: FontSizes.bodyMedium,
        fontWeight: FontWeight.normal,
        color: Color.lerp(LightModeColors.lightSecondary, Colors.white, 0.4),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: LightModeColors.lightTertiary, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: LightModeColors.lightTertiary, width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: LightModeColors.lightTertiary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: LightModeColors.lightError, width: 2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: LightModeColors.lightError, width: 2),
      ),
    ),
    textTheme: TextTheme(
      displayLarge: GoogleFonts.bungee(
        fontSize: FontSizes.displayLarge,
        fontWeight: FontWeight.normal,
        color: LightModeColors.lightTertiary,
      ),
      displayMedium: GoogleFonts.bungee(
        fontSize: FontSizes.displayMedium,
        fontWeight: FontWeight.normal,
        color: LightModeColors.lightTertiary,
      ),
      displaySmall: GoogleFonts.bungee(
        fontSize: FontSizes.displaySmall,
        fontWeight: FontWeight.w600,
      ),
      headlineLarge: GoogleFonts.bungee(
        fontSize: FontSizes.headlineLarge,
        fontWeight: FontWeight.normal,
        color: LightModeColors.lightTertiary,
      ),
      headlineMedium: GoogleFonts.bungee(
        fontSize: FontSizes.headlineMedium,
        fontWeight: FontWeight.w300,
        color: LightModeColors.lightTertiary,
      ),
      headlineSmall: GoogleFonts.bungee(
        fontSize: FontSizes.headlineSmall,
        fontWeight: FontWeight.normal,
        color: LightModeColors.lightTertiary,
      ),
      titleLarge: GoogleFonts.bungee(
        fontSize: FontSizes.titleLarge,
        fontWeight: FontWeight.w300,
        color: LightModeColors.lightTertiary,
      ),
      titleMedium: GoogleFonts.bungee(
        fontSize: FontSizes.titleMedium,
        fontWeight: FontWeight.w300,
        color: LightModeColors.lightTertiary,
      ),
      titleSmall: GoogleFonts.bungee(
        fontSize: FontSizes.titleSmall,
        fontWeight: FontWeight.w300,
        color: LightModeColors.lightTertiary,
      ),
      labelLarge: GoogleFonts.bungee(
        fontSize: FontSizes.labelLarge,
        fontWeight: FontWeight.w300,
      ),
      labelMedium: GoogleFonts.bungee(
        fontSize: FontSizes.labelMedium,
        fontWeight: FontWeight.w300,
      ),
      labelSmall: GoogleFonts.bungee(
        fontSize: FontSizes.labelSmall,
        fontWeight: FontWeight.w300,
      ),
      bodyLarge: GoogleFonts.nunitoSans(
        fontSize: FontSizes.bodyLarge,
        fontWeight: FontWeight.normal,
        color: Color.lerp(LightModeColors.lightTertiary, Colors.white, 0.4),
      ),
      bodyMedium: GoogleFonts.nunitoSans(
        fontSize: FontSizes.bodyMedium,
        fontWeight: FontWeight.normal,

        color: Color.lerp(LightModeColors.lightTertiary, Colors.white, 0.4),
      ),
      bodySmall: GoogleFonts.nunitoSans(
        fontSize: FontSizes.bodySmall,
        fontWeight: FontWeight.normal,
        color: Color.lerp(LightModeColors.lightTertiary, Colors.white, 0.4),
      ),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: LightModeColors.lightTertiary,
      selectionColor: LightModeColors.lightSecondary,
    ));
