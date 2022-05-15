import 'dart:async';
// import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:transalin/providers/camera_controller_listener.dart';
import 'package:transalin/screens/output_screen.dart';
import 'package:transalin/widgets/language_bar.dart';

late CameraController _controller;

//a screen that takes input from users through gallery or cameras
class InputScreen extends StatefulWidget {
  const InputScreen({Key? key, required this.cameras}) : super(key: key);

  final List<CameraDescription> cameras;

  @override
  InputScreenState createState() => InputScreenState();
}

class InputScreenState extends State<InputScreen> {
  late final CameraDescription camera;
  late Future<void> _initializeControllerFuture;
  bool isFlashOn = true;

  @override
  void initState() {
    camera = widget.cameras.first; //use first camera from the list
    // To display the current output from the Camera, create a CameraController.
    _controller = CameraController(
        // Get a specific cameras from the list of available cameras.
        camera,
        ResolutionPreset.max, // Define the resolution to use.
        enableAudio: false);

    _initializeControllerFuture = _controller.initialize();

    super.initState();
  }

  displayCameraView() {
    _initializeControllerFuture = _controller.initialize();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isControllerInitialized =
        context.watch<CameraControllerListener>().isInitialized;

    return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
            title: const Text('TranSalin',
                style: TextStyle(shadows: [
                  Shadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 0))
                ])),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0),
        // You must wait until the controller is initialized before displaying the
        // cameras preview. Use a FutureBuilder to display a loading spinner until the
        // controller has finished initializing.
        body: Stack(clipBehavior: Clip.none, children: [
          SizedBox(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height * 0.96,
              child: FutureBuilder<void>(
                future: _initializeControllerFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done &&
                      _controller.value.isInitialized) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      context.read<CameraControllerListener>().change(true);
                      !isFlashOn
                          ? _controller.setFlashMode(FlashMode.off)
                          : _controller.setFlashMode(FlashMode.always);
                    });

                    // If the Future is complete, display the preview.
                    return CameraPreview(_controller);
                  } else {
                    // Otherwise, display a loading indicator.
                    return Center(
                        child: TextButton(
                            child: const Text('Allow access to camera',
                                style: TextStyle(color: Colors.white)),
                            onPressed: () => displayCameraView()));
                  }
                },
              )),
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
                              color: Colors.white,
                              // icon: const Icon(Icons.add_to_photos),
                              icon: const Icon(Icons.collections),
                              onPressed: () async {
                                try {
                                  final XFile? inputImage = await ImagePicker()
                                      .pickImage(source: ImageSource.gallery);
                                  if (inputImage != null) {
                                    if (!mounted) return;
                                    await Navigator.of(context).push(
                                        MaterialPageRoute(
                                            builder: (context) => OutputScreen(
                                                index: 0,
                                                inputImage: inputImage)));
                                  }
                                } on PlatformException {
                                  // If an error occurs, log the error to the console.
                                }
                              }))),
                  Expanded(
                      child: isControllerInitialized
                          ? OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                    width: 3.0, color: Colors.white),
                                shape: const CircleBorder(),
                                padding: const EdgeInsets.all(3.0),
                              ),
                              child: const Icon(
                                Icons.circle,
                                size: 50,
                                color: Colors.white,
                              ),
                              onPressed: () async {
                                // Take the Picture in a try / catch block. If anything goes wrong,
                                // catch the error.
                                try {
                                  // Ensure that the cameras is initialized.
                                  await _initializeControllerFuture;

                                  // Attempt to take a picture and get the file `image`
                                  // where it was saved.
                                  final XFile inputImage =
                                      await _controller.takePicture();

                                  // If the picture was taken, display it on a new screen.
                                  // ignore: use_build_context_synchronously
                                  await Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => OutputScreen(
                                        // Pass the automatically generated path to
                                        // the OutputScreen widget.
                                        index: 1,
                                        inputImage: inputImage,
                                      ),
                                    ),
                                  );
                                } catch (e) {
                                  // If an error occurs, log the error to the console.
                                  // debugPrint(e);
                                }
                              })
                          : const SizedBox(width: 30)),
                  Expanded(
                      child: isControllerInitialized
                          ? IconButton(
                              icon: !isFlashOn
                                  ? const Icon(Icons.flash_on)
                                  : const Icon(Icons.flash_off),
                              iconSize: 30,
                              color: Colors.white,
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
