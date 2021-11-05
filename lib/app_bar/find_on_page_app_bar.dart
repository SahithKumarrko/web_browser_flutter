import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:webpage_dev_console/models/browser_model.dart';
import 'package:provider/provider.dart';
import 'package:webpage_dev_console/models/findResults.dart';

class FindOnPageAppBar extends StatefulWidget {
  final void Function()? hideFindOnPage;

  FindOnPageAppBar({Key? key, this.hideFindOnPage}) : super(key: key);

  @override
  _FindOnPageAppBarState createState() => _FindOnPageAppBarState();
}

class _FindOnPageAppBarState extends State<FindOnPageAppBar> {
  TextEditingController _finOnPageController = TextEditingController();

  @override
  void dispose() {
    _finOnPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var browserModel = Provider.of<BrowserModel>(context, listen: false);
    var findResults = Provider.of<FindResults>(context, listen: true);
    var webViewModel = browserModel.getCurrentTab()?.webViewModel;
    var _webViewController = webViewModel?.webViewController;
    var cur = findResults.total > 0 ? 1 : 0;

    return AppBar(
      titleSpacing: 10.0,
      automaticallyImplyLeading: false,
      backgroundColor: Theme.of(context).backgroundColor,
      title: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                        color: Theme.of(this.context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.2),
                        blurRadius: 2,
                        offset: Offset(1, 1))
                  ],
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                      color: Theme.of(this.context).colorScheme.onSurface)),
              height: 40.0,
              child: TextField(
                onSubmitted: (value) {
                  _webViewController?.findAllAsync(find: value);
                },
                onChanged: (value) {
                  _webViewController?.findAllAsync(find: value);
                },
                controller: _finOnPageController,
                autocorrect: false,
                autofocus: true,
                textInputAction: TextInputAction.go,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.only(
                      left: 10, top: 10, bottom: 10, right: 0),
                  filled: true,
                  border: OutlineInputBorder(borderSide: BorderSide.none),
                  fillColor: Theme.of(context).appBarTheme.backgroundColor,
                  hintText: "Find on page ...",
                  suffix: IconButton(
                    highlightColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    padding: EdgeInsets.symmetric(vertical: 0, horizontal: 4),
                    constraints: BoxConstraints(),
                    icon: FaIcon(
                      FontAwesomeIcons.timesCircle,
                      color: Theme.of(context)
                          .colorScheme
                          .onBackground
                          .withOpacity(0.7),
                      size: 18,
                    ),
                    onPressed: () {
                      _webViewController?.clearMatches();
                      _finOnPageController.text = "";
                    },
                  ),
                  hintStyle: Theme.of(context).textTheme.bodyText2?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.54)),
                ),
                cursorColor: Theme.of(context).colorScheme.onBackground,
                style: Theme.of(context).textTheme.bodyText1,
              ),
            ),
          ),
          SizedBox(
            width: 8,
          ),
          Text(
            "${findResults.current + cur}/${findResults.total}",
            style: Theme.of(context).textTheme.bodyText1,
          ),
          SizedBox(
            width: 4,
          ),
        ],
      ),
      actions: <Widget>[
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            IconButton(
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(),
              highlightColor: Colors.transparent,
              splashColor: Colors.transparent,
              icon: Icon(
                Icons.keyboard_arrow_up,
                color: Theme.of(context).colorScheme.onBackground,
              ),
              onPressed: () {
                _webViewController?.findNext(forward: false);
              },
            ),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(),
              highlightColor: Colors.transparent,
              splashColor: Colors.transparent,
              icon: Icon(
                Icons.keyboard_arrow_down,
                color: Theme.of(context).colorScheme.onBackground,
              ),
              onPressed: () {
                _webViewController?.findNext(forward: true);
              },
            ),
          ],
        ),
        IconButton(
          highlightColor: Colors.transparent,
          splashColor: Colors.transparent,
          icon: Icon(
            Icons.close,
            color: Theme.of(context).colorScheme.onBackground,
          ),
          onPressed: () {
            _webViewController?.clearMatches();
            _finOnPageController.text = "";

            if (widget.hideFindOnPage != null) {
              widget.hideFindOnPage!();
            }
          },
        ),
      ],
    );
  }
}
