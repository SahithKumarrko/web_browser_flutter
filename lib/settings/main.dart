import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:webpage_dev_console/c_popmenuitem.dart';
import 'package:webpage_dev_console/models/browser_model.dart';
import 'package:webpage_dev_console/models/webview_model.dart';
// import 'package:webpage_dev_console/settings/android_settings.dart';
import 'package:webpage_dev_console/settings/cross_platform_settings.dart';
import 'package:webpage_dev_console/settings/ios_settings.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';

class PopupSettingsMenuActions {
  static const String RESET_BROWSER_SETTINGS = "Reset Browser Settings";
  static const String RESET_WEBVIEW_SETTINGS = "Reset WebView Settings";

  static const List<String> choices = <String>[
    RESET_BROWSER_SETTINGS,
    RESET_WEBVIEW_SETTINGS,
  ];
}

class SettingsPage extends StatefulWidget {
  SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            bottom: TabBar(
                onTap: (value) {
                  FocusScope.of(context).unfocus();
                },
                tabs: [
                  Tab(
                    text: "Cross-Platform",
                    icon: Container(
                      width: 25,
                      height: 25,
                      child: CircleAvatar(
                        backgroundImage: AssetImage("assets/icon/icon.png"),
                      ),
                    ),
                  ),
                  Tab(
                    text: "Android",
                    icon: Icon(
                      Icons.android,
                      color: Colors.green,
                    ),
                  ),
                  Tab(
                    text: "iOS",
                    icon: FaIcon(FontAwesomeIcons.apple),
                  ),
                ]),
            title: const Text(
              "Settings",
            ),
            actions: <Widget>[
              PopupMenuButton<String>(
                onSelected: _popupMenuChoiceAction,
                itemBuilder: (context) {
                  var items = [
                    CustomPopupMenuItem<String>(
                      enabled: true,
                      value: PopupSettingsMenuActions.RESET_BROWSER_SETTINGS,
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(PopupSettingsMenuActions
                                .RESET_BROWSER_SETTINGS),
                            FaIcon(FontAwesomeIcons.windowRestore)
                          ]),
                    ),
                    CustomPopupMenuItem<String>(
                      enabled: true,
                      value: PopupSettingsMenuActions.RESET_WEBVIEW_SETTINGS,
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(PopupSettingsMenuActions
                                .RESET_WEBVIEW_SETTINGS),
                            FaIcon(FontAwesomeIcons.recycle)
                          ]),
                    )
                  ];

                  return items;
                },
              )
            ],
          ),
          body: TabBarView(
            physics: NeverScrollableScrollPhysics(),
            children: [
              CrossPlatformSettings(),
              // AndroidSettings(),
              IOSSettings(),
            ],
          ),
        ));
  }

  void _popupMenuChoiceAction(String choice) async {
    switch (choice) {
      case PopupSettingsMenuActions.RESET_BROWSER_SETTINGS:
        var browserModel = Provider.of<BrowserModel>(context, listen: false);
        setState(() {
          browserModel.updateSettings(BrowserSettings());
          browserModel.save();
        });
        break;
      case PopupSettingsMenuActions.RESET_WEBVIEW_SETTINGS:
        var browserModel = Provider.of<BrowserModel>(context, listen: false);
        var settings = browserModel.getSettings();
        var currentWebViewModel =
            Provider.of<WebViewModel>(context, listen: false);
        var _webViewController = currentWebViewModel.webViewController;
        await _webViewController?.setOptions(
            options: InAppWebViewGroupOptions(
                crossPlatform: InAppWebViewOptions(
                    incognito: currentWebViewModel.isIncognitoMode,
                    useOnDownloadStart: true,
                    useOnLoadResource: true),
                android: AndroidInAppWebViewOptions(safeBrowsingEnabled: true),
                ios: IOSInAppWebViewOptions(
                    allowsLinkPreview: false,
                    isFraudulentWebsiteWarningEnabled: true)));
        currentWebViewModel.options = await _webViewController?.getOptions();
        browserModel.save();
        setState(() {});
        break;
    }
  }
}
