import 'dart:async';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:shared_preferences/shared_preferences.dart';
import 'analytics_events.g.dart';
import 'analytics_sinks.dart';
import 'crashlytics.dart';
import 'telemetry.dart';

/// Facade for product analytics (ANALYTICS-PLAN.md §4.2). Events fan out to every provider that is on,
/// PostHog and/or Google Analytics 4 (D-397, [AnalyticsSink]).
/// All methods are safe no-ops when no provider is on, consent is opted out,
/// or server_kind is not 'cloud'.
class Analytics {
  @visibleForTesting
  static void Function(String event, Map<String, Object>? properties)? onCaptureForTest;

  @visibleForTesting
  static List<AnalyticsSink>? sinksOverrideForTest;

  static final _posthog = PosthogSink();
  static final _ga4 = Ga4Sink();
  static final _ga4Relay = Ga4RelaySink(platform: Telemetry.platformName);

  /// Where the Windows and Linux GA4 relay sends (the backend's relayAnalytics), set once at startup.
  static set relaySend(
    Future<void> Function(String platform, List<({String name, Map<String, Object> properties})> events)? send,
  ) =>
      _ga4Relay.send = send;

  /// The providers that are on in this build, in order.
  static List<AnalyticsSink> get _sinks =>
      sinksOverrideForTest ??
      [
        if (Telemetry.posthogAnalyticsOn) _posthog,
        if (Telemetry.ga4On) _ga4,
        if (Telemetry.ga4RelayOn) _ga4Relay,
      ];

  /// Runs [call] on each sink; one failing never stops the others.
  static Future<void> _each(Iterable<AnalyticsSink> sinks, Future<void> Function(AnalyticsSink s) call) =>
      Future.wait([for (final s in sinks) call(s).catchError((Object _) {})]);

  /// GA4 runs only on Casama Cloud with consent. Called when the server kind or the switch changes.
  static Future<void> syncGa4() async {
    if (!Telemetry.ga4On && !Telemetry.ga4RelayOn) return;
    final on = Telemetry.isCloud && await isConsentEnabled();
    try {
      if (Telemetry.ga4On) await _ga4.setEnabled(on);
      if (Telemetry.ga4RelayOn) await _ga4Relay.setEnabled(on);
    } catch (_) {}
  }

  /// A screen view (route template), deduped per session by [SessionScreenObserver].
  static void screen(String name) => unawaited(_each(_sinks, (s) => s.screen(name)));

  static const _consentKey = 'casama.analytics_enabled';
  static const _syncedKey = 'casama.analytics_opt_out_synced';
  static const _internalKeyPrefix = 'casama.analytics_internal.';
  static bool? _consentCache;

  static String _internalKey(String userId) => '$_internalKeyPrefix$userId';

  /// Whether analytics consent is currently active (default true on Cloud builds).
  static Future<bool> isConsentEnabled() async {
    if (_consentCache != null) return _consentCache!;
    try {
      final prefs = await SharedPreferences.getInstance();
      _consentCache = prefs.getBool(_consentKey) ?? true;
    } catch (_) {
      _consentCache = true;
    }
    return _consentCache!;
  }

  /// Updates local consent preference and notifies PostHog, GA4 and the crash reporters.
  static Future<void> setConsentEnabled(bool enabled) async {
    _consentCache = enabled;
    Telemetry.crashConsent = enabled;
    await CrashlyticsReporter.setEnabled(enabled);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_consentKey, enabled);
    } catch (_) {}

    if (Telemetry.posthogAnalyticsOn) {
      try {
        await _posthog.setEnabled(enabled);
      } catch (_) {}
    }
    await syncGa4();
  }

  /// Tells the server the current choice, once per change, so its events and rollups follow the switch.
  /// Cleared on sign-out, so the next person to sign in on this device is told too.
  static Future<void> syncOptOut(Future<void> Function(bool optOut) send) async {
    try {
      final optOut = !await isConsentEnabled();
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_syncedKey) == optOut) return;
      await send(optOut);
      await prefs.setBool(_syncedKey, optOut);
    } catch (_) {
      // Offline or signed out: tried again at the next sign-in or switch.
    }
  }

  /// Identifies the user (PostHog person, GA4 user id) when server is cloud and consent is given.
  static Future<void> identify(String userId) async {
    final sinks = _sinks;
    if (sinks.isEmpty || !Telemetry.isCloud) return;
    final consent = await isConsentEnabled();
    if (!consent) return;
    bool? cachedInternal;
    try {
      final prefs = await SharedPreferences.getInstance();
      cachedInternal = prefs.getBool(_internalKey(userId));
    } catch (_) {}
    await _each(
      sinks,
      (s) => s.identify(
        userId,
        set: cachedInternal != null ? {'is_internal': cachedInternal} : null,
        setOnce: {'signup_platform': Telemetry.platformName},
      ),
    );
  }

  /// Fetches whether [userId] is an internal/test account from `/v1/me` and applies it to all active sinks.
  static Future<void> syncInternal(String userId, Future<bool> Function() fetch) async {
    final sinks = _sinks;
    if (sinks.isEmpty || !Telemetry.isCloud) return;
    final consent = await isConsentEnabled();
    if (!consent) return;
    try {
      final internal = await fetch();
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_internalKey(userId), internal);
      } catch (_) {}
      await _each(sinks, (s) => s.setInternal(internal));
    } catch (_) {
      // Offline or signed out: keep any cached flag applied during identify().
    }
  }

  /// Resets distinctId on sign-out or account deletion.
  static Future<void> reset() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_syncedKey);
    } catch (_) {}
    await _each(_sinks, (s) => s.reset());
  }

  /// Records a catalog-typed event if telemetry & consent are active.
  static Future<void> capture(String event, {Map<String, Object?>? properties}) async {
    final clean = properties != null
        ? {
            for (final e in properties.entries)
              if (e.value != null) e.key: e.value!,
          }
        : null;
    onCaptureForTest?.call(event, clean);
    final sinks = _sinks;
    if (sinks.isEmpty) return;
    final consent = await isConsentEnabled();
    if (!consent) return;
    // PostHog filters in its beforeSend; GA4 gets catalog events on Casama Cloud and nothing else, so
    // the self-hosted daily ping never reaches it.
    await _each(
      sinks.where((s) => s.name != 'ga4' || (Telemetry.isCloud && Telemetry.allowEvent(event, Telemetry.serverKind))),
      (s) => s.capture(event, clean),
    );
  }

  /// [capture] without waiting, for call sites in UI handlers.
  static void log(String event, [Map<String, Object?>? properties]) => unawaited(capture(event, properties: properties));

  /// Errors already reported this session, as `code|screen`: each pair once, so a loop can't flood events.
  static final _errorsShown = <String>{};

  /// A failure the person saw. Only a stable code, the HTTP status, a coarse kind and the screen's route
  /// template: never the message, which can carry names or text.
  static void errorShown({String? code, int? status, required String kind}) {
    final screen = Telemetry.currentScreen;
    if (!_errorsShown.add('${code ?? kind}|$status|$screen')) return;
    log('app_error_shown', {'error_code': code, 'http_status': status, 'kind': kind, 'screen': screen});
  }

  /// Once a day on a server that is not Casama Cloud: that the app was used, and which kind of server. This
  /// and crash reports are all the official app sends there (ANALYTICS-PLAN §3).
  static Future<void> dailyPing() async {
    if (!Telemetry.posthogAnalyticsOn || Telemetry.isCloud) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toUtc().toIso8601String().substring(0, 10);
      if (prefs.getString('casama.daily_ping') == today) return;
      await prefs.setString('casama.daily_ping', today);
      await capture('app_active_daily', properties: {'server_kind': Telemetry.serverKind});
    } catch (_) {}
  }

  /// The closed list of `feature_used` features (ANALYTICS-PLAN §6.10): a new one is added here and in the catalog.
  static const features = analyticsFeatures;

  /// `widget_action`'s closed list of actions (D-405 §15), as the catalog has it.
  static const widgetActions = {'run', 'do_it', 'allow', 'deny', 'stop', 'ask', 'talk'};

  /// A widget's or control's button, carried out by the app (D-405 §15): the event, and the
  /// feature once a day.
  static void widgetAction(String action) {
    assert(widgetActions.contains(action), 'Unknown widget action: $action');
    log('widget_action', {'action': action});
    feature('widget_action');
  }

  /// Pages that count as using a feature when opened (the route template, never ids).
  static const routeFeatures = {
    '/search': 'search',
    '/pages': 'pages',
    // The Library took over Pages (D-274); it counts as the same feature.
    '/library': 'pages',
    '/projects': 'projects',
    '/tasks': 'tasks_board',
    '/inbox': 'inbox',
    '/computer/live': 'computer_live',
    '/teach/:id': 'teach',
    '/groups/:id': 'group_chat',
    '/quick-ask': 'quick_ask',
  };

  /// [featureUsed] without waiting, for UI handlers.
  static void feature(String name) => unawaited(featureUsed(name));

  /// Counts a page as feature use, when it is one.
  static void routeFeature(String route) {
    final f = routeFeatures[route];
    if (f != null) unawaited(featureUsed(f));
  }

  /// Emits feature_used at most once per feature per day per device.
  static Future<void> featureUsed(String feature) async {
    assert(features.contains(feature), 'Unknown feature: $feature');
    if (!features.contains(feature)) return;
    if (_sinks.isEmpty) return;
    final consent = await isConsentEnabled();
    if (!consent) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toUtc().toIso8601String().substring(0, 10);
      final key = 'casama.feature_used.$feature.$today';
      if (prefs.getBool(key) == true) return;

      await prefs.setBool(key, true);
      await capture('feature_used', properties: {'feature': feature});
    } catch (_) {}
  }
}
