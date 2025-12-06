import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

ThemeData buildTheme() {
  final base = ThemeData.light();
  return base.copyWith(
    colorScheme: base.colorScheme.copyWith(
      primary: Color(0xFF0F62FE),
      secondary: Color(0xFF00C9A7),
    ),
    scaffoldBackgroundColor: Color(0xFFF7FAFF),
    textTheme: GoogleFonts.rubikTextTheme(base.textTheme),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.rubik(
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),
    cardTheme: CardThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 6,
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      ),
    ),
  );
}
