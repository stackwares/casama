import 'package:flutter/material.dart';
import 'package:kasama_sdk/kasama_sdk.dart';

import '../theme/app_colors.dart';
import 'motion.dart';

/// Gradients bots draw from, picked by name so a bot keeps its color everywhere.
const _palettes = <List<Color>>[
  [Color(0xFF14B8A6), Color(0xFF0F766E)],
  [Color(0xFF6366F1), Color(0xFF4338CA)],
  [Color(0xFFF59E0B), Color(0xFFD97706)],
  [Color(0xFFEC4899), Color(0xFFBE185D)],
  [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
  [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
  [Color(0xFF10B981), Color(0xFF047857)],
  [Color(0xFFF97316), Color(0xFFC2410C)],
];

List<Color> botPalette(String name) {
  var h = 0;
  for (final c in name.toLowerCase().codeUnits) {
    h = (h * 31 + c) & 0x7fffffff;
  }
  return _palettes[h % _palettes.length];
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first.characters.first.toUpperCase();
  return (parts.first.characters.first + parts[1].characters.first).toUpperCase();
}

/// A bot's mark: a rounded square in its gradient with its initials, and a status dot that pulses
/// while it works.
class BotAvatar extends StatelessWidget {
  const BotAvatar({super.key, required this.name, this.size = 40, this.status, this.ringColor});

  final String name;
  final double size;
  final BotStatusEnum? status;

  /// The surface behind the avatar, for the gap around the status dot.
  final Color? ringColor;

  @override
  Widget build(BuildContext context) {
    final colors = botPalette(name);
    final radius = size * 0.32;
    final dotColor = switch (status) {
      BotStatusEnum.working => context.appColors.working,
      BotStatusEnum.waiting => context.appColors.waiting,
      _ => null,
    };
    final dot = size * 0.3;
    Widget? statusDot;
    if (dotColor != null) {
      statusDot = Container(
        width: dot,
        height: dot,
        decoration: BoxDecoration(
          color: dotColor,
          shape: BoxShape.circle,
          border: Border.all(color: ringColor ?? context.colorScheme.surface, width: size * 0.06),
        ),
      );
      if (status == BotStatusEnum.working) statusDot = Pulse(child: statusDot);
    }
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
              boxShadow: [
                if (size >= 56)
                  BoxShadow(
                    color: colors.last.withValues(alpha: context.isDark ? 0.5 : 0.3),
                    blurRadius: size * 0.3,
                    offset: Offset(0, size * 0.1),
                  ),
              ],
            ),
            alignment: Alignment.center,
            child: ExcludeSemantics(
              child: Text(
                _initials(name),
                style: TextStyle(
                  fontFamily: 'Nunito',
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: size * (name.trim().contains(' ') ? 0.36 : 0.44),
                  height: 1,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
          if (statusDot != null) Positioned(right: -size * 0.06, bottom: -size * 0.06, child: statusDot),
        ],
      ),
    );
  }
}
