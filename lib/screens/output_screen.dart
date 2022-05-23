import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:lpinyin/lpinyin.dart';
import 'package:provider/provider.dart';
import 'package:transalin/constants/app_color.dart';
import 'package:transalin/constants/app_global.dart';
import 'package:transalin/constants/app_language.dart';
import 'package:transalin/providers/source_language_changer.dart';
import 'package:transalin/providers/target_language_changer.dart';
import 'package:transalin/screens/instruction_screen.dart';
import 'package:transalin/widgets/language_bar.dart';

//lists where the texts are saved
List<String> translatedTextList = [];
List<String> romanizedTextList = [];

//a screen that displays the result of translation
class OutputScreen extends StatefulWidget {
  const OutputScreen(
      {Key? key, required this.fromGallery, required this.imageFile})
      : super(key: key);

  final bool fromGallery;
  final XFile imageFile;

  @override
  OutputScreenState createState() => OutputScreenState();
}

class OutputScreenState extends State<OutputScreen> {
  late AppBar appBar;

  //for image info and display
  late File filePath;
  late Image displayImage;
  late InputImage recognizerImage;

  //for recognition and translation
  final textRecognizer = TextRecognizer(script: TextRecognitionScript.chinese);

  late TranslateLanguage langSourceTag;
  late TranslateLanguage langTargetTag;

  late RecognizedText inputText;
  late String recognizedText;
  late String translatedText;
  late String romanizedText;

  //for text-to-speech
  late String speechSourceTag;
  late String speechTargetTag;
  final FlutterTts flutterTts = FlutterTts();

  //for features
  late bool showOverlay; //toggle
  late bool showRomanized; //change
  late bool withRomanization; //change
  late String copiedText; //copy
  late bool playAudio; //listen
  late bool showStopSign; //listen

  late String textLabel; //toast display
  ValueNotifier<bool> isDialOpen =
      ValueNotifier(false); //floating action button behavior

  //for drawing into and saving canvas
  late CustomPainter boundingBoxPainter;
  late CustomPainter translationPainter;
  late CustomPainter romanizationPainter;
  GlobalKey globalKey = GlobalKey(); //for saving canvas state

  @override
  void initState() {
    super.initState();
    //to deny language change when the recognizer and translator are still processing
    AppGlobal.inOutputScreen = true;

    appBar = AppBar(
      title: Text('TranSalin',
          style: TextStyle(
              shadows: const [AppGlobal.shadowStyle],
              fontSize: AppGlobal.screenWidth * 0.042)),
      centerTitle: true,
      backgroundColor: AppColor.kColorTransparent,
      elevation: 0,
      actions: [
        //help button
        IconButton(
            splashColor: AppColor.kColorPeriLight,
            splashRadius: 14,
            icon: Icon(Icons.help_outline_rounded,
                size: AppGlobal.screenWidth * 0.055,
                color: AppColor.kColorWhite,
                shadows: const [AppGlobal.shadowStyle]),
            onPressed: () {
              //stop TTS and toast display when the instruction screen is displayed
              Fluttertoast.cancel();
              flutterTts.stop();

              () async {
                await Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const InstructionScreen(pop: true)));
              }();
            })
      ],
      //go back to input screen button
      leading: IconButton(
        splashColor: AppColor.kColorPeriLight,
        splashRadius: 14,
        icon: Icon(Icons.close_rounded,
            size: AppGlobal.screenWidth * 0.07,
            color: AppColor.kColorWhite,
            shadows: const [AppGlobal.shadowStyle]),
        onPressed: () => Navigator.of(context).pop(),
      ),
    );

    flutterTts.setStartHandler(() {
      //this is called when the audio starts
      if (mounted) {
        setState(() => showStopSign = true); //show option to stop the audio
      }
    });

    flutterTts.setCompletionHandler(() {
      //this is called when the audio ends
      if (mounted) {
        //hide the display that shows TTS is loading/playing
        setState(() {
          playAudio = false;
          showStopSign = false;
        });
      }
    });

    flutterTts.setCancelHandler(() {
      //this is called when the audio is stopped
      if (mounted) {
        //hide the display that shows TTS is loading/playing
        setState(() {
          playAudio = false;
          showStopSign = false;
        });
      }
    });

    //start processing iamge
    filePath = File(widget.imageFile.path);
    displayImage = Image.file(filePath);
    recognizerImage = InputImage.fromFilePath(widget.imageFile.path);

    translateText();
  }

  @override
  void dispose() {
    //set to false to allow language change anytime in the input screen
    AppGlobal.inOutputScreen = false;
    Fluttertoast.cancel();
    flutterTts.stop();
    textRecognizer.close();
    super.dispose();
  }

  clear() {
    //clearing and reassigning variables' value
    AppGlobal.hasTranslated = false;

    langSourceTag = getLangTag(0);
    langTargetTag = getLangTag(1);
    speechSourceTag = getSpeechTag(langSourceTag);
    speechTargetTag = getSpeechTag(langTargetTag);

    showOverlay = true;
    showRomanized = false;
    showStopSign = false;
    withRomanization = langTargetTag == AppLanguage.zhTag;
    playAudio = false;

    recognizedText = '';
    translatedText = '';
    romanizedText = '';

    translatedTextList.clear();
    romanizedTextList.clear();
  }

  translateText() async {
    clear();

    //recognize text
    inputText = await textRecognizer.processImage(recognizerImage);
    if (!mounted) return;

    String recognized;
    String translated;
    String romanized;

    for (TextBlock block in inputText.blocks) {
      for (TextLine line in block.lines) {
        recognized = line.text;

        final OnDeviceTranslator translator;
        translator = OnDeviceTranslator(
            sourceLanguage: langSourceTag, targetLanguage: langTargetTag);
        translated = await translator.translateText(recognized);
        translator.close();

        if (mounted) {
          setState(() {
            recognizedText += '$recognized ';
            translatedText += '$translated ';

            //get translated texts for the canvas display
            translatedTextList.add(translated);
            if (withRomanization) {
              romanized = PinyinHelper.getPinyinE(translated,
                  separator: " ", format: PinyinFormat.WITH_TONE_MARK);
              romanizedText += '$romanized ';
              //get romanized texts for the canvas display
              romanizedTextList.add(romanized);
            }
          });
        }
      }
      if (mounted) {
        setState(() {
          recognizedText += '\n';
          translatedText += '\n';
          romanizedText += '\n';
        });
      }
    }

    //make the overlay display
    boundingBoxPainter = BoxPainter(inputText);
    translationPainter = TranslationPainter(inputText);
    if (withRomanization) romanizationPainter = RomanizationPainter(inputText);

    if (mounted) setState(() => AppGlobal.hasTranslated = true);
  }

  @override
  Widget build(BuildContext context) {
    if (mounted) {
      if (langSourceTag != context.watch<SourceLanguageChanger>().tag ||
          langTargetTag != context.watch<TargetLanguageChanger>().tag) {
        //if there is a language change, translate text again
        translateText();
      }
    }

    double fabWidth = (AppGlobal.screenWidth * 0.15).toDouble();
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: appBar,
      floatingActionButton: Container(
          //button that shows the features
          padding: EdgeInsets.only(bottom: AppGlobal.screenHeight * 0.08),
          alignment: Alignment.bottomRight,
          child: SpeedDial(
            buttonSize: Size(fabWidth, fabWidth),
            childrenButtonSize: Size(fabWidth, fabWidth),
            animatedIcon: AnimatedIcons.menu_close,
            backgroundColor: AppColor.kColorPeriDarkest,
            overlayColor: AppColor.kColorBlack,
            overlayOpacity: 0.3,
            spacing: AppGlobal.screenHeight * 0.005,
            spaceBetweenChildren: AppGlobal.screenHeight * 0.005,
            openCloseDial: isDialOpen,
            closeManually: true,
            onPress: () => {
              //do not allow opening the button when translation is not yet ready
              if (!AppGlobal.hasTranslated)
                {
                  isDialOpen.value = false,
                }
              //catcher for when there is no recognized text in the image
              else
                {
                  recognizedText == ''
                      ? {
                          isDialOpen.value = false,
                          AppGlobal.showToast('No text detected.'),
                        }
                      : isDialOpen.value = true
                }
            },
            children: [
              //toggle overlay visibility
              SpeedDialChild(
                  child: Icon(Icons.visibility_outlined,
                      color: AppColor.kColorPeriLightest, size: fabWidth - 30),
                  backgroundColor: AppColor.kColorPeriDarker,
                  onTap: () {
                    if (mounted) {
                      setState(() => showOverlay = !showOverlay);
                    }
                  }),
              //change Chinese script
              SpeedDialChild(
                  child: Icon(Icons.translate,
                      color: AppColor.kColorPeriLightest, size: fabWidth - 30),
                  backgroundColor: AppColor.kColorPeriDark,
                  onTap: () {
                    if (withRomanization) {
                      //only apply when the target language is Chinese
                      if (mounted) {
                        setState(() => showRomanized = !showRomanized);
                      }
                    } else {
                      AppGlobal.showToast(
                          'Not applicable. Target\nlanguage is not Chinese.');
                    }
                  }),
              //copy text
              SpeedDialChild(
                  child: Icon(Icons.content_copy,
                      color: AppColor.kColorPeriLightest, size: fabWidth - 30),
                  backgroundColor: AppColor.kColorPeri,
                  onTap: () {
                    if (showOverlay) {
                      //determine what text is currently shown on the screen
                      if (showRomanized) {
                        copiedText = romanizedText;
                        textLabel = 'Romanized';
                      } else {
                        copiedText = translatedText;
                        textLabel = 'Translated';
                      }
                    } else {
                      copiedText = recognizedText;
                      textLabel = 'Recognized';
                    }

                    //copy text to clipboard
                    Clipboard.setData(ClipboardData(text: copiedText))
                        .then((_) {
                      return AppGlobal.showToast('$textLabel text copied');
                    });
                  }),
              //listen to text
              SpeedDialChild(
                  child: Icon(Icons.hearing,
                      color: AppColor.kColorPeriLightest, size: fabWidth - 30),
                  backgroundColor: AppColor.kColorPeriLight,
                  onTap: () {
                    if (!playAudio) {
                      if (mounted) {
                        setState(() => playAudio = true);
                      } //to show loading sign while TTS is not yet ready
                      () async {
                        if (!showOverlay) {
                          //determine what text is currently shown on the screen and set audio language and text
                          flutterTts.setLanguage(speechSourceTag);
                          await flutterTts.speak(recognizedText);
                        } else {
                          //still the same with or without romanization
                          flutterTts.setLanguage(speechTargetTag);
                          await flutterTts.speak(translatedText);
                        }
                      }();
                    }
                  }),
              //save image
              SpeedDialChild(
                  child: Icon(Icons.save_alt,
                      color: AppColor.kColorPeriLightest, size: fabWidth - 30),
                  backgroundColor: AppColor.kColorPeriLighter,
                  onTap: () {
                    () async {
                      //determine what text is currently shown on the screen
                      if (!showOverlay) {
                        textLabel = 'Original';
                        //save original image when there is no overlay
                        await GallerySaver.saveImage(widget.imageFile.path);
                      } else {
                        showRomanized
                            ? textLabel = 'Romanized'
                            : textLabel = 'Translated';

                        //save the current state of the canvas
                        RenderRepaintBoundary boundary =
                            globalKey.currentContext?.findRenderObject()
                                as RenderRepaintBoundary;
                        ui.Image image = await boundary.toImage();

                        ByteData? byteData = await image.toByteData(
                            format: ui.ImageByteFormat.png);

                        await ImageGallerySaver.saveImage(
                            byteData!.buffer.asUint8List());
                      }
                      if (!mounted) return;

                      AppGlobal.showToast('$textLabel image saved');
                    }();
                  }),
            ],
          )),
      body: Stack(children: [
        SizedBox(
            width: AppGlobal.screenWidth,
            height: AppGlobal.screenHeight * 0.92,
            //image/canvas display
            child: ClipRRect(
                borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20)),
                child: Container(
                    color: AppColor.kColorPeriLighter,
                    child: Stack(children: [
                      //if translation has not finished, show a loading sign
                      !AppGlobal.hasTranslated
                          ? Stack(children: [
                              imageDisplay(),
                              Center(
                                child: SizedBox(
                                    width: AppGlobal.screenWidth * 0.07,
                                    height: AppGlobal.screenWidth * 0.07,
                                    child: circularProgressWidget()),
                              )
                            ])
                          : InteractiveViewer(
                              //allows to zoom in and out the image
                              boundaryMargin:
                                  const EdgeInsets.all(double.infinity),
                              maxScale: 4,
                              minScale: 0.5,
                              //if show overlay is false, hide custom painters
                              child: !showOverlay
                                  ? imageDisplay()
                                  : !widget.fromGallery
                                      ? Align(
                                          alignment: Alignment.topCenter,
                                          child: overlayDisplay())
                                      : Center(child: overlayDisplay())),
                      //if TTS is not loading or playing, show nothing
                      !playAudio
                          ? Container()
                          : showStopSign
                              ? stopSign()
                              : loadingSign(), //show loading sign while TTS is not yet ready
                    ])))),
        Container(alignment: Alignment.bottomCenter, child: const LanguageBar())
      ]),
    );
  }

  Widget imageDisplay() {
    return !widget.fromGallery
        ? Align(alignment: Alignment.topCenter, child: displayImage)
        : Center(child: displayImage);
  }

  FittedBox overlayDisplay() {
    return FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox(
            width: displayImage.width,
            height: displayImage.height,
            child: RepaintBoundary(
                key: globalKey,
                child: Stack(children: [
                  imageDisplay(),
                  CustomPaint(painter: boundingBoxPainter),
                  showRomanized
                      ? CustomPaint(painter: romanizationPainter)
                      : CustomPaint(painter: translationPainter)
                ]))));
  }

  getLangTag(int index) {
    //return language tag for translation
    if (!mounted) return;

    return index == 0
        ? context.read<SourceLanguageChanger>().tag
        : context.read<TargetLanguageChanger>().tag;
  }

  getSpeechTag(TranslateLanguage langTag) {
    //return language tag for TTS
    String tag = langTag == AppLanguage.enTag
        ? 'en-US'
        : langTag == AppLanguage.tlTag
            ? 'fil-PH'
            : 'zh-CN';

    return tag;
  }

  Widget circularProgressWidget() => const CircularProgressIndicator(
      valueColor: AlwaysStoppedAnimation<Color>(AppColor.kColorPeriLight));

  Widget ttsSign(Widget child) => Align(
      //used for displaying signs that TTS is loading/playing
      alignment: Alignment.topRight,
      child: Container(
          width: AppGlobal.screenWidth * 0.13,
          height: AppGlobal.screenWidth * 0.13,
          alignment: Alignment.center,
          margin:
              EdgeInsets.only(top: appBar.preferredSize.height + 20, right: 20),
          decoration: const BoxDecoration(
              shape: BoxShape.circle, color: AppColor.kColorWhite70),
          child: child));

  Widget loadingSign() => ttsSign(SizedBox(
      width: AppGlobal.screenWidth * 0.045,
      height: AppGlobal.screenWidth * 0.045,
      child: circularProgressWidget()));

  Widget stopSign() => ttsSign(Center(
      child: IconButton(
          icon: const Icon(Icons.stop_rounded),
          iconSize: AppGlobal.screenWidth * 0.084,
          color: AppColor.kColorPeriLight,
          onPressed: () => flutterTts.stop())));
}

double findAngle(Point<int> p1, Point<int> p2) {
  //find angle between bottom left and bottom right corner points
  final double deltaY = p2.y.toDouble() - p1.y.toDouble();
  final double deltaX = p2.x.toDouble() - p1.x.toDouble();
  final double result = atan2(deltaY, deltaX);
  return (result < 0) ? (6.283 + result) : result;
}

bool hasNegativePoint(List<Point<int>> points) {
  //to catch error when a cornerpoint of an overlay exceeds the canvas
  bool point0 = points[0].x < 0 || points[0].y < 0;
  bool point1 = points[1].x < 0 || points[1].y < 0;
  bool point2 = points[2].x < 0 || points[2].y < 0;
  bool point3 = points[3].x < 0 || points[3].y < 0;
  return point0 || point1 || point2 || point3;
}

class BoxPainter extends CustomPainter {
  BoxPainter(this.inputText);
  final RecognizedText inputText;

  @override
  Future<void> paint(ui.Canvas canvas, ui.Size size) async {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = AppColor.kColorPeriDarkest;

    for (TextBlock block in inputText.blocks) {
      for (TextLine line in block.lines) {
        List<Point<int>> points = line.cornerPoints;

        if (!hasNegativePoint(points)) {
          final Path rectangle = Path(); //draw the bounding box of each line
          rectangle.moveTo(points[0].x.toDouble(), points[0].y.toDouble());
          rectangle.lineTo(points[1].x.toDouble(), points[1].y.toDouble());
          rectangle.lineTo(points[2].x.toDouble(), points[2].y.toDouble());
          rectangle.lineTo(points[3].x.toDouble(), points[3].y.toDouble());

          canvas.drawPath(rectangle, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class TranslationPainter extends CustomPainter {
  TranslationPainter(this.inputText);
  final RecognizedText inputText;

  @override
  Future<void> paint(ui.Canvas canvas, ui.Size size) async {
    int counter = 0;

    for (TextBlock block in inputText.blocks) {
      for (TextLine line in block.lines) {
        List<Point<int>> points = line.cornerPoints;

        if (!hasNegativePoint(points)) {
          //get the size of the bounding box to adjust the text size
          double frameWidth = points[1].x.toDouble() - points[0].x.toDouble();
          double frameHeight = points[3].y.toDouble() - points[0].y.toDouble();

          final TextPainter textPainter = TextPainter(
            text: TextSpan(
              text: translatedTextList[
                  counter++], //access the previously saved translated text list
              style: TextStyle(
                fontSize: frameHeight, //initial text size
                color: AppColor.kColorWhite,
              ),
            ),
            textDirection: TextDirection.ltr,
            textScaleFactor: 1,
          )..layout();

          //if text size is still out of the bounds, decrease the text scale factor
          while (textPainter.height >= frameHeight) {
            textPainter.textScaleFactor -= 0.01;
            textPainter.layout(maxWidth: frameWidth);
          }

          canvas.save(); //save canvas before rotating
          canvas.translate(points[0].x.toDouble(), points[0].y.toDouble());
          canvas.rotate(findAngle(points[0], points[1]));
          canvas.translate(-points[0].x.toDouble(), -points[0].y.toDouble());

          //draw text before restoring canvas
          textPainter.paint(
              canvas, Offset(points[0].x.toDouble(), points[0].y.toDouble()));
          canvas.restore();
        }
      }
    }
    counter = 0;
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class RomanizationPainter extends CustomPainter {
  RomanizationPainter(this.inputText);
  final RecognizedText inputText;

  @override
  Future<void> paint(ui.Canvas canvas, ui.Size size) async {
    int counter = 0;

    for (TextBlock block in inputText.blocks) {
      for (TextLine line in block.lines) {
        List<Point<int>> points = line.cornerPoints;

        //get the size of the bounding box to adjust the text size
        double frameWidth = points[1].x.toDouble() - points[0].x.toDouble();
        double frameHeight = points[3].y.toDouble() - points[0].y.toDouble();

        final TextPainter textPainter = TextPainter(
          text: TextSpan(
            text: romanizedTextList[
                counter++], //access the previously saved romanized text list
            style: TextStyle(
              fontSize: frameHeight, //initial text size
              color: AppColor.kColorWhite,
            ),
          ),
          textDirection: TextDirection.ltr,
          textScaleFactor: 1,
        )..layout();

        //if text size is still out of the bounds, decrease the text scale factor
        while (textPainter.height >= frameHeight) {
          textPainter.textScaleFactor -= 0.01;
          textPainter.layout(maxWidth: frameWidth);
        }

        canvas.save(); //save canvas before rotating
        canvas.translate(points[0].x.toDouble(), points[0].y.toDouble());
        canvas.rotate(findAngle(points[0], points[1]));
        canvas.translate(-points[0].x.toDouble(), -points[0].y.toDouble());
        //draw text before restoring canvas
        textPainter.paint(
            canvas, Offset(points[0].x.toDouble(), points[0].y.toDouble()));
        canvas.restore();
      }
    }
    counter = 0;
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
