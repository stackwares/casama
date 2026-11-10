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

/// Keeps this device's shared data up to date and answers runs' requests (D-149).
class DeviceSync {
  DeviceSync(this.backend, this.collector, {this.now = DateTime.now});
  final Backend backend;
  final DeviceCollector collector;
  final DateTime Function() now;
  StreamSubscription<String>? _sub;
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
    if (on && !await collector.requestPermission(kind)) return false;
    final key = await deviceKey();
    final s = await current();
    final kinds = Map<String, DeviceKindSettings>.of(s?.kinds ?? const {});
    if (on) {
      kinds[kind.value] = settings ?? kinds[kind.value] ?? DeviceKindSettings();
    } else {
      kinds.remove(kind.value);
    }
    await backend.saveDeviceSource(key, name: s?.name ?? defaultName, platform: platform, kinds: kinds);
    if (on) await _upload(key, kind);
    return true;
  }

  (DateTime, DateTime) _window(DeviceKind kind) {
    final t = now();
    return switch (kind) {
      DeviceKind.calendar => (t.subtract(const Duration(days: 1)), t.add(const Duration(days: 30))),
      _ => (t.subtract(const Duration(days: 1)), t),
    };
  }

  Future<List<DeviceReadingInput>> _upload(String key, DeviceKind kind, {DateTime? from, DateTime? to, String? requestId}) async {
    final w = _window(kind);
    final readings = await collector.collect(kind, from ?? w.$1, to ?? w.$2);
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
        await _upload(s.deviceKey, kind);
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
          if (kind == null || !s.kinds.containsKey(r.kind) || !collector.supported.contains(kind)) {
            await backend.answerDeviceRequest(r.id, ok: false, error: '${r.kind} isn\'t shared from this device');
          } else if (r.action == DeviceRequestActionEnum.read) {
            final from = DateTime.tryParse('${r.params['from']}');
            final to = DateTime.tryParse('${r.params['to']}');
            await _upload(s.deviceKey, kind, from: from, to: to, requestId: r.id);
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
        unawaited(answerPending().catchError((_) {}));
        unawaited(syncAll().catchError((_) {}));
      },
    );
    unawaited(answerPending().catchError((_) {}));
    unawaited(syncAll().catchError((_) {}));
  }

  void dispose() {
    unawaited(_sub?.cancel());
    _sub = null;
    _life?.dispose();
    _life = null;
  }
}

final deviceCollectorProvider = Provider<DeviceCollector>((ref) => PluginDeviceCollector());

final deviceSyncProvider = Provider<DeviceSync>((ref) {
  final sync = DeviceSync(ref.watch(backendProvider), ref.watch(deviceCollectorProvider));
  ref.onDispose(sync.dispose);
  ref.listen(signedInProvider, (_, next) {
    if (next.value == true && sync.collector.supported.isNotEmpty) sync.start();
  }, fireImmediately: true);
  return sync;
});
