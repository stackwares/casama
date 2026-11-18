import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/backend.dart';
import '../../core/providers.dart';
import '../../core/router.dart';
import '../companion/companion.dart';
import '../devices/device_sync.dart';
import 'companion_hook.dart';
import 'os_permissions.dart';
import 'permissions_platform.dart';

/// Keeps the server's copy of this device's system permissions current (D-376), and carries out
/// what a card asks this device to do.
///
/// This device can be two things the server knows: the computer it lends to bots (the companion's
/// local device, `computer:<id>`) and the device that shares data (`source:<id>`). Each gets the
/// whole map, checked without prompting: at start, on resume, after any action, and every 3 s
/// while something on screen shows this device's permissions.
class PermissionsReporter {
  PermissionsReporter({required this.backend, required this.platform, required this.computerId, required this.sourceId, required this.openCasamaSettings, this.interval = const Duration(seconds: 3)});

  final Backend backend;
  final PermissionsPlatform platform;

  /// The companion's local device id in the current workspace, if this computer is paired.
  final Future<String?> Function() computerId;

  /// This device's device_sources id, if it shares data.
  final Future<String?> Function() sourceId;

  /// Opens Casama's own Use this computer screen (shared folders, local tools).
  final void Function() openCasamaSettings;
  final Duration interval;

  /// Bumped after every report, so screens showing this device read the new states.
  final reports = ValueNotifier<int>(0);

  /// What this device last checked.
  final states = ValueNotifier<Map<String, String>>(const {});

  Timer? _timer;
  var _watchers = 0;
  var _foreground = true;
  Future<void>? _running;
  AppLifecycleListener? _life;

  Set<String>? _refs;
  DateTime? _refsAt;

  /// This device's refs (`computer:<id>`, `source:<id>`), looked up again after a minute (pairing
  /// and sharing change) or when [fresh].
  Future<Set<String>> refs({bool fresh = false}) async {
    final known = _refs;
    if (!fresh && known != null && DateTime.now().difference(_refsAt!) < const Duration(minutes: 1)) return known;
    final out = <String>{};
    try {
      final c = await computerId();
      if (c != null) out.add('computer:$c');
    } catch (_) {}
    try {
      final s = await sourceId();
      if (s != null) out.add('source:$s');
    } catch (_) {}
    _refs = out;
    _refsAt = DateTime.now();
    return out;
  }

  /// Ids this device reports: everything its platform has except Casama's own settings, which the
  /// server knows itself.
  List<String> get ids => [
    for (final id in permissionIdsFor(platform.platform))
      if (permissionAsk(id, platform.platform) != PermissionAsk.casama) id,
  ];

  /// Checks and sends; one at a time.
  Future<void> report() => _running ??= _report().whenComplete(() => _running = null);

  Future<void> _report() async {
    final ids = this.ids;
    if (ids.isEmpty) return;
    final now = await platform.check(ids);
    states.value = now;
    for (final ref in await refs()) {
      try {
        await backend.reportDevicePermissions(ref, now);
      } catch (e) {
        debugPrint('permissions report $ref failed: $e');
      }
    }
    reports.value++;
  }

  /// Something on screen shows this device's permissions: check every few seconds until [unwatch].
  void watch() {
    _watchers++;
    _schedule();
  }

  void unwatch() {
    if (_watchers > 0) _watchers--;
    _schedule();
  }

  void _schedule() {
    final want = _watchers > 0 && _foreground;
    if (want && _timer == null) {
      _timer = Timer.periodic(interval, (_) => unawaited(report().catchError((_) {})));
    } else if (!want) {
      _timer?.cancel();
      _timer = null;
    }
  }

  /// Does what a card asked: [action] is request, open_settings or relaunch.
  Future<String?> perform(String id, String action) async {
    String? state;
    final ask = permissionAsk(id, platform.platform);
    if (action == 'relaunch') {
      await platform.relaunch();
      return null;
    }
    if (ask == PermissionAsk.casama) {
      openCasamaSettings();
    } else if (action == 'open_settings' || ask == PermissionAsk.settings) {
      await platform.openSettings(id);
    } else {
      state = await platform.request(id);
    }
    unawaited(report().catchError((_) {}));
    return state;
  }

  /// The companion's socket message from another device's card.
  Future<void> onCompanionMessage(Map<String, dynamic> m) async {
    final id = m['permission'];
    final action = m['do'];
    if (id is! String || action is! String) return;
    await perform(id, action);
  }

  void start() {
    companionPermissionHandler = onCompanionMessage;
    _life ??= AppLifecycleListener(
      onResume: () {
        _foreground = true;
        _schedule();
        unawaited(report().catchError((_) {}));
      },
      onHide: () {
        _foreground = false;
        _schedule();
      },
    );
    unawaited(report().catchError((_) {}));
  }

  void dispose() {
    if (companionPermissionHandler == onCompanionMessage) companionPermissionHandler = null;
    _timer?.cancel();
    _timer = null;
    _life?.dispose();
    _life = null;
  }
}

final permissionsReporterProvider = Provider<PermissionsReporter>((ref) {
  final reporter = PermissionsReporter(
    backend: ref.watch(backendProvider),
    platform: ref.watch(permissionsPlatformProvider),
    computerId: () async {
      final org = ref.read(currentOrgProvider);
      if (org == null || !ref.read(companionProvider).supported) return null;
      return (await ref.read(deviceTokenStoreProvider).read(org.id))?.$1;
    },
    sourceId: () async => (await ref.read(deviceSyncProvider).current())?.id,
    openCasamaSettings: () => ref.read(routerProvider).push('/settings/companion'),
  );
  ref.onDispose(reporter.dispose);
  ref.listen(signedInProvider, (_, next) {
    if (next.value == true) reporter.start();
  }, fireImmediately: true);
  return reporter;
});
