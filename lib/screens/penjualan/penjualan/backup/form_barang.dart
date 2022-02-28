import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sales/services/helper.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

class FormBarang extends StatefulWidget {
  final ctx, idPenjualan, formData;
  FormBarang({this.ctx, this.idPenjualan, this.formData});
  _TambahBarangState createState() => _TambahBarangState();
}

class _TambahBarangState extends State<FormBarang> {
  var namaBarang = TextEditingController(),
      qty = new TextEditingController(),
      qtyPcs = new TextEditingController(),
      namaPromo = TextEditingController();

  var qtyNode = FocusNode(), qtyPcsNode = FocusNode();

  var tipeHarga = '', dataBarang = [], dataPromo = [];
  int idStock = 0,
      idPromo = 0,
      idHarga = 0,
      lQty = 0,
      lQtyPcs = 2,
      indexBarang; // index barang untuk menghapus array barang
  bool loaderBarang = true, loaderPromo = true, isSave = false;

  @override
  void initState() {
    super.initState();
    initForms();
  }

  initForms() {
    var _ = widget.formData;
    if (_ != null) {
      namaBarang.text = _['nama_barang'];
      qty.text = _['qty'].toString();
      qtyPcs.text = _['qty_pcs'].toString();
      namaPromo.text = _['nama_promo'];

      idStock = int.parse(_['id_stock']);
      idHarga = int.parse(_['id_harga']);
      idPromo = int.parse(_['id_promo']);
    }
  }

  void saveBarang() async {
    if (idStock == 0 ||
        qty.text == '' && qtyPcs.text == '' ||
        qty.text == '0' && qtyPcs.text == '0') {
      Wi.toast('Lengkapi Form');
    } else {
      var data = {
        'id_penjualan': widget.idPenjualan,
        'id_stock': idStock.toString(),
        'qty': qty.text == '' ? '0' : qty.text.toString(),
        'qty_pcs': qtyPcs.text == '' ? '0' : qtyPcs.text.toString(),
        'id_harga': idHarga.toString(),
        'id_promo': idPromo.toString()
      };
      setState(() {
        isSave = true;
      });

      if (widget.formData == null) {
        Api.post('detail_penjualan', formData: data, then: (s, data) {
          Map res = decode(data);

          if (s == 201) {
            // Firestore.instance
            //     .collection('trigger_sales')
            //     .document('barang')
            //     .updateData({'trigger': timestamp().toString()});
            Navigator.of(context).pop({'added': true});
          } else {
            Wi.toast(res['message']);
          }

          setState(() {
            isSave = false;
          });
        }, error: (err) {
          setState(() {
            isSave = false;
          });
          Message.error(err);
        });
      } else {
        print(data);

        Api.put('detail_penjualan/' + widget.formData['id'].toString(),
            formData: data, then: (s, data) {
          Map res = decode(data);

          if (s == 201) {
            // Firestore.instance.collection('trigger_sales').document('barang').updateData({ 'trigger': timestamp().toString() });
            Navigator.of(context).pop({'edited': true});
          } else {
            Wi.toast(res['message']);
          }

          setState(() {
            isSave = false;
          });
        }, error: (err) {
          setState(() {
            isSave = false;
          });
          Message.error(err);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Unfocus(
      child: Scaffold(
        appBar: Wi.appBar(context,
            title: widget.formData == null ? 'Tambah Barang' : 'Edit Barang'),
        body: PreventScrollGlow(
            child: SingleChildScrollView(
          padding: EdgeInsets.all(15),
          child: Column(children: [
            FormControl.select(context,
                label: 'Pilih Barang',
                enabled: widget.formData != null ? false : true,
                controller: namaBarang, onTap: () {
              modal(widget.ctx,
                  child: ListBarang(idPenjualan: widget.idPenjualan),
                  then: (res) {
                if (res != null) {
                  setState(() {
                    namaBarang.text = res['barang'];
                    idStock = res['id'];
                    indexBarang = res['index'];
                  });
                }
              });
            }),
            FormControl.number(
                label: 'Qty',
                node: qtyNode,
                controller: qty,
                onChange: (String n) {
                  setState(() => qty.text = n);
                }),
            FormControl.number(
                label: 'Qty Pcs',
                node: qtyPcsNode,
                controller: qtyPcs,
                onChange: (String n) {
                  setState(() => qtyPcs.text = n);
                }),
            FormControl.select(context,
                label: 'Pilih Promo',
                mb: namaPromo.text.isEmpty ? 25 : 0,
                controller: namaPromo, onTap: () {
              modal(widget.ctx, child: ListPromo(), then: (res) {
                if (res != null) {
                  setState(() {
                    namaPromo.text = res['promo'];
                    idPromo = res['id'];
                  });
                }
              });
            }),
            namaPromo.text.isEmpty
                ? SizedBox.shrink()
                : Container(
                    width: Mquery.width(context),
                    padding: EdgeInsets.all(10),
                    margin: EdgeInsets.only(bottom: 0),
                    child: GestureDetector(
                      child: text('Hapus promo',
                          align: TextAlign.right, color: Colors.red),
                      onTap: () {
                        setState(() => namaPromo.clear());
                        idPromo = 0;
                      },
                    ),
                  ),
            FormControl.button(
                textButton: 'Simpan',
                isSubmit: isSave,
                onTap: () {
                  saveBarang();
                })
          ]),
        )),
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
    setState(() => loading = true);

    timer = setTimer(1, then: (t) {
      request({Function then}) {
        Api.get('detail_penjualan/list/barang', then: (s, data) {
          if (s == 200) {
            var res = decode(data);
            then(res['data']);
          }
        }, error: (err) {
          Message.error(err);
        });
      }

      if (refill) {
        request(then: (val) {
          setPrefs('barang', encode(val));
          setState(() {
            dataFiltered = dataBarang = val;
            loading = false;
          });
        });
      } else {
        getPrefs('barang', dec: true).then((res) {
          setState(() {
            dataBarang = dataFiltered = res;
            loading = false;
          });
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    this.loadDataBarang();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        focus(context, FocusNode());
      },
      child: Scaffold(
        appBar: Wi.appBar(context,
            title: FormControl.search(
                hint: 'Ketik kode atau nama barang',
                autofocus: true,
                onChange: (String s) {
                  var k = s.toLowerCase();
                  setState(() {
                    dataFiltered = dataBarang
                        .where((item) =>
                            item['nama_barang'].toLowerCase().contains(k) ||
                            item['kode_barang'].toLowerCase().contains(k))
                        .toList();
                  });
                }),
            actions: [
              IconButton(
                icon: Icon(Icons.refresh,
                    color: loading ? Colors.black26 : Colors.black54),
                onPressed: loading
                    ? null
                    : () {
                        loadDataBarang(refill: true);
                      },
              )
            ]),
        body: loading
            ? Wi.spiner(size: 50)
            : new Container(
                color: Colors.white,
                child:
                    this.dataFiltered == null || this.dataFiltered.length == 0
                        ? Wi.noData(message: 'Tidak ada data barang')
                        : new ListView.builder(
                            itemCount: this.dataFiltered.length,
                            itemBuilder: (context, i) {
                              var data = dataFiltered[i];

                              return new GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).pop({
                                      'barang': data['kode_barang'] +
                                          ' - ' +
                                          data['nama_barang'],
                                      'id': data['id'],
                                      'qtyAvailable': data['qty_available'],
                                      'index': i
                                    });
                                  },
                                  child: new Container(
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                            width: 1.0, color: Colors.black12),
                                      ),
                                    ),
                                    child: new Column(
                                      children: <Widget>[
                                        new Container(
                                            color: i % 2 == 0
                                                ? Color.fromRGBO(0, 0, 0, 0.05)
                                                : Colors.white,
                                            padding: EdgeInsets.all(15),
                                            child: new Align(
                                              alignment: Alignment.centerLeft,
                                              child: new Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: <Widget>[
                                                  text(
                                                    data['kode_barang'] +
                                                        ' - ' +
                                                        data['nama_barang'],
                                                  ),
                                                ],
                                              ),
                                            ))
                                      ],
                                    ),
                                  ));
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
    setState(() => loading = true);

    request({Function then}) {
      Api.get('promo', then: (s, data) {
        if (s == 200) {
          var res = decode(data);
          then(res['data']);
        }
      }, error: (err) {
        Message.error(err);
      });
    }

    if (refill == true) {
      checkConnection().then((con) {
        if (con) {
          request(then: (val) {
            setPrefs('promo', encode(val));
            setState(() {
              dataFiltered = dataPromo = val;
              loading = false;
            });
          });
        } else {
          Wi.box(context, title: 'Periksa koneksi internet Anda');
        }
      });
    } else {
      getPrefs('promo', dec: true).then((res) {
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
      appBar: Wi.appBar(context,
          title: FormControl.search(
              hint: 'Ketik nama promo',
              autofocus: true,
              onChange: (String s) {
                var k = s.toLowerCase();
                setState(() {
                  dataFiltered = dataPromo
                      .where((item) =>
                          item['nama_promo'].toLowerCase().contains(k))
                      .toList();
                });
              }),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh,
                  color: loading ? Colors.black26 : Colors.black54),
              onPressed: loading
                  ? null
                  : () {
                      loadDataPromo(refill: true);
                    },
            )
          ]),
      body: loading
          ? Wi.spiner(size: 50)
          : new Container(
              color: Colors.white,
              child: this.dataFiltered.length == 0
                  ? Align(
                      alignment: Alignment.center,
                      child: Container(
                        child: text('Tidak ada promo'),
                      ))
                  : new ListView.builder(
                      itemCount: this.dataFiltered.length,
                      itemBuilder: (context, i) {
                        var data = dataFiltered[i];

                        return new GestureDetector(
                            onTap: () {
                              Navigator.of(context).pop({
                                'promo': data['nama_promo'],
                                'id': data['id']
                              });
                            },
                            child: new Container(
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                      width: 1.0, color: Colors.black12),
                                ),
                              ),
                              child: new Column(
                                children: <Widget>[
                                  new Container(
                                      color: i % 2 == 0
                                          ? Color.fromRGBO(0, 0, 0, 0.05)
                                          : Colors.white,
                                      padding: EdgeInsets.all(15),
                                      child: new Align(
                                        alignment: Alignment.centerLeft,
                                        child: new Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: <Widget>[
                                            text(
                                              data['nama_promo'],
                                            ),
                                          ],
                                        ),
                                      ))
                                ],
                              ),
                            ));
                      },
                    ),
            ),
    );
  }
}
// 575
