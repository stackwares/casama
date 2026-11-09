import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kasama_sdk/kasama_sdk.dart';

import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/app_card.dart';
import '../../ui/segmented.dart';
import '../../ui/shell_header.dart';

/// A bot's routines: one-time, repeating (cron in a timezone), or webhook-triggered.
class RoutinesScreen extends ConsumerWidget {
  const RoutinesScreen({super.key, required this.botId});
  final String botId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: ShellHeader(
        title: l10n.routines,
        actions: [HeaderIconButton(key: const Key('newRoutine'), icon: Icons.add_rounded, tooltip: l10n.newRoutine, onPressed: () => _create(context, ref))],
      ),
      body: AsyncView(
        value: ref.watch(routinesProvider(botId)),
        onRetry: () => ref.invalidate(routinesProvider(botId)),
        data: (items) => items.isEmpty
            ? EmptyState(
                icon: Icons.schedule_rounded,
                title: l10n.noRoutines,
                message: l10n.noRoutinesHelp,
                action: FilledButton.icon(onPressed: () => _create(context, ref), icon: const Icon(Icons.add_rounded), label: Text(l10n.newRoutine)),
              )
            : LayoutBuilder(builder: (context, constraints) {
                final side = AppSpace.gutter + AppBreakpoints.centeringInset(constraints.maxWidth, maxWidth: 720);
                return ListView.separated(
                  padding: EdgeInsets.fromLTRB(side, AppSpace.xs, side, AppSpace.xl + MediaQuery.paddingOf(context).bottom),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: AppSpace.xs),
                  itemBuilder: (context, i) => _RoutineCard(routine: items[i]).appListItemEntrance(i),
                );
              }),
      ),
    );
  }

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final created = await showAdaptiveSheet<CreatedRoutine>(context: context, builder: (_) => NewRoutineSheet(botId: botId));
    if (created == null || !context.mounted) return;
    ref.invalidate(routinesProvider(botId));
    if (created.webhookUrl != null) {
      final l10n = context.l10n;
      await showDialog<void>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(l10n.webhookCreated),
          content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l10n.webhookShownOnce),
            const SizedBox(height: 12),
            SelectableText('${l10n.webhookUrl}: ${created.webhookUrl}'),
            const SizedBox(height: 8),
            SelectableText('${l10n.webhookSecret}: ${created.webhookSecret ?? ''}', key: const Key('webhookSecret')),
          ]),
          actions: [
            TextButton(onPressed: () => Clipboard.setData(ClipboardData(text: created.webhookSecret ?? '')), child: Text(l10n.copySecret)),
            FilledButton(onPressed: () => Navigator.pop(c), child: Text(l10n.close)),
          ],
        ),
      );
    }
  }
}

String _formatWhen(BuildContext context, DateTime t) {
  final local = t.toLocal();
  return '${MaterialLocalizations.of(context).formatMediumDate(local)} · ${TimeOfDay.fromDateTime(local).format(context)}';
}

class _RoutineCard extends ConsumerWidget {
  const _RoutineCard({required this.routine});
  final Routine routine;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final ok = await showConfirm(
      context: context,
      title: l10n.deleteRoutineTitle(routine.name),
      message: l10n.deleteRoutineBody,
      confirmLabel: l10n.delete,
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    await runGuarded(context, () => ref.read(backendProvider).deleteRoutine(routine.id));
    ref.invalidate(routinesProvider(routine.botId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final r = routine;
    final (icon, schedule) = switch (r.trigger) {
      RoutineTrigger.schedule => (Icons.repeat_rounded, l10n.routineSchedule(r.scheduleCron ?? '', r.timezone)),
      RoutineTrigger.once => (Icons.alarm_rounded, l10n.routineOnce),
      RoutineTrigger.github => (Icons.code_rounded, l10n.routineGithub),
      RoutineTrigger.webhook => (Icons.webhook_rounded, l10n.routineWebhook),
    };
    final next = r.enabled && r.nextRunAt != null ? l10n.nextRun(_formatWhen(context, r.nextRunAt!)) : null;
    final last = r.lastRunAt != null ? l10n.lastRun(_formatWhen(context, r.lastRunAt!)) : null;
    final tint = r.enabled ? scheme.primary : scheme.onSurfaceVariant;
    return AppCard(
      key: Key('routine-${r.id}'),
      padding: const EdgeInsets.fromLTRB(AppSpace.md, 14, AppSpace.xs, 14),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(color: tint.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppRadius.icon)),
          alignment: Alignment.center,
          child: Icon(icon, size: 20, color: tint),
        ),
        const SizedBox(width: AppSpace.sm),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(r.name, style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(schedule, style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
            if (next != null || last != null || !r.enabled) ...[
              const SizedBox(height: 6),
              Wrap(spacing: AppSpace.xs, runSpacing: 4, children: [
                if (!r.enabled) StatusLabel(text: l10n.routineOff, color: scheme.onSurfaceVariant, pill: true),
                if (next != null) StatusLabel(text: next, color: context.appColors.positive, pill: true, icon: Icons.schedule_rounded),
                if (last != null) Text(last, style: context.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
              ]),
            ],
          ]),
        ),
        Switch(
          key: Key('routineEnabled-${r.id}'),
          value: r.enabled,
          onChanged: (v) async {
            await runGuarded(context, () => ref.read(backendProvider).setRoutineEnabled(r.id, v));
            ref.invalidate(routinesProvider(r.botId));
          },
        ),
        MenuAnchor(
          alignmentOffset: const Offset(-120, 0),
          menuChildren: [
            MenuItemButton(
              key: Key('runRoutine-${r.id}'),
              leadingIcon: const Icon(Icons.play_arrow_rounded, size: 20),
              onPressed: () async {
                final runId = await runGuarded(context, () => ref.read(backendProvider).runRoutine(r.id));
                if (runId != null && context.mounted) {
                  final router = GoRouter.maybeOf(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(l10n.routineStarted),
                    action: router == null ? null : SnackBarAction(label: l10n.viewRun, onPressed: () => router.go('/bots/${r.botId}/runs/$runId')),
                  ));
                }
              },
              child: Text(l10n.runNow),
            ),
            MenuItemButton(
              key: Key('deleteRoutine-${r.id}'),
              leadingIcon: Icon(Icons.delete_outline_rounded, size: 20, color: scheme.error),
              onPressed: () => _delete(context, ref),
              child: Text(l10n.delete, style: TextStyle(color: scheme.error)),
            ),
          ],
          builder: (context, controller, _) => IconButton(
            key: Key('routineMenu-${r.id}'),
            tooltip: l10n.moreActions,
            icon: const Icon(Icons.more_vert_rounded),
            onPressed: () => controller.isOpen ? controller.close() : controller.open(),
          ),
        ),
      ]),
    );
  }
}

/// Common schedules so people don't have to write cron by hand.
const schedulePresets = <(String, String)>[
  ('0 7 * * *', 'everyDayAt7'),
  ('0 9 * * 1-5', 'weekdaysAt9'),
  ('0 * * * *', 'everyHour'),
  ('0 9 * * 1', 'mondaysAt9'),
];

class NewRoutineSheet extends ConsumerStatefulWidget {
  const NewRoutineSheet({super.key, required this.botId});
  final String botId;

  @override
  ConsumerState<NewRoutineSheet> createState() => _NewRoutineSheetState();
}

class _NewRoutineSheetState extends ConsumerState<NewRoutineSheet> {
  final _name = TextEditingController();
  final _instructions = TextEditingController();
  final _cron = TextEditingController(text: schedulePresets.first.$1);
  final _timezone = TextEditingController(text: DateTime.now().timeZoneName.contains('/') ? DateTime.now().timeZoneName : 'America/Chicago');
  var _trigger = 'once';
  DateTime _runAt = DateTime.now().add(const Duration(hours: 1));
  var _busy = false;

  @override
  void dispose() {
    for (final c in [_name, _instructions, _cron, _timezone]) {
      c.dispose();
    }
    super.dispose();
  }

  String _presetLabel(String key) {
    final l10n = context.l10n;
    return switch (key) {
      'everyDayAt7' => l10n.everyDayAt7,
      'weekdaysAt9' => l10n.weekdaysAt9,
      'everyHour' => l10n.everyHour,
      _ => l10n.mondaysAt9,
    };
  }

  Future<void> _pickTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _runAt,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_runAt));
    if (time == null) return;
    setState(() => _runAt = DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final valid = _name.text.trim().isNotEmpty && _instructions.text.trim().isNotEmpty && (_trigger != 'once' || _runAt.isAfter(DateTime.now()));
    final now = DateTime.now();
    final tomorrow9 = DateTime(now.year, now.month, now.day + 1, 9);
    final quick = <(String, DateTime)>[
      (l10n.inMinutes(15), now.add(const Duration(minutes: 15))),
      (l10n.inHours(1), now.add(const Duration(hours: 1))),
      (l10n.tomorrowAt9, tomorrow9),
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(AppSpace.lg, 0, AppSpace.lg, AppSpace.md),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(l10n.newRoutine, style: context.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.3)),
        const SizedBox(height: AppSpace.md),
        TextField(
          key: const Key('routineName'),
          controller: _name,
          decoration: InputDecoration(labelText: l10n.routineName),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppSpace.sm),
        TextField(
          key: const Key('routineInstructions'),
          controller: _instructions,
          decoration: InputDecoration(labelText: l10n.routineInstructions, hintText: l10n.routineInstructionsHint),
          maxLines: 4,
          minLines: 2,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppSpace.md),
        AppSegmentedControl<String>(
          values: const ['once', 'schedule', 'github', 'webhook'],
          labels: {'once': l10n.triggerOnce, 'schedule': l10n.triggerSchedule, 'github': l10n.triggerGithub, 'webhook': l10n.triggerWebhook},
          groupValue: _trigger,
          onValueChanged: (v) => setState(() => _trigger = v),
        ),
        if (_trigger == 'once') ...[
          const SizedBox(height: AppSpace.sm),
          Wrap(spacing: 8, runSpacing: 4, children: [
            for (final q in quick)
              ChoiceChip(
                label: Text(q.$1),
                selected: (_runAt.difference(q.$2).inMinutes).abs() < 1,
                onSelected: (_) => setState(() => _runAt = q.$2),
              ),
          ]),
          const SizedBox(height: AppSpace.xs),
          OutlinedButton.icon(
            key: const Key('routineRunAt'),
            onPressed: _pickTime,
            icon: const Icon(Icons.event_rounded, size: 18),
            label: Text(_formatWhen(context, _runAt)),
          ),
        ],
        if (_trigger == 'schedule') ...[
          const SizedBox(height: AppSpace.sm),
          Wrap(spacing: 8, runSpacing: 4, children: [
            for (final p in schedulePresets)
              ChoiceChip(label: Text(_presetLabel(p.$2)), selected: _cron.text == p.$1, onSelected: (_) => setState(() => _cron.text = p.$1)),
          ]),
          const SizedBox(height: AppSpace.sm),
          TextField(
            key: const Key('routineCron'),
            controller: _cron,
            decoration: InputDecoration(labelText: l10n.cronExpression, helperText: l10n.cronHelp),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpace.sm),
          TextField(key: const Key('routineTimezone'), controller: _timezone, decoration: InputDecoration(labelText: l10n.timezone)),
        ],
        const SizedBox(height: AppSpace.md),
        FilledButton(
          key: const Key('createRoutine'),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
          onPressed: _busy || !valid
              ? null
              : () async {
                  setState(() => _busy = true);
                  final created = await runGuarded(
                    context,
                    () => ref.read(backendProvider).createRoutine(
                          widget.botId,
                          name: _name.text.trim(),
                          instructions: _instructions.text.trim(),
                          trigger: _trigger,
                          cron: _cron.text.trim(),
                          runAt: _runAt,
                          timezone: _timezone.text.trim().isEmpty ? null : _timezone.text.trim(),
                        ),
                  );
                  if (!context.mounted) return;
                  setState(() => _busy = false);
                  if (created != null) Navigator.of(context).pop(created);
                },
          child: Text(l10n.create),
        ),
      ]),
    );
  }
}
