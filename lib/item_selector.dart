import 'package:flutter/material.dart';

class ItemSelector extends StatefulWidget {
  String value;
  bool isSelected;
  Function(String) select;
  ItemSelector(
      {this.isSelected = false,
      required this.value,
      required this.select,
      Key? key})
      : super(key: key);

  @override
  _ItemSelectorState createState() => _ItemSelectorState();
}

class _ItemSelectorState extends State<ItemSelector> {
  @override
  Widget build(BuildContext context) {
    return _buildSelectItem();
  }

  Widget _buildSelectItem() {
    return InkWell(
      onTap: () {
        this.setState(() {
          widget.isSelected = !widget.isSelected;
        });
      },
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black87, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            AnimatedSwitcher(
              duration: Duration(milliseconds: 300),
              child: widget.isSelected
                  ? Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.black87, width: 1),
                      ),
                      child: Icon(
                        Icons.check,
                        size: 16,
                        color: Colors.green,
                        key: ValueKey<String>(widget.value),
                      ),
                    )
                  : const SizedBox(),
            ),
            SizedBox(
              width: 8,
            ),
            Text("${widget.value}"),
          ],
        ),
      ),
    );
  }
}
