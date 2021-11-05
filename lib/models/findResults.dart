import 'package:flutter/cupertino.dart';

class FindResults extends ChangeNotifier {
  int _total = 0;
  int _current = 0;

  int get total => _total;
  int get current => _current;
  setTotal(int v) {
    _total = v;
    notifyListeners();
  }

  setCurrent(int v) {
    _current = v;
    notifyListeners();
  }
}
