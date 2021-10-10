import 'dart:io';

import 'package:flash/flash.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:html/parser.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share/share.dart';
import 'package:webpage_dev_console/models/browser_model.dart';
import 'package:webpage_dev_console/models/webview_model.dart';
import 'package:webpage_dev_console/webview_tab.dart';

class Helper {
  static String getTitle(String title) {
    List<String> t = title.toString().split("-");
    t = t.sublist(
        0,
        t.length == 0
            ? 0
            : t.length > 1
                ? t.length - 1
                : 1);
    return t.join("-").trim();
  }

  static String htmlToString(String htmlString) {
    final document = parse(htmlString);
    final String parsedString =
        parse(document.body?.text).documentElement!.text;
    return parsedString;
  }

  static void share(BuildContext context) {
    var browserModel = Provider.of<BrowserModel>(context, listen: false);
    var webViewModel = browserModel.getCurrentTab()?.webViewModel;
    var url = webViewModel?.url;
    if (url != null) {
      Share.share(url.toString(), subject: webViewModel?.title);
    }
  }

  static void addNewTab({Uri? url, required BuildContext context}) {
    var browserModel = Provider.of<BrowserModel>(context, listen: false);
    var settings = browserModel.getSettings();

    if (url == null) {
      url = settings.homePageEnabled && settings.customUrlHomePage.isNotEmpty
          ? Uri.parse(settings.customUrlHomePage)
          : Uri.parse(settings.searchEngine.url);
    }

    browserModel.addTab(
        WebViewTab(
          key: GlobalKey(),
          webViewModel: WebViewModel(url: url, openedByUser: true),
        ),
        true);
  }

  static void addNewIncognitoTab({Uri? url, required BuildContext context}) {
    var browserModel = Provider.of<BrowserModel>(context, listen: false);
    var settings = browserModel.getSettings();

    if (url == null) {
      url = settings.homePageEnabled && settings.customUrlHomePage.isNotEmpty
          ? Uri.parse(settings.customUrlHomePage)
          : Uri.parse(settings.searchEngine.url);
    }

    browserModel.addTab(
        WebViewTab(
          key: GlobalKey(),
          webViewModel:
              WebViewModel(url: url, isIncognitoMode: true, openedByUser: true),
        ),
        true);
  }

  static void showBasicFlash(
      {Duration? duration,
      flashStyle = FlashBehavior.floating,
      required String msg,
      FlashPosition position = FlashPosition.bottom,
      Color backgroundColor = Colors.white,
      Color textColor = Colors.black,
      required BuildContext context}) {
    showFlash(
      context: context,
      duration: duration,
      builder: (context, controller) {
        return Flash(
          controller: controller,
          behavior: flashStyle,
          position: position,
          boxShadows: kElevationToShadow[4],
          backgroundColor: backgroundColor,
          horizontalDismissDirection: HorizontalDismissDirection.horizontal,
          child: FlashBar(
            content: Text(
              msg,
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w500, color: textColor),
            ),
          ),
        );
      },
    );
  }
}

class Splash extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(
          color: Colors.blue,
        ),
      ),
    );
  }
}

class HandlePermission {
  static void showDeniedError(
      {Duration? duration,
      flashStyle = FlashBehavior.floating,
      required String msg,
      required BuildContext context}) {
    showFlash(
      context: context,
      duration: duration,
      builder: (context, controller) {
        return Flash(
          controller: controller,
          behavior: flashStyle,
          position: FlashPosition.top,
          backgroundColor: Colors.red.shade400,
          boxShadows: kElevationToShadow[4],
          horizontalDismissDirection: HorizontalDismissDirection.horizontal,
          child: FlashBar(
            content: Text(
              msg,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white),
            ),
          ),
        );
      },
    );
  }
}

class FileUtil {
  static Future<String> findLocalPath() async {
    var externalStorageDirPath;
    if (Platform.isAndroid) {
      try {
        Directory path = Directory("storage/emulated/0/Download/DevWeb");
        if ((await path.exists())) {
          return path.path;
        } else {
          path.create();
          return path.path;
        }
      } catch (e) {
        final directory = await getExternalStorageDirectory();
        externalStorageDirPath = directory?.path;
        final savedDir = Directory(externalStorageDirPath);
        bool hasExisted = await savedDir.exists();
        if (!hasExisted) {
          savedDir.create();
        }
      }
    } else if (Platform.isIOS) {
      externalStorageDirPath =
          (await getApplicationDocumentsDirectory()).absolute.path;
    }
    return externalStorageDirPath;
  }
}
