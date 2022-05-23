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

  //for showing errors/confirmation
  static showToast(String message) => () async {
        await Fluttertoast.cancel();

        Fluttertoast.showToast(
            msg: message,
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.TOP,
            fontSize: AppGlobal.screenWidth * 0.028,
            backgroundColor: AppColor.kColorPeriDarkest70,
            textColor: AppColor.kColorWhite);
      }();

  static const Shadow shadowStyle =
      Shadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 0));

  static void initSizeConfig(BuildContext context) {
    //save screen width and height before the app starts
    AppGlobal.screenWidth = MediaQuery.of(context).size.width;
    AppGlobal.screenHeight = MediaQuery.of(context).size.height;
  }
}
