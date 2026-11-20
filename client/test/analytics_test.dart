import 'package:casama/core/analytics.dart';
import 'package:casama/core/analytics_sinks.dart';
import 'package:casama/core/push.dart';
import 'package:casama/core/telemetry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _RecordingSink implements AnalyticsSink {
  @override
  String get name => 'recording';

  final calls = <String>[];

  @override
  Future<void> capture(String event, Map<String, Object>? properties) async =>
      calls.add('capture:$event');

  @override
  Future<void> identify(
    String userId, {
    Map<String, Object>? set,
    Map<String, Object>? setOnce,
  }) async =>
      calls.add('identify:$userId:${set?['is_internal']}');

  @override
  Future<void> reset() async => calls.add('reset');

  @override
  Future<void> screen(String name) async => calls.add('screen:$name');

  @override
  Future<void> setEnabled(bool enabled) async => calls.add('enabled:$enabled');

  @override
  Future<void> setInternal(bool internal) async => calls.add('internal:$internal');
}

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

  test('syncInternal persists cached is_internal and identify applies it on next launch', () async {
    SharedPreferences.setMockInitialValues({});
    final prevKind = Telemetry.serverKind;
    final sink = _RecordingSink();
    Telemetry.serverKind = 'cloud';
    Analytics.sinksOverrideForTest = [sink];
    try {
      await Analytics.identify('u-int');
      await Analytics.syncInternal('u-int', () async => true);
      expect(sink.calls, ['identify:u-int:null', 'internal:true']);

      // Next cold start (even while offline) identifies immediately with cached is_internal=true.
      sink.calls.clear();
      await Analytics.identify('u-int');
      await Analytics.syncInternal('u-int', () async => throw Exception('offline'));
      expect(sink.calls, ['identify:u-int:true']);

      // Later sync flips back to false when server says false.
      await Analytics.syncInternal('u-int', () async => false);
      expect(sink.calls, ['identify:u-int:true', 'internal:false']);
    } finally {
      Analytics.sinksOverrideForTest = null;
      Telemetry.serverKind = prevKind;
    }
  });
}
