import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kasama_sdk/kasama_sdk.dart';

import '../../core/providers.dart';
import '../../core/widgets.dart';

/// A bot's routines: scheduled (cron in a timezone) or webhook-triggered.
class RoutinesScreen extends ConsumerWidget {
  const RoutinesScreen({super.key, required this.botId});
  final String botId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.routines)),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('newRoutine'),
        onPressed: () => _create(context, ref),
        icon: const Icon(Icons.add),
        label: Text(l10n.newRoutine),
      ),
      body: AsyncView(
        value: ref.watch(routinesProvider(botId)),
        onRetry: () => ref.invalidate(routinesProvider(botId)),
        data: (items) => items.isEmpty
            ? EmptyState(icon: Icons.schedule, message: l10n.noRoutines)
            : ListView(children: [for (final r in items) _RoutineTile(routine: r)]),
      ),
    );
  }

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final created = await showModalBottomSheet<CreatedRoutine>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => NewRoutineSheet(botId: botId),
    );
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
            TextButton(
              onPressed: () => Clipboard.setData(ClipboardData(text: created.webhookSecret ?? '')),
              child: Text(l10n.copySecret),
            ),
            FilledButton(onPressed: () => Navigator.pop(c), child: Text(l10n.close)),
          ],
        ),
      );
    }
  }
}

class _RoutineTile extends ConsumerWidget {
  const _RoutineTile({required this.routine});
  final Routine routine;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final r = routine;
    final when = switch (r.trigger) {
      RoutineTrigger.schedule => l10n.routineSchedule(r.scheduleCron ?? '', r.timezone),
      RoutineTrigger.github => l10n.routineGithub,
      RoutineTrigger.webhook => l10n.routineWebhook,
    };
    final next = r.nextRunAt == null ? null : MaterialLocalizations.of(context).formatShortDate(r.nextRunAt!.toLocal());
    final nextTime = r.nextRunAt == null ? null : TimeOfDay.fromDateTime(r.nextRunAt!.toLocal()).format(context);
    return ListTile(
      key: Key('routine-${r.id}'),
      leading: Icon(r.trigger == RoutineTrigger.schedule ? Icons.schedule : Icons.webhook),
      title: Text(r.name),
      subtitle: Text([when, if (r.enabled && next != null) l10n.nextRun('$next $nextTime')].join('\n')),
      isThreeLine: r.enabled && next != null,
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        IconButton(
          key: Key('runRoutine-${r.id}'),
          tooltip: l10n.runNow,
          icon: const Icon(Icons.play_arrow),
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
        ),
        Switch(
          key: Key('routineEnabled-${r.id}'),
          value: r.enabled,
          onChanged: (v) async {
            await runGuarded(context, () => ref.read(backendProvider).setRoutineEnabled(r.id, v));
            ref.invalidate(routinesProvider(r.botId));
          },
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
  var _trigger = 'schedule';
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final valid = _name.text.trim().isNotEmpty && _instructions.text.trim().isNotEmpty;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.viewInsetsOf(context).bottom + 16),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(l10n.newRoutine, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          TextField(
            key: const Key('routineName'),
            controller: _name,
            decoration: InputDecoration(labelText: l10n.routineName),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          TextField(
            key: const Key('routineInstructions'),
            controller: _instructions,
            decoration: InputDecoration(labelText: l10n.routineInstructions, hintText: l10n.routineInstructionsHint),
            maxLines: 4,
            minLines: 2,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            segments: [
              ButtonSegment(value: 'schedule', label: Text(l10n.triggerSchedule), icon: const Icon(Icons.schedule)),
              ButtonSegment(value: 'github', label: Text(l10n.triggerGithub)),
              ButtonSegment(value: 'webhook', label: Text(l10n.triggerWebhook)),
            ],
            selected: {_trigger},
            onSelectionChanged: (v) => setState(() => _trigger = v.first),
          ),
          if (_trigger == 'schedule') ...[
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 4, children: [
              for (final p in schedulePresets)
                ChoiceChip(
                  label: Text(_presetLabel(p.$2)),
                  selected: _cron.text == p.$1,
                  onSelected: (_) => setState(() => _cron.text = p.$1),
                ),
            ]),
            const SizedBox(height: 8),
            TextField(
              key: const Key('routineCron'),
              controller: _cron,
              decoration: InputDecoration(labelText: l10n.cronExpression, helperText: l10n.cronHelp),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            TextField(key: const Key('routineTimezone'), controller: _timezone, decoration: InputDecoration(labelText: l10n.timezone)),
          ],
          const SizedBox(height: 16),
          FilledButton(
            key: const Key('createRoutine'),
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
      ),
    );
  }
}
