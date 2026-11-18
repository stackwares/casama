import '../../l10n/generated/app_localizations.dart';
import 'island_feed.dart';

/// The island on Windows and Linux (D-324, Phase 6): no notch, so the tray menu carries the feed.
/// Each run is a row (the bot and what it's doing) followed by its buttons, the same ones the Mac's
/// notch has: Stop while it works, Allow and Deny when it asks for an OK (a click in the menu, never
/// a hover), Open always. The tray's tooltip and title say what matters most. Kept as plain data so
/// it is tested without a tray; `desktop_shell.dart` turns it into the native menu.
class TrayEntry {
  const TrayEntry.row(this.label) : action = null;
  const TrayEntry.button(this.label, Map<String, Object?> this.action);

  /// What the menu shows. Buttons are indented under their row.
  final String label;

  /// The island action a click sends (island_bridge.dart, `action`); null for a row.
  final Map<String, Object?>? action;

  bool get isButton => action != null;

  @override
  String toString() => isButton ? '  $label → $action' : label;
}

String _row(IslandItem i, AppLocalizations l10n) {
  final what = switch (i.phase) {
    IslandPhase.needsOk => '${l10n.islandNeedsOk}: ${i.step}',
    IslandPhase.takeOver => i.step.isEmpty ? l10n.islandTakeOver : i.step,
    _ => i.step,
  };
  final here = i.onThisComputer ? ' (${l10n.islandOnThisComputer})' : '';
  return '${i.bot}: $what$here';
}

/// The menu's run rows and buttons, in the feed's order (needs you first).
List<TrayEntry> trayEntries(List<IslandItem> feed, AppLocalizations l10n) {
  if (feed.isEmpty) return [TrayEntry.row(l10n.islandNothing)];
  return [
    for (final i in feed) ...[
      TrayEntry.row(_row(i, l10n)),
      if (i.phase == IslandPhase.needsOk && i.approvalId != null) ...[
        TrayEntry.button(l10n.islandAllow, {'kind': 'allow', 'approval_id': i.approvalId}),
        TrayEntry.button(l10n.islandDeny, {'kind': 'deny', 'approval_id': i.approvalId}),
      ],
      if (i.phase == IslandPhase.working && i.runId != null)
        TrayEntry.button(l10n.islandStop, {'kind': 'stop', 'run_id': i.runId}),
      TrayEntry.button(l10n.islandOpen, {'kind': 'open', 'link': i.link}),
    ],
  ];
}

/// The tray's tooltip: the first row, or just "Casama".
String trayTooltip(List<IslandItem> feed, AppLocalizations l10n) => feed.isEmpty ? 'Casama' : _row(feed.first, l10n);

/// The tray's title beside the icon (Linux shows it; Windows ignores it): a dot and the bot while
/// something needs the person or a bot works, nothing at rest.
String? trayTitle(List<IslandItem> feed, AppLocalizations l10n) {
  if (feed.isEmpty) return null;
  final first = feed.first;
  if (first.phase == IslandPhase.needsOk || first.phase == IslandPhase.takeOver) {
    return '● ${l10n.islandNeedsYou}';
  }
  if (first.phase == IslandPhase.working) return '● ${first.bot}';
  return null;
}
