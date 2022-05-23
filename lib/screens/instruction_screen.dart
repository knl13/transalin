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
  static TextStyle textStylePeriDarkerBold = TextStyle(
      color: AppColor.kColorPeriDarker,
      fontWeight: FontWeight.bold,
      fontSize: AppGlobal.screenWidth * 0.0445);

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
              width: AppGlobal.screenWidth * 0.1,
              padding: const EdgeInsets.all(5),
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: AppColor.kColorWhite),
              child: Icon(inst.icon,
                  size: AppGlobal.screenWidth * 0.055,
                  color: AppColor.kColorPeriLight)),
          SizedBox(width: AppGlobal.screenWidth * 0.028),
          Text(
            inst.heading,
            style: TextStyle(
                color: AppColor.kColorWhite,
                fontWeight: FontWeight.bold,
                fontSize: AppGlobal.screenWidth * 0.039),
          )
        ]),
        SizedBox(height: AppGlobal.screenHeight * 0.0145),
        Text(
          inst.text,
          style: TextStyle(
            color: AppColor.kColorPeriLighter,
            fontSize: AppGlobal.screenWidth * 0.023,
          ),
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
          Text('Yep, we\'re good to go!\nYou can use the app offline.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColor.kColorPeriDarker,
                  fontSize: AppGlobal.screenWidth * 0.039)),
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
          //guide how to the app works
          Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 20, bottom: 10),
              child: Text('How to use TranSalin?',
                  style: textStylePeriDarkerBold)),
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
            Text('Let\'s go!', style: textStylePeriDarkerBold),
            Container(
                padding: EdgeInsets.only(top: AppGlobal.screenHeight * 0.005),
                child: Text(' Give a thumbs up to get started.',
                    style: TextStyle(
                      color: AppColor.kColorPeri,
                      fontSize: AppGlobal.screenWidth * 0.0305,
                    )))
          ]),
        ],
      )),
    );
  }
}
