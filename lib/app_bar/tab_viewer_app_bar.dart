import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:webpage_dev_console/c_popmenuitem.dart';
import 'package:webpage_dev_console/helpers.dart';
import 'package:webpage_dev_console/models/browser_model.dart';
import 'package:webpage_dev_console/models/webview_model.dart';
import 'package:webpage_dev_console/settings/main.dart';
import 'package:webpage_dev_console/webview_tab.dart';
import 'package:provider/provider.dart';
import 'package:badges/badges.dart';
import '../tab_viewer_popup_menu_actions.dart';

class TabViewerAppBar extends StatefulWidget implements PreferredSizeWidget {
  final PageController controller;
  final Function move;
  TabViewerAppBar({Key? key, required this.controller, required this.move})
      : preferredSize = Size.fromHeight(kToolbarHeight),
        super(key: key);

  @override
  _TabViewerAppBarState createState() => _TabViewerAppBarState();

  @override
  final Size preferredSize;
}

class _TabViewerAppBarState extends State<TabViewerAppBar> {
  GlobalKey tabInkWellKey = new GlobalKey();
  GlobalKey tabInkWellKey2 = new GlobalKey();

  @override
  Widget build(BuildContext context) {
    var browserModel = Provider.of<BrowserModel>(context, listen: true);
    var settings = browserModel.getSettings();
    var inl = browserModel.incognitowebViewTabs.length;
    return AppBar(
      backgroundColor: Theme.of(context).backgroundColor,
      centerTitle: true,
      title: inl != 0
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                InkWell(
                  splashFactory: NoSplash.splashFactory,
                  highlightColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                  splashColor: Colors.transparent,
                  onTap: () {
                    widget.controller.animateToPage(0,
                        duration: Duration(milliseconds: 200),
                        curve: Curves.easeInOut);
                    print("Tapped :: 0");
                  },
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                            border: Border.all(
                                width: 2.0,
                                color: Theme.of(context).colorScheme.onSurface),
                            shape: BoxShape.rectangle,
                            borderRadius: BorderRadius.circular(5.0)),
                        constraints:
                            BoxConstraints(minWidth: 25.0, maxHeight: 28),
                        child: Container(
                            child: Center(
                                child: Text(
                          browserModel.webViewTabs.length.toString(),
                          style: Theme.of(context)
                              .textTheme
                              .bodyText1
                              ?.copyWith(
                                  fontWeight: FontWeight.bold, fontSize: 14.0),
                        ))),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 16,
                ),
                SizedBox(
                  width: 2,
                  height: 25,
                  child: Container(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                SizedBox(
                  width: 16,
                ),
                InkWell(
                  splashColor: Colors.transparent,
                  splashFactory: NoSplash.splashFactory,
                  highlightColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                  onTap: () {
                    widget.controller.animateToPage(1,
                        duration: Duration(milliseconds: 200),
                        curve: Curves.easeInOut);
                    print("Tapped :: 1");
                  },
                  child: Badge(
                    badgeColor: Colors.deepPurple,
                    shape: BadgeShape.circle,
                    toAnimate: true,
                    badgeContent: Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: Text(
                          browserModel.incognitowebViewTabs.length.toString(),
                          style: TextStyle(
                            // color: Colors.white,
                            fontSize: 12,
                          )),
                    ),
                    position: BadgePosition.topEnd(
                      end: browserModel.incognitowebViewTabs.length < 10
                          ? -20
                          : browserModel.incognitowebViewTabs.length < 100
                              ? -26
                              : -30,
                    ),
                    child: FaIcon(
                      FontAwesomeIcons.userSecret,
                      // color: Colors.black,
                    ),
                  ),
                ),
              ],
            )
          : SizedBox.shrink(),
      leading: _buildAddTabButton(),
      actions: _buildActionsMenu(),
    );
  }

  Widget _buildAddTabButton() {
    var browserModel = Provider.of<BrowserModel>(context, listen: false);
    return IconButton(
      icon: Icon(
        Icons.add,
        // color: Colors.black,
      ),
      onPressed: () {
        Helper.addNewTab(context: context);
        browserModel.showTabScroller = false;
      },
    );
  }

  List<Widget> _buildActionsMenu() {
    var browserModel = Provider.of<BrowserModel>(context, listen: true);

    List<Widget> widgets = [];
    if (browserModel.incognitowebViewTabs.length == 0) {
      widgets.add(InkWell(
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        splashColor: Colors.transparent,
        onTap: () {
          widget.controller.animateToPage(0,
              duration: Duration(milliseconds: 200), curve: Curves.easeInOut);
        },
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                  border: Border.all(
                      width: 2.0,
                      color: Theme.of(context).colorScheme.onSurface),
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(5.0)),
              constraints: BoxConstraints(minWidth: 25.0, maxHeight: 28),
              child: Container(
                  child: Center(
                      child: Text(
                browserModel.webViewTabs.length.toString(),
                style: Theme.of(context)
                    .textTheme
                    .bodyText1
                    ?.copyWith(fontWeight: FontWeight.bold, fontSize: 14.0),
              ))),
            ),
          ],
        ),
      ));
      widgets.add(SizedBox(
        width: 5,
      ));
    }
    widgets.add(PopupMenuButton<String>(
      onSelected: _popupMenuChoiceAction,
      icon: Icon(Icons.more_vert_rounded),
      iconSize: 24,
      itemBuilder: (popupMenuContext) {
        var items = <PopupMenuEntry<String>>[];

        items.addAll(TabViewerPopupMenuActions.choices.map((choice) {
          switch (choice) {
            case TabViewerPopupMenuActions.NEW_TAB:
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
            case TabViewerPopupMenuActions.NEW_INCOGNITO_TAB:
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
                      FaIcon(
                        FontAwesomeIcons.userSecret,
                        // color: Colors.black,
                      )
                    ]),
              );
            case TabViewerPopupMenuActions.CLOSE_ALL_TABS:
              return CustomPopupMenuItem<String>(
                enabled: browserModel.webViewTabs.length > 0,
                value: choice,
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        !browserModel.isIncognito
                            ? choice
                            : "Close All Incognito Tabs",
                        style: Theme.of(context).textTheme.bodyText1,
                      ),
                      Icon(
                        Icons.close,
                        // color: Colors.black,
                      )
                    ]),
              );
            case TabViewerPopupMenuActions.SETTINGS:
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
            default:
              return CustomPopupMenuItem<String>(
                value: choice,
                child: Text(choice),
              );
          }
        }).toList());

        return items;
      },
    ));
    return widgets;
  }

  void _popupMenuChoiceAction(String choice) async {
    var browserModel = Provider.of<BrowserModel>(context, listen: false);
    switch (choice) {
      case TabViewerPopupMenuActions.NEW_TAB:
        Future.delayed(const Duration(milliseconds: 200), () {
          Helper.addNewTab(context: context);
          browserModel.showTabScroller = false;
        });
        break;
      case TabViewerPopupMenuActions.NEW_INCOGNITO_TAB:
        Future.delayed(const Duration(milliseconds: 200), () {
          Helper.addNewIncognitoTab(context: context);
          browserModel.showTabScroller = false;
        });
        break;
      case TabViewerPopupMenuActions.CLOSE_ALL_TABS:
        Future.delayed(const Duration(milliseconds: 300), () {
          if (browserModel.isIncognito) {
            browserModel.showTabScroller = false;
            browserModel.isIncognito = false;
            browserModel.closeAllIncognitoTabs();
          } else {
            closeAllTabs();
          }
        });
        break;
      case TabViewerPopupMenuActions.SETTINGS:
        Future.delayed(const Duration(milliseconds: 300), () {
          goToSettingsPage();
        });
        break;
    }
  }

  void addNewTab({Uri? url}) {
    var browserModel = Provider.of<BrowserModel>(context, listen: false);
    var settings = browserModel.getSettings();

    if (url == null) {
      url = settings.homePageEnabled && settings.customUrlHomePage.isNotEmpty
          ? Uri.parse(settings.customUrlHomePage)
          : Uri.parse(settings.searchEngine.url);
    }

    browserModel.showTabScroller = false;

    browserModel.addTab(
        WebViewTab(
          key: GlobalKey(),
          webViewModel: WebViewModel(url: url, openedByUser: true),
        ),
        true);
  }

  void addNewIncognitoTab({Uri? url}) {
    var browserModel = Provider.of<BrowserModel>(context, listen: false);
    var settings = browserModel.getSettings();

    if (url == null) {
      url = settings.homePageEnabled && settings.customUrlHomePage.isNotEmpty
          ? Uri.parse(settings.customUrlHomePage)
          : Uri.parse(settings.searchEngine.url);
    }

    browserModel.showTabScroller = false;

    browserModel.addTab(
        WebViewTab(
          key: GlobalKey(),
          webViewModel:
              WebViewModel(url: url, isIncognitoMode: true, openedByUser: true),
        ),
        true);
  }

  void closeAllTabs() {
    var browserModel = Provider.of<BrowserModel>(context, listen: false);

    browserModel.showTabScroller = false;

    browserModel.closeAllTabs();
  }

  void goToSettingsPage() {
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => SettingsPage()));
  }
}
