import 'package:flutter/cupertino.dart';
import 'package:flutter_downloader/flutter_downloader.dart';

class TaskInfo {
  String? name;
  String? link;

  String fileName;
  String savedDir;
  String? taskId;
  int? progress = 0;
  String fileSize = "";
  bool notFromDownload = false;
  bool isWebArchive = false;
  String webArchivePath;
  DownloadTaskStatus? status = DownloadTaskStatus.undefined;

  GlobalKey? key = GlobalKey();

  TaskInfo(
      {this.name,
      this.link,
      this.key,
      this.taskId,
      this.progress,
      this.fileSize = "",
      required this.fileName,
      required this.savedDir,
      this.notFromDownload = false,
      this.isWebArchive = false,
      this.webArchivePath = "",
      this.status});

  @override
  String toString() {
    return "TaskInfo(taskId: $taskId,name: $name, savedDir: $savedDir ,link: $link, filesize: $fileSize ,status: $status, isWebArchive: $isWebArchive,webArchivePath: $webArchivePath)";
  }

  static TaskInfo? fromMap(Map<String, dynamic>? map) {
    return map != null
        ? TaskInfo(
            name: map["name"],
            link: map["link"],
            taskId: map["taskId"],
            progress: map["progress"],
            fileSize: map["fileSize"],
            fileName: map["fileName"],
            savedDir: map["savedDir"],
            notFromDownload: map["notFromDownload"],
            isWebArchive: map["isWebArchive"],
            webArchivePath: map["webArchivePath"],
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
      "fileSize": fileSize,
      "fileName": fileName,
      "savedDir": savedDir,
      "isWebArchive": isWebArchive,
      "webArchivePath": webArchivePath,
      "notFromDownload": notFromDownload
    };
  }
}
