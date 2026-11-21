import 'dart:async';

import 'package:device_calendar/device_calendar.dart' as dc;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as fc;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:health/health.dart' as hc;
import 'package:notification_listener_service/notification_listener_service.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:casama_sdk/casama_sdk.dart' show DeviceKind;

import '../../core/push.dart';
import '../devices/device_collector.dart';
import '../devices/device_sync.dart';
import 'os_permissions.dart';
import 'permissions_web.dart' if (dart.library.io) 'permissions_web_stub.dart';

/// Checks, asks for and opens the settings of this device's system permissions (D-376).
///
/// [check] never prompts. [request] shows the system prompt when the system would still ask, and
/// otherwise opens the page with the switch; it returns the state afterwards (a settings page
/// returns before the person flips anything, so the caller checks again later).
abstract class PermissionsPlatform {
  /// This device's platform, in the table's names (ios, android, macos, windows, linux, web).
  String get platform;
  Future<Map<String, String>> check(Iterable<String> ids);
  Future<String> request(String id);
  Future<bool> openSettings(String id);

  /// Restarts Casama (macOS, after Screen Recording). False where it can't.
  Future<bool> relaunch();
}

/// The native side of what no plugin covers: on macOS Accessibility, Screen Recording,
/// Automation, Full Disk Access, the microphone and speech, and restarting; on iOS the camera,
/// photos, the microphone, speech and "Always" location (geolocator never asks to go from "While
/// using" to "Always"). Methods: `check {ids}` → `{id: state}`, `request {id}` →
/// state, `relaunch`.
const permissionsChannel = MethodChannel('casama/permissions');

/// Ids the native channel answers on each platform.
const _nativeIds = <String, Set<String>>{
  'macos': {'accessibility', 'screen_recording', 'automation', 'full_disk', 'microphone', 'speech', 'notifications'},
  'ios': {'camera', 'photos', 'microphone', 'speech', 'location_always'},
};

/// System Settings panes on a Mac.
const _macPanes = <String, String>{
  'accessibility': 'x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility',
  'screen_recording': 'x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture',
  'automation': 'x-apple.systempreferences:com.apple.preference.security?Privacy_Automation',
  'full_disk': 'x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles',
  'microphone': 'x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone',
  'speech': 'x-apple.systempreferences:com.apple.preference.security?Privacy_SpeechRecognition',
  'contacts': 'x-apple.systempreferences:com.apple.preference.security?Privacy_Contacts',
  'notifications': 'x-apple.systempreferences:com.apple.Notifications-Settings.extension',
};

/// Windows settings pages.
const _windowsPages = <String, String>{'microphone': 'ms-settings:privacy-microphone', 'notifications': 'ms-settings:notifications'};

/// The plugins the app already uses, with the native channel and settings links for the rest.
class PluginPermissionsPlatform implements PermissionsPlatform {
  PluginPermissionsPlatform({required this.collector, required this.enablePush, String? platform}) : platform = platform ?? currentPermissionPlatform();

  /// Device connections' collector: the same calendar, contacts and health asks as turning a kind on.
  final DeviceCollector collector;

  /// Push's own Turn on: the system prompt, then this device's registration.
  final Future<bool> Function() enablePush;

  @override
  final String platform;

  /// What a request answered, for plugins that can't tell "never asked" from "said no".
  static String _askedKey(String id) => 'permissions.asked.$id';

  Future<bool> _asked(String id) async => (await SharedPreferences.getInstance()).getBool(_askedKey(id)) ?? false;
  Future<void> _markAsked(String id) async => (await SharedPreferences.getInstance()).setBool(_askedKey(id), true);

  bool _native(String id) => _nativeIds[platform]?.contains(id) ?? false;

  @override
  Future<Map<String, String>> check(Iterable<String> ids) async {
    final out = <String, String>{};
    final native = [
      for (final id in ids)
        if (_native(id)) id,
    ];
    if (native.isNotEmpty) {
      try {
        final m = await permissionsChannel.invokeMapMethod<String, String>('check', {'ids': native});
        out.addAll(m ?? const {});
      } catch (_) {
        // An older build without the channel: unknown, not an error.
      }
    }
    for (final id in ids) {
      if (out.containsKey(id)) continue;
      try {
        out[id] = await _check(id);
      } catch (_) {
        out[id] = PermissionState.unknown;
      }
    }
    return out;
  }

  Future<String> _check(String id) async {
    final ask = permissionAsk(id, platform);
    if (ask == null) return PermissionState.unavailable;
    // Casama's own settings: the server knows them (allowed folders, local tools).
    if (ask == PermissionAsk.casama) return PermissionState.unknown;
    if (platform == 'web') return webPermissionState(id);
    switch (id) {
      case 'location':
      case 'location_always':
        return switch (await Geolocator.checkPermission()) {
          LocationPermission.always => PermissionState.granted,
          LocationPermission.whileInUse => id == 'location' ? PermissionState.granted : PermissionState.notAsked,
          // Android: asked and refused, may ask again; iOS: never asked. Either way a prompt can show.
          LocationPermission.denied => PermissionState.notAsked,
          LocationPermission.deniedForever => PermissionState.denied,
          LocationPermission.unableToDetermine => PermissionState.unknown,
        };
      case 'contacts':
        return switch (await fc.FlutterContacts.permissions.check(fc.PermissionType.read)) {
          fc.PermissionStatus.granted => PermissionState.granted,
          fc.PermissionStatus.limited => PermissionState.limited,
          fc.PermissionStatus.denied => PermissionState.notAsked,
          fc.PermissionStatus.permanentlyDenied => PermissionState.denied,
          fc.PermissionStatus.restricted => PermissionState.restricted,
          fc.PermissionStatus.notDetermined => PermissionState.notAsked,
        };
      case 'microphone':
        if (await AudioRecorder().hasPermission(request: false)) return PermissionState.granted;
        return await _asked(id) ? PermissionState.denied : PermissionState.notAsked;
      case 'speech':
        if (await SpeechToText().hasPermission) return PermissionState.granted;
        return await _asked(id) ? PermissionState.denied : PermissionState.notAsked;
      case 'calendar':
        if ((await dc.DeviceCalendarPlugin().hasPermissions()).data == true) return PermissionState.granted;
        return await _asked(id) ? PermissionState.denied : PermissionState.notAsked;
      case 'health':
        return _healthState(asked: await _asked(id));
      case 'notifications':
        if (platform == 'windows') return PermissionState.unknown;
        if (Firebase.apps.isEmpty) return PermissionState.unknown;
        return switch ((await FirebaseMessaging.instance.getNotificationSettings()).authorizationStatus) {
          AuthorizationStatus.authorized => PermissionState.granted,
          AuthorizationStatus.provisional => PermissionState.limited,
          AuthorizationStatus.denied || AuthorizationStatus.deniedPermanently => PermissionState.denied,
          AuthorizationStatus.notDetermined => PermissionState.notAsked,
        };
      case 'notification_access':
        return await NotificationListenerService.isPermissionGranted() ? PermissionState.granted : PermissionState.denied;
    }
    return PermissionState.unknown;
  }

  /// Health without prompting. Health Connect (Android) says whether reading is allowed. HealthKit
  /// (iOS) never does and shows its sheet only once, so after asking, step data Casama can read
  /// counts as on and none as off: the switches are then in the Health app.
  Future<String> _healthState({required bool asked}) async {
    final health = hc.Health();
    await health.configure();
    if (platform == 'android') {
      final status = await health.getHealthConnectSdkStatus();
      if (status == hc.HealthConnectSdkStatus.sdkUnavailable) return PermissionState.unavailable;
      // Missing or out of date: Turn on installs it first.
      if (status != hc.HealthConnectSdkStatus.sdkAvailable) return PermissionState.notAsked;
      final types = PluginDeviceCollector.healthTypes(null).where(health.isDataTypeAvailable).toList();
      final ok = await health.hasPermissions(types, permissions: [for (final _ in types) hc.HealthDataAccess.READ]);
      // Not all allowed yet: Health Connect asks again for the rest.
      return ok == true ? PermissionState.granted : PermissionState.notAsked;
    }
    if (!asked) return PermissionState.notAsked;
    final now = DateTime.now();
    final steps = await health.getTotalStepsInInterval(now.subtract(const Duration(days: 14)), now);
    return (steps ?? 0) > 0 ? PermissionState.granted : PermissionState.denied;
  }

  @override
  Future<String> request(String id) async {
    final ask = permissionAsk(id, platform);
    if (ask == null) return PermissionState.unavailable;
    if (ask != PermissionAsk.prompt) {
      await openSettings(id);
      return (await check([id]))[id] ?? PermissionState.unknown;
    }
    final before = (await check([id]))[id];
    if (permissionOn(before)) return before!;
    // Said no before: the system won't ask again, so the switch is in its settings.
    if (before == PermissionState.denied || before == PermissionState.restricted) {
      await openSettings(id);
      return before!;
    }
    await _markAsked(id);
    try {
      await _prompt(id);
    } catch (e) {
      debugPrint('permission request $id failed: $e');
    }
    final after = (await check([id]))[id] ?? PermissionState.unknown;
    // A Mac's Accessibility and Screen Recording prompts return at once, before the person
    // answers, and the switch is in System Settings either way: open the pane with it. Elsewhere
    // the prompt waited for the answer, and a "Don't allow" just now is left alone.
    if (!permissionOn(after) && platform == 'macos' && (id == 'accessibility' || id == 'screen_recording')) await openSettings(id);
    return after;
  }

  Future<void> _prompt(String id) async {
    if (platform == 'web') {
      if (id == 'location') {
        await Geolocator.requestPermission();
      } else if (id == 'notifications') {
        await enablePush();
      } else {
        await webPermissionRequest(id);
      }
      return;
    }
    if (_native(id) && id != 'microphone' && id != 'speech') {
      await permissionsChannel.invokeMethod<String>('request', {'id': id});
      return;
    }
    switch (id) {
      case 'location':
        await Geolocator.requestPermission();
      case 'contacts':
        await collector.requestPermission(DeviceKind.contacts);
      case 'calendar':
        await collector.requestPermission(DeviceKind.calendar);
      case 'health':
        if (platform == 'android') {
          final health = hc.Health();
          await health.configure();
          if (await health.getHealthConnectSdkStatus() != hc.HealthConnectSdkStatus.sdkAvailable) {
            // Health Connect missing or out of date: its store page; the row turns on after it's set up.
            await health.installHealthConnect();
            return;
          }
        }
        await collector.requestPermission(DeviceKind.health);
      case 'microphone':
        await AudioRecorder().hasPermission();
      case 'speech':
        await SpeechToText().initialize();
      case 'notifications':
        await enablePush();
    }
  }

  @override
  Future<bool> openSettings(String id) async {
    try {
      switch (platform) {
        case 'macos':
          final pane = _macPanes[id];
          return pane != null && await launchUrl(Uri.parse(pane));
        case 'windows':
          final page = _windowsPages[id];
          return page != null && await launchUrl(Uri.parse(page));
        case 'android':
          if (id == 'notification_access') return await NotificationListenerService.requestPermission();
          return await Geolocator.openAppSettings();
        case 'ios':
          // Health's switches are in the Health app (profile → Apps → Casama), not in Settings.
          if (id == 'health') return await launchUrl(Uri.parse('x-apple-health://'));
          // Everything else: Casama's own page in Settings, where every switch for it is.
          return await Geolocator.openAppSettings();
      }
    } catch (e) {
      debugPrint('permission settings $id failed: $e');
    }
    return false;
  }

  @override
  Future<bool> relaunch() async {
    if (platform != 'macos') return false;
    try {
      await permissionsChannel.invokeMethod<void>('relaunch');
      return true;
    } catch (_) {
      return false;
    }
  }
}

final permissionsPlatformProvider = Provider<PermissionsPlatform>((ref) => PluginPermissionsPlatform(collector: ref.watch(deviceCollectorProvider), enablePush: () => ref.read(pushProvider).enable()));
