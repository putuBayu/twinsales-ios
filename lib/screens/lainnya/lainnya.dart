import 'package:flutter/material.dart';
import 'package:sales/screens/lainnya/panduan/panduan.dart';
import 'package:sales/screens/lainnya/password/password.dart';
import 'package:sales/screens/lainnya/profil/profil.dart';
import 'package:sales/screens/login/login.dart';
import 'package:sales/services/api/api.dart';
import 'package:sales/services/constant.dart';
import 'package:sales/services/v2/helper.dart';
import 'package:sales/services/v3/helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Lainnya extends StatefulWidget {
  final ctx;
  Lainnya(this.ctx);

  @override
  _LainnyaState createState() => _LainnyaState();
}

class _LainnyaState extends State<Lainnya> {

  var user = {};

  initUser(){
    getPrefs('user', dec: true).then((res){
      if(res != null){
        user = res;
      }
    });
  }

  Widget label(icon, label){
    return Container(
      margin: EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          Container(
            margin: EdgeInsets.only(right: 7),
            child: Icon(icon, size: 20)
          ), text(label, color: Colors.black45, bold: true),
        ]
      )
    );
  }

  Widget list(icon, label){
    return Container(
      padding: EdgeInsets.only(top: 13, bottom: 13, left: 15, right: 10),
      decoration: BoxDecoration(
        border: Border(
            bottom: BorderSide(color: Colors.white)
        )
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          text(label, color: Colors.black87),
          Icon(icon, color: Colors.black26, size: 20)
        ]
      ),
    );
  }

  Widget listGroup({IconData icon, String label, double space: 25, @required List<Widget> children}){
    return Container(
      margin: EdgeInsets.only(bottom: space),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 17),
              Container(
                margin: EdgeInsets.only(left: 10),
                child: text(label)
              )
            ],
          ),

          Container(
            margin: EdgeInsets.only(top: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          )
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState(); initUser();
  }

  @override
  Widget build(BuildContext context) {

    // void onSelected(index){
    //   switch (index) {
    //     case 0: modalBottom(index); break;
    //     case 1: modalBottom(index); break;
    //     case 2: modalBottom(index); break;
    //     case 3 :
    //       showDialog(
    //         context: context,
    //         builder: (BuildContext context) {
    //           return AppInfo();
    //         },
    //       );
    //     break;
    //     case 4: isLogout(context); break;
    //   }
    // }

    return Scaffold(
      backgroundColor: TColor.silver(),
      appBar: Wh.appBar(context, title: 'Menu', back: false),

      body: PreventScrollGlow(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              listGroup(
                icon: Ic.user(), label: 'PROFIL',
                children: List.generate(1, (i){
                  var labels = ['Profil Saya'];

                  return WidSplash(
                    onTap: (){
                      getPrefs('user', dec: true).then((res){
                        if(res != null) modal(widget.ctx, child: Profil(user: res));
                      });
                    },
                    color: Colors.white,
                    child: Container(
                      width: Mquery.width(context),
                      padding: EdgeInsets.all(12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          text(labels[i]), Icon(Ic.user(), size: 17, color: Colors.black38)
                        ],
                      )
                    ),
                  );
                })
              ),

              listGroup(
                icon: Ic.lock(), label: 'AKUN',
                children: List.generate(2, (i){
                  var labels = ['Ganti Password', 'Logout'],
                      icons = [Ic.lock(), Ic.logout()];

                  return WidSplash(
                    onTap: (){
                      switch (i) {
                        case 0: modal(widget.ctx, child: Password()); break;

                        case 1: Wh.confirmation(widget.ctx, message: 'Keluar dari akun '+ucword(user['name'].toLowerCase())+'?', confirmText: 'Keluar', then: (res){
                          if(res != null && res == 0){
                            showDialog(
                              context: context,
                              child: OnProgress(message: 'Logout...')
                            );

                            setTimer(1, then: (t){
                              Request.post('logout', then: (status, d){
                                clearPrefs(except: ['user','loginWithEmail','api','printer']);

                                Navigator.pop(widget.ctx);
                                Navigator.of(widget.ctx).popUntil((route) => route.isFirst);
                                Navigator.of(widget.ctx).pushReplacement(MaterialPageRoute(builder: (BuildContext context) => Login()));
                              }, error: (err){
                                onError(context, response: err, popup: true);
                              });
                            });
                          }
                        }); break;

                        default: break;
                      }
                    },
                    color: Colors.white,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                            bottom: BorderSide(color: TColor.silver())
                        )
                      ),
                      width: Mquery.width(context),
                      padding: EdgeInsets.all(12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          text(labels[i]),
                          Icon(icons[i], size: 17, color: Colors.black38)
                        ],
                      )
                    ),
                  );
                })
              ),

              listGroup(
                icon: Ic.link2(), label: 'TAUTAN',
                children: List.generate(1, (i){
                  var labels = ['Situs Web Resmi'];

                  return WidSplash(
                    onTap: (){
                      switch (i) {
                        case 0: goto('https://kembarputra.com'); break;
                      }
                    },
                    color: Colors.white,
                    child: Container(
                      width: Mquery.width(context),
                      padding: EdgeInsets.all(12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          text(labels[i]),
                          Icon(Ic.globe(), size: 17, color: Colors.black38)
                        ],
                      )
                    ),
                  );
                })
              ),

              listGroup(
                icon: Ic.list(), label: 'LAINNYA', space: 0,
                children: List.generate(4, (i){
                  var labels = ['Tentang Aplikasi','Hubungi IT Support','Nilai Kami','Panduan'],
                      icons = [Ic.info(),Ic.whatsapp(),Ic.star(),Ic.book()];

                  return WidSplash(
                    onTap: (){
                      switch (i) {
                        case 0: Wh.dialog(context, child: AppInfo()); break;
                        case 1: goto('https://chat.whatsapp.com/BF6SzDk0VhCJqtwgV4YAbI'); break;
                        case 2: goto('https://play.google.com/store/apps/details?id=com.jangkar.sales'); break;
                        default: modal(widget.ctx, child: Panduan()); break;
                        // default: break;
                      }
                    },
                    color: Colors.white,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: TColor.silver()))
                      ),
                      width: Mquery.width(context),
                      padding: EdgeInsets.all(12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          text(labels[i]), Icon(icons[i], size: 17, color: Colors.black38)
                        ],
                      )
                    ),
                  );
                })
              ),
            ]
          ),
        ),
      ),
    );
  }
}

class AppInfo extends StatefulWidget {
  @override
  _AppInfoState createState() => _AppInfoState();
}

class _AppInfoState extends State<AppInfo> {

  var tap = 0, apiSelected = 0, isSave = false;
  var apiName = [
    'https://kpm-api.kembarputra.com',
    'https://kpm-api-test.kembarputra.com'
  ];

  initApi() {
    apiSelected = 0; 
    
    getPrefs('api').then((res){
      if(res != null){
        apiSelected = apiName.indexOf(res);
      }
    });
  }

  setApi() async{
    var prefs = await SharedPreferences.getInstance();
    
    setState(() {
      isSave = true;
    });

    Request.post('logout', then: (status, body){
      if(status == 200){
        clearPrefs(except: ['user','loginWithEmail','api','printer']);

        prefs.setString('api', apiName[apiSelected]);

        if(apiName[apiSelected] == 'https://kpm-api.kembarputra.com'){
          setPrefs('mode', 'production');
        }else{
          setPrefs('mode', 'development');
        }

        Navigator.of(context).popUntil((route) => route.isFirst);
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (BuildContext context) => Login()));
      }else{
        Wh.alert(context, title: 'Terjadi kesalahan');
        Navigator.of(context).pop();
      } 
    });
  }

  @override
  void initState() {
    super.initState();
    initApi();
  }

  @override
  Widget build(BuildContext context) {
    return ZoomIn(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            padding: EdgeInsets.all(0),
            width: MediaQuery.of(context).size.width,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(2)
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                tap >= 5 ?
                SlideUp(
                  child: Container(
                    child: Column(
                      children: List.generate(apiName.length, (int i){

                        return WidSplash(
                          onTap: isSave ? null : (){
                            setState(() {
                              apiSelected = i;
                            });
                          },
                          color: isSave ? TColor.gray() : Colors.white,
                          padding: EdgeInsets.all(0),
                          child: Container(
                            padding: EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              border: Border(
                                  bottom: BorderSide(
                                      color: Colors.black12
                                  )
                              )
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Row(
                                  children: <Widget>[
                                    Icon(Ic.link(), color: Colors.blue, size: 15),
                                    Container(
                                      margin: EdgeInsets.only(left: 10),
                                      child: text(apiName[i]),
                                    )
                                  ],
                                ),
                                apiSelected == i ? Icon(Ic.check(), color: Colors.green, size: 18) : SizedBox.shrink()
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ) :

                Column(
                    children: <Widget>[
                      Container(
                          padding: EdgeInsets.only(left: 15, top: 15, right: 15),
                          child: html('<b>'+APP_NAME+'</b> adalah aplikasi internal yang dibuat dan dikembangkan oleh <b>PT Jangkar Teknologi Indonesia</b> untuk memudahkan transaksi antara salesman dan toko atau outlet yang menjalin kerjasama dengan perusahaan yang dinaungi oleh PT Jangkar Teknologi Indonesia.')
                      ),

                      Container(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              GestureDetector(
                                  onTap: (){
                                    tap += 1;

                                    if(tap >= 5){
                                      setState(() { });
                                    }
                                  },
                                  child: Container(
                                    padding: EdgeInsets.all(15),
                                    child: html('Version : '+App.version()),
                                  )
                              )
                            ],
                          )
                      )
                    ]
                )
              ],
            )
          ),

          tap < 5 ? SizedBox.shrink() :

          SlideUp(
            child: Container(
              child: Container(
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                  color: Colors.white
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    
                    Container(
                      child: Row(
                        children: List.generate(2, (int i){
                          var btnLabel = ['Batal', 'OK'];

                          return WidSplash(
                            onTap: isSave ? null : (){
                              if(i == 0){
                                Navigator.pop(context);
                              }else{
                                setApi();
                              }
                            },
                            child: Row(
                              children: <Widget>[
                                Container(
                                  width: MediaQuery.of(context).size.width / 2 - 15,
                                  padding: EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    border: Border(left: BorderSide(
                                      color: i == 0 ? Colors.transparent : Colors.black12
                                    ))
                                  ),
                                  child: i == 0 ? text(btnLabel[i],
                                      align: TextAlign.center) : isSave ? Wh.spiner(size: 17) : text(btnLabel[i], align: TextAlign.center),
                                )
                              ],
                            ),
                          );
                        }),
                      )
                    )
                  ],
                ),
              ),
            )
          )
        ],
      ),
    );
  }
}