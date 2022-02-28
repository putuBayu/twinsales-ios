import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_icons/flutter_icons.dart';

import 'helper.dart';

// static option() -> helper.dart
class ListOption extends StatefulWidget {
  final List<String> options;

  ListOption({this.options});

  @override
  _ListOptionState createState() => _ListOptionState();
}

class _ListOptionState extends State<ListOption> {
  @override
  Widget build(BuildContext context) {
    return widget.options == null || widget.options.length == 0 ? SizedBox.shrink() : SlideUp(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [

          Container(
            margin: EdgeInsets.all(10),
            child: Material(
              color: Colors.transparent,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white
                  ),
                  width: Mquery.width(context),
                  child: Column(
                    children: List.generate(widget.options.length, (int i){
                      return Button(
                        onTap: (){
                          Navigator.pop(context, {'index': i, 'value': widget.options[i]});
                        },
                        child: Container(
                          width: Mquery.width(context),
                          padding: EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            border: i == 0 ? Border() : Border(
                              top: BorderSide(color: Colors.black12)
                            )
                          ),
                          child: Text(ucwords(widget.options[i]), textAlign: TextAlign.center)
                        ),
                      );
                    })
                  )
                ),
              ),
            ),
          ),

          Container(
            width: Mquery.width(context),
            margin: EdgeInsets.only(left: 10, right: 10, bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(5)
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: Button(
                padding: EdgeInsets.all(15),
                onTap: (){ Navigator.pop(context); },
                child: Material(
                  color: Colors.transparent,
                  child: Text('Batal', textAlign: TextAlign.center)
                ),
              ),
            )
            
            
          ),

        ]
      ),
    );
  }
}

// static confirm() -> helper.dart
class WidgetConfirmation extends StatefulWidget {
  final message, textButton;
  WidgetConfirmation({this.message, this.textButton});

  @override
  _WidgetConfirmationState createState() => _WidgetConfirmationState();
}

class _WidgetConfirmationState extends State<WidgetConfirmation> {

  @override
  Widget build(BuildContext context) {
    return SlideUp(
      child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            Container(
              margin: EdgeInsets.all(15),
              child: Material(
                color: Colors.transparent,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white
                    ),
                    width: Mquery.width(context),
                    child: Column(
                      children: [

                        Container(
                          margin: EdgeInsets.all(15),
                          child: html(widget.message == null ? '' : widget.message),
                        ),

                        Row(
                          children: List.generate(2, (int i){
                            var labels = widget.textButton == null ? ['batal', 'iya'] : widget.textButton;

                            return Button(
                              onTap: (){
                                Navigator.pop(context, i);
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border(
                                    top: BorderSide(color: Colors.black12),
                                    right: BorderSide(color: i == 0 ? Colors.black12 : Colors.transparent))
                                ),
                                width: Mquery.width(context) / 2 - 15,
                                padding: EdgeInsets.all(15),
                                child: Text(ucwords(labels[i]), textAlign: TextAlign.center)
                              ),
                            );
                          })
                        )

                      ]
                    )
                    
                  ),
                ),
              ),
            ),

          ]
      ),
    );
  }
}

// static confirm() -> helper.dart
class FormNumber extends StatefulWidget {
  final String label, init;
  final TextEditingController controller;
  final FocusNode node;
  final TextInputAction inputAction;
  final Function onSubmit, onChange;

  FormNumber({this.label, this.init, this.controller, this.node, this.inputAction, this.onSubmit, this.onChange});

  @override
  _FormNumberState createState() => _FormNumberState();
}

class _FormNumberState extends State<FormNumber> {

  void _count(i){
    var ctrl = widget.controller.text == '' ? 0 : int.parse(widget.controller.text);

    switch (i) {
      case 0: // decrease
        if(ctrl > 0){
          widget.controller.text = (ctrl - 1).toString();
        } break;
      default: // increase
        if(ctrl < 99999999999){
          widget.controller.text = (ctrl + 1).toString();
        } break;
    }
  }

  void _onChange(s){

    if(s == ''){
      // widget.controller.text = '0';
    }

    var str = s.substring(0, 1);
    if(s == '0' || str == '0'){
      // widget.controller.text = s.substring(1);
      // widget.controller.value = widget.controller.value.copyWith(text: '9');
    }

    // FocusScope.of(context).requestFocus(widget.node);
  }

  @override
  void initState() {
    super.initState();

    if(widget.node != null){
      widget.node.addListener((){
        var isFocus = widget.node.hasFocus;
        if(!isFocus){
          if(widget.controller.text.isEmpty){
            widget.controller.text = '0';
          }
        }
      });
    }

    widget.controller.text = widget.controller.text == '' ? '0' : widget.controller.text;
  }

  @override
  Widget build(BuildContext context) {
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        widget.label == null ? SizedBox.shrink() : 
        Container(
          margin: EdgeInsets.only(bottom: 7),
          child: text(widget.label, bold: true)
        ),

        Container(
          margin: EdgeInsets.only(bottom: 25),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black26),
                    borderRadius: BorderRadius.circular(4),
                    color: Colors.white
                  ),
                  child: TextField(
                    controller: widget.controller,
                    focusNode: widget.node,
                    // maxLines: lines,
                    keyboardType: TextInputType.datetime,
                    textInputAction: widget.inputAction,
                    onSubmitted: widget.onSubmit, onTap: (){
                      if(widget.controller.text == '0'){
                        widget.controller.clear();
                      }
                    },
                    onChanged: _onChange, onEditingComplete: (){
                      if(widget.controller.text.isEmpty){
                        widget.controller.text = '0';
                      }
                    },
                    decoration: new InputDecoration(
                      
                      alignLabelWithHint: true,
                      border: InputBorder.none,
                      isDense: true,
                      hintStyle: TextStyle(fontFamily: 'sans'),
                      contentPadding: EdgeInsets.only(left: 15, right: 15, top: 10, bottom: 10)
                    ),
                    style: TextStyle(fontFamily: 'sans'),
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(11),
                    ],
                  ),
                ),

                Positioned(
                  right: 0,
                  child: Row(
                    children: List.generate(2, (int i){
                      var icons = [Icons.remove, Icons.add];
                      return Button(
                        onTap: (){ _count(i); },
                        padding: EdgeInsets.only(top: 7, bottom: 8, left: 10, right: 10),
                        child: Icon(icons[i]),
                      );
                    })
                  ),
                )
              ]
            ),
          ),
        )

        
      ],
    );
  }
}

// static toggle -> helper.dart
class FormToggle extends StatefulWidget {
  final Function onChange;
  final config;

  FormToggle({this.onChange, this.config});

  @override
  _FormToggleState createState() => _FormToggleState();
}

class _FormToggleState extends State<FormToggle> {

  @override
  Widget build(BuildContext context) {
    return Button(
      highlightColor: Colors.transparent,
      splash: Colors.transparent,
      radius: BorderRadius.circular(50),
      padding: EdgeInsets.all(5),
      onTap: !widget.config['enabled'] ? null : (){
        setState(() => widget.config['value'] = !widget.config['value'] );
        widget.onChange(widget.config['value']);
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Stack(
            children: <Widget>[
              AnimatedContainer(
                duration: Duration(milliseconds: 100),
                margin: EdgeInsets.only(bottom: 5, top: 5),
                width: 37, height: 14,
                decoration: BoxDecoration(
                  color: widget.config['value'] ? Colors.blue[200] : Colors.black12,
                  borderRadius: BorderRadius.circular(50)
                ),
              ),

              AnimatedPositioned(
                top: 1, left: widget.config['value'] ? 15 : 0,
                duration: Duration(milliseconds: 100),
                child: Container(
                  height: 22, width: 22,
                  decoration: BoxDecoration(
                    color: widget.config['value'] ? Colors.blue : Colors.grey[400],
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                        color: widget.config['value'] ? Colors.blue[100] : Colors.black38,
                        blurRadius: 1.0, // has the effect of softening the shadow
                        spreadRadius: .5, // has the effect of extending the shadow
                        offset: Offset(1, .5),
                      )
                    ],
                  ),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }
}

// static radio -> helper.dart
class WidgetRadio extends StatefulWidget {
  final String label;
  final Function onChange;
  final double mb, mt;
  final params;

  WidgetRadio({this.label, this.params, this.onChange, this.mb, this.mt});

  @override
  _WidgetRadioState createState() => _WidgetRadioState();
}

class _WidgetRadioState extends State<WidgetRadio> {

  void _onChecked(i){ 
    setState(() {
      widget.params['checked'] = widget.params['values'][i];
    });

    if(widget.onChange != null){
      widget.onChange(widget.params['checked']);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: widget.mb, top: widget.mt),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          widget.label == null ? SizedBox.shrink() : 
          Container(
            margin: EdgeInsets.only(bottom: 7),
            child: text(widget.label, bold: true),
          ),

          Wrap(
            children: List.generate(widget.params['values'].length, (int i){
              var checked = widget.params['values'][i].toLowerCase() == widget.params['checked'].toLowerCase();

              return Container(
                margin: EdgeInsets.only(right: 15, bottom: 10),
                child: GestureDetector(
                  onTap: (){ _onChecked(i); },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        margin: EdgeInsets.only(right: 10),
                        height: 20, width: 20,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(50),
                          border: checked ? Border() : Border.all(color: Colors.black38),
                          color: checked ? Colors.blue : Colors.white,
                        ),
                        child: checked ? Icon(Icons.fiber_manual_record, color: Colors.white, size: 20) : SizedBox.shrink(),
                      ), text(ucwords(widget.params['values'][i].toString().replaceAll('_', ' ')))
                    ]
                  ),
                )
                
              );
            })
          )
        ],
      ),
    );
  }
}

// static checkbox -> helper.dart
class WidgetCheckbox extends StatefulWidget {
  final String label;
  final List values, checked;
  final Function onChange;
  final double marginY;
  final bool enabled;

  WidgetCheckbox({this.label, @required this.values, @required this.checked, this.enabled: true, this.onChange, this.marginY});

  @override
  _WidgetCheckboxState createState() => _WidgetCheckboxState();
}

class _WidgetCheckboxState extends State<WidgetCheckbox> {

  void _onChecked(i){
    var v = widget.values[i];

    setState(() {
      if(widget.checked.indexOf(v) > -1){
        widget.checked.remove(v);
      }else{
        widget.checked.add(v);
      }
    });

    widget.onChange(widget.checked);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: widget.marginY == null ? 25 : widget.marginY),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          widget.label == null ? SizedBox.shrink() : 
          Container(
            margin: EdgeInsets.only(bottom: 7),
            child: text(widget.label, bold: true),
          ),

          Wrap(
            children: List.generate(widget.values.length, (int i){
              var checkeds = widget.checked.indexOf(widget.values[i]);
              return Container(
                margin: EdgeInsets.only(right: 10, bottom: 10),
                child: GestureDetector(
                  onTap: !widget.enabled ? null : (){ _onChecked(i); },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        margin: EdgeInsets.only(right: 10),
                        height: 20, width: 20,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          border: checkeds > -1 ? Border() : Border.all(color: Colors.black38),
                          color: checkeds > -1 ? Colors.blue : Colors.white,
                        ),
                        child: checkeds > -1 ? Icon(Icons.check, color: Colors.white, size: 20) : SizedBox.shrink(),
                      ), text(widget.values[i])
                    ]
                  ),
                )
                
              );
            }),
          )
        ],
      ),
    );
  }
}

// static optionBox -> helper.dart
class OptionBox extends StatefulWidget {
  final String label;
  final Function onChange;
  final config;

  OptionBox({this.label, @required this.config, this.onChange});

  @override
  _OptionBoxState createState() => _OptionBoxState();
}

class _OptionBoxState extends State<OptionBox> {

  void _onChecked(i){ 
    setState(() {
      widget.config['checked'] = widget.config['values'][i];
    });

    if(widget.onChange != null){
      widget.onChange(widget.config['checked']);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          widget.label == null ? SizedBox.shrink() : 
          Container(
            margin: EdgeInsets.only(bottom: 7),
            child: text(widget.label, bold: true),
          ),

          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black12),
              borderRadius: BorderRadius.circular(4)
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: Row(
                children: List.generate(widget.config['values'].length, (int i){
                  return Container(
                    width: (Mquery.width(context) - 32) / widget.config['values'].length,
                    decoration: BoxDecoration(
                      border: i == 0 ? Border() : Border(
                        left: BorderSide(color: Colors.black12)
                      )
                    ),
                    child: Button(
                      onTap: (){ _onChecked(i); },
                      padding: EdgeInsets.all(11),
                      color: widget.config['values'][i] == widget.config['checked'] ? Cl.black05() : Colors.white,
                      child: Container(
                        child: text(widget.config['values'][i], align: TextAlign.center, bold: widget.config['values'][i] == widget.config['checked']),
                      ),
                    ),
                  );
                })
              )
            ),
          )

        ],
      ),
    );
  }
}

class WidgetDropdown extends StatefulWidget {
  final String label;
  final List options, values;
  final TextEditingController controller;

  WidgetDropdown({this.label, @required this.options, this.values, @required this.controller});

  @override
  _WidgetDropdownState createState() => _WidgetDropdownState();
}

class _WidgetDropdownState extends State<WidgetDropdown> {
  GlobalKey _key = GlobalKey();
  ScrollController _scrollController = ScrollController();

  _scrollToTop() {
    Timer(Duration(milliseconds: 200), (){ 
      _scrollController.animateTo(_scrollController.position.maxScrollExtent,
      duration: Duration(milliseconds: 100), curve: Curves.easeIn);
    });
  }

  void _showOptions(){
    final RenderBox renderBox = _key.currentContext.findRenderObject();
    final position = renderBox.localToGlobal(Offset.zero),
          size = renderBox.size;

    showDialog(
      context: context,
      builder: (BuildContext context){
        return GestureDetector(
          onTap: (){ Navigator.pop(context); },
          child: ScrollConfiguration(
            behavior: ScrollConfig(),
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                children: [

                  Container(
                    margin: EdgeInsets.only(top: position.dy - 24),
                    child: Center(
                      child: Material(
                        color: Colors.transparent,
                        child: Container(
                          width: size.width,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            // border: Border.all(color: Colors.black26),
                            borderRadius: BorderRadius.circular(4)
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: List.generate(widget.options.length, (int i){
                                return Button(
                                  onTap: (){
                                    Navigator.pop(context, widget.options[i]);
                                  },
                                  color: widget.options[i] != widget.controller.text ? Colors.white : Cl.black05(),
                                  child: Container(
                                    width: Mquery.width(context),
                                    padding: EdgeInsets.only(left: 15, right: 15, top: 10, bottom: 10),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        text(widget.options[i]),
                                        
                                        widget.options[i] != widget.controller.text ? SizedBox.shrink() :
                                        Icon(Icons.check, color: Colors.green, size: 20,)
                                      ]
                                    )
                                  ),
                                );
                              })
                            ),
                          ),
                        ),
                      ),
                    ),
                  )

                ]
              ),
            ),
          ),
        );
      }
    ).then((res){
      if(res != null){
        setState(() => widget.controller.text = res );
      }
    });

    _scrollToTop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          widget.label == null ? SizedBox.shrink() : 
          Container(
            margin: EdgeInsets.only(bottom: 7),
            child: text(widget.label, bold: true),
          ),

          Stack(
            children: [
              Button(
                onTap: (){
                  _showOptions();
                },
                color: Colors.white,
                child: Container(
                  key: _key,
                  padding: EdgeInsets.only(left: 15, right: 15, top: 10, bottom: 10),
                  width: Mquery.width(context),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black26),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: text(widget.controller.text),
                ),
              ),

              Positioned(
                right: 10, top: 7,
                child: IgnorePointer(child: Icon(Icons.expand_more)),
              ),
            ]
          )
        ]
      ),
    );
  }
}

class Dropdown extends StatefulWidget {
  final String label, hint, values, resDataLabel, resDataValue;
  final double space;
  final List item;
  final List options;
  final Function onChanged;
  Dropdown({this.label, this.hint, this.space: 0, this.values, this.options, this.onChanged, this.resDataLabel, this.resDataValue, this.item});

  @override
  _DropdownState createState() => _DropdownState();
}

class _DropdownState extends State<Dropdown> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          child: text(widget.label, bold: true),
          margin: EdgeInsets.only(bottom: 7),
        ),
        Container(
          margin: EdgeInsets.only(bottom: widget.space),
          padding: EdgeInsets.only(left: 15, right: 15, top: 10, bottom: 10),
          height: 40,
          decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black12),
              borderRadius: BorderRadius.circular(5)
          ),
          child: DropdownButton(
              icon: Icon(Feather.chevron_down, size: 17,),
              hint: text(widget.hint, color: Colors.black45),
              isExpanded: true,
              value: widget.values,
              underline: SizedBox.shrink(),
              items: widget.item != null ? widget.item : widget.options.map((value){
                return DropdownMenuItem<String>(
                  value: value,
                  child: text(ucwords(value), color: Colors.black87),
                );
              }).toList(),
              onChanged: widget.onChanged
          ),
        ),
      ],
    );
  }
}

class ListExpanded extends StatefulWidget {
  final config;
  final Widget title;
  final List list;
  final Function onExpand, onListTap;

  ListExpanded({this.title, this.list, this.config: false, this.onExpand, this.onListTap});

  @override
  _ListExpandedState createState() => _ListExpandedState();
}

class _ListExpandedState extends State<ListExpanded> {
  
  @override
  Widget build(BuildContext context) {
    var _h = (47.3 * (widget.list.length)).toDouble();

    return Container(
      child: Column(
          children: <Widget>[
            Button(
              onTap: (){
                setState(() => widget.config['expand'] = !widget.config['expand'] );
                if(widget.onExpand != null) widget.onExpand(widget.config['expand']);
              },
              child: Container(
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  // border: Border(bottom: BorderSide(color: Colors.black12))
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    widget.title,
                    RotationTransition(
                      turns: new AlwaysStoppedAnimation(widget.config['expand'] ? .25 : 0),
                      child: Icon(Icons.chevron_right, size: 18, color: Colors.black45)
                    )
                  ],
                ),
              ),
            ),

            AnimatedContainer(
              height: widget.config['expand'] ? _h : 0,
              duration: Duration(milliseconds: 200),
              color: Cl.softSilver(),
              child: PreventScrollGlow(
                child: SingleChildScrollView(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: Colors.black12))
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: List.generate(widget.list.length, (int i){
                        return Button(
                          onTap: (){ if(widget.onListTap != null) widget.onListTap(i); },
                          child: Container(
                            padding: EdgeInsets.only(left: 15, right: 15, top: 15, bottom: 15),
                            width: Mquery.width(context),
                            child: text(widget.list[i]),
                          )
                        );
                      }),
                    ),
                  ),
                ),
              )
            ),

          ],
        ),
    );





  // var _h = (47.5 * (widget.list.length + 1)).toDouble();

    // return Container(
    //   child: Stack(
    //     children: <Widget>[
    //       AnimatedContainer(
    //         duration: Duration(milliseconds: 300),
    //         height: widget.expand ? _h : 0),

    //       AnimatedPositioned(
    //         top: widget.expand ? 49 : -_h,
    //         duration: Duration(milliseconds: 300),
    //         child: Container(
    //           decoration: BoxDecoration(
    //             color: Cl.black05(),
    //             border: Border(
    //               top: BorderSide(color: Colors.black12),
    //             )
    //           ),
    //           child: Column(
    //             crossAxisAlignment: CrossAxisAlignment.start,
    //             children: List.generate(widget.list.length, (int i){
    //               return Button(
    //                 onTap: (){ if(widget.onListTap != null) widget.onListTap(i); },
    //                 child: Container(
    //                   padding: EdgeInsets.only(left: 15, right: 15, top: 15, bottom: 15),
    //                   width: Mquery.width(context),
    //                   child: text(widget.list[i]),
    //                 )
    //               );
    //             }),
    //           ),
    //         ),
    //       ),

    //       Container(
    //         child: Button(
    //           onTap: (){ 
    //             setState(() => widget.expand = !widget.expand );
    //             if(widget.onExpand != null) widget.onExpand(widget.expand);
    //           },
    //           color: Colors.white,
    //           child: Container(
    //             // decoration: BoxDecoration(
    //             //   border: Border(
    //             //     bottom: BorderSide(color: Colors.black12),
    //             //     // top: BorderSide(color: !widget.expand ? Colors.black12 : Colors.transparent),
    //             //   )
    //             // ),
    //             width: double.infinity,
    //             padding: EdgeInsets.all(15),
    //             child: Row(
    //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
    //               children: <Widget>[
    //                 widget.title,

    //                 RotationTransition(
    //                   turns: new AlwaysStoppedAnimation(widget.expand ? .25 : 0),
    //                   child: Icon(Icons.chevron_right, size: 19, color: Colors.black45)
    //                 )
                    
    //               ],
    //             )
    //           ),
    //         ),
    //       ),
          
    //     ],
    //   ),
    // );
  
  }
}