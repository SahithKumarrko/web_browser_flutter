import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:implicitly_animated_reorderable_list/implicitly_animated_reorderable_list.dart';
import 'package:material_floating_search_bar/material_floating_search_bar.dart';
import 'package:provider/provider.dart';
import 'package:webpage_dev_console/custom_image.dart';
import 'package:webpage_dev_console/helpers.dart';
import 'package:webpage_dev_console/model_search.dart';
import 'package:webpage_dev_console/models/browser_model.dart';
import 'package:webpage_dev_console/models/webview_model.dart';
import 'package:webpage_dev_console/search_model.dart';
import 'package:webpage_dev_console/util.dart';

class SearchPage extends StatefulWidget {
  SearchPage({Key? key}) : super(key: key);

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  bool isFocused = false;
  FloatingSearchBarController searchController = FloatingSearchBarController();
  int _index = 0;
  bool loaded = false;
  String copiedContents = "";
  int get index => _index;
  set index(int value) {
    _index = min(value, 2);
    _index == 2 ? searchController.hide() : searchController.show();

    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      searchController.open();
      Future.delayed(Duration(milliseconds: 700), () {
        this.setState(() {
          this.loaded = true;
        });
      });
    });
  }

  bool changed = true;
  String curTitle = "";
  String query = "";
  String sTitle = "";
  void focusChanged() async {
    if (!isFocused) {
      var browserModel = Provider.of<BrowserModel>(context, listen: false);
      var webViewModel = browserModel.getCurrentTab()?.webViewModel;
      var _webViewController = webViewModel?.webViewController;

      searchController.query =
          (await _webViewController?.getUrl())?.toString() ?? "";
    }
  }

  void searchQuery(String qurl) {
    // searchController.close();
    var browserModel = Provider.of<BrowserModel>(context, listen: false);
    var settings = browserModel.getSettings();

    var webViewModel = Provider.of<WebViewModel>(context, listen: false);
    var _webViewController = webViewModel.webViewController;
    var url = Uri.parse(qurl);
    if (!url.scheme.startsWith("http") && !Util.isLocalizedContent(url)) {
      url = Uri.parse(settings.searchEngine.searchUrl + qurl.trim());
    }

    if (_webViewController != null) {
      _webViewController.loadUrl(urlRequest: URLRequest(url: url));
      var ww = browserModel.getCurrentTab()?.webViewModel;
      var whl = (ww?.history?.list?.length ?? 0);
      if (whl > 0) {
        if (whl - 1 != ww?.curIndex) {
          ww?.history?.list?.removeRange(ww.curIndex + 1, whl);
        }
        ww?.history?.list?.add(WebHistoryItem());
        ww?.curIndex = ww.curIndex + 1;
        var ci = ww?.curIndex;
        var whh = ww?.history;
        print("HI-S :: $ci :: $whh");
        browserModel.save();
      }
    } else {
      Helper.addNewTab(url: url, context: context);
      webViewModel.url = url;
    }
  }

  bool _validURL = false;
  void getCopiedContents() async {
    ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    _validURL = false;

    // try {
    //   _validURL = Uri.parse(data?.text.toString() ?? "").isAbsolute;
    // } catch (e) {}
    String cpdata = data?.text.toString() ?? "";
    cpdata = cpdata.trim();
    if (cpdata.toLowerCase().startsWith(RegExp("http[s]{0,1}:[/]{2}")) ||
        cpdata.toLowerCase().startsWith(RegExp("ws:[/]{2}"))) {
      _validURL = true;
    }
    if (_validURL)
      setState(() {
        copiedContents = data?.text.toString() ?? "";
      });
    else
      copiedContents = "";
  }

  void handleSearch(String q) {
    print("Querying" + q);

    searchQuery(q);
    Navigator.pop(context);
  }

  Widget buildInitialSearchPage(BrowserSettings settings) {
    getCopiedContents();
    var _webViewModel = Provider.of<WebViewModel>(context, listen: true);
    return (_webViewModel.url == null ||
            _webViewModel.title.toString().isEmpty ||
            _webViewModel.title == null)
        ? SizedBox.shrink()
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              copiedContents != "" &&
                      _validURL &&
                      copiedContents.compareTo(_webViewModel.url.toString()) !=
                          0
                  ? InkWell(
                      onTap: () {
                        handleSearch(copiedContents);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: 8,
                            ),
                            Text(
                              "Go to the link that you copied",
                              style:
                                  TextStyle(color: Colors.black, fontSize: 16),
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    copiedContents,
                                    style: TextStyle(
                                        color: Colors.blue,
                                        overflow: TextOverflow.fade,
                                        fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(
                              height: 8,
                            ),
                            Divider(
                              color: Colors.black54,
                            ),
                          ],
                        ),
                      ),
                    )
                  : SizedBox.shrink(),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _webViewModel.url != null
                            ? InkWell(
                                onTap: () =>
                                    handleSearch(_webViewModel.url.toString()),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    CustomImage(
                                        url: _webViewModel.url
                                                .toString()
                                                .startsWith(RegExp(
                                                    "http[s]{0,1}:[/]{2}"))
                                            ? Uri.parse((_webViewModel
                                                        .url?.origin ??
                                                    settings.searchEngine.url) +
                                                "/favicon.ico")
                                            : null,
                                        maxWidth: 24.0,
                                        height: 24.0)
                                  ],
                                ),
                              )
                            : InkWell(
                                onTap: () =>
                                    handleSearch(_webViewModel.url.toString()),
                                child: SizedBox(
                                    width: 24,
                                    child: Icon(Icons.search,
                                        key: Key('lsearch'))),
                              ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: InkWell(
                            onTap: () =>
                                handleSearch(_webViewModel.url.toString()),
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Html(
                                  data: _webViewModel.title.toString(),
                                  style: {
                                    "body": Style(
                                        fontSize: _webViewModel.url != null
                                            ? FontSize(16)
                                            : FontSize(18),
                                        fontWeight: _webViewModel.url != null
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        textOverflow: TextOverflow.ellipsis),
                                  },
                                ),
                                _webViewModel.url != null
                                    ? Padding(
                                        padding:
                                            const EdgeInsets.only(left: 8.0),
                                        child: Text(
                                          _webViewModel.url.toString(),
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                              fontSize: 14, color: Colors.blue),
                                        ),
                                      )
                                    : SizedBox.shrink(),
                              ],
                            ),
                          ),
                        ),
                        //   ],
                        // ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              iconSize: 20,
                              onPressed: () {
                                Helper.share(context);
                              },
                              icon: FaIcon(
                                FontAwesomeIcons.shareAlt,
                                color: Colors.black.withOpacity(0.7),
                              ),
                            ),
                            IconButton(
                              iconSize: 24,
                              onPressed: () {
                                Clipboard.setData(ClipboardData(
                                    text: _webViewModel.url.toString()));
                                // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                //   content: Text("Copied!"),
                                // ));
                                Helper.showBasicFlash(
                                    duration: Duration(seconds: 2),
                                    msg: "Copied!",
                                    context: context);
                              },
                              icon: FaIcon(
                                FontAwesomeIcons.copy,
                                color: Colors.black.withOpacity(0.7),
                              ),
                            ),
                            IconButton(
                              iconSize: 24,
                              onPressed: () {
                                setState(() {
                                  changed = true;
                                });

                                searchController.query =
                                    _webViewModel.url.toString();
                              },
                              icon: FaIcon(
                                FontAwesomeIcons.pencilAlt,
                                color: Colors.black.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Divider(
                      color: Colors.black54,
                    ),
                  ],
                ),
              ),
            ],
          );
  }

  Widget _buildSearchTextField() {
    var browserModel = Provider.of<BrowserModel>(context, listen: false);
    var settings = browserModel.getSettings();

    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;

    return Consumer<SearchModel>(
      builder: (context, model, _) => FloatingSearchBar(
        automaticallyImplyBackButton: false,
        controller: searchController,
        clearQueryOnClose: false,
        hint: "Search for or type a web address",
        iconColor: Colors.black54,
        backdropColor: Colors.grey,
        textInputType: TextInputType.url,
        queryStyle: TextStyle(fontSize: 18),
        padding: EdgeInsets.only(left: 0, right: 0),
        leadingActions: <Widget>[
          IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: FaIcon(FontAwesomeIcons.arrowLeft))
        ],
        transitionDuration: const Duration(milliseconds: 200),
        transitionCurve: Curves.easeInOutCubic,
        physics: const BouncingScrollPhysics(),
        axisAlignment: isPortrait ? 0.0 : -1.0,
        openAxisAlignment: 0.0,
        actions: [
          FloatingSearchBarAction.searchToClear(
            showIfClosed: false,
          ),
        ],
        progress: model.isLoading,
        debounceDelay: const Duration(milliseconds: 300),
        onQueryChanged: (q) {
          if (isFocused) {
            model.onQueryChanged(
                context,
                ((q.toLowerCase().startsWith("https://") ||
                            q.toLowerCase().startsWith("http://")) &&
                        q.toLowerCase().contains(query.toLowerCase()))
                    ? query
                    : q,
                searchController.query.isEmpty,
                settings.searchEngine.url);
          }
          changed = true;
        },
        scrollPadding: EdgeInsets.zero,
        transition: ExpandingFloatingSearchBarTransition(),
        builder: (context, _) => buildExpandableBody(model, settings),
        body: buildBody(),
        onFocusChanged: (_isFocused) async {
          isFocused = _isFocused;

          changed = false;

          if (_isFocused) {
            searchController.query = "";
          } else {
            Navigator.pop(context);
          }
          // var title = await _webViewController!.getTitle();

          focusChanged();
        },
        onSubmitted: (value) {
          FloatingSearchBar.of(context)?.close();
          Future.delayed(
            const Duration(milliseconds: 200),
            () => model.clear(),
          );
          // searchController.query = Helper.htmlToString(value);
          // query = searchController.query;
          searchQuery(Helper.htmlToString(value));
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget buildExpandableBody(SearchModel model, BrowserSettings settings) {
    return Column(
      children: [
        (changed == false || searchController.query.isEmpty) && loaded
            ? buildInitialSearchPage(settings)
            : SizedBox.shrink(),
        (changed == false || searchController.query.isEmpty) && loaded
            ? SizedBox.shrink()
            : Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Material(
                  color: Colors.white,
                  elevation: 4.0,
                  borderRadius: BorderRadius.circular(8),
                  child: ImplicitlyAnimatedList<Search>(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    items: model.suggestions.take(8).toList(),
                    areItemsTheSame: (a, b) =>
                        Helper.htmlToString(a.title).toLowerCase().compareTo(
                            Helper.htmlToString(b.title).toLowerCase()) ==
                        0,
                    itemBuilder: (context, animation, search, i) {
                      return search.title.isEmpty
                          ? SizedBox.shrink()
                          : buildItem(context, search, settings);
                    },
                    updateItemBuilder: (context, animation, search) {
                      return search.title.isEmpty
                          ? SizedBox.shrink()
                          : buildItem(context, search, settings);
                    },
                  ),
                ),
              ),
      ],
    );
  }

  Widget buildItem(
      BuildContext context, Search search, BrowserSettings settings) {
    final model = Provider.of<SearchModel>(context, listen: false);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () {
            FloatingSearchBar.of(context)?.close();
            Future.delayed(
              const Duration(milliseconds: 200),
              () => model.clear(),
            );
            // searchController.query = Helper.htmlToString(search.title);
            // query = searchController.query;
            searchQuery(Helper.htmlToString(
                search.url != null ? search.url.toString() : search.title));
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                search.url != null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          CustomImage(
                              url: search.url
                                      .toString()
                                      .startsWith(RegExp("http[s]{0,1}:[/]{2}"))
                                  ? Uri.parse((search.url?.origin ??
                                          settings.searchEngine.url) +
                                      "/favicon.ico")
                                  : null,
                              maxWidth: 24.0,
                              height: 24.0)
                        ],
                      )
                    : search.isHistory
                        ? SizedBox(
                            width: 24,
                            child: Icon(Icons.history, key: Key('history')))
                        : SizedBox(
                            width: 24,
                            child: Icon(Icons.search, key: Key('search'))),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Html(
                        data: search.title,
                        style: {
                          "body": Style(
                              fontSize: search.url != null
                                  ? FontSize(16)
                                  : FontSize(18),
                              fontWeight: search.url != null
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              textOverflow: TextOverflow.ellipsis),
                        },
                      ),
                      search.url != null
                          ? Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Text(
                                search.url.toString(),
                                overflow: TextOverflow.ellipsis,
                                style:
                                    TextStyle(fontSize: 14, color: Colors.blue),
                              ),
                            )
                          : SizedBox(),
                    ],
                  ),
                ),
                //   ],
                // ),
                SizedBox(
                  width: 24,
                  child: IconButton(
                    onPressed: () {
                      searchController.query = search.url != null
                          ? search.url!.toString()
                          : Helper.htmlToString(search.title);
                    },
                    icon: Icon(
                      Icons.north_west_rounded,
                      color: Colors.black.withOpacity(0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (model.suggestions.isNotEmpty && search != model.suggestions.last)
          const Divider(height: 0),
      ],
    );
  }

  Widget buildBody() {
    return Column(
      children: [
        Expanded(
          child: IndexedStack(
            index: min(index, 2),
            children: [
              FloatingSearchAppBar(
                color: Colors.white,
                transitionDuration: const Duration(milliseconds: 600),
                body: Container(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SearchModel(),
      child: SafeArea(
        child: WillPopScope(
          onWillPop: () async {
            Navigator.pop(context);
            return false;
          },
          child: Scaffold(
            backgroundColor: Colors.white,
            resizeToAvoidBottomInset: false,
            body: _buildSearchTextField(),
          ),
        ),
      ),
    );
  }
}
