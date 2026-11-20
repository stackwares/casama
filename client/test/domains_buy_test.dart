// Buying and keeping a domain (SITES-AND-DOMAINS-PLAN §7.7–§7.10, §7.16): where Buy shows, Find a
// Domain's results, the registrant form, checkout in the browser or charged, the order's progress,
// a bought domain's screen (renewal, Renew Automatically, Renew Now, the registrant email, DNS
// Records, Move to Another Registrar), Admin → Domains and the delete-account list.
import 'package:casama/core/providers.dart';
import 'package:casama/core/remote_config.dart';
import 'package:casama/features/admin/admin_screen.dart';
import 'package:casama/features/billing/billing_screen.dart';
import 'package:casama/features/privacy/privacy_screen.dart';
import 'package:casama/features/sites/connect_domain_screen.dart';
import 'package:casama/features/sites/domain_buying.dart';
import 'package:casama/features/sites/domain_records_screen.dart';
import 'package:casama/features/sites/domain_screen.dart';
import 'package:casama/features/sites/domains_screen.dart';
import 'package:casama/features/sites/find_domain_screen.dart';
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
import 'admin_test_helpers.dart';

FakeBackend _backend({bool buy = true}) => FakeBackend()
  ..sitesConfig = SitesConfig(
    zone: 'sites.example',
    customDomains: true,
    buyDomains: buy,
    tlds: const ['com', 'net'],
  );

DomainContact _contact() => DomainContact(
  firstName: 'Ada',
  lastName: 'Lovelace',
  address1: '1 Main St',
  city: 'London',
  state: 'London',
  zip: 'N1 1AA',
  country: 'GB',
  phone: '+44 20 7946 0000',
  email: 'ada@example.com',
);

DioException _problem(int status, String code, String detail) {
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
        'code': code,
        'detail': detail,
      },
    ),
  );
}

Widget _routed(
  FakeBackend backend,
  String initial, {
  TargetPlatform platform = TargetPlatform.macOS,
  List<String>? opened,
}) {
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
            path: 'find',
            builder: (_, s) =>
                FindDomainScreen(query: s.uri.queryParameters['q']),
          ),
          GoRoute(
            path: 'contact',
            builder: (_, _) => const DomainContactScreen(),
          ),
          GoRoute(
            path: 'orders/:orderId',
            builder: (_, s) => DomainOrderScreen(
              orderId: s.pathParameters['orderId']!,
              paying: s.uri.queryParameters['paying'] == '1',
            ),
          ),
          GoRoute(
            path: ':id',
            builder: (_, s) => DomainScreen(domainId: s.pathParameters['id']!),
            routes: [
              GoRoute(
                path: 'records',
                builder: (_, s) => DomainRecordsScreen(
                  domainId: s.pathParameters['id']!,
                  domainName: s.uri.queryParameters['name'],
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      backendProvider.overrideWithValue(backend),
      platformProvider.overrideWithValue(platform),
      openUrlProvider.overrideWithValue((url) async => opened?.add(url)),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

/// Pumps frames for [ms] without waiting for spinners to stop.
Future<void> _settle(WidgetTester tester, {int ms = 1200}) async {
  for (var i = 0; i < ms ~/ 100; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

DomainSearchResult _result(
  String name, {
  bool available = true,
  String? reason,
}) => DomainSearchResult(
  name: name,
  available: available,
  reason: reason,
  priceUsd: available ? 14.5 : null,
  renewPriceUsd: available ? 18.5 : null,
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('Where Buy shows', () {
    testWidgets('on the desktop app, Find a Domain is offered', (tester) async {
      await tester.pumpWidget(_routed(_backend(), '/settings/domains'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('domainsFind')), findsOneWidget);
      expect(find.textContaining('web or the desktop app'), findsNothing);
    });

    testWidgets('never on Android, and no pointer to buying elsewhere', (
      tester,
    ) async {
      await tester.pumpWidget(
        _routed(
          _backend(),
          '/settings/domains',
          platform: TargetPlatform.android,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('domainsFind')), findsNothing);
      // Store rules: no call to action toward another way to pay (Play §4, App Store 3.1.1(a)).
      expect(find.textContaining('web or the desktop app'), findsNothing);
      expect(find.byKey(const Key('domainsConnect')), findsOneWidget);
    });

    testWidgets('not when the server sells no domains, and no web line', (
      tester,
    ) async {
      await tester.pumpWidget(
        _routed(_backend(buy: false), '/settings/domains'),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('domainsFind')), findsNothing);
      expect(find.textContaining('web or the desktop app'), findsNothing);
    });

    testWidgets('not for members', (tester) async {
      final container = ProviderContainer(
        overrides: [
          backendProvider.overrideWithValue(
            _backend()..orgRole = OrgRole.member,
          ),
          platformProvider.overrideWithValue(TargetPlatform.macOS),
        ],
      );
      addTearDown(container.dispose);
      await container.read(organizationsProvider.future);
      expect(container.read(canBuyDomainsProvider), isFalse);
    });

    testWidgets('the App Store switch hides buying on iOS only', (tester) async {
      Future<bool> canBuy(TargetPlatform platform, Map<String, bool> flags) async {
        final config = RemoteAppConfig(
          minVersions: RemoteAppConfigMinVersions(),
          updateUrls: RemoteAppConfigUpdateUrls(),
          maintenance: null,
          announcements: const [],
          flags: flags,
        );
        final backend = _backend();
        final org = (await backend.organizations()).first;
        final container = ProviderContainer(
          overrides: [
            backendProvider.overrideWithValue(backend),
            currentOrgProvider.overrideWithValue(org),
            platformProvider.overrideWithValue(platform),
            storefrontProvider.overrideWith((ref) async => 'USA'),
            remoteConfigProvider.overrideWith(() => _FixedConfig(config)),
          ],
        );
        addTearDown(container.dispose);
        await container.read(storefrontProvider.future);
        await container.read(remoteConfigProvider.future);
        return container.read(canBuyDomainsProvider);
      }

      // iOS on the US storefront can buy; so can the desktop (Developer ID) Mac build.
      expect(await canBuy(TargetPlatform.iOS, const {}), isTrue);
      expect(await canBuy(TargetPlatform.macOS, const {}), isTrue);
      // Switched off: the App Store build stops, the desktop build is unaffected.
      const off = {'buy_domains_app_store': false};
      expect(await canBuy(TargetPlatform.iOS, off), isFalse);
      expect(await canBuy(TargetPlatform.macOS, off), isTrue);
    });

    testWidgets('a bot link on Android opens Find a Domain without Buy', (
      tester,
    ) async {
      await tester.pumpWidget(
        _routed(
          _backend(),
          '/settings/domains/find?q=bakery',
          platform: TargetPlatform.android,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('findDomainNotOffered')), findsOneWidget);
      expect(find.byKey(const Key('findDomainField')), findsNothing);
    });
  });

  group('Find a Domain', () {
    testWidgets(
      'a bot link fills in the name; results show prices and greyed names',
      (tester) async {
        final backend = _backend()
          ..domainSearchResults = {
            'bakery': [
              _result('bakery.net'),
              _result('bakery.com', available: false, reason: 'taken'),
              _result('bakery.io', available: false, reason: 'premium'),
            ],
          };
        await tester.pumpWidget(
          _routed(backend, '/settings/domains/find?q=bakery'),
        );
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<TextField>(find.byKey(const Key('findDomainField')))
              .controller!
              .text,
          'bakery',
        );
        expect(backend.domainActions, contains('search:bakery'));
        expect(
          find.textContaining(r'$14.50 a year plus tax · Renews at $18.50'),
          findsOneWidget,
        );
        expect(find.byKey(const Key('domainBuy-bakery.net')), findsOneWidget);
        expect(find.byKey(const Key('domainBuy-bakery.com')), findsNothing);
        expect(find.text('Taken'), findsOneWidget);
        expect(find.text('Premium name, not sold here'), findsOneWidget);
      },
    );

    testWidgets('typing searches after a pause', (tester) async {
      final backend = _backend()
        ..domainSearchResults = {
          'shop': [_result('shop.dev')],
        };
      await tester.pumpWidget(_routed(backend, '/settings/domains/find'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('findDomainField')), 'sh');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(find.byKey(const Key('findDomainField')), 'shop');
      await tester.pump(FindDomainScreen.debounce);
      await tester.pumpAndSettle();
      expect(backend.domainActions.where((a) => a.startsWith('search:')), [
        'search:shop',
      ]);
      expect(find.byKey(const Key('domainResult-shop.dev')), findsOneWidget);
    });
  });

  group('Buying', () {
    FakeBackend buyable() => _backend()
      ..domainSearchResults = {
        'bakery': [_result('bakery.com')],
      };

    testWidgets('the first purchase asks for the registrant and checks it', (
      tester,
    ) async {
      await setSize(tester, const Size(1000, 2400));
      final backend = buyable();
      await tester.pumpWidget(
        _routed(backend, '/settings/domains/find?q=bakery'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('domainBuy-bakery.com')));
      await tester.pumpAndSettle();
      // Prefilled with the account's email.
      expect(
        tester
            .widget<TextFormField>(find.byKey(const Key('domainContact-email')))
            .controller!
            .text,
        'ada@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('domainContact-country')),
        'USA',
      );
      await tester.enterText(
        find.byKey(const Key('domainContact-phone')),
        '4155550100',
      );
      await tester.tap(find.byKey(const Key('domainContactSave')));
      await tester.pumpAndSettle();
      expect(find.text('Required'), findsNWidgets(6));
      expect(find.text('Use a two-letter code, like US'), findsOneWidget);
      expect(
        find.text('Use international form, like +1 415 555 0100'),
        findsOneWidget,
      );
      expect(backend.savedDomainContact, isNull);

      Future<void> type(String key, String text) =>
          tester.enterText(find.byKey(Key('domainContact-$key')), text);
      await type('first', 'Ada');
      await type('last', 'Lovelace');
      await type('address1', '1 Main St');
      await type('city', 'Springfield');
      await type('state', 'IL');
      await type('zip', '62701');
      await type('country', 'us');
      await type('phone', '+1 415 555 0100');
      await tester.tap(find.byKey(const Key('domainContactSave')));
      await tester.pumpAndSettle();
      expect(backend.savedDomainContact?.country, 'US');
      expect(backend.savedDomainContact?.email, 'ada@example.com');
      // Then the buy sheet.
      expect(find.byKey(const Key('domainBuyTerms')), findsOneWidget);
    });

    testWidgets(
      'checkout opens the payment page and follows the order to the domain',
      (tester) async {
        await setSize(tester, const Size(1000, 2400));
        final opened = <String>[];
        final backend = buyable()
          ..savedDomainContact = _contact()
          ..domainOrderStatuses = ['checkout', 'registering', 'done']
          ..domainOrderDomainId = 'd-9'
          ..domainList = [fakeRegisteredDomain('d-9')];
        await tester.pumpWidget(
          _routed(backend, '/settings/domains/find?q=bakery', opened: opened),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('domainBuy-bakery.com')));
        await tester.pumpAndSettle();
        // No buying until the terms are ticked.
        await tester.tap(find.byKey(const Key('domainBuySubmit')));
        await tester.pumpAndSettle();
        expect(
          backend.domainActions.where((a) => a.startsWith('checkout')),
          isEmpty,
        );
        expect(
          find.textContaining('then \$18.50 a year, plus tax'),
          findsOneWidget,
        );
        await tester.tap(find.byKey(const Key('domainBuyTerms')));
        await tester.tap(find.byKey(const Key('domainBuyAutoRenew')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('domainBuySubmit')));
        await _settle(tester);
        expect(backend.domainActions, contains('checkout:bakery.com::false'));
        expect(opened, ['https://pay.example/checkout']);
        expect(find.byKey(const Key('domainOrder-checkout')), findsOneWidget);
        expect(
          find.text('Waiting for your payment in the browser.'),
          findsOneWidget,
        );

        await tester.pump(DomainOrderScreen.pollEvery);
        await _settle(tester, ms: 300);
        expect(find.text('Registering bakery.com…'), findsOneWidget);
        await tester.pump(DomainOrderScreen.pollEvery);
        await _settle(tester);
        // Done: the new domain's screen.
        expect(find.byKey(const Key('domainRenewsOn')), findsOneWidget);
      },
    );

    testWidgets('with a saved payment method it is charged, with no browser', (
      tester,
    ) async {
      await setSize(tester, const Size(1000, 2400));
      final opened = <String>[];
      final backend = buyable()
        ..savedDomainContact = _contact()
        ..domainCheckoutUrl = null
        ..domainOrderStatuses = ['paid', 'done']
        ..domainOrderDomainId = 'd-9'
        ..domainList = [fakeRegisteredDomain('d-9')];
      await tester.pumpWidget(
        _routed(backend, '/settings/domains/find?q=bakery', opened: opened),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('domainBuy-bakery.com')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('domainBuyTerms')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('domainBuySubmit')));
      await _settle(tester);
      expect(backend.domainActions, contains('checkout:bakery.com::true'));
      expect(opened, isEmpty);
      expect(find.text('Registering bakery.com…'), findsOneWidget);
      await tester.pump(DomainOrderScreen.pollEvery);
      await _settle(tester);
      expect(find.byKey(const Key('domainRenewsOn')), findsOneWidget);
    });

    testWidgets('a refused checkout shows the server\'s words', (tester) async {
      await setSize(tester, const Size(1000, 2400));
      final backend = buyable()
        ..savedDomainContact = _contact()
        ..domainCheckoutError = _problem(
          429,
          'purchase_cap',
          'This workspace has bought 3 domains in its first 30 days.',
        );
      await tester.pumpWidget(
        _routed(backend, '/settings/domains/find?q=bakery'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('domainBuy-bakery.com')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('domainBuyTerms')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('domainBuySubmit')));
      await tester.pumpAndSettle();
      expect(
        find.text('This workspace has bought 3 domains in its first 30 days.'),
        findsOneWidget,
      );
    });

    testWidgets('an order that could not be registered says it was refunded', (
      tester,
    ) async {
      final backend = _backend()
        ..domainOrderStatuses = ['registering', 'refunded']
        ..domainOrderFailure = 'Someone else registered it first.';
      await tester.pumpWidget(
        _routed(backend, '/settings/domains/orders/order-1'),
      );
      await _settle(tester, ms: 300);
      expect(find.text('Registering bakery.com…'), findsOneWidget);
      await tester.pump(DomainOrderScreen.pollEvery);
      await tester.pumpAndSettle();
      expect(
        find.text(
          "We couldn't register bakery.com, so we refunded you in full.",
        ),
        findsOneWidget,
      );
      expect(find.text('Someone else registered it first.'), findsOneWidget);
      expect(find.byKey(const Key('domainOrderBack')), findsOneWidget);
      // It stops looking once the order has ended.
      final polls = backend.domainActions
          .where((a) => a.startsWith('order:'))
          .length;
      await tester.pump(DomainOrderScreen.pollEvery * 2);
      expect(
        backend.domainActions.where((a) => a.startsWith('order:')).length,
        polls,
      );
    });
  });

  group('A bought domain', () {
    testWidgets(
      'shows renewal, its switch and links instead of records to add',
      (tester) async {
        await setSize(tester, const Size(430, 2400));
        final backend = _backend()..domainList = [fakeRegisteredDomain('d-1')];
        await tester.pumpWidget(_routed(backend, '/settings/domains/d-1'));
        await tester.pumpAndSettle();
        expect(find.text('Renews on Nov 16, 2027'), findsOneWidget);
        expect(find.text(r'$18.50 a year plus tax'), findsOneWidget);
        expect(
          tester.widget<Switch>(find.byKey(const Key('domainAutoRenew'))).value,
          isTrue,
        );
        expect(find.byKey(const Key('domainRenewNow')), findsOneWidget);
        expect(find.byKey(const Key('domainDnsRecords')), findsOneWidget);
        expect(find.byKey(const Key('domainContactDetails')), findsOneWidget);
        expect(find.byKey(const Key('domainMoveOut')), findsOneWidget);
        expect(find.text('Records to add'), findsNothing);
        expect(find.byKey(const Key('domainDisconnect')), findsNothing);
        expect(find.byKey(const Key('domainVerifyBanner')), findsNothing);
        expect(find.byKey(const Key('domainStateLine')), findsNothing);
      },
    );

    testWidgets('on Android: no price, no Renew Now, the switch only turns renewals off', (
      tester,
    ) async {
      await setSize(tester, const Size(430, 2400));
      final backend = _backend()
        ..domainList = [
          fakeRegisteredDomain('d-1'),
          fakeRegisteredDomain('d-2', name: 'cafe.com', autoRenew: false),
        ];
      await tester.pumpWidget(
        _routed(backend, '/settings/domains/d-1', platform: TargetPlatform.android),
      );
      await tester.pumpAndSettle();
      expect(find.text('Renews on Nov 16, 2027'), findsOneWidget);
      expect(find.textContaining('a year plus tax'), findsNothing);
      expect(find.byKey(const Key('domainRenewNow')), findsNothing);
      final on = tester.widget<Switch>(find.byKey(const Key('domainAutoRenew')));
      expect(on.value, isTrue);
      expect(on.onChanged, isNotNull);
      expect(find.byKey(const Key('domainDnsRecords')), findsOneWidget);

      await tester.pumpWidget(
        _routed(backend, '/settings/domains/d-2', platform: TargetPlatform.android),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('domainAutoRenewRow')), findsNothing);
      expect(find.byKey(const Key('domainRenewNow')), findsNothing);
    });

    testWidgets('the registrant email banner sends again', (tester) async {
      await setSize(tester, const Size(430, 2400));
      final backend = _backend()
        ..domainList = [fakeRegisteredDomain('d-1', registrantVerified: false)];
      await tester.pumpWidget(_routed(backend, '/settings/domains/d-1'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('domainVerifyBanner')), findsOneWidget);
      await tester.tap(find.byKey(const Key('domainVerifySendAgain')));
      await tester.pumpAndSettle();
      expect(backend.domainActions, contains('verifyEmail:d-1'));
      expect(find.text("Sent. Check the registrant's inbox."), findsOneWidget);
    });

    testWidgets('an expired domain says so; a lapsed one points to support', (
      tester,
    ) async {
      await setSize(tester, const Size(430, 2400));
      final backend = _backend()
        ..domainList = [
          fakeRegisteredDomain('d-1', registrarStatus: 'expired'),
          fakeRegisteredDomain(
            'd-2',
            name: 'old.com',
            registrarStatus: 'lapsed',
          ),
        ];
      await tester.pumpWidget(_routed(backend, '/settings/domains/d-1'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Expired on Nov 16, 2027. Renew within 25 days of that date to keep it.',
        ),
        findsOneWidget,
      );
      expect(find.text('Expires on Nov 16, 2027'), findsOneWidget);

      await tester.pumpWidget(_routed(backend, '/settings/domains/d-2'));
      await tester.pumpAndSettle();
      expect(find.textContaining('This domain has lapsed.'), findsOneWidget);
    });

    testWidgets('Renew Automatically turns off', (tester) async {
      await setSize(tester, const Size(430, 2400));
      final backend = _backend()..domainList = [fakeRegisteredDomain('d-1')];
      await tester.pumpWidget(_routed(backend, '/settings/domains/d-1'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('domainAutoRenew')));
      await tester.pumpAndSettle();
      expect(backend.domainActions, contains('autoRenew:d-1:false'));
      expect(
        tester.widget<Switch>(find.byKey(const Key('domainAutoRenew'))).value,
        isFalse,
      );
      expect(find.text('Expires on Nov 16, 2027'), findsOneWidget);
    });

    testWidgets('Renew Now opens the payment page, or is charged', (
      tester,
    ) async {
      await setSize(tester, const Size(430, 2400));
      final opened = <String>[];
      final backend = _backend()..domainList = [fakeRegisteredDomain('d-1')];
      await tester.pumpWidget(
        _routed(backend, '/settings/domains/d-1', opened: opened),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('domainRenewNow')));
      await tester.pumpAndSettle();
      expect(backend.domainActions, contains('renew:d-1'));
      expect(opened, ['https://pay.example/checkout']);
      expect(
        find.text(
          "Finish paying in your browser. The new date shows here once it's paid.",
        ),
        findsOneWidget,
      );

      backend.domainCheckoutUrl = null;
      await tester.pump(const Duration(seconds: 5));
      await tester.tap(find.byKey(const Key('domainRenewNow')));
      await tester.pumpAndSettle();
      expect(opened, hasLength(1));
      expect(
        find.text('Renewed. The new date shows here in a minute.'),
        findsOneWidget,
      );
    });

    testWidgets('Renew Now past the late window shows the server\'s words', (
      tester,
    ) async {
      await setSize(tester, const Size(430, 2400));
      final backend = _backend()
        ..domainList = [fakeRegisteredDomain('d-1', registrarStatus: 'lapsed')]
        ..renewDomainError = _problem(
          409,
          'restore_by_support',
          'Write to support to restore it.',
        );
      await tester.pumpWidget(_routed(backend, '/settings/domains/d-1'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('domainRenewNow')));
      await tester.pumpAndSettle();
      expect(find.text('Write to support to restore it.'), findsOneWidget);
    });

    testWidgets('the contact details screen saves the workspace contact', (
      tester,
    ) async {
      await setSize(tester, const Size(430, 2400));
      final backend = _backend()..savedDomainContact = _contact();
      await tester.pumpWidget(_routed(backend, '/settings/domains/contact'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('domainContact-city')),
        'Paris',
      );
      await tester.tap(find.byKey(const Key('domainContactSave')));
      await tester.pumpAndSettle();
      expect(backend.savedDomainContact?.city, 'Paris');
      expect(find.text('Contact details saved.'), findsOneWidget);
    });
  });

  group('DNS records', () {
    FakeBackend withRecords() => _backend()
      ..domainList = [fakeRegisteredDomain('d-1')]
      ..domainRecordLists = {
        'd-1': [
          DnsRecordItem(
            id: 'r-site',
            host: 'www',
            type: 'CNAME',
            answer: 'd-abc123.sites.example',
            ttl: 300,
            priority: null,
            managed: true,
          ),
          DnsRecordItem(
            id: 'r-mx',
            host: '',
            type: 'MX',
            answer: 'mx.mail.example',
            ttl: 300,
            priority: 10,
            managed: false,
          ),
        ],
      };

    testWidgets('the site\'s records are locked; others can be deleted', (
      tester,
    ) async {
      await setSize(tester, const Size(430, 2400));
      final backend = withRecords();
      await tester.pumpWidget(
        _routed(backend, '/settings/domains/d-1/records?name=bakery.com'),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Used by your Casama site'), findsOneWidget);
      expect(find.byKey(const Key('dnsRecordDelete-r-site')), findsNothing);
      await tester.tap(find.byKey(const Key('dnsRecord-r-site')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('dnsRecordSave')), findsNothing);
      expect(find.text('MX  bakery.com'), findsOneWidget);

      await tester.tap(find.byKey(const Key('dnsRecordDelete-r-mx')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirmDeleteRecord')));
      await tester.pumpAndSettle();
      expect(backend.domainActions, contains('deleteRecord:d-1:r-mx'));
      expect(find.byKey(const Key('dnsRecord-r-mx')), findsNothing);
    });

    testWidgets('adds a record', (tester) async {
      await setSize(tester, const Size(430, 2400));
      final backend = withRecords();
      await tester.pumpWidget(
        _routed(backend, '/settings/domains/d-1/records?name=bakery.com'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('dnsRecordAdd')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('dnsRecordType')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('TXT').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('dnsRecordHost')), '_dmarc');
      await tester.enterText(
        find.byKey(const Key('dnsRecordAnswer')),
        'v=DMARC1; p=none',
      );
      await tester.tap(find.byKey(const Key('dnsRecordSave')));
      await tester.pumpAndSettle();
      expect(
        backend.domainActions,
        contains('addRecord:d-1:TXT:_dmarc:v=DMARC1; p=none'),
      );
      expect(find.text('TXT  _dmarc'), findsOneWidget);
    });

    testWidgets('a refused record shows why under the fields', (tester) async {
      await setSize(tester, const Size(430, 2400));
      final backend = withRecords()
        ..addDomainRecordError = _problem(
          400,
          'invalid_record',
          'A CNAME can\'t share its name with other records.',
        );
      await tester.pumpWidget(
        _routed(backend, '/settings/domains/d-1/records?name=bakery.com'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('dnsRecordAdd')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('dnsRecordAnswer')),
        '1.2.3.4',
      );
      await tester.tap(find.byKey(const Key('dnsRecordSave')));
      await tester.pumpAndSettle();
      expect(
        tester.widget<Text>(find.byKey(const Key('dnsRecordError'))).data,
        "A CNAME can't share its name with other records.",
      );
      // The sheet stays open to fix it.
      expect(find.byKey(const Key('dnsRecordSave')), findsOneWidget);
    });
  });

  group('Move to Another Registrar', () {
    testWidgets('before the lock ends it gives the date', (tester) async {
      await setSize(tester, const Size(430, 2400));
      final backend = _backend()
        ..domainList = [
          fakeRegisteredDomain('d-1', transferAfter: DateTime(2099, 1, 15)),
        ];
      await tester.pumpWidget(_routed(backend, '/settings/domains/d-1'));
      await tester.pumpAndSettle();
      expect(find.text('It can move after Jan 15, 2099'), findsOneWidget);
      await tester.tap(find.byKey(const Key('domainMoveOut')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('domainMoveOutName')), findsNothing);
    });

    testWidgets('only the owner sees it', (tester) async {
      await setSize(tester, const Size(430, 2400));
      final backend = _backend()
        ..orgRole = OrgRole.admin
        ..domainList = [fakeRegisteredDomain('d-1')];
      await tester.pumpWidget(_routed(backend, '/settings/domains/d-1'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('domainMoveOut')), findsNothing);
      expect(find.byKey(const Key('domainRenewNow')), findsOneWidget);
    });

    testWidgets('typing the name shows the code once, then Lock Again', (
      tester,
    ) async {
      await setSize(tester, const Size(430, 2400));
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
      final backend = _backend()
        ..domainList = [
          fakeRegisteredDomain('d-1', transferAfter: DateTime(2026, 1, 1)),
        ];
      await tester.pumpWidget(_routed(backend, '/settings/domains/d-1'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('domainMoveOut')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('domainMoveOutConfirm')));
      await tester.pumpAndSettle();
      expect(
        backend.domainActions.where((a) => a.startsWith('transferOut')),
        isEmpty,
      );
      await tester.enterText(
        find.byKey(const Key('domainMoveOutName')),
        'Bakery.com',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('domainMoveOutConfirm')));
      await tester.pumpAndSettle();
      expect(backend.domainActions, contains('transferOut:d-1:bakery.com'));
      expect(find.text('EPP-CODE-123'), findsOneWidget);
      await tester.tap(find.byKey(const Key('domainTransferCodeCopy')));
      await tester.pump();
      expect(copied, ['EPP-CODE-123']);
      await tester.tap(find.byKey(const Key('domainTransferCodeDone')));
      await tester.pumpAndSettle();
      // Gone once closed: never kept on screen.
      expect(find.text('EPP-CODE-123'), findsNothing);
      expect(find.byKey(const Key('domainLockAgain')), findsOneWidget);
      await tester.tap(find.byKey(const Key('domainLockAgain')));
      await tester.pumpAndSettle();
      expect(backend.domainActions, contains('lock:d-1'));
      expect(find.byKey(const Key('domainLockAgain')), findsNothing);
    });

    testWidgets('the server\'s transfer lock gives the date', (tester) async {
      await setSize(tester, const Size(430, 2400));
      final backend = _backend()
        ..domainList = [
          fakeRegisteredDomain('d-1', transferAfter: DateTime(2026, 1, 1)),
        ]
        ..transferOutError = _problem(409, 'transfer_locked', 'Locked.');
      await tester.pumpWidget(_routed(backend, '/settings/domains/d-1'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('domainMoveOut')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('domainMoveOutName')),
        'bakery.com',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('domainMoveOutConfirm')));
      await tester.pumpAndSettle();
      expect(find.text('It can move after Jan 1, 2026.'), findsOneWidget);
    });

    testWidgets('an old sign-in asks to sign in again, then shows the code', (
      tester,
    ) async {
      await setSize(tester, const Size(430, 2400));
      final backend = _FreshBackend()
        ..sitesConfig = _backend().sitesConfig
        ..domainList = [
          fakeRegisteredDomain('d-1', transferAfter: DateTime(2026, 1, 1)),
        ];
      await tester.pumpWidget(_routed(backend, '/settings/domains/d-1'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('domainMoveOut')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('domainMoveOutName')),
        'bakery.com',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('domainMoveOutConfirm')));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Sign in again to get a transfer code. It needs a sign-in from the last 10 minutes.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('domainReauthSubmit')));
      await tester.pumpAndSettle();
      expect(backend.magicLinkEmail, 'tester@example.com');
      await tester.enterText(
        find.byKey(const Key('domainReauthCode')),
        '123456',
      );
      await tester.tap(find.byKey(const Key('domainReauthSubmit')));
      await tester.pumpAndSettle();
      expect(backend.verifiedCode, '123456');
      expect(find.text('EPP-CODE-123'), findsOneWidget);
    });
  });

  group('Admin → Domains', () {
    testWidgets('approves and retries orders, suspends a domain after asking', (
      tester,
    ) async {
      await setSize(tester, const Size(1000, 2400));
      final backend = FakeBackend()
        ..adminDomainsData = AdminDomains(
          counts: AdminDomainsCounts(
            connected: 4,
            registered: 7,
            liveHosts: 9,
            suspended: 1,
          ),
          balanceUsd: 250,
          orders: [
            AdminDomainOrder(
              id: 'o-new',
              kind: 'register',
              name: 'new.com',
              priceUsd: 14.5,
              status: 'paid',
              failure: null,
              needsApproval: true,
              domainId: null,
              createdAt: DateTime(2026, 11, 16),
              paidAt: DateTime(2026, 11, 16),
              refundedAt: null,
              orgId: 'org-2',
              orgName: 'Bakery',
              attempts: 0,
            ),
            AdminDomainOrder(
              id: 'o-stuck',
              kind: 'register',
              name: 'stuck.com',
              priceUsd: 14.5,
              status: 'needs_attention',
              failure: 'Refund failed',
              needsApproval: false,
              domainId: null,
              createdAt: DateTime(2026, 11, 16),
              paidAt: DateTime(2026, 11, 16),
              refundedAt: null,
              orgId: 'org-2',
              orgName: 'Bakery',
              attempts: 2,
            ),
          ],
          domains: [
            AdminDomain(
              id: 'dom-1',
              name: 'bakery.com',
              kind: 'registered',
              orgId: 'org-2',
              orgName: 'Bakery',
              registrarStatus: 'active',
              expiresAt: DateTime(2027, 11, 16),
              suspended: false,
              createdAt: DateTime(2026, 11, 16),
            ),
          ],
        );
      await tester.pumpWidget(harness(backend, const AdminScreen()));
      await tester.pumpAndSettle();
      await unlockAdmin(tester);
      await tester.tap(find.widgetWithText(Tab, 'Domains'));
      await tester.pumpAndSettle();
      expect(find.textContaining(r'$250.00'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);

      await tester.tap(find.byKey(const Key('adminDomainApprove-o-new')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('adminDomainRetry-o-stuck')));
      await tester.pumpAndSettle();
      expect(backend.adminDomainActions, ['approve:o-new', 'retry:o-stuck']);

      await tester.tap(find.byKey(const Key('adminDomainSuspend-dom-1')));
      await tester.pumpAndSettle();
      expect(find.text('Suspend bakery.com?'), findsOneWidget);
      await tester.tap(find.byKey(const Key('confirmDomainSuspend')));
      await tester.pumpAndSettle();
      expect(backend.adminDomainActions.last, 'suspend:dom-1');
    });
  });

  group('Deleting the account', () {
    testWidgets('lists bought domains and what happens to them', (
      tester,
    ) async {
      await setSize(tester, const Size(430, 2400));
      final backend = _backend()
        ..domainList = [
          fakeRegisteredDomain('d-1'),
          fakeDomain('d-2', name: 'mine.org'),
        ];
      await tester.pumpWidget(harness(backend, const PrivacyScreen()));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('deleteAccount')));
      await tester.tap(find.byKey(const Key('deleteAccount')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('deleteAccountDomains')), findsOneWidget);
      expect(
        find.byKey(const Key('deleteAccountDomain-bakery.com')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('deleteAccountDomain-mine.org')),
        findsNothing,
      );
      expect(
        find.text(
          'These domains stay registered to their registrant until they expire, stop renewing, '
          'and their sites go offline.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('no list without bought domains', (tester) async {
      await setSize(tester, const Size(430, 2400));
      final backend = _backend()
        ..domainList = [fakeDomain('d-2', name: 'mine.org')];
      await tester.pumpWidget(harness(backend, const PrivacyScreen()));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('deleteAccount')));
      await tester.tap(find.byKey(const Key('deleteAccount')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('deleteAccountDomains')), findsNothing);
      expect(find.byKey(const Key('confirmEmail')), findsOneWidget);
    });
  });
}

/// Answers 401 reauthentication_needed until the person has signed in again with a code.
class _FreshBackend extends FakeBackend {
  @override
  Future<String> transferOutDomain(String id, String confirmName) async {
    if (verifiedCode == null) {
      throw _problem(
        401,
        'reauthentication_needed',
        'Sign in again to get a transfer code. It needs a sign-in from the last 10 minutes.',
      );
    }
    return super.transferOutDomain(id, confirmName);
  }
}

/// Remote settings fixed for a test: no fetch, no timer.
class _FixedConfig extends RemoteConfigNotifier {
  _FixedConfig(this.config);
  final RemoteAppConfig config;

  @override
  Future<RemoteAppConfig?> build() async => config;
}
