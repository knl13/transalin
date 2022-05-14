// ignore_for_file: avoid_print

import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:provider/provider.dart';
import 'package:transalin/constants/app_language.dart';
import 'package:transalin/providers/camera_controller_listener.dart';
import 'package:transalin/providers/change_script_listener.dart';
import 'package:transalin/providers/source_language_changer.dart';
import 'package:transalin/providers/target_language_changer.dart';
import 'package:transalin/screens/input_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding
      .ensureInitialized(); //ensure initialization of plugin services for availableCameras() function
  final List<CameraDescription> cameras =
      await availableCameras(); //get list of device's available cameras

  runApp(MyApp(cameras: cameras));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key, required this.cameras}) : super(key: key);

  final List<CameraDescription> cameras;

  void downloadModels() async {
    final modelManager = GoogleMlKit.nlp.translateLanguageModelManager();

    final bool isChineseDownloaded =
        await modelManager.isModelDownloaded(AppLanguage.zh);
    final bool isEnglishDownloaded =
        await modelManager.isModelDownloaded(AppLanguage.en);
    final bool isFilipinoDownloaded =
        await modelManager.isModelDownloaded(AppLanguage.tl);
    final bool isKoreanDownloaded =
        await modelManager.isModelDownloaded(AppLanguage.ko);

    if (!isChineseDownloaded) {
      debugPrint('Downloading Chinese model...');
      await modelManager.downloadModel(AppLanguage.zh);
      debugPrint('Chinese model downloading done!');
    } else {
      debugPrint('Chinese model already downloaded!');
    }
    if (!isEnglishDownloaded) {
      debugPrint('Downloading English model...');
      await modelManager.downloadModel(AppLanguage.zh);
      debugPrint('English model downloading done!');
    } else {
      debugPrint('English model already downloaded!');
    }
    if (!isFilipinoDownloaded) {
      debugPrint('Downloading Tagalog model...');
      await modelManager.downloadModel(AppLanguage.tl);
      debugPrint('Tagalog model downloading done!');
    } else {
      debugPrint('Tagalog model already downloaded!');
    }
    if (!isKoreanDownloaded) {
      debugPrint('Downloading Korean model...');
      await modelManager.downloadModel(AppLanguage.ko);
      debugPrint('Korean model downloading done!');
    } else {
      debugPrint('Korean model already downloaded!');
    }
  }

  @override
  Widget build(BuildContext context) {
    downloadModels();
    return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => CameraControllerListener()),
          ChangeNotifierProvider(create: (_) => ChangeScriptListener()),
          ChangeNotifierProvider(create: (_) => SourceLanguageChanger()),
          ChangeNotifierProvider(create: (_) => TargetLanguageChanger()),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(scaffoldBackgroundColor: Colors.black),
          home: InputScreen(
              cameras: cameras), //pass cameras to InputScreen widget
        ));
  }
}
