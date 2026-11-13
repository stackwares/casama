import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/date_format.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../core/haptics.dart';
import '../../theme/app_colors.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/app_card.dart';
import '../../ui/form_sheet.dart';
import '../../ui/property_row.dart';

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
        GroupedCard(
          children: [
            GroupedTile(
              icon: LucideIcons.sun,
              title: l10n.checkins,
              onTap: () {
                HapticsHelper.light();
                setState(() => _enabled = !_enabled);
              },
              trailing: Switch(key: const Key('checkinsEnabled'), value: _enabled, onChanged: hapticOnChanged((v) => setState(() => _enabled = v))),
            ),
            GroupedTile(
              key: const Key('briefTime'),
              icon: LucideIcons.sunrise,
              title: l10n.briefTime,
              onTap: !_enabled
                  ? null
                  : () async {
                      unfocusBeforeModal();
                      final p = _time.split(':').map(int.parse).toList();
                      final t = await showTimePicker(context: context, initialTime: TimeOfDay(hour: p[0], minute: p[1]));
                      if (t != null) setState(() => _time = '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}');
                    },
              trailing: Text(
                formatClockTime(context, _time),
                style: context.textTheme.bodyLarge?.copyWith(color: context.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600),
              ),
            ),
            PropertyRow<int>(
              key: const Key('scanEvery'),
              icon: LucideIcons.radar,
              title: l10n.scanEvery,
              value: l10n.hours(_every),
              // Off: no menu, the row just shows the value.
              options: !_enabled
                  ? const []
                  : [for (final h in const [1, 2, 3, 4, 6, 12]) PropertyOption(value: h, label: l10n.hours(h), selected: h == _every)],
              onSelected: (v) => setState(() => _every = v),
            ),
          ],
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
