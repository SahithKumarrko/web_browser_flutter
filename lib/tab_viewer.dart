import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webpage_dev_console/models/browser_model.dart';

class TabViewer extends StatefulWidget {
  final List<Widget> children;
  final int currentIndex;
  final Function(int index)? onTap;

  TabViewer(
      {Key? key, required this.children, this.onTap, this.currentIndex = 0})
      : super(key: key);

  @override
  _TabViewerState createState() => _TabViewerState();
}

class _TabViewerState extends State<TabViewer> {
  @override
  void initState() {
    super.initState();
    var browserModel = Provider.of<BrowserModel>(context, listen: false);
    if (browserModel.loadingVisible) {
      browserModel.loadingVis = false;

      Navigator.pop(browserModel.loadctx);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: BouncingScrollPhysics(),
      slivers: <Widget>[
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (BuildContext context, int index) {
              return GestureDetector(
                onTap: () {
                  if (widget.onTap != null) {
                    widget.onTap!(index);
                  }
                },
                child: widget.children[index],
              );
            },
            childCount: widget.children.length,
          ),
        ),
      ],
    );
  }
}
