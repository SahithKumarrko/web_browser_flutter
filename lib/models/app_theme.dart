import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData.light().copyWith(
      backgroundColor: Colors.white,
      colorScheme: ColorScheme.light(),
      primaryColor: Colors.white,
      scaffoldBackgroundColor: Colors.white,
      dialogTheme: DialogTheme(
          contentTextStyle: TextStyle(color: Colors.blueGrey, fontSize: 18.0),
          titleTextStyle: TextStyle(color: Colors.black)),
      visualDensity: VisualDensity.adaptivePlatformDensity,
      progressIndicatorTheme: ProgressIndicatorThemeData(
          color: Colors.blue,
          circularTrackColor: Colors.white,
          linearTrackColor: Colors.white,
          refreshBackgroundColor: Colors.blueGrey[100]),
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
      disabledColor: Colors.grey,
      textTheme: TextTheme(
        headline1: GoogleFonts.poppins(
            color: Colors.black, fontSize: 24, fontWeight: FontWeight.w600),
        headline2: GoogleFonts.poppins(
            color: Colors.black, fontSize: 18, fontWeight: FontWeight.w500),
        bodyText1: GoogleFonts.poppins(color: Colors.black, fontSize: 16),
      ));

  static ThemeData darkTheme = ThemeData.dark().copyWith(
      backgroundColor: Colors.grey[900],
      primaryColor: Colors.black,
      scaffoldBackgroundColor: Colors.grey[900],
      colorScheme: ColorScheme.dark(),
      disabledColor: Colors.white54,
      progressIndicatorTheme: ProgressIndicatorThemeData(
          color: Colors.blue,
          circularTrackColor: Colors.grey[900],
          linearTrackColor: Colors.grey[900],
          refreshBackgroundColor: Colors.white),
      popupMenuTheme: PopupMenuThemeData(color: Colors.grey[800]),
      dialogTheme: DialogTheme(
          backgroundColor: Colors.grey[700],
          contentTextStyle: TextStyle(color: Colors.white, fontSize: 18.0),
          titleTextStyle: TextStyle(color: Colors.white)),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.grey[900],
        actionsIconTheme: IconThemeData(
          color: Colors.white,
        ),
        shadowColor: Colors.white30,
        iconTheme: IconThemeData(
          color: Colors.white,
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.grey[900],
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        titleTextStyle: GoogleFonts.poppins(color: Colors.white),
      ),
      textTheme: TextTheme(
        bodyText1: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
        headline1: GoogleFonts.poppins(
            color: Colors.white, fontSize: 24, fontWeight: FontWeight.w600),
        headline2: GoogleFonts.poppins(
            color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
      primaryTextTheme: TextTheme(
        bodyText1: GoogleFonts.poppins(color: Colors.white),
      ));
}
