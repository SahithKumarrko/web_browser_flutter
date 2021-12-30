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
import 'package:webpage_dev_console/models/app_theme.dart';
import 'package:webpage_dev_console/models/browser_model.dart';
import 'package:webpage_dev_console/models/favorite_model.dart';
import 'package:webpage_dev_console/models/webview_model.dart';
import 'package:webpage_dev_console/objectbox.g.dart';
import 'package:webpage_dev_console/tab_viewer_popup_menu_actions.dart';
import 'package:webpage_dev_console/util.dart';

class FavoriteVars {
  bool showSearchField = false;
  GlobalKey clearAllSwitcher = GlobalKey();
  List<FItem> data = [];

  List<FItem> selectedList = [];
  GlobalKey<AnimatedListState> listKey = GlobalKey();

  TextEditingController txtc = TextEditingController();
  GlobalKey nohist = GlobalKey();
  bool longPressed = false;
  late BrowserModel browserModel;
  late BrowserSettings settings;
  String curDate = "";
  bool isRemoved = false;
  Map<String, List<int>> items = {};
  late FItem ritem;
  GlobalKey appBarKey = GlobalKey();
  Box<FavoriteModel>? store;
  var count = 0;

  bool nodata = false;
  bool nodataT = false;
  bool isLoadingT = false;

  bool change = false;

  bool isloading = false;
  bool loadFreshly = false;

  GlobalKey loadmoredataKey = GlobalKey();
}

late FavoriteVars favoriteVars;

class LoadMoreData extends StatefulWidget {
  LoadMoreData({Key? key}) : super(key: key);

  @override
  _LoadMoreDataState createState() => _LoadMoreDataState();
}

class _LoadMoreDataState extends State<LoadMoreData> {
  @override
  Widget build(BuildContext context) {
    return favoriteVars.isloading &&
            !favoriteVars.nodata &&
            favoriteVars.data.length != 0
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
        : favoriteVars.nodata && favoriteVars.data.length != 0
            ? Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text("No More Favorites Available"))
            : SizedBox();
  }
}

class FItem {
  FItem(
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
  FavoriteModel? search;

  @override
  String toString() =>
      'FItem(title: $date,url: $search,isSelected : $isSelected)';
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
      child: (favoriteVars.data.length > 1)
          ? widget.buildhistoryList()
          : widget.buildNoHistory(),
    );
  }
}

class Favorite extends StatefulWidget {
  Favorite({
    Key? key,
  }) : super(key: key);

  @override
  _FavoriteState createState() => _FavoriteState();
}

class _FavoriteState extends State<Favorite> {
  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    favoriteVars = FavoriteVars();
    favoriteVars.browserModel =
        Provider.of<BrowserModel>(context, listen: false);

    favoriteVars.settings = favoriteVars.browserModel.getSettings();

    favoriteVars.store = favoriteVars.browserModel.favouritebox;
    favoriteVars.count = 0;
  }

  Future initialize(BuildContext context) async {
    // This is where you can initialize the resources needed by your app while
    // the splash screen is displayed.  Remove the following example because
    // delaying the user experience is a bad design practice!
    await Future.delayed(const Duration(seconds: 1), () async {
      generateHistoryValues("", false, 40);
    });
  }

  var previousSearch = "";
  generateHistoryValues(String searchValue, bool needUpdate, int offset) {
    QueryBuilder<FavoriteModel>? q;
    if (searchValue.isNotEmpty)
      q = favoriteVars.store?.query(FavoriteModel_.title
          .contains(searchValue.trim(), caseSensitive: false)
          .and(FavoriteModel_.url
              .contains(searchValue.trim(), caseSensitive: false)));
    else
      q = favoriteVars.store?.query();
    q?.order(FavoriteModel_.id, flags: Order.descending);
    print("Count :: ${favoriteVars.count} :: Offset :: $offset");
    var qq = q?.build()
      ?..offset = favoriteVars.count
      ..limit = offset;
    qq
      ?..offset = favoriteVars.count
      ..limit = offset;

    List<FavoriteModel>? litems = qq?.find();
    log("Items :: $litems");
    favoriteVars.nodata = false;

    favoriteVars.count = favoriteVars.count + offset;
    if ((litems?.length ?? 0) < favoriteVars.count) {
      favoriteVars.nodata = true;
    }
    int ind = 0;
    if (favoriteVars.loadFreshly ||
        (favoriteVars.showSearchField && !favoriteVars.isloading)) {
      favoriteVars.data = [];
      favoriteVars.items = {};
      favoriteVars.loadFreshly = false;
      // tdata = favoriteVars.data;
      // ttitems = favoriteVars.items;
    }
    searchValue = searchValue.toLowerCase();
    var dl = favoriteVars.data.length;
    var dates = litems?.map((e) => e.date).toSet().toList();
    log("Dates : $dates :: ${dates?.length}");
    for (String k in dates ?? []) {
      var c = 0;
      favoriteVars.data.add(FItem(date: k, search: null));

      favoriteVars.items[k] = [];
      favoriteVars.items[k]!.addAll([c, ind]);
      ind = ind + 1;
      for (FavoriteModel s in litems ?? []) {
        if (s.date == k) {
          favoriteVars.data.add(
              FItem(date: k, search: s, key: GlobalKey(), ikey: GlobalKey()));
          c += 1;
          ind = ind + 1;
        }
      }
      if (c == 0) {
        favoriteVars.items.remove(k);
        favoriteVars.data.removeAt(ind - 1);
        ind = ind - 1;
      } else {
        favoriteVars.items[k]![0] = c;
      }
    }
    log("Final :: ${favoriteVars.data}");
    if (needUpdate) {
      favoriteVars.listKey.currentState?.setState(() {});
      favoriteVars.nohist.currentState?.setState(() {});

      if (favoriteVars.isloading) {
        favoriteVars.isloading = false;
        for (int i = dl; i <= favoriteVars.data.length; i++) {
          favoriteVars.listKey.currentState?.insertItem(i);
        }
      }
      favoriteVars.loadmoredataKey.currentState?.setState(() {});
    }
    previousSearch = searchValue;
  }

  Widget buildHistory() {
    var ct = Provider.of<ChangeTheme>(context, listen: true);
    return Theme(
      data: (SchedulerBinding.instance!.window.platformBrightness ==
                  Brightness.dark ||
              ct.cv == Brightness.dark ||
              favoriteVars.browserModel.isIncognito)
          ? AppTheme.darkTheme
          : AppTheme.lightTheme,
      child: SafeArea(
        child: WillPopScope(
          onWillPop: () async {
            if (!favoriteVars.showSearchField && !favoriteVars.longPressed)
              Navigator.pop(context);
            else if (favoriteVars.longPressed) {
              favoriteVars.selectedList.clear();
              favoriteVars.longPressed = false;

              favoriteVars.clearAllSwitcher.currentState?.setState(() {});
              favoriteVars.nohist.currentState?.setState(() {});
              favoriteVars.appBarKey.currentState?.setState(() {});
              for (var i in favoriteVars.selectedList) {
                i.isSelected = false;
              }
            } else {
              favoriteVars.appBarKey.currentState?.setState(() {
                favoriteVars.showSearchField = false;
              });
              favoriteVars.count = 0;
              favoriteVars.loadFreshly = true;
              favoriteVars.txtc.clear();
              favoriteVars.clearAllSwitcher.currentState?.setState(() {});

              generateHistoryValues("", true, 50);
            }

            return false;
          },
          child: Scaffold(
            resizeToAvoidBottomInset: true,
            appBar: HistoryAppBar(
              generateHistoryValues: generateHistoryValues,
              key: favoriteVars.appBarKey,
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
                        dataLen: favoriteVars.data.length,
                        hbrowserModel: favoriteVars.browserModel,
                        key: favoriteVars.clearAllSwitcher,
                      ),
                      Expanded(
                        child: CAS(
                          buildNoHistory: _buildNoHistory,
                          buildhistoryList: _buildhistoryList,
                          key: favoriteVars.nohist,
                        ),
                      ),
                      LoadMoreData(
                        key: favoriteVars.loadmoredataKey,
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
          "No bookmark found",
          style: Theme.of(context).textTheme.bodyText1?.copyWith(
                fontSize: 24.0,
              ),
        ),
      ),
    );
  }

  _onEndScroll(ScrollMetrics metrics) {
    log("Scroll End");
    if (!favoriteVars.isloading && !favoriteVars.nodata) {
      favoriteVars.isloading = true;
      favoriteVars.loadmoredataKey.currentState?.setState(() {});
      Future.delayed(Duration(seconds: 1), () {
        generateHistoryValues(favoriteVars.txtc.value.text, true, 50);
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
        key: favoriteVars.listKey,
        initialItemCount: favoriteVars.data.length,
        physics: BouncingScrollPhysics(),
        padding: EdgeInsets.only(bottom: 16),
        itemBuilder: (context, index, animation) {
          if (index < favoriteVars.data.length) {
            FItem item = favoriteVars.data.elementAt(index);

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
    return buildHistory();
  }
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
  final FItem item;

  @override
  _HisItemState createState() => _HisItemState();
}

class _HisItemState extends State<HisItem> {
  Widget _buildItem(FItem item, int index, Animation<double> animation) {
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
                    if (!favoriteVars.longPressed) {
                      favoriteVars.longPressed = true;
                      favoriteVars.listKey.currentState?.setState(() {});
                      favoriteVars.clearAllSwitcher.currentState
                          ?.setState(() {});
                    }
                    if (!item.isSelected) {
                      favoriteVars.selectedList.add(item);
                    } else {
                      favoriteVars.selectedList.remove(item);
                      if (favoriteVars.selectedList.length == 0) {
                        favoriteVars.longPressed = false;
                        favoriteVars.listKey.currentState?.setState(() {});
                        favoriteVars.clearAllSwitcher.currentState
                            ?.setState(() {});
                      }
                    }
                    widget.item.key?.currentState?.setState(() {
                      widget.item.isSelected = !widget.item.isSelected;
                    });
                    favoriteVars.appBarKey.currentState?.setState(() {});
                  },
                  onTap: () {
                    if (!favoriteVars.longPressed) {
                      var webViewModel =
                          Provider.of<WebViewModel>(context, listen: false);
                      var _webViewController = webViewModel.webViewController;
                      var url = Uri.parse(widget.item.search!.url.toString());
                      if (!url.scheme.startsWith("http") &&
                          !Util.isLocalizedContent(url)) {
                        url = Uri.parse(
                            favoriteVars.settings.searchEngine.searchUrl +
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
                        favoriteVars.selectedList.remove(item);
                        if (favoriteVars.selectedList.length == 0) {
                          favoriteVars.longPressed = false;
                          favoriteVars.listKey.currentState?.setState(() {});
                          favoriteVars.clearAllSwitcher.currentState
                              ?.setState(() {});
                        }
                      } else {
                        favoriteVars.selectedList.add(item);
                      }
                      item.key?.currentState?.setState(() {
                        item.isSelected = !item.isSelected;
                      });

                      favoriteVars.appBarKey.currentState?.setState(() {});
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
                                      ? Helper.getFavIconUrl(
                                          item.search?.url ?? "",
                                          favoriteVars
                                              .settings.searchEngine.url)
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
                                item.search!.title.toString(),
                                style: Theme.of(context).textTheme.headline3,
                                overflow: TextOverflow.ellipsis,
                              ),
                              item.search!.url != ""
                                  ? Text(
                                      item.search!.url.startsWith(
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
                        favoriteVars.longPressed
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
            favoriteVars.ritem = favoriteVars.data.removeAt(index);
            for (int i = 0; i < favoriteVars.data.length; i++) {
              if (favoriteVars.data[i].search == null) {
                favoriteVars.items[favoriteVars.data[i].date]![1] = i;
              }
            }
            AnimatedListRemovedItemBuilder builder = (context, animation) {
              favoriteVars.store
                  ?.query(FavoriteModel_.date
                      .equals(favoriteVars.ritem.date)
                      .and(FavoriteModel_.title
                          .equals(favoriteVars.ritem.search!.title))
                      .and(FavoriteModel_.url
                          .equals(favoriteVars.ritem.search!.url)))
                  .build()
                  .remove();
              favoriteVars.items[favoriteVars.ritem.date]![0] =
                  (favoriteVars.items[favoriteVars.ritem.date]![0] - 1);
              favoriteVars.ritem.isDeleted = true;

              return _buildItem(favoriteVars.ritem, index, animation);
            };
            favoriteVars.listKey.currentState?.removeItem(index, builder);

            if (favoriteVars.items[favoriteVars.ritem.date]![0] <= 1) {
              AnimatedListRemovedItemBuilder builder2 = (context, animation) {
                return _buildItem(
                    favoriteVars.data.removeAt(
                        favoriteVars.items[favoriteVars.ritem.date]![1]),
                    favoriteVars.items[favoriteVars.ritem.date]![1],
                    animation);
              };
              favoriteVars.listKey.currentState?.removeItem(
                  favoriteVars.items[favoriteVars.ritem.date]![1], builder2);

              favoriteVars.nohist.currentState?.setState(() {});
              favoriteVars.clearAllSwitcher.currentState?.setState(() {});
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
    return _buildItem(widget.item, widget.index, widget.animation);
  }
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
              (!favoriteVars.showSearchField)
                  ? "Clear All Bookmarks"
                  : "Clear All Searched Results",
              key: vk,
              style: TextStyle(
                color: (!favoriteVars.longPressed)
                    ? Colors.blue
                    : Theme.of(context).disabledColor,
                decoration: TextDecoration.underline,
                fontSize: 16,
              ),
            ),
            onPressed: () {
              if (!favoriteVars.longPressed) {
                showDialog(
                    context: context,
                    builder: (_) {
                      return AlertDialog(
                        title: Text('Warning'),
                        content: Text(!favoriteVars.showSearchField
                            ? 'Do you really want to clear all your bookmarks?'
                            : 'Do you really want to clear these bookmarks?'),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () {
                              if (!favoriteVars.showSearchField) {
                                favoriteVars.store?.removeAll();
                              } else {
                                var ritems = favoriteVars.data
                                    .where((element) => element.search != null)
                                    .toList()
                                    .map((e) => e.search?.id ?? 0)
                                    .toList();
                                favoriteVars.store?.removeMany(ritems);
                              }
                              favoriteVars.data.clear();
                              setState(
                                  () => favoriteVars.listKey = GlobalKey());
                              favoriteVars.nohist.currentState?.setState(() {});
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
      child: (favoriteVars.data.length > 1)
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
    favoriteVars.txtc.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    favoriteVars.txtc = TextEditingController();
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
              setState(() {
                favoriteVars.showSearchField = false;
              });
              favoriteVars.loadFreshly = true;
              favoriteVars.count = 0;
              widget.generateHistoryValues("", true, 50);
              favoriteVars.txtc.clear();
              favoriteVars.clearAllSwitcher.currentState?.setState(() {});
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
              controller: favoriteVars.txtc,
              onChanged: (value) {
                favoriteVars.count = 0;
                widget.generateHistoryValues(value.toString(), true, 50);
                favoriteVars.clearAllSwitcher.currentState?.setState(() {});
              },
            ),
          ),
          InkWell(
            child: Icon(
              Icons.clear,
              color: Theme.of(context).colorScheme.onBackground,
            ),
            onTap: () {
              favoriteVars.txtc.clear();
              favoriteVars.count = 0;
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
            "Bookmarks",
            style: Theme.of(context).textTheme.headline1,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                InkWell(
                  onTap: () {
                    setState(() {
                      favoriteVars.showSearchField = true;
                    });
                    favoriteVars.clearAllSwitcher.currentState?.setState(() {});
                    // favoriteVars.loadmoredataKey.currentState?.setState(() {});
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
                  for (var i in favoriteVars.selectedList) {
                    i.isSelected = false;
                  }
                  favoriteVars.selectedList = [];
                  favoriteVars.longPressed = false;
                  favoriteVars.count = 0;
                  widget.generateHistoryValues("", true, 50);
                  this.setState(() {});
                  favoriteVars.clearAllSwitcher.currentState?.setState(() {});
                },
              ),
              SizedBox(
                width: 12,
              ),
              Text(
                "${favoriteVars.selectedList.length} Selected",
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
                  setState(() {
                    favoriteVars.showSearchField = false;
                  });
                  favoriteVars.clearAllSwitcher.currentState?.setState(() {});
                  showDialog(
                      context: context,
                      builder: (_) {
                        return AlertDialog(
                          title: Text('Warning'),
                          content: Text(
                              'Do you really want to clear all the selected bookmarks?'),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () {
                                var ritems = favoriteVars.selectedList
                                    .where((element) => element.search != null)
                                    .toList()
                                    .map((e) => e.search?.id ?? 0)
                                    .toList();
                                favoriteVars.store?.removeMany(ritems);
                                favoriteVars.selectedList.clear();
                                favoriteVars.longPressed = false;
                                favoriteVars.count = 0;
                                widget.generateHistoryValues("", true, 50);
                                favoriteVars.clearAllSwitcher.currentState
                                    ?.setState(() {});
                                favoriteVars.nohist.currentState
                                    ?.setState(() {});
                                favoriteVars.appBarKey.currentState
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
                    if (favoriteVars.selectedList.length == 1) {
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
          favoriteVars.selectedList.forEach((element) {
            Helper.addNewTab(
                url: Uri.parse(element.search?.url ?? ""), context: context);
          });
        });
        Navigator.pop(context);
        break;
      case TabViewerPopupMenuActions.NEW_INCOGNITO_TAB:
        favoriteVars.selectedList.forEach((element) {
          Helper.addNewIncognitoTab(
              url: Uri.parse(element.search?.url ?? ""), context: context);
        });

        Navigator.pop(context);
        break;
      case "Copy Link":
        Clipboard.setData(ClipboardData(
            text:
                favoriteVars.selectedList.elementAt(0).search?.url.toString()));
        Helper.showBasicFlash(
            duration: Duration(seconds: 2),
            msg: "Copied!",
            context: this.context);
        favoriteVars.selectedList = [];
        favoriteVars.longPressed = false;
        favoriteVars.count = 0;
        widget.generateHistoryValues("", true, 50);
        favoriteVars.clearAllSwitcher.currentState?.setState(() {});
        favoriteVars.nohist.currentState?.setState(() {});
        setState(() {});
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: AnimatedSwitcher(
        duration: Duration(milliseconds: 200),
        child: (favoriteVars.showSearchField && !favoriteVars.longPressed)
            ? _buildSTF(key: ksf)
            : favoriteVars.longPressed
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
