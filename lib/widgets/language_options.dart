import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:transalin/classes/language.dart';
import 'package:transalin/classes/languages.dart';
import 'package:transalin/constants/app_color.dart';
import 'package:transalin/constants/app_global.dart';
import 'package:transalin/providers/source_language_changer.dart';
import 'package:transalin/providers/target_language_changer.dart';

class LanguageOptions extends StatefulWidget {
  const LanguageOptions({Key? key, required this.index}) : super(key: key);

  final int index;

  @override
  State<LanguageOptions> createState() => _LanguageOptionsState();
}

class _LanguageOptionsState extends State<LanguageOptions> {
  changeLanguage(int index, String selectedLanguage) {
    if (AppGlobal.inOutputScreen && !AppGlobal.hasTranslated) {
      () async {
        await Fluttertoast.cancel();

        Fluttertoast.showToast(
            msg: 'Already processing. Try\nchanging the language again later.',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.TOP,
            fontSize: 10,
            backgroundColor: AppColor.kColorPeriDarkestOp,
            textColor: Colors.white);
      }();
    } else {
      return index == 0
          ? context.read<SourceLanguageChanger>().change(selectedLanguage)
          : context.read<TargetLanguageChanger>().change(selectedLanguage);
    }
  }

  watchLanguage(int index) {
    return index == 0
        ? context.watch<SourceLanguageChanger>().language
        : context.watch<TargetLanguageChanger>().language;
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<Language>(
        color: AppColor.kColorPeriDarkest,
        constraints: const BoxConstraints(maxWidth: 155),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(10),
          ),
        ),
        offset: const Offset(0, -185),
        itemBuilder: (context) => [
              ...Languages.languages
                  .map((Language lang) => PopupMenuItem<Language>(
                      value: lang,
                      child: Row(children: [
                        Image.asset(
                          lang.icon,
                          height: 25,
                          width: 25,
                          fit: BoxFit.fitWidth,
                        ),
                        const SizedBox(width: 10),
                        Text(lang.text,
                            style: const TextStyle(
                                color: AppColor.kColorPeriLightest))
                      ])))
                  .toList()
            ],
        onSelected: (Language selectedLanguage) =>
            changeLanguage(widget.index, selectedLanguage.text),
        child: Text(
          watchLanguage(widget.index),
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColor.kColorPeriLightest),
        ));
  }
}
