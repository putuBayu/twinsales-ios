import 'package:flutter/material.dart';
import 'package:sales/services/api/api.dart';
import 'package:sales/services/v2/helper.dart';
import 'package:sales/services/v3/helper.dart';

class ListSalesman extends StatefulWidget {
  ListSalesman({@required this.url});

  final url;

  @override
  _ListSalesmanState createState() => _ListSalesmanState();
}

class _ListSalesmanState extends State<ListSalesman> {

  bool loading = false;
  List salesman = [], filter = [];

  getData({refill: false}){
    setState(() => loading = true );

    getPrefs('salesman-01', dec: true).then((res){
      if(salesman == null || refill){

        Request.get(widget.url, then: (_, res){ print(res);
          salesman = filter = decode(res)['data'];

          // set to local data
          setPrefs('salesman-01', decode(res)['data'], enc: true);

          setState(() => loading = false );
        }, error: (err){
          onError(context, response: err);
        });

      }else{
        salesman = filter = res;
        setState(() => loading = false );
      }
    });

  }

  @override
  void initState() {
    super.initState(); getData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Wh.appBar(context, title: Input.field(hint: 'Ketik tim atau nama sales', enabled: !loading, change: (String s){
        String k = s.toLowerCase();

        setState(() {
          filter = salesman.where((item) => item['tim'].toString().toLowerCase().contains(k) || item['nama_salesman'].toString().toLowerCase().contains(k)).toList();
        });
      }), actions: [
        IconButton(
          icon: Icon(Ic.refresh(), size: 20, color: loading ? Colors.black26 : Colors.black54),
          onPressed: loading ? null : (){
            getData(refill: true);
          },
        )
      ]),

      body: loading ? 
        ListSkeleton(length: 15) : 
          filter == null || filter.length == 0 ? 
            Wh.noData(message: 'Tidak ada salesman, coba dengan kata kunci lain') :

        ListView.builder(
          itemCount: filter.length,
          itemBuilder: (BuildContext context, i){
            var data = filter[i];

            return WidSplash(
              padding: EdgeInsets.all(15),
              color: i % 2 == 0 ? TColor.silver() : Colors.white,
              onTap: (){
                Navigator.pop(context, {'id': data['id'], 'nama': data['nama_salesman']});
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  text(data['tim']+' - '+data['nama_salesman'])
                ]
              ),
            );
          }
        )
    );
  }
}