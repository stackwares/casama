import 'dart:async';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'telemetry.dart';

/// Facade for product analytics (ANALYTICS-PLAN.md §4.2).
/// All methods are safe no-ops when PostHog is disabled, consent is opted out,
/// or server_kind is not 'cloud'.
class Analytics {
  static const _consentKey = 'casama.analytics_enabled';
  static const _syncedKey = 'casama.analytics_opt_out_synced';
  static bool? _consentCache;

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

  /// Updates local consent preference and notifies PostHog.
  static Future<void> setConsentEnabled(bool enabled) async {
    _consentCache = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_consentKey, enabled);
    } catch (_) {}

    if (Telemetry.posthogOn) {
      try {
        if (enabled) {
          await Posthog().capture(eventName: 'enable_analytics_sharing');
          await Posthog().optIn();
        } else {
          await Posthog().capture(eventName: 'disable_analytics_sharing');
          await Posthog().optOut();
        }
      } catch (_) {}
    }
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

  /// Identifies the user on PostHog when server is cloud and consent is given.
  static Future<void> identify(String userId) async {
    if (!Telemetry.posthogOn) return;
    final consent = await isConsentEnabled();
    if (!consent) return;
    try {
      await Posthog().identify(
        userId: userId,
        userProperties: {
          'server_kind': 'cloud',
        },
        userPropertiesSetOnce: {
          'signup_platform': Telemetry.platformName,
        },
      );
    } catch (_) {}
  }

  /// Resets distinctId on sign-out or account deletion.
  static Future<void> reset() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_syncedKey);
    } catch (_) {}
    if (!Telemetry.posthogOn) return;
    try {
      await Posthog().reset();
    } catch (_) {}
  }

  /// Records a catalog-typed event if telemetry & consent are active.
  static Future<void> capture(String event, {Map<String, Object?>? properties}) async {
    if (!Telemetry.posthogOn) return;
    final consent = await isConsentEnabled();
    if (!consent) return;
    try {
      final clean = properties != null
          ? {
              for (final e in properties.entries)
                if (e.value != null) e.key: e.value!,
            }
          : null;
      await Posthog().capture(
        eventName: event,
        properties: clean,
      );
    } catch (_) {}
  }

  /// Emits feature_used at most once per feature per day per device.
  static Future<void> featureUsed(String feature) async {
    if (!Telemetry.posthogOn) return;
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
