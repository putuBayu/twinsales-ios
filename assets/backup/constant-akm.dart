// file ini dibuat untuk membedakan aplikasi Twin Sales dan AKM sales
import 'package:flutter/material.dart';

const String APP_NAME = 'AKM Sales';
const Color THEME_COLOR = Colors.red;
const String TRIGGER_UPDATE = 'akmsales';

Color primary({double o: 1}){
  return Color.fromRGBO(246, 0, 63, o);
}

Color invertBlue({double o: 1}){
  return Color.fromRGBO(189, 52, 43, o);
}