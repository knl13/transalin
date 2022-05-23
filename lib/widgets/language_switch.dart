import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:transalin/constants/app_color.dart';
import 'package:transalin/constants/app_global.dart';
import 'package:transalin/providers/source_language_changer.dart';
import 'package:transalin/providers/target_language_changer.dart';

class LanguageSwitch extends StatelessWidget {
  const LanguageSwitch({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String sourceLanguage = context.watch<SourceLanguageChanger>().language;
    String targetLanguage = context.watch<TargetLanguageChanger>().language;

    return IconButton(
        onPressed: () {
          //deny language change when the recognizer and translator are still processing
          if (AppGlobal.inOutputScreen && !AppGlobal.hasTranslated) {
            AppGlobal.showToast(
                'Already processing. Try\nchanging the language again later.');
          } else {
            //switch languages
            String tempLanguage = sourceLanguage;
            context.read<SourceLanguageChanger>().change(targetLanguage);
            context.read<TargetLanguageChanger>().change(tempLanguage);
          }
        },
        icon: Icon(
          Icons.swap_horiz_rounded,
          color: AppColor.kColorPeriLightest,
          size: AppGlobal.screenWidth * 0.084,
        ));
  }
}
