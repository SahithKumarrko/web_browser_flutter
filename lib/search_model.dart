import 'dart:convert';
import 'dart:math';
import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:webpage_dev_console/helpers.dart';
import 'package:webpage_dev_console/models/model_search.dart';
import 'package:webpage_dev_console/models/browser_model.dart';
import 'package:webpage_dev_console/models/favorite_model.dart';
import 'package:webpage_dev_console/models/webview_model.dart';
import 'package:webpage_dev_console/objectbox.g.dart';

class SearchModel extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<Search> _suggestions = [];
  List<Search> get suggestions => _suggestions;
  void clearS() {
    _suggestions = [];
  }

  String _query = '';
  String get query => _query;
  List<Search> shuffle(List<Search> items) {
    var random = new Random();

    // Go through all elements.
    for (var i = items.length - 1; i > 0; i--) {
      // Pick a pseudorandom number according to the list length
      var n = random.nextInt(i + 1);

      var temp = items[i];
      items[i] = items[n];
      items[n] = temp;
    }

    return items;
  }

  Future<void> onQueryChanged(
      BuildContext context, String query, bool startPage, String url) async {
    _isLoading = true;
    notifyListeners();
    query = query.trim();

    if (query.isNotEmpty) {
      var browserModel = Provider.of<BrowserModel>(context, listen: false);
      var webviewModel = Provider.of<WebViewModel>(context, listen: false);
      var hr = browserModel.searchbox
          ?.query((Search_.title
                  .contains(query, caseSensitive: false)
                  .or(Search_.url.contains(query, caseSensitive: false)))
              .and(Search_.url
                  .notEquals(webviewModel.url == null
                      ? ""
                      : webviewModel.url.toString())
                  .and(Search_.title.notEquals(webviewModel.title == null
                      ? ""
                      : webviewModel.title.toString()))))
          .build();
      List<Search> webHistory = (hr?.find() ?? []).reversed.toSet().toList();

      var q = browserModel.favouritebox
          ?.query((FavoriteModel_.title
                  .contains(query, caseSensitive: false)
                  .or(FavoriteModel_.url.contains(query, caseSensitive: false)))
              .and(FavoriteModel_.url
                  .notEquals(webviewModel.url == null
                      ? ""
                      : webviewModel.url.toString())
                  .and(FavoriteModel_.title.notEquals(webviewModel.title == null
                      ? ""
                      : webviewModel.title.toString()))))
          .build();
      List<FavoriteModel> favorites =
          (q?.find() ?? []).reversed.toSet().toList();
      // var fav = [];
      // for (FavoriteModel i in favorites) {
      //   fav
      //       .add(Search(date: i.date, title: i.title, url: i.url.toLowerCase().contains(url.toLowerCase())
      //               ? ""
      //               : i.url));
      // }

      if (query.isNotEmpty) _query = query;

      try {
        history = [];
        if (!startPage) {
          // for (var h in webHistory) {
          //   history.add(Search(
          //       date: "",
          //       title: h.title,
          //       url: h.url.toLowerCase().contains(url.toLowerCase())
          //           ? ""
          //           : h.url,
          //       isHistory: true,
          //       hashValue: h.title.trim().toLowerCase().hashCode));
          // }
          // history = history.toSet().toList();

          var gurl =
              "https://www.google.com/complete/search?client=hp&hl=en&sugexp=msedr&gs_rn=62&gs_ri=hp&cp=1&gs_id=9c&q=$query&xhr=t";
          final response = await http.get(Uri.parse(gurl));
          final body = json.decode(utf8.decode(response.bodyBytes));
          List<Search> results = [];
          var r = body[1];
          int qhv = query.trim().toLowerCase().hashCode;
          for (var i in r) {
            var tit = Helper.htmlToString(i[0].toString()).trim().toLowerCase();
            if (tit.replaceAll(query, "").trim() != "") {
              var ttt = tit.hashCode;
              bool found = false;
              if (history.length != 0) {
                for (var element in history) {
                  if (element.hashValue != -1 &&
                      (element.hashValue == ttt || ttt == qhv)) {
                    found = true;
                    break;
                  }
                }
                if (!found) {
                  results
                      .add(Search(date: "", url: "", title: i[0].toString()));
                  continue;
                }
              }
              if (history.isEmpty && ttt != query.trim().toLowerCase().hashCode)
                results.add(Search(date: "", url: "", title: i[0].toString()));
            }
          }

          var hl = webHistory.length;
          var rl = results.length;
          var fl = favorites.length;
          var occ = rl >= 4 ? 4 : rl;
          var av = (8 - occ);
          var s1 = (av / 2).round();
          hl = hl >= s1 ? s1 : hl;
          fl = (fl > 0) ? ((fl % av + 1) - hl) : 0;
          if ((hl + fl) != av) {
            var free = (av - (hl + fl));
            hl = hl +
                ((webHistory.length - hl) >= free
                    ? free
                    : webHistory.length - hl);
          }

          if ((hl + fl) != av) {
            var free = (av - (hl + fl));
            fl = fl +
                ((favorites.length - fl) >= free
                    ? free
                    : favorites.length - fl);
          }

          if ((hl + fl) != av) {
            var free = (av - (hl + fl));
            occ = occ +
                ((results.length - occ) >= free ? free : results.length - occ);
          }

          history.addAll(webHistory.sublist(0, hl));
          history.addAll(favorites
              .sublist(0, fl)
              .map((e) => Search(date: e.date, title: e.title, url: e.url)));
          history.addAll(results.sublist(0, occ));

          history = history.toSet().toList();
        }
        _suggestions = history;
      } catch (e) {
        print("error : " + e.toString());
      }
    } else {
      _suggestions = [];
    }
    _isLoading = false;
    notifyListeners();
  }

  void clear() {
    _suggestions = [];
    notifyListeners();
  }
}

List<Search> history = [];
