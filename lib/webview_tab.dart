import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webpage_dev_console/TaskInfo.dart';
import 'package:webpage_dev_console/helpers.dart';
import 'package:webpage_dev_console/main.dart';
import 'package:webpage_dev_console/model_search.dart';
import 'package:webpage_dev_console/models/webview_model.dart';
import 'package:webpage_dev_console/util.dart';

import 'javascript_console_result.dart';
import 'long_press_alert_dialog.dart';
import 'models/browser_model.dart';
import 'package:http/http.dart' as http;

class WebViewTab extends StatefulWidget {
  final GlobalKey<WebViewTabState> key;

  WebViewTab({required this.key, required this.webViewModel}) : super(key: key);

  final WebViewModel webViewModel;

  @override
  WebViewTabState createState() => WebViewTabState();
}

class WebViewTabState extends State<WebViewTab> with WidgetsBindingObserver {
  InAppWebViewController? _webViewController;
  bool _isWindowClosed = false;

  TextEditingController _httpAuthUsernameController = TextEditingController();
  TextEditingController _httpAuthPasswordController = TextEditingController();
  late String _localPath;
  late PermissionStatus _permissionReady;
  bool _checkPermissionAfterSettingsPage = false;
  String fileName = "", durl = "";
  late BrowserModel dbm;
  bool isHisUpdated = false;
  @override
  void initState() {
    WidgetsBinding.instance!.addObserver(this);
    super.initState();
  }

  @override
  void dispose() {
    _webViewController = null;
    widget.webViewModel.webViewController = null;

    _httpAuthUsernameController.dispose();
    _httpAuthPasswordController.dispose();

    WidgetsBinding.instance!.removeObserver(this);

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_webViewController != null && Platform.isAndroid) {
      if (state == AppLifecycleState.paused) {
        pauseAll();
      } else {
        resumeAll();
      }
    }
  }

  void pauseAll() {
    if (Platform.isAndroid) {
      _webViewController?.android.pause();
    }
    pauseTimers();
  }

  void resumeAll() {
    if (Platform.isAndroid) {
      _webViewController?.android.resume();
    }
    resumeTimers();
  }

  void pause() {
    if (Platform.isAndroid) {
      _webViewController?.android.pause();
    }
  }

  void resume() async {
    if (Platform.isAndroid) {
      _webViewController?.android.resume();
    }
    if (_checkPermissionAfterSettingsPage) {
      _checkPermissionAfterSettingsPage = false;
      dbm = Provider.of<BrowserModel>(context, listen: false);
      fileName =
          await FileUtil.retryDownload(context: context, fileName: fileName);
    }
  }

  void pauseTimers() {
    _webViewController?.pauseTimers();
  }

  void resumeTimers() {
    _webViewController?.resumeTimers();
  }

  void download() {
    var task = TaskInfo(
        link: durl.toString(),
        name: fileName,
        fileName: fileName,
        savedDir: _localPath);
    dbm.requestDownload(task, _localPath, fileName);
    dbm.addDownloadTask = task;
    dbm.save();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: _buildWebView(),
    );
  }

  InAppWebView _buildWebView() {
    var browserModel = Provider.of<BrowserModel>(context, listen: true);
    var settings = browserModel.getSettings();
    var currentWebViewModel = Provider.of<WebViewModel>(context, listen: true);

    if (Platform.isAndroid) {
      AndroidInAppWebViewController.setWebContentsDebuggingEnabled(
          settings.debuggingEnabled);
    }

    var initialOptions = widget.webViewModel.options!;
    initialOptions.crossPlatform.useOnDownloadStart = true;
    initialOptions.crossPlatform.useOnLoadResource = true;
    initialOptions.crossPlatform.useShouldOverrideUrlLoading = true;
    initialOptions.crossPlatform.javaScriptCanOpenWindowsAutomatically = true;
    initialOptions.crossPlatform.userAgent =
        "Mozilla/5.0 (Linux; Android 9; LG-H870 Build/PKQ1.190522.001) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/83.0.4103.106 Mobile Safari/537.36";
    initialOptions.crossPlatform.transparentBackground = true;

    initialOptions.android.safeBrowsingEnabled = true;
    initialOptions.android.appCachePath = WEB_ARCHIVE_DIR;
    initialOptions.android.scrollbarFadingEnabled = true;
    initialOptions.android.scrollBarDefaultDelayBeforeFade = 500;
    initialOptions.android.scrollBarFadeDuration = 300;
    initialOptions.android.loadsImagesAutomatically = true;

    initialOptions.android.disableDefaultErrorPage = true;
    initialOptions.android.supportMultipleWindows = true;
    initialOptions.android.useHybridComposition = true;
    initialOptions.android.verticalScrollbarThumbColor =
        Color.fromRGBO(0, 0, 0, 0.2);
    initialOptions.android.horizontalScrollbarThumbColor =
        Color.fromRGBO(0, 0, 0, 0.2);

    initialOptions.ios.allowsLinkPreview = false;
    initialOptions.ios.isFraudulentWebsiteWarningEnabled = true;
    initialOptions.ios.disableLongPressContextMenuOnLinks = true;
    initialOptions.ios.allowingReadAccessTo =
        Uri.parse('file://$WEB_ARCHIVE_DIR/');

    return InAppWebView(
      initialUrlRequest: URLRequest(url: widget.webViewModel.url),
      initialOptions: initialOptions,
      windowId: widget.webViewModel.windowId,
      onWebViewCreated: (controller) async {
        initialOptions.crossPlatform.transparentBackground = false;
        await controller.setOptions(options: initialOptions);

        _webViewController = controller;
        widget.webViewModel.webViewController = controller;

        if (Platform.isAndroid) {
          controller.android.startSafeBrowsing();
        }
        try {
          widget.webViewModel.options = await controller.getOptions();
        } catch (e) {}

        if (isCurrentTab(currentWebViewModel)) {
          currentWebViewModel.updateWithValue(widget.webViewModel);
        }
      },
      onLoadStart: (controller, url) async {
        widget.webViewModel.isSecure = Util.urlIsSecure(url!);
        widget.webViewModel.url = url;
        widget.webViewModel.loaded = false;
        widget.webViewModel.setLoadedResources([]);
        widget.webViewModel.setJavaScriptConsoleResults([]);

        if (isCurrentTab(currentWebViewModel)) {
          currentWebViewModel.updateWithValue(widget.webViewModel);
          if (widget.webViewModel.isDesktopMode) {
            String js =
                "document.querySelector('meta[name=\"viewport\"]').setAttribute('content', 'width=1024px, initial-scale=' + (document.documentElement.clientWidth / 1024));";
            widget.webViewModel.webViewController
                ?.evaluateJavascript(source: js);
          }
        } else if (widget.webViewModel.needsToCompleteInitialLoad) {
          controller.stopLoading();
        }
        isHisUpdated = false;
        widget.webViewModel.isLoading = true;
      },
      onLoadStop: (controller, url) async {
        widget.webViewModel.url = url;
        widget.webViewModel.favicon = null;
        widget.webViewModel.loaded = true;

        var sslCertificateFuture = _webViewController?.getCertificate();
        var titleFuture = _webViewController?.getTitle();

        var sslCertificate = await sslCertificateFuture;
        if (sslCertificate == null && !Util.isLocalizedContent(url!)) {
          widget.webViewModel.isSecure = false;
        }
        widget.webViewModel.title = await titleFuture;
        if (widget.webViewModel.progress >= 1.0) {
          isHisUpdated = false;
          widget.webViewModel.isLoading = false;
          if (widget.webViewModel.isDesktopMode) {
            await widget.webViewModel.webViewController
                ?.zoomBy(zoomFactor: 0.02);
          }
        }

        // print("RT :: " +
        //     widget.webViewModel.title.toString() +
        //     " :: " +
        //     widget.webViewModel.progress.toString());
        // if (widget.webViewModel.title != null) {
        //   browserModel.addToHistory(Search(
        //       title: widget.webViewModel.title.toString(),
        //       url: widget.webViewModel.url,
        //       isHistory: true));
        // }
        // List<Favicon>? favicons = await faviconsFuture;
        // if (favicons != null && favicons.isNotEmpty) {
        //   for (var fav in favicons) {
        //     if (widget.webViewModel.favicon == null) {
        //       widget.webViewModel.favicon = fav;
        //     } else {
        //       if ((widget.webViewModel.favicon!.width == null &&
        //               !widget.webViewModel.favicon!.url
        //                   .toString()
        //                   .endsWith("favicon.ico")) ||
        //           (fav.width != null &&
        //               widget.webViewModel.favicon!.width != null &&
        //               fav.width! > widget.webViewModel.favicon!.width!)) {
        //         widget.webViewModel.favicon = fav;
        //       }
        //     }
        //   }
        // }

        if (isCurrentTab(currentWebViewModel)) {
          widget.webViewModel.needsToCompleteInitialLoad = false;
          currentWebViewModel.updateWithValue(widget.webViewModel);
        }
      },
      onProgressChanged: (controller, progress) {
        widget.webViewModel.progress = progress / 100;

        if (isCurrentTab(currentWebViewModel)) {
          currentWebViewModel.updateWithValue(widget.webViewModel);
        }
      },
      onUpdateVisitedHistory: (controller, url, androidIsReload) async {
        widget.webViewModel.url = url;
        widget.webViewModel.title = await _webViewController?.getTitle();

        if (isCurrentTab(currentWebViewModel)) {
          currentWebViewModel.updateWithValue(widget.webViewModel);
        }
        if (!isHisUpdated) {
          var hhhh = await widget.webViewModel.webViewController
              ?.getCopyBackForwardList();
          if (hhhh?.list != null && (hhhh?.list?.length ?? 0) > 0) {
            var ch = hhhh?.list?.elementAt(hhhh.currentIndex ?? 0);

            var wci = widget.webViewModel.history?.list
                ?.elementAt(widget.webViewModel.curIndex);
            if (ch?.url != wci?.url && ch?.originalUrl != wci?.originalUrl) {
              if (wci?.url == null && wci?.originalUrl == null) {
                widget.webViewModel.history?.list
                    ?.elementAt(widget.webViewModel.curIndex)
                    .url = ch?.url;
                widget.webViewModel.history?.list
                    ?.elementAt(widget.webViewModel.curIndex)
                    .originalUrl = ch?.originalUrl;
                isHisUpdated = true;
              } else {
                widget.webViewModel.curIndex += 1;
                widget.webViewModel.history?.list?.removeRange(
                    widget.webViewModel.curIndex,
                    widget.webViewModel.history?.list?.length ?? 0);
                widget.webViewModel.history?.list?.add(WebHistoryItem());

                widget.webViewModel.history?.list
                    ?.elementAt(widget.webViewModel.curIndex)
                    .url = ch?.url;
                widget.webViewModel.history?.list
                    ?.elementAt(widget.webViewModel.curIndex)
                    .originalUrl = ch?.originalUrl;
                isHisUpdated = true;
              }

              browserModel.save();
            }
          }
        }

        // if (widget.webViewModel.title != null &&
        //     widget.webViewModel.progress >= 0.9) {
        //   browserModel.addToHistory(Search(
        //       title: widget.webViewModel.title.toString(),
        //       url: widget.webViewModel.url,
        //       isHistory: true));
        // }
      },
      onLongPressHitTestResult: (controller, hitTestResult) async {
        if (LongPressAlertDialog.HIT_TEST_RESULT_SUPPORTED
            .contains(hitTestResult.type)) {
          var requestFocusNodeHrefResult =
              await _webViewController?.requestFocusNodeHref();

          if (requestFocusNodeHrefResult != null) {
            showDialog(
              context: context,
              builder: (context) {
                return LongPressAlertDialog(
                  webViewModel: widget.webViewModel,
                  hitTestResult: hitTestResult,
                  requestFocusNodeHrefResult: requestFocusNodeHrefResult,
                );
              },
            );
          }
        }
      },
      onConsoleMessage: (controller, consoleMessage) {
        Color consoleTextColor = Colors.black;
        Color consoleBackgroundColor = Colors.transparent;
        IconData? consoleIconData;
        Color? consoleIconColor;
        if (consoleMessage.messageLevel == ConsoleMessageLevel.ERROR) {
          consoleTextColor = Colors.red;
          consoleIconData = Icons.report_problem;
          consoleIconColor = Colors.red;
        } else if (consoleMessage.messageLevel == ConsoleMessageLevel.TIP) {
          consoleTextColor = Colors.blue;
          consoleIconData = Icons.info;
          consoleIconColor = Colors.blueAccent;
        } else if (consoleMessage.messageLevel == ConsoleMessageLevel.WARNING) {
          consoleBackgroundColor = Color.fromRGBO(255, 251, 227, 1);
          consoleIconData = Icons.report_problem;
          consoleIconColor = Colors.orangeAccent;
        }

        widget.webViewModel.addJavaScriptConsoleResults(JavaScriptConsoleResult(
          data: consoleMessage.message,
          textColor: consoleTextColor,
          backgroundColor: consoleBackgroundColor,
          iconData: consoleIconData,
          iconColor: consoleIconColor,
        ));

        if (isCurrentTab(currentWebViewModel)) {
          currentWebViewModel.updateWithValue(widget.webViewModel);
        }
      },
      onLoadResource: (controller, resource) {
        widget.webViewModel.addLoadedResources(resource);

        if (isCurrentTab(currentWebViewModel)) {
          currentWebViewModel.updateWithValue(widget.webViewModel);
        }
      },
      shouldOverrideUrlLoading: (controller, navigationAction) async {
        var url = navigationAction.request.url;

        if (url != null &&
            ![
              "http",
              "https",
              "file",
              "chrome",
              "data",
              "javascript",
              "about",
              "ws"
            ].contains(url.scheme)) {
          if (await canLaunch(url.toString())) {
            // Launch the App
            await launch(
              url.toString(),
            );
            // and cancel the request
            return NavigationActionPolicy.CANCEL;
          }
        }

        return NavigationActionPolicy.ALLOW;
      },
      onDownloadStart: (controller, url) async {
        String path = url.path;
        durl = url.toString();
        fileName = path.substring(path.lastIndexOf('/') + 1);

        RegExp unspupportedRegex = RegExp(r'[@$%&\/:*?"<>|~`^+={}[];!]');
        if (unspupportedRegex.hasMatch(fileName) || fileName.contains("'")) {
          final response = await http.head(Uri.parse("$durl"));
          if (response.headers.containsKey("content-type")) {
            var t = response.headers["content-type"] ?? "";
            fileName = "download." + t.split("/").last;
          }
        }

        // final taskId = await FlutterDownloader.enqueue(
        //   url: url.toString(),
        //   fileName: fileName,
        //   savedDir: (await getTemporaryDirectory()).path,
        //   showNotification: true,
        //   openFileFromNotification: true,
        // );
        dbm = browserModel;
        _permissionReady = await FileUtil.checkPermission(context: context);

        if (_permissionReady == PermissionStatus.granted) {
          _localPath = await FileUtil.findLocalPath();
          print("Checking in :: $_localPath");

          bool fileExists = await File(_localPath + "/" + fileName).exists();
          if (fileExists) {
            // var files = await myDir.toList();
            // print(entries.length.toString());

            // files.forEach((entity) {
            //   print(entity.path);
            //   if (entity.path.endsWith(fileName)) count += 1;
            // });

            // await for (var entity
            //     in myDir.list(recursive: false, followLinks: false)) {
            //   print(entity.path);
            //   if (entity.path.endsWith(fileName)) count += 1;
            // }
            // fileName = await getFileName(fileName);
            FileUtil.showAlreadyFileExistsError(
                context: context,
                action: () async {
                  fileName = await FileUtil.getFileName(
                      context: context, fileName: fileName);
                  download();
                });
          } else {
            download();
          }
        } else {
          if (_permissionReady == PermissionStatus.permanentlyDenied) {
            FileUtil.showPermissionError(
                context: context,
                action: () {
                  _checkPermissionAfterSettingsPage = true;
                });
          }
        }
      },
      onReceivedServerTrustAuthRequest: (controller, challenge) async {
        var sslError = challenge.protectionSpace.sslError;
        if (sslError != null &&
            (sslError.iosError != null || sslError.androidError != null)) {
          if (Platform.isIOS && sslError.iosError == IOSSslError.UNSPECIFIED) {
            return ServerTrustAuthResponse(
                action: ServerTrustAuthResponseAction.PROCEED);
          }
          widget.webViewModel.isSecure = false;
          if (isCurrentTab(currentWebViewModel)) {
            currentWebViewModel.updateWithValue(widget.webViewModel);
          }
          return ServerTrustAuthResponse(
              action: ServerTrustAuthResponseAction.CANCEL);
        }
        return ServerTrustAuthResponse(
            action: ServerTrustAuthResponseAction.PROCEED);
      },
      onLoadError: (controller, url, code, message) async {
        if (Platform.isIOS && code == -999) {
          // NSURLErrorDomain
          return;
        }

        var errorUrl =
            url ?? widget.webViewModel.url ?? Uri.parse('about:blank');

        _webViewController?.loadData(data: """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, user-scalable=no, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0">
    <meta http-equiv="X-UA-Compatible" content="ie=edge">
    <style>
    ${await _webViewController?.getTRexRunnerCss()}
    </style>
    <style>
    .interstitial-wrapper {
        box-sizing: border-box;
        font-size: 1em;
        line-height: 1.6em;
        margin: 0 auto 0;
        max-width: 600px;
        width: 100%;
    }
    </style>
</head>
<body>
    ${await _webViewController?.getTRexRunnerHtml()}
    <div class="interstitial-wrapper">
      <h1>Website not available</h1>
      <p>Could not load web pages at <strong>$errorUrl</strong> because:</p>
      <p>$message</p>
    </div>
</body>
    """, baseUrl: errorUrl, androidHistoryUrl: errorUrl);

        widget.webViewModel.url = url;
        widget.webViewModel.isSecure = false;

        if (isCurrentTab(currentWebViewModel)) {
          currentWebViewModel.updateWithValue(widget.webViewModel);
        }
      },
      onTitleChanged: (controller, title) async {
        widget.webViewModel.title = title;
        if (isCurrentTab(currentWebViewModel)) {
          currentWebViewModel.updateWithValue(widget.webViewModel);
        }
        if (widget.webViewModel.title != null) {
          browserModel.addToHistory(Search(
              title: widget.webViewModel.title.toString().trim(),
              url: widget.webViewModel.url,
              isHistory: true));
        }
        // var hhhh = browserModel.getCurrentTab()?.webViewModel.history;
        // print("TAB HIS :: $hhhh");
        // browserModel.getCurrentTab()?.webViewModel.addBackHistory(await widget
        //     .webViewModel.webViewController
        //     ?.getCopyBackForwardList());
        // browserModel.save();
      },
      onCreateWindow: (controller, createWindowRequest) async {
        var webViewTab = WebViewTab(
          key: GlobalKey(),
          webViewModel: WebViewModel(
              url: Uri.parse("about:blank"),
              windowId: createWindowRequest.windowId),
        );

        browserModel.addTab(webViewTab, true);

        return true;
      },
      onCloseWindow: (controller) {
        if (_isWindowClosed) {
          return;
        }
        _isWindowClosed = true;
        if (widget.webViewModel.tabIndex != null) {
          browserModel.closeTab(widget.webViewModel.tabIndex!);
        }
      },
      androidOnPermissionRequest: (InAppWebViewController controller,
          String origin, List<String> resources) async {
        return PermissionRequestResponse(
            resources: resources,
            action: PermissionRequestResponseAction.GRANT);
      },
      onReceivedHttpAuthRequest: (InAppWebViewController controller,
          URLAuthenticationChallenge challenge) async {
        var action = await createHttpAuthDialog(challenge);
        return HttpAuthResponse(
            username: _httpAuthUsernameController.text.trim(),
            password: _httpAuthPasswordController.text,
            action: action,
            permanentPersistence: true);
      },
    );
  }

  bool isCurrentTab(WebViewModel currentWebViewModel) {
    return currentWebViewModel.tabIndex == widget.webViewModel.tabIndex;
  }

  Future<HttpAuthResponseAction> createHttpAuthDialog(
      URLAuthenticationChallenge challenge) async {
    HttpAuthResponseAction action = HttpAuthResponseAction.CANCEL;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Login"),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(challenge.protectionSpace.host),
              TextField(
                decoration: InputDecoration(labelText: "Username"),
                controller: _httpAuthUsernameController,
              ),
              TextField(
                decoration: InputDecoration(labelText: "Password"),
                controller: _httpAuthPasswordController,
                obscureText: true,
              ),
            ],
          ),
          actions: <Widget>[
            ElevatedButton(
              child: Text("Cancel"),
              onPressed: () {
                action = HttpAuthResponseAction.CANCEL;
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text("Ok"),
              onPressed: () {
                action = HttpAuthResponseAction.PROCEED;
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );

    return action;
  }

  void onShowTab() async {
    this.resume();
    if (widget.webViewModel.needsToCompleteInitialLoad) {
      widget.webViewModel.needsToCompleteInitialLoad = false;
      await widget.webViewModel.webViewController
          ?.loadUrl(urlRequest: URLRequest(url: widget.webViewModel.url));
    }
  }

  void onHideTab() async {
    this.pause();
  }
}
