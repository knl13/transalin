import 'package:flutter/material.dart';
import 'package:transalin/classes/instruction.dart';

class Instructions {
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
    translation,
    romanization,
    feature,
    interface
  ];
}
