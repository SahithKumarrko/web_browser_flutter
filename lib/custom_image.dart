import 'package:extended_image/extended_image.dart';
import 'package:custom_file_icons/file_icon.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;

class CustomImage extends StatefulWidget {
  final double? width;
  final double? height;
  final double maxWidth;
  final double maxHeight;
  final double minWidth;
  final double minHeight;
  final Uri? url;
  final bool isCurrent;
  final bool isSelected;
  final IconData iconData;
  final bool isDownload;
  final String fileName;
  CustomImage(
      {Key? key,
      this.url,
      this.width,
      this.height,
      this.isCurrent = false,
      this.maxWidth = double.infinity,
      this.maxHeight = double.infinity,
      this.minWidth = 0.0,
      this.minHeight = 0.0,
      this.isSelected = false,
      this.iconData = Icons.file_present_rounded,
      this.isDownload = false,
      this.fileName = ""})
      : super(key: key);

  @override
  State<CustomImage> createState() => _CustomImageState();
}

class _CustomImageState extends State<CustomImage> {
  GlobalKey imageKey = GlobalKey();
  GlobalKey noImageKey = GlobalKey();

  GlobalKey selectedImage = GlobalKey();
  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
          maxWidth: this.widget.maxWidth,
          maxHeight: this.widget.maxHeight,
          minHeight: this.widget.minHeight,
          minWidth: this.widget.minWidth),
      width: this.widget.width,
      height: this.widget.height,
      child: AnimatedSwitcher(
          duration: Duration(milliseconds: 300),
          child: widget.isSelected ? _buildSelectionWidget() : getImage()),
    );
  }

  checkUrl(String url) async {
    http.Response response1 = await http.get(Uri.parse(url));
    return response1.statusCode;
  }

  Widget? getImage() {
    if (widget.isDownload) {
      print("Getting for :: ${widget.fileName}");
      // var ext = widget.fileName.split(".").last.toLowerCase();
      // if( ["apk"].contains(ext) || ['.dot','.dotm','.wps','.odt'].contains(ext)){

      // }
      return Container(
        key: imageKey,
        child: FileIcon(
          fileName: widget.fileName,
          size: this.widget.width ?? this.widget.height ?? this.widget.maxWidth,
        ),
      );
    }
    if (widget.url != null) {
      return Container(
        key: imageKey,
        child: ExtendedImage.network(
          widget.url.toString(),
          cache: true,
          width:
              this.widget.width ?? this.widget.height ?? this.widget.maxWidth,
          imageCacheName: widget.url?.origin,
          loadStateChanged: (state) {
            switch (state.extendedImageLoadState) {
              case LoadState.loading:
                return CircularProgressIndicator(
                  color: widget.isCurrent ? Colors.white : Colors.blue,
                );

              case LoadState.completed:
                return ExtendedRawImage(
                  image: state.extendedImageInfo?.image,
                );
              case LoadState.failed:
                return getBrokenImageIcon();
            }
          },
        ),
      );
    }
    return getBrokenImageIcon();
  }

  Widget getBrokenImageIcon() {
    return Container(
      key: noImageKey,
      child: FaIcon(
        FontAwesomeIcons.globeAsia,
        size: this.widget.width ?? this.widget.height ?? this.widget.maxWidth,
      ),
    );
  }

  Widget? _buildSelectionWidget() {
    return Container(
      key: selectedImage,
      child: Icon(
        Icons.check_circle,
        size: this.widget.width ?? this.widget.height ?? this.widget.maxWidth,
        color: Colors.redAccent,
      ),
    );
  }
}
