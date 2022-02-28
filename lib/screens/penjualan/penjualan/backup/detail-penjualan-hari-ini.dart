// import 'package:flutter/material.dart';
// import 'package:sales/screens/penjualan/pelunasan/detail-pelunasan.dart';
// import 'package:sales/services/api/api.dart';
// import 'package:sales/services/helper.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'dart:async';

// import 'package:blue_thermal_printer/blue_thermal_printer.dart';
// import 'package:flutter/services.dart';

// import 'edit_penjualan.dart';
// import 'form_barang.dart';

// class DetailPenjualanHariIni extends StatefulWidget {
//   final ctx, dataPenjualan, isNew, readOnly, paddingTop;
//   const DetailPenjualanHariIni({this.ctx, this.dataPenjualan, this.isNew: false, this.readOnly: false, this.paddingTop});

//   @override
//   _DetailPenjualanHariIniState createState() => _DetailPenjualanHariIniState();
// }

// class _DetailPenjualanHariIniState extends State<DetailPenjualanHariIni> {

//   // declare variable 
//   var loader = true, loaderTotal = true, printPermission = false, approvePermission = false,
//       data, details = [], detValue = [], detailBarang = [], penjualan, ___tipeHarga = '', status = 'waiting';

//   loadData() async {
//     status = widget.dataPenjualan['status'];

//     var prefs = await SharedPreferences.getInstance(), id = data['id'],
//         logSales = decode(prefs.getString('log_salesman'));

//     prefs.remove('epTb');
//     prefs.remove('epTh');
//     prefs.remove('epKt');

//     setState(() {
//       loader = true;
//     });

//     Request.get('penjualan/'+id.toString(), then: (status, data){
//       printPermission = true;
//       if(logSales != null && logSales['tipe'] == 'to'){
//         printPermission = false;
//       }
      
//       if(logSales != null && logSales['tipe'] == 'canvass'){
//         approvePermission = true;
//       }

//       if(mounted){
//         setState(() {
//           Map res = decode(data);
//           penjualan = res['data'];
//           loaderTotal = false;
//         });
//       }
//     }, error: (err){
//       onError(context, response: err, popup: true, backOnDismiss: true);
//     });

//     Api.get('detail_penjualan/'+id.toString()+'/detail', then: (status, data){
//       if(mounted){
//         setState(() {
//           Map res = decode(data);
//           this.loader = false;
//           this.detailBarang = res['data'];
//         });
//       }
//     }, error: (err){
//       Message.error(err);
//     });

//   }

//   _confirm(res) async {
//     if(res != null && res == 1){
//       Wi.dialog(context, transparent: true, dismiss: false, child: Wi.spiner(size: 35, color: Colors.white, margin: 15));

//       var url = 'penjualan/'+penjualan['id'].toString()+(status == 'waiting' ? '/approve' : '/cancel_approval');

//       Api.post(url, then: (s, data){
//         var invoice = decode(data)['no_invoice'];

//         Navigator.pop(context);
//         Wi.toast(status == 'waiting' ? 'Berhasil disetujui' : 'Batal disetujui');

//         setState((){
//           status = status == 'waiting' ? 'approved' : 'waiting';
//           this.widget.dataPenjualan['no_invoice'] = invoice;
//           penjualan['no_invoice'] = invoice;
//         });
//       }, error: (err){
//         Message.error(err);
//       });
//     }
//   }
  
//   @override
//   void initState() {
//     data = widget.dataPenjualan; loadData();
//     super.initState();
//   }

//   Future<Null> _onRefresh() async {
//     loadData();
//   }

//   Future<bool> onWillPop() {
//     if (widget.isNew == true) {
//       Navigator.of(context).pop({'is_new': true}); 
//       // Navigator.of(context).pop();
//     }
//     return Future.value(true);
//   }

//   @override
//   Widget build(BuildContext context) {
//     Widget widget = loader ? SizedBox.shrink() :

//     detailBarang == null || detailBarang.length == 0 ? Wi.noData(message: 'Tidak ada data barang\nTap icon untuk memuat ulang', onTap: (){ loadData(); }) : 
    
//     new SafeArea(
//       child: Column(
//       children: <Widget>[
//         Expanded(
//           child: ListView.builder(
//               itemCount: detailBarang.length,
//               itemBuilder: (context, i) {
//                 var data = detailBarang[i];

//               return Material(
//                 color: i % 2 == 0 ? Color.fromRGBO(0, 0, 0, 0.05) : Colors.white,
//                 child: InkWell(
//                   onTap: () {
//                     modal(context, child: RincianBarang(data: data), height: Mquery.height(context) - 80, radius: 15);
//                   },
//                   onLongPress: (){
//                     if(!this.widget.readOnly && status == 'waiting'){
//                       if( data['id_harga'] == '0' ){
//                         Wi.toast('Item promo tidak bisa dirubah');
//                       }else{
//                         // _showOptionBarang(data['id'], json.encode(data) );
//                         Wi.options(context, options: ['edit','hapus'], then: (res){
//                           if(res != null){
//                             switch (res['value']) {
//                               case 'edit': 
//                                 modal(this.widget.ctx, child: FormBarang(ctx: this.widget.ctx, idPenjualan: this.widget.dataPenjualan['id'].toString(), formData: data), then: (res){
//                                   if(res != null)
//                                     setState(() {
//                                       if(res['edited']) loader = true; loadData();
//                                     });
//                                 }); break;
                                
//                               default: Wi.confirm(context, message: 'Yakin ingin menghapus barang ini?', then: (res){
//                                 if(res != null && res == 1){
//                                   Wi.dialog(context, transparent: true, dismiss: false, child: Wi.spiner(size: 35, color: Colors.white, margin: 15));

//                                   Api.delete('detail_penjualan/'+data['id'].toString(), then: (s, data){
//                                     if(s == 200){
//                                       Navigator.pop(context); loadData();
//                                     }
//                                   }, error: (err){
//                                     Message.error(err);
//                                   });
//                                 }
//                               });
//                             }
//                           }
//                         });
//                       }
//                     }
//                   },
//                   child: new Container(
//                     padding: EdgeInsets.all(15),
//                     decoration: BoxDecoration(
//                       // border: Border(
//                       //   bottom: BorderSide(
//                       //     width: 1.0, color: Colors.black12),
//                       // ),
//                     ),
//                     child: 

//                       Column(
//                         children: <Widget>[
//                           Row(
//                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                             children: <Widget>[
//                               text(data['kode_barang'], bold: true),
//                               Row(
//                                 children: <Widget>[
//                                   text(data['order_qty'].toString()+'/'+data['order_pcs'].toString() ),
//                                   Container(
//                                     margin: EdgeInsets.only(left: 5),
//                                     padding: EdgeInsets.only(left: 5, right: 5, top: 1, bottom: 1),
//                                     decoration: BoxDecoration(
//                                       color: Colors.blueGrey,
//                                       borderRadius: BorderRadius.circular(3)
//                                     ),
//                                     child: text(data['qty'].toString()+'/'+data['qty_pcs'].toString(), color: Colors.white),
//                                   )

//                                 ],
//                               ),
//                             ],
//                           ),

//                           Row(
//                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: <Widget>[
//                               Flexible(
//                                 child: text(data['nama_barang'])
//                               ),
//                               Container(
//                                 padding: EdgeInsets.only(left: 15),
//                                 child: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.end,
//                                   children: <Widget>[
//                                     text('Rp '+ribuan(data['subtotal'].toString())),
//                                   ],
//                                 ) 
//                               ),
//                             ],
//                           ),

//                           Row(
//                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                               children: <Widget>[

//                                 data['nama_promo'] == null ? SizedBox.shrink() :
//                                 Row(
//                                   children: <Widget>[
//                                     Icon(Icons.local_offer, size: 9, color: Colors.blue,),
//                                     Container(
//                                       margin: EdgeInsets.only(left: 5),
//                                       child: text(data['nama_promo'],  color: Colors.blue, size: 12),
//                                     ),
//                                   ],
//                                 ),

//                                 data['discount'] == 0 ? SizedBox.shrink() : text('- Rp '+ribuan(data['discount'].toString()), color: Colors.blue, size: 12),

//                               ]
//                           )

//                         ],
//                       )
                    
//                   )
//                 )
//               );
//             }),
//           ),

//           Container(
//             height: 102, width: Mquery.width(context),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.only(
//                 topLeft: Radius.circular(15),
//                 topRight: Radius.circular(15)
//               ),
//               boxShadow: [
//                 BoxShadow(
//                   color: Color.fromRGBO(0, 0, 0, .3),
//                   blurRadius: 20.0, // has the effect of softening the shadow
//                   spreadRadius: 5.0, // has the effect of extending the shadow
//                   offset: Offset( 2.0, 2.0 ),
//                 )
//               ],
//             ),

//             child: Column(
//               children: [
//                 Container(
//                   padding: EdgeInsets.all(11),
//                   decoration: BoxDecoration(
//                     border: Border(bottom: BorderSide(color: Colors.black12))
//                   ),
//                   child: loaderTotal ? Wi.itext(icon: Wi.spiner(size: 15), child: text('Sedang memuat...')) :
//                     new Row(
//                       mainAxisAlignment: MainAxisAlignment.start,
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: List.generate(3, (int i){
//                         var labels = ['Total Qty','Total Pcs','Total Sku'],
//                             values = [penjualan['total_qty'], penjualan['total_pcs'], penjualan['sku']];

//                         return Container(
//                           padding: EdgeInsets.only(right: 15),
//                           child: text(labels[i]+' : '+values[i].toString()),
//                         );
//                       })
//                     )
//                 ),

//                 Container(
//                   padding: EdgeInsets.all(11),
//                   child: loaderTotal ? Wi.itext(icon: Wi.spiner(size: 15), child: text('Sedang memuat...')) :
//                   new Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     mainAxisSize: MainAxisSize.max,
//                     children: <Widget>[
//                       Container(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: <Widget>[
//                             text(penjualan['total'] == null ? '-' : 'Total : Rp '+ribuan(penjualan['total'].toString())),
//                             text(penjualan['disc_total'] == null ? '-' : 'Diskon : Rp '+ribuan(penjualan['disc_total'].toString())),
//                           ],
//                         ),
//                       ),

//                       Container(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.end,
//                           children: <Widget>[
//                             text(penjualan['ppn'] == null ? '-' : 'PPN : Rp '+ribuan(penjualan['ppn'].toString())),
//                             text(penjualan['grand_total'] == null ? '-' : 'Grand Total : Rp '+ribuan(penjualan['grand_total'].toString())),
//                           ],
//                         ),
//                       ),
//                     ]
//                   )
//                 )

//               ]
//             ),
//           )
  
//         ],
//       )
  
//     );

//     return new WillPopScope(
//       onWillPop: onWillPop,
//       child: Scaffold(
//         appBar: Wi.appBar(context, 
//           leading: IconButton( 
//             onPressed: (){
//               if (this.widget.isNew == true) {
//                 Navigator.of(context).pop({'is_new': true}); 
//                 Navigator.of(context).pop();
//               }else{
//                 Navigator.of(context).pop(); 
//               }
//             },
//             icon: Icon(Icons.arrow_back), color: Colors.black87
//           ),

//           title: new Container(
//             margin: EdgeInsets.only(top: 0),
//             child: new Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: <Widget>[ 
//                 text(this.widget.dataPenjualan['toko'][0]['nama_toko'], bold: true),
//                 text(dateFormat(data['tanggal'])+', '+data['id'].toString()+''+___tipeHarga.toUpperCase()+''+(data['no_invoice'] == null ? '' : ', '+data['no_invoice']))
//               ],
//             )
//           ),

//           actions: [
//             IconButton(
//               icon: Icon(Icons.more_vert),
//               onPressed: (){
//                 var options = ['detail','edit',status == 'waiting' ? 'setujui' : 'batal setujui','cetak','pelunasan'];

//                 options.removeWhere((item) => this.widget.readOnly ? item == 'edit' || item == 'cetak' : printPermission ? item == '' : item == 'cetak');
//                 options.removeWhere((item) => approvePermission ? item == '' : item == 'setujui' || item == 'batal setujui');
//                 options.removeWhere((item) => status == 'waiting' ? item == 'cetak' || item == 'pelunasan' : item == '');
//                 options.removeWhere((item) => status != 'waiting' ? item == 'edit' || item == 'setujui' || item == 'batal setujui' : item == '');


//                 Wi.options(context, options: options, then: (res){
                  
//                   if(res != null){
//                     switch (res['value']) {
//                       case 'detail': modal(this.widget.ctx, child: DetailPenjualan(data: this.widget.dataPenjualan), radius: 15, height: Mquery.height(context) - 80); break;
//                       case 'edit': modal(this.widget.ctx, child: EditPenjualan(data: this.widget.dataPenjualan)); break;
//                       case 'setujui': Wi.confirm(context, message: 'Yakin ingin menyetujui penjualan ini?', then: (res){ _confirm(res); }); break;
//                       case 'batal setujui': Wi.confirm(context, message: 'Yakin ingin membatalkan menyetujui penjualan ini?', then: (res){ _confirm(res); }); break;
//                       case 'pelunasan':
//                         Wi.dialog(context, transparent: true, dismiss: false, child: Wi.spiner(size: 35, color: Colors.white, margin: 15));

//                         Api.get('pelunasan_penjualan/'+data['id'].toString(), then: (s, body){
//                           if(s == 200){
//                             Navigator.pop(context);
//                             var dataPelunasan = decode(body)['data'];
//                             modal(this.widget.ctx, child: DetailPelunasan(ctx: this.widget.ctx, data: dataPelunasan));
//                           }
//                         }, error: (err){
//                           Message.error(err);
//                         });

//                       break;
//                       default: modal(this.widget.ctx, child: PrintPenjualan(data: penjualan, items: detailBarang), height: Mquery.height(context) / 2, radius: 15); break;
                      
//                       // Wi.dialog(context, slide: 0.25, child: PrepareToPrint(data: penjualan, items: detailBarang)); break;
//                     }
//                   }
//                 });
//               },
//             )
//           ]
        
//       ),
      

//       floatingActionButton: loader || this.widget.readOnly || status != 'waiting' && !printPermission ? null : Container(
//         margin: EdgeInsets.only(bottom: this.detailBarang.length == 0 ? 0 : 43),
//         child: FloatingActionButton(
//           onPressed: () {
//             if(status != 'waiting'){
//               modal(this.widget.ctx, child: PrintPenjualan(data: penjualan, items: detailBarang), height: Mquery.height(context) / 2, radius: 15);
//             }else{
//               modal(this.widget.ctx, child: FormBarang(ctx: this.widget.ctx, idPenjualan: this.widget.dataPenjualan['id'].toString()), then: (res){
//                 if(res != null)
//                 setState(() {
//                   if(res['added'] == true){
//                     loader = true;
//                     loadData();
//                   }
//                 });
//               });
//             }
//           },
//           child: Icon(status != 'waiting' ? Icons.print : Icons.add,),
//           backgroundColor: Colors.redAccent,
//         ),

//       ),

//       body: new RefreshIndicator(
//         onRefresh: _onRefresh,
//         child: loader ? Wi.spiner(size: 50) : widget,
//       ),

//     ));
//   }
  
// }



// class DetailPenjualan extends StatefulWidget {
//   final data;
//   DetailPenjualan({this.data});

//   @override
//   _DetailPenjualanState createState() => _DetailPenjualanState();
// }

// class _DetailPenjualanState extends State<DetailPenjualan>{
//   var data, widgetPenjualan = [];

//   initPrefs() async {
//     var prefs = await SharedPreferences.getInstance(), data = widget.data,
//         epTb = prefs.getString('epTb'), epTh = prefs.getString('epTh'),  epKt = prefs.getString('epKt'); 

//     setState(() {
//       widgetPenjualan = [
//         text('No. PO : '+data['id'].toString()),
//         text('No. Invoice : '+(data['no_invoice'] == null ? '' : data['no_invoice'])),
//         text('Nama Toko : '+data['toko'][0]['nama_toko']),
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: <Widget>[
//           text('Alamat : '+data['toko'][0]['alamat']),
//             data['latitude'] == null ? SizedBox.shrink() :

//             Container(
//               decoration: BoxDecoration(
//                 // borderRadius: BorderRadius.circular(25),
                
//               ),
//               child: new Material(
//                 // borderRadius: BorderRadius.circular(25),
//                 child: new InkWell(
//                   // borderRadius: BorderRadius.circular(25),
//                   onTap: (){
//                     openMap(double.parse(data['latitude']), double.parse(data['longitude']));
//                   },
//                   child: Container(
//                     padding: EdgeInsets.all(10),
//                     child: Icon(Icons.pin_drop, color: Colors.white)
//                   )
//                 ),
//                 color: Colors.blueAccent,
//               ),
//             ),
//         ],),

//         text(data['toko'][0]['no_acc'] == null ? 'No ACC : -' : 'No ACC : '+data['toko'][0]['no_acc']),
//         text(data['toko'][0]['cust_no'] == null ? 'Cust No : -' : 'Cust No : '+data['toko'][0]['cust_no']),
//         text('Nama Salesman : '+data['salesman'][0]['nama_salesman']),
//         text('Tim : '+data['salesman'][0]['tim']),
//         text('Tipe Toko : '+data['toko'][0]['tipe']),
//         text(epTh == null ? 'Tipe Harga : '+ucwords(data['tipe_harga']) : 'Tipe Harga : '+ucwords(epTh)),

//         // ambil tipe pembayaran dari localstorage (jika tidak null), tipe pembayaran (di localstorage) terupdate saat penjualan diperbarui 
//         text(epTb == null ? 'Tipe Pembayaran : '+ucwords(data['tipe_pembayaran']) : 'Tipe Pembayaran : '+ucwords(epTb) ),
//         text(epKt == null ? 'Keterangan : '+data['keterangan'] : 'Keterangan : '+epKt),
        
//         text('Diinput : '+ data['created_at']),
//         text('Disetujui : '+ (data['approved_at'] == null || data['approved_at'] == '' ? '-' : data['approved_at'])),
//         text('Dikirim : '+ (data['delivered_at'] == null || data['delivered_at'] == '' ? '-' : data['delivered_at'])),
//       ];
//     });

//   }

//   @override
//   void initState() {
//     super.initState();
//     initPrefs();
//   }
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: Wi.appBar(context, title: 'Detail Penjualan'),
//       body: Container(
//         child: ListView.builder(
//           shrinkWrap: true,
//           itemCount: widgetPenjualan.length,
//           itemBuilder: (context, i) {
//             return new Container(
//               color: i % 2 == 0 ? Color.fromRGBO(0, 0, 0, 0.05) : Colors.white,
//                 padding: i == 3 ? EdgeInsets.only(left: 15) : EdgeInsets.all(15),
//                 child: new Align(
//                   alignment: Alignment.centerLeft,
//                   child: new Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: <Widget>[
//                       widgetPenjualan[i]
//                     ],
//                   ),
//                 )
//               );
//           }
//         )
//       )
//     );
  
//   }
// }

// class RincianBarang extends StatefulWidget {
//   RincianBarang({Key key, this.data}) : super(key: key);
//   final data;

//   @override
//   _RincianBarangState createState() => _RincianBarangState();
// }

// class _RincianBarangState extends State<RincianBarang> with SingleTickerProviderStateMixin {
//   var data;

//   AnimationController controller;
//   Animation<double> scaleAnimation;

//   var title = [
//     'Kode Barang','Nama Barang','Jumlah Pesanan','Jumlah Terkirim','Harga','Subtotal','Diskon','Net','Nama Promo','Diinput Pada'
//   ];

//   var value = [];

//   @override
//   void initState() {
//     super.initState();
//     data = widget.data;

//     value = [
//       data['kode_barang'],
//       data['nama_barang'], 
//       data['order_qty']+' dus / '+data['order_pcs']+' pcs',
//       data['qty']+' dus / '+data['qty_pcs']+' pcs',
//       'Rp '+ribuan(data['harga_barang'].toString()),
//       'Rp '+ribuan(data['subtotal'].toString()),
//       'Rp '+ribuan(data['discount'].toString()),
//       data['net'] == null ? '-' : 'Rp '+ribuan(data['net'].toString()),
//       data['nama_promo'] == null ? '-' : data['nama_promo'],
//       data['created_at']
//     ];

//     controller = AnimationController(vsync: this, duration: Duration(milliseconds: 250));
//     scaleAnimation = CurvedAnimation(parent: controller, curve: Curves.decelerate);
//     controller.forward();
//   }
//   @override
//   Widget build(BuildContext context) {
//     return ScaleTransition(
//       scale: scaleAnimation,
//       child: Scaffold(
//         appBar: Wi.appBar(context, title: 'Detail Barang'),
//         body: ListView.builder(
//           shrinkWrap: true,
//           itemCount: title.length,
//           itemBuilder: (context, i) {
//             return new Container(
//               color: i % 2 == 0 ? Color.fromRGBO(0, 0, 0, 0.05) : Colors.white,
//                 padding: EdgeInsets.all(15),
//                 child: new Align(
//                   alignment: Alignment.centerLeft,
//                   child: new Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: <Widget>[
//                       text(title[i]+' : '+value[i], ),
//                     ],
//                   ),
//                 )
//               );
//           }
//         )
//       )
//     );
//   }
// }

// class PrintPenjualan extends StatefulWidget {
//   final data, items;
//   PrintPenjualan({this.data, this.items});

//   @override
//   _PrintPenjualanState createState() => _PrintPenjualanState();
// }

// class _PrintPenjualanState extends State<PrintPenjualan> {
//   var printer = TextEditingController();

//   BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;
//   bool loading = true, isConnected = false, isDeviceConnected = true, isPrint = false;

//   List _devices = [];
//   List<BluetoothDevice> bDevices = [];

//   // cari printer thermal
//   findThermalPrinter() async{
//     getPrefs('printer').then((res){
//       if(res != null){
//         printer.text = res;
//       }
//     });

//     setState(() {
//       isConnected = false;
//       loading = true;
//     });

//     bluetooth.isOn.then((res) async{
//       setState(() {
//         isConnected = res;
//       });

//       if(res){
//         _devices = []; bDevices = [];

//         try {
//           List<BluetoothDevice> devices = await bluetooth.getBondedDevices();
//           bDevices = devices;
          
//           devices.forEach((device){
//             _devices.add(device.name);
//             // if(device.name == 'BlueTooth Printer'){
//             //   printer.text = device.name;
//             // }
//           });

//           setState(() {
//             loading = false;
//           });
          
//         } catch (e) {
//           Wi.box(context, title: 'Bluetooth Error', message: 'Terjadi kesalahan saat menghubungkan ke perangkat Bluetooth Thermal.');
//         }
//       }

//     });
//   }

//   @override
//   void initState() {
//     super.initState(); findThermalPrinter();

//     bluetooth.onStateChanged().listen((state) {
//       if(mounted){ //print('# '+state.toString());
//         if(state == 11 || state == 12 || state == 1){
//           setState(() {
//             isConnected = true;
//           });

//           findThermalPrinter();
//         }else{
//           setState(() {
//             isConnected = false;
//           });
//         }
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return SingleChildScrollView(
//       padding: EdgeInsets.all(15),
//       child: Wi.content(header: 'CETAK PENJUALAN',
//         children: [

//           !isConnected ? Column(
//             children: [
              
//               Container(
//                 padding: EdgeInsets.all(10), margin: EdgeInsets.only(top: 25, bottom: 25),
//                 decoration: BoxDecoration(
//                   border: Border.all(color: Colors.black38),
//                   borderRadius: BorderRadius.circular(50)
//                 ),
//                 child: Icon(Icons.bluetooth_disabled, size: 50, color: Colors.black38)
//               ), text('Aktifkan Bluetooth Anda\nAksi ini membutuhkan jaringan Bluetooth', align: TextAlign.center)
              
//             ]
//           ) :

//           loading ? Container(
//             margin: EdgeInsets.only(top: 25, bottom: 25),
//             child: Column(
//               children: <Widget>[
//                 Wi.spiner(size: 50, margin: 25),
//                 text('Mencari perangkat printer')
//               ],
//             ),
//           ) :

//           _devices.length == 0 ?
//             Container(
//               child: Column(
//                 children: [
//                   Container(
//                     padding: EdgeInsets.all(10), margin: EdgeInsets.only(top: 25, bottom: 25),
//                     decoration: BoxDecoration(
//                       border: Border.all(color: Colors.black38),
//                       borderRadius: BorderRadius.circular(50)
//                     ),
//                     child: Icon(Icons.print, size: 50, color: Colors.black38)
//                   ),

//                   Column(
//                     children: [
//                       text('Tidak ada perangkat printer yang tersedia', bold: true),
//                       text('Pilih terlebih dahulu perangkat printer di pengaturan bluetooth, pastikan printer dalam keadaan menyala serta tidak terhubung ke perangkat manapun, kemudian tutup laman ini dan coba buka kembali.', align: TextAlign.center),
//                     ]
//                   )
//                 ]
//               )
//             ) :

//           Column(
//             children: [

//               text(isPrint ? 'Menghubungkan...' : 'Pilih Perangkat Printer'),
//               Picker(list: _devices, selected: printer.text, then: (res){
//                 if(res != null){
//                   setPrefs('printer', res);

//                   bDevices.forEach((device){
//                     if(device.name == res){
//                       bluetooth.isConnected.then((con) {
//                         if (!con) {
//                           setState(() => isPrint = true );
                          
//                           try {
//                             bluetooth.connect(device).then((_){
//                               Print(context: context, data: widget.data, items: widget.items).run();
//                             }, onError: (onErr){
//                               Navigator.pop(context, {'error': true});
//                             });
//                           }on PlatformException catch (_) {
//                             Navigator.pop(context, {'error': true});
//                           }
//                         }else{
//                           Print(context: context, data: widget.data, items: widget.items).run();
//                         }
//                       });
//                     }
//                   });
//                 }
//               })
//             ]
//           ),

//         ]
//       )
//     );
//   }
// }

// class Print {
//   Print({this.context, this.data, this.items}); final context, data, items;
//   BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;

//   run() async {

//     getPrefs('cp'+data['no_invoice']).then((res){

//       bluetooth.isConnected.then((isConnected) {
//         if(isConnected){
//           bluetooth.printCustom("PT. KEMBAR PUTRA MAKMUR",1,1);
//           bluetooth.printCustom("Jl. Anggrek I No. 1, Kapal, Mengwi, Badung",0,1);
//           bluetooth.printCustom("(0361) 9006481 | www.kembarputra.com",0,1);
          
//           if(res == null){
//             bluetooth.printCustom("------------------------------------------",0,1);
//           }else{
//             bluetooth.printCustom("--------------------------------------COPY",0,1);
//           }

//           bluetooth.printLeftRight('PO : '+data['id'].toString(), ' Tgl. '+dateTime(),0);
//           bluetooth.printLeftRight('Invoice : '+data['no_invoice']+' ', data['tipe_pembayaran'].toString().toUpperCase(),0);
//           bluetooth.printCustom('Sales : '+data['salesman'][0]['tim']+' - '+data['salesman'][0]['nama_salesman'],0,0);
//           bluetooth.printCustom('Cust : '+data['toko'][0]['no_acc']+' - '+data['toko'][0]['nama_toko'],0,0);
//           bluetooth.printCustom("------------------------------------------",0,1);

//           for (var i = 0; i < items.length; i++) {
//             var item = items[i], knb = item['kode_barang']+' - '+item['nama_barang'],
            
//             nb = knb.length > 42 ? knb.substring(0, 42) : knb,
//             qty = item['qty'] == '0' ? '' : item['qty'].toString()+' crt ',
//             pcs = item['qty_pcs'] == '0' ? '' : item['qty_pcs'].toString()+' '+item['satuan'];


//             if(qty != '' || pcs != ''){ 
//               bluetooth.printCustom(nb,0,0);
//               bluetooth.printLeftRight(qty+''+pcs, ribuan(item['price_after_tax'].toString())+'         '+ribuan(item['subtotal_after_tax'].toString()), 0);
//               if(item['discount'] != 0){
//                 bluetooth.printCustom('Disc - '+ribuan(item['discount'].toString()),0,2);
//               }
//             }
//           }

//           bluetooth.printCustom("------------------------------------------",0,1);

//           bluetooth.printLeftRight('Total : ', ribuan(data['total_after_tax'].toString()), 0);
//           bluetooth.printLeftRight('Total Diskon : ', ribuan(data['disc_total'].toString()), 0);
//           // bluetooth.printLeftRight('PPN : ', ribuan(data['ppn'].toString()), 0);
//           bluetooth.printLeftRight('Grand Total : ', ribuan(data['grand_total'].toString()), 0);

//           bluetooth.printNewLine();
//           bluetooth.printCustom('Harga sudah termasuk PPN',0,1);
//           bluetooth.printCustom('--== Terima Kasih ==--',0,1);
//           bluetooth.printNewLine();
//           bluetooth.printNewLine();
//           bluetooth.printNewLine();
//           bluetooth.paperCut();

//           setPrefs('cp'+data['no_invoice'], data['no_invoice']);

//           Navigator.pop(context);
//         }else{
//           Wi.box(context, title: 'Opps!', message: 'Tidak dapat terhubung ke printer! Periksa dan pastikan printer tidak sedang terhubung ke ponsel manapun.');
//           Navigator.pop(context);
//         }
//       });
    
//     });
//   }
  
// }