// import 'package:flutter/material.dart';
// import 'package:sales/services/helper.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// import '../detail-penjualan-hari-ini.dart';

// class TambahPenjualan extends StatefulWidget {
//   final ctx, paddingTop;
//   TambahPenjualan(this.ctx, {this.paddingTop});

//   _TambahPenjualanState createState() => _TambahPenjualanState();
// }

// class _TambahPenjualanState extends State<TambahPenjualan> {
//   var toko = TextEditingController(),
//       keterangan = TextEditingController();

//   var tipePembayaran = 'credit', tipeHarga = 'wbp';
//   var loaded = true, isSave = false, idToko = 0;
//   var dataToko = [], dataFiltered = [], penjualanHariIni, tbIndex = 1, selectTb = 1, thIndex = 0, selectTh = 0;

//   var tpRadio = 0;

//   var listTipePembayaran = ['credit','cash'];
//   var listTipeHarga = ['wbp', 'rbp', 'hcobp'];

//   initForm() async{
//     // var prefs = await SharedPreferences.getInstance();
//     // var salesman = decode(prefs.getString('log_salesman'));

//     getPrefs('log_salesman', dec: true).then((res){
//       setState(() {
//         if(res['tipe'] == 'canvass'){
//           // tipePembayaran = 'cash'; tbIndex = 0; selectTb = 0;
//           tpRadio = 0; tipePembayaran = 'cash';
//           tipeHarga = 'rbp'; thIndex = 1; selectTh = 1;
//         }
//       });
//     });

//   }

//   @override
//   void initState() {
//     super.initState();
//     initForm();
//   }

//   void savePenjualan() async {

//     if( toko.text.isEmpty || toko == null || idToko == 0){
//       Wi.toast('Lengkapi form');
//     }else{
//       bool isLocationEnabled = await Geolocator().isLocationServiceEnabled();
//       Geolocator geolocator = Geolocator()..forceAndroidLocationManager = true;

//       if (isLocationEnabled) {
//         Position position = await geolocator.getLastKnownPosition(desiredAccuracy: LocationAccuracy.high);

//         if (position == null) {
//           position = await geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
//         }
        
//         var formData = {'id_toko': idToko.toString(), 'tipe_pembayaran': tipePembayaran.toLowerCase(), 'tipe_harga': tipeHarga, 'per_page': '1', 'keterangan': keterangan.text, 'latitude': position.latitude.toString(), 'longitude': position.longitude.toString()};

//         void submit() {
//           setState(() { isSave = true; });

//           Api.post('penjualan', formData: formData, then: (status, data){
//             Map res = decode(data);

//             if(status == 201 || status == 200){

//               setPrefs('penjualan_baru', true);

//               modal(widget.ctx, child: DetailPenjualanHariIni(ctx: widget.ctx, dataPenjualan: res['data'][0], isNew: true), then: (res){
//                 if(res == null) Navigator.pop(context);
//               });

//               // trigger firebase
//               Firestore.instance.collection('trigger_sales').document('penjualan').updateData({ 'trigger': timestamp().toString() });
//             }else{
//               setState(() => isSave = false );
//               Wi.toast(res['message']);
//             }

//           }, error: (err){
//             Message.error(err);
//             setState(() => isSave = false );
//           });
//         }

//         checkConnection().then((con){
//           if(con){
//             submit();
//           }else{
//             Wi.box(context, title: 'Periksa koneksi internet Anda');
//             setState(() { isSave = false; });
//           }
//         });

//       } else {
//         Wi.box(context, title: 'Mohon aktifkan GPS Anda', message: 'Aksi ini membutuhkan titik lokasi yang benar.');
//         setState(() {
//           isSave = false;
//         });
//       }
      
//     }
//   }

//   @override
//   Widget build(BuildContext context) {

//     return Scaffold(
//       appBar: Wi.appBar(context, title: 'Penjualan Baru', actions: [
//         IconButton(
//           icon: Icon(Icons.info_outline),
//           onPressed: (){
//             Wi.box(context, title: 'Informasi', message: 'Untuk menambahkan penjualan setiap pengguna wajib untuk mengaktifkan Gps agar sistem dapat membaca lokasi dimana penjualan diinputkan. <br><br> Penggunaan Fake Gps akan dikenakan sangsi. Sistem akan mengedintifikasi apabila perangkat terbaca menggunakan Fake Gps.');
//           },
//         )
//       ]),

//       body: PreventScrollGlow(
//         child: SingleChildScrollView(
//           padding: EdgeInsets.all(15),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [

//               FormControl.select(context, controller: toko, label: 'Pilih Toko', onTap: (){
//                 modal(widget.ctx, child: DaftarToko(), then: (res){
//                   if(res != null && res['id'] != null)
//                   setState(() {
//                     toko.text = res['toko']; idToko = res['id'];
//                   });
//                 });
//               }),

//               FormControl.radio(label: 'Tipe Pembayaran', values: listTipePembayaran, checked: tipePembayaran, onChange: (c){
//                 setState(() => tipePembayaran = c );
//               }),

//               FormControl.radio(label: 'Tipe Harga', values: listTipeHarga, checked: tipeHarga, onChange: (c){
//                 setState(() => tipeHarga = c );
//               }),

//               FormControl.input(label: 'Keterangan', controller: keterangan, maxLines: 3),
//               FormControl.button(textButton: 'Simpan', isSubmit: isSave, onTap: (){
//                 savePenjualan();
//               })

//             ]
//           ),
//         ),
//       ),
//     );
    
//   }

// }

// class DaftarToko extends StatefulWidget {
//   _DaftarTokoState createState() => _DaftarTokoState();
// }

// class _DaftarTokoState extends State<DaftarToko> {
//   var dataToko = [], dataFiltered = [], loaded = false, isSearch = false, keyword = TextEditingController();

//   loadDataToko({refill: false}) async {
//     request({Function then}) async {
//       setState(() { loaded = false; });

//       Api.get('toko', then: (status, data){
//         Map res = decode(data);
//         then(res['data']);
//       }, error: (err){
//         Message.error(err);
//       });
//     }

//     if(refill == true){
//       request(then: (val){
//         setPrefs('toko', val, enc: true);
//         setState(() {
//           dataFiltered = dataToko = val;
//           loaded = true;
//         });
//       });
//     }else{
//       getPrefs('toko', dec: true).then((res){
//         setState(() {
//           dataToko = dataFiltered = res;
//           loaded = true;
//         });
//       });
//     }
//   }

//   @override
//   void initState() {
//     super.initState();
//     loadDataToko();
//   }

//   @override
//   Widget build(BuildContext context) {

//     return SafeArea(
//       child: Scaffold(
//         appBar: Wi.appBar(context, title: 
//           FormControl.search(hint: 'Ketik nama toko', autofocus: true, onChange: (String s){
//             var k = s.toLowerCase();
//             setState(() {
//               dataFiltered = dataToko.where((item) => item['nama_toko'].toLowerCase().contains(k)).toList();
//             });
//           }), actions: [

//             IconButton(
//               icon: Icon(Icons.refresh, color: !loaded ? Colors.black26 : Colors.black87),
//               onPressed: !loaded ? null : (){ loadDataToko(refill: true); },
//             )

//           ]),
        
//         body: !loaded ? Wi.spiner(size: 50) :
        
//          new Container(
//           color: Colors.white,
//           child: dataFiltered == null || dataFiltered.length == 0 ? Wi.noData(message: 'Data tidak ditemukan') :
//           new ListView.builder(
//             itemCount: dataFiltered.length,
//             itemBuilder: (context, i) {
//               var data = dataFiltered[i];

//               var noAcc = data['no_acc'] == null ? '' : data['no_acc'];
//               var custNo = data['cust_no'] == null ? '' : ' - '+data['cust_no'];
              
//               return Button(
//                 color: i % 2 == 0 ? Color.fromRGBO(0, 0, 0, 0.05) : Colors.white,
//                 onTap: (){
//                   Navigator.of(context).pop({'toko': data['nama_toko'], 'id': data['id']});
//                 },
//                 child: Container(
//                   padding: EdgeInsets.all(15),
//                   child: Row( mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: <Widget>[
//                       Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: <Widget>[
//                           noAcc == '' ? SizedBox.shrink() : text('['+noAcc+''+custNo+']'),
//                           text(data['nama_toko']),
//                         ],
//                       ),
//                     ],
//                   )
//                 )
//               );

//             },
//           ),
//         ),
//       ),
//     );
  
//   }
// }
