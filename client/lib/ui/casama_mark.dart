import 'dart:math';

import 'package:material_ui/material_ui.dart';

import 'mascot.dart';

/// The Casama mark on front-facing screens: one of the brand cloud bots (Winky, Giggly, Thinker or
/// Wow), picked at random each time the mark appears, animated and on a transparent background.
class CasamaMark extends StatefulWidget {
  const CasamaMark({super.key, this.size = 36, this.animate = true});
  final double size;
  final bool animate;

  @override
  State<CasamaMark> createState() => _CasamaMarkState();
}

class _CasamaMarkState extends State<CasamaMark> {
  static final _rng = Random();
  late final Mascot _mascot = Mascot.brand[_rng.nextInt(Mascot.brand.length)];

  @override
  Widget build(BuildContext context) => MascotImage(
    _mascot,
    size: widget.size,
    animate: widget.animate,
    semanticLabel: 'Casama',
  );
}
