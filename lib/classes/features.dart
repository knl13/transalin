import 'package:flutter/material.dart';
import 'package:transalin/classes/feature.dart';

class Features {
  static const toggle =
      Feature(icon: Icons.visibility_outlined, text: 'Toggle');
  static const change = Feature(icon: Icons.translate, text: 'Change');
  static const copy = Feature(icon: Icons.content_copy, text: 'Copy');
  static const listen = Feature(icon: Icons.hearing, text: 'Listen');
  static const save = Feature(icon: Icons.save_alt, text: 'Save');

  static const List<Feature> features = [toggle, change, copy, listen, save];
}
