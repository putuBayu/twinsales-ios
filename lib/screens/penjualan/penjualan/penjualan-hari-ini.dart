import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:path/path.dart';
import 'package:sales/services/api/api.dart';
import 'package:sales/services/v2/helper.dart';
import 'package:ntp/ntp.dart';

import 'detail-penjualan-hari-ini.dart';

class PenjualanHariIni extends StatefulWidget {
  final ctx, paddingTop;
  PenjualanHariIni({this.ctx, this.paddingTop});

  _PenjualanHariIniState createState() => _PenjualanHariIniState();
}

class _PenjualanHariIniState extends State<PenjualanHariIni>{
  var isSearch = false, loading = true, dataPenjualan = [], dataFiltered = [],
      isLoadMore = false, isMaxScroll = true, page = 1, perPage = 10, totalRow = 0,
      keyword = '', idUser, idDepo, kodeEks, dataEks = [];

  ScrollController scroll;

  getPenjualanHariIni({refill: false}) async {
    page = 1;
    setState(() { loading = true; });

    Request.get('penjualan/list/penjualan_today?per_page='+perPage.toString()+'&page='+page.toString() + '&keyword=' + keyword, then: (status, body){
      if(mounted){
        setState(() {
          totalRow = decode(body)['meta']['total'];
        });

        Map res = decode(body);
        loading = false;

        setState(() {
          dataPenjualan = res['data'];
          dataFiltered = res['data'];
        });

        return res['data'];
      }
    }, error: (err){
      setState(() { loading = false; });
      onError(context, response: err);
    });
  }

  syncOrder()async{
    Wh.dialog(this.context, child: SyncPenjualan());
    var tanggal = await NTP.now();
    String formated = dateFormat(tanggal.toString(), format: 'y-m-d');

    // print('import/penjualan_kino?id_user=' + idUser.toString() + '&id_depo=' + idDepo.toString() + '&kode_eksklusif=' + kodeEks.toString() + '&tanggal=' + formated);

    Request.get('import/penjualan_kino?id_user=' + idUser.toString() + '&id_depo=' + idDepo.toString() + '&kode_eksklusif=' + kodeEks.toString() + '&tanggal=' + formated, then: (status, body){
      if(mounted){
        Navigator.pop(this.context);
        getPenjualanHariIni(refill: true);
      }
    }, error: (err){
      Navigator.pop(this.context);
      setState(() { loading = false; });
      onError(this.context, response: err);
    });
  }

  getSalesEks()async{
    dataEks = await getPrefs('user-eksklusif', dec: true);

    if(dataEks.length > 0){
      setState(() {
        idUser = dataEks[0]['id_user'];
        idDepo = dataEks[0]['id_depo'];
        kodeEks = dataEks[0]['kode_eksklusif'];
      });
    }
  }

  @override
  void initState() {
    getSalesEks();
    getPenjualanHariIni(refill: true);

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

  Future<Null> _onRefresh() async {
    setState(() {
      page = 1;
      keyword = '';
    });
    getPenjualanHariIni(refill: true);
  }

  Future<bool> onWillPop() {
    Navigator.pop(this.context);
    return Future.value(false);
  }

  Future loadMore() async{
    getData(result) async {
      setState(() { 
        isLoadMore = true;
        page = page + 1;
      });

      Request.get('penjualan/list/penjualan_today?per_page='+perPage.toString()+'&page='+page.toString() + '&keyword=' + keyword, then: (status, body){
        Map res = decode(body);
        result(res['data']);
      }, error: (err){
        onError(context, response: err, popup: true);
      });
    }

    checkConnection().then((con){
      if(con){
        getData((val){
          setState(() {
            isMaxScroll = false;

            for (var item in val) {
              dataPenjualan.add(item);
            }
            isLoadMore = false;

            Timer(Duration(milliseconds: 200), (){
              scroll.animateTo(
                scroll.position.maxScrollExtent - 50,
                curve: Curves.easeOut,
                duration: const Duration(milliseconds: 300),
              );
            });

          });
        });
      }else{
        Wh.alert(context, title: 'Opps!', message: 'Periksa koneksi internet Anda');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TColor.silver(),
      appBar: Wh.appBar(context, back: true, title: !isSearch ? 'Penjualan Hari Ini' :

      Fc.search(hint: 'Ketik nama toko', autofocus: true, change: (String s){
        var k = s.toLowerCase();
        setState(() {
          keyword = k;
          // dataFiltered = dataPenjualan.where((item) => item['toko'][0]['nama_toko'].toLowerCase().contains(k)).toList();
        });
      }),
        
      actions: [
        isSearch ? SlideLeft(
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: WidSplash(
              radius: BorderRadius.circular(5),
              onTap: (){
                setState(() {
                  getPenjualanHariIni();
                });
              },
              color: TColor.azure(),
              child: Container(
                margin: EdgeInsets.symmetric(vertical: 5),
                // width: Mquery.width(context),
                padding: EdgeInsets.symmetric(vertical: 3, horizontal: 10),
                child: text('Cari', spacing: 2, align: TextAlign.center, color: Colors.white),
              ),
            ),
          ),
        ) : SizedBox.shrink(),

        IconButton(
          icon: Icon(isSearch ? Ic.close() : Ic.search(), size: 20, color: loading || dataFiltered.length == 0 ? Colors.black26 : Colors.black54),
          onPressed: loading || dataFiltered.length == 0 ? null : (){
            setState(() {
              _onRefresh();
              isSearch = !isSearch;
              if(!isSearch) dataFiltered = dataPenjualan;
            });
          },
        ),

        !isSearch ? IconButton(
          icon: Icon(Ic.refresh(), size: 20, color: loading ? Colors.black26 : Colors.black54),
          onPressed: loading ? null : (){
            getPenjualanHariIni();
          },
        ) : SizedBox.shrink()
      ]),

      body: loading ? ListSkeleton(length: 10) :  Stack(
        children: <Widget>[
          
          new RefreshIndicator(
            onRefresh: _onRefresh,
            child: dataFiltered == null || dataFiltered.length == 0 ? Wh.noData(message: 'Tidak ada data penjualan\nCoba refresh atau dengan kata kunci lain.') :

            ListView.builder(
                controller: scroll,
                itemCount: dataFiltered.length,
                itemBuilder: (context, i) {
                  var data = dataFiltered[i];

                  return SlideUp(
                    child: WidSplash(
                      color: i % 2 == 0 ? TColor.silver() : Colors.white,
                      onTap: (){
                        modal(widget.ctx, child: DetailPenjualanHariIni(ctx: widget.ctx, dataPenjualan: data), then: (res){
                          // baca aktivitas menyetujui penjualan
                          getPrefs('hasApproved', type: bool).then((res){
                            if(res != null){
                              removePrefs(list: ['hasApproved']);
                              getPenjualanHariIni(refill: true);
                            }
                          });
                        });
                      },
                      child: new Container(
                        child: new Column(
                          children: <Widget>[
                            new Container(
                                padding: EdgeInsets.all(15),
                                child: new Align(
                                  alignment: Alignment.centerLeft,
                                  child: new Column(
                                    children: <Widget>[
                                      Row(
                                        children: <Widget>[
                                          Expanded(
                                            child: text(
                                                data['po_manual'] == null || data['po_manual'] == '' ? data['id'].toString() : data['po_manual'], bold: true)
                                          ),
                                          data['pending_status'] == null ? SizedBox.shrink() : Container(
                                            margin: EdgeInsets.only(right: 10),
                                            padding: EdgeInsets.only(left: 10, right: 10),
                                            decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(2),
                                                color: Colors.red[900]
                                            ),
                                            child: text(data['pending_status'].toString().toUpperCase(), size: 14, color: Colors.white),
                                          ),
                                          Container(
                                            padding: EdgeInsets.only(left: 10, right: 10),
                                            decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(2),
                                                color: data['status'] == 'waiting' ? TColor.orange() : data['status'] == 'approved' ? TColor.green() : TColor.blueLight()
                                            ),
                                            child: text(ucword(data['status']), color: Colors.white),
                                          ),
                                        ],
                                      ),

                                      Container(
                                        margin: EdgeInsets.only(top: 5),
                                        child: Row(
                                          children: <Widget>[
                                            Expanded(
                                              child: text( data['toko'][0]['nama_toko'], color: data['id_mitra'] == null || data['id_mitra'] == 0 ? TColor.black() : TColor.blueLight())
                                            ),

                                            data['no_invoice'] == null
                                                ? SizedBox.shrink()
                                                : text(data['no_invoice'].toString().toUpperCase(), bold: true)
                                          ],
                                        ),
                                      )
                                      
                                    ],
                                  ),
                                )
                              )
                            ],
                          ),
                        )
                      ),
                  );
                },
              )
            ),

            PaginateControl(
              isMaxScroll: isMaxScroll,
              isLoad: isLoadMore,
              totalRow: totalRow,
              totalData: dataPenjualan.length,
              onTap: loadMore,
            )

          ]
        ),
        floatingActionButton: loading || dataEks.length <= 0 ? SizedBox.shrink() : FloatingActionButton(
          backgroundColor: TColor.azure(),
          onPressed: (){
            syncOrder();
          },
          child: Icon(Ic.sync()),
        ),
    );
  }
}

class SyncPenjualan extends StatefulWidget {
  @override
  _SyncPenjualanState createState() => _SyncPenjualanState();
}

class _SyncPenjualanState extends State<SyncPenjualan> {
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
          child: Row(
            children: <Widget>[
              Wh.spiner(size: 25, margin: 15),
              Flexible(
                  child: Container(
                    padding: EdgeInsets.only(right: 15),
                    child: text('Mohon menunggu, sedang menyiapkan data'),
                  )
              )
            ],
          ),
        )
    );
  }
}
