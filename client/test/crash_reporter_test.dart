import 'dart:convert';

import 'package:casama/core/analytics.dart';
import 'package:casama_sdk/casama_sdk.dart' show RemoteAppConfig;
import 'package:casama/core/crash_reporter.dart';
import 'package:casama/core/crashlytics.dart';
import 'package:casama/core/telemetry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeSink implements CrashlyticsSink {
  final calls = <String>[];

  @override
  Future<void> setCollectionEnabled(bool enabled) async =>
      calls.add('collect:$enabled');

  @override
  Future<void> deleteUnsentReports() async => calls.add('deleteUnsent');

  @override
  Future<void> setKey(String key, String value) async => calls.add('key:$key');

  @override
  Future<void> recordError(
    Object error,
    StackTrace stack, {
    String? reason,
  }) async => calls.add('record');
}

const _all = {
  CrashReporterKind.sentry,
  CrashReporterKind.crashlytics,
  CrashReporterKind.posthog,
};

void main() {
  setUp(() {
    CrashReporters.active = CrashReporterKind.none;
    CrashlyticsReporter.resetForTest();
  });
  tearDown(() => CrashReporters.active = CrashReporterKind.none);

  group('the remote choice (D-417)', () {
    test("this platform's key wins over default", () {
      final config = {
        'crash_reporter': {'default': 'sentry', 'ios': 'crashlytics'},
      };
      expect(
        CrashReporters.remoteChoice(config, 'ios'),
        CrashReporterKind.crashlytics,
      );
      expect(
        CrashReporters.remoteChoice(config, 'android'),
        CrashReporterKind.sentry,
      );
    });

    test('nothing, or a value this app does not know, is no choice', () {
      expect(CrashReporters.remoteChoice(null, 'ios'), isNull);
      expect(CrashReporters.remoteChoice({'flags': {}}, 'ios'), isNull);
      expect(
        CrashReporters.remoteChoice({'crash_reporter': 'sentry'}, 'ios'),
        isNull,
      );
      expect(
        CrashReporters.remoteChoice({
          'crash_reporter': {'ios': 'bugsnag'},
        }, 'ios'),
        isNull,
      );
      // An unknown platform value falls through to the default.
      expect(
        CrashReporters.remoteChoice({
          'crash_reporter': {'ios': 'bugsnag', 'default': 'posthog'},
        }, 'ios'),
        CrashReporterKind.posthog,
      );
    });

    test('read from the settings saved on the device', () async {
      SharedPreferences.setMockInitialValues({
        CrashReporters.savedConfigKey: jsonEncode({
          'min_versions': {},
          'crash_reporter': {'default': 'posthog', 'web': 'none'},
        }),
      });
      expect(
        await CrashReporters.savedRemoteChoice('macos'),
        CrashReporterKind.posthog,
      );
      expect(
        await CrashReporters.savedRemoteChoice('web'),
        CrashReporterKind.none,
      );
      SharedPreferences.setMockInitialValues({
        CrashReporters.savedConfigKey: 'not json',
      });
      expect(await CrashReporters.savedRemoteChoice('ios'), isNull);
    });
  });

  test(
    'the admin editor round-trips the setting through the generated model',
    () {
      final json = {
        'min_versions': <String, dynamic>{},
        'update_urls': <String, dynamic>{},
        'maintenance': null,
        'announcements': <dynamic>[],
        'flags': <String, dynamic>{},
        'crash_reporter': {'default': 'sentry', 'android': 'crashlytics'},
      };
      final config = RemoteAppConfig.fromJson(json);
      final back =
          jsonDecode(jsonEncode(config.toJson())) as Map<String, dynamic>;
      expect(back['crash_reporter'], {
        'default': 'sentry',
        'android': 'crashlytics',
      });
      // A reporter this app doesn't know yet still parses (strings, not a strict enum).
      expect(
        () => RemoteAppConfig.fromJson({
          ...json,
          'crash_reporter': {'default': 'bugsnag'},
        }),
        returnsNormally,
      );
    },
  );

  group('choosing the one reporter', () {
    CrashReporterKind choose(
      CrashReporterKind? remote, {
      String mode = 'auto',
      Set<CrashReporterKind> available = _all,
    }) => CrashReporters.choose(
      remote: remote,
      buildMode: mode,
      available: available,
    );

    test(
      'the remote default and a platform override are taken when available',
      () {
        expect(choose(CrashReporterKind.sentry), CrashReporterKind.sentry);
        expect(
          choose(CrashReporterKind.crashlytics),
          CrashReporterKind.crashlytics,
        );
        expect(choose(CrashReporterKind.posthog), CrashReporterKind.posthog);
        expect(choose(CrashReporterKind.none), CrashReporterKind.none);
      },
    );

    test('a remote choice this build lacks falls back to the build default, then none', () {
      // Crashlytics on Windows (not available) → the build's Sentry.
      expect(
        choose(
          CrashReporterKind.crashlytics,
          available: {CrashReporterKind.sentry, CrashReporterKind.posthog},
        ),
        CrashReporterKind.sentry,
      );
      // Build says sentry but has no DSN, remote asks for Crashlytics it lacks → none.
      expect(
        choose(
          CrashReporterKind.crashlytics,
          mode: 'sentry',
          available: {CrashReporterKind.posthog},
        ),
        CrashReporterKind.none,
      );
      // A self-hosted build with nothing configured.
      expect(
        choose(CrashReporterKind.sentry, available: {}),
        CrashReporterKind.none,
      );
    });

    test('auto: Sentry with a DSN, else PostHog with a key, else none', () {
      expect(choose(null), CrashReporterKind.sentry);
      expect(
        choose(
          null,
          available: {CrashReporterKind.posthog, CrashReporterKind.crashlytics},
        ),
        CrashReporterKind.posthog,
      );
      expect(
        choose(null, available: {CrashReporterKind.crashlytics}),
        CrashReporterKind.none,
      );
      expect(choose(null, mode: 'unknown'), CrashReporterKind.sentry);
    });

    test('an explicit build mode is followed when nothing remote is set', () {
      expect(choose(null, mode: 'posthog'), CrashReporterKind.posthog);
      expect(choose(null, mode: 'crashlytics'), CrashReporterKind.crashlytics);
      expect(choose(null, mode: 'none'), CrashReporterKind.none);
      expect(
        choose(null, mode: 'posthog', available: {CrashReporterKind.sentry}),
        CrashReporterKind.none,
      );
    });

    test(
      'the switch does not change the choice; it turns the chosen one off',
      () async {
        SharedPreferences.setMockInitialValues({});
        CrashReporters.active = CrashReporterKind.sentry;
        await Analytics.setConsentEnabled(false);
        expect(CrashReporters.active, CrashReporterKind.sentry);
        expect(
          Telemetry.crashConsent,
          isFalse,
        ); // Sentry's beforeSend drops everything
        await Analytics.setConsentEnabled(true);
        expect(Telemetry.crashConsent, isTrue);
      },
    );
  });

  group('only the chosen reporter starts', () {
    test('each choice turns on exactly one of them', () {
      CrashReporters.active = CrashReporterKind.sentry;
      expect(Telemetry.sentryErrors, isTrue);
      expect(Telemetry.posthogErrors, isFalse);
      expect(CrashlyticsReporter.on, isFalse);

      CrashReporters.active = CrashReporterKind.posthog;
      expect(Telemetry.sentryErrors, isFalse);
      expect(Telemetry.posthogErrors, isTrue);
      expect(CrashlyticsReporter.on, isFalse);

      CrashReporters.active = CrashReporterKind.none;
      expect(Telemetry.sentryErrors, isFalse);
      expect(Telemetry.posthogErrors, isFalse);
      expect(CrashlyticsReporter.on, isFalse);
    });

    test('Crashlytics runs only when chosen and in the build (a test build has no flag)', () {
      CrashReporters.active = CrashReporterKind.crashlytics;
      expect(CrashlyticsReporter.available, isFalse);
      expect(CrashlyticsReporter.on, isFalse);
      expect(Telemetry.sentryErrors, isFalse);
      expect(Telemetry.posthogErrors, isFalse);
    });

    test(
      'a build with no reporter picks none and keeps that for the web page',
      () async {
        SharedPreferences.setMockInitialValues({
          CrashReporters.savedConfigKey: jsonEncode({
            'crash_reporter': {'default': 'sentry'},
          }),
        });
        expect(Telemetry.availableCrashReporters, isEmpty);
        expect(await Telemetry.chooseCrashReporter(), CrashReporterKind.none);
        await pumpEventQueue();
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString(CrashReporters.activeKey), 'none');
      },
    );

    test(
      'an unchosen Crashlytics keeps collection off and drops what it kept',
      () async {
        final sink = _FakeSink();
        await CrashlyticsReporter.stopWith(sink);
        expect(sink.calls, ['collect:false', 'deleteUnsent']);
        expect(CrashlyticsReporter.collecting, isFalse);
        await CrashlyticsReporter.record(
          StateError('x'),
          null,
          scrub: Telemetry.scrub,
        );
        expect(sink.calls, ['collect:false', 'deleteUnsent']);
      },
    );
  });
}
