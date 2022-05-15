import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:math';
// import 'package:image/image.dart' as imagelib;

import 'package:camera/camera.dart';
import 'package:flutter/rendering.dart' hide BoxDecoration, BoxShadow;
import 'package:flutter/services.dart';
import 'package:flutter_inset_box_shadow/flutter_inset_box_shadow.dart';
import 'package:flutter/material.dart' hide BoxDecoration, BoxShadow;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:image_size_getter/file_input.dart' as isgfi;
import 'package:image_size_getter/image_size_getter.dart' as isg;
import 'package:lpinyin/lpinyin.dart';
import 'package:provider/provider.dart';
import 'package:transalin/classes/feature.dart';
import 'package:transalin/classes/features.dart';
import 'package:transalin/constants/app_language.dart';
import 'package:transalin/providers/source_language_changer.dart';
import 'package:transalin/providers/target_language_changer.dart';
import 'package:transalin/widgets/language_bar.dart';

List<String> translatedTextList = [];
List<String> romanizedTextList = [];
List<String> textDisplayList = [];
late ui.Image translatedImage;
late ui.Image romanizedImage;
late ui.Image uiImage;
late ui.Size sizeCopy;

// A widget that displays the picture taken by the user.
class OutputScreen extends StatefulWidget {
  const OutputScreen({Key? key, required this.index, required this.inputImage})
      : super(key: key);

  final int index;
  final XFile inputImage;

  @override
  OutputScreenState createState() => OutputScreenState();
}

class OutputScreenState extends State<OutputScreen> {
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
  late List<Offset>? cornerPoints;
  late Image image;
  late InputImage inputImage;
  late double screenWidth;
  late double screenHeight;

  late int imageWidth;
  late int imageHeight;
  late bool showOverlay;
  late bool showRomanized;
  late bool showVolumeSign;
  late bool playAudio;
  late String copiedText;
  late String textLabel;
  GlobalKey globalKey = GlobalKey();
  final FlutterTts flutterTts = FlutterTts();
  FToast ftoast = FToast();
  late bool withRomanization;

  AppBar appBar = AppBar(
    title: const Text('TranSalin',
        style: TextStyle(shadows: [
          Shadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, 0))
        ])),
    centerTitle: true,
    backgroundColor: Colors.transparent,
    elevation: 0,
    leading: const Icon(Icons.arrow_back, color: Colors.white, shadows: [
      Shadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, 0))
    ]),
  );

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

  @override
  void initState() {
    super.initState();
    image = Image.file(File(widget.inputImage.path));
    inputImage = InputImage.fromFilePath(widget.inputImage.path);
    convertToUIImage(File(widget.inputImage.path))
        .then((image) => uiImage = image);

    flutterTts.setStartHandler(() {
      ///This is called when the audio starts
      setState(() => showVolumeSign = true);
    });

    flutterTts.setCompletionHandler(() {
      ///This is called when the audio ends
      setState(() {
        showVolumeSign = false;
        playAudio = false;
      });
    });
    getResults().then((_) {
      showModalBottomSheet(
          barrierColor: Colors.black.withOpacity(0.2),
          backgroundColor: Colors.transparent,
          context: context,
          builder: (builder) => featureMenu(context));
    });
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

    final textRecognizer = GoogleMlKit.vision.textDetectorV2();
    // inputText = await textRecognizer.processImage(inputImage,
    //     script: TextRecognitionOptions.CHINESE);
    inputText = await textRecognizer.processImage(inputImage,
        script: TextRecognitionOptions.CHINESE);
    await textRecognizer.close();

    setState(() => hasRecognized = true);

    String lineText;
    String outputText;
    String convertedText;

    //translate recognized text by block to assure a sound translation
    for (TextBlock block in inputText.blocks) {
      for (TextLine line in block.lines) {
        lineText = line.text;
        final OnDeviceTranslator translator = GoogleMlKit.nlp
            .onDeviceTranslator(
                sourceLanguage: getLangTag(0), targetLanguage: getLangTag(1));

        outputText = await translator.translateText(lineText);
        translator.close();

        if (mounted) {
          setState(() {
            recognizedText += '$lineText ';
            translatedText += '$outputText ';
            convertedText = PinyinHelper.getPinyinE(lineText,
                separator: " ", format: PinyinFormat.WITH_TONE_MARK);
            romanizedText += '$convertedText ';
            translatedTextList.add(outputText);
            romanizedTextList.add(convertedText);
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
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;
    if (langSourceTag != context.watch<SourceLanguageChanger>().tag ||
        langTargetTag != context.watch<TargetLanguageChanger>().tag) {
      getResults();
      debugPrint('wew $withRomanization');
    }
    getImageDimensions();
    // recognizeText();
    // translateText();
    debugPrint('test test $hasRecognized $hasTranslated');
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: appBar,
      // The image is stored as a file on the device. Use the `Image.file`
      // constructor with the given path to display the image.
      body: Stack(children: [
        !hasTranslated
            ? Stack(children: [
                imageDisplay(),
                const Center(child: CircularProgressIndicator())
              ])
            : InteractiveViewer(
                maxScale: 4,
                child: !showOverlay
                    ? imageDisplay()
                    :
                    // showRomanized
                    // ?
                    Center(
                        child: FittedBox(
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
                                          ? CustomPaint(
                                              painter: RomanizationPainter(
                                                  inputText))
                                          :
                                          // const Center(child: Text("hello"))
                                          CustomPaint(
                                              painter:
                                                  TranslationPainter(inputText))
                                    ])))))),
        // : Center(
        //     child: FittedBox(
        //         fit: BoxFit.scaleDown,
        //         child: SizedBox(
        //             width: imageWidth.toDouble(),
        //             height: imageHeight.toDouble(),
        //             child: RepaintBoundary(
        //                 key: globalKey,
        //                 child: Stack(children: [
        //                   CustomPaint(
        //                       painter: BoxPainter(
        //                     File(widget.inputImage.path),
        //                     inputText,
        //                   )),
        //                   CustomPaint(
        //                       painter: TranslationPainter(
        // inputText, translatedTextList))
        // ]))))),
        !playAudio
            ? Container()
            : showVolumeSign
                ? volumeSign()
                : loadingSign(),
        Column(mainAxisAlignment: MainAxisAlignment.end, children: [
          GestureDetector(
              // onVerticalDragEnd: (DragEndDetails details) => {},
              onVerticalDragStart: (DragStartDetails details) =>
                  showModalBottomSheet(
                      barrierColor: Colors.black.withOpacity(0.2),
                      backgroundColor: Colors.transparent,
                      context: context,
                      builder: (context) => featureMenu(context)),
              child: const LanguageBar()),
        ])
      ]),
    );
  }

  SizedBox featureMenu(BuildContext context) {
    return SizedBox(
        height: screenHeight * 0.4,
        child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
          const LanguageBar(),
          Container(
              width: MediaQuery.of(context).size.width,
              padding: const EdgeInsets.only(top: 10.0),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                  width: 0.0,
                  color: Colors.white,
                ),
                boxShadow: [
                  BoxShadow(
                    inset: true,
                    color: Colors.grey.withOpacity(0.6),
                    blurStyle: BlurStyle.inner,
                    spreadRadius: -5.0,
                    blurRadius: 4,
                    offset: const Offset(0, 10), // changes position of shadow
                  ),
                ],
              ),
              child: Center(
                  child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                height: 5.0,
                width: 30.0,
                decoration: BoxDecoration(
                    color: Colors.grey[350],
                    borderRadius: const BorderRadius.all(Radius.circular(5.0))),
              ))),
          Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height * 0.12,
            decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                  width: 0.0,
                  color: Colors.white,
                )),
            child:

                // ListView.builder(
                // scrollDirection: Axis.horizontal,
                // itemCount: Features.features.length,
                // itemBuilder: (context, index) =>
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              ...Features.features.map((Feature feat) => buildFeature(feat))
            ]),
          ),
          // Container(
          //     padding: const EdgeInsets.only(left: 20, right: 20),
          //     width: MediaQuery.of(context).size.width,
          //     height: MediaQuery.of(context).size.height * 0.15,
          //     color: Colors.white,
          //     child: ListView(children: [
          //       Text("RECOGNIZED: $recognizedText"),
          //       Text("TRANSLATED: $translatedText"),
          //       Text("ROMANIZED: $romanizedText"),
          //     ]))
        ]));
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
              EdgeInsets.only(top: appBar.preferredSize.height + 10, right: 10),
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
              EdgeInsets.only(top: appBar.preferredSize.height + 10, right: 10),
          padding: const EdgeInsets.all(10),
          decoration: const BoxDecoration(
              shape: BoxShape.circle, color: Colors.white70),
          child: const Icon(
            Icons.volume_up,
            size: 30,
            color: Colors.blue,
          )));

  Widget buildFeature(Feature feat) => Container(
      margin: const EdgeInsets.only(left: 1.5, right: 1.5),
      child: Column(children: [
        ElevatedButton(
            style: ElevatedButton.styleFrom(
              primary: Colors.black,
              // side: const BorderSide(width: 3.0, color: Colors.white),
              shape: const CircleBorder(),

              padding: const EdgeInsets.all(10.0),
              // shape: RoundedRectangleBorder(
              //     borderRadius: BorderRadius.circular(18.0)),
              // side: const BorderSide(
              //   color: Colors.grey,
              //   width: 1.0,
              //   style: BorderStyle.solid,
            ),
            onPressed: () {
              if (feat == Features.toggle) {
                setState(() => showOverlay = !showOverlay);
              } else if (feat == Features.change) {
                if (withRomanization) {
                  setState(() => showRomanized = !showRomanized);
                } else {
                  Fluttertoast.showToast(
                      msg: '! Not applicable. Target language is not Chinese.',
                      toastLength: Toast.LENGTH_SHORT,
                      gravity: ToastGravity.CENTER,
                      backgroundColor: Colors.black45,
                      textColor: Colors.white);
                }
              } else if (feat == Features.copy) {
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

                Clipboard.setData(ClipboardData(text: copiedText)).then((_) {
                  return Fluttertoast.showToast(
                      msg: '$textLabel text copied',
                      toastLength: Toast.LENGTH_SHORT,
                      gravity: ToastGravity.CENTER,
                      backgroundColor: Colors.black45,
                      textColor: Colors.white);
                  // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  //   behavior: SnackBarBehavior.floating,
                  //   margin: const EdgeInsets.only(top: 10.0),
                  //   content: Text("$textLabel copied to clipboard"),
                  // )
                  // );
                });
              } else if (feat == Features.listen) {
                setState(() => playAudio = true);
                // debugPrint('weh $showVolumeSign');
                // ftoast.init(context);

                // ftoast.showToast(
                //     child: const Material(
                //         color: Colors.black45,
                //         child: Icon(Icons.volume_up, color: Colors.white)));
                () async {
                  if (!showOverlay) {
                    flutterTts.setLanguage(speechSourceTag);
                    await flutterTts.setPitch(1);
                    await flutterTts.speak(recognizedText);
                  } else {
                    if (showRomanized) {
                      flutterTts.setLanguage('zh-CN');
                      await flutterTts.setPitch(1);
                      await flutterTts.speak(romanizedText);
                    } else {
                      flutterTts.setLanguage(speechTargetTag);
                      await flutterTts.setPitch(1);
                      await flutterTts.speak(translatedText);
                    }
                  }
                }();
                // debugPrint('weh $showVolumeSign');

                // ftoast.removeCustomToast();
              } else if (feat == Features.save) {
                () async {
                  if (!showOverlay) {
                    textLabel = 'Original';
                    await GallerySaver.saveImage(widget.inputImage.path);
                  } else {
                    showRomanized
                        ? textLabel = 'Romanized'
                        : textLabel = 'Translated';

                    RenderRepaintBoundary boundary = globalKey.currentContext
                        ?.findRenderObject() as RenderRepaintBoundary;
                    ui.Image image = await boundary.toImage();
                    // Uint8List pngBytes = byteData.buffer.asUint8List();

                    ByteData? byteData =
                        await image.toByteData(format: ui.ImageByteFormat.png);

                    await ImageGallerySaver.saveImage(
                        byteData!.buffer.asUint8List());
                  }

                  Fluttertoast.showToast(
                      msg: '$textLabel image saved',
                      toastLength: Toast.LENGTH_SHORT,
                      gravity: ToastGravity.CENTER,
                      backgroundColor: Colors.black45,
                      textColor: Colors.white);
                }();
              }
            },
            child: Icon(
              feat.icon,
              size: 30,
              color: Colors.white,
            )),
        const SizedBox(height: 5),
        Text(
          feat.text,
          style: const TextStyle(color: Colors.black, fontSize: 8),
          textAlign: TextAlign.center,
        )
      ]));

  void recognizeText() async {
    final textRecognizer = GoogleMlKit.vision.textDetectorV2();
    // inputText = await textRecognizer.processImage(inputImage,
    //     script: TextRecognitionOptions.CHINESE);
    inputText = await textRecognizer.processImage(inputImage,
        script: TextRecognitionOptions.CHINESE);
    await textRecognizer.close();

    setState(() => hasRecognized = true);
  }

  void translateText() async {
    String lineText;
    String outputText;
    recognizedText = '';
    translatedText = '';
    romanizedText = '';

    //translate recognized text by block to assure a sound translation
    for (TextBlock block in inputText.blocks) {
      // for (TextLine line in block.lines) {
      lineText = block.text;
      final OnDeviceTranslator translator = GoogleMlKit.nlp.onDeviceTranslator(
          sourceLanguage: AppLanguage.ko, targetLanguage: AppLanguage.tl);

      outputText = await translator.translateText(lineText);
      translator.close();

      if (mounted) {
        setState(() {
          recognizedText += '$lineText ';
          translatedText += '$outputText ';
          romanizedText +=
              '${PinyinHelper.getPinyinE(recognizedText, separator: " ", defPinyin: '#', format: PinyinFormat.WITHOUT_TONE)} ';
        });
      }
    }

    debugPrint("test 1 $recognizedText");
    debugPrint("test 2 $translatedText");
    debugPrint("test 3 $romanizedText");
    if (mounted) setState(() => hasTranslated = true);
  }

  getLangTag(int index) {
    if (mounted) {
      return index == 0
          ? context.read<SourceLanguageChanger>().tag
          : context.read<TargetLanguageChanger>().tag;
    }
    return '';
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

// image lib uses uses KML color format, convert #AABBGGRR to regular #AARRGGBB
  // int abgrToArgb(int argbColor) {
  //   int r = (argbColor >> 16) & 0xFF;
  //   int b = argbColor & 0xFF;
  //   return (argbColor & 0xFF00FF00) | (b << 16) | r;
  // }

  // Color getFlutterColor(int abgr) {
  //   int argb = abgrToArgb(abgr);
  //   return Color(argb);
  // }

  // List<Color> extractPixelsColors(
  //     Uint8List bytes, topLeft, topRight, bottomLeft, bottomRight) {
  //   imagelib.Image croppedImage;
  //   List<Color> colors = [];

  //   List<int> values = bytes.buffer.asUint8List();
  //   imagelib.Image? image = imagelib.decodeImage(values);

  //   if (image != null) {
  //     croppedImage = imagelib.copyRectify(image,
  //         topLeft: topLeft,
  //         topRight: topRight,
  //         bottomLeft: bottomLeft,
  //         bottomRight: bottomRight);

  //     List<int> pixels = [];

  //     int width = croppedImage.width;
  //     int height = croppedImage.height;

  //     for (int j = 1; j < height + 1; j++) {
  //       for (int i = 1; i < width + 1; i++) {
  //         int pixel = croppedImage.getPixel(i, j);
  //         pixels.add(pixel);
  //         colors.add(getFlutterColor(pixel));
  //       }
  //     }
  //   }

  //   return colors;
  // }

  // List<Color> sortColors(List<Color> colors) {
  //   List<Color> sorted = [];

  //   sorted.addAll(colors);
  //   sorted.sort((a, b) => b.computeLuminance().compareTo(a.computeLuminance()));

  //   return sorted;
  // }

  // Color getAverageColor(List<Color> colors) {
  //   int r = 0, g = 0, b = 0;

  //   for (int i = 0; i < colors.length; i++) {
  //     r += colors[i].red;
  //     g += colors[i].green;
  //     b += colors[i].blue;
  //   }

  //   r = r ~/ colors.length;
  //   g = g ~/ colors.length;
  //   b = b ~/ colors.length;

  //   return Color.fromRGBO(r, g, b, 1);
  // }

  @override
  Future<void> paint(ui.Canvas canvas, ui.Size size) async {
    bytes = fileImage.readAsBytesSync();
    final paint = Paint()..style = PaintingStyle.fill;
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

        // paint.color = frameColor;
        canvas.drawPath(rectangle, paint);
      }
    }
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
        // String outputText = await translator.translateText(line.text);

        double frameWidth = points[1].dx - points[0].dx;
        double frameHeight = points[3].dy - points[0].dy;
        double minimumFontScale = 0;

        final TextPainter textPainter = TextPainter(
            text: TextSpan(
              text: translatedTextList[counter],
              style: TextStyle(
                fontSize: frameHeight + 10,
                // color: frameColor.titleTextColor
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

class RomanizationPainter extends CustomPainter {
  RomanizationPainter(this.inputText);
  final RecognisedText inputText;

  int counter = 0;
  @override
  Future<void> paint(ui.Canvas canvas, ui.Size size) async {
    // final translator = GoogleMlKit.nlp.onDeviceTranslator(
    //     sourceLanguage: langSourceTag, targetLanguage: langTargetTag);
    for (TextBlock block in inputText.blocks) {
      for (TextLine line in block.lines) {
        List<Offset> points = line.cornerPoints;
        // String outputText = await translator.translateText(line.text);

        double frameWidth = points[1].dx - points[0].dx;
        double frameHeight = points[3].dy - points[0].dy;
        double minimumFontScale = 0;

        final TextPainter textPainter = TextPainter(
            text: TextSpan(
              text: romanizedTextList[counter],
              style: TextStyle(
                fontSize: frameHeight,
                // color: frameColor.titleTextColor
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
