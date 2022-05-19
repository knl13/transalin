import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:transalin/classes/features.dart';
import 'package:transalin/classes/instruction.dart';
import 'package:transalin/classes/instructions.dart';
import 'package:transalin/constants/app_color.dart';
import 'package:transalin/constants/app_global.dart';
import 'package:transalin/constants/app_language.dart';
import 'package:transalin/providers/camera_controller_listener.dart';
import 'package:transalin/providers/source_language_changer.dart';
import 'package:transalin/providers/target_language_changer.dart';
import 'package:transalin/screens/input_screen.dart';

late List<CameraDescription> cameras;
late TranslateLanguageModelManager modelManager;
bool isChineseEnglishDownloaded = false;
bool isFilipinoDownloaded = false;
bool modelsAreDownloaded = false;

Future<void> main() async {
  WidgetsFlutterBinding
      .ensureInitialized(); //ensure initialization of plugin services for availableCameras() function
  cameras = await availableCameras(); //get list of device's available cameras

  checkModels();
  debugPrint('wewew');
  runApp(MyApp(cameras: cameras));
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
  const MyApp({Key? key, required this.cameras}) : super(key: key);

  final List<CameraDescription> cameras;

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
            theme: ThemeData(scaffoldBackgroundColor: AppColor.kColorBlack),
            home: modelsAreDownloaded
                ? InputScreen(
                    cameras: cameras) //pass cameras to InputScreen widget
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
    Icons.download_done,
    color: AppColor.kColorPeriDarker,
    size: 30,
  );
  Icon downloadingSymbol = const Icon(
    Icons.downloading,
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

  void goToStartScreen() {
    Future.delayed(const Duration(seconds: 1), () async {
      await Navigator.of(context)
          .push(MaterialPageRoute(builder: (context) => const StartScreen()));
    });
  }

  @override
  Widget build(BuildContext context) {
    AppGlobal.screenWidth = MediaQuery.of(context).size.width;
    AppGlobal.screenHeight = MediaQuery.of(context).size.height;
    if (isChineseEnglishDownloaded && isFilipinoDownloaded) goToStartScreen();

    return Scaffold(
      backgroundColor: AppColor.kColorPeriLighter,
      body: Center(
          child: Column(
        // crossAxisAlignment: CrossAxisAlignment.center,
        // mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(height: AppGlobal.screenHeight * 0.155),
          const FittedBox(
              child: Text(
                  'Welcome! Let\'s first download\nthe translation language models.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColor.kColorPeriDarker))),
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
                                  color: AppColor.kColorPeriDarker,
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
                                  color: AppColor.kColorPeriDarker,
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
                                  color: AppColor.kColorPeriDarker,
                                  fontWeight: FontWeight.bold)),
                    ]),
                  ]))
        ],
      )),
    );
  }
}

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  Widget buildInstruction(Instruction inst) => Container(
      width: AppGlobal.screenWidth * 0.6,
      height: AppGlobal.screenWidth * 0.5,
      decoration: const BoxDecoration(
          color: AppColor.kColorPeriDarkest,
          borderRadius: BorderRadius.all(Radius.circular(15))),
      margin: const EdgeInsets.only(left: 10),
      padding: const EdgeInsets.all(15),
      child: Column(children: [
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Container(
              padding: const EdgeInsets.all(5),
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: AppColor.kColorWhite),
              child: Icon(
                inst.icon,
                size: 20,
                color: AppColor.kColorPeriLight,
              )),
          const SizedBox(width: 10),
          FittedBox(
            child: Text(
              inst.heading,
              style: const TextStyle(
                  color: AppColor.kColorWhite, fontWeight: FontWeight.bold),
            ),
          )
        ]),
        const SizedBox(height: 10),
        Text(
          inst.text,
          // softWrap: true,
          // overflow: TextOverflow.visible,
          style:
              const TextStyle(color: AppColor.kColorPeriLighter, fontSize: 8),
        )
      ]));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.kColorPeriLighter,
      body: Center(
          child: Column(
        // crossAxisAlignment: CrossAxisAlignment.center,
        // mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(height: AppGlobal.screenHeight * 0.155),
          const FittedBox(
              child: Text(
                  'Yep, we\'re good to go!\nYou can use the app offline.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColor.kColorPeriDarker))),
          SizedBox(height: AppGlobal.screenHeight * 0.025),
          TextButton(
              onPressed: () async => await Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) => InputScreen(cameras: cameras))),
              child: SizedBox(
                  width: AppGlobal.screenWidth * 0.5,
                  child: Lottie.asset('assets/thumb_up.json'))),
          SizedBox(height: AppGlobal.screenHeight * 0.025),

          Container(
              width: AppGlobal.screenWidth,
              height: AppGlobal.screenWidth * 0.4,
              padding: const EdgeInsets.only(left: 10, right: 20),
              decoration: const BoxDecoration(
                color: AppColor.kColorPeriLighter,
              ),
              child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: Instructions.instructions.length,
                  itemBuilder: (context, index) => Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            buildInstruction(Instructions.instructions[index])
                          ]))),
          SizedBox(height: AppGlobal.screenHeight * 0.05),
          // FittedBox(
          // child:
          Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: const [
                Text('Got it? ',
                    style: TextStyle(
                      color: AppColor.kColorPeriDarkest,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    )),
                Text('Give a thumb up to get started.',
                    style: TextStyle(
                      color: AppColor.kColorPeriDarker,
                      fontSize: 11,
                    ))
              ]),
        ],
      )),
    );
  }
}
