import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webpage_dev_console/app_bar/find_on_page_app_bar.dart';
import 'package:webpage_dev_console/app_bar/webview_tab_app_bar.dart';
import 'package:webpage_dev_console/models/findResults.dart';

class BrowserAppBar extends StatefulWidget implements PreferredSizeWidget {
  BrowserAppBar({Key? key})
      : preferredSize = Size.fromHeight(kToolbarHeight),
        super(key: key);

  @override
  _BrowserAppBarState createState() => _BrowserAppBarState();

  @override
  final Size preferredSize;
}

class _BrowserAppBarState extends State<BrowserAppBar> {
  bool _isFindingOnPage = false;

  @override
  Widget build(BuildContext context) {
    var changePage = Provider.of<ChangePage>(context, listen: true);
    return _isFindingOnPage && changePage.isFinding
        ? FindOnPageAppBar(
            hideFindOnPage: () {
              setState(() {
                _isFindingOnPage = false;
              });
            },
          )
        : WebViewTabAppBar(
            showFindOnPage: () {
              setState(() {
                _isFindingOnPage = true;
              });
            },
          );
  }
}
