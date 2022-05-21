import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:transalin/constants/app_color.dart';

abstract class AppGlobal {
  static double screenWidth = 0;
  static double screenHeight = 0;

  static late CameraDescription camera;

  //checkers to allow/deny language change
  static bool inOutputScreen = false;
  static bool hasTranslated = false;

  //toast for denying language change
  static denyLanguageChange() => () async {
        await Fluttertoast.cancel();

        Fluttertoast.showToast(
            msg: 'Already processing. Try\nchanging the language again later.',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.TOP,
            fontSize: 10,
            backgroundColor: AppColor.kColorPeriDarkest70,
            textColor: AppColor.kColorWhite);
      }();

  static const TextStyle textStylePeriLight =
      TextStyle(color: AppColor.kColorPeriLight);
  static const TextStyle textStylePeriDarkBold =
      TextStyle(color: AppColor.kColorPeriDark, fontWeight: FontWeight.bold);
  static const TextStyle textStylePeriDarkerBold16 = TextStyle(
      color: AppColor.kColorPeriDarker,
      fontWeight: FontWeight.bold,
      fontSize: 16);

  static const Shadow shadowStyle =
      Shadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 0));
}
