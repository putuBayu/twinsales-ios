import 'package:flutter/material.dart';
import 'package:sales/screens/barang/barang.dart';
import 'package:sales/services/api/api.dart';
import 'package:sales/services/v2/helper.dart';

class Gudang extends StatefulWidget {
  Gudang({this.ctx}); final ctx;

  @override
  _GudangState createState() => _GudangState();
}

class _GudangState extends State<Gudang> {
  var test = false;
  var gudang = [], filter = [], loading = true, keyword = TextEditingController();

  getDataGudang({refill: false}) async {
    setState(() => loading = true );

    Request.get('gudang?jenis=baik,canvass', then: (s, body){
      if(mounted) setState(() {
        loading = false;
        gudang = filter = decode(body)['data'];
      });
    }, error: (err){
      onError(context, response: err, popup: true);

      // if(mounted){
      //   setState(() => loading = false );
      // }
    });
  }
  
  @override
  void initState() {
    super.initState();
    if(mounted) getDataGudang();
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
                  color: gudang.length == 0 ? TColor.silver() : Colors.white
                ),
                child: Fc.search(hint: 'Ketik nama gudang', enabled: gudang.length != 0,  prefix: Icon(Ic.search(), size: 18), change: (String s){
                  var k = s.toLowerCase();
                setState(() {
                  filter = gudang.where(
                    (item) => item['nama_gudang'].toLowerCase().contains(k)
                  ).toList();
                });
                })
              ),
            ),
          ]
        ),
      ),

      body: loading ? ListSkeleton(length: 10) :
        filter.length == 0 ? Wh.noData(message: 'Tidak ada data gudang\nTap gambar untuk memuat ulang.', onTap: (){ getDataGudang(refill: true); }) :

        RefreshIndicator(
          onRefresh: () async{ getDataGudang(refill: true); },
          child: ListView.builder(
            itemCount: filter.length,
            itemBuilder: (BuildContext context, i){
              var data = filter[i];

              return WidSplash(
                color: i % 2 == 0 ? TColor.silver() : Colors.white,
                onTap: (){
                  modal(widget.ctx, child: Barang(ctx: widget.ctx, idGudang: data['id']));
                },
                child: Container(
                  padding: EdgeInsets.all(15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          text(data['nama_gudang'], bold: true),
                          text(data['jenis'])
                        ],
                      ),

                      Icon(Ic.chevright(), size: 20, color: Colors.black38)
                    ],
                  )
                ),
            );
           }
          )
        )
    );
  }
}