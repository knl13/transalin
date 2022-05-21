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
  WidgetsFlutterBinding
      .ensureInitialized(); //ensure initialization of plugin services for availableCameras() function
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown
  ]); //prevent orientation from rotating

  final List<CameraDescription> cameras =
      await availableCameras(); //get list of device's available cameras
  AppGlobal.camera =
      cameras.first; //save and use first camera from the list (back cam)

  checkModels().then((_) => runApp(
      const MyApp())); //check models before running the app to know what screen to show first
}

checkModels() async {
  modelManager = OnDeviceTranslatorModelManager();

  isChineseEnglishDownloaded = await modelManager
      .isModelDownloaded('zh'); //english model is included in any other models
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
            home: modelsAreDownloaded
                ? const InputScreen() //go straight to input screen when models are already downloaded
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
    AppGlobal.screenWidth = MediaQuery.of(context).size.width;
    AppGlobal.screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColor.kColorPeriLightest,
      body: Center(
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          //text guide that tells the models are being downloaded
          const FittedBox(
              child: Text(
                  'Welcome! Let\'s first download\nthe translation language models.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColor.kColorPeriDark))),
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
                      const SizedBox(width: 10),
                      Text('中文 (Zhōngwén)',
                          style: !isChineseEnglishDownloaded
                              ? AppGlobal.textStylePeriLight
                              : AppGlobal.textStylePeriDarkBold)
                    ]),
                    const SizedBox(height: 10),
                    //English language
                    Row(mainAxisAlignment: MainAxisAlignment.start, children: [
                      !isChineseEnglishDownloaded
                          ? downloadingSymbol
                          : doneSymbol,
                      const SizedBox(width: 10),
                      Text('English language',
                          style: !isChineseEnglishDownloaded
                              ? AppGlobal.textStylePeriLight
                              : AppGlobal.textStylePeriDarkBold)
                    ]),
                    const SizedBox(height: 10),
                    //Filipino language
                    Row(mainAxisAlignment: MainAxisAlignment.start, children: [
                      !isFilipinoDownloaded ? downloadingSymbol : doneSymbol,
                      const SizedBox(width: 10),
                      Text('wikang Filipino',
                          style: !isFilipinoDownloaded
                              ? AppGlobal.textStylePeriLight
                              : AppGlobal.textStylePeriDarkBold)
                    ]),
                  ]))
        ],
      )),
    );
  }
}
