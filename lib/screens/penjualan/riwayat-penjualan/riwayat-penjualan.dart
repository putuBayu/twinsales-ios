import 'package:flutter/material.dart';
import 'package:sales/services/api/api.dart';
import 'package:sales/services/v2/helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

import 'daftar-penjualan.dart';

class RiwayatPenjualan extends StatefulWidget {
  final ctx;
  RiwayatPenjualan(this.ctx);

  _RiwayatPenjualanState createState() => _RiwayatPenjualanState();
}

class _RiwayatPenjualanState extends State<RiwayatPenjualan> {
  SharedPreferences sharedPreferences;
  DateTime selectedDate = DateTime.now();

  var isSearch = false, isKeyboardSearch = false, loading = true;
  var listTanggal = [],
      dataFiltered = [],
      dateVal,
      isLoadMore = false,
      isMaxScroll = false,
      page = 1,
      perPage = 12,
      totalRow = 0;

  ScrollController scroll;

  getRiwayatPenjualan({refill: false}) async {
    setState(() {
      loading = true;
    });
    page = 1;

    Future getData({then}) async {
      Request.get('penjualan/list/tanggal?per_page=' + perPage.toString() + '&page=' + page.toString(), then: (status, data) {
        then(decode(data));
      }, error: (err) {
        onError(context, response: err, popup: true);
      });
    }

    getData(then: (res) {
      if (res != null) {
        setPrefs('riwayat', res, enc: true);

        setState(() {
          listTanggal = res;
          dataFiltered = res;
          loading = false;
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    getRiwayatPenjualan();

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

  void _setDate(date) {
    setState(() {
      isSearch = true;
      dateVal = date;
      dataFiltered =
          listTanggal.where((item) => item['tanggal'].contains(date)).toList();
    });
  }

  Future loadMore() async {
    setState(() {
      isLoadMore = true;
      page = page + 1;
    });

    Request.get(
        'penjualan/list/tanggal?per_page=' +
            perPage.toString() +
            '&page=' +
            page.toString(), then: (status, data) {
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
    getRiwayatPenjualan(refill: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: Wh.appBar(context,
            title: isSearch ? dateFormat(dateVal) : !isKeyboardSearch
                ? 'Riwayat Penjualan' : Fc.search(
                hint: 'Cari riwayat penjualan',
                enabled: listTanggal.length != 0,
                autofocus: true,
                action: TextInputAction.go,
                change: (String s) {
                  var k = s.toLowerCase();
                  setState(() {
                    dataFiltered = listTanggal
                        .where((item) => item['tanggal'].contains(k))
                        .toList()
                        .toList();
                  });
//          if(s.isNotEmpty){
//            modal(widget.ctx, child: DaftarPenjualan(widget.ctx, '', '', keyword: s));
//          }
                }
            ),
            actions: [
              IconButton(
                icon: Icon(
                    isKeyboardSearch || isSearch ? Ic.close() : Ic.search(),
                    color: loading ? Colors.black38 : Colors.black54,
                    size: 20),
                onPressed: loading ? null : () {
                  setState(() {
                    isKeyboardSearch =
                    isSearch ? false : !isKeyboardSearch;
                    isSearch = false;
                    dataFiltered = listTanggal;
                  });
                },
              ),
              IconButton(
                icon: Icon(
                  Ic.calendar(),
                  color: loading ? Colors.black38 : Colors.black54,
                  size: 20,
                ),
                onPressed: loading ? null : () {
                  Wh.datePicker(context, init: selectedDate, max: Dt.dateTime(format: 'now+')).then((res) {
                    if (res != null) setState(() => _setDate(res));
                    selectedDate = DateTime.parse(res);
                  });
                },
              ),
            ]
        ),
        body: Stack(
            children: <Widget>[
              new RefreshIndicator(
                onRefresh: _onRefresh,
                child: loading ? ListSkeleton(length: 10) : new Container(
                  color: Colors.white,
                  child: dataFiltered.length == 0 ? Wh.noData(
                      message: 'Tidak ada riwayat penjualan\nTap gambar untuk memuat ulang.',
                      onTap: () {
                        _onRefresh();
                      }
                  ) : new ListView.builder(
                    controller: scroll,
                    itemCount: dataFiltered.length,
                    itemBuilder: (context, i) {
                      var data = dataFiltered[i];
                      return WidSplash(
                        color: i % 2 == 0 ? TColor.silver() : Colors.white,
                        onTap: () {
                          modal(widget.ctx, child: DaftarPenjualan(widget.ctx, data['tanggal'], data['count'].toString()));
                        },
                        child: new Container(
                          child: new Column(
                            children: <Widget>[
                              new Container(
                                padding: EdgeInsets.all(15),
                                child: new Align(
                                  alignment: Alignment.centerLeft,
                                  child: new Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: <Widget>[
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: <Widget>[
                                          text(dateFormat(data['tanggal']), bold: true),
                                          text(data['count'].toString() + ' PENJUALAN'),
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
              ),
              PaginateControl(
                isMaxScroll: isMaxScroll,
                isLoad: isLoadMore,
                totalRow: totalRow,
                totalData: listTanggal.length,
                onTap: loadMore,
              )
            ]
        )
    );
  }
}
