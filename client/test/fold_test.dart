// What the app works out about a folding phone's window (D-411): the pose, the fold and the side
// strip, from the window's size, its safe-area insets, the display features Flutter reports
// (Android) and what our iOS bridge reports.
import 'dart:ui' show DisplayFeature, DisplayFeatureState, DisplayFeatureType;

import 'package:casama/app.dart';
import 'package:casama/core/fold/fold.dart';
import 'package:casama/core/providers.dart';
import 'package:casama/features/bots/bots_screen.dart';
import 'package:casama/features/chat/chat_screen.dart';
import 'package:casama/ui/floating_tab_chrome.dart';
import 'package:casama/ui/side_strip.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_backend.dart';

FoldInfo _resolve(
  Size size, {
  EdgeInsets padding = EdgeInsets.zero,
  List<DisplayFeature> features = const [],
  NativeFold native = NativeFold.none,
  bool ios = true,
}) => FoldInfo.resolve(
  size: size,
  viewPadding: padding,
  features: features,
  native: native,
  ios: ios,
);

void main() {
  group('iPhone Duo, from what iOS reports', () {
    const strip = EdgeInsets.only(right: 84, bottom: 34);
    const band = Rect.fromLTWH(455.5, 0, 40, 669);

    test('closed: the strip on the right, no fold', () {
      final info = _resolve(const Size(466, 678), padding: strip);
      expect(info.pose, Pose.closed);
      expect(info.strip, StripSide.right);
      expect(info.stripWidth, 84);
      expect(info.stripTop, FoldInfo.defaultStripTop);
      expect(info.fold, isNull);
    });

    test('tent: the outer screen on its side, the strip on the left', () {
      final info = _resolve(
        const Size(678, 466),
        padding: const EdgeInsets.only(left: 84, bottom: 34),
      );
      expect(info.pose, Pose.tent);
      expect(info.strip, StripSide.left);
    });

    test('open wide: the fold is known and does not divide', () {
      final info = _resolve(
        const Size(951, 669),
        padding: strip,
        native: const NativeFold(
          known: true,
          hinge: HingeStatus.open,
          fold: band,
        ),
      );
      expect(info.pose, Pose.openWide);
      expect(info.gap, isNull);
      expect(info.splitX, 475.5);
    });

    test('book: the fold divides once the hinge and the region agree', () {
      // The region lags the hinge: partly open, not yet active.
      var info = _resolve(
        const Size(951, 669),
        padding: strip,
        native: const NativeFold(
          known: true,
          hinge: HingeStatus.partlyOpen,
          fold: band,
        ),
      );
      expect(info.gap, isNull);
      info = _resolve(
        const Size(951, 669),
        padding: strip,
        native: const NativeFold(
          known: true,
          hinge: HingeStatus.partlyOpen,
          fold: band,
          foldActive: true,
        ),
      );
      expect(info.pose, Pose.book);
      expect(info.gap, band);
      expect(info.foldVertical, isTrue);
      // Laid flat again: the hinge says so at once, whatever the region still says.
      info = _resolve(
        const Size(951, 669),
        padding: strip,
        native: const NativeFold(
          known: true,
          hinge: HingeStatus.open,
          fold: band,
          foldActive: true,
        ),
      );
      expect(info.gap, isNull);
    });

    test('laptop: the fold runs side to side', () {
      final info = _resolve(
        const Size(669, 951),
        padding: const EdgeInsets.only(top: 82, bottom: 34),
        native: const NativeFold(
          known: true,
          hinge: HingeStatus.partlyOpen,
          fold: Rect.fromLTWH(0, 455.5, 669, 40),
          foldActive: true,
        ),
      );
      expect(info.pose, Pose.laptop);
      expect(info.foldVertical, isFalse);
      expect(info.splitY, 475.5);
      expect(info.splitX, isNull);
    });

    // The regions below are what the iPhone Duo simulator (iOS 27.2) reported in each pose.
    test(
      'what iOS covers at the top of the strip says where its free part starts',
      () {
        final outer = _resolve(
          const Size(466, 678),
          padding: strip,
          native: const NativeFold(
            known: true,
            hinge: HingeStatus.closed,
            cameras: [
              Rect.fromLTRB(399.7, 29.3, 436.7, 66.3),
              Rect.fromLTRB(382, 0, 466, 174),
            ],
          ),
        );
        expect(outer.stripTop, 182);
        expect(outer.stripBottom, 678 - 34 - 8);
        final inner = _resolve(
          const Size(951, 669),
          padding: strip,
          native: const NativeFold(
            known: true,
            hinge: HingeStatus.open,
            fold: band,
            cameras: [Rect.fromLTRB(867, 0, 951, 124)],
          ),
        );
        expect(inner.stripTop, 132);
        // A region as tall as the strip says nothing about where the status items end.
        final whole = _resolve(
          const Size(466, 678),
          padding: strip,
          native: const NativeFold(
            known: true,
            hinge: HingeStatus.closed,
            cameras: [Rect.fromLTRB(382, 0, 466, 678)],
          ),
        );
        expect(whole.stripTop, FoldInfo.defaultStripTop);
      },
    );

    test(
      'on its side iOS draws at the bottom of the strip, and the top is free',
      () {
        final info = _resolve(
          const Size(678, 466),
          padding: strip,
          native: const NativeFold(
            known: true,
            hinge: HingeStatus.closed,
            cameras: [
              Rect.fromLTRB(611.7, 399.7, 648.7, 436.7),
              Rect.fromLTRB(594, 384, 678, 466),
            ],
          ),
        );
        expect(info.pose, Pose.tent);
        expect(info.strip, StripSide.right);
        expect(info.stripTop, FoldInfo.stripCornerClearance);
        expect(info.stripBottom, 384 - 8);
      },
    );

    test('split view: a fold that isn\'t in this window is nobody\'s', () {
      final info = _resolve(
        const Size(469, 669),
        padding: const EdgeInsets.only(bottom: 34),
        native: const NativeFold(
          known: true,
          hinge: HingeStatus.open,
          fold: Rect.fromLTWH(469, 0, 0, 669),
          fullScreen: false,
        ),
      );
      expect(info.fold, isNull);
      expect(info.hasStrip, isFalse);
      expect(info.pose, Pose.plain);
    });

    test(
      'an ordinary iPhone on its side has a notch on both sides, not a strip',
      () {
        final info = _resolve(
          const Size(874, 402),
          padding: const EdgeInsets.only(left: 62, right: 62, bottom: 21),
        );
        expect(info.hasStrip, isFalse);
        expect(info.pose, Pose.plain);
      },
    );

    test('the bridge\'s message is read as sent', () {
      final native = NativeFold.fromMap({
        'hinge': 'partlyOpen',
        'angle': 127.8,
        'fold': [455.5, 0.0, 40.0, 669.0],
        'foldActive': true,
        'bar': 'right',
        'status': [867.0, 0.0, 84.0, 120.0],
        'cameras': [
          [890.0, 15.0, 37.0, 37.0],
        ],
        'fullScreen': true,
      });
      expect(native.known, isTrue);
      expect(native.hinge, HingeStatus.partlyOpen);
      expect(native.angle, 127.8);
      expect(native.fold, const Rect.fromLTWH(455.5, 0, 40, 669));
      expect(native.bar, StripSide.right);
      expect(native.cameras.single, const Rect.fromLTWH(890, 15, 37, 37));
    });
  });

  group('Android foldables, from the display features Flutter reports', () {
    test('half open: the fold divides; flat: it is known and does not', () {
      var info = _resolve(
        const Size(841, 701),
        ios: false,
        features: const [
          DisplayFeature(
            bounds: Rect.fromLTWH(420, 0, 1, 701),
            type: DisplayFeatureType.fold,
            state: DisplayFeatureState.postureHalfOpened,
          ),
        ],
      );
      expect(info.pose, Pose.book);
      expect(info.hasStrip, isFalse);
      info = _resolve(
        const Size(841, 701),
        ios: false,
        features: const [
          DisplayFeature(
            bounds: Rect.fromLTWH(420.5, 0, 0, 701),
            type: DisplayFeatureType.fold,
            state: DisplayFeatureState.postureFlat,
          ),
        ],
      );
      expect(info.pose, Pose.openWide);
      expect(info.gap, isNull);
      expect(info.splitX, 420.5);
    });

    test('a side inset is never a strip there', () {
      final info = _resolve(
        const Size(466, 678),
        ios: false,
        padding: const EdgeInsets.only(right: 84),
      );
      expect(info.hasStrip, isFalse);
    });
  });

  testWidgets(
    'an Android foldable narrower than two panes\' worth still gets them around its fold, with the tab bar under the list',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(690, 830);
      tester.view.displayFeatures = const [
        DisplayFeature(
          bounds: Rect.fromLTWH(345, 0, 0, 830),
          type: DisplayFeatureType.fold,
          state: DisplayFeatureState.postureFlat,
        ),
      ];
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [backendProvider.overrideWithValue(FakeBackend())],
          child: const CasamaApp(),
        ),
      );
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(tester.getRect(find.byType(BotsScreen)).right, 345);
      expect(tester.getRect(find.byType(ChatScreen)).left, 345);
      expect(find.byType(StripTabs), findsNothing);
      expect(find.byType(NavigationRail), findsNothing);
      // The floating bar sits under the list, clear of the fold.
      expect(
        tester.getRect(find.byType(FloatingTabChrome)).right,
        lessThanOrEqualTo(345),
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(minutes: 1));
    },
  );
}
