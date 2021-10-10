import 'package:flutter/cupertino.dart';

class MenuItem {
  int? value;
  String name = "";
  bool selected = false;
  MenuItem({@required value, @required name, selected = false});
}
