
import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF1A3651); // bleu très foncé
  static const Color secondaryColor = Color(0xFFFFD700); // Jaune pur
  static const Color lightYellowishGray = Color(0xFFF5F5DD); // jaune grisâtre clair
  static const Color lightOrangeyGray = Color(0xFFF8F5F0); // orange gris clair
  static const Color veryLightGray = Color(0xFFDADADA); // gris très clair

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: lightOrangeyGray,
      colorScheme: const ColorScheme(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: Colors.white,
        background: lightOrangeyGray,
        error: Colors.red,
        onPrimary: Colors.white, // White text on dark blue
        onSecondary: primaryColor, // Dark blue text on yellow
        onSurface: primaryColor,
        onBackground: primaryColor,
        onError: Colors.white,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white, // White title on dark blue appbar
        elevation: 0,
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white, // White text on dark blue button
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: veryLightGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: veryLightGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: primaryColor, width: 2.0),
        ),
        labelStyle: const TextStyle(color: primaryColor),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: primaryColor, fontSize: 32, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
        displayMedium: TextStyle(color: primaryColor, fontSize: 28, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
        headlineMedium: TextStyle(color: primaryColor, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
        titleLarge: TextStyle(color: primaryColor, fontSize: 20, fontWeight: FontWeight.w600, fontFamily: 'Poppins'),
        bodyLarge: TextStyle(color: primaryColor, fontSize: 16, fontFamily: 'Roboto'),
        bodyMedium: TextStyle(color: primaryColor, fontSize: 14, fontFamily: 'Roboto'),
      ),
    );
  }
}
