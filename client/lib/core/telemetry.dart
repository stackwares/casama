import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'billing.dart' show defaultStore, RevenueCatStore;
import 'config.dart';
import 'crash_reporter.dart';
import 'crashlytics.dart';
import 'distribution.dart';
import 'telemetry_web_stub.dart' if (dart.library.js_interop) 'telemetry_web.dart';
import 'analytics.dart';
import 'analytics_events.g.dart';
import 'analytics_sinks.dart';
import 'push.dart' show PushConfig;

/// Error reporting and product analytics (D-063, D-206). Off unless a key is given at build time:
///   --dart-define=SENTRY_DSN=...          Sentry, self-hosted Sentry or GlitchTip
///   --dart-define=POSTHOG_API_KEY=...     PostHog errors and screen analytics
///   --dart-define=POSTHOG_HOST=...        PostHog Cloud region or a self-hosted instance
///   --dart-define=POSTHOG_ENVIRONMENT=... production|staging|development
///   --dart-define=ERROR_REPORTING=auto|sentry|posthog|crashlytics|none  the build's crash reporter
///   --dart-define=ANALYTICS_PROVIDERS=posthog,ga4  product analytics providers (empty: every configured one)
///   --dart-define=GA4_ENABLED=true                  Google Analytics 4 when ANALYTICS_PROVIDERS is empty
///   --dart-define=FIREBASE_WEB_MEASUREMENT_ID=...   the web app's GA4 stream (D-397)
///   --dart-define=CRASHLYTICS_ENABLED=true          Firebase Crashlytics can run, iOS/Android/macOS (D-416)
/// One crash reporter runs per launch (D-417): the remote settings' `crash_reporter`, else the build's
/// ERROR_REPORTING, among those this build has ([CrashReporters]).
/// The "Share usage data and crash reports" switch turns the crash reporter off with the analytics.
/// Payloads never carry message text, prompts, secrets or emails.
///
/// Native PostHog auto-init is disabled in the iOS and macOS Info.plists and the Android
/// manifest. Without that, the plugin demands a token at process start and logs an error
/// on every launch. [Posthog.setup] still runs here when a key is set.
class Telemetry {
  static const sentryDsn = String.fromEnvironment('SENTRY_DSN');
  static const posthogKey = String.fromEnvironment('POSTHOG_API_KEY');
  static const posthogHost = String.fromEnvironment(
    'POSTHOG_HOST',
    defaultValue: 'https://us.i.posthog.com',
  );
  static const posthogEnv = String.fromEnvironment(
    'POSTHOG_ENVIRONMENT',
    defaultValue: kReleaseMode ? 'production' : 'development',
  );
  static const mode = String.fromEnvironment('ERROR_REPORTING', defaultValue: 'auto');

  static bool get posthogOn => posthogKey.isNotEmpty && mode != 'none';

  /// Which product analytics providers may run (D-397): a comma list of `posthog`, `ga4`, or `none`.
  /// Empty means every configured one (GA4 also needs [ga4Enabled] then). Crash reports don't follow it.
  static const analyticsProviders = String.fromEnvironment('ANALYTICS_PROVIDERS');
  static const ga4Enabled = bool.fromEnvironment('GA4_ENABLED');
  static const ga4WebMeasurementId = String.fromEnvironment('FIREBASE_WEB_MEASUREMENT_ID');

  /// PostHog product events and screens (its SDK may still run for crash reports when this is off).
  static bool get posthogAnalyticsOn =>
      analyticsProviderOn('posthog', raw: analyticsProviders, configured: posthogOn);

  /// GA4 has a Firebase project, a supported platform and, on the web, a measurement id.
  static bool get ga4Configured =>
      PushConfig.enabled &&
      ga4PlatformSupported(isWeb: kIsWeb, platform: defaultTargetPlatform) &&
      (!kIsWeb || ga4WebMeasurementId.isNotEmpty);

  /// Google Analytics 4 product events and screens (still Casama Cloud and consent only, [Analytics.syncGa4]).
  static bool get ga4On => analyticsProviderOn(
        'ga4',
        raw: analyticsProviders,
        configured: ga4Configured,
        onByDefault: ga4Enabled,
      );

  /// Windows and Linux: GA4 through the server instead (D-399). The same switch as [ga4On], minus the
  /// Firebase requirement; the server forwards only when it has GA4 keys.
  static bool get ga4RelayOn =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.linux) &&
      analyticsProviderOn('ga4', raw: analyticsProviders, configured: true, onByDefault: ga4Enabled);

  /// Done once PostHog is set up. Every PostHog call waits for it: on the web the app starts
  /// while posthog-js is still downloading (see [run]), and the plugin silently drops calls made
  /// before that.
  static Future<void> posthogReady = Future.value();
  /// The switch's state for crash reports: Sentry drops reports while it's off (PostHog opts out as a
  /// whole, Crashlytics stops collecting; see [Analytics.setConsentEnabled]).
  static bool crashConsent = true;

  /// The crash reporters this build can run on this platform (D-417). `ERROR_REPORTING=none` rules
  /// them all out.
  static Set<CrashReporterKind> get availableCrashReporters => {
        if (sentryDsn.isNotEmpty && mode != 'none') CrashReporterKind.sentry,
        if (posthogOn) CrashReporterKind.posthog,
        if (CrashlyticsReporter.available) CrashReporterKind.crashlytics,
      };

  /// Sentry is this launch's crash reporter (it isn't even initialised otherwise).
  static bool get sentryErrors => CrashReporters.active == CrashReporterKind.sentry;

  /// PostHog captures exceptions this launch (its analytics and replay don't depend on this).
  static bool get posthogErrors => CrashReporters.active == CrashReporterKind.posthog;

  /// Picks this launch's one crash reporter. Called once, before any reporter starts; a remote
  /// change fetched later applies on the next launch.
  static Future<CrashReporterKind> chooseCrashReporter() async {
    final available = availableCrashReporters;
    final remote = available.isEmpty ? null : await CrashReporters.savedRemoteChoice(platformName);
    CrashReporters.active = CrashReporters.choose(remote: remote, buildMode: mode, available: available);
    unawaited(CrashReporters.remember());
    return CrashReporters.active;
  }

  static final _secrets = [
    RegExp(r'\b(sk|pk|rk)-[A-Za-z0-9_-]{12,}'),
    RegExp(r'\bBearer\s+[A-Za-z0-9._~+/=-]{8,}', caseSensitive: false),
    RegExp(r'\beyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{5,}'),
    RegExp(r'\b(gh[pousr]_[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16})\b'),
    RegExp(r'[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}'),
  ];
  static final _sensitiveKey = RegExp(
    r'authorization|cookie|token|secret|password|api[_-]?key|credential|prompt|content|message|text|args|input|output|body|email|persona',
    caseSensitive: false,
  );
  static const _keepKeys = {
    r'$exception_list',
    r'$exception_level',
    r'$exception_type',
    r'$exception_message',
    r'$screen_name',
  };

  /// Removes secrets and emails, and truncates.
  static String scrub(String s, [int max = 500]) {
    var out = s;
    for (final re in _secrets) {
      out = out.replaceAll(re, '[redacted]');
    }
    return out.length > max ? '${out.substring(0, max)}…' : out;
  }

  static Object? _deep(Object? v) => switch (v) {
        String s => scrub(s),
        Map m => {
            for (final e in m.entries)
              if (!(e.key is String && _sensitiveKey.hasMatch(e.key as String) && !_keepKeys.contains(e.key)) &&
                  !const {'pre_context', 'context_line', 'post_context'}.contains(e.key))
                e.key: _deep(e.value),
          },
        List l => [for (final x in l) _deep(x)],
        _ => v,
      };

  /// Platform string matching PostHog schema.
  static String get platformName {
    if (kIsWeb) return 'web';
    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS => 'ios',
      TargetPlatform.android => 'android',
      TargetPlatform.macOS => 'macos',
      TargetPlatform.windows => 'windows',
      TargetPlatform.linux => 'linux',
      _ => 'unknown',
    };
  }

  /// How this build is distributed: app_store | google_play | mac_app_store | direct | web.
  static String get distributionName {
    if (kIsWeb) return 'web';
    if (isMacAppStoreBuild) return 'mac_app_store';
    final store = defaultStore(() => null);
    if (store is RevenueCatStore) {
      return store.source; // 'app_store' or 'google_play'
    }
    return kDistribution == 'appstore' ? 'app_store' : 'direct';
  }

  /// Client product events (ANALYTICS-PLAN §6). Anything else is dropped before it leaves the device.
  static const catalogEvents = analyticsClientEvents;

  /// What an official app may send while connected to someone else's server: crash reports (always) and these.
  static const _selfHostedEvents = {'app_active_daily', 'app_startup_failed'};

  /// The kind of server the app is connected to (cloud, self_hosted, local), unknown until its config loads.
  static String serverKind = 'unknown';

  static bool get isCloud => serverKind == 'cloud';

  /// The route template of the page on screen (never ids), for events that say where something happened.
  static String? currentScreen;

  /// Whether an event may leave the device: exceptions always; screens and product events on Casama
  /// Cloud only; a self-hosted or local server only ever sees [_selfHostedEvents].
  static bool allowEvent(String name, String kind) {
    if (name == r'$exception') return true;
    if (kind == 'cloud') return name == r'$screen' || catalogEvents.contains(name);
    return _selfHostedEvents.contains(name);
  }

  /// Classifies connected server kind (cloud, local, self_hosted) without sending the URL.
  static String resolveServerKind({required String apiUrl, required bool billingEnabled}) {
    final uri = Uri.tryParse(apiUrl);
    final host = uri?.host ?? '';
    final official = host == 'casama.ai' || host.endsWith('.casama.ai') || apiUrl == AppConfig.fromEnvironment.apiUrl;
    if (billingEnabled && official) return 'cloud';
    if (host == 'localhost' || host == '127.0.0.1' || host == '::1') {
      return 'local';
    }
    return 'self_hosted';
  }

  /// Registers or updates server_kind super property once server configuration is known.
  static Future<void> updateServerKind({required String apiUrl, required bool billingEnabled}) async {
    if (!posthogOn && !ga4On && !CrashlyticsReporter.on) return;
    final kind = resolveServerKind(apiUrl: apiUrl, billingEnabled: billingEnabled);
    serverKind = kind;
    unawaited(CrashlyticsReporter.setKey('server_kind', kind));
    if (posthogOn) {
      try {
        await posthogReady;
        await Posthog().register('server_kind', kind);
      } catch (_) {}
    }
    await Analytics.syncGa4();
  }

  /// Starts error reporting (if configured) and runs the app.
  static Future<void> run(Widget app) async {
    // First: which one crash reporter runs (D-417). Everything below starts only that one.
    await chooseCrashReporter();
    if (posthogOn) {
      posthogReady = _setUpPosthog().catchError((Object _) {});
      // On the web, setup first downloads posthog-js (up to 3 s on a slow connection); the app's
      // first frame doesn't wait for it, and calls made meanwhile wait on [posthogReady]. Native
      // setup is local and quick, so it still finishes first and catches the earliest errors.
      if (!kIsWeb) await posthogReady;
    }
    if (sentryErrors || CrashlyticsReporter.on) {
      crashConsent = await Analytics.isConsentEnabled();
    }
    if (CrashlyticsReporter.on) {
      // Handlers now (they wait for setup and the switch), Firebase setup without holding the first frame.
      CrashlyticsReporter.installHandlers(scrub: scrub);
      unawaited(CrashlyticsReporter.start(
        consent: crashConsent,
        keys: {'distribution': distributionName, 'environment': posthogEnv, 'server_kind': serverKind},
      ));
    } else {
      unawaited(CrashlyticsReporter.stopUnused());
    }
    if (sentryErrors) {
      await SentryFlutter.init((o) {
        o.dsn = sentryDsn;
        o.sendDefaultPii = false;
        o.beforeBreadcrumb = (b, _) {
          if (b == null) return null;
          if (b.message != null) b.message = scrub(b.message!);
          b.data = null;
          return b;
        };
        o.beforeSend = (event, _) {
          if (!crashConsent) return null;
          for (final e in event.exceptions ?? const <SentryException>[]) {
            if (e.value != null) e.value = scrub(e.value!);
          }
          if (event.message != null) event.message = SentryMessage(scrub(event.message!.formatted));
          event.user = null;
          event.request = null;
          return event;
        };
      }, appRunner: () => runApp(app));
      return;
    }
    runApp(app);
  }

  static Future<void> _setUpPosthog() async {
    if (kIsWeb) {
      await initWebPosthog(apiKey: posthogKey, host: posthogHost);
    }
    final config = PostHogConfig(posthogKey)
      ..host = posthogHost
      ..captureApplicationLifecycleEvents = false
      ..personProfiles = PostHogPersonProfiles.identifiedOnly
      ..sessionReplay = false
      ..surveys = false
      ..preloadFeatureFlags = false
      ..capturePushNotificationSubscriptions = false
      ..capturePushNotificationOpened = false
      ..beforeSend = [
        (event) {
          final eventName = event.event;
          if (eventName == r'$exception') {
            event.properties = (_deep(event.properties) as Map?)?.cast<String, Object>();
            event.userProperties = null;
            event.userPropertiesSetOnce = null;
            return event;
          }
          if (!allowEvent(eventName, serverKind)) {
            // Product events and screens are Casama Cloud only; anything uncatalogued is a bug in debug builds.
            assert(
              serverKind != 'cloud' || eventName == r'$screen' || _selfHostedEvents.contains(eventName),
              'Unexpected event before catalog registration: $eventName',
            );
            return null;
          }
          if (eventName == r'$screen') return event;
          if (event.properties != null) {
            event.properties = (_deep(event.properties) as Map?)?.cast<String, Object>();
          }
          return event;
        },
      ];
    if (posthogErrors) {
      config.errorTrackingConfig
        ..captureFlutterErrors = true
        ..capturePlatformDispatcherErrors = true
        ..captureIsolateErrors = true
        ..captureNativeExceptions = true
        ..captureNativeCrashes = true
        ..inAppIncludes.add('casama')
        ..exceptionSteps.enabled = true;
    }
    await Posthog().setup(config);

    // Super properties applied to every event
    await Posthog().register('app', 'casama');
    await Posthog().register('environment', posthogEnv);
    await Posthog().register('platform', platformName);
    await Posthog().register('distribution', distributionName);
    await Posthog().register('server_kind', 'unknown');
    await Posthog().register('crash_reporter', CrashReporters.active.name);
  }

  // Rate-limiting for reported exceptions (ANALYTICS-PLAN §8.2):
  // At most 20 exceptions a minute per process, and the same error fingerprint
  // at most once every 5 minutes.
  static final List<DateTime> _recentExceptionTimes = [];
  static final Map<String, DateTime> _recentFingerprints = {};
  static const int _maxExceptionsPerMinute = 20;
  static const Duration _fingerprintCooldown = Duration(minutes: 5);

  /// Captures an unexpected exception or warning to this launch's crash reporter, if any.
  /// Rate-limited to protect quotas against reconnect / retry loops.
  static Future<void> captureException(
    Object error,
    StackTrace? stackTrace, {
    Map<String, Object?>? context,
    bool warning = false,
  }) async {
    final now = DateTime.now();

    // 1. Minute rate-cap check
    _recentExceptionTimes.removeWhere((t) => now.difference(t) > const Duration(minutes: 1));
    if (_recentExceptionTimes.length >= _maxExceptionsPerMinute) {
      return;
    }

    // 2. Fingerprint deduplication (error type + first line of stack trace)
    final topFrame = stackTrace?.toString().split('\n').firstOrNull ?? '';
    final fingerprint = '${error.runtimeType}:${scrub(error.toString())}:$topFrame';
    final lastSeen = _recentFingerprints[fingerprint];
    if (lastSeen != null && now.difference(lastSeen) < _fingerprintCooldown) {
      return;
    }

    _recentExceptionTimes.add(now);
    _recentFingerprints[fingerprint] = now;

    // Prune stale fingerprints periodically
    if (_recentFingerprints.length > 200) {
      _recentFingerprints.removeWhere((_, time) => now.difference(time) > _fingerprintCooldown);
    }

    final scrubbedContext = (_deep(context) as Map?)?.cast<String, Object>();

    if (!warning) unawaited(CrashlyticsReporter.record(error, stackTrace, scrub: scrub, reason: 'handled'));

    if (posthogErrors) {
      try {
        await Posthog().capture(
          eventName: r'$exception',
          properties: {
            r'$exception_message': scrub(error.toString()),
            r'$exception_type': error.runtimeType.toString(),
            if (stackTrace != null) r'$exception_stack_trace_raw': scrub(stackTrace.toString(), 2000),
            r'$exception_level': warning ? 'warning' : 'error',
            ...?scrubbedContext,
          },
        );
      } catch (_) {}
    }

    if (sentryErrors) {
      try {
        await Sentry.captureException(
          error,
          stackTrace: stackTrace,
          withScope: (scope) {
            if (warning) scope.level = SentryLevel.warning;
            if (scrubbedContext != null) {
              for (final entry in scrubbedContext.entries) {
                scope.setContexts(entry.key, entry.value);
              }
            }
          },
        );
      } catch (_) {}
    }
  }

  /// Screen views for the analytics providers (no-op when none is on).
  /// Returns a fresh session-deduped observer for each navigator.
  static List<NavigatorObserver> get observers =>
      posthogAnalyticsOn || ga4On ? [SessionScreenObserver()] : const [];
}

/// Deduplicates screen tracking events so each screen template is sent at most once
/// per session (ANALYTICS-PLAN.md §4.2). A session resets after 30 minutes in background.
class SessionScreenObserver extends NavigatorObserver with WidgetsBindingObserver {
  SessionScreenObserver() {
    WidgetsBinding.instance.addObserver(this);
  }

  static final Set<String> _seenScreens = <String>{};
  static DateTime _lastActive = DateTime.now();
  static const Duration sessionTimeout = Duration(minutes: 30);

  static void resetSession() {
    _seenScreens.clear();
    _lastActive = DateTime.now();
  }

  @visibleForTesting
  static bool hasSeen(String name) => _seenScreens.contains(name);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (DateTime.now().difference(_lastActive) > sessionTimeout) {
        _seenScreens.clear();
      }
      _lastActive = DateTime.now();
    } else if (state == AppLifecycleState.paused) {
      _lastActive = DateTime.now();
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _maybeTrack(route);
    super.didPush(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute != null) _maybeTrack(newRoute);
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute != null) _maybeTrack(previousRoute);
    super.didPop(route, previousRoute);
  }

  void _maybeTrack(Route<dynamic> route) {
    final name = route.settings.name;
    if (name == null || name.trim().isEmpty) return;
    Telemetry.currentScreen = name;
    Analytics.routeFeature(name);
    if (_seenScreens.add(name)) Analytics.screen(name);
  }
}
