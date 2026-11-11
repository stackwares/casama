// The web and desktop are click and open: pages and tabs switch there with no transition, and pages still
// paint the wallpaper. Android and iOS keep their own transitions.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama_app/core/local_cache.dart';
import 'package:casama_app/core/providers.dart';
import 'package:casama_app/core/router.dart';
import 'package:casama_app/features/inbox/inbox_screen.dart';
import 'package:casama_app/l10n/generated/app_localizations.dart';
import 'package:casama_app/theme/app_theme.dart';
import 'package:casama_app/theme/wallpaper.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_backend.dart';

void main() {
  testWidgets('desktop pages have no transition; Android and iOS keep theirs', (tester) async {
    final builders = AppTheme.light().pageTransitionsTheme.builders;
    for (final platform in const [TargetPlatform.macOS, TargetPlatform.windows, TargetPlatform.linux]) {
      expect(builders[platform]!.transitionDuration, Duration.zero, reason: '$platform');
      expect(builders[platform]!.reverseTransitionDuration, Duration.zero, reason: '$platform');
    }
    for (final platform in const [TargetPlatform.android, TargetPlatform.iOS]) {
      expect(builders[platform], isA<WallpaperPageTransitionsBuilder>(), reason: '$platform');
    }
  });

  testWidgets('on desktop a page opens and closes at once, over the wallpaper', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light().copyWith(platform: TargetPlatform.macOS),
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const Text('second page'))),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pump();
    final second = find.text('second page');
    expect(ModalRoute.of(tester.element(second))!.animation!.status, AnimationStatus.completed);
    expect(find.ancestor(of: second, matching: find.byType(Wallpaper)), findsOneWidget);
    Navigator.of(tester.element(second)).pop();
    await tester.pump();
    expect(second, findsNothing);
  });

  testWidgets('on desktop the Chats, Inbox and Tasks tabs switch at once too', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final container = ProviderContainer(retry: (_, _) => null, overrides: [backendProvider.overrideWithValue(FakeBackend()), localCacheProvider.overrideWithValue(const NoCache())]);
    addTearDown(container.dispose);
    final router = container.read(routerProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          theme: AppTheme.light().copyWith(platform: TargetPlatform.macOS),
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    for (var i = 0; i < 15; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    router.go('/inbox');
    await tester.pump();
    expect(ModalRoute.of(tester.element(find.byType(InboxScreen)))!.animation!.status, AnimationStatus.completed);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(minutes: 1));
  });
}
