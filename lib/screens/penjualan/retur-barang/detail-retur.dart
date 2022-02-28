import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/services.dart';
import 'package:sales/services/api/api.dart';
import 'package:sales/services/v2/helper.dart';

import 'forms/form-retur-barang.dart';
import 'forms/form-retur-toko.dart';

class DetailRetur extends StatefulWidget {
  DetailRetur({this.ctx, this.data}); final ctx, data;

  @override
  _DetailReturState createState() => _DetailReturState();
}

class _DetailReturState extends State<DetailRetur> {

  var detailRetur = [];
  bool loaded = false, printPermission = false,
      approvePermission = false, isNPWP = true, canVerify = false;
  var idrp, idb = '16', katBs = 'kd', expDate = '2020-02-15', qtyDus = '1',
      qtyPcs = '0', tipeSalesman, role;
  var totalDus = 0.0, totalPcs = 0.0;

  getDetailRetur(){
    isNPWP = widget.data['npwp'] == '' ? false : true;
    getPrefs('user', dec: true).then((res){
      role = res['role'];
    });

    getPrefs('log_salesman', dec: true).then((res){
      if(res != null){
        tipeSalesman = res['tipe'];

        printPermission = true;
        if(res['tipe'] == 'to'){
          printPermission = false;
        }
        
        if(res['tipe'] == 'canvass'){
          approvePermission = true;
        }
      }
    });

    idrp = widget.data['id'].toString();

    setState(() {
      loaded = false;
    }); 

    Request.get('detail_retur_penjualan/'+idrp.toString()+'/detail', debug: true, then: (status, data){
      setState(() {
        loaded = true;
        detailRetur = decode(data)['data'];
        initFooter(detailRetur);
      });
    }, error: (err){
      onError(context, response: err, popup: true);
    });

  }

  initFooter(data){
    totalDus = 0; totalPcs = 0;

    for (var item in data) {
      // print(double.parse(item['subtotal']).round());
      setState(() {
        // totalValue += item['subtotal_ppn'].round();
        // totalDus += int.parse(item['qty_dus'].toString());
        // totalPcs += int.parse(item['qty_pcs'].toString());

        totalDus += double.parse(item['qty_dus']);
        totalPcs += double.parse(item['qty_pcs']);

        // print(item['qty_dus'].runtimeType);
        // print(double.parse(item['qty_dus']).runtimeType);
        // print(item['qty_pcs']);
      });
    }
  }

  getPermissions(){
    getPrefs('permissions', type: List).then((res) async {
      if(res.contains('Verify Retur Penjualan')){
        setState(() {
          canVerify = true;
        });
      }else{
        setState(() {
          canVerify = false;
        });
      }
    });
  }

  _verifyRetur(){
    showDialog(context: context, child: OnProgress(message: 'Verify...'));

    Request.put('retur_penjualan/'+widget.data['id'].toString()+'/set_verified', debug: true, then: (s, data){
      Map res = decode(data);
      Wh.toast(res['message']);
      Navigator.pop(context);
      Navigator.pop(context);
    }, error: (err){
      Navigator.pop(context);
      onError(context, response: err, popup: true);
    });
  }

  Future<Null> _onRefresh() async {
    getDetailRetur();
  }

  @override
  void initState() {
    super.initState();

    getPermissions();
    getDetailRetur();
  }

  _confirm() async {
    showDialog(context: context, child: OnProgress(message: 'Menyetujui...'));

    Request.post('retur_penjualan/'+widget.data['id'].toString()+'/approve', then: (s, data){
      Map res = decode(data);
      Wh.toast(res['message']);
      setPrefs('approved_detail_retur', widget.data, enc: true);

      // tandai bahwa ada aktivitas menyetujui penjualan
      setPrefs('returHasApproved', true);

      setState(() => widget.data['status'] = 'approved' );
      Navigator.pop(context);

    }, error: (err){
      Navigator.pop(context);
      onError(context, response: err, popup: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TColor.silver(),
      appBar: Wh.appBar(context, title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          text(widget.data['id'].toString(), bold: true),
          text('['+widget.data['no_acc_toko']+'] - '+widget.data['nama_toko'], size: 13)
        ],
      ), actions: [

        IconButton(
          icon: Icon(Ic.more()),
          onPressed: (){
            var options = ['Detail Retur','Edit','Cetak','Setujui', 'Verify'],
                icons = [Ic.info(),Ic.edit(),Ic.print(),Ic.check(), Ic.check()];

            var filter = [];

            if(widget.data['status'] != 'waiting'){
              filter..addAll([1,3]);
            }else{
              filter..addAll([2]);
            }

            if(!approvePermission){
              filter..addAll([2,3]);
            }

            if(!canVerify){
              filter..addAll([4]);
            }

            if(widget.data['verified_by'] != null){
              filter..addAll([1]);
            }

            getPrefx(['user','log_salesman'], (res){
              if(res[1] != null && decode(res[1])['tipe'] != 'canvass'){
                options.removeWhere((item) => item == 'cetak' || item == 'setujui');
              }
            });

            Wh.options(widget.ctx, options: options, hide: filter, icons: icons, then: (res){ Navigator.pop(context);
              if(res != null)
              switch (res) {
                case 0: modal(widget.ctx, child: InfoDetailRetur(data: widget.data)); break;
                case 1: modal(widget.ctx, child: FormReturToko(ctx: widget.ctx, formData: widget.data), then: (res){
                    if(res != null){
                      print(res);
                      setState(() {
                        widget.data['id_toko'] = int.parse(res['data']['id_toko']);
                        widget.data['nama_toko'] = res['data']['nama_toko'];
                        widget.data['tipe_barang'] = res['data']['tipe_barang'];
                        widget.data['keterangan'] = res['data']['keterangan'];
                      });
                    }
                  }); break;
                case 2: 
                  modal(widget.ctx, wrap: true, child: PrintRetur(toko: widget.data, barang: detailRetur), radius: 15, then: (res){
                    if(res != null){
                      Wh.alert(context, title: 'Bluetooth Error', message: 'Tidak dapat terhubung ke perangkat Blutetooth Thermal, pastikan printer sudah aktif dan tidak terhubung ke ponsel manapun setelah itu coba ulang kembali.');
                    }
                  });
                break;

                case 3: 
                  if(detailRetur.length < 1){
                    Wh.toast('Barang tidak boleh kosong');
                  }else{ _confirm(); }
                
                 break;

                case 4:
                  if(detailRetur.length < 1){
                    Wh.toast('Barang tidak boleh kosong');
                  }else{
                    _verifyRetur();
                  }
                  break;
                default:
              }
            });

          },
        )
      ]),
      body: !loaded ? ListSkeleton(length: 10)
          : detailRetur == null || detailRetur.length == 0
          ? Wh.noData(
            message: 'Tidak ada data barang\nTap gambar untuk memuat ulang',
            onTap: (){
              getDetailRetur();
            }
      ) : RefreshIndicator(
          onRefresh: _onRefresh,
            child: Stack(
                children: [
                  ListView.builder(
                    padding: EdgeInsets.only(bottom: 87),
                    itemCount: detailRetur.length,
                    itemBuilder: (context, i){
                      var data = detailRetur[i];

                      return WidSplash(
                        onTap: (){
                          modal(widget.ctx, child: DetailBarang(data: data, isNPWP: isNPWP));
                        },
                        onLongPress: widget.data['status'] != 'waiting' || widget.data['verified_by'] != null ? null : (){
                          Wh.options(context, options: ['Edit','Hapus'], icons: [Ic.edit(), Ic.trash()], then: (res){
                            Navigator.pop(context);

                            if(res != null){
                              switch (res) {
                                case 0:
                                  modal(widget.ctx, child: FormReturBarang(ctx: widget.ctx, idRP: widget.data['id'], formData: data, tipeRetur: widget.data['tipe_barang']), then: (res){
                                    if(res != null) getDetailRetur();
                                  });
                                  
                                  break;
                                default: Wh.confirmation(context, message: 'Yakin ingin menghapus barang ini?', confirmText: 'Hapus Barang', then: (res){
                                  if(res != null && res == 0){
                                    Navigator.pop(context);

                                    showDialog(
                                      context: context,
                                      child: OnProgress(message: 'Menghapus...')
                                    );

                                    setTimer(1, then: (t){
                                      Request.delete('detail_retur_penjualan/'+data['id'].toString(), then: (status, body){
                                        setState(() {
                                          detailRetur.removeWhere((item) => item['id'] == data['id']);
                                          initFooter(detailRetur);
                                        });
                                        Map res = decode(body);
                                        Wh.toast(res['message']);

                                        Navigator.pop(context, {'delete': true, 'id': data['id']});
                                      }, error: (err){
                                        onError(context, response: err, popup: true, backOnError: true);
                                      });
                                    });
                                  }
                                });
                              }
                            }
                          });
                        },
                        padding: EdgeInsets.only(left: 15, right: 15, top: 10, bottom: 10),
                        color: i % 2 == 0 ? TColor.silver() : Colors.white,
                        child: Container(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    text(data['kode_barang'], bold: true),
                                    text(data['nama_barang']),
                                    // text('Rp '+number(data['harga'])),
                                  ]
                                )
                              ),

                              Container(
                                margin: EdgeInsets.only(left: 15),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    text(data['kategori_bs'].toString().toUpperCase()),
                                    text(data['qty_dus'].toString()+' / '+data['qty_pcs'].toString()),
                                    // text('Rp '+ribuan(isNPWP ? data['subtotal'] : data['subtotal_ppn'] )),
                                    text('Rp '+ribuan(data['subtotal'])),
                                  ]
                                ),
                              )
                            ]
                          ),
                        ),
                      );
                    },
                  ),

                  Positioned(
                    left: -1, bottom: 18,
                    child: Container(
                      width: Mquery.width(context),
                      child: Row(
                        children: [
                          widget.data['grand_total'] == 0 ? SizedBox.shrink() : Container(
                            margin: EdgeInsets.only(right: 5),
                            padding: EdgeInsets.only(left: 15, top: 9, bottom: 9, right: 25),
                            decoration: BoxDecoration(
                              // border: Border.all(color: Colors.black12),
                              borderRadius: BorderRadius.only(
                                topRight: Radius.circular(50),
                                bottomRight: Radius.circular(50)
                              ),
                              color: TColor.azure(),
                              boxShadow: [
                                BoxShadow(
                                  color: Color.fromRGBO(0, 0, 0, .2),
                                  blurRadius: 5.0, // has the effect of softening the shadow
                                  spreadRadius: 2.0, // has the effect of extending the shadow
                                  offset: Offset( 1.0, 2.0 ),
                                )
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                text('TOTAL VALUE : Rp '+ribuan(widget.data['grand_total']), color: Colors.white),
                                text('TOTAL DUS/PCS : '+totalDus.toString()+'/'+totalPcs.toString(), color: Colors.white),
                              ]
                            ),
                          ),
                          Expanded(child: SizedBox.shrink()),
                          !canVerify || widget.data['verified_by'] != null ? SizedBox.shrink() : FloatingActionButton(
                            onPressed: (){
                              _verifyRetur();
                            },
                            backgroundColor: TColor.azure(),
                            child: Icon(Ic.check()),
                          ),
                          SizedBox(width: 5,),
                          floatingAdd(),
                          SizedBox(width: 5,),
                        ],
                      ),
                    ),
                  )
                ]
              )
        ),

      floatingActionButton: loaded && (detailRetur == null || detailRetur.length == 0) ? floatingAdd() : SizedBox.shrink(),

      // floatingActionButton: widget.data['status'] != 'waiting' && role != 'admin' && tipeSalesman != 'canvass' ? null : FloatingActionButton(
      //   onPressed: (){
      //     if(widget.data['status'] != 'waiting' && (role == 'admin' || tipeSalesman == 'canvass')){
      //       modal(widget.ctx, wrap: true, child: PrintRetur(toko: widget.data, barang: detailRetur), then: (res){
      //         if(res != null){
      //           Wh.alert(context,
      //               title: 'Bluetooth Error',
      //               message: 'Tidak dapat terhubung ke perangkat Blutetooth Thermal, '
      //                   'pastikan printer sudah aktif dan tidak terhubung ke ponsel manapun setelah itu coba ulang kembali.'
      //           );
      //         }
      //       });
      //     }else{
      //       modal(widget.ctx, child: FormReturBarang(ctx: widget.ctx, idRP: widget.data['id'], tipeRetur: widget.data['tipe_barang']), then: (res){
      //         if(res != null) getDetailRetur();
      //       });
      //     }
      //   },
      //   backgroundColor: TColor.azure(),
      //   child: Icon(widget.data['status'] != 'waiting' ? Ic.print() : Ic.add()),
      // )
    );
  }

  Widget floatingAdd(){
    return widget.data['verified_by'] != null || widget.data['status'] != 'waiting' && role != 'admin' && tipeSalesman != 'canvass' ? SizedBox.shrink() : FloatingActionButton(
      onPressed: (){
        if(widget.data['status'] != 'waiting' && (role == 'admin' || tipeSalesman == 'canvass')){
          modal(widget.ctx, wrap: true, child: PrintRetur(toko: widget.data, barang: detailRetur), then: (res){
            if(res != null){
              Wh.alert(context,
                  title: 'Bluetooth Error',
                  message: 'Tidak dapat terhubung ke perangkat Blutetooth Thermal, '
                      'pastikan printer sudah aktif dan tidak terhubung ke ponsel manapun setelah itu coba ulang kembali.'
              );
            }
          });
        }else{
          modal(widget.ctx, child: FormReturBarang(ctx: widget.ctx, idRP: widget.data['id'], tipeRetur: widget.data['tipe_barang']), then: (res){
            if(res != null) getDetailRetur();
          });
        }
      },
      backgroundColor: TColor.azure(),
      child: Icon(widget.data['status'] != 'waiting' ? Ic.print() : Ic.add()),
    );
  }
}

class InfoDetailRetur extends StatefulWidget {
  final data;
  InfoDetailRetur({this.data});

  @override
  _InfoDetailReturState createState() => _InfoDetailReturState();
}

class _InfoDetailReturState extends State<InfoDetailRetur> {
  var length = 0, labels = [], values = [];

  initData(){
    var data = widget.data;
    print(data);
    labels = [
      'No. Retur Penjualan',
      'Nama Toko',
      'No. Acc',
      'Cust. No',
      'Alamat',
      'NPWP',
      'Gudang',
      'Tipe Barang',
      'Tanggal Retur',
      'Tanggal Claim',
      'Status',
      'Keterangan',
      'Nama Sales',
      'Nama Tim'
    ];
    values = [
      data['id'],
      data['nama_toko'],
      data['no_acc_toko'],
      data['no_cust_toko'],
      data['alamat_toko'],
      data['npwp'] == null || data['npwp'] == '' ? '-' : data['npwp'],
      data['nama_gudang'],
      data['tipe_barang'].toString().toUpperCase(),
      dateFormat(data['sales_retur_date']),
      data['claim_date'] == null ? '-' : dateFormat(data['claim_date']),
      ucword(data['claim_date'] == null ? data['status'] : 'claim'),
      data['keterangan'] == null || data['keterangan'] == '' ? '-' : data['keterangan'],
      data['nama_salesman'],
      data['nama_tim']
    ];
    
    length = labels.length;
  }

  @override
  void initState() {
    super.initState(); initData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Wh.appBar(context, title: 'Detail Retur', center: true),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
    );
  }
}

class DetailBarang extends StatefulWidget {
  final data, isNPWP;
  DetailBarang({this.data, this.isNPWP});

  @override
  _DetailBarangState createState() => _DetailBarangState();
}

class _DetailBarangState extends State<DetailBarang> {
  var length = 0, labels = [], values = [];

  initData(){
    var data = widget.data;
    labels = [
      'kode barang',
      'nama barang',
      'kategori bs',
      'expired date',
      'qty dus',
      'qty pcs',
      'Harga',
      'discount percent',
      'discount nominal',
      'value retur percentage',
      'Subtotal',
      'Potongan',
      'DPP'
    ];
    values = [
      data['kode_barang'],
      data['nama_barang'],
      data['kategori_bs'],
      data['expired_date'],
      data['qty_dus'], 
      data['qty_pcs'],
      'Rp '+ribuan(data['harga'], fixed: 2),
      // 'Rp '+ribuan(widget.isNPWP ? data['harga'] : data['harga_ppn'], fixed: 2),
      data['disc_persen'].toString()+'%',
      'Rp '+ribuan(data['disc_nominal'], fixed: 2),
      data['value_retur_percentage']+'%',
      // 'Rp '+ribuan(widget.isNPWP ? data['subtotal'] : data['subtotal_ppn'], fixed: 2),
      // 'Rp '+ribuan(widget.isNPWP ? data['discount'] : data['discount_ppn'], fixed: 2),
      // 'Rp '+ribuan(widget.isNPWP ? data['dpp'] : data['net'], fixed: 2),

      'Rp '+ribuan(data['subtotal'], fixed: 2),
      'Rp '+ribuan(data['discount'], fixed: 2),
      'Rp '+ribuan(data['dpp'], fixed: 2),
    ];

    length = labels.length;
  }

  @override
  void initState() {
    super.initState(); initData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Wh.appBar(context, title: 'Detail Barang'),
      body: SingleChildScrollView(
        child: Column(
          children: List.generate(length, (int i){
            return Container(
              padding: EdgeInsets.all(15),
              color: i % 2 == 0 ? TColor.silver() : Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  text(ucword(labels[i])),
                  Expanded(
                    child: text(values[i],align: TextAlign.right),
                  )
                ],
              ),
            );
          })
        ),
      ),
    );
  }
}

class PrintRetur extends StatefulWidget {
  final toko, barang;
  PrintRetur({this.toko, this.barang});

  @override
  _PrintReturState createState() => _PrintReturState();
}

class _PrintReturState extends State<PrintRetur> {
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
            child: !isConnected ? Column(
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
            ) : loading ? Container(
              margin: EdgeInsets.only(top: 25, bottom: 25),
              child: Column(
                children: <Widget>[
                  Wh.spiner(size: 50, margin: 25),
                  text('Mencari perangkat printer')
                ],
              ),
            ) : _devices.length == 0 ?
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
                        text('Pilih terlebih dahulu perangkat printer di pengaturan bluetooth, '
                            'pastikan printer dalam keadaan menyala serta tidak terhubung ke perangkat manapun, '
                            'kemudian tutup laman ini dan coba buka kembali.',
                            align: TextAlign.center),
                      ]
                    )
                  ]
                )
              ) : Column(
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
                                timer.cancel();
                                hasPrinted = true; // print success
                                Print.run(widget.toko, widget.barang, onFinish: (f){
                                  // setState(() => isPrint = false );
                                  Navigator.pop(context);
                                });
                              }, onError: (onErr){
                                Wh.toast(onErr.toString());
                                // Navigator.pop(context, {'error': true});
                              });
                            }on PlatformException catch (_) {
                              Wh.toast(_.toString());
                              // Navigator.pop(context, {'error': true});
                            }
                          }else{
                            timer.cancel();
                            hasPrinted = true; // print success

                            // jalankan printer
                            Print.run(widget.toko, widget.barang, onFinish: (f){
                              Navigator.pop(context);
                            });
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
  static run(toko, barang, {Function onFinish}) async{
    BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;

    await getPrefs('cp'+toko['id'].toString(), type: int).then((res){
      // print(res);
      // print('TOKO : ' + toko.toString());
      // print('BARANG : ' + barang.toString());
      bluetooth.isConnected.then((isConnected) {
        if(isConnected){
          // bluetooth.printCustom("PT. KEMBAR PUTRA MAKMUR",1,1);
          // bluetooth.printCustom("Jl. Anggrek I No. 1, Kapal, Mengwi, Badung",0,1);
          // bluetooth.printCustom("(0361) 9006481 | www.kembarputra.com",0,1);
          bluetooth.printCustom(toko['nama_perusahaan'].toString().toUpperCase(),1,1);
          bluetooth.printCustom(toko['alamat_depo'],0,1);
          bluetooth.printCustom('Telp.' + toko['telp_depo'] + '|Fax.' + toko['fax_depo'],0,1);
          bluetooth.printCustom(toko['nama_depo'],0,1);
          bluetooth.printCustom("--------------- BUKTI RETUR --------------",0,1);
          bluetooth.printLeftRight('No. '+toko['id'].toString(), ' Tgl. '+Dt.dmy,0);
          bluetooth.printCustom('Sales : '+toko['nama_tim']+' - '+toko['nama_salesman'],0,0);
          bluetooth.printCustom('Cust : '+toko['no_acc_toko']+' - '+toko['nama_toko'],0,0);
          bluetooth.printCustom('NPWP : '+(toko['npwp'] == '' ? '-' : toko['npwp']),0,0);
          
          if(res == null){
            bluetooth.printCustom("------------------------------------------",0,1);
          }else{
            bluetooth.printCustom("--------------------------------------COPY",0,1);
          }

          var tQty = 0, tPcs = 0, gt = 0.0, tp = 0, total = 0.0;

          for (var i = 0; i < barang.length; i++) {
            var item = barang[i],
                kodeNamaBarang = item['kode_barang']+' - '+item['nama_barang'],

            namaBarang = kodeNamaBarang.length > 42 ? kodeNamaBarang.substring(0, 42) : kodeNamaBarang,
            qtyDus = item['qty_dus'].toString(),
            qtyPcs = item['qty_pcs'].toString();
            // qtyDus = item['qty_dus'].toString()+' crt ',
            // qtyPcs = item['qty_pcs'].toString()+' '+' pcs ';
            // tQty += item['qty_dus'];
            // tPcs += item['qty_pcs'];
            // gt += item['subtotal'];
            // tPpn += item['ppn'];

            tQty += int.parse(item['qty_dus']);
            tPcs += int.parse(item['qty_pcs']);
            gt += toko['npwp'] != '' ? item['subtotal'] : item['subtotal_ppn'];
            // tPpn += item['ppn'];

            bluetooth.printCustom(namaBarang,0,0);
            // bluetooth.printLeftRight(qtyDus.toString()+'      '+qtyPcs.toString(),'         '+ribuan(toko['npwp'] != '' ? item['subtotal'].toString() : item['subtotal_ppn'].toString()), 0);
            bluetooth.printLeftRight('qty: '+qtyDus.toString()+'/'+qtyPcs.toString() +
                '     '+'pot: '+ribuan(toko['npwp'] != '' ? item['discount'].toString() : item['discount_ppn'].toString()),
                'sub: '+ribuan(toko['npwp'] != '' ? item['subtotal'].toString() : item['subtotal_ppn'].toString()),0);
          }

          bluetooth.printCustom("------------------------------------------",0,1);

          bluetooth.printLeftRight('Jml Fisik', tQty.toString()+' crt / '+tPcs.toString()+' pcs', 0);
          // bluetooth.printLeftRight('Ppn', tPpn.toString(), 0);
          // bluetooth.printLeftRight('Grand Total', ribuan(gt), 0);
          bluetooth.printLeftRight('Subtotal', ribuan(toko['npwp'] != '' ? toko['subtotal'] : toko['subtotal_ppn']), 0);
          bluetooth.printLeftRight('Potongan', ribuan(toko['npwp'] != '' ? toko['discount'] : toko['discount_ppn']), 0);
          if(toko['npwp'] != ''){
            bluetooth.printLeftRight('DPP Retur', ribuan(toko['dpp']), 0);
            bluetooth.printLeftRight('PPn', ribuan(toko['ppn']), 0);
          }
          bluetooth.printLeftRight('Grand Total', ribuan(toko['npwp'] != '' ? toko['dpp'] : toko['grand_total']), 0);

          bluetooth.printCustom("------------------------------------------",0,1);
          bluetooth.printCustom('Harap lengkapi dengan stempel & TT toko', 0, 1);
          bluetooth.printNewLine();
          bluetooth.printNewLine();
          bluetooth.printNewLine();
          bluetooth.paperCut();

          setPrefs('cp'+toko['id'].toString(), toko['id']);
          onFinish(true);
        }
      });
    });
  }
}