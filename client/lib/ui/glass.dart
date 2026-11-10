import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Frosted glass over the wallpaper: a blur of what's behind, a translucent surface tint, a light
/// top edge and a hairline. For panes and bars that sit on the wallpaper (sidebar, computer panel,
/// composer) so they read clearly but still feel part of it.
class Glass extends StatelessWidget {
  const Glass({super.key, required this.child, this.borderRadius = BorderRadius.zero, this.blur = 28, this.opacity, this.border, this.tint});
  final Widget child;
  final BorderRadius borderRadius;
  final double blur;

  /// How opaque the tint is; defaults suit text on top.
  final double? opacity;
  final Border? border;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final dark = context.isDark;
    final base = tint ?? (dark ? scheme.surfaceContainerLow : scheme.surfaceContainerLowest);
    final a = opacity ?? (dark ? 0.62 : 0.68);
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            border: border ?? Border.all(color: context.appColors.hairline.withValues(alpha: dark ? 0.9 : 0.7)),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.lerp(base, Colors.white, dark ? 0.04 : 0.3)!.withValues(alpha: a),
                base.withValues(alpha: a),
              ],
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
