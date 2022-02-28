// helper -> version: 3.0.0, by Ashta

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sales/services/v2/helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:connectivity/connectivity.dart';
import 'package:badges/badges.dart';
import 'package:dart_ping/dart_ping.dart';

String fontFamily = 'Nunito';

//METHOD
pingStyle(var timeRespond) {
  if (CheckPing().getStatus() == "Online") {
    if (timeRespond >= 150) {
      return Row(
        children: [
          Icon(
            Icons.signal_wifi_off,
            color: Colors.red,
          )
        ],
      );
    } else {
      return Row(
        children: [
          Icon(
            Icons.wifi,
            color: Colors.green,
          )
        ],
      );
    }
  } else {
    return Row(
      children: [
        Icon(
          Icons.signal_wifi_off,
          color: Colors.red,
        ),
      ],
    );
  }
}

//CLASS
class App {
  static version() {
    return '1.0.20';
  }
}

class CheckPing {
  static double timeRespond = 0;
  DateTime start = new DateTime.now();
  static DateTime stop1;
  static String status = "Online";
  static int stopTime = 0;

  getPingMs(DateTime start) async {
    final ping = Ping('app.kembarputra.com', count: 2);
    // Begin ping process and listen for output
    ping.stream.listen((event) {
      if (event.error == null) {
        timeRespond = 0;
      } else {
        timeRespond = 9999;
      }
    });
    // Waiting for ping to output first two results
    // Not needed in actual use. For example only
    await Future.delayed(Duration(seconds: 2));
    // Stop the ping prematurely and output a summary
    await ping.stop();
  }

  intConnection() async {
    var result = await Connectivity().checkConnectivity();
    if (result == ConnectivityResult.mobile ||
        result == ConnectivityResult.wifi) {
      status = 'Online';
      // print('online');
    } else {
      status = 'Offline';
      // print('offline');
    }
  }

  getStatus() {
    return status;
  }

  getTimeRespond() {
    return timeRespond;
  }
}

class Cur {
  static rupiah(n) {
    final oCcy = new NumberFormat('#,##0.00', "en_US");

    if (n == null) {
      return '';
    }
    var value = oCcy.format(n).toString().split('.');
    return value[0].replaceAll(',', '.') + ',' + value[1].replaceAll('.', ',');
  }
}

class Auth {
  static Future user({String field}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    Map data = decode(prefs.getString('user'));

    if (field == null) {
      return data;
    } else {
      return data[field].toString();
    }
  }

  static Future id() async {
    return await user(field: 'id');
  }

  static Future token() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }
}

class FColor {
  static silver({double o: 1}) {
    return Color.fromRGBO(244, 247, 251, o);
  }

  static blue({double o: 1}) {
    return Color.fromRGBO(52, 107, 190, o);
  }

  static azure({double o: 1}) {
    return Color.fromRGBO(95, 170, 236, o);
  }

  static indigo({double o: 1}) {
    return Color.fromRGBO(103, 118, 199, o);
  }

  static purple({double o: 1}) {
    return Color.fromRGBO(154, 102, 226, o);
  }

  static pink({double o: 1}) {
    return Color.fromRGBO(229, 118, 154, o);
  }

  static red({double o: 1}) {
    return Color.fromRGBO(189, 52, 43, o);
  }

  static orange({double o: 1}) {
    return Color.fromRGBO(241, 150, 69, o);
  }

  static yellow({double o: 1}) {
    return Color.fromRGBO(240, 178, 63, o);
  }

  static lime({double o: 1}) {
    return Color.fromRGBO(163, 212, 79, o);
  }

  static green({double o: 1}) {
    return Color.fromRGBO(117, 183, 54, o);
  }

  static teal({double o: 1}) {
    return Color.fromRGBO(98, 200, 186, o);
  }

  static cyan({double o: 1}) {
    return Color.fromRGBO(73, 160, 181, o);
  }

  static gray({double o: 1}) {
    return Color.fromRGBO(169, 174, 182, o);
  }
}

class Input {
  static field(
      {String label,
      String hint,
      TextInputAction action,
      TextInputType type,
      bool autofocus: false,
      bool enabled: true,
      bool obsecure: false,
      int length: 255,
      FocusNode node,
      Widget prefix,
      Widget suffix,
      Function submit,
      Function change,
      TextEditingController controller}) {
    return TextField(
        // textAlign: TextAlign.center,
        keyboardType: type,
        onSubmitted: submit,
        focusNode: node,
        onChanged: change,
        controller: controller,
        textInputAction: action,
        obscureText: obsecure,
        enabled: enabled,
        inputFormatters: [LengthLimitingTextInputFormatter(length)],
        autofocus: autofocus,
        decoration: InputDecoration(
            alignLabelWithHint: true,
            suffixIcon: suffix,
            prefixIcon: prefix,
            hintText: hint,
            hintStyle: TextStyle(fontFamily: fontFamily),
            labelStyle: TextStyle(fontFamily: fontFamily),
            border: InputBorder.none));
  }
}

class LocalData {
  // LocalData.set('key', data);
  static Future set(key, data, {encode: false}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    switch (data.runtimeType) {
      case bool:
        prefs.setBool(key, data);
        break;

      case double:
        prefs.setDouble(key, data);
        break;

      case int:
        prefs.setInt(key, data);
        break;

      case String:
        prefs.setString(key, data);
        break;

      case List:
        prefs.setString(key, json.encode(data));
        break;

      case Map:
        prefs.setString(key, json.encode(data));
        break;

      default:
        prefs.setString(key, encode ? json.encode(data) : data);
        break;
    }
  }

  // var data = await LocalData.get('key');
  static Future get(key, {type: String, decode: false}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    switch (type) {
      case bool:
        prefs.getBool(key);
        break;

      case double:
        prefs.getDouble(key);
        break;

      case int:
        prefs.getInt(key);
        break;

      case String:
        var data = prefs.getString(key);
        return !decode ? data : json.decode(data);
        break;

      default:
        prefs.getString(key);
        break;
    }
  }
}

class Roles {
  // var isSales = await Roles.isSales();
  static Future isSales() async {
    var roles = await LocalData.get('roles', decode: true).then((res) => res);
    return roles.indexOf('salesman') > -1 ||
        roles.indexOf('salesman canvass') > -1;
  }
}

class Env {
  // var baseUrl = await Env.baseUrl();
  static Future baseUrl() async {
    var url = await LocalData.get('api').then((res) => res);
    return url;
  }

  // var isDev = await Env.isDev();
  static Future isDev() async {
    var url = await LocalData.get('api').then((res) => res);
    return url == null || url == 'https://kpm-api.kembarputra.com'
        ? false
        : true;
  }
}

class Fn {
  static mapToString(data) {
    return data.toString().replaceAllMapped(
        new RegExp('[{}: , ]', caseSensitive: false),
        (Match m) => "${m[0] == ':' ? '=' : m[0] == ',' ? '&' : ''}");
    // return data.toString().replaceAllMapped(new RegExp('[{}]', caseSensitive: false), (Match m) => '');
  }
}

class Gps {
  static Future latlon() async {
    bool location = await Geolocator().isLocationServiceEnabled();

    if (!location) {
      return 'Please enabled your location.';
    }

    Geolocator geolocator = Geolocator()..forceAndroidLocationManager = true;
    Position position = await geolocator.getLastKnownPosition(
        desiredAccuracy: LocationAccuracy.high);

    if (position == null) {
      position = await geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
    }
    return position;
  }

  static Future enabled() async {
    return await Geolocator().isLocationServiceEnabled();
  }
}

class CFilter {
  // ColorFiltered( colorFilter: CFilter.grayScale(), child: <image> )
  static grayScale() {
    return ColorFilter.matrix(<double>[
      0.2126,
      0.7152,
      0.0722,
      0,
      0,
      0.2126,
      0.7152,
      0.0722,
      0,
      0,
      0.2126,
      0.7152,
      0.0722,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ]);
  }
}

// ===== FORM WIDGET

class InlineRadio extends StatefulWidget {
  InlineRadio(
      {this.label,
      this.labelDescription: '',
      this.options,
      @required this.values,
      this.color});

  final String label, labelDescription;
  final List options, values;
  final Color color;

  @override
  _InlineRadioState createState() => _InlineRadioState();
}

class _InlineRadioState extends State<InlineRadio> {
  int checked = -1;

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            margin: EdgeInsets.only(bottom: 10),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  text(widget.label, bold: true),
                  text(widget.labelDescription)
                ]),
          ),
          Container(
              child: Wrap(
                  children: List.generate(widget.values.length, (i) {
            return GestureDetector(
              onTap: () {
                setState(() {
                  checked = i;
                });
              },
              child: Container(
                margin: EdgeInsets.only(right: 15, bottom: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      width: 18,
                      height: 18,
                      margin: EdgeInsets.only(right: 5),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(100),
                          border: checked == i
                              ? Border.all(color: FColor.blue(), width: 5)
                              : Border.all(color: Colors.black26),
                          color: Colors.white,
                          boxShadow: checked == i
                              ? [
                                  BoxShadow(
                                    color: Color.fromRGBO(205, 217, 239, 1),
                                    spreadRadius: 3,
                                    blurRadius: 0,
                                    offset: Offset(
                                        0, 0), // changes position of shadow
                                  ),
                                ]
                              : null),
                    ),
                    text(widget.values[i]),
                  ],
                ),
              ),
            );
          })))
        ],
      ),
    );
  }
}

/*  modal(context, height: Mquery.height(context) / 2,
      child: ListCupertino(options: [], values:[], initValue: controller, onSelect: (res){
        res = {object}
      })
    ); */

class ListCupertino extends StatefulWidget {
  ListCupertino({this.options, this.values, this.initValue, this.onSelect});

  final List options, values;
  final Function onSelect;
  final TextEditingController initValue;

  @override
  _ListCupertinoState createState() => _ListCupertinoState();
}

class _ListCupertinoState extends State<ListCupertino> {
  String selected;
  Map object;

  @override
  void initState() {
    super.initState();
    selected = widget.initValue.text;
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Expanded(
        child: PreventScrollGlow(
          child: CupertinoPicker(
              scrollController: FixedExtentScrollController(
                initialItem: widget.options.indexOf(selected),
              ),
              itemExtent: 40.0,
              backgroundColor: Colors.white,
              onSelectedItemChanged: (int i) {
                // if(widget.onSelect != null){
                //   widget.values != null ? widget.onSelect(widget.values[i]) :  widget.onSelect(widget.options[i]);
                // }
                selected = widget.options[i];
                object = {
                  'option': widget.options[i],
                  'value':
                      (widget.values == null ? '' : widget.values[i].toString())
                };
              },
              children:
                  new List<Widget>.generate(widget.options.length, (int index) {
                return Container(
                    margin: EdgeInsets.all(3),
                    width: Mquery.width(context) - 100,
                    // padding: EdgeInsets.all(5),
                    decoration: BoxDecoration(
                        color: TColor.silver(),
                        borderRadius: BorderRadius.circular(25)),
                    child: Center(
                      child: text(ucword(widget.options[index].toString())),
                    ));
              })),
        ),
      ),
      Container(
          padding: EdgeInsets.all(15),
          color: Colors.white,
          child: Button(
              text: 'Pilih',
              onTap: () {
                setState(() {
                  widget.onSelect(object);
                  widget.initValue.text = selected;
                });
                Navigator.pop(context);
              }))
    ]);
  }
}

/*  SelectCupertino(
      label: 'Label', hint: 'hint', controller: controller,
      options: ['A', 'B', 'C', 'D'] or [{}].map((item) => item['property']).toList()
    ), */

class SelectCupertino extends StatefulWidget {
  SelectCupertino(
      {this.label,
      this.hint,
      this.select,
      @required this.controller,
      this.enabled: true,
      this.suffix,
      this.options,
      this.values});

  final String label, hint;
  final Function select;
  final TextEditingController controller;
  final bool enabled;
  final IconData suffix;
  final List options, values;

  @override
  _SelectCupertinoState createState() => _SelectCupertinoState();
}

class _SelectCupertinoState extends State<SelectCupertino> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          widget.label == null
              ? SizedBox.shrink()
              : Container(
                  margin: EdgeInsets.only(bottom: 7),
                  child: text(widget.label, bold: true),
                ),
          WidSplash(
            onTap: !widget.enabled
                ? null
                : () {
                    modal(context,
                        height: Mquery.height(context) / 2,
                        child: ListCupertino(
                            options: widget.options,
                            values: widget.values,
                            initValue: widget.controller,
                            onSelect: (res) {
                              setState(() {
                                widget.controller.text = res['option'];
                              });

                              if (widget.select != null) widget.select(res);
                            }));
                  },
            color: widget.enabled
                ? Colors.white
                : Color.fromRGBO(232, 236, 241, 1),
            child: Container(
              padding:
                  EdgeInsets.only(left: 15, right: 15, top: 10, bottom: 10),
              width: Mquery.width(context),
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.black12),
                  borderRadius: BorderRadius.circular(2)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Flexible(
                    child: text(
                        widget.controller.text.isEmpty
                            ? widget.hint
                            : widget.controller.text,
                        color: widget.controller.text.isEmpty
                            ? Colors.black45
                            : Colors.black87,
                        overflow: TextOverflow.ellipsis),
                  ),
                  Icon(widget.suffix == null ? Ic.chevron() : widget.suffix,
                      size: 17)
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

class Badges extends StatelessWidget {
  final Widget child;
  final String title;
  final bool showBadge;
  final double start, end, top, bottom;
  Badges(
      {this.child,
      this.title,
      this.showBadge: true,
      this.start,
      this.top: -8,
      this.bottom,
      this.end: -10});

  @override
  Widget build(BuildContext context) {
    return Badge(
      badgeContent: text(title, color: Colors.white, size: 10),
      // shape: BadgeShape.square,
      // borderRadius: BorderRadius.circular(100),
      animationType: BadgeAnimationType.scale,
      position: BadgePosition(start: start, end: end, top: top, bottom: bottom),
      showBadge: showBadge,
      child: child,
    );
  }
}
