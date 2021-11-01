import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:webpage_dev_console/browser.dart';
import 'package:webpage_dev_console/helpers.dart';
import 'package:webpage_dev_console/models/browser_model.dart';
import 'package:webpage_dev_console/models/webview_model.dart';

late final WEB_ARCHIVE_DIR;

late final TAB_VIEWER_BOTTOM_OFFSET_1;
late final TAB_VIEWER_BOTTOM_OFFSET_2;
late final TAB_VIEWER_BOTTOM_OFFSET_3;

const TAB_VIEWER_TOP_OFFSET_1 = 0.0;
const TAB_VIEWER_TOP_OFFSET_2 = 10.0;
const TAB_VIEWER_TOP_OFFSET_3 = 20.0;

const TAB_VIEWER_TOP_SCALE_TOP_OFFSET = 250.0;
const TAB_VIEWER_TOP_SCALE_BOTTOM_OFFSET = 230.0;
void main() async {
  // SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
  //   systemNavigationBarColor: Colors.black,
  //   // statusBarBrightness: Brightness.light,
  //   // navigation bar color
  //   // statusBarColor: Colors.white, // status bar color
  // ));
  WidgetsFlutterBinding.ensureInitialized();
  // SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  WEB_ARCHIVE_DIR = (await getApplicationSupportDirectory()).path;

  if (Platform.isIOS) {
    TAB_VIEWER_BOTTOM_OFFSET_1 = 130.0;
    TAB_VIEWER_BOTTOM_OFFSET_2 = 140.0;
    TAB_VIEWER_BOTTOM_OFFSET_3 = 150.0;
  } else {
    TAB_VIEWER_BOTTOM_OFFSET_1 = 110.0;
    TAB_VIEWER_BOTTOM_OFFSET_2 = 120.0;
    TAB_VIEWER_BOTTOM_OFFSET_3 = 130.0;
  }

  await FlutterDownloader.initialize(
      debug: false // optional: set false to disable printing logs to console
      );

  await Permission.camera.request();
  await Permission.microphone.request();
  await Permission.storage.request();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => WebViewModel(),
        ),
        ChangeNotifierProxyProvider<WebViewModel, BrowserModel>(
          update: (context, webViewModel, browserModel) {
            browserModel!.setCurrentWebViewModel(webViewModel);
            return browserModel;
          },
          create: (BuildContext context) => BrowserModel(new WebViewModel()),
        ),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Poppins',
        visualDensity: VisualDensity.adaptivePlatformDensity,
        // appBarTheme: AppBarTheme(
        //   systemOverlayStyle: SystemUiOverlayStyle.dark,
        // ),
      ),
      home: FutureBuilder(
        future: Init.instance.initialize(context),
        builder: (context, AsyncSnapshot snapshot) {
          // Show splash screen while waiting for app resources to load:
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Splash();
          } else {
            // Loading is done, return the app:
            return Browser();
          }
        },
      ),
    );
  }
}

// class Splash extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     print("Building spash");
//     bool lightMode =
//         MediaQuery.of(context).platformBrightness == Brightness.light;
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: Center(
//           child: lightMode
//               ? Image.asset('assets/browser_96p.png')
//               : Image.asset('assets/browser_96p.png')),
//     );
//   }
// }

class Init {
  Init._();
  static final instance = Init._();

  Future initialize(BuildContext context) async {
    // This is where you can initialize the resources needed by your app while
    // the splash screen is displayed.  Remove the following example because
    // delaying the user experience is a bad design practice!
    await Future.delayed(const Duration(seconds: 1), () async {
      var browserModel = Provider.of<BrowserModel>(context, listen: false);
      await browserModel.restore();
    });
  }
}
