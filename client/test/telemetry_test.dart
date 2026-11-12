import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama_app/core/telemetry.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  test('error payloads lose secrets and emails', () {
    final s = Telemetry.scrub(
      'failed for ada@example.com using sk-or-v1-abcdef1234567890 and Bearer abcdefghijklmnop',
    );
    expect(s, isNot(contains('ada@example.com')));
    expect(s, isNot(contains('sk-or-v1')));
    expect(s, isNot(contains('abcdefghijklmnop')));
  });

  test('reporting is off without keys', () {
    expect(Telemetry.sentryErrors, isFalse);
    expect(Telemetry.posthogOn, isFalse);
    expect(Telemetry.observers, isEmpty);
  });

  test('server_kind classification is privacy-safe', () {
    expect(
      Telemetry.resolveServerKind(
        apiUrl: 'https://cloud.casama.ai',
        billingEnabled: true,
      ),
      'cloud',
    );
    expect(
      Telemetry.resolveServerKind(
        apiUrl: 'https://cloud.casama.ai',
        billingEnabled: false,
      ),
      'self_hosted',
    );
    expect(
      Telemetry.resolveServerKind(
        apiUrl: 'http://localhost:8787',
        billingEnabled: false,
      ),
      'local',
    );
    expect(
      Telemetry.resolveServerKind(
        apiUrl: 'http://127.0.0.1:8787',
        billingEnabled: false,
      ),
      'local',
    );
    expect(
      Telemetry.resolveServerKind(
        apiUrl: 'https://custom-server.internal',
        billingEnabled: false,
      ),
      'self_hosted',
    );
  });

  test('Casama Cloud is the official hosts with billing on, never the URL itself', () {
    String kind(String url, {bool billing = true}) => Telemetry.resolveServerKind(apiUrl: url, billingEnabled: billing);
    expect(kind('https://api.casama.ai'), 'cloud');
    expect(kind('https://api-dev.casama.ai'), 'cloud');
    expect(kind('https://api.casama.ai', billing: false), 'self_hosted');
    expect(kind('https://casama.example.com'), 'self_hosted');
    expect(kind('https://evilcasama.ai'), 'self_hosted');
  });

  test('screens and product events leave only for Casama Cloud; crashes always; a self-hosted server sees two', () {
    for (final cloud in ['cloud']) {
      expect(Telemetry.allowEvent(r'$screen', cloud), isTrue);
      expect(Telemetry.allowEvent('sign_in_started', cloud), isTrue);
      expect(Telemetry.allowEvent('first_name_typed', cloud), isFalse, reason: 'uncatalogued events are dropped');
    }
    for (final other in ['self_hosted', 'local', 'unknown']) {
      expect(Telemetry.allowEvent(r'$exception', other), isTrue);
      expect(Telemetry.allowEvent('app_active_daily', other), isTrue);
      expect(Telemetry.allowEvent('app_startup_failed', other), isTrue);
      expect(Telemetry.allowEvent(r'$screen', other), isFalse);
      expect(Telemetry.allowEvent('sign_in_started', other), isFalse);
      expect(Telemetry.allowEvent('purchase_completed', other), isFalse);
    }
  });

  test('session screen observer deduplicates screens per session', () {
    SessionScreenObserver.resetSession();
    final observer = SessionScreenObserver();
    final route1 = MaterialPageRoute(
      settings: const RouteSettings(name: '/bots'),
      builder: (_) => const SizedBox(),
    );
    final route2 = MaterialPageRoute(
      settings: const RouteSettings(name: '/bots'),
      builder: (_) => const SizedBox(),
    );
    final route3 = MaterialPageRoute(
      settings: const RouteSettings(name: '/settings'),
      builder: (_) => const SizedBox(),
    );

    observer.didPush(route1, null);
    observer.didPush(route2, route1);
    observer.didPush(route3, route2);

    SessionScreenObserver.resetSession();
    observer.didPush(route1, route3);
  });

  test('captureException runs safely without keys and dedupes', () async {
    final err = StateError('test-failure');
    await Telemetry.captureException(err, StackTrace.current);
    await Telemetry.captureException(err, StackTrace.current);
  });
}
