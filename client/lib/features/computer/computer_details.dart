import 'package:casama_sdk/casama_sdk.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/widgets.dart';

/// What a computer card says about the machine (D-227): its system and size, what bots may use
/// on a personal computer, and when it was last active.

/// "512 MB", "1 GB", "1.5 GB".
String memoryLabel(num mb) {
  if (mb < 1024) return '${mb.round()} MB';
  final gb = mb / 1024;
  return gb == gb.roundToDouble() ? '${gb.round()} GB' : '${gb.toStringAsFixed(1)} GB';
}

/// "Ubuntu 24.04 · 1 CPU · 1 GB RAM · 10 GB disk" for a cloud computer; "macOS 26.2 · This
/// device" for a personal one. Empty when nothing is known.
String computerSystemLine(BuildContext context, Computer c, {required bool thisDevice}) {
  final l10n = context.l10n;
  final s = c.size;
  return [
    if (c.os case final os? when os.isNotEmpty) os,
    if (c.kind == ComputerKindEnum.local && thisDevice) l10n.thisDevice,
    if (c.kind != ComputerKindEnum.local) ...[
      if (s.cpus case final n? when n > 0) l10n.computerCpus(n.round()),
      if (s.memoryMb case final mb? when mb > 0) l10n.computerMemory(memoryLabel(mb)),
      if (s.diskGb case final gb? when gb > 0) l10n.computerDisk('${gb.round()} GB'),
    ],
  ].join(' · ');
}

/// What bots may use on a personal computer, or null when the server didn't say.
String? computerAccessLine(BuildContext context, Computer c) {
  final caps = c.device?.capabilities;
  if (caps == null) return null;
  final l10n = context.l10n;
  final names = [
    if (caps.files == true) l10n.computerCapFiles,
    if (caps.shell == true) l10n.computerCapShell,
    if (caps.browser == true) l10n.computerCapBrowser,
    if (caps.desktop == true) l10n.computerCapDesktop,
    if (caps.mcp == true) l10n.computerCapMcp,
    if (caps.messages == true) l10n.computerCapMessages,
  ];
  return names.isEmpty ? l10n.computerCanUseNothing : l10n.computerCanUse(names.join(', '));
}

/// "Last used 2 hours ago" for a computer that isn't on; "Last seen 5 minutes ago" for a personal
/// computer that isn't connected. Null while it's on, or when it never was.
String? computerActivityLine(BuildContext context, Computer c) {
  final on = c.state == ComputerState.running || c.state == ComputerState.idle;
  if (on || c.state == ComputerState.error) return null;
  if (c.kind == ComputerKindEnum.local) {
    final seen = c.device?.lastSeenAt ?? c.lastActiveAt;
    return seen == null ? null : context.l10n.computerLastSeen(relativeTime(seen, context));
  }
  final used = c.lastActiveAt;
  return used == null ? null : context.l10n.computerLastUsed(relativeTime(used, context));
}
