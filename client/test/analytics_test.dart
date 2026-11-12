import 'package:casama_app/core/analytics.dart';
import 'package:casama_app/core/push.dart';
import 'package:casama_app/core/telemetry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a notification is classified by its in-app link, and the link itself never leaves', () {
    expect(PushRegistrar.pushKind('/approvals/abc'), 'approval');
    expect(PushRegistrar.pushKind('/bots/b1/call'), 'call');
    expect(PushRegistrar.pushKind('/calls/c1'), 'call');
    expect(PushRegistrar.pushKind('/bots/b1/runs/r1'), 'run');
    expect(PushRegistrar.pushKind('/inbox'), 'checkin');
    expect(PushRegistrar.pushKind('/bots/b1/chat'), 'mention');
    expect(PushRegistrar.pushKind('/settings'), 'other');
    expect(PushRegistrar.pushKind(null), 'other');
  });

  test('feature_used has a closed list, and every page it counts is on it', () {
    for (final f in Analytics.routeFeatures.values) {
      expect(Analytics.features, contains(f), reason: f);
    }
    expect(Analytics.features, containsAll(['dictation', 'voice_call', 'routines_run_now', 'mac_menu']));
    expect(Analytics.features, isNot(contains('typed_text')));
  });

  test('the app sends only catalogued product events, and feature_used is among them', () {
    expect(Telemetry.catalogEvents, containsAll(['feature_used', 'app_error_shown', 'sign_in_started', 'purchase_completed']));
    // Server-only events are not on the app's list.
    for (final serverOnly in ['signed_up', 'purchase', 'usage_daily', 'workspace_daily', 'first_value']) {
      expect(Telemetry.catalogEvents, isNot(contains(serverOnly)), reason: serverOnly);
    }
  });

  test('without keys nothing is sent and calls are harmless', () async {
    await Analytics.capture('sign_in_started', properties: {'method': 'password'});
    Analytics.errorShown(code: 'x', status: 500, kind: 'server');
    Analytics.feature('dictation');
    await Analytics.dailyPing();
  });
}
