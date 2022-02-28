import 'dart:io';

import 'package:flutter/material.dart';
import 'package:connectivity/connectivity.dart';
import 'package:flutter/services.dart';
import 'package:sales/services/v2/helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_icons/flutter_icons.dart';

var defaultApi = 'https://kpm-api.kembarputra.com';

_connection({Function then}) async {
  var connectivityResult = await (Connectivity().checkConnectivity()),
      mobile = connectivityResult == ConnectivityResult.mobile,
      wifi = connectivityResult == ConnectivityResult.wifi;

  then(mobile || wifi ? true : false);
}

class Request {
  static get(url,
      {debug: false,
      authorization: true,
      Function then,
      Function error}) async {
    var prefs = await SharedPreferences.getInstance();

    // get api from local data
    api(url) {
      var apiUrl = prefs.getString('api');
      return apiUrl == null ? defaultApi + '/' + url : apiUrl + '/' + url;
    }

    _connection(then: (con) {
      if (con) {
        if (debug) {
          print('# url : ' + api(url));
        }

        try {
          http
              .get(api(url),
                  headers: !authorization
                      ? {}
                      : {
                          HttpHeaders.authorizationHeader:
                              prefs.getString('token'),
                          'Accept': 'application/json'
                        })
              .then((res) {
            if (debug) {
              print('# token: ' + prefs.getString('token').toString());
              print('# request : ' + res.request.toString());
              print('# status : ' + res.statusCode.toString());
              print('# body : ' + res.body.toString());
            }

            if (res.statusCode != 200) {
              var response = {
                'status': res.statusCode,
                'body': res.statusCode == 500 || res.statusCode == 401
                    ? {}
                    : decode(res.body)
              };
              error(response);
            } else {
              if (then != null) then(res.statusCode, res.body);
            }
          });
        } catch (e) {
          if (e is PlatformException) {
            if (error != null) error(e.message);
          }
        }
      } else {
        Wh.toast('Periksa koneksi internet Anda!');
      }
    });
  }

  // await post('user', formData: {}, debug: true, then: (res){ }, error: (err){ })
  static post(url,
      {formData,
      debug: false,
      authorization: true,
      Function then,
      Function error}) async {
    var prefs = await SharedPreferences.getInstance();

    // get api from local data
    api(url) {
      var apiUrl = prefs.getString('api');
      return apiUrl == null ? defaultApi + '/' + url : apiUrl + '/' + url;
    }

    checkConnection().then((con) {
      if (con) {
        if (debug) {
          print('# url : ' + api(url));
        }

        try {
          http
              .post(api(url),
                  body: formData == null ? {} : formData,
                  headers: !authorization
                      ? {}
                      : {
                          HttpHeaders.authorizationHeader:
                              prefs.getString('token'),
                          'Accept': 'application/json'
                        })
              .then((res) {
            if (debug) {
              print('# request : ' + res.request.toString());
              print('# status : ' + res.statusCode.toString());
              print('# body : ' + res.body.toString());
            }

            if (res.statusCode != 200 && res.statusCode != 201) {
              var response = {
                'status': res.statusCode,
                'body': decode(res.body)
              };
              error(response);
            } else {
              if (then != null) then(res.statusCode, res.body);
            }
          });
        } catch (e) {
          if (e is PlatformException) {
            if (then != null) then(e);
          }
        }
      } else {
        Wh.toast('Periksa koneksi internet Anda!');
      }
    });
  }

  // await put('user', formData: {}, debug: true, then: (res){ }, error: (err){ })
  static put(url,
      {formData,
      debug: false,
      authorization: true,
      Function then,
      Function error}) async {
    var prefs = await SharedPreferences.getInstance();

    // get api from local data
    api(url) {
      var apiUrl = prefs.getString('api');
      return apiUrl == null ? defaultApi + '/' + url : apiUrl + '/' + url;
    }

    checkConnection().then((con) {
      if (con) {
        if (debug) {
          print('# url : ' + api(url));
        }

        try {
          http
              .put(api(url),
                  body: formData,
                  headers: !authorization
                      ? {}
                      : {
                          HttpHeaders.authorizationHeader:
                              prefs.getString('token'),
                          'Accept': 'application/json'
                        })
              .then((res) {
            if (debug) {
              print('# request : ' + res.request.toString());
              print('# status : ' + res.statusCode.toString());
              print('# body : ' + res.body.toString());
            }

            if (res.statusCode != 200 && res.statusCode != 201) {
              var response = {
                'status': res.statusCode,
                'body': decode(res.body)
              };
              error(response);
            } else {
              if (then != null) then(res.statusCode, res.body);
            }
          });
        } catch (e) {
          if (e is PlatformException) {
            if (then != null) then(e);
          }
        }
      } else {
        Wh.toast('Periksa koneksi internet Anda!');
      }
    });
  }

  // await delete('user/1', debug: true, then: (res){ }, error: (err){ })
  static delete(url,
      {debug: false,
      authorization: true,
      Function then,
      Function error}) async {
    var prefs = await SharedPreferences.getInstance();

    // get api from local data
    api(url) {
      var apiUrl = prefs.getString('api');
      return apiUrl == null ? defaultApi + '/' + url : apiUrl + '/' + url;
    }

    checkConnection().then((con) {
      if (con) {
        if (debug) {
          print('# url : ' + api(url));
        }

        try {
          http
              .delete(api(url),
                  headers: !authorization
                      ? {}
                      : {
                          HttpHeaders.authorizationHeader:
                              prefs.getString('token'),
                          'Accept': 'application/json'
                        })
              .then((res) {
            if (debug) {
              print('# request : ' + res.request.toString());
              print('# status : ' + res.statusCode.toString());
              print('# body : ' + res.body.toString());
            }

            if (res.statusCode != 200) {
              var response = {
                'status': res.statusCode,
                'body': decode(res.body)
              };
              error(response);
            } else {
              if (then != null) then(res.statusCode, res.body);
            }
          });
        } catch (e) {
          if (e is PlatformException) {
            if (then != null) then(e);
          }
        }
      } else {
        Wh.toast('Periksa koneksi internet Anda!');
      }
    });
  }
}

// ERROR HANDLER
onError(context,
    {response,
    bool popup: false,
    backOnDismiss: true,
    backOnError: false,
    Function then}) {
  var status = response['status'], message = response['body']['message'];

  switch (status) {
    case 403:
      if (popup) {
        showDialog(
          context: context,
          // child: ErrorPopup(status: status, message: message)
        ).then((_) {
          if (backOnDismiss) {
            Navigator.pop(context);
          }
        });
      } else {
        Wh.toast(status.toString() + ' - ' + message);
      }
      break;

    case 404:
      if (popup) {
        showDialog(
          context: context,
          // child: ErrorPopup(status: status, message: message)
        ).then((_) {
          if (backOnDismiss) {
            Navigator.pop(context);
          }
        });
      } else {
        Wh.toast(message);
      }
      break;

    case 500:
      showDialog(
              context: context,
              child: ErrorPopup(
                  status: status,
                  icon: Feather.server,
                  message: 'Internal server error!'))
          .then((_) {
        if (backOnDismiss) {
          Navigator.pop(context);
        }
        if (then != null) then(status);
      });
      break;

    case 401:
      Wh.toast('Session expired, coba login ulang.');
      break;

    default: //Wh.toast(status.toString()+' - Unknown Error'); print(response['body']);
      response['body'].forEach((k, v) {
        Wh.toast(response['body'][k] is List
            ? response['body'][k].join('')
            : response['body']['error']);
        Wh.toast(response['body'][k] is List
            ? response['body'][k].join('')
            : response['body']['message']);
      });
      if (backOnError) {
        Navigator.pop(context);
      }
  }
}

class ErrorPopup extends StatefulWidget {
  ErrorPopup({this.status, this.icon, this.message});
  final status, icon, message;

  @override
  _ErrorPopupState createState() => _ErrorPopupState();
}

class _ErrorPopupState extends State<ErrorPopup> {
  @override
  Widget build(BuildContext context) {
    return ZoomIn(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: Material(
              child: Container(
                  width: Mquery.width(context) - 50,
                  height: 300,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(5)),
                  child: Column(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Container(
                                padding: EdgeInsets.all(15),
                                margin: EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                    border: Border.all(color: TColor.red()),
                                    borderRadius: BorderRadius.circular(50)),
                                child: Icon(
                                    widget.icon == null
                                        ? Feather.user_x
                                        : widget.icon,
                                    size: 30,
                                    color: TColor.red())),
                            Container(
                                child: Column(
                              children: <Widget>[
                                text(widget.status,
                                    bold: true, size: 25, height: 3),
                                text(ucword(widget.message), bold: true),
                                text('Butuh bantuan? hubungi Tim IT.',
                                    color: Colors.black54)
                              ],
                            ))
                          ],
                        ),
                      ),
                      Container(
                        // padding: EdgeInsets.all(10),
                        child: WidSplash(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          color: Color.fromRGBO(0, 0, 0, .05),
                          child: Container(
                            width: Mquery.width(context),
                            padding: EdgeInsets.all(11),
                            child: text('Tutup', align: TextAlign.center),
                          ),
                        ),
                      )
                    ],
                  )),
            ),
          )
        ],
      ),
    );
  }
}
