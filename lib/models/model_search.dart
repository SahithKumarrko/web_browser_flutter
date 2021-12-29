import 'package:objectbox/objectbox.dart';
import 'package:webpage_dev_console/helpers.dart';

@Entity()
class Search {
  @Id()
  int id = 0;
  String date;
  final String title;
  final String url;
  final bool isHistory;
  final bool isIncognito;
  int hashValue;
  Search(
      {required this.date,
      required this.title,
      required this.url,
      this.isHistory = false,
      this.hashValue = -1,
      this.isIncognito = false});

  bool get hasSearch => title.isNotEmpty == true;

  set searchDate(String d) => date = d;

  factory Search.fromJson(Map<String, dynamic> props) {
    return Search(
      date: props["date"],
      title: props["title"],
      url: props["url"],
      isHistory: props["isHistory"],
      isIncognito: props["isIncognito"],
    );
  }

  static Search? fromMap(Map<String, dynamic>? map) {
    return map != null
        ? Search(
            date: map["date"],
            title: map["title"],
            url: map["url"],
            isHistory: true,
            isIncognito: map["isIncognito"])
        : null;
  }

  Map<String, dynamic> toMap() {
    return {
      "date": date,
      "title": Helper.htmlToString(title),
      "url": url.toString(),
      "isIncognito": isIncognito,
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
      'Search(date: $date, title: $title,url: $url, isHistory: $isHistory,isIncognito: $isIncognito)';

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is Search && o.title == title;
  }

  @override
  int get hashCode => title.trim().toLowerCase().hashCode;
}
