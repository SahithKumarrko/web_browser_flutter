// import 'package:cached_network_image/cached_network_image.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flash/flash.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:webpage_dev_console/TaskInfo.dart';
import 'package:webpage_dev_console/custom_image.dart';
import 'package:webpage_dev_console/helpers.dart';
import 'package:webpage_dev_console/history.dart';
import 'package:webpage_dev_console/webview_tab.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share/share.dart';

import 'models/browser_model.dart';
import 'models/webview_model.dart';

class LongPressAlertDialog extends StatefulWidget {
  static const List<InAppWebViewHitTestResultType> HIT_TEST_RESULT_SUPPORTED = [
    InAppWebViewHitTestResultType.SRC_IMAGE_ANCHOR_TYPE,
    InAppWebViewHitTestResultType.SRC_ANCHOR_TYPE,
    InAppWebViewHitTestResultType.IMAGE_TYPE
  ];

  LongPressAlertDialog(
      {Key? key,
      required this.webViewModel,
      required this.hitTestResult,
      this.requestFocusNodeHrefResult})
      : super(key: key);

  final WebViewModel webViewModel;
  final InAppWebViewHitTestResult hitTestResult;
  final RequestFocusNodeHrefResult? requestFocusNodeHrefResult;

  @override
  _LongPressAlertDialogState createState() => _LongPressAlertDialogState();
}

class _LongPressAlertDialogState extends State<LongPressAlertDialog> {
  var _isLinkPreviewReady = false;
  late String _localPath;
  late PermissionStatus _permissionReady;
  bool _checkPermissionAfterSettingsPage = false;
  String fileName = "", durl = "";

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: EdgeInsets.all(0.0),
      content: SingleChildScrollView(
        child: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _buildDialogLongPressHitTestResult(),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildDialogLongPressHitTestResult() {
    if (widget.hitTestResult.type ==
            InAppWebViewHitTestResultType.SRC_ANCHOR_TYPE ||
        widget.hitTestResult.type ==
            InAppWebViewHitTestResultType.SRC_IMAGE_ANCHOR_TYPE ||
        (widget.hitTestResult.type ==
                InAppWebViewHitTestResultType.IMAGE_TYPE &&
            widget.requestFocusNodeHrefResult != null &&
            widget.requestFocusNodeHrefResult!.url != null &&
            widget.requestFocusNodeHrefResult!.url.toString().isNotEmpty)) {
      // print("Type Returning Image");
      // print("Type2 :: ${widget.requestFocusNodeHrefResult?.url}");
      return <Widget>[
        _buildOpenNewTab(),
        _buildOpenNewIncognitoTab(),
        _buildCopyAddressLink(),
        _buildShareLink(),
      ];
    } else if (widget.hitTestResult.type ==
        InAppWebViewHitTestResultType.IMAGE_TYPE) {
      // print("Type :: ${widget.requestFocusNodeHrefResult?.url}");
      // print("TTT :: ${widget.hitTestResult.extra}");
      // String aa = widget.requestFocusNodeHrefResult?.src ?? "";
      // print("TTT :: ${base64.decode(aa)}");
      return <Widget>[
        // _buildImageTile(),
        // Divider(),
        _buildOpenImageNewTab(),
        _buildDownload(),
        _buildSearchImageOnGoogle(),
        _buildShareImage(),
      ];
    }

    return [];
  }

  Widget _buildLinkTile() {
    var url =
        widget.requestFocusNodeHrefResult?.url ?? Uri.parse("about:blank");
    var faviconUrl = Uri.parse(url.origin + "/favicon.ico");

    var title = widget.requestFocusNodeHrefResult?.title ?? "";
    if (title.isEmpty) {
      title = "Link";
    }

    return ListTile(
      leading: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          CustomImage(
            url: widget.requestFocusNodeHrefResult?.src != null
                ? Uri.parse(widget.requestFocusNodeHrefResult!.src!)
                : faviconUrl,
            maxWidth: 30.0,
            height: 30.0,
          )
        ],
      ),
      title: Text(
        title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        widget.requestFocusNodeHrefResult?.url?.toString() ?? "",
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      isThreeLine: true,
    );
  }

  Widget _buildLinkPreview() {
    var browserModel = Provider.of<BrowserModel>(context, listen: true);
    return ListTile(
      title: Center(child: const Text("Link Preview")),
      subtitle: Container(
        padding: EdgeInsets.only(top: 15.0),
        height: 250,
        child: IndexedStack(
          index: _isLinkPreviewReady ? 1 : 0,
          children: <Widget>[
            Center(
              child: CircularProgressIndicator(),
            ),
            InAppWebView(
              gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>[
                new Factory<OneSequenceGestureRecognizer>(
                  () => new EagerGestureRecognizer(),
                ),
              ].toSet(),
              initialUrlRequest:
                  URLRequest(url: widget.requestFocusNodeHrefResult?.url),
              initialOptions: InAppWebViewGroupOptions(
                  android: AndroidInAppWebViewOptions(
                      useHybridComposition: true,
                      verticalScrollbarThumbColor: Color.fromRGBO(0, 0, 0, 0.5),
                      horizontalScrollbarThumbColor:
                          Color.fromRGBO(0, 0, 0, 0.5))),
              onProgressChanged: (controller, progress) {
                if (progress > 50) {
                  setState(() {
                    _isLinkPreviewReady = true;
                  });
                }
              },
            )
          ],
        ),
      ),
    );
  }

  Widget _buildOpenNewTab() {
    var browserModel = Provider.of<BrowserModel>(context, listen: false);

    return ListTile(
      title: const Text("Open in a new tab"),
      onTap: () {
        browserModel.addTab(
            WebViewTab(
              key: GlobalKey(),
              webViewModel: WebViewModel(
                  url: widget.requestFocusNodeHrefResult?.url,
                  openedByUser: true),
            ),
            true);
        Navigator.pop(context);
      },
    );
  }

  Widget _buildOpenNewIncognitoTab() {
    var browserModel = Provider.of<BrowserModel>(context, listen: false);

    return ListTile(
      title: const Text("Open in a new incognito tab"),
      onTap: () {
        browserModel.addTab(
            WebViewTab(
              key: GlobalKey(),
              webViewModel: WebViewModel(
                  url: widget.requestFocusNodeHrefResult?.url,
                  openedByUser: true,
                  isIncognitoMode: true),
            ),
            true);
        Navigator.pop(context);
      },
    );
  }

  Widget _buildCopyAddressLink() {
    return ListTile(
      title: const Text("Copy address link"),
      onTap: () {
        Clipboard.setData(ClipboardData(text: widget.hitTestResult.extra));
        Navigator.pop(context);
      },
    );
  }

  Widget _buildShareLink() {
    return ListTile(
      title: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text("Share link"),
        Padding(
          padding: EdgeInsets.only(right: 12.5),
          child: Icon(
            Icons.share,
            color: Colors.black54,
            size: 20.0,
          ),
        )
      ]),
      onTap: () {
        if (widget.hitTestResult.extra != null) {
          Share.share(widget.hitTestResult.extra!);
        }
        Navigator.pop(context);
      },
    );
  }

  Widget _buildImageTile() {
    return ListTile(
      contentPadding:
          EdgeInsets.only(left: 15.0, top: 15.0, right: 15.0, bottom: 5.0),
      leading: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          // CachedNetworkImage(
          //   placeholder: (context, url) => CircularProgressIndicator(),
          //   imageUrl: widget.hitTestResult.extra,
          //   height: 50,
          // ),
          CustomImage(
              url: Uri.parse(widget.hitTestResult.extra!),
              maxWidth: 50.0,
              height: 50.0)
        ],
      ),
      title: Text(widget.webViewModel.title ?? ""),
    );
  }

  void resume() async {
    if (Platform.isAndroid) {
      widget.webViewModel.webViewController?.android.resume();
    }
    if (_checkPermissionAfterSettingsPage) {
      _checkPermissionAfterSettingsPage = false;
      fileName =
          await FileUtil.retryDownload(context: context, fileName: fileName);
    }
  }

  TextEditingController frController = TextEditingController();
  Future<void> download(bool isImage) async {
    var browserModel = Provider.of<BrowserModel>(context, listen: false);
    if (fileName == "") {
      print("TTT :: Openming");
      showDialog(
          context: context,
          barrierDismissible: true,
          builder: (actx) {
            return AlertDialog(
              title: Text("Save as"),
              content: TextField(
                controller: frController,
                autofocus: true,
                autocorrect: false,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.done,
                onSubmitted: (v) {
                  fileName = frController.value.text;

                  download(isImage);
                  Navigator.pop(actx);
                },
                decoration: InputDecoration(
                    suffixIcon: InkWell(
                        onTap: () {
                          fileName = frController.value.text;

                          download(isImage);
                          Navigator.pop(actx);
                        },
                        child: Icon(FontAwesomeIcons.edit))),
              ),
            );
          });
    } else if (!isImage) {
      var task;

      task = TaskInfo(
          link: durl.toString(),
          name: fileName,
          fileName: fileName,
          savedDir: _localPath);

      browserModel.requestDownload(task, _localPath, fileName);
      browserModel.addDownloadTask = task;
      browserModel.save();
    } else {
      String p = widget.requestFocusNodeHrefResult?.src ?? "";
      if (p.startsWith("data")) {
        var pp = p.split("/");
        if (pp.length >= 2) {
          var p2 = pp[1];
          var t = p2.split(";").first;
          print("File type :: $t");
          Uint8List bytes = Base64Decoder()
              .convert(p.replaceFirst("${pp[0]}/$t;base64,", ""));

          File f = File(_localPath + "/" + fileName);
          f.writeAsBytes(bytes);
          int fl = await f.length();
          var task = TaskInfo(
              link: durl.toString(),
              name: fileName,
              fileName: fileName,
              fileSize: fl.toString(),
              status: DownloadTaskStatus.complete,
              progress: 100,
              notFromDownload: true,
              savedDir: _localPath);
          browserModel.addDownloadTask = task;
          browserModel.save();
          Helper.showBasicFlash(
              msg: "Saved Successfully.",
              context: context,
              backgroundColor: Colors.green,
              textColor: Colors.white,
              position: FlashPosition.top,
              duration: Duration(seconds: 3));
        } else {
          Helper.showBasicFlash(
              msg: "Not able to download file. 2",
              context: context,
              backgroundColor: Colors.red,
              textColor: Colors.white,
              position: FlashPosition.top,
              duration: Duration(seconds: 3));
        }
      }
    }
  }

  Widget _buildDownload() {
    var browserModel = Provider.of<BrowserModel>(context, listen: false);
    return ListTile(
      title: const Text("Save"),
      onTap: () async {
        // Navigator.pop(context);
        bool isImage = false;
        fileName = "";
        if (widget.requestFocusNodeHrefResult?.src != null) {
          if ((widget.requestFocusNodeHrefResult?.src ?? "")
              .startsWith("data")) {
            isImage = true;
          } else {
            durl = widget.requestFocusNodeHrefResult?.src.toString() ?? "";
          }
        } else if (widget.requestFocusNodeHrefResult?.url != null) {
          String path = widget.requestFocusNodeHrefResult?.url?.path ?? "";
          fileName = path.substring(path.lastIndexOf('/') + 1);

          durl = widget.requestFocusNodeHrefResult?.url.toString() ?? "";
          fileName = path.substring(path.lastIndexOf('/') + 1);
        } else {
          print("${widget.requestFocusNodeHrefResult?.toString()}");
          Helper.showBasicFlash(
              msg: "Not able to download file. 1",
              context: context,
              backgroundColor: Colors.red,
              textColor: Colors.white,
              position: FlashPosition.top,
              duration: Duration(seconds: 3));

          return;
        }

        _permissionReady = await FileUtil.checkPermission(context: context);

        if (_permissionReady == PermissionStatus.granted) {
          _localPath = await FileUtil.findLocalPath();
          // print("Checking in :: $_localPath");

          bool fileExists = await File(_localPath + "/" + fileName).exists();
          if (fileExists) {
            FileUtil.showAlreadyFileExistsError(
                context: context,
                action: () async {
                  fileName = await FileUtil.getFileName(
                      context: context, fileName: fileName);
                  download(isImage);
                });
          } else {
            download(isImage);
          }
        } else {
          if (_permissionReady == PermissionStatus.permanentlyDenied) {
            FileUtil.showPermissionError(
                context: context,
                action: () {
                  _checkPermissionAfterSettingsPage = true;
                });
          }
        }
      },
    );
  }

  Widget _buildShareImage() {
    return ListTile(
      title: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text("Share image"),
        Padding(
          padding: EdgeInsets.only(right: 12.5),
          child: Icon(
            Icons.share,
            color: Colors.black54,
            size: 20.0,
          ),
        )
      ]),
      onTap: () {
        if (widget.hitTestResult.extra != null) {
          Share.share(widget.hitTestResult.extra!);
        }
        Navigator.pop(context);
      },
    );
  }

  Widget _buildOpenImageNewTab() {
    var browserModel = Provider.of<BrowserModel>(context, listen: false);

    return ListTile(
      title: const Text("Image in a new tab"),
      onTap: () {
        browserModel.addTab(
            WebViewTab(
              key: GlobalKey(),
              webViewModel: WebViewModel(
                  url: Uri.parse(widget.hitTestResult.extra ?? "about:blank"),
                  openedByUser: true),
            ),
            true);
        Navigator.pop(context);
      },
    );
  }

  Widget _buildSearchImageOnGoogle() {
    var browserModel = Provider.of<BrowserModel>(context, listen: false);

    return ListTile(
      title: const Text("Search this image on Google"),
      onTap: () {
        if (widget.hitTestResult.extra != null) {
          var url = "http://images.google.com/searchbyimage?image_url=" +
              widget.hitTestResult.extra!;
          browserModel.addTab(
              WebViewTab(
                key: GlobalKey(),
                webViewModel:
                    WebViewModel(url: Uri.parse(url), openedByUser: true),
              ),
              true);
        }
        Navigator.pop(context);
      },
    );
  }
}
