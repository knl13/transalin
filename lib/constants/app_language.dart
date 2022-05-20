import 'package:google_mlkit_translation/google_mlkit_translation.dart';

abstract class AppLanguage {
  static const zh = TranslateLanguage.chinese;
  static const en = TranslateLanguage.english;
  static const tl = TranslateLanguage.tagalog;
  static const chinese = 'Chinese';
  static const english = 'English';
  static const filipino = 'Filipino';

  static TranslateLanguage getTag(String language) {
    if (language == AppLanguage.chinese) return AppLanguage.zh;
    if (language == AppLanguage.english) return AppLanguage.en;
    return AppLanguage.tl;
  }
}
