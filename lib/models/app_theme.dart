import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData.light().copyWith(
      backgroundColor: Colors.white,
      colorScheme: ColorScheme.light(),
      primaryColor: Colors.white,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        actionsIconTheme: IconThemeData(
          color: Colors.black87,
        ),
        iconTheme: IconThemeData(
          color: Colors.black87,
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.white,
          statusBarBrightness: Brightness.light,
          statusBarIconBrightness: Brightness.dark,
        ),
        titleTextStyle: GoogleFonts.poppins(color: Colors.black),
      ),
      textTheme: TextTheme(
          bodyText1: GoogleFonts.poppins(color: Colors.black, fontSize: 16)));

  static ThemeData darkTheme = ThemeData.dark().copyWith(
      backgroundColor: Colors.black,
      primaryColor: Colors.black,
      colorScheme: ColorScheme.dark(),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.black,
        actionsIconTheme: IconThemeData(
          color: Colors.white70,
        ),
        iconTheme: IconThemeData(
          color: Colors.white70,
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.black,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        titleTextStyle: GoogleFonts.poppins(color: Colors.white),
      ),
      textTheme: TextTheme(
        bodyText1: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
      primaryTextTheme: TextTheme(
        bodyText1: GoogleFonts.poppins(color: Colors.white),
      ));
}
