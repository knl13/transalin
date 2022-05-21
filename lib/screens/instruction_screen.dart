import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:transalin/classes/instruction.dart';
import 'package:transalin/classes/instructions.dart';
import 'package:transalin/constants/app_color.dart';
import 'package:transalin/constants/app_global.dart';
import 'package:transalin/screens/input_screen.dart';

//a screen that guides the user how the app works
class InstructionScreen extends StatelessWidget {
  const InstructionScreen({super.key, required this.pop});
  final bool pop;

  Widget buildInstruction(Instruction inst) => Container(
      width: AppGlobal.screenWidth * 0.6,
      height: AppGlobal.screenWidth * 0.5,
      decoration: const BoxDecoration(
          color: AppColor.kColorPeriDarker,
          borderRadius: BorderRadius.all(Radius.circular(15))),
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(15),
      child: Column(children: [
        Row(children: [
          Container(
              padding: const EdgeInsets.all(5),
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: AppColor.kColorWhite),
              child:
                  Icon(inst.icon, size: 20, color: AppColor.kColorPeriLight)),
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          //heading
          const FittedBox(
              child: Text(
                  'Yep, we\'re good to go!\nYou can use the app offline.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColor.kColorPeriDarker))),
          SizedBox(height: AppGlobal.screenHeight * 0.025),
          //thumbs up button to go to input/output screen
          OutlinedButton(
              style: OutlinedButton.styleFrom(
                primary: AppColor.kColorPeriLight,
                side: const BorderSide(
                    width: 0.0, color: AppColor.kColorPeriLightest),
                shape: const CircleBorder(),
              ),
              onPressed: () async => pop
                  ? Navigator.of(context)
                      .pop() //pop screen if previous screen is input/output screen (help button)
                  : await Navigator.of(context).pushReplacement(MaterialPageRoute(
                      builder: (context) =>
                          const InputScreen())), //push input screen if prev screen is download screen
              child: SizedBox(
                  width: AppGlobal.screenWidth * 0.5,
                  child: Lottie.asset('assets/lottie/thumb_up.json'))),
          SizedBox(height: AppGlobal.screenHeight * 0.025),
          //guide how to use the app
          Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 20, bottom: 10),
              child: const Text('How to use TranSalin?',
                  style: AppGlobal.textStylePeriDarkerBold16)),
          Container(
              width: AppGlobal.screenWidth,
              height: AppGlobal.screenWidth * 0.45,
              padding: const EdgeInsets.only(left: 20, right: 20),
              decoration:
                  const BoxDecoration(color: AppColor.kColorPeriLightest),
              child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: Instructions.instructions.length,
                  itemBuilder: (context, index) => Row(children: [
                        buildInstruction(Instructions.instructions[index])
                      ]))),
          SizedBox(height: AppGlobal.screenHeight * 0.05),
          //helper to know that the thumbs up button is clickable
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('Let\'s go! ',
                style: AppGlobal.textStylePeriDarkerBold16),
            Container(
                padding: const EdgeInsets.only(top: 4.5),
                child: const Text('Give a thumbs up to get started.',
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
