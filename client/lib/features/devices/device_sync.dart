import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kasama_sdk/kasama_sdk.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/backend.dart';
import '../../core/providers.dart';
import 'device_collector.dart';
import 'device_events.dart';

/// Keeps this device's shared data up to date and answers runs' requests (D-149).
class DeviceSync {
  DeviceSync(this.backend, this.collector, {DeviceTriggerPlatform? triggers, this.now = DateTime.now}) : triggers = triggers ?? PluginTriggerPlatform();
  final Backend backend;
  final DeviceCollector collector;
  final DeviceTriggerPlatform triggers;
  final DateTime Function() now;
  StreamSubscription<String>? _sub;
  StreamSubscription<({String app, String title, String text})>? _notifications;

  /// Kinds this device can share: collected data plus event-based kinds (D-151).
  Set<DeviceKind> get supported => {
    ...collector.supported,
    if (triggers.supportsPlaces) DeviceKind.places,
    if (triggers.supportsNotifications) DeviceKind.notifications,
  };
  AppLifecycleListener? _life;
  bool _busy = false;

  static const _keyPref = 'kasama.device_key';

  /// A random id for this install, kept across launches.
  Future<String> deviceKey() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_keyPref);
    if (existing != null) return existing;
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final r = Random.secure();
    final key = 'dev-${List.generate(24, (_) => chars[r.nextInt(chars.length)]).join()}';
    await prefs.setString(_keyPref, key);
    return key;
  }

  static String get platform => switch (defaultTargetPlatform) {
    TargetPlatform.iOS => 'ios',
    TargetPlatform.android => 'android',
    TargetPlatform.macOS => 'macos',
    TargetPlatform.windows => 'windows',
    TargetPlatform.linux => 'linux',
    _ => 'web',
  };

  static String get defaultName => switch (defaultTargetPlatform) {
    TargetPlatform.iOS => 'iPhone',
    TargetPlatform.android => 'Android phone',
    TargetPlatform.macOS => 'Mac',
    TargetPlatform.windows => 'Windows PC',
    TargetPlatform.linux => 'Linux computer',
    _ => 'Browser',
  };

  /// This device's record on the server, if it was registered.
  Future<DeviceSource?> current() async {
    final key = await deviceKey();
    for (final s in await backend.deviceSources()) {
      if (s.deviceKey == key) return s;
    }
    return null;
  }

  /// Turns a kind on (after the system prompt) or off (the server deletes its data).
  /// Returns false when the person declined the permission.
  Future<bool> setKind(DeviceKind kind, bool on, {DeviceKindSettings? settings}) async {
    if (on && !await _permission(kind, settings)) return false;
    final key = await deviceKey();
    final s = await current();
    final kinds = Map<String, DeviceKindSettings>.of(s?.kinds ?? const {});
    if (on) {
      kinds[kind.value] = settings ?? kinds[kind.value] ?? DeviceKindSettings();
    } else {
      kinds.remove(kind.value);
    }
    await backend.saveDeviceSource(key, name: s?.name ?? defaultName, platform: platform, kinds: kinds);
    if (kind == DeviceKind.places) {
      on ? await refreshPlaces() : await triggers.stopPlaces();
    } else if (kind == DeviceKind.notifications) {
      on ? _watchNotifications(kinds[kind.value]) : await _stopNotifications();
    } else if (on) {
      await _upload(key, kind, settings: kinds[kind.value]);
    }
    return true;
  }

  Future<bool> _permission(DeviceKind kind, DeviceKindSettings? settings) => switch (kind) {
    DeviceKind.places => triggers.requestPlaces(),
    DeviceKind.notifications => triggers.requestNotifications(),
    _ => collector.requestPermission(kind, settings: settings),
  };

  /// Re-registers geofences for the person's named places (after they change).
  Future<void> refreshPlaces() async => triggers.watchPlaces(await backend.devicePlaces());

  void _watchNotifications(DeviceKindSettings? settings) {
    unawaited(_notifications?.cancel());
    final apps = [for (final a in settings?.apps ?? const <String>[]) a.toLowerCase()];
    _notifications = triggers.notifications().listen((n) async {
      // Only apps the person picked; codes are masked before anything is queued.
      if (!apps.any((a) => n.app.toLowerCase().contains(a))) return;
      final at = now().toUtc();
      await DeviceEventQueue.add({
        'id': 'notif-${at.microsecondsSinceEpoch}-${n.app.hashCode & 0xffff}',
        'type': 'notification',
        'at': at.toIso8601String(),
        'app': n.app,
        'title': maskCodes(n.title),
        'text': maskCodes(n.text),
      });
      await DeviceEventQueue.flush(backend).catchError((_) => 0);
    });
  }

  Future<void> _stopNotifications() async {
    await _notifications?.cancel();
    _notifications = null;
  }

  (DateTime, DateTime) _window(DeviceKind kind) {
    final t = now();
    return switch (kind) {
      DeviceKind.calendar => (t.subtract(const Duration(days: 1)), t.add(const Duration(days: 30))),
      // Health: the last week of days, so a missed morning catches up.
      DeviceKind.health => (DateTime(t.year, t.month, t.day - 7), t),
      _ => (t.subtract(const Duration(days: 1)), t),
    };
  }

  Future<List<DeviceReadingInput>> _upload(String key, DeviceKind kind, {DateTime? from, DateTime? to, String? requestId, DeviceKindSettings? settings}) async {
    final w = _window(kind);
    final readings = await collector.collect(kind, from ?? w.$1, to ?? w.$2, settings: settings);
    if (readings.isEmpty && requestId != null) {
      await backend.uploadDeviceReadings(key, const [], requestId: requestId);
    }
    for (var i = 0; i < readings.length; i += 100) {
      final last = i + 100 >= readings.length;
      await backend.uploadDeviceReadings(key, readings.sublist(i, min(i + 100, readings.length)), requestId: last ? requestId : null);
    }
    return readings;
  }

  /// Uploads every kind that's on.
  Future<void> syncAll() async {
    final s = await current();
    if (s == null) return;
    for (final k in s.kinds.keys) {
      final kind = DeviceKind.values.where((v) => v.value == k).firstOrNull;
      if (kind == null || !collector.supported.contains(kind)) continue;
      try {
        await _upload(s.deviceKey, kind, settings: s.kinds[k]);
      } catch (e) {
        debugPrint('device sync $k failed: $e');
      }
    }
  }

  /// Answers what runs asked this device for: fresh reads and writes.
  Future<void> answerPending() async {
    if (_busy) return;
    _busy = true;
    try {
      final s = await current();
      if (s == null) return;
      for (final r in await backend.deviceRequests(s.deviceKey)) {
        final kind = DeviceKind.values.where((v) => v.value == r.kind).firstOrNull;
        try {
          if (r.action == DeviceRequestActionEnum.locate) {
            // "Where am I now" for leave-now: answered once, never stored here (D-151).
            final at = s.kinds.containsKey('places') ? await triggers.currentLocation() : null;
            await backend.answerDeviceRequest(r.id, ok: at != null, result: at == null ? null : {'lat': at.lat, 'lng': at.lng}, error: at == null ? 'Location isn\'t available' : null);
          } else if (kind == null || !s.kinds.containsKey(r.kind) || !collector.supported.contains(kind)) {
            await backend.answerDeviceRequest(r.id, ok: false, error: '${r.kind} isn\'t shared from this device');
          } else if (r.action == DeviceRequestActionEnum.read) {
            final from = DateTime.tryParse('${r.params['from']}');
            final to = DateTime.tryParse('${r.params['to']}');
            await _upload(s.deviceKey, kind, from: from, to: to, requestId: r.id, settings: s.kinds[r.kind]);
          } else {
            final result = await collector.write(r.action.value, r.params);
            await backend.answerDeviceRequest(r.id, ok: true, result: result);
          }
        } catch (e) {
          await backend.answerDeviceRequest(r.id, ok: false, error: '$e').catchError((_) {});
        }
      }
    } finally {
      _busy = false;
    }
  }

  /// Runs while signed in: answers requests as they arrive and refreshes when the app comes back.
  void start() {
    _sub ??= backend.watchDeviceRequests().listen((_) => unawaited(answerPending().catchError((_) {})));
    _life ??= AppLifecycleListener(
      onResume: () {
        unawaited(DeviceEventQueue.flush(backend).catchError((_) => 0));
        unawaited(answerPending().catchError((_) {}));
        unawaited(syncAll().catchError((_) {}));
      },
    );
    unawaited(answerPending().catchError((_) {}));
    unawaited(syncAll().catchError((_) {}));
    unawaited(_startTriggers().catchError((_) {}));
  }

  Future<void> _startTriggers() async {
    await DeviceEventQueue.flush(backend);
    final s = await current();
    if (s == null) return;
    if (s.kinds.containsKey('places') && triggers.supportsPlaces) await refreshPlaces();
    if (s.kinds.containsKey('notifications') && triggers.supportsNotifications) _watchNotifications(s.kinds['notifications']);
  }

  void dispose() {
    unawaited(_notifications?.cancel());
    unawaited(_sub?.cancel());
    _sub = null;
    _life?.dispose();
    _life = null;
  }
}

final deviceCollectorProvider = Provider<DeviceCollector>((ref) => PluginDeviceCollector());
final deviceTriggerPlatformProvider = Provider<DeviceTriggerPlatform>((ref) => PluginTriggerPlatform());

final deviceSyncProvider = Provider<DeviceSync>((ref) {
  final sync = DeviceSync(ref.watch(backendProvider), ref.watch(deviceCollectorProvider), triggers: ref.watch(deviceTriggerPlatformProvider));
  ref.onDispose(sync.dispose);
  ref.listen(signedInProvider, (_, next) {
    if (next.value == true && sync.supported.isNotEmpty) sync.start();
  }, fireImmediately: true);
  return sync;
});
