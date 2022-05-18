import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:transalin/constants/app_color.dart';
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
          if (sourceLanguage == 'Detect') {
            context.read<SourceLanguageChanger>().change(targetLanguage);
            context.read<TargetLanguageChanger>().change('Select');
          } else if (targetLanguage == 'Select') {
            context.read<TargetLanguageChanger>().change(sourceLanguage);
            context.read<SourceLanguageChanger>().change('Detect');
          } else {
            String tempLanguage = sourceLanguage;
            context.read<SourceLanguageChanger>().change(targetLanguage);
            context.read<TargetLanguageChanger>().change(tempLanguage);
          }
        },
        icon: const Icon(
          // Icons.autorenew,
          Icons.swap_horiz,
          color: AppColor.kColorPeriDarkest,
        ));
  }
}
