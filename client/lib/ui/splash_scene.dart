import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:material_ui/material_ui.dart';

import '../theme/app_tokens.dart';
import 'ambient_motion.dart';
import 'page_clock.dart';

/// The painted "coming home" scene behind the splash and the welcome screen (visuals/round-10),
/// one painting for both so the two screens flow into each other. A day and a night version follow
/// light and dark (like the D-388 wallpapers), in a wide cut for tablets, desktops and the web and a
/// tall one for phones.
///
/// Kept cheap on purpose: a WebP of about 1600 px with any veil baked in, decoded at the screen's
/// size (never full size), no blur. Its only motion is a very slow zoom ([driftScale] over
/// [driftPeriod], back and forth, ease in-out), a transform of one cached layer; it's off with
/// Reduce Motion and pauses whenever the screen isn't ticking. On the web it keeps in step with
/// the loading page's own CSS zoom (web/index.html) through the page clock. It never holds up startup: the plain
/// background shows until the picture is decoded, then the painting fades in. Every [SplashScene]
/// on screen holds it, and the decoded picture is dropped from the image cache once the last one
/// goes, a frame later (after the welcome screen, or after the splash for someone who's already set up).
class SplashScene extends StatefulWidget {
  const SplashScene({
    super.key,
    required this.brightness,
    required this.background,
  });

  /// Which version to show. The splash follows the system (the saved theme isn't loaded yet).
  final Brightness brightness;

  /// The plain color under the painting, shown until it's ready.
  final Color background;

  /// How far the slow zoom goes, and how long one way takes (web/index.html uses the same).
  static const driftScale = 1.05;
  static const driftPeriod = Duration(seconds: 16);

  /// Where the zoom is at [ms] since the page started: 0 to 1, and whether it's going in.
  static (double, bool) driftAt(double ms) {
    final p = driftPeriod.inMilliseconds.toDouble();
    final cycle = ms % (2 * p);
    return cycle < p ? (cycle / p, true) : (2 - cycle / p, false);
  }

  static const _wideRatio = 3 / 2;
  static const _tallRatio = 2 / 3;

  /// The painting's own size; decode never goes above it.
  static const _wideSize = Size(1600, 1067);
  static const _tallSize = Size(1067, 1600);

  /// The asset for this screen shape and brightness.
  static String assetFor(Size screen, Brightness brightness) {
    final time = brightness == Brightness.dark ? 'night' : 'day';
    return 'assets/scene/scene-$time-${_isWide(screen) ? 'wide' : 'tall'}.webp';
  }

  static bool _isWide(Size screen) {
    if (screen.height <= 0) return true;
    final r = screen.width / screen.height;
    // Pick the cut that crops the least.
    return (math.log(r / _wideRatio)).abs() <= (math.log(r / _tallRatio)).abs();
  }

  /// The picture as an image provider decoded to cover [screen] at [dpr], so [precache] and the
  /// screen share one cache entry.
  static ImageProvider providerFor(
    Size screen,
    double dpr,
    Brightness brightness,
  ) {
    if (kIsWeb) {
      // The web loading screen's own lighter copy (web/splash/, ~20-60 KB), already in the browser
      // cache by the time Flutter draws, so the hand-off from the loading page doesn't flash.
      final time = brightness == Brightness.dark ? 'night' : 'day';
      return ResizeImage(
        NetworkImage('splash/scene-$time-wide.webp'),
        width: (screen.width * dpr * driftScale).round().clamp(64, 1536),
        policy: ResizeImagePolicy.fit,
      );
    }
    final wide = _isWide(screen);
    final own = wide ? _wideSize : _tallSize;
    // BoxFit.cover scales the painting until it fills both sides; decode at that width.
    final scale = math.max(
      screen.width / own.width,
      screen.height / own.height,
    );
    final width = (own.width * scale * dpr).round().clamp(
      64,
      own.width.toInt(),
    );
    return ResizeImage(
      AssetImage(assetFor(screen, brightness)),
      width: width,
      policy: ResizeImagePolicy.fit,
    );
  }

  /// Starts decoding the picture this screen will show, without waiting for it. Call it as soon as
  /// there's a context; a failure only means the plain background stays.
  static void precache(BuildContext context, {Brightness? brightness}) {
    final media = MediaQuery.maybeOf(context);
    if (media == null || media.size.isEmpty) return;
    final provider = providerFor(
      media.size,
      media.devicePixelRatio,
      brightness ?? media.platformBrightness,
    );
    unawaited(precacheImage(provider, context, onError: (_, _) {}));
  }

  static final _clock = Stopwatch();
  static int _holders = 0;
  static final _held = <ImageProvider>{};

  @override
  State<SplashScene> createState() => _SplashSceneState();
}

class _SplashSceneState extends State<SplashScene>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drift;
  late final CurvedAnimation _eased;

  @override
  void initState() {
    super.initState();
    SplashScene._holders++;
    // On the web, start where the loading page's zoom is now, so the hand-off doesn't jump.
    // Elsewhere, every scene shares one clock, so the welcome screen picks up where the splash is.
    final (value, goingIn) = SplashScene.driftAt(
      pageClockMs() ??
          (SplashScene._clock..start()).elapsedMilliseconds.toDouble(),
    );
    _drift = AnimationController(
      vsync: this,
      duration: SplashScene.driftPeriod,
      value: value,
    );
    _eased = CurvedAnimation(parent: _drift, curve: Curves.easeInOut);
    _goingIn = goingIn;
  }

  var _goingIn = true;
  var _reduced = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = !ambientMotionOn(context);
    if (reduced == _reduced && (_drift.isAnimating || reduced)) return;
    _reduced = reduced;
    if (reduced) {
      _drift.stop();
      _drift.value = 0;
      return;
    }
    _drift.removeStatusListener(_turn);
    _drift.addStatusListener(_turn);
    _goingIn ? _drift.forward() : _drift.reverse();
  }

  void _turn(AnimationStatus status) {
    if (status == AnimationStatus.completed) _drift.reverse();
    if (status == AnimationStatus.dismissed) _drift.forward();
  }

  @override
  void dispose() {
    _eased.dispose();
    _drift.dispose();
    SplashScene._holders--;
    if (SplashScene._holders <= 0) {
      SplashScene._holders = 0;
      // Let go once a frame has passed with no scene on screen. The splash and the welcome screen
      // overlap during the fade between them, so the hand-over keeps it.
      final binding = WidgetsBinding.instance;
      binding.addPostFrameCallback((_) {
        if (SplashScene._holders > 0) return;
        for (final p in SplashScene._held) {
          unawaited(p.evict());
        }
        SplashScene._held.clear();
      });
      binding.scheduleFrame();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final provider = SplashScene.providerFor(
      media.size,
      media.devicePixelRatio,
      widget.brightness,
    );
    SplashScene._held.add(provider);
    final image = RepaintBoundary(
      child: Image(
        key: const Key('splashScene'),
        image: provider,
        fit: BoxFit.cover,
        // The scene's interest is in its bottom third; keep that in view when cropping.
        alignment: const Alignment(0, 0.4),
        filterQuality: FilterQuality.medium,
        gaplessPlayback: true,
        excludeFromSemantics: true,
        width: double.infinity,
        height: double.infinity,
        frameBuilder: (context, child, frame, sync) {
          if (sync) return child;
          return AnimatedOpacity(
            opacity: frame == null ? 0 : 1,
            duration: AppMotion.of(context, const Duration(milliseconds: 450)),
            curve: Curves.easeOut,
            child: child,
          );
        },
        errorBuilder: (_, _, _) => const SizedBox.expand(),
      ),
    );
    return ColoredBox(
      color: widget.background,
      child: ClipRect(
        child: AnimatedBuilder(
          animation: _eased,
          child: image,
          builder: (context, child) => Transform.scale(
            scale: 1 + (SplashScene.driftScale - 1) * _eased.value,
            alignment: const Alignment(0, 0.4),
            child: child,
          ),
        ),
      ),
    );
  }
}
