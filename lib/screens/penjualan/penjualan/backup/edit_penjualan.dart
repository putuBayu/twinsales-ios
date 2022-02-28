import 'package:flutter/material.dart';
import 'package:sales/services/api/api.dart';
import 'package:sales/services/helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditPenjualan extends StatefulWidget {
  final data;
  EditPenjualan({this.data});

  _EditPenjualanState createState() => _EditPenjualanState();
}

class _EditPenjualanState extends State<EditPenjualan> {
  var keterangan = new TextEditingController();
  
  var tipePembayaran = 'credit', data, tipeHarga = 'wbp';
  double textPadding = 15; bool isSave = false;

  var tpRadio = 0;

  var listTipePembayaran = ['credit','cash'],
      listTipeHarga = ['wbp', 'rbp', 'hcobp'];

  initForms() async{ // ambil data penjualan dari localstorage
    var prefs = await SharedPreferences.getInstance(); data = widget.data;
    var tb = prefs.getString('epTb'), th = prefs.getString('epTh'), kt = prefs.getString('epKt');
      
      if(tb == null || th == null || kt == null){

        prefs.setString('epTb', data['tipe_pembayaran']);
        prefs.setString('epTh', data['tipe_harga']);
        prefs.setString('epKt', data['keterangan']);

        setState(() {
          tipePembayaran = data['tipe_pembayaran']; tpRadio = listTipePembayaran.indexOf(data['tipe_pembayaran']);
          tipeHarga = data['tipe_harga'];
          keterangan.text = data['keterangan'];
        });

      }else{
        setState(() {
          tipePembayaran = prefs.getString('epTb'); tpRadio = listTipePembayaran.indexOf(prefs.getString('epTb'));
          tipeHarga = prefs.getString('epTh');
          keterangan.text = prefs.getString('epKt');
        });
      }
  }

  @override
  void initState() {
    super.initState();
    initForms();
  }

  void editPenjualan() async {
    setState(() { isSave = true; });

    var formData = {
      'id_toko': data['toko'][0]['id'].toString(),
      'id_salesman': data['salesman'][0]['id'].toString(),
      'tanggal': data['tanggal'],
      'tipe_pembayaran': tipePembayaran.toLowerCase(),
      'tipe_harga': tipeHarga.toLowerCase(),
      'keterangan': keterangan.text
    };

    Request.put('penjualan/'+data['id'].toString(), formData: formData, debug: true, then: (s, d){
      if(s == 201){
        setPrefs('epTb', tipePembayaran);
        setPrefs('epTh', tipeHarga);
        setPrefs('epKt', keterangan.text);

        Wi.toast('Berhasil diperbarui');
        Navigator.of(context).pop();
      }else{
        setState(() => isSave = false );
      }
    }, error: (err){
      setState(() => isSave = false );
      onError(context, response: err, popup: true, backOnDismiss: true);
    });
  }

  @override
  Widget build(BuildContext context) {

    return Unfocus(
      child: Scaffold(
        appBar: Wi.appBar(context, title: 'Edit Penjualan'),

        body: PreventScrollGlow(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FormControl.radio(label: 'Tipe Pembayaran', values: listTipePembayaran, checked: tipePembayaran, onChange: (r){
                  setState(() => tipePembayaran = r );
                }),

                FormControl.radio(label: 'Tipe Harga', values: listTipeHarga, checked: tipeHarga, onChange: (r){
                  setState(() => tipeHarga = r );
                }),

                FormControl.input(label: 'Keterangan', maxLines: 3, controller: keterangan),
                FormControl.button(textButton: 'Simpan', isSubmit: isSave, onTap: (){
                  editPenjualan();
                })

              ]
            ),
          ),
        ),
      ),
    );
  }
}
