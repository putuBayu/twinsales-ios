import 'dart:async';
import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sales/services/api/api.dart';
import 'package:sales/services/v2/helper.dart';
import 'package:sales/services/v3/helper.dart';

class FormBarang extends StatefulWidget {
  final ctx, idPenjualan, initData;
  FormBarang(this.ctx, {this.idPenjualan, this.initData});
  _TambahBarangState createState() => _TambahBarangState();
}

class _TambahBarangState extends State<FormBarang> {

  Timer pingLooper;

  var barang = TextEditingController(),
      qty = new TextEditingController(text: '0'),
      qtyPcs = new TextEditingController(text: '0'),
      promo = TextEditingController();

  var qtyNode = FocusNode(),
      qtyPcsNode = FocusNode();

  var tipeHarga = '',
      dataBarang = [],
      dataPromo = [],
      dataStock;

  int idStock = 0,
      idPromo = 0,
      idHarga,
      lQty = 0,
      lQtyPcs = 2,
      indexBarang; // index barang untuk menghapus array barang

  bool loaderBarang = true,
      loaderPromo = true,
      loaderInfo = false,
      isSubmit = false;

  getInfoStock()async{
    setState(() {
      loaderInfo = true;
    });
    await Request.get('stock/sisa/' + idStock.toString(), then: (status, body){
      if(mounted){
        Map res = decode(body);

        setState(() {
          dataStock = res;
          loaderInfo = false;
        });

        return res;
      }
    }, error: (err){
      setState(() { loaderInfo = false; });
      onError(context, response: err);
    });
  }

  @override
  void initState(){
    super.initState();
    initForms();

    DateTime start = DateTime.now();
    pingLooper = Timer.periodic(Duration(seconds: 5), (Timer t) {
      setState(() {
        CheckPing().intConnection();
        CheckPing().getPingMs(start);
      });
    });
  }

  @override
  void dispose(){
    if(this.mounted){
      pingLooper.cancel();
    }
    super.dispose();
  }

  initForms(){
    var _ = widget.initData;
    if(_ != null){
      barang.text = _['nama_barang'];
      qty.text = _['qty'].toString();
      qtyPcs.text = _['qty_pcs'].toString();
      promo.text = _['nama_promo'];

      idStock = int.parse(_['id_stock']);
      idHarga = null;
      idPromo = int.parse(_['id_promo']);
      getInfoStock();
    }
  }

  void submit() async {
    if( idStock == 0 || qty.text == '' && qtyPcs.text == '' || qty.text == '0' && qtyPcs.text == '0' ){
      Wh.toast('Lengkapi Form');
    }else{
      var data = {
        'id_penjualan': widget.idPenjualan,
        'id_stock': idStock.toString(),
        'qty': qty.text == '' ? '0' : qty.text.toString() ,
        'qty_pcs': qtyPcs.text == '' ? '0' : qtyPcs.text.toString(),
        'id_harga': '', 'id_promo': idPromo.toString()
      };
      setState(() { isSubmit = true; });
      pingLooper.cancel();
      if(widget.initData == null){
        Request.post('detail_penjualan', formData: data, then: (status, data){
          Map res = decode(data);
          Wh.toast(res['message']);
          // Firestore.instance.collection('trigger_sales').document('barang').updateData({ 'trigger': timestamp().toString() });
          Navigator.of(context).pop({'added': true});
          setState(() { isSubmit = false; });
        }, error: (err){
          setState(() { isSubmit = false; });
          onError(context, response: err, popup: true);
        });

      }else{
        Request.put('detail_penjualan/'+widget.initData['id'].toString(), formData: data, then: (status, data){
          Map res = decode(data);
          Wh.toast(res['message']);
          Navigator.of(context).pop({'edited': true});
          setState(() { isSubmit = false; });
        }, error: (err){
          setState(() { isSubmit = false; });
          onError(context, response: err, popup: true);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Unfocus(
      child: Scaffold(
        appBar: Wh.appBar(context, title: widget.initData == null ? 'Tambah Barang' : 'Edit Barang', center: true,
          actions:[
            Padding(
              padding: const EdgeInsets.only(right: 10.0),
              child: pingStyle(CheckPing().getTimeRespond()),
            ),
          ],
        ),
        body: PreventScrollGlow(
          child: Column(
            children: <Widget>[
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SelectInput(
                        label: 'Pilih Barang',
                        hint: 'Pilih barang',
                        enabled: widget.initData == null ? true : false,
                        space: 10,
                        controller: barang,
                        select: (){
                          modal(widget.ctx, child: ListBarang(idPenjualan: widget.idPenjualan), then: (res){
                            print(res.toString());
                            if(res != null){
                              setState(() {
                                barang.text = res['barang'];
                                idStock = res['id'];
                                indexBarang = res['index'];
                              });
                              getInfoStock();
                            }
                          });
                        }
                      ),

                      // SelectInput(
                      //   label: 'Info Stok',
                      //   hint: 'Pilih barang',
                      //   enabled: widget.initData == null ? true : false,
                      //   space: 10,
                      //   controller: barang,
                      //   select: (){
                      //
                      //   },
                      //   flexibleSpace: Row(
                      //     children: [
                      //       Expanded(
                      //         child: text('Buffer : 0/0', size: 13, color: Colors.black, align: TextAlign.center),
                      //       ),
                      //       Expanded(
                      //         child: text('Waiting : 0/0', size: 13, color: Colors.black, align: TextAlign.center),
                      //       ),
                      //       Expanded(
                      //         child: text('Sisa : 0/0', size: 13, color: Colors.black, align: TextAlign.center),
                      //       ),
                      //     ],
                      //   ),
                      // ),

                      // loaderInfo || dataStock == null ? SizedBox.shrink() : Container(
                      //   child: text('Info Stok: ', size: 13, color: Colors.black),
                      // ),
                      dataStock == null ? SizedBox.shrink() : loaderInfo ? ListSkeleton(length: 1,) : Container(
                        child: Row(
                          children: [
                            SizedBox(width: 10,),
                            Expanded(
                              child: text('Buffer : ' + dataStock['qty_buffer'].toString() + '/' + dataStock['pcs_buffer'].toString(), size: 13, color: Colors.black, align: TextAlign.center),
                            ),
                            Expanded(
                              child: text('Waiting : ' + dataStock['qty_waiting'].toString() + '/' + dataStock['pcs_waiting'].toString(), size: 13, color: Colors.black, align: TextAlign.center),
                            ),
                            Expanded(
                              child: text('Sisa : ' + dataStock['qty_sisa'].toString() + '/' + dataStock['pcs_sisa'].toString(), size: 13, color: Colors.black, align: TextAlign.center),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 15,),

                      InputNumber(
                        label: 'Qty',
                        hint: 'Jumlah qty',
                        controller: qty,
                        length: 11,
                      ),

                      InputNumber(
                        label: 'Qty Pcs',
                        hint: 'Jumlah pcs',
                        controller: qtyPcs,
                        length: 11,
                      ),

                      SelectInput(label: 'Promo', hint: 'Promo', controller: promo, select: (){
                        modal(widget.ctx, child: ListPromo(), then: (res){
                          if(res != null){
                            if(res['remove_promo'] != null){
                              setState(() => promo.clear());
                              idPromo = 0;
                            }else{
                              setState(() {
                                promo.text = res['promo'];
                                idPromo = res['id'];
                              });
                            }
                          }
                        });
                      }),

                      // SelectInput(label: 'Promo Off Faktur', hint: 'Promo Off Faktur', controller: promo, select: (){
                      //   modal(widget.ctx, child: ListPromo(), then: (res){
                      //     if(res != null){
                      //       if(res['remove_promo'] != null){
                      //         setState(() => promo.clear());
                      //         idPromo = 0;
                      //       }else{
                      //         setState(() {
                      //           promo.text = res['promo'];
                      //           idPromo = res['id'];
                      //         });
                      //       }
                      //     }
                      //   });
                      // }),

                      // FormControl.select(context, label: 'Pilih Barang', enabled: widget.initData != null ? false : true, controller: barang, onTap: (){
                      //   modal(widget.ctx, child: ListBarang(idPenjualan: widget.idPenjualan), then: (res){
                      //     if(res != null){
                      //       setState(() {
                      //         barang.text = res['barang'];
                      //         idStock = res['id'];
                      //         indexBarang = res['index'];
                      //       });
                      //     }
                      //   });
                      // }),

                      // FormControl.number(label: 'Qty', node: qtyNode, controller: qty, onChange: (String n){
                      //   setState(() => qty.text = n);
                      // }),

                      // FormControl.number(label: 'Qty Pcs', node: qtyPcsNode, controller: qtyPcs, onChange: (String n){
                      //   setState(() => qtyPcs.text = n);
                      // }),

                      // FormControl.select(context, label: 'Pilih Promo', mb: promo.text.isEmpty ? 25 : 0, controller: promo, onTap: (){
                      //   modal(widget.ctx, child: ListPromo(), then: (res){
                      //     if(res != null){
                      //       setState(() {
                      //         promo.text = res['promo'];
                      //         idPromo = res['id'];
                      //       });
                      //     }
                      //   });
                      // }),

                      // promo.text.isEmpty ? SizedBox.shrink() : Container(
                      //   width: Mquery.width(context),
                      //   padding: EdgeInsets.all(10), margin: EdgeInsets.only(bottom: 0),
                      //   child: GestureDetector(
                      //     child: text('Hapus promo', align: TextAlign.right, color: Colors.red),
                      //     onTap: (){
                      //       setState(() => promo.clear());
                      //       idPromo = 0;
                      //     },
                      //   ),
                      // ),

                      // FormControl.button(textButton: 'Simpan', isSubmit: isSubmit, onTap: (){
                      //   saveBarang();
                      // })
                    ]
                  ),
                ),
              ),

              WhiteShadow(
                child: Button(
                  text: 'Simpan',
                  onTap: submit,
                  isSubmit: isSubmit,
                ),
              )
            ],
          )
        ),
      ),
    );
  }
}

// LIST BARANG
class ListBarang extends StatefulWidget {
  ListBarang({Key key, this.idPenjualan}) : super(key: key);
  final idPenjualan;
  _ListBarangState createState() => _ListBarangState();
}

class _ListBarangState extends State<ListBarang> {
  Timer timer;

  var dataBarang = [], dataFiltered = [], loading = false;

  loadDataBarang({refill: false}) async {

    request({Function then}){
      Request.get('detail_penjualan/list/barang', then: (s, data){
        var res = decode(data);
        then(res['data']);
      }, error: (err){
        onError(context, response: err, popup: true);
      });
    }

    if(refill){
      setState(() => loading = true );

      request(then: (val){
        setPrefs('barang', encode(val));
        setState(() {
          dataFiltered = dataBarang = val;
          loading = false;
        });
      });
    }else{
      getPrefs('barang', dec: true).then((res){
        if(res != null)
        setState(() {
          dataBarang = dataFiltered = res;
          loading = false;
        });
      });
    }
  }

  @override
  void initState() {
    super.initState();
    this.loadDataBarang();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_){ focus(context, FocusNode()); },
      child: Scaffold(
        appBar: Wh.appBar(context, title: Fc.search(hint: 'Ketik kode atau nama barang', autofocus: dataFiltered.length > 0, change: (String s){
          var k = s.toLowerCase();
          setState((){
            dataFiltered = dataBarang.where((item) => item['nama_barang'].toLowerCase().contains(k) || item['kode_barang'].toLowerCase().contains(k)).toList();
          });
        }), actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: loading ? Colors.black26 : Colors.black54),
            onPressed: loading ? null : (){ loadDataBarang(refill: true); },
          )
        ]),

        body: loading ? ListSkeleton(length: 10) :
         new Container(
          color: Colors.white,
          child: this.dataFiltered == null || this.dataFiltered.length == 0
              ? Wh.noData(message: 'Tidak ada data barang\nCoba refresh atau dengan kata kunci lain.')
              : new ListView.builder(
            itemCount: this.dataFiltered.length,
            itemBuilder: (context, i) {
              var data = dataFiltered[i];

              return new GestureDetector(
                onTap: () { 
                  Navigator.of(context).pop({'barang': data['kode_barang']+' - '+data['nama_barang'], 'id': data['id'], 'qtyAvailable': data['qty_available'], 'index': i});
                },
                child: new Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(width: 1.0, color: Colors.black12),
                    ),
                  ),
                  child: new Column(
                    children: <Widget>[ 
                      new Container(
                        color: i % 2 == 0 ? Color.fromRGBO(0, 0, 0, 0.05) : Colors.white,
                          padding: EdgeInsets.all(15),
                          child: new Align(
                            alignment: Alignment.centerLeft,
                            child: new Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Row(
                                  children: [
                                    Expanded(
                                      child: text(data['kode_barang'], bold: true),
                                    ),
                                    data['tipe'] == null ? SizedBox.shrink() : WidSplash(
                                      padding: EdgeInsets.only(left: 10, right: 10),
                                      color: data['tipe'].toString().toLowerCase() == 'exist' ? TColor.red()
                                          : data['tipe'].toString().toLowerCase() == 'non_exist' ? TColor.green()
                                          : TColor.blueLight(),
                                      radius: BorderRadius.circular(2),
                                      child: text(data['tipe'], color: Colors.white),
                                    )
                                  ],
                                ),
                                SizedBox(height: 5,),
                                text(data['nama_barang']),
                              ],
                            ),
                          )
                      )
                    ],
                  ),
                )
              );
            },
          ),
        ),
      ),
    );
  }
}

// LIST PROMO
class ListPromo extends StatefulWidget {
  _ListPromoState createState() => _ListPromoState();
}

class _ListPromoState extends State<ListPromo> {
  var dataPromo = [], dataFiltered = [], loading = false;

  loadDataPromo({refill: false}) async {
    setState(() => loading = true );

    request({Function then}){
      Request.get('promo', then: (s, data){
        if(s == 200){
          var res = decode(data);
          then(res['data']);
        }
      }, error: (err){
        onError(context, response: err, popup: true);
      });
    }

    if(refill == true){
      checkConnection().then((con){
        if(con){
          request(then: (val){
            setPrefs('promo', encode(val));
            setState(() {
              dataFiltered = dataPromo = val;
              loading = false;
            });
          });
        }else{
          Wh.alert(context, title: 'Periksa koneksi internet Anda');
        }
      });
    }else{
      getPrefs('promo', dec: true).then((res){
        setState(() {
          dataPromo = dataFiltered = res;
          loading = false;
        });
      });
    }
  }

  @override
  void initState() {
    super.initState();
    this.loadDataPromo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Wh.appBar(context, title: Fc.search(hint: 'Ketik nama promo', autofocus: true, change: (String s){
        var k = s.toLowerCase();
        setState((){
          dataFiltered = dataPromo.where((item) => item['nama_promo'].toLowerCase().contains(k) ).toList();
        });
      }), actions: [
        IconButton(
          icon: Icon(Ic.refresh(), size: 20, color: loading ? Colors.black26 : Colors.black54),
          onPressed: loading ? null : (){ loadDataPromo(refill: true); },
        ),
        IconButton(
          icon: Icon(Ic.trash(), size: 20, color: loading ? Colors.black26 : Colors.red),
          onPressed: loading ? null : (){
            Navigator.pop(context, {'remove_promo': true});
          },
        )
      ]),

      body: loading ? ListSkeleton(length: 10) : new Container(
        color: Colors.white,
        child: this.dataFiltered.length == 0 ? Align(
            alignment: Alignment.center,
            child: Container(
              child: text('Tidak ada promo'),
            )
          )
        : new ListView.builder(
          itemCount: this.dataFiltered.length,
          itemBuilder: (context, i) {
            var data = dataFiltered[i];
            return new GestureDetector(
                onTap: () { 
                  Navigator.of(context).pop({'promo': data['nama_promo'], 'id': data['id']});
                },
                child: new Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(width: 1.0, color: Colors.black12 ),
                    ),
                  ),
                  child: new Column(
                    children: <Widget>[ 
                      new Container(
                        color: i % 2 == 0 ? Color.fromRGBO(0, 0, 0, 0.05) : Colors.white,
                          padding: EdgeInsets.all(15),
                          child: new Align(
                            alignment: Alignment.centerLeft,
                            child: new Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                text(data['nama_promo']),
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
    );
  }
}
// 575