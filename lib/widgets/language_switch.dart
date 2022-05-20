import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
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
          if (AppGlobal.inOutputScreen && !AppGlobal.hasTranslated) {
            () async {
              await Fluttertoast.cancel();

              Fluttertoast.showToast(
                  msg:
                      'Already processing. Try\nchanging the language again later.',
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.TOP,
                  fontSize: 10,
                  backgroundColor: AppColor.kColorPeriDarkest30,
                  textColor: AppColor.kColorWhite);
            }();
          } else {
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
          }
        },
        icon: const Icon(
          // Icons.autorenew,
          Icons.swap_horiz_rounded,
          color: AppColor.kColorPeriLightest,
          size: 30,
        ));
  }
}
