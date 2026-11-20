import 'dart:io';

import 'package:casama/ui/ambient_motion.dart';
import 'package:casama/ui/painted_cover.dart';
import 'package:casama/ui/splash_scene.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  group('painted art files', () {
    test(
      'every name the app knows has its picture, small enough to bundle',
      () {
        for (final name in paintedArt) {
          final f = File('assets/art/$name.webp');
          expect(f.existsSync(), isTrue, reason: '$name is missing');
          expect(
            f.lengthSync(),
            lessThan(40 * 1024),
            reason: '$name is too big',
          );
        }
      },
    );

    test(
      'the splash scene has a day and night version of each cut, within budget',
      () {
        for (final time in ['day', 'night']) {
          for (final cut in ['wide', 'tall']) {
            final f = File('assets/scene/scene-$time-$cut.webp');
            expect(f.existsSync(), isTrue, reason: '$time $cut is missing');
            expect(f.lengthSync(), lessThan(150 * 1000));
          }
          final web = File('web/splash/scene-$time-wide.webp');
          expect(web.existsSync(), isTrue, reason: 'web $time is missing');
          expect(web.lengthSync(), lessThan(60 * 1000));
        }
      },
    );
  });

  group('names', () {
    test('known names map to assets; unknown ones fall back', () {
      expect(paintedAsset('invite'), 'assets/art/invite.webp');
      expect(paintedAsset('nope'), isNull);
      expect(paintedAsset(null), isNull);
      expect(categoryArt('work'), 'assets/art/cat-work.webp');
      expect(categoryArt('money'), 'assets/art/cat-money.webp');
      expect(categoryArt('other'), isNull);
    });

    test('the fallback gradient is the same for the same seed', () {
      expect(paintedFallbackColors('a'), paintedFallbackColors('a'));
    });
  });

  group('PaintedCover', () {
    testWidgets('draws the picture when it has one', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Center(
            child: PaintedCover(
              size: 64,
              seed: 'x',
              asset: 'assets/art/invite.webp',
              icon: LucideIcons.gift,
            ),
          ),
        ),
      );
      expect(find.byType(Image), findsOneWidget);
      expect(find.byIcon(LucideIcons.gift), findsNothing);
    });

    testWidgets('draws a tile with the icon when it has no picture', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Center(
            child: PaintedCover(size: 64, seed: 'x', icon: LucideIcons.gift),
          ),
        ),
      );
      expect(find.byType(Image), findsNothing);
      expect(find.byIcon(LucideIcons.gift), findsOneWidget);
    });
  });

  group('SplashScene', () {
    test('picks the cut that crops least', () {
      expect(
        SplashScene.assetFor(const Size(390, 844), Brightness.light),
        'assets/scene/scene-day-tall.webp',
      );
      expect(
        SplashScene.assetFor(const Size(1440, 900), Brightness.dark),
        'assets/scene/scene-night-wide.webp',
      );
      expect(
        SplashScene.assetFor(const Size(1024, 1366), Brightness.light),
        'assets/scene/scene-day-tall.webp',
      );
    });

    test('decodes at the screen size, never above the file', () {
      final phone = SplashScene.providerFor(
        const Size(390, 844),
        3,
        Brightness.light,
      ) as ResizeImage;
      // 844 tall on a 1600-tall painting: cover scale 0.5275 × 1067 wide × 3 ≈ 1689, capped at 1067.
      expect(phone.width, 1067);
      final small = SplashScene.providerFor(
        const Size(360, 640),
        1,
        Brightness.light,
      ) as ResizeImage;
      expect(small.width, lessThan(500));
      final desktop = SplashScene.providerFor(
        const Size(1920, 1080),
        2,
        Brightness.dark,
      ) as ResizeImage;
      expect(desktop.width, 1600);
    });

    testWidgets('shows the plain background under the picture', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SplashScene(
            brightness: Brightness.light,
            background: Color(0xFFFFFFFF),
          ),
        ),
      );
      expect(find.byKey(const Key('splashScene')), findsOneWidget);
      final box = tester.widget<ColoredBox>(
        find
            .descendant(
              of: find.byType(SplashScene),
              matching: find.byType(ColoredBox),
            )
            .first,
      );
      expect(box.color, const Color(0xFFFFFFFF));
      // Gone: its decoded picture is let go a frame later, with no timers left over.
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      await tester.pump(const Duration(seconds: 3));
    });
  });

  group('motion', () {
    setUp(() => ambientMotionEnabled = true);
    tearDown(() => ambientMotionEnabled = false);

    test('the zoom goes in for one period, then back out', () {
      final p = SplashScene.driftPeriod.inMilliseconds.toDouble();
      expect(SplashScene.driftAt(0), (0.0, true));
      expect(SplashScene.driftAt(p / 2).$1, closeTo(0.5, 1e-9));
      final (back, goingIn) = SplashScene.driftAt(p * 1.25);
      expect(back, closeTo(0.75, 1e-9));
      expect(goingIn, isFalse);
    });

    double sceneScale(WidgetTester tester) => tester
        .widget<Transform>(
          find
              .descendant(
                of: find.byType(SplashScene),
                matching: find.byType(Transform),
              )
              .first,
        )
        .transform
        .getMaxScaleOnAxis();

    testWidgets('the scene zooms slowly and stops for Reduce Motion', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SplashScene(
            brightness: Brightness.light,
            background: Color(0xFFFFFFFF),
          ),
        ),
      );
      final start = sceneScale(tester);
      await tester.pump(const Duration(seconds: 8));
      final later = sceneScale(tester);
      expect(later, greaterThan(start));
      expect(later, lessThanOrEqualTo(SplashScene.driftScale + 1e-9));

      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            home: SplashScene(
              brightness: Brightness.light,
              background: Color(0xFFFFFFFF),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 4));
      expect(sceneScale(tester), closeTo(1, 1e-9));
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('a floating hero bobs, and holds still for Reduce Motion', (
      tester,
    ) async {
      Offset at() => tester.getTopLeft(find.byType(PaintedCover));
      await tester.pumpWidget(
        const MaterialApp(
          home: Center(child: PaintedHero(name: 'wait-envelope', float: true)),
        ),
      );
      final a = at();
      await tester.pump(const Duration(seconds: 1));
      expect(at(), isNot(a));

      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            home: Center(
              child: PaintedHero(name: 'wait-envelope', float: true),
            ),
          ),
        ),
      );
      final b = at();
      await tester.pump(const Duration(seconds: 1));
      expect(at(), b);
    });

    testWidgets('a cover settles in once and then stops', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Center(
            child: CoverSettleIn(child: SizedBox(width: 10, height: 10)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final opacity = tester.widget<Opacity>(find.byType(Opacity));
      expect(opacity.opacity, 1);
    });
  });
}
