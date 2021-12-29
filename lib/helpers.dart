import 'dart:io';

import 'package:flash/flash.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:html/parser.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:share/share.dart';
import 'package:share_extend/share_extend.dart';
import 'package:webpage_dev_console/TaskInfo.dart';
import 'package:webpage_dev_console/models/browser_model.dart';
import 'package:webpage_dev_console/models/webview_model.dart';
import 'package:webpage_dev_console/webview_tab.dart';
import 'package:filesystem_picker/filesystem_picker.dart';

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
    String res = t.join("-").trim();
    String scheme = res.split("//").first.trim().toLowerCase();
    if (["http", "https", "file", "chrome", "data", "javascript", "about", "ws"]
        .contains(scheme))
      res = scheme + ":" + "//" + res.split("//").sublist(1).join("//").trim();
    return res;
  }

  static String htmlToString(String htmlString) {
    final document = parse(htmlString);
    final String parsedString =
        parse(document.body?.text).documentElement!.text;
    return parsedString;
  }

  static getFavIconUrl(String url, String secondUrl) {
    url = url.trim();
    var u = Uri.parse(url);
    return Uri.parse((url == "" ? secondUrl : u.origin) + "/favicon.ico");
  }

  static int polynomialRollingHash(String str) {
    // P and M
    int p = 293;
    int m = (1e9 + 9).toInt();
    int powerOfP = 1;
    int hashVal = 0;

    // Loop to calculate the hash value
    // by iterating over the elements of String
    for (int i = 0; i < str.length; i++) {
      hashVal = (hashVal + (int.parse(str[i]) + 1) * powerOfP) % m;
      powerOfP = (powerOfP * p) % m;
    }
    return hashVal;
  }

  static void share(BuildContext context) {
    var browserModel = Provider.of<BrowserModel>(context, listen: false);
    var webViewModel = browserModel.getCurrentTab()?.webViewModel;
    var url = webViewModel?.url;
    if (url != null) {
      Share.share(url.toString(), subject: webViewModel?.title);
    }
  }

  static void shareFiles(List<String> filePaths) async {
    ShareExtend.shareMultiple(filePaths, "file",
        subject: "Share the selected files to");
  }

  static showLoadingDialog(
      {required BuildContext context, required String msg}) {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) {
          return AlertDialog(
            content: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: Colors.blue,
                ),
                SizedBox(
                  width: 16,
                ),
                Text(msg),
              ],
            ),
          );
        });
  }

  static void addNewTab(
      {Uri? url, required BuildContext context, bool needUpdate = true}) {
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
        needUpdate);
  }

  static void addNewIncognitoTab(
      {Uri? url, required BuildContext context, bool needUpdate = true}) {
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
        needUpdate);
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

  static void cancelDownload(
      {required TaskInfo task, bool removeFromStorage = true}) async {
    print("Canceling");
    if (task.status != DownloadTaskStatus.complete) {
      await FlutterDownloader.cancel(taskId: task.taskId!);
    }
    await FlutterDownloader.remove(
        taskId: task.taskId!, shouldDeleteContent: removeFromStorage);
  }

  static void pauseDownload(TaskInfo task) async {
    await FlutterDownloader.pause(taskId: task.taskId!);
  }

  static void resumeDownload(TaskInfo task) async {
    String? newTaskId = await FlutterDownloader.resume(taskId: task.taskId!);
    task.taskId = newTaskId;
  }

  static void retryDownload(TaskInfo task) async {
    String? newTaskId = await FlutterDownloader.retry(taskId: task.taskId!);
    task.taskId = newTaskId;
  }

  static downloadActionclick(
      TaskInfo task, BrowserModel browserModel, String _localPath) {
    if (task.status == DownloadTaskStatus.undefined) {
      browserModel.requestDownload(task, _localPath, task.name.toString());
    } else if (task.status == DownloadTaskStatus.running) {
      pauseDownload(task);
    } else if (task.status == DownloadTaskStatus.paused) {
      resumeDownload(task);
    } else if (task.status == DownloadTaskStatus.failed ||
        task.status == DownloadTaskStatus.canceled) {
      retryDownload(task);
    }
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

  static Future<String> getFileName(
      {required String fileName, required BuildContext context}) async {
    var fn1 = fileName.split(".");
    var fn2 = fn1.sublist(0, fn1.length - 1);
    String _localPath = await FileUtil.findLocalPath();
    print("Downloading in :: $_localPath");
    var myDir = Directory(_localPath);
    var fname = fn2.join(".");

    var count = 0;
    var exists = await myDir.exists();
    if (!exists) {
      _localPath = await FileUtil.findLocalPath();
      myDir = Directory(_localPath);
      exists = await myDir.exists();
    }
    if (exists) {
      var l = myDir.list(recursive: false, followLinks: false);
      var tasks = await FlutterDownloader.loadTasks();
      var l2 = await l.toList();
      l2.forEach((element) {
        var fp = element.path.split("/").last;
        if (fp.startsWith(fname) && fn1.last == fp.split(".").last) {
          count += 1;
        }
      });
      tasks?.forEach((element) {
        var tfn = element.filename ?? "";
        var temp = fname + " ($count)." + fn1.last;
        if (tfn.startsWith(fname) && tfn == temp) {
          count += 1;
        }
      });
    } else {
      Helper.showBasicFlash(
          msg: "Not able to download file.",
          context: context,
          position: FlashPosition.top,
          backgroundColor: Colors.redAccent,
          textColor: Colors.white,
          duration: Duration(seconds: 5));
    }

    return fname + " ($count)." + fn1.last;
  }

  static Future<PermissionStatus> checkPermission(
      {required BuildContext context}) async {
    final platform = Theme.of(context).platform;
    // DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    // AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    //  &&
    //     androidInfo.version.sdkInt <= 28
    if (platform == TargetPlatform.android) {
      final status = await Permission.storage.status;

      if (status != PermissionStatus.granted) {
        var result = await Permission.storage.request();

        if (result == PermissionStatus.granted) {
          return PermissionStatus.granted;
        }
      } else {
        return PermissionStatus.granted;
      }
    }
    return PermissionStatus.permanentlyDenied;
  }

  static void showAlreadyFileExistsError({
    bool persistent = true,
    EdgeInsets margin = EdgeInsets.zero,
    required BuildContext context,
    required Function action,
  }) {
    showFlash(
      context: context,
      persistent: persistent,
      builder: (_, controller) {
        return Flash(
          controller: controller,
          margin: margin,
          behavior: FlashBehavior.fixed,
          position: FlashPosition.bottom,
          borderRadius: BorderRadius.circular(8.0),
          boxShadows: kElevationToShadow[8],
          onTap: () => controller.dismiss(),
          forwardAnimationCurve: Curves.easeInBack,
          reverseAnimationCurve: Curves.easeInCubic,
          child: FlashBar(
            title: Text(
              'Warning!',
              style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 20.0),
            ),
            content: Text(
              "The file is already present, do you want to download again?",
              style: TextStyle(color: Colors.black),
            ),
            indicatorColor: Colors.red,
            icon: Icon(Icons.info_outline),
            primaryAction: IconButton(
              constraints: BoxConstraints(),
              padding: EdgeInsets.zero,
              onPressed: () => controller.dismiss(),
              icon: Icon(Icons.close),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  controller.dismiss();
                },
                child: Text(
                  'Cancel',
                  style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                      fontSize: 16.0),
                ),
              ),
              TextButton(
                  onPressed: () async {
                    controller.dismiss();
                    action();
                  },
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black26,
                              blurRadius: 1,
                              offset: Offset(1, 1)),
                        ]),
                    child: Text(
                      'Download',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16.0),
                    ),
                  )),
            ],
          ),
        );
      },
    );
  }

  static Future showPermissionError(
      {bool persistent = true,
      required BuildContext context,
      required Function action}) async {
    context.showFlashDialog(
        persistent: persistent,
        title: Text('Error!'),
        content: Text(
          'Please grant accessing storage permission to continue -_-',
          textAlign: TextAlign.left,
          style: TextStyle(color: Colors.blueGrey, fontSize: 18.0),
        ),
        negativeActionBuilder: (context, controller, _) {
          return TextButton(
            onPressed: () {
              controller.dismiss();
            },
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.red.shade400,
                fontWeight: FontWeight.bold,
                fontSize: 20.0,
              ),
            ),
          );
        },
        positiveActionBuilder: (context, controller, _) {
          return TextButton(
              onPressed: () async {
                await openAppSettings();
                action();
                controller.dismiss();
              },
              child: Text(
                'Open Settings',
                style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 20.0),
              ));
        });
  }

  static Future<File> changeFileNameOnly(File file, String newFileName) {
    var path = file.path;
    var lastSeparator = path.lastIndexOf(Platform.pathSeparator);
    var newPath = path.substring(0, lastSeparator + 1) + newFileName;
    return file.rename(newPath);
  }

  static Future<String> retryDownload(
      {required BuildContext context, required String fileName}) async {
    BrowserModel dbm = Provider.of<BrowserModel>(context, listen: false);
    var result = await Permission.storage.request();

    if (result == PermissionStatus.granted) {
      return await FileUtil.getFileName(context: context, fileName: fileName);
      // download();
    } else {
      HandlePermission.showDeniedError(
          msg: "Not able to download as write storage permision is not given.",
          duration: Duration(seconds: 5),
          context: context);
    }
    return "";
  }

  void download({
    required String durl,
    required String fileName,
    required String localPath,
    required BrowserModel browserModel,
  }) {
    var task = TaskInfo(
        link: durl.toString(),
        name: fileName,
        fileName: fileName,
        savedDir: localPath);
    browserModel.requestDownload(task, localPath, fileName);
    browserModel.addDownloadTask = task;
    browserModel.save();
  }

  static Future<String?> getFolder(
      {required BuildContext context, required Directory rootPath}) async {
    return await FilesystemPicker.open(
      title: 'Save to folder',
      context: context,
      rootDirectory: rootPath,
      fsType: FilesystemType.folder,
      pickText: 'Save file to this folder',
      folderIconColor: Colors.teal,
      requestPermission: () async =>
          await Permission.storage.request().isGranted,
    );
  }
}
