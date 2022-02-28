import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sales/services/api/api.dart';
import 'package:sales/services/v2/helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LaporanAktual extends StatefulWidget {
  final ctx;
  LaporanAktual({this.ctx});

  @override
  _LaporanAktualState createState() => _LaporanAktualState();
}

class _LaporanAktualState extends State<LaporanAktual> {

  var loading = false, laporan = [], startDate = Dt.ymd, endDate = Dt.ymd, isSales = false;
  
  getData({refill: false}) async{
    var prefs = await SharedPreferences.getInstance(), roles = prefs.getString('roles');
    var user = decode(prefs.getString('user')), id = user['id'], url;

    setState(() {
      loading = true;
    });

    if(roles != null){
      isSales = decode(roles).indexOf('salesman') > -1 || decode(roles).indexOf('salesman canvass') > -1;
    }

    if(isSales){
      url = 'report/laporan_actual?id_salesman='+id.toString()+'&start_date='+startDate+'&end_date='+endDate;
    }else{
      url = 'report/laporan_actual?id_salesman=all&start_date='+startDate+'&end_date='+endDate;
    }

    if(refill){
      Request.get(url, then: (status, body){
        laporan = decode(body);
        setState(() => loading = false );
        setPrefs('lap-aktual', decode(body), enc: true);
      }, error: (err){
        setState(() => loading = false );
        onError(context, response: err, popup: true);
      });
    }else{
      getPrefs('lap-aktual', dec: true).then((res){
        setState(() {
          laporan = res[1];
          loading = true;
        });
      });
    }
  }

  @override
  void initState() {
    super.initState(); getData(refill: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Wh.appBar(context, title: 'Laporan Aktual', actions: [
        IconButton(
          icon: Icon(Ic.calendar(), size: 20),
          onPressed: (){
            Wh.datePicker(context, init: DateTime.parse(startDate == null ? Dt.ymd : startDate), max: Dt.dateTime(format: 'now+')).then((res){
              if(res != null){
                startDate = endDate = res;
                getData(refill: true);
              }
            });

          },
        )
      ]),

      body: loading ? ListSkeleton(length: 10) : laporan == null || laporan.length == 0 ? Wh.noData(message: 'Tap icon kalender pojok kanan atas untuk pencarian') :
      
      RefreshIndicator(
        onRefresh: () async {
          getData(refill: true);
        },
        child: Container(
          width: Mquery.width(context),
          height: Mquery.height(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                margin: EdgeInsets.only(bottom: 15, left: 20, right: 20),
                child: text('Klik tombol dibawah untuk download laporan tanggal ' + startDate.toString(), align: TextAlign.center, color: TColor.gray()),
              ),
              WidSplash(
                onTap: (){
                  goto('https://kpm-api.kembarputra.com/excel/laporan_actual' + startDate + '.xlsx');
                },
                color: TColor.azure(),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: text('Download Laporan', color: Colors.white),
              ),
            ],
          ),
        )
    // ListView.builder(
    //       padding: EdgeInsets.all(15),
    //       itemCount: laporan.length,
    //       itemBuilder: (BuildContext context, i){

            // if(i == 0){
            //   return Container(
            //     padding: EdgeInsets.only(bottom: 10),
            //     child: text('HASIL PENCARIAN '+dateFormat(startDate), align: TextAlign.center)
            //   );
            //
            // }else{
            //   var data = laporan[i - 1];
            //   var labels = [
            //         '['+data['tim']+'] ' + data['nama_salesman'],
            //         'Jumlah Invoice',
            //         'EC','Sku','Total Pesanan','Total Disetujui',
            //         'Jumlah Cash','Jumlah Credit','Total Ppn','Diskon'
            //       ],
            //
            //       values = [
            //         '',
            //         data['count_inv'],
            //         data['ec'],
            //         data['sku'],
            //         ribuan(data['total_qty_order'])+'/'+ribuan(data['total_pcs_order'])+' (Rp '+ribuan(data['value_order'])+')',
            //         ribuan(data['total_qty'])+'/'+ribuan(data['total_pcs'])+' (Rp '+ribuan(data['value'])+')',
            //         'Rp '+ribuan(data['value_cash']),
            //         'Rp '+ribuan(data['value_credit']),
            //         'Rp '+ribuan(data['total_ppn']),
            //         'Rp '+ribuan(data['total_discount'])
            //       ];
            //
            //   return Container(
            //     padding: EdgeInsets.all(15),
            //     margin: EdgeInsets.only(bottom: 15),
            //     decoration: BoxDecoration(
            //       color: Colors.white,
            //       border: Border.all(color: Colors.black12),
            //       borderRadius: BorderRadius.circular(4)
            //     ),
            //     child: Column(
            //       children: List.generate(labels.length, (int l){
            //         return Container(
            //           padding: EdgeInsets.only(top: 5, bottom: 5),
            //           decoration: BoxDecoration(
            //             border: Border(
            //               bottom: BorderSide(color: l == labels.length - 1 ? Colors.transparent : Colors.black12)
            //             )
            //           ),
            //           child: Row(
            //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //             children: <Widget>[
            //               text(labels[l].toString(), bold: l == 0 ? true : false),
            //               text(values[l].toString())
            //             ],
            //           )
            //         );
            //       })
            //     ),
            //   );
          // }
        // })
      )
    );
  }
}