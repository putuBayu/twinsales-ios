import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sales/screens/penjualan/penjualan/detail-penjualan-hari-ini.dart';
import 'package:sales/services/api/api.dart';
import 'package:sales/services/v2/helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RiwayatPenjualanAdmin extends StatefulWidget {
  RiwayatPenjualanAdmin({this.ctx, this.paddingTop}); final ctx, paddingTop;

  @override
  _RiwayatPenjualanAdminState createState() => _RiwayatPenjualanAdminState();
}

class _RiwayatPenjualanAdminState extends State<RiwayatPenjualanAdmin> {
  var keyword = TextEditingController();

  var dataPenjualan = [], loaded = true, date = Dt.ymd, idSales = 'all', 
      isLoadMore = false, isSearch = false, isMaxScroll = true, keywordSearch = false, page = 1, totalRow = 0, perPage = 15, namaSales = 'Semua Salesman';

  ScrollController scroll;
  DateTime selectedDate = DateTime.now();
  

  getDataPenjualan({data}) async {
    setState(() { loaded = false; page = 1; });
    var url = '';
    
    if(keyword.text == ''){
      url = 'penjualan?page='+page.toString()+'&per_page='+perPage.toString()+'&start_date='+date+'&end_date='+date+'&id_salesman='+idSales;
    }else{
      url = 'penjualan?page='+page.toString()+'&per_page='+perPage.toString()+'&id_salesman='+idSales+'&keyword='+keyword.text;
    }

    Request.get(url, then: (s, body){
      if(mounted){
        Map res = decode(body);
        totalRow = res['meta']['total'];

        setState(() {
          loaded = true;
          dataPenjualan = res['data'];
          isSearch = true;
        });
      }
    }, error: (err){
      setState(() { loaded = true; });
      onError(context, response: err, popup: true);
    });
  }

  Future<Null> _onRefresh() async {
    page = 1;
    getDataPenjualan();
  }

  loadMore() async {
    page += 1;

    _get(result) async {
      var url = '';
      
      if(keyword.text == ''){
        url = 'penjualan?page='+page.toString()+'&per_page='+perPage.toString()+'&start_date='+date+'&end_date='+date+'&id_salesman='+idSales;
      }else{
        url = 'penjualan?page='+page.toString()+'&per_page='+perPage.toString()+'&id_salesman='+idSales+'&keyword='+keyword.text;
      }

      Request.get(url,  then: (status, body){
        if(mounted){
          var res = decode(body);
          result(res['data']);
        }
      }, error: (err){
        setState(() { loaded = true; });
        onError(context, response: err, popup: true);
      });
    }

    checkConnection().then((con){
      setState(() {
        isLoadMore = true;
      });

      if(con){
        _get((res){
          for (var item in res) {
            setState(() {
              dataPenjualan.add(item);
              isLoadMore = false;
            });
          }

          Timer(Duration(milliseconds: 200), (){
            scroll.animateTo(
              scroll.position.maxScrollExtent,
              curve: Curves.easeOut,
              duration: const Duration(milliseconds: 300),
            );
          });
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();

    // watch scroll position
    scroll = ScrollController()..addListener(() {
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
      appBar: Wh.appBar(context, title: keywordSearch ? 
        Fc.search(hint: 'Ketik no. invoice, no. acc, nama toko', autofocus: true, controller: keyword, action: TextInputAction.go,
            change: (String s){
              getDataPenjualan();
        }) :
      
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            text('Riwayat Penjualan', size: 18),
            isSearch ? SlideUp(child: text(dataPenjualan.length.toString()+' / '+totalRow.toString()+' Penjualan', size: 13)) : SizedBox.shrink()
          ],
        ), actions: [

          IconButton(
            icon: Icon(keywordSearch ? Ic.close() : Ic.search(), size: 20, color: !loaded ? Colors.black38 : Colors.black54),
            onPressed: !loaded ? null : (){
              setState(() {
                keywordSearch = !keywordSearch;
                if(keywordSearch){
                  keyword.text = '';
                }
              });
            }
          ),

          keywordSearch ? SizedBox.shrink() :

          IconButton(
            icon: Icon(Ic.user(), size: 20, color: !loaded ? Colors.black38 : Colors.black54),
            onPressed: !loaded ? null : (){
              modal(widget.ctx, child: DaftarSalesman(), then: (res){
                if(res != null){
                  setState(() {
                    idSales = res['id'].toString();
                    namaSales = res['nama'];
                  });
                }
              });
            }
          ),

          keywordSearch ? SizedBox.shrink() :

          IconButton(
            icon: Icon(Ic.calendar(), size: 20, color: !loaded ? Colors.black38 : Colors.black54),
            onPressed: !loaded ? null : (){ 
              Wh.datePicker(context, init: DateTime.parse(date), max: Dt.dateTime(format: 'now+')).then((res){
                if(res != null) setState(() => date = res );
              });
            }
          ),
        ]
      ),

      body: Stack(
        children: <Widget>[ !loaded ? ListSkeleton(length: 10) :
      
          dataPenjualan == null || dataPenjualan.length == 0 ? Wh.noData(message: 'Tidak ada riwayat penjualan') :
          
          RefreshIndicator(
            onRefresh: _onRefresh,
            child: ListView.builder(
              controller: scroll,
              padding: EdgeInsets.only(bottom: 55),
              itemCount: dataPenjualan.length + 1,
              itemBuilder: (context, i){

                if(i == dataPenjualan.length){
                  return dataPenjualan.length >= totalRow ? SizedBox.shrink() : WidSplash(
                    padding: EdgeInsets.all(15),
                    onTap: isLoadMore ? null : (){ loadMore(); },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        isLoadMore ? Wh.spiner(size: 18) : Container(
                          margin: EdgeInsets.only(left: 10),
                          child: text('Muat Lainnya')
                          // WH.itext(icon: Icon(Icons.refresh, size: 20), child: 'Muat lainnnya'),
                        )
                      ],
                    ) 
                  );
                }else{
                  var data = dataPenjualan[i];
                  return Container(
                      decoration: BoxDecoration(
                    // border: Border(
                    //   bottom: BorderSide(color: Colors.black12)
                    // )
                      ),
                      child: Material(
                        color: i % 2 == 0 ? TColor.silver() : Colors.white,
                        child: InkWell(
                          onTap: (){
                            modal(widget.ctx, child: DetailPenjualanHariIni(dataPenjualan: data, readOnly: true));
                            },
                          child: Container(
                            child: Column(
                              children: <Widget>[
                                new Container(
                                    padding: EdgeInsets.all(15),
                                    child: new Align(
                                        alignment: Alignment.centerLeft,
                                        child: Column(
                                          // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          // crossAxisAlignment: CrossAxisAlignment.start,
                                          children: <Widget>[
                                            Row(
                                              // crossAxisAlignment: CrossAxisAlignment.start,
                                              children: <Widget>[
                                                Expanded(child: text(data['id'].toString(), bold: true)),
                                                Container(
                                                    decoration: BoxDecoration(
                                                      // color: Color.fromRGBO(26, 100, 156, 1),
                                                        color: Colors.blueGrey, borderRadius: BorderRadius.circular(3)
                                                    ),
                                                    padding: EdgeInsets.only(left: 5, right: 5),
                                                    // margin: EdgeInsets.only(right: 7),
                                                    child: data['salesman'][0]['kode_eksklusif'] == null
                                                        ? text(data['toko'][0]['nama_tim'], color: Colors.white)
                                                        : text(data['toko'][0]['nama_tim'] + ' - ' + data['salesman'][0]['kode_eksklusif'], color: Colors.white)
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 5,),
                                            Row(
                                              children: <Widget>[
                                                Expanded(
                                                    child: text(data['toko'][0]['nama_toko'])
                                                ),
                                                SizedBox(width: 5,),
                                                text(data['no_invoice'] == null ? '' : data['no_invoice'], bold: true, align: TextAlign.right)
                                              ],
                                            )
                                          ],
                                        )
                                    )
                                )
                              ],
                            ),
                          ),
                        ),
                      )
                  );
                }
              },
            ),
          ),

          keywordSearch ? SizedBox.shrink() :
          Positioned(
            bottom: 0,
            child: Container(
              width: MediaQuery.of(context).size.width,
              padding: EdgeInsets.only(left: 15, right: 5, top: 5, bottom: 5),
              decoration: BoxDecoration(
                color: Colors.blueGrey[500],
                border: Border(top: BorderSide(color: Colors.blueGrey))
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      text(namaSales == null ? 'Pilih Salesman' : namaSales, bold: true, color: Colors.white),
                      text(dateFormat(date), color: Colors.white)
                    ],
                  ),

                  WidSplash(
                    radius: BorderRadius.circular(50), padding: EdgeInsets.all(11),
                    onTap: !loaded || isLoadMore || namaSales == null ? null : (){ getDataPenjualan(); },
                    child: Icon(Icons.send, color: !loaded || isLoadMore || namaSales == null ? Colors.white38 : Colors.white),
                  )
                ],
              ),
            ),
          )
        ]
      )
    );
  }
}

class DaftarSalesman extends StatefulWidget {
  @override
  _DaftarSalesmanState createState() => _DaftarSalesmanState();
}

class _DaftarSalesmanState extends State<DaftarSalesman> {

  var sales = [], filter = [], loaded = false;

  getDataSalesman({refill: false}) async {
    var prefs = await SharedPreferences.getInstance();

    getData() async {
      setState(() { loaded = false; });

      Request.get('salesman', then: (status, body){
        var res = decode(body);
        return res['data'];
      }, error: (err){
        onError(context, response: err, popup: true);
      });
    }

    if(refill == true || prefs.getString('salesman') == null){
      checkConnection().then((con){
        if(con){
          getData().then((val){ print(val);
            prefs.setString('salesman', encode(val));
            setState(() {
              sales = filter = val;
            });
          });
        }else{
          Wh.alert(context, title: 'Periksa koneksi internet Anda');
        }
      });
    }else{
      var data = decode( prefs.getString('salesman') );
      setState(() {
        sales = filter = data;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    getDataSalesman();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Wh.appBar(context, title:
        Fc.search(hint: 'Ketik nama salesman', autofocus: true, change: (String s){
          var k = s.toLowerCase();
          setState(() {
            filter = sales.where((item) => item['nama_salesman'].toLowerCase().contains(k) || item['tim'].toLowerCase().contains(k)).toList();
          });
        }), actions: [

          Container(
            padding: EdgeInsets.all(10),
            child: WidSplash(
              color: TColor.silver(), radius: BorderRadius.circular(50),
              padding: EdgeInsets.only(left: 15, right: 15),
              onTap: (){ Navigator.of(context).pop({'id': 'all', 'nama': 'Semua Salesman'}); },
              child: Row(
                children: [
                  Container(
                    margin: EdgeInsets.only(right: 10),
                    child: Icon(Ic.users(), size: 20, color: Colors.black54)
                  ), text('Semua')
                ]
              ),
            ),
          )
        ]),

        body: filter.length == 0 ? Wh.noData(message: 'Tidak ada data salesman\nCobalah dengan kata kunci lain') : ListView.builder(
          itemCount: filter.length,
          itemBuilder: (BuildContext context, i){
            var data = filter[i];

            return WidSplash(
              color: i % 2 == 0 ? TColor.silver() : Colors.white,
              onTap: (){
                Navigator.of(context).pop({'id': data['id'], 'nama': data['nama_salesman']});
              },
              child: Container(
                padding: EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    text(data['tim']+' - '+data['nama_salesman'])
                  ],
                ),
              ),
            );
          },
        ),
    );
  }
}