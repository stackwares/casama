// The browser tab names the open page (web) and follows every navigation, pushes and pops included.
import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:casama_app/core/local_cache.dart';
import 'package:casama_app/core/providers.dart';
import 'package:casama_app/core/route_title.dart';
import 'package:casama_app/core/router.dart';
import 'package:casama_app/l10n/generated/app_localizations.dart';
import 'package:casama_app/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_backend.dart';

void main() {
  testWidgets('the tab title names the page and follows navigation', (tester) async {
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
          theme: AppTheme.light(),
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => RouteTitle(router: router, enabled: true, child: child!),
        ),
      ),
    );
    Future<void> settle() async {
      for (var i = 0; i < 15; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    String title() => tester.widget<Title>(find.byKey(const Key('routeTitle'))).title;

    await settle();
    expect(title(), 'Chats · Casama');
    router.go('/settings');
    await settle();
    expect(title(), 'Settings · Casama');
    router.go('/bots/$botId/chat');
    await settle();
    expect(title(), 'Ada · Casama');
    router.go('/bots/$botId/memory');
    await settle();
    expect(title(), 'Memory · Ada · Casama');
    router.go('/settings/skills');
    await settle();
    expect(title(), 'Skills · Casama');
    // Pushed pages aren't in the URL; the tab follows them anyway.
    unawaited(router.push('/settings/skills/catalog'));
    await settle();
    expect(title(), 'Skill catalog · Casama');
    router.pop();
    await settle();
    expect(title(), 'Skills · Casama');

    // Every page in the router has a title of its own, except the ones that only pass through.
    final l10n = lookupAppLocalizations(const Locale('en'));
    final templates = <String>[];
    void walk(List<RouteBase> routes, String parent) {
      for (final r in routes) {
        if (r is GoRoute) {
          final full = r.path.startsWith('/') ? r.path : '$parent/${r.path}';
          if (r.pageBuilder != null || r.builder != null) templates.add(full);
          walk(r.routes, full);
        } else {
          walk(r.routes, parent);
        }
      }
    }

    walk(router.configuration.routes, '');
    expect(templates, contains('/bots/:botId/chat'));
    const passThrough = {'/welcome', '/joined/:orgId', '/run-routine/:ref'};
    for (final t in templates) {
      expect(tabTitleFor(t, l10n) == 'Casama', passThrough.contains(t), reason: t);
    }
    expect(tabTitleFor(null, l10n), 'Casama');

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(minutes: 1));
  });
}
