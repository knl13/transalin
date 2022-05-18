import 'package:flutter/material.dart';
import 'package:transalin/constants/app_color.dart';
import 'package:transalin/widgets/language_options.dart';
import 'package:transalin/widgets/language_switch.dart';

class LanguageBar extends StatelessWidget {
  const LanguageBar({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height * 0.08,
        margin: const EdgeInsets.only(top: 20),
        decoration: const BoxDecoration(
            color: AppColor.kColorPeriLightest,
            borderRadius: BorderRadius.only(
                // topLeft: Radius.circular(20),
                // topRight: Radius.circular(20),
                )),
        child: Row(children: const [
          Expanded(child: LanguageOptions(index: 0)),
          LanguageSwitch(),
          Expanded(child: LanguageOptions(index: 1)),
        ]));
  }
}
