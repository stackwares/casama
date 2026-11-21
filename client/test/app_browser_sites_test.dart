import 'dart:convert';
import 'dart:io';

import 'package:casama/features/app_browser/app_browser_sites.dart';
import 'package:flutter_test/flutter_test.dart';

/// The phone browser's site gate (PROTOCOL.md §2) against the cases the server's reference
/// (`appSiteDecision`, packages/domain/src/app-browser-sites.ts) writes.
void main() {
  final guard = AppBrowserGuard.fromJson(
    jsonDecode(File('assets/app_browser/guard.json').readAsStringSync())
        as Map<String, dynamic>,
  );
  final fixture = jsonDecode(
    File('test/fixtures/app_browser_sites.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final policies = {
    for (final e in (fixture['policies'] as Map<String, dynamic>).entries)
      e.key: AppSitePolicy.fromJson(e.value as Map<String, dynamic>),
  };
  final cases = (fixture['cases'] as List).cast<Map<String, dynamic>>();

  test('the fixture has cases', () {
    expect(cases.length, greaterThan(50));
  });

  for (final c in cases) {
    final once = [for (final o in c['once'] as List) '$o'];
    test('${c['policy']} once=$once ${c['url']}', () {
      final got = appSiteDecision(
        c['url'] as String,
        policies[c['policy']]!,
        guard,
        once: once,
      ).toJson();
      expect(got, c['expect']);
    });
  }

  test('the person browsing by hand gets only the first two steps', () {
    expect(personSiteDecision('https://www.paypal.com/', guard).toJson(), {
      'kind': 'allowed',
    });
    expect(personSiteDecision('https://app.casama.ai/', guard).toJson(), {
      'kind': 'refused',
      'host': 'app.casama.ai',
      'why': 'casama',
    });
    expect(personSiteDecision('file:///etc/passwd', guard).toJson(), {
      'kind': 'refused',
      'host': '',
      'why': 'not_web',
    });
  });

  test('sites added by the server only add to the kinds', () {
    final d = appSiteDecision(
      'https://my.newbank.example/',
      const AppSitePolicy(),
      guard,
      extra: const {
        'banking': ['newbank.example'],
      },
    );
    expect(d.toJson(), {
      'kind': 'refused',
      'host': 'my.newbank.example',
      'why': 'banking',
    });
  });

  test('site entries are cleaned like the server cleans them', () {
    expect(
      cleanSitePattern('https://www.Shop.example:8443/basket?x=1'),
      'shop.example',
    );
    expect(cleanSitePattern('*.docs.example'), '*.docs.example');
    expect(cleanSitePattern('not a site'), isNull);
    expect(cleanSitePattern('localhost'), 'localhost');
  });
}
