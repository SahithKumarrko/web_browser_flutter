import 'dart:developer';
import 'dart:io';

// import 'package:cached_network_image/cached_network_image.dart';
import 'package:flash/flash.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share/share.dart';
import 'package:share_extend/share_extend.dart';
import 'package:webpage_dev_console/TaskInfo.dart';
import 'package:webpage_dev_console/app_bar/url_info_popup.dart';
import 'package:webpage_dev_console/c_popmenuitem.dart';
import 'package:webpage_dev_console/custom_image.dart';
import 'package:webpage_dev_console/custom_popup_dialog.dart';
import 'package:webpage_dev_console/developers/main.dart';
import 'package:webpage_dev_console/favorites.dart';
import 'package:webpage_dev_console/helpers.dart';
import 'package:webpage_dev_console/history.dart';
import 'package:webpage_dev_console/main.dart';
import 'package:webpage_dev_console/model_search.dart';
import 'package:webpage_dev_console/models/browser_model.dart';
import 'package:webpage_dev_console/models/favorite_model.dart';
import 'package:webpage_dev_console/models/findResults.dart';
import 'package:webpage_dev_console/models/web_archive_model.dart';
import 'package:webpage_dev_console/models/webview_model.dart';
import 'package:webpage_dev_console/page_download.dart';
import 'package:webpage_dev_console/search_page.dart';
import 'package:webpage_dev_console/settings/main.dart';
import 'package:webpage_dev_console/tab_popup_menu_actions.dart';

import '../popup_menu_actions.dart';
import '../webview_tab.dart';

GlobalKey favKey = GlobalKey();

class WebViewTabAppBar extends StatefulWidget {
  final void Function()? showFindOnPage;

  WebViewTabAppBar({Key? key, this.showFindOnPage}) : super(key: key);

  @override
  _WebViewTabAppBarState createState() => _WebViewTabAppBarState();
}

class _WebViewTabAppBarState extends State<WebViewTabAppBar>
    with SingleTickerProviderStateMixin {
  TextEditingController? _searchController = TextEditingController();
  FocusNode? _focusNode;

  GlobalKey tabInkWellKey = new GlobalKey();

  Duration customPopupDialogTransitionDuration =
      const Duration(milliseconds: 300);
  CustomPopupDialogPageRoute? route;

  OutlineInputBorder outlineBorder = OutlineInputBorder(
    borderSide: BorderSide(color: Colors.transparent, width: 0.0),
    borderRadius: const BorderRadius.all(
      const Radius.circular(50.0),
    ),
  );

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode?.addListener(() async {
      if (_focusNode != null &&
          !_focusNode!.hasFocus &&
          _searchController != null &&
          _searchController!.text.isEmpty) {
        var browserModel = Provider.of<BrowserModel>(context, listen: true);
        var webViewModel = browserModel.getCurrentTab()?.webViewModel;
        var _webViewController = webViewModel?.webViewController;
        _searchController!.text =
            (await _webViewController?.getUrl())?.toString() ?? "";
      }
    });
  }

  @override
  void dispose() {
    _focusNode?.dispose();
    _focusNode = null;
    _searchController?.dispose();
    _searchController = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Selector<WebViewModel, Uri?>(
        selector: (context, webViewModel) => webViewModel.url,
        builder: (context, url, child) {
          if (url == null) {
            _searchController?.text = "";
          }
          if (url != null && _focusNode != null && !_focusNode!.hasFocus) {
            _searchController?.text = url.toString();
          }

          Widget? leading = _buildAppBarHomePageWidget();
          return Selector<WebViewModel, bool>(
              selector: (context, webViewModel) => webViewModel.isIncognitoMode,
              builder: (context, isIncognitoMode, child) {
                return leading != null
                    ? AppBar(
                        backgroundColor: Theme.of(context).backgroundColor,
                        leading: _buildAppBarHomePageWidget(),
                        centerTitle: false,
                        leadingWidth: 26,

                        // titleSpacing: 10.0,
                        title: _buildSearchTextField(),
                        actions: _buildActionsMenu(),
                      )
                    : AppBar(
                        backgroundColor: Theme.of(context).backgroundColor,
                        titleSpacing: 10.0,
                        title: _buildSearchTextField(),
                        actions: _buildActionsMenu(),
                      );
              });
        });
  }

  Widget? _buildAppBarHomePageWidget() {
    var browserModel = Provider.of<BrowserModel>(context, listen: true);
    var settings = browserModel.getSettings();

    var webViewModel = Provider.of<WebViewModel>(context, listen: true);
    var _webViewController = webViewModel.webViewController;
    settings.homePageEnabled = true;
    if (!settings.homePageEnabled) {
      return null;
    }

    return IconButton(
      icon: Icon(
        Icons.home_outlined,
      ),
      onPressed: () {
        if (_webViewController != null) {
          var url =
              settings.homePageEnabled && settings.customUrlHomePage.isNotEmpty
                  ? Uri.parse(settings.customUrlHomePage)
                  : Uri.parse(settings.searchEngine.url);
          _webViewController.loadUrl(urlRequest: URLRequest(url: url));
        } else {
          Helper.addNewTab(context: context);
        }
      },
    );
  }

  Widget _buildSearchTextField() {
    var browserModel = Provider.of<BrowserModel>(context, listen: false);
    var webViewModel = Provider.of<WebViewModel>(context, listen: true);
    var wc = webViewModel.webViewController;
    bool isLoading = (browserModel.isIncognito
                ? browserModel.getCurrentIncognitoTab()
                : browserModel.getCurrentTab())
            ?.webViewModel
            .isLoading ??
        false;
    String without = webViewModel.url
            ?.toString()
            .replaceFirst(RegExp("http[s]{0,1}:[/]{2}"), "") ??
        "";
    String origin = webViewModel.url?.origin
            .replaceFirst(RegExp("http[s]{0,1}:[/]{2}"), "") ??
        "";
    print("Origin :: $origin ;;; Without :: $without");
    return Container(
      height: 40.0,
      decoration: BoxDecoration(
          // border: Border.all(color: Colors.black),
          color: Theme.of(context).brightness == Brightness.dark ||
                  browserModel.isIncognito
              ? Color(0xFF4f5761)
              : Colors.grey[200],
          boxShadow: [
            BoxShadow(
                color: Theme.of(this.context)
                    .colorScheme
                    .onSurface
                    .withOpacity(0.2),
                blurRadius: 2,
                offset: Offset(1, 1))
          ],
          borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          IconButton(
            padding: EdgeInsets.only(left: 6, right: 4),
            constraints: BoxConstraints(),
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            hoverColor: Colors.transparent,
            icon: Selector<WebViewModel, bool>(
              selector: (context, webViewModel) => webViewModel.isSecure,
              builder: (context, isSecure, child) {
                var icon = Icons.info_outline;
                if (webViewModel.isIncognitoMode) {
                  icon = FontAwesomeIcons.userSecret;
                } else if (isSecure) {
                  if (webViewModel.url != null &&
                      webViewModel.url!.scheme == "file") {
                    icon = Icons.offline_pin;
                  } else {
                    icon = Icons.lock;
                  }
                }

                return Icon(
                  icon,
                  size: 20,
                  color: isSecure ? Colors.green : Colors.grey,
                );
              },
            ),
            onPressed: () {
              showUrlInfo();
            },
          ),
          Expanded(
            child: InkWell(
              splashFactory: NoSplash.splashFactory,
              onTap: () {
                Navigator.of(context)
                    .push(MaterialPageRoute(builder: (c) => SearchPage()));
              },
              child: Padding(
                padding: EdgeInsets.only(right: 6),
                child: webViewModel.url == null || without.length == 0
                    ? Text(
                        "Search for or type a web address",
                        textDirection: TextDirection.ltr,
                        overflow: TextOverflow.fade,
                        style: Theme.of(this.context)
                            .textTheme
                            .bodyText2
                            ?.copyWith(
                                color: Theme.of(this.context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.5)),
                      )
                    : RichText(
                        textDirection: TextDirection.ltr,
                        overflow: TextOverflow.fade,
                        maxLines: 1,
                        text: TextSpan(children: [
                          TextSpan(
                              text: origin,
                              style:
                                  Theme.of(this.context).textTheme.bodyText1),
                          TextSpan(
                              text: without.replaceFirst(origin, ""),
                              style: Theme.of(this.context)
                                  .textTheme
                                  .bodyText2
                                  ?.copyWith(
                                      color: Theme.of(this.context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.6)))
                        ])),
              ),
            ),
          ),
          IconButton(
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              hoverColor: Colors.transparent,
              padding: EdgeInsets.only(right: 6),
              constraints: BoxConstraints(),
              onPressed: () async {
                if (!isLoading) {
                  await wc?.reload();
                  browserModel.addToHistory(Search(
                      title: webViewModel.title.toString(),
                      url: webViewModel.url,
                      isHistory: true,
                      isIncognito: browserModel.isIncognito ||
                          webViewModel.isIncognitoMode));
                } else {
                  await wc?.stopLoading();
                }
              },
              icon: isLoading
                  ? FaIcon(
                      FontAwesomeIcons.timesCircle,
                      size: 20,
                    )
                  : Icon(Icons.refresh_rounded),
              iconSize: 24,
              color: wc != null
                  ? Theme.of(context).colorScheme.onBackground.withOpacity(0.7)
                  : Colors.black12)
        ],
      ),
    );
  }

  List<Widget> _buildActionsMenu() {
    var browserModel = Provider.of<BrowserModel>(context, listen: true);
    return <Widget>[
      // settings.homePageEnabled
      //     ? SizedBox(
      //         width: 10.0,
      //       )
      //     : Container(),
      InkWell(
        key: tabInkWellKey,
        onLongPress: () {
          final RenderBox? box =
              tabInkWellKey.currentContext!.findRenderObject() as RenderBox?;
          if (box == null) {
            return;
          }

          Offset position = box.localToGlobal(Offset.zero);

          showMenu(
                  context: context,
                  position: RelativeRect.fromLTRB(position.dx,
                      position.dy + box.size.height, box.size.width, 0),
                  items: TabPopupMenuActions.choices.map((tabPopupMenuAction) {
                    IconData? iconData;
                    switch (tabPopupMenuAction) {
                      case TabPopupMenuActions.CLOSE_TABS:
                        iconData = Icons.cancel;
                        break;
                      case TabPopupMenuActions.NEW_TAB:
                        iconData = Icons.add;
                        break;
                      case TabPopupMenuActions.NEW_INCOGNITO_TAB:
                        iconData = FontAwesomeIcons.userSecret;
                        break;
                    }

                    return PopupMenuItem<String>(
                      value: tabPopupMenuAction,
                      child: Row(children: [
                        Icon(
                          iconData,
                          color: Colors.black,
                        ),
                        Container(
                          padding: EdgeInsets.only(left: 10.0),
                          child: Text(tabPopupMenuAction),
                        )
                      ]),
                    );
                  }).toList())
              .then((value) {
            switch (value) {
              case TabPopupMenuActions.CLOSE_TABS:
                browserModel.closeAllTabs();
                break;
              case TabPopupMenuActions.NEW_TAB:
                Helper.addNewTab(context: context);
                break;
              case TabPopupMenuActions.NEW_INCOGNITO_TAB:
                Helper.addNewIncognitoTab(context: context);
                break;
            }
          });
        },
        onTap: () async {
          var webViewTabs = (browserModel.isIncognito
              ? browserModel.incognitowebViewTabs
              : browserModel.webViewTabs);
          if (webViewTabs.length > 0) {
            var webViewModel = (browserModel.isIncognito
                    ? browserModel.getCurrentIncognitoTab()
                    : browserModel.getCurrentTab())
                ?.webViewModel;
            var webViewController = webViewModel?.webViewController;
            var widgetsBingind = WidgetsBinding.instance;

            if (widgetsBingind != null &&
                widgetsBingind.window.viewInsets.bottom > 0.0) {
              if (FocusManager.instance.primaryFocus != null)
                FocusManager.instance.primaryFocus!.unfocus();
              if (webViewController != null) {
                await webViewController.evaluateJavascript(
                    source: "document.activeElement.blur();");
              }
              // await Future.delayed(Duration(milliseconds: 300));
            }

            // browserModel.showLoadingDialog(context);
            // await Future.delayed(Duration(milliseconds: 60));
            browserModel.showTabScroller = true;
          }
        },
        child: Container(
          margin: EdgeInsets.only(top: 16.0, bottom: 16.0),
          padding: EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
              border: Border.all(
                  width: 2.0, color: Theme.of(context).colorScheme.onSurface),
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(5.0)),
          constraints: BoxConstraints(minWidth: 20.0),
          child: Center(
              child: Text(
            browserModel.isIncognito
                ? browserModel.incognitowebViewTabs.length.toString()
                : browserModel.webViewTabs.length.toString(),
            style: Theme.of(context)
                .textTheme
                .bodyText1
                ?.copyWith(fontWeight: FontWeight.bold, fontSize: 12.0),
          )),
        ),
      ),
      PopupMenuButton<String>(
        onSelected: _popupMenuChoiceAction,
        icon: Icon(Icons.more_vert_rounded),
        iconSize: 24,
        itemBuilder: (popupMenuContext) {
          var items = [
            CustomPopupMenuItem<String>(
              enabled: true,
              isIconButtonRow: true,
              child: StatefulBuilder(
                builder: (statefulContext, setState) {
                  var browserModel =
                      Provider.of<BrowserModel>(statefulContext, listen: true);
                  var webViewModel =
                      Provider.of<WebViewModel>(statefulContext, listen: true);
                  var _webViewController = webViewModel.webViewController;

                  var isFavorite = false;
                  FavoriteModel? favorite;

                  if (webViewModel.url != null &&
                      webViewModel.url!.toString().isNotEmpty) {
                    favorite = FavoriteModel(
                        url: webViewModel.url,
                        title: webViewModel.title ?? "",
                        favicon: webViewModel.favicon);
                    isFavorite = browserModel.containsFavorite(favorite);
                  }

                  var children = <Widget>[];

                  if (Platform.isIOS) {
                    children.add(
                      Container(
                          width: 35.0,
                          child: IconButton(
                              padding: const EdgeInsets.all(0.0),
                              icon: Icon(
                                Icons.arrow_back,
                                color: Colors.black,
                              ),
                              onPressed: () async {
                                var canShowTabScroller =
                                    browserModel.showTabScroller &&
                                        browserModel.webViewTabs.isNotEmpty;

                                if (canShowTabScroller) {
                                  browserModel.showTabScroller = false;
                                  // return true;
                                } else {
                                  var wbm;
                                  if (browserModel.isIncognito) {
                                    wbm = browserModel
                                        .getCurrentIncognitoTab()
                                        ?.webViewModel;
                                  } else {
                                    wbm = browserModel
                                        .getCurrentTab()
                                        ?.webViewModel;
                                  }
                                  print(wbm?.openedByUser);
                                  if (wbm?.openedByUser ?? false) {
                                    int cind = wbm?.curIndex ?? 0;
                                    var platform = const MethodChannel(
                                        'com.applance.webpage_dev_console.intent_data');

                                    if (cind == 0)
                                      platform.invokeMethod("sendToBackground");
                                    else {
                                      if (cind != 0) {
                                        cind = cind - 1;
                                        wbm?.curIndex = cind;
                                      }
                                      log(wbm?.history);
                                      print("GOING BACK :: $cind");
                                      var hitem =
                                          wbm?.history?.list!.elementAt(cind);
                                      print("UU :: $hitem");
                                      var wchl = await wbm?.webViewController
                                          ?.getCopyBackForwardList();
                                      WebHistoryItem? foundInd;
                                      for (WebHistoryItem wchli
                                          in wchl?.list ?? []) {
                                        if (hitem?.url != null) {
                                          if ((wchli.url.toString().compareTo(
                                                      hitem?.url.toString() ??
                                                          "") ==
                                                  0) &&
                                              (wchli.originalUrl
                                                      .toString()
                                                      .compareTo(hitem
                                                              ?.originalUrl
                                                              .toString() ??
                                                          "") ==
                                                  0)) {
                                            foundInd = wchli;
                                            break;
                                          }
                                        }
                                      }
                                      if (foundInd != null) {
                                        wbm?.webViewController
                                            ?.goTo(historyItem: foundInd);
                                      } else {
                                        wbm?.webViewController!.loadUrl(
                                            urlRequest:
                                                URLRequest(url: hitem?.url));
                                      }
                                    }
                                  } else {
                                    if ((await wbm?.webViewController
                                            ?.canGoBack()) ??
                                        false) {
                                      await wbm?.webViewController?.goBack();
                                    } else {
                                      if (wbm != null && wbm.tabIndex != null) {
                                        setState(() {
                                          if (browserModel.isIncognito) {
                                            browserModel.closeIncognitoTab(
                                                wbm.tabIndex!);
                                          } else {
                                            browserModel
                                                .closeTab(wbm.tabIndex!);
                                          }
                                        });
                                        FocusScope.of(context).unfocus();
                                      }
                                    }
                                  }
                                }
                                Navigator.pop(popupMenuContext);
                              })),
                    );
                  }
                  var wbm = browserModel.isIncognito
                      ? browserModel.getCurrentIncognitoTab()?.webViewModel
                      : browserModel.getCurrentTab()?.webViewModel;
                  var canGoForward = ((wbm?.curIndex ?? 0) <
                      ((wbm?.history?.list?.length ?? 0) - 1));
                  children.addAll([
                    Container(
                        width: 35.0,
                        child: IconButton(
                            padding: const EdgeInsets.all(0.0),
                            icon: Icon(
                              Icons.arrow_forward,
                              color: canGoForward
                                  ? Theme.of(context).colorScheme.onSurface
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.4),
                            ),
                            onPressed: () {
                              // _webViewController?.goForward();
                              if (!canGoForward) return null;

                              wbm?.curIndex += 1;
                              var hitem = (browserModel.isIncognito
                                      ? browserModel.getCurrentIncognitoTab()
                                      : browserModel.getCurrentTab())
                                  ?.webViewModel
                                  .history
                                  ?.list!
                                  .elementAt(wbm?.curIndex ?? 0);
                              (browserModel.isIncognito
                                      ? browserModel.getCurrentIncognitoTab()
                                      : browserModel.getCurrentTab())
                                  ?.webViewModel
                                  .webViewController!
                                  .loadUrl(
                                      urlRequest: URLRequest(url: hitem?.url));
                              Navigator.pop(popupMenuContext);
                            })),
                    Fav(
                      key: favKey,
                    ),
                    Container(
                        width: 35.0,
                        child: IconButton(
                            padding: const EdgeInsets.all(0.0),
                            icon: Icon(
                              Icons.file_download,
                              // color: Colors.black,
                            ),
                            onPressed: () async {
                              Navigator.pop(popupMenuContext);
                              if (webViewModel.url != null &&
                                  webViewModel.url!.scheme.startsWith("http")) {
                                var url = webViewModel.url;
                                if (url == null) {
                                  return;
                                }
                                // Directory p =
                                //     Directory("storage/emulated/0/Download");
                                // print("PP :: $p");
                                // String? path = await FileUtil.getFolder(
                                //     context: context, rootPath: p);
                                Directory? path =
                                    await getExternalStorageDirectory();
                                print("Path :: $path");
// path.toString() +
//                                     "/" +
//                                     url.scheme +
//                                     "-" +
//                                     url.host +
//                                     url.path.replaceAll("/", "-") +
//                                     DateTime.now()
//                                         .microsecondsSinceEpoch
//                                         .toString() +
//                                     "." +
                                String gg = await webViewModel.webViewController
                                        ?.getTitle() ??
                                    "offline";
                                String fileName = gg +
                                    DateTime.now()
                                        .microsecondsSinceEpoch
                                        .toString() +
                                    "." +
                                    (Platform.isAndroid
                                        ? WebArchiveFormat.MHT.toValue()
                                        : WebArchiveFormat.WEBARCHIVE
                                            .toValue());
                                String webArchivePath =
                                    (path?.path ?? "") + "/" + fileName;

                                print("webArchivePath :: $webArchivePath");
                                String? savedPath =
                                    (await _webViewController?.saveWebArchive(
                                        filePath: webArchivePath,
                                        autoname: false));

                                // var webArchiveModel = WebArchiveModel(
                                //     url: url,
                                //     path: savedPath,
                                //     title: webViewModel.title,
                                //     favicon: webViewModel.url.toString(),
                                //     timestamp: DateTime.now());

                                var task = TaskInfo(
                                    link: webViewModel.url.toString(),
                                    name: fileName,
                                    fileName: fileName,
                                    status: DownloadTaskStatus.complete,
                                    webArchivePath: savedPath ?? webArchivePath,
                                    isWebArchive: true,
                                    progress: 100,
                                    notFromDownload: false,
                                    taskId: "",
                                    savedDir: (path?.path ?? ""));

                                if (savedPath != null) {
                                  File f = File(savedPath);
                                  int fs = await f.length();
                                  task.fileSize = fs.toString();
                                  browserModel.addDownloadTask = task;
                                  Helper.showBasicFlash(
                                      msg: "Saved Successfully.",
                                      context: this.context,
                                      backgroundColor: Colors.green,
                                      textColor: Colors.white,
                                      position: FlashPosition.top,
                                      duration: Duration(seconds: 3));
                                  browserModel.save();
                                } else {
                                  Helper.showBasicFlash(
                                      msg: "Not able to save webpage offline.",
                                      context: this.context,
                                      backgroundColor: Colors.red,
                                      textColor: Colors.white,
                                      position: FlashPosition.top,
                                      duration: Duration(seconds: 3));
                                }
                              }
                            })),
                    Container(
                        width: 35.0,
                        child: IconButton(
                            padding: const EdgeInsets.all(0.0),
                            icon: Icon(
                              Icons.info_outline,
                              // color: Colors.black,
                            ),
                            onPressed: () async {
                              Navigator.pop(popupMenuContext);

                              await route?.completed;
                              showUrlInfo();
                            })),
                    Container(
                        width: 35.0,
                        child: IconButton(
                            padding: const EdgeInsets.all(0.0),
                            icon: FaIcon(
                              FontAwesomeIcons.mobile,
                              // color: Colors.black,
                            ),
                            onPressed: () async {
                              Navigator.pop(popupMenuContext);

                              await route?.completed;

                              takeScreenshotAndShow();
                            })),
                  ]);

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    mainAxisSize: MainAxisSize.max,
                    children: children,
                  );
                },
              ),
            )
          ];

          items.addAll(PopupMenuActions.choices.map((choice) {
            switch (choice) {
              case PopupMenuActions.NEW_TAB:
                return CustomPopupMenuItem<String>(
                  enabled: true,
                  value: choice,
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          choice,
                          style: Theme.of(context).textTheme.bodyText1,
                        ),
                        Icon(
                          Icons.add,
                          // color: Colors.black,
                        )
                      ]),
                );
              case PopupMenuActions.NEW_INCOGNITO_TAB:
                return CustomPopupMenuItem<String>(
                  enabled: true,
                  value: choice,
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          choice,
                          style: Theme.of(context).textTheme.bodyText1,
                        ),
                        Icon(
                          FontAwesomeIcons.userSecret,
                          // color: Colors.black,
                        )
                      ]),
                );
              case PopupMenuActions.FAVORITES:
                return CustomPopupMenuItem<String>(
                  enabled: true,
                  value: choice,
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          choice,
                          style: Theme.of(context).textTheme.bodyText1,
                        ),
                        Icon(
                          Icons.star,
                          color: Colors.yellow,
                        )
                      ]),
                );

              case PopupMenuActions.DOWNLOADS:
                return CustomPopupMenuItem<String>(
                  enabled: true,
                  value: choice,
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          choice,
                          style: Theme.of(context).textTheme.bodyText1,
                        ),
                        Icon(
                          Icons.offline_pin,
                          color: Colors.blue,
                        )
                      ]),
                );
              case PopupMenuActions.DESKTOP_MODE:
                return CustomPopupMenuItem<String>(
                  enabled: (browserModel.isIncognito
                          ? browserModel.getCurrentIncognitoTab()
                          : browserModel.getCurrentTab()) !=
                      null,
                  value: choice,
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          choice,
                          style: Theme.of(context).textTheme.bodyText1,
                        ),
                        Selector<WebViewModel, bool>(
                          selector: (context, webViewModel) =>
                              webViewModel.isDesktopMode,
                          builder: (context, value, child) {
                            return Icon(
                              value
                                  ? Icons.check_box
                                  : Icons.check_box_outline_blank,
                              // color: Colors.black,
                            );
                          },
                        )
                      ]),
                );
              case PopupMenuActions.HISTORY:
                return CustomPopupMenuItem<String>(
                  value: choice,
                  enabled: true,
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          choice,
                          style: Theme.of(context).textTheme.bodyText1,
                        ),
                        Icon(
                          Icons.history,
                          // color: Colors.black,
                        )
                      ]),
                );
              case PopupMenuActions.SHARE:
                return CustomPopupMenuItem<String>(
                  enabled: (browserModel.isIncognito
                          ? browserModel.getCurrentIncognitoTab()
                          : browserModel.getCurrentTab()) !=
                      null,
                  value: choice,
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          choice,
                          style: Theme.of(context).textTheme.bodyText1,
                        ),
                        FaIcon(
                          FontAwesomeIcons.whatsapp,
                          color: Colors.green,
                        )
                      ]),
                );
              case PopupMenuActions.SETTINGS:
                return CustomPopupMenuItem<String>(
                  enabled: true,
                  value: choice,
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          choice,
                          style: Theme.of(context).textTheme.bodyText1,
                        ),
                        Icon(
                          Icons.settings,
                          // color: Colors.grey,
                        )
                      ]),
                );
              case PopupMenuActions.DEVELOPERS:
                return CustomPopupMenuItem<String>(
                  enabled: (browserModel.isIncognito
                          ? browserModel.getCurrentIncognitoTab()
                          : browserModel.getCurrentTab()) !=
                      null,
                  value: choice,
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          choice,
                          style: Theme.of(context).textTheme.bodyText1,
                        ),
                        Icon(
                          Icons.developer_mode,
                          // color: Colors.black,
                        )
                      ]),
                );
              case PopupMenuActions.FIND_ON_PAGE:
                return CustomPopupMenuItem<String>(
                  enabled: (browserModel.isIncognito
                          ? browserModel.getCurrentIncognitoTab()
                          : browserModel.getCurrentTab()) !=
                      null,
                  value: choice,
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          choice,
                          style: Theme.of(context).textTheme.bodyText1,
                        ),
                        Icon(
                          Icons.search,
                          // color: Colors.black,
                        )
                      ]),
                );
              default:
                return CustomPopupMenuItem<String>(
                  value: choice,
                  child: Text(
                    choice,
                    style: Theme.of(context).textTheme.bodyText1,
                  ),
                );
            }
          }).toList());

          return items;
        },
      ),
    ];
  }

  Route _goToPage(var obj) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => obj,
      transitionDuration: const Duration(milliseconds: 400),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        const curve = Curves.ease;

        var tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  void _popupMenuChoiceAction(String choice) async {
    switch (choice) {
      case PopupMenuActions.NEW_TAB:
        Helper.addNewTab(context: context);
        break;
      case PopupMenuActions.NEW_INCOGNITO_TAB:
        Helper.addNewIncognitoTab(context: context);
        break;
      case PopupMenuActions.FAVORITES:
        // showFavorites();
        Navigator.of(context).push(_goToPage(Favorite()));
        break;
      case PopupMenuActions.HISTORY:
        Navigator.of(context).push(_goToPage(History()));
        break;
      case PopupMenuActions.DOWNLOADS:
        // Navigator.push(
        //   context,
        //   MaterialPageRoute(builder: (context) => PageDownload()),
        // );
        Navigator.of(context).push(_goToPage(PageDownload()));
        break;

      case PopupMenuActions.FIND_ON_PAGE:
        if (widget.showFindOnPage != null) {
          var changePage = Provider.of<ChangePage>(context, listen: false);
          changePage.setIsFinding(true, false);
          widget.showFindOnPage!();
        }
        break;
      case PopupMenuActions.SHARE:
        share();
        break;
      case PopupMenuActions.DESKTOP_MODE:
        toggleDesktopMode();
        break;
      case PopupMenuActions.DEVELOPERS:
        Future.delayed(const Duration(milliseconds: 300), () {
          goToDevelopersPage();
        });
        break;
      case PopupMenuActions.SETTINGS:
        Future.delayed(const Duration(milliseconds: 300), () {
          goToSettingsPage();
        });
        break;
    }
  }

  // void showFavorites() {
  //   showDialog(
  //       context: context,
  //       builder: (context) {
  //         var browserModel = Provider.of<BrowserModel>(context, listen: true);

  //         return AlertDialog(
  //             contentPadding: EdgeInsets.all(0.0),
  //             content: Container(
  //                 width: double.maxFinite,
  //                 child: ListView(
  //                   children: browserModel.favorites.map((favorite) {
  //                     var url = favorite.url;
  //                     var faviconUrl = favorite.favicon != null
  //                         ? favorite.favicon!.url
  //                         : Uri.parse((url?.origin ?? "") + "/favicon.ico");

  //                     return ListTile(
  //                       leading: Column(
  //                         mainAxisAlignment: MainAxisAlignment.center,
  //                         children: <Widget>[
  //                           // CachedNetworkImage(
  //                           //   placeholder: (context, url) =>
  //                           //       CircularProgressIndicator(),
  //                           //   imageUrl: faviconUrl,
  //                           //   height: 30,
  //                           // )
  //                           CustomImage(
  //                             url: faviconUrl,
  //                             maxWidth: 30.0,
  //                             height: 30.0,
  //                           )
  //                         ],
  //                       ),
  //                       title: Text(
  //                           favorite.title ?? favorite.url?.toString() ?? "",
  //                           maxLines: 2,
  //                           overflow: TextOverflow.ellipsis),
  //                       subtitle: Text(favorite.url?.toString() ?? "",
  //                           maxLines: 2, overflow: TextOverflow.ellipsis),
  //                       isThreeLine: true,
  //                       onTap: () {
  //                         setState(() {
  //                           Helper.addNewTab(
  //                               url: favorite.url, context: context);
  //                           Navigator.pop(context);
  //                         });
  //                       },
  //                       trailing: Row(
  //                         mainAxisSize: MainAxisSize.min,
  //                         children: <Widget>[
  //                           IconButton(
  //                             icon: Icon(Icons.close, size: 20.0),
  //                             onPressed: () {
  //                               setState(() {
  //                                 browserModel.removeFavorite(favorite);
  //                                 if (browserModel.favorites.length == 0) {
  //                                   Navigator.pop(context);
  //                                 }
  //                               });
  //                             },
  //                           )
  //                         ],
  //                       ),
  //                     );
  //                   }).toList(),
  //                 )));
  //       });
  // }

  // void showHistory() {
  //   showDialog(
  //       context: context,
  //       builder: (context) {
  //         var webViewModel = Provider.of<WebViewModel>(context, listen: true);

  //         return AlertDialog(
  //             contentPadding: EdgeInsets.all(0.0),
  //             content: FutureBuilder(
  //               future:
  //                   webViewModel.webViewController?.getCopyBackForwardList(),
  //               builder: (context, snapshot) {
  //                 if (!snapshot.hasData) {
  //                   return Container();
  //                 }

  //                 WebHistory history = snapshot.data as WebHistory;
  //                 return Container(
  //                     width: double.maxFinite,
  //                     child: ListView(
  //                       children: history.list?.reversed.map((historyItem) {
  //                             var url = historyItem.url;

  //                             return ListTile(
  //                               leading: Column(
  //                                 mainAxisAlignment: MainAxisAlignment.center,
  //                                 children: <Widget>[
  //                                   // CachedNetworkImage(
  //                                   //   placeholder: (context, url) =>
  //                                   //       CircularProgressIndicator(),
  //                                   //   imageUrl: (url?.origin ?? "") + "/favicon.ico",
  //                                   //   height: 30,
  //                                   // )
  //                                   CustomImage(
  //                                       url: Uri.parse((url?.origin ?? "") +
  //                                           "/favicon.ico"),
  //                                       maxWidth: 30.0,
  //                                       height: 30.0)
  //                                 ],
  //                               ),
  //                               title: Text(historyItem.title ?? url.toString(),
  //                                   maxLines: 2,
  //                                   overflow: TextOverflow.ellipsis),
  //                               subtitle: Text(url?.toString() ?? "",
  //                                   maxLines: 2,
  //                                   overflow: TextOverflow.ellipsis),
  //                               isThreeLine: true,
  //                               onTap: () {
  //                                 webViewModel.webViewController
  //                                     ?.goTo(historyItem: historyItem);
  //                                 Navigator.pop(context);
  //                               },
  //                             );
  //                           }).toList() ??
  //                           <Widget>[],
  //                     ));
  //               },
  //             ));
  //       });
  // }

  // void showWebArchives() async {
  //   showDialog(
  //       context: context,
  //       builder: (context) {
  //         var browserModel = Provider.of<BrowserModel>(context, listen: true);
  //         var webArchives = browserModel.webArchives;

  //         var listViewChildren = <Widget>[];
  //         webArchives.forEach((key, webArchive) {
  //           var path = webArchive.path;
  //           // String fileName = path.substring(path.lastIndexOf('/') + 1);

  //           var url = webArchive.url;

  //           listViewChildren.add(ListTile(
  //             leading: Column(
  //               mainAxisAlignment: MainAxisAlignment.center,
  //               children: <Widget>[
  //                 // CachedNetworkImage(
  //                 //   placeholder: (context, url) => CircularProgressIndicator(),
  //                 //   imageUrl: (url?.origin ?? "") + "/favicon.ico",
  //                 //   height: 30,
  //                 // )
  //                 CustomImage(
  //                     url: Uri.parse((url?.origin ?? "") + "/favicon.ico"),
  //                     maxWidth: 30.0,
  //                     height: 30.0)
  //               ],
  //             ),
  //             title: Text(webArchive.title ?? url?.toString() ?? "",
  //                 maxLines: 2, overflow: TextOverflow.ellipsis),
  //             subtitle: Text(url?.toString() ?? "",
  //                 maxLines: 2, overflow: TextOverflow.ellipsis),
  //             trailing: IconButton(
  //               icon: Icon(Icons.delete),
  //               onPressed: () async {
  //                 setState(() {
  //                   browserModel.removeWebArchive(webArchive);
  //                   browserModel.save();
  //                 });
  //               },
  //             ),
  //             isThreeLine: true,
  //             onTap: () {
  //               if (path != null) {
  //                 var browserModel =
  //                     Provider.of<BrowserModel>(context, listen: false);
  //                 browserModel.addTab(
  //                     WebViewTab(
  //                       key: GlobalKey(),
  //                       webViewModel: WebViewModel(
  //                           url: Uri.parse("file://" + path),
  //                           openedByUser: true),
  //                     ),
  //                     true);
  //               }
  //               Navigator.pop(context);
  //             },
  //           ));
  //         });

  //         return AlertDialog(
  //             contentPadding: EdgeInsets.all(0.0),
  //             content: Builder(
  //               builder: (context) {
  //                 return Container(
  //                     width: double.maxFinite,
  //                     child: ListView(
  //                       children: listViewChildren,
  //                     ));
  //               },
  //             ));
  //       });
  // }

  void share() {
    var browserModel = Provider.of<BrowserModel>(context, listen: false);
    var webViewModel = (browserModel.isIncognito
            ? browserModel.getCurrentIncognitoTab()
            : browserModel.getCurrentTab())
        ?.webViewModel;
    var url = webViewModel?.url;
    if (url != null) {
      Share.share(url.toString(), subject: webViewModel?.title);
    }
  }

  void toggleDesktopMode() async {
    var browserModel = Provider.of<BrowserModel>(context, listen: false);
    var webViewModel = (browserModel.isIncognito
            ? browserModel.getCurrentIncognitoTab()
            : browserModel.getCurrentTab())
        ?.webViewModel;
    var _webViewController = webViewModel?.webViewController;

    var currentWebViewModel = Provider.of<WebViewModel>(context, listen: false);

    if (_webViewController != null) {
      print("TOGGLING DESKTOP MODE");
      webViewModel?.isDesktopMode = !webViewModel.isDesktopMode;
      currentWebViewModel.isDesktopMode = webViewModel?.isDesktopMode ?? false;

      await _webViewController.setOptions(
          options: InAppWebViewGroupOptions(
              crossPlatform: InAppWebViewOptions(
                  preferredContentMode: webViewModel?.isDesktopMode ?? false
                      ? UserPreferredContentMode.DESKTOP
                      : UserPreferredContentMode.RECOMMENDED)));
      await _webViewController.reload();
    }
  }

  void showUrlInfo() {
    var webViewModel = Provider.of<WebViewModel>(context, listen: false);
    var url = webViewModel.url;
    if (url == null || url.toString().isEmpty) {
      return;
    }

    route = CustomPopupDialog.show(
      context: context,
      transitionDuration: customPopupDialogTransitionDuration,
      builder: (context) {
        return UrlInfoPopup(
          route: route!,
          transitionDuration: customPopupDialogTransitionDuration,
          onWebViewTabSettingsClicked: () {
            goToSettingsPage();
          },
        );
      },
    );
  }

  void goToDevelopersPage() {
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => DevelopersPage()));
  }

  void goToSettingsPage() {
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => SettingsPage()));
  }

  void takeScreenshotAndShow() async {
    var webViewModel = Provider.of<WebViewModel>(context, listen: false);
    var screenshot = await webViewModel.webViewController?.takeScreenshot();

    if (screenshot != null) {
      var dir = await getApplicationDocumentsDirectory();
      File file = File("${dir.path}/" +
          "screenshot_" +
          DateTime.now().microsecondsSinceEpoch.toString() +
          ".png");
      await file.writeAsBytes(screenshot);

      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: Image.memory(screenshot),
            actions: <Widget>[
              ElevatedButton(
                child: Text("Share"),
                onPressed: () async {
                  await ShareExtend.share(file.path, "image");
                },
              )
            ],
          );
        },
      );

      file.delete();
    }
  }
}

class Fav extends StatefulWidget {
  const Fav({Key? key}) : super(key: key);

  @override
  _FavState createState() => _FavState();
}

class _FavState extends State<Fav> {
  @override
  Widget build(BuildContext context) {
    var browserModel = Provider.of<BrowserModel>(context, listen: true);
    var webViewModel = (browserModel.isIncognito
            ? browserModel.getCurrentIncognitoTab()
            : browserModel.getCurrentTab())
        ?.webViewModel;
    var isFavorite = false;
    var favorite;
    if (webViewModel?.url != null &&
        (webViewModel?.url ?? "").toString().isNotEmpty) {
      favorite = FavoriteModel(
          url: webViewModel?.url,
          title: webViewModel?.title ?? "",
          favicon: webViewModel?.favicon);
      isFavorite = browserModel.containsFavorite(favorite);
    }
    print("Settting");
    return Container(
        width: 35.0,
        child: IconButton(
            padding: const EdgeInsets.all(0.0),
            icon: Icon(
              isFavorite ? Icons.star : Icons.star_border,
            ),
            onPressed: () {
              if (favorite != null) {
                log(browserModel.favorites.toString());
                if (!browserModel.containsFavorite(favorite)) {
                  browserModel.addFavorite(favorite);
                  browserModel.save();
                  print("Added");
                  // favKey.currentState?.setState(() {
                  //   isFavorite = true;
                  //   print("Called");
                  // });
                  this.setState(() {
                    isFavorite = true;
                  });
                } else {
                  print("Removing");
                  browserModel.removeFavorite(favorite);
                  browserModel.save();
                  // favKey.currentState?.setState(() {
                  //   isFavorite = false;
                  // });
                  this.setState(() {
                    print("rrrrrrr");
                    isFavorite = false;
                  });
                }
              }
            }));
  }
}
