import 'package:flutter/material.dart';
import 'package:sales/screens/penjualan/laporan/average-per-toko/laporan-average-per-toko.dart';
import 'package:sales/screens/penjualan/laporan/laporan-estimasi.dart';
import 'package:sales/screens/penjualan/laporan/laporan-target-salesman.dart';
import 'package:sales/screens/penjualan/riwayat-penjualan/admin-riwayat-penjualan.dart';
import 'package:sales/screens/penjualan/laporan/laporan-aktual.dart';
import 'package:sales/screens/penjualan/laporan/laporan-penjualan.dart';
import 'package:sales/screens/penjualan/laporan/laporan-posisi-stock.dart';
import 'package:sales/screens/penjualan/pelunasan/daftar-pelunasan.dart';
import 'package:sales/screens/penjualan/penjualan/forms/form-penjualan.dart';
import 'package:sales/screens/penjualan/penjualan/penjualan-hari-ini.dart';
import 'package:sales/screens/penjualan/retur-barang/retur.dart';
import 'package:sales/services/api/api.dart';
import 'package:sales/services/constant.dart';
import 'package:sales/services/v2/helper.dart';
import 'package:sales/services/v3/helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'riwayat-penjualan/riwayat-penjualan.dart';

class Penjualan extends StatefulWidget {
  final ctx, isSales;
  Penjualan({this.ctx, this.isSales: false});

  @override
  _PenjualanState createState() => _PenjualanState();
}

class _PenjualanState extends State<Penjualan> {
  var role, auth, api;
  bool development = false;
  int count;

  getCount(){
    if(widget.isSales){
      Request.get('/penjualan/count/penjualan_today?status=waiting', then: (status, body){
        if(mounted){
          int res = decode(body);
          // loading = false;

          setState(() {
            count = res;
            // tipeHarga.text = dataTipeHarga[0].toString();
          });

          return res;
        }
      }, error: (err){
        // setState(() { loading = false; });
        onError(context, response: err);
      });
    }
  }

  initUser() async {
    // await FlutterStatusbarcolor.setStatusBarColor(Colors.red);
    //       FlutterStatusbarcolor.setStatusBarWhiteForeground( useWhiteForeground(Colors.red) ? false : true);

    var prefs = await SharedPreferences.getInstance(),
        user = decode(prefs.getString('user'));
    setState(() {
      role = user['role'];
      auth = user;
    });

    getPrefs('api').then((res) {
      if (res != null) {
        if (res != 'https://kpm-api.kembarputra.com') {
          development = true;
          api = res;
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    initUser();
    getCount();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: ScrollConfiguration(
            behavior: ScrollConfig(),
            child: SingleChildScrollView(
              child: Stack(
                children: <Widget>[
                  CurvedShape(
                    color: Colors.blueGrey[100],
                    height: 130,
                    radius: -80,
                  ),
                  CurvedShape(
                    color: TColor.azure(),
                    height: 120,
                    radius: -60,
                  ),
                  Column(
                    children: <Widget>[
                      Container(
                          margin: EdgeInsets.only(top: 20),
                          padding: EdgeInsets.all(15),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Expanded(
                                child: html(APP_NAME, size: 25, bold: true, color: Colors.white),
                              ),
                              development
                                  ? Container(
                                      margin: EdgeInsets.only(right: 15),
                                      child: WidSplash(
                                        radius: BorderRadius.circular(50),
                                        onTap: () {
                                          print(development);
                                          Wh.alert(context, icon: Ic.code(), title: 'Mode Development', message: api);
                                        },
                                        child: Container(
                                            padding: EdgeInsets.all(5),
                                            child: Icon(Ic.code(), color: Colors.white),
                                        ),
                                      ),
                                    )
                                  : SizedBox.shrink(),
                              SingleChildScrollView(
                                child: Material(
                                  color: TColor.blue(o: .3),
                                  borderRadius: BorderRadius.circular(50),
                                  child: WidSplash(
                                    onTap: () {
                                      showDialog(
                                          context: context, child: MyProfile());
                                    },
                                    child: Container(
                                      child: Icon(Icons.account_circle,
                                          color: Colors.white, size: 33),
                                      padding: EdgeInsets.all(5),
                                    ),
                                    splash: TColor.blue(o: .5),
                                    highlightColor: TColor.blue(o: .5),
                                    radius: BorderRadius.circular(50),
                                  ),
                                ),
                              )
                            ],
                          ),
                      ),
                      Container(
                        margin: EdgeInsets.only(left: 15, right: 15),
                        child: Wrap(
                          children: List.generate(6, (int i) {
                            var labels = [
                                  'Penjualan Baru',
                                  'Penjualan Hari Ini',
                                  'Riwayat Penjualan',
                                  'Retur Penjualan',
                                  // 'Kunjungan Hari Ini',
                                  // 'Riwayat Kunjungan',
                                  'Pelunasan',
                                  'Laporan'
                                ],
                                icons = [
                                  Feather.edit_3,
                                  Feather.calendar,
                                  Feather.clock,
                                  Feather.corner_up_left,
                                  // Feather.user_check,
                                  // Feather.clipboard,
                                  Feather.check_square,
                                  Feather.file_text
                                ],
                                desc = [
                                  'Buat penjualan baru',
                                  'Daftar penjualan hari ini',
                                  'Daftar riwayat penjualan',
                                  'Daftar retur penjualan',
                                  // 'Daftar kunjungan outlet hari ini',
                                  // 'Daftar riwayat kunjungan',
                                  'Daftar pelunasan',
                                  'Daftar Laporan'
                                ];

                            return Container(
                              padding: EdgeInsets.all(5),
                              child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    WidSplash(
                                      onTap: () async {
                                        var padding = MediaQuery.of(context).padding.top;
                                        statusBar(
                                          color: Colors.transparent,
                                          darkText: false
                                        );

                                        switch (i) {
                                          case 0:
                                            statusBar(color: Colors.transparent, darkText: true);
                                            Navigator.of(widget.ctx).push(MaterialPageRoute(
                                                builder: (BuildContext context) => FormPenjualan(widget.ctx,))
                                            );
                                            // if (widget.isSales) {
                                            //   // modal(widget.ctx, radius: 5, child: FormPenjualan(widget.ctx), then: (res) {});
                                            //   statusBar(color: Colors.transparent, darkText: true);
                                            //   Navigator.of(widget.ctx).push(MaterialPageRoute(
                                            //       builder: (BuildContext context) => FormPenjualan(widget.ctx,))
                                            //   ).then((value){
                                            //     statusBar(color: Colors.transparent, darkText: false);
                                            //   });
                                            // } else {
                                            //   Wh.alert(context, icon: Ic.userx(), borderColor: TColor.red(), color: TColor.red(), message: 'Selain salesman tidak dapat menambahkan penjualan pada aplikasi ini.');
                                            // }
                                            break;

                                          case 1:
                                            modal(widget.ctx, child: PenjualanHariIni(ctx: widget.ctx, paddingTop: padding), then: (res) {
                                              getCount();
                                            });
                                            break;

                                          case 2:
                                            modal(widget.ctx, child: widget.isSales ? RiwayatPenjualan(widget.ctx) : RiwayatPenjualanAdmin(ctx: widget.ctx, paddingTop: padding), then: (res) {});
                                            break;

                                          case 3:
                                            modal(widget.ctx, child: Retur(widget.ctx), then: (res) {});
                                            break;

                                          // case 4:
                                          //   modal(widget.ctx, radius: 5, child: KunjunganHariIni(widget.ctx), then: (res) {});
                                          //   break;
                                          //
                                          // case 5:
                                          //   modal(widget.ctx, child: RiwayatKunjungan(ctx: widget.ctx), then: (res) {});
                                          //   break;

                                          case 4:
                                            modal(widget.ctx, child: DaftarPelunasan(ctx: widget.ctx), then: (res) {});
                                            break;

                                          default:
                                            modal(widget.ctx, wrap: true, child: DaftarLaporan(widget.ctx), then: (res) {});
                                          // modal(widget.ctx, child: LaporanPenjualan(), then: (res){ setStatusBar(color: 'red-white'); });
                                        }
                                      },
                                      color: Colors.white,
                                      radius: BorderRadius.circular(4),
                                      child: Container(
                                        padding: EdgeInsets.only(left: 15, right: 15, top: 15, bottom: 15),
                                        height: 140,
                                        decoration: BoxDecoration(
                                            border: Border.all(color: Colors.black12),
                                            borderRadius: BorderRadius.circular(4)
                                        ),
                                        width: Mquery.width(context) / 2 - 25,
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: <Widget>[
                                            Container(
                                                margin: EdgeInsets.only(bottom: 15),
                                                height: 40,
                                                decoration: BoxDecoration(
                                                      // border: Border.all(color: Colors.black12)
                                                ),
                                                child: Badges(
                                                  title: count.toString(),
                                                  showBadge: i != 1 || count == null || count == 0 ? false : true,
                                                  child: Icon(icons[i], size: 33, color: Colors.blueGrey)
                                                ),
                                            ),
                                            Container(
                                              height: 50,
                                              child: Column(
                                                children: <Widget>[
                                                  text(labels[i], bold: true, align: TextAlign.center),
                                                  Flexible(
                                                    child: text(desc[i], color: Colors.black45, align: TextAlign.center, size: 14),
                                                  )
                                                ],
                                              ),
                                            )
                                          ],
                                        ),
                                      ),
                                    ),
                                  ]),
                            );
                          }),
                        ),
                      )
                    ],
                  )
                ],
              ),
            ),
        ),
    );
  }
}

class DaftarLaporan extends StatefulWidget {
  final ctx;
  DaftarLaporan(this.ctx);

  @override
  _DaftarLaporanState createState() => _DaftarLaporanState();
}

class _DaftarLaporanState extends State<DaftarLaporan> {
  var auth;
  var labels = [
    'Laporan Penjualan',
    'Laporan Estimasi Penjualan',
    'Laporan Aktual',
    'Laporan Posisi Stock',
    'Laporan Average Per Toko',
    'Laporan Target Salesman'
  ];

  initAuth() {
    getPrefs('user', dec: true).then((res) {
      auth = res;
    });
  }

  @override
  void initState() {
    super.initState();
    initAuth();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: List.generate(labels.length, (int i) {
          return WidSplash(
              onTap: () {
                Navigator.pop(context);

                switch (i) {
                  case 0:
                    modal(widget.ctx, child: LaporanPenjualan(), then: (res) {});
                    break;

                  case 1:
                    modal(widget.ctx, child: LaporanEstimasi(), then: (res) {});
                    break;

                  case 2:
                    modal(widget.ctx, child: LaporanAktual(), then: (res) {});
                    break;

                  case 3:
                    modal(widget.ctx, child: LaporanPosisiStock(widget.ctx, auth: auth), then: (res) {});
                    break;

                  case 4:
                    modal(widget.ctx, child: LaporanAveragePerToko(widget.ctx), then: (res) {});
                    break;

                  case 5:
                    modal(widget.ctx, child: LaporanTargetSalesman(widget.ctx), then: (res) {});
                    break;

                  default:
                }
              },
              child: Container(
                decoration: BoxDecoration(
                    border: Border(
                        bottom: BorderSide(
                            color: i != labels.length-1 ? Colors.black12 : Colors.transparent))),
                padding: EdgeInsets.all(15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    text(labels[i]),
                    // Wi.itext(icon: Icon(Feather.file_text, size: 20), child: labels[i]),
                    Icon(Icons.chevron_right, color: Colors.black38, size: 20)
                  ],
                ),
              ),
          );
        }),
      ),
    );
  }
}

class MyProfile extends StatefulWidget {
  @override
  _MyProfileState createState() => _MyProfileState();
}

class _MyProfileState extends State<MyProfile> {
  var name, email, phone, role, status, tim, tipe, gudang, isSales = false;

  initUser() async {
    // var prefs = await SharedPreferences.getInstance(), data = decode(prefs.getString('user')), roles = prefs.getStringList('roles'), namaGudang = prefs.getString('nama_gudang');

    // setState(() {
    //   name = data['name']; email = data['email']; phone = data['phone'];
    //   role = roles.join(', '); status = data['status'];

    //   if(prefs.getString('log_salesman') != null){
    //     var salesman = decode(prefs.getString('log_salesman'));
    //     tim = salesman['nama_tim'];
    //     tipe = salesman['tipe'];
    //     gudang = namaGudang;
    //   }
    // });

    getPrefs('user', dec: true).then((user) {
      setState(() {
        name = user['name'];
        email = user['email'];
        phone = user['phone'];

        getPrefs('log_salesman', dec: true).then((res) {
          if (res != null) {
            setState(() {
              tim = res['nama_tim'];
              tipe = res['tipe'];
            });
          }
        });

        getPrefs('nama_gudang').then((res) {
          if (res != null) {
            gudang = res;
          }
        });

        getPrefs('roles', type: List).then((roles) {
          this.role = roles.join(',');

          if (roles.indexOf('salesman') > -1 ||
              roles.indexOf('salesman canvass') > -1) {
            isSales = true;
          }
        });
      });
    });
  }

  listUserInfo() {
    var list = <Widget>[],
        title = isSales
            ? ['No. Telepon', 'Posisi', 'Nama Tim', 'Tipe Salesman', 'Gudang']
            : ['No. Telepon', 'Posisi'],
        value = [phone, role, tim, tipe, gudang];

    for (var i = 0; i < title.length; i++) {
      list.add(Container(
        // padding: EdgeInsets.only(top: 1, bottom: 1),
        padding: EdgeInsets.only(left: 15, right: 15, top: 10, bottom: 10),
        decoration:
            BoxDecoration(color: i % 2 == 0 ? TColor.silver() : Colors.white),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[text(title[i], bold: true), text(ucword(value[i]))],
        ),
      ));
    }
    return list;
  }

  @override
  void initState() {
    super.initState();
    initUser();
  }

  @override
  Widget build(BuildContext context) {
    return ZoomIn(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: Container(
              // padding: EdgeInsets.all(15),
              width: Mquery.width(context) - 30,
              decoration: BoxDecoration(
                color: Colors.white,
              ),
              child: Material(
                child: Column(
                  children: <Widget>[
                    Stack(
                      children: <Widget>[
                        Container(width: Mquery.width(context)),
                        Center(
                          child: Container(
                            margin: EdgeInsets.only(bottom: 15, top: 35),
                            decoration: BoxDecoration(
                              border:
                                  Border.all(color: TColor.silver(), width: 2),
                              borderRadius: BorderRadius.circular(50),
                              image: DecorationImage(
                                image: AssetImage("assets/img/profile.png"),
                              ),
                            ),
                            height: 100,
                            width: 100,
                          ),
                        ),
                        Positioned(
                          right: 5,
                          top: 5,
                          child: WidSplash(
                            padding: EdgeInsets.all(5),
                            radius: BorderRadius.circular(50),
                            onTap: () {
                              Navigator.pop(context);
                            },
                            child: Icon(Ic.close(), color: Colors.black38),
                          ),
                        )
                      ],
                    ),
                    text(name, bold: true),
                    text(email),
                    Container(
                      margin: EdgeInsets.only(top: 15),
                      // padding: EdgeInsets.all(15),
                      decoration: BoxDecoration(
                          border:
                              Border(top: BorderSide(color: Colors.black12))),
                      child: Column(children: listUserInfo()),
                    ),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.only(
                          left: 15, right: 15, top: 5, bottom: 5),
                      decoration: BoxDecoration(
                          // border: Border(top: BorderSide(color: Colors.black12)),
                          color: TColor.azure()),
                      child: text(Dt.dateTime(format: 'd M y'),
                          color: Colors.white, align: TextAlign.right),
                    )
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
