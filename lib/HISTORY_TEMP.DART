import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';

import 'package:webpage_dev_console/custom_image.dart';
import 'package:webpage_dev_console/model_search.dart';
import 'package:webpage_dev_console/models/browser_model.dart';
import 'package:webpage_dev_console/models/webview_model.dart';
import 'package:webpage_dev_console/util.dart';

class History2 extends StatefulWidget {
  final void Function({Uri? url}) addNewTab;
  History2({
    Key? key,
    required this.addNewTab,
  }) : super(key: key);

  @override
  _History2State createState() => _History2State();
}

class HItem2 {
  String date;
  Search search;
  HItem2({
    required this.date,
    required this.search,
  });

  @override
  String toString() => 'HItem2(title: $date,url: $search)';
}

class _History2State extends State<History2> {
  List<HItem2> _data = [];
  GlobalKey<AnimatedListState> _listKey = GlobalKey();
  late BrowserModel browserModel;
  late BrowserSettings settings;
  String curDate = "";
  bool isRemoved = false;
  Map<String, int> items = {};
  @override
  void initState() {
    super.initState();
    browserModel = Provider.of<BrowserModel>(context, listen: false);
    var keys = browserModel.history.keys.toList().reversed;
    for (String k in keys) {
      var v = browserModel.history[k];
      var c = 0;
      for (Search s in v ?? []) {
        _data.add(HItem2(date: k, search: s));
        c += 1;
      }
      items[k] = c;
    }
    settings = browserModel.getSettings();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: WillPopScope(
        onWillPop: () async {
          Navigator.pop(context);
          return false;
        },
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          appBar: HistoryAppBar(),
          body: SafeArea(
            child: Column(children: <Widget>[
              _data.length != 0
                  ? Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextButton(
                            child: Text(
                              "Clear Browsing History",
                              style: TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                                fontSize: 16,
                              ),
                            ),
                            onPressed: () {
                              showDialog(
                                  context: context,
                                  builder: (_) {
                                    return AlertDialog(
                                      title: Text('Warning'),
                                      content: Text(
                                          'Do you really want to clear all your history?'),
                                      actions: <Widget>[
                                        TextButton(
                                          onPressed: () {
                                            browserModel.history =
                                                LinkedHashMap();
                                            browserModel.save();
                                            _data.clear();
                                            setState(
                                                () => _listKey = GlobalKey());
                                            

                                            Navigator.pop(context);
                                          },
                                          child: Text('YES'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                          child: Text('NO'),
                                        ),
                                      ],
                                    );
                                  });
                            },
                          ),
                        ),
                      ],
                    )
                  : SizedBox.shrink(),
              Expanded(
                child: AnimatedList(
                  key: _listKey,
                  initialItemCount: _data.length,
                  itemBuilder: (context, index, animation) {
                    HItem2 item = _data.elementAt(index);

                    bool showDate = false;
                    showDate = (curDate != item.date);

                    curDate = showDate ? item.date : curDate;
                    return Column(children: [
                      showDate
                          ? Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 5),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.date,
                                    style: TextStyle(
                                      fontSize: 16,
                                    ),
                                  ),
                                  SizedBox(
                                    height: 8,
                                  ),
                                ],
                              ),
                            )
                          : SizedBox.shrink(),
                      _buildItem(item, index, animation)
                    ]);
                  },
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildItem(HItem2 item, int index, Animation<double> animation) {
    return SizeTransition(
      sizeFactor: animation,
      child: InkWell(
        onTap: () {
          var browserModel = Provider.of<BrowserModel>(context, listen: false);
          var settings = browserModel.getSettings();

          var webViewModel = Provider.of<WebViewModel>(context, listen: false);
          var _webViewController = webViewModel.webViewController;
          var url = Uri.parse(item.search.url.toString());
          if (!url.scheme.startsWith("http") && !Util.isLocalizedContent(url)) {
            url = Uri.parse(settings.searchEngine.searchUrl +
                item.search.url.toString().trim());
          }

          if (_webViewController != null) {
            _webViewController.loadUrl(urlRequest: URLRequest(url: url));
          } else {
            widget.addNewTab(url: url);
            webViewModel.url = url;
          }

          Navigator.pop(context);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blue[100],
                    ),
                    padding: EdgeInsets.all(8),
                    child: CustomImage(
                        url: Uri.parse((item.search.url?.origin ??
                                settings.searchEngine.url) +
                            "/favicon.ico"),
                        maxWidth: 18.0,
                        height: 18.0),
                  )
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.search.title,
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                    item.search.url != null
                        ? Text(
                            (item.search.url?.origin ??
                                    settings.searchEngine.url)
                                .replaceFirst(RegExp("http[s]:[/]{2}"), ""),
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 16),
                          )
                        : SizedBox.shrink(),
                  ],
                ),
              ),
              SizedBox(
                width: 28,
                child: Transform.rotate(
                  angle: 0.785398,
                  child: IconButton(
                    onPressed: () {
                      AnimatedListRemovedItemBuilder builder =
                          (context, animation) {
                        // A method to build the Card widget.
                        var browserModel =
                            Provider.of<BrowserModel>(context, listen: false);
                        HItem2 ritem = _data.removeAt(index);

                        browserModel.history[ritem.date] = _data
                            .where((element) => (element.date == ritem.date &&
                                element.search.title != ritem.search.title &&
                                element.search.url != ritem.search.url))
                            .toList()
                            .map((e) => e.search)
                            .toList();
                        browserModel.save();
                        curDate = "";
                        return _buildItem(ritem, index, animation);
                      };

                      _listKey.currentState?.removeItem(index, builder);
                    },
                    icon: Icon(
                      Icons.control_point_sharp,
                      color: Colors.black.withOpacity(0.7),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HistoryAppBar extends StatefulWidget implements PreferredSizeWidget {
  HistoryAppBar({Key? key}) : super(key: key);

  @override
  _HistoryAppBarState createState() => _HistoryAppBarState();

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}

class _HistoryAppBarState extends State<HistoryAppBar> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: 16, left: 16, bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "History",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                  onPressed: () {},
                  icon: Icon(
                    Icons.search,
                    size: 26,
                  )),
              IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: Icon(
                    Icons.close,
                    size: 26,
                  )),
            ],
          ),
        ],
      ),
    );
  }
}
