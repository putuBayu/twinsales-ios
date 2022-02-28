import 'package:flutter/material.dart';
import 'package:sales/screens/penjualan/penjualan/detail-penjualan-hari-ini.dart';
import 'package:sales/services/api/api.dart';
import 'package:sales/services/v2/helper.dart';

import 'forms/form-pelunasan.dart';

class DetailPelunasan extends StatefulWidget {
  final ctx, data;
  DetailPelunasan({this.ctx, this.data});

  @override
  _DetailPelunasanState createState() => _DetailPelunasanState();
}

class _DetailPelunasanState extends State<DetailPelunasan> {
  bool minimize = false;
  var pelunasan = [],
      loaded = true,
      jumlahLunas = 0,
      jumlahBelumBayar = 0,
      approvePermission = false;

  getData() async{
    setState(() => loaded = false );

    getPrefs('log_salesman', dec: true).then((res){
      if(res != null){
       if(res['tipe'] == 'canvass') approvePermission = true;
      }
    });

    getPrefs('user', dec: true).then((res){
      if(res != null){
       if(res['role'] == 'adminn') approvePermission = true;
      }
    });

    await Request.get('pelunasan_penjualan/'+widget.data['id'].toString(), then: (s, body){
      var data = decode(body);
      widget.data.forEach((k, v){
        widget.data[k] = data['data'][k];
      });
    }, error: (err){
      onError(context, response: err, popup: true);
    });

    await Request.get('detail_pelunasan_penjualan/jumlah_belum_dibayar/'+widget.data['id'].toString(), then: (s, body){
      var data = decode(body);
      setState(() {
        jumlahLunas = data['jumlah_lunas'];
        jumlahBelumBayar = data['jumlah_belum_dibayar'];
      });
    }, error: (err){
      onError(context, response: err, popup: true);
    });

    await Request.get('detail_pelunasan_penjualan?per_page=10&page=1&keyword='+widget.data['id'].toString(), then: (s, body){
      var data = decode(body);
      setState(() {
        loaded = true;
        pelunasan = data['data'];
      });
    }, error: (err){
      onError(context, response: err, popup: true);
    });
  }

  @override
  void initState() {
    super.initState();
    getData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Wh.appBar(context, title: 'Detail Pelunasan', actions: [
        IconButton(
          icon: Icon(!minimize ? Ic.minimize() : Ic.maximize(), size: 20, color: loaded && !minimize ? Colors.black54 : Colors.black38,),
          onPressed: !loaded ? null : (){ setState(() => minimize = !minimize );  },
        ),

        IconButton(
          icon: Icon(Ic.refresh(), size: 20, color: loaded ? Colors.black54 : Colors.black38,),
          onPressed: !loaded ? null : (){ getData(); },
        ),
      ]),

      body: !loaded ? ListSkeleton(length: 10) : 
      
      Column(
        children: [
          AnimatedContainer(
            duration: Duration(milliseconds: 300),
            height: minimize ? 0 : (11 * 21).toDouble(),
            padding: EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: TColor.silver(), width: 1)
              ),
              image: DecorationImage(
                image: AssetImage('assets/img/line-card.png'),
                fit: BoxFit.fill,
                colorFilter: ColorFilter.linearToSrgbGamma()
              )
            ),
            child: PreventScrollGlow(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(11, (int i){
                    var labels = ['No. PO','No. Invoice','Nama Toko','No. Acc','Cust No','Tanggal Penjualan','Jatuh Tempo',
                    'Grand Total','Bayar','Sisa','Status'],

                        values = [
                          widget.data['id'], 
                          widget.data['no_invoice'] == null ? '' : widget.data['no_invoice'],
                          widget.data['nama_toko'],
                          widget.data['no_acc'] == null ? '' : widget.data['no_acc'],
                          widget.data['cust_no'] == null ? '' : widget.data['cust_no'],
                          widget.data['tanggal_penjualan'],
                          widget.data['paid_at'] == null ? widget.data['due_date']+' ('+widget.data['over_due'].toString()+' hari)' : widget.data['due_date']+' (LUNAS)',
                          // widget.data['tipe_pembayaran'], 
                          // dateFormat(widget.data['due_date']), 
                          'Rp '+ribuan(widget.data['jumlah_pembayaran'].toString(), fixed: 2),
                          'Rp '+ribuan(jumlahLunas.toString()),
                          'Rp '+ribuan(jumlahBelumBayar.toString(), fixed: 0),
                          widget.data['paid_at'] == null ? 'Belum Lunas' : 'LUNAS ('+dateFormat(widget.data['paid_at'])+')',
                          // widget.data['paid_at'] == null ? '-' : dateFormat(widget.data['paid_at'])
                        ];
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        text(labels[i]),

                        i == 0 ? WidSplash(
                          onTap: (){
                            showDialog(
                              context: context,
                              child: OnProgress(message: 'Loading...')
                            );

                            Request.get('penjualan?keyword='+widget.data['id'].toString()+'&per_page=1&page=1', then: (s, body){
                              Navigator.pop(context);
                              var data = decode(body)['data'][0];
                              modal(widget.ctx, child: DetailPenjualanHariIni(ctx: this.widget.ctx, dataPenjualan: data, readOnly: true));
                            }, error: (err){
                              onError(context, response: err, popup: true);
                            });

                          },
                          child: text(values[i], color: i == 0 ? Colors.blue : Colors.black54),
                        ) : text(values[i], color: i == 0 ? Colors.blue : Colors.black54),
                      ]
                    );
                  })
                ),
              ),
            ),
          ),
          pelunasan == null || pelunasan.length == 0 ? Container(margin: EdgeInsets.only(top: 15), child: Wh.noData(message: 'Tidak ada data pelunasan\nTap gambar untuk memuat ulang.', onTap: (){ getData(); })) :

          Expanded(
            child: ListView.builder(
              itemCount: pelunasan.length,
              itemBuilder: (BuildContext context, i){
                var data = pelunasan[i];

                return WidSplash(
                  onTap: (){
                    modal(widget.ctx, child: DetailItemPelunasan(data: data));
                  },
                  onLongPress: data['status'] == 'approved' ? null : (){
                    var options = ['Edit','Hapus','Setujui'];

                    var filter = [];

                    if(!approvePermission){ filter..addAll([2]); }
                    if(data['tipe'] != 'tunai' && data['tipe'] != 'saldo_retur'){ filter..addAll([2]); }

                    Wh.options(context, options: options, hide: filter, then: (res){
                      if(res != null){
                        Navigator.pop(context);

                        switch (res) {
                          case 0:
                            modal(widget.ctx, child: FormPelunasan(data: widget.data, isEdit: true, dataPelunasan: data), then: (res){
                              if(res != null) getData();
                            });
                            break;

                          case 2:
                            Wh.confirmation(context, message: 'Yakin ingin menyetujui pelunasan ini?', confirmText: 'Setujui Pelunasan', then: (res){
                              if(res != null && res == 0){
                                Navigator.pop(context);

                                showDialog(
                                  context: context,
                                  child: OnProgress(message: 'Menyetujui...')
                                );

                                Request.post('detail_pelunasan_penjualan/approve/'+data['id'].toString(), then: (status, body){
                                  Map res = decode(body);
                                  setState(() {
                                    data['status'] = 'approved';
                                  });

                                  Wh.toast(res['message']);
                                  Navigator.pop(context);
                                }, error: (err){
                                  onError(context, response: err, popup: true);
                                });
                              }
                            });
                            break;

                            default:
                            Wh.confirmation(context, message: 'Yakin ingin menghapus pelunasan ini?', confirmText: 'Hapus Pelunasan', then: (res){
                              if(res != null && res == 0){
                                Navigator.pop(context);

                                showDialog(
                                  context: context,
                                  child: OnProgress(message: 'Menghapus...')
                                );

                                setTimer(1, then: (t){
                                  Request.delete('detail_pelunasan_penjualan/'+data['id'].toString(), then: (status, body){
                                    Map res = decode(body);
                                    getData();
                                    Wh.toast(res['message']);

                                    Navigator.pop(context, {'delete': true});
                                  }, error: (err){
                                    onError(context, response: err, popup: true);
                                  });
                                });
                              }
                            });
                        }
                      }
                    });
                  },
                  color: i % 2 == 0 ? TColor.silver() : Colors.white,
                  padding: EdgeInsets.all(0),
                  child: Container(
                    padding: EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            text(data['tipe']),
                            text(data['created_at']),
                          ]
                        ),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            text('Rp. '+ribuan(data['nominal'].toString())),

                            Container(
                              width: 80,
                              padding: EdgeInsets.only(left: 5, right: 5),
                              decoration: BoxDecoration(
                                color: data['status'] == 'waiting' ? TColor.orange() : data['status'] == 'approved' ? TColor.green() : TColor.red(),
                                borderRadius: BorderRadius.circular(2)
                              ),
                              child: text(data['status'], color: Colors.white, align: TextAlign.center),
                            ),
                          ]
                        ),
                      ]
                    ),
                  ),
                );
              },
            ),
          )
        ]
      ),

      floatingActionButton: !loaded || jumlahBelumBayar == 0 ? null : FloatingActionButton(
        backgroundColor: TColor.azure(),
        child: Icon(Ic.add()),
        onPressed: (){
          modal(widget.ctx, child: FormPelunasan(data: widget.data, autoNominal: jumlahBelumBayar.toString()), then: (res){
            if(res != null){
              getData();
            }
          });
        },
      ),
    );
  }
}

class DetailItemPelunasan extends StatefulWidget {
  final data;
  DetailItemPelunasan({this.data});

  @override
  _DetailItemPelunasanState createState() => _DetailItemPelunasanState();
}

class _DetailItemPelunasanState extends State<DetailItemPelunasan> {
  var length = 0, labels = [], values = [];

  initData(){
    var data = widget.data;
    print(data);
    labels = [
      'No. PO', 'No. Invoice', 'No. Acc', 'Cust No', 'Nama Toko', 'Tipe Pelunasan', 'No. Invoice Rebate', 'Nominal', 'Bank', 'No. Rekening', 'No. BG', 'Jatuh Tempo Bg', 'Keterangan', 'Status', 'Created At', 'Approved At'
    ];

    values = [
      data['id_penjualan'],
      data['no_invoice'] == null ? '' : data['no_invoice'],
      data['no_acc'],
      data['cust_no'],
      data['nama_toko'],
      data['tipe'],
      data['no_invoice_rebate'] == null ? '' : data['no_invoice_rebate'],
      'Rp '+ribuan(data['nominal']),
      data['bank'],
      data['no_rekening'],
      data['no_bg'],
      data['jatuh_tempo_bg'] == null ? '' : data['jatuh_tempo_bg'],
      data['keterangan'], 
      data['status'], 
      data['created_at'],
      data['approved_at']
    ];

    var removes = [];

    if(data['tipe'] == 'transfer'){
      removes = ['No. BG','Jatuh Tempo Bg', 'No. Invoice Rebate'];
    }else if(data['tipe'] == 'bilyet_giro'){
      removes = ['No. Rekening', 'No. Invoice Rebate'];
    }else if(data['tipe'] == 'cash_rebate'){
      removes = ['Bank','No. Rekening','No. BG','Jatuh Tempo Bg'];
    }else{
      removes = ['Bank','No. Rekening','No. BG','Jatuh Tempo Bg', 'No. Invoice Rebate'];
    }

    removes.forEach((f){
      var index = labels.indexOf(f);
      labels.removeWhere((item) => item == f);
      values.removeAt(index);
    });

    length = labels.length;
  }

  @override
  void initState() {
    super.initState(); initData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Wh.appBar(context, title: 'Detail Item Pelunasan', center: true),

      body: PreventScrollGlow(
        child: SingleChildScrollView(
          child: Column(
            children: List.generate(length, (int i){
              return Container(
                padding: EdgeInsets.all(15), width: Mquery.width(context),
                color: i % 2 == 0 ? TColor.silver() : Colors.white,
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: <Widget>[
                     text(labels[i], bold: true),
                     text(values[i])
                   ],
                 ),
              );
            })
          ),
        ),
      ),
    );
  }
}