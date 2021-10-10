import 'dart:io';

import 'package:device_info/device_info.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:webpage_dev_console/models/browser_model.dart';
import 'package:webpage_dev_console/models/webview_model.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:webpage_dev_console/webview_tab.dart';

import 'browser.dart';

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
  WidgetsFlutterBinding.ensureInitialized();

  WEB_ARCHIVE_DIR = (await getApplicationSupportDirectory()).path;

  await FlutterDownloader.initialize(
      debug: false // optional: set false to disable printing logs to console
      );

  await Permission.camera.request();
  await Permission.microphone.request();
  await Permission.storage.request();
  BrowserModel browserModel = new BrowserModel(new WebViewModel());
  startWeb(BuildContext context) {
    var settings = browserModel.getSettings();
    var url;
    if (url == null) {
      url = settings.homePageEnabled && settings.customUrlHomePage.isNotEmpty
          ? Uri.parse(settings.customUrlHomePage)
          : Uri.parse(settings.searchEngine.url);
    }
    print(url);
    browserModel.showTabScroller = false;
    // if (browserModel.webViewTabs.length == 0) {
    //   WebViewTab wm = WebViewTab(
    //     key: GlobalKey(),
    //     webViewModel: WebViewModel(url: url),
    //   );
    //   if (wm.webViewModel.webViewController != null) print("yuppp");
    //   browserModel.addTab(wm, true);
    // }
    return browserModel;
  }

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
          create: (BuildContext context) => startWeb(context),
        ),
      ],
      child: FlutterBrowserApp(),
    ),
  );
}

class FlutterBrowserApp extends StatefulWidget {
  @override
  _FlutterBrowserAppState createState() => _FlutterBrowserAppState();
}

class _FlutterBrowserAppState extends State<FlutterBrowserApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Dev Web',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => Browser(),
        });
  }
}
