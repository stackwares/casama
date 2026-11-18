import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

import 'analytics_events.g.dart';
import 'push.dart' show PushConfig;
import 'telemetry.dart';

/// Where product analytics go (D-397): PostHog, Google Analytics 4, or both. Every catalog event goes to
/// each provider that is on; consent, the Cloud-only rule and the catalog apply to all of them.
///
///   --dart-define=ANALYTICS_PROVIDERS=posthog,ga4   which providers may run (empty: every configured one)
///   --dart-define=GA4_ENABLED=true                   GA4 when ANALYTICS_PROVIDERS is empty
///   --dart-define=FIREBASE_WEB_MEASUREMENT_ID=G-...  the web app's GA4 stream (web only)
///
/// GA4 uses the build's Firebase project (the same settings as push, see [PushConfig]).
abstract class AnalyticsSink {
  String get name;
  Future<void> identify(String userId, {Map<String, Object>? setOnce});
  Future<void> reset();
  Future<void> capture(String event, Map<String, Object>? properties);
  Future<void> screen(String name);
  Future<void> setEnabled(bool enabled);
}

/// The providers named in [raw] (`ANALYTICS_PROVIDERS`), lower-cased; null when it names none, which
/// means "every configured provider".
Set<String>? parseAnalyticsProviders(String raw) {
  final names = {
    for (final p in raw.split(RegExp(r'[,\s]+')))
      if (p.trim().isNotEmpty) p.trim().toLowerCase(),
  };
  return names.isEmpty ? null : names;
}

/// Whether provider [name] runs: it must be configured, and either listed in `ANALYTICS_PROVIDERS` or
/// (with nothing listed) on by default. `none` in the list turns every provider off.
bool analyticsProviderOn(
  String name, {
  required String raw,
  required bool configured,
  bool onByDefault = true,
}) {
  if (!configured) return false;
  final listed = parseAnalyticsProviders(raw);
  if (listed == null) return onByDefault;
  if (listed.contains('none')) return false;
  return listed.contains(name);
}

/// firebase_analytics runs on Android, iOS, macOS and the web; never Windows or Linux.
bool ga4PlatformSupported({
  required bool isWeb,
  required TargetPlatform platform,
}) =>
    isWeb ||
    platform == TargetPlatform.android ||
    platform == TargetPlatform.iOS ||
    platform == TargetPlatform.macOS;

/// Catalog properties as GA4 takes them: strings (scrubbed, cut to 100) and numbers. Booleans become
/// 1/0; nulls, lists and maps are dropped. GA4 keeps at most 25 parameters per event.
Map<String, Object> ga4Params(Map<String, Object?>? properties) {
  final out = <String, Object>{};
  for (final e in (properties ?? const <String, Object?>{}).entries) {
    if (out.length >= 25) break;
    final key = e.key;
    if (key.isEmpty || key.length > 40 || key.startsWith(r'$')) continue;
    if (key.startsWith('firebase_') ||
        key.startsWith('google_') ||
        key.startsWith('ga_')) {
      continue;
    }
    final v = e.value;
    switch (v) {
      case bool b:
        out[key] = b ? 1 : 0;
      case num n:
        out[key] = n;
      case String s:
        out[key] = Telemetry.scrub(s, 100).characters100;
      default:
        break;
    }
  }
  return out;
}

/// The GA4 events for a catalog event: the event, then its recommended twin when the catalog names one
/// (D-398: `sign_up`, `login`, `tutorial_complete`, `begin_checkout`, …), so GA4's built-in reports fill in.
List<({String name, Map<String, Object> params})> ga4Events(String event, Map<String, Object?>? properties) {
  final out = [(name: event, params: ga4Params(properties))];
  final twin = analyticsGa4Twins[event];
  if (twin != null) {
    out.add((
      name: twin.name,
      params: ga4Params({
        ...twin.set,
        for (final p in twin.params)
          if (properties?[p] != null) p: properties![p],
      }),
    ));
  }
  return out;
}

/// Windows and Linux: GA4 through the server (D-399). Events queue here and go to [send] in batches of
/// up to 25 (the endpoint's limit), every 30 seconds or at 20 queued, and before a reset. A failed send
/// (offline, signed out: the endpoint needs a session) drops its batch rather than growing a backlog.
class Ga4RelaySink implements AnalyticsSink {
  Ga4RelaySink({required this.platform, this.every = const Duration(seconds: 30)});

  final String platform;

  /// How long an event may wait before its batch goes.
  final Duration every;

  /// Set by the app once the backend exists ([Analytics.relaySend]).
  Future<void> Function(String platform, List<({String name, Map<String, Object> properties})> events)? send;

  final _queue = <({String name, Map<String, Object> properties})>[];
  Timer? _timer;
  bool _enabled = false;

  @override
  String get name => 'ga4_relay';

  @visibleForTesting
  int get queued => _queue.length;

  @override
  Future<void> setEnabled(bool enabled) async {
    _enabled = enabled;
    if (!enabled) {
      _queue.clear();
      _timer?.cancel();
      _timer = null;
    }
  }

  // The server knows the account from the session; nothing to identify here.
  @override
  Future<void> identify(String userId, {Map<String, Object>? setOnce}) async {}

  @override
  Future<void> reset() => flush();

  @override
  Future<void> capture(String event, Map<String, Object>? properties) async {
    if (!_enabled) return;
    _queue.add((name: event, properties: ga4Params(properties)));
    if (_queue.length >= 20) {
      await flush();
    } else {
      _timer ??= Timer(every, () => unawaited(flush()));
    }
  }

  @override
  Future<void> screen(String name) => capture('screen_view', {'screen': name});

  Future<void> flush() async {
    _timer?.cancel();
    _timer = null;
    final sender = send;
    while (_queue.isNotEmpty) {
      final batch = _queue.take(25).toList();
      _queue.removeRange(0, batch.length);
      if (sender == null) continue;
      try {
        await sender(platform, batch);
      } catch (_) {
        // Dropped: analytics is never worth a retry queue.
      }
    }
  }
}

extension on String {
  /// [Telemetry.scrub] adds an ellipsis past the limit; GA4 counts it, so cut again to 100.
  String get characters100 => length > 100 ? substring(0, 100) : this;
}

/// Today's PostHog calls, unchanged.
class PosthogSink implements AnalyticsSink {
  @override
  String get name => 'posthog';

  @override
  Future<void> identify(String userId, {Map<String, Object>? setOnce}) async {
    await Telemetry.posthogReady;
    await Posthog().identify(userId: userId, userPropertiesSetOnce: setOnce);
  }

  @override
  Future<void> reset() async {
    await Telemetry.posthogReady;
    await Posthog().reset();
  }

  @override
  Future<void> capture(String event, Map<String, Object>? properties) async {
    await Telemetry.posthogReady;
    await Posthog().capture(eventName: event, properties: properties);
  }

  @override
  Future<void> screen(String name) async {
    await Telemetry.posthogReady;
    await Posthog().screen(screenName: name);
  }

  @override
  Future<void> setEnabled(bool enabled) async {
    await Telemetry.posthogReady;
    if (enabled) {
      await Posthog().capture(eventName: 'enable_analytics_sharing');
      await Posthog().optIn();
    } else {
      await Posthog().capture(eventName: 'disable_analytics_sharing');
      await Posthog().optOut();
    }
  }
}

/// Google Analytics 4 through firebase_analytics. Collection is off in the native defaults (Info.plist,
/// AndroidManifest) and only turned on here for Casama Cloud with consent. On the web nothing loads
/// (gtag sends a page view as it starts) until it is turned on.
class Ga4Sink implements AnalyticsSink {
  @override
  String get name => 'ga4';

  Future<FirebaseAnalytics>? _instance;
  bool _enabled = false;

  Future<FirebaseAnalytics> _analytics() => _instance ??= () async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: PushConfig.options);
    }
    return FirebaseAnalytics.instance;
  }();

  /// Whether calls may go out right now: turned on, and (on the web) loaded.
  bool get _live => _enabled && _instance != null;

  @override
  Future<void> setEnabled(bool enabled) async {
    _enabled = enabled;
    // The web loads gtag only to turn it on; a native app always syncs, since the choice persists
    // between launches and a later self-hosted connection must turn it back off.
    if (kIsWeb && !enabled && _instance == null) return;
    final a = await _analytics();
    await a.setAnalyticsCollectionEnabled(enabled);
    if (enabled) {
      await a.setUserProperty(
        name: 'distribution',
        value: Telemetry.distributionName,
      );
      await a.setUserProperty(name: 'environment', value: Telemetry.posthogEnv);
    }
  }

  @override
  Future<void> identify(String userId, {Map<String, Object>? setOnce}) async {
    if (!_live) return;
    final a = await _analytics();
    await a.setUserId(id: userId);
    final platform = setOnce?['signup_platform'];
    if (platform is String) {
      await a.setUserProperty(name: 'signup_platform', value: platform);
    }
  }

  @override
  Future<void> reset() async {
    if (_instance == null) return;
    final a = await _analytics();
    await a.setUserId(id: null);
    if (!kIsWeb) await a.resetAnalyticsData();
  }

  @override
  Future<void> capture(String event, Map<String, Object>? properties) async {
    if (!_live) return;
    final a = await _analytics();
    for (final e in ga4Events(event, properties)) {
      await a.logEvent(name: e.name, parameters: e.params);
    }
  }

  @override
  Future<void> screen(String name) async {
    if (!_live) return;
    await (await _analytics()).logScreenView(
      screenName: Telemetry.scrub(name, 100).characters100,
    );
  }
}
