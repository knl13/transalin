import 'package:flutter/material.dart';
import 'package:transalin/classes/feature.dart';

class Features {
  static const toggle =
      Feature(icon: Icons.visibility_outlined, text: 'toggle');
  static const change = Feature(icon: Icons.translate, text: 'change');
  static const copy = Feature(icon: Icons.content_copy, text: 'copy');
  static const listen = Feature(icon: Icons.hearing, text: 'listen');
  static const save = Feature(icon: Icons.save_alt, text: 'save');

  static const List<Feature> features = [toggle, change, copy, listen, save];
}
