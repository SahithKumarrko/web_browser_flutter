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

class _OpenTabsViewerState extends State<OpenTabsViewer> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return _buildWebViewTabsViewer();
  }

  Widget _buildWebViewTabsViewer() {
    var browserModel = Provider.of<BrowserModel>(context, listen: true);

    return Scaffold(
        appBar: TabViewerAppBar(),
        body: TabViewer(
          currentIndex: browserModel.getCurrentTabIndex(),
          children: browserModel.webViewTabs.map((webViewTab) {
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

            var isCurrentTab = browserModel.getCurrentTabIndex() ==
                webViewTab.webViewModel.tabIndex;

            return Container(
              color: isCurrentTab
                  ? Colors.blue
                  : (webViewTab.webViewModel.isIncognitoMode
                      ? Colors.black
                      : Colors.white),
              child: ListTile(
                leading: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    CustomImage(url: faviconUrl, maxWidth: 30.0, height: 30.0)
                  ],
                ),
                title: Text(
                    webViewTab.webViewModel.title ??
                        webViewTab.webViewModel.url?.toString() ??
                        "",
                    maxLines: 1,
                    style: TextStyle(
                      color: webViewTab.webViewModel.isIncognitoMode ||
                              isCurrentTab
                          ? Colors.white
                          : Colors.black,
                    ),
                    overflow: TextOverflow.ellipsis),
                subtitle: Text(webViewTab.webViewModel.url?.toString() ?? "",
                    style: TextStyle(
                      color: webViewTab.webViewModel.isIncognitoMode ||
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
                        color: webViewTab.webViewModel.isIncognitoMode ||
                                isCurrentTab
                            ? Colors.white60
                            : Colors.black54,
                      ),
                      onPressed: () {
                        setState(() {
                          if (webViewTab.webViewModel.tabIndex != null) {
                            if (browserModel.webViewTabs.length == 1) {
                              browserModel.showTabScroller = false;
                            }
                            browserModel
                                .closeTab(webViewTab.webViewModel.tabIndex!);
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
            browserModel.showTab(index);
          },
        ));
  }
}
