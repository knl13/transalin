import 'package:flutter/foundation.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:transalin/constants/app_language.dart';

class SourceLanguageChanger extends ChangeNotifier {
  String _language =
      AppLanguage.english; //set initial source language to English
  String get language => _language;
  TranslateLanguage _tag =
      AppLanguage.en; //set the corresponding TranslateLanguage type
  TranslateLanguage get tag => _tag;

  change(String selectedLanguage) {
    _language = selectedLanguage;
    _tag = AppLanguage.getTag(selectedLanguage);
    notifyListeners();
  }
}
