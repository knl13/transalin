import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:transalin/constants/app_color.dart';
import 'package:transalin/constants/app_global.dart';
import 'package:transalin/providers/camera_controller_listener.dart';
import 'package:transalin/screens/instruction_screen.dart';
import 'package:transalin/screens/output_screen.dart';
import 'package:transalin/widgets/language_bar.dart';

late CameraController _controller;

//a screen that takes input from users through gallery or camera
class InputScreen extends StatefulWidget {
  const InputScreen({Key? key}) : super(key: key);

  @override
  InputScreenState createState() => InputScreenState();
}

class InputScreenState extends State<InputScreen> {
  late Future<void> _initializeControllerFuture;
  bool isFlashOn = false;

  @override
  void initState() {
    super.initState();
    //create a camera controller to display the current camera preview
    _controller = CameraController(
        AppGlobal.camera, //use the saved camera from the time the app started
        ResolutionPreset.max, //use the highest resolution available
        enableAudio: false); //audio is not needed

    _initializeControllerFuture = _controller.initialize();
  }

  displayCameraView() {
    //initialize the controller again if the user did not allow camera access at first
    _initializeControllerFuture = _controller.initialize();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller.dispose(); //dispose controller when the widget is disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //save screen width and height to catch if the app does not start at download screen
    AppGlobal.screenWidth = MediaQuery.of(context).size.width;
    AppGlobal.screenHeight = MediaQuery.of(context).size.height;

    bool isControllerInitialized = context
        .watch<CameraControllerListener>()
        .isInitialized; //watch if the camera has been granted access to show the shutter and flash buttons

    return Scaffold(
        extendBodyBehindAppBar: true,
        //title and help button
        appBar: AppBar(
          title: const Text('TranSalin',
              style: TextStyle(shadows: [AppGlobal.shadowStyle])),
          centerTitle: true,
          backgroundColor: AppColor.kColorTransparent,
          elevation: 0,
          actions: [
            //go to instruction screen if help button is clicked
            IconButton(
                splashColor: AppColor.kColorPeriLight,
                splashRadius: 14,
                icon: const Icon(Icons.help_outline_rounded,
                    size: 20,
                    color: AppColor.kColorWhite,
                    shadows: [AppGlobal.shadowStyle]),
                onPressed: () async => await Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (context) => const InstructionScreen(
                            pop:
                                true)))) //pop is true to go back to input screen
          ],
        ),
        body: Stack(children: [
          //container for allow camera access text button or camera preview
          SizedBox(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height * 0.92,
              child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20)),
                  child: Container(
                      color: AppColor.kColorPeriLighter,
                      child: FutureBuilder<void>(
                        future: _initializeControllerFuture,
                        builder: (context, snapshot) {
                          //the camera preview will only show if the controller has been successfully initialized
                          if (snapshot.connectionState ==
                                  ConnectionState.done &&
                              _controller.value.isInitialized) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              context.read<CameraControllerListener>().change(
                                  true); //update listener to display shutter and flash buttons
                              //update flash icon when the user turns it on or off
                              !isFlashOn
                                  ? _controller.setFlashMode(FlashMode.off)
                                  : _controller.setFlashMode(FlashMode.always);
                            });

                            return CameraPreview(_controller);
                          } else {
                            //display the allow camera access text button if the camera has not been initialized
                            return Center(
                                child: TextButton(
                                    child: const Text('Allow access to camera',
                                        style: TextStyle(
                                            color: AppColor.kColorPeriDark)),
                                    onPressed: () => displayCameraView()));
                          }
                        },
                      )))),
          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Expanded(
                      child: SizedBox(
                          height: 60,
                          child: IconButton(
                              iconSize: 30,
                              color: isControllerInitialized
                                  ? AppColor.kColorWhite
                                  : AppColor.kColorPeri,
                              //select image from gallery button
                              icon: const Icon(Icons.collections_rounded),
                              onPressed: () async {
                                try {
                                  final XFile? imageFile = await ImagePicker()
                                      .pickImage(source: ImageSource.gallery);
                                  if (imageFile != null) {
                                    if (!mounted) {
                                      return;
                                    } //catcher for when the user did not select any photo

                                    //give the image file to the output screen
                                    //the index determines the alignment of input image
                                    //0: coming from the camera, top align
                                    //1: coming from the gallery, center align
                                    await Navigator.of(context).push(
                                        MaterialPageRoute(
                                            builder: (context) => OutputScreen(
                                                index: 0,
                                                imageFile: imageFile)));
                                  }
                                } on PlatformException {
                                  // debugPrint(e);
                                }
                              }))),
                  Expanded(
                      child: isControllerInitialized
                          ? OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                    width: 3.0, color: AppColor.kColorWhite),
                                shape: const CircleBorder(),
                                padding: const EdgeInsets.all(1.0),
                              ),
                              child: const Icon(
                                Icons.circle_rounded,
                                size: 55,
                                color: AppColor.kColorWhite,
                              ),
                              onPressed: () async {
                                try {
                                  await _initializeControllerFuture;

                                  final XFile imageFile =
                                      await _controller.takePicture();

                                  //give the image file to the output screen
                                  //the index determines the alignment of input image
                                  //0: coming from the camera, top align
                                  //1: coming from the gallery, center align
                                  () async {
                                    await Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => OutputScreen(
                                          index: 1,
                                          imageFile: imageFile,
                                        ),
                                      ),
                                    );
                                  }();
                                } catch (e) {
                                  // debugPrint(e);
                                }
                              })
                          : const SizedBox(width: 30)),
                  Expanded(
                      //flash button
                      child: isControllerInitialized
                          ? IconButton(
                              icon: !isFlashOn
                                  ? const Icon(Icons.flash_on_rounded)
                                  : const Icon(Icons
                                      .flash_off_rounded), //change display depending on flash status
                              iconSize: 30,
                              color: AppColor.kColorWhite,
                              onPressed: () {
                                !isFlashOn
                                    ? setState(() => isFlashOn = true)
                                    : setState(() => isFlashOn = false);
                              },
                            )
                          : const SizedBox(width: 30))
                ],
              ),
              const LanguageBar()
            ],
          )
        ]));
  }
}
