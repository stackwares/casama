import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/date_format.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../core/haptics.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/form_sheet.dart';

/// Check-ins for one bot (D-114): off by default; a morning brief and a scan every few hours.
final botCheckinsProvider = FutureProvider.family<BotCheckins, String>((ref, id) => ref.watch(backendProvider).botCheckins(id));

Future<void> showCheckins(BuildContext context, WidgetRef ref, String botId) async {
  final current = await runGuarded(context, () => ref.read(botCheckinsProvider(botId).future));
  if (current == null || !context.mounted) return;
  final next = await showAdaptiveSheet<BotCheckins>(context: context, builder: (_) => _CheckinsSheet(initial: current));
  if (next == null || !context.mounted) return;
  await runGuarded(context, () => ref.read(backendProvider).setBotCheckins(botId, next));
  ref.invalidate(botCheckinsProvider(botId));
}

class _CheckinsSheet extends StatefulWidget {
  const _CheckinsSheet({required this.initial});
  final BotCheckins initial;

  @override
  State<_CheckinsSheet> createState() => _CheckinsSheetState();
}

class _CheckinsSheetState extends State<_CheckinsSheet> {
  late var _enabled = widget.initial.enabled;
  late var _time = widget.initial.briefTime;
  late var _every = widget.initial.scanEveryHours;
  late final _cap = TextEditingController(text: widget.initial.dailyCapUsd.toStringAsFixed(2));

  @override
  void dispose() {
    _cap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cap = double.tryParse(_cap.text.trim());
    return FormSheet(
      icon: LucideIcons.sun,
      title: l10n.checkins,
      subtitle: l10n.checkinsHelp,
      submitLabel: l10n.save,
      submitKey: const Key('saveCheckins'),
      onSubmit: cap == null || cap <= 0
          ? null
          : () => Navigator.pop(context, BotCheckins(enabled: _enabled, briefTime: _time, scanEveryHours: _every, dailyCapUsd: cap)),
      children: [
        SwitchListTile(key: const Key('checkinsEnabled'), contentPadding: EdgeInsets.zero, title: Text(l10n.checkins), value: _enabled, onChanged: hapticOnChanged((v) => setState(() => _enabled = v))),
        OutlinedButton.icon(
          key: const Key('briefTime'),
          onPressed: !_enabled
              ? null
              : () async {
                  unfocusBeforeModal();
                  final p = _time.split(':').map(int.parse).toList();
                  final t = await showTimePicker(context: context, initialTime: TimeOfDay(hour: p[0], minute: p[1]));
                  if (t != null) setState(() => _time = '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}');
                },
          icon: const Icon(LucideIcons.sunrise, size: 18),
          label: Text('${l10n.briefTime} ${formatClockTime(context, _time)}'),
        ),
        DropdownButtonFormField<int>(
          isExpanded: true,
          key: const Key('scanEvery'),
          initialValue: _every,
          decoration: InputDecoration(labelText: l10n.scanEvery),
          items: [for (final h in const [1, 2, 3, 4, 6, 12]) DropdownMenuItem(value: h, child: Text(l10n.hours(h)))],
          onChanged: hapticOnChanged(!_enabled ? null : (v) => setState(() => _every = v ?? 3), haptic: HapticsHelper.selection),
        ),
        TextField(
          key: const Key('dailyCap'),
          controller: _cap,
          enabled: _enabled,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: l10n.dailyCap, prefixText: r'$ '),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }
}
