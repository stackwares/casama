import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'mascot.dart';

/// A full-screen wait: a cloud bot bobbing over its soft shadow, with an optional line under it.
/// For waits with nothing to sketch yet (starting a routine, setting up a space); lists and pages
/// that are loading use skeletons instead. Still with reduced motion.
class BotLoader extends StatefulWidget {
  const BotLoader({
    super.key,
    this.label,
    this.mascot = Mascot.focused,
    this.size = 96,
  });

  final String? label;
  final Mascot mascot;
  final double size;

  @override
  State<BotLoader> createState() => _BotLoaderState();
}

class _BotLoaderState extends State<BotLoader>
    with SingleTickerProviderStateMixin {
  late final _bob = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _bob.stop();
    } else if (!_bob.isAnimating) {
      _bob.repeat();
    }
  }

  @override
  void dispose() {
    _bob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final label = widget.label;
    return Semantics(
      label: label,
      liveRegion: label != null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(
            child: AnimatedBuilder(
              animation: _bob,
              builder: (context, child) {
                // Up and down with a little tilt; the shadow shrinks as the bot rises.
                final lift = (math.sin(_bob.value * 2 * math.pi) + 1) / 2;
                return SizedBox(
                  width: size,
                  height: size * 1.25,
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      Container(
                        width: size * (0.55 - 0.15 * lift),
                        height: size * 0.08,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(
                            alpha: 0.10 - 0.04 * lift,
                          ),
                          borderRadius: BorderRadius.all(
                            Radius.elliptical(size, size * 0.08),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: size * (0.08 + 0.12 * lift),
                        child: Transform.rotate(
                          angle: math.sin(_bob.value * 2 * math.pi + 1) * 0.06,
                          child: child,
                        ),
                      ),
                    ],
                  ),
                );
              },
              child: MascotImage(widget.mascot, size: size),
            ),
          ),
          if (label != null) ...[
            const SizedBox(height: 12),
            ExcludeSemantics(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
