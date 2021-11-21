import 'dart:convert';
import 'dart:math';
import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:webpage_dev_console/helpers.dart';
import 'package:webpage_dev_console/model_search.dart';
import 'package:webpage_dev_console/models/browser_model.dart';
import 'package:webpage_dev_console/models/favorite_model.dart';

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
    // if (query == _query && _query.isNotEmpty) return;

    _isLoading = true;
    notifyListeners();
    query = query.trim();

    if (query.isNotEmpty) {
      var browserModel = Provider.of<BrowserModel>(context, listen: false);
      var sortedKeys = browserModel.history.keys.toList().reversed;
      List<Search> webHistory = [];
      for (String key in sortedKeys) {
        List<Search> res = browserModel.history[key] ?? [];
        webHistory.addAll(res);
      }
      for (String key in browserModel.favorites.keys.toList().reversed) {
        List<FavoriteModel> res = browserModel.favorites[key] ?? [];
        for (FavoriteModel i in res) {
          webHistory.add(Search(title: i.title.toString(), url: i.url));
        }
      }

      if (query.isNotEmpty) _query = query;

      try {
        history = [];
        if (!startPage) {
          for (var i = webHistory.length; i > 0; i--) {
            Search h = webHistory.elementAt(i - 1);
            if (h.title.length != 0) {
              String hTitle = Helper.getTitle(h.title);
              List<String> lq = query.split(" ");
              bool y = false, y2 = false;
              bool isHome =
                  h.url.toString().toLowerCase().startsWith(url.toLowerCase());

              for (String qq in lq) {
                if ((hTitle.toLowerCase().contains(qq) || qq.isEmpty) &&
                    !hTitle
                        .toString()
                        .toLowerCase()
                        .startsWith(url.toLowerCase())) y = true;
                if (h.url!.toString().toLowerCase().contains(qq) && !isHome)
                  y2 = true;
              }
              // dev.log("L1 :: $query :: ${h.url} :: $isHome :: $y :: $y2");
              if (y || y2) {
                history.add(new Search(
                    title: hTitle,
                    url: (isHome && !startPage) ? null : h.url,
                    isHistory: true));
              }
            }
          }
          history = history.toSet().toList();
          var gurl =
              "https://www.google.com/complete/search?client=hp&hl=en&sugexp=msedr&gs_rn=62&gs_ri=hp&cp=1&gs_id=9c&q=$query&xhr=t";
          final response = await http.get(Uri.parse(gurl));
          final body = json.decode(utf8.decode(response.bodyBytes));
          List<Search> results = [];
          var r = body[1];
          // dev.log("$r");
          for (var i in r) {
            var ttt = Helper.htmlToString(i[0].toString()).trim().toLowerCase();
            bool found = false;
            if (history.length != 0) {
              for (var element in history) {
                // dev.log(
                //     "PP :: ${Helper.htmlToString(element.title).trim().toLowerCase()} :: ${Helper.htmlToString(i[0].toString()).trim().toLowerCase()}");
                if (Helper.htmlToString(element.title).trim().toLowerCase() ==
                        ttt ||
                    ttt == query.trim().toLowerCase()) {
                  found = true;
                  break;
                }
              }
              // dev.log("PP :: $found");
              if (!found) {
                results.add(Search(title: i[0].toString()));
                continue;
              }
            }
            if (history.length == 0 && ttt != query.trim().toLowerCase())
              results.add(Search(title: i[0].toString()));
          }

          // dev.log("$results");

          var hl = history.length;
          history = history.sublist(0, hl >= 4 ? 4 : hl);
          history.addAll(results.sublist(0, results.length - history.length));

          history = history.toSet().toList();
        }
        _suggestions = history;
        dev.log("${history.length}");
      } catch (e) {
        // print("error : " + e.toString());
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
