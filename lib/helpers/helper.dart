// last update : 21/02/2020

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity/connectivity.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:http/http.dart' as http;

import 'helper-form-control.dart';

// var apiX = 'https://kpm-api.kembarputra.com';

// setApi() async {
//   var prefs = await SharedPreferences.getInstance(),
//       apiString = prefs.getString('api');

//   if(apiString != null){
//     apiX = prefs.getString('api');
//   }
// }

// Future getApi(Function url) async{
//   var prefs = await SharedPreferences.getInstance(),
//       apiUrl = prefs.getString('api');

//       print(apiUrl);

//   if(apiUrl == null){
//     url('https://kpm-api.kembarputra.com');
//   }else{
//     url(apiUrl);
//   }
// }

// test() async{
//   await getApi((res){
//     return res;
//   });
// }

// api(url){
//   test().then((res){
//     return res;
//   });
// }
 
class PreventScrollGlow extends ScrollBehavior { // this class is to prevent scroll glow
  @override
  Widget buildViewportChrome(
    BuildContext context, Widget child, AxisDirection axisDirection) {
    return child;
  }
}

class Hover extends StatelessWidget {
  Hover({this.child, this.elevation : 0, this.onTap, this.padding, this.color, this.radius, this.border}); 
  
  final Widget child;
  final Function onTap;
  final EdgeInsetsGeometry padding;
  final Color color;
  final BorderRadiusGeometry radius;
  final BoxBorder border;
  final double elevation;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: elevation,
      color: color == null ? Colors.transparent : color,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: border,
            // color: color,
          ),
          padding: padding == null ? EdgeInsets.all(0) : padding,
          child: child
        )
      ),
    );
  }
}

class Modal extends StatelessWidget {
  final title;
  final Widget child;
  Modal({this.title, this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
          margin: EdgeInsets.all(10),
          child: ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: Material(
            child: Column(
              children: <Widget>[
                Container(
                  color: Colors.white,
                  child: Column(
                    children: <Widget>[
                
                      Container(
                        height: 40,
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: Colors.black12))
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Container(
                              padding: EdgeInsets.only(left: 15),
                              child: text(title, bold: true),
                            ),

                            GestureDetector(
                              onTap: (){ Navigator.pop(context); },
                              child: Container(
                                padding: EdgeInsets.all(7),
                                child: Icon(Icons.close, color: Colors.redAccent),
                              )
                            )
                            
                        ],)
                      ),

                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          ConstrainedBox(
                            constraints: new BoxConstraints(
                              maxHeight: MediaQuery.of(context).size.height - 100
                            ),
                            child: child,
                          )
                        ],
                      )
                      
                    ],
                  ),
                )
              ],
            ),
          )
        )

        )
      ],
    
    );
  }
}

final oCcy = new NumberFormat("#,##0", "en_US");

number(String n){
  if(n == null){
    return '-';
  }

  var x = double.parse(n).toInt();
  return "${oCcy.format(x)}".replaceAll(',', '.');
}

ucwords(str){
  if(str != '' && str != null){
    var splitStr = str.replaceAll(new RegExp(r"\s+\b|\b\s"), ' ').toLowerCase().split(' ');
    for (var i = 0; i < splitStr.length; i++) {
      if(splitStr[i] != ''){
        splitStr[i] = splitStr[i][0].toUpperCase() + splitStr[i].substring(1);     
      }
    }
    return splitStr.join(' ');
  }else{
    return '';
  }
}

bool isUpperCase(String string) {
  if (string == null) {
    return false;
  }
  if (string.isEmpty) {
    return false;
  }
  if (string.trimLeft().isEmpty) {
    return false;
  }
  String firstLetter = string.trimLeft().substring(0, 1);
  if (double.tryParse(firstLetter) != null) {
    return false;
  }
  return firstLetter.toUpperCase() == string.substring(0, 1);      
}

toast(String msg){
  return Fluttertoast.showToast(
    msg: msg == null ? 'Kesalahan Server' : msg,
    toastLength: Toast.LENGTH_SHORT,
    gravity: ToastGravity.BOTTOM,
    
    timeInSecForIos: 1,
    backgroundColor: Color.fromRGBO(0, 0, 0, .8),
    textColor: Colors.white,
    fontSize: 14.0
  );
}

// periksa koneksi internet, checkConnection().then((con){ print(con); })
checkConnection() async{
  var connectivityResult = await (Connectivity().checkConnectivity());
  if (connectivityResult == ConnectivityResult.mobile) {
    return true;
  } else if (connectivityResult == ConnectivityResult.wifi) {
    return true;
  }else{
    return false;
  }
}

// encode & decode, encode('string'); decode(datajson);
encode(data){ return json.encode(data); }
decode(data){
  if(data != null){
    return json.decode(data); 
  }
}

// set data ke local storage, setPrefs('user', data, true);
setPrefs(key, data, {enc}) async{
  var prefs = await SharedPreferences.getInstance();

  // jika enc tidak null, set enc by param
  if(enc != null){
    prefs.setString(key, enc ? encode(data) : data);
  }else{
    // set enc by data type, [] = List, {} = Map
    if(data is List || data is Map){
      prefs.setString(key, encode(data));
    }

    else if(data is bool){
      prefs.setBool(key, data);
    }

    else if(data is int){
      prefs.setInt(key, data);
    }

    else if(data is String){
      prefs.setString(key, data);
    }

    else{
      prefs.setDouble(key, data);
    }

  }
}

// get data dari local storage, getPrefs('key').then((res){ print(res); });
getPrefs(key, {dec: false}) async{
  var prefs = await SharedPreferences.getInstance();
  var data = prefs.getString(key);
  return data == null ? 'null' : dec ? decode(data) : data;
}

// check data local storage, checkPrefs();
checkPrefs() async{
  var prefs = await SharedPreferences.getInstance();
  print(prefs.getKeys());
}

// clear all local storage, clearPrefs(['user']); -> kecuali data user
clearPrefs({List except}) async{
  var prefs = await SharedPreferences.getInstance(), keys = prefs.getKeys();
  for (var i = 0; i < keys.toList().length; i++) {
    if( except.indexOf(keys.toList()[i]) < 0 ){
      prefs.remove(keys.toList()[i]);
    }
  }
}


appBar(context, {title = '', elevation = 1, back: true, spacing: 15, List<Widget> actions, autoLeading: false}){
  return back ? new AppBar(
    backgroundColor: Colors.white,
    automaticallyImplyLeading: autoLeading,
    titleSpacing: 0,
    elevation: elevation.toDouble(),
    leading: IconButton( onPressed: (){ Navigator.pop(context); }, icon: Icon(Icons.arrow_back), color: Colors.black87, ),
    title: title is Widget ? title : text(title, color: black(), size: 20, bold: true ),
    actions: actions,
  ) : 
  new AppBar(
    backgroundColor: Colors.white,
    automaticallyImplyLeading: autoLeading,
    titleSpacing: spacing.toDouble(),
    elevation: elevation.toDouble(),
    title: title is Widget ? title : text(title, color: black(), size: 20, bold: true ),
    actions: actions,
  );
}

box(context, {dismiss: true, title, message: ''}){
  showDialog(
    context: context,
    barrierDismissible: dismiss,
    builder: (BuildContext context) {

      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Container(
          width: MediaQuery.of(context).size.width,
          margin: EdgeInsets.all(15),
          child: ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: Material(
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: <Widget>[
                Container(
                  color: Colors.white,
                  child: Column(
                    children: <Widget>[
                
                      Container(
                        padding: EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: Colors.black12))
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            title == null ? SizedBox.shrink() : Container(
                              child: html(title, bold: true, size: 17), margin: EdgeInsets.only(bottom: 5), 
                            ),
                            html(message)
                        ],)
                      ),

                    ],
                  ),
                )
              ],
            ),
          )
        )

        )
      ],
    
    );
        
    }
  );
}

emailValidate(String email){
  return email == '' || email == null ? 'Ops!' : RegExp(r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(email);
}

dateTime({format: 'datetime'}){ // datetime, date, time
  var date = new DateTime.now().toString().split('.');
  var dateTime = date[0].split(' ');
  return format == 'datetime' ? date[0] : format == 'date' ? dateTime[0] : dateTime[1];  
}

// date format must be 2019-07-30 13:39:45
dateFormat(date, {format: 'd-M-y', type: 'short'}){
  var dateParse = DateTime.parse(date);
  var bln = ['Januari','Februari','Maret','April','Mei','Juni','Juli','Agustus','September','Oktoberr','November','Desember'];
 
  var x = date.split(' ')[0],
  d = int.parse(x.split('-')[2]).toString().length,
  m = int.parse(x.split('-')[1]).toString().length;

  var dd = 'd', mm = 'M';

  if(d == 1){ dd = '0d'; }
  if(m == 1){ mm = '0M'; }

  _d(dt){ return DateFormat( dt ).format(dateParse); }

  switch (format) {
    case 'd': return DateFormat(d == 1 ? '0d' : 'd').format(dateParse); break;
    case 'M': return DateFormat('MMM').format(dateParse); break;
    case 'F': return DateFormat('MMMM').format(dateParse); break;
    case 'Y': return DateFormat('y').format(dateParse); break;
    default: return type == 'short' ? DateFormat( dd+'-'+mm+'-y' ).format(dateParse) : _d(dd)+' '+bln[int.parse(_d(mm)) - 1]+' '+_d('y');
  }
}

text(text, {color, size: 15, bold: false, align: 'left', spacing: 0, font: 'sans'}){
  return Text(text.toString(), softWrap: true, textAlign: align == 'center' ? TextAlign.center : align == 'right' ? TextAlign.end : TextAlign.start, style: TextStyle(
      color: color == null ? Color.fromRGBO(60, 60, 60, 1) : color, 
      fontFamily: font,
      fontSize: size.toDouble(),
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      letterSpacing: spacing.toDouble(),
    ),
  );
}

nodata({message: '', img: 'no-data.png', Function onRefresh}){
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,

      children: <Widget>[
        Container(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Image.asset('assets/img/'+img, height: 100),
              Container(
                padding: EdgeInsets.all(10),
                child: text(message, color: Colors.black54, size: 15, align: 'center')
              ),
              Container(
                child: onRefresh != null ? IconButton(
                  icon: Icon(Icons.refresh, color: Colors.black54,),
                  onPressed: onRefresh,
                ) : SizedBox.shrink(),
              )
            ],
          ),
          padding: EdgeInsets.all(10),
        )
      ],
    )
  );
}

openMap(latitude, longitude) async {
  String googleUrl = 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
  if (await canLaunch(googleUrl)) {
    await launch(googleUrl);
  } else {
    toast('Tidak dapat membuka map');
  }
}

class Comp{

  textSparate(list, {color: Colors.white}){
    List<Widget> wList = [];

    for (var i = 0; i < list.length; i++) {
      wList.add(
        Container(
          padding: EdgeInsets.only(right: i == list.length - 1 ? 0 : 15),
          margin: EdgeInsets.only(right: i == list.length - 1 ? 0 : 15),
          decoration: BoxDecoration(
            border: Border(right: BorderSide(color: i == list.length - 1 ? Colors.transparent : white(opacity: .5)))
          ),
          child: text(list[i], color: color),
        )
      );
    }

    return wList;
  }
}

modal(context, {Widget child, Function onClose, height: 'full', Color background: Colors.white}) async {
  showModalBottomSheet(
    backgroundColor: background,
    context: context,
    builder: (BuildContext _) {
      return Container(
        height: height != 'full' ? height.toDouble() :  MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top,
        child: child
      );
    },
    isScrollControlled: true,
  ).then((res) { if(onClose != null) onClose(res); });
}

mquery(context, {attr: 'width'}){
  switch (attr) {
    case 'width': return MediaQuery.of(context).size.width; break;
    case 'height': return MediaQuery.of(context).size.height; break;
    case 'p-top': return MediaQuery.of(context).padding.top; break;
  }
}

html(message, {borderBottom, padding: 0, double size: 13, bold: false, TextAlign align}){
  return Container(
    padding: EdgeInsets.all(padding.toDouble()),
    decoration: BoxDecoration(
      border: Border(
        bottom: BorderSide(
          color: borderBottom == null ? Colors.transparent : borderBottom
        )
      )
    ),
    child: Html(data: message, customTextAlign: (node) {
      return align == null ? TextAlign.left : align;
  }, defaultTextStyle: TextStyle(fontFamily: 'sans', fontSize: size, fontWeight: bold ? FontWeight.bold : FontWeight.normal))
  );
}

alertInfo(message){
  return Container(
    child: text(message),
    margin: EdgeInsets.only(bottom: 15),
    padding: EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: Color.fromRGBO(218, 234, 251, 1),
      border: Border.all(color: Color.fromRGBO(204, 226, 250, 1)),
      borderRadius: BorderRadius.circular(5)
    ),
  );
}

timeAgo(datetime){
  Duration compare(DateTime x, DateTime y) {
    return Duration(microseconds: (x.microsecondsSinceEpoch - y.microsecondsSinceEpoch).abs());
  }

  var split = datetime.toString().split(' ');
  var date = split[0].split('-');
  var time = split[1].split(':');

  DateTime x = DateTime.now();
  DateTime y = DateTime(int.parse(date[0]), int.parse(date[1]), int.parse(date[2]), int.parse(time[0]), int.parse(time[1]), int.parse(time[2]));  
  
  var diff = compare(x, y);

  // return 'minute: '+diff.inMinutes.toString()+', second: '+diff.inSeconds.toString();

  if(diff.inSeconds >= 60){
    if(diff.inMinutes >= 60){
      if(diff.inHours >= 24){
        return diff.inDays.toString()+' hari yang lalu';
      }else{
        return diff.inHours.toString()+' jam yang lalu';
      }
    }else{
      return diff.inMinutes.toString()+' menit yang lalu';
    }
  }else{
    return 'baru saja';
  }
}

getDay(datetime){
  Duration compare(DateTime x, DateTime y) {
    return Duration(microseconds: (x.microsecondsSinceEpoch - y.microsecondsSinceEpoch).abs());
  }

  var split = datetime.toString().split(' ');
  var date = split[0].split('-');
  var time = split[1].split(':');

  DateTime x = DateTime.now();
  DateTime y = DateTime(int.parse(date[0]), int.parse(date[1]), int.parse(date[2]), int.parse(time[0]), int.parse(time[1]), int.parse(time[2]));  
  
  var diff = compare(x, y);
  return diff.inDays;
}


  calculateAge(date){
    var today = DateTime.now();
    var birthDate = DateTime.parse(date);
    var age = today.year - birthDate.year;
    var m = today.month - birthDate.month;
    if (m < 0 || (m == 0 && today.day < birthDate.day)) {
        age--;
    }

    return age.toString();
  }

  Widget searchField({Function onChange, controller, hint: '', size: 16, focus: true, enable: true}){
    return new TextField(
      autofocus: focus,
      enabled: enable,
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        border: InputBorder.none,
        hintStyle: TextStyle(color: Colors.black54, fontFamily: 'sans')
      ),
      style: TextStyle(color: Colors.black87, fontSize: size.toDouble(), fontFamily: 'sans'),
      onChanged: onChange,
    ); 
  }

  sparator({height: 30, color, space: 0}){
    return Container(
      margin: EdgeInsets.only(left: space.toDouble(), right: space.toDouble()),
      height: height.toDouble(),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(
            color: color == null ? black() : color
          )
        )
      ),
      child: Text(''),
    );
  }

  alert(String value) {
    BuildContext context;
    Widget cancelButton = FlatButton(
      child: Text("Ok"),
      onPressed:  () { Navigator.pop(context); },
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Alert"),
          content: Text(value),
          actions: [
            cancelButton,
          ],
        );
      },
    );
  }

  

  snackToast(scaffold, msg){
    final snackBar = SnackBar(
      content: Text(msg),
      // action: SnackBarAction(
      //   label: 'Undo',
      //   onPressed: () {
          
      //   },
      // ),
    );
    scaffold.currentState.showSnackBar(snackBar);
  }
  
  generate(){
    return DateTime.now().millisecondsSinceEpoch;
  }

  loader({message: 'Loading...', size: 15.0, color: 'blue'}){
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          SizedBox(
            child: new Container(
              padding: EdgeInsets.all(1),
              child: new CircularProgressIndicator(
                valueColor: new AlwaysStoppedAnimation( color == 'blue' ? Colors.blue : Colors.white),
                strokeWidth: 2.0),
            ),
            height: size,
            width: size,
          ),

          Container(
            margin: EdgeInsets.only(left: message == '' ? 0 : 10),
            child: Text(message),
          )
        ],
      )
    );
  }
  
  

  formControl(controller, {
    mt: 0.0, mb: 0.0, ml: 0.0, mr: 0.0, m: 0.0,
    keyboardType: 'text', length: 255, enabled: true,
    autofocus: false, obsecure: false, hint: ''
  }){
    return Container(
      margin: m != 0.0 ? EdgeInsets.all(m) : EdgeInsets.only(top: mt, bottom: mb, left: ml, right: mr),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        color: Colors.white,
      ),
      child: new TextField(
        inputFormatters: [ LengthLimitingTextInputFormatter(length) ],
        controller: controller,
        enabled: enabled,
        autofocus: autofocus,
        obscureText: obsecure,
        keyboardType: keyboardType == 'text' ? TextInputType.text : keyboardType == 'phone' ? TextInputType.phone : keyboardType == 'email' ? TextInputType.emailAddress : TextInputType.number,
        decoration: new InputDecoration(
          hintText: hint,
          contentPadding: EdgeInsets.all(15),
            border: new OutlineInputBorder( ),
          ),
      ),
    );
  }

  

  outlineInputBorder({circular: 25}){
    return OutlineInputBorder(
      borderSide: BorderSide(color: Colors.black12),
      borderRadius: BorderRadius.circular(circular.toDouble())
    );
  }

  blueColor(){
    return Color.fromRGBO(125, 204, 255, 1);
  }

  black({opacity: 1}){
    return Color.fromRGBO(60, 60, 60, opacity.toDouble());
  }

  white({opacity: 1}){
    return Color.fromRGBO(255, 255, 255, opacity.toDouble());
  }

  background(){
    return Color.fromRGBO(245, 247, 251, 1);
  }
  
  

spiner({size: 15, color: 'blue', stroke: 2, margin: 0, marginX: 0, message: 'loading', position: 'default'}){
  Widget spinerWidget(){
    return Container(
      margin: margin == 0 ? EdgeInsets.only(left: marginX.toDouble(), right: marginX.toDouble()) : EdgeInsets.all(margin.toDouble()),
      child: SizedBox(
        child: new Container(
          padding: EdgeInsets.all(1),
          child: new CircularProgressIndicator(
            valueColor: new AlwaysStoppedAnimation( color == 'blue' ? Colors.blue : Colors.white),
            strokeWidth: stroke.toDouble()),
        ),
        height: size.toDouble(),
        width: size.toDouble(),
      )
    );
  }  

  return position == 'center' ?

  Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[ spinerWidget() ],
    )
  ) : spinerWidget();
}

spin({size: 15, color: 'blue', stroke: 2, margin: 0, marginX: 0, message: 'loading', position: 'default'}){
  Widget spinerWidget(){
    return Container(
      margin: margin == 0 ? EdgeInsets.only(left: marginX.toDouble(), right: marginX.toDouble()) : EdgeInsets.all(margin.toDouble()),
      child: SizedBox(
        child: new Container(
          padding: EdgeInsets.all(1),
          child: new CircularProgressIndicator(
            valueColor: new AlwaysStoppedAnimation( color == 'blue' ? Colors.blue : Colors.white),
            strokeWidth: stroke.toDouble()),
        ),
        height: size.toDouble(),
        width: size.toDouble(),
      )
    );
  }  

  return position == 'center' ?

  Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[ spinerWidget() ],
    )
  ) : spinerWidget();
}

getFirstChar(string, {length: 2}){
  var str = string.split(' ');
  var char = '';

  for (var i = 0; i < str.length; i++) {
    if(i < length){
      char += str[i].substring(0, 1);
    }
  }

  return char.toUpperCase();
}

listSidebar(icon, label, {onTap: Function, subtitle}){
  return Container(
    decoration: BoxDecoration(
      border: Border(bottom: BorderSide(color: Colors.black12))
    ),
    child: subtitle == null ?
      ListTile(
        title: Row(
          children: <Widget>[
            Icon(icon, color: Colors.black54),
            Container(
              padding: EdgeInsets.only(left: 15),
              child: text(label, bold: true)
            )
          ],
        ),
        onTap: onTap
      ) :

      ListTile(
        title: Row(
          children: <Widget>[
            Icon(icon, color: Colors.black54),
            Container(
              padding: EdgeInsets.only(left: 15),
              child: text(label, bold: true)
            )
          ],
        ),
        subtitle: Container(
          margin: EdgeInsets.only(left: 35),
          child: text(subtitle),
        ),
        onTap: onTap
      )
  );
}

class BottomSheetContainer extends StatelessWidget{
  final List<Widget> children;
  BottomSheetContainer({this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 190.0,
      padding: EdgeInsets.only(top: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10)
        )
      ),
      child: Column(
        children: children,
      )
    );
  }

  
}


class FormControl {
    final context, font = 'sans';
    FormControl(this.context);

    numberPicker({initValue,  Function onChange, List<int> options}){
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (BuildContext context){
          return Container(
            height: 150.0,
            padding: EdgeInsets.only(top: 9),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10)
              )
            ),
            child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: CupertinoPicker(
                      scrollController: FixedExtentScrollController(
                        initialItem: initValue,
                      ),
                      itemExtent: 40.0,
                      backgroundColor: Colors.white,
                      onSelectedItemChanged: onChange,
                      children: new List<Widget>.generate(
                      options.length, (int i) {
                        return new Center(
                          child: text(options[i], size: 17),
                        );
                      }
                    )),
                  ),

                ],
              ),
          );
        }
      );
    }

    dropdown(context, {label: 'Label', value, List items, Function onChange}){
      return Container(
        margin: EdgeInsets.only(bottom: 0, top: 10),
        child: new Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            new Container(
              margin: EdgeInsets.only(bottom: 5),
              child: text(label, bold: true),
            ),

            Container(
              width: MediaQuery.of(context).size.width,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: Colors.black26)
              ),
              child: DropdownButtonHideUnderline(
                
                child: ButtonTheme(
                  height: 20,
                  alignedDropdown: true,
                  child: DropdownButton<String>(
                    value: value,
                    onChanged: onChange,
                    items: items.map<DropdownMenuItem<String>>((value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: text(value),
                      );
                    }).toList(),
                  ),
                )
              )
            ),
            
          ],
        ),
      );
    }

    selector({label: '', controller, Function onTap, enabled: true, marginT: 0, marginB: 0}){
      return Container(
        margin: EdgeInsets.only(bottom: marginB.toDouble()),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(top: marginT.toDouble(), bottom: 5),
              child: text(label, bold: true),
            ),

            new Material(
              borderRadius: BorderRadius.circular(3),
              color: enabled ? Colors.white : black(opacity: .04),
              child: InkWell(
                highlightColor: Colors.transparent,
                borderRadius: BorderRadius.circular(5),
                splashColor: Colors.blue[50],
                onTap: enabled ? onTap : null,
                child: Container(
                  padding: EdgeInsets.only(left: 15, top: 10, bottom: 10, right: 15),
                  width: MediaQuery.of(context).size.width,
                  decoration: BoxDecoration(
                    border: Border.all(color: enabled ? Colors.black38 : Colors.black12, ),
                    borderRadius: BorderRadius.circular(5)
                  ),
                  child: text(controller == null ? '' : controller)
                )
              )
            )

          ],
        ),
      );
    }

    formControl(controller, {
      mt: 0.0, mb: 0.0, ml: 0.0, mr: 0.0, m: 0.0,
      keyboardType: 'text', length: 255, enabled: true,
      autofocus: false, obsecure: false, hint: ''
    }){
      return Container(
        margin: m != 0.0 ? EdgeInsets.all(m) : EdgeInsets.only(top: mt, bottom: mb, left: ml, right: mr),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          color: Colors.white,
        ),
        child: new TextField(
          inputFormatters: [ LengthLimitingTextInputFormatter(length) ],
          controller: controller,
          enabled: enabled,
          autofocus: autofocus,
          obscureText: obsecure,
          keyboardType: keyboardType == 'text' ? TextInputType.text : keyboardType == 'phone' ? TextInputType.phone : keyboardType == 'email' ? TextInputType.emailAddress : TextInputType.number,
          decoration: new InputDecoration(
            hintText: hint,
            contentPadding: EdgeInsets.all(15),
              border: new OutlineInputBorder( ),
            ),
        ),
      );
    }

    input({label: '', controller, maxLength: 255, focusNode, type, action, Function onSubmit, Function trailing, obsecure: false, hint: '', bottom: 5, top: 10, enabled: true}){
      return Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(top: label == '' ? 0 : top.toDouble(), bottom: 5),
              child: text(label, bold: true),
            ),
            
            ConstrainedBox(
              constraints: BoxConstraints(minWidth: double.infinity),
              child: Stack(
                alignment: const Alignment(1, -1),
                children: <Widget>[

                  Align(
                    alignment: Alignment.topLeft,
                      child: Container(
                      height: 40,
                      width: trailing is Function ? MediaQuery.of(context).size.width - 90 : MediaQuery.of(context).size.width,
                      margin: EdgeInsets.only(top: 0, bottom: bottom.toDouble()),
                      decoration: BoxDecoration(
                        color: enabled ? Colors.white : black(opacity: 0.05),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: TextField(
                        style: TextStyle(fontFamily: font),
                        obscureText: obsecure,
                        focusNode: focusNode,
                        decoration: new InputDecoration(
                          hintText: hint,
                          contentPadding: EdgeInsets.only(left: 15, right: 15),
                          border: new OutlineInputBorder( ),
                        ),
                        enabled: enabled,
                        controller: controller,
                        keyboardType: type == null ? TextInputType.text : type,
                        textInputAction: action == null ? TextInputAction.done : action,
                        onSubmitted: onSubmit,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(maxLength),
                        ],
                      ),
                    ),
                  ),

                  trailing is Function ?
                    IconButton(
                      icon: Icon(Icons.assignment, color: Colors.black54,),
                      onPressed: trailing,
                    ) : SizedBox.shrink()
                ]
              ),
                
            )
          ],
        ),
      );
    }


    select(context, {label: 'Label', value: '', top: 15, bottom: 15, Function onTap, uc: true, enable: true, Function onCancel}){
      return Container(
        margin: EdgeInsets.only(bottom: 0, top: top.toDouble()),
        child: new Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[

            new Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                new Container(
                  margin: EdgeInsets.only(bottom: 3),
                  child: text(label, bold: true),
                ),
              ],
            ),
            
            GestureDetector(
              onTap: onTap,
              child: Row(
                children: <Widget>[
                  Container(
                    width: onCancel is Function ? MediaQuery.of(context).size.width - 100 : MediaQuery.of(context).size.width - 30,
                    padding: EdgeInsets.only(top: 10, bottom: 10, left: 15, right: 15),
                    decoration: BoxDecoration(
                      color: enable ? Colors.white : black(opacity: .1),
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: Colors.black38)
                    ),
                    child: text( uc ? ucwords(value) : value ),
                  ),
                  
                  onCancel is Function ?
                    Container(
                      margin: EdgeInsets.only(left: 10),
                      height: 38,
                      child: ButtonTheme(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5)
                        ),
                        minWidth: 30,
                        height: 40,
                        child: RaisedButton(
                          color: Colors.white,
                          onPressed: onCancel,
                          child: Icon(Icons.close, color: black(),),
                        ),
                      )
                    ) :

                    SizedBox.shrink()
                ],
              )
            )
          ],
        ),
      );
    }

    static Widget radio({label: '', List<String> values, group, double mt: 20, info: '', Function onChange}){

      List<Widget> list = [];

      for (var i = 0; i < values.length; i++) {
        list.add(
          Container(
            margin: EdgeInsets.only(right: 10, top: 10),
            child: Material(
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                onTap: (){ onChange(values[i], i); },
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  padding: EdgeInsets.only(right: 15),
                  height: 30,
                  decoration: BoxDecoration(
                    border: Border.all(color: i == group ? Colors.blue : Colors.black12),
                    borderRadius: BorderRadius.circular(20)
                  ),
                  child: Row(
                    children: <Widget>[
                      Radio(
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        value: i,
                        groupValue: group,
                        onChanged: (int){
                          onChange(values[i], i);
                        },
                      ), text(ucwords(values[i]))
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Container(
                margin: EdgeInsets.only(top: mt),
                child: text(label, bold: true),
              ),

              text(info, size: 13)
            ],
          ),

          SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row( children: list ))
        ],
      );
      
    }


    textarea({label: 'Label', hint: '', controller, maxlines: 2, bottom: 0}){
      return Container(
        margin: EdgeInsets.only(bottom: bottom.toDouble()),
        child: new Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            label == '' ? SizedBox.shrink() :
            new Container(
              margin: EdgeInsets.only(bottom: 5, top: 15),
              child: text(label, bold: true),
            ),

            new Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(5)
              ),

              child: new TextField(
                style: TextStyle(fontFamily: font),
                keyboardType: TextInputType.text,
                maxLines: maxlines,
                controller: controller,
                decoration: new InputDecoration(
                  hintText: hint,
                  contentPadding: EdgeInsets.only(left: 15, right: 15),
                  border: new OutlineInputBorder( ),
                ),
                
              ),
            )
            
          ],
        ),
      );
    }

    button({label, Function onPressed, width: 'block', marginT: 20, marginY: 15, marginX: 0, color: Colors.redAccent}){
      return ConstrainedBox( constraints: BoxConstraints(minWidth: width == 'block' ?  double.infinity : width.toDouble()),
        child: new Container(
        margin: EdgeInsets.only(bottom: marginY.toDouble(), top: marginT.toDouble(), left: marginX.toDouble(), right: marginX.toDouble()),
          child: new RaisedButton(
            child: label,
            color: color,
            padding: const EdgeInsets.all(5.0),
            shape: new RoundedRectangleBorder(borderRadius: new BorderRadius.circular(5.0)),
            splashColor: Color.fromRGBO(255, 255, 255, .2),
            onPressed: onPressed
          )
        ),
      );
    }

    picker({label: '', initialItem: 0, controlButton = false, top: 15, bottom: 0, options: List, Function onChange, Function onSelect }){
      return Container(
        margin: EdgeInsets.only(bottom: bottom.toDouble()),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          color: Colors.transparent
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(bottom: 5, top: top.toDouble()),
              child: text(label, bold: true)
            ),
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(5),
              child: InkWell(
                borderRadius: BorderRadius.circular(5),
                highlightColor: Colors.transparent,
                splashColor: Colors.blue[50],
                onTap: (){
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    builder: (BuildContext context){

                      return Container(
                        height: 190.0,
                        child: Column(
                          children: <Widget>[

                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(15),
                                topRight: Radius.circular(15)
                              ),
                              child: Stack(
                                children: <Widget>[

                                
                              
                              Column(
                                children: <Widget>[

                                    Expanded(
                                      child: CupertinoPicker(
                                      scrollController: FixedExtentScrollController(
                                        initialItem: initialItem,
                                      ),
                                      itemExtent: 40.0,
                                      backgroundColor: Colors.white,
                                      onSelectedItemChanged: onChange,
                                      children: new List<Widget>.generate(
                                      options.length, (int index) {
                                        return Container(
                                          width: MediaQuery.of(context).size.width - 100,
                                          margin: EdgeInsets.all(2),
                                          decoration: BoxDecoration(
                                            color: black(opacity: .05),
                                            borderRadius: BorderRadius.circular(20)
                                          ),
                                          child: new Center(
                                            child: text( ucwords(options[index]) , size: 17),
                                          ),
                                        );
                                      }
                                    )),
                                ),

                                ],
                              ),

                              Positioned(
                                top: 15, right: 15,
                                child: Btn(
                                  padding: EdgeInsets.all(15),
                                  color: Colors.black12,
                                  radius: BorderRadius.circular(50),
                                  onTap: onSelect == null ? (){ Navigator.pop(context); } : onSelect,
                                  child: text('OK', bold: true),
                                ),
                              )



                              ],
                              )
                            ),
                          ),
                         

                        ],
                        )
                      );
                    }
                  );
                },
                child: Container(
                  padding: EdgeInsets.only(left: 16, right: 16, top: 10, bottom: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black38),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  width: MediaQuery.of(context).size.width,
                  child: text( ucwords(options[initialItem]) ),
                )
              ),
            )
          ],
        )
        
      );
    }
  }

  backArrow(context){
    return IconButton( onPressed: (){ Navigator.of(context).pop(); }, icon: Icon(Icons.arrow_back), color: Colors.black87, );
  }


  class Tf{

    font(){
      return TextStyle(fontFamily: 'sans');
    }

    label(title, {size: 15}){
      return Container(
        margin: EdgeInsets.only(bottom: 5),
        child: text(title, size: size, bold: true, spacing: .5)
      );
    }

    decoration({hint: '', icon}){
      return new InputDecoration(
        prefixIcon: icon is Widget ? Icon(Icons.email) : null,
        contentPadding: EdgeInsets.only(left: 16, right: 16, top: 10, bottom: 10),
        enabledBorder: outlineInputBorder(circular: 5),
        focusedBorder: outlineInputBorder(circular: 5),
        hintText: hint,
      );
    }

    contDecoration({color}){
      return BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        color: color == null ? Colors.transparent : Colors.white
      );
    }

    style(){
      return TextStyle(
        fontFamily: 'sans',
        fontSize: 17
      );
    }

    textfield(context, {label: 'Label', controller, enable: true, type: 'text', max = 255, Function onChange, Function btnControl, obsecure: false, autofocus: false}){

      return Container(
        margin: EdgeInsets.only(bottom: 0, top: 15),
        child: new Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            new Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                new Container(
                  margin: EdgeInsets.only(bottom: 3),
                  child: text(label, bold: true),
                ),
              ],
            ),

            new Row(
              children: <Widget>[
                new Container(
                  height: 40,
                  width: btnControl is Function ? MediaQuery.of(context).size.width - 155 : MediaQuery.of(context).size.width - 80,
                  decoration: BoxDecoration(
                    color: enable ? Colors.white : black(opacity: .1),
                    borderRadius: BorderRadius.circular(5)
                  ),

                  child: new TextField(
                    style: Tf().style(),
                    keyboardType: type == 'text' ? TextInputType.text : type == 'email' ? TextInputType.emailAddress : TextInputType.number,
                    enabled: enable,
                    onChanged: onChange,
                    inputFormatters: [
                      // WhitelistingTextInputFormatter(new RegExp(r'^[a-zA-Z0-9_.]+$')),
                      LengthLimitingTextInputFormatter(max),
                    ],
                    controller: controller,
                    decoration: new InputDecoration(
                      contentPadding: EdgeInsets.only(left: 15, right: 15),
                      border: new OutlineInputBorder( ),
                    ),
                    obscureText: obsecure,
                    autofocus: autofocus,
                  ),
                ),

                btnControl is Function ? 

                Row(
                  children: <Widget>[

                 
                Container(
                  margin: EdgeInsets.only(left: 10),
                  child: ButtonTheme(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(5),
                          bottomLeft: Radius.circular(5),
                        )
                      ),
                    minWidth: 30,
                    height: 40,
                    child: RaisedButton(
                      color: Colors.white,
                      onPressed: (){ 
                        if(controller.text == ''){
                          btnControl('0');
                        }else{
                          var nqty = int.parse(controller.text);
                          if(nqty > 0){
                            btnControl((nqty- 1).toString());
                          }
                        }
                      },
                      child: Icon(Icons.remove, color: black(),),
                    ),
                  )
                ),

                ButtonTheme(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(5),
                      bottomRight: Radius.circular(5),
                    )
                  ),
                  minWidth: 30,
                  height: 40,
                  child: RaisedButton(
                    color: Colors.white,
                    onPressed: (){
                      if(controller.text == ''){
                        btnControl((0 + 1).toString());
                      }else{
                        var nqty = int.parse(controller.text);
                        if(nqty < 9999){
                          btnControl((nqty + 1).toString());
                        }
                      }
                    },
                    child: Icon(Icons.add, color: black(),),
                  ),
                )
                 ],
                )
                : SizedBox.shrink()

              ],
            )

          ],
        ),
      );
    }

    picker(context, {label: 'Label', initialItem: 0, options: List, Function onChange, Function onSelect }){
      return Container(
        margin: EdgeInsets.only(bottom: 15),
        decoration: Tf().contDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(bottom: 5),
              child: text(label)
            ),
            GestureDetector(
              onTap: (){
                showModalBottomSheet(
                  context: context,
                  builder: (BuildContext context){
                    return Container(
                      height: 200.0,
                      color: Colors.white,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          CupertinoButton(
                            child: Icon(Icons.close),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                          Expanded(
                            child: CupertinoPicker(
                              scrollController: FixedExtentScrollController(
                                initialItem: initialItem,
                              ),
                              itemExtent: 40.0,
                              backgroundColor: Colors.white,
                              onSelectedItemChanged: onChange,
                              children: new List<Widget>.generate(
                              options.length, (int index) {
                                return new Center(
                                  child: text( ucwords(options[index]) , size: 17),
                                );
                              }
                            )),
                          ),
                          CupertinoButton(
                            child: Icon(Icons.check_circle_outline),
                            onPressed: onSelect
                          ),
                        ],
                      ),
                    );
                  }
                );
              },
              child: Container(
                padding: EdgeInsets.only(left: 16, right: 16, top: 10, bottom: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black26),
                  borderRadius: BorderRadius.circular(5),
                  color: Colors.white
                ),
                width: MediaQuery.of(context).size.width,
                child: text( ucwords(options[initialItem]) ),
              )
            )
          ],
        )
        
      );
    }

    textarea(context, {label: 'Label', controller, maxlines: 2}){
      return Container(
        margin: EdgeInsets.only(bottom: 15),
        child: new Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            new Container(
              margin: EdgeInsets.only(bottom: 5),
              child: text(label),
            ),

            new Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.black26),
                borderRadius: BorderRadius.circular(5)
              ),

              child: new TextField(
                style: Tf().style(),
                keyboardType: TextInputType.text,
                maxLines: maxlines,
                controller: controller,
                decoration: new InputDecoration(
                  contentPadding: EdgeInsets.all(15),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black26, width: 0.0),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black26, width: 0.0),
                  ),
                )
              ),
            )
            
          ],
        ),
      );
    }

    button({Widget child, Function onPressed, radius: 5, color, background, y: 0}){
      return new ConstrainedBox(
        constraints: BoxConstraints(minWidth: double.infinity),
        child: new Container(
            margin: EdgeInsets.only(bottom: y.toDouble(), top: y.toDouble()),
            child: new RaisedButton(
              shape: RoundedRectangleBorder(borderRadius: new BorderRadius.circular( radius.toDouble() )),
              child: child,
              color: color == null ? background : color,
              padding: const EdgeInsets.all(10),
              splashColor: Color.fromRGBO(255, 255, 255, .2),
              onPressed: onPressed
            )),
      );
    }

    

  }

  class Elm{

    tab(context, {icon, itemCount: 1, radiusLeft: false, radiusRight: false, sparator: false, Function onTap}){
      return Container(
        width: MediaQuery.of(context).size.width / itemCount - 10.7,
        decoration: BoxDecoration(
          border: sparator ? Border(
            right: BorderSide(color: Colors.black12)
          ) : null
        ),
        child: new Material(
          color: Colors.transparent,
          child: new InkWell(
            highlightColor: black(opacity: .07),
            splashColor: Colors.transparent,
            borderRadius: !radiusLeft && !radiusRight ? null :
             radiusLeft && !radiusRight ?
              BorderRadius.only(
                topLeft: Radius.circular(25),
                bottomLeft: Radius.circular(25)
              ) : 
              BorderRadius.only(
                topRight: Radius.circular(25),
                bottomRight: Radius.circular(25)
              ),
            onTap: onTap,
            child: Container(
              padding: EdgeInsets.all(5),
              child: Column(
                children: <Widget>[
                  Icon(icon, color: Colors.black45,)
                ],
              )
            )
          ),
        ),
      );
    }

    textfield(context, {label: 'Label', controller, icon: IconData, enable: true, type: 'text', max = 255, Function onChange, obsecure: false, autofocus: false,
              hint: '', bottom: 0}){

      return Container(
        margin: EdgeInsets.only(bottom: bottom.toDouble()),
        child: new Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            new Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                new Container(
                  margin: EdgeInsets.only(bottom: label != '' ? 3 : 0),
                  child: text(label),
                ),
              ],
            ),

            new ConstrainedBox(
              constraints: const BoxConstraints(minWidth: double.infinity),
              child: new Container(
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                  color: enable ? Colors.white : black(opacity: .1),
                  border: Border.all(color: black(opacity: .3)),
                  borderRadius: BorderRadius.circular(5)
                ),

                child: new TextField(
                  style: TextStyle(
                    fontFamily: 'sans',
                    fontSize: 17
                  ),
                  keyboardType: type == 'text' ? TextInputType.text : type == 'email' ? TextInputType.emailAddress : TextInputType.number,
                  enabled: enable,
                  onChanged: onChange,
                  inputFormatters: [
                    // WhitelistingTextInputFormatter(new RegExp(r'^[a-zA-Z0-9_.]+$')),
                    LengthLimitingTextInputFormatter(max),
                  ],
                  controller: controller,
                  decoration: new InputDecoration(
                    prefixIcon: icon == IconData ? null : Icon(icon, size: 20, color: Colors.black38,),
                    hintText: hint,
                    hintStyle: TextStyle(
                      fontFamily: 'sans',
                    fontSize: 17
                    ),
                    contentPadding: EdgeInsets.all(10),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.transparent, width: 0.0),
                      borderRadius: BorderRadius.circular(5)
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.transparent, width: 0.0),
                      borderRadius: BorderRadius.circular(5)

                    ),
                  ),
                  obscureText: obsecure,
                  autofocus: autofocus,
                ),
              )
            )

          ],
        ),
      );
    }

    datePicker(context, {Function onChange, value}){
      var dateParse = value == '' || value == null ? 'now' : DateTime.parse(value);

      showModalBottomSheet(
        context: context,
        builder: (BuildContext builder) {
          return Container(
            height: MediaQuery.of(context).copyWith().size.height / 3,
            child: CupertinoDatePicker(
              initialDateTime: dateParse == 'now' ? DateTime.now() : dateParse,
              onDateTimeChanged: (DateTime newdate) {
                onChange(newdate.toString().split(' ')[0]);
              },
              use24hFormat: true,
              maximumDate: DateTime.now(),
              minimumYear: 2018,
              maximumYear: DateTime.now().year,
              minuteInterval: 1,
              mode: CupertinoDatePickerMode.date,
            )
            
            );
        });
    }



  }


class Button extends StatelessWidget{
  final Function onTap; 
  final style;
  final label;
  final margin;

  Button({this.onTap, this.style: 'default', this.label: 'OK', this.margin});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin == null ? EdgeInsets.all(0) : margin,
      child: Hover(
        // radius: 5,
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.only(left: 15, right: 15, top: 10, bottom: 10),
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black12),
            borderRadius: BorderRadius.circular(5),
            color: black(opacity: .05)
          ),
          child: text(label, spacing: 1, bold: true, color: Colors.blue, align: 'center'),
        ) 
      ),
    );

  }
}

class XButton extends StatelessWidget {
  final Function onTap;
  final padding;

  XButton({this.onTap, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Material(
        child: InkWell(
          highlightColor: Colors.black12,
          splashColor: Colors.black12,
          onTap: onTap,
          child: Container(
            padding: padding == null ? EdgeInsets.all(15) : padding,
            child: Icon(Icons.close, color: Colors.redAccent),
          ),
        ),
      ),
    );
  }
}

class ShowUp extends StatefulWidget {
  final Widget child;
  final int delay;

  ShowUp({@required this.child, this.delay});

  @override
  _ShowUpState createState() => _ShowUpState();
}

class _ShowUpState extends State<ShowUp> with TickerProviderStateMixin {
  AnimationController _animController;
  Animation<Offset> _animOffset;

  @override
  void initState() {
    super.initState();

    _animController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 500));
    final curve =
        CurvedAnimation(curve: Curves.decelerate, parent: _animController);
    _animOffset =
        Tween<Offset>(begin: const Offset(0.0, 0.35), end: Offset.zero)
            .animate(curve);

    if (widget.delay == null) {
      _animController.forward();
    } else {
      Timer(Duration(milliseconds: widget.delay), () {
        _animController.forward();
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
    _animController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      child: SlideTransition(
        position: _animOffset,
        child: widget.child,
      ),
      opacity: _animController,
    );
  }
}


class Foo {
    final context, font = 'sans';
    Foo({this.context});

    static Widget input({label: '', hint: '', length: 255, count: false, Function onChange, lines: 1, double mt: 35, TextEditingController controller, FocusNode node, TextInputType keyboard, TextInputAction inputAction, Function onSubmit}){

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          
          Container(
            margin: EdgeInsets.only(top: mt),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                text(label, bold: true),
                count ? text(controller.text.length.toString()+'/'+length.toString()) : SizedBox.shrink()
              ],
            )
          ),

          TextField(
            controller: controller,
            focusNode: node,
            maxLines: lines,
            keyboardType: keyboard,
            textInputAction: inputAction,
            onSubmitted: onSubmit,
            onChanged: onChange,
            decoration: new InputDecoration(
              alignLabelWithHint: true,
              isDense: true,
              hintText: hint,
              hintStyle: TextStyle(fontFamily: 'sans')
            ),
            style: TextStyle(fontFamily: 'sans'),
            inputFormatters: [
              LengthLimitingTextInputFormatter(length),
            ],
          ),
        ],
      );
    }

    static Widget radio({label: '', List<String> values, group, double mt: 35, Function onChange}){

      List<Widget> list = [];

      for (var i = 0; i < values.length; i++) {
        list.add(
          Container(
            margin: EdgeInsets.only(right: 10, top: 10),
            child: Material(
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                onTap: (){ onChange(values[i], i); },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: EdgeInsets.only(right: 15),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black12),
                    borderRadius: BorderRadius.circular(20)
                  ),
                  child: Row(
                    children: <Widget>[
                      Radio(
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        value: i,
                        groupValue: group,
                        onChanged: (int){
                          onChange(values[i], i);
                        },
                      ), text(ucwords(values[i]))
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            margin: EdgeInsets.only(top: mt),
            child: text(label, bold: true),
          ),

          SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row( children: list ))
        ],
      );
      
    }

    // widget seperti select option, bisa digunakan untuk pengambilan tanggal
    static Widget select({label: '', hint: '', double mt: 0, caret: true, TextEditingController controller, Function onTap}){
      return Container(
        margin: EdgeInsets.only(top: mt),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            label == '' ? SizedBox.shrink() :
            Container(
              child: text(label, bold: true),
            ),

            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(3),
              child: InkWell(
                borderRadius: BorderRadius.circular(3),
                onTap: onTap,
                child: Stack(
                  children: <Widget>[

                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.only(top: 10, bottom: 10, left: 15, right: 15),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.black26
                        ),
                        borderRadius: BorderRadius.circular(3)
                      ),
                      child: text(controller.text == null || controller.text.isEmpty ? hint : controller.text, size: 16, color: controller.text == null || controller.text.isEmpty ? Colors.black54 : Colors.black87),
                    ),

                    caret ? 
                    Positioned(
                      child: Icon(Icons.keyboard_arrow_down, color: Colors.black38),
                      right: 5, top: 10,
                    ) : SizedBox.shrink(),

                  ],
                )
                
              ),
            ),

          ],
        )
        
      );
    }

    static Widget select2({label: '', hint: '', double width: 100, double mt: 0, caret: true, TextEditingController controller, Function onTap}){
      return Container(
        margin: EdgeInsets.only(top: mt),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              child: text(label, bold: true),
            ),

            Material(
              child: InkWell(
                onTap: onTap,
                child: Stack(
                  children: <Widget>[

                    Container(
                      width: width,
                      padding: EdgeInsets.only(top: 7, bottom: 7),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.black38
                          )
                        )
                      ),
                      child: text(controller.text == null || controller.text.isEmpty ? hint : controller.text, size: 16, color: controller.text == null || controller.text.isEmpty ? Colors.black54 : Colors.black87),
                    ),

                    caret ? 
                    Positioned(
                      child: Icon(Icons.keyboard_arrow_down, color: Colors.black38),
                      right: 0, top: 6,
                    ) : SizedBox.shrink(),

                  ],
                )
                
              ),
            ),

          ],
        )
        
      );
    }

    // fungsi untuk menampilkan dan memilih inputan
    static cupertinoSelector(context, {initialItem, List options, uppercase: false, Function onChange}){
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (BuildContext context){

          return Container(
            height: 190.0,
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15)
              ),
              child: Column(
                children: <Widget>[

                    Expanded(
                      child: CupertinoPicker(
                      scrollController: FixedExtentScrollController(
                        initialItem: initialItem,
                      ),
                      itemExtent: 40.0,
                      backgroundColor: Colors.white,
                      onSelectedItemChanged: onChange,
                      children: new List<Widget>.generate(
                      options.length, (int index) {
                        return new Center(
                          child: text( uppercase ? ucwords(options[index]) : options[index] , size: 17),
                        );
                      }
                    )),
                ),

                ],
              ),
            ),
           
          );
        }
      );
    }

    static Widget button({label: '', double width: 100, match: true, Widget child, Color color, Function onTap, double mt: 35, double mb: 15, double mr: 0, double ml: 0}){
      return Container(
        margin: EdgeInsets.only(top: mt, bottom: mb, right: mr, left: ml),
        child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: match ? double.infinity : width),
          child: RaisedButton(
            shape: RoundedRectangleBorder(borderRadius: new BorderRadius.circular(3)),
            child: child, color: color,
            elevation: 0,
            padding: EdgeInsets.all(10),
            splashColor: Color.fromRGBO(255, 255, 255, .2),
            onPressed: onTap
          )
        ),
      );
    }





    numberPicker({initValue,  Function onChange, List<int> options}){
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (BuildContext context){
          return Container(
            height: 150.0,
            padding: EdgeInsets.only(top: 9),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10)
              )
            ),
            child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: CupertinoPicker(
                      scrollController: FixedExtentScrollController(
                        initialItem: initValue,
                      ),
                      itemExtent: 40.0,
                      backgroundColor: Colors.white,
                      onSelectedItemChanged: onChange,
                      children: new List<Widget>.generate(
                      options.length, (int i) {
                        return new Center(
                          child: text(options[i], size: 17),
                        );
                      }
                    )),
                  ),

                ],
              ),
          );
        }
      );
    }

    dropdown(context, {label: 'Label', value, List items, Function onChange}){
      return Container(
        margin: EdgeInsets.only(bottom: 0, top: 10),
        child: new Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            new Container(
              margin: EdgeInsets.only(bottom: 5),
              child: text(label, bold: true),
            ),

            Container(
              width: MediaQuery.of(context).size.width,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: Colors.black26)
              ),
              child: DropdownButtonHideUnderline(
                
                child: ButtonTheme(
                  height: 20,
                  alignedDropdown: true,
                  child: DropdownButton<String>(
                    value: value,
                    onChanged: onChange,
                    items: items.map<DropdownMenuItem<String>>((value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: text(value),
                      );
                    }).toList(),
                  ),
                )
              )
            ),
            
          ],
        ),
      );
    }

}

class Btn extends StatelessWidget {
  Btn({this.child, this.elevation : 0, this.onTap, this.onLongPress, this.onTapDown, this.onTapCancel, this.padding, this.color, this.radius, this.border}); 
  
  final Widget child;
  final Function onTap, onLongPress, onTapCancel, onTapDown;
  final EdgeInsetsGeometry padding;
  final Color color;
  final BorderRadiusGeometry radius;
  final BoxBorder border;
  final double elevation;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: elevation,
      color: color == null ? Colors.transparent : color,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        onTapCancel: onTapCancel,
        onTapDown: onTapDown,
        borderRadius: radius,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: border,
            // color: color,
          ),
          padding: padding == null ? EdgeInsets.all(10) : padding,
          child: child
        )
      ),
    );
  }
}


class Confirmate extends StatefulWidget {
  Confirmate({this.api}); final api;

  @override
  _ConfirmateState createState() => _ConfirmateState();
}

class _ConfirmateState extends State<Confirmate> {

  var isDelete = false;

  void delete(){
    setState(() => isDelete = true );

    try {
      Api.delete(widget.api, then: (res){
        
        if(res.statusCode == 200){
          toast('Berhasil dihapus');
          Navigator.pop(context, {'deleted': true});
        }else{
          setState(() => isDelete = true );
          Message.error(res); 
        }

      });
    } catch (e) {
      Message.error(e);
      setState(() => isDelete = true );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [

        Material(
          color: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(15),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: Container(
                width: mquery(context),
                decoration: BoxDecoration(
                  color: white()
                ),
                child: Column(
                  children: [

                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.only(top: 25, bottom: 20),
                      child: text('Yakin ingin menghapus data ini?', align: 'center'),
                    ),

                    Row(
                      children: List.generate(2, (int i){
                        var b = ['BATAL','IYA'], btn = text(b[i], align: 'center', color: i == 0 ? Colors.black87 : Colors.white);

                        return Btn(
                          onTap: isDelete ? null : (){
                            switch (i) {
                              case 0: Navigator.pop(context); break;
                              default: delete(); break;
                            }
                          },
                          color: i == 0 ? black(opacity: .05) : Colors.red[400],
                          child: Container(
                            width: mquery(context) / 2 - 35,
                            child: i == 0 ? btn : isDelete ? Container(child: spiner(color: white(), position: 'center')) : btn,
                          ),
                        );
                      })
                    )

                  ]
                )
              )
            )
          )
        )

      ]
    );
  }
}



// fix helper
class Fn{

}

class Message{

  static error(e, {String message: 'Terjadi kesalahan', Timer timer}){
    print('error : '+e.toString());
    toast(message);

    if(timer != null){
      timer.toString();
    }
  }

  static connection(context, {Timer timer}){
    box(context, title: 'Network Connection!', message: 'Sepertinya terjadi masalah pada koneksi internet Anda, periksa jaringan dan pastikan koneksi internet Anda stabil.');
    if(timer != null){
      timer.cancel();
    }
  }

  static fail({obj, String message: 'Terjadi kesalahan', Timer timer}){
    toast(message);
    if(timer != null){
      timer.cancel();
    }

    if(obj != null){
      print(obj.request);
      print(obj.statusCode);
      print(obj.body);
    }
  }

}

class Input{

  static selector(){

  }

  static number({title: '', hint: '', TextEditingController controller, Function onChange}){
    return InputNumber(
      title: title,
      hint: hint,
      controller: controller,
      onChange: onChange,
    );
  }

  static date({title: '', hint: '', TextEditingController controller, DateTime min, DateTime max}){
    return InputDate(
      title: title,
      hint: hint,
      controller: controller,
      min: min, max: max
    );
  }
}


class Wi{

  static datePicker(context, {initDate, DateTime min, DateTime max}) async {
    final DateTime picked = await showDatePicker(
      context: context,
      initialDate: initDate,
      firstDate: min == null ? DateTime(2000, 0) : min,
      lastDate: max == null ? DateTime(2030) : max
    );

    var d = picked.toString().split(' ');

    if(picked != null){
      return d[0];
    }
  }

  static confirmate(context, {String api, Function onClose}){
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return ShowUp(
          child: Confirmate(api: api),
        );
      }
    ).then((res){
      if(onClose != null){
        onClose(res);
      }
    });
  }

  static options(context, {List options, Function onSelect, Function onClose}){
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Material(
              color: Colors.transparent,
              child: Container(
                padding: EdgeInsets.all(15),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: Container(
                    width: mquery(context),
                    decoration: BoxDecoration(
                      color: Colors.white,
                    ),
                    child: Column(
                      children: List.generate(options.length, (int i){
                        return Btn(
                          onTap: (){ onSelect(options[i]); },
                          padding: EdgeInsets.all(0),
                          child: Container(
                            padding: EdgeInsets.all(15),
                            width: mquery(context),
                            decoration: BoxDecoration(
                              border: i == 0 ? Border() : Border(top: BorderSide(color: Colors.black12))
                            ),
                            child: text(ucwords(options[i])),
                          ),
                        );
                      }),
                    ),
                  )
                )
              )
            ),
          ]
        );
      }
    ).then((res){
      if(onClose != null){
        onClose(res);
      }
    });
  }

  static poplist(context, {title, List labels, List values, dismiss: true}){
    showDialog(
      context: context,
      barrierDismissible: dismiss,
      builder: (BuildContext context) {
        return SingleChildScrollView(
          child: ShowUp(
            child: Column(
              children: [
                Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: EdgeInsets.all(15),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: mquery(context),
                        decoration: BoxDecoration(
                          color: white()
                        ),
                        child: Column(
                          children: [
                            // header
                            Container(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    margin: EdgeInsets.only(left: 15),
                                    child: text(title, bold: true),
                                  ),
                                  
                                  Btn(
                                    onTap: (){ Navigator.pop(context); },
                                    child: Icon(Icons.close, color: Colors.black54)
                                  )
                                ]
                              )
                            ),

                            // body
                            Container(
                              child: Column(
                                children: List.generate(labels.length, (int i){
                                  return Container(
                                    width: mquery(context),
                                    padding: EdgeInsets.only(left: 15, right: 15, top: 10, bottom: 10),
                                    color: i % 2 == 0 ? black(opacity: .05) : white(),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        text(ucwords(labels[i]), bold: true),
                                        text(values[i])
                                      ]
                                    ),
                                  );
                                })
                              ),
                            )
                          ]
                        )
                      ),
                    ),
                  )
                )
              ]
            ),
          ),
        );
      }
    );
  }

  static search({hint: '', Function onChange}){
    return new TextField(
      autofocus: true,
      decoration: InputDecoration(
        hintText: hint,
        border: InputBorder.none,
        hintStyle: const TextStyle(color: Colors.black54)
      ),
      style: TextStyle(color: Colors.black87, fontSize: 16),
      onChanged: onChange,
    );
  }
}

class Api{

  static apii(url) async{
    var prefs = await SharedPreferences.getInstance(),
        _url = prefs.getString('api');

    print(_url);

  }

  static post(url, {@required formData, Function then}) async {
    var prefs = await SharedPreferences.getInstance();

    http.post(apii(url), body: formData, headers: {
      HttpHeaders.authorizationHeader: prefs.getString('token'), "Accept": "application/json"
    }).then((res){
      print(res.headers);
      print(res.body);
      print(res.request);

      if(then != null) then(res);
    });
  }

  static get(url, {Function then}) async {
    var prefs = await SharedPreferences.getInstance();

    http.get(apii(url), headers: {
      HttpHeaders.authorizationHeader: prefs.getString('token'), "Accept": "application/json"
    }).then((res){ 
      if(then != null) then(res);
    });
  }

  static put(url, {@required formData, Function then}) async {
    var prefs = await SharedPreferences.getInstance();

    http.put(apii(url), body: formData, headers: {
      HttpHeaders.authorizationHeader: prefs.getString('token'), "Accept": "application/json"
    }).then((res){ 
      if(then != null) then(res);
    });
  }

  static delete(url, {Function then}) async {
    var prefs = await SharedPreferences.getInstance();

    http.delete(apii(url), headers: {
      HttpHeaders.authorizationHeader: prefs.getString('token'), "Accept": "application/json"
    }).then((res){ 
      if(then != null) then(res);
    });
  }
  
}

