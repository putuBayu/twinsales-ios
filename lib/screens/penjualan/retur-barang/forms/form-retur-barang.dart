import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sales/services/api/api.dart';
import 'package:sales/services/v2/helper.dart';
import 'package:sales/services/v3/helper.dart';

class FormReturBarang extends StatefulWidget {
  FormReturBarang({this.ctx, this.idRP, this.formData, this.tipeRetur});
  final ctx, idRP, formData, tipeRetur;

  @override
  _FormReturBarangState createState() => _FormReturBarangState();
}

class _FormReturBarangState extends State<FormReturBarang> {

  var idBarang = 0, isSubmit = false,
      barang = TextEditingController(),
      kategori = TextEditingController(),
      qtyPcs = TextEditingController(),
      qtyDus = TextEditingController(),
      disPercent = TextEditingController(),
      disNominal = TextEditingController(),
      dateExp = TextEditingController(text: Dt.ymd);

  // var bsRadio = [''];
  var  dataJenisRetur;
  bool loading = true;

  Timer pingLooper;

  submit(){
    if(barang.text.isEmpty || kategori.text.isEmpty || dateExp.text.isEmpty){
      Wh.toast('Lengkapi form');
    }else{
      if(qtyPcs.text == '0' && qtyDus.text == '0'){
        Wh.toast('Jumlah dus atau pcs harus diisi');
      }else{
        setState(() {
          isSubmit = true;
        });
        pingLooper.cancel();
        var formData = {
          'id_retur_penjualan': widget.idRP.toString(),
          'id_barang': idBarang.toString(),
          'kategori_bs': kategori.text,
          'expired_date': dateExp.text,
          'qty_dus': qtyDus.text,
          'qty_pcs': qtyPcs.text,
          'disc_persen': disPercent.text,
          'disc_nominal': disNominal.text,
        };

        if(widget.formData == null){
          Request.post('detail_retur_penjualan', formData: formData, then: (status, data){
            Map res = decode(data);
            Wh.toast(res['message']);
            Navigator.pop(context, {'added': true});
          }, error: (err){
            setState(() => isSubmit = false );
            onError(context, response: err, popup: true);
          });
        }else{
          Request.put('detail_retur_penjualan/'+widget.formData['id'].toString(), formData: formData, then: (status, data){
            Map res = decode(data);
            Wh.toast(res['message']);
            Navigator.pop(context, {'updated': true});
          }, error: (err){
            setState(() => isSubmit = false );
            onError(context, response: err, popup: true);
          });
        }
      }
    }
  }

  getJenisRetur(){
    setState(() {
      loading = true;
    });
    Request.get('/options/get/list?code=jenis_retur_barang', then: (status, body){
      if(mounted){
        var res = decode(body);

        setState(() {
          dataJenisRetur = res['data'];
          if(widget.formData == null){
            kategori.text = widget.tipeRetur == 'baik' ? 'rb' : dataJenisRetur[0]['value'];
          }
        });

        initForm();
        loading = false;

        // kunjunganController = new TabController(length: dataKunjungan.length, vsync: this);
        // kunjunganController.addListener(() {TColor.azure();});

        // setState(() {
        //   kunjunganController.index = dataKunjungan.length-1;
        // });

        return res;
      }
    }, error: (err){
      setState(() { loading = false; });
      onError(context, response: err);
    });
  }

  initForm(){
    // kategori.text = widget.tipeRetur == 'baik' ? 'rb' : 'kd';
    // if(widget.tipeRetur == 'kategori'){
    //   bsRadio = ['kd','tk','kp'];
    // }else{
    //   bsRadio = ['kd','tk','kp','rb'];
    // }

    if(widget.formData != null){
      var d = widget.formData;

      setState(() {
        idBarang = int.parse(d['id_barang']);
        barang.text = d['nama_barang'];
        dateExp.text = d['expired_date'];
        qtyPcs.text = d['qty_pcs'].toString();
        qtyDus.text = d['qty_dus'].toString();
        disPercent.text = d['disc_persen'].toString();
        disNominal.text = d['disc_nominal'].toString();
        if(widget.tipeRetur == 'baik'){
          kategori.text = 'rb';
        }else{
          kategori.text = d['kategori_bs'];
        }
      });
    }else{
      qtyDus.text = '0';
      qtyPcs.text = '0';
      disPercent.text = '0';
      disNominal.text = '0';
    }
  }

  @override
  void initState() {
    super.initState();
    getJenisRetur();
    print(widget.tipeRetur);

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Wh.appBar(context, title: widget.formData == null ? 'Tambah Barang' : 'Edit Barang', center: true,
        actions:[
          Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: pingStyle(CheckPing().getTimeRespond()),
          ),
        ],
      ),
      body: loading ? ListSkeleton(length: 10,) : PreventScrollGlow(
        child: Column(
          children: <Widget>[
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    SelectInput(label: 'Pilih Barang', hint: 'Pilih barang', controller: barang, select: (){
                      modal(widget.ctx, child: ListBarang(), then: (res){
                        if(res != null){
                          setState(() {
                            idBarang = res['idBarang'];
                            barang.text = res['barang'];
                          });
                        }
                      });
                    }),

                    // widget.tipeRetur == 'baik' ? SizedBox.shrink() : SelectGroup(
                    //   label: 'Kategori BS',
                    //   controller: kategori,
                    //   options: bsRadio, labelsUppercase: true,
                    // ),
                    widget.tipeRetur == 'baik' ? SizedBox.shrink() : Container(
                      child: text('Tipe Retur', bold: true),
                    ),

                    widget.tipeRetur == 'baik' ? SizedBox.shrink() : WidSplash(
                      child: Container(
                        margin: EdgeInsets.only(bottom: 15),
                        child: Wrap(
                          children: List.generate(dataJenisRetur.length, (i){
                            var data = dataJenisRetur[i];
                            return Container(
                              margin: EdgeInsets.only(right: 10),
                              child: ChoiceChip(
                                label: text(data['text'], color: kategori.text == data['value'] ? Colors.white : Colors.black54),
                                selected: kategori.text == data['value'] ? true : false,
                                onSelected: (isSelected){
                                  if(isSelected){
                                    setState(() {
                                      kategori.text = data['value'];
                                      // tipeHarga.text = data[i].toString().toLowerCase();
                                    });
                                  }
                                },
                                selectedColor: TColor.azure(),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),

                    SelectInput(
                      label: 'Tanggal Expired',
                      controller: dateExp, suffix: Ic.calendar(),
                      select: (){
                        Wh.datePicker(context).then((res){
                          setState(() => dateExp.text = res );
                        });
                      },
                    ),

                    Row(
                      children: [
                        Expanded(
                          child: InputNumber(
                            label: 'Banyak Dus',
                            hint: 'Banyak dus',
                            controller: qtyDus,
                          ),
                        ),
                        SizedBox(width: 15,),
                        Expanded(
                          child: InputNumber(
                            label: 'Banyak Pcs',
                            hint: 'Banyak pcs',
                            controller: qtyPcs,
                          ),
                        )
                      ],
                    ),

                    Row(
                      children: [
                        Expanded(
                          child: InputNumber(
                            label: 'Disc Percent',
                            hint: 'Disc percent',
                            controller: disPercent,
                            suffix: Container(
                                padding: EdgeInsets.only(left: 10, right: 10, top: 10, bottom: 10),
                                child: text('%', size: 16, align: TextAlign.end)
                            ),
                          ),
                        ),
                        SizedBox(width: 15,),
                        Expanded(
                          child: InputNumber(
                            label: 'Disc Nominal',
                            hint: 'Disc nominal',
                            controller: disNominal,
                            prefix: text('Rp  '),
                            isSuffix: false,
                          ),
                        )
                      ],
                    ),

              // FormControl.radio(label: 'Kategori BS', values: bsRadio, checked: kategori.text, onChange: (c){
              //   setState(() => kategori.text = c );
              // }),

              // FormControl.select(context, label: 'Tanggal Expired', controller: dateExp, icon: Icon(Icons.today, color: Colors.black45), onTap: (){
              //   Wh.datePicker(context).then((res){
              //     setState(() => dateExp.text = res );
              //   });
              // }),

              // FormControl.number(label: 'Banyak Dus', controller: qtyDus),
              // FormControl.number(label: 'Banyak Pcs', controller: qtyPcs),

              // FormControl.button(textButton: 'Simpan', isSubmit: isSubmit, onTap: (){ saveReturBarang(); })
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
    );

    // return Scaffold(
    //   appBar: Wh.appBar(context, title: widget.formData == null ? 'Tambah Barang' : 'Edit Barang'),
    //   body: SingleChildScrollView(
    //     padding: EdgeInsets.all(15),
    //     child: Column(
    //       crossAxisAlignment: CrossAxisAlignment.start,
    //       children: [

    //         FormControl(context).selector(label: 'Pilih Barang ', controller: barang.text, onTap: (){
    //           modal(widget.ctx, child: ListBarang(), onClose: (res){
    //             if(res != null){
    //               idBarang = res['idBarang'];
    //               barang.text = res['barang'];
    //             }
    //           });
    //         }),

    //         widget.tipeRetur == 'baik' ? SizedBox.shrink() :
    //         FormControl.radio(label: 'Kategori BS', values: bsRadio, group: bsIndex, onChange: (v, i){
    //           setState(() {
    //             kategori.text = v; bsIndex = i;
    //           });
    //         }),

    //         Input.date(
    //           title: 'Tanggal Expired',
    //           hint: 'yyyy-mm-dd',
    //           controller: dateExp,
    //         ),

    //         Input.number(title: 'Banyak Dus', hint: 'Jumlah dus', controller: qtyDus),

    //         Input.number(title: 'Banyak Pcs', hint: 'Jumlah pcs', controller: qtyPcs),


    //         FormControl(context).button(label: isSubmit ? spin(color: Colors.white) : text('Simpan', color: Colors.white), marginY: 5, onPressed: isSubmit ? null : (){ saveReturBarang(); }),




    //       ]
    //     ),
    //   ),
    // );
  
  }
}

class ListBarang extends StatefulWidget {
  @override
  _ListBarangState createState() => _ListBarangState();
}

class _ListBarangState extends State<ListBarang> {

  var data = [], filter = [], loaded = false;

  getData({refill: false}){
    setState(() {
      loaded = false;
    });

    if(refill){
      Request.get('barang?per_page=all', then: (status, result){
        setState(() {
          setPrefs('barangRetur', decode(result)['data'], enc: true);
          loaded = true;
        });
      }, error: (err){
        onError(context, response: err, popup: true, backOnDismiss: true);
      });
    }else{
      getPrefs('barangRetur', dec: true).then((res){
        if(res != null){
          setState(() {
            data = filter = res;
            loaded = true;
          });
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    getData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Wh.appBar(context, title: Fc.search(hint: 'Ketik kode atau nama barang', autofocus: true, change: (String s){
        var k = s.toLowerCase();
        setState(() {
          filter = data.where((item) => item['kode_barang'].toLowerCase().contains(k) || item['nama_barang'].toLowerCase().contains(k)).toList();
        });
      }), actions: [
        IconButton(
          icon: Icon(Icons.refresh, color: !loaded ? Colors.black26 : Colors.black54),
          onPressed: !loaded ? null : (){ getData(refill: true); },
        )
      ]),

      body: !loaded ? Wh.spiner(size: 50) :
        filter == null || filter.length == 0 ? Wh.noData(message: 'Tidak ada data barang\nCobalah dengan kode atau nama lain') :

        ListView.builder(
          itemCount: filter.length,
          itemBuilder: (context, i){
            var row = filter[i];

            return WidSplash(
              padding: EdgeInsets.all(15),
              onTap: (){
                Navigator.pop(context, {'idBarang': row['id'], 'barang': row['nama_barang']});
              },
              color: i % 2 == 0 ? TColor.silver() : Colors.white,
              child: Container(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: text(row['kode_barang'], bold: true),
                        ),
                        row['tipe'] == null ? SizedBox.shrink() : WidSplash(
                          padding: EdgeInsets.only(left: 10, right: 10),
                          color: row['tipe'].toString().toLowerCase() == 'exist' ? TColor.red() 
                              : row['tipe'].toString().toLowerCase() == 'non_exist' ? TColor.green()
                              : TColor.blueLight(),
                          radius: BorderRadius.circular(2),
                          child: text(row['tipe'], color: Colors.white),
                        )
                      ],
                    ),
                    SizedBox(height: 5,),
                    text(row['nama_barang'])
                  ]
                ),
              ),
            );
          },
        ),
    );
  }
}