import 'package:flutter/material.dart';

/// The Kasama mark: two companions side by side on a teal rounded square. Drawn in code so it
/// stays sharp at every size and needs no asset.
class KasamaMark extends StatelessWidget {
  const KasamaMark({super.key, this.size = 36});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.3),
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF2DD4BF), Color(0xFF0F766E)]),
      ),
      child: CustomPaint(painter: _MarkPainter()),
    );
  }
}

class _MarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final front = Paint()..color = Colors.white;
    final back = Paint()..color = Colors.white.withValues(alpha: 0.55);
    // The companion behind: smaller, to the right.
    canvas.drawCircle(Offset(s * 0.64, s * 0.36), s * 0.115, back);
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(s * 0.5, s * 0.53, s * 0.28, s * 0.22),
        topLeft: Radius.circular(s * 0.14),
        topRight: Radius.circular(s * 0.14),
        bottomLeft: Radius.circular(s * 0.04),
        bottomRight: Radius.circular(s * 0.04),
      ),
      back,
    );
    // The companion in front.
    canvas.drawCircle(Offset(s * 0.4, s * 0.38), s * 0.135, front);
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(s * 0.22, s * 0.57, s * 0.36, s * 0.2),
        topLeft: Radius.circular(s * 0.18),
        topRight: Radius.circular(s * 0.18),
        bottomLeft: Radius.circular(s * 0.04),
        bottomRight: Radius.circular(s * 0.04),
      ),
      front,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
