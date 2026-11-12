import 'dart:async';

import 'package:casama_app/core/config.dart';
import 'package:casama_app/main.dart';
import 'package:casama_app/ui/brand_splash.dart';
import 'package:casama_app/ui/splash_art.g.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

LottieComposition? _brand;

StartupGate gate(Future<Widget> Function(AppConfig) connect) {
  return StartupGate(config: const AppConfig(apiUrl: 'http://casama.invalid'), connect: connect);
}

void expectCloud({required WidgetTester tester, required double width}) {
  final art = tester.getRect(find.byKey(const Key('startupSplashArt')));
  final splash = tester.getRect(find.byKey(const Key('startupSplash')));
  final box = splashCloudBox;
  final height = width * (box.bottom - box.top) / (box.right - box.left);
  expect(art.width, closeTo(width, 0.1));
  expect(art.height, closeTo(height, 0.1));
  expect(art.center.dx, closeTo(splash.center.dx, 0.5));
  expect(art.center.dy, closeTo(splash.center.dy, 0.5));
}

/// Holds the connection open for [body], then lets it finish so the startup timeouts are not left pending.
Future<void> hold(WidgetTester tester, Future<void> Function(Completer<Widget> pending) body, {TargetPlatform? platform}) async {
  final pending = Completer<Widget>();
  if (platform != null) debugDefaultTargetPlatformOverride = platform;
  try {
    await tester.pumpWidget(gate((_) => pending.future));
    await body(pending);
  } finally {
    debugDefaultTargetPlatformOverride = null;
    if (!pending.isCompleted) pending.complete(const SizedBox());
    await tester.pump(const Duration(milliseconds: 500));
  }
}

Future<void> pumpArt(WidgetTester tester, {LottieComposition? composition, bool reduceMotion = false, TargetPlatform platform = TargetPlatform.iOS}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(platform: platform),
      themeAnimationDuration: Duration.zero,
      home: Builder(
        builder: (context) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
            child: Scaffold(
              key: const Key('startupSplash'),
              backgroundColor: BrandSplash.lightBackground,
              body: BrandSplash(composition: composition),
            ),
          );
        },
      ),
    ),
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('the brand loop decodes', (tester) async {
    _brand = await tester.runAsync(() => AssetLottie(BrandSplash.lottieAsset).load());
    expect(_brand!.duration, greaterThan(Duration.zero));
  });

  testWidgets('the still stands in until the loop has decoded', (tester) async {
    await pumpArt(tester);
    expect(find.byKey(const Key('startupSplashStill')), findsOneWidget);
    expect(find.byType(Lottie), findsNothing);
    expectCloud(tester: tester, width: splashCloudWidth);
  });

  testWidgets('the decoded loop plays, and Reduce Motion keeps the still', (tester) async {
    await pumpArt(tester, composition: _brand);
    expect(find.byType(Lottie), findsOneWidget);
    expect(find.byKey(const Key('startupSplashStill')), findsNothing);
    expectCloud(tester: tester, width: splashCloudWidth);

    await pumpArt(tester, composition: _brand, reduceMotion: true);
    expect(find.byType(Lottie), findsNothing);
    expect(find.byKey(const Key('startupSplashStill')), findsOneWidget);
    expectCloud(tester: tester, width: splashCloudWidth);

    await pumpArt(tester, composition: _brand, platform: TargetPlatform.android);
    expectCloud(tester: tester, width: splashCloudWidthAndroid);
  });

  testWidgets('first frame centres the launch cloud on the light background', (tester) async {
    await hold(tester, (pending) async {
      expect(find.byKey(const Key('startupSplash')), findsOneWidget);
      expect(tester.widget<Scaffold>(find.byKey(const Key('startupSplash'))).backgroundColor, BrandSplash.lightBackground);
      expectCloud(tester: tester, width: splashCloudWidth);
      expect(find.byKey(const Key('startupConnecting')), findsNothing);

      final center = tester.getRect(find.byKey(const Key('startupSplashArt'))).center;
      await tester.pump(BrandSplash.labelDelay);
      expect(find.byKey(const Key('startupConnecting')), findsOneWidget);
      expect(tester.getRect(find.byKey(const Key('startupSplashArt'))).center, center);
    }, platform: TargetPlatform.iOS);
  });

  testWidgets('a status-bar inset does not move the cloud off the screen centre', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 47, bottom: 34);
    tester.view.viewPadding = const FakeViewPadding(top: 47, bottom: 34);
    addTearDown(tester.view.reset);

    await hold(tester, (_) async {
      expectCloud(tester: tester, width: splashCloudWidth);
    }, platform: TargetPlatform.iOS);
  });

  testWidgets('dark mode uses the dark launch background', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await hold(tester, (_) async {
      expect(tester.widget<Scaffold>(find.byKey(const Key('startupSplash'))).backgroundColor, BrandSplash.darkBackground);
    });
  });

  testWidgets('the splash fades into the app, and Reduce Motion skips the fade', (tester) async {
    await hold(tester, (pending) async {
      pending.complete(const MaterialApp(home: Text('app ready')));
      // Pictures are given up to 500ms, then the fade runs for 300ms. Step in small
      // pumps so the sample lands during the fade rather than after it.
      for (var i = 0; i < 20 && find.text('app ready').evaluate().isEmpty; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      // The exit ticker starts on the frame after the app is ready, so the first pump only arms it.
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 100));
      final fade = tester.widget<FadeTransition>(find.byKey(const Key('startupSplashFade')));
      expect(fade.opacity.value, greaterThan(0));
      expect(fade.opacity.value, lessThan(1));

      for (var i = 0; i < 20 && find.byKey(const Key('startupSplash')).evaluate().isNotEmpty; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(find.byKey(const Key('startupSplash')), findsNothing);
      expect(find.text('app ready'), findsOneWidget);
    }, platform: TargetPlatform.iOS);

    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await hold(tester, (pending) async {
      pending.complete(const MaterialApp(home: Text('app ready')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();
      expect(find.byKey(const Key('startupSplash')), findsNothing);
      expect(find.text('app ready'), findsOneWidget);
    });
  });
}
