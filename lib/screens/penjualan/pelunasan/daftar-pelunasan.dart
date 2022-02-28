import 'package:flutter/material.dart';
import 'package:sales/screens/penjualan/pelunasan/detail-pelunasan.dart';
import 'package:sales/services/api/api.dart';
import 'dart:async';

import 'package:sales/services/v2/helper.dart';

class DaftarPelunasan extends StatefulWidget {
  final ctx;
  DaftarPelunasan({this.ctx});

  @override
  _DaftarPelunasanState createState() => _DaftarPelunasanState();
}

class _DaftarPelunasanState extends State<DaftarPelunasan>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  var loaded = true,
      perPage = 10,
      page = 1,
      isLoadMore = false,
      keyword = '',
      status = 'belum_lunas',
      dueDate = '';
  ScrollController scroll = new ScrollController();

  var dataPelunasan = [],
      dataFiltered = [],
      totalRow = 0,
      // lastData = 0,
      isMaxScroll = false;

  bool isSearch = false;

  // filter
  var fTanggal = TextEditingController(text: Dt.ymd),
      fStatus = TextEditingController(text: 'belum_lunas');

  loadDataPelunasan({refresh: false,}) async {
    if (dueDate == '') {
      dueDate = Dt.ymd;
    }
    page = 1;

    setState(() {
      loaded = false;
    });

    Request.get('pelunasan_penjualan?per_page=' + perPage.toString() + '&page=' + page.toString() + '&status=' + status + '&keyword=' + keyword + '&due_date=' + dueDate, then: (s, body) {
      Map res = decode(body);
      // loaded = true;
      // isSearch = false;
      dataFiltered = dataPelunasan = res['data'];

      // if (keyword.toString().isEmpty) {
      //   // jika bukan pencarian
      //   lastData = res['data'].length;
      // }
      totalRow = res['meta']['total'];
      setState(() {
        loaded = true;
      });
    }, error: (err) {
      setState(() {
        loaded = true;
      });
      onError(context, response: err, popup: true);
    });
  }

  loadMoreData() async {
    Request.get('pelunasan_penjualan?per_page=' + perPage.toString() + '&page=' + page.toString() + '&status=' + status + '&keyword=' + keyword + '&due_date=' + dueDate, then: (s, body) {
      Map res = decode(body);
      for (var i = 0; i < res['data'].length; i++) {
        dataPelunasan.add(res['data'][i]);
      }

      totalRow = res['meta']['total'];
      // lastData = lastData + res['data'].length;

      setState(() {
        isLoadMore = false;
      });

      Future.delayed(const Duration(milliseconds: 200), () {
        scroll.animateTo(
          scroll.position.maxScrollExtent - 50,
          curve: Curves.easeOut,
          duration: const Duration(milliseconds: 300),
        );
      });
    }, error: (err) {
      onError(context, response: err, popup: true);
    });
  }

  @override
  void initState() {
    super.initState();
    loadDataPelunasan();

    // watch scroll position
    scroll = ScrollController()
      ..addListener(() {
        double maxScroll = scroll.position.maxScrollExtent,
            currentScroll = scroll.position.pixels,
            delta = 50.0;

        setState(() {
          isMaxScroll = maxScroll - currentScroll <= delta ? true : false;
        });
      });
  }

  Future<Null> _onRefresh() async {
    keyword = '';
    loadDataPelunasan();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: Wh.appBar(context,
          title: isSearch ? Fc.search(
              hint: 'Cari pelunasan',
              autofocus: true,
              change: (String s) {
                var k = s.toLowerCase();
                setState(() {
                  keyword = k;
                  loadDataPelunasan();
                  // dataFiltered = dataPelunasan.where((element) => keyword.contains(k));
                  // dataFiltered = dataPelunasan.where((item) => item['nama_toko'].toLowerCase().contains(k) || item['no_invoice'].toLowerCase().contains(k)).toList();
                });
              }
          ) : 'Daftar Pelunasan',
          actions: [
            isSearch ? SizedBox.shrink() : SlideLeft(
              child: IconButton(
                icon: Icon(
                    Ic.filter(),
                    size: 20,
                    color: !loaded ? Colors.black12 : Colors.black54
                ),
                onPressed: !loaded ? null : () {
                  _scaffoldKey.currentState.openDrawer();
                },
              ),
            ),
            IconButton(
              icon: Icon(
                  isSearch ? Ic.close() : Ic.search(),
                  size: 20,
                  color: !loaded ? Colors.black12 : Colors.black54
              ),
              onPressed: !loaded ? null : () {
                setState(() {
                  isSearch = !isSearch;
                  if (!isSearch) {
                    _onRefresh();
                    dataFiltered = dataPelunasan;
                  }
                });
              },
            ),
          ]
      ),
      body: Stack(
        children: <Widget>[
          new RefreshIndicator(
            onRefresh: _onRefresh,
            child: !loaded ? ListSkeleton(length: 10) : new Container(
              child: dataFiltered == null || dataFiltered.length == 0 ? Wh.noData(
                message: 'Tidak ada data penagihan\nCobalah dengan menggunakan filter lain\natau tap gambar untuk memuat ulang',
                onTap: (){
                  _onRefresh();
                }
              ) : new ListView.builder(
                controller: scroll,
                itemCount: dataFiltered.length,
                itemBuilder: (context, i) {
                  var data = dataFiltered[i],
                      invoice = data['no_invoice'] == null ? '' : ' - ' + data['no_invoice'].toString();

                  return WidSplash(
                    color: i % 2 == 0 ? TColor.silver() : Colors.white38,
                    padding: EdgeInsets.all(15),
                    onTap: () {
                      modal(widget.ctx,
                          child: DetailPelunasan(
                            ctx: widget.ctx,
                            data: data,
                          )
                      );
                    },
                    child: Container(
                      child: new Column(
                        children: <Widget>[
                          new Container(
                            child: new Align(
                              alignment: Alignment.centerLeft,
                              child: new Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: <Widget>[
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: <Widget>[
                                        text(data['id'].toString() + '' + invoice, bold: true),
                                        text(data['nama_toko'].toString()),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    child: data['paid_at'] == null ? Icon(Ic.close(), color: Colors.redAccent, size: 20) : Icon(Ic.check(), size: 20, color: Colors.green),
                                  )
                                ],
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          PaginateControl(
            isMaxScroll: isMaxScroll,
            isLoad: isLoadMore,
            totalRow: totalRow,
            totalData: dataPelunasan.length,
            onTap: loadMore,
          )
        ],
      ),
      drawer: Drawer(
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                  width: Mquery.width(context),
                  padding: EdgeInsets.only(left: 15, right: 15, top: 18.7, bottom: 19),
                  decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.black12))
                  ),
                  child: text('FILTER PELUNASAN')),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(15),
                  child: Column(
                    children: <Widget>[
                      SelectInput(
                        suffix: Ic.calendar(),
                        controller: fTanggal,
                        label: 'Tanggal',
                        select: () {
                          Wh.datePicker(
                              context,
                              init: DateTime.parse(fTanggal.text),
                              max: Dt.dateTime(format: 'now+')).then((res) {
                                focus(context, FocusNode());
                                if (res != null) setState(() => fTanggal.text = res);
                              });
                          },
                      ),
                      Fc.radio(
                          values: ['semua', 'due_date', 'lunas', 'belum_lunas', 'over_due'],
                          label: 'Status', marginBottom: 0, controller: fStatus
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.all(15),
                child: Button(
                  text: 'Cari',
                  onTap: () {
                    status = fStatus.text;
                    dueDate = fTanggal.text;
                    loadDataPelunasan(refresh: true);
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
        ),
      ),
    );
  }

  void loadMore() {
    setState(() {
      isLoadMore = true;
      page = page + 1;
    });
    loadMoreData();
  }
}

class FilterPelunasan extends StatefulWidget {
  final data;
  FilterPelunasan({this.data});

  @override
  _FilterPelunasanState createState() => _FilterPelunasanState();
}

class _FilterPelunasanState extends State<FilterPelunasan> {
  DateTime today = DateTime.now();

  var keyword = TextEditingController();
  var tanggal = TextEditingController();
  var status = TextEditingController(text: 'belum_lunas');

  var statusR = 3, statusOpt = ['semua', 'due_date', 'lunas', 'belum_lunas', 'over_due'];

  initDate() {
    print(widget.data);
    if (widget.data != null) {
      var i = statusOpt.indexOf(widget.data['status']);
      statusR = i < 0 ? 3 : i;

      today = DateTime.parse(widget.data['date']);
      tanggal.text = widget.data['date'];
      status.text = widget.data['status'] == '' ? 'semua' : widget.data['status'];
      keyword.text = widget.data['keyword'];
    } else {
      tanggal.text = Dt.ymd;
    }
  }

  @override
  void initState() {
    super.initState();
    initDate();
  }

  @override
  Widget build(BuildContext context) {
    return Unfocus(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: Mquery.width(context),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(5)
            ),
            child: Column(children: <Widget>[
              Container(
                padding: EdgeInsets.only(left: 15, right: 15),
                decoration: BoxDecoration(
                    border: Border(
                        bottom: BorderSide(color: Colors.black12)
                    )
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    text('Filter', size: 19),
                    Row(
                      children: List.generate(1, (i) {
                        var icons = [Ic.check()];
                        return Container(
                          child: WidSplash(
                            splash: Colors.transparent,
                            highlightColor: Colors.transparent,
                            onTap: () {
                              switch (i) {
                                case 10:
                                  // setState(() {
                                  //   keyword.clear();
                                  //   tanggal.text = Dt.ymd;
                                  //   status.text = 'belum_lunas';
                                  // });
                                  break;

                                default:
                                  Navigator.pop(context, {'keyword': keyword.text, 'date': tanggal.text, 'status': status.text == 'semua' ? '' : status.text});
                                  break;
                              }
                            },
                            padding: EdgeInsets.only(left: 25, top: 15, bottom: 15),
                            child: Icon(icons[i], size: 20),
                          ),
                        );
                      }),
                    )
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.all(15),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Fc.select(
                          context,
                          label: 'Tanggal',
                          controller: tanggal,
                          suffix: Ic.calendar(),
                          unUsedOption: true, onSelect: () {
                            Wh.datePicker(context, init: today).then((res) {
                              focus(context, FocusNode());
                              if (res != null)
                                setState(() => tanggal.text = res);
                            });
                          },
                      ),
                      Fc.radio(
                          values: statusOpt,
                          label: 'Status',
                          marginBottom: 0,
                          controller: status,
                      ),
                    ],
                ),
              )
            ]),
          )
        ]),
      ),
    );
  }
}
