import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/backend.dart';
import '../../core/date_format.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../core/haptics.dart';
import '../../theme/app_tokens.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/form_sheet.dart';

/// Quiet hours (D-109): pushes wait until the window ends; the inbox fills as usual. Urgent
/// approvals (from a chat you're in) still come through. Each bot can be let through or given its
/// own hours.

final quietHoursProvider = FutureProvider<QuietHoursView>((ref) async {
  if (ref.watch(signedInProvider).value == false) {
    return const QuietHoursView(enabled: false, start: '22:00', end: '07:00');
  }
  return ref.watch(backendProvider).quietHours();
});
final botQuietProvider = FutureProvider.family<BotQuietView, String>(
  (ref, botId) => ref.watch(backendProvider).botQuiet(botId),
);

String quietSummary(BuildContext context, QuietHoursView q) =>
    q.enabled ? context.l10n.quietHoursRange(formatClockTime(context, q.start), formatClockTime(context, q.end)) : context.l10n.off;

Future<void> showQuietHours(BuildContext context, WidgetRef ref) async {
  final current = await ref.read(quietHoursProvider.future);
  if (!context.mounted) return;
  final picked = await showAdaptiveSheet<QuietHoursView>(context: context, builder: (_) => _QuietSheet(initial: current, title: context.l10n.quietHours));
  if (picked == null || !context.mounted) return;
  await runGuarded(context, () => ref.read(backendProvider).setQuietHours(picked));
  ref.invalidate(quietHoursProvider);
}

Future<void> showBotQuiet(BuildContext context, WidgetRef ref, String botId) async {
  final l10n = context.l10n;
  final current = await ref.read(botQuietProvider(botId).future);
  if (!context.mounted) return;
  final mode = await showChoiceSheet<String>(
    context,
    title: l10n.botNotifications,
    subtitle: l10n.botNotificationsHelp,
    icon: LucideIcons.bellRing,
    selected: current.mode,
    choices: [
      Choice(value: 'default', label: l10n.quietDefault, icon: LucideIcons.moon),
      Choice(value: 'always', label: l10n.quietAlways, icon: LucideIcons.bellRing),
      Choice(value: 'custom', label: l10n.quietCustom, icon: LucideIcons.clock),
    ],
  );
  if (mode == null || !context.mounted) return;
  var hours = current.hours;
  if (mode.value == 'custom') {
    hours = await showAdaptiveSheet<QuietHoursView>(
      context: context,
      builder: (_) => _QuietSheet(initial: current.hours ?? const QuietHoursView(enabled: true, start: '22:00', end: '07:00'), title: l10n.quietCustom),
    );
    if (hours == null || !context.mounted) return;
  }
  await runGuarded(context, () => ref.read(backendProvider).setBotQuiet(botId, BotQuietView(mode: mode.value, hours: hours)));
  ref.invalidate(botQuietProvider(botId));
}

class _QuietSheet extends StatefulWidget {
  const _QuietSheet({required this.initial, required this.title});
  final QuietHoursView initial;
  final String title;

  @override
  State<_QuietSheet> createState() => _QuietSheetState();
}

class _QuietSheetState extends State<_QuietSheet> {
  late var _enabled = widget.initial.enabled;
  late var _start = widget.initial.start;
  late var _end = widget.initial.end;

  Future<void> _pick(bool start) async {
    final parts = (start ? _start : _end).split(':').map(int.parse).toList();
    final t = await showTimePicker(context: context, initialTime: TimeOfDay(hour: parts[0], minute: parts[1]));
    if (t == null) return;
    final v = '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    setState(() => start ? _start = v : _end = v);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FormSheet(
      icon: LucideIcons.moon,
      title: widget.title,
      subtitle: l10n.quietHoursHelp,
      submitLabel: l10n.save,
      submitKey: const Key('saveQuiet'),
      onSubmit: _start == _end ? null : () => Navigator.pop(context, QuietHoursView(enabled: _enabled, start: _start, end: _end)),
      children: [
        SwitchListTile(
          key: const Key('quietEnabled'),
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.quietHours),
          value: _enabled,
          onChanged: hapticOnChanged((v) => setState(() => _enabled = v)),
        ),
        Row(
          spacing: AppSpace.sm,
          children: [
            Expanded(
              child: OutlinedButton.icon(key: const Key('quietStart'), onPressed: _enabled ? () => _pick(true) : null, icon: const Icon(LucideIcons.moon, size: 18), label: Text('${l10n.from} ${formatClockTime(context, _start)}')),
            ),
            Expanded(
              child: OutlinedButton.icon(key: const Key('quietEnd'), onPressed: _enabled ? () => _pick(false) : null, icon: const Icon(LucideIcons.sun, size: 18), label: Text('${l10n.until} ${formatClockTime(context, _end)}')),
            ),
          ],
        ),
      ],
    );
  }
}
