import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:webpage_dev_console/c_popmenuitem.dart';
import 'package:webpage_dev_console/custom_image.dart';
import 'package:webpage_dev_console/helpers.dart';
import 'package:webpage_dev_console/model_search.dart';
import 'package:webpage_dev_console/models/browser_model.dart';
import 'package:webpage_dev_console/models/favorite_model.dart';
import 'package:webpage_dev_console/models/webview_model.dart';
import 'package:webpage_dev_console/tab_viewer_popup_menu_actions.dart';
import 'package:webpage_dev_console/util.dart';

bool showSearchField = false;
GlobalKey clearAllSwitcher = GlobalKey();
List<FItem> _data = [];

List<FItem> _selectedList = [];
GlobalKey<AnimatedListState> _listKey = GlobalKey();

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
      child: (_data.length > 1)
          ? widget.buildhistoryList()
          : widget.buildNoHistory(),
    );
  }
}

class Favorite extends StatefulWidget {
  Favorite({
    Key? key,
  }) : super(key: key) {
    _selectedList = [];
    longPressed = false;
  }

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
    browserModel = Provider.of<BrowserModel>(context, listen: false);

    settings = browserModel.getSettings();
  }

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
    for (String k in keys) {
      var v = browserModel.favorites[k] ?? [];
      if (v.length != 0) {
        var c = 0;
        _data.add(FItem(date: k, search: null));

        items[k] = [];
        items[k]!.addAll([c, ind]);
        ind = ind + 1;
        for (FavoriteModel s in v) {
          if (searchValue == "" ||
              s.title!.toLowerCase().contains(searchValue) ||
              s.url!.origin.toString().toLowerCase().contains(searchValue)) {
            _data.add(
                FItem(date: k, search: s, key: GlobalKey(), ikey: GlobalKey()));
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
      _listKey.currentState?.setState(() {});
      nohist.currentState?.setState(() {});
    }
  }

  SafeArea buildHistory() {
    return SafeArea(
      child: WillPopScope(
        onWillPop: () async {
          if (!showSearchField && !longPressed)
            Navigator.pop(context);
          else if (longPressed) {
            _selectedList.clear();
            longPressed = false;
            generateHistoryValues("", true);
            clearAllSwitcher.currentState?.setState(() {});
            nohist.currentState?.setState(() {});
            appBarKey.currentState?.setState(() {});
          } else {
            appBarKey.currentState?.setState(() {
              showSearchField = false;
            });
            generateHistoryValues("", true);
            txtc.clear();
            clearAllSwitcher.currentState?.setState(() {});
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
                      hbrowserModel: browserModel,
                      key: clearAllSwitcher,
                    ),
                    Expanded(
                      child: CAS(
                        buildNoHistory: _buildNoHistory,
                        buildhistoryList: _buildhistoryList,
                        key: nohist,
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

  AnimatedList _buildhistoryList() {
    return AnimatedList(
      key: _listKey,
      initialItemCount: _data.length,
      physics: BouncingScrollPhysics(),
      padding: EdgeInsets.only(bottom: 16),
      itemBuilder: (context, index, animation) {
        if (index < _data.length) {
          FItem item = _data.elementAt(index);

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
                    if (!longPressed) {
                      longPressed = true;
                      _listKey.currentState?.setState(() {});
                      clearAllSwitcher.currentState?.setState(() {});
                    }
                    if (!item.isSelected) {
                      _selectedList.add(item);
                    } else {
                      _selectedList.remove(item);
                      if (_selectedList.length == 0) {
                        longPressed = false;
                        _listKey.currentState?.setState(() {});
                        clearAllSwitcher.currentState?.setState(() {});
                      }
                    }
                    widget.item.key?.currentState?.setState(() {
                      widget.item.isSelected = !widget.item.isSelected;
                    });
                    appBarKey.currentState?.setState(() {});
                  },
                  onTap: () {
                    if (!longPressed) {
                      var webViewModel =
                          Provider.of<WebViewModel>(context, listen: false);
                      var _webViewController = webViewModel.webViewController;
                      var url = Uri.parse(widget.item.search!.url.toString());
                      if (!url.scheme.startsWith("http") &&
                          !Util.isLocalizedContent(url)) {
                        url = Uri.parse(settings.searchEngine.searchUrl +
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
                        _selectedList.remove(item);
                        if (_selectedList.length == 0) {
                          longPressed = false;
                          _listKey.currentState?.setState(() {});
                          clearAllSwitcher.currentState?.setState(() {});
                        }
                      } else {
                        _selectedList.add(item);
                      }
                      item.key?.currentState?.setState(() {
                        item.isSelected = !item.isSelected;
                      });

                      appBarKey.currentState?.setState(() {});
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
                                      ? Uri.parse((item.search!.url?.origin ??
                                              settings.searchEngine.url) +
                                          "/favicon.ico")
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
                                style: Theme.of(context).textTheme.headline2,
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
                                      style:
                                          Theme.of(context).textTheme.bodyText1,
                                    )
                                  : SizedBox.shrink(),
                            ],
                          ),
                        ),
                        longPressed
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
            ritem = _data.removeAt(index);
            for (int i = 0; i < _data.length; i++) {
              if (_data[i].search == null) {
                items[_data[i].date]![1] = i;
              }
            }
            AnimatedListRemovedItemBuilder builder = (context, animation) {
              browserModel.favorites[ritem.date] = _data
                  .where((element) => element.search != null)
                  .toList()
                  .where((element) => (element.date == ritem.date &&
                      element.search!.title != ritem.search!.title &&
                      element.search!.url != ritem.search!.url))
                  .toList()
                  .map((e) => e.search!)
                  .toList();
              browserModel.save();
              items[ritem.date]![0] = (items[ritem.date]![0] - 1);
              ritem.isDeleted = true;

              return _buildItem(ritem, index, animation);
            };
            _listKey.currentState?.removeItem(index, builder);

            if (items[ritem.date]![0] <= 1) {
              AnimatedListRemovedItemBuilder builder2 = (context, animation) {
                return _buildItem(_data.removeAt(items[ritem.date]![1]),
                    items[ritem.date]![1], animation);
              };
              _listKey.currentState
                  ?.removeItem(items[ritem.date]![1], builder2);

              nohist.currentState?.setState(() {});
              clearAllSwitcher.currentState?.setState(() {});
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
              (!showSearchField)
                  ? "Clear All Bookmarks"
                  : "Clear All Searched Results",
              key: vk,
              style: TextStyle(
                color: (!longPressed)
                    ? Colors.blue
                    : Theme.of(context).disabledColor,
                decoration: TextDecoration.underline,
                fontSize: 16,
              ),
            ),
            onPressed: () {
              if (!longPressed) {
                showDialog(
                    context: context,
                    builder: (_) {
                      return AlertDialog(
                        title: Text('Warning'),
                        content: Text(!showSearchField
                            ? 'Do you really want to clear all your bookmarks?'
                            : 'Do you really want to clear these bookmarks?'),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () {
                              if (!showSearchField) {
                                widget.hbrowserModel.favorites =
                                    LinkedHashMap();
                              } else {
                                var prevh = widget.hbrowserModel.favorites;
                                for (FItem hitem in _data) {
                                  if (hitem.search != null) {
                                    prevh[hitem.date]?.removeWhere((element) =>
                                        element.url == hitem.search?.url);
                                  }
                                }
                                widget.hbrowserModel.favorites = prevh;
                              }
                              widget.hbrowserModel.save();
                              _data.clear();
                              setState(() => _listKey = GlobalKey());
                              nohist.currentState?.setState(() {});
                              Navigator.pop(context);
                            },
                            child: Text(
                              'YES',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyText1
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
                              style: Theme.of(context).textTheme.bodyText1,
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
      child: (_data.length > 1)
          ? _buildClearAllHistory(context)
          : SizedBox.shrink(),
    );
  }
}

class HistoryAppBar extends StatefulWidget implements PreferredSizeWidget {
  HistoryAppBar({required this.generateHistoryValues, Key? key})
      : super(key: key);

  final Function(String, bool) generateHistoryValues;

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
    txtc.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    txtc = TextEditingController();
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
                showSearchField = false;
              });
              widget.generateHistoryValues("", true);
              txtc.clear();
              clearAllSwitcher.currentState?.setState(() {});
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
              decoration: InputDecoration(
                contentPadding: EdgeInsets.fromLTRB(12, 0, 12, 12),
                hintText: "Search or type address",
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                fillColor: Colors.black54,
              ),
              controller: txtc,
              onChanged: (value) {
                widget.generateHistoryValues(value.toString(), true);
                clearAllSwitcher.currentState?.setState(() {});
              },
            ),
          ),
          InkWell(
            child: Icon(
              Icons.clear,
              color: Theme.of(context).colorScheme.onBackground,
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
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "Bookmarks",
            style: Theme.of(context).textTheme.headline1,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              InkWell(
                onTap: () {
                  setState(() {
                    showSearchField = true;
                  });
                  clearAllSwitcher.currentState?.setState(() {});
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
                  setState(() {
                    showSearchField = false;
                  });
                  _selectedList = [];
                  longPressed = false;
                  widget.generateHistoryValues("", true);
                  clearAllSwitcher.currentState?.setState(() {});
                },
              ),
              SizedBox(
                width: 12,
              ),
              Text(
                "${_selectedList.length} Selected",
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
                    showSearchField = false;
                  });
                  clearAllSwitcher.currentState?.setState(() {});
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
                                var prevh = browserModel.favorites;
                                for (FItem hitem in _selectedList) {
                                  if (hitem.search != null) {
                                    prevh[hitem.date]?.removeWhere((element) =>
                                        element.url == hitem.search?.url);
                                  }
                                }
                                browserModel.favorites = prevh;

                                browserModel.save();
                                _selectedList.clear();
                                longPressed = false;
                                widget.generateHistoryValues("", true);
                                clearAllSwitcher.currentState?.setState(() {});
                                nohist.currentState?.setState(() {});
                                appBarKey.currentState?.setState(() {});
                                Navigator.pop(context);
                              },
                              child: Text(
                                'YES',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyText1
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
                                style: Theme.of(context).textTheme.bodyText1,
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
                    if (_selectedList.length == 1) {
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
          _selectedList.forEach((element) {
            Helper.addNewTab(url: element.search?.url, context: context);
          });
        });
        Navigator.pop(context);
        break;
      case TabViewerPopupMenuActions.NEW_INCOGNITO_TAB:
        _selectedList.forEach((element) {
          Helper.addNewIncognitoTab(url: element.search?.url, context: context);
        });

        Navigator.pop(context);
        break;
      case "Copy Link":
        Clipboard.setData(ClipboardData(
            text: _selectedList.elementAt(0).search?.url.toString()));
        Helper.showBasicFlash(
            duration: Duration(seconds: 2), msg: "Copied!", context: context);
        _selectedList = [];
        longPressed = false;

        widget.generateHistoryValues("", true);
        clearAllSwitcher.currentState?.setState(() {});
        nohist.currentState?.setState(() {});
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
        child: (showSearchField && !longPressed)
            ? _buildSTF(key: ksf)
            : longPressed
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
