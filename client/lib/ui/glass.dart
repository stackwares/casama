import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/wallpaper.dart';

/// Frosted glass over the wallpaper: a blur of what's behind, a translucent surface tint, a light
/// top edge and a hairline. For panes and bars that sit on the wallpaper (sidebar, computer panel,
/// composer) so they read clearly but still feel part of it.
///
/// The blur is a [BackdropFilter], which re-reads and blurs the pixels behind it on every frame
/// anything there repaints. Keep it to a few large, fixed surfaces. Anything that repeats or
/// scrolls (cards, list rows) uses [frostedDecoration] instead: the same look without the blur,
/// which costs no more than an opaque fill. `blur: 0` does the same here.
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
    final dark = context.isDark;
    final box = DecoratedBox(
      decoration: frostedDecoration(
        context,
        borderRadius: borderRadius,
        opacity: opacity ?? (dark ? 0.62 : 0.68),
        tint: tint,
        border: border ?? Border.all(color: context.appColors.hairline.withValues(alpha: dark ? 0.9 : 0.7)),
      ),
      child: child,
    );
    if (blur <= 0) return box;
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur), child: box),
    );
  }
}

/// The frosted surface without a live blur: a translucent surface tint, lighter at the top, with
/// an optional border. Over the wallpaper (whose photo is already blurred once and cached) it reads
/// as glass, at the cost of a plain fill. Used by [AppCard], [GroupedCard] and their skeletons.
///
/// [opacity] defaults to [frostedOpacity].
BoxDecoration frostedDecoration(
  BuildContext context, {
  BorderRadius? borderRadius,
  double? opacity,
  Color? tint,
  Border? border,
}) {
  final scheme = context.colorScheme;
  final dark = context.isDark;
  final base = tint ?? (dark ? scheme.surfaceContainerLow : scheme.surfaceContainerLowest);
  final a = opacity ?? frostedOpacity(context);
  return BoxDecoration(
    borderRadius: borderRadius,
    border: border,
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color.lerp(base, Colors.white, dark ? 0.04 : 0.3)!.withValues(alpha: a),
        base.withValues(alpha: a),
      ],
    ),
  );
}

/// How opaque an unblurred frosted card is. Higher than [Glass]'s default, since nothing behind
/// it is blurred by the card itself, and higher again over a photo the user turned the blur down
/// on, where a sharp picture would show through and make text hard to read.
double frostedOpacity(BuildContext context) {
  final dark = context.isDark;
  final spec = Theme.of(context).extension<WallpaperTheme>()?.spec;
  final sharpPhoto = spec != null && spec.photo != null && spec.photoBlur < 0.2;
  if (sharpPhoto) return dark ? 0.86 : 0.9;
  return dark ? 0.74 : 0.8;
}
