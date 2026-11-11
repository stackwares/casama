import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../ui/mascot.dart';

/// One bot on the sign-in screen: where it rests (fractions of the screen), how big it is (a
/// fraction of the shorter side), and how it drifts.
class _Float {
  const _Float(this.mascot, this.x, this.y, this.size, this.phase, {this.speed = 1, this.animate = false});
  final Mascot mascot;
  final double x;
  final double y;
  final double size;
  final double phase;
  /// Whole cycles per 24 s loop (1 or 2), so the loop has no seam.
  final int speed;

  /// Plays the mascot's own loop too (a few of them; ten playing at once is a lot of decoding).
  final bool animate;
}

// Around the edges, leaving the middle band (the name and the tagline) and the bottom (the button)
// clear. Some peek in from the sides.
const _floats = [
  _Float(Mascot.starry, 0.30, 0.14, 0.15, 0.0, speed: 1),
  _Float(Mascot.winky, 0.68, 0.19, 0.24, 1.3, animate: true),
  _Float(Mascot.giggly, 0.05, 0.31, 0.25, 2.1, speed: 1, animate: true),
  _Float(Mascot.lovey, 0.97, 0.34, 0.17, 3.4, speed: 2),
  _Float(Mascot.shy, 0.02, 0.50, 0.15, 4.2, speed: 2),
  _Float(Mascot.sleepy, 0.99, 0.53, 0.14, 0.7, speed: 1),
  _Float(Mascot.thinker, 0.10, 0.70, 0.21, 5.0, speed: 1, animate: true),
  _Float(Mascot.cool, 0.45, 0.75, 0.15, 2.8, speed: 2),
  _Float(Mascot.wow, 0.85, 0.71, 0.23, 1.9, speed: 1, animate: true),
  _Float(Mascot.focused, 0.62, 0.05, 0.11, 3.9, speed: 2),
];

/// The Casama bots drifting around the sign-in screen: each bobs, sways and tilts on its own slow
/// loop. Still when the system asks for reduced motion.
class FloatingMascots extends StatefulWidget {
  const FloatingMascots({super.key});

  @override
  State<FloatingMascots> createState() => _FloatingMascotsState();
}

class _FloatingMascotsState extends State<FloatingMascots> with SingleTickerProviderStateMixin {
  late final _clock = AnimationController(vsync: this, duration: const Duration(seconds: 24));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Paused under the sign-in sheet (or any page on top) and with reduced motion.
    final covered = !(ModalRoute.of(context)?.isCurrent ?? true);
    if (MediaQuery.disableAnimationsOf(context) || covered) {
      _clock.stop();
    } else if (!_clock.isAnimating) {
      _clock.repeat();
    }
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    return ExcludeSemantics(
      child: LayoutBuilder(
        builder: (context, box) {
          final w = box.maxWidth;
          final h = box.maxHeight;
          // Sized from the shorter side, capped so they stay friendly on big windows.
          final unit = math.min(math.min(w, h), 560.0);
          return AnimatedBuilder(
            animation: _clock,
            builder: (context, _) {
              final t = _clock.value * 2 * math.pi;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  for (final f in _floats)
                    Builder(
                      builder: (context) {
                        final size = unit * f.size;
                        final a = t * f.speed + f.phase;
                        final dx = math.sin(a) * unit * 0.025;
                        final dy = math.sin(a * 2) * unit * 0.018;
                        final tilt = math.sin(a + 1.1) * 0.09;
                        return Positioned(
                          left: f.x * w - size / 2 + dx,
                          top: f.y * h - size / 2 + dy,
                          child: Transform.rotate(
                            angle: tilt,
                            child: MascotImage(f.mascot, size: size, animate: f.animate && !still),
                          ),
                        );
                      },
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
