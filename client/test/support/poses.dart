// The windows an iPhone Duo gives an app (docs/IPHONE-DUO-PLAN.md §2.2), for tests: the size, the
// safe-area insets, and the fold. Run the test as an iPhone
// (`variant: TargetPlatformVariant.only(TargetPlatform.iOS)`): the side strip exists only there.
import 'dart:ui' show DisplayFeature, DisplayFeatureState, DisplayFeatureType;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class DuoPose {
  const DuoPose(
    this.name,
    this.size, {
    this.padding = FakeViewPadding.zero,
    this.fold,
    this.folded = false,
  });

  final String name;
  final Size size;
  final FakeViewPadding padding;

  /// The fold's band in the window, known while the inner screen is the one in use.
  final Rect? fold;

  /// The band divides the window (the device is partly folded).
  final bool folded;

  /// The outer screen, upright. The strip is the 84 points on the right.
  static const closed = DuoPose(
    'closed',
    Size(466, 678),
    padding: FakeViewPadding(right: 84, bottom: 34),
  );

  /// The outer screen on its side, standing on its edges.
  static const tent = DuoPose(
    'tent',
    Size(678, 466),
    padding: FakeViewPadding(left: 84, bottom: 34),
  );

  /// The inner screen lying flat, wide.
  static const openWide = DuoPose(
    'open wide',
    Size(951, 669),
    padding: FakeViewPadding(right: 84, bottom: 34),
    // Flat, a fold has no width: Flutter splits dialogs around any fold that has one.
    fold: Rect.fromLTWH(475.5, 0, 0, 669),
  );

  /// The inner screen held wide and partly folded.
  static const book = DuoPose(
    'book',
    Size(951, 669),
    padding: FakeViewPadding(right: 84, bottom: 34),
    fold: Rect.fromLTWH(455.5, 0, 40, 669),
    folded: true,
  );

  /// The inner screen lying flat, tall.
  static const openTall = DuoPose(
    'open tall',
    Size(669, 951),
    padding: FakeViewPadding(top: 82, bottom: 34),
    fold: Rect.fromLTWH(0, 475.5, 669, 0),
  );

  /// The inner screen propped up, the fold across the middle.
  static const laptop = DuoPose(
    'laptop',
    Size(669, 951),
    padding: FakeViewPadding(top: 82, bottom: 34),
    fold: Rect.fromLTWH(0, 455.5, 669, 40),
    folded: true,
  );

  /// Half the inner screen, beside another app.
  static const splitView = DuoPose(
    'split view',
    Size(469, 669),
    padding: FakeViewPadding(bottom: 34),
  );

  static const all = [
    closed,
    tent,
    openWide,
    book,
    openTall,
    laptop,
    splitView,
  ];

  @override
  String toString() => name;
}

/// Puts the test's window in [pose]. Call again to fold, unfold, open or close the device.
void setPose(WidgetTester tester, DuoPose pose) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = pose.size;
  tester.view.padding = pose.padding;
  tester.view.viewPadding = pose.padding;
  tester.view.displayFeatures = [
    if (pose.fold case final fold?)
      DisplayFeature(
        bounds: fold,
        type: DisplayFeatureType.fold,
        state: pose.folded
            ? DisplayFeatureState.postureHalfOpened
            : DisplayFeatureState.postureFlat,
      ),
  ];
  addTearDown(tester.view.reset);
}
