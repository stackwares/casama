import 'package:casama/core/analytics.dart';
import 'package:casama/core/analytics_sinks.dart';
import 'package:casama/core/telemetry.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ANALYTICS_PROVIDERS (D-397)', () {
    test(
      'empty means every configured provider, GA4 only when GA4_ENABLED',
      () {
        expect(parseAnalyticsProviders(''), isNull);
        expect(parseAnalyticsProviders(' , '), isNull);
        expect(
          analyticsProviderOn('posthog', raw: '', configured: true),
          isTrue,
        );
        expect(
          analyticsProviderOn('posthog', raw: '', configured: false),
          isFalse,
        );
        expect(
          analyticsProviderOn(
            'ga4',
            raw: '',
            configured: true,
            onByDefault: false,
          ),
          isFalse,
        );
        expect(
          analyticsProviderOn(
            'ga4',
            raw: '',
            configured: true,
            onByDefault: true,
          ),
          isTrue,
        );
      },
    );

    test('a list picks providers, and still needs their config', () {
      expect(parseAnalyticsProviders('PostHog, ga4'), {'posthog', 'ga4'});
      expect(
        analyticsProviderOn(
          'ga4',
          raw: 'ga4',
          configured: true,
          onByDefault: false,
        ),
        isTrue,
      );
      expect(
        analyticsProviderOn('posthog', raw: 'ga4', configured: true),
        isFalse,
      );
      expect(
        analyticsProviderOn('ga4', raw: 'ga4', configured: false),
        isFalse,
      );
      expect(
        analyticsProviderOn('posthog', raw: 'posthog ga4', configured: true),
        isTrue,
      );
    });

    test('none turns everything off', () {
      expect(
        analyticsProviderOn('posthog', raw: 'none', configured: true),
        isFalse,
      );
      expect(
        analyticsProviderOn('ga4', raw: 'none,ga4', configured: true),
        isFalse,
      );
    });
  });

  test('GA4 runs on Android, iOS, macOS and the web only', () {
    expect(
      ga4PlatformSupported(isWeb: true, platform: TargetPlatform.linux),
      isTrue,
    );
    for (final p in [
      TargetPlatform.android,
      TargetPlatform.iOS,
      TargetPlatform.macOS,
    ]) {
      expect(ga4PlatformSupported(isWeb: false, platform: p), isTrue);
    }
    for (final p in [
      TargetPlatform.windows,
      TargetPlatform.linux,
      TargetPlatform.fuchsia,
    ]) {
      expect(ga4PlatformSupported(isWeb: false, platform: p), isFalse);
    }
  });

  group('ga4Params', () {
    test(
      'keeps strings and numbers, turns booleans into 1/0, drops the rest',
      () {
        final p = ga4Params({
          'plan': 'plus',
          'step_index': 2,
          'duration_s': 1.5,
          'on': true,
          'reconnect': false,
          'missing': null,
          'list': [1, 2],
          'map': {'a': 1},
        });
        expect(p, {
          'plan': 'plus',
          'step_index': 2,
          'duration_s': 1.5,
          'on': 1,
          'reconnect': 0,
        });
      },
    );

    test('cuts text to 100 and scrubs secrets and emails', () {
      final p = ga4Params({
        'reason': 'x' * 300,
        'error_code': 'ada@example.com',
      });
      expect((p['reason'] as String).length, 100);
      expect(p['error_code'], isNot(contains('ada@example.com')));
    });

    test('drops reserved and over-long keys, keeps at most 25', () {
      final p = ga4Params({
        r'$screen_name': 'x',
        'firebase_x': 'x',
        'google_x': 'x',
        'ga_x': 'x',
        'k' * 41: 'x',
        for (var i = 0; i < 30; i++) 'p$i': i,
      });
      expect(
        p.keys.any(
          (k) =>
              k.startsWith(r'$') ||
              k.startsWith('firebase_') ||
              k.startsWith('ga_'),
        ),
        isFalse,
      );
      expect(p.length, 25);
    });

    test('null properties give an empty map', () {
      expect(ga4Params(null), isEmpty);
    });
  });

  test('without keys no provider is on and nothing is sent', () async {
    expect(Telemetry.analyticsProviders, isEmpty);
    expect(Telemetry.posthogAnalyticsOn, isFalse);
    expect(Telemetry.ga4On, isFalse);
    expect(Telemetry.observers, isEmpty);
    // All safe no-ops without a provider (no platform channel is touched).
    await Analytics.capture('signed_up');
    await Analytics.identify('u1');
    await Analytics.syncGa4();
    Analytics.screen('/chat');
  });

  group('ga4Events (D-398)', () {
    test('adds the recommended twin with only its own params and constants', () {
      final events = ga4Events('purchase_started', {'store': 'dodo', 'kind': 'plan', 'product_id': 'plus_m', 'surface': 'x'});
      expect(events.map((e) => e.name), ['purchase_started', 'begin_checkout']);
      expect(events[1].params, {'currency': 'USD', 'store': 'dodo', 'kind': 'plan', 'product_id': 'plus_m'});
      expect(events[0].params['surface'], 'x');
    });

    test('shares become share with a content type', () {
      final events = ga4Events('referral_shared', {'method': 'copy'});
      expect(events.last.name, 'share');
      expect(events.last.params, {'content_type': 'referral', 'method': 'copy'});
    });

    test('paywall_view becomes view_item_list with defaults', () {
      final events = ga4Events('paywall_view', {
        'source': 'limit',
        'paywall_kind': 'regular',
        'default_plan': 'pro',
        'default_period': 'month',
      });
      expect(events.map((e) => e.name), ['paywall_view', 'view_item_list']);
      expect(events.last.params, {
        'item_list_id': 'paywall',
        'item_list_name': 'Casama plans',
        'source': 'limit',
        'paywall_kind': 'regular',
        'default_plan': 'pro',
        'default_period': 'month',
      });
    });

    test('paywall_plan_select becomes select_item with plan and interval', () {
      final events = ga4Events('paywall_plan_select', {'plan': 'pro_yearly', 'interval': 'year'});
      expect(events.map((e) => e.name), ['paywall_plan_select', 'select_item']);
      expect(events.last.params, {
        'item_list_id': 'paywall',
        'item_list_name': 'Casama plans',
        'plan': 'pro_yearly',
        'interval': 'year',
      });
    });

    test('an event without a twin goes alone', () {
      expect(ga4Events('paywall_dismiss', {'source': 'limit'}).map((e) => e.name), ['paywall_dismiss']);
    });
  });

  group('Ga4RelaySink (D-399)', () {
    test('batches cleaned events, screens as screen_view, and sends at most 25 per call', () async {
      final sent = <List<String>>[];
      final sink = Ga4RelaySink(platform: 'windows', every: const Duration(hours: 1))
        ..send = (platform, events) async {
          expect(platform, 'windows');
          sent.add([for (final e in events) e.name]);
        };
      await sink.setEnabled(true);
      await sink.capture('paywall_dismiss', {'source': 'limit', 'ok': true});
      await sink.screen('/chat/:id');
      expect(sink.queued, 2);
      await sink.flush();
      expect(sent, [
        ['paywall_dismiss', 'screen_view'],
      ]);
      for (var i = 0; i < 19; i++) {
        await sink.capture('feature_used', {'feature': 'search'});
      }
      await sink.capture('feature_used', {'feature': 'search'}); // the 20th flushes
      expect(sent.last.length, 20);
    });

    test('off: nothing queues, and turning off drops the queue', () async {
      var calls = 0;
      final sink = Ga4RelaySink(platform: 'linux', every: const Duration(hours: 1))..send = (_, _) async => calls++;
      await sink.capture('paywall_dismiss', null);
      expect(sink.queued, 0);
      await sink.setEnabled(true);
      await sink.capture('paywall_dismiss', null);
      await sink.setEnabled(false);
      await sink.flush();
      expect(calls, 0);
    });

    test('a failed send drops its batch', () async {
      final sink = Ga4RelaySink(platform: 'linux', every: const Duration(hours: 1))
        ..send = (_, _) async => throw Exception('401');
      await sink.setEnabled(true);
      await sink.capture('paywall_dismiss', null);
      await sink.flush();
      expect(sink.queued, 0);
    });

    test('tags queued events with traffic_type=internal while internal, and clears on reset', () async {
      final sent = <List<({String name, Map<String, Object> properties})>>[];
      final sink = Ga4RelaySink(platform: 'windows', every: const Duration(hours: 1))
        ..send = (_, events) async => sent.add(events);
      await sink.setEnabled(true);
      await sink.identify('u1', set: {'is_internal': true});
      await sink.capture('paywall_dismiss', {'source': 'limit'});
      await sink.setInternal(false);
      await sink.capture('feature_used', {'feature': 'search'});
      await sink.setInternal(true);
      await sink.screen('/inbox');
      await sink.reset(); // flushes screen_view with traffic_type=internal, then clears
      await sink.capture('paywall_dismiss', {'source': 'after_reset'});
      await sink.flush();

      expect(sent.length, 2);
      expect(sent[0].map((e) => e.name), ['paywall_dismiss', 'feature_used', 'screen_view']);
      expect(sent[0][0].properties['traffic_type'], 'internal');
      expect(sent[0][1].properties.containsKey('traffic_type'), isFalse);
      expect(sent[0][2].properties['traffic_type'], 'internal');
      expect(sent[1][0].properties.containsKey('traffic_type'), isFalse);
    });
  });

  group('internal account params', () {
    test('ga4Params reserves traffic_type=internal within the 25-param cap', () {
      final props = {
        'traffic_type': 'external',
        for (var i = 0; i < 30; i++) 'p$i': i,
      };
      final p = ga4Params(props, internal: true);
      expect(p.length, 25);
      expect(p['traffic_type'], 'internal');
    });

    test('ga4Events sets traffic_type=internal on main event and twin', () {
      final events = ga4Events(
        'paywall_plan_select',
        {'plan': 'pro_yearly', 'interval': 'year'},
        internal: true,
      );
      expect(events, hasLength(2));
      expect(events[0].params['traffic_type'], 'internal');
      expect(events[1].params['traffic_type'], 'internal');
    });
  });
}
