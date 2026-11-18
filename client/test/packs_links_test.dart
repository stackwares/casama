// Pack links (docs/PLUGINS-AND-PACKS-PLAN.md B.8, E.31) open the pack's preview.
import 'package:casama/app.dart';
import 'package:casama/core/open_links.dart';
import 'package:casama/core/providers.dart';
import 'package:casama/core/router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_test.dart' show setSize;
import 'fake_backend.dart';

Future<ProviderContainer> _app(WidgetTester tester, FakeBackend backend) async {
  await tester.pumpWidget(
    ProviderScope(overrides: [backendProvider.overrideWithValue(backend)], child: const CasamaApp()),
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

  testWidgets('casama.ai/open/pack?url= opens the preview of that GitHub link', (tester) async {
    await setSize(tester, const Size(500, 1000));
    final backend = FakeBackend();
    final c = await _app(tester, backend);
    c.read(routerProvider).go('/open/pack?url=https://github.com/acme/trip-kit');
    await _settle(tester);
    expect(
      c.read(routerProvider).state.uri.toString(),
      '/settings/gallery/packs/add?url=https%3A%2F%2Fgithub.com%2Facme%2Ftrip-kit',
    );
    expect(backend.packActions, contains('preview:https://github.com/acme/trip-kit'));
    expect(find.byKey(const Key('packAdd')), findsOneWidget);
  });

  testWidgets('a pack link without a pack offers the ways to add one, not an error', (tester) async {
    await setSize(tester, const Size(500, 1000));
    final backend = FakeBackend();
    final c = await _app(tester, backend);
    c.read(routerProvider).go('/settings/gallery/packs/add');
    await _settle(tester);
    expect(find.byKey(const Key('packNoSource')), findsOneWidget);
    expect(backend.packActions.where((a) => a.startsWith('preview:')), isEmpty);
  });

  testWidgets('a shared pack link opens its preview from the share', (tester) async {
    await setSize(tester, const Size(500, 1000));
    final backend = FakeBackend();
    final c = await _app(tester, backend);
    c.read(routerProvider).go('/open/packs/share/tok-1234567890');
    await _settle(tester);
    expect(c.read(routerProvider).state.uri.toString(), '/settings/gallery/packs/share/tok-1234567890');
    expect(backend.packActions, contains('share-view:tok-1234567890'));

    // The app's own share URL works the same.
    c.read(routerProvider).go('/packs/share/tok-0987654321');
    await _settle(tester);
    expect(c.read(routerProvider).state.uri.toString(), '/settings/gallery/packs/share/tok-0987654321');
  });
}
