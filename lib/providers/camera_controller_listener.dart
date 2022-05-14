import 'package:flutter/foundation.dart';

class CameraControllerListener extends ChangeNotifier {
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  change(bool value) {
    _isInitialized = value;
    notifyListeners();
  }
}
