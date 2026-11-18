import 'dart:async';
import 'dart:ui' show DisplayFeature, DisplayFeatureState, DisplayFeatureType;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Folding phones (D-411): what the window is on right now. One description for the iPhone Duo and
/// Android foldables, worked out from the window itself, so nothing asks "is this a Duo".
///
/// The fold comes from [MediaQueryData.displayFeatures] where Flutter fills it (Android), and from
/// our own bridge (`casama/fold`, `FoldBridge` in ios/Runner/AppDelegate.swift) where it doesn't
/// yet (iOS, flutter/flutter#193025). The strip is the column iOS keeps down one side of an iPhone
/// Duo for the camera, the clock and the battery: Apple's apps put their buttons and tabs there,
/// and so do we (ui/side_strip.dart).

/// What the hinge says.
enum HingeStatus { unknown, closed, partlyOpen, open }

/// Which side of the window the strip is on. It follows the hardware, not the language.
enum StripSide { none, left, right }

/// How the device is held. `plain` is every window without a fold or a strip.
enum Pose {
  plain,

  /// iPhone Duo closed: the outer screen, upright.
  closed,

  /// The outer screen on its side, standing on its edges: hands-free.
  tent,

  /// The inner screen lying flat, wider than tall.
  openWide,

  /// The inner screen held wide and partly folded, the fold running top to bottom.
  book,

  /// The inner screen lying flat, taller than wide.
  openTall,

  /// The inner screen propped up, the fold running side to side.
  laptop,
}

/// What iOS reports through the bridge. Empty on every other platform, on iOS before 27.1 and on
/// an iPhone without a hinge.
@immutable
class NativeFold {
  const NativeFold({
    this.known = false,
    this.hinge = HingeStatus.unknown,
    this.angle,
    this.fold,
    this.foldActive = false,
    this.bar = StripSide.none,
    this.statusFrame,
    this.cameras = const [],
    this.fullScreen = true,
  });

  static const none = NativeFold();

  /// The device has a hinge and the bridge has reported at least once.
  final bool known;
  final HingeStatus hinge;

  /// Degrees, 0 closed to 180 flat. For effects only; layout follows [hinge] and the fold.
  final double? angle;

  /// The fold's band in the Flutter view's coordinates. Reported while flat too.
  final Rect? fold;

  /// iOS says the band divides the window right now.
  final bool foldActive;

  /// Where UIKit puts its vertical bar (`verticalBarEdge`), as a side of the window.
  final StripSide bar;

  /// The status bar's frame as UIKit gives it. On an iPhone Duo it is a sliver across the top and
  /// says nothing about the strip; kept for the readout.
  final Rect? statusFrame;

  /// What iOS says is covered right now (its "occlusion" regions): the camera, and the part of
  /// the strip that holds the clock and the battery. That part is at the top of the strip with
  /// the phone upright and can be at the bottom with it on its side.
  final List<Rect> cameras;

  /// UIKit's full-screen flag for the scene. Read as false in every pose on the simulator, so
  /// nothing depends on it; kept for the readout.
  final bool fullScreen;

  static Rect? _rect(Object? v) {
    if (v is! List || v.length < 4) return null;
    final n = [for (final e in v.take(4)) (e as num).toDouble()];
    return Rect.fromLTWH(n[0], n[1], n[2], n[3]);
  }

  factory NativeFold.fromMap(Map<Object?, Object?> m) => NativeFold(
    known: m['hinge'] != null,
    hinge: switch (m['hinge']) {
      'closed' => HingeStatus.closed,
      'partlyOpen' => HingeStatus.partlyOpen,
      'open' => HingeStatus.open,
      _ => HingeStatus.unknown,
    },
    angle: (m['angle'] as num?)?.toDouble(),
    fold: _rect(m['fold']),
    foldActive: m['foldActive'] == true,
    bar: switch (m['bar']) {
      'left' => StripSide.left,
      'right' => StripSide.right,
      _ => StripSide.none,
    },
    statusFrame: _rect(m['status']),
    cameras: [for (final c in (m['cameras'] as List?) ?? const []) ?_rect(c)],
    fullScreen: m['fullScreen'] != false,
  );

  @override
  bool operator ==(Object other) =>
      other is NativeFold &&
      other.known == known &&
      other.hinge == hinge &&
      other.angle == angle &&
      other.fold == fold &&
      other.foldActive == foldActive &&
      other.bar == bar &&
      other.statusFrame == statusFrame &&
      listEquals(other.cameras, cameras) &&
      other.fullScreen == fullScreen;

  @override
  int get hashCode => Object.hash(
    known,
    hinge,
    angle,
    fold,
    foldActive,
    bar,
    statusFrame,
    Object.hashAll(cameras),
    fullScreen,
  );

  @override
  String toString() =>
      'NativeFold(known: $known, hinge: ${hinge.name}, angle: ${angle?.toStringAsFixed(1)}, fold: $fold, active: $foldActive, '
      'bar: ${bar.name}, status: $statusFrame, cameras: $cameras, fullScreen: $fullScreen)';
}

class NativeFoldNotifier extends Notifier<NativeFold> {
  static const _events = EventChannel('casama/fold');

  @override
  NativeFold build() {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) {
      return NativeFold.none;
    }
    // No bridge on the other end (iOS before 27.1, a test) is an error on the stream, not a throw.
    final sub = _events.receiveBroadcastStream().listen((e) {
      if (e is! Map) return;
      state = NativeFold.fromMap(e);
      // Debug builds say what iOS reported, for checking a layout against the device.
      assert(() {
        debugPrint('casama/fold: $state');
        return true;
      }());
    }, onError: (Object _) {});
    ref.onDispose(() => unawaited(sub.cancel()));
    return NativeFold.none;
  }
}

/// The hinge, fold and status area as iOS reports them.
final nativeFoldProvider = NotifierProvider<NativeFoldNotifier, NativeFold>(
  NativeFoldNotifier.new,
);

class _Off extends Notifier<bool> {
  @override
  bool build() => false;
  void set(bool on) => state = on;
}

/// The hinge drives the list pane's arrival while the device opens: the pane comes in as far as
/// the device is open, instead of on a clock. Off until it has been tried on a real iPhone Duo:
/// nobody has published a real hinge reading yet, only the simulator's (IPHONE-DUO-PLAN §9).
final hingeMotionProvider = NotifierProvider<_Off, bool>(_Off.new);

/// The window, described once: its pose, where the fold is, and where the strip is.
@immutable
class FoldInfo {
  const FoldInfo({
    this.pose = Pose.plain,
    this.fold,
    this.foldActive = false,
    this.strip = StripSide.none,
    this.stripWidth = 0,
    this.stripTop = 0,
    this.stripBottom = 0,
    this.hinge = HingeStatus.unknown,
    this.angle,
  });

  static const plain = FoldInfo();

  /// The narrowest side inset that is a strip rather than a notch. iPhones on their side have 59
  /// points on both sides; the Duo has 84 on one side and nothing on the other.
  static const double minStripWidth = 60;

  /// How far down the strip iOS draws (the camera, the clock, the battery) on the outer screen,
  /// for when iOS doesn't say: it reports that part as a covered region, 174 points tall there
  /// and 124 on the inner screen (read on the iPhone Duo simulator, iOS 27.2).
  static const double defaultStripTop = 182;

  /// The room left clear at an end of the strip iOS draws nothing in: the screen's corner is
  /// round there.
  static const double stripCornerClearance = 24;

  /// The margin on the strip's outer side. iOS centers the camera, the clock and the battery 36
  /// points from the strip's inner edge, not in the middle of its 84 (seen on the simulator), so
  /// what we draw in the strip keeps this much off the screen's edge to line up with them.
  static const double stripOuterMargin = 12;

  final Pose pose;

  /// The fold's band in window coordinates, when the window has one. Zero-width while a device
  /// that reports it that way lies flat.
  final Rect? fold;

  /// The band divides the window now: nothing you can tap goes on it.
  final bool foldActive;

  final StripSide strip;
  final double stripWidth;

  /// Where our part of the strip starts, under what iOS draws at its top.
  final double stripTop;

  /// Where our part of the strip ends: above the home indicator, and above what iOS draws at the
  /// strip's bottom when the phone is on its side.
  final double stripBottom;

  final HingeStatus hinge;
  final double? angle;

  bool get hasStrip => strip != StripSide.none;

  /// The fold runs top to bottom (book); false when it runs side to side (laptop).
  bool get foldVertical => fold != null && fold!.width < fold!.height;

  /// Where two panes meet: the middle of a fold that runs top to bottom, active or not.
  double? get splitX => fold != null && foldVertical ? fold!.center.dx : null;

  /// Where a top half and a bottom half meet, while the fold divides the window that way.
  double? get splitY =>
      fold != null && foldActive && !foldVertical ? fold!.center.dy : null;

  /// The band to leave empty right now, or null.
  Rect? get gap => foldActive ? fold : null;

  static FoldInfo resolve({
    required Size size,
    required EdgeInsets viewPadding,
    required List<DisplayFeature> features,
    required NativeFold native,
    required bool ios,
  }) {
    Rect? fold;
    var active = false;
    for (final f in features) {
      if (f.type == DisplayFeatureType.fold) {
        fold = f.bounds;
        active = f.state == DisplayFeatureState.postureHalfOpened;
        break;
      }
      // A hinge is a physical gap: it always divides.
      if (f.type == DisplayFeatureType.hinge) {
        fold = f.bounds;
        active = f.bounds.shortestSide > 0;
        break;
      }
    }
    if (fold == null && native.known && native.fold != null) {
      fold = native.fold;
      // iOS's own flag lags the hinge by up to a second, so both have to agree (as Flutter's own
      // bridge does): a flat device never has a band splitting its dialogs.
      active =
          native.foldActive &&
          native.hinge == HingeStatus.partlyOpen &&
          fold!.shortestSide > 0;
    }
    // Only a fold that crosses this window counts (not one beside us in Split View).
    if (fold != null) {
      final vertical = fold.width < fold.height;
      final crosses = vertical
          ? fold.left > 0 &&
                fold.right < size.width &&
                fold.height >= size.height * 0.9
          : fold.top > 0 &&
                fold.bottom < size.height &&
                fold.width >= size.width * 0.9;
      if (!crosses) {
        fold = null;
        active = false;
      }
    }

    var strip = StripSide.none;
    var stripWidth = 0.0;
    if (ios) {
      if (viewPadding.right >= minStripWidth && viewPadding.left < 20) {
        strip = StripSide.right;
        stripWidth = viewPadding.right;
      } else if (viewPadding.left >= minStripWidth && viewPadding.right < 20) {
        strip = StripSide.left;
        stripWidth = viewPadding.left;
      }
    }
    var stripTop = 0.0;
    var stripBottom = size.height;
    if (strip != StripSide.none) {
      stripBottom = size.height - viewPadding.bottom - 8;
      final column = strip == StripSide.right
          ? Rect.fromLTRB(size.width - stripWidth, 0, size.width, size.height)
          : Rect.fromLTRB(0, 0, stripWidth, size.height);
      // What iOS covers in the strip is ours to keep clear of, whichever end it is at. A region
      // as tall as the strip is not a block at one end and says nothing.
      final taken = [
        for (final r in native.cameras)
          if (r.overlaps(column) && r.height < size.height * 0.6) r,
      ];
      if (taken.isEmpty) {
        stripTop = defaultStripTop;
      } else {
        stripTop = stripCornerClearance;
        for (final r in taken) {
          if (r.center.dy < size.height / 2) {
            if (r.bottom + 8 > stripTop) stripTop = r.bottom + 8;
          } else if (r.top - 8 < stripBottom) {
            stripBottom = r.top - 8;
          }
        }
      }
      if (stripBottom < stripTop) stripBottom = stripTop;
    }

    final vertical = fold != null && fold.width < fold.height;
    final Pose pose;
    if (fold != null && active) {
      pose = vertical ? Pose.book : Pose.laptop;
    } else if (strip != StripSide.none) {
      pose = size.width >= 840
          ? Pose.openWide
          : (size.width > size.height && size.height < 520
                ? Pose.tent
                : Pose.closed);
    } else if (fold != null) {
      pose = vertical ? Pose.openWide : Pose.openTall;
    } else if (native.known &&
        native.hinge != HingeStatus.closed &&
        size.height > size.width &&
        size.width >= 600) {
      pose = Pose.openTall;
    } else {
      pose = Pose.plain;
    }
    return FoldInfo(
      pose: pose,
      fold: fold,
      foldActive: active,
      strip: strip,
      stripWidth: stripWidth,
      stripTop: stripTop,
      stripBottom: stripBottom,
      hinge: native.hinge,
      angle: native.angle,
    );
  }

  /// The nearest [FoldScope]'s description, or [plain] where there is none (a screen pumped alone
  /// in a test).
  static FoldInfo of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_FoldData>()?.info ?? plain;

  @override
  bool operator ==(Object other) =>
      other is FoldInfo &&
      other.pose == pose &&
      other.fold == fold &&
      other.foldActive == foldActive &&
      other.strip == strip &&
      other.stripWidth == stripWidth &&
      other.stripTop == stripTop &&
      other.stripBottom == stripBottom &&
      other.hinge == hinge &&
      other.angle == angle;

  @override
  int get hashCode => Object.hash(
    pose,
    fold,
    foldActive,
    strip,
    stripWidth,
    stripTop,
    stripBottom,
    hinge,
    angle,
  );

  @override
  String toString() =>
      'FoldInfo(${pose.name}, fold: $fold, active: $foldActive, strip: ${strip.name} $stripWidth from $stripTop to $stripBottom, hinge: ${hinge.name})';
}

class _FoldData extends InheritedWidget {
  const _FoldData({required this.info, required super.child});
  final FoldInfo info;

  @override
  bool updateShouldNotify(_FoldData old) => old.info != info;
}

/// Works out the [FoldInfo] for the window and hands it to everything below. On iOS it also puts
/// the fold into [MediaQueryData.displayFeatures] while it divides the window, so Flutter's own
/// dialogs, menus and sheets keep clear of it as they do on Android.
class FoldScope extends ConsumerWidget {
  const FoldScope({super.key, required this.child});
  final Widget child;

  static String? _logged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final media = MediaQuery.of(context);
    final native = ref.watch(nativeFoldProvider);
    final info = FoldInfo.resolve(
      size: media.size,
      viewPadding: media.viewPadding,
      features: media.displayFeatures,
      native: native,
      ios: !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS,
    );
    assert(() {
      // Debug builds say what the window is whenever that changes.
      final line =
          'window ${media.size.width}x${media.size.height} insets ${media.viewPadding} -> $info';
      if (line != _logged) {
        _logged = line;
        if (info != FoldInfo.plain) debugPrint('fold: $line');
      }
      return true;
    }());
    Widget out = _FoldData(info: info, child: child);
    final gap = info.gap;
    final has = media.displayFeatures.any(
      (f) =>
          f.type == DisplayFeatureType.fold ||
          f.type == DisplayFeatureType.hinge,
    );
    // Stands down by itself the day Flutter reports the fold on iOS.
    if (gap != null && !has) {
      out = MediaQuery(
        data: media.copyWith(
          displayFeatures: [
            ...media.displayFeatures,
            DisplayFeature(
              bounds: gap,
              type: DisplayFeatureType.fold,
              state: DisplayFeatureState.postureHalfOpened,
            ),
          ],
        ),
        child: out,
      );
    }
    return out;
  }
}

/// What a pane of the window sees as its window: its own width, the safe-area insets of the edges
/// it touches, and only the display features inside it. Screens written for a phone then lay
/// themselves out for the pane without knowing they are in one.
MediaQueryData paneMedia(MediaQueryData media, Rect pane) {
  final width = media.size.width;
  final height = media.size.height;
  EdgeInsets cut(EdgeInsets e) => e.copyWith(
    left: pane.left > 0 ? 0 : e.left,
    right: pane.right < width ? 0 : e.right,
    top: pane.top > 0 ? 0 : e.top,
    bottom: pane.bottom < height ? 0 : e.bottom,
  );
  return media.copyWith(
    size: pane.size,
    padding: cut(media.padding),
    viewPadding: cut(media.viewPadding),
    displayFeatures: [
      for (final f in media.displayFeatures)
        if (f.bounds.left > pane.left && f.bounds.right < pane.right)
          DisplayFeature(
            bounds: f.bounds.shift(Offset(-pane.left, 0)),
            type: f.type,
            state: f.state,
          ),
    ],
  );
}

/// Gives a pane its own [FoldInfo]: the fold in the pane's coordinates if it crosses the pane, no
/// fold if it doesn't, and no strip (the shell owns the strip).
class FoldPane extends StatelessWidget {
  const FoldPane({super.key, required this.rect, required this.child});

  /// The pane in window coordinates.
  final Rect rect;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final window = FoldInfo.of(context);
    final fold = window.fold;
    final inside =
        fold != null &&
        (window.foldVertical
            ? fold.left > rect.left && fold.right < rect.right
            : fold.top > rect.top && fold.bottom < rect.bottom);
    return _FoldData(
      info: FoldInfo(
        pose: window.pose,
        fold: inside ? fold.shift(-rect.topLeft) : null,
        foldActive: inside && window.foldActive,
        hinge: window.hinge,
        angle: window.angle,
      ),
      child: child,
    );
  }
}

/// The whole window's [FoldInfo], asked from anywhere: inside a pane [FoldInfo.of] describes the
/// pane, and what covers the app (a sheet, a dialog, a toast) is placed in the window.
FoldInfo windowFold(BuildContext context) {
  final root = Navigator.maybeOf(context, rootNavigator: true)?.context;
  return FoldInfo.of(root ?? context);
}

/// Where a dialog or a menu opens while a fold divides the window: the trailing half of a fold
/// that runs top to bottom (close to where it will be when the device closes, as iOS does), the
/// lower half of one that runs side to side (the half you touch). Null without a dividing fold.
/// For `showDialog(anchorPoint:)`, which then keeps the dialog off the fold by itself.
Offset? foldAnchor(BuildContext context) {
  if (windowFold(context).gap == null) return null;
  final size = MediaQuery.sizeOf(
    Navigator.maybeOf(context, rootNavigator: true)?.context ?? context,
  );
  return Offset(
    Directionality.of(context) == TextDirection.rtl ? 0 : size.width,
    size.height,
  );
}

/// Side insets that keep what covers the app in the part of the window it belongs to: clear of
/// the strip, and in the trailing half while a fold that runs top to bottom divides the window.
/// [context] is the sheet's or dialog's own, under the root navigator.
EdgeInsets foldSideInsets(BuildContext context, {bool besideFold = true}) {
  final info = FoldInfo.of(context);
  var left = info.strip == StripSide.left ? info.stripWidth : 0.0;
  var right = info.strip == StripSide.right ? info.stripWidth : 0.0;
  final gap = info.gap;
  if (besideFold && gap != null && info.foldVertical) {
    final width = MediaQuery.sizeOf(context).width;
    if (Directionality.of(context) == TextDirection.rtl) {
      if (width - gap.left > right) right = width - gap.left;
    } else if (gap.right > left) {
      left = gap.right;
    }
  }
  return EdgeInsets.only(left: left, right: right);
}
