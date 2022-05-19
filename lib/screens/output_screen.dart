import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/rendering.dart' hide BoxDecoration, BoxShadow;
import 'package:flutter/services.dart';
import 'package:flutter_inset_box_shadow/flutter_inset_box_shadow.dart';
import 'package:flutter/material.dart' hide BoxDecoration, BoxShadow;
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image/image.dart' as imagelib;
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:image_size_getter/file_input.dart' as isgfi;
import 'package:image_size_getter/image_size_getter.dart' as isg;
import 'package:lpinyin/lpinyin.dart';
import 'package:provider/provider.dart';
import 'package:transalin/classes/features.dart';
import 'package:transalin/constants/app_color.dart';
import 'package:transalin/constants/app_global.dart';
import 'package:transalin/constants/app_language.dart';
import 'package:transalin/providers/source_language_changer.dart';
import 'package:transalin/providers/target_language_changer.dart';
import 'package:transalin/screens/instruction_screen.dart';
import 'package:transalin/widgets/language_bar.dart';

List<String> translatedTextList = [];
List<String> romanizedTextList = [];
List<String> textDisplayList = [];
late ui.Image translatedImage;
late ui.Image romanizedImage;
late imagelib.Image? imageLibImage;

late ui.Size sizeCopy;
List<List<Color>> frameColors = [];

// A widget that displays the picture taken by the user.
class OutputScreen extends StatefulWidget {
  const OutputScreen({Key? key, required this.index, required this.inputImage})
      : super(key: key);

  final int index;
  final XFile inputImage;

  @override
  OutputScreenState createState() => OutputScreenState();
}

class OutputScreenState<T extends num> extends State<OutputScreen> {
  late String langSourceTag;
  late String langTargetTag;
  late String speechSourceTag;
  late String speechTargetTag;
  late bool hasRecognized;
  late bool hasTranslated;
  late RecognisedText inputText;
  late String recognizedText;
  late String translatedText;
  late String romanizedText;
  late Image image;
  late InputImage inputImage;
  late ui.Image uiImage;

  late int imageWidth;
  late int imageHeight;
  late int halfLength;
  late bool showOverlay;
  late bool showRomanized;
  late bool showVolumeSign;
  late bool playAudio;
  late String copiedText;
  late String textLabel;
  GlobalKey globalKey = GlobalKey();
  final FlutterTts flutterTts = FlutterTts();
  late bool withRomanization;
  late AppBar appBar;
  void getImageDimensions() {
    final size = isg.ImageSizeGetter.getSize(
        isgfi.FileInput(File(widget.inputImage.path)));
    if (size.needRotate) {
      imageWidth = size.height;
      imageHeight = size.width;
    } else {
      imageWidth = size.width;
      imageHeight = size.height;
    }
  }

  ValueNotifier<bool> isDialOpen = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    image = Image.file(File(widget.inputImage.path));
    inputImage = InputImage.fromFilePath(widget.inputImage.path);
    convertToUIImage(File(widget.inputImage.path))
        .then((image) => uiImage = image);

    Uint8List imageBytes = File(widget.inputImage.path).readAsBytesSync();

    List<int> values = imageBytes.buffer.asUint8List();

    imageLibImage = imagelib.decodeImage(values);

    appBar = AppBar(
      title: const Text('TranSalin',
          style: TextStyle(shadows: [AppGlobal.shadowStyle])),
      centerTitle: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      actions: [
        IconButton(
            splashColor: AppColor.kColorPeriLight,
            splashRadius: 14,
            icon: const Icon(Icons.help_outline_rounded,
                size: 20,
                color: Colors.white,
                shadows: [AppGlobal.shadowStyle]),
            onPressed: () async => await Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (context) => const InstructionScreen(pop: true))))
      ],
      leading: IconButton(
        splashColor: AppColor.kColorPeriLight,
        splashRadius: 14,
        icon: const Icon(Icons.close_rounded,
            size: 25, color: Colors.white, shadows: [AppGlobal.shadowStyle]),
        onPressed: () => Navigator.of(context).pop(),
      ),
    );

    flutterTts.setStartHandler(() {
      ///This is called when the audio starts
      if (mounted) setState(() => showVolumeSign = true);
    });

    flutterTts.setCompletionHandler(() {
      ///This is called when the audio ends
      if (mounted) {
        setState(() {
          showVolumeSign = false;
          playAudio = false;
        });
      }
    });

    getResults();
    // .then((_) {
    //   if (mounted) {
    //     showModalBottomSheet(
    //         barrierColor: Colors.black.withOpacity(0.2),
    //         backgroundColor: Colors.transparent,
    //         context: context,
    //         builder: (builder) => featureMenu(context));
    //   }
    // });
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    Fluttertoast.cancel();
    flutterTts.stop();
    super.dispose();
  }

  getResults() async {
    hasRecognized = false;
    hasTranslated = false;
    langSourceTag = getLangTag(0);
    langTargetTag = getLangTag(1);
    speechSourceTag = getSpeechTag(langSourceTag);
    speechTargetTag = getSpeechTag(langTargetTag);
    translatedTextList.clear();
    romanizedTextList.clear();
    recognizedText = '';
    translatedText = '';
    romanizedText = '';
    showOverlay = true;
    showRomanized = false;
    showVolumeSign = false;
    playAudio = false;
    withRomanization = langTargetTag == AppLanguage.zh;
    frameColors.clear();

    final textRecognizer = GoogleMlKit.vision.textDetectorV2();
    // inputText = await textRecognizer.processImage(inputImage,
    //     script: TextRecognitionOptions.KOREAN);
    inputText = await textRecognizer.processImage(inputImage,
        script: TextRecognitionOptions.CHINESE);
    if (!mounted) return;
    await textRecognizer.close();
    if (!mounted) return;
    if (mounted) setState(() => hasRecognized = true);

    String lineText;
    String outputText;
    String convertedText;

    //translate recognized text by block to assure a sound translation
    for (TextBlock block in inputText.blocks) {
      for (TextLine line in block.lines) {
        // List<Offset> points = line.cornerPoints;
        // List<Color> colors = extractPixelsColors(
        //     imageBytes, topLeft, topRight, bottomLeft, bottomRight);

        // frameColor =
        //     generator.darkVibrantColor ?? PaletteColor(Colors.black, 2);

        // List<Color> colors = extractPixelsColors(
        //     imageBytes,
        //     imagelib.Point(points[3].dx, points[3].dy),
        //     imagelib.Point(points[2].dx, points[2].dy),
        //     imagelib.Point(points[0].dx, points[0].dy),
        //     imagelib.Point(points[1].dx, points[1].dy));
        // colors = sortColors(colors);
        // halfLength = (colors.length ~/ 2);
        // Color color1 = getAverageColor(colors, 0, halfLength);
        // Color color2 = getAverageColor(colors, halfLength, colors.length);
        // frameColors.add([color1, color2]);
        lineText = line.text;
        final OnDeviceTranslator translator = GoogleMlKit.nlp
            .onDeviceTranslator(
                sourceLanguage: getLangTag(0), targetLanguage: getLangTag(1));

        outputText = await translator.translateText(lineText);
        if (!mounted) return;
        translator.close();

        if (mounted) {
          setState(() {
            recognizedText += '$lineText ';
            translatedText += '$outputText ';
            translatedTextList.add(outputText);

            if (withRomanization) {
              convertedText = PinyinHelper.getPinyinE(outputText,
                  separator: " ", format: PinyinFormat.WITH_TONE_MARK);
              romanizedText += '$convertedText ';
              romanizedTextList.add(convertedText);
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

    if (mounted) setState(() => hasTranslated = true);
  }

  Future<ui.Image> convertToUIImage(File file) async {
    final data = await file.readAsBytes();
    return await decodeImageFromList(data);
  }

  @override
  Widget build(BuildContext context) {
    if (mounted) {
      if (langSourceTag != context.watch<SourceLanguageChanger>().tag ||
          langTargetTag != context.watch<TargetLanguageChanger>().tag) {
        getResults();
      }
    }
    getImageDimensions();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: appBar,
      floatingActionButton: Container(
          padding: EdgeInsets.only(bottom: (AppGlobal.screenHeight * 0.08)),
          alignment: Alignment.bottomRight,
          child: SpeedDial(
            backgroundColor: AppColor.kColorPeriDarkest,
            spacing: 3,
            spaceBetweenChildren: 3,
            closeManually: true,
            openCloseDial: isDialOpen,

            onPress: () => {
              if (!hasTranslated)
                {
                  isDialOpen.value = false,
                }
              else
                {
                  recognizedText == ''
                      ? {
                          isDialOpen.value = false,
                          showToast(
                              'No text detected. The image\nmay be too dark or blurry.'),
                        }
                      : isDialOpen.value = true
                }
            },
            // buttonSize: const Size(45, 45),
            // spacing: 12,
            // elevation: AppGlobal.screenHeight * 0.08,
            animatedIcon: AnimatedIcons.menu_close,
            overlayColor: AppColor.kColorPeriDarkest,
            overlayOpacity: 0.2,
            children: [
              SpeedDialChild(
                  child: Icon(Features.toggle.icon,
                      color: AppColor.kColorPeriLightest),
                  backgroundColor: AppColor.kColorPeriDarker,
                  // label: Features.toggle.text,
                  onTap: () {
                    if (mounted) {
                      setState(() => showOverlay = !showOverlay);
                    }
                  }),
              SpeedDialChild(
                  child: Icon(Features.change.icon,
                      color: AppColor.kColorPeriLightest),
                  backgroundColor: AppColor.kColorPeriDark,
                  // label: Features.change.text,
                  onTap: () {
                    if (withRomanization) {
                      if (mounted) {
                        setState(() => showRomanized = !showRomanized);
                      }
                    } else {
                      showToast(
                          'Not applicable. Target\nlanguage is not Chinese.');
                    }
                  }),
              SpeedDialChild(
                  child: Icon(Features.copy.icon,
                      color: AppColor.kColorPeriLightest),
                  backgroundColor: AppColor.kColorPeri,
                  // label: Features.copy.text,
                  onTap: () {
                    if (showOverlay) {
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

                    Clipboard.setData(ClipboardData(text: copiedText))
                        .then((_) {
                      return showToast('$textLabel text copied');
                    });
                  }),
              SpeedDialChild(
                  child: Icon(Features.listen.icon,
                      color: AppColor.kColorPeriLightest),
                  backgroundColor: AppColor.kColorPeriLight,
                  // label: Features.listen.text,
                  onTap: () {
                    if (mounted) setState(() => playAudio = true);

                    () async {
                      if (!showOverlay) {
                        flutterTts.setLanguage(speechSourceTag);
                        await flutterTts.speak(recognizedText);
                      } else {
                        flutterTts.setLanguage(speechTargetTag);
                        await flutterTts.speak(translatedText);
                      }
                    }();
                  }),
              SpeedDialChild(
                  child: Icon(Features.save.icon,
                      color: AppColor.kColorPeriLightest),
                  backgroundColor: AppColor.kColorPeriLighter,
                  // label: Features.save.text,
                  onTap: () {
                    () async {
                      if (!showOverlay) {
                        textLabel = 'Original';
                        await GallerySaver.saveImage(widget.inputImage.path);
                      } else {
                        showRomanized
                            ? textLabel = 'Romanized'
                            : textLabel = 'Translated';

                        RenderRepaintBoundary boundary =
                            globalKey.currentContext?.findRenderObject()
                                as RenderRepaintBoundary;
                        ui.Image image = await boundary.toImage();

                        // Uint8List pngBytes = byteData.buffer.asUint8List();

                        ByteData? byteData = await image.toByteData(
                            format: ui.ImageByteFormat.png);

                        await ImageGallerySaver.saveImage(
                            byteData!.buffer.asUint8List());
                      }
                      if (!mounted) return;

                      showToast('$textLabel image saved');
                    }();
                  }),
            ],
          )),
      // The image is stored as a file on the device. Use the `Image.file`
      // constructor with the given path to display the image.
      // floatingActionButton: ,
      body: Stack(children: [
        SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height * 0.92,
            child: ClipRRect(
                // clipBehavior: Clip.,
                borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20)),
                child: Container(
                    color: AppColor.kColorPeriLighter,
                    child: Stack(children: [
                      !hasTranslated
                          ? Stack(children: [
                              imageDisplay(),
                              const Center(
                                  child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColor.kColorPeriLight),
                              ))
                            ])
                          : InteractiveViewer(
                              // clipBehavior: ui.Clip.hardEdge,
                              boundaryMargin:
                                  const EdgeInsets.all(double.infinity),
                              maxScale: 4,
                              minScale: 0.5,
                              child: !showOverlay
                                  ? imageDisplay()
                                  : widget.index == 0
                                      ? Center(child: overlayDisplay())
                                      : Align(
                                          alignment: Alignment.topCenter,
                                          child: overlayDisplay())),
                      !playAudio
                          ? Container()
                          : showVolumeSign
                              ? volumeSign()
                              : loadingSign(),
                    ])))),

        // Column(mainAxisAlignment: MainAxisAlignment.end, children: [
        //   GestureDetector(
        //       onVerticalDragStart: (DragStartDetails details) {
        //         if (mounted) {
        //           showModalBottomSheet(
        //               barrierColor: Colors.black.withOpacity(0.2),
        //               backgroundColor: Colors.transparent,
        //               context: context,
        //               builder: (context) => featureMenu(context));
        //         }
        //       },
        Container(alignment: Alignment.bottomCenter, child: const LanguageBar())
        // ),
        // ])
      ]),
    );
  }

  Future showToast(String message) async {
    await Fluttertoast.cancel();

    Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.TOP,
        fontSize: 10,
        backgroundColor: AppColor.kColorPeriDarkestOp,
        textColor: Colors.white);
  }

  FittedBox overlayDisplay() {
    return FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox(
            width: imageWidth.toDouble(),
            height: imageHeight.toDouble(),
            child: RepaintBoundary(
                key: globalKey,
                child: Stack(children: [
                  imageDisplay(),
                  CustomPaint(
                      painter: BoxPainter(
                    File(widget.inputImage.path),
                    inputText,
                  )),
                  showRomanized
                      ? CustomPaint(painter: RomanizationPainter(inputText))
                      : CustomPaint(painter: TranslationPainter(inputText))
                ]))));
  }

  Widget imageDisplay() {
    return widget.index == 0
        ? Center(child: image)
        : Align(alignment: Alignment.topCenter, child: image);
  }

  Widget loadingSign() => Align(
      alignment: Alignment.topRight,
      child: Container(
          width: 50,
          height: 50,
          alignment: Alignment.center,
          margin:
              EdgeInsets.only(top: appBar.preferredSize.height + 20, right: 20),
          padding: const EdgeInsets.all(10),
          decoration: const BoxDecoration(
              shape: BoxShape.circle, color: Colors.white70),
          child: const SizedBox(
              width: 20, height: 20, child: CircularProgressIndicator())));

  Widget volumeSign() => Align(
      alignment: Alignment.topRight,
      child: Container(
          width: 50,
          height: 50,
          alignment: Alignment.center,
          margin:
              EdgeInsets.only(top: appBar.preferredSize.height + 20, right: 20),
          padding: const EdgeInsets.all(10),
          decoration: const BoxDecoration(
              shape: BoxShape.circle, color: Colors.white70),
          child: const Icon(
            Icons.volume_up_rounded,
            size: 30,
            color: AppColor.kColorPeriLight,
          )));

  getLangTag(int index) {
    if (mounted) {
      return index == 0
          ? context.read<SourceLanguageChanger>().tag
          : context.read<TargetLanguageChanger>().tag;
    }
    return;
  }

  getSpeechTag(String langTag) {
    return langTag == AppLanguage.en
        ? 'en-US'
        : langTag == AppLanguage.tl
            ? 'fil-PH'
            : 'zh-CN';
  }
}

class BoxPainter extends CustomPainter {
  BoxPainter(this.fileImage, this.inputText);
  final RecognisedText inputText;
  final File fileImage;
  late Uint8List bytes;
  // final ui.PictureRecorder recorder = ui.PictureRecorder();
  int counter = 0;
  late ByteData uiBytes;

  @override
  Future<void> paint(ui.Canvas canvas, ui.Size size) async {
    bytes = fileImage.readAsBytesSync();
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = AppColor.kColorPeriDarkest;
    // canvas = Canvas(recorder);
    // canvasCopy = Canvas(recorder);

    // canvas.drawImage(uiImage, Offset.zero, paint);
    // debugPrint("weh ${uiImage.width} ${uiImage.height}");
    for (TextBlock block in inputText.blocks) {
      for (TextLine line in block.lines) {
        List<Offset> points = line.cornerPoints;
        // final PaletteGenerator generator =
        //     await PaletteGenerator.fromImageProvider(
        //   FileImage(fileImage),
        //   maximumColorCount: 2,
        // );

        // frameColor =
        //     generator.darkVibrantColor ?? PaletteColor(Colors.black, 2);
        // List<Color> colors = extractPixelsColors(
        //     bytes, points[3], points[2], points[0], points[1]);
        // colors = sortColors(colors);
        // Color frameColor = getAverageColor(colors);
        // debugPrint("weh $frameColor");
        final Path rectangle = Path();
        rectangle.moveTo(points[0].dx, points[0].dy);
        rectangle.lineTo(points[1].dx, points[1].dy);
        rectangle.lineTo(points[2].dx, points[2].dy);
        rectangle.lineTo(points[3].dx, points[3].dy);

        // paint.color = Color(abgrToArgb(imageLibImage!
        // .getPixel(points[2].dx.toInt(), points[2].dy.toInt())));
        canvas.drawPath(rectangle, paint);
      }
    }
    counter = 0;
  }

  int abgrToArgb(int argbColor) {
    int r = (argbColor >> 16) & 0xFF;
    int b = argbColor & 0xFF;
    return (argbColor & 0xFF00FF00) | (b << 16) | r;
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

double findAngle(Offset p1, Offset p2) {
  final double deltaY = (p2.dy - p1.dy);
  final double deltaX = (p2.dx - p1.dx);
  final double result = atan2(deltaY, deltaX);
  return (result < 0) ? (6.283 + result) : result;
}

class TranslationPainter extends CustomPainter {
  TranslationPainter(this.inputText);
  final RecognisedText inputText;

  int counter = 0;
  @override
  Future<void> paint(ui.Canvas canvas, ui.Size size) async {
    // final translator = GoogleMlKit.nlp.onDeviceTranslator(
    //     sourceLanguage: langSourceTag, targetLanguage: langTargetTag);
    for (TextBlock block in inputText.blocks) {
      for (TextLine line in block.lines) {
        List<Offset> points = line.cornerPoints;

        double frameWidth = points[1].dx - points[0].dx;
        double frameHeight = points[3].dy - points[0].dy;
        double minimumFontScale = 0;

        final TextPainter textPainter = TextPainter(
            text: TextSpan(
              text: translatedTextList[counter],
              style: TextStyle(
                fontSize: frameHeight + 5,
                // color: frameColors[counter][1],
                color: Colors.white,
              ),
            ),
            textDirection: TextDirection.ltr,
            textScaleFactor: 1)
          ..layout();

        counter++;
        double textScaleFactor = 1;

        if (textPainter.height > frameHeight) {
          //
          debugPrint('${textPainter.size}');
          textPainter.textScaleFactor = minimumFontScale;
          textPainter.layout(maxWidth: frameWidth);
          debugPrint('${textPainter.size}');

          if (textPainter.height > frameHeight) {
            //
            //even minimum does not fit render it with minimum size
            debugPrint("Using minimum set font");
            textScaleFactor = minimumFontScale;
          } else if (minimumFontScale < 1) {
            //binary search for valid Scale factor
            int h = 100;
            int l = (minimumFontScale * 100).toInt();
            while (h > l) {
              int mid = (l + (h - l) / 2).toInt();
              double newScale = mid.toDouble() / 100.0;
              textPainter.textScaleFactor = newScale;
              textPainter.layout(maxWidth: frameWidth);

              if (textPainter.height > frameHeight) {
                //
                h = mid - 1;
              } else {
                l = mid + 1;
              }
              if (h <= l) {
                debugPrint('${textPainter.size}');
                textScaleFactor = newScale - 0.01;
                textPainter.textScaleFactor = newScale;
                textPainter.layout(maxWidth: frameWidth);
                break;
              }
            }
          }
        }

        textPainter.textScaleFactor = textScaleFactor;
        textPainter.layout(maxWidth: frameWidth);
        canvas.save();
        canvas.translate(points[0].dx, points[0].dy);
        debugPrint('weh weh 1');
        canvas.rotate(findAngle(points[0], points[1]));
        debugPrint('weh weh 2');
        canvas.translate(-points[0].dx, -points[0].dy);
        textPainter.paint(canvas, Offset(points[0].dx, points[0].dy));
        canvas.restore();
      }
    }
    counter = 0;
  }

  // final TextPainter textPainter = TextPainter(
  //   text: TextSpan(
  //     text: line.text,
  //     // style: TextStyle(fontSize: (points[3].dy - points[0].dy)),
  //   ),
  //   // textAlign: TextAlign.center,
  //   textDirection: TextDirection.ltr,
  //   maxLines: 1,
  // )..layout(
  //     minWidth: points[1].dx - points[0].dx,
  //     maxWidth: points[1].dx + points[0].dx,
  //   );
  // debugPrint(
  //     "weh${points[1].dx} - ${points[0].dx} = ${(points[1].dx - points[0].dx)}");
  // final textSpan = TextSpan(
  //   text: ' $title ',
  //   style: TextStyle(
  //     color: titleColor,
  //     fontSize: fontSize,
  //     height: 1.0,
  //     backgroundColor: backgroundColor,
  //   ),
  // );
  // final TextPainter textPainter = TextPainter(
  //     text: textSpan)
  //   ..layout(minWidth: 0, maxWidth: double.infinity);
  // debugPrint(textPainter.size); //the TextSpan width

// Size measure(String text, TextStyle style,
//       {int maxLines: 1, TextDirection direction = TextDirection.ltr, double maxWidth = double.infinity}) {
//     final TextPainter textPainter =
//         TextPainter(text: TextSpan(text: text, style: style), maxLines: maxLines, textDirection: direction)
//           ..layout(minWidth: 0, maxWidth: maxWidth);
//     return textPainter.size;
//   }
  // canvas.save();
  // final pivot = textPainter.size.center(const Offset(50, 50));
  // canvas.translate(pivot.dx, pivot.dy);
  // canvas.rotate(-0.1);
  // canvas.translate(-pivot.dx, -pivot.dy);
  // textPainter.paint(canvas, Offset(points[0].dx, points[0].dy));
  // canvas.restore();
  // }
  // }
  // translator.close();

  // double textSize(ui.Size size, List<Offset> points) {
  //   if (size.width > size.height) {
  //     return (points[1].dx - points[0].dx) / 100;
  //   }
  //   else {
  //     return
  //   }
  // }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class RomanizationPainter extends CustomPainter {
  RomanizationPainter(this.inputText);
  final RecognisedText inputText;

  int counter = 0;
  @override
  Future<void> paint(ui.Canvas canvas, ui.Size size) async {
    for (TextBlock block in inputText.blocks) {
      for (TextLine line in block.lines) {
        List<Offset> points = line.cornerPoints;

        double frameWidth = points[1].dx - points[0].dx;
        double frameHeight = points[3].dy - points[0].dy;
        double minimumFontScale = 0;

        final TextPainter textPainter = TextPainter(
            text: TextSpan(
              text: romanizedTextList[counter],
              style: TextStyle(fontSize: frameHeight, color: Colors.white
                  // color: frameColors[counter][1],
                  ),
            ),
            textDirection: TextDirection.ltr,
            textScaleFactor: 1)
          ..layout();

        counter++;
        double textScaleFactor = 1;

        if (textPainter.height > frameHeight) {
          //
          debugPrint('${textPainter.size}');
          textPainter.textScaleFactor = minimumFontScale;
          textPainter.layout(maxWidth: frameWidth);
          debugPrint('${textPainter.size}');

          if (textPainter.height > frameHeight) {
            //
            //even minimum does not fit render it with minimum size
            debugPrint("weh 1");
            textScaleFactor = minimumFontScale;
          } else if (minimumFontScale < 1) {
            debugPrint("weh 2");

            //binary search for valid Scale factor
            int h = 100;
            int l = (minimumFontScale * 100).toInt();
            while (h > l) {
              int mid = (l + (h - l) / 2).toInt();
              double newScale = mid.toDouble() / 100.0;
              textPainter.textScaleFactor = newScale;
              textPainter.layout(maxWidth: frameWidth);

              if (textPainter.height > frameHeight) {
                //
                h = mid - 1;
              } else {
                l = mid + 1;
              }
              if (h <= l) {
                debugPrint('${textPainter.size}');
                textScaleFactor = newScale - 0.01;
                textPainter.textScaleFactor = newScale;
                textPainter.layout(maxWidth: frameWidth);
                break;
              }
            }
          }
        }

        textPainter.textScaleFactor = textScaleFactor;
        textPainter.layout(maxWidth: frameWidth);
        canvas.save();
        canvas.translate(points[0].dx, points[0].dy);
        canvas.rotate(findAngle(points[0], points[1]));
        canvas.translate(-points[0].dx, -points[0].dy);
        textPainter.paint(canvas, Offset(points[0].dx, points[0].dy));
        canvas.restore();
      }
    }
    counter = 0;
  }

  // final TextPainter textPainter = TextPainter(
  //   text: TextSpan(
  //     text: line.text,
  //     // style: TextStyle(fontSize: (points[3].dy - points[0].dy)),
  //   ),
  //   // textAlign: TextAlign.center,
  //   textDirection: TextDirection.ltr,
  //   maxLines: 1,
  // )..layout(
  //     minWidth: points[1].dx - points[0].dx,
  //     maxWidth: points[1].dx + points[0].dx,
  //   );
  // debugPrint(
  //     "weh${points[1].dx} - ${points[0].dx} = ${(points[1].dx - points[0].dx)}");
  // final textSpan = TextSpan(
  //   text: ' $title ',
  //   style: TextStyle(
  //     color: titleColor,
  //     fontSize: fontSize,
  //     height: 1.0,
  //     backgroundColor: backgroundColor,
  //   ),
  // );
  // final TextPainter textPainter = TextPainter(
  //     text: textSpan)
  //   ..layout(minWidth: 0, maxWidth: double.infinity);
  // debugPrint(textPainter.size); //the TextSpan width

// Size measure(String text, TextStyle style,
//       {int maxLines: 1, TextDirection direction = TextDirection.ltr, double maxWidth = double.infinity}) {
//     final TextPainter textPainter =
//         TextPainter(text: TextSpan(text: text, style: style), maxLines: maxLines, textDirection: direction)
//           ..layout(minWidth: 0, maxWidth: maxWidth);
//     return textPainter.size;
//   }
  // canvas.save();
  // final pivot = textPainter.size.center(const Offset(50, 50));
  // canvas.translate(pivot.dx, pivot.dy);
  // canvas.rotate(-0.1);
  // canvas.translate(-pivot.dx, -pivot.dy);
  // textPainter.paint(canvas, Offset(points[0].dx, points[0].dy));
  // canvas.restore();
  // }
  // }
  // translator.close();

  // double textSize(ui.Size size, List<Offset> points) {
  //   if (size.width > size.height) {
  //     return (points[1].dx - points[0].dx) / 100;
  //   }
  //   else {
  //     return
  //   }
  // }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// //无法转换拼音会 throw PinyinException
//         romanizedText = PinyinHelper.getPinyin(recognizedText);
//         debugPrint("weh 1 $romanizedText");

//         romanizedText = PinyinHelper.getPinyin(recognizedText,
//             separator: " ",
//             format: PinyinFormat.WITHOUT_TONE); //tian fu guang chang
//         debugPrint("weh 2 $romanizedText");

// //无法转换拼音 默认用' '替代
//         romanizedText = PinyinHelper.getPinyinE(recognizedText);
//         debugPrint("weh 3 $romanizedText");

//         romanizedText = PinyinHelper.getPinyinE(recognizedText,
//             separator: " ",
//             defPinyin: '#',
//             format: PinyinFormat.WITHOUT_TONE); //tian fu guang chang
//         debugPrint("weh 4 $romanizedText");
