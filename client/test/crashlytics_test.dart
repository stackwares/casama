import 'package:casama/core/analytics.dart';
import 'package:casama/core/crashlytics.dart';
import 'package:casama/core/telemetry.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeSink implements CrashlyticsSink {
  final calls = <String>[];
  final errors = <String>[];
  final keys = <String, String>{};

  @override
  Future<void> setCollectionEnabled(bool enabled) async =>
      calls.add('collect:$enabled');

  @override
  Future<void> deleteUnsentReports() async => calls.add('deleteUnsent');

  @override
  Future<void> setKey(String key, String value) async => keys[key] = value;

  @override
  Future<void> recordError(
    Object error,
    StackTrace stack, {
    String? reason,
  }) async => errors.add(error.toString());
}

void main() {
  setUp(CrashlyticsReporter.resetForTest);

  group('which builds report to Crashlytics (D-416)', () {
    bool configured({
      bool flag = true,
      bool firebase = true,
      String mode = 'auto',
      bool isWeb = false,
      TargetPlatform platform = TargetPlatform.iOS,
    }) => CrashlyticsReporter.configured(
      flag: flag,
      firebase: firebase,
      mode: mode,
      isWeb: isWeb,
      platform: platform,
    );

    test('an official build with Firebase on iOS, Android or macOS', () {
      expect(configured(platform: TargetPlatform.iOS), isTrue);
      expect(configured(platform: TargetPlatform.android), isTrue);
      expect(configured(platform: TargetPlatform.macOS), isTrue);
      expect(configured(mode: 'sentry'), isTrue);
      expect(configured(mode: 'posthog'), isTrue);
    });

    test('never without the flag (self-hosted and unofficial builds), Firebase, or with reporting off', () {
      expect(configured(flag: false), isFalse);
      expect(configured(firebase: false), isFalse);
      expect(configured(mode: 'none'), isFalse);
    });

    test('never on Windows, Linux or the web', () {
      expect(configured(platform: TargetPlatform.windows), isFalse);
      expect(configured(platform: TargetPlatform.linux), isFalse);
      expect(configured(isWeb: true), isFalse);
      expect(
        configured(isWeb: true, platform: TargetPlatform.android),
        isFalse,
      );
    });

    test('a test build has no flag, so it stays off', () {
      expect(CrashlyticsReporter.on, isFalse);
    });
  });

  group('the switch', () {
    String scrub(String s) => Telemetry.scrub(s);

    test('opted out: collection off, waiting reports deleted, nothing recorded, no keys', () async {
      final sink = _FakeSink();
      await CrashlyticsReporter.startWith(
        sink,
        consent: false,
        keys: {'distribution': 'app_store'},
      );
      expect(sink.calls, ['collect:false', 'deleteUnsent']);
      await CrashlyticsReporter.record(
        StateError('boom'),
        StackTrace.current,
        scrub: scrub,
      );
      await CrashlyticsReporter.setKey('server_kind', 'cloud');
      expect(sink.errors, isEmpty);
      expect(sink.keys, isEmpty);
    });

    test('opted in: errors are recorded scrubbed, with keys', () async {
      final sink = _FakeSink();
      await CrashlyticsReporter.startWith(
        sink,
        consent: true,
        keys: {'distribution': 'google_play'},
      );
      expect(sink.calls, ['collect:true']);
      expect(sink.keys, {'distribution': 'google_play'});
      await CrashlyticsReporter.record(
        StateError('failed for someone@example.com with sk-abcdefghijklmnop'),
        StackTrace.current,
        scrub: scrub,
      );
      expect(sink.errors, hasLength(1));
      expect(sink.errors.single, startsWith('StateError: '));
      expect(sink.errors.single, isNot(contains('someone@example.com')));
      expect(sink.errors.single, isNot(contains('sk-abcdefghijklmnop')));
    });

    test('turning it off later stops reports and deletes the unsent ones; on again resumes', () async {
      final sink = _FakeSink();
      await CrashlyticsReporter.startWith(sink, consent: true);
      await CrashlyticsReporter.setEnabled(false);
      expect(sink.calls, ['collect:true', 'collect:false', 'deleteUnsent']);
      await CrashlyticsReporter.record(StateError('x'), null, scrub: scrub);
      expect(sink.errors, isEmpty);
      await CrashlyticsReporter.setEnabled(true);
      await CrashlyticsReporter.record(StateError('y'), null, scrub: scrub);
      expect(sink.errors, ['StateError: Bad state: y']);
    });

    test('the Settings switch reaches Crashlytics and Sentry', () async {
      SharedPreferences.setMockInitialValues({});
      final sink = _FakeSink();
      await CrashlyticsReporter.startWith(sink, consent: true);
      await Analytics.setConsentEnabled(false);
      expect(Telemetry.crashConsent, isFalse);
      expect(CrashlyticsReporter.collecting, isFalse);
      expect(sink.calls.last, 'deleteUnsent');
      await Analytics.setConsentEnabled(true);
      expect(Telemetry.crashConsent, isTrue);
      expect(CrashlyticsReporter.collecting, isTrue);
    });

    test('before setup nothing is recorded and calls are harmless', () async {
      await CrashlyticsReporter.setEnabled(true);
      await CrashlyticsReporter.record(StateError('x'), null, scrub: scrub);
      await CrashlyticsReporter.setKey('k', 'v');
      expect(CrashlyticsReporter.collecting, isFalse);
    });
  });
}
