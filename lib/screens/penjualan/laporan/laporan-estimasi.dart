import 'package:flutter/material.dart';
import 'package:sales/services/api/api.dart';
import 'package:sales/services/v2/helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LaporanEstimasi extends StatefulWidget {
  @override
  _LaporanEstimasiState createState() => _LaporanEstimasiState();
}

class _LaporanEstimasiState extends State<LaporanEstimasi> {

  bool loaded = true, isSales = false, expandFooter = false;
  String startDate = Dt.ymd, endDate = Dt.ymd;
  List dataEstimasi = [];
  int totalQty = 0, totalPcs = 0, totalEc = 0, totalVal = 0, totalQo = 0,
      totalPo = 0, totalVo = 0, tEc = 0, tSku = 0, tQo = 0, tPo = 0, tQty = 0,
      tPcs = 0, tVo = 0, tV = 0, tJin = 0, tCsh = 0, tCrd = 0, tPpn = 0, tDisc = 0,
      tTgt = 0, tAch = 0, avgAch = 0;

  var labelsAdmmin = [
    'Total Jumlah Invoice',
    'Total Ec',
    'Total Sku',
    'Total Pesanan',
    'Total Diskon',
    'Total PPN',
    'Total Disetujui',
    'Total Jumlah Cash',
    'Total Jumlah Credit',
    'Total Target',
    'Total Achievement'
  ];

  getDataEstimasi()async{
    var prefs = await SharedPreferences.getInstance(),
        roles = prefs.getString('roles');

    setState(() {
      loaded = false;
    });

    var user = decode(prefs.getString('user')),
        id = user['id'],
        url;

    if(roles != null){
      isSales = decode(roles).indexOf('salesman') > -1 || decode(roles).indexOf('salesman canvass') > -1;
    }

    if(isSales){
      url = 'report/laporan_penjualan?id_salesman='+id.toString()+'&date='+startDate+'&tipe=estimasi';
    }else{
      url = 'report/laporan_penjualan?id_salesman=all&date='+startDate + '&tipe=estimasi';
    }

    Request.get(url, then: (status, body){
      var data = decode(body);

      setState(() {
        loaded = true;
        dataEstimasi = data;
      });

      for (var i = 0; i < data.length; i++) {
        var d = data[i];

        tEc += d['ec'];
        tSku += d['sku'].round();
        tQo += d['total_qty_order'];
        tPo += d['total_pcs_order'];
        tQty += d['total_qty'];
        tPcs += d['total_pcs'];
        tVo += d['value_order'];
        tV += d['value'];
        tPpn += d['total_ppn'];
        tDisc += d['total_discount'];

        // tTni += d['penagihan_tunai'];
        // tBg += d['penagihan_bg'];
        // tTrf += d['penagihan_transfer'];
        // tRtr += d['penagihan_retur'];
        // tLn += d['penagihan_lainnya'];

        tJin += d['count_inv'];
        tCsh += d['value_cash'];
        tCrd += d['value_credit'];

        tTgt += d['target'];
        tAch += d['ach'];

        setState(() {
          totalQty += d['total_qty'];
          totalPcs += d['total_pcs'];
          totalEc += d['ec'];
          totalVal += d['value'];
          totalQo += d['total_qty_order'];
          totalPo += d['total_pcs_order'];
          totalVo += d['value_order'];
        });
      }

      if(tAch > 0){
        setState(() {
          avgAch = (tAch/data.length).round();
        });
      }
    }, error: (err){
      onError(context, response: err, popup: true);
    });
  }

  Future<Null> _onRefresh()async{
    getDataEstimasi();
  }

  @override
  void initState() {
    super.initState();
    getDataEstimasi();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TColor.silver(),
      appBar: Wh.appBar(context, title: 'Laporan Estimasi Penjualan',
          // leading: IconButton( onPressed: (){ Navigator.of(context).pop(); }, icon: Icon(Icons.arrow_back), color: Colors.black54),
        actions: [
          IconButton(
            icon: Icon(Ic.calendar(), size: 20, color: !loaded ? Colors.black38 : Colors.black54),
            onPressed: !loaded ? null : (){
              Wh.datePicker(context, init: DateTime.parse(startDate == null ? Dt.ymd : startDate), max: Dt.dateTime(format: 'now+')).then((res){
                if(res != null){
                  startDate = endDate = res;
                  getDataEstimasi();
                }
              });
            },
          )
        ]
      ),
      body: !loaded ? ListSkeleton(length: 10,)
          : dataEstimasi == null || dataEstimasi.length == 0
          ? Wh.noData(message: 'Tap icon kalender pojok kanan atas untuk pencarian')
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
                          child: text('HASIL PENCARIAN '+dateFormat(startDate)),
                          decoration: BoxDecoration(
                            color: TColor.silver(),
                            boxShadow: [
                              BoxShadow(
                                color: TColor.silver(o: .8),
                                spreadRadius: 125,
                                blurRadius: 7,
                                offset: Offset(0.0, 0.75)
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            padding: EdgeInsets.only(bottom: 15, left: 15, right: 15),
                            shrinkWrap: true,
                            itemCount: dataEstimasi.length,
                            itemBuilder: (context, i){

                              var data = dataEstimasi[i],
                                  ec = data['ec'] == null ? 0 : data['ec'],
                                  sku = data['sku'] == null ? 0 : data['sku'].toString().length > 4 ? data['sku'].toString().substring(0,4) : data['sku'],
                                  qty = data['total_qty'] == null ? 0 : ribuan(data['total_qty'].toString()),
                                  pcs = data['total_pcs'] == null ? 0 : ribuan(data['total_pcs'].toString()),
                                  tv = data['value'] == null ? 0 : 'Rp '+ribuan(data['value'].toString()),
                                  tqo = data['total_qty_order'] == null ? 0 : ribuan(data['total_qty_order'].toString()),
                                  tpo = data['total_pcs_order'] == null ? 0 : ribuan(data['total_pcs_order'].toString()),
                                  vo = data['value_order'] == null ? 0 : ribuan(data['value_order'].toString()),
                                  ach = data['ach'] == null ? 0 : data['ach'].toString();

                              var labels = [
                                '['+data['tim']+'] ',
                                'Jumlah Invoice',
                                'EC',
                                'Sku',
                                'Total Pesanan',
                                'Total Diskon',
                                'Total PPN',
                                'Total Disetujui',
                                'Jumlah Cash',
                                'Jumlah Credit',
                                'Target',
                                'Achievement'
                              ];

                              return Container(
                                padding: EdgeInsets.all(15),
                                margin: EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.black12),
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(3)
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: List.generate(labels.length, (int i){
                                    // var labels = ['['+data['tim']+'] ', 'Jumlah Invoice','EC','Sku','Total Pesanan','Total Disetujui','Jumlah Cash','Jumlah Credit','Pelunasan Tunai','Pelunasan Bg','Pelunasan Transfer','Pelunasan Retur','Pelunasan Lainnya'],
                                    var values = [
                                          data['nama_salesman'],
                                          data['count_inv'],
                                          ec.toString(),
                                          sku.toString(),
                                          tqo+'/'+tpo+' (Rp '+vo+')',
                                          'Rp '+ribuan(data['total_discount']),
                                          'Rp '+ribuan(data['total_ppn']),
                                          qty+'/'+pcs+' ('+tv.toString()+')',
                                          'Rp '+ribuan(data['value_cash']),
                                          'Rp '+ribuan(data['value_credit']),
                                          'Rp '+ribuan(data['target']),
                                          ach.toString()+'%'
                                        ];

                                    return Container(
                                      padding: EdgeInsets.only(top: 5, bottom: 5),
                                      decoration: BoxDecoration(
                                        border: Border(bottom: BorderSide(color: i == labels.length-1 ? Colors.transparent : Colors.black12))
                                      ),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: i == 0 ? MainAxisAlignment.start : MainAxisAlignment.start,
                                        children: <Widget>[
                                          i == 0 ? text(labels[i], bold: true) : Expanded(
                                              child: text(labels[i])
                                          ),
                                          i == 0 ? Expanded(child:
                                          text(values[i], bold: true)
                                          ) : text(values[i]),
                                        ],
                                      ),
                                    );
                                  })
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  isSales ? SizedBox.shrink() : Positioned(
                    bottom: 0,
                    child: Stack(
                      children: [
                        AnimatedContainer(
                          duration: Duration(milliseconds: 300),
                          margin: EdgeInsets.only(top: 15),
                          width: Mquery.width(context), height: expandFooter ? 380 : 100,
                          padding: EdgeInsets.only(left: 15, right: 15, top: 10, bottom: 10),
                          decoration: BoxDecoration(
                            // border: Border.all(color: Colors.black12),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(5),
                              topRight: Radius.circular(5)
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Color.fromRGBO(0, 0, 0, .3),
                                blurRadius: 20.0, // has the effect of softening the shadow
                                spreadRadius: 5.0, // has the effect of extending the shadow
                                offset: Offset( 2.0, 2.0 ),
                              )
                            ],
                            // border: Border(top: BorderSide(color: Colors.black12)),
                            image: DecorationImage(
                              image: AssetImage('assets/img/line-card.png'),
                              fit: BoxFit.fill,
                              colorFilter: ColorFilter.linearToSrgbGamma()
                            )
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(15),
                              topRight: Radius.circular(15)
                            ),
                            child: SingleChildScrollView(
                              // physics: NeverScrollableScrollPhysics(),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: List.generate(labelsAdmmin.length, (int i){
                                  var values = [
                                    tJin,
                                    tEc,
                                    tSku,
                                    tQo.toString()+'/'+tPo.toString()+' (Rp '+ribuan(tVo)+')',
                                    'Rp '+ribuan(tDisc),
                                    'Rp '+ribuan(tPpn),
                                    tQty.toString()+'/'+tPcs.toString()+' (Rp '+ribuan(tV)+')',
                                    'Rp '+ribuan(tCsh),
                                    'Rp '+ribuan(tCrd),
                                    'Rp '+ribuan(tTgt),
                                    avgAch.toString() + '%'
                                    // 'Rp '+ribuan(tTni),
                                    // 'Rp '+ribuan(tBg),
                                    // 'Rp '+ribuan(tTrf),
                                    // 'Rp '+ribuan(tRtr),
                                    // 'Rp '+ribuan(tLn)
                                  ];

                                  return Container(
                                    padding: EdgeInsets.only(top: 5, bottom: 5),
                                    decoration: BoxDecoration(
                                      border: Border(bottom: BorderSide(color: Colors.green[50]))
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                          )
                        ),

                        Positioned(
                          left: Mquery.width(context) / 2 - 22, top: 0,
                          child: WidSplash(
                            onTap: (){ setState(() => expandFooter = !expandFooter ); },
                            color: Colors.white, padding: EdgeInsets.all(9),
                            radius: BorderRadius.circular(50),
                            child: Icon(expandFooter ? Ic.chevron() : Ic.chevronUp(), size: 20),
                          ),
                        )
                      ]
                    )
                  ),
                ],
              ),
            ),
      ),
    );
  }
}
