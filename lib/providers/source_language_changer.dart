import 'package:flutter/foundation.dart';
import 'package:transalin/constants/app_language.dart';

class SourceLanguageChanger extends ChangeNotifier {
  // String _language = 'Detect';
  String _language = AppLanguage.chinese;
  String get language => _language;
  String _tag = AppLanguage.zh;
  String get tag => _tag;

  change(String selectedLanguage) {
    _language = selectedLanguage;
    _tag = AppLanguage.getTag(selectedLanguage);
    notifyListeners();
  }
}
