// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:sales/screens/penjualan/penjualan/forms/form-penjualan.dart';
// import 'package:sales/services/api/api.dart';
// import 'package:sales/services/helper-widget.dart';
// import 'package:sales/services/v2/helper.dart';
// import 'package:sales/services/v3/helper.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:geolocator/geolocator.dart';
//
// class FormKunjungan extends StatefulWidget {
//   final ctx, initData;
//   FormKunjungan(this.ctx, {this.initData});
//   @override
//   _FormKunjunganState createState() => _FormKunjunganState();
// }
//
// class _FormKunjunganState extends State<FormKunjungan> with SingleTickerProviderStateMixin{
//   Timer pingLooper;
//
//   TextEditingController toko = TextEditingController(),
//       locationController = TextEditingController(),
//       listCall = TextEditingController(),
//       keterangan = TextEditingController();
//
//   TabController tabController;
//   LatLng currentLocation;
//   GoogleMapController _mapController;
//   GoogleMapController get mapController => _mapController;
//   bool loading = true, isSubmit = false, showLabel = false;
//   int idToko = 0, selected = 0;
//   String fullAddress;
//   var dataCall;
//
//   getCall() async {
//     setState(() { loading = true; });
//
//     Request.get('/options/get/list?code=call', then: (status, body){
//       if(mounted){
//         var res = decode(body);
//
//         setState(() {
//           dataCall = res['data'];
//           listCall.text = dataCall[0]['value'];
//           print(listCall.text);
//         });
//         loading = false;
//
//         tabController = new TabController(length: dataCall.length, vsync: this);
//         tabController.addListener(() {TColor.azure();});
//
//         return res;
//       }
//     }, error: (err){
//       setState(() { loading = false; });
//       onError(context, response: err);
//     });
//   }
//
//   onCreated(GoogleMapController controller){
//     _mapController = controller;
//   }
//
//   onCameraMove(CameraPosition position) async{
//     setState(() {});
//     showLabel = false;
//     currentLocation = LatLng(position.target.latitude, position.target.longitude);
//   }
//
//   getMoveCamera() async{
//     showLabel = false;
//     List<Placemark> placemark = await Geolocator().placemarkFromCoordinates(currentLocation.latitude, currentLocation.longitude);
//     locationController.text = placemark[0].thoroughfare.toString();
//     setState(() {
//       fullAddress = placemark[0].thoroughfare.toString()
//           + ', ' + placemark[0].subLocality.toString()
//           + ', ' + placemark[0].locality.toString()
//           + ', ' + placemark[0].subAdministrativeArea.toString()
//           + ', ' + placemark[0].administrativeArea.toString()
//           + ', ' + placemark[0].postalCode.toString();
//
//       showLabel = true;
//     });
//   }
//
//   getUserLocation() async{
//     Position position = await Geolocator().getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
//     List<Placemark> placemark = await Geolocator().placemarkFromCoordinates(position.latitude, position.longitude);
//     currentLocation = LatLng(position.latitude, position.longitude);
//     locationController.text = placemark[0].thoroughfare.toString();
//     _mapController.animateCamera(CameraUpdate.newLatLng(currentLocation));
//   }
//
//   initLocation() async{
//     if(widget.initData == null){
//       Position position = await Geolocator().getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
//       print(position.longitude.toString());
//       currentLocation = LatLng(position.latitude, position.longitude);
//     }else{
//       currentLocation = LatLng(widget.initData['latitude'], widget.initData['longitude']);
//     }
//   }
//
//   initForm(){
//     var data = widget.initData;
//     if(data != null){
//       toko.text = data['nama_toko'];
//       idToko = data['id_toko'];
//       listCall.text = data['status'];
//       keterangan.text = data['keterangan'];
//     }
//   }
//
//   submit()async{
//     if(toko.text.isEmpty || idToko == 0 || listCall.text.isEmpty){
//       Wh.toast('Lengkapi Form');
//     }else if(currentLocation == null){
//       Wh.toast('Tidak dapat menemukan lokasi');
//     }else{
//       isEnabledLocation(
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
//               'status': listCall.text,
//               'latitude': currentLocation.latitude.toString(),
//               'longitude': currentLocation.longitude.toString(),
//               'keterangan': keterangan.text
//             };
//
//             if(widget.initData == null){
//               Request.post('kunjungan_sales', formData: formData, debug: true, then: (status, data) {
//                 Map res = decode(data);
//                 Wh.toast(res['message']);
//                 Navigator.of(context).pop(true);
//               }, error: (err) {
//                 onError(context, response: err, popup: true);
//                 setState(() => isSubmit = false);
//               });
//             }else{
//               Request.put('kunjungan_sales/' + widget.initData['id'].toString(), formData: formData, debug: true, then: (status, data) {
//                 Map res = decode(data);
//                 Wh.toast(res['message']);
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
//       );
//     }
//   }
//
//   @override
//   void initState() {
//     initLocation();
//     getCall();
//     initForm();
//     statusBar(color: Colors.transparent, darkText: true);
//     super.initState();
//
//     DateTime start = DateTime.now();
//     pingLooper = Timer.periodic(Duration(seconds: 5), (Timer t) {
//       setState(() {
//         CheckPing().intConnection();
//         CheckPing().getPingMs(start);
//       });
//     });
//   }
//
//   @override
//   void dispose() {
//     if (this.mounted) {
//       pingLooper.cancel();
//     }
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Unfocus(
//       child: Scaffold(
//         backgroundColor: TColor.silver(),
//         appBar: Wh.appBar(
//           context,
//           title: widget.initData != null ? 'Edit Kunjungan Toko' : 'Buat Kunjungan Toko',
//           center: true,
//           actions: [
//             Padding(
//                 padding: const EdgeInsets.only(right: 10.0),
//                 child: pingStyle(CheckPing().getTimeRespond())
//             )
//           ],
//         ),
//         body: PreventScrollGlow(
//           child: Column(
//             children: [
//               Container(
//                 color: TColor.gray(o: 0.5),
//                 margin: EdgeInsets.only(bottom: 5),
//                 width: Mquery.width(context),
//                 height: Mquery.width(context)/2,
//                 child: Stack(
//                   children: [
//                     currentLocation == null ? SizedBox.shrink() : GoogleMap(
//                       initialCameraPosition: CameraPosition(
//                           target: currentLocation,
//                           zoom: 15
//                       ),
//                       zoomControlsEnabled: true,
//                       myLocationEnabled: true,
//                       myLocationButtonEnabled: false,
//                       onCameraMove: onCameraMove,
//                       onMapCreated: onCreated,
//                       onCameraIdle: (){
//                         setState(() {
//                           getMoveCamera();
//                           showLabel = true;
//                         });
//                         // getUserLocation();
//                       },
//                     ),
//                     Align(
//                       alignment: Alignment.center,
//                       child: Container(
//                         margin: EdgeInsets.only(bottom: 45),
//                         child: ClipRRect(
//                             borderRadius: BorderRadius.circular(20),
//                             child: Image.asset('assets/img/marker.png', height: 40, color: TColor.azure(),)
//                         ),
//                       ),
//                     ),
//                     Align(
//                       alignment: Alignment.center,
//                       child: Container(
//                         margin: EdgeInsets.only(bottom: 55),
//                         child: ClipRRect(
//                             borderRadius: BorderRadius.circular(20),
//                             child: Image.asset('assets/img/profile.png', height: 25,)
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               Expanded(
//                 child: SingleChildScrollView(
//                   padding: EdgeInsets.all(15),
//                   child: loading ? ListSkeleton(length: 10,) : Container(
//                     // margin: EdgeInsets.only(bottom: 70),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         !showLabel ? ListSkeleton(length: 1, type: 'text',) : Container(
//                           margin: EdgeInsets.only(bottom: 15),
//                           child: text(fullAddress,
//                               color: Colors.black87, size: 16
//                           ),
//                         ),
//                         SelectInput(
//                           space: 10,
//                           label: 'Pilih Toko',
//                           hint: 'Pilih toko',
//                           controller: toko,
//                           enabled: true,
//                           select: () {
//                             modal(widget.ctx, radius: 5, child: DaftarToko(), then: (res) {
//                               if (res != null)
//                                 setState(() {
//                                   toko.text = res['toko'];
//                                   idToko = res['id'];
//                                   print(idToko);
//                                 });
//                             });
//                           },
//                         ),
//                         Container(
//                           margin: EdgeInsets.only(bottom: 7),
//                           child: text('Status', bold: true),
//                         ),
//
//                         Container(
//                           margin: EdgeInsets.only(bottom: 10),
//                           child: TabBar(
//                             unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),
//                             isScrollable: false,
//                             labelPadding: EdgeInsets.zero,
//                             indicatorWeight: 2,
//                             indicatorColor: Colors.transparent,
//                             controller: tabController,
//                             tabs: List.generate(dataCall.length, (i){
//                               var data = dataCall[i];
//                               return Center(
//                                 child: WidSplash(
//                                   onTap: (){
//                                     setState(() {
//                                       tabController.index = i;
//                                       listCall.text = data['value'];
//                                       print(listCall.text);
//                                     });
//                                   },
//                                   color: tabController.index == i ? TColor.azure() : Colors.white,
//                                   padding: EdgeInsets.symmetric(vertical: 10),
//                                   border: Border.all(color: Colors.black26),
//                                   child: Container(
//                                     width: Mquery.width(context)/3,
//                                     child: text(data['text'], align: TextAlign.center, color: tabController.index == i ? Colors.white : Colors.black87)
//                                   )
//                                 ),
//                               );
//                             }),
//                           ),
//                         ),
//
//                         // Container(
//                         //   margin: EdgeInsets.only(bottom: 10),
//                         //   width: Mquery.width(context),
//                         //   child: Row(
//                         //     children: List.generate(dataCall.length, (i){
//                         //       var data = dataCall[i];
//                         //
//                         //       return Container(
//                         //         // width: Mquery.width(context)/dataCall.length,
//                         //         // margin: EdgeInsets.only(right: 10),
//                         //         child: ChoiceChip(
//                         //           label: text(data['text'], color: selected == i ? Colors.white : Colors.black54),
//                         //           selected: selected == i ? true : false,
//                         //           onSelected: (isSelected){
//                         //             if(isSelected){
//                         //               setState(() {
//                         //                 selected = i;
//                         //                 listCall.text = data[i]['value'];
//                         //               });
//                         //             }
//                         //           },
//                         //           selectedColor: TColor.azure(),
//                         //         ),
//                         //       );
//                         //     }),
//                         //   ),
//                         // ),
//                         TextInput(
//                           space: 15,
//                           maxLines: 5,
//                           label: 'Keterangan',
//                           hint: 'Inputkan keterangan',
//                           controller: keterangan,
//                         ),
//                         Button(
//                           text: 'Simpan',
//                           onTap: submit,
//                           isSubmit: isSubmit,
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget formData(){
//     return PreventScrollGlow(
//       child: Column(
//         children: [
//           Expanded(
//             child: SingleChildScrollView(
//               padding: EdgeInsets.all(15),
//               child: Container(
//                 margin: EdgeInsets.only(bottom: 70),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     !showLabel ? ListSkeleton(length: 1, type: 'text',) : Container(
//                       margin: EdgeInsets.only(bottom: 15),
//                       child: text(fullAddress,
//                           color: Colors.black87, size: 16
//                       ),
//                     ),
//                     SelectInput(
//                       label: 'Pilih Toko',
//                       hint: 'Pilih toko',
//                       controller: toko,
//                       enabled: true,
//                       select: () {
//                         modal(widget.ctx, radius: 5, child: DaftarToko(), then: (res) {
//                           if (res != null)
//                             setState(() {
//                               toko.text = res['toko'];
//                               idToko = res['id'];
//                             });
//                         });
//                       },
//                     ),
//                     // Dropdown(
//                     //   values: dropdownValue,
//                     //   space: 25,
//                     //   label: 'Keterangan',
//                     //   hint: 'Masukkan keterangan',
//                     //   options: ['Order', 'Tidak Order', 'Tutup'],
//                     //   onChanged: (value){
//                     //     setState(() {
//                     //       dropdownValue = value;
//                     //     });
//                     //   },
//                     // ),
//                     TextInput(
//                       maxLines: 5,
//                       label: 'Catatan',
//                       hint: 'Masukkan catatan',
//                       controller: keterangan,
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           )
//         ],
//       ),
//     );
//   }
// }
