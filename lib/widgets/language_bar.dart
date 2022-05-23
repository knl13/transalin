import 'package:flutter/material.dart';
import 'package:transalin/constants/app_color.dart';
import 'package:transalin/constants/app_global.dart';
import 'package:transalin/widgets/language_options.dart';
import 'package:transalin/widgets/language_switch.dart';

class LanguageBar extends StatelessWidget {
  const LanguageBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        width: AppGlobal.screenWidth,
        height: AppGlobal.screenHeight * 0.08,
        margin: EdgeInsets.only(top: AppGlobal.screenHeight * 0.03),
        color: AppColor.kColorPeriDarkest,
        child: Row(children: const [
          Expanded(child: LanguageOptions(isSourceLanguage: true)),
          LanguageSwitch(),
          Expanded(child: LanguageOptions(isSourceLanguage: false)),
        ]));
  }
}
