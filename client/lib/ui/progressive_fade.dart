import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Dissolves a page's content as it scrolls up under the status bar, on pages with no app bar, so
/// it never collides with the clock and battery.
///
/// Wrap the page body, and let the scroll view start at the very top of the screen: use
/// `SafeArea(top: false)` and add the status bar's height (`MediaQuery.paddingOf(context).top`) to
/// the scroll view's top padding, so content at rest still starts below the status bar. The mask is
/// alpha-only: it fades the content itself, over any background, in light and dark mode.
class ProgressiveFade extends StatelessWidget {
  const ProgressiveFade({super.key, required this.child, this.height});

  final Widget child;

  /// How far down the fade reaches, in logical pixels. Defaults to the status bar's height plus
  /// [AppSpace.lg], so content resting below the status bar stays fully visible.
  final double? height;

  /// How far the fade reaches under a status bar [statusBar] logical pixels tall: nowhere when there
  /// is none (desktop, web, a phone in landscape), since nothing scrolls under one there.
  static double reachFor(double statusBar, {double? height}) => statusBar <= 0 ? 0.0 : (height ?? statusBar + AppSpace.lg);

  @override
  Widget build(BuildContext context) {
    final reach = reachFor(MediaQuery.paddingOf(context).top, height: height);
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (bounds) {
        // Measured against the masked area, not the screen: the keyboard makes the body shorter.
        final end = bounds.height <= 0 ? 0.0 : (reach / bounds.height).clamp(0.0, 1.0);
        if (end == 0) return const LinearGradient(colors: [Color(0xFFFFFFFF), Color(0xFFFFFFFF)]).createShader(bounds);
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          // Several steps ease the content out; two colors would give a hard, linear cut.
          colors: const [Color(0x00FFFFFF), Color(0x26FFFFFF), Color(0x66FFFFFF), Color(0xB3FFFFFF), Color(0xFFFFFFFF)],
          stops: [0, end * 0.25, end * 0.5, end * 0.75, end],
        ).createShader(bounds);
      },
      child: child,
    );
  }
}
