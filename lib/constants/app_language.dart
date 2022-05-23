import 'package:google_mlkit_translation/google_mlkit_translation.dart';

abstract class AppLanguage {
  //for popup menu
  static const chinese = 'Chinese';
  static const english = 'English';
  static const filipino = 'Filipino';

  //for translation
  static const zhTag = TranslateLanguage.chinese;
  static const enTag = TranslateLanguage.english;
  static const tlTag = TranslateLanguage.tagalog;

  static TranslateLanguage getTag(String language) {
    if (language == AppLanguage.chinese) return AppLanguage.zhTag;
    if (language == AppLanguage.english) return AppLanguage.enTag;
    return AppLanguage.tlTag;
  }
}
