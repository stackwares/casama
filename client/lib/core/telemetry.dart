import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Error reporting and product analytics (D-063). Off unless a key is given at build time:
///   --dart-define=SENTRY_DSN=...          Sentry, self-hosted Sentry or GlitchTip
///   --dart-define=POSTHOG_API_KEY=...     PostHog errors and screen analytics
///   --dart-define=POSTHOG_HOST=...        PostHog Cloud region or a self-hosted instance
///   --dart-define=ERROR_REPORTING=auto|sentry|posthog|none
/// Payloads never carry message text, prompts, secrets or emails.
///
/// Native PostHog auto-init is disabled in the iOS and macOS Info.plists and the Android
/// manifest. Without that, the plugin demands a token at process start and logs an error
/// on every launch. [Posthog.setup] still runs here when a key is set.
class Telemetry {
  static const sentryDsn = String.fromEnvironment('SENTRY_DSN');
  static const posthogKey = String.fromEnvironment('POSTHOG_API_KEY');
  static const posthogHost = String.fromEnvironment('POSTHOG_HOST', defaultValue: 'https://us.i.posthog.com');
  static const mode = String.fromEnvironment('ERROR_REPORTING', defaultValue: 'auto');

  static bool get posthogOn => posthogKey.isNotEmpty && mode != 'none';
  static bool get sentryErrors => sentryDsn.isNotEmpty && (mode == 'auto' || mode == 'sentry');
  static bool get posthogErrors => posthogOn && (mode == 'posthog' || (mode == 'auto' && sentryDsn.isEmpty));

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
  static const _keepKeys = {r'$exception_list', r'$exception_level', r'$exception_type', r'$exception_message', r'$screen_name'};

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

  /// Starts error reporting (if configured) and runs the app.
  static Future<void> run(Widget app) async {
    if (posthogOn) {
      final config = PostHogConfig(posthogKey)
        ..host = posthogHost
        ..captureApplicationLifecycleEvents = true
        ..personProfiles = PostHogPersonProfiles.never
        ..sessionReplay = false
        ..beforeSend = [
          (event) {
            event.properties = (_deep(event.properties) as Map?)?.cast<String, Object>();
            event.userProperties = null;
            event.userPropertiesSetOnce = null;
            return event;
          },
        ];
      if (posthogErrors) {
        config.errorTrackingConfig
          ..captureFlutterErrors = true
          ..capturePlatformDispatcherErrors = true;
      }
      await Posthog().setup(config);
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

  /// Screen views for PostHog (no-op when PostHog is off).
  static List<NavigatorObserver> get observers => posthogOn ? [PosthogObserver()] : const [];
}
