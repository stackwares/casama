import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../core/haptics.dart';
import '../../ui/mascot.dart';

/// One bot on the sign-in screen: where it rests (fractions of the screen), how big it is (a
/// fraction of the shorter side), and how far it wanders from there (fractions of the screen).
class _Float {
  const _Float(this.mascot, this.x, this.y, this.size, this.phase, {required this.rx, required this.ry, this.fx = 1, this.fy = 1});
  final Mascot mascot;
  final double x;
  final double y;
  final double size;
  final double phase;
  final double rx;
  final double ry;

  /// Whole cycles per loop across and down, so the loop has no seam. Unequal ones trace a figure eight.
  final int fx;
  final int fy;

  /// 0 for the smallest (far away), 1 for the biggest (close up).
  double get depth => ((size - 0.11) / 0.13).clamp(0.0, 1.0);
}

// Spread around the name and the tagline, never wandering into them or down to the button. Listed
// small to big, so the close ones pass in front of the far ones.
const _floats = [
  _Float(Mascot.focused, 0.60, 0.07, 0.11, 3.9, rx: 0.10, ry: 0.015, fx: 1, fy: 2),
  _Float(Mascot.sleepy, 0.92, 0.53, 0.13, 0.7, rx: 0.025, ry: 0.025),
  _Float(Mascot.shy, 0.08, 0.56, 0.14, 4.2, rx: 0.025, ry: 0.025, fy: 2),
  _Float(Mascot.starry, 0.26, 0.14, 0.15, 0.0, rx: 0.06, ry: 0.02, fx: 2, fy: 1),
  _Float(Mascot.cool, 0.50, 0.69, 0.15, 2.8, rx: 0.13, ry: 0.02, fx: 1, fy: 2),
  _Float(Mascot.lovey, 0.89, 0.29, 0.17, 3.4, rx: 0.035, ry: 0.02, fy: 2),
  _Float(Mascot.thinker, 0.16, 0.76, 0.20, 5.0, rx: 0.05, ry: 0.02, fx: 2, fy: 1),
  _Float(Mascot.giggly, 0.13, 0.28, 0.22, 2.1, rx: 0.04, ry: 0.02, fy: 2),
  _Float(Mascot.wow, 0.83, 0.75, 0.22, 1.9, rx: 0.05, ry: 0.02, fx: 1, fy: 2),
  _Float(Mascot.winky, 0.70, 0.20, 0.23, 1.3, rx: 0.06, ry: 0.025, fx: 2, fy: 1),
];

/// The Casama bots wandering around the sign-in screen behind [child]: each plays its own Lottie
/// loop while it drifts on a slow loop, the far ones fainter and slower. They pop in one by one,
/// and a tapped bot hops. Still when the system asks for reduced motion.
class FloatingMascots extends StatefulWidget {
  const FloatingMascots({super.key, this.child});

  /// What sits in front of the bots. Taps reach it as usual; one that lands on a bot also makes it hop.
  final Widget? child;

  @override
  State<FloatingMascots> createState() => _FloatingMascotsState();
}

class _FloatingMascotsState extends State<FloatingMascots> with TickerProviderStateMixin {
  late final _clock = AnimationController(vsync: this, duration: const Duration(seconds: 48));
  late final _intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));
  late final _hops = [
    for (final _ in _floats) AnimationController(vsync: this, duration: const Duration(milliseconds: 750)),
  ];
  late final _ticks = Listenable.merge([_clock, _intro, ..._hops]);

  /// Where each bot was last painted, for finding the one under a tap.
  final _rects = List<Rect>.filled(_floats.length, Rect.zero);
  Offset? _down;

  bool get _still => MediaQuery.disableAnimationsOf(context) || !(ModalRoute.of(context)?.isCurrent ?? true);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Paused under the sign-in sheet (or any page on top) and with reduced motion.
    if (MediaQuery.disableAnimationsOf(context)) {
      _intro.value = 1;
    } else if (_intro.isDismissed) {
      _intro.forward();
    }
    if (_still) {
      _clock.stop();
    } else if (!_clock.isAnimating) {
      _clock.repeat();
    }
  }

  @override
  void dispose() {
    _clock.dispose();
    _intro.dispose();
    for (final h in _hops) {
      h.dispose();
    }
    super.dispose();
  }

  void _tapAt(Offset p) {
    if (_still) return;
    // Front to back, so the bot on top answers.
    for (var i = _floats.length - 1; i >= 0; i--) {
      if (_rects[i].deflate(_rects[i].width * 0.12).contains(p)) {
        if (!_hops[i].isAnimating) {
          HapticsHelper.light();
          _hops[i].forward(from: 0);
        }
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final still = _still;
    // A plain Listener sees the taps without taking them from the buttons and scrolling in front.
    return Listener(
      onPointerDown: (e) => _down = e.localPosition,
      onPointerUp: (e) {
        final down = _down;
        _down = null;
        if (down != null && (e.localPosition - down).distance < 12) _tapAt(e.localPosition);
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          ExcludeSemantics(
            child: LayoutBuilder(
              builder: (context, box) {
                final w = box.maxWidth;
                final h = box.maxHeight;
                // Sized from the shorter side, capped so they stay friendly on big windows.
                final unit = math.min(math.min(w, h), 560.0);
                return AnimatedBuilder(
                  animation: _ticks,
                  builder: (context, _) {
                    final t = _clock.value * 2 * math.pi;
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        for (final (i, f) in _floats.indexed) _bot(i, f, t, w, h, unit, still),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          ?widget.child,
        ],
      ),
    );
  }

  Widget _bot(int i, _Float f, double t, double w, double h, double unit, bool still) {
    final size = unit * f.size;
    final a = t + f.phase;
    // Far ones wander less, so they read as further away.
    final reach = 0.6 + 0.4 * f.depth;
    final dx = math.sin(a * f.fx) * f.rx * w * reach;
    final dy = math.sin(a * f.fy + f.phase * 1.7) * f.ry * h * reach + math.sin(a * 6) * unit * 0.006;
    final tilt = math.sin(a * 2 + 1.1) * 0.08;

    // Popping in, staggered.
    final start = i / _floats.length * 0.55;
    final pop = CurvedAnimation(parent: _intro, curve: Interval(start, start + 0.45, curve: Curves.easeOutBack)).value;

    // A hop: up and back down with a squash on landing and a wiggle.
    final hp = _hops[i].value;
    final hop = _hops[i].isAnimating ? hp : 0.0;
    final lift = math.sin(math.pi * hop) * size * 0.45;
    final squash = hop > 0.85 ? math.sin((hop - 0.85) / 0.15 * math.pi) * 0.12 : 0.0;
    final wiggle = math.sin(hop * math.pi * 4) * 0.22 * (1 - hop);

    final left = f.x * w - size / 2 + dx;
    final top = f.y * h - size / 2 + dy - lift;
    _rects[i] = Rect.fromLTWH(left, top, size, size);
    return Positioned(
      left: left,
      top: top,
      child: Opacity(
        opacity: (0.72 + 0.28 * f.depth) * pop.clamp(0.0, 1.0),
        child: Transform(
          alignment: Alignment.bottomCenter,
          transform: Matrix4.identity()
            ..rotateZ(tilt + wiggle)
            ..scaleByDouble(pop * (1 + squash), pop * (1 - squash), 1, 1),
          child: MascotImage(f.mascot, size: size, animate: !still),
        ),
      ),
    );
  }
}
