import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sales/screens/toko/toko.dart';
import 'package:sales/services/api/api.dart';
import 'package:sales/services/v2/helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminToko extends StatefulWidget {
  AdminToko({this.ctx}); final ctx;

  @override
  _AdminTokoState createState() => _AdminTokoState();
}

class _AdminTokoState extends State<AdminToko> {
  var keyword = TextEditingController();

  var dataToko = [], dataFiltered = [], index = 0, listTotal;
  var isSearch = false, loaded = true, isPaginate = false;
  var perPage = 15, currentPage = 1, timSelected = 'all';

  var tim = [], timId = [], namaTim = '', initTim = 0;

  loadDataToko({refill: false}) async {
    var prefs = await SharedPreferences.getInstance();

    // load data tim di localstorage
    var lsTim = prefs.getString('tim'), tempTim = [], tempTimId = [];
    if(lsTim != null){
      tempTim.add('Pilih Semua'); tempTimId.add('');

      for (var i = 0; i < decode(lsTim).length; i++) {
        var d = decode(lsTim)[i];
        tempTim.add(d['nama_tim']); tempTimId.add(d['id']);
      }

      setState(() {
        tim = tempTim; timId = tempTimId;
      });
    }

    getData() async {
      setState(() { loaded = false; currentPage = 1; });

      var url = 'toko?per_page='+perPage.toString()+'&page='+currentPage.toString()+'&id_tim='+timSelected+'&keyword='+keyword.text;
      Request.get(url, then: (status, body){
        if(mounted){
          Map res = decode(body);
          setPrefs('toko', encode(res['data']));

          setState(() {
            listTotal = res['meta']['total'];
            dataFiltered = dataToko = res['data'];
            loaded = true;
          });
        }
      }, error: (err){
        onError(context, response: err, popup: true);
      });
    }

    if(refill == true){
      getData();
    }else{
      var data = prefs.getString('toko');
      if(data != null){
        setState(() {
          dataToko = dataFiltered = decode(data);
          loaded = true;
        });
      }else{
        getData();
      }
    }
  }

  pagination() async {
    setState(() {
      currentPage = currentPage + 1;
      isPaginate = true;
    });

    var url = 'toko?per_page='+perPage.toString()+'&page='+currentPage.toString()+'&id_tim='+timSelected+'&keyword='+keyword.text;
    Request.get(url, then: (status, body){
      Map res = decode(body); 
      var data = res['data'];

      setState(() { isPaginate = false; });

      for (var i = 0; i < data.length; i++) {
        setState(() {
          // dataToko.add(data[i]);
          dataFiltered.add(data[i]);
        });
      }
    }, error: (err){
      onError(context, response: err, popup: true);
    });
  }

  @override
  void initState() {
    loadDataToko();
    super.initState();
  }
 
  Future<Null> _onRefresh() async {
    setState(() {
      timSelected = 'all';
      namaTim = '';
    });
    loadDataToko(refill: true);
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
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
                child: Fc.search(hint: 'Ketik nama toko',  prefix: Icon(Ic.search(), size: 18), change: (String s){
                  var k = s.toLowerCase();
                  setState(() {
                    keyword.text = k;
                    // dataFiltered = dataToko.where(
                    //   (item) => item['nama_toko'].toLowerCase().contains(k) || item['no_acc'].toString().toLowerCase().contains(k) || item['cust_no'].toString().toLowerCase().contains(k)
                    // ).toList();
                  });
                  loadDataToko(refill: true);
                })
              ),
            ),

            Container(
              margin: EdgeInsets.only(left: 15),
              child: WidSplash(
                padding: EdgeInsets.all(10),
                radius: BorderRadius.circular(50),
                onTap: (){
                  showModalBottomSheet(
                    context: widget.ctx,
                    backgroundColor: Colors.transparent,
                    builder: (BuildContext context){

                      return PreventScrollGlow(
                        child: ClipRRect(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(5),
                            topRight: Radius.circular(5)
                          ),
                          child: Container(
                            padding: EdgeInsets.only(top: 15),
                            color: Colors.white,
                            height: 230.0,
                            child: Column(
                              children: <Widget>[

                                Expanded(
                                  child: CupertinoPicker(
                                    scrollController: FixedExtentScrollController(
                                      initialItem: initTim,
                                    ),
                                    itemExtent: 40.0,
                                    backgroundColor: Colors.white,
                                    onSelectedItemChanged: (int i){
                                      setState(() { initTim = i; });
                                    },
                                    children: new List<Widget>.generate(
                                      tim.length, (int index) {
                                        return Container(
                                          margin: EdgeInsets.all(3),
                                          width: MediaQuery.of(context).size.width - 100,
                                          padding: EdgeInsets.all(5),
                                          decoration: BoxDecoration(
                                            color: TColor.silver(),
                                            borderRadius: BorderRadius.circular(25)
                                          ),
                                          child: Center(
                                            child: text(tim[index]),
                                          ) 
                                        );
                                      }
                                    )
                                  ),
                                ),

                                Container(
                                  padding: EdgeInsets.all(15),
                                  child: Button(
                                    onTap: (){
                                      timSelected = timId[initTim].toString();
                                      keyword.text = ''; 
                                      loadDataToko(refill: true);
                                      Navigator.pop(context); 
                                    },
                                    text: 'Cari',
                                  ),
                                )
                              ],
                            )
                          ),
                        ),
                      );
                    }
                  );

                },
                child: Icon(Ic.users(), size: 20, color: !loaded ? Colors.black38 : Colors.black54),
              ),
            )
          ]
        ),
      
    ),

    body: !loaded ? ListSkeleton(length: 10) :
      
      dataFiltered == null || dataFiltered.length == 0 ? Wh.noData(message: 'Tidak ada data toko\nTap gambar untuk memuat ulang', onTap: (){ loadDataToko(refill: true); }) :
      RefreshIndicator(
        onRefresh: _onRefresh,
        child: ListView.builder(
          itemCount: dataFiltered.length + 1,
          itemBuilder: (context, i){

            if(i == dataFiltered.length){
              return i == listTotal ? SizedBox.shrink() : Container(
                padding: EdgeInsets.all(10),
                child: isPaginate ? Wh.spiner(size: 20, margin: 14) : IconButton(
                  icon: Icon(Icons.cached),
                  onPressed: (){ pagination(); },
                ),
              );
            }else{
              var data = dataFiltered[i], noAcc = data['no_acc'] == null ? '' : data['no_acc'], custNo = data['cust_no'] == null ? '' : ' - '+data['cust_no']+'';

              return Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.black12)
                  )
                ),
                child: new Material(
                  color: Colors.white,
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
                          color: i % 2 == 0 ? TColor.silver() : Colors.white,
                            padding: EdgeInsets.all(15),
                            child: new Align(
                              alignment: Alignment.centerLeft,
                              child: new Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  data['no_acc'] == null ? SizedBox.shrink() : text('['+noAcc+''+custNo+']', bold: true),
                                  text(data['nama_toko'] == null ? '-' : data['nama_toko'], bold: true),
                                  text(data['alamat'] == null ? '-' : data['alamat'])
                                ],
                              ),
                            ))
                      ],
                    ),
                  ),
                ),
              );
              
            }
          },
        ),
      ),

      // floatingActionButton: isSearch ? null : FloatingActionButton(
      //   onPressed: () {
      //     showModalBottomSheet(
      //       context: widget.ctx,
      //       builder: (BuildContext _) {
      //         return Container(
      //           height: MediaQuery.of(context).size.height - MediaQuery.of(widget.ctx).padding.top,
      //           child: FormToko()
      //         );
      //       },
      //       isScrollControlled: true,
      //     ).then((onValue){
      //       if(onValue != null){
      //         if(onValue['added']){
      //           loadDataToko(refill: true);
      //         }
      //       }
      //     });
      //   },
      //   child: Icon(Icons.add,),
      //   backgroundColor: Colors.redAccent,
      // ),
    );
  }
}

// class DetailToko extends StatefulWidget {
//   DetailToko({Key key, this.data}) : super(key: key);
//   final data;
//
//   @override
//   _DetailTokoState createState() => _DetailTokoState();
// }
//
// class _DetailTokoState extends State<DetailToko> with SingleTickerProviderStateMixin {
//   final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
//
//   var data;
//
//   AnimationController controller;
//   Animation<double> scaleAnimation;
//
//   var title = [
//     'Nama Toko', 'No Acc', 'Cust No', 'Nama Pemilik', 'Alamat', 'Nomor Telepon', 'Tipe Toko', 'Kode Pos',
//     'Kabupaten', 'Kecamatan', 'Kelurahan', 'Tipe Pembayaran', 'Limit', 'Minggu', 'Hari'
//   ];
//
//   var value = [];
//
//   @override
//   void initState() {
//     super.initState();
//     data = widget.data;
//
//     value = [
//       data['nama_toko'],
//       data['no_acc'] == null ? '-' : data['no_acc'],
//       data['cust_no'] == null ? '-' : data['cust_no'],
//       data['pemilik'] == null ? '-' : data['pemilik'],
//       data['alamat'] == null ? '-' : data['alamat'],
//       data['telepon'] == null ? '-' : data['telepon'],
//       data['tipe'],
//       data['kode_pos'] == null ? '-' : data['kode_pos'],
//       data['kabupaten'] == null ? '-' : data['kabupaten'],
//       data['kecamatan'] == null ? '-' : data['kecamatan'],
//       data['kelurahan'] == null ? '-' : data['kelurahan'],
//       data['k_t'], ribuan(data['limit']),
//       data['minggu'] == null ? '-' : data['minggu'], data['hari']
//     ];
//
//
//     controller = AnimationController(vsync: this, duration: Duration(milliseconds: 250));
//     scaleAnimation = CurvedAnimation(parent: controller, curve: Curves.decelerate);
//     controller.forward();
//   }
//   @override
//   Widget build(BuildContext context) {
//
//     return Scaffold(
//       appBar: Wh.appBar(context, title: 'Detail Toko'),
//       body: ScaleTransition(
//         key: _scaffoldKey,
//         scale: scaleAnimation,
//         child:  Container(
//           child: ListView.builder(
//             padding: EdgeInsets.all(0),
//             shrinkWrap: true,
//             itemCount: title.length,
//             itemBuilder: (context, i) {
//               return new Container(
//                 color: i % 2 == 0 ? TColor.silver() : Colors.white,
//                   padding: i == 4 ? data['latitude'] == null ? EdgeInsets.all(15) : EdgeInsets.only(left: 15) : EdgeInsets.all(15),
//                   child: new Align(
//                     alignment: Alignment.centerLeft,
//                     child: new Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: <Widget>[
//                         i == 4 ?
//
//                           Row(
//                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                             children: <Widget>[
//                             Expanded(child: text('Alamat : '+value[i])),
//                             data['latitude'] == null ? SizedBox.shrink() :
//
//                               Container(
//                                 child: WidSplash(
//                                   color: TColor.azure(), padding: EdgeInsets.all(13),
//                                   onTap: (){
//                                     openMap(double.parse(data['latitude']), double.parse(data['longitude']));
//                                   },
//                                   child: Icon(Ic.gps(), size: 20, color: Colors.white)
//                                 )
//                               ),
//                           ],) :
//                         text(title[i]+' : '+value[i]),
//                       ],
//                     ),
//                   )
//                 );
//             }
//           ),
//         )
//
//       ),
//     );
//
//   }
// }
