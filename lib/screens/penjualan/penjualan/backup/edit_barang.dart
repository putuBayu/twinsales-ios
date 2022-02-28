// import 'package:flutter/material.dart';
// import 'package:sales/services/helper.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:http/http.dart' as http;
// import 'dart:async';
// import 'dart:convert';
// import 'dart:io';
// import 'package:cloud_firestore/cloud_firestore.dart';

// class EditBarang extends StatefulWidget {
//   final String idPenjualan, idBarang, itemBarang; final paddingTop;
//   EditBarang({Key key, this.idPenjualan, this.idBarang, this.itemBarang, this.paddingTop}) : super(key: key);
//   _EditBarangState createState() => _EditBarangState();
// }

// class _EditBarangState extends State<EditBarang> {
//   TextEditingController qty = new TextEditingController(text: '0');
//   TextEditingController qtyPcs = new TextEditingController(text: '0');
//   double textPadding = 15;

//   var namaBarang = '', tipeHarga = '', namaPromo = '', dataPromo = []; int idStock = 0, idPromo = 0, idHarga = 0, lQty = 0, lQtyPcs = 2;
//   bool loaderBarang = true, loaderPromo = true, isSave = false;

//   setSharedPreferences() async {
//     var prefs = await SharedPreferences.getInstance();

//     Future<void> getPromo() async {
//       http.Response result = await http.get(
//         Uri.encodeFull( api('promo/list/aktif') ),
//         headers: {HttpHeaders.authorizationHeader: prefs.getString('token'), "Accept": "application/json"});

//       if(mounted){
//         setState(() {
//           Map res = json.decode(result.body);
//           this.loaderPromo = false;
//           this.dataPromo = res['data'];
//         });
//       }
//     }

//     getPromo();
//   }

//   @override
//   void initState() {
//     super.initState();
//     this.setSharedPreferences();

//     var data = json.decode(widget.itemBarang);
    
//     // idStock = int.parse(widget.idBarang);
//     idStock = int.parse(data['id_stock']);
//     namaBarang = data['nama_barang'];
//     namaPromo = data['nama_promo'] == null ? '' : data['nama_promo'];
//     idPromo = int.parse(data['id_promo']);
//     idHarga = int.parse(data['id_harga']);
//     tipeHarga = data['tipe_harga'].toUpperCase();
//     qty.text = data['qty'];
//     qtyPcs.text = data['qty_pcs'];
//     lQty = data['qty_available'];
//   }

//   void saveBarang() async {

//     if( idStock == 0 ){
//       Wi.toast('Lengkapi Form');
//     }else{

//       setState(() { isSave = true; });

//       var data = {'id_penjualan': widget.idPenjualan, 'id_stock': idStock.toString(), 'qty': qty.text == '' ? 0 : qty.text.toString(), 'qty_pcs': qtyPcs.text == '' ? 0 : qtyPcs.text.toString(), 'id_harga': idHarga.toString(), 'id_promo': idPromo.toString()};
      
//       Api.put('detail_penjualan/'+json.decode(widget.itemBarang)['id'].toString(), formData: data, then: (status, body){
//         Map res = decode(body);

//         if(status == 201){
//           Wi.toast('Tersimpan');
//           Navigator.of(context).pop({'edited': true});
//         }else{
//           Wi.toast(res['message']);
//         }

//         setState(() { isSave = false; });
//         // Firestore.instance.collection('trigger_sales').document('barang').updateData({ 'trigger': generate().toString() });
        
//       });

//     }
//   }

//   @override
//   Widget build(BuildContext context) {

//     return ScrollConfiguration(
//           behavior: ScrollConfig(),
//           child:
    
//     Scaffold(
//       backgroundColor: Cl.softSilver(),
//         appBar: Wi.appBar(context, title: 'Edit Barang'),
//         body:

//           new Container(
//             child: 
//         new ListView(
//           padding: EdgeInsets.all(15),
//             shrinkWrap: true,
//             children: <Widget>[
//             new Column(
//             children: <Widget>[

//               FormControl(context).selector(label: 'Pilih Barang ', controller: namaBarang, enabled: false),

//               Tf().textfield(context, 
//                 label: 'Qty',
//                 controller: qty,
//                 type: 'number', max: 4,
//                 onChange: (String val){
//                   print(val);
//                 },
//                 btnControl: (String val){
//                   setState(() { qty.text = val; });
//                 }
//               ),

//               Tf().textfield(context, 
//                 label: 'Qty Pcs',
//                 controller: qtyPcs,
//                 type: 'number', max: 4,
//                 onChange: (String val){
//                   print(val);
//                 },
//                 btnControl: (String val){
//                   setState(() { qtyPcs.text = val; });
//                 }
//               ),

//               FormControl(context).select(context,
//                 label: 'Pilih Promo',
//                 value: namaPromo,
//                 uc: false,
//                 onTap: (){
//                   showModalBottomSheet(
//                     context: context,
//                     builder: (BuildContext _) {
//                       return Container(
//                         height: MediaQuery.of(context).size.height - widget.paddingTop,
//                         child: ListPromo()
//                       );
//                     },
//                     isScrollControlled: true,
//                   ).then((value) {
//                     if(value != null)
//                     setState(() {
//                       namaPromo = value['promo'];
//                       idPromo = value['id'];
//                     });
//                   });

//                 },
//                 onCancel: namaPromo == '' ? null : (){
//                   setState(() {
//                     namaPromo = ''; idPromo = 0;
//                   });
//                 }
//               ),

//               FormControl(context).button(label: isSave ? spin(color: Colors.white) : text('Simpan', color: Colors.white), marginY: 5, onPressed: isSave ? null : (){ saveBarang(); }),

//             ],
//           ),
//           ]
//         )
//           ),
    
//     ));
//   }
// }

// class ListPromo extends StatefulWidget {
//   _ListPromoState createState() => _ListPromoState();
// }

// class _ListPromoState extends State<ListPromo> {
//   TextEditingController _searchQuery = new TextEditingController();

//   var dataPromo = [], dataFiltered = [];
//   bool _isSearching = false, loaded = false;

//   loadDataPromo({refill: false}) async {
//     var prefs = await SharedPreferences.getInstance();

//     getData() async {
//       setState(() { loaded = false; });

//       try {
//         http.Response result = await http.get(
//         Uri.encodeFull( api('promo') ), headers: {HttpHeaders.authorizationHeader: prefs.getString('token'), "Accept": "application/json"});
//         if(mounted){
//           Map res = json.decode(result.body);
//           return res['data'];
//         }
//       } catch (e) {
//         print('-- error : '+e.toString());
//         box(context, title: 'Gagal load data promo');
//       }
//     }

//     if(refill == true){
//       checkConnection().then((con){
//         if(con){
//           getData().then((val){
//             prefs.setString('promo', json.encode(val));
//             setState(() {
//               dataFiltered = dataPromo = val;
//               loaded = true;
//             });
//           });
//         }else{
//           box(context, title: 'Periksa koneksi internet Anda');
//         }
//       });
//     }else{
//       var data = json.decode( prefs.getString('promo') );
//       setState(() {
//         dataPromo = dataFiltered = data;
//         loaded = true;
//       });
//     }
//   }

//   @override
//   void initState() {
//     super.initState();
//     this.loadDataPromo();
//   }

//   Widget _buildSearchField(){
//     return new TextField(
//       controller: _searchQuery,
//       autofocus: true,
//       decoration: InputDecoration(
//         hintText: "Cari promo...",
//         border: InputBorder.none,
//         hintStyle: const TextStyle(color: Colors.black54)
//       ),
//       style: TextStyle(color: Colors.black87, fontSize: 16),
//       onChanged: updateSearchQuery,
//     );
//   }

//   List<Widget> _buildActions(){
//     return <Widget>[
//       new IconButton(
//         icon: Icon(Icons.refresh, color: !loaded ? Colors.black26 : Colors.black87),
//         padding: EdgeInsets.all(0),
//         onPressed: !loaded ? null : () {
//           setState(() {
//             _searchQuery.clear();
//             _isSearching = false;
//             loaded = false;
//           });
//           loadDataPromo(refill: true);
//         },
//       ),

//       _isSearching ?
//         new IconButton(
//           icon: const Icon(Icons.clear, color: Colors.black87,),
//           onPressed: () {
//             setState(() {
//               _searchQuery.clear();
//               _isSearching = false;
//               dataFiltered = dataPromo;
//             });
//             return;
//           },
//         ) : Text('')
//     ];
//   }

//   Widget myAppBar(){
//     return new AppBar(
//       elevation: 1,
//       backgroundColor: Colors.white,
//       titleSpacing: 0,
//       leading: backArrow(context),
//       title: _buildSearchField(),
//       actions: _buildActions()
//     );
//   }

//   void updateSearchQuery(String newQuery) {
    
//     if( (_searchQuery.text.isNotEmpty) ){
//       List tempList = new List();
//       for(int i = 0; i < dataPromo.length; i++){
//         if(dataPromo[i]['nama_promo'].toLowerCase().contains(_searchQuery.text.toLowerCase())){
//           tempList.add(dataPromo[i]);
//         }
//       }

//       setState(() {
//         _isSearching = true;
//         dataFiltered = tempList;
//       });
//     }else{
//       setState(() {
//         _isSearching = false;
//         dataFiltered = dataPromo;
//       });

//     }

//   }

//   @override
//   Widget build(BuildContext context) {

//     return Scaffold(
//       appBar: myAppBar(),
//       body: !loaded ? spiner(position: 'center', size: 50) : new Container(
//         color: Colors.white,
//         child: 
//         this.dataFiltered.length == 0 ?
//           Align(alignment: Alignment.center,
//             child: Container(
//               child: Text('Tidak ada promo', style: TextStyle(color: Color.fromRGBO(0,0,0,.5)),),
//             )
//           )
//         :
//         new ListView.builder(
//           itemCount: this.dataFiltered.length,
//           itemBuilder: (context, i) {
//             var data = dataFiltered[i];

//             return new GestureDetector(
//                 onTap: () { 
//                   Navigator.of(context).pop({'promo': data['nama_promo'], 'id': data['id']});
//                 },
//                 child: new Container(
//                   decoration: BoxDecoration(
//                     border: Border(
//                       bottom: BorderSide(width: 1.0, color: Colors.black12),
//                     ),
//                   ),
//                   // border: new Border.onl(color: Colors.black12)),
//                   child: new Column(
//                     children: <Widget>[ 
//                       new Container(
//                         color: i % 2 == 0 ? Color.fromRGBO(0, 0, 0, 0.05) : Colors.white,
//                           padding: EdgeInsets.all(15),
//                           child: new Align(
//                             alignment: Alignment.centerLeft,
//                             child: new Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: <Widget>[
//                                 Text( data['nama_promo'], ),
//                               ],
//                             ),
//                           ))
//                     ],
//                   ),
//                 ));
//           },
//         ),
//       ),
//     );
  
//   }
// }
