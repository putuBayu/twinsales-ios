import 'package:flutter/material.dart';
import 'package:sales/components/items/items.dart';
import 'package:sales/components/salesman/salesman.dart';
import 'package:sales/screens/penjualan/laporan/average-per-toko/lapt-drawer.dart';
import 'package:sales/services/api/api.dart';
import 'package:sales/services/v2/helper.dart';
import 'package:sales/services/v3/helper.dart';

class LaporanAveragePerToko extends StatefulWidget { // ✔
  LaporanAveragePerToko(this.ctx);

  final ctx;

  @override
  _LaporanAveragePerTokoState createState() => _LaporanAveragePerTokoState();
}

class _LaporanAveragePerTokoState extends State<LaporanAveragePerToko> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  bool loading = false, isSales = true;
  List laporan = [], filter = [];

  var item = TextEditingController(),
      startDate = TextEditingController(text: Dt.ymd),
      endDate = TextEditingController(text: Dt.ymd),
      salesman = TextEditingController(),

      date = TextEditingController(text: dateFormat(Dt.ymd));

  String idBarang = '', idSales = '';

  getData(){
    setState((){
      loading = true;
    });

    var params = 'id_barang='+idBarang+'&id_salesman='+idSales+'&start_date='+startDate.text+'&end_date='+endDate.text;
    Request.get('report/effective_call/item?'+params, then: (_, res){
      laporan = filter = decode(res);
      setState(() => loading = false );
    }, error: (err){
      onError(context, response: err, popup: true);
    });
  }

  initRole() async{
    isSales = await Roles.isSales();
    LocalData.get('user', decode: true).then((value) => idSales = isSales ? value['id'].toString() : '');
    setState((){ });
  }

  @override
  void initState(){
    super.initState(); initRole();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: Wh.appBar(context, title: 'Laporan Average Per Toko', actions: [
        IconButton(
          icon: Icon(Ic.filter(), size: 20),
          onPressed: (){
            _scaffoldKey.currentState.openDrawer();
          },
        )
      ]),

      body: loading ? ListSkeleton(length: 15) : 
        filter == null || filter.length == 0 ? Wh.noData(message: 'Tidak ada data laporan\nTap gambar untuk memuat ulang.', onTap: (){ getData(); }) :
      
      ListView.builder(
        itemCount: filter.length,
        itemBuilder: (BuildContext context, i){
          var data = filter[i];

          return WidSplash(
            onTap: (){
              Wh.toast(data['total_pcs'].toString()+' pcs dari '+data['jumlah_toko'].toString()+' toko');
            },
            color: i % 2 == 0 ? TColor.silver() : Colors.white,
            child: Container(
              padding: EdgeInsets.all(15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[

                  Flexible(
                    child: Column(
                      children: [
                        text(data['kode_barang']+' - '+data['nama_barang'])
                      ]
                    ),
                  ),

                  Container(
                    margin: EdgeInsets.only(left: 15),
                    padding: EdgeInsets.only(left: 5, right: 5, top: 2, bottom: 2),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey,
                      borderRadius: BorderRadius.circular(2)
                    ),
                    child: text(data['total_pcs'].toString()+'/'+data['jumlah_toko'].toString(), color: Colors.white)
                  )
                ],
              ),
            ),
          );
        }
      ),

      drawer: LaptDrawer(
        title: 'FILTER LAPORAN',
        body: [

          SelectInput(
            controller: item, label: 'Pilih Barang', hint: 'Pilih barang',
            select: (){
              modal(widget.ctx, child: ListItem(url: 'barang', multiple: true, selected: idBarang), then: (res){
                if(res != null){
                  setState(() {
                    idBarang = res['id'].toString();
                    item.text = res['nama'];
                  });
                }
              });
            },
          ),

          isSales ? SizedBox.shrink() :
          SelectInput(
            controller: salesman, label: 'Pilih Salesman', hint: 'Pilih salesman',
            select: (){
              modal(widget.ctx, child: ListSalesman(url: 'salesman'), then: (res){
                if(res != null){
                  setState(() {
                    idSales = res['id'].toString();
                    salesman.text = res['nama'];
                  });
                }
              });
            },
          ),

          SelectInput(
            controller: date, label: 'Pilih Tanggal', hint: 'Pilih tanggal', suffix: Ic.calendar(),
            select: (){
              Wh.dateRangePicker(context, firstDate: DateTime.parse(startDate.text), lastDate: DateTime.parse(endDate.text), max: DateTime(Dt.y, Dt.m, Dt.d)).then((res){
                if(res != null) setState(() {

                  _res(i){ return res[i].toString().split(' ')[0]; }

                  if(res.length == 1){
                    startDate.text = endDate.text = _res(0);
                    date.text = dateFormat(_res(0));
                  }else{
                    startDate.text = _res(0);
                    endDate.text = _res(1);
                    date.text = dateFormat(_res(0))+' - '+dateFormat(_res(1));
                  }
                });
              });
            },
          )

        ],

        footer: Container(
          padding: EdgeInsets.all(15),
          child: Button(
            text: 'Filter',
            onTap: (){
              getData();
              Navigator.pop(context);
            },
          ),
        ),
      ),
    );
  }
}