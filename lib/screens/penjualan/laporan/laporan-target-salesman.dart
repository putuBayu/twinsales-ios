import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sales/services/api/api.dart';
import 'package:sales/services/v2/helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:month_picker_dialog/month_picker_dialog.dart';

class LaporanTargetSalesman extends StatefulWidget {
  final ctx;
  LaporanTargetSalesman(this.ctx);

  @override
  _LaporanTargetSalesmanState createState() => _LaporanTargetSalesmanState();
}

class _LaporanTargetSalesmanState extends State<LaporanTargetSalesman> {
  bool loaded = true, isSales = false, expandFooter = false;
  List dataTarget = [];
  String month = '', tanggal = '';
  int tTgt = 0, tJual = 0, tRtr = 0, tNet = 0;
  double avgAch = 0.0, tAch = 0.0;

  var labelsAdmmin = [
    'Total Target',
    'Total Penjualan',
    'Total Retur',
    'Total Net',
    'Total Achievement'
  ];

  getDataTarget() async {
    var prefs = await SharedPreferences.getInstance(),
        roles = prefs.getString('roles');

    setState(() {
      loaded = false;
      month = dateConvert(date: DateTime.now(), dateFormat: 'MMMM');
    });

    var user = decode(prefs.getString('user')), id = user['id'], url;

    if (roles != null) {
      isSales = decode(roles).indexOf('salesman') > -1 ||
          decode(roles).indexOf('salesman canvass') > -1;
    }

    url = 'target_salesman/get/report?tanggal=' + tanggal;

    Request.get(url, debug: true, then: (status, body) {
      var data = decode(body);

      setState(() {
        loaded = true;
        dataTarget = data;
      });

      for (var i = 0; i < data.length; i++) {
        var d = data[i];

        setState(() {
          tTgt += d['target'];
          tJual += d['penjualan'];
          tRtr += d['retur'];
          tNet += d['net'];
          tAch += d['ach'];
          // totalQty += d['total_qty'];
          // totalPcs += d['total_pcs'];
          // totalEc += d['ec'];
          // totalVal += d['value'];
          // totalQo += d['total_qty_order'];
          // totalPo += d['total_pcs_order'];
          // totalVo += d['value_order'];
        });
      }

      if (tAch > 0) {
        setState(() {
          avgAch = (tAch / data.length);
        });
      }
    }, error: (err) {
      onError(context, response: err, popup: true);
    });
  }

  Future<Null> _onRefresh() async {
    getDataTarget();
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getDataTarget();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TColor.silver(),
      appBar: Wh.appBar(context, title: 'Laporan Target Salesman',
          // leading: IconButton( onPressed: (){ Navigator.of(context).pop(); }, icon: Icon(Icons.arrow_back), color: Colors.black54),
          actions: [
            IconButton(
              icon: Icon(Ic.calendar(),
                  size: 20, color: !loaded ? Colors.black38 : Colors.black54),
              onPressed: !loaded
                  ? null
                  : () {
                      // showMonthPicker(
                      //   context: context,
                      //   firstDate: DateTime(DateTime.now().year - 5, 5),
                      //   lastDate: DateTime(DateTime.now().year + 5, 9),
                      //   initialDate: tanggal == '' ? DateTime.now() : DateTime.parse(tanggal),
                      //   // locale: Locale("id"),
                      // ).then((date) {
                      //   if (date != null) {
                      //     setState(() {
                      //       tanggal = dateConvert(date: date, dateFormat: 'yyyy-MM-dd').toString();
                      //       month = dateConvert(date: date, dateFormat: 'MMMM').toString();
                      //     });
                      //     getDataTarget();
                      //   }
                      // });
                    },
            )
          ]),
      body: !loaded
          ? ListSkeleton(
              length: 10,
            )
          : dataTarget == null || dataTarget.length == 0
              ? Wh.noData(
                  message:
                      'Tidak ada data\nTap icon kalender pojok kanan atas untuk pencarian')
              : RefreshIndicator(
                  onRefresh: _onRefresh,
                  child: PreventScrollGlow(
                    child: Stack(
                      children: [
                        Container(
                          padding: EdgeInsets.only(bottom: !isSales ? 80 : 0),
                          child: Column(
                            children: [
                              Container(
                                padding: EdgeInsets.all(15),
                                child: text('HASIL PENCARIAN BULAN ' +
                                    month.toUpperCase()),
                                decoration: BoxDecoration(
                                  color: TColor.silver(),
                                  boxShadow: [
                                    BoxShadow(
                                        color: TColor.silver(o: .8),
                                        spreadRadius: 125,
                                        blurRadius: 7,
                                        offset: Offset(0.0, 0.75)),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: ListView.builder(
                                  padding: EdgeInsets.only(
                                      bottom: 15, left: 15, right: 15),
                                  shrinkWrap: true,
                                  itemCount: dataTarget.length,
                                  itemBuilder: (context, i) {
                                    var data = dataTarget[i],
                                        tgt = data['target'] == null
                                            ? 0
                                            : data['target'],
                                        jual = data['penjualan'] == null
                                            ? 0
                                            : data['penjualan'],
                                        rtr = data['retur'] == null
                                            ? 0
                                            : data['retur'],
                                        net = data['net'] == null
                                            ? 0
                                            : data['net'],
                                        ach = data['ach'] == null
                                            ? 0
                                            : data['ach'];

                                    var labels = [
                                      '[' + data['nama_tim'] + '] ',
                                      'Target ',
                                      'Penjualan ',
                                      'Retur ',
                                      'Net ',
                                      'Achievement '
                                    ];

                                    return Container(
                                      padding: EdgeInsets.all(15),
                                      margin: EdgeInsets.only(bottom: 10),
                                      decoration: BoxDecoration(
                                          border:
                                              Border.all(color: Colors.black12),
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(3)),
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: List.generate(labels.length,
                                              (int i) {
                                            // var labels = ['['+data['tim']+'] ', 'Jumlah Invoice','EC','Sku','Total Pesanan','Total Disetujui','Jumlah Cash','Jumlah Credit','Pelunasan Tunai','Pelunasan Bg','Pelunasan Transfer','Pelunasan Retur','Pelunasan Lainnya'],
                                            var values = [
                                              data['nama_salesman'],
                                              'Rp ' + ribuan(tgt),
                                              'Rp ' + ribuan(jual),
                                              'Rp ' + ribuan(rtr),
                                              'Rp ' + ribuan(net),
                                              ach.toString() + '%'
                                            ];

                                            return Container(
                                              padding: EdgeInsets.only(
                                                  top: 5, bottom: 5),
                                              decoration: BoxDecoration(
                                                  border: Border(
                                                      bottom: BorderSide(
                                                          color: i ==
                                                                  labels.length -
                                                                      1
                                                              ? Colors
                                                                  .transparent
                                                              : Colors
                                                                  .black12))),
                                              child: Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisAlignment: i == 0
                                                    ? MainAxisAlignment.start
                                                    : MainAxisAlignment.start,
                                                children: <Widget>[
                                                  i == 0
                                                      ? text(labels[i],
                                                          bold: true)
                                                      : Expanded(
                                                          child:
                                                              text(labels[i])),
                                                  i == 0
                                                      ? Expanded(
                                                          child: text(values[i],
                                                              bold: true))
                                                      : text(values[i]),
                                                ],
                                              ),
                                            );
                                          })),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        isSales
                            ? SizedBox.shrink()
                            : Positioned(
                                bottom: 0,
                                child: Stack(children: [
                                  AnimatedContainer(
                                      duration: Duration(milliseconds: 300),
                                      margin: EdgeInsets.only(top: 15),
                                      width: Mquery.width(context),
                                      height: expandFooter ? 380 : 100,
                                      padding: EdgeInsets.only(
                                          left: 15,
                                          right: 15,
                                          top: 10,
                                          bottom: 10),
                                      decoration: BoxDecoration(
                                          // border: Border.all(color: Colors.black12),
                                          borderRadius: BorderRadius.only(
                                              topLeft: Radius.circular(5),
                                              topRight: Radius.circular(5)),
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Color.fromRGBO(0, 0, 0, .3),
                                              blurRadius:
                                                  20.0, // has the effect of softening the shadow
                                              spreadRadius:
                                                  5.0, // has the effect of extending the shadow
                                              offset: Offset(2.0, 2.0),
                                            )
                                          ],
                                          // border: Border(top: BorderSide(color: Colors.black12)),
                                          image: DecorationImage(
                                              image: AssetImage(
                                                  'assets/img/line-card.png'),
                                              fit: BoxFit.fill,
                                              colorFilter: ColorFilter
                                                  .linearToSrgbGamma())),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(15),
                                            topRight: Radius.circular(15)),
                                        child: SingleChildScrollView(
                                          // physics: NeverScrollableScrollPhysics(),
                                          child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: List.generate(
                                                  labelsAdmmin.length, (int i) {
                                                var values = [
                                                  'Rp ' + ribuan(tTgt),
                                                  'Rp ' + ribuan(tJual),
                                                  'Rp ' + ribuan(tRtr),
                                                  'Rp ' + ribuan(tNet),
                                                  avgAch.toStringAsFixed(2) +
                                                      '%'
                                                ];

                                                return Container(
                                                  padding: EdgeInsets.only(
                                                      top: 5, bottom: 5),
                                                  decoration: BoxDecoration(
                                                      border: Border(
                                                          bottom: BorderSide(
                                                              color: Colors
                                                                  .green[50]))),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: <Widget>[
                                                      text(labelsAdmmin[i]),
                                                      text(values[i]),
                                                    ],
                                                  ),
                                                );
                                              })

                                              // <Widget>[
                                              //   Row(
                                              //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              //     children: <Widget>[
                                              //       text('Total Ec : '),
                                              //       text(ribuan(totalEc.toString())),
                                              //     ],
                                              //   ),

                                              //   Row(
                                              //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              //     children: <Widget>[
                                              //       text('Total Pesanan : '),
                                              //       text(ribuan(totalQo.toString())+'/'+ribuan(totalPo.toString())+ ' (Rp '+ribuan(totalVo.toString())+')'),
                                              //     ],
                                              //   ),

                                              //   Row(
                                              //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              //     children: <Widget>[
                                              //       text('Total Terkirim : '),
                                              //       text(ribuan(totalQty.toString())+'/'+ribuan(totalPcs.toString())+' (Rp '+ribuan(totalVal.toString())+')'),
                                              //     ],
                                              //   ),
                                              // ],
                                              ),
                                        ),
                                      )),
                                  Positioned(
                                    left: Mquery.width(context) / 2 - 22,
                                    top: 0,
                                    child: WidSplash(
                                      onTap: () {
                                        setState(
                                            () => expandFooter = !expandFooter);
                                      },
                                      color: Colors.white,
                                      padding: EdgeInsets.all(9),
                                      radius: BorderRadius.circular(50),
                                      child: Icon(
                                          expandFooter
                                              ? Ic.chevron()
                                              : Ic.chevronUp(),
                                          size: 20),
                                    ),
                                  )
                                ])),
                      ],
                    ),
                  ),
                ),
    );
  }
}
