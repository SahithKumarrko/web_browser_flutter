import 'package:flutter/cupertino.dart';
import 'package:flutter_downloader/flutter_downloader.dart';

class TaskInfo {
  String? name;
  String? link;

  String? taskId;
  int? progress = 0;
  String fileSize = "";
  DownloadTaskStatus? status = DownloadTaskStatus.undefined;
  GlobalKey? key = GlobalKey();

  TaskInfo(
      {this.name,
      this.link,
      this.key,
      this.taskId,
      this.progress,
      this.fileSize = "",
      this.status});

  @override
  String toString() {
    return "TaskInfo(taskId: $taskId,name: $name,link: $link, filesize: $fileSize ,status: $status)";
  }

  static TaskInfo? fromMap(Map<String, dynamic>? map) {
    return map != null
        ? TaskInfo(
            name: map["name"],
            link: map["link"],
            taskId: map["taskId"],
            progress: map["progress"],
            fileSize: map["fileSize"],
            status: DownloadTaskStatus(map["status"] ?? 0))
        : null;
  }

  Map<String, dynamic> toMap() {
    return {
      "name": name,
      "link": link?.toString(),
      "taskId": taskId,
      "progress": progress ?? 0,
      "status": status?.value ?? 0,
      "fileSize": fileSize
    };
  }
}
