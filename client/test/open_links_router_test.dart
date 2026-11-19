import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama/app.dart';
import 'package:casama/core/open_links.dart';
import 'package:casama/core/providers.dart';
import 'package:casama/core/router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_test.dart' show setSize;
import 'fake_backend.dart';

Future<ProviderContainer> _app(WidgetTester tester, FakeBackend backend) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [backendProvider.overrideWithValue(backend)],
      child: const CasamaApp(),
    ),
  );
  await _settle(tester);
  return ProviderScope.containerOf(tester.element(find.byType(CasamaApp)));
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await PendingOpenLink.preload();
  });

  testWidgets('a casama.ai/open link opens its route', (tester) async {
    await setSize(tester, const Size(500, 1000));
    final c = await _app(tester, FakeBackend());
    c.read(routerProvider).go('/open/settings/billing?highlight=credits');
    await _settle(tester);
    expect(
      c.read(routerProvider).state.uri.toString(),
      '/settings/billing?highlight=credits',
    );
  });

  testWidgets('every in-app route in packages/contracts/support/places.json resolves in routerProvider', (tester) async {
    await setSize(tester, const Size(500, 1000));
    final c = await _app(tester, FakeBackend());
    final router = c.read(routerProvider);
    final decoded = jsonDecode(
      File('../packages/contracts/support/places.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final places = (decoded['places'] as List).cast<Map<String, dynamic>>();
    final routes = [
      for (final p in places)
        if (p['route'] is String)
          (p['route'] as String).replaceAll(
            '{botId}',
            '00000000-0000-0000-0000-000000000001',
          ),
    ];
    expect(routes, isNotEmpty);
    for (final r in routes) {
      final matches = router.configuration.findMatch(Uri.parse(r));
      expect(matches.isNotEmpty, isTrue, reason: 'Unmatched route: $r');
      expect(matches.error, isNull, reason: 'Router error on route: $r');
    }
  });

  testWidgets('signed out, the link waits through sign-in', (tester) async {
    await setSize(tester, const Size(500, 1000));
    final backend = FakeBackend()..signedIn = false;
    final c = await _app(tester, backend);
    c.read(routerProvider).go('/open/settings/billing');
    await _settle(tester);
    expect(c.read(routerProvider).state.matchedLocation, '/sign-in');
    expect(c.read(pendingOpenLinkProvider), '/settings/billing');
    await backend.signIn('a@b.c', 'pw');
    await _settle(tester);
    expect(c.read(routerProvider).state.uri.toString(), '/settings/billing');
    // Moving on is the end of it.
    c.read(routerProvider).go('/settings');
    await _settle(tester);
    expect(c.read(routerProvider).state.uri.toString(), '/settings');
    expect(c.read(pendingOpenLinkProvider), isNull);
  });

  testWidgets('signing out somewhere is not a link to come back to', (
    tester,
  ) async {
    await setSize(tester, const Size(500, 1000));
    final backend = FakeBackend();
    final c = await _app(tester, backend);
    c.read(routerProvider).go('/settings');
    await _settle(tester);
    await backend.signOut();
    await _settle(tester);
    expect(c.read(routerProvider).state.matchedLocation, '/sign-in');
    expect(c.read(pendingOpenLinkProvider), isNull);
  });

  testWidgets('a link kept through a reload opens once the app is back', (
    tester,
  ) async {
    await setSize(tester, const Size(500, 1000));
    final now = DateTime.now().millisecondsSinceEpoch;
    SharedPreferences.setMockInitialValues({
      'casama.pending_open': '$now\t/settings/billing',
    });
    await PendingOpenLink.preload();
    final c = await _app(tester, FakeBackend());
    expect(c.read(routerProvider).state.uri.toString(), '/settings/billing');
  });

  testWidgets('an old one is forgotten', (tester) async {
    await setSize(tester, const Size(500, 1000));
    final then = DateTime.now()
        .subtract(const Duration(hours: 2))
        .millisecondsSinceEpoch;
    SharedPreferences.setMockInitialValues({
      'casama.pending_open': '$then\t/settings/billing',
    });
    await PendingOpenLink.preload();
    final c = await _app(tester, FakeBackend());
    expect(c.read(routerProvider).state.uri.path, isNot('/settings/billing'));
  });

  testWidgets('signed out, the link is kept on the device', (tester) async {
    await setSize(tester, const Size(500, 1000));
    final c = await _app(tester, FakeBackend()..signedIn = false);
    c.read(routerProvider).go('/open/import/tok123');
    await _settle(tester);
    final saved = (await SharedPreferences.getInstance()).getString(
      'casama.pending_open',
    );
    expect(saved, endsWith('\t/import/tok123'));
  });
}
