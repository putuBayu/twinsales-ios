import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:sales/services/api/api.dart';
import 'package:sales/services/v2/helper.dart';
// import 'package:sales/screens/toko/forms/form_toko.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'forms/form-toko.dart';

class Toko extends StatefulWidget {
  final ctx;
  Toko({this.ctx});

  @override
  _TokoState createState() => _TokoState();
}

class _TokoState extends State<Toko> {
  var dataToko = [], dataFiltered = [], index = 0;
  var isSearch = false, loading = true, keyword = TextEditingController();

  loadDataToko({refill: false}) async {
    var prefs = await SharedPreferences.getInstance();
    setState(() {
      loading = true;
    });

    if(refill){
      Request.get('penjualan/list/toko', then: (s, body){
        var res = decode(body)['data'];
        setPrefs('toko', res, enc: true);

        setState(() {
          dataFiltered = dataToko = res;
          loading = false;
        });

      }, error: (err){
        onError(context, response: err, backOnDismiss: false, then: (_status){
          if(_status == 500){
            if(mounted) setState((){
              loading = false;
              dataToko = dataFiltered = [];
            });
          }
        });
      });
    }else{
      var data = json.decode( prefs.getString('toko'));
      setState(() {
        dataToko = dataFiltered = data;
        loading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState(); loadDataToko();
  }

  Future<Null> _onRefresh() async {
    loadDataToko(refill: true);
  }

  // void _itemOptions(data){

  //   showModalBottomSheet(
  //     context: context,
  //     builder: (context){

  //       return ListTile(
  //         onTap: (){
  //           Navigator.of(context).pop();

  //           showModalBottomSheet(
  //             context: widget.ctx,
  //             builder: (BuildContext _) {
  //               return Container(
  //                 height: MediaQuery.of(widget.ctx).size.height - MediaQuery.of(widget.ctx).padding.top,
  //                 child: FormToko(data: data)
  //               );
  //             },
  //             isScrollControlled: true,
  //           ).then((onValue){
  //             if(onValue != null && onValue['updated']){
  //               loadDataToko(refill: true);
  //             }
  //           });

  //           // Navigator.push(context, MaterialPageRoute( builder: (context) => FormToko(data: data) )).then((onValue){
  //           //   if(onValue != null && onValue['updated']){
  //           //     loadDataToko(refill: true);
  //           //   }
  //           // });
  //         },
  //         title: Row(
  //           children: <Widget>[
  //             Icon(Icons.edit),
  //             Container(
  //               margin: EdgeInsets.only(left: 10),
  //               child: Text('Edit Toko')
  //             )
  //           ],
  //         ),
  //       );

  //     }
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Unfocus(
      child: Scaffold(
        appBar: Wh.appBar(context, back: false, title:

          Row(
            children: <Widget>[
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black12),
                    borderRadius: BorderRadius.circular(30),
                    color: dataToko.length == 0 ? TColor.silver() : Colors.white
                  ),
                  child: Fc.search(hint: 'Ketik nama toko', enabled: dataToko.length != 0,  prefix: Icon(Ic.search(), size: 18), change: (String s){
                    var k = s.toLowerCase();
                    setState(() {
                      dataFiltered = dataToko.where((item) => item['nama_toko'].toLowerCase().contains(k) || item['no_acc'].toString().toLowerCase().contains(k) || item['cust_no'].toString().toLowerCase().contains(k)).toList();
                    });
                  })
                ),
              ),

              Container(
                margin: EdgeInsets.only(left: 15),
                child: WidSplash(
                  padding: EdgeInsets.all(10),
                  radius: BorderRadius.circular(50),
                  onTap: (){
                    loadDataToko(refill: true);
                  },
                  child: Icon(Ic.refresh(), size: 20, color: loading ? Colors.black38 : Colors.black54),
                ),
              )
            ]
          )



          // Stack(
          //   children: <Widget>[
          //     Container(
          //       width: Mquery.width(context), padding: EdgeInsets.only(left: 15), height: ,
          //       decoration: BoxDecoration(
          //         border: Border.all(color: Colors.black12),
          //         borderRadius: BorderRadius.circular(50)
          //       ),
          //       child: Fc.search(hint: 'Ketik nama toko', controller: keyword, autofocus: false, change: (String s){
          //         var k = s.toLowerCase();
          //         setState(() {
          //           dataFiltered = dataToko.where(
          //             (item) => item['nama_toko'].toLowerCase().contains(k) || item['no_acc'].toString().toLowerCase().contains(k) || item['cust_no'].toString().toLowerCase().contains(k)
          //           ).toList();
          //         });
          //       }),
          //     ),

          //     AnimatedPositioned(
          //       duration: Duration(milliseconds: 300),
          //       right: keyword.text == '' ? -35 : 0, bottom: -3,
          //       child: IconButton(
          //         padding: EdgeInsets.all(0),
          //         icon: Icon(Icons.close),
          //         onPressed: (){
          //           focus(context, FocusNode());

          //           setState(() {
          //             keyword.clear();
          //             dataFiltered = dataToko;
          //           });
          //         },
          //       )
          //     )

          //   ],
          // )

        ),

        body: loading ? ListSkeleton(length: 10) :
        dataFiltered == null || dataFiltered.length == 0 ? Wh.noData(message: 'Tidak ada data toko\nTap gambar untuk memuat ulang.', onTap: (){ loadDataToko(refill: true); }) :

        RefreshIndicator(
          onRefresh: _onRefresh,
          child: ListView.builder(
            itemCount: dataFiltered.length,
            itemBuilder: (context, i){
              var data = dataFiltered[i], noAcc = data['no_acc'] == null ? '' : data['no_acc'], custNo = data['cust_no'] == null ? '' : ' - '+data['cust_no']+'';

              return Container(
                decoration: BoxDecoration(
                  // border: Border(
                  //   bottom: BorderSide(color: Colors.black12)
                  // )
                ),
                child: new Material(
                  color: i % 2 == 0 ? TColor.silver() : Colors.white,
                  child: new InkWell(
                    onDoubleTap: (){},
                    onLongPress: (){
                      // _itemOptions(data);
                    },
                    onTap: (){
                      modal(widget.ctx, child: DetailToko(data: data));
                    },
                    child: new Column(
                      children: <Widget>[
                        new Container(
                          padding: EdgeInsets.all(15),
                          child: new Align(
                            alignment: Alignment.centerLeft,
                            child: new Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                data['no_acc'] == null ? SizedBox.shrink() : text('['+noAcc+''+custNo+']', bold: true),
                                text(data['nama_toko'] == null ? '-' : data['nama_toko'], bold: true),
                                text(data['alamat'] == null ? '-' : ucword(data['alamat']))
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        floatingActionButton: FloatingActionButton(
          onPressed: () {
            modal(widget.ctx, child: FormToko(widget.ctx), then: (res){
              if(res != null && res['added']){
                Wh.toast('Berhasil ditambahkan');
                loadDataToko(refill: true);
              }
            });
          },
          child: Icon(Icons.add),
          backgroundColor: TColor.azure(),
        ),
      ),
    );
  }
}

class DetailToko extends StatefulWidget {
  DetailToko({Key key, this.data}) : super(key: key);
  final data;

  @override
  _DetailTokoState createState() => _DetailTokoState();
}

class _DetailTokoState extends State<DetailToko> with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  var data;

  AnimationController controller;
  Animation<double> scaleAnimation;

  var title = [
    'Nama Toko', 'No Acc', 'Cust No', 'Nama Pemilik', 'Alamat', 'Nomor Telepon',
    'Tipe Toko', 'Kode Pos', 'Kabupaten', 'Kecamatan', 'Kelurahan', 'Tipe Pembayaran',
    'TOP', 'Limit', 'Minggu', 'Hari', 'NPWP', 'No KTP', 'Nama Tim'
  ];

  var value = [];

  @override
  void initState() {
    super.initState();
    data = widget.data;

    value = [
      data['nama_toko'],
      data['no_acc'] == null ? '-' : data['no_acc'],
      data['cust_no'] == null ? '-' : data['cust_no'],
      data['pemilik'] == null || data['pemilik'] == '' ? '-' : ucword(data['pemilik']),
      data['alamat'] == null ? '-' : ucword(data['alamat']),
      data['telepon'] == null || data['telepon'] == '' ? '-' : data['telepon'],
      data['tipe'],
      data['kode_pos'] == null ? '-' : data['kode_pos'],
      data['kabupaten'] == null ? '-' : data['kabupaten'],
      data['kecamatan'] == null ? '-' : data['kecamatan'],
      data['kelurahan'] == null ? '-' : data['kelurahan'],
      ucword(data['k_t']),
      data['top'] == null ? '-' : data['top']+' hari',
      ribuan(data['limit']),
      data['minggu'] == null ? '-' : data['minggu'], data['hari'],
      data['npwp'] == null || data['npwp'] == '' ? '-' : data['npwp'],
      data['no_ktp'] == null || data['no_ktp'] == '' ? '-' : data['no_ktp'],
      data['nama_tim'] == null ? '-' : data['nama_tim']
    ];

    controller = AnimationController(vsync: this, duration: Duration(milliseconds: 250));
    scaleAnimation = CurvedAnimation(parent: controller, curve: Curves.decelerate);
    controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Wh.appBar(context, title: 'Detail Toko', center: true),
      body: ScaleTransition(
        key: _scaffoldKey,
        scale: scaleAnimation,
        child:  Container(
          // title: 'Detail Toko',
          child: ListView.builder(
            padding: EdgeInsets.all(0),
            shrinkWrap: true,
            itemCount: title.length,
            itemBuilder: (context, i) {
              return new Container(
                  color: i % 2 == 0 ? TColor.silver() : Colors.white,
                  padding: i == 4 ? data['latitude'] == null ? EdgeInsets.all(15) : EdgeInsets.only(left: 15) : EdgeInsets.all(15),
                  child: new Align(
                    alignment: Alignment.centerLeft,
                    child: new Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        i == 4 ? Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Expanded(child: text('Alamat : '+value[i])),
                            data['latitude'] == null ? SizedBox.shrink() : Container(
                              decoration: BoxDecoration(
                                  // borderRadius: BorderRadius.circular(25),
                              ),
                              child: new Material(
                                  // borderRadius: BorderRadius.circular(25),
                                child: new InkWell(
//                                     borderRadius: BorderRadius.circular(25),
                                    onTap: (){
                                      openMap(double.parse(data['latitude']), double.parse(data['longitude']));
                                    },
                                    child: Container(
                                      padding: EdgeInsets.all(10),
                                      child: Icon(Icons.pin_drop, color: Colors.white)
                                    )
                                  ),
                                  color: Colors.blueAccent,
                                ),
                              ),
                          ]
                        ) : text(title[i]+' : '+value[i]),
                      ],
                    ),
                  )
              );
            }
          ),
        )
      ),
    );
  }
}
