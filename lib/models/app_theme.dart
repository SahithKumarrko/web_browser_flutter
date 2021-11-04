import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class ChangeTheme extends ChangeNotifier {
  Brightness cv = Brightness.light;
  ChangeTheme() {
    if (SchedulerBinding.instance!.window.platformBrightness == Brightness.dark)
      cv = Brightness.dark;
    print("Theme :: $cv");
  }
  change(Brightness v, BuildContext ctx) {
    cv = v;
    print("Changing theme ::: $cv");
    if (cv == Brightness.dark)
      SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(
          statusBarColor: Colors.grey[900],
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      );
    else
      SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(
          statusBarColor: Colors.white,
          statusBarBrightness: Brightness.light,
          statusBarIconBrightness: Brightness.dark,
        ),
      );
    notifyListeners();
  }
}

class AppTheme {
  static ThemeData lightTheme = ThemeData.light().copyWith(
      backgroundColor: Colors.white,
      colorScheme: ColorScheme.light(),
      primaryColor: Colors.white,
      scaffoldBackgroundColor: Colors.white,
      dialogTheme: DialogTheme(
          contentTextStyle:
              GoogleFonts.poppins(color: Colors.blueGrey, fontSize: 18.0),
          titleTextStyle: GoogleFonts.poppins(
              color: Colors.black, fontSize: 20, fontWeight: FontWeight.w600)),
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
      textSelectionTheme: TextSelectionThemeData(cursorColor: Colors.black),
      disabledColor: Colors.grey,
      textTheme: TextTheme(
        bodyText2: GoogleFonts.poppins(color: Colors.black, fontSize: 14),
        headline1: GoogleFonts.poppins(
            color: Colors.black, fontSize: 24, fontWeight: FontWeight.w600),
        headline2: GoogleFonts.poppins(
            color: Colors.black, fontSize: 18, fontWeight: FontWeight.w500),
        headline3: GoogleFonts.poppins(
            color: Colors.black, fontSize: 16, fontWeight: FontWeight.w500),
        bodyText1: GoogleFonts.poppins(color: Colors.black, fontSize: 16),
      ));

  static ThemeData darkTheme = ThemeData.dark().copyWith(
      backgroundColor: Colors.grey[900],
      primaryColor: Colors.black,
      scaffoldBackgroundColor: Colors.grey[900],
      colorScheme: ColorScheme.dark(),
      textSelectionTheme: TextSelectionThemeData(cursorColor: Colors.white),
      disabledColor: Colors.white54,
      progressIndicatorTheme: ProgressIndicatorThemeData(
          color: Colors.blue,
          circularTrackColor: Colors.grey[900],
          linearTrackColor: Colors.grey[900],
          refreshBackgroundColor: Colors.white),
      popupMenuTheme: PopupMenuThemeData(color: Colors.grey[800]),
      dialogTheme: DialogTheme(
          backgroundColor: Colors.grey[700],
          contentTextStyle:
              GoogleFonts.poppins(color: Colors.white, fontSize: 18.0),
          titleTextStyle: GoogleFonts.poppins(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.grey[900],
        actionsIconTheme: IconThemeData(
          color: Colors.white,
        ),
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
        bodyText2: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
        headline1: GoogleFonts.poppins(
            color: Colors.white, fontSize: 24, fontWeight: FontWeight.w600),
        headline2: GoogleFonts.poppins(
            color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
        headline3: GoogleFonts.poppins(
            color: Colors.white, fontSize: 16, fontWeight: FontWeight.w400),
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
      primaryTextTheme: TextTheme(
        bodyText1: GoogleFonts.poppins(color: Colors.white),
      ));
}
