import 'package:flutter/cupertino.dart';

class FindResults extends ChangeNotifier {
  int _total = 0;
  int _current = 0;

  int get total => _total;
  int get current => _current;
  setTotal({int v = 0, bool notify = true}) {
    _total = v;
    if (notify) notifyListeners();
  }

  setCurrent({int v = 0, bool notify = true}) {
    _current = v;
    if (notify) notifyListeners();
  }
}

class ChangePage extends ChangeNotifier {
  bool _isfinding = false;
  bool get isFinding => _isfinding;
  setIsFinding(bool v, bool notify) {
    _isfinding = v;
    if (notify) notifyListeners();
  }
}
