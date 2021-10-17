import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class WebArchiveModel {
  Uri? url;
  String? title;
  String? path;
  String? favicon;
  DateTime timestamp;

  WebArchiveModel(
      {this.url, this.title, this.favicon, this.path, required this.timestamp});

  static WebArchiveModel? fromMap(Map<String, dynamic>? map) {
    return map != null
        ? WebArchiveModel(
            url: map["url"] != null ? Uri.parse(map["url"]) : null,
            title: map["title"],
            path: map["path"],
            timestamp: DateTime.fromMicrosecondsSinceEpoch(map["timestamp"]),
            favicon: map["favicon"])
        : null;
  }

  Map<String, dynamic> toMap() {
    return {
      "url": url?.toString(),
      "title": title,
      "favicon": favicon,
      "path": path,
      "timestamp": timestamp.millisecondsSinceEpoch
    };
  }

  Map<String, dynamic> toJson() {
    return toMap();
  }

  @override
  String toString() {
    return toMap().toString();
  }
}
