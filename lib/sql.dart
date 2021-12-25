import 'dart:async';
import 'dart:io';
import 'dart:convert';

main() {
  var path = "./filter_blocklist.txt";
  var dom = [];
  new File(path)
      .openRead()
      .transform(utf8.decoder)
      .transform(new LineSplitter())
      .forEach((l) => dom.add(l));
  print(dom.length);
}
