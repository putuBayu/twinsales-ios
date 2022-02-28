import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sales/screens/penjualan/penjualan/detail-penjualan-hari-ini.dart';
import 'package:sales/services/api/api.dart';
import 'dart:async';
import 'dart:convert';

import 'package:sales/services/v2/helper.dart';

class DaftarPenjualan extends StatefulWidget {
  final String tanggal, jml;
  final ctx, paddingTop, keyword;

  const DaftarPenjualan(this.ctx, this.tanggal, this.jml, {this.paddingTop, this.keyword});

  @override
  _DaftarPenjualanState createState() => _DaftarPenjualanState();
}

class _DaftarPenjualanState extends State<DaftarPenjualan> {
  bool loading = true, isSearch = false;

  var dataToko = [], dataFiltered = [],
      isLoadMore = false, isMaxScroll = true, page = 1, perPage = 10, totalRow = 0;

  getData() async {
    setState(() {
      isSearch = false; page = 1; loading = true;
    });

    String url;

    if(widget.keyword == null){
      url = 'penjualan/tanggal/'+widget.tanggal+'?per_page='+perPage.toString()+'&page='+page.toString();
    }else{
      url = 'penjualan?keyword='+widget.keyword+'&per_page='+perPage.toString()+'&page='+page.toString();
    }

    Request.get(url, then: (s, body){
      if(mounted)
        setState(() {
          totalRow = decode(body)['meta']['total'];
          Map res = json.decode(body);
          this.loading = false;
          dataToko = res['data'];
          dataFiltered = res['data'];
        });
      }, error: (err){
      onError(context, response: err, popup: true);
    });
  }

  @override
  void initState() {
    super.initState(); getData();
  }

  Future loadMore() async{
    setState(() {
      isLoadMore = true;
      page = page + 1;
    });
    String url;

    if(widget.keyword == null){
      url = 'penjualan/tanggal/'+widget.tanggal+'?per_page='+perPage.toString()+'&page='+page.toString();
    }else{
      url = 'penjualan?keyword='+widget.keyword+'&per_page='+perPage.toString()+'&page='+page.toString();
    }

    Request.get(url, then: (s, body){
      setState(() {
        for (var item in decode(body)['data']) {
          dataToko.add(item);
        }
        isLoadMore = false;
      });
    }, error: (err){
      onError(context, response: err, popup: true);
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: TColor.silver(),
      appBar: Wh.appBar(context, title: !isSearch ? 'Daftar Penjualan' : 
        Fc.search(hint: 'Ketik nama toko', autofocus: true, change: (String s){
          var k = s.toLowerCase();
          setState(() {
            dataFiltered = dataToko.where((item) => item['toko'][0]['nama_toko'].toLowerCase().contains(k) || item['no_invoice'].toLowerCase().contains(k)).toList();
          });
        }),
          actions: [
            IconButton(
              icon: Icon(isSearch ? Ic.close() : Ic.search(), size: 20),
              onPressed: (){
                setState(() {
                  isSearch = !isSearch;

                  if(!isSearch) dataFiltered = dataToko;
                });
              },
            )
          ]
      ),

      body: loading ? ListSkeleton(length: 10) : dataFiltered == null || dataFiltered.length == 0 ? Wh.noData(message: 'Tidak ada data penjualan\nTap gambar untuk memuat ulang', onTap: (){ getData(); }) :
      
      Column(
        children: <Widget>[
          this.widget.keyword == null ? 
          new Container(
            padding: EdgeInsets.only(left: 15, right: 15, top: 7, bottom: 7),
            decoration: new BoxDecoration(
              color: Colors.blueGrey,
              boxShadow: [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, .3),
                  blurRadius: 20.0,
                  spreadRadius: 5.0,
                  offset: Offset( 2.0, 2.0, ),
                )
              ]
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                text( dateFormat(this.widget.tanggal), color: Colors.white),
                text(this.widget.jml+' Toko', color: Colors.white),
              ],
            )
          ) : SizedBox.shrink(),

          Expanded(
            child: ListView.builder(
              itemCount: dataFiltered.length == null ? 0 : dataFiltered.length + 1,
              itemBuilder: (context, i) {
                if(i == dataFiltered.length){
                  return i == totalRow || isSearch ? SizedBox.shrink() : WidSplash(
                    onTap: (){ loadMore(); },
                    padding: EdgeInsets.all(15),
                    child: Container(
                      width: Mquery.width(context),
                      child: isLoadMore ? Wh.spiner() : text('Muat lainnya', align: TextAlign.center)
                    )
                  );
                }else{
                  var data = dataFiltered[i];

                  return WidSplash(
                    color: i % 2 == 0 ? TColor.silver() : Colors.white,
                      onTap: () {
                        modal(widget.ctx, child: DetailPenjualanHariIni(ctx: this.widget.ctx, dataPenjualan: data));
                      },
                      child: Container(
                        padding: EdgeInsets.all(15),
                        child: Column(
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: text(data['id'].toString(), bold: true, )
                                ),
                                data['pending_status'] == null ? SizedBox.shrink() : Container(
                                  padding: EdgeInsets.only(left: 10, right: 10),
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(2),
                                      color: Colors.red[900]
                                  ),
                                  child: text(data['pending_status'].toString().toUpperCase(), size: 14, color: Colors.white),
                                ),
                              ],
                            ),

                            Container(
                              margin: EdgeInsets.only(top: 5),
                              child: Row(
                                children: <Widget>[
                                  Expanded(
                                    child: text(data['toko'][0] == null ? '-' : data['toko'][0]['nama_toko'], color: data['toko'][0]['id_mitra'] == null ? TColor.black() : TColor.blueLight())
                                  ),
                                  data['no_invoice'] == null ? SizedBox.shrink() : text(data['no_invoice'].toString(), bold: true,),
                                  // Icon(Icons.chevron_right, color: Cl.black05())
                                ],
                              ),
                            ),
                          ],
                        )
                      )
                  );
                }
              }
            ),
          ),
        ],
      )
    );
  }
}
