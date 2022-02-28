import 'package:flutter/material.dart';
import 'package:sales/services/api/api.dart';
import 'package:sales/services/v2/helper.dart';
import 'package:sales/services/v3/helper.dart';

class ListItem extends StatefulWidget {
  ListItem({@required this.url, this.multiple: false, this.selected});

  final String url, selected;
  final bool multiple;

  @override
  _ListItemState createState() => _ListItemState();
}

class _ListItemState extends State<ListItem> {

  bool loading = false;
  List items = [], filter = [], selected = [];

  getData({refill: false}){
    setState(() => loading = true );

    getPrefs('items-01', dec: true).then((res){
      if(res == null || refill){

        Request.get(widget.url, then: (_, res){
          items = filter = decode(res)['data'];

          // set to local data
          setPrefs('items-01', decode(res)['data'], enc: true);
          initSelected();

          setState(() => loading = false );
        }, error: (err){
          onError(context, response: err);
        });

      }else{
        items = filter = res;
        initSelected();
        setState(() => loading = false );
      }
    });

  }

  initSelected(){
    var data = widget.selected;
    if(data != null && data != ''){
      var id = data.split(',');

      for (var i = 0; i < id.length; i++) {
        selected.add(int.parse(id[i]));

        // if(i == id.length - 1){
        //   setState(() { });
        // }
      }
    }
  }

  @override
  void initState() {
    super.initState(); getData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Wh.appBar(context, title: Input.field(hint: 'Ketik kode atau nama barang', enabled: !loading, change: (String s){
        String k = s.toLowerCase();

        setState(() {
          filter = items.where((item) => item['kode_barang'].toString().toLowerCase().contains(k) || item['nama_barang'].toString().toLowerCase().contains(k)).toList();
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
            Wh.noData(message: 'Tidak ada barang, coba dengan kata kunci lain') :

        ListView.builder(
          itemCount: filter.length,
          itemBuilder: (BuildContext context, i){
            var data = filter[i];

            return WidSplash(
              color: i % 2 == 0 ? TColor.silver() : Colors.white,
              onTap: (){
                if(widget.multiple){
                  setState(() {
                    if(selected.indexOf(data['id']) > -1){
                      selected.removeWhere((item) => item == data['id']);
                    }else{
                      selected.add(data['id']);
                    }
                  });
                }else{
                  Navigator.pop(context, {'id': data['id'], 'nama': data['nama_barang']});
                }
              },
              child: Stack(
                children: [

                  Container(
                    padding: EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        text(data['kode_barang']+' - '+data['nama_barang'])
                      ]
                    ),
                  ),

                  Positioned(
                    right: 15, top: 10,
                    child: selected.indexOf(data['id']) < 0 ? SizedBox.shrink() : SlideLeft(
                      child: Container(
                        padding: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: TColor.gray(),
                          borderRadius: BorderRadius.circular(2)
                        ),
                        child: Icon(Ic.check(), size: 17, color: Colors.white,),
                      ),
                    )
                  ),
                  
                ]
              )
            );
          }
        ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: TColor.azure(),
        onPressed: (){
          Navigator.pop(context, {'id': selected.join(', ').replaceAll(new RegExp(r"\s+"), ""), 'nama': selected.length > 0 ? selected.length.toString()+' Barang' : ''});
        },
        child: selected.length == 0 ? Icon(Ic.check()) : text(selected.length, size: 20, color: Colors.white),
      ),
    );
  }
}