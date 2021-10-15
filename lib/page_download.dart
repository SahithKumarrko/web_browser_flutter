import 'dart:collection';
import 'dart:isolate';

import 'package:extended_image/extended_image.dart';
import 'package:flash/flash.dart';
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
bool isLoadingSearch = false;

late String _localPath;
late bool _permissionReady;

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
      'DItem(title: $date,fileSize : ${task?.fileSize}, taskId: ${task?.taskId}, url: ${task?.link},"name":${task?.name},isSelected : $isSelected,"name":${task?.name})';
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
      child: isLoadingSearch
          ? Row(
              children: [
                Center(
                  child: CircularProgressIndicator(
                    color: Colors.blue,
                  ),
                )
              ],
            )
          : (_data.length > 1)
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
      await generateHistoryValues("", false);
      bindBackgroundIsolate();
      FlutterDownloader.registerCallback(downloadCallback);
      _localPath = await FileUtil.findLocalPath();
    });
  }

  ReceivePort _port = ReceivePort();

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
      if (_data.isNotEmpty) {
        final task = _data.firstWhere((_task) => _task.task?.taskId == id);

        task.task?.status = status;
        task.task?.progress = progress;
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

  generateHistoryValues(String searchValue, bool needUpdate) async {
    if (needUpdate) {
      nohist.currentState?.setState(() {
        isLoadingSearch = true;
      });
    }
    var keys = browserModel.tasks.keys.toList().reversed;
    var tasks = await FlutterDownloader.loadTasks();
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
    for (DItem ditem in _data) {
      if (ditem.task != null) {
        for (DownloadTask t in tasks ?? []) {
          if (t.filename == ditem.task?.name && t.url == ditem.task?.link) {
            ditem.task?.taskId = t.taskId;
            ditem.task?.fileSize = t.fileSize;
            ditem.task?.link = t.url;
            ditem.task?.name = t.filename;
            ditem.task?.progress = t.progress;
            ditem.task?.status = t.status;
          }
        }
      }
    }
    if (needUpdate) {
      _listKey.currentState?.setState(() {});
      nohist.currentState?.setState(() {
        isLoadingSearch = false;
      });
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
    print(
        "File Name :: ${item.task?.fileName} , Size :: ${item.task?.fileSize}, Date :: ${item.date}");
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
                                  Expanded(
                                    child: Text(
                                      (widget.item.task?.name ?? "NA"),
                                      style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  longPressed
                                      ? SizedBox(
                                          width: 28,
                                        )
                                      : _buildActionForTask(widget.item.task!),
                                ],
                              ),
                              SizedBox(
                                height: 2,
                              ),

                              // (widget.item.task?.status ==
                              //             DownloadTaskStatus.complete ||
                              //         widget.item.task?.status ==
                              //             DownloadTaskStatus.failed ||
                              //         widget.item.task?.status == null)
                              //     ? SizedBox.shrink()
                              //     :
                              Row(
                                children: [
                                  (widget.item.task?.status ==
                                              DownloadTaskStatus.complete ||
                                          widget.item.task?.status ==
                                              DownloadTaskStatus.failed ||
                                          widget.item.task?.status ==
                                              DownloadTaskStatus.canceled ||
                                          widget.item.task?.status == null)
                                      ? SizedBox.shrink()
                                      : Text(
                                          num.parse(widget.item.task
                                                          ?.fileSize ??
                                                      "0") ==
                                                  0
                                              ? "NA"
                                              : (((num.parse(widget.item.task
                                                                          ?.fileSize ??
                                                                      "0") /
                                                                  1024) /
                                                              1024) *
                                                          ((widget.item.task
                                                                      ?.progress ??
                                                                  1) /
                                                              100))
                                                      .toStringAsFixed(2) +
                                                  "MB",
                                          style: TextStyle(
                                              color: (widget
                                                          .item.task?.status ==
                                                      DownloadTaskStatus
                                                          .running)
                                                  ? Color(0xff8dc149)
                                                  : (widget.item.task?.status ==
                                                          DownloadTaskStatus
                                                              .paused)
                                                      ? Color(0xff519aba)
                                                      : (widget.item.task
                                                                      ?.status ==
                                                                  DownloadTaskStatus
                                                                      .failed ||
                                                              widget.item.task
                                                                      ?.status ==
                                                                  DownloadTaskStatus
                                                                      .canceled)
                                                          ? Color(0xffcc3e44)
                                                          : Colors.black,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w400),
                                        ),
                                  (widget.item.task?.status ==
                                              DownloadTaskStatus.complete ||
                                          widget.item.task?.status ==
                                              DownloadTaskStatus.failed ||
                                          widget.item.task?.status ==
                                              DownloadTaskStatus.canceled ||
                                          widget.item.task?.status == null)
                                      ? SizedBox.shrink()
                                      : Text(
                                          "/",
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 14,
                                          ),
                                        ),
                                  Text(
                                    num.parse(widget.item.task?.fileSize ??
                                                "0") ==
                                            0
                                        ? "NA"
                                        : (((num.parse(widget.item.task
                                                                ?.fileSize ??
                                                            "0") /
                                                        1024) /
                                                    1024))
                                                .toStringAsFixed(2) +
                                            "MB",
                                    style: TextStyle(
                                      color: (widget.item.task?.status ==
                                              DownloadTaskStatus.complete)
                                          ? Color(0xff8dc149)
                                          : (widget.item.task?.status ==
                                                      DownloadTaskStatus
                                                          .failed ||
                                                  widget.item.task?.status ==
                                                      DownloadTaskStatus
                                                          .canceled)
                                              ? Color(0xffcc3e44)
                                              : Colors.black,
                                      fontSize: 14,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 4,
                                  ),
                                  item.task!.link != null
                                      ? Expanded(
                                          child: Text(
                                            item.task!.link.toString(),
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.black54),
                                          ),
                                        )
                                      : SizedBox.shrink(),
                                ],
                              ),
                              SizedBox(
                                height: 4,
                              ),
                              (widget.item.task?.status ==
                                          DownloadTaskStatus.complete ||
                                      widget.item.task?.status ==
                                          DownloadTaskStatus.failed ||
                                      widget.item.task?.status ==
                                          DownloadTaskStatus.canceled ||
                                      widget.item.task?.status == null)
                                  ? SizedBox.shrink()
                                  : LinearProgressIndicator(
                                      value: (widget.item.task?.progress ?? 0) /
                                          100,
                                    ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ],
    );
  }

  void _popupMenuChoiceAction(String choice, TaskInfo task) {
    switch (choice) {
      case "Open in File Explorer":
        break;
      case "Rename":
        break;
      case "Share":
        print("Sharing .. ${task.savedDir}/${task.fileName}");
        Helper.shareFiles([task.savedDir + "/" + task.fileName]);
        break;
      case "Delete":
        removeItem(widget.index);
        break;
    }
  }

  Widget _buildoptionsMenu(TaskInfo task) {
    return PopupMenuButton<String>(
        onSelected: (choice) => _popupMenuChoiceAction(choice, task),
        padding: EdgeInsets.zero,
        child: Container(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              Icons.more_vert_rounded,
              color: Colors.black,
              size: 20,
            )),
        itemBuilder: (popupMenuContext) {
          var popupitems = <PopupMenuEntry<String>>[];

          popupitems.add(CustomPopupMenuItem<String>(
            enabled: true,
            value: "Open in File Explorer",
            child: Text("Open in File Explorer"),
          ));
          popupitems.add(CustomPopupMenuItem<String>(
            enabled: true,
            value: "Rename",
            child: Text("Rename"),
          ));

          popupitems.add(CustomPopupMenuItem<String>(
            enabled: true,
            value: "Share",
            child: Text("Share"),
          ));

          popupitems.add(CustomPopupMenuItem<String>(
            enabled: true,
            value: "Delete",
            child: Text("Delete"),
          ));
          return popupitems;
        });
  }

  Widget _buildActionForTask(TaskInfo task) {
    if (task.status == DownloadTaskStatus.undefined) {
      return Row(
        children: [
          IconButton(
            onPressed: () {
              Helper.downloadActionclick(task, browserModel, _localPath);
            },
            icon: Icon(
              Icons.refresh,
              color: Colors.red,
              size: 24,
            ),
            constraints: BoxConstraints(),
            padding: EdgeInsets.zero,
          ),
          SizedBox(
            width: 8,
          ),
          _cancelTask(task),
        ],
      );
    } else if (task.status == DownloadTaskStatus.running) {
      return Row(
        children: [
          IconButton(
            onPressed: () {
              Helper.downloadActionclick(task, browserModel, _localPath);
            },
            icon: Icon(
              Icons.pause,
              color: Colors.blue,
              size: 24,
            ),
            constraints: BoxConstraints(),
            padding: EdgeInsets.zero,
          ),
          SizedBox(
            width: 8,
          ),
          _cancelTask(task),
        ],
      );
    } else if (task.status == DownloadTaskStatus.paused) {
      return Row(
        children: [
          IconButton(
            onPressed: () {
              Helper.downloadActionclick(task, browserModel, _localPath);
            },
            icon: Icon(
              Icons.play_arrow,
              color: Colors.green,
              size: 24,
            ),
            constraints: BoxConstraints(),
            padding: EdgeInsets.zero,
          ),
          SizedBox(
            width: 8,
          ),
          _cancelTask(task),
        ],
      );
    } else if (task.status == DownloadTaskStatus.complete) {
      return _buildoptionsMenu(task);
    } else if (task.status == DownloadTaskStatus.failed) {
      return IconButton(
        onPressed: () {
          Helper.downloadActionclick(task, browserModel, _localPath);
        },
        icon: Icon(
          Icons.refresh,
          color: Colors.red,
          size: 24,
        ),
        constraints: BoxConstraints(),
        padding: EdgeInsets.zero,
      );
    } else if (task.status == DownloadTaskStatus.enqueued) {
      return Container(
        constraints: BoxConstraints(minHeight: 32.0, minWidth: 32.0),
        child: CircularProgressIndicator(
          color: Colors.blue,
        ),
      );
    } else if (task.status == DownloadTaskStatus.canceled) {
      return Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.red,
            size: 24,
          ),
          SizedBox(
            width: 8,
          ),
          IconButton(
            onPressed: () {
              removeItem(widget.index);
            },
            icon: Icon(
              Icons.delete_forever_rounded,
              color: Colors.red,
              size: 24,
            ),
            constraints: BoxConstraints(),
            padding: EdgeInsets.zero,
          ),
        ],
      );
    } else {
      return Icon(
        Icons.warning_amber_rounded,
        color: Colors.red,
        size: 24,
      );
    }
  }

  IconButton _cancelTask(TaskInfo task) {
    return IconButton(
      onPressed: () {
        Helper.cancelDownload(task);
      },
      icon: Icon(
        Icons.close_rounded,
        color: Colors.red,
        size: 24,
      ),
      constraints: BoxConstraints(),
      padding: EdgeInsets.zero,
    );
  }

  removeItem(int index) {
    ritem = _data.removeAt(index);
    print("Removing ritem :: $ritem");
    for (int i = 0; i < _data.length; i++) {
      if (_data[i].task == null) {
        items[_data[i].date]![1] = i;
      }
    }
    AnimatedListRemovedItemBuilder builder = (context, animation) {
      if (browserModel.tasks[ritem.date] != null) {
        List<TaskInfo> d = browserModel.tasks[ritem.date] ?? [];

        browserModel.tasks[ritem.date] = d
            .where((t) => (t.fileName != ritem.task?.fileName &&
                t.taskId != ritem.task?.taskId))
            .toList();
        print("data :: ");
        print(browserModel.tasks[ritem.date]);
        browserModel.save();
      }

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
      _listKey.currentState?.removeItem(items[ritem.date]![1], builder2);

      nohist.currentState?.setState(() {});
      clearAllSwitcher.currentState?.setState(() {});
    }
  }

  // Widget _buildStatusOfDownload(int index) {
  //   return SizedBox(
  //     width: 28,
  //     child: IconButton(
  //         padding: EdgeInsets.zero,
  //         constraints: BoxConstraints(),
  //         onPressed: removeItem(index),
  //         icon: FaIcon(
  //           FontAwesomeIcons.timesCircle,
  //           color: Colors.black.withOpacity(0.7),
  //           size: 18,
  //         )),
  //   );
  // }

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

  void _popupMenuChoiceActionForSelected(String choice) async {
    switch (choice) {
      case "Share":
        List<String> filePaths = [];
        var c = 0;
        for (var i in _selectedList) {
          var fp = "${i.task?.savedDir}/${i.task?.fileName}";
          File file = File(fp);
          if (await file.exists()) {
            filePaths.add(fp);
            c += 1;
          }
        }
        if (c != _selectedList.length) {
          Helper.showBasicFlash(
              msg: "Not able to share few files.",
              context: context,
              duration: Duration(seconds: 5),
              backgroundColor: Colors.redAccent,
              textColor: Colors.white,
              position: FlashPosition.top);
        }
        Helper.shareFiles(filePaths);
        break;
      case "Delete":
        break;
    }
  }

  Widget _buildoptionsMenu() {
    return PopupMenuButton<String>(
        onSelected: (choice) => _popupMenuChoiceActionForSelected(choice),
        padding: EdgeInsets.zero,
        child: Container(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              Icons.more_vert_rounded,
              color: Colors.white,
              size: 24,
            )),
        itemBuilder: (popupMenuContext) {
          var popupitems = <PopupMenuEntry<String>>[];

          popupitems.add(CustomPopupMenuItem<String>(
            enabled: true,
            value: "Share",
            child: Text("Share"),
          ));

          popupitems.add(CustomPopupMenuItem<String>(
            enabled: true,
            value: "Delete",
            child: Text("Delete"),
          ));
          return popupitems;
        });
  }

  Widget _buildLongPressed({required Key key}) {
    return Container(
      key: key,
      color: Colors.redAccent,
      padding: EdgeInsets.all(16),
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
              _buildoptionsMenu(),
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
