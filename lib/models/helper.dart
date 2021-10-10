import 'package:flutter/material.dart';

class HelperModel extends ChangeNotifier {
  bool _restored = false;
  bool get restored => _restored;
  set restored(bool value) {
    _restored = value;
    notifyListeners();
  }
}
