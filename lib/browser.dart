import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_html/shims/dart_ui_real.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_floating_search_bar/material_floating_search_bar.dart';
import 'package:provider/provider.dart';
import 'package:webpage_dev_console/app_bar/browser_app_bar.dart';
import 'package:webpage_dev_console/helpers.dart';
import 'package:webpage_dev_console/models/webview_model.dart';
import 'package:webpage_dev_console/open_tabs_viewer.dart';
import 'package:webpage_dev_console/webview_tab.dart';

import 'empty_tab.dart';
import 'models/browser_model.dart';

class Browser extends StatefulWidget {
  Browser({Key? key}) : super(key: key);

  @override
  _BrowserState createState() => _BrowserState();
}

class _BrowserState extends State<Browser> with SingleTickerProviderStateMixin {
  static const platform =
      const MethodChannel('com.applance.webpage_dev_console.intent_data');

  GlobalKey tabInkWellKey = new GlobalKey();

  Duration customPopupDialogTransitionDuration =
      const Duration(milliseconds: 300);
  OutlineInputBorder outlineBorder = OutlineInputBorder(
    borderSide: BorderSide(color: Colors.transparent, width: 0.0),
    borderRadius: const BorderRadius.all(
      const Radius.circular(50.0),
    ),
  );

  final _searchController = FloatingSearchBarController();

  var _isRestored = false;
  @override
  void initState() {
    super.initState();

    getIntentData();

    bindBackgroundIsolate();

    FlutterDownloader.registerCallback(downloadCallback);
  }

  ReceivePort _port = ReceivePort();

  void bindBackgroundIsolate() {
    bool isSuccess = IsolateNameServer.registerPortWithName(
        _port.sendPort, 'downloader_send_port');
    if (!isSuccess) {
      unbindBackgroundIsolate();
      bindBackgroundIsolate();
      return;
    }
    // _port.listen((dynamic data) {
    //   if (debug) {
    //     print('UI Isolate Callback: $data');
    //   }
    //   String? id = data[0];
    //   DownloadTaskStatus? status = data[1];
    //   int? progress = data[2];
    // });
  }

  void unbindBackgroundIsolate() {
    IsolateNameServer.removePortNameMapping('downloader_send_port');
  }

  static void downloadCallback(
      String id, DownloadTaskStatus status, int progress) {
    if (debug) {
      print(
          'Background Isolate Callback: task ($id) is in status ($status) and process ($progress)');
    }
    final SendPort send =
        IsolateNameServer.lookupPortByName('downloader_send_port')!;
    send.send([id, status, progress]);
  }

  getIntentData() async {
    if (Platform.isAndroid) {
      String? url = await platform.invokeMethod("getIntentData");
      if (url != null) {
        var browserModel = Provider.of<BrowserModel>(context, listen: false);
        browserModel.addTab(
            WebViewTab(
              key: GlobalKey(),
              webViewModel:
                  WebViewModel(url: Uri.parse(url), openedByUser: true),
            ),
            true);
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
    _searchController.dispose();

    unbindBackgroundIsolate();
  }

  restore() async {
    var browserModel = Provider.of<BrowserModel>(context, listen: true);
    browserModel.restore();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isRestored) {
      _isRestored = true;
      // restore();
    }
    precacheImage(AssetImage("assets/icon/icon.png"), context);
  }

  @override
  Widget build(BuildContext context) {
    return _buildBrowser();
  }

  Widget _buildBrowser() {
    var currentWebViewModel = Provider.of<WebViewModel>(context, listen: true);
    var browserModel = Provider.of<BrowserModel>(context, listen: true);

    browserModel.addListener(() {
      browserModel.save();
    });
    currentWebViewModel.addListener(() {
      browserModel.save();
    });

    var canShowTabScroller =
        browserModel.showTabScroller && browserModel.webViewTabs.isNotEmpty;

    return Theme(
      data: browserModel.isIncognito
          ? ThemeData.dark().copyWith(
              backgroundColor: Colors.black,
              primaryColor: Colors.white70,
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
                bodyText1:
                    GoogleFonts.poppins(color: Colors.white, fontSize: 16),
              ),
              primaryTextTheme: TextTheme(
                bodyText1: GoogleFonts.poppins(color: Colors.white),
              ))
          : ThemeData.light().copyWith(
              backgroundColor: Colors.white,
              primaryColor: Colors.black,
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
                  bodyText1:
                      GoogleFonts.poppins(color: Colors.black, fontSize: 16))),
      child: WillPopScope(
        onWillPop: () async {
          // print("GBBBBB");
          if (canShowTabScroller) {
            browserModel.showTabScroller = false;
            // return true;
          } else {
            var wbm;
            if (browserModel.isIncognito) {
              wbm = browserModel.getCurrentIncognitoTab()?.webViewModel;
            } else {
              wbm = browserModel.getCurrentTab()?.webViewModel;
            }
            // print("Opened::");

            // print(wbm?.openedByUser);
            // log("VVVVV ::::  ${wbm?.curIndex} ::  ${wbm?.history?.list}");
            if (wbm?.openedByUser ?? false) {
              int cind = wbm?.curIndex ?? 0;

              if (cind == 0)
                platform.invokeMethod("sendToBackground");
              else {
                if (cind != 0) {
                  cind = cind - 1;
                  wbm?.curIndex = cind;
                }

                print("GOING BACK :: $cind");
                var hitem = wbm?.history?.list!.elementAt(cind);
                print("UU :: $hitem");
                var wchl =
                    await wbm?.webViewController?.getCopyBackForwardList();
                WebHistoryItem? foundInd;
                for (WebHistoryItem wchli in wchl?.list ?? []) {
                  if (hitem?.url != null) {
                    if ((wchli.url
                                .toString()
                                .compareTo(hitem?.url.toString() ?? "") ==
                            0) &&
                        (wchli.originalUrl.toString().compareTo(
                                hitem?.originalUrl.toString() ?? "") ==
                            0)) {
                      foundInd = wchli;
                      break;
                    }
                  }
                }
                if (foundInd != null) {
                  wbm?.webViewController?.goTo(historyItem: foundInd);
                } else {
                  wbm?.webViewController!
                      .loadUrl(urlRequest: URLRequest(url: hitem?.url));
                }
              }
            } else {
              if ((await wbm?.webViewController?.canGoBack()) ?? false) {
                await wbm?.webViewController?.goBack();
              } else {
                if (wbm != null && wbm.tabIndex != null) {
                  setState(() {
                    if (browserModel.isIncognito) {
                      browserModel.closeIncognitoTab(wbm.tabIndex!);
                    } else {
                      browserModel.closeTab(wbm.tabIndex!);
                    }
                  });
                  FocusScope.of(context).unfocus();
                }
              }
            }
          }
          return false;
        },
        child: IndexedStack(
          index: canShowTabScroller ? 1 : 0,
          children: [
            _buildWebViewTabs(),
            canShowTabScroller ? OpenTabsViewer() : Container()
          ],
        ),
      ),
    );
  }

  Widget _buildWebViewTabs() {
    return Scaffold(
      appBar: BrowserAppBar(),
      body: _buildWebViewTabsContent(),
    );
  }

  Widget _buildWebViewTabsContent() {
    var browserModel = Provider.of<BrowserModel>(context, listen: true);
    if (browserModel.webViewTabs.length == 0) {
      browserModel.showTabScroller = false;
      // browserModel.setCurrentWebViewModel(WebViewModel());
      Future.delayed(Duration.zero, () async {
        Helper.addNewTab(context: context, needUpdate: true);
      });
    }

    var stackChildren = <Widget>[
      IndexedStack(
        index: browserModel.isIncognito
            ? browserModel.getCurrentIncogTabIndex()
            : browserModel.getCurrentTabIndex(),
        children: (browserModel.isIncognito
                ? browserModel.incognitowebViewTabs
                : browserModel.webViewTabs)
            .map((webViewTab) {
          var isCurrentTab = webViewTab.webViewModel.tabIndex ==
              (browserModel.isIncognito
                  ? browserModel.getCurrentIncogTabIndex()
                  : browserModel.getCurrentTabIndex());

          if (isCurrentTab) {
            Future.delayed(const Duration(milliseconds: 100), () {
              webViewTab.key.currentState?.onShowTab();
            });
          } else {
            webViewTab.key.currentState?.onHideTab();
          }

          return webViewTab;
        }).toList(),
      ),
      _createProgressIndicator()
    ];

    return Stack(
      children: stackChildren,
    );
  }

  Widget _createProgressIndicator() {
    return Selector<WebViewModel, double>(
        selector: (context, webViewModel) => webViewModel.progress,
        builder: (context, progress, child) {
          if (progress >= 1.0) {
            return Container();
          }
          return PreferredSize(
              preferredSize: Size(double.infinity, 4.0),
              child: SizedBox(
                  height: 4.0,
                  child: LinearProgressIndicator(
                    value: progress,
                  )));
        });
  }
}
