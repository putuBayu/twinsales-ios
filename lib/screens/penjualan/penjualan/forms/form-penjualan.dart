import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sales/screens/penjualan/penjualan/detail-penjualan-hari-ini.dart';
import 'package:sales/services/api/api.dart';
import 'package:sales/services/v2/helper.dart';
import 'package:sales/services/v3/helper.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class FormPenjualan extends StatefulWidget {
  FormPenjualan(this.ctx, {this.initData, this.initDataKunjungan});

  final ctx, initData, initDataKunjungan;

  _FormPenjualanState createState() => _FormPenjualanState();
}

class _FormPenjualanState extends State<FormPenjualan>
    with TickerProviderStateMixin {
  Timer pingLooper;

  var toko = TextEditingController(),
      infoOD = TextEditingController(),
      keterangan = TextEditingController(),
      tipePembayaran = TextEditingController(text: 'credit'),
      tipeKunjungan = TextEditingController(text: 'Efektif'),
      listKunjungan = TextEditingController(),
      keteranganTidakEfektif = TextEditingController(),
      locationController = TextEditingController(),
      poManual = TextEditingController(),
      tipeHarga = TextEditingController();

  var initData = {}, isSubmit = false, idToko = 0;
  var selected = 0,
      loading = true,
      loadKunjungan = true,
      showLabel = false,
      loadOD = false;
  List dataTipeHarga,
      dataTipeKunjungan = ['Efektif', 'Tidak Efektif'],
      dataKunjungan;
  Map dataOd;
  TabController tabController, kunjunganController;
  // LatLng currentLocation;
  // GoogleMapController _mapController;
  // GoogleMapController get mapController => _mapController;
  String fullAddress;

  //mitra
  // List mitraValue = ['Tanpa Mitra', 'UD. Mandiri Jaya'];
  List mitraValue;
  String selectedMitra = '0';
  // int selectedIdMitra = 0;

  getMitra({refill: false}) async {
    getPrefs('mitra', dec: true).then((res) async {
      if (!refill && res != null) {
        mitraValue = res;
        loading = false;
        initForm();
      } else {
        await Request.get('/mitra/list/simple', then: (status, body) {
          if (mounted) {
            Map res = decode(body);
            loading = false;

            var noMitra = {
              "id": 0,
              "kode_mitra": "",
              "perusahaan": "Tanpa Mitra"
            };

            setState(() {
              mitraValue = res['data'];
              mitraValue.insert(0, noMitra);
              setPrefs('mitra', mitraValue, enc: true);
              // tipeHarga.text = dataTipeHarga[0].toString();
            });

            initForm();

            return res;
          }
        }, error: (err) {
          setState(() {
            loading = false;
          });
          onError(context, response: err);
        });
      }
    });
  }

  getTipeHarga({refill: false}) async {
    setState(() {
      loading = true;
    });

    getPrefs('tipeHarga', dec: true).then((res) async {
      if (!refill && res != null) {
        dataTipeHarga = res;
        getMitra();
      } else {
        await Request.get('/tipe_harga/get/list', then: (status, body) {
          if (mounted) {
            List res = decode(body);
            // loading = false;

            setState(() {
              dataTipeHarga = res;
              setPrefs('tipeHarga', dataTipeHarga, enc: true);
              // tipeHarga.text = dataTipeHarga[0].toString();
            });

            getMitra(refill: true);

            return res;
          }
        }, error: (err) {
          setState(() {
            loading = false;
          });
          onError(context, response: err);
        });
      }
    });
  }

  getLimitOd() async {
    setState(() {
      loadOD = true;
    });
    await Request.get('/toko/sisa_limit_od/' + idToko.toString(),
        then: (status, body) {
      if (mounted) {
        Map res = decode(body);

        setState(() {
          dataOd = res;
          loadOD = false;
        });

        return res;
      }
    }, error: (err) {
      setState(() {
        loading = false;
      });
      onError(context, response: err);
    });
  }

  Widget detailOD() {
    return loadOD
        ? ListSkeleton(
            length: 5,
          )
        : Container(
            height:
                dataOd['od'].length <= 0 ? 100 : Mquery.height(context) * 0.6,
            child: Column(
              children: [
                Expanded(
                  child: dataOd['od'].length <= 0
                      ? Center(
                          child: text('Tidak ada invoice yang OD'),
                        )
                      : SingleChildScrollView(
                          child: Column(
                            children: List.generate(dataOd['od'].length, (i) {
                              var data = dataOd['od'][i];
                              return WidSplash(
                                color:
                                    i % 2 == 0 ? TColor.silver() : Colors.white,
                                child: Container(
                                  padding: EdgeInsets.all(15),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      text(data['invoice'], bold: true),
                                      Row(
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              text('Due Date', size: 13),
                                              text('Grand Total', size: 13),
                                            ],
                                          ),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                text(' : ' + data['due_date'],
                                                    size: 13),
                                                text(
                                                    ' : ' +
                                                        ribuan(
                                                            data['grand_total'],
                                                            cur: 'Rp '),
                                                    size: 13),
                                              ],
                                            ),
                                          ),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              text('OD', size: 13),
                                              text('Umur', size: 13)
                                            ],
                                          ),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              text(
                                                  ' : ' +
                                                      data['over_due']
                                                          .toString() +
                                                      ' hari',
                                                  size: 13),
                                              text(
                                                  ' : ' +
                                                      data['umur'].toString() +
                                                      ' hari',
                                                  size: 13)
                                            ],
                                          )
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                ),
                Container(
                  margin: EdgeInsets.all(10),
                  child: WidSplash(
                    border: Border.all(color: Colors.black26),
                    onTap: () {
                      Navigator.pop(context);
                    },
                    color: Color.fromRGBO(0, 0, 0, .03),
                    radius: BorderRadius.circular(5),
                    child: Container(
                      width: Mquery.width(context),
                      padding: EdgeInsets.all(11),
                      child: text('Tutup', align: TextAlign.center),
                    ),
                  ),
                )
              ],
            ),
          );
  }

  getKunjungan() {
    setState(() {
      loadKunjungan = true;
    });
    Request.get('/options/get/list?code=call', then: (status, body) {
      if (mounted) {
        var res = decode(body);

        setState(() {
          dataKunjungan = res['data'];
          if (widget.initDataKunjungan == null) {
            listKunjungan.text =
                dataKunjungan[dataKunjungan.length - 1]['value'];
          }
        });
        loadKunjungan = false;

        kunjunganController =
            new TabController(length: dataKunjungan.length, vsync: this);
        kunjunganController.addListener(() {
          TColor.azure();
        });

        setState(() {
          kunjunganController.index = dataKunjungan.length - 1;
        });

        return res;
      }
    }, error: (err) {
      setState(() {
        loading = false;
      });
      onError(context, response: err);
    });
  }

  initForm() async {
    if (widget.initData != null) {
      var data = widget.initData;
      initData = data;

      idToko = int.parse(data['id_toko']);
      // selectedIdMitra = data['id_mitra'];
      // selectedMitra = mitraValue[data['id_mitra']];
      for (int i = 0; i < mitraValue.length; i++) {
        if (mitraValue[i]['id'].toString().toLowerCase() ==
            data['id_mitra'].toString().toLowerCase()) {
          setState(() {
            selectedMitra = mitraValue[i]['id'].toString();
          });
        }
      }

      for (int i = 0; i < dataTipeHarga.length; i++) {
        if (dataTipeHarga[i].toString().toLowerCase() ==
            data['tipe_harga'].toString().toLowerCase()) {
          setState(() {
            tipeHarga.text = data['tipe_harga'];
            selected = i;
          });
        }
      }

      // getLimitOd();

      setState(() {
        toko.text = data['toko'][0]['nama_toko'];
        tipePembayaran.text = data['tipe_pembayaran'];
        // tipeHarga.text = data['tipe_harga'];
        poManual.text = data['po_manual'];
        keterangan.text = data['keterangan'];
      });
    } else if (widget.initDataKunjungan != null) {
      var data = widget.initDataKunjungan;
      if (data != null) {
        toko.text = data['nama_toko'];
        idToko = data['id_toko'];
        listKunjungan.text = data['status'].toString().toLowerCase();
        keterangan.text = data['keterangan'];
        tabController.index = 1;
        tipeKunjungan.text = dataTipeKunjungan[1];
      }
    } else {
      tipeHarga.text = dataTipeHarga[0].toString();
      getPrefs('log_salesman', dec: true).then((res) {
        if (res != null)
          setState(() {
            if (res['tipe'] == 'canvass') {
              tipePembayaran.text = 'cash';
              // tipeHarga.text = 'rbp';
            }
          });
      });
    }
  }

  selectedPrice(var data) {
    for (int i = 0; i < dataTipeHarga.length; i++) {
      if (dataTipeHarga[i].toString().toLowerCase() ==
          data.toString().toLowerCase()) {
        setState(() {
          selected = i;
          tipeHarga.text = dataTipeHarga[i].toString().toLowerCase();
        });
      }
    }
  }

  onCreated() {
    // _mapController = controller;
  }

  onCameraMove() async {
    setState(() {});
    showLabel = false;
    // currentLocation =
    //     LatLng(position.target.latitude, position.target.longitude);
  }

  getMoveCamera() async {
    showLabel = false;
    // List<Placemark> placemark = await Geolocator().placemarkFromCoordinates(
    //     currentLocation.latitude, currentLocation.longitude);
    // locationController.text = placemark[0].thoroughfare.toString();
    setState(() {
      fullAddress = '';
      // placemark[0].thoroughfare.toString() +
      //     ', ' +
      //     placemark[0].subLocality.toString() +
      //     ', ' +
      //     placemark[0].locality.toString() +
      //     ', ' +
      //     placemark[0].subAdministrativeArea.toString() +
      //     ', ' +
      //     placemark[0].administrativeArea.toString() +
      //     ', ' +
      //     placemark[0].postalCode.toString();

      showLabel = true;
    });
  }

  // getUserLocation() async{
  //   Position position = await Geolocator().getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  //   List<Placemark> placemark = await Geolocator().placemarkFromCoordinates(position.latitude, position.longitude);
  //   currentLocation = LatLng(position.latitude, position.longitude);
  //   locationController.text = placemark[0].thoroughfare.toString();
  //   _mapController.animateCamera(CameraUpdate.newLatLng(currentLocation));
  // }

  initLocation() async {
    if (widget.initDataKunjungan == null) {
      // Position position = await Geolocator().getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      // print(position.longitude.toString());
      isEnabledLocation(
          getGps: true,
          then: (res) {
            if (res['enabled']) {
              // currentLocation = LatLng(
              //     double.parse(res['position'].latitude.toString()),
              //     double.parse(res['position'].longitude.toString()));
            } else {
              Wh.alert(context,
                  icon: Ic.gps(),
                  message:
                      'Hidupkan GPS atau lokasi Anda untuk dapat menambahkan data penjualan.');
            }
          });
      // currentLocation = LatLng(position.latitude, position.longitude);
    } else {
      // print(widget.initData);
      // currentLocation = LatLng(widget.initDataKunjungan['latitude'],widget.initDataKunjungan['longitude']);
    }
  }

  @override
  void initState() {
    // initLocation();
    super.initState();
    // getKunjungan();
    getTipeHarga();
    // initForm();

    DateTime start = DateTime.now();
    pingLooper = Timer.periodic(Duration(seconds: 5), (Timer t) {
      setState(() {
        CheckPing().intConnection();
        CheckPing().getPingMs(start);
      });
    });

    tabController =
        new TabController(length: dataTipeKunjungan.length, vsync: this);
    tabController.addListener(() {
      TColor.azure();
    });
  }

  @override
  void dispose() {
    pingLooper.cancel();
    // if (this.mounted) {
    //   _mapController.dispose();
    //   mapController.dispose();
    // }
    super.dispose();
  }

  submit() async {
    if (toko.text.isEmpty || idToko == 0) {
      Wh.toast('Lengkapi form');
    } else {
      setState(() {
        isSubmit = true;
      });
      isEnabledLocation(
          getGps: true,
          then: (res) {
            if (res['enabled']) {
              pingLooper.cancel();

              if (widget.initData == null) {
                var pos = res['position'];
                var formData = {
                  'id_toko': idToko.toString(),
                  'tipe_pembayaran': tipePembayaran.text,
                  'tipe_harga': tipeHarga.text,
                  'po_manual': poManual.text,
                  'keterangan': keterangan.text,
                  'latitude': pos.latitude.toString(),
                  'longitude': pos.longitude.toString(),
                  'id_mitra': selectedMitra.toString()
                };

                Request.post('penjualan', formData: formData,
                    then: (status, data) {
                  Map res = decode(data); // data penjualan yang ditambahkan

                  removePrefs(list: ['activities']); // reset activity
                  Wh.toast(res['message']);

                  modal(widget.ctx,
                      child: DetailPenjualanHariIni(
                          ctx: widget.ctx,
                          dataPenjualan: res['data'][0]), then: (_) {
                    statusBar(color: Colors.transparent, darkText: false);
                    Navigator.pop(context);
                  });

                  // trigger firebase
                  // Firestore.instance
                  //     .collection('trigger_sales')
                  //     .document('penjualan')
                  //     .updateData({'trigger': timestamp().toString()});
                }, error: (err) {
                  onError(context, response: err, popup: true);
                  setState(() => isSubmit = false);
                });
              } else {
                var formData = {
                  'id_toko': idToko.toString(),
                  'id_salesman': initData['salesman'][0]['id'].toString(),
                  'tanggal': initData['tanggal'],
                  'tipe_pembayaran': tipePembayaran.text,
                  'tipe_harga': tipeHarga.text,
                  'po_manual': poManual.text,
                  'keterangan': keterangan.text,
                };

                Request.put('penjualan/' + initData['id'].toString(),
                    formData: formData, then: (status, body) {
                  Map res = decode(body);
                  // update initData
                  widget.initData['tipe_pembayaran'] = tipePembayaran.text;
                  widget.initData['tipe_harga'] = tipeHarga.text;
                  widget.initData['keterangan'] = keterangan.text;
                  widget.initData['po_manual'] = poManual.text;

                  Wh.toast(res['message']);
                  statusBar(color: Colors.transparent, darkText: false);
                  Navigator.of(context).pop();
                }, error: (err) {
                  setState(() => isSubmit = false);
                  onError(context, response: err, popup: true);
                });
              }
            } else {
              setState(() {
                isSubmit = false;
              });
              Wh.alert(context,
                  icon: Ic.gps(),
                  message:
                      'Hidupkan GPS atau lokasi Anda untuk dapat menambahkan data penjualan.');
            }
          });
    }
  }

  // submitNonEfektif()async{
  //   if(toko.text.isEmpty || idToko == 0 || listKunjungan.text.isEmpty){
  //     Wh.toast('Lengkapi Form');
  //   }else if(currentLocation == null){
  //     Wh.toast('Tidak dapat menemukan lokasi');
  //   }else{
  //     isEnabledLocation(
  //         getGps: true,
  //         then: (res){
  //           if(res['enabled']){
  //             pingLooper.cancel();
  //             setState(() {
  //               isSubmit = true;
  //             });
  //
  //             var formData = {
  //               'id_toko': idToko.toString(),
  //               'status': listKunjungan.text,
  //               'latitude': currentLocation.latitude.toString(),
  //               'longitude': currentLocation.longitude.toString(),
  //               'keterangan': keterangan.text
  //             };
  //
  //             if(widget.initDataKunjungan == null){
  //               Request.post('kunjungan_sales', formData: formData, then: (status, data) {
  //                 Map res = decode(data);
  //                 Wh.toast(res['message']);
  //                 statusBar(color: Colors.transparent, darkText: false);
  //                 modal(widget.ctx, child: KunjunganHariIni(widget.ctx), then: (_) {
  //                   statusBar(color: Colors.transparent, darkText: false);
  //                   Navigator.pop(context);
  //                 });
  //               }, error: (err) {
  //                 onError(context, response: err, popup: true);
  //                 setState(() => isSubmit = false);
  //               });
  //             }else{
  //               Request.put('kunjungan_sales/' + widget.initDataKunjungan['id'].toString(), formData: formData, then: (status, data) {
  //                 Map res = decode(data);
  //                 Wh.toast(res['message']);
  //                 statusBar(color: Colors.transparent, darkText: false);
  //                 Navigator.of(context).pop(true);
  //               }, error: (err) {
  //                 onError(context, response: err, popup: true);
  //                 setState(() => isSubmit = false);
  //               });
  //             }
  //           }else{
  //             Wh.alert(
  //                 context, icon: Ic.gps(),
  //                 message: 'Hidupkan GPS atau lokasi Anda untuk dapat menambahkan data kunjungan.'
  //             );
  //           }
  //         }
  //     );
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Unfocus(
      child: Scaffold(
        backgroundColor: TColor.silver(),
        appBar: Wh.appBar(
          context,
          title: widget.initData != null
              ? 'Edit Penjualan'
              : widget.initDataKunjungan != null
                  ? 'Edit Kunjungan'
                  : tipeKunjungan.text == 'Efektif'
                      ? 'Penjualan Baru'
                      : 'Buat Kunjungan',
          center: true,
          actions: [
            Padding(
                padding: const EdgeInsets.only(left: 5.0),
                child: pingStyle(CheckPing().getTimeRespond())),
            IconButton(
              icon: Icon(Ic.refresh(),
                  size: 20, color: loading ? Colors.black38 : Colors.black54),
              onPressed: loading
                  ? null
                  : () {
                      getTipeHarga(refill: true);
                    },
            ),
          ],
        ),
        body: loading
            ? ListSkeleton(
                length: 10,
              )
            : PreventScrollGlow(
                child: Column(
                  children: <Widget>[
                    // widget.initData != null || widget.initDataKunjungan != null ? SizedBox.shrink() : TabBar(
                    //   unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),
                    //   isScrollable: false,
                    //   labelPadding: EdgeInsets.zero,
                    //   labelColor: TColor.azure(),
                    //   indicatorWeight: 2,
                    //   indicatorColor: TColor.azure(),
                    //   controller: tabController,
                    //   tabs: List.generate(dataTipeKunjungan.length, (i){
                    //     var data = dataTipeKunjungan[i];
                    //     return Center(
                    //       child: WidSplash(
                    //           onTap: (){
                    //             setState(() {
                    //               tabController.index = i;
                    //               tipeKunjungan.text = data;
                    //             });
                    //           },
                    //           color: Colors.white,
                    //           padding: EdgeInsets.symmetric(vertical: 10),
                    //           child: Container(
                    //               width: Mquery.width(context)/dataTipeKunjungan.length,
                    //               child: text(data,
                    //                   align: TextAlign.center,
                    //                   color: tabController.index == i ? TColor.azure() : Colors.black54,
                    //                   bold: tabController.index == i ? true : false
                    //               )
                    //           )
                    //       ),
                    //     );
                    //   }),
                    // ),
                    // tabController.index == 0 ? SizedBox.shrink() : SlideDown(
                    //   child: Container(
                    //     color: TColor.gray(o: 0.5),
                    //     margin: EdgeInsets.only(bottom: 5),
                    //     width: Mquery.width(context),
                    //     height: 150,
                    //     child: Stack(
                    //       children: [
                    //         currentLocation == null ? SizedBox.shrink() : GoogleMap(
                    //           initialCameraPosition: CameraPosition(
                    //               target: currentLocation,
                    //               zoom: 15
                    //           ),
                    //           zoomControlsEnabled: true,
                    //           myLocationEnabled: true,
                    //           myLocationButtonEnabled: false,
                    //           onCameraMove: onCameraMove,
                    //           onMapCreated: onCreated,
                    //           onCameraIdle: (){
                    //             setState(() {
                    //               getMoveCamera();
                    //               showLabel = true;
                    //             });
                    //             // getUserLocation();
                    //           },
                    //         ),
                    //         Align(
                    //           alignment: Alignment.center,
                    //           child: Container(
                    //             margin: EdgeInsets.only(bottom: 45),
                    //             child: ClipRRect(
                    //                 borderRadius: BorderRadius.circular(20),
                    //                 child: Image.asset('assets/img/marker.png', height: 40, color: TColor.azure(),)
                    //             ),
                    //           ),
                    //         ),
                    //         Align(
                    //           alignment: Alignment.center,
                    //           child: Container(
                    //             margin: EdgeInsets.only(bottom: 55),
                    //             child: ClipRRect(
                    //                 borderRadius: BorderRadius.circular(20),
                    //                 child: Image.asset('assets/img/profile.png', height: 25,)
                    //             ),
                    //           ),
                    //         ),
                    //       ],
                    //     ),
                    //   ),
                    // ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(15),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              tabController.index != 1
                                  ? SizedBox.shrink()
                                  : !showLabel
                                      ? ListSkeleton(
                                          length: 1,
                                          type: 'text',
                                        )
                                      : Container(
                                          margin: EdgeInsets.only(bottom: 15),
                                          child: text(fullAddress,
                                              color: Colors.black87, size: 16),
                                        ),
                              Dropdown(
                                values: selectedMitra,
                                space: 15,
                                label: 'Mitra',
                                hint: 'Pilih Mitra',
                                item: mitraValue.map((value) {
                                  return DropdownMenuItem<String>(
                                    child: value['kode_mitra'] == null ||
                                            value['kode_mitra'] == ''
                                        ? text(value['perusahaan'])
                                        : text(value['kode_mitra'] +
                                            ' - ' +
                                            value['perusahaan']),
                                    value: value['id'].toString(),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (widget.initData != null) {
                                    Wh.toast('Tidak dapat mengedit mitra');
                                  } else {
                                    setState(() {
                                      selectedMitra = value;
                                      for (int i = 0;
                                          i < mitraValue.length;
                                          i++) {
                                        if (mitraValue[i]['id'].toString() ==
                                            value.toString()) {
                                          setState(() {
                                            selectedMitra = i.toString();
                                            print(selectedMitra);
                                          });
                                        }
                                      }
                                    });
                                  }
                                },
                              ),
                              SelectInput(
                                space: 15,
                                label: 'Pilih Toko',
                                hint: 'Pilih toko',
                                controller: toko,
                                enabled: widget.initData == null ? true : false,
                                select: () {
                                  modal(widget.ctx,
                                      radius: 5,
                                      child: DaftarToko(), then: (res) {
                                    if (res != null) {
                                      setState(() {
                                        toko.text = res['toko'];
                                        idToko = res['id'];
                                      });
                                      selectedPrice(res['tipe_harga']);
                                      // getLimitOd();
                                    }
                                  });
                                },
                              ),

                              // tabController.index == 1 || dataOd == null ? SizedBox.shrink() : loadOD ? ListSkeleton(length: 1,) : SelectInput(
                              //   space: 15,
                              //   label: 'Informasi Credit',
                              //   controller: infoOD,
                              //   select: (){
                              //     Wh.dialog(context, child: detailOD());
                              //   },
                              //   flexibleSpace: Container(
                              //     child: Column(
                              //       crossAxisAlignment: CrossAxisAlignment.start,
                              //       children: [
                              //         text('Sisa Limit: ' + ribuan(dataOd['sisa_limit'], cur: 'Rp '), size: 12),
                              //         text('Jumlah OD: ' + dataOd['od'].length.toString() + ' Invoice', size: 12),
                              //       ],
                              //     ),
                              //   ),
                              // ),

                              // widget.initData != null ? SizedBox.shrink() : Container(
                              //   margin: EdgeInsets.only(bottom: 7),
                              //   child: text('Tipe Kunjungan', bold: true),
                              // ),
                              //
                              // widget.initData != null ? SizedBox.shrink() : Container(
                              //   margin: EdgeInsets.only(bottom: 15),
                              //   child: TabBar(
                              //     unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),
                              //     isScrollable: false,
                              //     labelPadding: EdgeInsets.zero,
                              //     indicatorWeight: 2,
                              //     indicatorColor: Colors.transparent,
                              //     controller: tabController,
                              //     tabs: List.generate(dataTipeKunjungan.length, (i){
                              //       var data = dataTipeKunjungan[i];
                              //       return Center(
                              //         child: WidSplash(
                              //             onTap: (){
                              //               setState(() {
                              //                 tabController.index = i;
                              //                 tipeKunjungan.text = data;
                              //               });
                              //             },
                              //             color: tabController.index == i ? TColor.azure() : Colors.white,
                              //             padding: EdgeInsets.symmetric(vertical: 10),
                              //             border: Border(
                              //                 left: BorderSide(color: tabController.index == i ? TColor.blue(o: .5) : Colors.black12),
                              //                 top: BorderSide(color: tabController.index == i ? TColor.blue(o: .5) : Colors.black12),
                              //                 bottom: BorderSide(color: tabController.index == i ? TColor.blue(o: .5) : Colors.black12),
                              //                 right: BorderSide(color: tabController.index == i ? TColor.blue(o: .5) : Colors.black12)
                              //             ),
                              //             child: Container(
                              //                 width: Mquery.width(context)/dataTipeKunjungan.length,
                              //                 child: text(data, align: TextAlign.center, color: tabController.index == i ? Colors.white : Colors.black54)
                              //             )
                              //         ),
                              //       );
                              //     }),
                              //   ),
                              // ),

                              // tipeKunjungan.text != 'Efektif' ? tidakEfektif() : efektif()
                              efektif()
                            ]),
                      ),
                    ),

                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                      child: Button(
                        text: 'Simpan',
                        onTap: () {
                          submit();
                          // if(tipeKunjungan.text == 'Efektif'){
                          //   submit();
                          // }else{
                          //   submitNonEfektif();
                          // }
                        },
                        isSubmit: isSubmit,
                      ),
                    )

                    // Container(
                    //   padding: EdgeInsets.all(15),
                    //   child: WidSplash(
                    //     onTap: (){}, radius: BorderRadius.circular(2),
                    //     color: TColor.azure(),
                    //     child: Container(
                    //       width: Mquery.width(context),
                    //       padding: EdgeInsets.all(13),
                    //       child: text('Simpan', align: TextAlign.center, color: Colors.white),
                    //     ),
                    //   ),
                    // )
                  ],
                ),
              ),
      ),
    );
  }

  Widget tidakEfektif() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.only(bottom: 7),
          child: text('Status', bold: true),
        ),
        loadKunjungan
            ? ListSkeleton(
                length: 1,
              )
            : Container(
                margin: EdgeInsets.only(bottom: 15),
                child: TabBar(
                  unselectedLabelStyle:
                      TextStyle(fontWeight: FontWeight.normal),
                  isScrollable: false,
                  labelPadding: EdgeInsets.zero,
                  indicatorWeight: 2,
                  indicatorColor: Colors.transparent,
                  controller: kunjunganController,
                  tabs: List.generate(dataKunjungan.length, (i) {
                    var data = dataKunjungan[i];
                    return Center(
                      child: WidSplash(
                          onTap: () {
                            setState(() {
                              kunjunganController.index = i;
                              listKunjungan.text = data['value'];
                              print(listKunjungan.text);
                            });
                          },
                          color: listKunjungan.text == data['value']
                              ? TColor.azure()
                              : Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 10),
                          border: Border(
                              left: BorderSide(
                                  color: listKunjungan.text == data['value']
                                      ? TColor.blue(o: .5)
                                      : Colors.black12),
                              top: BorderSide(
                                  color: listKunjungan.text == data['value']
                                      ? TColor.blue(o: .5)
                                      : Colors.black12),
                              bottom: BorderSide(
                                  color: listKunjungan.text == data['value']
                                      ? TColor.blue(o: .5)
                                      : Colors.black12),
                              right: BorderSide(
                                  color: listKunjungan.text == data['value']
                                      ? TColor.blue(o: .5)
                                      : Colors.black12)),
                          child: Container(
                              width: Mquery.width(context) / 3,
                              child: text(data['text'],
                                  align: TextAlign.center,
                                  color: listKunjungan.text == data['value']
                                      ? Colors.white
                                      : Colors.black54))),
                    );
                  }),
                ),
              ),
        TextInput(
          maxLines: 5,
          label: 'Keterangan',
          hint: 'Inputkan keterangan',
          controller: keteranganTidakEfektif,
        ),
      ],
    );
  }

  Widget efektif() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SelectGroup(
          space: 15,
          label: 'Tipe Pembayaran',
          options: ['credit', 'cash'],
          controller: tipePembayaran,
        ),

        Container(
          child: text('Tipe Harga', bold: true),
        ),

        WidSplash(
          child: Container(
            margin: EdgeInsets.only(bottom: 15),
            child: Wrap(
              children: List.generate(dataTipeHarga.length, (i) {
                var data = dataTipeHarga;
                return Container(
                  margin: EdgeInsets.only(right: 10),
                  child: ChoiceChip(
                    label: text(data[i].toString().toUpperCase(),
                        color: selected == i ? Colors.white : Colors.black54),
                    selected: selected == i ? true : false,
                    onSelected: (isSelected) {
                      if (isSelected) {
                        setState(() {
                          selected = i;
                          tipeHarga.text = data[i].toString().toLowerCase();
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

        TextInput(
          space: 15,
          label: 'No. PO Manual',
          hint: 'Nomor po manual',
          controller: poManual,
          length: 25,
        ),

        TextInput(
          label: 'Keterangan',
          hint: 'Inputkan keterangan',
          controller: keterangan,
        ),

        // Fc.select(context, label: 'Pilih toko', hint: 'Pilih toko', options: ['lore','ipsum','dolor'], controller: toko, onSelect: (res){
        //   print(res);
        // }),

        // Fc.radio(label: 'Tipe Pembayaran', values: ['credit','cash'], radioLabels: ['Credit','Cash'], controller: tipe),

        // Fc.radio(label: 'Tipe Harga', values: ['wbp','rbp','hcobp'], radioLabels: ['Wbp','Rbp','Hcobp'], controller: tipe),

        // Fc.input(label: 'Keterangan', hint: 'Keterangan', controller: keterangan)

        // FormControl.select(context, controller: toko, label: 'Pilih Toko', onTap: (){
        //   modal(widget.ctx, child: DaftarToko(), then: (res){
        //     if(res != null && res['id'] != null)
        //     setState(() {
        //       toko.text = res['toko']; idToko = res['id'];
        //     });
        //   });
        // }),

        // FormControl.radio(label: 'Tipe Pembayaran', values: listTipePembayaran, checked: tipePembayaran, onChange: (c){
        //   setState(() => tipePembayaran = c );
        // }),

        // FormControl.radio(label: 'Tipe Harga', values: listTipeHarga, checked: tipeHarga, onChange: (c){
        //   setState(() => tipeHarga = c );
        // }),

        // FormControl.input(label: 'Keterangan', controller: keterangan, maxLines: 3),
        // FormControl.button(textButton: 'Simpan', isSubmit: isSubmit, onTap: (){
        //   savePenjualan();
        // }
      ],
    );
  }
}

class DaftarToko extends StatefulWidget {
  _DaftarTokoState createState() => _DaftarTokoState();
}

class _DaftarTokoState extends State<DaftarToko> {
  var dataToko = [],
      dataFiltered = [],
      loading = false,
      isSearch = false,
      keyword = TextEditingController();

  loadDataToko({refill: false}) async {
    request({Function then}) async {
      setState(() {
        loading = true;
      });

      Request.get('penjualan/list/toko', then: (status, data) {
        Map res = decode(data);
        then(res['data']);
      }, error: (err) {
        onError(context, response: err, popup: true);
      });
    }

    if (refill == true) {
      request(then: (val) {
        setPrefs('toko', val, enc: true);
        setState(() {
          dataFiltered = dataToko = val;
          loading = false;
        });
      });
    } else {
      getPrefs('toko', dec: true).then((res) {
        if (res != null)
          setState(() {
            dataToko = dataFiltered = res;
            loading = false;
          });
      });
    }
  }

  @override
  void initState() {
    super.initState();
    loadDataToko();
  }

  _filter(k, {clear: false}) {
    if (clear) keyword.clear();

    setState(() {
      dataFiltered = dataToko
          .where((item) =>
              item['nama_toko'].toLowerCase().contains(k) ||
              item['no_acc'].toString().toLowerCase().contains(k) ||
              item['cust_no'].toString().toLowerCase().contains(k))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Wh.appBar(context,
          title: Fc.search(
              hint: 'Ketik nama toko',
              autofocus: true,
              controller: keyword,
              change: (String s) {
                _filter(s.toLowerCase());
              }),
          actions: [
            IconButton(
              icon: Icon(keyword.text.length > 0 ? Ic.close() : Ic.refresh(),
                  size: 20, color: loading ? Colors.black38 : Colors.black54),
              onPressed: loading
                  ? null
                  : () {
                      keyword.text.length > 0
                          ? _filter('', clear: true)
                          : loadDataToko(refill: true);
                    },
            ),
            IconButton(
              icon: Icon(Ic.info(), size: 20),
              onPressed: () {
                Wh.toast(dataToko.length == 0
                    ? 'Tidak ada data toko'
                    : dataToko.length.toString() + ' Toko');
              },
            )
          ]),
      body: loading
          ? SlideUp(child: ListSkeleton(length: 10))
          : dataFiltered == null || dataFiltered.length == 0
              ? Wh.noData(
                  message: 'Tidak ada data toko, coba dengan kata kunci lain.')
              : new ListView.builder(
                  itemCount: dataFiltered.length,
                  itemBuilder: (context, i) {
                    var data = dataFiltered[i];
                    var noAcc = data['no_acc'] == null ? '' : data['no_acc'];
                    var custNo =
                        data['cust_no'] == null ? '' : ' - ' + data['cust_no'];

                    return WidSplash(
                      color: i % 2 == 0 ? TColor.silver() : Colors.white,
                      onTap: () {
                        Navigator.of(context).pop({
                          'toko': data['nama_toko'],
                          'id': data['id'],
                          'tipe_harga': data['tipe_harga']
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.all(15),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                noAcc == ''
                                    ? SizedBox.shrink()
                                    : text('[' + noAcc + '' + custNo + ']',
                                        color: TColor.black()),
                                text(data['nama_toko'].toString().toUpperCase(),
                                    bold: true,
                                    color: data['id_mitra'] == null ||
                                            data['id_mitra'].toString() == '0'
                                        ? TColor.black()
                                        : TColor.blueLight()),
                                text(data['alamat'].toString().toUpperCase(),
                                    color: data['id_mitra'] == null ||
                                            data['id_mitra'].toString() == '0'
                                        ? TColor.black()
                                        : TColor.blueLight()),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
