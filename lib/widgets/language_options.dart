import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:transalin/classes/language.dart';
import 'package:transalin/classes/languages.dart';
import 'package:transalin/constants/app_color.dart';
import 'package:transalin/constants/app_global.dart';
import 'package:transalin/providers/source_language_changer.dart';
import 'package:transalin/providers/target_language_changer.dart';

class LanguageOptions extends StatefulWidget {
  const LanguageOptions({Key? key, required this.isSourceLanguage})
      : super(key: key);

  final bool isSourceLanguage; //0: source language; 1: target language

  @override
  State<LanguageOptions> createState() => _LanguageOptionsState();
}

class _LanguageOptionsState extends State<LanguageOptions> {
  //update to chosen language from the popup menu
  changeLanguage(bool isSourceLanguage, String selectedLanguage) {
    //deny language change when the recognizer and translator are still processing
    if (AppGlobal.inOutputScreen && !AppGlobal.hasTranslated) {
      AppGlobal.showToast(
          'Already processing. Try\nchanging the language again later.');
    } else {
      return isSourceLanguage
          ? context.read<SourceLanguageChanger>().change(selectedLanguage)
          : context.read<TargetLanguageChanger>().change(selectedLanguage);
    }
  }

  //listeners for language display in the language bar
  watchLanguage(bool isSourceLanguage) {
    return isSourceLanguage
        ? context.watch<SourceLanguageChanger>().language
        : context.watch<TargetLanguageChanger>().language;
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<Language>(
        color: AppColor.kColorPeriDarkest,
        constraints: BoxConstraints(maxWidth: AppGlobal.screenWidth * 0.4),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(20),
          ),
        ),
        offset: const Offset(0, 0),
        itemBuilder: (context) => [
              ...Languages.languages
                  .map((Language lang) => PopupMenuItem<Language>(
                      value: lang,
                      child: Row(children: [
                        Image.asset(
                          lang.icon,
                          height: AppGlobal.screenWidth * 0.07,
                          width: AppGlobal.screenWidth * 0.07,
                          fit: BoxFit.fitWidth,
                        ),
                        SizedBox(width: AppGlobal.screenWidth * 0.028),
                        Text(lang.text,
                            style: TextStyle(
                                color: AppColor.kColorPeriLightest,
                                fontSize: ((AppGlobal.screenHeight * 0.02) *
                                    (AppGlobal.screenWidth * 0.0027)))),
                      ])))
                  .toList()
            ],
        onSelected: (Language selectedLanguage) =>
            changeLanguage(widget.isSourceLanguage, selectedLanguage.text),
        child: Text(
          watchLanguage(widget.isSourceLanguage),
          textAlign: TextAlign.center,
          style: TextStyle(
              color: AppColor.kColorPeriLightest,
              fontSize: ((AppGlobal.screenHeight * 0.02) *
                  (AppGlobal.screenWidth * 0.0027))),
        ));
  }
}
