import 'package:flutter/material.dart';
import 'package:transalin/classes/feature.dart';

class Features {
  // static const toggle = Feature(icon: Icons.remove_red_eye, text: 'Toggle visibility');
  static const toggle =
      Feature(icon: Icons.remove_red_eye_outlined, text: 'Toggle');
  static const change = Feature(icon: Icons.translate, text: 'Change script');
  // static const copy = Feature(icon: Icons.file_copy, text: 'Copy text');
  static const copy = Feature(icon: Icons.content_copy, text: 'Copy text');
  static const listen = Feature(icon: Icons.hearing, text: 'Listen to text');
  static const save = Feature(icon: Icons.save_alt, text: 'Save image');

  static const List<Feature> features = [toggle, change, copy, listen, save];
}
