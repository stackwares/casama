import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthRetryableFetchException, AuthUnknownException;

/// The crash reporters an app can run. Exactly one runs at a time (D-417): two native crash
/// handlers (Sentry and Crashlytics) fight over signals on iOS and Android, and two dashboards
/// for the same crash confuse triage.
enum CrashReporterKind { sentry, crashlytics, posthog, none }

/// Picks the one crash reporter for this launch, before any of them starts (D-417).
///
/// 1. The server owner's choice from the remote app settings (`crash_reporter`), this platform's
///    key over `default`, read from the copy saved on the device at the last fetch. A change
///    fetched during a session takes effect on the next launch: reporters are never swapped
///    while the app runs.
/// 2. Otherwise, or when that reporter isn't in this build or on this platform, the build's own
///    `ERROR_REPORTING` (`auto`: Sentry with a DSN, else PostHog with a key, else none).
/// 3. Otherwise none.
///
/// The "Share usage data and crash reports" switch still turns the chosen one off.
class CrashReporters {
  const CrashReporters._();

  /// What this launch runs. [CrashReporterKind.none] until `Telemetry.run` picks one.
  static CrashReporterKind active = CrashReporterKind.none;

  /// Where the shared_preferences copy of the remote settings lives (remote_config.dart).
  static const savedConfigKey = 'remoteConfig.saved';

  /// What this launch runs, for the web page's own error reporter (web/errors.js) at the next
  /// page load: it stays quiet unless this is `sentry`.
  static const activeKey = 'casama.crash_reporter';

  static CrashReporterKind? parse(Object? v) => switch (v) {
    'sentry' => CrashReporterKind.sentry,
    'crashlytics' => CrashReporterKind.crashlytics,
    'posthog' => CrashReporterKind.posthog,
    'none' => CrashReporterKind.none,
    _ => null,
  };

  /// The owner's choice for [platform] in a remote settings object (as JSON), or null. Read from
  /// the raw JSON, not the generated model, so an unknown value never breaks anything.
  static CrashReporterKind? remoteChoice(Object? config, String platform) {
    if (config is! Map) return null;
    final choice = config['crash_reporter'];
    if (choice is! Map) return null;
    return parse(choice[platform]) ?? parse(choice['default']);
  }

  /// The build's own choice from `ERROR_REPORTING`.
  static CrashReporterKind buildDefault(
    String mode, {
    required Set<CrashReporterKind> available,
  }) => switch (mode) {
    'none' => CrashReporterKind.none,
    'sentry' => CrashReporterKind.sentry,
    'posthog' => CrashReporterKind.posthog,
    'crashlytics' => CrashReporterKind.crashlytics,
    _ =>
      available.contains(CrashReporterKind.sentry)
          ? CrashReporterKind.sentry
          : available.contains(CrashReporterKind.posthog)
          ? CrashReporterKind.posthog
          : CrashReporterKind.none,
  };

  /// The rule in the class comment. [available] are the reporters this build can run here.
  static CrashReporterKind choose({
    CrashReporterKind? remote,
    required String buildMode,
    required Set<CrashReporterKind> available,
  }) {
    if (remote == CrashReporterKind.none) return remote!;
    if (remote != null && available.contains(remote)) return remote;
    final build = buildDefault(buildMode, available: available);
    return available.contains(build) ? build : CrashReporterKind.none;
  }

  /// The owner's choice for [platform] from the settings saved on this device, or null.
  static Future<CrashReporterKind?> savedRemoteChoice(String platform) async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(
        savedConfigKey,
      );
      return raw == null ? null : remoteChoice(jsonDecode(raw), platform);
    } catch (_) {
      return null;
    }
  }

  /// Keeps [active] on the device for web/errors.js (see [activeKey]).
  static Future<void> remember() async {
    try {
      await (await SharedPreferences.getInstance()).setString(
        activeKey,
        active.name,
      );
    } catch (_) {}
  }
}

/// Errors no crash reporter should get: Supabase's session refresh failing because the device is
/// offline or the network dropped (`AuthRetryableFetchException`, or an unknown auth error whose
/// cause is a network one). Every offline person throws these from the background refresh timer,
/// and Supabase retries by itself. Other auth errors (a refused token, a bad grant) still report.
bool isCrashNoise(Object error) =>
    error is AuthRetryableFetchException ||
    (error is AuthUnknownException && _isNetworkError(error.originalError));

bool _isNetworkError(Object? e) =>
    e is http.ClientException || e is TimeoutException || e is AuthRetryableFetchException;

/// The exception type names [isCrashNoise] drops, for reporters that only see an event's text
/// (PostHog's `$exception_list` and Sentry's exception list carry the Dart type's name).
const crashNoiseTypes = {'AuthRetryableFetchException'};

/// Whether a PostHog `$exception` event's properties describe [crashNoiseTypes] only.
bool isCrashNoiseEvent(Map<String, Object?>? properties) {
  if (properties == null) return false;
  if (crashNoiseTypes.contains(properties[r'$exception_type'])) return true;
  final list = properties[r'$exception_list'];
  if (list is! List || list.isEmpty) return false;
  final first = list.first;
  return first is Map && crashNoiseTypes.contains(first['type']);
}
