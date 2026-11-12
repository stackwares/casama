import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:lottie/lottie.dart';

import '../theme/app_tokens.dart';
import 'splash_art.g.dart';

/// The launch cloud, then its loop.
///
/// Native launch screens cannot play Lottie, so they show the first frame of
/// [lottieAsset] (made by scripts/casama-splash.py). This draws that same crop, at the same
/// width, centred on the same background, and then lets the loop play. The still stands in
/// until the composition has decoded, and whenever the system asks for reduced motion.
class BrandSplash extends StatefulWidget {
  const BrandSplash({super.key, this.composition, this.label});

  static const stillAsset = 'assets/mascots/brand-splash.png';
  static const lottieAsset = 'assets/mascots/brand.json';

  /// Launch-screen background. The saved theme is not applied yet, so this follows the system.
  static const lightBackground = Color(0xFFFCF3FB);
  static const darkBackground = Color(0xFF25102F);

  /// How the cloud leaves once the app is ready. [AppMotion.of] drops it to zero for Reduce Motion.
  static const exitDuration = Duration(milliseconds: 300);

  /// "Connecting…" waits this long, so a fast launch never flashes the line.
  static const labelDelay = Duration(milliseconds: 1500);

  /// The decoded loop. Null until [lottieAsset] has loaded.
  final LottieComposition? composition;

  /// Painted under the cloud once [labelDelay] has passed.
  final Widget? label;

  static Color backgroundOf(BuildContext context) => MediaQuery.platformBrightnessOf(context) == Brightness.dark ? darkBackground : lightBackground;

  /// Cloud width in logical pixels. Android's launch icon is smaller so it fits the system
  /// splash's circle mask; every other platform matches the 160-wide launch image.
  static double widthOf(BuildContext context) {
    if (kIsWeb) return splashCloudWidth;
    return Theme.of(context).platform == TargetPlatform.android ? splashCloudWidthAndroid : splashCloudWidth;
  }

  @override
  State<BrandSplash> createState() => _BrandSplashState();
}

class _BrandSplashState extends State<BrandSplash> {
  Timer? _labelTimer;
  var _showLabel = false;

  @override
  void initState() {
    super.initState();
    if (widget.label != null) {
      _labelTimer = Timer(BrandSplash.labelDelay, () {
        if (mounted) setState(() => _showLabel = true);
      });
    }
  }

  @override
  void dispose() {
    _labelTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = BrandSplash.widthOf(context);
    final box = splashCloudBox;
    final cloudW = box.right - box.left;
    final cloudH = box.bottom - box.top;
    final scale = width / cloudW;
    final height = cloudH * scale;
    final animate = widget.composition != null && !MediaQuery.disableAnimationsOf(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: _cloud(width: width, height: height, scale: scale, animate: animate),
            ),
            if (_showLabel && widget.label != null) Positioned(left: 32, right: 32, top: constraints.maxHeight / 2 + height / 2 + 16, child: widget.label!),
          ],
        );
      },
    );
  }

  /// The launch screens show [splashCloudBox] of the 256² loop, scaled to [width]. The loop is
  /// shifted so that crop sits in the same centred box as the still.
  Widget _cloud({required double width, required double height, required double scale, required bool animate}) {
    final box = splashCloudBox;
    final full = 256.0 * scale;
    final still = Image.asset(
      BrandSplash.stillAsset,
      key: const Key('startupSplashStill'),
      width: width,
      height: height,
      fit: BoxFit.fill,
      filterQuality: FilterQuality.medium,
      gaplessPlayback: true,
      excludeFromSemantics: true,
    );
    final composition = widget.composition;
    Widget art = still;
    if (animate && composition != null) {
      // BoxFit.fill, not the default scaleDown: the composition's intrinsic size is 256, and the
      // launch crop is drawn smaller than that, so the art must be scaled to this rectangle.
      art = ClipRect(
        child: OverflowBox(
          alignment: Alignment.topLeft,
          minWidth: full,
          maxWidth: full,
          minHeight: full,
          maxHeight: full,
          child: Transform.translate(
            offset: Offset(-box.left * scale, -box.top * scale),
            child: Lottie(composition: composition, width: full, height: full, fit: BoxFit.fill, frameRate: FrameRate.max, filterQuality: FilterQuality.medium),
          ),
        ),
      );
    }
    return SizedBox(key: const Key('startupSplashArt'), width: width, height: height, child: art);
  }
}

/// Fades and slightly scales [child] away over [BrandSplash.exitDuration] once [leaving] is set.
/// Reduce Motion skips the fade. The widget stays in place before that, so the cloud's state
/// (the loop, the delayed label) is not rebuilt when the app becomes ready.
class SplashHandoff extends StatefulWidget {
  const SplashHandoff({super.key, required this.leaving, required this.onLeft, required this.child});

  final bool leaving;
  final VoidCallback onLeft;
  final Widget child;

  @override
  State<SplashHandoff> createState() => _SplashHandoffState();
}

class _SplashHandoffState extends State<SplashHandoff> with SingleTickerProviderStateMixin {
  late final AnimationController _exit;
  late final CurvedAnimation _curve;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  var _started = false;

  @override
  void initState() {
    super.initState();
    _exit = AnimationController(vsync: this, duration: BrandSplash.exitDuration);
    _curve = CurvedAnimation(parent: _exit, curve: Curves.easeOutCubic);
    _fade = Tween<double>(begin: 1, end: 0).animate(_curve);
    _scale = Tween<double>(begin: 1, end: 0.94).animate(_curve);
    _exit.addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onLeft();
    });
    if (widget.leaving) _begin();
  }

  @override
  void didUpdateWidget(SplashHandoff oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.leaving && !oldWidget.leaving) _begin();
  }

  void _begin() {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _exit.duration = AppMotion.of(context, BrandSplash.exitDuration);
      _exit.forward();
    });
  }

  @override
  void dispose() {
    _curve.dispose();
    _exit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      key: const Key('startupSplashFade'),
      opacity: _fade,
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}
