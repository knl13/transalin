abstract class AppLanguage {
  static const zh = 'zh';
  static const en = 'en';
  static const tl = 'tl';
  static const ko = 'ko';
  static const chinese = 'Chinese';
  static const english = 'English';
  static const filipino = 'Filipino';
  static const korean = 'Korean';

  static String getTag(String language) {
    if (language == AppLanguage.chinese) return AppLanguage.zh;
    if (language == AppLanguage.english) return AppLanguage.en;
    if (language == AppLanguage.filipino) return AppLanguage.tl;
    if (language == AppLanguage.korean) return AppLanguage.ko;
    return '';
  }
}
