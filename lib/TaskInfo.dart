import 'package:flutter/cupertino.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:webpage_dev_console/helpers.dart';

class TaskInfo {
  String? name;
  String? link;

  String? taskId;
  int? progress = 0;
  DownloadTaskStatus? status = DownloadTaskStatus.undefined;
  GlobalKey? key = GlobalKey();

  TaskInfo(
      {this.name,
      this.link,
      this.key,
      this.taskId,
      this.progress,
      this.status});

  @override
  String toString() {
    return "TaskInfo(taskId: $taskId,name: $name,link: $link, status: $status)";
  }

  static TaskInfo? fromMap(Map<String, dynamic>? map) {
    return map != null
        ? TaskInfo(
            name: map["name"],
            link: map["link"],
            taskId: map["taskId"],
            progress: map["progress"],
            status: map["status"])
        : null;
  }

  Map<String, dynamic> toMap() {
    return {
      "name": name,
      "link": link?.toString(),
      "taskId": taskId,
      "progress": progress ?? 0,
      "status": status
    };
  }
}
