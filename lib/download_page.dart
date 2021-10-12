import 'dart:isolate';

import 'package:device_info/device_info.dart';
import 'package:flash/flash.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_html/shims/dart_ui_real.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:webpage_dev_console/TaskInfo.dart';
import 'package:webpage_dev_console/helpers.dart';
import 'package:webpage_dev_console/models/browser_model.dart';

class DownloadPage extends StatefulWidget {
  DownloadPage({Key? key}) : super(key: key);

  @override
  _DownloadPageState createState() => _DownloadPageState();
}

class _DownloadPageState extends State<DownloadPage> {
  bool errorDismissed = false;
  late bool _isLoading;
  late List<ItemHolder> _items = [];
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
    _isLoading = true;

    bindBackgroundIsolate();

    FlutterDownloader.registerCallback(downloadCallback);
    _prepare();
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

  Future<Null> _prepare() async {
    var tasks = await FlutterDownloader.loadTasks();
    int count = 0;
    _tasks = [];
    _items = [];
    var browserModel = Provider.of<BrowserModel>(context, listen: false);
    var downloads = browserModel.tasks;

    // _tasks!.addAll(downloads!.map((download) =>
    //     TaskInfo(name: download.name, link: download.link, key: GlobalKey())));

    for (int i = count; i < _tasks!.length; i++) {
      _items.add(ItemHolder(name: _tasks![i].name, task: _tasks![i]));
      count++;
    }
    tasks!.forEach((task) {
      for (TaskInfo info in _tasks!) {
        if (info.link == task.url && info.name == task.filename) {
          info.taskId = task.taskId;
          info.status = task.status;
          info.progress = task.progress;
        }
      }
    });
    _permissionReady = await _checkPermission();

    if (_permissionReady) {
      _localPath = await FileUtil.findLocalPath();
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<bool> _openDownloadedFile(TaskInfo? task) {
    if (task != null) {
      return FlutterDownloader.open(taskId: task.taskId!);
    } else {
      return Future.value(false);
    }
  }

  // void _delete(TaskInfo task) async {
  //   await FlutterDownloader.remove(
  //       taskId: task.taskId!, shouldDeleteContent: true);
  //   var browserModel = Provider.of<BrowserModel>(context, listen: false);
  //   browserModel.tasks.removeWhere((element) => element.taskId == task.taskId);
  //   await _prepare();
  //   setState(() {});

  //   await browserModel.save();
  // }

  void _showPermissionError({bool persistent = true}) {
    context.showFlashDialog(
        persistent: persistent,
        title: Text('Error!'),
        content: Text(
          'Please grant accessing storage permission to continue -_-',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.blueGrey, fontSize: 18.0),
        ),
        negativeActionBuilder: (context, controller, _) {
          return TextButton(
            onPressed: () {
              controller.dismiss();
              errorDismissed = true;
            },
            child: Text(
              'Dismiss',
              style: TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
                fontSize: 20.0,
              ),
            ),
          );
        },
        positiveActionBuilder: (context, controller, _) {
          return TextButton(
              onPressed: () {
                controller.dismiss();
                _retryRequestPermission();
              },
              child: Text(
                'Retry',
                style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 20.0),
              ));
        });
  }

  Future<void> _retryRequestPermission() async {
    final hasGranted = await _checkPermission();

    if (hasGranted) {
      _localPath = await FileUtil.findLocalPath();
    }

    setState(() {
      _permissionReady = hasGranted;
    });
  }

  Future<bool> _checkPermission() async {
    final platform = Theme.of(context).platform;
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    if (platform == TargetPlatform.android &&
        androidInfo.version.sdkInt <= 28) {
      final status = await Permission.storage.status;
      if (status != PermissionStatus.granted) {
        final result = await Permission.storage.request();
        if (result == PermissionStatus.granted) {
          return true;
        }
      } else {
        return true;
      }
    } else {
      return true;
    }
    return false;
  }

  Future<bool> checkFilePath() async {
    _permissionReady = await _checkPermission();
    if (_permissionReady) {
      _localPath = await FileUtil.findLocalPath();
    } else {
      while (!(_permissionReady || errorDismissed)) _showPermissionError();
    }
    if (!errorDismissed && _permissionReady) {
      return true;
    }
    return false;
  }

  Widget _buildDownloadList() {
    var browserModel = Provider.of<BrowserModel>(context, listen: true);
    return Container(
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        children: _items
            .map((item) => DownloadItem(
                  key: item.task?.key,
                  data: item,
                  onItemClick: (task) {
                    _openDownloadedFile(task).then((success) {
                      if (!success) {
                        Helper.showBasicFlash(
                            msg: "Not able to open this file.",
                            duration: Duration(seconds: 1),
                            context: context);
                      }
                    });
                  },
                  onActionClick: (task) {
                    if (task.status == DownloadTaskStatus.undefined) {
                      browserModel.requestDownload(
                          task, _localPath, task.name.toString());
                    } else if (task.status == DownloadTaskStatus.running) {
                      _pauseDownload(task);
                    } else if (task.status == DownloadTaskStatus.paused) {
                      _resumeDownload(task);
                    } else if (task.status == DownloadTaskStatus.complete) {
                      // _delete(task);
                    } else if (task.status == DownloadTaskStatus.failed) {
                      _retryDownload(task);
                    }
                  },
                ))
            .toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Builder(
          builder: (context) => _isLoading
              ? new Center(
                  child: new CircularProgressIndicator(),
                )
              : _buildDownloadList(),
        ),
      ),
    );
  }
}

class ItemHolder {
  ItemHolder({this.name, this.task});

  final String? name;
  final TaskInfo? task;
}

class DownloadItem extends StatefulWidget {
  DownloadItem({this.data, this.onItemClick, this.onActionClick, Key? key})
      : super(key: key);

  final Function(TaskInfo?)? onItemClick;
  final Function(TaskInfo)? onActionClick;
  final ItemHolder? data;

  @override
  State<DownloadItem> createState() => _DownloadItemState();
}

class _DownloadItemState extends State<DownloadItem> {
  Widget? _buildActionForTask(TaskInfo task) {
    if (task.status == DownloadTaskStatus.undefined) {
      return RawMaterialButton(
        onPressed: () {
          widget.onActionClick!(task);
        },
        child: Icon(Icons.file_download),
        shape: CircleBorder(),
        constraints: BoxConstraints(minHeight: 32.0, minWidth: 32.0),
      );
    } else if (task.status == DownloadTaskStatus.running) {
      return RawMaterialButton(
        onPressed: () {
          widget.onActionClick!(task);
        },
        child: Icon(
          Icons.pause,
          color: Colors.red,
        ),
        shape: CircleBorder(),
        constraints: BoxConstraints(minHeight: 32.0, minWidth: 32.0),
      );
    } else if (task.status == DownloadTaskStatus.paused) {
      return RawMaterialButton(
        onPressed: () {
          widget.onActionClick!(task);
        },
        child: Icon(
          Icons.play_arrow,
          color: Colors.green,
        ),
        shape: CircleBorder(),
        constraints: BoxConstraints(minHeight: 32.0, minWidth: 32.0),
      );
    } else if (task.status == DownloadTaskStatus.complete) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            'Ready',
            style: TextStyle(color: Colors.green),
          ),
          RawMaterialButton(
            onPressed: () {
              widget.onActionClick!(task);
            },
            child: Icon(
              Icons.delete_forever,
              color: Colors.red,
            ),
            shape: CircleBorder(),
            constraints: BoxConstraints(minHeight: 32.0, minWidth: 32.0),
          )
        ],
      );
    } else if (task.status == DownloadTaskStatus.canceled) {
      return Text('Canceled', style: TextStyle(color: Colors.red));
    } else if (task.status == DownloadTaskStatus.failed) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text('Failed', style: TextStyle(color: Colors.red)),
          RawMaterialButton(
            onPressed: () {
              widget.onActionClick!(task);
            },
            child: Icon(
              Icons.refresh,
              color: Colors.green,
            ),
            shape: CircleBorder(),
            constraints: BoxConstraints(minHeight: 32.0, minWidth: 32.0),
          )
        ],
      );
    } else if (task.status == DownloadTaskStatus.enqueued) {
      return Text('Pending', style: TextStyle(color: Colors.orange));
    } else {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 16.0, right: 8.0),
      child: InkWell(
        onTap: widget.data!.task!.status == DownloadTaskStatus.complete
            ? () {
                widget.onItemClick!(widget.data!.task);
              }
            : null,
        child: Stack(
          children: <Widget>[
            Container(
              width: double.infinity,
              height: 64.0,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: Text(
                      widget.data!.name!,
                      maxLines: 1,
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: _buildActionForTask(widget.data!.task!),
                  ),
                ],
              ),
            ),
            widget.data!.task!.status == DownloadTaskStatus.running ||
                    widget.data!.task!.status == DownloadTaskStatus.paused
                ? Positioned(
                    left: 0.0,
                    right: 0.0,
                    bottom: 0.0,
                    child: LinearProgressIndicator(
                      value: widget.data!.task!.progress! / 100,
                    ),
                  )
                : Container()
          ].toList(),
        ),
      ),
    );
  }
}
