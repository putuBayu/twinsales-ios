import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sales/screens/penjualan/penjualan/forms/form-penjualan.dart';
import 'package:sales/services/api/api.dart';
import 'package:sales/services/v2/helper.dart';
import 'package:sales/services/v3/helper.dart';

class FormReturToko extends StatefulWidget {
  FormReturToko({this.ctx, this.formData}); final ctx, formData;

  @override
  _FormReturTokoState createState() => _FormReturTokoState();
}

class _FormReturTokoState extends State<FormReturToko> {
  var toko = TextEditingController();
  var tipeRetur = TextEditingController(text: 'bs');
  // var tipeHarga = TextEditingController(text: 'wbp');
  var keterangan = TextEditingController();
  var noReturManual = TextEditingController();

  String idToko = '';
  bool isSubmit = false, loading = true;

  Timer pingLooper;

  //mitra
  List mitraValue;
  String selectedMitra = '0';
  // int selectedIdMitra = 0;

  getMitra({refill: false}) async{
    setState(() {
      loading = true;
    });
    getPrefs('mitra', dec: true).then((res) async{
      if(!refill && res != null){
        setState(() {
          mitraValue = res;
          loading = false;
          initForm();
        });
      }else{
        await Request.get('/mitra/list/simple', then: (status, body){
          if(mounted){
            Map res = decode(body);
            loading = false;

            var noMitra = {
              "id": 0,
              "kode_mitra": "",
              "perusahaan": "Tanpa Mitra"
            };

            setState(() {
              mitraValue = res['data'];
              mitraValue.insert(0, noMitra);
              setPrefs('mitra', mitraValue, enc: true);
              initForm();
              // tipeHarga.text = dataTipeHarga[0].toString();
            });

            return res;
          }
        }, error: (err){
          setState(() { loading = false; });
          onError(context, response: err);
        });
      }
    });
  }

  submit() async {
    var formData = {
      'id_toko': idToko.toString(),
      'tipe_barang': tipeRetur.text,
      // 'tipe_harga': tipeHarga.text,
      'keterangan': keterangan.text,
      'no_retur_manual': noReturManual.text,
      'id_mitra': selectedMitra.toString()
    };

    setState(() => isSubmit = true );
    pingLooper.cancel();
    if(widget.formData == null){
      Request.post('retur_penjualan', formData: formData, debug: true, then: (status, data){
        Map res = decode(data);
        Wh.toast(res['message']);
        Navigator.pop(context, {'message': 'retur added successfully', 'data': res['data']});
      }, error: (err){
        setState(() => isSubmit = false );
        onError(context, response: err, popup: true);
      });
    }else{
      formData['sales_retur_date'] = widget.formData['sales_retur_date'];

      Request.put('retur_penjualan/'+widget.formData['id'].toString(), formData: formData, then: (status, data){
        // tambah atribut toko untuk update perubahan pada halaman sebelumnya
        formData['nama_toko'] = toko.text;

        setState(() {
          widget.formData['keterangan'] = formData['keterangan'];
          widget.formData['tipe_barang'] = formData['tipe_barang'];
        });

        Map res = decode(data);
        Wh.toast(res['message']);
        // Wh.toast('Berhasil diperbarui');
        Navigator.pop(context, {'message': 'retur updated successfully', 'data': formData});
      
      }, error: (err){
        setState(() => isSubmit = false );
        onError(context, response: err, popup: true);
      });
    }
  }

  initForm(){
    if(widget.formData != null){
      var d = widget.formData; //print(d['tipe_barang']);
      toko.text = d['nama_toko'];
      idToko = d['id_toko'].toString();
      tipeRetur.text = d['tipe_barang'];
      keterangan.text = d['keterangan'];

      // selectedMitra = d['id_mitra'].toString();
      // selectedMitra = mitraValue[d['id_mitra']];
      for(int i=0; i<mitraValue.length; i++){
        if(mitraValue[i]['id'].toString().toLowerCase() == d['id_mitra'].toString().toLowerCase()){
          setState(() {
            selectedMitra = mitraValue[i]['id'].toString();
          });
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    getMitra();
    // initForm();

    DateTime start = DateTime.now();
    pingLooper = Timer.periodic(Duration(seconds: 5), (Timer t) {
      setState(() {
        CheckPing().intConnection();
        CheckPing().getPingMs(start);
      });
    });
  }

  @override
  void dispose(){
    if(this.mounted){
      pingLooper.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Unfocus(
      child: Scaffold(
        backgroundColor: TColor.silver(),
        appBar: Wh.appBar(
          context,
          title: widget.formData == null ? 'Buat Retur' : 'Edit Retur',
          center: true,
          actions:[
            Padding(
              padding: const EdgeInsets.only(left: 5.0),
              child: pingStyle(CheckPing.timeRespond),
            ),
            IconButton(
              icon: Icon(Ic.refresh(), size: 20,
                  color: loading ? Colors.black38 : Colors.black54
              ),
              onPressed: loading ? null : () {
                getMitra(refill: true);
              },
            ),
          ],
        ),
        
        body: loading? ListSkeleton(length: 10,) : PreventScrollGlow(
          child: Column(
            children: <Widget>[
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Dropdown(
                        values: selectedMitra,
                        space: 15,
                        label: 'Mitra',
                        hint: 'Pilih Mitra',
                        item: mitraValue.map((value){
                          return DropdownMenuItem<String>(
                            child: value['kode_mitra'] == null || value['kode_mitra'] == ''
                                ? text(value['perusahaan'])
                                : text(value['kode_mitra'] + ' - ' + value['perusahaan']),
                            value: value['id'].toString(),
                          );
                        }).toList(),
                        onChanged: (value){
                          if(widget.formData != null){
                            Wh.toast('Tidak dapat mengedit mitra');
                          }else{
                            setState(() {
                              selectedMitra = value;
                              for(int i = 0; i < mitraValue.length; i++){
                                if(mitraValue[i].toString() == value.toString()){
                                  setState(() {
                                    selectedMitra = i.toString();
                                    print(selectedMitra);
                                  });
                                }
                              }
                            });
                          }
                        },
                      ),
                      SelectInput(
                          label: 'Pilih Toko',
                          hint: 'Pilih toko',
                          controller: toko, enabled: widget.formData == null,
                          select: (){
                            modal(widget.ctx, radius: 5, child: DaftarToko(), then: (res){
                              if(res != null && res['id'] != null)
                                setState(() {
                                  toko.text = res['toko'];
                                  idToko = res['id'].toString();
                                });
                              });
                          }
                      ),

                      TextInput(
                          label: 'No. Retur Manual',
                          hint: 'Inputkan no. retur manual',
                          controller: noReturManual
                      ),

                      SelectGroup(
                          label: 'Tipe Retur Barang',
                          options: ['baik','bs'],
                          controller: tipeRetur
                      ),

                      // SelectGroup(label: 'Tipe Harga', options: ['wbp','rbp','hcobp','dbp+3'], labelsUppercase: true, controller: tipeHarga),

                      TextInput(
                          label: 'Keterangan',
                          hint: 'Inputkan keterangan',
                          controller: keterangan
                      ),
                    ]
                  ),
                ),
              ),

              WhiteShadow(
                child: Button(
                  text: 'Simpan',
                  onTap: submit,
                  isSubmit: isSubmit,
                ),
              )
            ],
          ),
        )
      ),
    );
  }
}