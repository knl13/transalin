import 'package:flutter/foundation.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:transalin/constants/app_language.dart';

class SourceLanguageChanger extends ChangeNotifier {
  //set initial source language to English
  String _language = AppLanguage.english;
  String get language => _language;

  //set the corresponding TranslateLanguage type
  TranslateLanguage _tag = AppLanguage.enTag;
  TranslateLanguage get tag => _tag;

  change(String selectedLanguage) {
    _language = selectedLanguage;
    _tag = AppLanguage.getTag(selectedLanguage);
    notifyListeners();
  }
}
