import 'dart:async';

import 'package:casama_sdk/casama_sdk.dart' show DevicePermissionType;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../ui/action_buttons.dart';
import '../../ui/glow_button.dart';
import '../chat/widgets/chat_look.dart';
import 'os_permissions.dart';
import 'permissions_reporter.dart';
import 'permissions_request.dart';

export 'permissions_request.dart';
import 'permissions_view.dart';

/// Turns on what a device is missing, from where it's tapped (D-376): on that device it asks the
/// system there; on another one it sends the ask to that device (a computer opens the page at
/// once, a phone gets a notification to tap). Rows update as the device reports.
mixin PermissionActions<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  PermissionsLive get live;
  String get fallbackPlatform;
  String get deviceName;
  String? get botId;

  final notes = <String, String>{};
  final busy = <String>{};

  /// Relaunch-kind permissions turned on while this was showing: Casama restarts to finish.
  final restart = <String>{};
  Map<String, String?> _seen = {};

  /// Notes rows that just turned on and need a restart. Call from the live model's listener.
  void trackRestarts(Iterable<String> ids) {
    final platform = live.platformOr(fallbackPlatform);
    final now = {for (final id in ids) id: live.state(id)};
    for (final id in ids) {
      final before = _seen[id];
      if (_seen.containsKey(id) && !permissionOn(before) && permissionOn(now[id]) && permissionNeedsRelaunch(id, platform)) restart.add(id);
    }
    _seen = now;
  }

  Future<void> turnOn(String id, {bool relaunch = false}) async {
    final l10n = context.l10n;
    final platform = live.platformOr(fallbackPlatform);
    final action = relaunch ? 'relaunch' : (permissionAsk(id, platform) == PermissionAsk.prompt ? 'request' : 'open_settings');
    setState(() {
      busy.add(id);
      notes.remove(id);
    });
    String? note;
    if (live.isThisDevice) {
      final reporter = ref.read(permissionsReporterProvider);
      await runGuarded(context, () => reporter.perform(id, action));
      if (relaunch) restart.remove(id);
    } else {
      final device = live.device;
      final ref0 = live.deviceRef!;
      if (device != null && device.type == DevicePermissionType.computer && !device.online) {
        note = l10n.permOffline(deviceName);
      } else {
        final via = await runGuarded(context, () => ref.read(backendProvider).askDevicePermission(ref0, id, action, botId: botId));
        if (via != null) {
          if (relaunch) restart.remove(id);
          note = via == 'socket' ? (relaunch ? l10n.permRestarting(deviceName) : l10n.permOpenedOn(deviceName)) : l10n.permSentTo(deviceName);
        }
      }
    }
    if (!mounted) return;
    setState(() {
      busy.remove(id);
      if (note != null) notes[id] = note;
    });
    unawaited(live.load());
  }

  Widget rowFor(String id, {required bool enabled}) => PermissionRow(
    id: id,
    platform: live.platformOr(fallbackPlatform),
    state: live.state(id),
    note: notes[id],
    busy: busy.contains(id),
    enabled: enabled,
    needsRestart: restart.contains(id),
    onTurnOn: () => turnOn(id),
    onRestart: () => turnOn(id, relaunch: true),
  );
}

class PermissionsCard extends ConsumerStatefulWidget {
  const PermissionsCard({super.key, required this.request, required this.onContinue});
  final PermissionsRequest request;

  /// Sends the person's answer as their message (the bot carries on).
  final Future<void> Function(String text) onContinue;

  @override
  ConsumerState<PermissionsCard> createState() => _PermissionsCardState();
}

class _PermissionsCardState extends ConsumerState<PermissionsCard> with PermissionActions<PermissionsCard> {
  @override
  late final PermissionsLive live;

  /// Not now, or Continue: the card folds to one line.
  String? _done;
  var _sending = false;

  @override
  String get fallbackPlatform => widget.request.platform;
  @override
  String get deviceName => widget.request.deviceName;
  @override
  String? get botId => widget.request.botId;

  @override
  void initState() {
    super.initState();
    live = PermissionsLive(backend: ref.read(backendProvider), reporter: ref.read(permissionsReporterProvider), deviceRef: widget.request.deviceRef, ids: widget.request.permissions)
      ..addListener(_changed);
    unawaited(live.start());
  }

  void _changed() {
    if (!mounted) return;
    trackRestarts(widget.request.permissions);
    setState(() {});
  }

  @override
  void dispose() {
    live.removeListener(_changed);
    live.dispose();
    super.dispose();
  }

  Future<void> _notNow() async {
    setState(() => _sending = true);
    final ok = await runGuarded(context, () async {
      await ref.read(backendProvider).snoozeDevicePermissions(widget.request.deviceRef, widget.request.botId, widget.request.permissions);
      return true;
    });
    if (!mounted) return;
    setState(() {
      _sending = false;
      if (ok == true) _done = 'later';
    });
  }

  Future<void> _continue() async {
    final text = context.l10n.permContinueMessage;
    setState(() => _sending = true);
    final ok = await runGuarded(context, () async {
      await widget.onContinue(text);
      return true;
    });
    if (!mounted) return;
    setState(() {
      _sending = false;
      if (ok == true) _done = 'continued';
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final scheme = context.colorScheme;
    final r = widget.request;
    if (_done != null) {
      final later = _done == 'later';
      return Padding(
        key: const Key('chatPermissions'),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          children: [
            Icon(later ? LucideIcons.circleMinus : LucideIcons.circleCheck, size: 18, color: later ? scheme.onSurfaceVariant : colors.positive),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                later ? l10n.permNotNowLine : l10n.permContinuedLine,
                style: context.textTheme.labelLarge?.copyWith(color: later ? scheme.onSurfaceVariant : colors.positive, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );
    }
    final owner = !live.loaded || live.isOwner;
    final enabled = live.loaded && live.isOwner;
    return Container(
      key: const Key('chatPermissions'),
      padding: ChatLook.cardPadding,
      decoration: ChatLook.card(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(color: ChatLook.fieldFill(context), borderRadius: BorderRadius.circular(9)),
                alignment: Alignment.center,
                child: Icon(LucideIcons.shieldCheck, size: 17, color: colors.working),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.cardPermissions,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(l10n.permissionsTitle(r.deviceName), style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, height: 1.3)),
          if (r.reason.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(r.reason, style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant, height: 1.4)),
            ),
          const SizedBox(height: 10),
          for (final id in r.permissions) rowFor(id, enabled: enabled),
          if (!owner)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                l10n.permOnlyOwner(r.deviceName),
                key: const Key('permOnlyOwner'),
                style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
          const SizedBox(height: 14),
          if (owner)
            ActionButtons(
              actions: [
                OutlinedButton(key: const Key('permNotNow'), onPressed: _sending || !enabled ? null : _notNow, child: Text(l10n.notNow)),
                GlowButton.icon(
                  key: const Key('permContinue'),
                  onPressed: _sending || !enabled || !live.allOn || restart.isNotEmpty ? null : _continue,
                  icon: const Icon(LucideIcons.check, size: 18),
                  label: Text(l10n.permContinue),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
