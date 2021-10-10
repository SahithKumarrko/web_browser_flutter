import 'dart:async';
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

Future main() async {
  runApp(new MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  // Override behavior methods and getters like dragDevices
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        // etc.
      };
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        scrollBehavior: MyCustomScrollBehavior(), home: InAppWebViewPage());
  }
}

class InAppWebViewPage extends StatefulWidget {
  @override
  _InAppWebViewPageState createState() => new _InAppWebViewPageState();
}

class _InAppWebViewPageState extends State<InAppWebViewPage> {
  String path = "";
  InAppWebViewController? webView;
  @override
  void initState() {
    super.initState();
    getP();
  }

  getP() async {
    Directory p = await getApplicationSupportDirectory();
    path = p.absolute.path;
    print("Path :: $path");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("InAppWebView"),
          actions: [
            IconButton(
                onPressed: () async {
                  if ((await webView?.canGoBack()) ?? false) {
                    webView?.goBack();
                  }
                },
                icon: Icon(Icons.arrow_back)),
            IconButton(
                onPressed: () async {
                  if ((await webView?.canGoForward()) ?? false) {
                    webView?.goForward();
                  }
                },
                icon: Icon(Icons.arrow_forward))
          ],
        ),
        body: Container(
            child: Column(children: <Widget>[
          Expanded(
            child: Container(
              child: InAppWebView(
                initialUrlRequest:
                    URLRequest(url: Uri.parse("https://flutter.dev")),
                initialOptions: InAppWebViewGroupOptions(
                  crossPlatform: InAppWebViewOptions(
                      preferredContentMode: UserPreferredContentMode.DESKTOP),
                  android: AndroidInAppWebViewOptions(
                      domStorageEnabled: true,
                      databaseEnabled: true,
                      appCachePath: path,
                      loadsImagesAutomatically: true,
                      useWideViewPort: true),
                ),
                onWebViewCreated: (InAppWebViewController controller) {
                  webView = controller;
                },
                onLoadStart: (controller, url) {},
                onLoadStop: (controller, url) {},
              ),
            ),
          ),
        ])));
  }
}
