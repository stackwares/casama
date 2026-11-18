// Connecting a domain you own (SITES-AND-DOMAINS-PLAN §7.16, Phase 2): the Settings row for admins
// when the server connects domains, the list with its state chips, Connect a Domain You Own (a
// domain, or the claim record when another workspace proved it first) and a domain's screen with
// its records, Check Again, Make Primary, the site picker and Disconnect.
import 'package:casama/core/providers.dart';
import 'package:casama/features/settings/settings_screen.dart';
import 'package:casama/features/sites/connect_domain_screen.dart';
import 'package:casama/features/sites/domain_screen.dart';
import 'package:casama/features/sites/domains_providers.dart';
import 'package:casama/features/sites/domains_screen.dart';
import 'package:casama/l10n/generated/app_localizations.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:dio/dio.dart' show DioException, RequestOptions, Response;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

SitesConfig _config({bool customDomains = true}) => SitesConfig(
  zone: 'sites.example',
  customDomains: customDomains,
  buyDomains: false,
  tlds: const [],
);

FakeBackend _backend({bool customDomains = true}) =>
    FakeBackend()..sitesConfig = _config(customDomains: customDomains);

Widget _routed(FakeBackend backend, String initial) {
  final router = GoRouter(
    initialLocation: initial,
    routes: [
      GoRoute(
        path: '/settings/domains',
        builder: (_, _) => const DomainsScreen(),
        routes: [
          GoRoute(
            path: 'connect',
            builder: (_, s) =>
                ConnectDomainScreen(pageId: s.uri.queryParameters['page_id']),
          ),
          GoRoute(
            path: ':id',
            builder: (_, s) => DomainScreen(domainId: s.pathParameters['id']!),
          ),
        ],
      ),
    ],
  );
  return ProviderScope(
    overrides: [backendProvider.overrideWithValue(backend)],
    child: MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

DioException _problem(int status, String detail) {
  final req = RequestOptions(path: '/v1/domains');
  return DioException(
    requestOptions: req,
    response: Response(
      requestOptions: req,
      statusCode: status,
      data: {
        'type': 'about:blank',
        'title': 'Error',
        'status': status,
        'code': 'domain_error',
        'detail': detail,
      },
    ),
  );
}

/// Records what the app puts on the clipboard.
List<String> _mockClipboard(WidgetTester tester) {
  final copied = <String>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'Clipboard.setData') {
        copied.add((call.arguments as Map)['text'] as String);
      }
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );
  return copied;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('Settings → Domains', () {
    testWidgets('hidden when the server connects no domains', (tester) async {
      await setSize(tester, const Size(430, 3200));
      await tester.pumpWidget(
        harness(_backend(customDomains: false), const SettingsScreen()),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('settingsDomains')), findsNothing);
    });

    testWidgets('hidden for members', (tester) async {
      await setSize(tester, const Size(430, 3200));
      await tester.pumpWidget(
        harness(_backend()..orgRole = OrgRole.member, const SettingsScreen()),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('settingsDomains')), findsNothing);
    });

    testWidgets('shown for admins when the server connects domains', (
      tester,
    ) async {
      await setSize(tester, const Size(430, 3200));
      await tester.pumpWidget(
        harness(_backend()..orgRole = OrgRole.admin, const SettingsScreen()),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('settingsDomains')), findsOneWidget);
      expect(find.text('Domains'), findsOneWidget);
    });
  });

  group('the list', () {
    testWidgets('empty: one line and the connect button', (tester) async {
      await setSize(tester, const Size(500, 1000));
      await tester.pumpWidget(_routed(_backend(), '/settings/domains'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('domainsEmpty')), findsOneWidget);
      expect(find.text('Connect a Domain You Own'), findsOneWidget);
      await tester.tap(find.byKey(const Key('domainsConnect')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('connectDomainField')), findsOneWidget);
    });

    testWidgets('each domain with its site and state chip', (tester) async {
      await setSize(tester, const Size(500, 1200));
      final backend = _backend()
        ..domainList = [
          fakeDomain('d-1', name: 'live.com', state: 'live', pageId: 'page-1'),
          fakeDomain('d-2', name: 'dns.com', state: 'waiting_dns'),
          fakeDomain('d-3', name: 'cert.com', state: 'waiting_cert'),
          fakeDomain('d-4', name: 'paused.com', state: 'paused'),
          fakeDomain('d-5', name: 'odd.com', state: 'something_new'),
        ];
      await tester.pumpWidget(_routed(backend, '/settings/domains'));
      await tester.pumpAndSettle();
      String chip(String id) => tester
          .widget<DomainStateChip>(find.byKey(Key('domainState-$id')))
          .label;
      expect(chip('d-1'), 'Live');
      expect(chip('d-2'), 'Waiting for DNS');
      expect(chip('d-3'), 'Getting Its Certificate');
      expect(chip('d-4'), 'Paused');
      expect(chip('d-5'), 'Needs Attention');
      expect(find.text('Space Dodger'), findsOneWidget);
      expect(find.text('No site yet'), findsNWidgets(4));

      await tester.tap(find.byKey(const Key('domain-d-2')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('domainScreenState')), findsOneWidget);
    });
  });

  group('Connect a Domain You Own', () {
    testWidgets(
      'the site comes preselected; a connected domain opens its screen',
      (tester) async {
        await setSize(tester, const Size(500, 1200));
        final backend = _backend()..siteList = [fakeSite('page-1')];
        await tester.pumpWidget(
          _routed(backend, '/settings/domains/connect?page_id=page-1'),
        );
        await tester.pumpAndSettle();
        expect(
          find.descendant(
            of: find.byKey(const Key('connectDomainSite')),
            matching: find.text('Space Dodger'),
          ),
          findsOneWidget,
        );
        await tester.enterText(
          find.byKey(const Key('connectDomainField')),
          'https://www.Bakery.com/',
        );
        await tester.pump();
        await tester.tap(find.byKey(const Key('connectDomainSubmit')));
        await tester.pumpAndSettle();
        expect(
          backend.domainActions,
          contains('connect:www.bakery.com:page-1'),
        );
        expect(find.byKey(const Key('domainScreenState')), findsOneWidget);
        expect(find.byKey(const Key('domainRecord-0')), findsOneWidget);
      },
    );

    testWidgets('a site can be left out with None', (tester) async {
      await setSize(tester, const Size(500, 1200));
      final backend = _backend()..siteList = [fakeSite('page-1')];
      await tester.pumpWidget(
        _routed(backend, '/settings/domains/connect?page_id=page-1'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('connectDomainSite')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('domainSiteOption-none')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('connectDomainField')),
        'shop.bakery.com',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('connectDomainSubmit')));
      await tester.pumpAndSettle();
      expect(backend.domainActions, contains('connect:shop.bakery.com:'));
    });

    testWidgets('a domain another workspace proved shows the claim record', (
      tester,
    ) async {
      await setSize(tester, const Size(500, 1200));
      final copied = _mockClipboard(tester);
      final backend = _backend()
        ..domainClaims = {
          'bakery.com': ConnectDomainResultClaim(
            type: 'TXT',
            name: '_casama-claim.bakery.com',
            value: 'claim-code-1',
          ),
        };
      await tester.pumpWidget(_routed(backend, '/settings/domains/connect'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('connectDomainField')),
        'bakery.com',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('connectDomainSubmit')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('connectDomainClaim')), findsOneWidget);
      expect(
        find.textContaining('Another workspace has connected'),
        findsOneWidget,
      );
      expect(find.text('_casama-claim.bakery.com'), findsOneWidget);
      await tester.tap(find.byKey(const Key('connectDomainClaimCopyValue')));
      await tester.pumpAndSettle();
      expect(copied, ['claim-code-1']);
      // Still here: nothing was connected.
      expect(find.byKey(const Key('domainScreenState')), findsNothing);
      expect(backend.domainList, isEmpty);
    });

    testWidgets("the server's words when it refuses", (tester) async {
      await setSize(tester, const Size(500, 1200));
      final backend = _backend()
        ..connectDomainError = _problem(
          409,
          'You have 10 domains waiting for DNS. Finish one first.',
        );
      await tester.pumpWidget(_routed(backend, '/settings/domains/connect'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('connectDomainField')),
        'bakery.com',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('connectDomainSubmit')));
      await tester.pumpAndSettle();
      expect(
        find.text('You have 10 domains waiting for DNS. Finish one first.'),
        findsOneWidget,
      );
    });
  });

  group("a domain's screen", () {
    testWidgets(
      'records with Copy, what DNS shows, the generic intro and history',
      (tester) async {
        await setSize(tester, const Size(500, 1800));
        final copied = _mockClipboard(tester);
        final backend = _backend()
          ..domainList = [
            fakeDomain(
              'd-1',
              records: [
                fakeDomainRecord(
                  'www.bakery.com',
                  value: 'd-abc123.sites.example',
                  ok: true,
                ),
                fakeDomainRecord(
                  'bakery.com',
                  type: 'TXT',
                  recordName: '_cf-custom-hostname.bakery.com',
                  value: 'proof-123',
                  purpose: 'proof',
                  ok: false,
                ),
                fakeDomainRecord(
                  'bakery.com',
                  type: 'FORWARD',
                  value: 'www.bakery.com',
                  purpose: 'forward',
                  required: false,
                ),
              ],
              events: [
                DomainEvent(
                  kind: 'connected',
                  detail: const {},
                  createdAt: DateTime(2026, 11, 16, 9),
                ),
                DomainEvent(
                  kind: 'needs_dns',
                  detail: const {'host': 'www.bakery.com'},
                  createdAt: DateTime(2026, 11, 16, 10),
                ),
              ],
            ),
          ];
        await tester.pumpWidget(_routed(backend, '/settings/domains/d-1'));
        await tester.pumpAndSettle();
        expect(
          find.textContaining('where your domain\'s DNS is managed'),
          findsOneWidget,
        );
        expect(find.byKey(const Key('domainRecordOk-0')), findsOneWidget);
        expect(find.byKey(const Key('domainRecordMissing-1')), findsOneWidget);
        expect(find.text('Not found yet'), findsOneWidget);
        expect(find.byKey(const Key('domainRecordOk-2')), findsNothing);
        expect(find.byKey(const Key('domainRecordMissing-2')), findsNothing);
        expect(find.byKey(const Key('domainRecordOptional-2')), findsOneWidget);
        expect(find.byKey(const Key('domainRecordOptional-0')), findsNothing);
        expect(
          find.text(
            'Turn on forwarding from bakery.com to www.bakery.com at the company you bought the domain from.',
          ),
          findsOneWidget,
        );
        await tester.tap(find.byKey(const Key('domainRecordCopyName-1')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('domainRecordCopyValue-1')));
        await tester.pumpAndSettle();
        expect(copied, ['_cf-custom-hostname.bakery.com', 'proof-123']);
        expect(find.text('Connected'), findsOneWidget);
        expect(find.text('Still waiting for DNS'), findsOneWidget);
        expect(
          find.textContaining('www.bakery.com · Nov 16, 2026'),
          findsOneWidget,
        );
      },
    );

    testWidgets('written for Cloudflare when that runs its DNS', (
      tester,
    ) async {
      await setSize(tester, const Size(500, 1400));
      final backend = _backend()
        ..domainList = [fakeDomain('d-1', dnsProvider: 'cloudflare')];
      await tester.pumpWidget(_routed(backend, '/settings/domains/d-1'));
      await tester.pumpAndSettle();
      expect(
        find.text('Add these at Cloudflare. Set the records to DNS only.'),
        findsOneWidget,
      );
    });

    testWidgets('Check Again asks the server; too soon is said gently', (
      tester,
    ) async {
      await setSize(tester, const Size(500, 1400));
      final backend = _backend()..domainList = [fakeDomain('d-1')];
      await tester.pumpWidget(_routed(backend, '/settings/domains/d-1'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('domainCheckAgain')));
      await tester.pumpAndSettle();
      expect(backend.domainActions, contains('check:d-1'));

      backend.checkDomainError = _problem(429, 'Checked a moment ago.');
      await tester.tap(find.byKey(const Key('domainCheckAgain')));
      await tester.pump();
      expect(find.text('Checked a moment ago.'), findsOneWidget);
      await tester.pumpAndSettle(const Duration(seconds: 6));
    });

    testWidgets('looks again every 30 seconds while waiting for DNS', (
      tester,
    ) async {
      await setSize(tester, const Size(500, 1400));
      final backend = _backend()..domainList = [fakeDomain('d-1')];
      await tester.pumpWidget(_routed(backend, '/settings/domains/d-1'));
      await tester.pumpAndSettle();
      int gets() => backend.domainActions.where((a) => a == 'get:d-1').length;
      expect(gets(), 1);
      await tester.pump(DomainScreen.pollEvery);
      await tester.pump();
      expect(gets(), 2);
      // Live: no more looking.
      backend.domainList = [fakeDomain('d-1', state: 'live')];
      await tester.pump(DomainScreen.pollEvery);
      await tester.pump();
      expect(gets(), 3);
      await tester.pump(DomainScreen.pollEvery * 2);
      expect(gets(), 3);
    });

    testWidgets('Make Primary on a live host that is not primary', (
      tester,
    ) async {
      await setSize(tester, const Size(500, 1400));
      final backend = _backend()
        ..domainList = [
          fakeDomain(
            'd-1',
            state: 'live',
            hosts: [
              fakeSiteHost('www.bakery.com', kind: 'custom'),
              fakeSiteHost('bakery.com', kind: 'custom', primary: false),
            ],
          ),
        ];
      await tester.pumpWidget(_routed(backend, '/settings/domains/d-1'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('domainMakePrimary-www.bakery.com')),
        findsNothing,
      );
      await tester.tap(find.byKey(const Key('domainMakePrimary-bakery.com')));
      await tester.pumpAndSettle();
      expect(backend.domainActions, contains('primary:d-1:bakery.com'));
      expect(
        find.byKey(const Key('domainMakePrimary-bakery.com')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('domainMakePrimary-www.bakery.com')),
        findsOneWidget,
      );
    });

    testWidgets('the site it shows can be changed, or set to None', (
      tester,
    ) async {
      await setSize(tester, const Size(500, 1400));
      final backend = _backend()
        ..siteList = [fakeSite('page-1')]
        ..domainList = [fakeDomain('d-1', state: 'live')];
      await tester.pumpWidget(_routed(backend, '/settings/domains/d-1'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('domainSite')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('domainSiteOption-page-1')));
      await tester.pumpAndSettle();
      expect(backend.domainActions, contains('site:d-1:page-1'));
      expect(
        find.descendant(
          of: find.byKey(const Key('domainSite')),
          matching: find.text('Space Dodger'),
        ),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('domainSite')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('domainSiteOption-none')));
      await tester.pumpAndSettle();
      expect(backend.domainActions.last, 'site:d-1:');
    });

    testWidgets('Disconnect asks first, then goes back to the list', (
      tester,
    ) async {
      await setSize(tester, const Size(500, 1400));
      final backend = _backend()
        ..domainList = [fakeDomain('d-1', state: 'live')];
      await tester.pumpWidget(_routed(backend, '/settings/domains'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('domain-d-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('domainDisconnect')));
      await tester.pumpAndSettle();
      expect(find.text('Disconnect bakery.com?'), findsOneWidget);
      await tester.tap(find.byKey(const Key('confirmDisconnectDomain')));
      await tester.pumpAndSettle();
      expect(backend.domainActions, contains('delete:d-1'));
      expect(find.byKey(const Key('domainsEmpty')), findsOneWidget);
    });
  });
}
