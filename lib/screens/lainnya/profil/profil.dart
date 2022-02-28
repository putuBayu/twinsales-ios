import 'package:flutter/material.dart';
import 'package:sales/services/v2/helper.dart';

class Profil extends StatefulWidget {
  Profil({this.user}); final user;

  @override
  _ProfilState createState() => _ProfilState();
}

class _ProfilState extends State<Profil> {
  var role;

  getRole(){
    getPrefs('roles', type: List).then((roles) {
      setState(() {
        role = roles.join(',');
      });
    });
  }

  @override
  void initState() {
    getRole();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var bcolor = Color.fromRGBO(0, 0, 0, .08);

    return Scaffold(
      backgroundColor: TColor.silver(),
      appBar: Wh.appBar(context, title: 'Profil Saya', center: true, actions: [
        // IconButton(
        //   onPressed: (){},
        //   icon: Icon(Ic.edit(), size: 20),
        // )
      ]),

      body: SingleChildScrollView(
        padding: EdgeInsets.all(15),
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[

              Container(
                margin: EdgeInsets.only(top: 25, bottom: 25),
                width: 111, height: 111,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: Colors.white, width: 5),
                  image: DecorationImage(
                    image: AssetImage('assets/img/profile.png')
                  )
                ),
              ),

              text(widget.user['name'], size: 20, bold: true),
              text(ucword(widget.user['phone'] == null ? '-' : widget.user['phone']), size: 17),

              Container(
                margin: EdgeInsets.only(top: 25),
                child: Row(
                  children: List.generate(1, (i){
                    var icons = [Ic.user()],
                        labels = ['Biodata'];

                    return WidSplash(
                      onTap: (){},
                      color: Colors.white,
                      child: Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(color: bcolor),
                            right: BorderSide(color: bcolor),
                            top: BorderSide(color: bcolor),
                          )
                        ),
                        child: Row(
                          children: <Widget>[
                            Container(
                              margin: EdgeInsets.only(right: 7),
                              child: Icon(icons[i], size: 15),
                            ),
                            text(labels[i]),
                          ],
                        )
                      ),
                    );
                  }),
                ),
              ),

              Container(
                width: Mquery.width(context),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    left: BorderSide(color: bcolor),
                    right: BorderSide(color: bcolor)
                  )
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(4, (i){
                    var labels = ['nama lengkap','email','role','status'],
                        values = [widget.user['name'],widget.user['email'],ucword(role),ucword(widget.user['status'])];

                    return Container(
                      width: Mquery.width(context),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: bcolor)),
                      ),
                      child: WidSplash(
                        padding: EdgeInsets.all(11),
                        onTap: (){},
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            text(ucword(labels[i]), bold: true), text(values[i])
                          ],
                        )
                      ),
                    );
                  })
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}