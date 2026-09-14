import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static _border([Color color = Colors.grey]) => OutlineInputBorder(
        borderSide: BorderSide(
          color: color,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(10),
      );

  static final lightThemeMode = ThemeData.light().copyWith(
    scaffoldBackgroundColor: const Color.fromRGBO(245, 245, 235, 1), // Beige
    appBarTheme: const AppBarTheme(
      backgroundColor: Color.fromRGBO(245, 245, 235, 1),
    ),
    chipTheme: const ChipThemeData(
      color: WidgetStatePropertyAll(
        Color.fromRGBO(245, 245, 235, 1),
      ),
      side: BorderSide.none,
    ),
    inputDecorationTheme: InputDecorationTheme(
      contentPadding: const EdgeInsets.all(27),
      border: _border(),
      enabledBorder: _border(),
      focusedBorder: _border(const Color.fromRGBO(107, 142, 35, 1)), // Sage Green
      errorBorder: _border(Colors.redAccent),
    ),
  );
}
