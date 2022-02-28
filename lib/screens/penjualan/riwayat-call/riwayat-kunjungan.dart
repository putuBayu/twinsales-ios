import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sales/screens/penjualan/kunjungan/riwayat-kunjungan-hari-ini.dart';
import 'package:sales/services/api/api.dart';
import 'package:sales/services/v2/helper.dart';

class RiwayatKunjungan extends StatefulWidget {
  final ctx;
  RiwayatKunjungan({this.ctx});

  @override
  _RiwayatKunjunganState createState() => _RiwayatKunjunganState();
}

class _RiwayatKunjunganState extends State<RiwayatKunjungan> {

  bool loading = false, isLoadMore = false, isMaxScroll = false;
  int page = 0, perPage = 10, totalRow = 0;
  List listTanggal = [], dataFiltered = [];
  String tanggal = '';
  DateTime date = DateTime.now();
  ScrollController scroll;

  getRiwayatCall() async {
    page = 1;
    setState(() { loading = true; });

    Request.get('kunjungan_sales/get/riwayat_kunjungan?tanggal=' + tanggal + '&per_page=' + perPage.toString() + '&page=' + page.toString(), then: (status, body){
      if(mounted){
        setState(() {
          totalRow = decode(body)['meta']['total'];
        });

        Map res = decode(body);
        loading = false;

        setState(() {
          listTanggal = res['data'];
          dataFiltered = res['data'];
        });

        return res['data'];
      }
    }, error: (err){
      setState(() { loading = false; });
      onError(context, response: err);
    });
  }

  Future loadMore() async {
    setState(() {
      isLoadMore = true;
      page = page + 1;
    });

    Request.get('kunjungan_sales/get/riwayat_kunjungan?tanggal=' + tanggal + '&per_page=' + perPage.toString() + '&page=' + page.toString(), then: (status, data) {
      for (var item in decode(data)) {
        listTanggal.add(item);
      }

      setState(() {
        isLoadMore = false;
      });

      Timer(Duration(milliseconds: 200), () {
        scroll.animateTo(
          scroll.position.maxScrollExtent - 50,
          curve: Curves.easeOut,
          duration: const Duration(milliseconds: 300),
        );
      });
    }, error: (err) {
      onError(context, response: err, popup: true);
    });
  }

  Future<Null> _onRefresh() async {
    setState(() {
      tanggal = '';
    });
    getRiwayatCall();
  }

  @override
  void initState() {
    super.initState();
    getRiwayatCall();

    // watch scroll position
    scroll = ScrollController()
      ..addListener(() {
        double maxScroll = scroll.position.maxScrollExtent,
            currentScroll = scroll.position.pixels,
            delta = 50.0;

        setState(() {
          isMaxScroll = maxScroll - currentScroll <= delta ? true : false;
        });
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TColor.silver(),
      appBar: Wh.appBar(context, title: 'Riwayat Kunjungan', actions: [
        IconButton(
          icon: Icon(Ic.calendar(), color: loading ? Colors.black38 : Colors.black54, size: 20),
          onPressed: loading ? null : (){
            Wh.datePicker(context, init: date, max: Dt.dateTime(format: 'now+')).then((res){
              if(res != null){
                tanggal = res;
                date = DateTime.parse(res);
                getRiwayatCall();
              }
            });
          },
        )
      ]),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _onRefresh,
            child: loading ? ListSkeleton(length: 10) : new Container(
              color: Colors.white,
              child: dataFiltered.length == 0 ? Wh.noData(
                  message: 'Tidak ada riwayat call\nTap gambar untuk memuat ulang.',
                  onTap: () {
                    _onRefresh();
                  }
              ) : ListView.builder(
                controller: scroll,
                itemCount: dataFiltered.length,
                itemBuilder: (context, i) {
                  var data = dataFiltered[i];
                  return WidSplash(
                    color: i % 2 == 0 ? TColor.silver() : Colors.white,
                    onTap: () {
                      modal(widget.ctx, child: KunjunganHariIni(widget.ctx, initData: data,));
                    },
                    child: Container(
                      child: Column(
                        children: <Widget>[
                          Container(
                            padding: EdgeInsets.all(15),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: <Widget>[
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      text(data['tanggal_format'], bold: true),
                                      text(data['jumlah_kunjungan'].toString() + ' KUNJUNGAN'),
                                    ],
                                  ),
                                  Icon(
                                      Ic.chevright(),
                                      color: Colors.black26,
                                      size: 20)
                                ],
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          )
        ],
      ),
    );
  }
}
