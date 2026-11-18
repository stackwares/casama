// A page's own web address from the Library (SITES-AND-DOMAINS-PLAN §7.16): Publish to the Web
// with the address checked as typed, then the address with Copy, Open and Unpublish, and the
// hosts' states in words.
import 'package:casama/core/providers.dart';
import 'package:casama/features/library/creation_detail.dart';
import 'package:casama/features/pages/pages_screen.dart';
import 'package:casama/features/sites/sites_providers.dart';
import 'package:casama/l10n/generated/app_localizations.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_test.dart' show setSize;
import 'fake_backend.dart';

Widget _app(FakeBackend backend, {List<Uri>? opened}) {
  final router = GoRouter(
    initialLocation: '/library/c-site',
    routes: [
      GoRoute(
        path: '/library/:id',
        builder: (_, s) =>
            CreationDetailScreen(creationId: s.pathParameters['id']!),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      backendProvider.overrideWithValue(backend),
      if (opened != null)
        pageOpenerProvider.overrideWithValue((Uri u) async => opened.add(u)),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

FakeBackend _backend({bool sites = true}) => FakeBackend()
  ..sitesConfig = sites
      ? SitesConfig(
          zone: 'sites.example',
          customDomains: false,
          buyDomains: false,
          tlds: const [],
        )
      : null
  ..creationList = [
    fakeCreation(
      'c-site',
      title: 'Space Dodger',
      label: 'Site',
      pageId: 'page-1',
    ),
  ];

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('address names come from the title; unknown states need attention', () {
    expect(siteLabelFrom('Space Dodger!'), 'space-dodger');
    expect(siteLabelFrom('AI'), 'ai-site');
    expect(siteLabelFrom('***'), '');
    expect(siteLabelFrom('x' * 50).length, 40);
  });

  testWidgets('the publish sheet shows the address and checks it as typed', (
    tester,
  ) async {
    await setSize(tester, const Size(500, 1100));
    final backend = _backend()
      ..takenSiteLabels = {'taken-name': 'Someone already uses this name.'};
    await tester.pumpWidget(_app(backend));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('publishToWeb')));
    await tester.pumpAndSettle();
    expect(find.text('https://space-dodger.sites.example'), findsOneWidget);
    expect(
      find.text('Anyone with the address will be able to open it.'),
      findsOneWidget,
    );
    expect(backend.siteActions, ['check:space-dodger']);
    expect(find.byKey(const Key('siteAddressAvailable')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('siteAddressField')),
      'taken-name',
    );
    await tester.pump(const Duration(milliseconds: 100));
    // Not checked until typing stops.
    expect(backend.siteActions, ['check:space-dodger']);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(backend.siteActions.last, 'check:taken-name');
    expect(find.text('https://taken-name.sites.example'), findsOneWidget);
    expect(find.text('Someone already uses this name.'), findsOneWidget);
    final publish = tester.widget<FilledButton>(
      find.descendant(
        of: find.byKey(const Key('sitePublish')),
        matching: find.byType(FilledButton),
        matchRoot: true,
      ),
    );
    expect(publish.onPressed, isNull);
  });

  testWidgets(
    'publishing calls PUT, then the address shows with Copy, Open and Unpublish',
    (tester) async {
      await setSize(tester, const Size(500, 1400));
      final backend = _backend();
      final opened = <Uri>[];
      await tester.pumpWidget(_app(backend, opened: opened));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('publishToWeb')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('sitePublish')));
      await tester.pumpAndSettle();
      expect(backend.siteActions.last, 'publish:page-1:space-dodger:');

      expect(find.byKey(const Key('publishToWeb')), findsNothing);
      expect(find.text('On the web'), findsOneWidget);
      expect(find.text('https://space-dodger.sites.example'), findsOneWidget);
      expect(find.byKey(const Key('siteCopy')), findsOneWidget);
      expect(find.byKey(const Key('siteUnpublish')), findsOneWidget);
      // No custom domains on this server.
      expect(find.byKey(const Key('siteUseOwnDomain')), findsNothing);

      await tester.tap(find.byKey(const Key('siteOpen')));
      await tester.pumpAndSettle();
      expect(opened.single.toString(), 'https://space-dodger.sites.example');

      await tester.tap(find.byKey(const Key('siteSearchEnginesSwitch')));
      await tester.pumpAndSettle();
      expect(backend.siteActions.last, 'publish:page-1::true');

      await tester.ensureVisible(find.byKey(const Key('siteUnpublish')));
      await tester.tap(find.byKey(const Key('siteUnpublish')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirmUnpublish')));
      await tester.pumpAndSettle();
      expect(backend.siteActions.last, 'unpublish:page-1');
      expect(find.byKey(const Key('publishToWeb')), findsOneWidget);
    },
  );

  testWidgets('hosts that are not live show their state in words', (
    tester,
  ) async {
    await setSize(tester, const Size(500, 1400));
    final backend = _backend()
      ..siteList = [
        fakeSite(
          'page-1',
          canIndex: false,
          hosts: [
            fakeSiteHost('space-dodger.sites.example'),
            fakeSiteHost(
              'www.dodger.com',
              kind: 'custom',
              status: 'pending_dns',
              primary: false,
            ),
            fakeSiteHost(
              'dodger.com',
              kind: 'custom',
              status: 'something_new',
              primary: false,
            ),
          ],
        ),
      ];
    await tester.pumpWidget(_app(backend));
    await tester.pumpAndSettle();

    expect(find.text('Waiting for DNS'), findsOneWidget);
    expect(find.text('Needs attention'), findsOneWidget);
    // The live address needs no chip.
    expect(find.text('Live'), findsNothing);
    // Search engines need a paid plan here.
    expect(find.text('Needs a paid plan.'), findsOneWidget);
    final sw = tester.widget<Switch>(
      find.byKey(const Key('siteSearchEnginesSwitch')),
    );
    expect(sw.onChanged, isNull);
  });

  testWidgets('no sites on the server: no Publish to the Web', (tester) async {
    await setSize(tester, const Size(500, 1100));
    final backend = _backend(sites: false);
    await tester.pumpWidget(_app(backend));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('creationDetail-c-site')), findsOneWidget);
    expect(find.byKey(const Key('publishToWeb')), findsNothing);
    expect(find.byKey(const Key('siteSection')), findsNothing);
    expect(backend.siteActions, isEmpty);
  });
}
