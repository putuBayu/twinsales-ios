import 'package:flutter/material.dart';
import 'package:sales/services/v2/helper.dart';

class Panduan extends StatefulWidget {
  final Widget child;
  Panduan({Key key, this.child}) : super(key: key);
  _PanduanState createState() => _PanduanState();
}

class _PanduanState extends State<Panduan> {

  int expanded = 0;

  @override
  void initState() { 
    super.initState();
  }

  onListTap(i, index, list){
    switch (i) {
      case 0:
        switch (index) {
          case 0: Wh.alert(context, title: list, message: '1. Pilih menu penjualan<br>2. Pilih penjualan baru<br>3. Lengkapi form dan klik simpan<br>4. Klik icon <b>Plus (+)</b> untuk menambah barang<br>5. Lengkapi form dan klik simpan'); break;
          case 1: Wh.alert(context, title: list, message: '1. Pilih menu penjualan<br>2. Pilih penjualan hari ini<br>3. Pilih toko'); break;
          case 2: Wh.alert(context, title: list, message: '1. Pilih menu penjualan<br>2. Pilih riwayat penjualan<br>3. Pilih penjualan<br>4. Pilih daftar penjualan'); break;
          case 3: Wh.alert(context, title: list, message: '1. Pilih menu penjualan<br>2. Pilih penjualan hari ini<br>3. Pilih toko<br>4. Tekan lama item<br>5. Pilih edit<br>6. Lengkapi form & simpan'); break;
          case 4: Wh.alert(context, title: list, message: '1. Pilih menu penjualan<br>2. Pilih penjualan hari ini<br>3. Pilih toko<br>4. Tekan lama item<br>5. Pilih hapus<br>6. Pilih iya'); break;
          case 5: Wh.alert(context, title: list, message: '1. Pilih menu penjualan<br>2. Pilih retur penjualan<br>3. Tap ikon <b>Kalender</b> pojok kanan atas untuk pencarian<br>4. Tap ikon <b>Plus (+)</b> pojok kanan bawah untuk menambah data<br>5. Pilih daftar retur untuk melihat detail retur<br>6. Tap icon <b>Plus (+)</b>untuk menambah barang<br>7. Tahan daftar barang untuk edit atau menghapus barang retur'); break;
          case 6: Wh.alert(context, title: list, message: '1. Pilih menu penjualan<br>2. Pilih pelunasan<br>3. Tap ikon <b>Cari</b> di pojok kanan atas untuk mencari no. invoice<br>4. Pilih daftar pelunasan untuk melihat detail pelunasan<br>5. Tekan tombol <b>Plus(+)</b> di pojok kanan bawah untuk membuat pelunasan<br>6. Masukkan Tipe Retur dan Nominal kemudian tekan <b>Simpan</b><br>7. Tekandan Tahan pelunasan untuk mengedit atau menghapus pelunasan'); break;
          case 7: Wh.alert(context, title: list, message: '1. Pilih menu penjualan<br>2. Pilih Call<br>3. Tap ikon <b>+</b><br>4. Geser peta untuk menentukan lokasi toko<br>5. Lengkapi form dan klik simpan<br>6. Tahan daftar kunjungan untuk edit atau menghapus kunjungan'); break;
          case 8: Wh.alert(context, title: list, message: '1. Pilih menu penjualan<br>2. Pilih Riwayat Call<br>3. Pilih tanggal kunjungan<br>4. Pilih daftar daftar kunjungan<br>'); break;
        } break;

      case 1:
        switch (index) {
          case 0: Wh.alert(context, title: list, message: '1. Pilih menu toko'); break;
          case 1: Wh.alert(context, title: list, message: '1. Pilih menu toko<br>2. Tap daftar toko'); break;
        } break;

      case 2:
        switch (index) {
          case 0: Wh.alert(context, title: list, message: '1. Pilih menu barang'); break;
          case 1: Wh.alert(context, title: list, message: '1. Pilih menu barang<br>2. Tap daftar barang'); break;
          case 2: Wh.alert(context, title: list, message: '1. Pilih menu barang<br>2. Tap icon <b>Barcode</b> pojok kanan atas<br>3. Arahkan kamera ke barcode barang'); break;
        } break;

      case 3:
        switch (index) {
          case 0: Wh.alert(context, title: list, message: '1. Pilih menu promo'); break;
          case 1: Wh.alert(context, title: list, message: '1. Pilih menu promo<br>2. Tap daftar promo'); break;
        } break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      backgroundColor: TColor.silver(),
      appBar: Wh.appBar(context, title: 'Panduan', center: true),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(15),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black12),
            borderRadius: BorderRadius.circular(4),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Column(
              children: List.generate(4, (int i){
                var labels = ['Penjualan','Toko','Barang','Promo'];
                var lists = [
                  ['Input Penjualan & Barang','Melihat Penjualan Hari Ini','Melihat Riwayat Penjualan','Mengubah Data Barang','Menghapus Data Barang','Retur Penjualan','Pelunasan','Melakukan Kunjungan', 'Melihat Riwayat Kunjungan'],
                  ['Daftar toko','Detail toko'],
                  ['Daftar Barang','Detail Barang','Scan Barcode Barang'],
                  ['Daftar Promo','Detail Promo'],
                ];

                return Container(
                  decoration: BoxDecoration(
                    border: i == 3 ? null : Border(
                      bottom: BorderSide(color: Colors.black12)
                    )
                  ),
                  child: ListExpanded(
                    label: labels[i],
                    expanded: expanded,
                    total: lists[i].length,
                    id: i,
                    onTap: (){
                      setState(() {
                        expanded = i;
                      });
                    },
                    children: List.generate(lists[i].length, (l){
                      var list = lists[i][l];

                      return WidSplash(
                        onTap: (){
                          onListTap(i, l, lists[i][l]);
                        },
                        color: Color.fromRGBO(0, 0, 0, .03),
                        child: Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border(
                                top: BorderSide(color: Colors.black12)
                            )
                          ),
                          width: Mquery.width(context),
                          child: Row(
                            children: <Widget>[
                              Container(
                                margin: EdgeInsets.only(right: 5),
                                child: Icon(Ic.chevright(), size: 17),
                              ),
                              text(list),
                            ],
                          )
                        ),
                      );
                    }),
                  )
                );
              })
            ),
          ),
        ),
      ),
    );
  }
}