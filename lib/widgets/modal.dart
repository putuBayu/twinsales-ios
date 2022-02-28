import 'package:flutter/material.dart';
import 'package:sales/services/v2/helper.dart';

class Modal {
  static bottom(context, {@required Widget child, bool wrap: false, double radius: 5, double height, Function then, Color backgroundColor}){
    showModalBottomSheet<dynamic>(
      isScrollControlled: true,
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext bc) {
        return !wrap ?
        
        Container(
          margin: EdgeInsets.only(top: Mquery.statusBar(context)),
          height: height == null ? Mquery.height(context) : height,
          child: ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(radius),
              topRight: Radius.circular(radius),
            ),
            child: child
          )
        ) : 
        
        ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(radius),
            topRight: Radius.circular(radius),
          ),
          child: Container(
            color: backgroundColor ?? Colors.transparent,
            child: Wrap(
              children: <Widget>[ child ]
            ),
          ),
        );
      }
    ).then((value){ if(then != null) then(value); });
  }
}