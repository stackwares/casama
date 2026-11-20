import 'dart:async';

import 'package:casama_sdk/casama_sdk.dart' show DevicePermissions;
import 'package:material_ui/material_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/backend.dart';
import '../../core/widgets.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../theme/app_colors.dart';
import 'os_permissions.dart';
import 'permissions_reporter.dart';

/// One device's permissions as they change (D-376): the server's copy, polled every few seconds,
/// and, when the device is this one, what this app just checked.
class PermissionsLive extends ChangeNotifier {
  PermissionsLive({required this.backend, required this.reporter, required this.ids, this.deviceRef, this.interval = const Duration(seconds: 3)});

  final Backend backend;
  final PermissionsReporter reporter;

  /// The device shown; null is this device.
  final String? deviceRef;

  /// The permissions shown; polling stops once every one is on.
  final List<String> ids;
  final Duration interval;

  List<DevicePermissions> devices = const [];
  Set<String> mine = const {};
  var loaded = false;
  Timer? _timer;
  var _watching = false;
  var _disposed = false;

  /// Whether [deviceRef] is this device (always, when null).
  bool get isThisDevice => deviceRef == null || mine.contains(deviceRef);

  /// The server's row for the device shown: [deviceRef], or this device's computer.
  DevicePermissions? get device {
    final ref = deviceRef;
    if (ref != null) return devices.where((d) => d.deviceRef == ref).firstOrNull;
    return devices.where((d) => mine.contains(d.deviceRef) && d.deviceRef.startsWith('computer:')).firstOrNull ?? devices.where((d) => mine.contains(d.deviceRef)).firstOrNull;
  }

  /// One of the caller's own devices (anyone else's card is read only).
  bool get isOwner => deviceRef == null || isThisDevice || devices.any((d) => d.deviceRef == deviceRef);

  /// The platform of the device shown.
  String platformOr(String fallback) => device?.platform ?? (isThisDevice ? reporter.platform.platform : fallback);

  String? state(String id) {
    if (isThisDevice) {
      final local = reporter.states.value[id];
      if (local != null) return local;
    }
    return device?.permissions[id]?.value;
  }

  bool get allOn => ids.every((id) => permissionOn(state(id)) || osPermission(id) == null);

  Future<void> start() async {
    reporter.reports.addListener(_onReport);
    reporter.states.addListener(_changed);
    await load();
    if (_disposed) return;
    if (isThisDevice) {
      _watching = true;
      reporter.watch();
      unawaited(reporter.report().catchError((_) {}));
    }
    _timer = Timer.periodic(interval, (_) {
      final life = WidgetsBinding.instance.lifecycleState;
      if (allOn || (life != null && life != AppLifecycleState.resumed)) return;
      unawaited(load());
    });
  }

  void _onReport() => unawaited(load());
  void _changed() {
    if (!_disposed) notifyListeners();
  }

  Future<void> load() async {
    try {
      final results = await Future.wait<Object>([backend.devicePermissions(), reporter.refs()]);
      if (_disposed) return;
      devices = results[0] as List<DevicePermissions>;
      mine = results[1] as Set<String>;
    } catch (_) {
      // Offline for a moment: keep what was shown.
    }
    loaded = true;
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    reporter.reports.removeListener(_onReport);
    reporter.states.removeListener(_changed);
    if (_watching) reporter.unwatch();
    super.dispose();
  }
}

/// What a row says about its state.
String permissionStateText(AppLocalizations l10n, String id, String? state) {
  if (osPermission(id) == null) return l10n.permStateUpdate;
  return switch (state) {
    PermissionState.granted => l10n.permStateOn,
    PermissionState.limited => l10n.permStateLimited,
    PermissionState.denied || PermissionState.restricted => l10n.permStateOff,
    PermissionState.notAsked => l10n.permStateNotAsked,
    PermissionState.unavailable => l10n.permStateUnavailable,
    _ => l10n.permStateUnknown,
  };
}

/// One permission: its name, state and the button that turns it on (D-376).
class PermissionRow extends StatelessWidget {
  const PermissionRow({
    super.key,
    required this.id,
    required this.platform,
    required this.state,
    this.note,
    this.busy = false,
    this.enabled = true,
    this.needsRestart = false,
    this.onTurnOn,
    this.onRestart,
  });

  final String id;
  final String platform;
  final String? state;

  /// A line under the row: "Opened on MacBook Pro", "… is offline".
  final String? note;
  final bool busy;

  /// False on someone else's card: no buttons.
  final bool enabled;

  /// Just turned on, but takes effect after Casama restarts.
  final bool needsRestart;
  final VoidCallback? onTurnOn;
  final VoidCallback? onRestart;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final scheme = context.colorScheme;
    final known = osPermission(id) != null;
    final ask = permissionAsk(id, platform);
    final on = permissionOn(state);
    final available = known && ask != null && state != PermissionState.unavailable;
    final text = known && ask == null ? l10n.permStateUnavailable : permissionStateText(l10n, id, state);
    Widget? button;
    if (enabled && needsRestart && onRestart != null) {
      button = OutlinedButton(key: Key('permRestart-$id'), onPressed: busy ? null : onRestart, child: Text(l10n.permRestart));
    } else if (enabled && available && !on && onTurnOn != null) {
      final label = switch (ask) {
        PermissionAsk.casama => l10n.permChoose,
        PermissionAsk.prompt when state == PermissionState.notAsked || state == null || state == PermissionState.unknown => l10n.permTurnOn,
        // HealthKit's switches live in the Health app, not in Settings.
        _ when id == 'health' && permissionPlatformOf(platform) == 'ios' => l10n.permOpenHealth,
        _ => l10n.permOpenSettings,
      };
      button = FilledButton.tonal(key: Key('permTurnOn-$id'), onPressed: busy ? null : onTurnOn, child: Text(label));
    }
    return Padding(
      key: Key('permRow-$id'),
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(on ? LucideIcons.circleCheck : (available ? LucideIcons.circle : LucideIcons.circleSlash), size: 18, color: on ? colors.positive : scheme.onSurfaceVariant),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(osPermissionLabel(l10n, id), style: context.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                    Text(
                      needsRestart ? l10n.permRestartToFinish : text,
                      key: Key('permState-$id'),
                      style: context.textTheme.bodySmall?.copyWith(color: on && !needsRestart ? colors.positive : scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              if (button != null) ...[const SizedBox(width: 8), button],
            ],
          ),
          if (note != null)
            Padding(
              padding: const EdgeInsets.only(left: 28, top: 4),
              child: Text(
                note!,
                key: Key('permNote-$id'),
                style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
        ],
      ),
    );
  }
}
