import 'package:transalin/classes/language.dart';
import 'package:transalin/constants/app_language.dart';

class Languages {
  static const chinese =
      Language(icon: 'assets/icon/china_flag.png', text: AppLanguage.chinese);
  static const english =
      Language(icon: 'assets/icon/uk_flag.png', text: AppLanguage.english);
  static const filipino = Language(
      icon: 'assets/icon/philippines_flag.png', text: AppLanguage.filipino);

  static const List<Language> languages = [chinese, english, filipino];
}
