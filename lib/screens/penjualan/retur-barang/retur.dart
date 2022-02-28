import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sales/screens/penjualan/retur-barang/detail-retur.dart';
import 'package:sales/screens/penjualan/retur-barang/forms/form-retur-toko.dart';
import 'package:sales/services/api/api.dart';
import 'package:sales/services/v2/helper.dart';

class Retur extends StatefulWidget {
  Retur(this.ctx); final ctx;

  @override
  _ReturState createState() => _ReturState();
}

class _ReturState extends State<Retur> {

  var retur = [];
  String startDate = '', endDate = '';
  bool loading = true, isLoadMore = false;
  int maxRow = 0, page = 1, perPage = 10;
  DateTime date = DateTime.now();

  getRetur() async {
    setState(() {
      loading = true;
      page = 1;
    });

    Request.get('retur_penjualan?per_page='+perPage.toString()+'&page='+page.toString()+'&start_date='+startDate+'&end_date='+endDate, debug: true, then: (status, res){
      if(mounted){
        setState(() {
          loading = false;
          maxRow = decode(res)['meta']['total'];
          retur = decode(res)['data'];
        });
      }
    }, error: (err){
      onError(context, response: err, popup: true);
    });
  }

  @override
  void initState() {
    super.initState();

    startDate = Dt.ymd;
    endDate = Dt.ymd;

    getRetur();
  }

  Future<Null> _onRefresh() async {
    getRetur();
  }

  void loadMore(){
    page = page + 1;

    setState(() {
      isLoadMore = true;
    });

    Request.get('retur_penjualan?per_page='+perPage.toString()+'&page='+page.toString()+'&start_date='+startDate+'&end_date='+endDate, then: (status, data){
      setState(() {
        isLoadMore = false;
        for (var item in decode(data)['data']) {
          retur.add(item);
        }
      });
    }, error: (err){
      onError(context, response: err, popup: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Wh.appBar(context, title: 'Daftar Retur', actions: [
        IconButton(
          icon: Icon(Ic.calendar(), color: loading ? Colors.black38 : Colors.black54, size: 20),
          onPressed: loading ? null : (){
            Wh.datePicker(context, init: date, max: Dt.dateTime(format: 'now+')).then((res){
              if(res != null){
                startDate = endDate = res;
                date = DateTime.parse(res);
                getRetur();
              }
            });
          },
        )
      ]),

      body: loading ? ListSkeleton(length: 10) : retur == null || retur.length == 0 ? Wh.noData(
          message: 'Tidak ada data retur\nTap gambar untuk memuat ulang',
          onTap: (){
            getRetur();
          }
      ) : RefreshIndicator(
        onRefresh: _onRefresh,
          child: ListView.builder(
              itemCount: retur.length + 1,
              itemBuilder: (context, i){
                if(i == retur.length){
                  return retur.length == maxRow ? SizedBox.shrink() : WidSplash(
                    onTap: isLoadMore ? null : (){
                      loadMore();
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(margin: EdgeInsets.only(right: 5), child: isLoadMore ? Wh.spiner(margin: 3, size: 19) : Icon(Icons.refresh)),
                        text('Muat lainnya')
                      ]
                    )
                  );
                }else{
                  var data = retur[i];

                  return WidSplash(
                    color: i % 2 == 0 ? TColor.silver() : Colors.white38,

                    onTap: (){
                      modal(widget.ctx, child: DetailRetur(ctx: widget.ctx, data: data), then: (_){
                        getPrefs('approved_detail_retur', dec: true).then((res){
                          if(res != null){
                            setState(() {
                              data['status'] = res['status'];
                            });
                            removePrefs(list: ['approved_detail_retur']);
                          }
                        });
                        _onRefresh();
                      });

                      getPrefs('returHasApproved', type: bool).then((res){
                        if(res != null){
                          removePrefs(list: ['returHasApproved']);
                          getRetur();
                        }
                      });
                    },
                    onLongPress: data['status'] != 'waiting' ? null : (){
                      Wh.options(context, options: ['Edit'], icons: [Ic.edit()], then: (res){
                        Navigator.pop(context);
                        if(res != null)
                        switch (res) {
                          case 0:
                            modal(widget.ctx, child: FormReturToko(ctx: widget.ctx, formData: data), then: (res){
                              if(res != null){
                                getRetur();
                                // setState(() {
                                //   data['toko']['id'] = int.parse(res['data']['id_toko']);
                                //   data['toko']['nama_toko'] = res['data']['nama_toko'];
                                //   data['tipe_barang'] = res['data']['tipe_barang'];
                                // });
                              }
                            });
                            break;
                        }
                      });
                    },
                    padding: EdgeInsets.all(15),
                    child: Container(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                  child: text(data['id'].toString(), bold: true)
                              ),
                              Row(
                                children: [
                                  data['verified_by'] == null ? SizedBox.shrink() : Container(
                                    margin: EdgeInsets.only(bottom: 5, right: 5),
                                    padding: EdgeInsets.only(left: 10, right: 10),
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(2),
                                        color: TColor.blue()
                                    ),
                                    child: text('verified', color: Colors.white),
                                  ),
                                  Container(
                                    margin: EdgeInsets.only(bottom: 5),
                                    padding: EdgeInsets.only(left: 10, right: 10),
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(2),
                                        color: data['claim_date'] != null ? TColor.blueLight() : data['status'] == 'waiting' ? TColor.orange() : TColor.green()
                                    ),
                                    child: text(data['claim_date'] != null ? 'claim' : data['status'], color: Colors.white),
                                  ),
                                ],
                              ),
                            ]
                          ),

                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Container(
                                    margin: EdgeInsets.only(top: 5),
                                    child: text(data['no_acc_toko']+', '+data['nama_toko'], color: data['id_mitra'] == null || data['id_mitra'] == 0 ? TColor.black() : TColor.blueLight())
                                ),
                              ),
                              text(data['tipe_barang'].toString().toUpperCase(), bold: true),
                            ]
                          ),
                        ]
                      )
                    ),
                  );
                }
              },
          ),
      ),

      floatingActionButton: loading ? null : FloatingActionButton(
        backgroundColor: TColor.azure(),
        onPressed: (){
          modal(widget.ctx, child: FormReturToko(ctx: this.widget.ctx), then: (res){
            if(res != null){
              modal(widget.ctx, child: DetailRetur(ctx: widget.ctx, data: res['data']));
              _onRefresh();
            }
          });
        },
        child: Icon(Ic.add(), color: Colors.white),
      ),
    );
  }
}