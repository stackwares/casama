import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/haptics.dart';
import 'mascot.dart';
import 'effects.dart';

/// For the big moments (a new bot, a new space, a first routine): a cloud bot pops up with a burst
/// of little stars and hearts and the [message], then floats away by itself. It sits over every
/// page, so it keeps playing while the app moves on to the next screen, and never takes a tap.
/// With reduced motion it's the bot and the message, fading in and out. Everyday saves keep the
/// quiet [showSuccess] message instead.
void showCelebration(BuildContext context, String message, {Mascot? mascot}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  HapticsHelper.success();
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _Celebration(
      message: message,
      mascot: mascot ?? _cheerful[math.Random().nextInt(_cheerful.length)],
      onDone: () {
        if (entry.mounted) entry.remove();
      },
    ),
  );
  overlay.insert(entry);
}

const _cheerful = [
  Mascot.giggly,
  Mascot.starry,
  Mascot.lovey,
  Mascot.wow,
  Mascot.winky,
];

const _confetti = [
  LucideIcons.star,
  LucideIcons.heart,
  LucideIcons.sparkle,
  LucideIcons.star,
  LucideIcons.heart,
];
const _confettiColors = [
  Color(0xFFFFC94D), // sunny
  Color(0xFFFF7EB3), // pink
  Color(0xFF8FB8FF), // sky
  Color(0xFFB79CFF), // lavender
  Color(0xFF6FE0C8), // mint
];

class _Celebration extends StatefulWidget {
  const _Celebration({
    required this.message,
    required this.mascot,
    required this.onDone,
  });
  final String message;
  final Mascot mascot;
  final VoidCallback onDone;

  @override
  State<_Celebration> createState() => _CelebrationState();
}

class _Piece {
  _Piece(math.Random r, int i, int n)
    : angle =
          -math.pi / 2 +
          (i / n - 0.5) * math.pi * 1.5 +
          (r.nextDouble() - 0.5) * 0.3,
      speed = 0.7 + r.nextDouble() * 0.6,
      spin = (r.nextDouble() - 0.5) * 6,
      size = 12 + r.nextDouble() * 10,
      icon = _confetti[i % _confetti.length],
      color = _confettiColors[r.nextInt(_confettiColors.length)];
  final double angle;
  final double speed;
  final double spin;
  final double size;
  final IconData icon;
  final Color color;
}

class _CelebrationState extends State<_Celebration>
    with SingleTickerProviderStateMixin {
  // One clock for the whole show; the overlay goes away when it ends (no timers).
  late final _clock =
      AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 2600),
        )
        ..addStatusListener((s) {
          if (s == AnimationStatus.completed) widget.onDone();
        })
        ..forward();
  final _pieces = () {
    final r = math.Random();
    return [for (var i = 0; i < 16; i++) _Piece(r, i, 16)];
  }();

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = !Effects.decorative(context);
    final scheme = Theme.of(context).colorScheme;
    final size = MediaQuery.sizeOf(context);
    final bot = math.min(120.0, size.shortestSide * 0.3);
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _clock,
        builder: (context, _) {
          final t = _clock.value;
          // In over the first 15%, out over the last 15%.
          final inT = Curves.easeOutBack.transform((t / 0.15).clamp(0.0, 1.0));
          final outT = Curves.easeIn.transform(
            ((t - 0.85) / 0.15).clamp(0.0, 1.0),
          );
          final scale = still ? 1.0 : inT * (1 - 0.2 * outT);
          final opacity =
              (1 - outT) * (still ? (t / 0.15).clamp(0.0, 1.0) : 1.0);
          final rise = still ? 0.0 : outT * 40;
          final bob = still ? 0.0 : math.sin(t * math.pi * 6) * 4 * (1 - outT);
          final center = Offset(size.width / 2, size.height * 0.42);
          return Stack(
            children: [
              if (!still)
                for (final p in _pieces) _piece(p, t, center, bot),
              Positioned(
                left: 0,
                right: 0,
                top: center.dy - bot / 2 - rise + bob,
                child: Opacity(
                  opacity: opacity,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Transform.scale(
                        scale: scale,
                        child: MascotImage(widget.mascot, size: bot),
                      ),
                      const SizedBox(height: 12),
                      Transform.scale(
                        scale: still ? 1 : 0.9 + 0.1 * inT,
                        child: Semantics(
                          liveRegion: true,
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 320),
                            margin: const EdgeInsets.symmetric(horizontal: 24),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            decoration: ShapeDecoration(
                              color: scheme.inverseSurface,
                              shape: const StadiumBorder(),
                              shadows: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.18),
                                  blurRadius: 20,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Text(
                              widget.message,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    color: scheme.onInverseSurface,
                                    fontWeight: FontWeight.w700,
                                    decoration: TextDecoration.none,
                                  ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _piece(_Piece p, double t, Offset center, double bot) {
    // Bursts out from behind the bot, slows, then drifts down and fades.
    final k = (t / 0.7).clamp(0.0, 1.0);
    final travel = Curves.easeOutCubic.transform(k) * bot * 1.6 * p.speed;
    final fall = k * k * bot * 0.6;
    final x = center.dx + math.cos(p.angle) * travel;
    final y = center.dy + math.sin(p.angle) * travel + fall;
    final fade = 1 - ((t - 0.45) / 0.3).clamp(0.0, 1.0);
    final grow = Curves.easeOutBack.transform((t / 0.12).clamp(0.0, 1.0));
    return Positioned(
      left: x - p.size / 2,
      top: y - p.size / 2,
      child: Opacity(
        opacity: fade,
        child: Transform.rotate(
          angle: p.spin * k,
          child: Transform.scale(
            scale: grow,
            child: Icon(p.icon, size: p.size, color: p.color),
          ),
        ),
      ),
    );
  }
}
