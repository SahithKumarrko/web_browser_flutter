import 'package:custom_file_icons/src/meta.dart';
import 'package:flutter/material.dart';
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
    iconData = null;
    color = null;
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

        chunks = chunks.sublist(1);
      }
    }

    return Icon(
      IconData(
        iconData ?? 0XE80C,
        fontFamily: 'Seti',
        fontPackage: 'custom_file_icons',
      ),
      color: Color(color ?? 0xff4d5a5e),
      size: widget.size,
    );
  }
}
