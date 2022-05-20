import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

abstract class AppGlobal {
  static double screenWidth = 0;
  static double screenHeight = 0;

  static late CameraDescription camera;

  static bool inOutputScreen = false;
  static bool hasTranslated = false;

  static const Shadow shadowStyle =
      Shadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 0));
}
