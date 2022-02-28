import 'package:flutter/material.dart';
import 'package:sales/services/api/api.dart';
import 'package:sales/services/v2/helper.dart';

class Password extends StatefulWidget {
  @override
  _PasswordState createState() => _PasswordState();
}

class _PasswordState extends State<Password> {

  var password = new TextEditingController(),
      confPassword = new TextEditingController();

  var passNode = new FocusNode();
  var confPassNode = new FocusNode();

  bool isSubmit = false, obsecure = true;

  submit() async{
    if( password.text.length < 6 ){
      Wh.toast('Password minimal 6 karakter'); focus(context, passNode);
    }else{
      if( password.text != confPassword.text || confPassword.text != password.text ){
        Wh.toast('Konfirmasi password tidak sesuai'); focus(context, confPassNode);
      }else{
        setState(() { isSubmit = true; });
        getPrefs('user', dec: true).then((res){
          Request.put('user/change_password/'+res['id'].toString(), formData: {'password': password.text, 'password_confirmation': confPassword.text}, then: (s, body){
            Wh.toast('Berhasil diperbarui');
            Navigator.pop(context);
          }, error: (err){
            setState(() { isSubmit = false; });
            onError(context, response: err, popup: true);
          });
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Unfocus(
      child: Scaffold(
        backgroundColor: TColor.silver(),
        appBar: Wh.appBar(context, title: 'Ganti Password', center: true, actions: [
          IconButton(
            icon: Icon(obsecure ? Ic.eye() : Ic.eyeoff(), size: 20),
            onPressed: (){
              setState(() {
                obsecure = !obsecure;
              });
            },
          )
        ]),

        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(15),
                child: Column(
                  children: [
                    TextInput(
                        label: 'Password',
                        hint: 'Inputkan password',
                        controller: password,
                        obsecure: obsecure,
                        length: 30,
                        action: TextInputAction.next,
                        submit: (String s){
                          focus(context, confPassNode);
                        }
                    ),
                    TextInput(
                        label: 'Konfirmasi Password',
                        hint: 'Konfirmasi password',
                        controller: confPassword,
                        obsecure: obsecure,
                        length: 30,
                        node: confPassNode
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
          ]
        ),
      ),
    );
  }
}