import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sales/services/api/api.dart';
import 'package:sales/services/v2/helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Promo extends StatefulWidget {
  final ctx;
  Promo({this.ctx});

  @override
  _PromoState createState() => _PromoState();
}

class _PromoState extends State<Promo> with TickerProviderStateMixin {
  List dataPromo = [],
      dataFiltered = [],
      promoTypes = ['On Faktur', 'Off Faktur'];
  int index = 0;
  bool isSearch = false,
      loading = true;
  TextEditingController keyword = TextEditingController();
  TabController controller;

  loadDataPromo({refill: false}) async {
    var prefs = await SharedPreferences.getInstance();

    getData({then}) async {
      setState(() { loading = true; });

      Request.get('promo', then: (s, body){
        if(mounted){
          Map res = decode(body);
          then(res['data']);
        }
      }, error: (err){
        onError(context, response: err, popup: true);
      });
    }

    _get(){
      getData(then: (val){
        setPrefs('promo', val, enc: true);
        setState(() {
          dataFiltered = dataPromo = val;
          loading = false;
        });
      });
    }

    if(refill){
      _get();
    }else{
      var data = prefs.getString('promo');
      if(data != null){
        setState(() {
          dataPromo = dataFiltered = decode(data);
          loading = false;
        });
      }else{
        _get();
      }
    }
  }

  @override
  void initState() {
    controller = new TabController(length: promoTypes.length, vsync: this);

    loadDataPromo();
    super.initState();
  }

  Future<Null> _onRefresh() async {
    loadDataPromo(refill: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Wh.appBar(context, back: false, title: Row(
          children: <Widget>[
            Expanded(
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black12),
                  borderRadius: BorderRadius.circular(30),
                  color: dataPromo.length == 0 ? TColor.silver() : Colors.white
                ),
                child: Fc.search(hint: 'Ketik nama promo', enabled: dataPromo.length != 0, prefix: Icon(Ic.search(), size: 18), change: (String s){
                  var k = s.toLowerCase();
                  setState(() {
                    dataFiltered = dataPromo.where((item) => item['nama_promo'].toLowerCase().contains(k) || item['keterangan'].toString().toLowerCase().contains(k)).toList();
                  });
                })
              ),
            ),

            Container(
              margin: EdgeInsets.only(left: 15),
              child: WidSplash(
                padding: EdgeInsets.all(10),
                radius: BorderRadius.circular(50),
                onTap: loading ? null : () { loadDataPromo(refill: true); },
                child: Icon(
                    Ic.refresh(),
                    size: 20,
                    color: loading ? Colors.black38 : Colors.black54
                ),
              ),
            )
          ]
        ),
      ),

      body: body()
      // DefaultTabController(
      //   length: promoTypes.length,
      //   child: Column(
      //     children: [
      //       Container(
      //         width: Mquery.width(context),
      //         constraints: BoxConstraints(maxHeight: 150),
      //         child: Material(
      //           color: Colors.white,
      //           child: TabBar(
      //             labelColor: TColor.azure(),
      //             dragStartBehavior: DragStartBehavior.start,
      //             unselectedLabelColor: TColor.gray(),
      //             unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),
      //             isScrollable: false,
      //             indicatorWeight: 2,
      //             indicatorColor: TColor.azure(),
      //             controller: controller,
      //             tabs: List.generate(promoTypes.length, (i){
      //               return Container(
      //                 child: Tab(
      //                   text: promoTypes[i],
      //                 ),
      //               );
      //             }),
      //           ),
      //         ),
      //       ),
      //       Expanded(
      //         child: Container(
      //           child: TabBarView(
      //             controller: controller,
      //             children: List.generate(promoTypes.length, (i){
      //               return body();
      //             }),
      //           ),
      //         ),
      //       )
      //     ],
      //   ),
      // )
    );
  }

  Widget body(){
    return loading ? ListSkeleton(length: 10)
        : dataFiltered == null || dataFiltered.length == 0
        ? Wh.noData(
            message: 'Tidak ada data promo\nCoba refresh atau dengan kata kunci lain.',
            onTap: (){
              loadDataPromo(refill: true);
            }
          )
        : RefreshIndicator(
            onRefresh: _onRefresh,
            child: ListView.builder(
              itemCount: dataFiltered.length,
              itemBuilder: (context, i){
                var data = dataFiltered[i];

                return WidSplash(
                  color: i % 2 == 0 ? TColor.silver() : Colors.white,
                  onTap: (){
                    modal(widget.ctx, child: DetailPromo(data: data), then: (_){
                      Timer(Duration(milliseconds: 500), (){
                        statusBar(color: Colors.transparent, darkText: true);
                      });
                    });
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
                                text(data['nama_promo'] == null ? '' : data['nama_promo'], bold: true),
                                text(data['keterangan'] == null ? '-' : data['keterangan'])
                              ],
                            ),
                          )
                      )
                    ],
                  ),
                );
              },
            ),
        );
  }
}

class DetailPromo extends StatefulWidget {
  DetailPromo({Key key, this.data}) : super(key: key);
  final data;

  @override
  _DetailPromoState createState() => _DetailPromoState();
}

class _DetailPromoState extends State<DetailPromo>{
  var data;
  var title = [
    'Proposal',
    'Nama Promo',
    'Diskon Rupiah',
    'Diskon Persen',
    'Barang Ekstra',
    'Pcs Ekstra',
    'Periode',
    'Keterangan'
  ];
  var value = [];

  @override
  void initState() {
    super.initState();
    data = widget.data;
    var startDate = dateConvert(date: data['tanggal_awal'], dateFormat: 'dd MMM yyyy'),
        endDate = dateConvert(date: data['tanggal_akhir'], dateFormat: 'dd MMM yyyy');

    value = [
      data['no_promo'],
      data['nama_promo'],
      'Rp '+ribuan(data['disc_rupiah'].toString()),
      data['disc_persen'].toString()+'%',
      data['nama_barang'] == null ? '-' : data['nama_barang'],
      data['pcs_extra'] == null ? '-' : data['pcs_extra'],
      startDate + ' - ' + endDate,
      data['keterangan'] == null ? '-' : data['keterangan']
    ];

  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Wh.appBar(context, title: 'Detail Promo', center: true),
      body: ListView.builder(
        padding: EdgeInsets.all(0),
        shrinkWrap: true,
        itemCount: title.length,
        itemBuilder: (context, i) {
          return new Container(
            color: i % 2 == 0 ? TColor.silver() : Colors.white,
            padding: EdgeInsets.all(15),
            child: new Align(
              alignment: Alignment.centerLeft,
              child: new Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  text(title[i].toString()+' : '+value[i].toString()),
                ],
              ),
            )
          );
        }
      ),
    );
  }
}
