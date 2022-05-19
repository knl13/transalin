import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:provider/provider.dart';
import 'package:transalin/constants/app_color.dart';
import 'package:transalin/constants/app_global.dart';
import 'package:transalin/constants/app_language.dart';
import 'package:transalin/providers/camera_controller_listener.dart';
import 'package:transalin/providers/source_language_changer.dart';
import 'package:transalin/providers/target_language_changer.dart';
import 'package:transalin/screens/input_screen.dart';
import 'package:transalin/screens/instruction_screen.dart';

late List<CameraDescription> cameras;
late TranslateLanguageModelManager modelManager;
bool isChineseEnglishDownloaded = false;
bool isFilipinoDownloaded = false;
bool modelsAreDownloaded = false;

Future<void> main() async {
  WidgetsFlutterBinding
      .ensureInitialized(); //ensure initialization of plugin services for availableCameras() function
  cameras = await availableCameras(); //get list of device's available cameras
  AppGlobal.camera = cameras.first; //use first camera from the list

  checkModels().then((_) => runApp(const MyApp()));
}

checkModels() async {
  modelManager = GoogleMlKit.nlp.translateLanguageModelManager();

  isChineseEnglishDownloaded =
      await modelManager.isModelDownloaded(AppLanguage.zh);
  isFilipinoDownloaded = await modelManager.isModelDownloaded(AppLanguage.tl);

  isChineseEnglishDownloaded && isFilipinoDownloaded
      ? modelsAreDownloaded = true
      : modelsAreDownloaded = false;
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => CameraControllerListener()),
          ChangeNotifierProvider(create: (_) => SourceLanguageChanger()),
          ChangeNotifierProvider(create: (_) => TargetLanguageChanger()),
        ],
        child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme:
                ThemeData(scaffoldBackgroundColor: AppColor.kColorPeriDarkest),
            home: modelsAreDownloaded
                ? const InputScreen() //pass cameras to InputScreen widget
                : const DownloadScreen()));
  }
}

class DownloadScreen extends StatefulWidget {
  const DownloadScreen({Key? key}) : super(key: key);

  @override
  DownloadScreenState createState() => DownloadScreenState();
}

class DownloadScreenState extends State<DownloadScreen> {
  Icon doneSymbol = const Icon(
    Icons.download_done_rounded,
    color: AppColor.kColorPeriDark,
    size: 30,
  );
  Icon downloadingSymbol = const Icon(
    Icons.downloading_rounded,
    color: AppColor.kColorPeriLight,
    size: 30,
  );
  @override
  void initState() {
    super.initState();
    downloadModels();
  }

  void downloadModels() async {
    if (!isChineseEnglishDownloaded) {
      await modelManager.downloadModel(AppLanguage.zh);
      if (mounted) setState(() => isChineseEnglishDownloaded = true);
    }
    if (!isFilipinoDownloaded) {
      await modelManager.downloadModel(AppLanguage.tl);
      if (mounted) setState(() => isFilipinoDownloaded = true);
    }
  }

  void goToInstructionScreen() {
    () async {
      await Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (context) => const InstructionScreen(pop: false)));
    }();
  }

  @override
  Widget build(BuildContext context) {
    AppGlobal.screenWidth = MediaQuery.of(context).size.width;
    AppGlobal.screenHeight = MediaQuery.of(context).size.height;
    if (isChineseEnglishDownloaded && isFilipinoDownloaded) {
      goToInstructionScreen();
    }

    return Scaffold(
      backgroundColor: AppColor.kColorPeriLightest,
      body: Center(
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const FittedBox(
              child: Text(
                  'Welcome! Let\'s first download\nthe translation language models.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColor.kColorPeri))),
          SizedBox(height: AppGlobal.screenHeight * 0.1),
          SpinKitFadingGrid(
            size: AppGlobal.screenWidth * 0.5,
            itemBuilder: (context, index) {
              final colors = [
                Colors.indigo.shade200,
                Colors.indigo.shade600,
                Colors.indigo.shade900,
                Colors.indigo.shade400,
                Colors.indigo.shade800,
                // AppColor.kColorPeriLighter,
                // AppColor.kColorPeriLight,
                // AppColor.kColorPeri,
                // AppColor.kColorPeriDark,
                // AppColor.kColorPeriDarker,
                // AppColor.kColorPeriDarkest,
              ];

              final color = colors[index % colors.length];

              return DecoratedBox(
                  decoration:
                      BoxDecoration(color: color, shape: BoxShape.circle));
            },
          ),
          SizedBox(height: AppGlobal.screenHeight * 0.1),
          FittedBox(
              alignment: Alignment.center,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(mainAxisAlignment: MainAxisAlignment.start, children: [
                      !isChineseEnglishDownloaded
                          ? downloadingSymbol
                          : doneSymbol,
                      const SizedBox(width: 10),
                      !isChineseEnglishDownloaded
                          ? const Text('中文 (Zhōngwén)',
                              style: TextStyle(color: AppColor.kColorPeriLight))
                          : const Text('中文 (Zhōngwén)',
                              style: TextStyle(
                                  color: AppColor.kColorPeriDark,
                                  fontWeight: FontWeight.bold)),
                    ]),
                    const SizedBox(height: 10),
                    Row(mainAxisAlignment: MainAxisAlignment.start, children: [
                      !isChineseEnglishDownloaded
                          ? downloadingSymbol
                          : doneSymbol,
                      const SizedBox(width: 10),
                      !isChineseEnglishDownloaded
                          ? const Text('English language',
                              style: TextStyle(color: AppColor.kColorPeriLight))
                          : const Text('English language',
                              style: TextStyle(
                                  color: AppColor.kColorPeriDark,
                                  fontWeight: FontWeight.bold)),
                    ]),
                    const SizedBox(height: 10),
                    Row(mainAxisAlignment: MainAxisAlignment.start, children: [
                      !isFilipinoDownloaded ? downloadingSymbol : doneSymbol,
                      const SizedBox(width: 10),
                      !isFilipinoDownloaded
                          ? const Text('wikang Filipino',
                              style: TextStyle(color: AppColor.kColorPeriLight))
                          : const Text('wikang Filipino',
                              style: TextStyle(
                                  color: AppColor.kColorPeriDark,
                                  fontWeight: FontWeight.bold)),
                    ]),
                  ]))
        ],
      )),
    );
  }
}
