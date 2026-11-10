import 'dart:math';

import 'package:flutter/material.dart';

import 'mascot.dart';

/// The Kasama mark on front-facing screens: one of the brand cloud bots (Winky, Giggly, Thinker or
/// Wow), picked at random each time the mark appears, animated and on a transparent background.
class KasamaMark extends StatefulWidget {
  const KasamaMark({super.key, this.size = 36, this.animate = true});
  final double size;
  final bool animate;

  @override
  State<KasamaMark> createState() => _KasamaMarkState();
}

class _KasamaMarkState extends State<KasamaMark> {
  static final _rng = Random();
  late final Mascot _mascot = Mascot.brand[_rng.nextInt(Mascot.brand.length)];

  @override
  Widget build(BuildContext context) => MascotImage(
    _mascot,
    size: widget.size,
    animate: widget.animate,
    semanticLabel: 'Kasama',
  );
}
