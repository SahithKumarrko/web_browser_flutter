import 'package:objectbox/objectbox.dart';
import 'package:quiver/core.dart';

@Entity()
class FavoriteModel {
  @Id()
  int id = 0;
  String date;
  String url;
  String title;

  FavoriteModel({required this.date, required this.url, required this.title});

  static FavoriteModel? fromMap(Map<String, dynamic>? map) {
    return map != null
        ? FavoriteModel(url: map["url"], title: map["title"], date: map["date"])
        : null;
  }

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "url": url,
      "title": title,
      "date": date,
    };
  }

  Map<String, dynamic> toJson() {
    return toMap();
  }

  @override
  String toString() {
    return toMap().toString();
  }

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is FavoriteModel && o.title == title && o.url == url;
  }

  @override
  int get hashCode => hash2(title, url);
}
