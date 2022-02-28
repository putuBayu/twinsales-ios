import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'helper.dart';

class InputNumber extends StatefulWidget {
  InputNumber({this.title, this.controller, this.hint, this.onChange, this.autofocus: false, this.startInputNumber: 1});
  final TextEditingController controller;
  final Function onChange;
  final title, hint, autofocus, startInputNumber;

  @override
  _InputNumberState createState() => _InputNumberState();
}

class _InputNumberState extends State<InputNumber> {
  var focus = false;

  void _onChange(s){
    var fi = s.substring(0, 1);
    if(s == '0' || fi == '0'){
      widget.controller.text = s.substring(1);
    }
  }

  @override
  void initState() {
    super.initState();
    // widget.controller.text = widget.startInputNumber.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.only(top: 17, bottom: 5),
          child: text(widget.title, bold: true),
        ),

        Container(
          margin: EdgeInsets.only(top: 0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: focus ? Colors.blue : Colors.black26),
                borderRadius: BorderRadius.circular(5),
                color: Colors.white
              ),
              child: Row(
                children: [

                  Expanded(
                    child: TextField(
                      controller: widget.controller,
                      autofocus: widget.autofocus,
                      keyboardType: TextInputType.datetime,
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.only(left: 15, right: 15),
                        hintText: widget.hint, isDense: true,
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: Colors.black54, fontFamily: 'sans'),
                      ),
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(11),
                      ],
                      style: TextStyle(color: Colors.black87, fontSize: 16),
                      onChanged: _onChange,
                    ),
                  ),

                  Btn(
                    onTap: (){
                      var ctrl = widget.controller.text;
                      if(ctrl == ''){ ctrl = '0'; }
                      else if(int.parse(ctrl) > 0){
                        widget.controller.text = (int.parse(ctrl) - 1).toString();
                      }
                    },
                    child: Icon(Icons.remove),
                    padding: EdgeInsets.only(top: 7, bottom: 7, left: 10, right: 10),
                  ),

                  Btn(
                    onTap: (){
                      var ctrl = widget.controller.text;
                      if(ctrl.length < 12){
                        if(ctrl == ''){ ctrl = '0'; }
                        widget.controller.text = (int.parse(ctrl) + 1).toString();
                      }
                    },
                    child: Icon(Icons.add),
                    padding: EdgeInsets.only(top: 7, bottom: 7, left: 10, right: 10),
                  )

                ]
              ),
            ),
          ),
        )
      
      ]
    );
  }
}

class InputDate extends StatefulWidget {
  final TextEditingController controller;
  final title, hint;
  final DateTime min, max;

  InputDate({this.title, this.controller, this.hint, this.min, this.max});

  @override
  _InputDateState createState() => _InputDateState();
}

class _InputDateState extends State<InputDate> {
  DateTime selectedDate = DateTime.now();

  Future<Null> _selectDate(BuildContext context) async {
    final DateTime picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: widget.min == null ? DateTime(2015, 0) : widget.min,
      lastDate: widget.max == null ? DateTime(2030) : widget.max
    );

    if (picked != null)
      setState(() {
        var d = picked.toString().split(' ');
        widget.controller.text = d[0];
        selectedDate = DateTime.parse(d[0]);
      });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.only(top: 17, bottom: 5),
          child: text(widget.title, bold: true),
        ),

        Container(
          margin: EdgeInsets.only(top: 0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black26),
                borderRadius: BorderRadius.circular(5),
                color: Colors.white
              ),
              child: Row(
                children: [

                  Expanded(
                    child: Container(
                      padding: EdgeInsets.only(left: 15, right: 15),
                      width: mquery(context),
                      child: widget.controller.text.isEmpty ? text(widget.hint, color: Colors.black38) : text(widget.controller.text),
                    )
                  ),

                  Btn(
                    onTap: (){ _selectDate(context); },
                    child: Icon(Icons.date_range, color: Colors.blue),
                    padding: EdgeInsets.only(top: 7, bottom: 7, left: 10, right: 10),
                  )

                ]
              ),
            ),
          ),
        )
      
      ]
    );
  }
}