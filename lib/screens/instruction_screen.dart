import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:transalin/classes/instruction.dart';
import 'package:transalin/classes/instructions.dart';
import 'package:transalin/constants/app_color.dart';
import 'package:transalin/constants/app_global.dart';
import 'package:transalin/screens/input_screen.dart';

class InstructionScreen extends StatelessWidget {
  const InstructionScreen({super.key, required this.pop});

  final bool pop;

  Widget buildInstruction(Instruction inst) => Container(
      width: AppGlobal.screenWidth * 0.6,
      height: AppGlobal.screenWidth * 0.5,
      decoration: const BoxDecoration(
          color: AppColor.kColorPeriDarker,
          borderRadius: BorderRadius.all(Radius.circular(15))),
      margin: const EdgeInsets.only(left: 10),
      padding: const EdgeInsets.all(15),
      child: Column(children: [
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Container(
              padding: const EdgeInsets.all(5),
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: AppColor.kColorWhite),
              child: Icon(
                inst.icon,
                size: 20,
                color: AppColor.kColorPeriLight,
              )),
          const SizedBox(width: 10),
          FittedBox(
            child: Text(
              inst.heading,
              style: const TextStyle(
                  color: AppColor.kColorWhite, fontWeight: FontWeight.bold),
            ),
          )
        ]),
        const SizedBox(height: 10),
        Text(
          inst.text,
          style:
              const TextStyle(color: AppColor.kColorPeriLighter, fontSize: 8.5),
        )
      ]));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.kColorPeriLightest,
      body: Center(
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const FittedBox(
              child: Text(
                  'Yep, we\'re good to go!\nYou can use the app offline.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColor.kColorPeriDarker))),
          SizedBox(height: AppGlobal.screenHeight * 0.025),

          OutlinedButton(
              style: OutlinedButton.styleFrom(
                primary: AppColor.kColorPeriLight,
                side: const BorderSide(
                    width: 0.0, color: AppColor.kColorPeriLightest),
                shape: const CircleBorder(),
                // padding: const EdgeInsets.all(1.0),
              ),
              onPressed: () async => pop
                  ? Navigator.of(context).pop()
                  : await Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                          builder: (context) => const InputScreen())),
              child: SizedBox(
                  width: AppGlobal.screenWidth * 0.5,
                  child: Lottie.asset('assets/lottie/thumb_up.json'))),
          SizedBox(height: AppGlobal.screenHeight * 0.025),
          Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 20, bottom: 10),
              child: const Text('How to use TranSalin?',
                  style: TextStyle(
                    color: AppColor.kColorPeriDarker,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ))),
          Container(
              width: AppGlobal.screenWidth,
              height: AppGlobal.screenWidth * 0.45,
              padding: const EdgeInsets.only(left: 10, right: 20),
              decoration: const BoxDecoration(
                color: AppColor.kColorPeriLightest,
              ),
              child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: Instructions.instructions.length,
                  itemBuilder: (context, index) => Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            buildInstruction(Instructions.instructions[index])
                          ]))),
          SizedBox(height: AppGlobal.screenHeight * 0.05),
          // FittedBox(
          // child:

          Row(mainAxisAlignment: MainAxisAlignment.center,
              // crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('Let\'s go! ',
                    style: TextStyle(
                      color: AppColor.kColorPeriDarker,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    )),
                Container(
                    padding: const EdgeInsets.only(top: 4.5),
                    child: const Text('Give a thumb up to get started.',
                        style: TextStyle(
                          color: AppColor.kColorPeri,
                          fontSize: 11,
                        )))
              ]),
        ],
      )),
    );
  }
}
