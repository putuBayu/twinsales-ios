import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sales/screens/dashboard.dart';
import 'package:sales/services/api/api.dart';
import 'package:sales/services/v2/helper.dart';
import 'package:sales/services/v3/helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_statusbarcolor/flutter_statusbarcolor.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sales/services/constant.dart';

class Login extends StatefulWidget {
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final databaseReference = Firestore.instance;

  Timer timer;
  bool isDev = false;

  final email = TextEditingController(),
        password = TextEditingController();

  // focus node
  var emailNode = new FocusNode();
  var passNode = new FocusNode();

  var isLogin = false, copyright = true, obsecure = true;

  initScreen() async {

    // check envi
    isDev = await Env.isDev();

    // set status bar color
    await FlutterStatusbarcolor.setStatusBarColor(Colors.transparent);
    FlutterStatusbarcolor.setStatusBarWhiteForeground( useWhiteForeground(Colors.transparent) ? true : false);

    // check token
    var prefs = await SharedPreferences.getInstance(),
        user = prefs.getString('user');

    setUserMail(){
      if(user != null){
        setState(() {
          if(prefs.getBool('loginWithEmail') != null){
            email.text = prefs.getBool('loginWithEmail') ? decode(user)['email'] : decode(user)['phone'].toString();
          }
        });
      }
    }

    if( prefs.getString('token') != '' && prefs.getString('token') != null ){
      Wh.dialog(context, child: CheckToken());
      setUserMail();
    }else{
      setUserMail();
    }
  }

  @override
  void initState() {
    setTimer(1, then: (t){
      statusBar(color: Colors.transparent, darkText: true);
    });

    super.initState();

    // check token (expired or not)
    initScreen();
    requestPermissions(location: true);
  }

  signin() async {
    request(){
      var formData = emailValidate(email.text) ? { // jika bukan format email -> no. telepon
        'email': email.text, 
        'password': password.text 
      } : {
        'phone': email.text, 
        'password': password.text 
      };

      if(email.text.isEmpty || password.text.isEmpty){
        focus(context, email.text.isEmpty ? emailNode : passNode);
      }else{
        setState(() {
          isLogin = true;
        });
        
        timer = Timer(Duration(seconds: 15), (){
          setState(() => isLogin = false );
          Wh.alert(context,
            icon: Ic.server(), 
            color: TColor.red(), 
            borderColor: TColor.red(), 
            message: 'Tidak dapat terhubung ke server, coba periksa koneksi internet anda atau beritahu TIM IT perihal masalah ini.',
            textConfirm: 'Hubungi TIM IT',
            onTap: (){
              goto('https://chat.whatsapp.com/BF6SzDk0VhCJqtwgV4YAbI');
            }
          );
        });

        Request.post('login', formData: formData, authorization: false, debug: true, then: (status, data){
          timer.cancel();
          var map = decode(data),
              token = 'Bearer '+map['token'],
              roles = map['roles'].map((item) => item.toString().toLowerCase()).toList(),
              permissions = map['permissions'],
              user = map['user'];

          if( roles.indexOf('salesman') < 0 && roles.indexOf('salesman canvass') < 0 && roles.indexOf('administrator') < 0 && roles.indexOf('sales supervisor') < 0 && roles.indexOf('sales koordinator') < 0){
            Wh.alert(context, message: 'Akun ini tidak terdaftar untuk aplikasi sales, pastikan Anda login dengan akun sales.', 
              icon: Ic.userx(), color: TColor.red(), borderColor: TColor.red()
            );
          }else{
            setPrefs('token', token);
            setPrefs('roles', roles);
            setPrefs('user', user, enc: true);
            setPrefs('permissions', permissions);

            if( roles.indexOf('salesman') > -1 || roles.indexOf('salesman canvass') > -1 ){
              setPrefs('id_gudang', map['id_gudang']);
              setPrefs('nama_gudang', map['nama_gudang']);
              setPrefs('log_salesman', map['salesman'], enc: true);
            }

            // catat di localstorage user login menggunakan email atau telepon
            setPrefs('loginWithEmail', formData['email'] != null ? true : false);
            Wh.dialog(context, child: PreparingData(token: token, roles: roles, user: user,), dismiss: true, forceClose: true);
          }
         
          setState(() => isLogin = false );
        }, error: (err){
          timer.cancel();
          setState(() => isLogin = false );
          onError(context, response: err);
        });
      }
    }

    requestPermissions(location: true, then: (allowed){
      if(allowed){
        if(email.text.isEmpty || password.text.isEmpty){
          focus(context, email.text.isEmpty ? emailNode : passNode);
        }else{
          // check app version
          setState(() => isLogin = true );

          databaseReference.collection('version').document(TRIGGER_UPDATE).get().then((snap){
            String version = snap.data['version'];
            bool req = snap.data['required'];

            if(version != App.version() && req){
              setState(() => isLogin = false );
              Wh.dialog(context, child: Warning(version));
            }else{
              request();
            }
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {

    statusBar(color: Colors.transparent, darkText: true);

    return Unfocus(
      child: Scaffold(
        backgroundColor: Color.fromRGBO(229, 232, 236, 1),
        body: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: PreventScrollGlow(
                  child: SingleChildScrollView(
                    child: Container(
                      padding: EdgeInsets.all(15),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ColorFiltered(
                            colorFilter: isDev ? CFilter.grayScale() : ColorFilter.mode(Colors.transparent, BlendMode.color),
                            child: Container(
                              height: 133, width: 133, margin: EdgeInsets.only(bottom: 25, top: Mquery.statusBar(context)+30),
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  image: AssetImage('assets/img/twin.png')
                                )
                              ),
                            ),
                          ),

                          Fc.textfield(
                            controller: email, hint: 'Inputkan alamat email',
                            length: 50, suffix: Icon(Ic.mail(), size: 18), node: emailNode, submit: (String s){ focus(context, passNode); },
                            type: TextInputType.emailAddress, action: TextInputAction.next,
                          ),

                          Fc.textfield(
                            controller: password, hint: 'Inputkan password', obsecure: obsecure,
                            length: 15, node: passNode, submit: (String s){ signin(); }, marginBottom: 0,
                            type: TextInputType.emailAddress, action: TextInputAction.go,
                            suffix: WidSplash(
                              onTap: (){
                                setState(() => obsecure = !obsecure );
                              },
                              child: Icon(obsecure ? Ic.lock() : Ic.unlock(), size: 18,),
                            )
                          ),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              WidSplash(
                                splash: Colors.transparent, highlightColor: Colors.transparent,
                                padding: EdgeInsets.only(top: 15, bottom: 15),
                                child: text('Saya lupa password', color: TColor.azure(), align: TextAlign.right),
                                onTap: (){
                                  Wh.alert(
                                    context, icon: Icons.info_outline,
                                    message: 'Untuk permasalahan seperti lupa password akun atau kendala lainnya yang berhubungan dengan aplikasi ini silahkan hubungi TIM IT.',
                                    textConfirm: 'Hubungi TIM IT',
                                    onTap: (){
                                      goto('https://chat.whatsapp.com/BF6SzDk0VhCJqtwgV4YAbI');
                                    }
                                  );
                                },
                              ),
                            ]
                          )
                        ]
                      )
                    ),
                  ),
                ),
              ),

              Container(
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Color.fromRGBO(229, 232, 236, 1),
                  boxShadow: [
                    BoxShadow(
                      color: Color.fromRGBO(229, 232, 236, .8),
                      spreadRadius: 25,
                      blurRadius: 7,
                      offset: Offset(0, 3), // changes position of shadow
                    ),
                  ],
                ),
                child: Column(
                  children: <Widget>[
                    WidSplash(
                      onTap: isLogin ? null : () { signin(); },
                      color: TColor.azure(o: isLogin ? .5 : 1),
                      child: Container(
                        width: Mquery.width(context),
                        padding: EdgeInsets.only(left: 15, right: 15, top: 11, bottom: 11),
                        child: isLogin ? Wh.spiner(color: Colors.white) : text('Masuk', spacing: 2, align: TextAlign.center, color: Colors.white),
                      ),
                    ),

                    Container(
                      margin: EdgeInsets.only(top: 10),
                      child: text('App Version '+App.version(), size: 13),
                    )
                  ],
                )
              )
            ]
          ),
        )
    );
  }
}

// menyiapkan data untuk level user tertentu
class PreparingData extends StatefulWidget {
  final token, roles, user;
  PreparingData({this.token, this.roles, this.user});

  @override
  _PreparingDataState createState() => _PreparingDataState();
}

class _PreparingDataState extends State<PreparingData>{

  var token = '', isLoaded = false, onRun = '';

  void checkData({label}){
    setState(() { isLoaded = true; });
    Navigator.of(context).popUntil((route) => route.isFirst);
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (BuildContext context) => Dashboard()));
  }

  isSales(){
    if( widget.roles.indexOf('salesman') > -1 || widget.roles.indexOf('salesman canvass') > -1 ){
      return true;
    }

    return false;
  }

  Future getDataToko() async {
    if(!isSales()){
      getDataPromo();
    }else{
      setState(() { onRun = 'toko'; });

      Request.get('penjualan/list/toko', then: (status, res){
        if(mounted){
          setPrefs('toko', decode(res)['data'], enc: true);
          getDataPromo();
        }
      }, error: (err){
        removePrefs(list: ['token']); // hapus token jadi saat app dibuka lagi user masih di halaman login
        onError(context, response: err, popup: true, backOnDismiss: true);
      });
    }
  }

  Future getDataPromo() async {
    setState(() { onRun = 'promo'; });

    Request.get('promo', then: (status, res){
      setPrefs('promo', decode(res)['data'], enc: true);
      getDataBarang();
    }, error: (err){
      removePrefs(list: ['token']);
      onError(context, response: err, popup: true, backOnDismiss: true);
    });
  }

  Future getDataBarang() async {
    if(!isSales()){
      getDataSalesman();
    }else{
      setState(() { onRun = 'barang'; });

      Request.get('detail_penjualan/list/barang', then: (status, res){
       if(mounted){
         setPrefs('barang', decode(res)['data'], enc: true);
         getDataBarangRetur();
       }
      }, error: (err){
        removePrefs(list: ['token']);
        onError(context, response: err, popup: true, backOnDismiss: true);
      });
    }
  }

  Future getDataBarangRetur() async {
    if(!isSales()){
      getDataSalesman();
    }else{
      setState(() { onRun = 'semua barang'; });

      Request.get('barang?per_page=all', then: (status, res){
        setPrefs('barangRetur', decode(res)['data'], enc: true);
        getDataUser();
      }, error: (err){
        removePrefs(list: ['token']);
        onError(context, response: err, popup: true, backOnDismiss: true);
      });
    }
  }

  Future getDataSalesman() async {
    if(isSales()){
      getDataUser();
    }else{
      setState(() { onRun = 'salesman'; });

      Request.get('salesman', then: (status, res){
        setPrefs('salesman', decode(res)['data'], enc: true);
        getDataTim();
      }, error: (err){
        removePrefs(list: ['token']);
        onError(context, response: err, popup: true, backOnDismiss: true);
      });
    }
  }

  Future getDataTim() async {
    if(isSales()){
      getDataUser();
    }else{
      setState(() { onRun = 'tim'; });

      Request.get('tim', then: (status, res){
        setPrefs('tim', decode(res)['data'], enc: true);
        getDataUser();
      }, error: (err){
        removePrefs(list: ['token']);
        onError(context, response: err, popup: true, backOnDismiss: true);
      });
    }
  }

  Future getDataUser() async {
    setState(() { onRun = 'user'; });

    Request.get('salesman/get/salesman_principal?id_user=' + widget.user['id'].toString(), then: (status, res){
      setPrefs('user-eksklusif', decode(res)['data'], enc: true);
      checkData();
    }, error: (err){
      removePrefs(list: ['token']);
      onError(context, response: err, popup: true, backOnDismiss: true);
    });
  }

  @override
  void initState() {
    super.initState();
    
    token = widget.token;
    if(mounted) getDataToko();
  }

  Future<bool> onWillPop() {
    return Future.value(false);
  }

  @override
  Widget build(BuildContext context) {
    return SlideUp(
      child: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/img/line-card.png'),
            fit: BoxFit.fill
          )
        ),
        padding: EdgeInsets.all(5),
        child: isLoaded ? Row(
          children: <Widget>[
            Container(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.check, color: Colors.green,)
            ), text('Data sudah siap')
          ],
        ) : Row(
          children: <Widget>[
            Wh.spiner(size: 25, margin: 15),
            Flexible(
              child: Container(
                padding: EdgeInsets.only(right: 15),
                child: text('Mohon menunggu, sedang menyiapkan data '+onRun),
              )
            )
          ],
        ),
      )
    );
  }
}

class CheckToken extends StatefulWidget {
  @override
  _CheckTokenState createState() => _CheckTokenState();
}

class _CheckTokenState extends State<CheckToken> {

  signin() async {
    Timer timer = setTimer(25, then: (t){      
      if(t){
        Wh.toast('Periksa koneksi internet Anda');
        Navigator.pop(context);
      }                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   
    });

    Request.get('me', then: (status, data){
      timer.cancel(); Navigator.pop(context);
      Navigator.of(context).popUntil((route) => route.isFirst);
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (BuildContext context) => Dashboard()));
    }, error: (err){ print(err);
      timer.cancel();
      onError(context, response: err);
      Navigator.pop(context);
    });
  }
  
  @override
  void initState() {
    super.initState();
    signin();
  }

  Future<bool> onWillPop() {
    return Future.value(false);
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/img/line-card.png'),
          fit: BoxFit.fill
        )
      ),
      child: Column(
        children: <Widget>[
          Container(
            child: Row(
              children: <Widget>[
                Wh.spiner(size: 25, margin: 15),
                text('Mohon menunggu...', color: Colors.black54),
              ],
            ),
          ),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(5),
                bottomRight: Radius.circular(5),
              )
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[],
            ),
          )
        ]
      ),
    );
  }
}

class Warning extends StatefulWidget {
  final String version;

  Warning(this.version);

  @override
  _WarningState createState() => _WarningState();
}

class _WarningState extends State<Warning> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
          width: Mquery.width(context),
          margin: EdgeInsets.all(15),
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(5)
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                margin: EdgeInsets.only(bottom: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Icon(Icons.info_outline),
                        SizedBox(width: 10,),
                        text('Update Required!', bold: true)
                      ],
                    ),
                  ],
                ),
              ),
              text('Aplikasi yang Anda gunakan adalah versi yang lama, untuk menghindari terjadinya kesalahan silahkan update ke versi yang terbaru ('+widget.version+'). \n\nDownload di playstore atau hubungi Tim IT.', color: Colors.black54),
            ],
          ),
        )
      ],
    );
  }
}