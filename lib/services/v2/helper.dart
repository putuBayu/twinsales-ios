import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:flutter_html/flutter_html.dart';
import 'dart:math' as math;
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sales/services/constant.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity/connectivity.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:date_range_picker/date_range_picker.dart' as DateRagePicker;
import 'package:flutter_statusbarcolor/flutter_statusbarcolor.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:intl/date_symbol_data_local.dart';

// methods

// text('lorem ipsum dolor')
Widget text(text, {color, size: 15, bold: false, TextAlign align: TextAlign.left, spacing: 0, double height: 1.3, font: 'Nunito', TextOverflow overflow}){
  return Text(
    text.toString(), overflow: overflow, softWrap: true, textAlign: align, style: TextStyle(
      color: color == null ? TColor.black() : color,
      fontFamily: font, height: height,
      fontSize: size.toDouble(),
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      letterSpacing: spacing.toDouble(),
    ),
  );
}

// html('lorem ipsum <b>dolor</b>')
html(message, {double padding: 0, double size: 14, bold: false, Color color, TextAlign align: TextAlign.left}){
  return Container(
    padding: EdgeInsets.all(padding),
    child: Html(data: message, customTextAlign: (node) { return align; },
    defaultTextStyle: TextStyle(fontFamily: 'Nunito', fontSize: size, color: color == null ? Colors.black87 : color, fontWeight: bold ? FontWeight.bold : FontWeight.normal))
  );
}

// set fokus textfield, focus(context, emailNode)
focus(context, node){
  FocusScope.of(context).requestFocus(node);
}

// daysInterval(DateTime(2020, 06, 01), DateTime.now())
List<DateTime> daysInterval(DateTime startDate, DateTime endDate) {
  List<DateTime> days = [];
  for (int i = 0; i <= endDate.difference(startDate).inDays; i++) {
    days.add(startDate.add(Duration(days: i)));
  }
  return days;
}

modal(context, {@required Widget child, bool wrap: false, double radius: 5, double height, Function then}){
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
          color: Colors.white,
          child: Wrap(
            children: <Widget>[ child ]
          ),
        ),
      );
    }
  ).then((value){ if(then != null) then(value); });
}

// ribuan(1500) -> 1.500, ribuan(1300.2), -> 1.300,2
// ribuan(50, cur: '\$') -> $50, ribuan(1300.50, fixed: 1) -> 1.300,5
ribuan(number, {String cur, int fixed}){
  final nf = new NumberFormat("#,##0", "en_US");
  if(number == null){ return 'null'; }

  var n = number.toString(), split = [];
  if(n.indexOf('.') > -1){
    n.split('.').forEach((f){
      split.add(f);
    });

    split[1] = fixed == null ? ','+split[1] : fixed == 0 ? '' : ','+split[1].substring(0, fixed);
    var res = nf.format(int.parse(split[0])).replaceAll(',', '.')+''+split[1];
    return cur != null ? cur+''+res : res;
  }

  number = number is String ? int.parse(number) : number;
  var res = nf.format(number).replaceAll(',', '.');
  return cur != null ? cur+''+res : res;
}

// ucwords('lorem ipsum') -> Lorem Ipsum
ucword(String str){
  if(str == '' || str == null) {
    return '';
  }

  var split = str.split(' ');
  for (var i = 0; i < split.length; i++) {
    if(split[i] != ''){
      split[i] = split[i][0].toUpperCase() + split[i].substring(1);
    }
  }
  return split.join(' ');
}

// periksa koneksi seluler & wifi, checkConnection().then((con){ })
checkConnection() async{
  var connectivityResult = await (Connectivity().checkConnectivity()),
      mobile = connectivityResult == ConnectivityResult.mobile,
      wifi = connectivityResult == ConnectivityResult.wifi;

  return mobile || wifi ? true : false;
}

// goto('https://google.com')
goto(url){ launch(url); }

// statusBar(color: Colors.transparent, darkText: false);
statusBar({@required Color color, bool darkText: true}) async{
  await FlutterStatusbarcolor.setStatusBarColor(color);
      FlutterStatusbarcolor.setStatusBarWhiteForeground( !darkText );
}

// Timer timer = setTimer(3, then: (t){ })
setTimer(second, {then}){
  return Timer(Duration(seconds: second), (){
    if(then != null) then(true);
  });
}

// encode & decode, encode(object) -> string, decode(string) -> object
encode(data){ return json.encode(data); }
decode(data){ if(data != null) return json.decode(data); }

// set data lokal, setPrefs('key', data)
setPrefs(key, data, {enc: false}) async{
  var prefs = await SharedPreferences.getInstance();

  if(data is List || data is Map){ prefs.setString(key, encode(data)); }
  else if(data is bool){ prefs.setBool(key, data); }
  else if(data is int){ prefs.setInt(key, data); }
  else if(data is String){ prefs.setString(key, enc ? encode(data) : data); }
  else{ prefs.setDouble(key, data); }
}

// get data lokal, getPrefs('key', type: String).then((res){ });
getPrefs(key, {dec: false, type: String}) async{
  var prefs = await SharedPreferences.getInstance();

  switch (type) {
    case List: return decode(prefs.getString(key)); break;
    case Map: return decode(prefs.getString(key)); break;
    case bool: return prefs.getBool(key); break;
    case int: return prefs.getInt(key); break;
    case String: return prefs.getString(key) == null ? null : dec ? decode(prefs.getString(key)) : prefs.getString(key); break;
    case double: return prefs.getDouble(key);
  }
}

// getPrefx(['user|s', 'id|i'], then: (res){  }), -> ['user|s'] = key user dengan tipe data string
getPrefx(List keys, Function then) async{
  var prefs = await SharedPreferences.getInstance();

  var data = [];
  keys.forEach((f){
    var k = f.split('|')[0];

    try {
      if(f.split('|').length > 1){
        var t = f.split('|')[1];

        switch (t) {
          case 's': data.add(prefs.getString(k)); break;
          case 'i': data.add(prefs.getInt(k)); break;
          case 'd': data.add(prefs.getDouble(k)); break;
          case 'b': data.add(prefs.getBool(k)); break;
        }
      }else{
        data.add(prefs.getString(k));
      }
    } catch (e) {
      data.add(null);
    }
    
  });

  then(data);
}

// periksa data lokal, checkPrefs()
checkPrefs() async{
  var prefs = await SharedPreferences.getInstance();
  print(prefs.getKeys());
}

// bersihkan data lokal, clearPrefs() -> clear all, clearPrefs(except: ['user']) -> kecuali user
clearPrefs({List except}) async{
  var prefs = await SharedPreferences.getInstance(), keys = prefs.getKeys();
  for (var i = 0; i < keys.toList().length; i++) {
    if(except == null){
      prefs.remove(keys.toList()[i]);
    }else{
      if(except.indexOf(keys.toList()[i]) < 0){
        prefs.remove(keys.toList()[i]);
      }
    }
  }
}

// removePrefs(['user']) -> hapus user
removePrefs({List list}) async{
  var prefs = await SharedPreferences.getInstance(), keys = prefs.getKeys();

  for (var i = 0; i < keys.toList().length; i++) {
    if(list.indexOf(keys.toList()[i]) > -1){
      prefs.remove(keys.toList()[i]);
    }
  }
}

// validasi email, emailValidate('lorem@gmail.com') -> true
emailValidate(String email){
  return email == null || email == '' ? false : RegExp(r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(email);
}

// format valid -> yyyy-mm-dd hh:ii:ss, dateFormat('2020-04-12 22:30:15', format: 'd-m-y') -> 12-04-2020 || ...format: 'd/m/y') -> 12/04/2020
dateFormat(date, {format: 'd-m-y'}){
  var bln = ['Januari','Februari','Maret','April','Mei','Juni','Juli','Agustus','September','Oktoberr','November','Desember'];

  var pattern = {'d': 2, 'm': 1, 'M': 1, 'y': 0, 'h': 3, 'i': 4, 's': 5}, // pola
      dateTime = date.replaceAll(':', '-').replaceAll(' ', '-'), result = [];

  format.split('').forEach((f){
    if(pattern[f] != null){
      if(f == 'M'){
        result.add(bln[ int.parse(dateTime.split('-')[pattern[f]]) - 1 ]);
      }else{
        result.add(dateTime.split('-')[pattern[f]]);
      }
    }else{
      result.add(f);
    }
  });

  return result.join('').toString();
}

timestamp(){
  return DateTime.now().millisecondsSinceEpoch;
}

// format valid -> yyyy-mm-dd hh:ii:ss, waktu yang lalu, timeAgo('2020-04-12 22:30:15') -> 2 jam yang lalu
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

  if(y.millisecondsSinceEpoch > x.millisecondsSinceEpoch){
    return '-';
  }else{
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
}

// hitung umur, calcAge('1995-11-05') -> 26
calcAge(date){
  if(date == null || date == ''){
    return '-';
  }else{
    var today = DateTime.now(),
        birthDate = DateTime.parse(date),
        age = today.year - birthDate.year,
        m = today.month - birthDate.month;

    if (m < 0 || (m == 0 && today.day < birthDate.day)) {
        age--;
    }

    return age < 0 ? '-' : age;
  }
}

// buka google map by kordinat, openMap(-8502322, 1520239)
openMap(latitude, longitude) async {
  String googleUrl = 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
  if (await canLaunch(googleUrl)) {
    await launch(googleUrl);
  }
}

// firstChar('lorem ipsum') -> LI, firstChar('lorem ipsum', length: 1) -> L
firstChar(string, {length: 2}){
  var str = string.split(' ');
  var char = '';

  for (var i = 0; i < str.length; i++) {
    if(i < length){
      char += str[i].substring(0, 1);
    }
  }

  return char.toUpperCase();
}

// get file size, formatBytes(1500) -> 1.46 KB
formatBytes(bytes, {decimals: 2}){
  if(bytes == 0) return '0 Bytes';

  var k = 1024,
      dm = decimals < 0 ? 0 : decimals,
      sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];

  var i = (math.log(bytes) / math.log(k)).floor();

  return (bytes / math.pow(k, i)).toStringAsFixed(dm)+' '+sizes[i];
}

// potong pertengahan string, cutHalf('lorem ipsum dolor set amet', maxLength: 5) -> lorem ipsum...er amet
cutHalf(String str, {int maxLength: 40}){
  if(str.length < maxLength) return str;

  var ls = str.length,
      first = str.substring(0, ((ls/3).round()) + (maxLength/3).round()),
      end = str.substring(ls - 7, ls);

  return first+'...'+end;
}

isEnabledLocation({@required Function then, bool getGps: false}) async{
  bool enabled = await Geolocator().isLocationServiceEnabled();

  if(enabled && getGps){
    Geolocator geolocator = Geolocator()..forceAndroidLocationManager = true;
    Position position = await geolocator.getLastKnownPosition(desiredAccuracy: LocationAccuracy.high);

    if (position == null) {
      position = await geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    }

    then({'enabled': enabled, 'position': position});
  }else{
    then({'enabled': enabled});
  }
}

// requestPermissions(location: true),then((allowed){ })
requestPermissions({location: false, Function then}) async{
  _permissionStatus() async{
    PermissionStatus status = await PermissionHandler().checkPermissionStatus(PermissionGroup.location);
    then(status == PermissionStatus.unknown || status == PermissionStatus.denied ? false : true);
  }

  _checkPermission(PermissionStatus status) async{
    if(status == PermissionStatus.unknown || status == PermissionStatus.denied){
      await PermissionHandler().requestPermissions([PermissionGroup.location]);
      if(then != null) _permissionStatus();
    }else{ if(then != null) then(true); }
  }

  if(location){
    PermissionHandler().checkPermissionStatus(PermissionGroup.location).then(_checkPermission);
  }
}

class Dt {
  static final y = DateTime.now().year;
  static final m = DateTime.now().month;
  static final d = DateTime.now().day;
  static final h = DateTime.now().hour;
  static final i = DateTime.now().minute;
  static final s = DateTime.now().second;
  static final his = (Dt.h < 9 ? '0'+Dt.h.toString() : Dt.h.toString())+':'+(Dt.i < 9 ? '0'+Dt.i.toString() : Dt.i.toString())+':'+(Dt.s < 9 ? '0'+Dt.s.toString() : Dt.s.toString());
  static final dmy = Dt.d.toString()+'-'+Dt.m.toString()+'-'+Dt.y.toString();
  static final ymd = Dt.y.toString()+'-'+(Dt.m.toString().length == 1 ? '0'+Dt.m.toString() : Dt.m.toString())+'-'+(Dt.d.toString().length == 1 ? '0'+Dt.d.toString() : Dt.d.toString());
  static final dmyhis = Dt.dmy+' '+Dt.his;
  static final ymdhis = Dt.ymd+' '+Dt.his;

  static dateTime({format}){
    var bln = ['Januari','Februari','Maret','April','Mei','Juni','Juli','Agustus','September','Oktober','November','Desember'];
    var hari = ['Senin','Selasa','Rabu','Kamis','Jum\'at','Sabtu','Minggu'];

    switch (format) {
      case 'now-': return DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, DateTime.now().hour, DateTime.now().minute - 1, 0); break;
      case 'now+': return DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, DateTime.now().hour, DateTime.now().minute + 1, 0); break;
      case 'd M y': return DateTime.now().day.toString()+' '+bln[Dt.m - 1]+' '+Dt.y.toString(); break;
      case 'M': return bln[Dt.m - 1]; break;
      case 'D': return hari[DateTime.now().weekday - 1];
      case 'w': return DateTime.now().weekday;
      default: return Dt.dmyhis; break;
    }
  }
}

// get screen size, Mquery.width(context)
class Mquery{
  static width(context){
    return MediaQuery.of(context).size.width;
  }

  static height(context){
    return MediaQuery.of(context).size.height;
  }

  static statusBar(context){
    return MediaQuery.of(context).padding.top;
  }
}

class WidSplash extends StatelessWidget {
  WidSplash({this.key, this.child, this.elevation : 0, this.onTap, this.onLongPress, this.padding, this.color, this.splash, this.highlightColor, this.radius, this.border}); 
  
  final Key key;
  final Widget child;
  final Function onTap;
  final Function onLongPress;
  final EdgeInsetsGeometry padding;
  final Color color, splash, highlightColor;
  final BorderRadiusGeometry radius;
  final BoxBorder border;
  final double elevation;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: key,
      elevation: elevation,
      color: color == null ? Colors.transparent : color,
      borderRadius: radius,
      child: InkWell(
        onLongPress: onLongPress,
        splashColor: splash == null ? Color.fromRGBO(0, 0, 0, .03) : splash,
        highlightColor: highlightColor == null ? Color.fromRGBO(0, 0, 0, .03) : highlightColor,
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

class LoadAnimation extends StatefulWidget {
  final Widget child;
  LoadAnimation({@required this.child, Key key}) : super(key: key);

  @override
  _LoadAnimationState createState() => _LoadAnimationState();
}

class _LoadAnimationState extends State<LoadAnimation>
    with SingleTickerProviderStateMixin {
  AnimationController controller;

  @override
  void initState() {
    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose(); // harus diatas or error :D
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        widget.child,
        Positioned.fill(
          child: ClipRect(
              child: AnimatedBuilder(
                animation: controller,
                builder: (context, child) {
                  return FractionallySizedBox(
                    widthFactor: .5,
                    alignment: AlignmentGeometryTween(
                      begin: Alignment(-2.0 - .9 * 3, .0),
                      end: Alignment(2.0 + .2 * 3, .0),
                    ).chain(CurveTween(curve: Curves.easeOut)).evaluate(controller),
                    child: child,
                  );
                },
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: const [
                        Color.fromARGB(0, 255, 255, 255),
                        Colors.white70
                      ],
                    ),
                  ),
                ),
              ),
          ),
        ),
      ],
    );
  }
}

// Skeleton.config(width: 30)
class Skeleton {
  static config({EdgeInsetsGeometry margin, BorderRadiusGeometry radius, Color color, double height: 5, double width: 50}){
    return Container(
      margin: margin,
      child: LoadAnimation(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: radius,
            color: color == null ? Colors.black12 : color,
          ),
          height: height,
          width: width,
        ),
      ),
    );
  }
}

class SlideZoom extends StatefulWidget {
  SlideZoom({this.child}); final Widget child;

  @override
  _SlideZoomState createState() => _SlideZoomState();
}

class _SlideZoomState extends State<SlideZoom> with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  AnimationController controller;
  Animation<double> scaleAnimation;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(vsync: this, duration: Duration(milliseconds: 250));
    scaleAnimation = CurvedAnimation(parent: controller, curve: Curves.decelerate);
    controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      key: _scaffoldKey,
      scale: scaleAnimation,
      child: SlideUp(
        child: widget.child
      )
    );
  }
}

class ZoomIn extends StatefulWidget {
  ZoomIn({this.child}); final Widget child;

  @override
  _ZoomInState createState() => _ZoomInState();
}

class _ZoomInState extends State<ZoomIn> with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  AnimationController controller;
  Animation<double> scaleAnimation;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(vsync: this, duration: Duration(milliseconds: 250));
    scaleAnimation = CurvedAnimation(parent: controller, curve: Curves.decelerate);
    controller.forward();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      key: _scaffoldKey,
      scale: scaleAnimation,
      child: widget.child
    );
  }
}

class SlideLeft extends StatefulWidget {
  final Widget child; final int delay; final double speed;
  SlideLeft({@required this.child, this.delay, this.speed: 0.50});
  @override
  _SlideLeftState createState() => _SlideLeftState();
}

class _SlideLeftState extends State<SlideLeft> with TickerProviderStateMixin {
  AnimationController _animController; Animation<Offset> _animOffset;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: Duration(milliseconds: 300));
    final curve = CurvedAnimation(curve: Curves.decelerate, parent: _animController);
    _animOffset = Tween<Offset>(begin: Offset(widget.speed, 0.0), end: Offset.zero).animate(curve);
    widget.delay == null ? _animController.forward() :Timer(Duration(milliseconds: widget.delay), () { _animController.forward(); });
  }

  @override
  void dispose() { _animController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return FadeTransition( child: SlideTransition( position: _animOffset, child: widget.child ), opacity: _animController );
  }
}

class SlideRight extends StatefulWidget {
  final Widget child; final int delay; final double speed;
  SlideRight({@required this.child, this.delay, this.speed: 0.50});
  @override
  _SlideRightState createState() => _SlideRightState();
}

class _SlideRightState extends State<SlideRight> with TickerProviderStateMixin {
  AnimationController _animController; Animation<Offset> _animOffset;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: Duration(milliseconds: 300));
    final curve = CurvedAnimation(curve: Curves.decelerate, parent: _animController);
    _animOffset = Tween<Offset>(begin: Offset(-widget.speed, 0.0), end: Offset.zero).animate(curve);
    widget.delay == null ? _animController.forward() :Timer(Duration(milliseconds: widget.delay), () { _animController.forward(); });
  }

  @override
  void dispose() { _animController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return FadeTransition( child: SlideTransition( position: _animOffset, child: widget.child ), opacity: _animController );
  }
}

class SlideUp extends StatefulWidget {
  final Widget child; final int delay; final double speed;
  SlideUp({@required this.child, this.delay, this.speed: 0.50});
  @override
  _SlideUpState createState() => _SlideUpState();
}

class _SlideUpState extends State<SlideUp> with TickerProviderStateMixin {
  AnimationController _animController; Animation<Offset> _animOffset;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: Duration(milliseconds: 300));
    final curve = CurvedAnimation(curve: Curves.decelerate, parent: _animController);
    _animOffset = Tween<Offset>(begin: Offset(0.0, widget.speed), end: Offset.zero).animate(curve);
    widget.delay == null ? _animController.forward() :Timer(Duration(milliseconds: widget.delay), () { _animController.forward(); });
  }

  @override
  void dispose() { _animController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return FadeTransition( child: SlideTransition( position: _animOffset, child: widget.child ), opacity: _animController );
  }
}

class SlideDown extends StatefulWidget {
  final Widget child; final int delay; final double speed;
  SlideDown({@required this.child, this.delay, this.speed: 0.50});
  @override
  _SlideDownState createState() => _SlideDownState();
}

class _SlideDownState extends State<SlideDown> with TickerProviderStateMixin {
  AnimationController _animController; Animation<Offset> _animOffset;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: Duration(milliseconds: 300));
    final curve = CurvedAnimation(curve: Curves.decelerate, parent: _animController);
    _animOffset = Tween<Offset>(begin: Offset(0.0, -widget.speed), end: Offset.zero).animate(curve);
    widget.delay == null ? _animController.forward() :Timer(Duration(milliseconds: widget.delay), () { _animController.forward(); });
  }

  @override
  void dispose() { _animController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return FadeTransition( child: SlideTransition( position: _animOffset, child: widget.child ), opacity: _animController );
  }
}

class ScrollConfig extends ScrollBehavior {
  @override Widget buildViewportChrome( BuildContext context, Widget child, AxisDirection axisDirection) { return child; }
}

// PreventScrollGlow(child: Widget)
class PreventScrollGlow extends StatelessWidget {
  final Widget child; PreventScrollGlow({this.child});

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: ScrollConfig(),
      child: child,
    );
  }
}

// Unfocus(child: Widget)
class Unfocus extends StatelessWidget {
  final Widget child; Unfocus({this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (){ focus(context, FocusNode()); },
      child: child,
    );
  }
}

// AnimatedCount(400, bold: true, prefix: '%')
class AnimatedCount extends StatefulWidget {
  AnimatedCount(this.number, {this.bold: false, this.prefix: '', this.color: Colors.black87, this.size: 15});
  
  final bold, prefix;
  final Color color;
  final double size, number;
  
  @override
  createState() => new AnimatedCountState();
}

class AnimatedCountState extends State<AnimatedCount> with TickerProviderStateMixin {
  AnimationController _controller;
  Animation<double> _animation;

  @override initState() {
    _controller = new AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _animation = _controller;
    super.initState();

    _animation = new Tween<double>(
      begin: _animation.value,
      end: widget.number.toDouble(),
    ).animate(new CurvedAnimation(
      curve: Curves.fastOutSlowIn,
      parent: _controller,
    ));

    _controller.forward(from: 0.0);
  }

  @override
  void dispose() {
    super.dispose(); _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return new AnimatedBuilder(
      animation: _animation,
      builder: (BuildContext context, Widget child) {
        return text( _animation.value.toStringAsFixed(0)+widget.prefix, bold: widget.bold, color: widget.color, size: widget.size);
      },
    );
  }
}

// Stack(children: [ CurvedShape(color: Colors.red[300], height: 93, radius: -60,), ])
class CurvedShape extends StatelessWidget {
  final Color color;
  final double height, radius;

  CurvedShape({this.color, this.height: 50, this.radius: -100});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      child: CustomPaint(
        painter: _MyPainter(color: color, radius: radius),
      ),
    );
  }
}

class SpritePainter extends CustomPainter {
  final Animation<double> _animation;

  SpritePainter(this._animation) : super(repaint: _animation);

  void circle(Canvas canvas, Rect rect, double value) {
    double opacity = (1.0 - (value / 4.0)).clamp(0.0, 1.0);
    Color color = new Color.fromRGBO(0, 117, 194, opacity);

    double size = rect.width / 2;
    double area = size * size;
    double radius = math.sqrt(area * value / 4);

    final Paint paint = new Paint()..color = color;
    canvas.drawCircle(rect.center, radius, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    Rect rect = new Rect.fromLTRB(0.0, 0.0, size.width, size.height);

    for (int wave = 3; wave >= 0; wave--) {
      circle(canvas, rect, wave + _animation.value);
    }
  }

  @override
  bool shouldRepaint(SpritePainter oldDelegate) {
    return true;
  }
}

// CircleWave()
class CircleWave extends StatefulWidget {
  CircleWave({this.height: 50, this.width: 50, this.icon});
  final double height, width;
  final Icon icon;

  @override
  CircleWaveState createState() => new CircleWaveState();
}

class CircleWaveState extends State<CircleWave>
    with SingleTickerProviderStateMixin {
  AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = new AnimationController(
      vsync: this,
    );
    _startAnimation();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startAnimation() {
    _controller.stop();
    _controller.reset();
    _controller.repeat(
      period: Duration(seconds: 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
        painter: new SpritePainter(_controller),
        child: new SizedBox(
          width: widget.width,
          height: widget.height,
          child: widget.icon
        ),
      
    );
  }
}

class _MyPainter extends CustomPainter {
  final Color color;
  final double radius;

  _MyPainter({this.color, this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = new Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true
      ..color = color;

    Path path = Path();
    path.lineTo(0, size.height);
    path.quadraticBezierTo(size.width / 2, size.height - radius, size.width, size.height);
    path.lineTo(size.width, 0);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

// widget helper
class Wh {

  static picker(context, {@required List options, List values, selected, Function change}){
    return Container(
      height: 200,
      child: Column(
        children: [
              
          Expanded(
            child: PreventScrollGlow(
              child: CupertinoPicker(
                scrollController: FixedExtentScrollController(
                  initialItem: values == null ? options.indexOf(selected) : values.indexOf(selected),
                ),
                itemExtent: 40.0,
                backgroundColor: Colors.white,
                onSelectedItemChanged: (int i){
                  if(change != null){
                    values != null ? change(values[i]) : change(options[i]);
                  }
                },
                children: new List<Widget>.generate(
                  options.length, (int index) {
                    return Container(
                      margin: EdgeInsets.all(3),
                      width: Mquery.width(context) - 100,
                      // padding: EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: TColor.silver(),
                        borderRadius: BorderRadius.circular(25)
                      ),
                      child: Center(
                        child: text(ucword(options[index].toString())),
                      ) 
                    );
                  }
                )
              ),
            ),
          ),
        ]
      )
    );
  }

  // dialog(context, child: Widget) -> slide 0.25 (up), slide -0.25 (down)
  static dialog(context, {dismiss: true, double slide: 0, bool custom: false, bool transparent: false, forceClose: true, MainAxisAlignment position, @required Widget child, Function then}){
    Future<bool> onWillPop() {
      return Future.value(forceClose);
    }
    return showDialog(
      context: context,
      barrierDismissible: dismiss,
      builder: (BuildContext context){
        return new WillPopScope(
          onWillPop: onWillPop,
          child: ZoomIn(
            child: Column(
              mainAxisAlignment: position == null ? MainAxisAlignment.center : position,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: Mquery.width(context),
                  margin: EdgeInsets.all(custom ? 0 : 15),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(custom ? 0 : 2),
                    child: Material(
                      color: transparent ? Colors.transparent : Colors.white,
                      child: child,
                    ),
                  ),
                )
              ]
            ),
          ),
        );
      }
    ).then((res){ if(then != null) then(res); });
  }

  static noData({image: 'nodata.png', message: '', Function onTap}){
    return Center(
      child: ZoomIn(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: onTap,
              child: Container(
                height: 222, width: 222,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/img/'+image)
                  )
                ),
              ),
            ),
            text(message, align: TextAlign.center)
          ]
        ),
      )
    );
  }

  // Wh.confirmation(context, message: 'Lorem ipsum dolor?', then: (res){})
  static confirmation(context, {@required String message, String confirmText: 'Confirm', String cancelText: 'Batal', Color confirmTextColor, Function then}){
    showModalBottomSheet<dynamic>(
      isScrollControlled: true,
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext bc) {
        return Container(
          padding: EdgeInsets.all(10),
          child: Wrap(
            children: [
              Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      width: Mquery.width(context),
                      color: Colors.white,
                      child: Column(
                        children: [
                          Container(
                            padding: EdgeInsets.all(15),
                            width: Mquery.width(context),
                            decoration: BoxDecoration(
                              border: Border(bottom: BorderSide(color: Colors.black12))
                            ),
                            child: text(message, align: TextAlign.center),
                          ),

                          WidSplash(
                            onTap: (){
                              then(0);
                            },
                            child: Container(
                              width: Mquery.width(context),
                              padding: EdgeInsets.all(15),
                              child: text(confirmText, color: confirmTextColor, align: TextAlign.center)
                            ),
                          )
                        ]
                      )
                    ),
                  ),

                  Container(
                    margin: EdgeInsets.only(top: 10),
                    child: WidSplash(
                      radius: BorderRadius.circular(4),
                      onTap: (){
                        Navigator.pop(context);
                      },
                      color: Colors.white,
                      child: Container(
                        width: Mquery.width(context),
                        padding: EdgeInsets.all(15),
                        child: text(cancelText, align: TextAlign.center)
                      ),
                    ),
                  )
                ]
              )
            ]
          ),
        );
      }
    );
  }

  // Wh.options(context, options: ['Option 1','Option 2','Option 3'], then: (res){ })
  static options(context, {String label, @required List options, List values, List icons, List hide, double radius: 5, Function then, bool backOnSelected: false}){

    showModalBottomSheet<dynamic>(
      isScrollControlled: true,
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext bc) {
        return Wrap(
          children: [
            Container(
              width: Mquery.width(context),
              color: Colors.transparent,
              child: Column(
                children: [
                  Container(
                    width: 70, margin: EdgeInsets.only(bottom: 10),
                    height: 5,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Color.fromRGBO(229, 232, 236, 1),
                    ),
                  ),

                  ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(radius),
                      topRight: Radius.circular(radius),
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: Mquery.height(context) / 2,
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          children: List.generate(options.length, (i){
                            var list = Container(
                              decoration: BoxDecoration(
                                border: Border(bottom: BorderSide(color: i == (options.length - 1) ? Colors.transparent : Color.fromRGBO(229, 232, 236, 1)))
                              ),
                              child: WidSplash(
                                onTap: (){
                                  if(then != null) then(values == null ? i : values[i]);
                                  if(backOnSelected){ Navigator.pop(context); }
                                },
                                color: Colors.white,
                                child: Container(
                                  width: Mquery.width(context),
                                  padding: EdgeInsets.all(15),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      Container(
                                        width: Mquery.width(context) - 50,
                                        child: text(options[i], align: TextAlign.left, overflow: TextOverflow.ellipsis),
                                      ),
                                      icons != null ? Icon(icons[i], size: 18) : SizedBox.shrink()
                                    ],
                                  )
                                ),
                              ),
                            );
                            return hide == null ? list : hide.indexOf(i) > -1 ? SizedBox.shrink() : list;
                          })
                        ),
                      ),
                    )
                  ),
                ]
              )
            ),
          ]
        );
      }
    );
  }

  static progress(context, {String message: ''}){
    showDialog(
      context: context,
      child: Material(
        color: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 100, width: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                image: DecorationImage(
                  image: AssetImage('assets/img/wl-busy.gif')
                )
              ),
            ),

            text(message, color: Colors.white)
          ]
        ),
      )
    );
  }

  static alert(context, {dismiss: true, Color color, Color borderColor, String title, message: '', IconData icon, Function onTap, String textConfirm: 'Tutup'}){
    showDialog(
      context: context,
      barrierDismissible: dismiss,
      builder: (BuildContext context) {

        return ZoomIn(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[

              Container(
                width: Mquery.width(context),
                margin: EdgeInsets.all(15),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: Material(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Container(
                          padding: EdgeInsets.all(15),
                          child: Column(
                            children: [
                              icon == null ? SizedBox.shrink() :
                              Container(
                                padding: EdgeInsets.all(15), margin: EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(50),
                                  border: Border.all(color: borderColor == null ? Colors.transparent : borderColor)
                                ),
                                // width: 60, height: 60,
                                child: Icon(icon, size: 35, color: color)
                              ),

                              title == null ? SizedBox.shrink() : text(title, bold: true, size: 20),

                              message is Widget ? message : html(message, align: TextAlign.center, size: 13.5),
                            ]
                          )
                        ),

                        Container(
                          decoration: BoxDecoration(
                            border: Border(top: BorderSide(color: Color.fromRGBO(229, 232, 236, 1)))
                          ),
                          child: WidSplash(
                            color: TColor.silver(),
                            onTap: onTap == null ? (){ Navigator.pop(context); } : onTap,
                            padding: EdgeInsets.all(10),
                            child: Container(
                              width: Mquery.width(context),
                              child: text(textConfirm, bold: true, align: TextAlign.center)
                            )
                          ),
                        )
                      ],
                    ),
                  )
                )
              )
            ],
          ),
        );
      }
    );
  }

  static appBar(context, {title = '', Color color, elevation = 1, back: true, spacing: 15, List<Widget> actions, bool autoLeading: false, bool center: false, Widget leading, Widget bottom}){
    return new AppBar(
      centerTitle: center,
      bottom: bottom,
      backgroundColor: color == null ? Colors.white : color,
      automaticallyImplyLeading: autoLeading,
      titleSpacing: back ? 0 : 15,
      elevation: elevation.toDouble(),
      leading: leading != null ? leading : !back ? null : IconButton(
        onPressed: (){ Navigator.pop(context); },
        icon: Icon(Feather.chevron_left), color: Colors.black54
      ),
      title: title is Widget ? title : text(title, color: Colors.black87, size: 18),
      actions: actions,
    );
  }

  // Wh.toast('lorem ipsum')
  static toast(String msg){
    return Fluttertoast.showToast(
      msg: msg,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Color.fromRGBO(0, 0, 0, .7),
      textColor: Colors.white,
      fontSize: 14.0
    );
  }

  // Wh.spiner(size: 50)
  static spiner({double size: 18, Color color, double stroke: 2, double margin: 0}){
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            margin: EdgeInsets.all(margin),
            child: SizedBox(
              child: CircularProgressIndicator(
                  valueColor: new AlwaysStoppedAnimation( color == null ? THEME_COLOR : color),
                  strokeWidth: stroke),
              ),
              height: size, width: size,
          ),
        ]
      )
    );
  }

  // Wh.datePicker(context, init: DateTime.now(), min: Dt.dateTime(format: 'now-')).then((res){ });
  static datePicker(BuildContext context, {DateTime init, DateTime min, DateTime max}) async {
    final DateTime picked = await showDatePicker(
      context: context,
      initialDate: init == null ? DateTime.now() : init,
      firstDate: min == null ? DateTime(1800, 0) : min,
      lastDate: max == null ? DateTime(2030) : max
    );

    if(picked != null){
      var date = picked.toString().split(' ');
      return date[0];
    }
  }

  // dateRangePicker(context, min: DateTime(Dt.y, Dt.m, Dt.d)).then((res){ })
  static dateRangePicker(BuildContext context, {
    DateTime firstDate, DateTime lastDate, DateTime min, DateTime max}) async {
    var y = DateTime.now().year, m = DateTime.now().month, d = DateTime.now().day;

    final List<DateTime> picked = await DateRagePicker.showDatePicker(
        context: context,
        initialFirstDate: firstDate == null ? DateTime(y, m, d) : firstDate,
        initialLastDate: lastDate == null ? DateTime(y, m, d + 2) : lastDate,
        firstDate: min == null ? DateTime(y) : min,
        lastDate: max == null ? DateTime(y + 1) : max
    );
      
    if (picked != null) return picked.toList();
  }

}

// class Fn {

//   static error(e){
//     if(e is PlatformException) {
//       Wh.toast(e.message);

//       print('# message -> '+e.message);
//       print('# code -> '+e.code);
//     }
//   }

  
// }

class Fc {
  static search({String label, String hint, TextInputAction action, bool autofocus: false, bool enabled: true, bool obsecure: false, int length: 255, FocusNode node, Widget prefix, Widget suffix, TextInputType type, Function submit, Function change, TextEditingController controller}){
    return TextField(
      // textAlign: TextAlign.center,
      keyboardType: type, onSubmitted: submit, focusNode: node, onChanged: change,
      controller: controller, textInputAction: action, obscureText: obsecure, enabled: enabled,
      inputFormatters: [ LengthLimitingTextInputFormatter(length) ], autofocus: autofocus,
      decoration: InputDecoration(
        alignLabelWithHint: true,
        suffixIcon: suffix,
        prefixIcon: prefix,
        hintText: hint,
        hintStyle: TextStyle(fontFamily: 'Nunito', ),
        labelStyle: TextStyle(fontFamily: 'Nunito'),
        border: InputBorder.none
      )
    );
  }

  static textfield({String label, String hint, TextInputAction action, bool autofocus: false, bool disabled: false, bool obsecure: false, int length: 255, FocusNode node, Widget suffix, TextInputType type, Function submit, TextEditingController controller, double marginBottom: 25}){
    return Container(
      margin: EdgeInsets.only(bottom: marginBottom),
      child: TextField(
        // textAlign: TextAlign.center,
        keyboardType: type, onSubmitted: submit, focusNode: node,
        controller: controller, textInputAction: action, obscureText: obsecure,
        inputFormatters: [ LengthLimitingTextInputFormatter(length) ],
        decoration: InputDecoration(
          alignLabelWithHint: true,
          suffixIcon: suffix,
          hintText: hint,
          hintStyle: TextStyle(fontFamily: 'Nunito'),
          labelStyle: TextStyle(fontFamily: 'Nunito'),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.black26),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: THEME_COLOR),
          ),
        )
      ),
    );
  }

  static input({String label, String hint, TextInputAction action, bool autofocus: false, bool disabled: false, TextInputType type, Function submit, TextEditingController controller, double marginBottom: 40}){
    return Container(
      margin: EdgeInsets.only(bottom: marginBottom),
      child: TextField(
        autofocus: autofocus, onChanged: (String k){ },
        textInputAction: action, keyboardType: type,
        onSubmitted: submit, controller: controller,
        style: TextStyle(fontFamily: 'Nunito'),
        decoration: InputDecoration(
          alignLabelWithHint: true,
          labelText: label,
          hintText: hint, enabled: !disabled,
          hintStyle: TextStyle(fontFamily: 'Nunito'),
          labelStyle: TextStyle(fontFamily: 'Nunito'),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.black26),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.blue),
          ),
        )
      ),
    );
  }

  static select2(context, {@required List options, List values, selected, Function onChange}){
    return Expanded(
      child: CupertinoPicker(
        scrollController: FixedExtentScrollController(
          initialItem: values == null ? options.indexOf(selected) : values.indexOf(selected),
        ),
        itemExtent: 40.0,
        backgroundColor: Colors.white,
        onSelectedItemChanged: (int i){
          if(onChange != null){
            values != null ? onChange(values[i]) : onChange(options[i]);
          }
        },
        children: new List<Widget>.generate(
          options.length, (int index) {
            return Container(
              margin: EdgeInsets.all(3),
              width: Mquery.width(context) - 100,
              padding: EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: TColor.silver(),
                borderRadius: BorderRadius.circular(25)
              ),
              child: Center(
                child: text(ucword(options[index].toString())),
              ) 
            );
            
          }
        )
      ),
    );
  }

  static select(context, {String label, String hint, List options, List values, bool unUsedOption: false, bool disabled: false, IconData suffix, Function onSelect, TextEditingController controller, double marginBottom: 40}){
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: marginBottom),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: disabled ? Colors.black12 : Colors.black26))
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          text(controller.text.isEmpty ? '' : label, size: 12, color: Colors.black45),
      
          WidSplash(
            onTap: disabled ? null : (){
              if(!unUsedOption){
                Wh.options(context, options: options, then: (i){
                  Navigator.pop(context);
                  if(onSelect != null) onSelect(values != null ? values[i] : options[i]);
                });
              }else{
                onSelect();
              }
            },
            padding: EdgeInsets.only(top: 0, bottom: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Container(
                  width: Mquery.width(context) - 50,
                  child: text(controller.text.isEmpty ? hint : controller.text, color: controller.text.isEmpty ? Colors.black54 : Colors.black87, size: 16, overflow: TextOverflow.ellipsis),
                ),
                Icon(suffix == null ? Ic.chevron() : suffix, size: 18, color: disabled ? Colors.black12 : Colors.black54)
              ],
            ),
          )

        ]
      )
    );
  }

  static date(context, {String label, String hint, DateTime init, DateTime startDate, DateTime endDate, DateTime min, DateTime max, bool disabled: false, bool dateRange: false, Function onSelect, TextEditingController controller, double marginBottom: 40}){
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: marginBottom),
      // padding: EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: disabled ? Colors.black12 : Colors.black26))
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          text(controller.text.isEmpty ? '' : label, size: 12, color: Colors.black45),
      
          WidSplash(
            onTap: disabled ? null : (){
              dateRange ? Wh.dateRangePicker(context, firstDate: startDate, lastDate: endDate, min: min, max: max).then((res){
                if(onSelect != null) onSelect(res.length > 1 ? res[0].toString().split(' ')[0]+' - '+res[1].toString().split(' ')[0] : res[0].toString().split(' ')[0]);
              })

              :

              Wh.datePicker(context, init: init, min: min, max: max).then((res){
                if(onSelect != null) onSelect(res);
              });
            },
            padding: EdgeInsets.only(top: 0, bottom: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Container(
                  width: Mquery.width(context) - 50,
                  child: text(controller.text.isEmpty ? hint : controller.text, color: controller.text.isEmpty ? Colors.black54 : Colors.black87, size: 16, overflow: TextOverflow.ellipsis),
                ),
                
                Icon(Feather.calendar, size: 18, color: disabled ? Colors.black12 : Colors.black54)
              ],
            ),
          )

        ]
      )
    );
  }

  static checkbox({String label, List checkLabels, List values, @required List controller}){
    return WCheck(label: label, checkLabels: checkLabels, values: values, controller: controller);
  }

  static radio({String label, List radioLabels, List values, TextEditingController controller, double marginBottom: 25}){
    return WRadio(label: label, radioLabels: radioLabels, values: values, controller: controller, marginBottom: marginBottom);
  }
}


class WCheck extends StatefulWidget {
  WCheck({this.label, this.values, this.checkLabels, this.controller});

  final String label;
  final List values, checkLabels;
  final List controller;


  @override
  _WCheckState createState() => _WCheckState();
}

class _WCheckState extends State<WCheck> {

  List checked = [];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        widget.label == null ? SizedBox.shrink() :
        Container(
          margin: EdgeInsets.only(bottom: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              text(widget.label, size: 12, color: Colors.black54),
            ],
          )
        ),

        Container(
          margin: EdgeInsets.only(bottom: 25),
          child: Wrap(
            children: List.generate(widget.values.length, (i){
              var isChecked = checked.indexOf(widget.values[i]) > -1;

              return GestureDetector(
                onTap: (){
                  setState(() {
                    if(isChecked){
                      checked.removeWhere((item) => item == widget.values[i]);
                      if(widget.controller != null) widget.controller.removeWhere((item) => item == widget.values[i]);
                    }else{
                      checked.add(widget.values[i]);
                      if(widget.controller != null) widget.controller.add(widget.values[i]);
                    }
                  });
                },
                child: Container(
                  margin: EdgeInsets.only(right: 15, bottom: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[

                      Container(
                        width: 17, height: 17,
                        // margin: EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: isChecked ? Colors.transparent : Colors.black26),
                          borderRadius: BorderRadius.circular(3),
                          color: isChecked ? TColor.blue() : Colors.white,
                          boxShadow: isChecked ? [
                            BoxShadow(
                              color: Color.fromRGBO(205, 217, 239, 1),
                              spreadRadius: 2,
                              blurRadius: 0,
                              offset: Offset(0, 0), // changes position of shadow
                            ),
                          ] : null
                        ),
                        child: isChecked ? Icon(Icons.check, size: 13, color: Colors.white) : SizedBox.shrink(),
                      ),

                      Container(
                        color: Colors.transparent,
                        padding: EdgeInsets.only(left: 10),
                        child: Text(widget.checkLabels == null ? widget.values[i] : widget.checkLabels[i])
                      )
                      
                    ],
                  ),
                ),
              );
              
              
            }),
          ),
        )

      ]
      
    );
  }
}

class WRadio extends StatefulWidget {
  WRadio({this.label, this.values, this.radioLabels, this.controller, this.marginBottom: 25});

  final String label;
  final List values, radioLabels;
  final TextEditingController controller;
  final double marginBottom;


  @override
  _WRadioState createState() => _WRadioState();
}

class _WRadioState extends State<WRadio> {

  var checked = -1;

  @override
  void initState() {
    super.initState();

    checked = widget.values.indexOf(widget.controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        widget.label == '' ? SizedBox.shrink() :
        Container(
          margin: EdgeInsets.only(bottom: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              text(widget.label, bold: true),
            ],
          )
        ),

        Container(
          margin: EdgeInsets.only(bottom: widget.marginBottom),
          child: Wrap(
            children: List.generate(widget.values.length, (i){
              return GestureDetector(
                onTap: (){
                  setState(() {
                    checked = i;
                    if(widget.controller != null) widget.controller.text = widget.values[i].toString();
                  });
                },
                child: Container(
                  margin: EdgeInsets.only(right: 15, bottom: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[

                      Container(
                        width: 19, height: 19,
                        // margin: EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: checked != i ? Border.all(color: Colors.black26) : Border.all(color: TColor.blue(), width: 5),
                          borderRadius: BorderRadius.circular(50),
                          boxShadow: checked == i ? [
                            BoxShadow(
                              color: Color.fromRGBO(205, 217, 239, 1),
                              spreadRadius: 3,
                              blurRadius: 0,
                              offset: Offset(0, 0), // changes position of shadow
                            ),
                          ] : null
                        ),
                      ),

                      Container(
                        color: Colors.transparent,
                        padding: EdgeInsets.only(left: 10),
                        child: text(widget.radioLabels == null ? ucword(widget.values[i].toString().replaceAll('_', ' ')) : widget.radioLabels[i])
                      )
                      
                    ],
                  ),
                ),
              );
              
              
            }),
          ),
        )

      ]
      
    );
  }
}

class TColor {

  static silver({double o: 1}){
    return Color.fromRGBO(244, 247, 251, o);
  }

  static blue({double o: 1}){
    return invertBlue(o: o);
  }

  static azure({double o: 1}){
    return primary(o: o);
  }

  static blueLight({double o: 1}){
    return Color.fromRGBO(95, 170, 236, o);
  }

  static indigo({double o: 1}){
    return Color.fromRGBO(103, 118, 199, o);
  }

  static purple({double o: 1}){
    return Color.fromRGBO(154, 102, 226, o);
  }

  static pink({double o: 1}){
    return Color.fromRGBO(229, 118, 154, o);
  }

  static red({double o: 1}){
    return Color.fromRGBO(189, 52, 43, o);
  }

  static orange({double o: 1}){
    return Color.fromRGBO(241, 150, 69, o);
  }

  static yellow({double o: 1}){
    return Color.fromRGBO(240, 178, 63, o);
  }

  static lime({double o: 1}){
    return Color.fromRGBO(163, 212, 79, o);
  }

  static green({double o: 1}){
    return Color.fromRGBO(117, 183, 54, o);
  }

  static teal({double o: 1}){
    return Color.fromRGBO(98, 200, 186, o);
  }

  static cyan({double o: 1}){
    return Color.fromRGBO(73, 160, 181, o);
  }

  static gray({double o: 1}){
    return Color.fromRGBO(169, 174, 182, o);
  }

  static black({double o: 1}){
    return Color.fromRGBO(60, 60, 60, o);
  }
}

// FEATHER ICONS
class Ic {
  static chevron(){ return Feather.chevron_down; }
  static chevronUp(){ return Feather.chevron_up; }
  static info(){ return Feather.info; }
  static search(){ return Feather.search; }
  static refresh(){ return Feather.rotate_ccw; }
  static close(){ return Feather.x; }
  static gps(){ return Feather.map_pin; }
  static add(){ return Feather.plus; }
  static more(){ return Feather.more_vertical; }
  static edit(){ return Feather.edit_2; }
  static check(){ return Feather.check; }
  static print(){ return Feather.printer; }
  static book(){ return Feather.book_open; }
  static minus(){ return Feather.minus; }
  static trash(){ return Feather.trash; }
  static calendar(){ return Feather.calendar; }
  static chevright(){ return Feather.chevron_right; }
  static filter(){ return Feather.filter; }
  static minimize(){ return Feather.minimize; }
  static maximize(){ return Feather.maximize; }
  static code(){ return Feather.code; }
  static camera(){ return Feather.camera; }
  static user(){ return Feather.user; }
  static userx(){ return Feather.user_x; }
  static users(){ return Feather.users; }
  static lock(){ return Feather.lock; }
  static unlock(){ return Feather.unlock; }
  static eye(){ return Feather.eye; }
  static eyeoff(){ return Feather.eye_off; }
  static link(){ return Feather.link; }
  static link2(){ return Feather.link_2; }
  static list(){ return Feather.list; }
  static whatsapp(){ return FontAwesome.whatsapp; }
  static star(){ return Feather.star; }
  static globe(){ return Feather.globe; }
  static logout(){ return Feather.log_out; }
  static mail(){ return Feather.mail; }
  static server(){ return Feather.server; }
  static sync(){ return Feather.refresh_ccw; }
}


// API

var defaultApi = 'https://kpm-api.kembarputra.com';

class Api {

  static setApi() async{
    var prefs = await SharedPreferences.getInstance(),
        apiUrl = prefs.getString('api');
    
    if(apiUrl != null){
      defaultApi = apiUrl;
    }
  }

  static apii(url){
    setApi();
    return defaultApi+'/'+url;
  }

  // await post('user', formData: {}, debug: true, then: (res){ }, error: (err){ })
  static post(url, {formData, debug: false, authorization: true, Function then, Function error}) async{
    var prefs = await SharedPreferences.getInstance();

    // get api from local data
    api(url){
      var apiUrl = prefs.getString('api');
      return apiUrl == null ? defaultApi+'/'+url : apiUrl+'/'+url;
    }

    checkConnection().then((con){
      if(con){
        if(debug) { print('# url : '+api(url)); }

        try {
          http.post(api(url), body: formData == null ? {} : formData, headers: !authorization ? {} : {
            HttpHeaders.authorizationHeader: prefs.getString('token'), 'Accept': 'application/json'
          }).then((res){
            if(debug){
              print('# request : '+res.request.toString());
              print('# status : '+res.statusCode.toString());
              print('# body : '+res.body.toString());
            }

            if(then != null) then(res.statusCode, res.body);
          });
        } catch (e) {
          if(e is PlatformException) {
            if(error != null) error(e.message);
          }
        }
      }else{
        Wh.toast('Check your internet connection!');
      }
    });
  }

  // await get('user', debug: true, then: (res){ }, error: (err){ })
  static get(url, {debug: false, authorization: true, Function then, Function error}) async{
    var prefs = await SharedPreferences.getInstance();

    // get api from local data
    api(url){
      var apiUrl = prefs.getString('api');
      return apiUrl == null ? defaultApi+'/'+url : apiUrl+'/'+url;
    }

    checkConnection().then((con){
      if(con){
        if(debug) { print('# url : '+api(url)); }

        try {
          http.get(api(url), headers: !authorization ? {} : {
            HttpHeaders.authorizationHeader: prefs.getString('token'), 'Accept': 'application/json'
          }).then((res){
            if(debug){
              print('# request : '+res.request.toString());
              print('# status : '+res.statusCode.toString());
              print('# body : '+res.body.toString());
            }

            if(then != null) then(res.statusCode, res.body);
          });
        } catch (e) {
          if(e is PlatformException) {
            if(error != null) error(e.message);
          }
        }
      }else{
        Wh.toast('Check your internet connection!');
      }
    });
  }

  // await put('user', formData: {}, debug: true, then: (res){ }, error: (err){ })
  static put(url, {@required formData, debug: false, authorization: true, Function then, Function error}) async{
    var prefs = await SharedPreferences.getInstance();

    // get api from local data
    api(url){
      var apiUrl = prefs.getString('api');
      return apiUrl == null ? defaultApi+'/'+url : apiUrl+'/'+url;
    }

    checkConnection().then((con){
      if(con){
        if(debug) { print('# url : '+api(url)); }

        try {
          http.put(api(url), body: formData, headers: !authorization ? {} : {
            HttpHeaders.authorizationHeader: prefs.getString('token'), 'Accept': 'application/json'
          }).then((res){
            if(debug){
              print('# request : '+res.request.toString());
              print('# status : '+res.statusCode.toString());
              print('# body : '+res.body.toString());
            }

            if(then != null) then(res.statusCode, res.body);
          });
        } catch (e) {
          if(e is PlatformException) {
            if(error != null) error(e.message);
          }
        }
      }else{
        Wh.toast('Check your internet connection!');
      }
    });
  }

  // await delete('user/1', debug: true, then: (res){ }, error: (err){ })
  static delete(url, {debug: false, authorization: true, Function then, Function error}) async{
    var prefs = await SharedPreferences.getInstance();

    // get api from local data
    api(url){
      var apiUrl = prefs.getString('api');
      return apiUrl == null ? defaultApi+'/'+url : apiUrl+'/'+url;
    }

    checkConnection().then((con){
      if(con){
        if(debug) { print('# url : '+api(url)); }

        try {
          http.delete(api(url), headers: !authorization ? {} : {
            HttpHeaders.authorizationHeader: prefs.getString('token'), 'Accept': 'application/json'
          }).then((res){
            if(debug){
              print('# request : '+res.request.toString());
              print('# status : '+res.statusCode.toString());
              print('# body : '+res.body.toString());
            }

            if(then != null) then(res.statusCode, res.body);
          });
        } catch (e) {
          if(e is PlatformException) {
            if(error != null) error(e.message);
          }
        }
      }else{
        Wh.toast('Check your internet connection!');
      }
    });
  }

}

class Dropdown extends StatefulWidget {
  final String label, hint, values, resDataLabel, resDataValue;
  final double space;
  final List item;
  final List options;
  final Function onChanged;
  Dropdown({this.label, this.hint, this.space: 0, this.values, this.options, this.onChanged, this.resDataLabel, this.resDataValue, this.item});

  @override
  _DropdownState createState() => _DropdownState();
}

class _DropdownState extends State<Dropdown> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          child: text(widget.label, bold: true),
          margin: EdgeInsets.only(bottom: 7),
        ),
        Container(
          margin: EdgeInsets.only(bottom: widget.space),
          padding: EdgeInsets.only(left: 15, right: 15, top: 10, bottom: 10),
          height: 40,
          decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black12),
              borderRadius: BorderRadius.circular(5)
          ),
          child: DropdownButton(
              icon: Icon(Ic.chevron(), size: 17),
              hint: text(widget.hint, color: Colors.black45),
              isExpanded: true,
              value: widget.values,
              underline: SizedBox.shrink(),
              items: widget.item != null ? widget.item : widget.options.map((value){
                return DropdownMenuItem<String>(
                  value: value,
                  child: text(value, color: Colors.black87),
                );
              }).toList(),
              onChanged: widget.onChanged
          ),
        ),
      ],
    );
  }
}

class SelectInput extends StatefulWidget {
  SelectInput({this.label, this.hint, this.flexibleSpace, this.select, @required this.controller, this.enabled: true, this.suffix, this.space: 25});

  final String label, hint;
  final Function select;
  final TextEditingController controller;
  final bool enabled;
  final IconData suffix;
  final double space;
  final Widget flexibleSpace;

  @override
  _SelectInputState createState() => _SelectInputState();
}

class _SelectInputState extends State<SelectInput> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: widget.space),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          
          widget.label == null ? SizedBox.shrink() :
          Container(
            margin: EdgeInsets.only(bottom: 7),
            child: text(widget.label, bold: true),
          ),

          WidSplash(
            onTap: widget.enabled ? widget.select : null,
            color: widget.enabled ? Colors.white : Color.fromRGBO(232, 236, 241, 1),
            child: Container(
              padding: EdgeInsets.only(left: 15, right: 15, top: 10, bottom: 10),
              width: Mquery.width(context),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black12),
                borderRadius: BorderRadius.circular(2)
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Flexible(
                    child:
                    widget.flexibleSpace != null ? widget.flexibleSpace
                        : text(widget.controller.text.isEmpty ? widget.hint : widget.controller.text, color: widget.controller.text.isEmpty ? Colors.black45 : Colors.black87, overflow: TextOverflow.ellipsis),
                  ),
                  
                  Icon(widget.suffix == null ? Ic.chevron() : widget.suffix, size: 17)
                ],
              )
              
            ),
          )

        ],
      ),
    );
  }
}

class SelectGroup extends StatefulWidget {
  SelectGroup({this.label, this.space: 25, @required this.options, this.labels, this.labelsUppercase: false, @required this.controller, });

  final double space;
  final String label;
  final List options, labels;
  final TextEditingController controller;
  final bool labelsUppercase;

  @override
  _SelectGroupState createState() => _SelectGroupState();
}

class _SelectGroupState extends State<SelectGroup> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: widget.space),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          
          widget.label == null ? SizedBox.shrink() :
          Container(
            margin: EdgeInsets.only(bottom: 7),
            child: text(widget.label, bold: true),
          ),

          Container(
            decoration: BoxDecoration(
              // border: Border.all(color: Colors.black12),
              borderRadius: BorderRadius.circular(4)
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.options.length, (i){

                  var checked = widget.controller.text == widget.options[i],
                      first = i == 0;

                  return Expanded(
                    child: WidSplash(
                      onTap: (){
                        setState(() {
                          widget.controller.text = widget.options[i];
                        });
                      },
                      color: checked ? TColor.azure() : Colors.white,
                      child: Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(color: checked ? TColor.blue(o: .5) : first ? Colors.black12 : Colors.transparent),
                            top: BorderSide(color: checked ? TColor.blue(o: .5) : Colors.black12),
                            bottom: BorderSide(color: checked ? TColor.blue(o: .5) : Colors.black12),
                            right: BorderSide(color: checked ? TColor.blue(o: .5) : Colors.black12)
                          ),
                        ),
                        child: text(
                          widget.labels == null ? 
                            widget.labelsUppercase ? widget.options[i].toString().toUpperCase() : 
                            ucword(widget.options[i]) :
                            widget.labelsUppercase ? widget.labels[i].toString().toUpperCase() : 
                            widget.labels[i], align: TextAlign.center, color: widget.controller.text == widget.options[i] ? Colors.white : Colors.black54),
                      )
                    ),
                  );
                }),
              ),
            ),
          )

        ],
      ),
    );
  }
}

class TextInput extends StatefulWidget {
  TextInput({this.label, this.space: 25, this.hint, this.controller, this.type, this.action, this.enabled: true, this.obsecure: false, this.submit, this.change, this.node, this.length, this.maxLines});

  final String label, hint;
  final TextEditingController controller;
  final TextInputType type;
  final TextInputAction action;
  final bool enabled, obsecure;
  final Function submit, change;
  final FocusNode node;
  final int length, maxLines;
  final double space;

  @override
  _TextinputState createState() => _TextinputState();
}

class _TextinputState extends State<TextInput> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: widget.space),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[

          widget.label == null ? SizedBox.shrink() :
          Container(
            margin: EdgeInsets.only(bottom: 7),
            child: text(widget.label, bold: true),
          ),

          Container(
            color: widget.enabled ? Colors.white : Color.fromRGBO(232, 236, 241, 1),
            child: TextField(
              controller: widget.controller,
              keyboardType: widget.type,
              textInputAction: widget.action,
              enabled: widget.enabled,
              focusNode: widget.node, obscureText: widget.obsecure,
              onSubmitted: widget.submit,
              style: TextStyle(fontFamily: 'Nunito'), maxLines: widget.maxLines == null ? 1 : widget.maxLines, minLines: 1,
              onChanged: widget.change,
              inputFormatters: [ LengthLimitingTextInputFormatter(widget.length) ],
              decoration: InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.only(left: 15, right: 15, top: 10, bottom: 10),
                hintText: widget.hint,
                border: InputBorder.none,
                hintStyle: TextStyle(fontFamily: 'Nunito'),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black12),
                  borderRadius: BorderRadius.circular(2)
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: TColor.azure()),
                  borderRadius: BorderRadius.circular(2)
                ),
                disabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black12),
                  borderRadius: BorderRadius.circular(2)
                ),
              )
            ),
          ),
        ],
      ),
    );
  }
}

class InputNumber extends StatefulWidget {
  InputNumber({
    this.label, this.hint, this.controller, this.action,
    this.enabled: true, this.submit, this.change, this.node, this.length,
    this.prefix, this.suffix, this.isSuffix: true
  });

  final String label, hint;
  final TextEditingController controller;
  final TextInputAction action;
  final bool enabled, isSuffix;
  final Function submit, change;
  final FocusNode node;
  final int length;
  final Widget prefix, suffix;

  @override
  _InputNumberState createState() => _InputNumberState();
}

class _InputNumberState extends State<InputNumber> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[

          Container(
            margin: EdgeInsets.only(bottom: 7),
            child: text(widget.label, bold: true),
          ),

          Container(
            color: widget.enabled ? Colors.white : Color.fromRGBO(232, 236, 241, 1), height: 40,
            child: TextField(
              controller: widget.controller,
              keyboardType: TextInputType.number,
              textInputAction: widget.action,
              enabled: widget.enabled,
              focusNode: widget.node,
              onSubmitted: widget.submit,
              style: TextStyle(fontFamily: 'Nunito'),
              onChanged: widget.change,
              inputFormatters: [ LengthLimitingTextInputFormatter(widget.length), WhitelistingTextInputFormatter(RegExp("[0-9,]")) ],
              decoration: InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.only(left: 15, right: widget.isSuffix ? 0 : 15, top: 10, bottom: 10),
                hintText: widget.hint,
                border: InputBorder.none, 
                prefix: widget.prefix,
                suffixIcon: !widget.isSuffix ? null : widget.suffix != null ? widget.suffix : Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(2, (i){
                    var icons = [Ic.minus(), Ic.add()];

                    return WidSplash(
                      onTap: (){
                        var ctrl = widget.controller.text;

                        if(i == 0){ // minus
                          if(ctrl != '0' && ctrl.isNotEmpty){
                            ctrl = (int.parse(ctrl) - 1).toString();
                            widget.controller.text = ctrl;
                          }

                          if(ctrl.isEmpty){
                            ctrl = '0'; widget.controller.text = ctrl;
                          }

                        }else{ // add
                          if(ctrl.isEmpty){
                            ctrl = '0';
                          }

                          ctrl = (int.parse(ctrl) + 1).toString();
                          widget.controller.text = ctrl;
                        }
                      },
                      padding: EdgeInsets.only(left: 10, right: 10, top: 10, bottom: 10),
                      child: Icon(icons[i]),
                    );
                  })
                ),

                hintStyle: TextStyle(fontFamily: 'Nunito'),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black12),
                  borderRadius: BorderRadius.circular(2)
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: TColor.azure()),
                  borderRadius: BorderRadius.circular(2)
                ),
                disabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black12),
                  borderRadius: BorderRadius.circular(2)
                ),
              )
            ),
          ),
        ],
      ),
    );
  }
}

class ListSkeleton extends StatefulWidget {
  ListSkeleton({this.length: 3, this.type});

  final int length;
  final String type;

  @override
  _ListSkeletonState createState() => _ListSkeletonState();
}

class _ListSkeletonState extends State<ListSkeleton> {
  @override
  Widget build(BuildContext context) {
    if(widget.type == null){
      return SingleChildScrollView(
          padding: EdgeInsets.all(widget.type == null ? 0 : 15),
          physics: NeverScrollableScrollPhysics(),
          child:

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(widget.length, (i){
              return Container(
                  width: Mquery.width(context),
                  padding: EdgeInsets.only(left: 15, right: 15, top: 25, bottom: 25),
                  decoration: BoxDecoration(
                    // border: Border(bottom: BorderSide(color: Colors.black12)),
                      color: i % 2 == 0 ? TColor.silver() : Colors.white
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Skeleton.config(width: 30 + math.Random().nextDouble() * 200, height: 7, margin: EdgeInsets.only(bottom: 5), radius: BorderRadius.circular(2)),
                      Skeleton.config(width: 50 + math.Random().nextDouble() * Mquery.width(context), height: 15, radius: BorderRadius.circular(2)),
                    ],
                  )

              );
            }),
          )



        // Wrap(
        //   children: List.generate(13, (i){
        //   return Container(
        //     width: Mquery.width(context) / 2 - 25, height: 30 + math.Random().nextDouble() * 200,
        //     margin: EdgeInsets.only(bottom: 10, left: 10),
        //     decoration: BoxDecoration(
        //       border: Border.all(color: Colors.black12)
        //     ),
        //     child: Column(
        //       children: <Widget>[
        //         Skeleton.config(width: 50, height: 50, margin: EdgeInsets.all(5)),
        //         Skeleton.config(width: 60, height: 5, margin: EdgeInsets.all(5)),
        //         Skeleton.config(width: 100, height: 5, margin: EdgeInsets.all(5)),
        //       ],
        //     ),
        //   );
        // }),
        // )
      );
    }else if(widget.type == 'text'){
      return SingleChildScrollView(
        // padding: EdgeInsets.all(widget.type == null ? 0 : 15),
        physics: NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(widget.length, (i){
            return Container(
                width: Mquery.width(context),
                padding: EdgeInsets.only(left: 15, right: 15, top: 10, bottom: 10),
                decoration: BoxDecoration(
                  // border: Border(bottom: BorderSide(color: Colors.black12)),
                    color: i % 2 != 0 ? TColor.silver() : Colors.white
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Skeleton.config(width: Mquery.width(context), height: 7, margin: EdgeInsets.only(bottom: 5), radius: BorderRadius.circular(2)),
                    Skeleton.config(width: Mquery.width(context)/2, height: 7, radius: BorderRadius.circular(2)),
                  ],
                )

            );
          }),
        ),
      );
    }else{
      return StaggeredGridView.count(
          physics: NeverScrollableScrollPhysics(),
          padding: EdgeInsets.all(15),
          crossAxisCount: 4,
          staggeredTiles: [4,5,6,7,3,5,4,2,5,3].map<StaggeredTile>((_) => StaggeredTile.fit(2)).toList(),
          mainAxisSpacing: 3.0,
          crossAxisSpacing: 4.0,
          children: List.generate(widget.length, (int i){

            return Container(
              width: Mquery.width(context) / 2 - 25,
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.black12),
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(2)
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[

                  Skeleton.config(width: Mquery.width(context), height: 30 + math.Random().nextDouble() * 100, margin: EdgeInsets.all(5)),
                  Skeleton.config(width: 60, height: 5, margin: EdgeInsets.only(left: 5, bottom: 5)),
                  Skeleton.config(width: 100, height: 5, margin: EdgeInsets.only(left: 5, bottom: 5)),

                ],
              ),
            );
          })
      );
    }
  }
}

class Button extends StatefulWidget {
  Button({this.text, this.onTap, this.isSubmit: false});

  final String text;
  final bool isSubmit;
  final Function onTap;

  @override
  _ButtonState createState() => _ButtonState();
}

class _ButtonState extends State<Button> {
  @override
  Widget build(BuildContext context) {
    return WidSplash(
      onTap: widget.isSubmit ? null : widget.onTap,
      radius: BorderRadius.circular(2),
      color: TColor.azure(o: widget.isSubmit ? .5 : 1),
      child: Container(
        width: Mquery.width(context),
        padding: EdgeInsets.all(11),
        child: widget.isSubmit ? Wh.spiner(color: Colors.white, size: 18) : text(widget.text, align: TextAlign.center, color: Colors.white),
      ),
    );
  }
}

class WhiteShadow extends StatefulWidget {
  WhiteShadow({this.child, this.padding});

  final child;
  final EdgeInsetsGeometry padding;

  @override
  _WhiteShadowState createState() => _WhiteShadowState();
}

class _WhiteShadowState extends State<WhiteShadow> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: widget.padding == null ? EdgeInsets.all(15) : widget.padding,
      decoration: BoxDecoration(
        color: Color.fromRGBO(244, 247, 251, 1),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(244, 247, 251, 1),
            // Color.fromRGBO(229, 232, 236, .8),
            spreadRadius: 15,
            blurRadius: 7,
            offset: Offset(0, 1), // changes position of shadow
          ),
        ],
      ),
      child: widget.child
    );
  }
}

class OnProgress extends StatefulWidget {
  OnProgress({this.message});

  final String message;

  @override
  _OnProgressState createState() => _OnProgressState();
}

class _OnProgressState extends State<OnProgress> {
  @override
  Widget build(BuildContext context) {
    return ZoomIn(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: Material(
                child: Container(
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white
                  ),
                  child: Column(
                    children: <Widget>[

                      Container(
                        height: 100, width: 100,
                        child: Image.asset('assets/img/loader.gif'),
                      ),

                      widget.message == null ? SizedBox.shrink() : text(widget.message, align: TextAlign.center)

                    ],
                  ),
                ),
              ),
            )

            

          ],
        ),
      ),
    );
  }
}

class Picker extends StatefulWidget {
  final list, selected, isPrint; final Function then;
  Picker({@required this.list, this.selected, this.then, this.isPrint: false});

  @override
  _PickerState createState() => _PickerState();
}

class _PickerState extends State<Picker> {
  var selected;

  init(){
    selected = widget.selected;
  }

  @override
  void initState() {
    super.initState(); init();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // padding: EdgeInsets.all(15),
      // height: 200,
      child: Column(
        children: <Widget>[
          // Container(
          //   height: 130,
          //   child: Row(
          //     children: <Widget>[
          //       Container(
          //         height: 100,
          //         child: Expanded(
          //           child: Column(
          //             children: <Widget>[
                        
          //             ]
          //           )
          //         ),
          //       ),
          //     ],
          //   ),
          // ),

          Wh.picker(context, options: widget.list, 
            selected: widget.selected, change: (res){ selected = res; }
          ),

          Button(
            text: 'Cetak', isSubmit: widget.isPrint,
            onTap: widget.isPrint ? null : (){
              widget.then(selected);
            },
          )
          
        ],
      ),
    );
  }
}

class PaginateControl extends StatefulWidget {
  PaginateControl({this.isMaxScroll, this.isLoad, this.totalRow, this.totalData, this.onTap});

  final bool isMaxScroll, isLoad;
  final int totalRow, totalData;
  final Function onTap;

  @override
  _PaginateControlState createState() => _PaginateControlState();
}

class _PaginateControlState extends State<PaginateControl> {
  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 10,
      child: !widget.isMaxScroll ? SizedBox.shrink() : ZoomIn(
        child: AnimatedOpacity(
          opacity: widget.isMaxScroll ? 1.0 : 0.0,
          duration: Duration(milliseconds: 500),
          child: !widget.isMaxScroll ? SizedBox.shrink() : Container(
            width: MediaQuery.of(context).size.width,
            child: Column(
              children: <Widget>[

                widget.isLoad ? Container(
                  
                  margin: EdgeInsets.all(25),
                  child: Wh.spiner(size: 20)
                  ) : widget.totalRow == widget.totalData ? SizedBox.shrink() : // jika jumlah data yang diload = jumlah total data, hide loadmore

                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: TColor.azure()),
                      borderRadius: BorderRadius.circular(50),
                      color: Colors.white
                    ),
                    margin: EdgeInsets.all(10),
                    child: new Material(
                      color: Colors.transparent,
                      child: new InkWell(
                      borderRadius: BorderRadius.circular(50),
                        onTap: widget.onTap,
                        onLongPress: (){ },
                        onDoubleTap: (){ },
                        child: Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(50)
                          ),
                          child: Icon(Ic.chevron(), color: TColor.azure(), size: 30,))
                      )
                    ),
                  )
              ],
            ),
          )
        ),
      )
    );
  }
}

class ListExpanded extends StatefulWidget {
  ListExpanded({this.label, this.id: -1, this.expanded, this.onTap, @required this.children, this.total});

  final String label;
  final int id, expanded, total;
  final Function onTap;
  final List<Widget> children;

  @override
  _ListExpandedState createState() => _ListExpandedState();
}

class _ListExpandedState extends State<ListExpanded> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          WidSplash(
            onTap: widget.onTap,
            padding: EdgeInsets.all(12),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                text(widget.label),
                Icon(widget.id == widget.expanded ? Ic.chevron() : Ic.chevright(), size: 17, color: Colors.black26),
              ]
            ),
          ),

          AnimatedContainer(
            height: widget.id == widget.expanded ? (widget.total * 43).toDouble() : 0,
            duration: Duration(milliseconds: 200),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: widget.children,
              )
            )
          )
        ]
      ),
    );
  }
}

// tracking activity
Future trackActivity(String activity) async{
  SharedPreferences prefs = await SharedPreferences.getInstance();

  var activities = prefs.getString('activities'), arrActivities = [];
  
  if(activities == null){
    arrActivities.add(activity);
    prefs.setString('activities', encode(arrActivities));
    // await LocalData.set('activities', arrActivities, encode: true);
  }else{
    arrActivities = decode(activities);
    arrActivities.add(activity);
    prefs.setString('activities', encode(arrActivities));
  }

  print(prefs.getString('activities'));
}

String dateConvert({@required var date, @required String dateFormat}){
  initializeDateFormatting('id'); //inisialisasi date dalam  bahasa indonesia
  DateTime dateTime = DateTime.parse(date.toString());
  DateFormat format = DateFormat(dateFormat, 'id'); // 'id' kode untuk bahasa indonesia
  String formatted = format.format(dateTime).toString();
  return formatted;
}