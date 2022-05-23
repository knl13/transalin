import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:provider/provider.dart';
import 'package:transalin/constants/app_color.dart';
import 'package:transalin/constants/app_global.dart';
import 'package:transalin/providers/camera_controller_listener.dart';
import 'package:transalin/providers/source_language_changer.dart';
import 'package:transalin/providers/target_language_changer.dart';
import 'package:transalin/screens/input_screen.dart';
import 'package:transalin/screens/instruction_screen.dart';

late OnDeviceTranslatorModelManager modelManager;
bool isChineseEnglishDownloaded = false;
bool isFilipinoDownloaded = false;
bool modelsAreDownloaded = false;

//root of app where the first screen is determined (download or input screen)
Future<void> main() async {
  //ensure initialization of plugin services for availableCameras() function
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown
  ]); //prevent landscape orientation

  //get list of device's available cameras
  final List<CameraDescription> cameras = await availableCameras();
  //save and use first camera from the list (back cam)
  AppGlobal.camera = cameras.first;

  //check models before running the app to know what screen to show first
  checkModels().then((_) => runApp(const MyApp()));
}

checkModels() async {
  modelManager = OnDeviceTranslatorModelManager();

  //english model is included in any other models
  isChineseEnglishDownloaded = await modelManager.isModelDownloaded('zh');
  isFilipinoDownloaded = await modelManager.isModelDownloaded('tl');

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
            //go straight to input screen when models are already downloaded
            home: modelsAreDownloaded
                ? const InputScreen()
                : const DownloadScreen()));
  }
}

//a screen that downloads language models and shows model status before using the app
class DownloadScreen extends StatefulWidget {
  const DownloadScreen({Key? key}) : super(key: key);

  @override
  DownloadScreenState createState() => DownloadScreenState();
}

class DownloadScreenState extends State<DownloadScreen> {
  late Icon doneSymbol;
  late Icon downloadingSymbol;
  late TextStyle textStylePeriLight;
  late TextStyle textStylePeriDarkBold;

  @override
  void initState() {
    super.initState();
    downloadModels();
  }

  void downloadModels() async {
    if (!isChineseEnglishDownloaded) {
      await modelManager.downloadModel('zh');
      if (mounted) setState(() => isChineseEnglishDownloaded = true);
    }
    if (!isFilipinoDownloaded) {
      await modelManager.downloadModel('tl');
      if (mounted) setState(() => isFilipinoDownloaded = true);
    }
    goToInstructionScreen();
  }

  void goToInstructionScreen() {
    () async {
      await Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (context) => const InstructionScreen(pop: false)));
      //pop value determines if the instruction screen will do pushReplacement or pop navigation
    }();
  }

  @override
  Widget build(BuildContext context) {
    //save screen width and height before the app starts
    AppGlobal.initSizeConfig(context);

    doneSymbol = Icon(
      Icons.download_done_rounded,
      color: AppColor.kColorPeriDark,
      size: AppGlobal.screenWidth * 0.08,
    );
    downloadingSymbol = Icon(
      Icons.downloading_rounded,
      color: AppColor.kColorPeriLight,
      size: AppGlobal.screenWidth * 0.08,
    );

    textStylePeriLight = TextStyle(
        color: AppColor.kColorPeriLight,
        fontSize: AppGlobal.screenWidth * 0.039);

    textStylePeriDarkBold = TextStyle(
        color: AppColor.kColorPeriDark,
        fontWeight: FontWeight.bold,
        fontSize: AppGlobal.screenWidth * 0.039);

    return Scaffold(
      backgroundColor: AppColor.kColorPeriLightest,
      body: Center(
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          //heading
          Text(
              'Welcome! Let\'s first download\nthe translation language models.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColor.kColorPeriDark,
                  fontSize: AppGlobal.screenWidth * 0.039)),
          SizedBox(height: AppGlobal.screenHeight * 0.1),
          //moving color circles
          SpinKitFadingGrid(
            size: AppGlobal.screenWidth * 0.6,
            itemBuilder: (context, index) {
              final List<Color> colors = [
                Colors.indigo.shade200,
                Colors.indigo.shade600,
                Colors.indigo.shade900,
                Colors.indigo.shade400,
                Colors.indigo.shade800
              ];

              final Color color = colors[index % colors.length];

              return DecoratedBox(
                  decoration:
                      BoxDecoration(color: color, shape: BoxShape.circle));
            },
          ),
          SizedBox(height: AppGlobal.screenHeight * 0.1),
          //display download status of models
          FittedBox(
              alignment: Alignment.center,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    //Chinese language
                    Row(children: [
                      !isChineseEnglishDownloaded
                          ? downloadingSymbol
                          : doneSymbol,
                      SizedBox(width: AppGlobal.screenWidth * 0.028),
                      Text('中文 (Zhōngwén)',
                          style: !isChineseEnglishDownloaded
                              ? textStylePeriLight
                              : textStylePeriDarkBold)
                    ]),
                    SizedBox(height: AppGlobal.screenHeight * 0.014),
                    //English language
                    Row(mainAxisAlignment: MainAxisAlignment.start, children: [
                      !isChineseEnglishDownloaded
                          ? downloadingSymbol
                          : doneSymbol,
                      SizedBox(width: AppGlobal.screenWidth * 0.028),
                      Text('English language',
                          style: !isChineseEnglishDownloaded
                              ? textStylePeriLight
                              : textStylePeriDarkBold)
                    ]),
                    SizedBox(height: AppGlobal.screenHeight * 0.014),
                    //Filipino language
                    Row(mainAxisAlignment: MainAxisAlignment.start, children: [
                      !isFilipinoDownloaded ? downloadingSymbol : doneSymbol,
                      SizedBox(width: AppGlobal.screenWidth * 0.028),
                      Text('wikang Filipino',
                          style: !isFilipinoDownloaded
                              ? textStylePeriLight
                              : textStylePeriDarkBold)
                    ]),
                  ]))
        ],
      )),
    );
  }
}
