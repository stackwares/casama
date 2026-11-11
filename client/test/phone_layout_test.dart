// Every screen lays out on phones without overflow or errors (the 6.9" and the small 4.7"
// iPhones). Catches clipped text, cut-off cards and broken navigation before they ship.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kasama_app/core/local_cache.dart';
import 'package:kasama_app/core/providers.dart';
import 'package:kasama_app/core/router.dart';
import 'package:kasama_app/l10n/generated/app_localizations.dart';
import 'package:kasama_app/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_backend.dart';

const routes = [
  '/bots',
  '/bots/$botId/chat',
  '/bots/$botId/activity',
  '/bots/$botId/memory',
  '/bots/$botId/settings',
  '/bots/$botId/sharing',
  '/bots/$botId/replays',
  '/bots/$botId/knowledge',
  '/bots/$botId/chat-apps',
  '/bots/$botId/links',
  '/bots/$botId/plugins',
  '/bots/$botId/watchers',
  '/bots/$botId/rules',
  '/bots/$botId/history',
  '/bots/$botId/routines',
  '/bots/$botId/integrations',
  '/bots/$botId/runs/$runId',
  '/inbox',
  '/tasks',
  '/projects',
  '/search',
  '/password-managers',
  '/pages',
  '/computer',
  '/settings',
  '/settings/keys',
  '/settings/themes',
  '/settings/theme',
  '/settings/fonts',
  '/settings/usage',
  '/settings/background',
  '/settings/skills',
  '/settings/integrations',
  '/settings/secrets',
  '/settings/computers',
  '/settings/companion',
  '/settings/devices',
  '/settings/admin',
  '/settings/billing',
  '/settings/privacy',
  '/settings/two-step',
  '/settings/workspace',
  '/quick-ask',
  '/welcome',
  '/onboarding',
];

void main() {
  for (final size in const [Size(430, 932), Size(375, 667)]) {
    testWidgets('every screen fits a ${size.width.toInt()}x${size.height.toInt()} phone', (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      final container = ProviderContainer(retry: (_, _) => null, overrides: [backendProvider.overrideWithValue(FakeBackend()), localCacheProvider.overrideWithValue(const NoCache())]);
      final router = container.read(routerProvider);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            theme: AppTheme.light(),
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      );
      final problems = <String>{};
      final old = FlutterError.onError;
      FlutterError.onError = (d) {
        final t = d.toString();
        if (t.contains('Duplicate GlobalKey')) problems.add('   dup: ${t.substring(0, t.length.clamp(0, 900)).replaceAll('\n', ' ')}');
        final i = t.indexOf('relevant error-causing widget was');
        if (i >= 0) problems.add('   where: ${t.substring(i, (i + 260).clamp(0, t.length)).replaceAll('\n', ' ')}');
        old?.call(d);
      };
      Future<void> settle(String tag) async {
        for (var i = 0; i < 15; i++) {
          await tester.pump(const Duration(milliseconds: 100));
          final e = tester.takeException();
          if (e != null) problems.add('$tag: ${e.toString().split('\n').first}');
        }
      }

      await settle('start');
      for (final r in routes) {
        router.go(r);
        await settle(r);
      }
      FlutterError.onError = old;
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(minutes: 1));
      tester.takeException();
      expect(problems, isEmpty, reason: problems.join('\n'));
    });
  }

  testWidgets('back from bot settings returns to the chat it was opened from', (tester) async {
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
        child: MaterialApp.router(theme: AppTheme.light(), routerConfig: router, localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales),
      ),
    );
    Future<void> settle() async {
      for (var i = 0; i < 15; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    router.go('/bots/$botId/chat');
    await settle();
    // The bot's name in the chat header opens its settings.
    await tester.tap(find.text('Ada').first);
    await settle();
    expect(find.text('Bot settings'), findsOneWidget);
    await tester.tap(find.byTooltip('Back').first);
    await settle();
    expect(find.text('Bot settings'), findsNothing);
    expect(find.byKey(const Key('messageInput')).hitTestable(), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(minutes: 1));
  });
}
