import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../ui/bot_avatar.dart';

/// The optional animated avatar for live calls (D-144), drawn on device from the bot's avatar: it
/// breathes while listening and, while the bot speaks, bounces gently with a pulsing ring and a
/// small voice meter, so it reads as talking. Respects reduced motion.
class TalkingAvatar extends StatefulWidget {
  const TalkingAvatar({super.key, required this.name, this.avatar, required this.speaking, this.size = 96, this.color});
  final String name;
  final String? avatar;
  final ValueListenable<bool> speaking;
  final double size;
  final Color? color;

  @override
  State<TalkingAvatar> createState() => _TalkingAvatarState();
}

class _TalkingAvatarState extends State<TalkingAvatar> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final color = widget.color ?? Theme.of(context).colorScheme.primary;
    return ValueListenableBuilder<bool>(
      valueListenable: widget.speaking,
      builder: (context, speaking, _) => AnimatedBuilder(
        animation: _c,
        builder: (context, child) {
          final t = reduce ? 0.0 : _c.value * 2 * math.pi;
          final scale = speaking ? 1 + 0.04 * math.sin(t * 4) : 1 + 0.015 * math.sin(t);
          final ring = speaking ? 0.35 + 0.25 * (0.5 + 0.5 * math.sin(t * 3)) : 0.12;
          return Column(
            key: Key(speaking ? 'avatarSpeaking' : 'avatarListening'),
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withValues(alpha: ring), width: 4),
                ),
                child: Transform.scale(scale: scale, child: child),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 14,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < 5; i++)
                      Container(
                        width: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        height: speaking ? 4 + 10 * (0.5 + 0.5 * math.sin(t * 5 + i * 1.3)).abs() : 4,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: speaking ? 0.9 : 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
        child: BotAvatar(name: widget.name, avatar: widget.avatar, size: widget.size),
      ),
    );
  }
}
