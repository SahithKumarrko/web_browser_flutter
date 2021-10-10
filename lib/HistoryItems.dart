import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:webpage_dev_console/custom_image.dart';
import 'package:webpage_dev_console/history.dart';
import 'package:webpage_dev_console/models/browser_model.dart';
import 'package:webpage_dev_console/util.dart';

import 'models/webview_model.dart';

class HistoryList extends StatefulWidget {
  final List<HItem> data;
  final GlobalKey<AnimatedListState> listKey;
  final BrowserModel browserModel;
  final BrowserSettings settings;
  final void Function({Uri? url}) addNewTab;
  final Map<String, List<int>> items;

  HistoryList({
    required this.data,
    required this.listKey,
    Key? key,
    required this.browserModel,
    required this.settings,
    required this.items,
    required this.addNewTab,
  }) : super(key: key);

  @override
  _HistoryListState createState() => _HistoryListState();
}

class _HistoryListState extends State<HistoryList> {
  late HItem ritem;
  String curDate = "";
  bool isRemoved = false;
  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: 1,
      duration: Duration(seconds: 1),
      child: AnimatedList(
        key: widget.listKey,
        initialItemCount: widget.data.length,
        itemBuilder: (context, index, animation) {
          HItem item = widget.data.elementAt(index);

          return Column(children: [_buildItem(item, index, animation)]);
        },
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
                                              widget
                                                  .settings.searchEngine.url) +
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
                                ritem = widget.data.removeAt(index);
                                for (int i = 0; i < widget.data.length; i++) {
                                  if (widget.data[i].search == null) {
                                    widget.items[widget.data[i].date]![1] = i;
                                  }
                                }
                                AnimatedListRemovedItemBuilder builder =
                                    (context, animation) {
                                  // A method to build the Card widget.

                                  var browserModel = Provider.of<BrowserModel>(
                                      context,
                                      listen: false);

                                  browserModel.history[ritem.date] = widget.data
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
                                  widget.items[ritem.date]![0] =
                                      (widget.items[ritem.date]![0] - 1);
                                  ritem.isDeleted = true;

                                  return _buildItem(ritem, index, animation);
                                };
                                widget.listKey.currentState
                                    ?.removeItem(index, builder);

                                if (widget.items[ritem.date]![0] <= 1) {
                                  AnimatedListRemovedItemBuilder builder2 =
                                      (context, animation) {
                                    return _buildItem(
                                        widget.data.removeAt(
                                            widget.items[ritem.date]![1]),
                                        widget.items[ritem.date]![1],
                                        animation);
                                  };
                                  widget.listKey.currentState?.removeItem(
                                      widget.items[ritem.date]![1], builder2);
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
