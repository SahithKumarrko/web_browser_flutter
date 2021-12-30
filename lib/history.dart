import 'dart:collection';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:webpage_dev_console/c_popmenuitem.dart';
import 'package:webpage_dev_console/custom_image.dart';
import 'package:webpage_dev_console/helpers.dart';
import 'package:webpage_dev_console/models/model_search.dart';
import 'package:webpage_dev_console/models/app_theme.dart';
import 'package:webpage_dev_console/models/browser_model.dart';
import 'package:webpage_dev_console/models/webview_model.dart';
import 'package:webpage_dev_console/objectbox.g.dart';
import 'package:webpage_dev_console/search_model.dart';
import 'package:webpage_dev_console/tab_viewer_popup_menu_actions.dart';
import 'package:webpage_dev_console/util.dart';

class HistoryVars {
  bool showSearchField = false;
  GlobalKey clearAllSwitcher = GlobalKey();
  List<HItem> data = [];
  bool isloading = false;
  List<HItem> selectedList = [];
  GlobalKey<AnimatedListState> listKey = GlobalKey();

  TextEditingController txtc = TextEditingController();
  GlobalKey nohist = GlobalKey();
  bool longPressed = false;
  late BrowserModel browserModel;
  late BrowserSettings settings;
  String curDate = "";
  bool isRemoved = false;
  Map<String, List<int>> items = {};
  late HItem ritem;
  GlobalKey appBarKey = GlobalKey();
  GlobalKey loadmoredataKey = GlobalKey();
  Box<Search>? store;
  var count = 0;
  bool nodata = false;

  bool nodataT = false;
  bool isLoadingT = false;

  bool change = false;

  bool loadFreshly = false;
}

late HistoryVars historyVars;

class History extends StatefulWidget {
  History({
    Key? key,
  }) : super(key: key);

  @override
  _HistoryState createState() => _HistoryState();
}

class HItem {
  HItem(
      {required this.date,
      required this.search,
      this.isDeleted = false,
      this.isSelected = false,
      this.ikey,
      this.key});

  String date;
  bool isDeleted;
  bool isSelected;
  GlobalKey? key;
  GlobalKey? ikey;
  Search? search;

  @override
  String toString() =>
      'HItem(title: $date,url: $search,isSelected : $isSelected)';
}

class LoadMoreData extends StatefulWidget {
  LoadMoreData({Key? key}) : super(key: key);

  @override
  _LoadMoreDataState createState() => _LoadMoreDataState();
}

class _LoadMoreDataState extends State<LoadMoreData> {
  @override
  Widget build(BuildContext context) {
    return historyVars.isloading &&
            !historyVars.nodata &&
            historyVars.data.length != 0
        ? Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.blue,
                ),
              ),
            ),
          )
        : historyVars.nodata && historyVars.data.length != 0
            ? Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text("No More History Available"))
            : SizedBox();
  }
}

class CAS extends StatefulWidget {
  CAS({required this.buildhistoryList, required this.buildNoHistory, Key? key})
      : super(key: key);

  final Function() buildhistoryList;
  final Function() buildNoHistory;

  @override
  _CASState createState() => _CASState();
}

class _CASState extends State<CAS> {
  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: Duration(milliseconds: 300),
      child: (historyVars.data.length > 1)
          ? widget.buildhistoryList()
          : widget.buildNoHistory(),
    );
  }
}

class _HistoryState extends State<History>
    with AutomaticKeepAliveClientMixin<History> {
  @override
  void dispose() {
    // WidgetsBinding.instance!.removeObserver(this);
    super.dispose();
  }

  @override
  void initState() {
    historyVars = HistoryVars();
    // WidgetsBinding.instance!.addObserver(this);
    historyVars.showSearchField = false;
    // historyVars.isKeyboardVisible =
    //     WidgetsBinding.instance!.window.viewInsets.bottom > 0.0;
    super.initState();
    historyVars.browserModel =
        Provider.of<BrowserModel>(context, listen: false);

    historyVars.settings = historyVars.browserModel.getSettings();

    historyVars.store = historyVars.browserModel.searchbox;

    historyVars.count = 0;

    // total = store?.count() ?? 0;
  }

  // @override
  // void didChangeMetrics() {
  //   final bottomInset = WidgetsBinding.instance!.window.viewInsets.bottom;
  //   final newValue = bottomInset > 0.0;
  //   if (newValue != historyVars.isKeyboardVisible) {
  //     historyVars.isKeyboardVisible = newValue;
  //     print("Changed keyboard :: $newValue");
  //     historyVars.appBarKey.currentState?.setState(() {});
  //   }
  // }

  Future initialize(BuildContext context) async {
    // This is where you can initialize the resources needed by your app while
    // the splash screen is displayed.  Remove the following example because
    // delaying the user experience is a bad design practice!
    await Future.delayed(const Duration(seconds: 1), () async {
      generateHistoryValues("", false, 50);
    });
  }

  var previousSearch = "";

  List<HItem> tdata = [];
  Map<String, List<int>> ttitems = {};

  generateHistoryValues(String searchValue, bool needUpdate, int offset) {
    QueryBuilder<Search>? q;
    if (searchValue.isNotEmpty)
      q = historyVars.store?.query(Search_.title
          .contains(searchValue.trim(), caseSensitive: false)
          .and(Search_.url.contains(searchValue.trim(), caseSensitive: false))
          .and(Search_.isIncognito.equals(false)));
    else
      q = historyVars.store?.query(Search_.isIncognito.equals(false));
    q?.order(Search_.id, flags: Order.descending);
    print("Count :: ${historyVars.count} :: Offset :: $offset");
    var qq = q?.build()
      ?..offset = historyVars.count
      ..limit = offset;
    List<Search>? litems = qq?.find();
    log("Q :: $litems");
    historyVars.count = historyVars.count + offset;
    historyVars.nodata = false;
    if ((litems?.length ?? 0) < historyVars.count) {
      historyVars.nodata = true;
    }
    int ind = 0;
    searchValue = searchValue.toLowerCase();
    if (historyVars.loadFreshly ||
        (historyVars.showSearchField && !historyVars.isloading)) {
      historyVars.data = [];
      historyVars.items = {};
      historyVars.loadFreshly = false;
      // tdata = historyVars.data;
      // ttitems = historyVars.items;
    }
    //  else {
    //   if (tdata.length != 0 && !historyVars.showSearchField) {
    //     historyVars.data = tdata;
    //     historyVars.items = ttitems;
    //   }
    // }
    var dl = historyVars.data.length;
    var dates = litems?.map((e) => e.date).toSet().toList();
    for (String k in dates ?? []) {
      var c = 0;
      historyVars.data.add(HItem(date: k, search: null));

      historyVars.items[k] = [];
      historyVars.items[k]!.addAll([c, ind]);
      ind = ind + 1;
      for (Search v in litems ?? []) {
        if (v.date == k) {
          historyVars.data.add(
              HItem(date: k, search: v, key: GlobalKey(), ikey: GlobalKey()));
          c += 1;
          ind = ind + 1;
        }
      }
      if (c == 0) {
        historyVars.items.remove(k);
        historyVars.data.removeAt(ind - 1);
        ind = ind - 1;
      } else {
        historyVars.items[k]![0] = c;
      }
    }

    log("Fianal :: ${historyVars.data}");

    if (needUpdate) {
      historyVars.listKey.currentState?.setState(() {});
      historyVars.nohist.currentState?.setState(() {});

      if (historyVars.isloading) {
        historyVars.isloading = false;
        for (int i = dl; i <= historyVars.data.length; i++) {
          historyVars.listKey.currentState?.insertItem(i);
        }
      }
      historyVars.loadmoredataKey.currentState?.setState(() {});
    }
    previousSearch = searchValue;
  }

  Widget buildHistory() {
    var ct = Provider.of<ChangeTheme>(context, listen: true);
    return Theme(
      data: (SchedulerBinding.instance!.window.platformBrightness ==
                  Brightness.dark ||
              ct.cv == Brightness.dark ||
              historyVars.browserModel.isIncognito)
          ? AppTheme.darkTheme
          : AppTheme.lightTheme,
      child: SafeArea(
        child: WillPopScope(
          onWillPop: () async {
            if (!historyVars.showSearchField && !historyVars.longPressed)
              Navigator.pop(context);
            else if (historyVars.longPressed) {
              historyVars.selectedList.clear();
              historyVars.longPressed = false;
              // historyVars.count = 0;
              // generateHistoryValues("", true, 50);
              historyVars.clearAllSwitcher.currentState?.setState(() {});
              historyVars.nohist.currentState?.setState(() {});
              historyVars.appBarKey.currentState?.setState(() {});
              for (var i in historyVars.selectedList) {
                i.isSelected = false;
              }
            } else {
              historyVars.appBarKey.currentState?.setState(() {
                historyVars.showSearchField = false;
              });
              historyVars.loadFreshly = true;
              historyVars.txtc.clear();
              historyVars.clearAllSwitcher.currentState?.setState(() {});

              historyVars.count = 0;
              log("going back");
              generateHistoryValues("", true, 50);
            }
            // if (historyVars.change) {
            //   historyVars.retain_load();
            //   historyVars.loadmoredataKey.currentState?.setState(() {});
            // }
            return false;
          },
          child: Scaffold(
            resizeToAvoidBottomInset: true,
            appBar: HistoryAppBar(
              generateHistoryValues: generateHistoryValues,
              key: historyVars.appBarKey,
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
                        dataLen: historyVars.data.length,
                        hbrowserModel: historyVars.browserModel,
                        key: historyVars.clearAllSwitcher,
                      ),
                      Expanded(
                        child: CAS(
                          buildNoHistory: _buildNoHistory,
                          buildhistoryList: _buildhistoryList,
                          key: historyVars.nohist,
                        ),
                      ),
                      LoadMoreData(
                        key: historyVars.loadmoredataKey,
                      )
                    ],
                  );
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoHistory() {
    return Center(
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[800]
                : Colors.blueGrey[100],
            border: Border.all(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
            borderRadius: BorderRadius.all(Radius.circular(10))),
        child: Text(
          "No history found",
          style: Theme.of(context).textTheme.bodyText1?.copyWith(
                fontSize: 24.0,
              ),
        ),
      ),
    );
  }

  _onEndScroll(ScrollMetrics metrics) {
    print("Scroll End");
    if (!historyVars.isloading && !historyVars.nodata) {
      historyVars.isloading = true;
      historyVars.loadmoredataKey.currentState?.setState(() {});
      Future.delayed(Duration(seconds: 1), () {
        generateHistoryValues(historyVars.txtc.value.text, true, 50);
      });
    }
  }

  Widget _buildhistoryList() {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification) {
          _onEndScroll(notification.metrics);
        }
        return false;
      },
      child: AnimatedList(
        key: historyVars.listKey,
        initialItemCount: historyVars.data.length,
        padding: EdgeInsets.only(bottom: 16),
        itemBuilder: (context, index, animation) {
          if (index < historyVars.data.length) {
            HItem item = historyVars.data.elementAt(index);

            return Column(children: [
              HisItem(
                item: item,
                index: index,
                animation: animation,
                key: item.key,
              )
            ]);
          }
          return SizedBox.shrink();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return buildHistory();
  }

  @override
  bool get wantKeepAlive => true;
}

class HisItem extends StatefulWidget {
  HisItem(
      {required this.item,
      required this.animation,
      required this.index,
      Key? key})
      : super(key: key);

  final Animation<double> animation;
  final int index;
  final HItem item;

  @override
  _HisItemState createState() => _HisItemState();
}

class _HisItemState extends State<HisItem>
    with AutomaticKeepAliveClientMixin<HisItem> {
  Widget _buildItem(HItem item, int index, Animation<double> animation) {
    return Column(
      children: [
        item.search == null
            ? SizeTransition(
                axis: Axis.horizontal,
                sizeFactor: animation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: index > 0 ? 6 : 0,
                      ),
                      Text(
                        item.date,
                        style: Theme.of(context).textTheme.bodyText1,
                      ),
                      SizedBox(
                        height: 6,
                      ),
                    ],
                  ),
                ),
              )
            : SizeTransition(
                axis: Axis.horizontal,
                sizeFactor: animation,
                child: InkWell(
                  onLongPress: () {
                    if (!historyVars.longPressed) {
                      historyVars.longPressed = true;
                      historyVars.listKey.currentState?.setState(() {});
                      historyVars.clearAllSwitcher.currentState
                          ?.setState(() {});
                    }
                    if (!item.isSelected) {
                      historyVars.selectedList.add(item);
                    } else {
                      historyVars.selectedList.remove(item);
                      if (historyVars.selectedList.length == 0) {
                        historyVars.longPressed = false;
                        historyVars.listKey.currentState?.setState(() {});
                        historyVars.clearAllSwitcher.currentState
                            ?.setState(() {});
                      }
                    }
                    widget.item.key?.currentState?.setState(() {
                      widget.item.isSelected = !widget.item.isSelected;
                    });
                    historyVars.appBarKey.currentState?.setState(() {});
                  },
                  onTap: () {
                    if (!historyVars.longPressed) {
                      var webViewModel =
                          Provider.of<WebViewModel>(context, listen: false);
                      var _webViewController = webViewModel.webViewController;
                      var url = Uri.parse(widget.item.search!.url.toString());
                      if (!url.scheme.startsWith("http") &&
                          !Util.isLocalizedContent(url)) {
                        url = Uri.parse(
                            historyVars.settings.searchEngine.searchUrl +
                                widget.item.search!.url.toString().trim());
                      }

                      if (_webViewController != null) {
                        _webViewController.loadUrl(
                            urlRequest: URLRequest(url: url));
                      } else {
                        Helper.addNewTab(url: url, context: context);
                        webViewModel.url = url;
                      }

                      Navigator.pop(context);
                    } else {
                      if (item.isSelected) {
                        historyVars.selectedList.remove(item);
                        if (historyVars.selectedList.length == 0) {
                          historyVars.longPressed = false;
                          historyVars.listKey.currentState?.setState(() {});
                          historyVars.clearAllSwitcher.currentState
                              ?.setState(() {});
                        }
                      } else {
                        historyVars.selectedList.add(item);
                      }
                      item.key?.currentState?.setState(() {
                        item.isSelected = !item.isSelected;
                      });

                      historyVars.appBarKey.currentState?.setState(() {});
                    }
                  },
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: item.isSelected
                                    ? Colors.white
                                    : Colors.blue[100],
                              ),
                              padding: EdgeInsets.all(4),
                              child: CustomImage(
                                  isSelected: item.isSelected,
                                  url: item.search!.url.toString().startsWith(
                                          RegExp("http[s]{0,1}:[/]{2}"))
                                      ? Helper.getFavIconUrl(item.search!.url,
                                          historyVars.settings.searchEngine.url)
                                      : null,
                                  maxWidth: 24.0,
                                  key: item.ikey,
                                  height: 24.0),
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
                                style: Theme.of(context).textTheme.headline3,
                                overflow: TextOverflow.ellipsis,
                              ),
                              item.search!.url != ""
                                  ? Text(
                                      item.search!.url.toString().startsWith(
                                              RegExp("http[s]{0,1}:[/]{2}"))
                                          ? (item.search!.url != ""
                                                  ? Uri.parse(item.search!.url)
                                                      .origin
                                                  : "")
                                              .replaceFirst(
                                                  RegExp("http[s]{0,1}:[/]{2}"),
                                                  "")
                                          : "",
                                      overflow: TextOverflow.ellipsis,
                                      style:
                                          Theme.of(context).textTheme.bodyText2,
                                    )
                                  : SizedBox.shrink(),
                            ],
                          ),
                        ),
                        historyVars.longPressed
                            ? SizedBox(
                                width: 28,
                              )
                            : _buildRemoveItem(index),
                      ],
                    ),
                  ),
                ),
              ),
      ],
    );
  }

  SizedBox _buildRemoveItem(int index) {
    return SizedBox(
      width: 28,
      child: IconButton(
          padding: EdgeInsets.zero,
          constraints: BoxConstraints(),
          onPressed: () {
            historyVars.ritem = historyVars.data.removeAt(index);
            for (int i = 0; i < historyVars.data.length; i++) {
              if (historyVars.data[i].search == null) {
                historyVars.items[historyVars.data[i].date]![1] = i;
              }
            }
            AnimatedListRemovedItemBuilder builder = (context, animation) {
              // browserModel.history[ritem.date] = _data
              //     .where((element) => element.search != null)
              //     .toList()
              //     .where((element) => (element.date == ritem.date &&
              //         element.search!.title != ritem.search!.title &&
              //         element.search!.url != ritem.search!.url))
              //     .toList()
              //     .map((e) => e.search!)
              //     .toList();
              historyVars.store
                  ?.query(Search_.date
                      .equals(historyVars.ritem.date)
                      .and(
                          Search_.title.equals(historyVars.ritem.search!.title))
                      .and(Search_.url.equals(historyVars.ritem.search!.url)))
                  .build()
                  .remove();
              // browserModel.save();
              historyVars.items[historyVars.ritem.date]![0] =
                  (historyVars.items[historyVars.ritem.date]![0] - 1);
              historyVars.ritem.isDeleted = true;

              return _buildItem(historyVars.ritem, index, animation);
            };
            historyVars.listKey.currentState?.removeItem(index, builder);

            if (historyVars.items[historyVars.ritem.date]![0] <= 1) {
              AnimatedListRemovedItemBuilder builder2 = (context, animation) {
                return _buildItem(
                    historyVars.data.removeAt(
                        historyVars.items[historyVars.ritem.date]![1]),
                    historyVars.items[historyVars.ritem.date]![1],
                    animation);
              };
              historyVars.listKey.currentState?.removeItem(
                  historyVars.items[historyVars.ritem.date]![1], builder2);

              historyVars.nohist.currentState?.setState(() {});
              historyVars.clearAllSwitcher.currentState?.setState(() {});
            }
          },
          icon: FaIcon(
            FontAwesomeIcons.timesCircle,
            color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
            size: 18,
          )),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return _buildItem(widget.item, widget.index, widget.animation);
  }

  @override
  bool get wantKeepAlive => true;
}

class ClearAllH extends StatefulWidget {
  ClearAllH({required this.dataLen, required this.hbrowserModel, Key? key})
      : super(key: key);

  final int dataLen;
  final BrowserModel hbrowserModel;

  @override
  _ClearAllHState createState() => _ClearAllHState();
}

class _ClearAllHState extends State<ClearAllH> {
  ValueKey vk = ValueKey("specificDeletion");

  Widget _buildClearAllHistory(BuildContext context) {
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextButton(
            child: Text(
              (!historyVars.showSearchField)
                  ? "Clear Browsing History"
                  : "Clear All Searched Results",
              key: vk,
              style: TextStyle(
                color: (!historyVars.longPressed)
                    ? Colors.blue
                    : Theme.of(context).disabledColor,
                decoration: TextDecoration.underline,
                fontSize: 16,
              ),
            ),
            onPressed: () {
              if (!historyVars.longPressed) {
                showDialog(
                    context: context,
                    builder: (_) {
                      return AlertDialog(
                        title: Text('Warning'),
                        content: Text(!historyVars.showSearchField
                            ? 'Do you really want to clear all your history?'
                            : 'Do you really want to clear this history?'),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () {
                              if (!historyVars.showSearchField) {
                                // widget.hbrowserModel.history = LinkedHashMap();
                                historyVars.store?.removeAll();
                              } else {
                                // var prevh = widget.hbrowserModel.history;
                                // for (HItem hitem in _data) {
                                //   if (hitem.search != null) {
                                //     prevh[hitem.date]?.removeWhere((element) =>
                                //         element.search ==
                                //             hitem.search?.search &&
                                //         element.url == hitem.search?.url);
                                //   }
                                // }
                                // widget.hbrowserModel.history = prevh;
                                var ritems = historyVars.data
                                    .where((element) => element.search != null)
                                    .toList()
                                    .map((e) => e.search?.id ?? 0)
                                    .toList();
                                historyVars.store?.removeMany(ritems);
                              }
                              // widget.hbrowserModel.save();
                              historyVars.data.clear();
                              this.setState(
                                  () => historyVars.listKey = GlobalKey());
                              historyVars.nohist.currentState?.setState(() {});
                              Navigator.pop(context);
                            },
                            child: Text(
                              'YES',
                              style: Theme.of(context)
                                  .textTheme
                                  .headline3
                                  ?.copyWith(
                                      color: Theme.of(context).disabledColor),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text(
                              'NO',
                              style: Theme.of(context).textTheme.headline3,
                            ),
                          ),
                        ],
                      );
                    });
              }
              return null;
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
      child: (historyVars.data.length > 1)
          ? _buildClearAllHistory(context)
          : SizedBox.shrink(),
    );
  }
}

class HistoryAppBar extends StatefulWidget implements PreferredSizeWidget {
  HistoryAppBar({required this.generateHistoryValues, Key? key})
      : super(key: key);

  final Function(String, bool, int) generateHistoryValues;

  @override
  _HistoryAppBarState createState() => _HistoryAppBarState();

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}

class _HistoryAppBarState extends State<HistoryAppBar> {
  GlobalKey deleteBar = GlobalKey();
  GlobalKey ksf = GlobalKey();
  GlobalKey ktab = GlobalKey();

  @override
  void dispose() {
    historyVars.txtc.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    historyVars.txtc = TextEditingController();
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
            child: Icon(
              Icons.arrow_back,
              color: Theme.of(context).colorScheme.onBackground,
            ),
            onTap: () {
              this.setState(() {
                historyVars.showSearchField = false;
              });
              // if (historyVars.change) {
              //   historyVars.retain_load();
              //   historyVars.loadmoredataKey.currentState?.setState(() {});
              // }
              historyVars.loadFreshly = true;
              historyVars.count = 0;
              widget.generateHistoryValues("", true, 50);
              historyVars.txtc.clear();
              historyVars.clearAllSwitcher.currentState?.setState(() {});
            },
          ),
          Expanded(
            child: TextFormField(
              autofocus: true,
              keyboardType: TextInputType.url,
              style: Theme.of(context).textTheme.bodyText1,
              textInputAction: TextInputAction.go,
              textAlignVertical: TextAlignVertical.center,
              textAlign: TextAlign.left,
              maxLines: 1,
              cursorColor: Theme.of(context).colorScheme.onBackground,
              decoration: InputDecoration(
                contentPadding: EdgeInsets.fromLTRB(12, 0, 12, 12),
                hintText: "Search or type address",
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                fillColor: Colors.black54,
              ),
              controller: historyVars.txtc,
              onChanged: (value) {
                historyVars.count = 0;
                widget.generateHistoryValues(value.toString(), true, 50);
                historyVars.clearAllSwitcher.currentState?.setState(() {});
              },
            ),
          ),
          InkWell(
            child: Icon(
              Icons.clear,
              color: Theme.of(context).colorScheme.onBackground,
            ),
            onTap: () {
              historyVars.txtc.clear();
              historyVars.count = 0;
              widget.generateHistoryValues("", true, 50);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHTab({required Key key}) {
    return Container(
      key: key,
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "History",
            style: Theme.of(context).textTheme.headline1,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              InkWell(
                onTap: () {
                  this.setState(() {
                    historyVars.showSearchField = true;
                  });
                  historyVars.clearAllSwitcher.currentState?.setState(() {});
                  // historyVars.copy_load(false, false);
                  // historyVars.loadmoredataKey.currentState?.setState(() {});
                },
                child: Icon(
                  Icons.search,
                  color: Theme.of(context).colorScheme.onBackground,
                  size: 24,
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
                  color: Theme.of(context).colorScheme.onBackground,
                  size: 24,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLongPressed({required Key key}) {
    return Container(
      key: key,
      color: Colors.redAccent,
      padding: EdgeInsets.only(left: 16, top: 16, bottom: 16, right: 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              InkWell(
                child: Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                ),
                onTap: () {
                  // this.setState(() {
                  //   historyVars.showSearchField = false;
                  // });
                  for (var i in historyVars.selectedList) {
                    i.isSelected = false;
                  }
                  historyVars.selectedList = [];
                  historyVars.longPressed = false;
                  historyVars.count = 0;
                  widget.generateHistoryValues("", true, 50);
                  this.setState(() {});
                  historyVars.clearAllSwitcher.currentState?.setState(() {});
                },
              ),
              SizedBox(
                width: 12,
              ),
              Text(
                "${historyVars.selectedList.length} Selected",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              InkWell(
                onTap: () {
                  this.setState(() {
                    historyVars.showSearchField = false;
                  });
                  historyVars.clearAllSwitcher.currentState?.setState(() {});
                  showDialog(
                      context: context,
                      builder: (_) {
                        return AlertDialog(
                          title: Text('Warning'),
                          content: Text(
                              'Do you really want to clear all the selected history?'),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () {
                                var ritems = historyVars.selectedList
                                    .where((element) => element.search != null)
                                    .toList()
                                    .map((e) => e.search?.id ?? 0)
                                    .toList();
                                historyVars.store?.removeMany(ritems);
                                historyVars.selectedList.clear();
                                historyVars.longPressed = false;
                                historyVars.count = 0;
                                widget.generateHistoryValues("", true, 50);
                                historyVars.clearAllSwitcher.currentState
                                    ?.setState(() {});
                                historyVars.nohist.currentState
                                    ?.setState(() {});
                                historyVars.appBarKey.currentState
                                    ?.setState(() {});
                                Navigator.pop(context);
                              },
                              child: Text(
                                'YES',
                                style: Theme.of(context)
                                    .textTheme
                                    .headline3
                                    ?.copyWith(
                                        color: Theme.of(context).disabledColor),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: Text(
                                'NO',
                                style: Theme.of(context).textTheme.headline3,
                              ),
                            ),
                          ],
                        );
                      });
                },
                child: Icon(
                  Icons.delete_forever_rounded,
                  color: Colors.white,
                ),
              ),
              SizedBox(
                width: 8,
              ),
              PopupMenuButton<String>(
                  onSelected: _popupMenuChoiceAction,
                  padding: EdgeInsets.zero,
                  icon: Icon(Icons.more_vert_rounded, color: Colors.white),
                  iconSize: 24,
                  itemBuilder: (popupMenuContext) {
                    var popupitems = <PopupMenuEntry<String>>[];

                    popupitems.add(CustomPopupMenuItem<String>(
                      enabled: true,
                      value: TabViewerPopupMenuActions.NEW_TAB,
                      child: Text(
                        "Open in New Tab",
                        style: Theme.of(context).textTheme.bodyText1,
                      ),
                    ));
                    popupitems.add(CustomPopupMenuItem<String>(
                      enabled: true,
                      value: TabViewerPopupMenuActions.NEW_INCOGNITO_TAB,
                      child: Text(
                        "Open in Incognito Tab",
                        style: Theme.of(context).textTheme.bodyText1,
                      ),
                    ));
                    if (historyVars.selectedList.length == 1) {
                      popupitems.add(CustomPopupMenuItem<String>(
                        enabled: true,
                        value: "Copy Link",
                        child: Text(
                          "Copy Link",
                          style: Theme.of(context).textTheme.bodyText1,
                        ),
                      ));
                    }

                    return popupitems;
                  }),
            ],
          ),
        ],
      ),
    );
  }

  void _popupMenuChoiceAction(String choice) {
    switch (choice) {
      case TabViewerPopupMenuActions.NEW_TAB:
        Future.delayed(const Duration(milliseconds: 300), () {
          historyVars.selectedList.forEach((element) {
            Helper.addNewTab(
                url: Uri.parse(element.search?.url ?? ""), context: context);
          });
        });
        Navigator.pop(context);
        break;
      case TabViewerPopupMenuActions.NEW_INCOGNITO_TAB:
        historyVars.selectedList.forEach((element) {
          Helper.addNewIncognitoTab(
              url: Uri.parse(element.search?.url ?? ""), context: context);
        });

        Navigator.pop(context);
        break;
      case "Copy Link":
        Clipboard.setData(ClipboardData(
            text:
                historyVars.selectedList.elementAt(0).search?.url.toString()));
        Helper.showBasicFlash(
            duration: Duration(seconds: 2),
            msg: "Copied!",
            context: this.context);
        historyVars.selectedList = [];
        historyVars.longPressed = false;
        historyVars.count = 0;
        widget.generateHistoryValues("", true, 50);
        historyVars.clearAllSwitcher.currentState?.setState(() {});
        historyVars.nohist.currentState?.setState(() {});
        this.setState(() {});
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: AnimatedSwitcher(
        duration: Duration(milliseconds: 200),
        child: (historyVars.showSearchField && !historyVars.longPressed)
            ? _buildSTF(key: ksf)
            : historyVars.longPressed
                ? _buildLongPressed(key: deleteBar)
                : _buildHTab(key: ktab),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: child,
        ),
      ),
    );
  }
}
