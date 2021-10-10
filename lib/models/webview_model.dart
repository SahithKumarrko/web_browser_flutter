import 'dart:collection';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class WebViewModel extends ChangeNotifier {
  int? _tabIndex;
  Uri? _url;
  String? _title;
  Favicon? _favicon;
  late double _progress;
  late bool _loaded;
  late bool _isDesktopMode;
  late bool _isIncognitoMode;
  late List<Widget> _javaScriptConsoleResults;
  late List<String> _javaScriptConsoleHistory;
  late List<LoadedResource> _loadedResources;
  late bool _isSecure;
  int? windowId;
  InAppWebViewGroupOptions? options;
  InAppWebViewController? webViewController;
  Uint8List? screenshot;
  bool needsToCompleteInitialLoad;
  bool openedByUser;
  late WebHistory? _history;
  int curIndex;
  bool _isLoading = false;
  WebViewModel(
      {int? tabIndex,
      Uri? url,
      String? title,
      Favicon? favicon,
      double progress = 0.0,
      bool loaded = false,
      bool isDesktopMode = false,
      bool isIncognitoMode = false,
      List<Widget>? javaScriptConsoleResults,
      List<String>? javaScriptConsoleHistory,
      List<LoadedResource>? loadedResources,
      WebHistory? history,
      bool isSecure = false,
      this.curIndex = 0,
      this.windowId,
      this.options,
      this.webViewController,
      this.openedByUser = false,
      this.needsToCompleteInitialLoad = true}) {
    _tabIndex = tabIndex;
    _url = url;
    _favicon = favicon;
    _progress = progress;
    _loaded = loaded;
    _isDesktopMode = isDesktopMode;
    _isIncognitoMode = isIncognitoMode;
    _javaScriptConsoleResults = javaScriptConsoleResults ?? <Widget>[];
    _javaScriptConsoleHistory = javaScriptConsoleHistory ?? <String>[];
    _loadedResources = loadedResources ?? <LoadedResource>[];
    _isSecure = isSecure;
    options = options ?? InAppWebViewGroupOptions();
    _history = history;
  }

  bool get isLoading => _isLoading;

  set isLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  int? get tabIndex => _tabIndex;

  set tabIndex(int? value) {
    if (value != _tabIndex) {
      _tabIndex = value;
      notifyListeners();
    }
  }

  WebHistory? get history => _history;
  set setHistory(WebHistory wwh) {
    _history = wwh;
  }

  setTabIndex(int? value, bool notify) {
    if (value != _tabIndex) {
      _tabIndex = value;
      if (notify) notifyListeners();
    }
  }

  Uri? get url => _url;

  set url(Uri? value) {
    if (value != _url) {
      _url = value;
      notifyListeners();
    }
  }

  String? get title => _title;

  set title(String? value) {
    if (value != _title) {
      _title = value;
      notifyListeners();
    }
  }

  Favicon? get favicon => _favicon;

  set favicon(Favicon? value) {
    if (value != _favicon) {
      _favicon = value;
      notifyListeners();
    }
  }

  double get progress => _progress;

  set progress(double value) {
    if (value != _progress) {
      _progress = value;
      notifyListeners();
    }
  }

  bool get loaded => _loaded;

  set loaded(bool value) {
    if (value != _loaded) {
      _loaded = value;
      notifyListeners();
    }
  }

  bool get isDesktopMode => _isDesktopMode;

  set isDesktopMode(bool value) {
    if (value != _isDesktopMode) {
      _isDesktopMode = value;
      notifyListeners();
    }
  }

  bool get isIncognitoMode => _isIncognitoMode;

  set isIncognitoMode(bool value) {
    if (value != _isIncognitoMode) {
      _isIncognitoMode = value;
      notifyListeners();
    }
  }

  UnmodifiableListView<Widget> get javaScriptConsoleResults =>
      UnmodifiableListView(_javaScriptConsoleResults);

  setJavaScriptConsoleResults(List<Widget> value) {
    if (!IterableEquality().equals(value, _javaScriptConsoleResults)) {
      _javaScriptConsoleResults = value;
      notifyListeners();
    }
  }

  void addJavaScriptConsoleResults(Widget value) {
    _javaScriptConsoleResults.add(value);
    notifyListeners();
  }

  UnmodifiableListView<String> get javaScriptConsoleHistory =>
      UnmodifiableListView(_javaScriptConsoleHistory);

  setJavaScriptConsoleHistory(List<String> value) {
    if (!IterableEquality().equals(value, _javaScriptConsoleHistory)) {
      _javaScriptConsoleHistory = value;
      notifyListeners();
    }
  }

  void addJavaScriptConsoleHistory(String value) {
    _javaScriptConsoleHistory.add(value);
    notifyListeners();
  }

  UnmodifiableListView<LoadedResource> get loadedResources =>
      UnmodifiableListView(_loadedResources);

  setLoadedResources(List<LoadedResource> value) {
    if (!IterableEquality().equals(value, _loadedResources)) {
      _loadedResources = value;
      notifyListeners();
    }
  }

  void addLoadedResources(LoadedResource value) {
    _loadedResources.add(value);
    notifyListeners();
  }

  bool get isSecure => _isSecure;

  set isSecure(bool value) {
    if (value != _isSecure) {
      _isSecure = value;
      notifyListeners();
    }
  }

  void updateWithValue(WebViewModel webViewModel) async {
    tabIndex = webViewModel.tabIndex;
    url = webViewModel.url;
    title = webViewModel.title;
    favicon = webViewModel.favicon;
    progress = webViewModel.progress;
    loaded = webViewModel.loaded;
    isDesktopMode = webViewModel.isDesktopMode;
    isIncognitoMode = webViewModel.isIncognitoMode;

    setJavaScriptConsoleResults(
        webViewModel._javaScriptConsoleResults.toList());
    setJavaScriptConsoleHistory(
        webViewModel._javaScriptConsoleHistory.toList());
    setLoadedResources(webViewModel._loadedResources.toList());
    isSecure = webViewModel.isSecure;
    options = webViewModel.options;
    webViewController = webViewModel.webViewController;
  }

  static WebViewModel? fromMap(Map<String, dynamic>? map) {
    return map != null
        ? WebViewModel(
            tabIndex: map["tabIndex"],
            url: map["url"] != null ? Uri.parse(map["url"]) : null,
            title: map["title"],
            favicon: map["favicon"] != null
                ? Favicon(
                    url: Uri.parse(map["favicon"]["url"]),
                    rel: map["favicon"]["rel"],
                    width: map["favicon"]["width"],
                    height: map["favicon"]["height"],
                  )
                : null,
            progress: map["progress"],
            isDesktopMode: map["isDesktopMode"],
            isIncognitoMode: map["isIncognitoMode"],
            javaScriptConsoleHistory:
                map["javaScriptConsoleHistory"]?.cast<String>(),
            isSecure: map["isSecure"],
            options: InAppWebViewGroupOptions.fromMap(map["options"]),
            curIndex: map["curIndex"],
            history: historyFromMap(map["history"]),
            openedByUser: map["openedByUser"])
        : null;
  }

  static historyFromMap(Map<String, dynamic> wh) {
    WebHistory w = WebHistory();
    List<WebHistoryItem> wi = [];
    for (var i in wh["list"] ?? []) {
      wi.add(WebHistoryItem(
        originalUrl: Uri.parse(i["originalUrl"]),
        url: Uri.parse(i["url"]),
        title: i["title"],
      ));
    }
    w.list = wi;
    return w;
  }

  Map<String, dynamic> toMap() {
    return {
      "tabIndex": _tabIndex,
      "url": _url?.toString(),
      "title": _title,
      "favicon": _favicon?.toMap(),
      "progress": _progress,
      "isDesktopMode": _isDesktopMode,
      "isIncognitoMode": _isIncognitoMode,
      "javaScriptConsoleHistory": _javaScriptConsoleHistory,
      "isSecure": _isSecure,
      "options": options?.toMap(),
      "screenshot": screenshot,
      "history": _history == null ? WebHistory().toMap() : _history?.toMap(),
      "curIndex": curIndex,
      "openedByUser": openedByUser
    };
  }

  Map<String, dynamic> toJson() {
    return toMap();
  }

  _startElementIdentification() {
    webViewController!.evaluateJavascript(
        source:
            """
                              var el = {};
                              function _elementInteraction(state){
                                if(state){
                                  _addNoInteraction();
                                  document.addEventListener('click',_handleDocClick, false);
                                }
                                else{
                                  var ele = document.getElementById("__fbrowser_no_interaction_div");
                                  if(ele!=null){
                                    ele.remove();
                                  }
                                  _clear();
                                  document.removeEventListener('click',_handleDocClick, false);
                                }
                              }
                              
                              function _addNoInteraction(){
                                var ele = document.createElement('div');
                                ele.style = "width:"+ document.body.clientWidth + "px;height:" + document.body.clientHeight +"px;position:absolute;top:0;left:0;z-index:90000000";
                                ele.setAttribute("id","__fbrowser_no_interaction_div");
                                document.body.append(ele);
                              }

                              function _clear(){
                                // if("current_element" in el){
                                //   var ele = el["current_element"];
                                //   ele.style = el["s"];
                                // }
                                var ele = document.getElementById('__fbrowser_selection_mark__');
                                if(ele!=null && ele!=undefined){
                                  ele.remove();
                                }
                              }
                              var div_ele;
                              function _createMark(ele){
                                var s = window.getComputedStyle(ele);
                                var b = ele.getBoundingClientRect();
                                
                                var mh = b.height + parseFloat(s.marginTop) + parseFloat(s.marginBottom);
                                var mw = b.width + parseFloat(s.marginLeft) + parseFloat(s.marginRight);

                                var scrollTop = window.pageYOffset || ele.scrollTop || document.body.scrollTop;
                                var scrollLeft = window.pageXOffset || ele.scrollLeft || document.body.scrollLeft;

                                var mtp = (b.y+scrollTop) - parseFloat(s.marginTop);
                                var mlp = (b.x+scrollLeft) - parseFloat(s.marginLeft);

                                var ptp = parseFloat(s.marginTop) + parseFloat(s.borderTop);
                                var plp = parseFloat(s.marginLeft) + parseFloat(s.borderLeft);
                                var pbp = parseFloat(s.marginBottom) + parseFloat(s.borderBottom);
                                var prp = parseFloat(s.marginRight) + parseFloat(s.borderRight);

                                var ctp = ptp + parseFloat(s.paddingTop);
                                var clp = plp + parseFloat(s.paddingLeft);
                                var cbp = pbp + parseFloat(s.paddingBottom);
                                var crp = prp + parseFloat(s.paddingRight);

                                div_ele = document.createElement("div");
                                div_ele.setAttribute('id','__fbrowser_selection_mark__');
                                div_ele.style = "position: absolute;width:"+mw+"px;height: "+mh+"px;top: "+mtp+"px;left: "+mlp+"px;z-index:20000;";
                                var content = "<div id='__fbrowser_selection_mark_area__' style='position:relative;width:100%;height:100%;'>";
                                content += "<div class='__fbrowser_selection_mark_area_margin__' style='position:relative;width:100%;height:100%;'><div></div><div></div><div></div><div></div></div>";
                                content += "<div  style='position:absolute;top:"+ s.marginTop +";left:"+s.marginLeft+";bottom:"+s.marginBottom+";right:"+s.marginRight+";'><div class='__fbrowser_selection_mark_area_border__' style='position:relative;width:100%;height:100%;'><div></div><div></div><div></div><div></div></div></div>";
                                content += "<div  style='position:absolute;top:"+ ptp +"px;left:"+plp+"px;bottom:"+pbp+"px;right:"+prp+"px;'><div class='__fbrowser_selection_mark_area_padding__' style='position:relative;width:100%;height:100%;'><div></div><div></div><div></div><div></div></div></div>";
                                content += "<div id='__fbrowser_selection_mark_area_content__' style='background:#0175c26b;position:absolute;top:"+ ctp +"px;left:"+clp+"px;bottom:"+cbp+"px;right:"+crp+"px;'></div>";
                                content += "</div></div>";
                                div_ele.innerHTML += content;

                                var dpm = div_ele.getElementsByClassName("__fbrowser_selection_mark_area_margin__")[0];
                                var mt = dpm.children[0];
                                mt.style = "position:absolute;top:0;background:rgba(249,204,157,0.5);width:100%;height:"+s.marginTop+";"
                                var mr = dpm.children[1];
                                mr.style = "position:absolute;right:0;background:rgba(249,204,157,0.5);width:"+s.marginRight+";top:"+s.marginTop+";bottom:"+s.marginBottom+";"
                                var mb = dpm.children[2];
                                mb.style = "position:absolute;bottom:0;background:rgba(249,204,157,0.5);width:100%;height:"+s.marginBottom+";"
                                var ml = dpm.children[3];
                                ml.style = "position:absolute;left:0;background:rgba(249,204,157,0.5);width:"+s.marginLeft+";top:"+s.marginTop+";bottom:"+s.marginBottom+";"
                                
                                var dpb = div_ele.getElementsByClassName("__fbrowser_selection_mark_area_border__")[0];
                                var bt = dpb.children[0];
                                bt.style = "position:absolute;top:0;background:rgba(253,221,155,0.5);width:100%;height:"+ parseFloat(s.borderTop) +"px;"
                                var br = dpb.children[1];
                                br.style = "position:absolute;right:0;background:rgba(253,221,155,0.5);width:"+parseFloat(s.borderTop)+"px;top:"+parseFloat(s.borderTop)+"px;bottom:"+parseFloat(s.borderBottom)+"px;"
                                var bb = dpb.children[2];
                                bb.style = "position:absolute;bottom:0;background:rgba(253,221,155,0.5);width:100%;height:"+parseFloat(s.borderBottom)+"px;"
                                var bl = dpb.children[3];
                                bl.style = "position:absolute;left:0;background:rgba(253,221,155,0.5);width:"+parseFloat(s.borderLeft)+"px;top:"+parseFloat(s.borderTop)+"px;bottom:"+parseFloat(s.borderBottom)+"px;"

                                var dpp = div_ele.getElementsByClassName("__fbrowser_selection_mark_area_padding__")[0];
                                var pt = dpp.children[0];
                                pt.style = "position:absolute;top:0;background:rgba(195,222,183,0.5);width:100%;height:"+s.paddingTop+";"
                                var pr = dpp.children[1];
                                pr.style = "position:absolute;right:0;background:rgba(195,222,183,0.5);width:"+s.paddingRight+";top:"+s.paddingTop+";bottom:"+s.paddingBottom+";"
                                var pb = dpp.children[2];
                                pb.style = "position:absolute;bottom:0;background:rgba(195,222,183,0.5);width:100%;height:"+s.paddingBottom+";"
                                var pl = dpp.children[3];
                                pl.style = "position:absolute;left:0;background:rgba(195,222,183,0.5);width:"+s.paddingLeft+";top:"+s.paddingTop+";bottom:"+s.paddingBottom+";"
                                document.body.append(div_ele);
                              }
                              
                              _handleDocClick=function (e) {
                                _clear()
                                
                                var x = e.clientX;
                                var y = e.clientY;
                                var ele = document.getElementById("__fbrowser_no_interaction_div");
                                ele.remove();
                                var ele = document.elementFromPoint(x,y);
                                window.flutter_inappwebview.callHandler('webElement',ele.outerHTML);
                                // console.log("ELEMENT :: "+ele.outerHTML);
                                var s = window.getComputedStyle(ele);
                                el["current_element"]=ele;
                                el["s"] = s;
                                // ele.style.backgroundColor = "#0175c26b";
                                // ele.style.border="2px solid orange";
                                _createMark(ele);
                                e.preventDefault();
                                e.stopPropagation();
                                _addNoInteraction();
                              }
                            
                            """);
  }

  @override
  String toString() {
    return toMap().toString();
  }
}
