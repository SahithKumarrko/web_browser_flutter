import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webpage_dev_console/TaskInfo.dart';
import 'package:webpage_dev_console/model_search.dart';
import 'package:webpage_dev_console/models/app_theme.dart';
import 'package:webpage_dev_console/models/favorite_model.dart';
import 'package:webpage_dev_console/models/web_archive_model.dart';
import 'package:webpage_dev_console/models/webview_model.dart';
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

  bool loadingVisible = false;
  late BuildContext loadctx;

  bool _isIncognito = false;

  bool get showTabScroller => _showTabScroller;

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
          // Container(
          //   margin: EdgeInsets.only(left: 18),
          //   child: Text("Loading..."),
          // ),
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

  // updateDownloadTask(String? id, DownloadTaskStatus? status, int? progress) {
  //   if (_tasks != null && _tasks!.isNotEmpty) {
  //     final task = _tasks!.firstWhere((_task) => _task.taskId == id);

  //     task.status = status;
  //     task.progress = progress;
  //     // notifyListeners();
  //   }
  // }

  LinkedHashMap<String, List<TaskInfo>> get tasks => _tasks;

  BrowserModel(currentWebViewModel) {
    this._currentWebViewModel = currentWebViewModel;
  }

  UnmodifiableListView<WebViewTab> get webViewTabs =>
      UnmodifiableListView(_webViewTabs);

  UnmodifiableListView<WebViewTab> get incognitowebViewTabs =>
      UnmodifiableListView(_incognitowebViewTabs);

  // UnmodifiableListView<FavoriteModel> get favorites =>
  //     UnmodifiableListView(_favorites);

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

    // if (_incogcurrentTabIndex >= 0) {
    //   _currentWebViewModel.updateWithValue(webViewTabs.last.webViewModel);
    // }
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
    // if (_webViewTabs.length == 1) {
    //   print("Changing");
    //   var settings = getSettings();

    //   addTab(
    //       WebViewTab(
    //         key: GlobalKey(),
    //         webViewModel:
    //             WebViewModel(url: Uri.parse(settings.searchEngine.searchUrl)),
    //       ),
    //       false);
    //   // return SizedBox.shrink();
    //   print("yup");
    // }
    _webViewTabs.removeAt(index);
    _currentTabIndex = _webViewTabs.length - 1;

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
    // if (_webViewTabs.length == 1) {
    //   print("Changing");
    //   var settings = getSettings();

    //   addTab(
    //       WebViewTab(
    //         key: GlobalKey(),
    //         webViewModel:
    //             WebViewModel(url: Uri.parse(settings.searchEngine.searchUrl)),
    //       ),
    //       false);
    //   // return SizedBox.shrink();
    //   print("yup");
    // }
    print("Closing incognito tab");
    _incognitowebViewTabs.removeAt(index);
    _incogcurrentTabIndex = _incognitowebViewTabs.length - 1;

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
    var keys = favorites.keys.toList();
    for (var k in keys) {
      for (FavoriteModel f in (favorites[k] ?? [])) {
        if ((f.title == favorite.title || favorite.title.toString().isEmpty) &&
            f.url == favorite.url) {
          return true;
        }
      }
    }
    return false;
  }

  void addFavorite(FavoriteModel favorite) {
    dev.log(favorites.toString());
    if (!containsFavorite(favorite)) {
      print("uuu");
      String date = DateFormat.yMMMd().format(DateTime.now());
      if (!favorites.containsKey(date)) {
        favorites[date] = [];
      }
      favorites[date]?.insert(0, favorite);
    }
  }

  // void addFavorites(List<FavoriteModel> favorites) {
  //   _favorites.addAll(favorites);

  //   // notifyListeners();
  // }

  void clearFavorites() {
    favorites.clear();

    // notifyListeners();
  }

  void removeFavorite(FavoriteModel favorite) {
    var keys = favorites.keys.toList();
    for (var k in keys) {
      favorites[k]?.removeWhere((f) =>
          ((f.title == favorite.title || favorite.title.toString().isEmpty) &&
              f.url == favorite.url));
    }
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

    // notifyListeners();
  }

  BrowserSettings getSettings() {
    return _settings.copy();
  }

  void updateSettings(BrowserSettings settings) {
    _settings = settings;

    // notifyListeners();
  }

  void setCurrentWebViewModel(WebViewModel webViewModel) {
    _currentWebViewModel = webViewModel;
  }

  addToHistory(Search search) {
    if (search.title.isNotEmpty) {
      String date = DateFormat.yMMMd().format(DateTime.now());
      for (Search s in history[date] ?? []) {
        if (s.title.compareTo(search.title) == 0 ||
            s.url.toString().compareTo(search.url.toString()) == 0) {
          history[date]?.remove(s);

          break;
        }
      }
      if (!history.containsKey(date)) {
        history[date] = [];
      }
      history[date]?.insert(0, search);
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

    // this.clearFavorites();
    this.closeAllTabs();
    this.clearWebArchives();

    // List<Map<String, dynamic>> favoritesList =
    //     browserData["favorites"]?.cast<Map<String, dynamic>>() ?? [];
    // List<FavoriteModel> favorites =
    //     favoritesList.map((e) => FavoriteModel.fromMap(e)!).toList();

    // Map<String, dynamic> webArchivesMap =
    //     browserData["webArchives"]?.cast<String, dynamic>() ?? {};
    // Map<String, WebArchiveModel> webArchives = webArchivesMap.map(
    //     (key, value) => MapEntry(
    //         key, WebArchiveModel.fromMap(value?.cast<String, dynamic>())!));

    BrowserSettings settings = BrowserSettings.fromMap(
            browserData["settings"]?.cast<String, dynamic>()) ??
        BrowserSettings();
    Map<String, dynamic> historyList =
        browserData["history"]?.cast<String, dynamic>() ?? {};
    // this.history = historyList.map((e) => Search.fromMap(e)!).toList();
    for (String key in historyList.keys) {
      List<dynamic> values = historyList[key] ?? [];
      this.history[key] = values.map((e) => Search.fromMap(e)!).toList();
    }

    Map<String, dynamic> favList =
        browserData["favorites"]?.cast<String, dynamic>() ?? {};
    // this.history = historyList.map((e) => Search.fromMap(e)!).toList();
    for (String key in favList.keys) {
      List<dynamic> values = favList[key] ?? [];
      this.favorites[key] =
          values.map((e) => FavoriteModel.fromMap(e)!).toList();
    }

    Map<String, dynamic> downloadList =
        browserData["downloads"]?.cast<String, dynamic>() ?? {};
    // this.history = historyList.map((e) => Search.fromMap(e)!).toList();
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

    // this.addFavorites(favorites);
    // this.addWebArchives(webArchives);
    this.updateSettings(settings);
    this.addTabs(webViewTabs);
    dev.log("DAta :::::  ${browserData["incognitowebViewTabs"]}");
    List<Map<String, dynamic>> incogwebViewTabList =
        browserData["incognitowebViewTabs"]?.cast<Map<String, dynamic>>() ?? [];
    dev.log("CCCCCCCC :::::::  $incogwebViewTabList");
    try {
      List<WebViewTab> inwebViewTabs = incogwebViewTabList
          .map((e) => WebViewTab(
                key: GlobalKey(),
                webViewModel: WebViewModel.fromMap(e)!,
              ))
          .toList();
      print("got inco data");
      inwebViewTabs.sort((a, b) =>
          a.webViewModel.tabIndex!.compareTo(b.webViewModel.tabIndex!));
      print("completed sorting");
      dev.log("TABS :::::::::::   $inwebViewTabs");
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
    // if (initialRestore) {
    //   var hm = Provider.of<HelperModel>(context, listen: false);
    //   Future.delayed(Duration(seconds: 5), () => hm.restored = true);
    // }
  }

  Map<String, dynamic> toMap() {
    return {
      "favorites": convertFavoriteToMap(),
      "webViewTabs": _webViewTabs.map((e) => e.webViewModel.toMap()).toList(),
      "incognitowebViewTabs":
          _incognitowebViewTabs.map((e) => e.webViewModel.toMap()).toList(),
      // "webArchives":
      //     _webArchives.map((key, value) => MapEntry(key, value.toMap())),
      "currentTabIndex": _currentTabIndex,
      "incognitocurrentTabIndex": _incogcurrentTabIndex,
      "settings": _settings.toMap(),
      "currentWebViewModel": _currentWebViewModel.toMap(),
      "history": convertSearchToMap(),
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

  Map<String, List<Map<String, dynamic>>> convertSearchToMap() {
    LinkedHashMap<String, List<Map<String, dynamic>>> res = LinkedHashMap();
    for (String key in history.keys) {
      List<Search> values = history[key] ?? [];
      res[key] = values.map((e) => e.toMap()).toList();
    }
    return res;
  }

  Map<String, List<Map<String, dynamic>>> convertFavoriteToMap() {
    LinkedHashMap<String, List<Map<String, dynamic>>> res = LinkedHashMap();
    for (String key in favorites.keys) {
      List<FavoriteModel> values = favorites[key] ?? [];
      res[key] = values.map((e) => e.toMap()).toList();
    }
    return res;
  }
}
