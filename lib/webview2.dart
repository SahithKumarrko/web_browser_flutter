import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

class WebView2 extends StatefulWidget {
  @override
  _WebView2State createState() => new _WebView2State();
}

class _WebView2State extends State<WebView2> {
  bool _addJs = false;
  bool _completedAddedJs = false;
  final GlobalKey webViewKey = GlobalKey();
  bool _isConsoleOpened = false;
  bool _isDesktopMode = false;
  InAppWebViewController? _webViewController;
  InAppWebViewGroupOptions options = InAppWebViewGroupOptions(
      crossPlatform: InAppWebViewOptions(
        useShouldOverrideUrlLoading: true,
        mediaPlaybackRequiresUserGesture: false,
        javaScriptEnabled: true,
        transparentBackground: true,
        supportZoom: true,
      ),
      android: AndroidInAppWebViewOptions(
        useHybridComposition: true,
      ),
      ios: IOSInAppWebViewOptions(
        allowsInlineMediaPlayback: true,
      ));

  late PullToRefreshController pullToRefreshController;
  String url = "";
  double progress = 0;
  final urlController = TextEditingController();
  String mobileUA = "";

  _addJsToCurrentPage() {
    _webViewController?.evaluateJavascript(
        source: _isDesktopMode
            ? "document.getElementsByName('viewport')[0].setAttribute('content','user-scalable=yes, maximum-scale=1.5');"
            : "document.getElementsByName('viewport')[0].setAttribute('content','width=device-width, initial-scale=1.0');");

    _webViewController!.evaluateJavascript(source: """
                              var el = {};
                              function _disableInteraction(state){
                                _disableAnchors(state);
                                _disableElements("input",state);
                                _disableElements("button",state);
                              }
                              
                              function _disableElements(type_ele,disable){
                                  var eles = document.getElementsByTagName(type_ele);
                                  var btns_divs = document.getElementsByClassName("__fbrowser_btn_identifier");
                                  console.log("Len :: "+eles.length+"  "+type_ele+"  ::  "+disable);
                                  for(i=0;i<eles.length;i++){
                                    var obj = eles[i];
                                    obj.disabled = disable;
                                    if(type_ele=="button" && disable){                                    
                                      var parent = obj.parentNode;
                                      var wrapper = document.createElement('div');
                                      wrapper.classList = parent.classList;
                                      wrapper.classList.add("__fbrowser_btn_identifier");
                                      wrapper.style.zIndex=2000;
                                      // set the wrapper as child (instead of the element)
                                      parent.replaceChild(wrapper, obj);
                                      // set element as child of wrapper
                                      wrapper.appendChild(obj);
                                      
                                      console.log(wrapper.outerHTML);
                                    }else if(type_ele=="button" && !disable){
                                      try{
                                        removeNode = btns_divs[i];
                                        while (removeNode.firstChild){
                                          removeNode.parentNode.insertBefore(removeNode.firstChild,removeNode);
                                        }
                                        removeNode.parentNode.removeChild(removeNode);
                                      }catch(error){

                                      }
                                    }
                                  }
                              }

                             
                              function _disableAnchors(disable){
                                  var eles = document.getElementsByTagName("a");
                                  console.log("Len :: "+eles.length+"  ::  "+disable);
                                  for(i=0;i<eles.length;i++){
                                    var obj = eles[i];
                                    if (disable) {
                                        var href = obj.getAttribute("href");
                                        if (href && href != "" && href != null) {
                                            obj.setAttribute('href_cus_bak', href);
                                        }
                                        obj.removeAttribute('href');
                                    }
                                    else {
                                      if(obj.getAttribute("href_cus_bak")!="" && obj.getAttribute("href_cus_bak")!=null){
                                        obj.setAttribute('href', obj.attributes['href_cus_bak'].nodeValue);
                                        obj.removeAttribute('href_cus_bak');
                                      }
                                    }
                                  }
                              }
                              function _generateXPATH(eleStr,attribute){
                                var ie = eleStr.split(">");
                                for(i=0;i<ie.length;i++){
                                    ie[i] += ">"
                                }
                                var l= [];
                                var si = eleStr.indexOf(attribute);
                                var s2=0;
                                var s = ie[0];
                                var r = "";
                                for(i=si;i<s.length;i++){
                                    if(s[i] == "\\""){
                                        s2 = s2+1;
                                        if(s2==2){
                                          break;
                                        }
                                        continue;
                                    }
                                    if(s2==1){
                                      r = r+s[i]; 
                                    }
                                }
                                return r;
                              }
                              function _clear(){
                                if("current_element" in el){
                                  var ele = el["current_element"];
                                  ele.style = el["s"];
                                }
                              }
                              _handleDocClick=function (e) {
                               _clear();
                                e = e || window.event;
                                var t = e.target || e.srcElement;
                                console.log("Element :: "+t.outerHTML);
                                    var text = t.textContent || t.innerText;
                                   var s = window.getComputedStyle(t);
                                   el["current_element"]=t;
                                    el["s"] = s;
                                    t.style.backgroundColor = "#0175c26b";
                                    t.style.border="2px solid orange"
                                    e.preventDefault();
                                    e.stopPropagation();
                              }
                            
                            """);
  }

  @override
  void initState() {
    super.initState();

    pullToRefreshController = PullToRefreshController(
      options: PullToRefreshOptions(
        color: Colors.blue,
      ),
      onRefresh: () async {
        if (Platform.isAndroid) {
          _webViewController?.reload();
        } else if (Platform.isIOS) {
          _webViewController?.loadUrl(
              urlRequest: URLRequest(url: await _webViewController?.getUrl()));
        }
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  bool isDesktopMode = false;
  // void toggleDesktopMode() async {
  //   if (_webViewController != null) {
  //     await _webViewController?.setOptions(
  //         options: InAppWebViewGroupOptions(
  //             crossPlatform: InAppWebViewOptions(
  //       preferredContentMode: isDesktopMode == false
  //           ? UserPreferredContentMode.DESKTOP
  //           : UserPreferredContentMode.RECOMMENDED,
  //     )));
  //     print("Changes 1 ");
  //     await _webViewController?.reload();
  //     print("Changes 2");
  //   }
  //   print("Done");
  //   isDesktopMode = !isDesktopMode;
  // }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Expanded(
          child: Stack(
            children: [
              InAppWebView(
                // key: webViewKey,
                initialUrlRequest:
                    URLRequest(url: Uri.parse("https://pub.dev/")),
                initialOptions: options,
                pullToRefreshController: pullToRefreshController,
                onWebViewCreated: (controller) {
                  mobileUA = options.crossPlatform.userAgent;
                  _webViewController = controller;
                },

                onLoadStart: (controller, url) {
                  setState(() {
                    this.url = url.toString();
                    urlController.text = this.url;
                  });
                  _addJs = false;
                  _completedAddedJs = false;
                  _isConsoleOpened = false;
                  _webViewController?.scrollTo(x: 0, y: 0);
                },
                androidOnPermissionRequest:
                    (controller, origin, resources) async {
                  return PermissionRequestResponse(
                      resources: resources,
                      action: PermissionRequestResponseAction.GRANT);
                },
                shouldOverrideUrlLoading: (controller, navigationAction) async {
                  var uri = navigationAction.request.url!;

                  if (![
                    "http",
                    "https",
                    "file",
                    "chrome",
                    "data",
                    "javascript",
                    "about"
                  ].contains(uri.scheme)) {
                    if (await canLaunch(url)) {
                      // Launch the App
                      await launch(
                        url,
                      );
                      // and cancel the request
                      return NavigationActionPolicy.CANCEL;
                    }
                  }

                  return NavigationActionPolicy.ALLOW;
                },
                onLoadStop: (controller, url) async {
                  pullToRefreshController.endRefreshing();
                  setState(() {
                    this.url = url.toString();
                    urlController.text = this.url;
                  });
                },
                onLoadError: (controller, url, code, message) {
                  pullToRefreshController.endRefreshing();
                },
                onProgressChanged: (controller, progress) {
                  controller.isLoading().then((value) => {
                        if (value) {_addJs = true}
                      });
                  if (_addJs && _completedAddedJs == false) {
                    _completedAddedJs = true;

                    _addJsToCurrentPage();
                    // _webViewController?.injectJavascriptFileFromAsset(assetFilePath: assetFilePath)
                    // b = document.evaluate("//h1[contains(@class,'title')]",document,null,XPathResult.FIRST_ORDERED_NODE_TYPE).singleNodeValue

                  }
                  if (progress == 100) {
                    pullToRefreshController.endRefreshing();
                  }
                  setState(() {
                    this.progress = progress / 100;
                    urlController.text = this.url;
                  });
                },
                onUpdateVisitedHistory: (controller, url, androidIsReload) {
                  setState(() {
                    this.url = url.toString();
                    urlController.text = this.url;
                  });
                },
                onConsoleMessage: (controller, consoleMessage) {
                  if (_isConsoleOpened &&
                      (consoleMessage.message
                              .toLowerCase()
                              .contains("_handleDocClick") ||
                          consoleMessage.message
                              .toLowerCase()
                              .contains("uncaught"))) {
                    _addJsToCurrentPage();
                    _webViewController?.evaluateJavascript(
                        source:
                            """document.removeEventListener('click',_handleDocClick, false);document.addEventListener('click',_handleDocClick, false);_disableInteraction(true)""");
                  }
                },
              ),
              progress < 1.0
                  ? LinearProgressIndicator(value: progress)
                  : Container(),
            ],
          ),
        ),
        ButtonBar(
          alignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            ElevatedButton(
              child: Icon(Icons.arrow_back),
              onPressed: () {
                _webViewController?.goBack();
              },
            ),
            ElevatedButton(
              child: Icon(Icons.desktop_windows),
              onPressed: () {
                // toggleDesktopMode();
                _isDesktopMode = !_isDesktopMode;
                _webViewController?.evaluateJavascript(
                    source: _isDesktopMode
                        ? "document.getElementsByName('viewport')[0].setAttribute('content','user-scalable=yes, maximum-scale=1.5');"
                        : "document.getElementsByName('viewport')[0].setAttribute('content','width=device-width, initial-scale=1.0');");
              },
            ),
            ElevatedButton(
              child: Icon(Icons.arrow_forward),
              onPressed: () {
                _webViewController?.goForward();
              },
            ),
            ElevatedButton(
              child: Icon(Icons.refresh),
              onPressed: () {
                _webViewController?.reload();
              },
            ),
            ElevatedButton(
              child: Icon(Icons.science_rounded),
              onPressed: () {
                _isConsoleOpened = !_isConsoleOpened;
                _webViewController?.evaluateJavascript(
                    source: _isConsoleOpened
                        ? "document.addEventListener('click',_handleDocClick, false); _disableInteraction(true)"
                        : "_clear();document.removeEventListener('click',_handleDocClick, false); _disableInteraction(false)");
              },
            ),
          ],
        ),
      ],
    );
  }
}
