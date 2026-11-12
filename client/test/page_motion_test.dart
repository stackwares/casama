// Pages and tabs never show two screens at once, and the wallpaper never blacks out between them.
// Android pages fade through each other along a shared axis over the one wallpaper behind every
// navigator; iOS pages slide, each painting its own copy of the wallpaper; tabs fade through.
import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:casama_app/core/local_cache.dart';
import 'package:casama_app/core/providers.dart';
import 'package:casama_app/core/router.dart';
import 'package:casama_app/features/bots/bots_screen.dart';
import 'package:casama_app/features/inbox/inbox_screen.dart';
import 'package:casama_app/features/settings/settings_screen.dart';
import 'package:casama_app/l10n/generated/app_localizations.dart';
import 'package:casama_app/theme/app_theme.dart';
import 'package:casama_app/theme/page_transitions.dart';
import 'package:casama_app/theme/wallpaper.dart';
import 'package:casama_app/ui/skeleton.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_backend.dart';

/// How much of [finder] shows: the product of the opacities above it.
double shown(WidgetTester tester, Finder finder) {
  var opacity = 1.0;
  tester.element(finder).visitAncestorElements((e) {
    final w = e.widget;
    if (w is FadeTransition) opacity *= w.opacity.value;
    if (w is Opacity) opacity *= w.opacity;
    return true;
  });
  return opacity;
}

/// Whether [finder] is on screen at all (an offstage page isn't found).
bool present(Finder finder) => finder.evaluate().isNotEmpty;

Widget app(TargetPlatform platform, {Widget? home}) => MaterialApp(
  theme: AppTheme.light().copyWith(platform: platform),
  builder: (context, child) => Wallpaper(child: child!),
  home: home ?? const _Home(),
);

class _Home extends StatelessWidget {
  const _Home();

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: TextButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                const Scaffold(body: Center(child: Text('second page'))),
          ),
        ),
        child: const Text('first page'),
      ),
    ),
  );
}

void main() {
  test('each platform gets its transition', () {
    final builders = AppTheme.light().pageTransitionsTheme.builders;
    expect(
      builders[TargetPlatform.android],
      isA<SharedAxisPageTransitionsBuilder>(),
    );
    expect(builders[TargetPlatform.iOS], isA<OpaquePageTransitionsBuilder>());
    for (final platform in const [
      TargetPlatform.macOS,
      TargetPlatform.windows,
      TargetPlatform.linux,
    ]) {
      expect(
        builders[platform],
        isA<InstantPageTransitionsBuilder>(),
        reason: '$platform',
      );
    }
  });

  testWidgets(
    'Android: a page fades through the one under it, both ways, and the wallpaper stays',
    (tester) async {
      await tester.pumpWidget(app(TargetPlatform.android));
      final first = find.text('first page');
      final second = find.text('second page');
      await tester.tap(first);
      await tester.pump();

      // Through the push the two pages never show together, and nothing paints over the wallpaper.
      var sawSecondPartly = false;
      for (var ms = 0; ms <= 300; ms += 10) {
        final a = present(first) ? shown(tester, first) : 0.0;
        final b = present(second) ? shown(tester, second) : 0.0;
        expect(
          a > 0.02 && b > 0.02,
          isFalse,
          reason: 'both pages showing at ${ms}ms ($a, $b)',
        );
        if (b > 0.1 && b < 0.9) sawSecondPartly = true;
        // Flutter's Android transition put the theme's surface color behind the leaving page.
        expect(
          find.byWidgetPredicate((w) => w is ColoredBox && w.color.a > 0),
          findsNothing,
          reason: 'an opaque fill at ${ms}ms',
        );
        await tester.pump(const Duration(milliseconds: 10));
      }
      expect(
        sawSecondPartly,
        isTrue,
        reason: 'the page fades in rather than cutting in',
      );
      await tester.pumpAndSettle();
      expect(shown(tester, second), 1);
      expect(first, findsNothing);
      // The page paints no wallpaper of its own: the one behind the navigator shows through.
      expect(
        find.ancestor(of: second, matching: find.byType(Wallpaper)),
        findsOneWidget,
      );

      // Back: the top page goes first, then the page under it comes back.
      Navigator.of(tester.element(second)).pop();
      await tester.pump();
      for (var ms = 0; ms <= 300; ms += 10) {
        final a = present(first) ? shown(tester, first) : 0.0;
        final b = present(second) ? shown(tester, second) : 0.0;
        expect(
          a > 0.02 && b > 0.02,
          isFalse,
          reason: 'both pages showing at ${ms}ms on the way back ($a, $b)',
        );
        await tester.pump(const Duration(milliseconds: 10));
      }
      await tester.pumpAndSettle();
      expect(second, findsNothing);
      expect(shown(tester, first), 1);
    },
  );

  testWidgets(
    'Android: a full-screen dialog covers the page with its own wallpaper',
    (tester) async {
      await tester.pumpWidget(
        app(
          TargetPlatform.android,
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  fullscreenDialog: true,
                  builder: (_) => const Text('dialog page'),
                ),
              ),
              child: const Text('first page'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('first page'));
      await tester.pumpAndSettle();
      expect(
        find.ancestor(
          of: find.text('dialog page'),
          matching: find.byType(Wallpaper),
        ),
        findsNWidgets(2),
      );
    },
  );

  testWidgets(
    'iOS: each page paints the wallpaper, so a sliding page covers the one under it',
    (tester) async {
      await tester.pumpWidget(app(TargetPlatform.iOS));
      await tester.tap(find.text('first page'));
      await tester.pumpAndSettle();
      // The app's own and the page's.
      expect(
        find.ancestor(
          of: find.text('second page'),
          matching: find.byType(Wallpaper),
        ),
        findsNWidgets(2),
      );
    },
  );

  testWidgets('Chats and Inbox fade through each other when switching tabs', (
    tester,
  ) async {
    final (router, backend) = await pumpRouter(tester);
    final chats = find.byType(BotsScreen);
    final inbox = find.byType(InboxScreen);
    expect(chats, findsOneWidget);
    router.go('/inbox');
    await tester.pump();
    var sawInboxPartly = false;
    for (var ms = 0; ms <= tabSwitchDuration.inMilliseconds; ms += 10) {
      final a = present(chats) ? shown(tester, chats) : 0.0;
      final b = present(inbox) ? shown(tester, inbox) : 0.0;
      expect(
        a > 0.02 && b > 0.02,
        isFalse,
        reason: 'both tabs showing at ${ms}ms ($a, $b)',
      );
      if (b > 0.1 && b < 0.9) sawInboxPartly = true;
      await tester.pump(const Duration(milliseconds: 10));
    }
    expect(sawInboxPartly, isTrue);
    await tester.pump(const Duration(milliseconds: 100));
    expect(shown(tester, inbox), 1);
    await unmount(tester);
  });

  testWidgets('a page opened from a tab fades through it, and back', (
    tester,
  ) async {
    final (router, _) = await pumpRouter(tester);
    final chats = find.byType(BotsScreen);
    final settings = find.byType(SettingsScreen);
    unawaited(router.push('/settings'));
    await tester.pump();
    for (var ms = 0; ms <= 300; ms += 10) {
      final a = present(chats) ? shown(tester, chats) : 0.0;
      final b = present(settings) ? shown(tester, settings) : 0.0;
      expect(
        a > 0.02 && b > 0.02,
        isFalse,
        reason: 'tab and page showing at ${ms}ms ($a, $b)',
      );
      await tester.pump(const Duration(milliseconds: 10));
    }
    await tester.pump(const Duration(milliseconds: 100));
    expect(shown(tester, settings), 1);
    router.pop();
    await tester.pump();
    for (var ms = 0; ms <= 300; ms += 10) {
      final a = present(chats) ? shown(tester, chats) : 0.0;
      final b = present(settings) ? shown(tester, settings) : 0.0;
      expect(
        a > 0.02 && b > 0.02,
        isFalse,
        reason: 'tab and page showing at ${ms}ms on the way back ($a, $b)',
      );
      await tester.pump(const Duration(milliseconds: 10));
    }
    await tester.pump(const Duration(milliseconds: 100));
    expect(shown(tester, chats), 1);
    await unmount(tester);
  });

  testWidgets('the Inbox opens again on what it showed, not on skeletons', (
    tester,
  ) async {
    final (router, _) = await pumpRouter(tester);
    router.go('/inbox');
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Today: 10:00 Standup.'), findsOneWidget);
    router.go('/bots');
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(InboxScreen), findsNothing);
    router.go('/inbox');
    // The first frame the Inbox is built in (the router takes a frame to get there).
    while (find.byType(InboxScreen).evaluate().isEmpty) {
      await tester.pump();
    }
    expect(find.descendant(of: find.byType(InboxScreen), matching: find.byType(SkeletonScope)), findsNothing);
    expect(find.text('Today: 10:00 Standup.'), findsOneWidget);
    await unmount(tester);
  });
}

/// The app's router on an Android phone, signed in to the fake backend, settled on Chats.
Future<(GoRouter, FakeBackend)> pumpRouter(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final backend = FakeBackend();
  final container = ProviderContainer(
    retry: (_, _) => null,
    overrides: [
      backendProvider.overrideWithValue(backend),
      localCacheProvider.overrideWithValue(const NoCache()),
    ],
  );
  addTearDown(container.dispose);
  final router = container.read(routerProvider);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        theme: AppTheme.light().copyWith(platform: TargetPlatform.android),
        builder: (context, child) => Wallpaper(child: child!),
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  for (var i = 0; i < 15; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  return (router, backend);
}

Future<void> unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(minutes: 1));
}
