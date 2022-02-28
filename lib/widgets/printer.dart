import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/services.dart';
import 'package:sales/services/v2/helper.dart';
import 'package:sales/services/v3/helper.dart';

class Printer extends StatefulWidget {
  Printer({@required this.print});

  final Function print;

  @override
  _PrinterState createState() => _PrinterState();
}

class _PrinterState extends State<Printer> {

  var printer = TextEditingController();

  BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;
  bool loading = true, isConnected = false, isDeviceConnected = true, isPrint = false, hasPrinted = false;

  List _devices = [];
  List<BluetoothDevice> bDevices = [];

  // cari printer thermal
  findThermalPrinter() async{
    String deviceName = await LocalData.get('printer');
    printer.text = deviceName ?? '';

    setState(() {
      isConnected = false;
      loading = true;
    });

    await bluetooth.isOn.then((res) async{
      setState(() {
        isConnected = res;
      });

      if(res){
        List temp = []; bDevices = [];

        try {
          List<BluetoothDevice> devices = await bluetooth.getBondedDevices();
          bDevices = devices;

          int i = 0;
          
          devices.forEach((device){ i++;
            temp.add(device.name);
            // if(device.name == 'BlueTooth Printer'){
            //   printer.text = device.name;
            // }

            if(devices.length == i){
              setState(() {
                loading = false;
                _devices = temp;

                listDevices = ListDevices(_devices, selected: printer.text, isPrint: isPrint, onSelect: (res){
                  if(res != null){
                    bDevices.forEach((device){
                      if(device.name == res){
                        bluetooth.isConnected.then((con) {
                          if (!con) {
                            // jika bluetooth tidak terhubung, hubungkan kemudian cetak
                            setState(() => isPrint = true );
                            
                            try {
                              bluetooth.connect(device).then((_){
                                hasPrinted = true; // print success

                                setPrefs('printer', res);

                                Navigator.pop(context);
                                if(widget.print != null) widget.print(true);
                                // Print(context: context, data: widget.data, items: widget.items).run();
                              }, onError: (onErr){
                                // Navigator.pop(context, {'error': true});
                              });
                            }on PlatformException catch (_) {
                              // Navigator.pop(context, {'error': true});
                            }
                          }else{ // jika sudah terhubung, langsung cetak
                            hasPrinted = true; // print success
                            setPrefs('printer', res);
                            Navigator.pop(context);
                            if(widget.print != null) widget.print(true);

                            // jalankan printer
                            // Print(context: context, data: widget.data, items: widget.items).run();
                          }
                        });
                      }
                    });
                  }
                });
              });
            }
          });
        } catch (e) {
          Wh.alert(context, title: 'Bluetooth Error', message: 'Terjadi kesalahan saat menghubungkan ke perangkat Bluetooth Thermal.');
        }
      }

    });
  }

  Widget listDevices = SizedBox.shrink();

  @override
  void initState() {
    findThermalPrinter();

    super.initState(); 

    bluetooth.onStateChanged().listen((state) {
      if(mounted){
        if(state == 11 || state == 12 || state == 1){
          setState(() {
            isConnected = true;
          });

          findThermalPrinter();
        }else{
          setState(() {
            isConnected = false;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return listDevices;
  }
}

class ListDevices extends StatefulWidget {
  ListDevices(this.options, {this.selected, this.onSelect, this.isPrint: false});

  final options, selected;
  final Function onSelect;
  final bool isPrint;


  @override
  _ListDevicesState createState() => _ListDevicesState();
}

class _ListDevicesState extends State<ListDevices> {

  String selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250,
      child: Column(
        children: [
          Container(
            width: 150, margin: EdgeInsets.only(bottom: 7),
            height: 5,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Color.fromRGBO(229, 232, 236, 1),
            ),
          ),
              
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(5),
                topRight: Radius.circular(5)
              ),
              child: CupertinoPicker(
                scrollController: FixedExtentScrollController(
                  initialItem: widget.options.indexOf(widget.selected)
                ),
                itemExtent: 40.0,
                backgroundColor: Colors.white,
                onSelectedItemChanged: (int i){
                  selected = widget.options[i];
                },
                children: new List<Widget>.generate(widget.options.length, (int i) {
                  return Container(
                    margin: EdgeInsets.all(3),
                    width: Mquery.width(context) - 100,
                    // padding: EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: TColor.silver(),
                      borderRadius: BorderRadius.circular(25)
                    ),
                    child: Center(
                      child: text(ucword(widget.options[i].toString()))
                    ) 
                  );
                }),
              ),
            )
          ),

          Container(
            color: Colors.white,
            padding: EdgeInsets.all(15),
            child: Button(
              onTap: (){
                if(widget.onSelect != null) widget.onSelect(selected ?? widget.selected); // selected ?? widget.selected -> selected == null ? widget.selected : selected,


                // if(widget.onSelect != null){
                //   widget.onSelect(selected ?? widget.selected);
                // }
              },
              text: 'Cetak', isSubmit: widget.isPrint,
            ),
          )
        ]
      )
    );
  }
}