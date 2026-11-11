import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_tokens.dart';

/// A picture from the web that eases in: a plain tone holds its place while it loads, it fades in
/// when ready, and if it can't load a small, faint broken-image mark shows instead (never a
/// technical message). It fills the box it is given, so give it a sized tile or a grid cell.
///
/// Built on Flutter's own Image builders (frameBuilder for the fade, errorBuilder for the failure
/// mark), so it needs no extra package and works on every platform.
class SmoothNetworkImage extends StatelessWidget {
  const SmoothNetworkImage(this.url, {super.key, this.fit = BoxFit.cover, this.decodeWidth, this.placeholderColor, this.error});

  final String url;
  final BoxFit fit;

  /// Decodes at this many pixels wide instead of the file's own size (remote logos are often
  /// 512 px or more for a 40 pt tile). Null decodes at full size.
  final int? decodeWidth;

  /// The tone shown while loading and behind the failure mark. Defaults to the theme's
  /// surfaceContainerHighest. Pass Colors.transparent when the box behind is already a placeholder.
  final Color? placeholderColor;

  /// Shown, centered, if the picture can't load. Defaults to a faint broken-image icon.
  final Widget? error;

  @override
  Widget build(BuildContext context) {
    final tone = placeholderColor ?? Theme.of(context).colorScheme.surfaceContainerHighest;
    // Faint on any tone: light marks on dark tones, dark marks on light ones.
    final mark = ThemeData.estimateBrightnessForColor(tone) == Brightness.dark ? Colors.white.withValues(alpha: 0.4) : Colors.black.withValues(alpha: 0.25);
    final duration = AppMotion.of(context, AppMotion.duration);
    return SizedBox.expand(
      child: Image(
        image: ResizeImage.resizeIfNeeded(decodeWidth, null, NetworkImage(url)),
        fit: fit,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          // Pictures already in memory (scrolling back, reopening a screen) show at once.
          if (wasSynchronouslyLoaded) return child;
          return Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: tone),
              AnimatedOpacity(opacity: frame == null ? 0 : 1, duration: duration, curve: AppMotion.curve, child: child),
            ],
          );
        },
        errorBuilder: (context, _, _) => ColoredBox(
          color: tone,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: duration,
            curve: AppMotion.curve,
            builder: (context, opacity, child) => Opacity(opacity: opacity, child: child),
            child: Center(child: error ?? Icon(LucideIcons.imageOff, size: 20, color: mark)),
          ),
        ),
      ),
    );
  }
}
