import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sales/screens/penjualan/kunjungan/detail-kunjungan-hari-ini.dart';
import 'package:sales/screens/penjualan/kunjungan/form-kunjungan.dart';
import 'package:sales/screens/penjualan/penjualan/forms/form-penjualan.dart';
import 'package:sales/services/api/api.dart';
import 'package:sales/services/v2/helper.dart';
import 'package:ntp/ntp.dart';
import 'package:intl/intl.dart';

class KunjunganHariIni extends StatefulWidget {
  final ctx, initData;
  KunjunganHariIni(this.ctx, {this.initData});
  @override
  _KunjunganHariIniState createState() => _KunjunganHariIniState();
}

class _KunjunganHariIniState extends State<KunjunganHariIni> {
  var isSearch = false, loading = true, dataCall = [], dataFiltered = [],
      isLoadMore = false, isMaxScroll = true, page = 1, perPage = 10, totalRow = 0,
      keyword = '';

  ScrollController scroll;

  getCall() async {
    page = 1;
    setState(() { loading = true; });

    var date = NTP.now();
    final DateFormat formatter = DateFormat('yyyy-MM-dd');
    final String formatted = formatter.format(await date);

    // var tanggal = widget.initData['tanggal'] == null ? '' : widget.initData['tanggal'];
    var tanggal = widget.initData == null ? formatted : widget.initData['tanggal'];

    Request.get('kunjungan_sales?per_page=' + perPage.toString() + '&page=' + page.toString() + '&tanggal=' + tanggal.toString() + '&keyword=' + keyword, then: (status, body){
      if(mounted){
        setState(() {
          totalRow = decode(body)['meta']['total'];
        });

        Map res = decode(body);
        loading = false;

        setState(() {
          dataCall = res['data'];
          dataFiltered = res['data'];
        });

        return res['data'];
      }
    }, error: (err){
      setState(() { loading = false; });
      onError(context, response: err);
    });
  }

  Future<Null> _onRefresh() async {
    setState(() {
      page = 1;
      keyword = '';
    });
    getCall();
  }

  Future loadMore() async{
    getData(result) async {
      setState(() {
        isLoadMore = true;
        page = page + 1;
      });

      Request.get('kunjungan_sales?per_page=' + perPage.toString() + '&page=' + page.toString() + '&keyword=' + keyword, then: (status, body){
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
              dataCall.add(item);
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
  void initState() {
    super.initState();
    getCall();

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
      appBar: Wh.appBar(context, back: true, title: !isSearch ? widget.initData == null ? 'Kunjungan Hari Ini' : 'Riwayat Kunjungan'
          : Fc.search(hint: 'Ketik nama toko', autofocus: true, change: (String s){
            var k = s.toLowerCase();
            setState(() {
              keyword = k;
              // isSearch = !isSearch;
              // if(!isSearch) dataFiltered = dataCall;
          // dataFiltered = dataPenjualan.where((item) => item['toko'][0]['nama_toko'].toLowerCase().contains(k)).toList();
            });
            getCall();
          }),
          actions: [
            IconButton(
              icon: Icon(isSearch ? Ic.close() : Ic.search(), size: 20, color: loading || dataFiltered.length == 0 ? Colors.black26 : Colors.black54),
              onPressed: loading || dataFiltered.length == 0 ? null : (){
                setState(() {
                  isSearch = !isSearch;
                  loading = true;
                  // if(!isSearch) dataFiltered = dataCall;
                });
                _onRefresh();
              },
            ),
          ]),

        body: loading ? ListSkeleton(length: 10) :  Stack(
            children: <Widget>[
              RefreshIndicator(
                onRefresh: _onRefresh,
                child: dataFiltered == null || dataFiltered.length == 0 ? Wh.noData(message: 'Tidak ada data kunjungan\nCoba refresh atau dengan kata kunci lain.') :
                Column(
                  children: [
                    widget.initData != null ? Container(
                        padding: EdgeInsets.only(left: 15, right: 15, top: 7, bottom: 7),
                        decoration: new BoxDecoration(
                            color: Colors.blueGrey,
                            boxShadow: [
                              BoxShadow(
                                color: Color.fromRGBO(0, 0, 0, .3),
                                blurRadius: 20.0,
                                spreadRadius: 5.0,
                                offset: Offset(2.0, 2.0),
                              )
                            ]),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: text(widget.initData['tanggal'], color: Colors.white)
                            ),
                            text(widget.initData['jumlah_kunjungan'] + ' Kunjungan', color: Colors.white),
                          ],
                        )
                    ) : SizedBox.shrink(),
                    Expanded(
                      child: ListView.builder(
                        controller: scroll,
                        itemCount: dataFiltered.length,
                        itemBuilder: (context, i) {
                          var data = dataFiltered[i];

                          return SlideUp(
                            child: WidSplash(
                                color: i % 2 == 0 ? TColor.silver() : Colors.white,
                                onTap: (){
                                  modal(widget.ctx, child: DetailKunjunganHariIni(ctx: widget.ctx, initData: data,));
                                },
                                onLongPress: (){
                                  if(widget.initData == null){
                                    Wh.options(context, options: ['Edit Kunjungan','Hapus Kunjungan'], icons: [Ic.edit(), Ic.trash()], then: (res){
                                      Navigator.pop(context);

                                      if(res != null){
                                        switch (res) {
                                          case 0:
                                            // modal(this.widget.ctx, child: FormCall(this.widget.ctx, initData: data), then: (res){
                                            //   if(res != null && res){
                                            //     setState(() {
                                            //       loading = true;
                                            //       getCall();
                                            //     });
                                            //   }
                                            // });
                                            Navigator.of(context).push(MaterialPageRoute(
                                                  builder: (BuildContext context) => FormPenjualan(widget.ctx, initDataKunjungan: data,))
                                            ).then((res){
                                              if(res != null && res){
                                                setState(() {
                                                  loading = true;
                                                  getCall();
                                                });
                                              }
                                            });
                                            // Navigator.of(context).push(MaterialPageRoute(
                                            //     builder: (BuildContext context) => FormKunjungan(widget.ctx, initData: data,))
                                            // ).then((res){
                                            //   if(res != null && res){
                                            //     setState(() {
                                            //       loading = true;
                                            //       getCall();
                                            //     });
                                            //   }
                                            // });
                                            break;

                                          default: Wh.confirmation(context, message: 'Yakin ingin menghapus kunjungan ini?', confirmText: 'Hapus Kunjungan', then: (res){
                                            if(res != null && res == 0){
                                              Navigator.pop(context);
                                              showDialog(context: context, child: OnProgress(message: 'Menghapus...'));

                                              Request.delete('kunjungan_sales/'+data['id'].toString(), debug: true, then: (s, data){
                                                Navigator.pop(context);
                                                getCall();
                                              }, error: (err){
                                                onError(context, response: err, popup: true);
                                              });
                                            }
                                          });
                                        }
                                      }
                                    });
                                  }
                                },
                                child: Container(
                                  padding: EdgeInsets.all(15),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: <Widget>[
                                              data['cust_no'] != ''
                                                  ? text( data['no_acc'] + ' - ' + data['cust_no'], bold: true )
                                                  : text( data['no_acc'], bold: true ),
                                              text(data['nama_toko']),

                                              Container(
                                                width: Mquery.width(context),
                                                child: Row(
                                                  children: <Widget>[
                                                    data['keterangan'] == ''
                                                        ? SizedBox.shrink()
                                                        : text(data['keterangan'])
                                                    // data['status'] != '' && data['keterangan'] != ''
                                                    //     ? text(ucword(data['status']) + ', ' + data['keterangan'])
                                                    //     : data['keterangan'] == ''
                                                    //     ? text(ucword(data['status']))
                                                    //     : text(data['keterangan'])
                                                  ],
                                                ),
                                              )
                                            ],
                                          ),
                                        ),
                                        data['status'] == '' ? SizedBox.shrink() : Container(
                                          margin: EdgeInsets.only(right: 5),
                                          height: 8,
                                          width: 8,
                                          decoration: BoxDecoration(
                                            color: data['status'] == 'tutup' || data['status'] == 'bangkrut' ? Colors.grey : Colors.red,
                                            borderRadius: BorderRadius.circular(20)
                                          ),
                                        ),
                                        text(data['status'].toString().toUpperCase(), size: 13)
                                      ],
                                    ),
                                  )
                                )
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                )
              ),

              PaginateControl(
                isMaxScroll: isMaxScroll,
                isLoad: isLoadMore,
                totalRow: totalRow,
                totalData: dataCall.length,
                onTap: loadMore,
              )
            ]
        ),
      // floatingActionButton: widget.initData != null ? SizedBox.shrink() : FloatingActionButton(
      //   onPressed: (){
      //     // modal(widget.ctx, child: FormCall(widget.ctx), then: (res){
      //     //   if(res != null && res){
      //     //     getCall();
      //     //   }
      //     // });
      //     Navigator.of(context).push(MaterialPageRoute(
      //         builder: (BuildContext context) => FormCall(widget.ctx,))
      //     ).then((res){
      //       if(res != null && res){
      //         getCall();
      //       }
      //     });
      //   },
      //   child: Icon(Icons.add, color: Colors.white,),
      //   backgroundColor: TColor.azure(),
      // ),
    );
  }
}
