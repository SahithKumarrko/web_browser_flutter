import 'dart:collection';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:webpage_dev_console/custom_image.dart';
import 'package:webpage_dev_console/model_search.dart';
import 'package:webpage_dev_console/models/browser_model.dart';
import 'package:webpage_dev_console/models/webview_model.dart';
import 'package:webpage_dev_console/util.dart';

bool showSearchField = false;
bool showClearAll = true;
GlobalKey clearAllSwitcher = GlobalKey();
List<HItem> _data = [];
GlobalKey<AnimatedListState> _listKey = GlobalKey();

class History extends StatefulWidget {
  final void Function({Uri? url}) addNewTab;
  History({
    Key? key,
    required this.addNewTab,
  }) : super(key: key);

  @override
  _HistoryState createState() => _HistoryState();
}

class HItem {
  String date;
  Search? search;
  bool isDeleted;
  HItem({required this.date, required this.search, this.isDeleted = false});

  @override
  String toString() => 'HItem(title: $date,url: $search)';
}

class _HistoryState extends State<History> {
  late BrowserModel browserModel;
  late BrowserSettings settings;
  String curDate = "";
  bool isRemoved = false;
  Map<String, List<int>> items = {};
  late HItem ritem;
  GlobalKey appBarKey = GlobalKey();

  Future initialize(BuildContext context) async {
    // This is where you can initialize the resources needed by your app while
    // the splash screen is displayed.  Remove the following example because
    // delaying the user experience is a bad design practice!
    await Future.delayed(const Duration(seconds: 1), () async {
      generateHistoryValues("", false);
    });
  }

  generateHistoryValues(String searchValue, bool needUpdate) {
    var keys = browserModel.history.keys.toList().reversed;
    int ind = 0;
    _data = [];
    items = {};
    searchValue = searchValue.toLowerCase();
    print("Getting for :: $searchValue");
    for (String k in keys) {
      var v = browserModel.history[k];
      if (v!.length != 0) {
        var c = 0;
        _data.add(HItem(date: k, search: null));

        items[k] = [];
        items[k]!.addAll([c, ind]);
        ind = ind + 1;
        for (Search s in v) {
          if (searchValue == "" ||
              s.title.toLowerCase().contains(searchValue) ||
              s.url.toString().toLowerCase().contains(searchValue)) {
            _data.add(HItem(date: k, search: s));
            c += 1;
            ind = ind + 1;
          }
        }
        if (c == 0) {
          items.remove(k);
          _data.removeAt(ind - 1);
          ind = ind - 1;
        } else {
          items[k]![0] = c;
        }
      }
    }
    if (needUpdate) {
      log(_data.toString());
      _listKey.currentState?.setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    browserModel = Provider.of<BrowserModel>(context, listen: false);

    settings = browserModel.getSettings();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return buildHistory();
  }

  SafeArea buildHistory() {
    return SafeArea(
      child: WillPopScope(
        onWillPop: () async {
          print("GB");
          if (!showSearchField)
            Navigator.pop(context);
          else {
            appBarKey.currentState?.setState(() {
              showSearchField = false;
            });
            clearAllSwitcher.currentState?.setState(() {
              showClearAll = true;
            });
          }
          return false;
        },
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          appBar: HistoryAppBar(
            generateHistoryValues: generateHistoryValues,
            key: appBarKey,
          ),
          body: FutureBuilder(
            future: initialize(context),
            builder: (context, AsyncSnapshot snapshot) {
              // Show splash screen while waiting for app resources to load:
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(
                    color: Colors.blue,
                  ),
                );
              } else {
                // Loading is done, return the app:

                return Column(
                  children: [
                    ClearAllH(
                      dataLen: _data.length,
                      browserModel: browserModel,
                      key: clearAllSwitcher,
                    ),
                    Expanded(
                      child: AnimatedOpacity(
                        opacity: 1,
                        duration: Duration(seconds: 1),
                        child: AnimatedList(
                          key: _listKey,
                          initialItemCount: _data.length,
                          itemBuilder: (context, index, animation) {
                            if (index < _data.length) {
                              HItem item = _data.elementAt(index);

                              return Column(children: [
                                _buildItem(item, index, animation)
                              ]);
                            }
                            return SizedBox.shrink();
                          },
                        ),
                      ),
                    ),
                  ],
                );
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildItem(HItem item, int index, Animation<double> animation) {
    return Column(
      children: [
        item.search == null
            ? SizeTransition(
                axis: Axis.horizontal,
                sizeFactor: animation,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
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
                ),
              )
            : SizeTransition(
                axis: Axis.horizontal,
                sizeFactor: animation,
                child: InkWell(
                  onTap: () {
                    var browserModel =
                        Provider.of<BrowserModel>(context, listen: false);
                    var settings = browserModel.getSettings();

                    var webViewModel =
                        Provider.of<WebViewModel>(context, listen: false);
                    var _webViewController = webViewModel.webViewController;
                    var url = Uri.parse(item.search!.url.toString());
                    if (!url.scheme.startsWith("http") &&
                        !Util.isLocalizedContent(url)) {
                      url = Uri.parse(settings.searchEngine.searchUrl +
                          item.search!.url.toString().trim());
                    }

                    if (_webViewController != null) {
                      _webViewController.loadUrl(
                          urlRequest: URLRequest(url: url));
                    } else {
                      widget.addNewTab(url: url);
                      webViewModel.url = url;
                    }

                    Navigator.pop(context);
                  },
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
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
                                  url: item.search!.url.toString().startsWith(
                                          RegExp("http[s]{0,1}:[/]{2}"))
                                      ? Uri.parse((item.search!.url?.origin ??
                                              settings.searchEngine.url) +
                                          "/favicon.ico")
                                      : null,
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
                                item.search!.title,
                                style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis,
                              ),
                              item.search!.url != null
                                  ? Text(
                                      item.search!.url.toString().startsWith(
                                              RegExp("http[s]{0,1}:[/]{2}"))
                                          ? (item.search!.url?.origin ?? "")
                                              .replaceFirst(
                                                  RegExp("http[s]{0,1}:[/]{2}"),
                                                  "")
                                          : "",
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 16),
                                    )
                                  : SizedBox.shrink(),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 28,
                          child: IconButton(
                              onPressed: () {
                                ritem = _data.removeAt(index);
                                for (int i = 0; i < _data.length; i++) {
                                  if (_data[i].search == null) {
                                    items[_data[i].date]![1] = i;
                                  }
                                }
                                AnimatedListRemovedItemBuilder builder =
                                    (context, animation) {
                                  // A method to build the Card widget.

                                  var browserModel = Provider.of<BrowserModel>(
                                      context,
                                      listen: false);

                                  browserModel.history[ritem.date] = _data
                                      .where(
                                          (element) => element.search != null)
                                      .toList()
                                      .where((element) =>
                                          (element.date == ritem.date &&
                                              element.search!.title !=
                                                  ritem.search!.title &&
                                              element.search!.url !=
                                                  ritem.search!.url))
                                      .toList()
                                      .map((e) => e.search!)
                                      .toList();
                                  browserModel.save();
                                  items[ritem.date]![0] =
                                      (items[ritem.date]![0] - 1);
                                  ritem.isDeleted = true;

                                  return _buildItem(ritem, index, animation);
                                };
                                _listKey.currentState
                                    ?.removeItem(index, builder);

                                if (items[ritem.date]![0] <= 1) {
                                  AnimatedListRemovedItemBuilder builder2 =
                                      (context, animation) {
                                    return _buildItem(
                                        _data.removeAt(items[ritem.date]![1]),
                                        items[ritem.date]![1],
                                        animation);
                                  };
                                  _listKey.currentState?.removeItem(
                                      items[ritem.date]![1], builder2);
                                }
                              },
                              icon: FaIcon(
                                FontAwesomeIcons.timesCircle,
                                color: Colors.black.withOpacity(0.7),
                              )),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ],
    );
  }
}

class ClearAllH extends StatefulWidget {
  final int dataLen;
  final BrowserModel browserModel;
  ClearAllH({required this.dataLen, required this.browserModel, Key? key})
      : super(key: key);

  @override
  _ClearAllHState createState() => _ClearAllHState();
}

class _ClearAllHState extends State<ClearAllH> {
  GlobalKey clearall = GlobalKey();
  Widget _buildClearAllHistory(BuildContext context, Key key) {
    return Row(
      children: [
        Padding(
          key: key,
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
                      content:
                          Text('Do you really want to clear all your history?'),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () {
                            widget.browserModel.history = LinkedHashMap();
                            widget.browserModel.save();
                            _data.clear();
                            setState(() => _listKey = GlobalKey());

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
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: Duration(milliseconds: 200),
      child: (widget.dataLen != 0 && showClearAll)
          ? _buildClearAllHistory(context, clearall)
          : SizedBox.shrink(),
    );
  }
}

class HistoryAppBar extends StatefulWidget implements PreferredSizeWidget {
  final Function(String, bool) generateHistoryValues;
  HistoryAppBar({required this.generateHistoryValues, Key? key})
      : super(key: key);

  @override
  _HistoryAppBarState createState() => _HistoryAppBarState();

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}

class _HistoryAppBarState extends State<HistoryAppBar> {
  TextEditingController txtc = TextEditingController();
  GlobalKey ktab = GlobalKey();
  GlobalKey ksf = GlobalKey();
  @override
  void dispose() {
    txtc.dispose();
    super.dispose();
  }

  Widget _buildSTF({required Key key}) {
    return Container(
      key: key,
      padding: EdgeInsets.all(8),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          InkWell(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(Icons.arrow_back),
            ),
            onTap: () {
              setState(() {
                showSearchField = false;
              });
              clearAllSwitcher.currentState?.setState(() {
                showClearAll = true;
              });
            },
          ),
          Expanded(
            child: TextFormField(
              autofocus: true,
              keyboardType: TextInputType.url,
              style: TextStyle(fontSize: 16),
              textInputAction: TextInputAction.go,
              textAlignVertical: TextAlignVertical.center,
              textAlign: TextAlign.left,
              maxLines: 1,
              decoration: InputDecoration(
                contentPadding: EdgeInsets.fromLTRB(0, 12, 12, 12),
                hintText: "Search or type address",
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                fillColor: Colors.black54,
              ),
              controller: txtc,
              onChanged: (value) {
                print("Searching for " + value.toString());
                widget.generateHistoryValues(value.toString(), true);
              },
            ),
          ),
          InkWell(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 8, 8, 8),
              child: Icon(Icons.clear),
            ),
            onTap: () {
              txtc.clear();
              widget.generateHistoryValues("", true);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHTab({required Key key}) {
    return Container(
      key: key,
      padding: EdgeInsets.all(16),
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
            children: [
              InkWell(
                onTap: () {
                  setState(() {
                    showSearchField = true;
                  });
                  clearAllSwitcher.currentState?.setState(() {
                    showClearAll = false;
                  });
                },
                child: Icon(
                  Icons.search,
                  size: 26,
                ),
              ),
              SizedBox(
                width: 16,
              ),
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Icon(
                  Icons.close,
                  size: 26,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: AnimatedSwitcher(
        duration: Duration(milliseconds: 200),
        child: showSearchField ? _buildSTF(key: ksf) : _buildHTab(key: ktab),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: child,
        ),
      ),
    );
  }
}
