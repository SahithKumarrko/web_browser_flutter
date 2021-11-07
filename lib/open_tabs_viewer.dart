import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:webpage_dev_console/app_bar/tab_viewer_app_bar.dart';
import 'package:webpage_dev_console/custom_image.dart';
import 'package:webpage_dev_console/helpers.dart';
import 'package:webpage_dev_console/models/browser_model.dart';
import 'package:webpage_dev_console/models/webview_model.dart';
import 'package:webpage_dev_console/tab_viewer.dart';
import 'package:webpage_dev_console/webview_tab.dart';

class OpenTabsViewer extends StatefulWidget {
  const OpenTabsViewer({Key? key}) : super(key: key);

  @override
  _OpenTabsViewerState createState() => _OpenTabsViewerState();
}

class _OpenTabsViewerState extends State<OpenTabsViewer>
    with
        AutomaticKeepAliveClientMixin<OpenTabsViewer>,
        SingleTickerProviderStateMixin {
  late PageController _controller;
  var _selectedIndex = 0.0;
  @override
  void initState() {
    super.initState();
    var browserModel = Provider.of<BrowserModel>(context, listen: false);

    _controller = PageController(initialPage: browserModel.isIncognito ? 1 : 0);
    _controller.addListener(() {
      print("CPPP :: ${_controller.page}");
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool shown = false;
  @override
  Widget build(BuildContext context) {
    super.build(context);
    // var browserModel = Provider.of<BrowserModel>(context, listen: false);
    // if (browserModel.isIncognito && !shown) {
    //   shown = true;
    //   Helper.showBasicFlash(
    //     msg: "You are in incognito mode.",
    //     context: context,
    //     backgroundColor: Theme.of(context).colorScheme.background,
    //     textColor: Theme.of(context).colorScheme.onSurface,
    //   );
    // }
    return _buildWebViewTabsViewer();
  }

  String getRandString(int len) {
    var random = Random.secure();
    var values = List<int>.generate(len, (i) => random.nextInt(32));
    return base64UrlEncode(values);
  }

  int getRandomLen() {
    var random = Random.secure();
    return random.nextInt(1000);
  }

  List<String> keysL = [];

  Widget _buildWebViewTabsViewer() {
    var browserModel = Provider.of<BrowserModel>(context, listen: true);

    return Scaffold(
        appBar: TabViewerAppBar(
            controller: _controller,
            move: () {
              setState(() {
                _selectedIndex = _controller.page ?? 0;
              });
            }),
        body: buildPages(browserModel));
  }

  Widget buildPages(BrowserModel browserModel) {
    return Column(
      children: [
        browserModel.isIncognito
            ? Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: Theme.of(context)
                        .scaffoldBackgroundColor
                        .withOpacity(0.5),
                    borderRadius: BorderRadius.circular(15)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        "You are in incognito mode.",
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headline3?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.7)),
                      ),
                    )
                  ],
                ))
            : SizedBox.shrink(),
        Expanded(
          child: PageView.builder(
            pageSnapping: false,
            allowImplicitScrolling: false,
            physics: NeverScrollableScrollPhysics(),
            itemBuilder: (ctx, position) {
              print(position);
              if (position == _selectedIndex.floor()) {
                return TabViewer(
                  currentIndex: browserModel.getCurrentTabIndex(),
                  children: browserModel.webViewTabs.length == 0
                      ? [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Center(
                                      child: Container(
                                        padding: EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                            color: Colors.blueGrey[50],
                                            border: Border.all(
                                              color: const Color(0xFF575859),
                                            ),
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(10))),
                                        child: Text(
                                          "No Tabs Opened",
                                          style: TextStyle(
                                              color: Colors.black87,
                                              fontSize: 24),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            ],
                          )
                        ]
                      : browserModel.webViewTabs.map((webViewTab) {
                          webViewTab.key.currentState?.pause();
                          // var screenshotData = webViewTab.webViewModel.screenshot;
                          // Widget screenshotImage = Container(
                          //   decoration: BoxDecoration(color: Colors.white),
                          //   width: double.infinity,
                          //   child: screenshotData != null
                          //       ? Image.memory(screenshotData)
                          //       : null,
                          // );

                          var url = webViewTab.webViewModel.url;
                          var faviconUrl =
                              webViewTab.webViewModel.favicon != null
                                  ? webViewTab.webViewModel.favicon!.url
                                  : (url != null &&
                                          ["http", "https"].contains(url.scheme)
                                      ? Uri.parse(url.origin + "/favicon.ico")
                                      : null);

                          var isCurrentTab =
                              (browserModel.getCurrentTabIndex() ==
                                      webViewTab.webViewModel.tabIndex) &&
                                  !browserModel.isIncognito;
                          if (webViewTab.webViewModel.isIncognitoMode) {
                            return SizedBox.shrink();
                          }
                          var k = getRandString(getRandomLen());
                          while (keysL.contains(k)) {
                            k = getRandString(getRandomLen());
                          }
                          var hitem = webViewTab.webViewModel.history?.list!
                              .elementAt(webViewTab.webViewModel.curIndex);
                          dev.log(
                              "HITEMSSS ::: ${webViewTab.webViewModel.history?.list}");
                          dev.log(
                              "HITEMC :: ${webViewTab.webViewModel.curIndex}");
                          dev.log("HITEM ::: $hitem");
                          return Dismissible(
                            key: Key(k),
                            onDismissed: (d) {
                              setState(() {
                                if (webViewTab.webViewModel.tabIndex != null) {
                                  if (browserModel.webViewTabs.length == 1) {
                                    browserModel.showTabScroller = false;
                                  }
                                  browserModel.closeTab(
                                      webViewTab.webViewModel.tabIndex!);
                                  print("Closed tab");
                                }
                              });
                            },
                            child: Container(
                              // margin: EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                  color: isCurrentTab
                                      ? Colors.blue[400]
                                      : Theme.of(context)
                                          .scaffoldBackgroundColor,
                                  borderRadius: BorderRadius.circular(15)),
                              child: ListTile(
                                leading: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    CustomImage(
                                        url: faviconUrl,
                                        maxWidth: 30.0,
                                        height: 30.0)
                                  ],
                                ),
                                title: Text(
                                    hitem?.title.toString().length == 0
                                        ? webViewTab.webViewModel.title ??
                                            webViewTab.webViewModel.url
                                                ?.toString() ??
                                            ""
                                        : hitem?.title ??
                                            webViewTab.webViewModel.title ??
                                            webViewTab.webViewModel.url
                                                ?.toString() ??
                                            "",
                                    maxLines: 1,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headline3
                                        ?.copyWith(
                                            color: isCurrentTab
                                                ? Colors.white
                                                : Theme.of(context)
                                                    .colorScheme
                                                    .onSurface),
                                    overflow: TextOverflow.ellipsis),
                                subtitle: Text(
                                    webViewTab.webViewModel.url?.toString() ??
                                        "",
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyText2
                                        ?.copyWith(
                                            color: isCurrentTab
                                                ? Colors.white60
                                                : Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withOpacity(0.54)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                isThreeLine: false,
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    IconButton(
                                      icon: FaIcon(
                                        FontAwesomeIcons.timesCircle,
                                        size: 24.0,
                                        color: isCurrentTab
                                            ? Colors.white60
                                            : Theme.of(context)
                                                .colorScheme
                                                .onBackground
                                                .withOpacity(0.54),
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          if (webViewTab
                                                  .webViewModel.tabIndex !=
                                              null) {
                                            if (browserModel
                                                    .webViewTabs.length ==
                                                1) {
                                              browserModel.showTabScroller =
                                                  false;
                                            }
                                            browserModel.closeTab(webViewTab
                                                .webViewModel.tabIndex!);
                                          }
                                        });
                                      },
                                    )
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                  onTap: (index) async {
                    browserModel.showTabScroller = false;
                    browserModel.setIsIncognito(false, context);

                    browserModel.showTab(index);
                  },
                );
              } else if (position == _selectedIndex.floor() + 1) {
                // var ind = 0;
                return TabViewer(
                  currentIndex: browserModel.getCurrentIncogTabIndex(),
                  children: browserModel.incognitowebViewTabs.map((webViewTab) {
                    webViewTab.key.currentState?.pause();
                    // var screenshotData = webViewTab.webViewModel.screenshot;
                    // Widget screenshotImage = Container(
                    //   decoration: BoxDecoration(color: Colors.white),
                    //   width: double.infinity,
                    //   child: screenshotData != null
                    //       ? Image.memory(screenshotData)
                    //       : null,
                    // );
                    // if (ind == 0) {
                    //   ind += 1;
                    //   print("Returning row");
                    //   return Row(
                    //     mainAxisAlignment: MainAxisAlignment.center,
                    //     crossAxisAlignment: CrossAxisAlignment.center,
                    //     mainAxisSize: MainAxisSize.min,
                    //     children: [
                    //       Container(
                    //           padding: EdgeInsets.all(8),
                    //           decoration: BoxDecoration(
                    //               color: Theme.of(context)
                    //                   .scaffoldBackgroundColor
                    //                   .withOpacity(0.5),
                    //               borderRadius: BorderRadius.circular(15)),
                    //           child: Row(
                    //             children: [
                    //               Expanded(
                    //                 child: Text(
                    //                   "Incognito Tabs",
                    //                   style: Theme.of(context)
                    //                       .textTheme
                    //                       .headline3
                    //                       ?.copyWith(
                    //                           color: Theme.of(context)
                    //                               .colorScheme
                    //                               .onSurface
                    //                               .withOpacity(0.7)),
                    //                 ),
                    //               )
                    //             ],
                    //           )),
                    //     ],
                    //   );
                    // }

                    // ind += 1;

                    var url = webViewTab.webViewModel.url;
                    var faviconUrl = webViewTab.webViewModel.favicon != null
                        ? webViewTab.webViewModel.favicon!.url
                        : (url != null && ["http", "https"].contains(url.scheme)
                            ? Uri.parse(url.origin + "/favicon.ico")
                            : null);

                    var isCurrentTab =
                        (browserModel.getCurrentIncogTabIndex() ==
                                webViewTab.webViewModel.tabIndex) &&
                            browserModel.isIncognito;

                    var k = getRandString(getRandomLen());
                    while (keysL.contains(k)) {
                      k = getRandString(getRandomLen());
                    }
                    var hitem = webViewTab.webViewModel.history?.list!
                        .elementAt(webViewTab.webViewModel.curIndex);
                    dev.log(
                        "HITEMSSS ::: ${webViewTab.webViewModel.history?.list}");
                    dev.log("HITEMC :: ${webViewTab.webViewModel.curIndex}");
                    dev.log("HITEM ::: $hitem");

                    return Dismissible(
                      key: Key(k),
                      onDismissed: (d) {
                        setState(() {
                          if (webViewTab.webViewModel.tabIndex != null) {
                            if (browserModel.incognitowebViewTabs.length == 1) {
                              browserModel.showTabScroller = false;
                            }
                            browserModel.closeIncognitoTab(
                                webViewTab.webViewModel.tabIndex!);
                          }
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                            color: webViewTab.webViewModel.isIncognitoMode &&
                                    isCurrentTab
                                ? Colors.black
                                : Theme.of(context).scaffoldBackgroundColor,
                            borderRadius: BorderRadius.circular(15)),
                        child: ListTile(
                          leading: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              CustomImage(
                                  url: faviconUrl, maxWidth: 30.0, height: 30.0)
                            ],
                          ),
                          title: Text(
                              hitem?.title.toString().length == 0
                                  ? webViewTab.webViewModel.title ??
                                      webViewTab.webViewModel.url?.toString() ??
                                      ""
                                  : hitem?.title ??
                                      webViewTab.webViewModel.title ??
                                      webViewTab.webViewModel.url?.toString() ??
                                      "",
                              maxLines: 1,
                              style: Theme.of(context)
                                  .textTheme
                                  .headline3
                                  ?.copyWith(
                                      color: isCurrentTab
                                          ? Colors.white
                                          : Theme.of(context)
                                              .colorScheme
                                              .onSurface),
                              overflow: TextOverflow.ellipsis),
                          subtitle: Text(
                              webViewTab.webViewModel.url?.toString() ?? "",
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyText2
                                  ?.copyWith(
                                      color: isCurrentTab
                                          ? Colors.white60
                                          : Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(0.54)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          isThreeLine: false,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              IconButton(
                                icon: FaIcon(
                                  FontAwesomeIcons.timesCircle,
                                  size: 24.0,
                                  color: isCurrentTab
                                      ? Colors.white60
                                      : Theme.of(context)
                                          .colorScheme
                                          .onBackground
                                          .withOpacity(0.54),
                                ),
                                onPressed: () {
                                  setState(() {
                                    if (webViewTab.webViewModel.tabIndex !=
                                        null) {
                                      if (browserModel
                                              .incognitowebViewTabs.length ==
                                          1) {
                                        browserModel.showTabScroller = false;
                                      }
                                      browserModel.closeIncognitoTab(
                                          webViewTab.webViewModel.tabIndex!);
                                    }
                                  });
                                },
                              )
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                  onTap: (index) async {
                    browserModel.showTabScroller = false;
                    browserModel.setIsIncognito(true, context);
                    browserModel.showIncognitoTab(index);
                  },
                );
              }
              return Container();
            },
            controller: _controller,
            itemCount: 2,
          ),
        ),
      ],
    );
  }

  @override
  bool get wantKeepAlive => true;
}
