import 'dart:async';
import 'dart:collection';
import 'dart:developer';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:extended_image/extended_image.dart';
import 'package:flash/flash.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_html/shims/dart_ui_real.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mime/mime.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:provider/provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:webpage_dev_console/TaskInfo.dart';
import 'package:webpage_dev_console/c_popmenuitem.dart';
import 'package:webpage_dev_console/custom_image.dart';
import 'package:webpage_dev_console/helpers.dart';
import 'package:webpage_dev_console/item_selector.dart';
import 'package:webpage_dev_console/models/browser_model.dart';
import 'package:webpage_dev_console/models/webview_model.dart';
import 'package:webpage_dev_console/webview_tab.dart';

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
TextEditingController frController = TextEditingController();
late String _localPath;
List<String?> _filter = [];

class DItem {
  DItem(
      {required this.date,
      required this.task,
      this.isDeleted = false,
      this.isSelected = false,
      this.key});

  String date;
  bool isDeleted;
  bool isSelected;
  GlobalKey? key;
  TaskInfo? task;

  @override
  String toString() =>
      'DItem(title: $date,fileSize : ${task?.fileSize}, taskId: ${task?.taskId}, url: ${task?.link},"name":${task?.name},isSelected : $isSelected,"name":${task?.name})';
}

class CAS extends StatefulWidget {
  CAS({required this.buildDownloadList, required this.buildNoHistory, Key? key})
      : super(key: key);

  final Function() buildDownloadList;
  final Function() buildNoHistory;

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

class ISelector extends StatefulWidget {
  const ISelector({required this.generateHistoryValues, Key? key})
      : super(key: key);

  final Function(String, bool) generateHistoryValues;

  @override
  _ISelectorState createState() => _ISelectorState();
}

class _ISelectorState extends State<ISelector> {
  LinkedHashMap<String, Icon> data = LinkedHashMap();

  @override
  void initState() {
    super.initState();
    data["All"] = Icon(
      Icons.select_all_rounded,
      color: Colors.redAccent,
    );
    data["Videos"] = Icon(
      Icons.video_collection_rounded,
      color: Colors.redAccent,
    );
    data["Photos"] = Icon(
      Icons.photo_library_rounded,
      color: Colors.redAccent,
    );

    data["Audios"] = Icon(
      Icons.audiotrack_rounded,
      color: Colors.redAccent,
    );

    data["Saved Offline"] = Icon(
      Icons.offline_pin_rounded,
      color: Colors.redAccent,
    );
    data["Other"] = Icon(
      Icons.insert_drive_file_rounded,
      color: Colors.redAccent,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: MultiSelectChipField<String?>(
        showHeader: false,
        items: data.keys
            .toList()
            .map((v) => MultiSelectItem<String?>(v, v))
            .toList(),
        initialValue: ["All"],
        selectedChipColor: Colors.blue[200],
        selectedTextStyle: TextStyle(color: Colors.black),
        icon: Icon(
          Icons.check,
          color: Colors.black,
        ),
        defaultIcon: data,
        onTap: (values) {
          _filter = values;
          print("Calling");
          widget.generateHistoryValues(
              "fjumpmPuvqLlrPAvshJXtCYxe6T+Ph55teaNScgI44ZY7S9z0nE3enRnLkBTQj6XHVGNI39cUhndFZYzcTT5cA==",
              true);
        },
      ),
    );
  }
}

class ThumbnailRequest {
  final String video;
  final String thumbnailPath;
  final ImageFormat imageFormat;
  final int maxHeight;
  final int maxWidth;
  final int timeMs;
  final bool isDownloaded;
  final int quality;

  const ThumbnailRequest(
      {required this.video,
      required this.thumbnailPath,
      required this.imageFormat,
      required this.maxHeight,
      required this.maxWidth,
      required this.timeMs,
      this.isDownloaded = false,
      required this.quality});
}

class ThumbnailResult {
  final Image? image;
  final int dataSize;
  final int height;
  final int width;
  const ThumbnailResult(
      {required this.image,
      required this.dataSize,
      required this.height,
      required this.width});
}

Future<ThumbnailResult> genThumbnail(ThumbnailRequest r) async {
  //WidgetsFlutterBinding.ensureInitialized();
  Uint8List bytes;

  final Completer<ThumbnailResult> completer = Completer();
  try {
    var type = lookupMimeType(r.video)?.toLowerCase();
    log("${r.video} :: ${type.toString()}");
    if (type?.contains("video") ?? false) {
      bytes = (await VideoThumbnail.thumbnailData(
          video: r.video,
          imageFormat: r.imageFormat,
          maxHeight: r.maxHeight,
          maxWidth: r.maxWidth,
          timeMs: r.timeMs,
          quality: r.quality))!;

      int _imageDataSize = bytes.length;
      print("image size: $_imageDataSize");

      final _image = Image.memory(bytes);
      _image.image
          .resolve(ImageConfiguration())
          .addListener(ImageStreamListener((ImageInfo info, bool _) {
        completer.complete(ThumbnailResult(
          image: _image,
          dataSize: _imageDataSize,
          height: info.image.height,
          width: info.image.width,
        ));
      }));
    } else if (r.isDownloaded && (type?.contains("image") ?? false)) {
      final file = File(r.thumbnailPath);
      bytes = file.readAsBytesSync();
      final _image = Image.memory(bytes);
      _image.image
          .resolve(ImageConfiguration())
          .addListener(ImageStreamListener((ImageInfo info, bool _) {
        completer.complete(ThumbnailResult(
          image: _image,
          dataSize: bytes.length,
          height: r.maxHeight,
          width: r.maxWidth,
        ));
      }));
    } else {
      completer.complete(ThumbnailResult(
        image: null,
        dataSize: 0,
        height: 0,
        width: 0,
      ));
    }
  } catch (e) {
    print("ERROROROROR :::: $e");
    completer.completeError(ThumbnailResult(
      image: null,
      dataSize: 0,
      height: 0,
      width: 0,
    ));
  }

  return completer.future;
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
  ReceivePort _port = ReceivePort();

  @override
  void dispose() {
    super.dispose();
    unbindBackgroundIsolate();

    // frController.dispose();
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
      await generateHistoryValues("", false);
      bindBackgroundIsolate();
      FlutterDownloader.registerCallback(downloadCallback);
      _localPath = await FileUtil.findLocalPath();
    });
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
      if (_data.isNotEmpty && id != null) {
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

  List<String> _getListOfFileTypes() {
    var searchType = _filter[0];
    List<String> res = [];
    switch (searchType) {
      case "Videos":
        res = [
          ".mp4",
          ".webm",
          ".mpg",
          ".mp2",
          ".mpeg",
          ".mpe",
          ".mpv",
          ".ogg",
          ".mp4",
          ".m4p",
          ".m4v",
          ".avi",
          ".wmv",
          ".mov",
          ".qt",
          ".flv",
          ".swf",
          ".avchd",
          ".mpg",
          ".3gp",
          ".3gp2"
        ];
        break;
      case "Photos":
        res = [
          ".jpg",
          ".png",
          ".gif",
          ".webp",
          ".tiff",
          ".psd",
          ".bmp",
          ".heif",
          ".indd",
          ".jpeg",
          ".svg",
          ".ai",
          ".eps",
          ".exif",
          ".jfif",
          ".tiff",
          ".ppm",
          ".pgm",
          ".pbm",
          ".pnm"
        ];
        break;
      case "Audios":
        res = [
          ".wav",
          ".mp3",
          ".ogg",
          ".flac",
          ".mpc",
          ".aiff",
          ".mid",
          ".m4a",
          ".gsm",
          ".dct",
          ".aac",
          ".vox",
          ".wma",
          ".mmf",
          ".atrac",
          ".ra",
          ".iklax",
          ".mxp4"
        ];
        break;
      case "Other":
        res = [
              ".mp4",
              ".webm",
              ".mpg",
              ".mp2",
              ".mpeg",
              ".mpe",
              ".mpv",
              ".ogg",
              ".mp4",
              ".m4p",
              ".m4v",
              ".avi",
              ".wmv",
              ".mov",
              ".qt",
              ".flv",
              ".swf",
              ".avchd",
              ".mpg",
              ".3gp",
              ".3gp2"
            ] +
            [
              ".jpg",
              ".png",
              ".gif",
              ".webp",
              ".tiff",
              ".psd",
              ".raw",
              ".bmp",
              ".heif",
              ".indd",
              ".jpeg",
              ".svg",
              ".ai",
              ".eps",
              ".exif",
              ".jfif",
              ".tiff",
              ".ppm",
              ".pgm",
              ".pbm",
              ".pnm"
            ] +
            [
              ".wav",
              ".mp3",
              ".ogg",
              ".flac",
              ".mpc",
              ".aiff",
              ".mid",
              ".m4a",
              ".gsm",
              ".dct",
              ".aac",
              ".vox",
              ".wma",
              ".mmf",
              ".atrac",
              ".ra",
              ".iklax",
              ".mxp4"
            ] +
            [".mht", ".html"];
        break;
      case "Saved Offline":
        res = [".mht", ".html"];
        break;
      default:
        break;
    }
    print("Called :: $res");
    return res;
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
    var st = [];
    if (searchValue !=
        "fjumpmPuvqLlrPAvshJXtCYxe6T+Ph55teaNScgI44ZY7S9z0nE3enRnLkBTQj6XHVGNI39cUhndFZYzcTT5cA==") {
      searchValue = searchValue.toLowerCase();
    }

    print("Called gg $searchValue");
    for (String k in keys) {
      var v = browserModel.tasks[k];
      if (v!.length != 0) {
        var c = 0;
        _data.add(DItem(date: k, task: null));
        print("VV");
        items[k] = [];
        items[k]!.addAll([c, ind]);
        ind = ind + 1;
        for (TaskInfo s in v) {
          if (searchValue ==
              "fjumpmPuvqLlrPAvshJXtCYxe6T+Ph55teaNScgI44ZY7S9z0nE3enRnLkBTQj6XHVGNI39cUhndFZYzcTT5cA==") {
            print("check");
            var f = "." + s.fileName.split(".").last;
            st = _getListOfFileTypes();
            if (_filter[0] == "Other") {
              if (!st.contains(f)) {
                _data.add(DItem(date: k, task: s, key: GlobalKey()));
                c += 1;
                ind = ind + 1;
              }
            } else if (st.contains(f)) {
              _data.add(DItem(date: k, task: s, key: GlobalKey()));
              c += 1;
              ind = ind + 1;
            } else if (st.isEmpty) {
              generateHistoryValues("", true);
              return;
            }
          } else if (searchValue == "" ||
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
          if (t.filename == ditem.task?.fileName &&
              t.url == ditem.task?.link &&
              !(ditem.task?.notFromDownload ?? true) &&
              !(ditem.task?.isWebArchive ?? true)) {
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
    log(tasks.toString());
  }

  SafeArea buildDownload() {
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
                        key: clearAllSwitcher,
                        generateHistoryValues: generateHistoryValues),
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
      physics: BouncingScrollPhysics(),
      padding: EdgeInsets.only(bottom: 16),
      itemBuilder: (context, index, animation) {
        if (index < _data.length) {
          DItem item = _data.elementAt(index);

          return Column(children: [
            DownloadItem(
              item: item,
              index: index,
              animation: animation,
              key: item.key,
              generateHistoryValues: generateHistoryValues,
            )
          ]);
        }
        return SizedBox.shrink();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return buildDownload();
  }
}

class DownloadItem extends StatefulWidget {
  DownloadItem(
      {required this.item,
      required this.animation,
      required this.index,
      required this.generateHistoryValues,
      Key? key})
      : super(key: key);

  final Function(String, bool) generateHistoryValues;
  final Animation<double> animation;
  final int index;
  final DItem item;

  @override
  _DownloadItemState createState() => _DownloadItemState();
}

class _DownloadItemState extends State<DownloadItem> {
  @override
  void dispose() {
    super.dispose();
  }

  Widget _buildItem(DItem item, int index, Animation<double> animation) {
    String size = (widget.item.task?.fileSize ?? "");
    size = size.isEmpty ? "0" : size;
    num downloadSize = num.parse(size) == 0
        ? 0
        : (((num.parse(size) / 1024)) *
            ((widget.item.task?.progress ?? 1) / 100));
    num actual = num.parse(size) == 0 ? 0 : (((num.parse(size) / 1024)));
    String downloaded = "";
    String actualSize = "";
    if (downloadSize <= 1023) {
      downloaded = downloadSize.toStringAsFixed(2) + "KB";
    } else if (downloadSize >= (1024 * 1000)) {
      downloaded = ((downloadSize / 1024) / 1024).toStringAsFixed(2) + "GB";
    } else {
      downloaded = (downloadSize / 1024).toStringAsFixed(2) + "MB";
    }

    if (actual <= 1023) {
      actualSize = actual.toStringAsFixed(2) + "KB";
    } else if (actual >= (1024 * 1000)) {
      actualSize = ((actual / 1024) / 1024).toStringAsFixed(2) + "GB";
    } else {
      actualSize = (actual / 1024).toStringAsFixed(2) + "MB";
    }

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
                  onTap: () async {
                    if (!longPressed) {
                      File f =
                          File("${item.task?.savedDir}/${item.task?.fileName}");
                      bool opened = false;
                      if (await f.exists()) {
                        if (item.task?.isWebArchive ?? false) {
                          browserModel.addTab(
                              WebViewTab(
                                key: GlobalKey(),
                                webViewModel: WebViewModel(
                                    url: Uri.parse("file://" +
                                        (item.task?.webArchivePath ?? "")),
                                    openedByUser: true),
                              ),
                              true);
                          Navigator.pop(context);
                        } else {
                          opened = await FlutterDownloader.openFile(
                              fileName: item.task?.fileName ?? "",
                              taskId: item.task?.taskId ?? "",
                              savedDir: item.task?.savedDir ?? "",
                              url: item.task?.link ?? "");
                        }
                      }

                      if (!opened && !(item.task?.isWebArchive ?? false)) {
                        String msg = "";
                        Color msgColor = Colors.red;
                        if (item.task?.status == DownloadTaskStatus.running ||
                            item.task?.status == DownloadTaskStatus.enqueued ||
                            item.task?.status == DownloadTaskStatus.paused) {
                          msg = "File is downloading...";
                          msgColor = Colors.blue;
                        } else if (item.task?.status ==
                                DownloadTaskStatus.failed ||
                            item.task?.status == DownloadTaskStatus.canceled) {
                          msg = "Not able to open file.";
                          msgColor = Colors.red;
                        } else if (item.task?.status ==
                            DownloadTaskStatus.complete) {
                          msg = "Not able to open file.";
                          msgColor = Colors.red;
                        }
                        Helper.showBasicFlash(
                            msg: msg,
                            context: context,
                            backgroundColor: msgColor,
                            textColor: Colors.white,
                            duration: Duration(seconds: 3),
                            position: FlashPosition.top);
                      }
                      // Navigator.pop(context);
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
                            // type!.contains("image") ? : type!.contains("video") ? :
                            item.task?.status == DownloadTaskStatus.failed
                                ? CustomImage(
                                    isSelected: item.isSelected,
                                    isDownload: true,
                                    fileName: item.task?.name ?? "",
                                    maxWidth: 36.0,
                                    height: 36.0)
                                : FutureBuilder<ThumbnailResult>(
                                    future: genThumbnail(ThumbnailRequest(
                                        video: item.task?.status ==
                                                DownloadTaskStatus.complete
                                            ? (item.task?.savedDir ?? "") +
                                                "/" +
                                                (item.task?.fileName ?? "")
                                            : item.task?.link.toString() ?? "",
                                        thumbnailPath:
                                            (item.task?.savedDir ?? "") +
                                                "/" +
                                                (item.task?.fileName ?? ""),
                                        imageFormat: ImageFormat.JPEG,
                                        maxHeight: 36,
                                        maxWidth: 36,
                                        isDownloaded: item.task?.status ==
                                            DownloadTaskStatus.complete,
                                        timeMs: 0,
                                        quality: 100)),
                                    builder: (BuildContext context,
                                        AsyncSnapshot snapshot) {
                                      if (snapshot.hasData) {
                                        if (snapshot.data.image != null) {
                                          final _image = snapshot.data.image;
                                          return Container(
                                            constraints: BoxConstraints(
                                                minWidth: 36,
                                                minHeight: 36,
                                                maxWidth: 36,
                                                maxHeight: 36),
                                            child: _image,
                                          );
                                        } else {
                                          return CustomImage(
                                              isSelected: item.isSelected,
                                              isDownload: true,
                                              fileName: item.task?.name ?? "",
                                              maxWidth: 36.0,
                                              height: 36.0);
                                        }
                                      } else if (snapshot.hasError) {
                                        return Container(
                                            padding: EdgeInsets.all(8.0),
                                            color: Colors.red,
                                            child: Icon(Icons
                                                .file_download_off_rounded));
                                      } else {
                                        return CircularProgressIndicator();
                                      }
                                    },
                                  )
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
                                          downloaded,
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
                                    actualSize,
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

  _renameFile(File f, BuildContext actx, TaskInfo task, String renamed) async {
    if (renamed != task.fileName) {
      File f = new File(task.savedDir + "/" + renamed);
      if (await f.exists()) {
        Helper.showBasicFlash(
            msg: "File Already Present. Try with giving a different name.",
            context: actx,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            duration: Duration(seconds: 3),
            position: FlashPosition.top);
        return;
      }
    }
    Navigator.pop(actx);

    await FileUtil.changeFileNameOnly(f, renamed);
    var prevD = browserModel.tasks;
    List<TaskInfo> tinfo = prevD[widget.item.date] ?? [];
    for (var i = 0; i < tinfo.length; i++) {
      if (tinfo[i].fileName == task.fileName &&
          tinfo[i].savedDir == task.savedDir &&
          tinfo[i].taskId == task.taskId) {
        tinfo[i].fileName = renamed;
        tinfo[i].name = renamed;

        break;
      }
    }
    browserModel.addListOfDownlods = prevD;

    await browserModel.save();
    Helper.showBasicFlash(
        msg: "Renamed Successfully.",
        context: context,
        backgroundColor: Colors.green,
        textColor: Colors.white,
        duration: Duration(seconds: 3),
        position: FlashPosition.top);
    widget.generateHistoryValues("", true);
  }

  void _popupMenuChoiceAction(String choice, TaskInfo task) async {
    switch (choice) {
      case "Rename":
        File f = File(task.savedDir + "/" + task.fileName);
        if (!(await f.exists())) {
          Helper.showBasicFlash(
              msg:
                  "Not able to perform file rename action.\nReason: File is not present.",
              context: context,
              duration: Duration(seconds: 5),
              backgroundColor: Colors.redAccent,
              textColor: Colors.white,
              position: FlashPosition.top);
          removeItem(widget.index);
        } else {
          showDialog(
              context: context,
              barrierDismissible: true,
              builder: (actx) {
                var ff = task.fileName.split(".");
                String fn = ff.sublist(0, ff.length - 1).join(".");
                frController = new TextEditingController(text: task.fileName);
                frController.selection = new TextSelection(
                  baseOffset: 0,
                  extentOffset: fn.length,
                );
                return AlertDialog(
                  title: Text("Rename File"),
                  content: TextField(
                    controller: frController,
                    autofocus: true,
                    autocorrect: false,
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (v) {
                      _renameFile(f, actx, task, frController.value.text);
                    },
                    decoration: InputDecoration(
                        suffixIcon: InkWell(
                            onTap: () {
                              _renameFile(
                                  f, actx, task, frController.value.text);
                            },
                            child: Icon(FontAwesomeIcons.edit))),
                  ),
                );
              });
        }
        break;
      case "Share":
        print("Sharing .. ${task.savedDir}/${task.fileName}");
        Helper.shareFiles([task.savedDir + "/" + task.fileName]);
        break;
      case "Delete From History":
        removeItem(widget.index);
        break;
      case "Delete From Storage and History":
        Helper.cancelDownload(task: task, removeFromStorage: true);
        removeItem(widget.index);
        break;
      case "Copy Download Url":
        Clipboard.setData(ClipboardData(text: task.link.toString()));
        // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        //   content: Text("Copied!"),
        // ));
        Helper.showBasicFlash(
            duration: Duration(seconds: 2),
            msg: "Copied!",
            backgroundColor: Colors.green,
            textColor: Colors.white,
            position: FlashPosition.top,
            context: context);
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
          if ((task.link ?? "").isNotEmpty)
            popupitems.add(CustomPopupMenuItem<String>(
              enabled: true,
              value: "Copy Download Url",
              child: Text("Copy Download Url"),
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
            value: "Delete From History",
            child: Text("Delete From History"),
          ));
          popupitems.add(CustomPopupMenuItem<String>(
            enabled: true,
            value: "Delete From Storage and History",
            child: Text("Delete From Storage and History"),
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
    } else if (task.status == DownloadTaskStatus.failed ||
        task.status == DownloadTaskStatus.canceled) {
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
          IconButton(
            onPressed: () {
              removeItem(widget.index);
              Helper.cancelDownload(task: task);
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
    } else if (task.status == DownloadTaskStatus.enqueued) {
      return Container(
        constraints: BoxConstraints(minHeight: 32.0, minWidth: 32.0),
        child: CircularProgressIndicator(
          color: Colors.blue,
        ),
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
        Helper.cancelDownload(task: task);
        removeItem(widget.index);
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

class CustomDeleteDownloadsAlertdialog extends StatefulWidget {
  const CustomDeleteDownloadsAlertdialog(
      {required this.generateHistoryValues, Key? key})
      : super(key: key);

  final Function(String, bool) generateHistoryValues;

  @override
  _CustomDeleteDownloadsAlertdialogState createState() =>
      _CustomDeleteDownloadsAlertdialogState();
}

class _CustomDeleteDownloadsAlertdialogState
    extends State<CustomDeleteDownloadsAlertdialog> {
  GlobalKey alertDialogKey = GlobalKey();
  bool deleteFromStorage = false;

  _removeFromStorage(List<DItem> dat) {
    nohist.currentState?.setState(() {
      isLoadingSearch = true;
    });
    for (var t in dat) {
      if (t.task != null) {
        Helper.cancelDownload(task: t.task!);
      }
    }
    nohist.currentState?.setState(() {
      isLoadingSearch = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: alertDialogKey,
      title: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.red,
          ),
          SizedBox(
            width: 8,
          ),
          Text('Warning!'),
        ],
      ),
      contentPadding: EdgeInsets.fromLTRB(24, 24, 0, 0),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(!showSearchField
              ? 'Do you really want to clear all your downloads?'
              : 'Do you really want to clear these downloads?'),
          SizedBox(
            height: 24,
            child: CheckboxListTile(
              value: deleteFromStorage,
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (v) {
                this.setState(() {
                  deleteFromStorage = !deleteFromStorage;
                });
              },
              title: Text(
                "Also Delete From Storage",
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          SizedBox(
            height: 12,
          )
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            List<DItem> deleteData = longPressed ? _selectedList : _data;
            if (!showSearchField) {
              browserModel.addListOfDownlods = LinkedHashMap();
            } else {
              var prevd = browserModel.tasks;
              for (DItem ditem in deleteData) {
                if (ditem.task != null) {
                  prevd[ditem.date]?.removeWhere((element) =>
                      element.taskId == ditem.task?.taskId &&
                      element.fileName == ditem.task?.fileName);
                }
              }
              browserModel.addListOfDownlods = prevd;
            }
            if (deleteFromStorage) {
              print("deleting From storage");
              _removeFromStorage(deleteData);
            }
            browserModel.save();
            if (!longPressed) {
              _data.clear();

              setState(() => _listKey = GlobalKey());
            } else {
              _selectedList.clear();
              longPressed = false;
              widget.generateHistoryValues("", true);
              appBarKey.currentState?.setState(() {});
            }

            clearAllSwitcher.currentState?.setState(() {});
            nohist.currentState?.setState(() {});

            Navigator.pop(context);
          },
          child: Text(
            'YES',
            style: TextStyle(color: Colors.red),
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text('NO'),
        ),
      ],
    );
  }
}

class ClearAllH extends StatefulWidget {
  ClearAllH(
      {required this.dataLen, required this.generateHistoryValues, Key? key})
      : super(key: key);

  final Function(String, bool) generateHistoryValues;
  final int dataLen;

  @override
  _ClearAllHState createState() => _ClearAllHState();
}

class _ClearAllHState extends State<ClearAllH> {
  GlobalKey alertDialogKey = GlobalKey();
  ValueKey vk = ValueKey("specificDeletion");

  Widget _buildClearAllHistory(BuildContext context) {
    return Column(
      children: [
        (!showSearchField && !longPressed)
            ? ISelector(
                generateHistoryValues: widget.generateHistoryValues,
              )
            : SizedBox.shrink(),
        Row(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
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
                          return CustomDeleteDownloadsAlertdialog(
                            key: alertDialogKey,
                            generateHistoryValues: widget.generateHistoryValues,
                          );
                        });
                  }
                  return null;
                },
              ),
            ),
          ],
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
                onTap: () async {
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
                },
                child: FaIcon(
                  FontAwesomeIcons.shareAlt,
                  color: Colors.white,
                ),
              ),
              SizedBox(
                width: 24,
              ),
              InkWell(
                onTap: () {
                  setState(() {
                    showSearchField = false;
                  });
                  clearAllSwitcher.currentState?.setState(() {});
                  showDialog(
                      context: context,
                      builder: (_) {
                        return CustomDeleteDownloadsAlertdialog(
                            generateHistoryValues:
                                widget.generateHistoryValues);
                      });
                },
                child: Icon(
                  Icons.delete_forever_rounded,
                  color: Colors.white,
                ),
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
