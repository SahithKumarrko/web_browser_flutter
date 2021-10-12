import 'package:custom_file_icons/src/meta.dart';
import 'package:flutter/widgets.dart';
import 'src/data.dart';

class FileIcon extends StatefulWidget {
  final String fileName;
  final double size;

  FileIcon({required this.fileName, required this.size});

  @override
  State<FileIcon> createState() => _FileIconState();
}

class _FileIconState extends State<FileIcon> {
  int? iconData;
  int? color;
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (iconSetMap.containsKey(widget.fileName)) {
      iconData = iconSetMap[widget.fileName]!.codePoint;
      color = iconSetMap[widget.fileName]!.color;
    } else {
      var chunks = widget.fileName.split('.').sublist(1);
      while (chunks.isNotEmpty) {
        var k = '.' + chunks.join();
        if (iconSetMap.containsKey(k)) {
          iconData = iconSetMap[k]?.codePoint;
          color = iconSetMap[k]?.color;
          break;
        }
        if (['.dot', '.dotm', '.wps', '.odt'].contains(k)) {
          iconData = iconSetMap[".doc"]?.codePoint;
          color = iconSetMap[".doc"]?.color;
          break;
        }
        if ([".exe", ".dll"].contains(k)) {
          iconData = 0xE07C;
        }
        chunks = chunks.sublist(1);
      }
    }
    return Icon(
      IconData(
        iconData ?? 0xE05F,
        fontFamily: 'Seti',
        fontPackage: 'custom_file_icons',
      ),
      color: Color(color ?? 0xE028),
      size: widget.size,
    );
  }
}
