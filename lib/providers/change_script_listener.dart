import 'package:flutter/foundation.dart';

class ChangeScriptListener extends ChangeNotifier {
  bool _withRomanization = false;
  bool get withRomanization => _withRomanization;

  change(bool value) {
    _withRomanization = value;
    notifyListeners();
  }
}
