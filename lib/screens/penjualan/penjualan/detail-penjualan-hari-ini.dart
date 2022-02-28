import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sales/screens/penjualan/pelunasan/detail-pelunasan.dart';
import 'package:sales/screens/penjualan/penjualan/forms/form-penjualan.dart';
import 'package:sales/services/api/api.dart';
import 'package:sales/services/v2/helper.dart';
import 'package:sales/services/v3/helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/services.dart';
import 'package:telebot/telebot.dart';

import 'forms/form-barang.dart';

class DetailPenjualanHariIni extends StatefulWidget {
  final ctx, dataPenjualan, readOnly;
  const DetailPenjualanHariIni({this.ctx, this.dataPenjualan, this.readOnly: false});

  @override
  _DetailPenjualanHariIniState createState() => _DetailPenjualanHariIniState();
}

class _DetailPenjualanHariIniState extends State<DetailPenjualanHariIni> {

  // declare variable
  var loader = true, loaderTotal = true, printPermission = false, approvePermission = false,
      data, detailBarang = [], penjualan, status = 'waiting';// ___tipeHarga = '';

  loadData({String activity, bool startPage: false, bool refresh: false}) async {
    status = widget.dataPenjualan['status'];

    var prefs = await SharedPreferences.getInstance(), id = data['id'],
        logSales = decode(prefs.getString('log_salesman'));

    setState(() {
      loader = true;
    });

    // removePrefs(list: ['activities']);

    await Request.get('penjualan/'+id.toString(), debug: true, then: (status, data) async{
      // printPermission = true;
      // if(logSales != null && logSales['tipe'] == 'to'){
      //   printPermission = false;
      // }

      if(logSales != null && logSales['tipe'] == 'canvass'){
        approvePermission = true;
        printPermission = true;
      }

      if(mounted){
        setState(() {
          Map res = decode(data); //print(res['data']['grand_total']);
          penjualan = res['data'];
          loaderTotal = false;

          // print(penjualan);
          // print('-- GT: '+penjualan['grand_total'].toString());
        });

        if(startPage){
            await trackActivity('Load halaman detail penjualan ('+penjualan['grand_total'].toString()+')');
          }

          if(refresh){
            await trackActivity('Refresh halaman ('+penjualan['grand_total'].toString()+')');
          }

          if(activity != null){
            await trackActivity(activity+' ('+penjualan['grand_total'].toString()+')');
          }
      }
    }, error: (err){
      onError(context, response: err, popup: true, backOnDismiss: true);
    });

    await Request.get('detail_penjualan/'+id.toString()+'/detail', then: (status, data){
      if(mounted){
        setState(() {
          Map res = decode(data);
          this.loader = false;
          this.detailBarang = res['data'];
        });
      }
    }, error: (err){
      onError(context, response: err, popup: true);
    });
  }

  _confirm(res) async {
    // if(res != null && res == 1){
      // Wh.dialog(context, transparent: true, dismiss: false, child: Wh.spiner(size: 35, color: Colors.white, margin: 15));

      var url = 'penjualan/'+penjualan['id'].toString()+(status == 'waiting' ? '/approve' : '/cancel_approval');

      Request.post(url, then: (s, data) async{
        var invoice = decode(data)['no_invoice'];

        // tandai bahwa ada aktivitas menyetujui penjualan
        setPrefs('hasApproved', true);

        await trackActivity('Menyetujui ('+penjualan['grand_total'].toString()+')');

        Map res = decode(data);
        Wh.toast(res['message']);

        Navigator.pop(context);
        // Wh.toast(status == 'waiting' ? 'Berhasil disetujui' : 'Batal disetujui');

        setState((){
          status = status == 'waiting' ? 'approved' : 'waiting';
          this.widget.dataPenjualan['no_invoice'] = invoice;
          penjualan['no_invoice'] = invoice;
        });
      }, error: (err){
        onError(context, response: err, popup: true, backOnError: true);
      });
    // }
  }

  @override
  void initState() {
    data = widget.dataPenjualan;
    loadData(startPage: true);
    super.initState();
  }

  Future<Null> _onRefresh() async {
    loadData(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    Widget widget = loader ? SizedBox.shrink()
        : detailBarang == null || detailBarang.length == 0
        ? Wh.noData(message: 'Tidak ada data barang\nTap + untuk menambahkan barang.')
        : Column(
          children: <Widget>[
            Expanded(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    child: Column(
                      children: [
                        Column(
                          children: List.generate(detailBarang.length, (i){
                                var data = detailBarang[i];

                                return Material(
                                  color: i % 2 == 0 ? TColor.silver() : Colors.white,
                                  child: InkWell(
                                    onTap: () {
                                      modal(this.widget.ctx, child: RincianBarang(data: data));
                                    },
                                    onLongPress: (){
                                      if(!this.widget.readOnly && status == 'waiting'){
                                        if( data['id_harga'] == '0' ){
                                          Wh.toast('Item promo tidak bisa dirubah');
                                        }else{
                                          // _showOptionBarang(data['id'], json.encode(data) );
                                          Wh.options(context, options: ['Edit Barang','Hapus Barang'], icons: [Ic.edit(), Ic.trash()], then: (res){
                                            Navigator.pop(context);

                                            if(res != null){
                                              switch (res) {
                                                case 0:
                                                  modal(this.widget.ctx, child: FormBarang(this.widget.ctx, idPenjualan: this.widget.dataPenjualan['id'].toString(), initData: data), then: (res){
                                                    if(res != null)
                                                      setState(() {
                                                        if(res['edited']) loader = true; loadData(activity: 'Edit barang');
                                                      });
                                                  }); break;

                                                default: Wh.confirmation(context, message: 'Yakin ingin menghapus barang ini?', confirmText: 'Hapus Barang', then: (res){
                                                  if(res != null && res == 0){
                                                    Navigator.pop(context);
                                                    showDialog(context: context, child: OnProgress(message: 'Menghapus...'));

                                                    Request.delete('detail_penjualan/'+data['id'].toString(), then: (s, body){
                                                      Map res = decode(body);
                                                      Wh.toast(res['message']);
                                                      Navigator.pop(context); loadData(activity: 'Hapus barang');
                                                    }, error: (err){
                                                      onError(context, response: err, popup: true);
                                                    });
                                                  }
                                                });
                                              }
                                            }
                                          });
                                        }
                                      }
                                    },
                                    child: new Container(
                                      padding: EdgeInsets.all(15),
                                      decoration: BoxDecoration(
                                        // border: Border(
                                        //   bottom: BorderSide(
                                        //     width: 1.0, color: Colors.black12),
                                        // ),
                                      ),
                                      child:

                                        Column(
                                          children: <Widget>[
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: <Widget>[
                                                text(data['kode_barang'], bold: true),
                                                Row(
                                                  children: <Widget>[
                                                    text(data['order_qty'].toString()+'/'+data['order_pcs'].toString() ),
                                                    Container(
                                                      margin: EdgeInsets.only(left: 5),
                                                      padding: EdgeInsets.only(left: 5, right: 5, top: 1, bottom: 1),
                                                      decoration: BoxDecoration(
                                                        color: Colors.blueGrey,
                                                        borderRadius: BorderRadius.circular(2)
                                                      ),
                                                      child: text(data['qty'].toString()+'/'+data['qty_pcs'].toString(), color: Colors.white),
                                                    )
                                                  ],
                                                ),
                                              ],
                                            ),

                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: <Widget>[
                                                Flexible(
                                                  child: text(data['nama_barang'])
                                                ),
                                                Container(
                                                  padding: EdgeInsets.only(left: 15),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.end,
                                                    children: <Widget>[
                                                      text('Rp '+ribuan(data['subtotal'].toString())),
                                                    ],
                                                  )
                                                ),
                                              ],
                                            ),

                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: <Widget>[

                                                  data['nama_promo'] == null ? SizedBox.shrink() :
                                                  Expanded(
                                                    child: Row(
                                                      children: <Widget>[
                                                        Icon(Icons.local_offer, size: 9, color: Colors.blue,),
                                                        Expanded(
                                                          child: Container(
                                                            margin: EdgeInsets.only(left: 5),
                                                            child: text(data['nama_promo'],  color: Colors.blue, size: 12),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  data['discount'] == 0 ? SizedBox.shrink() : text('- Rp '+ribuan(data['discount'].toString()), color: Colors.blue, size: 12),
                                                ]
                                            )
                                          ],
                                        )
                                    )
                                  )
                                );
                              })
                        ),
                        SizedBox(height: 60,)
                      ],
                    ),
                  ),
                  loader || this.widget.readOnly || status != 'waiting' && !printPermission ? SizedBox.shrink() : Positioned(
                    bottom: 5,
                    right: 0,
                    child: Container(
                      margin: EdgeInsets.only(bottom: 10, right: 15),
                      child: FloatingActionButton(
                        onPressed: () {
                          if(status != 'waiting'){
                            modal(this.widget.ctx, wrap: true, child: PrintPenjualan(data: penjualan, items: detailBarang), radius: 15);
                          }else{
                            modal(this.widget.ctx, child: FormBarang(this.widget.ctx, idPenjualan: this.widget.dataPenjualan['id'].toString()), then: (res){
                              if(res != null)
                                setState(() {
                                  if(res['added'] == true){
                                    loader = true;
                                    loadData(activity: 'Tambah barang');
                                  }
                                });
                            });
                          }
                        },
                        child: Icon(status != 'waiting' ? Icons.print : Icons.add,),
                        backgroundColor: TColor.azure(),
                      ),
                    ),
                  ),
                ],
              ),
            ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    width: Mquery.width(context),
                    decoration: BoxDecoration(
                      color: Colors.white,
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
                    ),

                    child: Column(
                      children: [
                        Container(
                          padding: EdgeInsets.all(11),
                          decoration: BoxDecoration(
                            border: Border(bottom: BorderSide(color: Colors.black12))
                          ),
                          child: loaderTotal ? text('Sedang memuat...') :
                            new Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: List.generate(3, (int i){
                                var labels = ['Total Qty','Total Pcs','Total Sku'],
                                    values = [penjualan['total_qty'], penjualan['total_pcs'], penjualan['sku']];

                                return Container(
                                  padding: EdgeInsets.only(right: 15),
                                  child: text(labels[i]+' : '+values[i].toString()),
                                );
                              })
                            )
                        ),

                        Container(
                          padding: EdgeInsets.all(11),
                          child: loaderTotal ? text('Sedang memuat...') :
                              Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(child: text(penjualan['total'] == null ? '-' : 'Total : Rp '+ribuan(penjualan['total'].toString()))),
                                      text(penjualan['disc_total'] == null ? '-' : 'Diskon : Rp '+ribuan(penjualan['disc_total'].toString())),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Expanded(child: text(penjualan['ppn'] == null ? '-' : 'PPN : Rp '+ribuan(penjualan['ppn'].toString()))),
                                      text(penjualan['grand_total'] == null ? '-' : 'Grand Total : Rp '+ribuan(penjualan['grand_total'].toString())),
                                    ],
                                  )
                                ],
                              )
                          // new Row(
                          //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          //   mainAxisSize: MainAxisSize.max,
                          //   children: <Widget>[
                          //     Expanded(
                          //       child: Container(
                          //         child: Column(
                          //           crossAxisAlignment: CrossAxisAlignment.start,
                          //           children: <Widget>[
                          //             text(penjualan['total'] == null ? '-' : 'Total : Rp '+ribuan(penjualan['total'].toString())),
                          //             text(penjualan['disc_total'] == null ? '-' : 'Diskon : Rp '+ribuan(penjualan['disc_total'].toString())),
                          //           ],
                          //         ),
                          //       ),
                          //     ),
                          //
                          //     Container(
                          //       child: Column(
                          //         crossAxisAlignment: CrossAxisAlignment.end,
                          //         children: <Widget>[
                          //           text(penjualan['ppn'] == null ? '-' : 'PPN : Rp '+ribuan(penjualan['ppn'].toString())),
                          //           text(penjualan['grand_total'] == null ? '-' : 'Grand Total : Rp '+ribuan(penjualan['grand_total'].toString())),
                          //         ],
                          //       ),
                          //     ),
                          //   ]
                          // )
                        )
                      ]
                    ),
                  ),
                ],
              ),
            ],
        );

    return Scaffold(
      backgroundColor: TColor.silver(),
        appBar: Wh.appBar(context, title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            text(this.widget.dataPenjualan['toko'][0]['nama_toko'], bold: true),
            text(dateFormat(data['tanggal'])+', '+(data['po_manual'] == null || data['po_manual'] == '' ? data['id'].toString() : data['po_manual'])+''+(data['no_invoice'] == null ? '' : ', '+data['no_invoice']), size: 13)
            // text(dateFormat(data['tanggal'])+', '+data['id'].toString()+''+___tipeHarga.toUpperCase()+''+(data['no_invoice'] == null ? '' : ', '+data['no_invoice']+' '+(data['po_manual'] == null ? '-' : ', '+data['po_manual'])), size: 13)
          ],
        ),

          actions: [
            IconButton(
              icon: Icon(Ic.more()),
              onPressed: (){
                var options = ['Detail Penjualan', 'Edit Penjualan', status == 'waiting' ? 'Setujui' : 'Batal Setujui', 'Cetak', 'Pelunasan'],
                    icons = [Ic.info(),Ic.edit(),Ic.check(),Ic.print(),Ic.book()];

                // filter options
                var filter = [];

                if(this.widget.readOnly){ filter = [1,2,3,4]; }
                if(!approvePermission){ filter..addAll([2]); }
                if(status == 'waiting'){ filter..addAll([3,4]); }
                if(status != 'waiting'){ filter..addAll([1,2]); }
                if(!printPermission){ filter..addAll([3]); }

                // options.removeWhere((item) => this.widget.readOnly ? item == 'edit' || item == 'cetak' : printPermission ? item == '' : item == 'cetak');
                // options.removeWhere((item) => approvePermission ? item == '' : item == 'setujui' || item == 'batal setujui');
                // options.removeWhere((item) => status == 'waiting' ? item == 'cetak' || item == 'pelunasan' : item == '');
                // options.removeWhere((item) => status != 'waiting' ? item == 'edit' || item == 'setujui' || item == 'batal setujui' : item == '');

                Wh.options(context, options: options, icons: icons, hide: filter, then: (res){
                  Navigator.pop(context);

                  switch (res) {
                    case 0: // detail
                      modal(this.widget.ctx, child: DetailPenjualan(data: this.widget.dataPenjualan));
                      break;

                    case 1: // edit
                      modal(this.widget.ctx, child: FormPenjualan(this.widget.ctx, initData: this.widget.dataPenjualan));
                      // Navigator.of(context).push(MaterialPageRoute(
                      //     builder: (BuildContext context) => FormPenjualan(this.widget.ctx, initData: this.widget.dataPenjualan))
                      // );
                      break;

                    case 2: // approve/unapprove
                      if(detailBarang.length < 1){
                        Wh.toast('Barang tidak boleh kosong');
                      }else{
                        showDialog(context: context, child: OnProgress(message: 'Menyetujui...',)); _confirm(res);
                      }
                      break;

                    case 3: // print
                      modal(this.widget.ctx, wrap: true, child: PrintPenjualan(data: penjualan, items: detailBarang));
                      break;

                    case 4: // pelunasan
                      showDialog(context: context, child: OnProgress(message: 'Loading...',));

                      Request.get('pelunasan_penjualan/'+data['id'].toString(), then: (s, body){
                        Navigator.pop(context);

                        var dataPelunasan = decode(body)['data'];
                        modal(this.widget.ctx, child: DetailPelunasan(ctx: this.widget.ctx, data: dataPelunasan));
                      }, error: (err){
                        onError(context, response: err, popup: true);
                      });
                      break;
                    default:
                  }
                  // if(res != null){
                  //   switch (res['value']) {
                  //     case 'detail': modal(this.widget.ctx, child: DetailPenjualan(data: this.widget.dataPenjualan), radius: 15); break;
                  //     case 'edit': modal(this.widget.ctx, child: EditPenjualan(data: this.widget.dataPenjualan)); break;
                  //     case 'setujui': Wh.confirmation(context, message: 'Yakin ingin menyetujui penjualan ini?', then: (res){ _confirm(res); }); break;
                  //     case 'batal setujui': Wh.confirmation(context, message: 'Yakin ingin membatalkan menyetujui penjualan ini?', then: (res){ _confirm(res); }); break;
                  //     case 'pelunasan':
                  //       Wh.dialog(context, transparent: true, dismiss: false, child: Wh.spiner(size: 35, color: Colors.white, margin: 15));

                  //       Api.get('pelunasan_penjualan/'+data['id'].toString(), then: (s, body){
                  //         if(s == 200){
                  //           Navigator.pop(context);
                  //           var dataPelunasan = decode(body)['data'];
                  //           modal(this.widget.ctx, child: DetailPelunasan(ctx: this.widget.ctx, data: dataPelunasan));
                  //         }
                  //       }, error: (err){
                  //         // Message.error(err);
                  //       });

                  //     break;
                  //     default: modal(this.widget.ctx, child: PrintPenjualan(data: penjualan, items: detailBarang), radius: 15); break;

                  //     // Wh.dialog(context, slide: 0.25, child: PrepareToPrint(data: penjualan, items: detailBarang)); break;
                  //   }
                  // }
                });
              },
            )
          ]
      ),


      floatingActionButton: loader || this.widget.readOnly || detailBarang.length != 0 || status != 'waiting' && !printPermission ? null : Container(
      // floatingActionButton: Container(
        margin: EdgeInsets.only(bottom: this.detailBarang.length == 0 ? 0 : 43),
        child: FloatingActionButton(
          onPressed: () {
            if(status != 'waiting'){
              modal(this.widget.ctx, wrap: true, child: PrintPenjualan(data: penjualan, items: detailBarang), radius: 15);
            }else{
              modal(this.widget.ctx, child: FormBarang(this.widget.ctx, idPenjualan: this.widget.dataPenjualan['id'].toString()), then: (res){
                if(res != null)
                setState(() {
                  if(res['added'] == true){
                    loader = true;
                    loadData(activity: 'Tambah barang');
                  }
                });
              });
            }
          },
          child: Icon(status != 'waiting' ? Icons.print : Icons.add,),
          backgroundColor: TColor.azure(),
        ),
      ),

      body: new RefreshIndicator(
        onRefresh: _onRefresh,
        child: loader ? ListSkeleton(length: 10) : widget,
      ),
    );
  }
}



class DetailPenjualan extends StatefulWidget {
  final data;
  DetailPenjualan({this.data});

  @override
  _DetailPenjualanState createState() => _DetailPenjualanState();
}

class _DetailPenjualanState extends State<DetailPenjualan>{
  var data = {}, detailPenjualan = [];

  initPrefs() async {
    data = widget.data;

    var prefs = await SharedPreferences.getInstance(),
        epTb = prefs.getString('epTb'), epTh = prefs.getString('epTh'),  epKt = prefs.getString('epKt');

    setState(() {
      detailPenjualan = [
        data['id'].toString(),
        data['no_invoice'] == null ? '-' : data['no_invoice'],
        data['toko'][0]['nama_toko'],
        data['toko'][0]['alamat'],
        data['toko'][0]['no_acc'] == null ? '-' : data['toko'][0]['no_acc'],
        data['toko'][0]['cust_no'] == null ? '-' : data['toko'][0]['cust_no'],
        data['salesman'][0]['nama_salesman'],
        data['salesman'][0]['tim'],
        data['toko'][0]['tipe'],
        epTh == null ? ucword(data['tipe_harga']) : ucword(epTh),

        // ambil tipe pembayaran dari localstorage (jika tidak null), tipe pembayaran (di localstorage) terupdate saat penjualan diperbarui
        epTb == null ? ucword(data['tipe_pembayaran']) : ucword(epTb),
        epKt == null ? data['keterangan'] : epKt,

        data['created_at'],
        data['approved_at'] == null || data['approved_at'] == '' ? '-' : data['approved_at'],
        data['delivered_at'] == null || data['delivered_at'] == '' ? '-' : data['delivered_at'],
      ];
    });
  }

  @override
  void initState() {
    super.initState();
    initPrefs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Wh.appBar(context, title: 'Detail Penjualan', actions: [
        widget.data['latitude'] == null ? SizedBox.shrink() : IconButton(
          icon: Icon(Ic.gps(), color: TColor.azure(), size: 20),
          onPressed: (){
            openMap(double.parse(data['latitude']), double.parse(data['longitude']));
          },
        )
      ]),
      body: Container(
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: detailPenjualan.length,
          itemBuilder: (context, i) {
            var labels = ['no. po','no. invoice','nama toko','alamat','no. acc','cust no','nama salesman','tim','tipe toko','tipe harga','tipe pembayaran','keterangan','diinput','disetujui','dikirim'];

            return Container(
              padding: EdgeInsets.all(15),
              color: i % 2 == 0 ? TColor.silver() : Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  text(ucword(labels[i]), bold: true),
                  text(detailPenjualan[i])
                ],
              ),
            );
          }
        )
      )
    );
  }
}

class RincianBarang extends StatefulWidget {
  RincianBarang({Key key, this.data}) : super(key: key);
  final data;

  @override
  _RincianBarangState createState() => _RincianBarangState();
}

class _RincianBarangState extends State<RincianBarang> {
  var data, title = [
    'Kode Barang','Nama Barang','Jumlah Pesanan','Jumlah Terkirim','Harga','Subtotal','Diskon','Net','Nama Promo','Diinput Pada'
  ];

  var value = [];

  @override
  void initState() {
    super.initState();
    data = widget.data;

    value = [
      data['kode_barang'],
      data['nama_barang'],
      data['order_qty']+' dus / '+data['order_pcs']+' pcs',
      data['qty']+' dus / '+data['qty_pcs']+' pcs',
      'Rp '+ribuan(data['harga_barang'].toString()),
      'Rp '+ribuan(data['subtotal'].toString()),
      'Rp '+ribuan(data['discount'].toString()),
      data['net'] == null ? '-' : 'Rp '+ribuan(data['net'].toString()),
      data['nama_promo'] == null ? '-' : data['nama_promo'],
      data['created_at']
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TColor.silver(),
        appBar: Wh.appBar(context, title: 'Detail Barang', center: true),
        body: ListView.builder(
          shrinkWrap: true,
          itemCount: title.length,
          itemBuilder: (context, i) {
            return new Container(
              color: i % 2 == 0 ? TColor.silver() : Colors.white,
                padding: EdgeInsets.all(15),
                child: new Align(
                  alignment: Alignment.centerLeft,
                  child: new Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      text(title[i], bold: true),
                      text(value[i])
                    ],
                  ),
                )
              );
          }
        )
    );
  }
}

class PrintPenjualan extends StatefulWidget {
  final data, items;
  PrintPenjualan({this.data, this.items});

  @override
  _PrintPenjualanState createState() => _PrintPenjualanState();
}

class _PrintPenjualanState extends State<PrintPenjualan> {
  var printer = TextEditingController();

  BlueThermalPrinter bluetooth = BlueThermalPrinter.instance; Timer timer;
  bool loading = true, isConnected = false, isDeviceConnected = true, isPrint = false, hasPrinted = false;

  List _devices = [];
  List<BluetoothDevice> bDevices = [];

  // cari printer thermal
  findThermalPrinter() async{
    getPrefs('printer').then((res){
      if(res != null){
        printer.text = res;
      }
    });

    setState(() {
      isConnected = false;
      loading = true;
    });

    bluetooth.isOn.then((res) async{
      setState(() {
        isConnected = res;
      });

      if(res){
        _devices = []; bDevices = [];

        try {
          List<BluetoothDevice> devices = await bluetooth.getBondedDevices();
          bDevices = devices;

          devices.forEach((device){
            _devices.add(device.name);
            // if(device.name == 'BlueTooth Printer'){
            //   printer.text = device.name;
            // }
          });

          setState(() {
            loading = false;
          });

        } catch (e) {
          Wh.alert(context, title: 'Bluetooth Error', message: 'Terjadi kesalahan saat menghubungkan ke perangkat Bluetooth Thermal.');
        }
      }
    });
  }

  @override
  void initState() {
    trackActivity('Menampilkan halaman print ('+widget.data['grand_total'].toString()+')');
    super.initState(); findThermalPrinter();

    bluetooth.onStateChanged().listen((state) {
      if(mounted){ //print('# '+state.toString());
        if(state == 11 || state == 12 || state == 1){
          setState(() {
            isConnected = true;
          });

          findThermalPrinter();
        }else{
          setState(() {
            isConnected = false;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    super.dispose(); if(timer != null) timer.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
        children: [

          Container(
            width: Mquery.width(context),
            padding: EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white
            ),
            child:

          !isConnected ? Column(
            children: [

              Container(
                padding: EdgeInsets.all(10), margin: EdgeInsets.only(top: 25, bottom: 25),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black38),
                  borderRadius: BorderRadius.circular(50)
                ),
                child: Icon(Icons.bluetooth_disabled, size: 50, color: Colors.black38)
              ), text('Aktifkan Bluetooth Anda\nAksi ini membutuhkan jaringan Bluetooth', align: TextAlign.center)
            ]
          ) :

          loading ? Container(
            margin: EdgeInsets.only(top: 25, bottom: 25),
            child: Column(
              children: <Widget>[
                Wh.spiner(size: 50, margin: 25),
                text('Mencari perangkat printer')
              ],
            ),
          ) :

          _devices.length == 0 ?
            Container(
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(10), margin: EdgeInsets.only(top: 25, bottom: 25),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black38),
                      borderRadius: BorderRadius.circular(50)
                    ),
                    child: Icon(Icons.print, size: 50, color: Colors.black38)
                  ),

                  Column(
                    children: [
                      text('Tidak ada perangkat printer yang tersedia', bold: true),
                      text('Pilih terlebih dahulu perangkat printer di pengaturan bluetooth, pastikan printer dalam keadaan menyala serta tidak terhubung ke perangkat manapun, kemudian tutup laman ini dan coba buka kembali.', align: TextAlign.center),
                    ]
                  )
                ]
              )
            ) :

          Column(
            children: [
              Container(
                padding: EdgeInsets.only(bottom: 10), width: Mquery.width(context) - 160,
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.black12))
                ),
                child: text('Pilih Perangkat Printer', align: TextAlign.center),
              ),

              Picker(list: _devices, selected: printer.text, isPrint: isPrint, then: (res){
                if(res != null){
                  setPrefs('printer', res); // simpan perangkat yang dipilih

                  timer = Timer(Duration(seconds: 5), (){
                    Navigator.pop(context);
                    Wh.toast('Tidak dapat terhubung ke perangkat manapun');
                  });

                  bDevices.forEach((device){
                    if(device.name == res){
                      bluetooth.isConnected.then((con) {
                        if (!con) {
                          setState(() => isPrint = true );

                          try {
                            bluetooth.connect(device).then((_){
                              timer.cancel(); hasPrinted = true; // print success
                              Print(context: context, data: widget.data, items: widget.items).run();
                            }, onError: (onErr){
                              // Navigator.pop(context, {'error': true});
                            });
                          }on PlatformException catch (_) {
                            // Navigator.pop(context, {'error': true});
                          }
                        }else{
                          timer.cancel();
                          hasPrinted = true; // print success

                          // jalankan printer
                          Print(context: context, data: widget.data, items: widget.items).run();
                        }
                      });
                    }
                  });
                }
              })
            ]
          ),
        )
      ]
    );
  }
}

class Print {
  Print({this.context, this.data, this.items});
  final context, data, items;
  BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;

  run() async {

    getPrefs('cp'+data['no_invoice']).then((res){ //print(data);

      List subtotals = []; // simpan subtotal disini untuk dikirim ke bot telegram

      bluetooth.isConnected.then((isConnected) async{
        if(isConnected){
          bluetooth.printCustom(data['nama_perusahaan'].toString().toUpperCase(),1,1);
          bluetooth.printCustom(data['alamat_depo'],0,1);
          bluetooth.printCustom('Telp.' + data['telp_depo'] + '|Fax.' + data['fax_depo'],0,1);
          bluetooth.printCustom(data['nama_depo'],0,1);

          if(res == null){
            bluetooth.printCustom("------------------------------------------",0,1);
          }else{
            bluetooth.printCustom("--------------------------------------COPY",0,1);
          }

          bluetooth.printLeftRight('PO : '+data['id'].toString(), ' Tgl. '+Dt.dateTime(),0);
          bluetooth.printLeftRight('Invoice : '+data['no_invoice']+' ', data['tipe_pembayaran'].toString().toUpperCase(),0);
          bluetooth.printCustom('Sales : '+data['salesman'][0]['tim']+' - '+data['salesman'][0]['nama_salesman'],0,0);
          bluetooth.printCustom('Cust : '+data['toko'][0]['no_acc']+' - '+data['toko'][0]['nama_toko'],0,0);
          bluetooth.printCustom('Alamat : '+data['toko'][0]['alamat'], 0,0);
          bluetooth.printCustom("------------------------------------------",0,1);

          for (var i = 0; i < items.length; i++) {
            var item = items[i], knb = item['kode_barang']+' - '+item['nama_barang'],

            nb = knb.length > 42 ? knb.substring(0, 42) : knb,
            qty = item['qty'] == '0' ? '' : item['qty'].toString()+' crt ',
            pcs = item['qty_pcs'] == '0' ? '' : item['qty_pcs'].toString()+' '+item['satuan'];

            if(qty != '' || pcs != ''){
              bluetooth.printCustom(nb,0,0);
              bluetooth.printLeftRight(qty+''+pcs, ribuan(item['price_after_tax'].toString())+'         '+ribuan(item['subtotal_after_tax'].toString()), 0);
              if(item['discount'] != 0){
                bluetooth.printCustom('Disc - '+ribuan(item['discount'].toString()),0,2);
              }
              subtotals.add(item['subtotal_after_tax']);
            }
          }

          // jumlahkan grand total di client side
          var __grandT = ((subtotals.reduce((a, b) => a + b) / 1.1) - data['disc_total']) * 1.1;

          bluetooth.printCustom("------------------------------------------",0,1);

          bluetooth.printLeftRight('Total : ', ribuan(data['total_after_tax'].toString()), 0);
          bluetooth.printLeftRight('Total Diskon : ', ribuan(data['disc_total'].toString()), 0);
          // bluetooth.printLeftRight('PPN : ', ribuan(data['ppn'].toString()), 0);
          bluetooth.printLeftRight('Grand Total : ', ribuan(data['grand_total'].toString(), fixed: 0), 0);

          bluetooth.printNewLine();
          bluetooth.printCustom('Harga sudah termasuk PPN',0,1);
          bluetooth.printCustom('--== Terima Kasih ==--',0,1);
          bluetooth.printNewLine();
          bluetooth.printNewLine();
          bluetooth.printNewLine();
          bluetooth.paperCut();

          await trackActivity('Melakukan print ('+data['grand_total'].toString()+')');

          setPrefs('cp'+data['no_invoice'], data['no_invoice']);

          // get all activities
          var activities = await LocalData.get('activities');
          print(activities);
          print(activities.runtimeType);

          // kirim data yang dicetak ke ke telegram

          String message = "#Print"+(res == null ? '' : ' (COPY)')+", Invoice: "+data['no_invoice'].toString()+", Subtotal: "+subtotals.toString()+", GrandTotal (BE): "+data['grand_total'].toString()+", GrandTotal (FE): "+ribuan(__grandT.round().toString(), fixed: 0).toString()+', --> AKTIVITAS '+activities.toString();

          var bot = TelegramBot.init("1253058966:AAH0_mP2-Z3z47f5KKx89GbtYZjFykuOgpM");
          bot.sendMessage(chatId: "-467075398", text: message).then((Message messageResult){
            // got result
            // print(messageResult);
          }).catchError((error){
            // handle error
            print(error);
          });

          Navigator.pop(context);
        }else{
          Wh.alert(context, title: 'Opps!', message: 'Tidak dapat terhubung ke printer! Periksa dan pastikan printer tidak sedang terhubung ke ponsel manapun.');
          Navigator.pop(context);
        }
      });

    });
  }
}