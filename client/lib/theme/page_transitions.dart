import 'package:material_ui/material_ui.dart';

import 'wallpaper.dart';

/// How far a page travels in a shared-axis transition: enough to say which way you went, short
/// enough that the page never seems to slide across the one under it.
const double _travel = 30;

/// How far a full-screen dialog rises as it opens.
const double _rise = 48;

/// Picks a value by the direction its animation runs: [forward] while it runs forward (and at
/// rest), [reverse] while it runs back. Read on demand, so it holds no listeners to dispose.
class _ByDirection extends Animatable<double> {
  const _ByDirection(this.forward, this.reverse);
  final double Function(double t) forward;
  final double Function(double t) reverse;

  @override
  double transform(double t) => forward(t);

  @override
  double evaluate(Animation<double> animation) =>
      animation.status == AnimationStatus.reverse
      ? reverse(animation.value)
      : forward(animation.value);
}

// The page on top. Pushed, it waits out the first 30% (while the page under it fades away), then
// fades in and settles into place. Popped, it fades out in the first 30% while moving off.
double _topOpacityIn(double t) =>
    const Interval(0.3, 1, curve: Curves.easeOut).transform(t);
double _topOpacityOut(double t) => const Interval(0.7, 1).transform(t);
double _topTravelIn(double t) => 1 - Curves.easeOutCubic.transform(t);
double _topTravelOut(double t) => 1 - Curves.easeInCubic.transform(t);

// The page underneath, driven by the top page's animation. A push fades it out in the first 30%
// as it moves aside; a pop brings it back once the top page has gone, settling as it fades in.
double _underOpacityPush(double t) => 1 - const Interval(0, 0.3).transform(t);
double _underOpacityPop(double t) =>
    1 -
    const Interval(0, 0.7, curve: FlippedCurve(Curves.easeOut)).transform(t);
double _underTravelPush(double t) => Curves.easeOutCubic.transform(t);
double _underTravelPop(double t) => Curves.easeInCubic.transform(t);

/// Opacity and travel (0 = in place, 1 = a full [_travel] away) of the page on top.
const _topOpacity = _ByDirection(_topOpacityIn, _topOpacityOut);
const _topTravel = _ByDirection(_topTravelIn, _topTravelOut);

/// The same for the page underneath, from its secondary animation.
const _underOpacity = _ByDirection(_underOpacityPush, _underOpacityPop);
const _underTravel = _ByDirection(_underTravelPush, _underTravelPop);

/// Fades [child] and moves it along one axis: [distance] logical pixels times [travel] (flipped in
/// right-to-left text on the x axis).
class _FadeAndMove extends StatelessWidget {
  const _FadeAndMove({
    required this.animation,
    required this.opacity,
    required this.travel,
    required this.distance,
    this.vertical = false,
    required this.child,
  });

  final Animation<double> animation;
  final Animatable<double> opacity;
  final Animatable<double> travel;
  final double distance;
  final bool vertical;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final moved = travel.animate(animation);
    final sign = !vertical && Directionality.of(context) == TextDirection.rtl
        ? -1.0
        : 1.0;
    return FadeTransition(
      opacity: opacity.animate(animation),
      child: AnimatedBuilder(
        animation: moved,
        child: child,
        builder: (context, child) {
          final d = sign * distance * moved.value;
          return Transform.translate(
            offset: vertical ? Offset(0, d) : Offset(d, 0),
            child: child,
          );
        },
      ),
    );
  }
}

/// Android: pages go forward and back along the x axis with Material's shared-axis motion. The
/// page leaving fades out in the first 30% of the transition and the page arriving fades in over
/// the rest, so the two are never on screen together. Pages are see-through over the one
/// wallpaper the app paints behind every navigator (see [Wallpaper]), and that wallpaper never
/// moves: nothing blacks out, flashes or shows twice. (Flutter's Android transition paints the
/// theme's surface color behind the leaving page, which blacked out the wallpaper on every page.)
///
/// Full-screen dialogs rise over the page instead, on their own copy of the wallpaper.
class SharedAxisPageTransitionsBuilder extends PageTransitionsBuilder {
  const SharedAxisPageTransitionsBuilder();

  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);

  // The page under a non-Material page (a tab, a custom route) moves aside the same way.
  @override
  DelegatedTransitionBuilder? get delegatedTransition => _underTransition;

  static Widget? _underTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    bool allowSnapshotting,
    Widget? child,
  ) => sharedAxisUnder(secondaryAnimation, child);

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (route.fullscreenDialog) {
      // The page under a full-screen dialog stays put, so the dialog covers it.
      return _FadeAndMove(
        animation: animation,
        opacity: const _ByDirection(_dialogOpacityIn, _dialogOpacityOut),
        travel: _topTravel,
        distance: _rise,
        vertical: true,
        child: Wallpaper(child: child),
      );
    }
    return _FadeAndMove(
      animation: animation,
      opacity: _topOpacity,
      travel: _topTravel,
      distance: _travel,
      child: sharedAxisUnder(secondaryAnimation, child),
    );
  }

  static double _dialogOpacityIn(double t) =>
      const Interval(0, 0.6, curve: Curves.easeOut).transform(t);
  static double _dialogOpacityOut(double t) =>
      const Interval(0.5, 1).transform(t);
}

/// How a page moves aside while another opens over it with [SharedAxisPageTransitionsBuilder]
/// (and comes back when that one closes): [secondaryAnimation] is the page on top's animation.
Widget sharedAxisUnder(Animation<double> secondaryAnimation, Widget? child) =>
    _FadeAndMove(
      animation: secondaryAnimation,
      opacity: _underOpacity,
      travel: _underTravel,
      distance: -_travel,
      child: child,
    );

/// iOS: the native slide, with the swipe back from the edge. A sliding page has to cover the page
/// under it, so each page paints its own copy of the wallpaper, lined up with the window on every
/// frame of the slide: the wallpaper looks still and only the content moves.
class OpaquePageTransitionsBuilder extends PageTransitionsBuilder {
  const OpaquePageTransitionsBuilder(this.base);
  final PageTransitionsBuilder base;

  @override
  Duration get transitionDuration => base.transitionDuration;

  @override
  Duration get reverseTransitionDuration => base.reverseTransitionDuration;

  @override
  DelegatedTransitionBuilder? get delegatedTransition =>
      base.delegatedTransition;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => base.buildTransitions(
    route,
    context,
    animation,
    secondaryAnimation,
    Wallpaper(child: child),
  );
}

/// The web and desktop: the page appears at once, with no transition, over the wallpaper the app
/// paints behind every navigator.
class InstantPageTransitionsBuilder extends PageTransitionsBuilder {
  const InstantPageTransitionsBuilder();

  @override
  Duration get transitionDuration => Duration.zero;

  @override
  Duration get reverseTransitionDuration => Duration.zero;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => child;
}

// Switching tabs: the tab you leave fades out in the first 35%, then the one you open fades in and
// grows from 98% (Material's fade through).
double _tabOpacityIn(double t) =>
    const Interval(0.35, 1, curve: Curves.easeOut).transform(t);
double _tabOpacityOut(double t) => const Interval(0.65, 1).transform(t);
double _tabScaleIn(double t) => 0.98 + 0.02 * Curves.easeOutCubic.transform(t);
double _tabScaleOut(double t) => 1;
// The tab you leave, from the new tab's animation: it isn't popped (the router swaps the page),
// so it stays in place, fully shown, unless it fades out on the new tab's animation.
double _tabUnderOpacity(double t) => 1 - const Interval(0, 0.35).transform(t);

/// How long switching tabs takes on phones and tablets.
const tabSwitchDuration = Duration(milliseconds: 250);

/// The Chats, Inbox and Tasks tabs fade through each other: the tab you leave is gone before the
/// one you open appears, so their lists never overlap on the see-through pages.
Widget fadeThrough(
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) => FadeTransition(
  opacity: const _ByDirection(
    _tabUnderOpacity,
    _tabUnderOpacity,
  ).animate(secondaryAnimation),
  child: FadeTransition(
    opacity: const _ByDirection(
      _tabOpacityIn,
      _tabOpacityOut,
    ).animate(animation),
    child: ScaleTransition(
      scale: const _ByDirection(_tabScaleIn, _tabScaleOut).animate(animation),
      child: child,
    ),
  ),
);
