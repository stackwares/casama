// Screen analytics (PostHog's $screen) name each page by its route's template, never by the ids in its
// address, so every page is reported and no id leaves the device.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama_app/core/local_cache.dart';
import 'package:casama_app/core/providers.dart';
import 'package:casama_app/core/router.dart';
import 'package:casama_app/features/skills/skill_catalog_screen.dart';
import 'package:casama_app/features/skills/skills_screen.dart';
import 'package:casama_app/l10n/generated/app_localizations.dart';
import 'package:casama_app/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';
import 'phone_layout_test.dart' show routes;

void main() {
  testWidgets('every page has a screen name: its route template, without ids', (tester) async {
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

    // The names of the pages on every navigator (the app's and the shell's).
    List<String> names() => [for (final navigator in tester.widgetList<Navigator>(find.byType(Navigator, skipOffstage: false))) ...navigator.pages.map((page) => page.name).whereType<String>()];

    await settle();
    router.go('/bots/$botId/chat');
    await settle();
    expect(names(), containsAll(['/bots', '/bots/:botId/chat']));
    router.go('/settings/keys');
    await settle();
    expect(names(), containsAll(['/settings', '/settings/keys']));

    for (final location in routes) {
      router.go(location);
      await settle();
      expect(names(), contains(router.state.fullPath), reason: location);
      expect(names().where((n) => n.contains(botId) || n.contains(runId)), isEmpty, reason: location);
    }

    // A page opened with push is named too.
    router.go('/settings/skills');
    await settle();
    unawaited(router.push('/settings/skills/catalog'));
    await settle();
    expect(names(), contains('/settings/skills/catalog'));

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(minutes: 1));
  });

  testWidgets('a page pushed without the router is named too', (tester) async {
    await setSize(tester, const Size(900, 1000));
    await tester.pumpWidget(harness(FakeBackend(), const SkillsScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('browseCatalog')));
    await tester.pumpAndSettle();
    expect(ModalRoute.of(tester.element(find.byType(SkillCatalogScreen)))!.settings.name, '/settings/skills/catalog');
  });
}
