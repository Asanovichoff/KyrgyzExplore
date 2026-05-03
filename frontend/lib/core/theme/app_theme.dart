import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

final appTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: kTeal,
    primary: kNavy,
    secondary: kTeal,
    surface: kLight,
    error: kError,
  ),

  // Poppins for all text — geometric, clean, modern feel
  textTheme: GoogleFonts.poppinsTextTheme(),
  primaryTextTheme: GoogleFonts.poppinsTextTheme(),

  appBarTheme: const AppBarTheme(
    backgroundColor: kNavy,
    foregroundColor: Colors.white,
    elevation: 0,
    centerTitle: false,
  ),

  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: kTeal,
      foregroundColor: Colors.white,
      minimumSize: const Size(88, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15),
    ),
  ),

  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: kTeal,
      minimumSize: const Size(88, 48),
      side: const BorderSide(color: kTeal),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15),
    ),
  ),

  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: kTeal,
      textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 14),
    ),
  ),

  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: kTeal, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: kError),
    ),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  ),

  cardTheme: CardThemeData(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    elevation: 2,
    clipBehavior: Clip.antiAlias,
  ),

  chipTheme: ChipThemeData(
    selectedColor: kTeal.withValues(alpha: 0.15),
    checkmarkColor: kTeal,
    labelStyle: GoogleFonts.poppins(fontSize: 13),
  ),

  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: Colors.white,
    indicatorColor: kTeal.withValues(alpha: 0.12),
    labelTextStyle: WidgetStateProperty.all(
      GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500),
    ),
    labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    elevation: 8,
    shadowColor: Colors.black12,
  ),

  dividerTheme: const DividerThemeData(
    color: Color(0xFFEEEEEE),
    thickness: 1,
  ),
);
