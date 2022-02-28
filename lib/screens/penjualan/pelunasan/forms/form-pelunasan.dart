import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sales/services/api/api.dart';
import 'package:sales/services/v2/helper.dart';
import 'package:sales/services/v3/helper.dart';

class FormPelunasan extends StatefulWidget {
  final data, isEdit, dataPelunasan, autoNominal;
  FormPelunasan(
      {this.data, this.isEdit: false, this.dataPelunasan, this.autoNominal});

  @override
  _FormPelunasanState createState() => _FormPelunasanState();
}

class _FormPelunasanState extends State<FormPelunasan> {
  DateTime selectedDate = DateTime.now();
  Timer pingLooper;

  var type = TextEditingController(text: 'tunai');

  var nominal = TextEditingController();
  var bank = TextEditingController();
  var rek = TextEditingController();
  var giro = TextEditingController();
  var tempo = TextEditingController();
  var noInvoiceRebate = TextEditingController();
  var keterangan = TextEditingController();
  var noRetur = TextEditingController();

  var saldo, isLoadSaldo = true;
  var look = '';

  bool isSubmit = false;
  // var listTipe = ['tunai','transfer','bilyet_giro','saldo_retur', 'cash_rebate', 'lainnya'];
  var listTipe = [
    'tunai',
    'transfer',
    'bilyet_giro',
    'biaya',
    'retur',
    'promo',
    'lainnya'
  ];
  var listTipeBiaya = ['Biaya Transfer', 'Biaya Materai', 'Biaya PO'];
  var listReturPenjualan = [];

  save() {
    submit() {
      setState(() {
        isSubmit = true;
      });

      var formData = {
        'id_penjualan': widget.data['id'].toString(),
        'tipe': type.text,
        'nominal': nominal.text,
        'bank': bank.text,
        'no_rekening': rek.text,
        'no_bg': giro.text,
        'jatuh_tempo_bg': tempo.text,
        'no_invoice_rebate': noInvoiceRebate.text,
        'keterangan': keterangan.text
      };

      if (widget.isEdit) {
        Request.put(
            'detail_pelunasan_penjualan/' +
                widget.dataPelunasan['id'].toString(),
            formData: formData,
            debug: true, then: (status, body) {
          Map res = decode(body);
          Wh.toast(res['message']);
          Navigator.pop(context, {'updated': 'success'});
        }, error: (err) {
          onError(context, response: err, popup: true);
        });
      } else {
        Request.post('detail_pelunasan_penjualan', formData: formData,
            then: (status, body) {
          Map res = decode(body);
          Wh.toast(res['message']);
          Navigator.pop(context, {'added': 'success'});
        }, error: (err) {
          onError(context, response: err, popup: true);
        });
      }
    }

    switch (type.text) {
      case 'tunai':
        if (nominal.text.isEmpty) {
          Wh.toast('Isi nominal');
        } else {
          submit();
        }
        break;

      case 'saldo_retur':
        if (nominal.text.isEmpty) {
          Wh.toast('Isi nominal');
        } else {
          submit();
        }
        break;

      case 'transfer':
        if (nominal.text.isEmpty || bank.text.isEmpty) {
          Wh.toast('Lengkapi form');
        } else {
          submit();
        }
        break;

      case 'bilyet_giro':
        if (nominal.text.isEmpty ||
            bank.text.isEmpty ||
            giro.text.isEmpty ||
            tempo.text.isEmpty) {
          Wh.toast('Lengkapi form');
        } else {
          submit();
        }
        break;

      case 'cash_rebate':
        if (noInvoiceRebate.text.isEmpty) {
          Wh.toast('Isi no invoice rebate');
        } else {
          submit();
        }
        break;

      default:
        if (nominal.text.isEmpty || keterangan.text.isEmpty) {
          Wh.toast('Lengkapi form');
        } else {
          submit();
        }
        break;
    }
  }

  _getSaldoRetur(checked) {
    setState(() {
      saldo = null;
      isLoadSaldo = true;
    });

    if (checked == 'saldo_retur') {
      setState(() {
        isLoadSaldo = false;
      });

      Request.get('toko/get_saldo_retur/' + widget.data['id_toko'].toString(),
          then: (status, body) {
        var data = decode(body);
        setState(() {
          saldo = data['saldo_retur'].toString();
          isLoadSaldo = true;
        });

        nominal.text = data['saldo_retur'] < int.parse(widget.autoNominal)
            ? data['saldo_retur'].toString()
            : widget.autoNominal;
      }, error: (err) {
        onError(context, response: err, popup: true);
      });
    } else {
      if (widget.autoNominal != null) {
        nominal.text = widget.autoNominal;
      }
    }
  }

  _getReturPenjualan() {
    Request.get('retur_penjualan/list/?no_retur=' + noRetur.text,
        then: (status, body) {
      var data = decode(body);
      var res = [];
      for (var row in data) {
        res.add(row['id'].toString() +
            ' ' +
            row['nama_toko'] +
            ' ' +
            row['nama_salesman'] +
            ' (' +
            row['nama_tim'] +
            ')');
      }
      setState(() {
        listReturPenjualan = res;
        keterangan.text = '';
        look = ' Berhasil diload Silahkan Pilih disini';
      });
    }, error: (err) {
      onError(context, response: err, popup: true);
    });
  }

  initForm() {
    if (widget.autoNominal != null) {
      nominal.text = widget.autoNominal;
    }

    tempo.text = Dt.ymd;

    if (widget.isEdit) {
      var _ = widget.dataPelunasan;

      type.text = _['tipe'];
      nominal.text = _['nominal'];
      bank.text = _['bank'];
      rek.text = _['no_rekening'];
      giro.text = _['no_bg'];
      tempo.text = _['jatuh_tempo_bg'];
      noInvoiceRebate.text = _['no_invoice_rebate'];
      keterangan.text = _['keterangan'];

      if (_['jatuh_tempo_bg'] == '0000-00-00') {
        tempo.text = Dt.ymd;
      }

      if (_['jatuh_tempo_bg'] != null) {
        if (_['jatuh_tempo_bg'] == '0000-00-00') {
          selectedDate = DateTime.parse(Dt.ymd);
        } else {
          selectedDate = DateTime.parse(_['jatuh_tempo_bg']);
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    initForm();

    DateTime start = DateTime.now();
    pingLooper = Timer.periodic(Duration(seconds: 5), (Timer t) {
      setState(() {
        CheckPing().intConnection();
        CheckPing().getPingMs(start);
      });
    });
  }

  @override
  void dispose() {
    if (this.mounted) {
      pingLooper.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Unfocus(
      child: Scaffold(
        appBar: Wh.appBar(context,
            title: widget.isEdit ? 'Edit Pelunasan' : 'Buat Pelunasan',
            center: true,
            actions: [
              Padding(
                  padding: const EdgeInsets.only(right: 10.0),
                  child: pingStyle(CheckPing().getTimeRespond()))
            ]),
        body: PreventScrollGlow(
            child: Column(
          children: <Widget>[
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(15),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SelectInput(
                        label: 'Tipe Pelunasan',
                        controller: type,
                        select: () {
                          Wh.options(context,
                              backOnSelected: true,
                              values: listTipe,
                              options: listTipe
                                  .map((e) => ucword(e.replaceAll('_', ' ')))
                                  .toList(), then: (res) {
                            _getSaldoRetur(res);
                            setState(() {
                              type.text = res;
                            });
                          });
                        },
                      ),
                      type.text == 'saldo_retur'
                          ? SlideUp(
                              child: Container(
                                  margin: EdgeInsets.only(bottom: 25),
                                  padding: EdgeInsets.only(
                                      left: 15, right: 15, top: 10, bottom: 10),
                                  decoration: BoxDecoration(
                                      color: TColor.azure(),
                                      borderRadius: BorderRadius.circular(2)),
                                  child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        text('Saldo Retur : ',
                                            color: Colors.white),
                                        !isLoadSaldo
                                            ? Wh.spiner(
                                                size: 17, color: Colors.white)
                                            : SlideLeft(
                                                child: text(
                                                    'Rp ' + ribuan(saldo),
                                                    color: Colors.white))
                                      ])))
                          : SizedBox.shrink(),
                      TextInput(
                        label: 'Nominal',
                        hint: 'Nominal',
                        type: TextInputType.datetime,
                        controller: nominal,
                      ),
                      type.text != 'cash_rebate'
                          ? SizedBox.shrink()
                          : SlideUp(
                              child: TextInput(
                                  label: 'No. Invoice Rebate',
                                  hint: 'No. Invoice Rebate',
                                  controller: noInvoiceRebate)),
                      type.text != 'transfer' && type.text != 'bilyet_giro'
                          ? SizedBox.shrink()
                          : Column(children: [
                              type.text == 'lainnya'
                                  ? SizedBox.shrink()
                                  : SlideUp(
                                      child: TextInput(
                                          label: 'Bank',
                                          hint: 'Nama bank',
                                          controller: bank)),
                              type.text != 'transfer'
                                  ? SizedBox.shrink()
                                  : SlideUp(
                                      child: TextInput(
                                          label: 'No. Rekening',
                                          hint: 'Nomor rekening',
                                          controller: rek,
                                          type: TextInputType.datetime)),
                              type.text != 'bilyet_giro'
                                  ? SizedBox.shrink()
                                  : SlideUp(
                                      child: TextInput(
                                          label: 'No. Bilyet Giro',
                                          hint: 'No. bilyet giro',
                                          controller: giro)),
                              type.text != 'bilyet_giro'
                                  ? SizedBox.shrink()
                                  : SlideUp(
                                      child: SelectInput(
                                          label: 'Jatuh Tempo',
                                          suffix: Ic.calendar(),
                                          controller: tempo,
                                          select: () {
                                            Wh.datePicker(context,
                                                    init: DateTime.parse(
                                                        tempo.text))
                                                .then((res) {
                                              if (res != null)
                                                setState(
                                                    () => tempo.text = res);
                                            });
                                          })),
                            ]),
                      type.text != 'biaya' &&
                              type.text != 'promo' &&
                              type.text != 'retur'
                          ? TextInput(
                              label: 'Keterangan',
                              hint: 'Keterangan',
                              controller: keterangan,
                              maxLines: 3)
                          : SizedBox.shrink(),
                      type.text == 'promo'
                          ? TextInput(
                              label: 'No Promo',
                              hint: 'No Promo',
                              controller: keterangan,
                              maxLines: 3)
                          : SizedBox.shrink(),
                      type.text == 'biaya'
                          ? SelectInput(
                              label: 'Tipe Biaya',
                              hint: 'Tipe Biaya',
                              controller: keterangan,
                              select: () {
                                Wh.options(context,
                                    backOnSelected: true,
                                    values: listTipeBiaya,
                                    options: listTipeBiaya
                                        .map((e) =>
                                            ucword(e.replaceAll('_', ' ')))
                                        .toList(), then: (res) {
                                  setState(() {
                                    keterangan.text = res;
                                  });
                                });
                              },
                            )
                          : SizedBox.shrink(),
                      type.text == 'retur'
                          ? Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: <Widget>[
                                  Flexible(
                                      flex: 3,
                                      child: TextInput(
                                          label: 'Cari No Retur',
                                          hint: 'No Retur / Tim / Toko',
                                          controller: noRetur,
                                          maxLines: 3)),
                                  Flexible(
                                    child: Button(
                                      text: 'Cari',
                                      onTap: () => {_getReturPenjualan()},
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : SizedBox.shrink(),
                      type.text == 'retur'
                          ? SelectInput(
                              label: 'No Retur',
                              hint: 'No Retur' + look,
                              controller: keterangan,
                              enabled:
                                  listReturPenjualan.length > 0 ? true : false,
                              select: () {
                                Wh.options(context,
                                    backOnSelected: true,
                                    values: listReturPenjualan,
                                    options: listReturPenjualan, then: (res) {
                                  setState(() {
                                    keterangan.text = res;
                                  });
                                });
                              },
                            )
                          : SizedBox.shrink(),
                    ]),
              ),
            ),
            WhiteShadow(
              child: Button(
                text: 'Simpan',
                onTap: save,
                isSubmit: isSubmit,
              ),
            )
          ],
        )),
      ),
    );
  }
}
