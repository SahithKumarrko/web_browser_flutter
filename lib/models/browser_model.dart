import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webpage_dev_console/TaskInfo.dart';
import 'package:webpage_dev_console/models/model_search.dart';
import 'package:webpage_dev_console/models/app_theme.dart';
import 'package:webpage_dev_console/models/favorite_model.dart';
import 'package:webpage_dev_console/models/web_archive_model.dart';
import 'package:webpage_dev_console/models/webview_model.dart';
import 'package:webpage_dev_console/objectbox.g.dart';
import 'package:webpage_dev_console/webview_tab.dart';

import 'search_engine_model.dart';

const debug = false;

class BrowserSettings {
  SearchEngineModel searchEngine;
  bool homePageEnabled;
  String customUrlHomePage;
  bool debuggingEnabled;

  BrowserSettings(
      {this.searchEngine = GoogleSearchEngine,
      this.homePageEnabled = true,
      this.customUrlHomePage = "",
      this.debuggingEnabled = false});

  BrowserSettings copy() {
    return BrowserSettings(
        searchEngine: searchEngine,
        homePageEnabled: homePageEnabled,
        customUrlHomePage: customUrlHomePage,
        debuggingEnabled: debuggingEnabled);
  }

  static BrowserSettings? fromMap(Map<String, dynamic>? map) {
    return map != null
        ? BrowserSettings(
            searchEngine: SearchEngines[map["searchEngineIndex"]],
            homePageEnabled: map["homePageEnabled"],
            customUrlHomePage: map["customUrlHomePage"],
            debuggingEnabled: map["debuggingEnabled"])
        : null;
  }

  Map<String, dynamic> toMap() {
    return {
      "searchEngineIndex": SearchEngines.indexOf(searchEngine),
      "homePageEnabled": homePageEnabled,
      "customUrlHomePage": customUrlHomePage,
      "debuggingEnabled": debuggingEnabled
    };
  }

  Map<String, dynamic> toJson() {
    return toMap();
  }

  @override
  String toString() {
    return toMap().toString();
  }
}

class BrowserModel extends ChangeNotifier {
  final List<WebViewTab> _webViewTabs = [];
  final List<WebViewTab> _incognitowebViewTabs = [];
  final Map<String, WebArchiveModel> _webArchives = {};
  int _currentTabIndex = -1;
  int _incogcurrentTabIndex = -1;
  BrowserSettings _settings = BrowserSettings();
  late WebViewModel _currentWebViewModel;
  LinkedHashMap<String, List<Search>> history = LinkedHashMap();
  LinkedHashMap<String, List<FavoriteModel>> favorites = LinkedHashMap();
  bool _showTabScroller = false;
  LinkedHashMap<String, List<TaskInfo>> _tasks = LinkedHashMap();

  Store? _store;
  Box<Search>? searchbox;
  Box<FavoriteModel>? favouritebox;

  bool adBlockerInitialized = false;

  bool loadingVisible = false;
  late BuildContext loadctx;

  bool _isIncognito = false;

  bool get showTabScroller => _showTabScroller;

  initializeStore() async {
    Directory dir = await getApplicationDocumentsDirectory();
    _store = Store(getObjectBoxModel(), directory: dir.path + "/objectbox");
    searchbox = _store?.box<Search>();
    favouritebox = _store?.box<FavoriteModel>();
  }

  Store? get searchStore => _store;

  set showTabScroller(bool value) {
    if (value != _showTabScroller) {
      _showTabScroller = value;

      notifyListeners();
    }
  }

  bool get isIncognito => _isIncognito;

  setIsIncognito(bool v, BuildContext context) {
    var ct = Provider.of<ChangeTheme>(context, listen: false);
    _isIncognito = v;
    ct.change(_isIncognito ? Brightness.dark : Brightness.light, context);
  }

  set loadingVis(bool v) {
    loadingVisible = v;
  }

  showLoadingDialog(BuildContext context) {
    loadingVisible = true;
    loadctx = context;

    AlertDialog alert = AlertDialog(
      content: new Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
        ],
      ),
    );
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  set addDownloadTask(TaskInfo task) {
    String date = DateFormat.yMMMd().format(DateTime.now());
    if (!_tasks.containsKey(date)) {
      _tasks[date] = [];
    }
    _tasks[date]?.insert(0, task);
  }

  set addListOfDownlods(LinkedHashMap<String, List<TaskInfo>> data) {
    _tasks = data;
  }

  bool get areTasksNotEmpty => _tasks.length != 0;

  LinkedHashMap<String, List<TaskInfo>> get tasks => _tasks;

  BrowserModel(currentWebViewModel) {
    this._currentWebViewModel = currentWebViewModel;
  }

  UnmodifiableListView<WebViewTab> get webViewTabs =>
      UnmodifiableListView(_webViewTabs);

  UnmodifiableListView<WebViewTab> get incognitowebViewTabs =>
      UnmodifiableListView(_incognitowebViewTabs);

  UnmodifiableMapView<String, WebArchiveModel> get webArchives =>
      UnmodifiableMapView(_webArchives);

  void addTab(WebViewTab webViewTab, bool notify) {
    if (webViewTab.webViewModel.isIncognitoMode) {
      print("Adding incognito");
      _incognitowebViewTabs.add(webViewTab);
      _incogcurrentTabIndex = _incognitowebViewTabs.length - 1;
      webViewTab.webViewModel.tabIndex = _incogcurrentTabIndex;

      _currentWebViewModel.updateWithValue(webViewTab.webViewModel);
      webViewTab.webViewModel.setHistory = WebHistory(list: []);
      webViewTab.webViewModel.history?.list?.add(WebHistoryItem());
      webViewTab.webViewModel.curIndex = 0;
      _isIncognito = true;
    } else {
      _webViewTabs.add(webViewTab);
      _currentTabIndex = _webViewTabs.length - 1;
      webViewTab.webViewModel.tabIndex = _currentTabIndex;
      try {
        _currentWebViewModel.updateWithValue(webViewTab.webViewModel);
      } catch (e) {}
      webViewTab.webViewModel.setHistory = WebHistory(list: []);
      webViewTab.webViewModel.history?.list?.add(WebHistoryItem());
      webViewTab.webViewModel.curIndex = 0;
      _isIncognito = false;
    }

    if (notify) notifyListeners();
  }

  void addTabs(List<WebViewTab> webViewTabs) {
    for (var webViewTab in webViewTabs) {
      _webViewTabs.add(webViewTab);
      webViewTab.webViewModel.tabIndex = _webViewTabs.length - 1;
    }
    _currentTabIndex = _webViewTabs.length - 1;
    if (_currentTabIndex >= 0) {
      _currentWebViewModel.updateWithValue(webViewTabs.last.webViewModel);
    }

    notifyListeners();
  }

  void addIncognitoTabs(List<WebViewTab> webViewTabs) {
    print("Adding incog tabs");
    for (var webViewTab in webViewTabs) {
      _incognitowebViewTabs.add(webViewTab);
      webViewTab.webViewModel.tabIndex = _incognitowebViewTabs.length - 1;
    }
    _incogcurrentTabIndex = _incognitowebViewTabs.length - 1;
    notifyListeners();
  }

  void closeTab(int index) {
    _webViewTabs.removeAt(index);
    if (_currentTabIndex == 0 && _webViewTabs.length > 0)
      _currentTabIndex = 0;
    else if (index <= _currentTabIndex) _currentTabIndex = _currentTabIndex - 1;

    for (int i = index; i < _webViewTabs.length; i++) {
      _webViewTabs[i].webViewModel.tabIndex = i;
    }

    if (_currentTabIndex >= 0) {
      _currentWebViewModel
          .updateWithValue(_webViewTabs[_currentTabIndex].webViewModel);
    } else {
      _currentWebViewModel.updateWithValue(WebViewModel());
    }

    notifyListeners();
  }

  void closeIncognitoTab(int index) {
    print("Closing incognito tab");
    _incognitowebViewTabs.removeAt(index);
    if (_incogcurrentTabIndex == 0 && _incognitowebViewTabs.length > 0)
      _incogcurrentTabIndex = 0;
    else if (index <= _incogcurrentTabIndex)
      _incogcurrentTabIndex = _incogcurrentTabIndex - 1;

    for (int i = index; i < _incognitowebViewTabs.length; i++) {
      _incognitowebViewTabs[i].webViewModel.tabIndex = i;
    }

    if (_incogcurrentTabIndex >= 0) {
      _currentWebViewModel.updateWithValue(
          _incognitowebViewTabs[_incogcurrentTabIndex].webViewModel);
    } else {
      _isIncognito = false;
      _currentWebViewModel.updateWithValue(_webViewTabs.length > 0
          ? _webViewTabs[_currentTabIndex].webViewModel
          : WebViewModel());
    }

    notifyListeners();
  }

  void showTab(int index) {
    if (_currentTabIndex != index) {
      _currentTabIndex = index;
      _currentWebViewModel
          .updateWithValue(_webViewTabs[_currentTabIndex].webViewModel);

      notifyListeners();
    }
  }

  void showIncognitoTab(int index) {
    if (_incogcurrentTabIndex != index) {
      _incogcurrentTabIndex = index;
      _currentWebViewModel.updateWithValue(
          _incognitowebViewTabs[_incogcurrentTabIndex].webViewModel);

      notifyListeners();
    }
  }

  void closeAllTabs() {
    _webViewTabs.clear();
    _currentTabIndex = -1;
    _currentWebViewModel.updateWithValue(WebViewModel());

    _incognitowebViewTabs.clear();
    _incogcurrentTabIndex = -1;

    notifyListeners();
  }

  void closeAllIncognitoTabs() {
    _incognitowebViewTabs.clear();
    _incogcurrentTabIndex = -1;

    notifyListeners();
  }

  void requestDownload(
      TaskInfo task, String _localPath, String fileName) async {
    task.taskId = await FlutterDownloader.enqueue(
      url: task.link!,
      savedDir: _localPath,
      fileName: fileName,
      showNotification: true,
      openFileFromNotification: true,
    );
  }

  int getCurrentTabIndex() {
    return _currentTabIndex;
  }

  int getCurrentIncogTabIndex() {
    return _incogcurrentTabIndex;
  }

  WebViewTab? getCurrentTab() {
    return _currentTabIndex >= 0 ? _webViewTabs[_currentTabIndex] : null;
  }

  WebViewTab? getCurrentIncognitoTab() {
    return _incogcurrentTabIndex >= 0
        ? _incognitowebViewTabs[_incogcurrentTabIndex]
        : null;
  }

  bool containsFavorite(FavoriteModel favorite) {
    return (favouritebox
                ?.query(FavoriteModel_.title
                    .equals(favorite.title)
                    .or(FavoriteModel_.url.equals(favorite.url)))
                .build()
                .count() ??
            0) >
        0;
  }

  void addFavorite(FavoriteModel favorite) {
    if (!containsFavorite(favorite)) {
      String date = DateFormat.yMMMd().format(DateTime.now());

      favouritebox?.put(
          FavoriteModel(date: date, url: favorite.url, title: favorite.title));
    }
  }

  void clearFavorites() {
    // favorites.clear();
    favouritebox?.removeAll();
  }

  void removeFavorite(FavoriteModel favorite) {
    // var keys = favorites.keys.toList();
    // for (var k in keys) {
    //   favorites[k]?.removeWhere((f) =>
    //       ((f.title == favorite.title || favorite.title.toString().isEmpty) &&
    //           f.url == favorite.url));
    // }
    favouritebox
        ?.query(FavoriteModel_.title
            .equals(favorite.title)
            .or(FavoriteModel_.url.equals(favorite.url)))
        .build()
        .remove();
  }

  void addWebArchive(String url, WebArchiveModel webArchiveModel) {
    _webArchives.putIfAbsent(url, () => webArchiveModel);

    // notifyListeners();
  }

  void addWebArchives(Map<String, WebArchiveModel> webArchives) {
    _webArchives.addAll(webArchives);

    // notifyListeners();
  }

  void removeWebArchive(WebArchiveModel webArchive) {
    var path = webArchive.path;
    if (path != null) {
      final webArchiveFile = File(path);
      try {
        webArchiveFile.deleteSync();
      } catch (e) {
      } finally {
        _webArchives.remove(webArchive.url.toString());
      }

      // notifyListeners();
    }
  }

  void clearWebArchives() {
    _webArchives.forEach((key, webArchive) {
      var path = webArchive.path;
      if (path != null) {
        final webArchiveFile = File(path);
        try {
          webArchiveFile.deleteSync();
        } catch (e) {
        } finally {
          _webArchives.remove(key);
        }
      }
    });
  }

  BrowserSettings getSettings() {
    return _settings.copy();
  }

  void updateSettings(BrowserSettings settings) {
    _settings = settings;
  }

  void setCurrentWebViewModel(WebViewModel webViewModel) {
    _currentWebViewModel = webViewModel;
  }

  addToHistory(Search search) async {
    if (search.title.isNotEmpty) {
      String date = DateFormat.yMMMd().format(DateTime.now());
      search.date = date;
      if (_store == null) {
        await initializeStore();
      }
      _store
          ?.box<Search>()
          .query(Search_.date
              .equals(date)
              .and(Search_.title.equals(search.title))
              .or(Search_.url.equals(search.url)))
          .build()
          .remove();

      _store?.box<Search>().put(search);
    }
  }

  DateTime _lastTrySave = DateTime.now();
  Timer? _timerSave;
  Future<void> save() async {
    _timerSave?.cancel();

    if (DateTime.now().difference(_lastTrySave) >=
        Duration(milliseconds: 400)) {
      _lastTrySave = DateTime.now();
      await flush();
    } else {
      _lastTrySave = DateTime.now();
      _timerSave = Timer(Duration(milliseconds: 500), () {
        save();
      });
    }
  }

  Future<void> flush() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString("browser", json.encode(toJson()));
  }

  Future<void> restore() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> browserData;
    try {
      browserData =
          await json.decode(prefs.getString("browser")?.toString() ?? "");
    } catch (e) {
      return;
    }

    this.closeAllTabs();
    this.clearWebArchives();

    BrowserSettings settings = BrowserSettings.fromMap(
            browserData["settings"]?.cast<String, dynamic>()) ??
        BrowserSettings();

    // Map<String, dynamic> favList =
    //     browserData["favorites"]?.cast<String, dynamic>() ?? {};
    // for (String key in favList.keys) {
    //   List<dynamic> values = favList[key] ?? [];
    //   this.favorites[key] =
    //       values.map((e) => FavoriteModel.fromMap(e)!).toList();
    // }

    Map<String, dynamic> downloadList =
        browserData["downloads"]?.cast<String, dynamic>() ?? {};
    for (String key in downloadList.keys) {
      List<dynamic> values = downloadList[key] ?? [];
      this._tasks[key] = values.map((e) => TaskInfo.fromMap(e)!).toList();
    }
    List<Map<String, dynamic>> webViewTabList =
        browserData["webViewTabs"]?.cast<Map<String, dynamic>>() ?? [];
    List<WebViewTab> webViewTabs = webViewTabList
        .map((e) => WebViewTab(
              key: GlobalKey(),
              webViewModel: WebViewModel.fromMap(e)!,
            ))
        .toList();
    webViewTabs.sort(
        (a, b) => a.webViewModel.tabIndex!.compareTo(b.webViewModel.tabIndex!));

    this.updateSettings(settings);
    this.addTabs(webViewTabs);
    List<Map<String, dynamic>> incogwebViewTabList =
        browserData["incognitowebViewTabs"]?.cast<Map<String, dynamic>>() ?? [];

    try {
      List<WebViewTab> inwebViewTabs = incogwebViewTabList
          .map((e) => WebViewTab(
                key: GlobalKey(),
                webViewModel: WebViewModel.fromMap(e)!,
              ))
          .toList();
      inwebViewTabs.sort((a, b) =>
          a.webViewModel.tabIndex!.compareTo(b.webViewModel.tabIndex!));

      this.addIncognitoTabs(inwebViewTabs);
    } catch (e) {
      dev.log("ERROR ::: $e");
    }

    int currentTabIndex =
        browserData["currentTabIndex"] ?? this._currentTabIndex;
    _incogcurrentTabIndex =
        browserData["incognitocurrentTabIndex"] ?? this._incogcurrentTabIndex;

    currentTabIndex = min(currentTabIndex, this._webViewTabs.length - 1);

    if (currentTabIndex >= 0) this.showTab(currentTabIndex);
  }

  Map<String, dynamic> toMap() {
    return {
      // "favorites": convertFavoriteToMap(),
      "webViewTabs": _webViewTabs.map((e) => e.webViewModel.toMap()).toList(),
      "incognitowebViewTabs":
          _incognitowebViewTabs.map((e) => e.webViewModel.toMap()).toList(),
      "currentTabIndex": _currentTabIndex,
      "incognitocurrentTabIndex": _incogcurrentTabIndex,
      "settings": _settings.toMap(),
      "currentWebViewModel": _currentWebViewModel.toMap(),
      "downloads": convertDownloadsToMap()
    };
  }

  Map<String, dynamic> toJson() {
    return toMap();
  }

  @override
  String toString() {
    return toMap().toString();
  }

  Map<String, List<Map<String, dynamic>>> convertDownloadsToMap() {
    LinkedHashMap<String, List<Map<String, dynamic>>> res = LinkedHashMap();
    for (String key in _tasks.keys) {
      List<TaskInfo> values = _tasks[key] ?? [];
      res[key] = values.map((e) => e.toMap()).toList();
    }
    return res;
  }

  // Map<String, List<Map<String, dynamic>>> convertFavoriteToMap() {
  //   LinkedHashMap<String, List<Map<String, dynamic>>> res = LinkedHashMap();
  //   for (String key in favorites.keys) {
  //     List<FavoriteModel> values = favorites[key] ?? [];
  //     res[key] = values.map((e) => e.toMap()).toList();
  //   }
  //   return res;
  // }
}
