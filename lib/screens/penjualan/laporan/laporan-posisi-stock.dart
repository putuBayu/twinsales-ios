import 'package:flutter/material.dart';
import 'package:sales/services/api/api.dart';
import 'package:sales/services/v2/helper.dart';
import 'package:sales/services/v3/helper.dart';
import 'package:sales/widgets/modal.dart';
import 'package:sales/widgets/printer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';

class LaporanPosisiStock extends StatefulWidget {
  final ctx, auth;
  LaporanPosisiStock(this.ctx, {this.auth});

  @override
  _LaporanPosisiStockState createState() => _LaporanPosisiStockState();
}

class _LaporanPosisiStockState extends State<LaporanPosisiStock> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  var tanggal = Dt.ymd;

  var laporan = [], dataFilter = [], loading = false, filter = {}, isSearch = false, isKeywordSearch = false, isSales = false;
  double totalQty = 0, totalPcs = 0, totalValue = 0;


  // filter
  var fGudang = TextEditingController(), fIdGudang = '',
      fTanggal = TextEditingController(text: Dt.ymd);

  getData() async{
    var prefs = await SharedPreferences.getInstance(), roles = prefs.getString('roles');

    setState(() {
      loading = true; totalQty = 0; totalPcs = 0; totalValue = 0;
    });

    if(roles != null){
      isSales = decode(roles).indexOf('salesman') > -1 || decode(roles).indexOf('salesman canvass') > -1;
    }

    getPrefs('id_gudang').then((idg){
      if(isSales){
        Request.get('report/posisi_stock?tanggal='+tanggal+'&id_gudang='+idg.toString(),then: (s, body){
          laporan = dataFilter = decode(body)['data']; countTotal(laporan);
          setState(() => loading = false );
        }, error: (err){
          setState(() => loading = false );
          onError(context, response: err, popup: true);
        });
      }else{
        Request.get('report/posisi_stock?tanggal='+fTanggal.text+'&id_gudang='+fIdGudang.toString(), then: (s, body){
          laporan = dataFilter = decode(body)['data']; countTotal(laporan);
          setState(() => loading = false );
        }, error: (err){
          setState(() => loading = false );
          onError(context, response: err, popup: true);
        });
      }
    });
  }

  countTotal(List data){
    data.forEach((f){
      totalQty += f['saldo_akhir_qty'];
      totalPcs += f['saldo_akhir_pcs'];
      totalValue += f['nilai_stock'];
    });
  }

  @override
  void initState() {
    super.initState(); getData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,

      appBar: Wh.appBar(context, title: !isKeywordSearch ? 'Laporan Posisi Stock' : 

        Fc.search(hint: 'Ketik kode atau nama barang', autofocus: true, change: (String s){
          var k = s.toLowerCase();
          setState(() {
            dataFilter = laporan.where((item) => item['kode_barang'].toLowerCase().contains(k) || item['nama_barang'].toLowerCase().contains(k)).toList();
          });
        })

      ,actions: [
        IconButton(
          icon: Icon(isKeywordSearch ? Ic.close() : Ic.search(), size: 20, color: !isKeywordSearch && dataFilter.length == 0 ? Colors.black26 : Colors.black54),
          onPressed: !isKeywordSearch && dataFilter.length == 0 ? null : (){
            setState(() {
              isKeywordSearch = !isKeywordSearch;

              if(!isKeywordSearch){
                dataFilter = laporan;
              }
            });
          },
        ),

        isSales ?
        IconButton(
          icon: Icon(Ic.calendar(), size: 20),
          onPressed: (){
            Wh.datePicker(context, init: DateTime.parse(tanggal), max: Dt.dateTime(format: 'now+')).then((res){
              if(res != null){
                tanggal = res; isSearch = true; getData();
              }
            });
          },
        ) : IconButton(
          icon: Icon(Ic.filter(), color: loading ? Colors.black38 : Colors.black54, size: 20),
          onPressed: loading ? null : (){
            _scaffoldKey.currentState.openDrawer();
          },
        ),

        IconButton(
          onPressed: (){
            Modal.bottom(widget.ctx, child: Printer(print: (b){ print(b);
              PrintStock(data: dataFilter, tanggal: tanggal).run();
            }), wrap: true);
          },
          icon: Icon(Ic.print(), size: 20),
        )
      ]),

      body: loading ? ListSkeleton(length: 10) : dataFilter == null || dataFilter.length == 0 ? Wh.noData(message: !isSearch ? 'Tap filter untuk melakukan pencarian.' : 'Data laporan tidak ditemukan\nCobalah cari dengan tanggal yang lain') :
        
        Column(
          children: [
              
            Expanded(
              child: ListView.builder(
                itemCount: dataFilter.length,
                itemBuilder: (BuildContext context, i){
                  var data = dataFilter[i];

                  return WidSplash(
                    onTap: (){
                      modal(widget.ctx, child: DetailPosisiStock(data: data));
                    },
                    color: i % 2 == 0 ? TColor.silver() : Colors.white,
                    child: Container(
                      padding: EdgeInsets.all(15),
                      child: Container(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  text(data['kode_barang'], bold: true),
                                  text(data['nama_barang'])
                                ],
                              ),
                            ),

                            Container(
                              margin: EdgeInsets.only(left: 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: <Widget>[
                                  text('Rp '+ribuan(data['harga'], fixed: 2), bold: true),
                                  text(ribuan(data['saldo_akhir_qty']).toString()+'/'+data['saldo_akhir_pcs'].toString())
                                ],
                              ),
                            )
                          ],
                        ),
                      )
                      
                      
                    ),
                  );
                }
              ),
            ),

            Container(
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: TColor.azure()
                // boxShadow: [
                //   BoxShadow(
                //     color: Color.fromRGBO(0, 0, 0, .3),
                //     blurRadius: 20.0, // has the effect of softening the shadow
                //     spreadRadius: 5.0, // has the effect of extending the shadow
                //     offset: Offset( 2.0, 2.0 ),
                //   )
                // ],
                // border: Border(top: BorderSide(color: Colors.black12)),
                // image: DecorationImage(
                //   image: AssetImage('assets/img/line-card.png'),
                //   fit: BoxFit.fill,
                //   colorFilter: ColorFilter.linearToSrgbGamma()
                // )
              ),
              child: Column(
                children: List.generate(2, (int i){
                  var labels = ['Total Stock','Nilai Stock'],
                      values = [ribuan(totalQty, fixed: 0)+'/'+ribuan(totalPcs, fixed: 0),'Rp '+ribuan(totalValue.round())];

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      text(labels[i], bold: true, color: Colors.white),
                      text(values[i], bold: true, color: Colors.white),
                    ],
                  );
                })
              )
              
              // Column(
              //   children: List.generate(1, (int i){
              //     var labels = ['Total Stock','Nilai Stock'],
              //         values = [ribuan(totalQty, fixed: 0)+'/'+ribuan(totalPcs, fixed: 0), 'Rp '+ribuan(totalValue, fixed: 2)];
              //         // values = [ribuan(totalQty, fixed: 0)+'/'+ribuan(totalPcs, fixed: 0), 'Rp '+ribuan(totalValue, fixed: 2)];

              //     return Row(
              //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //       children: <Widget>[
              //         text(labels[i], bold: true, color: Colors.white),
              //         text(values[i], bold: true, color: Colors.white),
              //       ],
              //     );
              //   })
              // ),
            )
          
          ]
        ),


      drawer: Drawer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: Mquery.width(context),
              padding: EdgeInsets.only(left: 15, right: 15, top: 18.7, bottom: 19), decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.black12))
              ),
              child: text('FILTER POSISI STOCK')
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(15),
                child: Column(
                  children: <Widget>[

                    SelectInput(
                      controller: fGudang, label: 'Pilih Gudang', hint: 'Pilih gudang',
                      select: (){
                        modal(widget.ctx, child: DataGudang(), then: (res){
                          if(res != null){
                            setState(() {
                              fIdGudang = res['id'].toString();
                              fGudang.text = res['nama'];
                            });
                          }
                        });
                      },
                    ),

                    SelectInput(
                      suffix: Ic.calendar(), controller: fTanggal, label: 'Tanggal',
                      select: (){
                        Wh.datePicker(context, init: DateTime.parse(fTanggal.text)).then((res){
                          focus(context, FocusNode());
                          if(res != null) setState(() => fTanggal.text = res );
                        });
                      },
                    ),


                  ],
                ),
              ),
            ),

            Container(
              padding: EdgeInsets.all(15),
              child: Button(
                text: 'Cari',
                onTap: (){
                  if(fIdGudang == ''){
                    Wh.toast('Pilih gudang');
                  }else{
                    filter['id'] = fIdGudang.toString();
                    filter['tanggal'] = fTanggal.text;

                    getData();
                    Navigator.pop(context);
                  }
                },
              ),
            ),
            
          ]
        ),
      ),

    );
  }
}


class DetailPosisiStock extends StatefulWidget {
  DetailPosisiStock({Key key, this.data});
  final data;

  @override
  _DetailTokoState createState() => _DetailTokoState();
}

class _DetailTokoState extends State<DetailPosisiStock>{

  var labels = ['kode barang','nama barang','saldo awal','pembelian','mutasi masuk','penjualan','mutasi keluar','saldo akhir','harga','nilai stock'], 
      values = [];

  initData(){
    var _ = widget.data;

    values.add(_['kode_barang']);
    values.add(_['nama_barang']);
    values.add(ribuan(_['saldo_awal_qty'])+'/'+ribuan(_['saldo_awal_pcs']));
    values.add(_['pembelian_qty'].toString()+'/'+_['pembelian_pcs'].toString());
    values.add(_['mutasi_masuk_qty'].toString()+'/'+_['mutasi_masuk_pcs'].toString());
    values.add(_['penjualan_qty'].toString()+'/'+_['penjualan_pcs'].toString());
    values.add(_['mutasi_keluar_qty'].toString()+'/'+_['mutasi_keluar_pcs'].toString());
    values.add(ribuan(_['saldo_akhir_qty'])+'/'+ribuan(_['saldo_akhir_pcs']));
    values.add('Rp '+ribuan(_['harga']));
    values.add('Rp '+ribuan(_['nilai_stock']));
  }

  @override
  void initState() {
    super.initState(); initData();
  }

  @override
  Widget build(BuildContext context) {

    return ZoomIn(
      child: Scaffold(
        appBar: Wh.appBar(context, title: 'Detail Stock'),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(labels.length, (int i){
              return Container(
                color: i % 2 == 0 ? TColor.silver() : Colors.white,
                width: Mquery.width(context),
                padding: EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    text(ucword(labels[i]), bold: true),
                    text(values.length <= i ? '-' : values[i])
                  ],
                ),
              );
            }),
          ),
        ),
      )
    );
   
  }
}

class DataGudang extends StatefulWidget {
  @override
  _DataGudangState createState() => _DataGudangState();
}

class _DataGudangState extends State<DataGudang> {
  bool loading = true;
  List gudang = [], filter = [];

  getGudang({refresh: false}){
    setState((){ loading = true; });

    getPrefs('gudang', dec: true).then((res){
      if(res == null || refresh){
        Request.get('gudang?per_page=all', then: (s, body){
          var data = decode(body)['data'];

          setPrefs('gudang', data, enc: true);
          setState(() { gudang = filter = data; loading = false; });
        }, error: (err){
          setState(() => loading = false );
          onError(context, response: err, popup: true);
        });
      }else{
        setState(() {
          loading = false;
          gudang = filter = res; 
        });
      }
    });
  }

  @override
  void initState() {
    super.initState(); getGudang();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Wh.appBar(context, title: Fc.search(hint: 'Ketik kode atau nama gudang', change: (String s){
        var k = s.toLowerCase();

        setState((){
          filter = gudang.where((item) => item['kode_gudang'].toString().toLowerCase().contains(k) || item['nama_gudang'].toString().toLowerCase().contains(k)).toList();
        });
      }), 
      
      actions: [
        IconButton(
          icon: Icon(Ic.refresh(), size: 20, color: loading ? Colors.black38 : Colors.black54),
          onPressed: loading ? null : (){ getGudang(refresh: true); },
        )
      ]),

      body: loading ? ListSkeleton(length: 10) : filter.length == 0 ? Wh.noData(message: 'Tidak ada data gudang\nCoba refresh atau dengan kata kunci lain.') : 
        ListView.builder(
          itemCount: filter.length,
          itemBuilder: (BuildContext context, i){
            var data = filter[i];

            return WidSplash(
              onTap: (){
                Navigator.pop(context, {'id': data['id'], 'nama': data['nama_gudang']});
              },
              color: i % 2 == 0 ? TColor.silver() : Colors.white,
              child: Container(
                padding: EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    text(data['kode_gudang']+' - '+data['nama_gudang'], bold: true),
                    text(data['keterangan']),
                  ]
                )
              ),
            );
          }
        ),
    );
  }
}

class PrintStock {
  PrintStock({this.data, this.tanggal});
  BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;


  final data, tanggal;

  run(){
    bluetooth.isConnected.then((isConnected) async{
      if(isConnected){ //print(data);

        var total = 0.0;
        var sales = await Auth.user(field: 'name');

        var dataSales = await LocalData.get('log_salesman');

        var tim = decode(dataSales)['nama_tim'];

        bluetooth.printCustom("PT. KEMBAR PUTRA MAKMUR",1,1);
        bluetooth.printCustom("Jl. Anggrek I No. 1, Kapal, Mengwi, Badung",0,1);
        bluetooth.printCustom("(0361) 9006481 | www.kembarputra.com",0,1);

        bluetooth.printCustom("------------------------------------------",0,1);

        bluetooth.printLeftRight('POSISI STOCK', '  Tgl. '+dateFormat(tanggal),0);
        bluetooth.printCustom('SALESMAN : '+tim+' - '+sales,0,1);
        bluetooth.printCustom("saldo awal | mutasi masuk | mutasi keluar | penjualan | saldo akhir",0,1);
        bluetooth.printCustom("------------------------------------------",0,1);

        for (var i = 0; i < data.length; i++) {
          var item = data[i];

          var saq = item['saldo_awal_qty'].toString(),
              sap = item['saldo_awal_pcs'].toString(),
              mmq = item['mutasi_masuk_qty'].toString(),
              mmp = item['mutasi_masuk_pcs'].toString(),
              mkq = item['mutasi_keluar_qty'].toString(),
              mkp = item['mutasi_keluar_pcs'].toString(),
              pq = item['penjualan_qty'].toString(),
              pp = item['penjualan_pcs'].toString(),
              sakq = item['saldo_akhir_qty'].toString(),
              sakp = item['saldo_akhir_pcs'].toString();

          // print(i.toString()+' -> '+sakq+'|'+sakp);


          if(sakq != '0' || sakp != '0'){
            total += item['nilai_stock'];

            bluetooth.printCustom(item['kode_barang']+' - '+item['nama_barang'],0,0);
            bluetooth.printCustom(saq+'/'+sap+'  |  '+mmq+'/'+mmp+'  |  '+mkq+'/'+mkp+'  |  '+pq+'/'+pp+'  |  '+sakq+'/'+sakp,0,0);
            bluetooth.printCustom('Nilai Stock : '+ribuan(item['nilai_stock']),0,0);
            bluetooth.printNewLine();
          }

          // if(i == 1) break;
        }

        bluetooth.printCustom('Total : '+Cur.rupiah(total),0,0);

        bluetooth.printNewLine();
        bluetooth.printCustom('--== Terima Kasih ==--',0,1);
        bluetooth.printNewLine();
        bluetooth.printNewLine();
        bluetooth.printNewLine();
        bluetooth.paperCut();

      }
    });
  }
}