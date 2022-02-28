import 'package:flutter/material.dart';
import 'package:sales/services/v2/helper.dart';

class LaptDrawer extends StatefulWidget {
  LaptDrawer({this.title, @required this.body, this.footer});

  final String title;
  final List<Widget> body;
  final Widget footer;

  @override
  _LaptDrawerState createState() => _LaptDrawerState();
}

class _LaptDrawerState extends State<LaptDrawer> {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: Mquery.width(context),
            padding: EdgeInsets.only(left: 15, right: 15, top: 18.7, bottom: 19), decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.black12))
            ),
            child: text(widget.title)
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: widget.body
              )
            ),
          ),

          widget.footer == null ? SizedBox.shrink() : widget.footer

        ]
      )
    );
  }
}