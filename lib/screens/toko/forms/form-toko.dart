import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sales/services/api/api.dart';
import 'package:sales/services/v2/helper.dart';
import 'package:sales/services/v3/helper.dart';
import 'package:flutter/cupertino.dart';

class FormToko extends StatefulWidget {
  FormToko(this.ctx, {this.initData}); final ctx, initData;
  _FormTokoState createState() => _FormTokoState();
} 

class _FormTokoState extends State<FormToko> {
  Timer pingLooper;

  var toko = new TextEditingController(),
      pemilik = new TextEditingController(),
      alamat = new TextEditingController(),
      telepon = new TextEditingController(),
      kodePos = new TextEditingController(),
      tipeToko = new TextEditingController(),
      kabupaten = new TextEditingController(),
      kecamatan = new TextEditingController(),
      kelurahan = new TextEditingController(),
      hari = new TextEditingController(),
      minggu = new TextEditingController();

  FocusNode nodeToko = FocusNode(), 
            nodePemilik = FocusNode(), 
            nodeAlamat = FocusNode(),
            nodeTelp = FocusNode(),
            nodePos = FocusNode();

  bool isSubmit = false, request = false;
  List listKabupaten = [], listKecamatan = [], listKelurahan = [];
  String idKelurahan;

  getKabupaten(){
    setState(() {
      request = true;
      kabupaten.clear();
      kecamatan.clear();
      kelurahan.clear();

      listKabupaten = listKecamatan = listKelurahan = [];
    });

    Request.get('daerah?type=kabupaten', then: (_, data){
      listKabupaten = decode(data)['data'];
      setState(() => request = false );
    }, error: (err){
      onError(context, response: err, popup: true);
    });
  }

  getKecamatan(String id){
    setState(() {
      request = true;
      kecamatan.clear();
      kelurahan.clear();

      listKecamatan = listKelurahan = [];
    });

    Request.get('daerah?type=kecamatan&parent_id='+id, then: (_, data){
      listKecamatan = decode(data)['data'];
      setState(() => request = false );
    }, error: (err){
      onError(context, response: err, popup: true);
    });
  }

  getKelurahan(String id){
    setState(() {
      request = true;
      kelurahan.clear();
    });

    Request.get('daerah?type=kelurahan&parent_id='+id, then: (_, data){
      listKelurahan = decode(data)['data'];
      setState(() => request = false );
    }, error: (err){
      onError(context, response: err, popup: true);
    });
  }

  submit() async{
    // print('object');

    var location = await Gps.enabled();

    if(!location){
      Wh.toast('Aktifkan GPS untuk menambahkan toko');
    }else{
      var position = await Gps.latlon();

      var formData = {
        'nama_toko': toko.text,
        'alamat': alamat.text,
        'telepon': telepon.text,
        'pemilik': pemilik.text,
        'kode_pos': kodePos.text,
        'tipe': tipeToko.text,
        'id_kelurahan': idKelurahan,
        'limit': '0',
        'top': '0',
        'mmminggu': '1&3',
        'hari': 'senin',
        'latitude': position.latitude.toString(),
        'longitude': position.longitude.toString(),
        'status_verifikasi': 'N'
      };

      if(toko.text.isEmpty || alamat.text.isEmpty || telepon.text.isEmpty || pemilik.text.isEmpty || tipeToko.text.isEmpty || idKelurahan == null){
        Wh.toast('Lengkapi form');
      }else{

        setState(() {
          isSubmit = true;
        });

        Request.post('toko', formData: formData, debug: true, then: (_, data){
          Navigator.pop(context, {'added': true});
        }, error: (err){
          onError(context, response: err, popup: true);
          setState(() => isSubmit = false );
        });

      }

    }
  }

  // var kabupaten = '', kecamatan = '', kelurahan = '';
  // var kabLoader = true, kecLoader = false, kelLoader = false, kecEnable = false, kelEnable = false, isSave = false, loader = false;
  // var textPadding = 15.0, type, idKelurahan = 0, tipeToko = 'R1', tipePembayaran = 'Kredit', hari = 'Senin', minggu = '1&3';
  // var dataKabupaten = [], dataKecamatan = [], dataKelurahan = [], dataFiltered = [], ttIndex = 0, selectTt = 0;

  // var listTipeToko = ['R1', 'R2', 'W', 'MM', 'KOP', 'HRC', 'HCO'];

  // // focus node
  // var fnPemilik = new FocusNode();
  // var fnAlamat = new FocusNode();
  // var fnTelepon = new FocusNode();
  // var fnPos = new FocusNode();


  // initInput(){
  //   if(widget.data != null){
  //     var toko = widget.data;

  //     namaToko.text = toko['nama_toko'];
  //     namaPemilik.text = toko['pemilik'];
  //     alamatToko.text = toko['alamat'];
  //     hp.text = toko['telepon'];
  //     kodePos.text = toko['kode_pos'];
  //     kabupaten = toko['kabupaten'].toString().toUpperCase();
  //     tipeToko = toko['tipe'];
  //     tipePembayaran = ucwords(toko['k_t']);
  //     hari = ucwords(toko['hari']);
  //     idKelurahan = int.parse(toko['id_kelurahan']);
  //     minggu = toko['minggu']; 

  //     _init();  
  //   }
  // }

  // loadDataKabupaten() async {
  //   var prefs = await SharedPreferences.getInstance();

  //   getData() async {
  //     setState(() { kabLoader = true; });

  //     Request.get('daerah?type=kabupaten', then: (_, data){
  //       Map res = json.decode(data);
  //       return res['data'];
  //     }, error: (err){
  //       onError(context, response: err, popup: true);
  //     });
  //   }

  //   var data = prefs.getString('data_kabupaten');

  //   // jika data kabupaten di localstorage ada, ambil dari localstorage
  //   if(data != null){
  //     dataKabupaten = json.decode(data);
  //     setState(() { kabLoader = false; });
  //   }else{
  //     getData().then((v){
  //       prefs.setString('data_kabupaten', json.encode(v));
  //       prefs.setBool('kabupaten', true); // tandai kabupaten terisi
  //       setState(() {
  //         dataKabupaten = v;
  //         kabLoader = false;
  //       });
  //     });
  //   }
  // }

  // _init() {
  //   setState(() {
  //     loader = true;
  //   });
    
  //   loadDataKeluarahan() async{
  //     var prefs = await SharedPreferences.getInstance(),
  //         ik = widget.data['id_kecamatan'];

  //     getData() async {
  //       Request.get('daerah?type=kelurahan&parent_id='+ik.toString(), then: (_, data){
  //         Map res = json.decode(data);
  //         return res['data'];
  //       }, error: (err){
  //         onError(context, response: err, popup: true);
  //       });
  //     }

  //     var data = prefs.getString(ik.toString());
  //     if(data == null){ 
  //       getData().then((v){
  //         setState(() {
  //           dataKelurahan = v;
  //           prefs.setString(ik.toString(), json.encode(v));
  //           kelLoader = false;
  //           kelEnable = true;
  //           kelurahan = widget.data['kelurahan'].toString().toUpperCase();

  //         });
  //       });
  //     }else{
  //       setState(() {
  //         dataKelurahan = json.decode(data);
  //         kelLoader = false;
  //         kelEnable = kelEnable = true;
  //         kelurahan = widget.data['kelurahan'].toString().toUpperCase();
  //       });
  //     }
  //   }

  //   loadDataKecamatan() async {
  //     var prefs = await SharedPreferences.getInstance(),
  //         ik = widget.data['id_kabupaten'];

  //     getData() async {
  //       setState(() { kecLoader = true; });

  //       Request.get('daerah?type=kecamatan&parent_id='+ik.toString(), then: (_, data){
  //         Map res = json.decode(data);
  //         return res['data'];
  //       }, error: (err){
  //         onError(context, response: err, popup: true);
  //       });
  //     }

  //     var data = prefs.getString(ik.toString());
  //     if(data == null){ 
  //       getData().then((v){
  //         setState(() {
  //           dataKecamatan = v;
  //           prefs.setString(ik.toString(), json.encode(v));
  //           kecLoader = false;
  //           kecEnable = true;
  //           kecamatan = widget.data['kecamatan'].toString().toUpperCase();
  //         });
  //         loadDataKeluarahan();
  //       });
  //     }else{ 
  //       setState(() {
  //         dataKecamatan = json.decode(data);
  //         kecLoader = false;
  //         kecEnable = kelEnable = true;
  //         kecamatan = widget.data['kecamatan'].toString().toUpperCase();
  //       });
  //       loadDataKeluarahan();
  //     }
  //   }

  //   loadDataKabupaten() async {
  //     var prefs = await SharedPreferences.getInstance();

  //     getData() async {
  //       setState(() { kabLoader = true; });

  //       Request.get('daerah?type=kabupaten', then: (_, data){
  //         Map res = json.decode(data);
  //         return res['data'];
  //       }, error: (err){
  //         onError(context, response: err, popup: true);
  //       });

  //     }

  //     var data = prefs.getString('data_kabupaten');

  //     // jika data kabupaten di localstorage ada, ambil dari localstorage
  //     if(data != null){
  //       dataKabupaten = json.decode(data);
  //       loadDataKecamatan();
  //       setState(() { kabLoader = loader = false; });
  //     }else{
  //       getData().then((v){
  //         prefs.setString('data_kabupaten', json.encode(v));
  //         prefs.setBool('kabupaten', true); // tandai kabupaten terisi
  //         loadDataKecamatan();
  //         setState(() {
  //           dataKabupaten = v;
  //           kabLoader = loader = false;
  //         });
  //       });
  //     }

  //   }
    
  //   loadDataKabupaten();
  // }

  @override
  void initState() {
    super.initState();
    getKabupaten();

    DateTime start = DateTime.now();
    pingLooper = Timer.periodic(Duration(seconds: 5), (Timer t) {
      setState(() {
        CheckPing().intConnection();
        CheckPing().getPingMs(start);
      });
    });
  }

  @override
  void dispose() {
    if (this.mounted) {
      pingLooper.cancel();
    }
    super.dispose();
  }

  void saveToko() async {
    // var prefs = await SharedPreferences.getInstance();
    // if( namaToko.text == '' || namaPemilik.text == '' || alamatToko.text == ''){
    //   Wh.toast('Lengkapi form');
    // }else{
      // submit(){
      //   setState(() { isSave = true; });

      //   var data = {'nama_toko':namaToko.text, 'pemilik':namaPemilik.text, 'alamat':alamatToko.text, 'telepon':hp.text, 'kode_pos':kodePos.text, 'tipe':tipeToko, 'id_kelurahan':idKelurahan.toString(), 'k_t':tipePembayaran.toLowerCase(), 'limit':'500000', 'hari':hari.toLowerCase(), 'minggu': minggu};
      //   if(widget.data != null){
      //     http.put( api('toko/'+widget.data['id'].toString()) , body: data, headers: {HttpHeaders.authorizationHeader: prefs.getString('token'), "Accept": "application/json"}).then((response) async {
      //       Map res = json.decode(response.body);
      //       if(response.statusCode == 201){
      //         toast('Tersimpan');
      //         Navigator.pop(context, {'updated': true});
      //       }else{
      //         toast(res['message']);
      //       }

      //       setState(() { isSave = false; });
      //     });
      //   }else{
      //     http.post( api('toko'), body: data, headers: {HttpHeaders.authorizationHeader: prefs.getString('token'), "Accept": "application/json"}).then((response) async {
      //       Map res = json.decode(response.body);
      //       if(response.statusCode == 201){
      //         toast('Tersimpan');
      //         Navigator.pop(context, {'added': true});
      //       }else{
      //         toast(res['message']);
      //       }

      //       setState(() { isSave = false; });
      //     });
      //   }
      // }

      // checkConnection().then((con){
      //   if(con){
      //     submit();
      //   }else{
      //     box(context, title: 'Periksa koneksi internet Anda');
      //     setState(() { isSave = false; });
      //   }
      // });

    // }
  }

  @override
  Widget build(BuildContext context) {
    return Unfocus(
      child: Scaffold(
          backgroundColor: TColor.silver(),
          appBar: Wh.appBar(context, title: widget.initData != null ? 'Edit Toko' : 'Tambah Toko', actions: [
            pingStyle(CheckPing.timeRespond),
            IconButton(
              icon: request ? Wh.spiner(size: 17) : Icon(Ic.refresh(), size: 20),
              onPressed: request ? null : (){
                getKabupaten();
              },
            ),
          ]),

          body: PreventScrollGlow(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[

                  TextInput(
                    label: 'Nama Toko',
                    hint: 'Nama toko',
                    controller: toko,
                    node: nodeToko,
                    action: TextInputAction.next,
                    submit: (String _){
                      focus(context, nodePemilik);
                    },
                  ),

                  TextInput(
                    label: 'Nama Pemilik',
                    hint: 'Nama pemilik toko',
                    controller: pemilik,
                    node: nodePemilik,
                    action: TextInputAction.next,
                    submit: (String _){
                      focus(context, nodeAlamat);
                    },
                  ),

                  TextInput(
                    label: 'Alamat Toko',
                    hint: 'Alamat toko',
                    controller: alamat,
                    node: nodeAlamat,
                    action: TextInputAction.next,
                    submit: (String _){
                      focus(context, nodeTelp);
                    },
                  ),

                  TextInput(
                    label: 'Nomor Telepon',
                    hint: 'Nomor telepon',
                    controller: telepon,
                    type: TextInputType.datetime,
                    length: 15,
                    node: nodeTelp,
                    action: TextInputAction.next,
                    submit: (String _){
                      focus(context, nodePos);
                    },
                  ),

                  TextInput(
                    label: 'Kode Pos',
                    hint: 'Kode pos',
                    controller: kodePos,
                    type: TextInputType.datetime,
                    length: 5,
                    node: nodePos,
                    action: TextInputAction.next,
                    submit: (String _){
                      focus(context, FocusNode());
                    },
                  ),

                  SelectCupertino(
                    label: 'Tipe Toko', controller: tipeToko,
                    hint: 'Pilih tipe toko',
                    options: ['R1', 'R2', 'W', 'MM', 'KOP', 'HRC', 'HCO']
                  ),

                  SelectCupertino(
                    label: 'Kabupaten', controller: kabupaten,
                    hint: 'Pilih kabupaten', enabled: listKabupaten.length > 0,
                    options: listKabupaten.map((i) => i['nama_kabupaten']).toList(),
                    values: listKabupaten.map((i) => i['id']).toList(),
                    select: (res){
                      getKecamatan(res['value']);
                    },
                  ),

                  SelectCupertino(
                    label: 'Kecamatan', controller: kecamatan,
                    hint: 'Pilih kecamatan', enabled: listKecamatan.length > 0,
                    options: listKecamatan.map((i) => i['nama_kecamatan']).toList(),
                    values: listKecamatan.map((i) => i['id']).toList(),
                    select: (res){
                      getKelurahan(res['value']);
                    },
                  ),

                  SelectCupertino(
                    label: 'Kelurahan', controller: kelurahan,
                    hint: 'Pilih kelurahan', enabled: listKelurahan.length > 0,
                    options: listKelurahan.map((i) => i['nama_kelurahan']).toList(),
                    values: listKelurahan.map((i) => i['id']).toList(),
                    select: (res){
                      idKelurahan = res['value'];
                    },
                  ),

                  Button(
                      text: 'Simpan',
                      onTap: submit,
                      isSubmit: isSubmit
                  ),
                ],
              ),
            ),
          )
      ),
    );
        
    //     body: ScrollConfiguration(
    //       behavior: PreventScrollGlow(),
    //       child: Container(
    //         child: 
    //           new ListView(
    //             padding: EdgeInsets.only(left: 15, right: 15, top: 7, bottom: 15),
    //             shrinkWrap: true,
    //             children: <Widget>[
    //             new Column(
    //             children: <Widget>[

    //               FormControl(context).input(label: 'Nama Toko', hint: '', bottom: 0, controller: namaToko, action: TextInputAction.next, onSubmit: (String v){
    //                 FocusScope.of(context).requestFocus(fnPemilik);
    //               }),

    //               FormControl(context).input(label: 'Nama Pemilik', hint: '', bottom: 0, controller: namaPemilik, focusNode: fnPemilik, action: TextInputAction.next, onSubmit: (String v){
    //                 FocusScope.of(context).requestFocus(fnAlamat);
    //               }),

    //               FormControl(context).input(label: 'Alamat Toko', hint: '', bottom: 0, controller: alamatToko, focusNode: fnAlamat, action: TextInputAction.next, onSubmit: (String v){
    //                 FocusScope.of(context).requestFocus(fnTelepon);
    //               }),

    //               FormControl(context).input(label: 'Nomor Telepon', hint: '', type: TextInputType.number, maxLength: 17, bottom: 0, controller: hp, action: TextInputAction.next, focusNode: fnTelepon, onSubmit: (String v){
    //                 FocusScope.of(context).requestFocus(fnPos);
    //               }),

    //               FormControl(context).input(label: 'Kode Pos', hint: '', type: TextInputType.number, maxLength: 5, bottom: 0, controller: kodePos, focusNode: fnPos),

    //               FormControl(context).dropdown(context,
    //                 label: 'Tipe Toko',
    //                 items: ['R1', 'R2', 'W', 'MM', 'KOP', 'HRC', 'HCO'],
    //                 value: tipeToko,
    //                 onChange: (String val){
    //                   FocusScope.of(context).requestFocus(new FocusNode());
    //                   setState(() {
    //                     tipeToko = val;
    //                   });
    //                 }
    //               ),

    //               FormControl(context).select(context,
    //                 label: 'Pilih Kabupaten', top: 15,
    //                 value: kabupaten == null ? '' : kabupaten,
    //                 enable: !kabLoader,
    //                 onTap: (){
    //                   if(!kabLoader) {_modal(1);}
    //                 }
    //               ),

    //               FormControl(context).select(context,
    //                 label: 'Pilih Kecamatan',
    //                 value: kecamatan == null ? '' : kecamatan,
    //                 enable: kecEnable,
    //                 onTap: (){
    //                   if(kecEnable) {_modal(2);}
    //                 }
    //               ),

    //               FormControl(context).select(context,
    //                 label: 'Pilih Kelurahan',
    //                 value: kelurahan == null ? '' : kelurahan,
    //                 enable: kelEnable,
    //                 onTap: (){
    //                   if(kelEnable) {_modal(3);}
    //                 }
    //               ),

    //               FormControl(context).dropdown(context,
    //                 label: 'Tipe Pembayaran',
    //                 items: ['Kredit','Tunai'],
    //                 value: tipePembayaran,
    //                 onChange: (String val){
    //                   FocusScope.of(context).requestFocus(new FocusNode());
    //                   setState(() {
    //                     tipePembayaran = val;
    //                   });
    //                 }
    //               ),

    //               FormControl(context).dropdown(context,
    //                 label: 'Pilih Hari',
    //                 items: ['Senin','Selasa','Rabu','Kamis','Jumat','Sabtu'],
    //                 value: hari,
    //                 onChange: (String val){
    //                   FocusScope.of(context).requestFocus(new FocusNode());
    //                   setState(() {
    //                     hari = val;
    //                   });
    //                 }
    //               ),

    //               FormControl(context).dropdown(context,
    //                 label: 'Pilih Minggu',
    //                 items: ['1&3','2&4','1-4'],
    //                 value: minggu,
    //                 onChange: (String val){
    //                   FocusScope.of(context).requestFocus(new FocusNode());
    //                   setState(() {
    //                     minggu = val;
    //                   });
    //                 }
    //               ),

    //               FormControl(context).button(label: isSave ? spin(color: Colors.white) : text('Simpan', color: Colors.white), marginY: 5, onPressed: isSave ? null : saveToko),

    //             ]),
    //           ]
    //         )
    //       ),
    // ));
  }

  // MODAL KECAMATARAN
  // void _modal(int type){
  //   this.setState(() {
  //     this.type = type;

  //     if( type == 1 ){ this.dataFiltered = this.dataKabupaten; }
  //     else if( type == 2 ){ this.dataFiltered = this.dataKecamatan; }
  //   });

  //   showModalBottomSheet(
  //     context: context,
  //     builder: (context){

  //       return Container(
  //         child: Column(
  //           children: <Widget>[
  //           Expanded(
  //           child: ListView.builder(
  //               itemCount: type == 1 ? this.dataKabupaten.length : type == 2 ? this.dataKecamatan.length : this.dataKelurahan.length,
  //               itemBuilder: (context, i) {
  //                 var data = type == 1 ? this.dataKabupaten[i] : type == 2 ? this.dataKecamatan[i] : this.dataKelurahan[i];

  //                 return new GestureDetector(
  //                     onTap: () {
  //                       switch (type) {
  //                         case 1:
  //                           // _pilihKabupaten(data['nama_kabupaten'], data['id']); break;
  //                         case 2:
  //                           // _pilihKecamatan(data['nama_kecamatan'], data['id']); break;
  //                         default:
  //                           // _pilihKelurahan(data['nama_kelurahan'], data['id']); break;
  //                       }
  //                     },
  //                     child: new Container(
  //                       decoration: BoxDecoration(
  //                         border: Border(
  //                           bottom: BorderSide(
  //                               width: 1.0, color: Colors.black12),
  //                         ),
  //                       ),
  //                       child: 
  //                       new Column(
  //                         children: <Widget>[
  //                           new Container(
  //                             color: i % 2 == 0 ? Color.fromRGBO(0, 0, 0, 0.05) : Colors.white,
  //                               padding: EdgeInsets.all(15),
  //                               child: new Align(
  //                                 alignment: Alignment.centerLeft,
  //                                 child: new Column(
  //                                   crossAxisAlignment:
  //                                       CrossAxisAlignment.start,
  //                                   children: <Widget>[
  //                                     Text(type == 1 ? data['nama_kabupaten'] : type == 2 ? data['nama_kecamatan'] : data['nama_kelurahan']),
  //                                   ],
  //                                 ),
  //                               ))
  //                         ],
  //                       ),
  //                     ));
  //               }),
  //             ),
  //           ],
  //         )
  //       );
  //     }
  //   );
  // }

  // void _pilihKabupaten(String nk, int ik) async{
  //   var prefs = await SharedPreferences.getInstance();
  //   Navigator.pop(context);

  //   setState(() {
  //     kabupaten = nk; kecamatan = ''; kelurahan = ''; loader = true;
  //     kecLoader = true;
  //     kecEnable = false;
  //   });

  //   getPilihKecamatan() async {
  //     setState(() { kecLoader = true; kecEnable = kelEnable = false; loader = true; });
  //     http.Response result = await http.get(
  //     Uri.encodeFull( api('daerah?type=kecamatan&parent_id='+ik.toString())),
  //     headers: {HttpHeaders.authorizationHeader: prefs.getString('token'), "Accept": "application/json"});
  //     Map res = json.decode(result.body);
  //     return res['data'];
  //   }

  //   var data = prefs.getString(ik.toString());
  //   if(data == null){
  //     getPilihKecamatan().then((v){
  //       setState(() {
  //         dataKecamatan = v;
  //         prefs.setString(ik.toString(), json.encode(v));
  //         kecLoader = kelEnable = false;
  //         kecEnable = true; loader = false;
  //       });
  //     });
  //   }else{
  //     setState(() {
  //       dataKecamatan = json.decode(data);
  //       kecLoader = kelEnable = false; loader = false;
  //       kecEnable = true;
  //     });
  //   }

  //   FocusScope.of(context).requestFocus(new FocusNode());
  // }

  // void _pilihKecamatan(String nk, int ik) async{
  //   var prefs = await SharedPreferences.getInstance();
  //   Navigator.pop(context);

  //   setState(() {
  //     kecamatan = nk; kelurahan = ''; loader = true;
  //     kelLoader = true;
  //     kelEnable = false;
  //   });

  //   getPilihKelurahan() async {
  //     setState(() { kelLoader = true; kelEnable = false; });
  //     http.Response result = await http.get(
  //     Uri.encodeFull( api('daerah?type=kelurahan&parent_id='+ik.toString()) ),
  //     headers: {HttpHeaders.authorizationHeader: prefs.getString('token'), "Accept": "application/json"});
  //     Map res = json.decode(result.body);
  //     return res['data'];
  //   }

  //   var data = prefs.getString(ik.toString());
  //   if(data == null){
  //     getPilihKelurahan().then((v){
  //       setState(() {
  //         dataKelurahan = v;
  //         prefs.setString(ik.toString(), json.encode(v));
  //         kelLoader = false;
  //         kelEnable = true; loader = false;
  //       });

  //     });
  //   }else{
  //     setState(() {
  //       dataKelurahan = json.decode(data);
  //       kelLoader = false; loader = false;
  //       kelEnable = kelEnable = true;
  //     });
  //   }

  //   FocusScope.of(context).requestFocus(new FocusNode());
  // }

  // void _pilihKelurahan(String nk, int ik){
  //   Navigator.pop(context);
  //   setState(() {
  //     kelurahan = nk;
  //     idKelurahan = ik;
  //   });
  //   FocusScope.of(context).requestFocus(new FocusNode());
  // }
}


// 575
