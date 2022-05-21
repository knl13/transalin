import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:transalin/constants/app_color.dart';

abstract class AppGlobal {
  static double screenWidth = 0;
  static double screenHeight = 0;

  static late CameraDescription camera;

  //listeners for languages
  static late String sourceLanguageReader;
  static late String targetLanguageReader;
  static late String sourceLanguageWatcher;
  static late String targetLanguageWatcher;

  //checkers to allow/deny language change
  static bool inOutputScreen = false;
  static bool hasTranslated = false;

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
