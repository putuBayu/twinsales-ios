import 'package:flutter/material.dart';
import 'package:sales/services/api/api.dart';
import 'package:sales/services/v2/helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:barcode_scan/barcode_scan.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

var defaultApi = 'https://kpm-api.kembarputra.com';

class Barang extends StatefulWidget {
  final ctx, idGudang;
  Barang({this.ctx, this.idGudang});

  @override
  _BarangState createState() => _BarangState();
}

class _BarangState extends State<Barang> {
  var loading = true, items = [], dataFiltered = [], temp = [], searchField = false, validField = false, isSearch = false, isLoadMore = false;
  var keyword = new TextEditingController();
  var totalRows = 0, tempTotal = 0, perPage = 25, currentPage = 1, viewBy = '*';
  String apii = '', barcode = '';
  String testcode = 'lalala';

  // get data barang
  getData({refill: false}) async {
    getPrefs('api').then((res){
      apii = res == null ? defaultApi+'/' : res+'/';
    });

    setState(() {
      if(!isSearch){
        loading = true;
      }
    });

    var prefs = await SharedPreferences.getInstance();
    
    Future getData({then}) async {
      Request.get(widget.idGudang == null ? 'detail_penjualan/list/barang' : 'stock/'+widget.idGudang.toString(), then: (s, body){
        if(mounted){
          // setState(() {
          //   loading = false;
          //   isSearch = false;
          // });
          then(decode(body)['data']);
        }
      }, error: (err){
        setState(() {
          loading = false;
          isSearch = false;
        });
        onError(context, response: err, popup: true);
      });
    }

    if(refill){
      getData(then: (res)async{
        items = dataFiltered = res;
        if(!isSearch){ temp = res; }
        setPrefs('barang', res, enc: true);
        dataFiltered.sort((a,b) => b['qty_pcs'].compareTo(a['qty_pcs']));
        dataFiltered.sort((a,b) => b['qty'].compareTo(a['qty']));
        Request.get('barang?per_page=all', then: (status, result){
          setState(() {
            setPrefs('barangRetur', decode(result)['data'], enc: true);
            loading = false;
            isSearch = false;
          });
        }, error: (err){
          setState(() {
            loading = false;
            isSearch = false;
          });
          onError(context, response: err, popup: true, backOnDismiss: true);
        });
      });
    }else{
      var emp = prefs.getString('barang');
      if(emp != null){
        setState(() {
          items = dataFiltered = decode(emp);
          loading = false;
          isSearch = false;
        });
      }else{
        getData().then((res){
          setState(() {
            items = dataFiltered = res;
            prefs.setString('barang', encode(res));
          });
        });
      }
    }

  }
  
  Future scanBarcode() async {
    // untuk edit package ini, cari source code kotlinnya di flutter/.pub-chache/hosted/pub.dartlang.org/barcode_scan -> BarcodeScannerActvity.kt

    try {
      String barcode = await BarcodeScanner.scan();
      setState(() => this.barcode = barcode);

      List tempList = new List();

      keyword.text = barcode;
      
      for(int i = 0; i < items.length; i++){
        var data = items[i];
        if(data['barcode'] != null)
          if(data['barcode'].toLowerCase().contains(barcode)){
            tempList.add(items[i]);
          }
      }

      if(tempList.length == 0){
        Wh.toast('Barang tidak ditemukan');
      }

      setState(() {
        dataFiltered = tempList;
      });

    } on PlatformException catch (e) {
      if (e.code == BarcodeScanner.CameraAccessDenied) {
        Wh.alert(context, title: 'Opps!', message: 'Pengguna tidak memberiksan izin akses kamera!');
      } else {
        
      }
    } on FormatException{
      // setState(() => this.barcode = 'null (User returned using the "back"-button before scanning anything. Result)');
    } catch (e) {
      Wh.alert(context, title: 'Barcode tidak valid!');
    }
  }

  @override
  void initState() { 
    super.initState();
    getData();
  }

  Future<Null> _onRefresh() async {
    setState(() {
      currentPage = 1;
    });
    keyword.text = '';
    getData(refill: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: Wh.appBar(context, back: false, title: Container(
          height: 40,
          padding: EdgeInsets.only(right: 5),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black12),
            borderRadius: BorderRadius.circular(30),
            // color: items.length == 0 ? TColor.silver() : Colors.white
          ),
          child: Fc.search(
            hint: 'Ketik kode atau nama barang',
            controller: keyword,
            // enabled: items.length != 0,
            prefix: Icon(Ic.search(), size: 18),
            change: (String s){
              var k = s.toLowerCase();
              setState(() {
                dataFiltered = items.where(
                  (item) => item['nama_barang'].toLowerCase().contains(k) || item['kode_barang'].toString().toLowerCase().contains(k)
                ).toList();
              });
            },
          )
        ), actions: [
            WidSplash(
              padding: EdgeInsets.only(right: 10),
              onTap: loading ? null : scanBarcode,
              child: Icon(
                Ic.camera(),
                size: 20,
                color: loading ? Colors.black38 : Colors.black54
              )
            ),
            WidSplash(
              padding: EdgeInsets.only(right: 15, left: 10),
              onTap: loading ? null : _onRefresh,
              child: Icon(
                Ic.refresh(),
                size: 20,
                color: loading ? Colors.black38 : Colors.black54
              ),
            )
          // IconButton(
          //   icon: Transform.rotate(
          //     angle: 180 * math.pi / 72,
          //     child: Icon(
          //       Icons.line_weight,
          //       color: !loading ? Colors.black38 : Colors.black87,
          //     ),
          //   ),
          //   onPressed: !loading ? null : scanBarcode
          // ),
        ]
      ),

      body: loading ? ListSkeleton(length: 10) :
        dataFiltered == null || dataFiltered.length == 0 ? Wh.noData(message: 'Tidak ada data barang\nCoba refresh atau dengan kata kunci lain.', onTap: _onRefresh) :

        RefreshIndicator(
          onRefresh: _onRefresh,
          child:  ListView.builder(
            itemCount: dataFiltered.length,
            itemBuilder: (context, i){
              var data = dataFiltered[i];

              return SlideUp(
                child: WidSplash(
                  border: Border(bottom: BorderSide(color: Colors.black12)),
                  child: Stack(
                    children: [
                      ListTile(
                        isThreeLine: false,
                        contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                        onTap: (){
                          modal(widget.ctx, child: DetailBarang(data: data));
                        },
                        leading: Container(
                          height: 50, width: 50,
                          margin: EdgeInsets.only(bottom: 10, top: 10),
                          child: data['gambar'] == null ? Image.asset('assets/img/no-img.png') : FadeInImage.assetNetwork(
                            height: 50, width: 50,
                            placeholder: 'assets/img/no-img.png',
                            image: apii+'images/items/'+data['gambar'],
                          ),
                        ),
                        title: text(data['kode_barang'], bold: true),
                        subtitle: text(data['nama_barang']),
                      ),

                      Container(
                        margin: EdgeInsets.only(top: 5, left: 5),
                        padding: EdgeInsets.only(left: 5, right: 5),
                        decoration: BoxDecoration(
                            color: Colors.blueGrey,
                            borderRadius: BorderRadius.circular(5)
                        ),
                        child: text(ribuan(data['qty'])+'/'+data['qty_pcs'].toString(), color: Colors.white),
                      ),
                    ],
                  ),
                ),
              );
            },
          )
        )
    );
  }

  Widget layoutLama(){
    return StaggeredGridView.count(
        padding: EdgeInsets.all(15),
        crossAxisCount: 4,
        staggeredTiles: dataFiltered.map<StaggeredTile>((_) => StaggeredTile.fit(2)).toList(),
        mainAxisSpacing: 3.0,
        crossAxisSpacing: 4.0,
        children: List.generate(dataFiltered.length, (int i){
          var data = dataFiltered[i];

          return SlideUp(
            child: WidSplash(
              onTap: (){
                modal(widget.ctx, child: DetailBarang(data: data));
              },
              color: Colors.white, radius: BorderRadius.circular(4),
              child: Container(
                // padding: EdgeInsets.only(left: 10, right: 10, top: 10, bottom: 15),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          margin: EdgeInsets.only(top: 5),
                          padding: EdgeInsets.only(left: 5, right: 5),
                          decoration: BoxDecoration(
                              color: Colors.blueGrey,
                              borderRadius: BorderRadius.only(
                                  topRight: Radius.circular(50),
                                  bottomRight: Radius.circular(50)
                              )
                          ),
                          child: text(ribuan(data['qty'])+'/'+data['qty_pcs'].toString(), color: Colors.white),
                        ),
                        Container(
                          padding: EdgeInsets.all(10),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  height: 50, width: 50,
                                  margin: EdgeInsets.only(bottom: 10, top: 10),
                                  child: data['gambar'] == null ? Image.asset('assets/img/no-img.png') :
                                  FadeInImage.assetNetwork(
                                    height: 50, width: 50,
                                    placeholder: 'assets/img/no-img.png',
                                    image: apii+'images/items/'+data['gambar'],
                                  ),
                                ),
                                text(data['kode_barang'], bold: true),
                                text(data['nama_barang'], align: TextAlign.center)
                              ]
                          ),
                        )
                      ]
                  )
              ),
            ),
          );
        }
        ));
    // Staggere
    // ListView.builder(
    //   itemCount: dataFiltered.length,
    //   itemBuilder: (BuildContext context, i){
    //     var data = dataFiltered[i];

    //     return Button(
    //       onTap: (){ },
    //       child: Row(
    //         mainAxisSize: MainAxisSize.min,
    //         children: <Widget>[
    //           Container(
    //             decoration: BoxDecoration(
    //               color: Colors.white,
    //               border: Border.all(color: Colors.black12)
    //             ),
    //             child: text('lorem'),
    //           )
    //         ],
    //       ),
    //     );
    //   }
    // )


    //   Column(
    //     children: <Widget>[

    //     Expanded(
    //       child: ListView.builder(
    //         itemCount: dataFiltered.length,
    //         itemBuilder: (context, i){

    //             var data = dataFiltered[i];

    //             return Container(
    //               width: MediaQuery.of(context).size.width,
    //               decoration: BoxDecoration(
    //                 border: Border(
    //                   bottom: BorderSide(color: Cl.black05())
    //                 ),
    //               ),
    //               child: new Material(
    //                 color: i % 2 == 0 ? Cl.black05() : Colors.white,
    //                 child: new InkWell(
    //                   highlightColor: Colors.transparent,
    //                   splashColor: Colors.blue[50],
    //                   onTap: (){
    //                     modal(widget.ctx, child: DetailBarang(data: data));
    //                   },
    //                   child: ListTile(
    //                     leading: Container(
    //                       height: 50,
    //                       width: 50,
    //                       child: data['gambar'] == null ? Image.asset('assets/img/no-data.png') :

    //                       FadeInImage.assetNetwork(
    //                         height: 50, width: 50,
    //                         placeholder: "assets/img/no-data.png",
    //                         image: api('images/items/'+data['gambar']),
    //                       ),
    //                     ),

    //                     title: Row(
    //                       children: <Widget>[
    //                         Flexible (
    //                           child: text(data['kode_barang'], bold: true),
    //                         ),
    //                     ],),

    //                     subtitle: Row(
    //                       children: <Widget>[
    //                         Flexible (
    //                           child: text(data['nama_barang']),
    //                         ),
    //                     ],),

    //                     trailing: Icon(Icons.chevron_right, color: Colors.black38,)
    //                   )

    //                 )
    //               ),

    //             );
    //         }
    //       ),
    //     )
    //   ],
    // )
  }
}

class DetailBarang extends StatefulWidget {
  final data;
  DetailBarang({this.data});

  @override
  _DetailBarangState createState() => _DetailBarangState();
}

class _DetailBarangState extends State<DetailBarang> {

  var loading = false, data, title = ['Kode Barang','Nama Barang','Stok','Satuan','Isi','Tipe','Berat','RBP','HCOBP','WBP','CBP'],
      value = [];

  String apii = '';

  getData() async {
    getPrefs('api').then((res){
      apii = res == null ? defaultApi+'/' : res+'/';
    });

    data = widget.data;
    setState(() => loading = false );

    Request.get('barang/'+widget.data['id_barang'], then: (s, body){
      var res = decode(body)['data'];

      value.add(data['kode_barang']);
      value.add(data['nama_barang']);
      value.add(ribuan(data['qty'])+' dus / '+ribuan(data['qty_pcs'])+' pcs');
      value.add(data['satuan']);
      value.add(data['isi']);
      value.add(data['tipe'] ?? '-');
      value.add(data['berat'] == null ? '-' : data['berat'].toString()+' Gram');
      value.add(res['rbp'] == null ? '-' : 'Rp. '+ribuan(res['rbp']['harga']));
      value.add(res['hcobp'] == null ? '-' : 'Rp. '+ribuan(res['hcobp']['harga']));
      value.add(res['wbp'] == null ? '-' : 'Rp. '+ribuan(res['wbp']['harga']));
      value.add(res['cbp'] == null ? '-' : 'Rp. '+ribuan(res['cbp']['harga']));

      setState(() => loading = true );

    }, error: (err){
      setState(() => loading = true );
      onError(context, response: err, popup: true);
    });

  }

  ScrollController scroll; double imgHeight = 0, imgSize = 200;

  @override
  void initState() { 
    super.initState(); getData();

    scroll = ScrollController()..addListener(() {
      double currentScroll = scroll.position.pixels;

      setState(() {
        imgHeight = currentScroll / 100;
        imgSize = 200 + currentScroll;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Wh.appBar(context, title: data['nama_barang'], actions: [
        IconButton(
          onPressed: null,
          icon: Icon(Icons.clear, color: Colors.transparent),
        ),

        loading ? SizedBox.shrink() : Container(
          padding: EdgeInsets.all(15),
          child: Wh.spiner(size: 20)
        )
      ]),

      body: ScrollConfiguration(
        behavior: ScrollConfig(),
        child: Stack(
          children: <Widget>[
            AnimatedPositioned(
              duration: Duration(milliseconds: 150),
              top: imgHeight,
              child: SlideUp(
                child: Container(
                  height: imgSize + 30, width: Mquery.width(context),
                  child: Center(
                    child: data['gambar'] == null ? Container(
                      child: text('Tidak ada gambar.'),
                    ) : AnimatedContainer(
                      duration: Duration(milliseconds: 150),
                      height: imgSize,
                      padding: EdgeInsets.only(top: 15, bottom: 15),
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage(apii+'images/items/'+widget.data['gambar'])// AssetImage('assets/img/no-img.png') // Image.network(api('images/items/'+data['gambar']), fit: BoxFit.cover),
                        )
                      ),
                    ),
                  ),
                ),
              ),
            ),
            ListView.builder(
              padding: EdgeInsets.only(top: 230),
              itemCount: title.length,
              controller: scroll,
              itemBuilder: (BuildContext context, i){
                return GestureDetector(
                  onTap: (){

                  },
                  child: Container(
                    padding: EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: i % 2 == 0 ? TColor.silver() : Colors.white
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        text(title[i], bold: true),
                        value.length <= i ? text('-') : SlideUp(child: text(value.length <= i ? '-' : value[i]))
                      ],
                    ),
                  )
                );
              },
            )
          ],
        )
      )
    );
  }
}
