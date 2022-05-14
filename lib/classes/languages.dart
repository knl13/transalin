import 'package:transalin/classes/language.dart';
import 'package:transalin/constants/app_language.dart';

class Languages {
  static const chinese =
      Language(icon: 'assets/images/china_flag.png', text: AppLanguage.chinese);
  static const english =
      Language(icon: 'assets/images/uk_flag.png', text: AppLanguage.english);
  static const filipino = Language(
      icon: 'assets/images/philippines_flag.png', text: AppLanguage.filipino);
  static const korean = Language(
      icon: 'assets/images/southkorea_flag.png', text: AppLanguage.korean);

  // static const List<Language> languages = [chinese, english, filipino];
  static const List<Language> languages = [chinese, english, filipino, korean];
}
