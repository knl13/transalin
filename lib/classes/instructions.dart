import 'package:flutter/material.dart';
import 'package:transalin/classes/instruction.dart';

class Instructions {
  static const language = Instruction(
      icon: Icons.language_rounded,
      heading: 'Language',
      text:
          'The current available languages are Chinese, English, and Filipino. These three are all functional as a source or target language.');

  static const input = Instruction(
      icon: Icons.photo_rounded,
      heading: 'Input',
      text:
          'The inputs that can be processed are either images chosen from the device or captured through the camera.');

  static const translation = Instruction(
      icon: Icons.wifi_off_rounded,
      heading: 'Translation',
      text:
          'The on-device translation displays the result as overlays. It uses the pre-saved models to provide offline services with relatively low-quality translation.');

  static const romanization = Instruction(
    icon: Icons.translate_rounded,
    heading: 'Romanization',
    text:
        'Romanizing means converting text from a different writing system to Latin script. This feature is only applicable if the target language is Chinese.',
  );
  static const feature = Instruction(
      icon: Icons.settings_rounded,
      heading: 'Features',
      text:
          'The features provided are toggle overlay visibility, romanize Chinese script, copy text, listen to text, save image, and pinch to zoom in or out the image.');
  static const interface = Instruction(
      icon: Icons.layers_outlined,
      heading: 'Interface',
      text:
          'The features operate on what text is shown on the screen. The toggle and romanize features help switch the display to access the recognized, translated, and romanized texts.');

  static const List<Instruction> instructions = [
    // language,
    // input,
    translation,
    romanization,
    feature,
    interface
  ];
}
