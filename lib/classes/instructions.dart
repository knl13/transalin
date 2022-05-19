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
          'The inputs that can be processed are images chosen from the storage or captured through the camera stream.');

  static const translation = Instruction(
      icon: Icons.wifi_off_rounded,
      heading: 'Translation',
      text:
          'The on-device translation shows the result through overlays. It uses the pre-saved language models to provide offline services but lower translation quality.');

  static const romanization = Instruction(
    icon: Icons.translate_rounded,
    heading: 'Romanization',
    text:
        'Romanizing is converting text from a different writing system to Latin script. This feature is only applicable if the target language is Chinese.',
  );
  static const feature = Instruction(
      icon: Icons.settings_rounded,
      heading: 'Feature',
      text:
          'The features provided are toggle overlay visibility, change Hanzi to Latin script, copy and listen to text, pinch to zoom in or out, and save the image with or without the overlay.');
  static const interface = Instruction(
      icon: Icons.layers_outlined,
      heading: 'Interface',
      text:
          'The features operate on what text is shown on the screen. The toggle and change features help switch the display to access the different texts.');

  static const List<Instruction> instructions = [
    language,
    input,
    translation,
    romanization,
    feature,
    interface
  ];
}
