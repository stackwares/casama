import 'package:flutter/material.dart';

/// The Kasama cloud companion mark.
class KasamaMark extends StatelessWidget {
  const KasamaMark({super.key, this.size = 36});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.3),
        child: Image.asset('assets/branding/kasama_mascot_icon.png', fit: BoxFit.cover),
      ),
    );
  }
}
