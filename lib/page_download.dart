import 'dart:collection';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_html/shims/dart_ui_real.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:webpage_dev_console/TaskInfo.dart';
import 'package:webpage_dev_console/c_popmenuitem.dart';
import 'package:webpage_dev_console/custom_image.dart';
import 'package:webpage_dev_console/helpers.dart';
import 'package:webpage_dev_console/model_search.dart';
import 'package:webpage_dev_console/models/browser_model.dart';
import 'package:webpage_dev_console/models/webview_model.dart';
import 'package:webpage_dev_console/tab_viewer_popup_menu_actions.dart';
import 'package:webpage_dev_console/util.dart';

bool showSearchField = false;
GlobalKey clearAllSwitcher = GlobalKey();
List<DItem> _data = [];

List<DItem> _selectedList = [];
GlobalKey<AnimatedListState> _listKey = GlobalKey();

TextEditingController txtc = TextEditingController();
GlobalKey nohist = GlobalKey();
bool longPressed = false;
late BrowserModel browserModel;
late BrowserSettings settings;
String curDate = "";
bool isRemoved = false;
Map<String, List<int>> items = {};
late DItem ritem;
GlobalKey appBarKey = GlobalKey();

class DItem {
  String date;
  TaskInfo? task;
  bool isDeleted;
  GlobalKey? key;
  bool isSelected;
  DItem(
      {required this.date,
      required this.task,
      this.isDeleted = false,
      this.isSelected = false,
      this.key});

  @override
  String toString() =>
      'DItem(title: $date,taskId: ${task?.taskId}, url: ${task?.link},"name":${task?.name},isSelected : $isSelected,"name":${task?.name})';
}

class CAS extends StatefulWidget {
  final Function() buildDownloadList;
  final Function() buildNoHistory;
  CAS({required this.buildDownloadList, required this.buildNoHistory, Key? key})
      : super(key: key);

  @override
  _CASState createState() => _CASState();
}

class _CASState extends State<CAS> {
  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: Duration(milliseconds: 300),
      child: (_data.length > 1)
          ? widget.buildDownloadList()
          : widget.buildNoHistory(),
    );
  }
}

class PageDownload extends StatefulWidget {
  PageDownload({
    Key? key,
  }) : super(key: key) {
    _selectedList = [];
    longPressed = false;
  }

  @override
  _PageDownloadState createState() => _PageDownloadState();
}

class _PageDownloadState extends State<PageDownload> {
  Future initialize(BuildContext context) async {
    // This is where you can initialize the resources needed by your app while
    // the splash screen is displayed.  Remove the following example because
    // delaying the user experience is a bad design practice!
    await Future.delayed(const Duration(seconds: 1), () async {
      generateHistoryValues("", false);
      bindBackgroundIsolate();
      FlutterDownloader.registerCallback(downloadCallback);
    });
  }

  late String _localPath;
  late bool _permissionReady;
  ReceivePort _port = ReceivePort();
  List<TaskInfo>? _tasks = [];

  @override
  void dispose() {
    super.dispose();
    unbindBackgroundIsolate();
  }

  @override
  void initState() {
    super.initState();

    browserModel = Provider.of<BrowserModel>(context, listen: false);

    settings = browserModel.getSettings();
  }

  void _cancelDownload(TaskInfo task) async {
    await FlutterDownloader.cancel(taskId: task.taskId!);
  }

  void _pauseDownload(TaskInfo task) async {
    await FlutterDownloader.pause(taskId: task.taskId!);
  }

  void _resumeDownload(TaskInfo task) async {
    String? newTaskId = await FlutterDownloader.resume(taskId: task.taskId!);
    task.taskId = newTaskId;
  }

  void _retryDownload(TaskInfo task) async {
    String? newTaskId = await FlutterDownloader.retry(taskId: task.taskId!);
    task.taskId = newTaskId;
  }

  void bindBackgroundIsolate() {
    bool isSuccess = IsolateNameServer.registerPortWithName(
        _port.sendPort, 'downloader_send_port');
    if (!isSuccess) {
      unbindBackgroundIsolate();
      bindBackgroundIsolate();
      return;
    }
    _port.listen((dynamic data) {
      if (debug) {
        print('UI Isolate Callback: $data');
      }
      String? id = data[0];
      DownloadTaskStatus? status = data[1];
      int? progress = data[2];
      if (_tasks != null && _tasks!.isNotEmpty) {
        final task = _tasks!.firstWhere((_task) => _task.taskId == id);

        task.status = status;
        task.progress = progress;
        task.key?.currentState?.setState(() {});
      }
    });
  }

  void unbindBackgroundIsolate() {
    IsolateNameServer.removePortNameMapping('downloader_send_port');
  }

  static void downloadCallback(
      String id, DownloadTaskStatus status, int progress) {
    if (debug) {
      print(
          'Background Isolate Callback: task ($id) is in status ($status) and process ($progress)');
    }
    final SendPort send =
        IsolateNameServer.lookupPortByName('downloader_send_port')!;
    send.send([id, status, progress]);
  }

  generateHistoryValues(String searchValue, bool needUpdate) {
    var keys = browserModel.tasks.keys.toList().reversed;
    int ind = 0;
    _data = [];
    items = {};
    searchValue = searchValue.toLowerCase();
    for (String k in keys) {
      var v = browserModel.tasks[k];
      if (v!.length != 0) {
        var c = 0;
        _data.add(DItem(date: k, task: null));

        items[k] = [];
        items[k]!.addAll([c, ind]);
        ind = ind + 1;
        for (TaskInfo s in v) {
          if (searchValue == "" ||
              s.name.toString().toLowerCase().contains(searchValue) ||
              s.link.toString().toLowerCase().contains(searchValue)) {
            _data.add(DItem(date: k, task: s, key: GlobalKey()));
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

  @override
  Widget build(BuildContext context) {
    return buildDownload();
  }

  SafeArea buildDownload() {
    return SafeArea(
      child: WillPopScope(
        onWillPop: () async {
          if (!showSearchField)
            Navigator.pop(context);
          else {
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
                        buildDownloadList: _buildDownloadList,
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
            color: Colors.blueGrey[50],
            border: Border.all(
              color: const Color(0xFF575859),
            ),
            borderRadius: BorderRadius.all(Radius.circular(10))),
        child: Text(
          "No downloads found",
          style: TextStyle(color: Colors.black87, fontSize: 24),
        ),
      ),
    );
  }

  AnimatedList _buildDownloadList() {
    return AnimatedList(
      key: _listKey,
      initialItemCount: _data.length,
      itemBuilder: (context, index, animation) {
        if (index < _data.length) {
          DItem item = _data.elementAt(index);

          return Column(children: [
            DownloadItem(
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
}

class DownloadItem extends StatefulWidget {
  final DItem item;
  final int index;
  final Animation<double> animation;
  DownloadItem(
      {required this.item,
      required this.animation,
      required this.index,
      Key? key})
      : super(key: key);

  @override
  _DownloadItemState createState() => _DownloadItemState();
}

class _DownloadItemState extends State<DownloadItem> {
  Widget _buildItem(DItem item, int index, Animation<double> animation) {
    return Column(
      children: [
        item.task == null
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
                        style: TextStyle(
                          fontSize: 16,
                        ),
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
                      var url = Uri.parse(widget.item.task!.link.toString());
                      if (!url.scheme.startsWith("http") &&
                          !Util.isLocalizedContent(url)) {
                        url = Uri.parse(settings.searchEngine.searchUrl +
                            widget.item.task!.link.toString().trim());
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
                  child: Container(
                    key: widget.item.key,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            CustomImage(
                                isSelected: item.isSelected,
                                isDownload: true,
                                fileName: item.task?.name ?? "",
                                maxWidth: 36.0,
                                height: 36.0)
                          ],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    "File name not available sadsadsad sadsa dsadsad",
                                    style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Padding(
                                    padding: EdgeInsets.only(left: 12),
                                    child: RichText(
                                      text: TextSpan(
                                        style: TextStyle(
                                          color: Colors.black.withOpacity(0.7),
                                          fontSize: 14,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: int.parse(widget.item.task
                                                            ?.fileSize ??
                                                        "0") ==
                                                    0
                                                ? "NA"
                                                : (((int.parse(widget.item.task
                                                                            ?.fileSize ??
                                                                        "0") /
                                                                    1024) /
                                                                1024) *
                                                            ((widget.item.task
                                                                        ?.progress ??
                                                                    1) /
                                                                100))
                                                        .toString() +
                                                    "MB",
                                          ),
                                          TextSpan(text: "/"),
                                          TextSpan(
                                            text: int.parse(widget.item.task
                                                            ?.fileSize ??
                                                        "0") ==
                                                    0
                                                ? "NA"
                                                : (((int.parse(widget.item.task
                                                                        ?.fileSize ??
                                                                    "0") /
                                                                1024) /
                                                            1024))
                                                        .toString() +
                                                    "MB",
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              item.task!.link != null
                                  ? Text(
                                      item.task!.link.toString().startsWith(
                                              RegExp("http[s]{0,1}:[/]{2}"))
                                          ? (item.task!.link ?? "")
                                              .replaceFirst(
                                                  RegExp("http[s]{0,1}:[/]{2}"),
                                                  "")
                                          : "",
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 16),
                                    )
                                  : SizedBox.shrink(),
                              LinearProgressIndicator(
                                value: (widget.item.task?.progress ?? 0) / 100,
                              ),
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
              if (_data[i].task == null) {
                items[_data[i].date]![1] = i;
              }
            }
            AnimatedListRemovedItemBuilder builder = (context, animation) {
              browserModel.tasks[ritem.date] = _data
                  .where((element) => element.task != null)
                  .toList()
                  .where((element) => (element.date == ritem.date &&
                      element.task!.name != ritem.task!.name &&
                      element.task!.link != ritem.task!.link))
                  .toList()
                  .map((e) => e.task!)
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
            color: Colors.black.withOpacity(0.7),
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
  final int dataLen;
  final BrowserModel hbrowserModel;
  ClearAllH({required this.dataLen, required this.hbrowserModel, Key? key})
      : super(key: key);

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
                  ? "Clear All Downloads"
                  : "Clear All Searched Downloads",
              key: vk,
              style: TextStyle(
                color: (!longPressed) ? Colors.blue : Colors.grey,
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
                            ? 'Do you really want to clear all your downloads?'
                            : 'Do you really want to clear this downloads?'),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () {
                              if (!showSearchField) {
                                widget.hbrowserModel.addListOfDownlods =
                                    LinkedHashMap();
                              } else {
                                var prevd = widget.hbrowserModel.tasks;
                                for (DItem ditem in _data) {
                                  if (ditem.task != null) {
                                    prevd[ditem.date]?.removeWhere((element) =>
                                        element.taskId == ditem.task?.taskId &&
                                        element.link == ditem.task?.link &&
                                        element.name == ditem.task?.name);
                                  }
                                }
                                widget.hbrowserModel.addListOfDownlods = prevd;
                              }
                              widget.hbrowserModel.save();
                              _data.clear();
                              setState(() => _listKey = GlobalKey());
                              nohist.currentState?.setState(() {});
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
  final Function(String, bool) generateHistoryValues;
  HistoryAppBar({required this.generateHistoryValues, Key? key})
      : super(key: key);

  @override
  _HistoryAppBarState createState() => _HistoryAppBarState();

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}

class _HistoryAppBarState extends State<HistoryAppBar> {
  GlobalKey ktab = GlobalKey();
  GlobalKey ksf = GlobalKey();
  GlobalKey deleteBar = GlobalKey();
  @override
  void initState() {
    super.initState();
    txtc = TextEditingController();
  }

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
              widget.generateHistoryValues("", true);
              txtc.clear();
              clearAllSwitcher.currentState?.setState(() {});
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
                widget.generateHistoryValues(value.toString(), true);
                clearAllSwitcher.currentState?.setState(() {});
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
            "Downloads",
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
                  clearAllSwitcher.currentState?.setState(() {});
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
                              'Do you really want to clear all the selected downloads?'),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () {
                                var prevD = browserModel.tasks;
                                for (DItem ditem in _selectedList) {
                                  if (ditem.task != null) {
                                    prevD[ditem.date]?.removeWhere((element) =>
                                        element.taskId == ditem.task?.taskId &&
                                        element.link == ditem.task?.link &&
                                        element.name == ditem.task?.name);
                                  }
                                }
                                browserModel.addListOfDownlods = prevD;

                                browserModel.save();
                                _selectedList.clear();
                                longPressed = false;
                                widget.generateHistoryValues("", true);
                                clearAllSwitcher.currentState?.setState(() {});
                                nohist.currentState?.setState(() {});
                                appBarKey.currentState?.setState(() {});
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
                child: Icon(
                  Icons.delete_forever_rounded,
                  color: Colors.white,
                ),
              ),
              SizedBox(
                width: 8,
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
