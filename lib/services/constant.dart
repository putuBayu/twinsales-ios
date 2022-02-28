// file ini dibuat untuk membedakan aplikasi Twin Sales dan AKM sales
import 'package:flutter/material.dart';

const String APP_NAME = 'Twin Sales';
const Color THEME_COLOR = Colors.blue;
const String TRIGGER_UPDATE = 'twinsales';

//color
Color primary({double o: 1}){
  return Color.fromRGBO(95, 170, 236, o);
}

Color invertBlue({double o: 1}){
  return Color.fromRGBO(52, 107, 190, o);
}