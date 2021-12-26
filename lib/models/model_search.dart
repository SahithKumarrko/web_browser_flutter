import 'package:webpage_dev_console/helpers.dart';

class Search {
  final String title;
  final Uri? url;
  final bool isHistory;
  final bool isIncognito;
  int hashValue;
  Search(
      {required this.title,
      this.url,
      this.isHistory = false,
      this.hashValue = -1,
      this.isIncognito = false});

  bool get hasSearch => title.isNotEmpty == true;

  factory Search.fromJson(Map<String, dynamic> props) {
    return Search(
      title: props["title"],
      url: props["url"],
      isHistory: props["isHistory"],
      isIncognito: props["isIncognito"],
    );
  }

  static Search? fromMap(Map<String, dynamic>? map) {
    return map != null
        ? Search(
            title: map["title"],
            url: Uri.parse(map["url"]),
            isHistory: true,
            isIncognito: map["isIncognito"])
        : null;
  }

  Map<String, dynamic> toMap() {
    return {
      "title": Helper.htmlToString(title),
      "url": url?.toString(),
      "isIncognito": isIncognito,
      // "hashValue": hashValue
    };
  }

  String get search {
    return '$title';
  }

  String get searchUrl {
    return '$url';
  }

  bool get incognito {
    return isIncognito;
  }

  @override
  String toString() =>
      'Search(title: $title,url: $url, isHistory: $isHistory,isIncognito: $isIncognito)';

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is Search && o.title == title;
  }

  @override
  int get hashCode => title.trim().toLowerCase().hashCode;
}
