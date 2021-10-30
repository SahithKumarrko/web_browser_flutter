import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:webpage_dev_console/app_bar/tab_viewer_app_bar.dart';
import 'package:webpage_dev_console/custom_image.dart';
import 'package:webpage_dev_console/models/browser_model.dart';
import 'package:webpage_dev_console/tab_viewer.dart';

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

    if (browserModel.isIncognito) {
      // _controller.animateToPage(1,
      //     duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
      // _controller.jumpToPage(1);

    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return _buildWebViewTabsViewer();
  }

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
        body: PageView.builder(
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
                        var faviconUrl = webViewTab.webViewModel.favicon != null
                            ? webViewTab.webViewModel.favicon!.url
                            : (url != null &&
                                    ["http", "https"].contains(url.scheme)
                                ? Uri.parse(url.origin + "/favicon.ico")
                                : null);

                        var isCurrentTab = (browserModel.getCurrentTabIndex() ==
                                webViewTab.webViewModel.tabIndex) &&
                            !browserModel.isIncognito;
                        if (webViewTab.webViewModel.isIncognitoMode) {
                          return SizedBox.shrink();
                        }
                        return Container(
                          // margin: EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                              color: isCurrentTab
                                  ? Colors.blue[400]
                                  : (webViewTab.webViewModel.isIncognitoMode
                                      ? Colors.black
                                      : Colors.white),
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
                                webViewTab.webViewModel.title ??
                                    webViewTab.webViewModel.url?.toString() ??
                                    "",
                                maxLines: 1,
                                style: TextStyle(
                                  color:
                                      webViewTab.webViewModel.isIncognitoMode ||
                                              isCurrentTab
                                          ? Colors.white
                                          : Colors.black,
                                ),
                                overflow: TextOverflow.ellipsis),
                            subtitle: Text(
                                webViewTab.webViewModel.url?.toString() ?? "",
                                style: TextStyle(
                                  color:
                                      webViewTab.webViewModel.isIncognitoMode ||
                                              isCurrentTab
                                          ? Colors.white60
                                          : Colors.black54,
                                ),
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
                                    color: webViewTab
                                                .webViewModel.isIncognitoMode ||
                                            isCurrentTab
                                        ? Colors.white60
                                        : Colors.black54,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      if (webViewTab.webViewModel.tabIndex !=
                                          null) {
                                        if (browserModel.webViewTabs.length ==
                                            1) {
                                          browserModel.showTabScroller = false;
                                        }
                                        browserModel.closeTab(
                                            webViewTab.webViewModel.tabIndex!);
                                      }
                                    });
                                  },
                                )
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                onTap: (index) async {
                  browserModel.showTabScroller = false;
                  browserModel.isIncognito = false;

                  browserModel.showTab(index);
                },
              );
            } else if (position == _selectedIndex.floor() + 1) {
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

                  var url = webViewTab.webViewModel.url;
                  var faviconUrl = webViewTab.webViewModel.favicon != null
                      ? webViewTab.webViewModel.favicon!.url
                      : (url != null && ["http", "https"].contains(url.scheme)
                          ? Uri.parse(url.origin + "/favicon.ico")
                          : null);

                  var isCurrentTab = (browserModel.getCurrentIncogTabIndex() ==
                          webViewTab.webViewModel.tabIndex) &&
                      browserModel.isIncognito;

                  return Container(
                    decoration: BoxDecoration(
                        color: (webViewTab.webViewModel.isIncognitoMode &&
                                isCurrentTab
                            ? Colors.black
                            : isCurrentTab
                                ? Colors.blue[400]
                                : Colors.white),
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
                          webViewTab.webViewModel.title ??
                              webViewTab.webViewModel.url?.toString() ??
                              "",
                          maxLines: 1,
                          style: TextStyle(
                            color: isCurrentTab ? Colors.white : Colors.black,
                          ),
                          overflow: TextOverflow.ellipsis),
                      subtitle:
                          Text(webViewTab.webViewModel.url?.toString() ?? "",
                              style: TextStyle(
                                color: isCurrentTab
                                    ? Colors.white60
                                    : Colors.black54,
                              ),
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
                                  : Colors.black54,
                            ),
                            onPressed: () {
                              setState(() {
                                if (webViewTab.webViewModel.tabIndex != null) {
                                  if (browserModel.webViewTabs.length == 1) {
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
                  );
                }).toList(),
                onTap: (index) async {
                  browserModel.showTabScroller = false;
                  browserModel.isIncognito = true;
                  browserModel.showIncognitoTab(index);
                },
              );
            }
            return Container();
          },
          controller: _controller,
          itemCount: 2,
        ));
  }

  @override
  // TODO: implement wantKeepAlive
  bool get wantKeepAlive => true;
}
