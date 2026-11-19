import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import 'crash_reporter.dart';
import 'push.dart' show PushConfig;

/// Firebase Crashlytics, one of the crash reporters (D-416); it runs only when it's the one chosen
/// for this launch ([CrashReporters], D-417).
///
///   --dart-define=CRASHLYTICS_ENABLED=true   (client/config/telemetry.json, official builds only)
///
/// Runs only on iOS, Android and macOS (Crashlytics has no Windows, Linux or web SDK), only with the
/// build's Firebase project ([PushConfig]), never with `ERROR_REPORTING=none`, and only while the
/// "Share usage data and crash reports" switch is on. Collection is off in the native defaults
/// (Info.plist `FirebaseCrashlyticsCollectionEnabled`, the Android manifest's
/// `firebase_crashlytics_collection_enabled`), so a build without the flag never sends anything, and
/// turning the switch off also deletes reports still waiting on the device.
///
/// Native crashes are caught by the SDK itself. Uncaught Flutter and platform errors, and the errors
/// [Telemetry.captureException] reports, are recorded as non-fatal: the app keeps running after them,
/// so the crash-free numbers stay about real crashes. Messages are scrubbed like every other report,
/// and no account id is attached.
class CrashlyticsReporter {
  const CrashlyticsReporter._();

  static const flag = bool.fromEnvironment('CRASHLYTICS_ENABLED');

  /// `--dart-define=CRASHLYTICS_SELF_TEST=true` records one non-fatal at start, to check a build reaches
  /// the Firebase console (it shows up after the next launch). Never in a build that ships.
  static const selfTest = bool.fromEnvironment('CRASHLYTICS_SELF_TEST');

  /// Whether the Crashlytics plugin runs on this platform.
  static bool platformSupported({
    required bool isWeb,
    required TargetPlatform platform,
  }) =>
      !isWeb &&
      (platform == TargetPlatform.iOS ||
          platform == TargetPlatform.android ||
          platform == TargetPlatform.macOS);

  /// Whether this build reports to Crashlytics at all (before consent).
  static bool configured({
    required bool flag,
    required bool firebase,
    required String mode,
    required bool isWeb,
    required TargetPlatform platform,
  }) =>
      flag &&
      firebase &&
      mode != 'none' &&
      platformSupported(isWeb: isWeb, platform: platform);

  /// Whether this build can run Crashlytics here at all.
  static bool get available => configured(
    flag: flag,
    firebase: PushConfig.enabled,
    mode: const String.fromEnvironment('ERROR_REPORTING', defaultValue: 'auto'),
    isWeb: kIsWeb,
    platform: defaultTargetPlatform,
  );

  /// Whether Crashlytics runs this launch: it can, and it's the chosen reporter (D-417). Otherwise
  /// its collection stays off (the native default) and its error hooks aren't installed.
  static bool get on =>
      available && CrashReporters.active == CrashReporterKind.crashlytics;

  static CrashlyticsSink? _sink;
  static bool _collecting = false;

  /// Whether reports go out right now: set up, and the switch is on.
  static bool get collecting => _collecting && _sink != null;

  /// Sets Crashlytics up and applies the switch. Safe to call when [on] is false (does nothing).
  static Future<void> start({
    required bool consent,
    required Map<String, String> keys,
  }) async {
    if (!on) return;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(options: PushConfig.options)
            .timeout(const Duration(seconds: 5));
      }
      await startWith(FirebaseCrashlyticsSink(), consent: consent, keys: keys);
      if (selfTest) {
        await record(
          StateError('Crashlytics self-test (D-416)'),
          StackTrace.current,
          scrub: (s) => s,
        );
      }
    } catch (_) {
      // Crash reporting is never worth failing startup for.
    }
  }

  /// When this build has Crashlytics but another reporter was chosen (D-417): keeps collection off
  /// and drops what the native SDK kept on the device, so switching back later never sends old
  /// reports. The SDK itself still loads with Firebase; it just never sends.
  static Future<void> stopUnused() async {
    if (!available || on) return;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(options: PushConfig.options)
            .timeout(const Duration(seconds: 5));
      }
      await stopWith(FirebaseCrashlyticsSink());
    } catch (_) {}
  }

  /// [stopUnused] with a given sink (tests). Leaves no sink behind, so nothing records.
  @visibleForTesting
  static Future<void> stopWith(CrashlyticsSink sink) async {
    _sink = null;
    _collecting = false;
    try {
      await sink.setCollectionEnabled(false);
      await sink.deleteUnsentReports();
    } catch (_) {}
  }

  /// [start] with a given sink (tests).
  @visibleForTesting
  static Future<void> startWith(
    CrashlyticsSink sink, {
    required bool consent,
    Map<String, String> keys = const {},
  }) async {
    _sink = sink;
    await setEnabled(consent);
    if (consent) {
      for (final e in keys.entries) {
        await sink.setKey(e.key, e.value);
      }
    }
  }

  /// Follows the switch: on sends from now on, off stops and deletes reports not yet sent.
  static Future<void> setEnabled(bool enabled) async {
    _collecting = enabled;
    final sink = _sink;
    if (sink == null) return;
    try {
      await sink.setCollectionEnabled(enabled);
      if (!enabled) await sink.deleteUnsentReports();
    } catch (_) {}
  }

  /// A custom key on later reports (server kind, distribution); never anything personal.
  static Future<void> setKey(String key, String value) async {
    if (!collecting) return;
    try {
      await _sink!.setKey(key, value);
    } catch (_) {}
  }

  /// Records an error as non-fatal, its message scrubbed with [scrub].
  static Future<void> record(
    Object error,
    StackTrace? stack, {
    required String Function(String) scrub,
    String? reason,
  }) async {
    if (!collecting) return;
    try {
      await _sink!.recordError(
        ScrubbedError('${error.runtimeType}: ${scrub(error.toString())}'),
        stack ?? StackTrace.empty,
        reason: reason,
      );
    } catch (_) {}
  }

  /// Sends uncaught Flutter and platform errors here too, then hands them on to whatever handled
  /// them before (PostHog, Sentry, Flutter's own printing). Call after those are set up.
  static void installHandlers({required String Function(String) scrub}) {
    if (!on) return;
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      if (collecting) {
        unawaited(
          record(
            details.exception,
            details.stack,
            scrub: scrub,
            reason: details.context?.toDescription(),
          ),
        );
      }
      (previous ?? FlutterError.presentError)(details);
    };
    final dispatcher = PlatformDispatcher.instance;
    final previousPlatform = dispatcher.onError;
    dispatcher.onError = (error, stack) {
      if (collecting) {
        unawaited(record(error, stack, scrub: scrub, reason: 'uncaught'));
      }
      return previousPlatform?.call(error, stack) ?? false;
    };
  }

  @visibleForTesting
  static void resetForTest() {
    _sink = null;
    _collecting = false;
  }
}

/// An error whose text has been scrubbed; Crashlytics shows [toString] as the issue's message.
class ScrubbedError implements Exception {
  const ScrubbedError(this.text);
  final String text;
  @override
  String toString() => text;
}

/// The Crashlytics calls Casama makes, so tests can stand in for the plugin.
abstract class CrashlyticsSink {
  Future<void> setCollectionEnabled(bool enabled);
  Future<void> deleteUnsentReports();
  Future<void> setKey(String key, String value);
  Future<void> recordError(Object error, StackTrace stack, {String? reason});
}

class FirebaseCrashlyticsSink implements CrashlyticsSink {
  FirebaseCrashlytics get _c => FirebaseCrashlytics.instance;

  @override
  Future<void> setCollectionEnabled(bool enabled) =>
      _c.setCrashlyticsCollectionEnabled(enabled);

  @override
  Future<void> deleteUnsentReports() => _c.deleteUnsentReports();

  @override
  Future<void> setKey(String key, String value) => _c.setCustomKey(key, value);

  @override
  Future<void> recordError(Object error, StackTrace stack, {String? reason}) =>
      _c.recordError(
        error,
        stack,
        reason: reason,
        fatal: false,
        printDetails: false,
      );
}
