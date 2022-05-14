import 'package:flutter/foundation.dart';
import 'package:transalin/constants/app_language.dart';

class TargetLanguageChanger extends ChangeNotifier {
  String _language = AppLanguage.filipino;
  String get language => _language;
  String _tag = AppLanguage.tl;
  String get tag => _tag;

  change(String selectedLanguage) {
    _language = selectedLanguage;
    _tag = AppLanguage.getTag(selectedLanguage);
    notifyListeners();
  }
}
