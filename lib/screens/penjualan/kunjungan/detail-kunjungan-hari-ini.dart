import 'package:flutter/material.dart';
import 'package:sales/services/v2/helper.dart';
import 'package:geolocator/geolocator.dart';

class DetailKunjunganHariIni extends StatefulWidget {
  final ctx, initData;
  DetailKunjunganHariIni({this.ctx, this.initData});

  @override
  _DetailKunjunganHariIniState createState() => _DetailKunjunganHariIniState();
}

class _DetailKunjunganHariIniState extends State<DetailKunjunganHariIni> with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  List title = ['Nama Toko', 'No Acc', 'Cust No', 'Lokasi Kunjungan', 'Status', 'Keterangan'],
      value = [];
  var data;
  String fullAddress = '';
  AnimationController controller;
  Animation<double> scaleAnimation;

  getPosition(var lat, var lng)async{
    List<Placemark> placemark = await Geolocator().placemarkFromCoordinates(lat, lng);
    // locationController.text = placemark[0].thoroughfare.toString();
    setState(() {
      // jalan = header = placemark[0].thoroughfare.toString();
      //
      // provinsi = placemark[0].administrativeArea.toString();
      // kabupaten = placemark[0].subAdministrativeArea.toString();
      // kecamatan = placemark[0].locality.toString();
      // kelurahan = placemark[0].subLocality.toString();
      // kodePos = placemark[0].postalCode.toString();
      // lat = currentLocation.latitude;
      // long = currentLocation.longitude;

      fullAddress = placemark[0].thoroughfare.toString()
          + ', ' + placemark[0].subLocality.toString()
          + ', ' + placemark[0].locality.toString()
          + ', ' + placemark[0].subAdministrativeArea.toString()
          + ', ' + placemark[0].administrativeArea.toString()
          + ', ' + placemark[0].postalCode.toString();
    });
  }

  initScreen()async{
    data = widget.initData;
    await getPosition(data['latitude'], data['longitude']);
    value = [
      data['nama_toko'],
      data['no_acc'] == '' ? '-' : data['no_acc'],
      data['cust_no'] == '' ? '-' : data['cust_no'],
      fullAddress,
      data['status'],
      data['keterangan'] == '' ? '-' : data['keterangan'],
    ];
  }

  @override
  void initState() {
    super.initState();
    initScreen();

    controller = AnimationController(vsync: this, duration: Duration(milliseconds: 250));
    scaleAnimation = CurvedAnimation(parent: controller, curve: Curves.decelerate);
    controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TColor.silver(),
      appBar: Wh.appBar(context, title: 'Detail Toko', center: true),
      body: ScaleTransition(
        key: _scaffoldKey,
        scale: scaleAnimation,
        child: Container(
          child:  ListView.builder(
              padding: EdgeInsets.all(0),
              shrinkWrap: true,
              itemCount: title.length,
              itemBuilder: (context, i) {
                return Container(
                    color: i % 2 == 0 ? TColor.silver() : Colors.white,
                    padding: i == 3 ? EdgeInsets.only(left: 15) : EdgeInsets.all(15),
                    child: new Align(
                      alignment: Alignment.centerLeft,
                      child: i == 3 ? Column(
                        children: [
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Container(
                                  // padding: EdgeInsets.symmetric(vertical: 15),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      text(title[i], bold: true),
                                      text(value[i]),
                                    ],
                                  ),
                                )
                              ),
                              WidSplash(
                                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 30),
                                color: Colors.blueAccent,
                                onTap: (){
                                  openMap(data['latitude'], data['longitude']);
                                },
                                child: Icon(Icons.pin_drop, color: Colors.white),
                              ),
                            ]
                          ),
                        ],
                      ) : value.length == 0 ? ListSkeleton(length: 10,) : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          text(title[i], bold: true),
                          text(value[i]),
                        ],
                      ),
                    )
                );
              }
          ),
        ),
      ),
    );
  }
}