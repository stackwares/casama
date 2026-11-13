import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/backend.dart';
import '../../core/date_format.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/app_card.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/form_sheet.dart';
import '../timeline/timeline_screen.dart' show runStatusStyle;
import 'cron_words.dart';

/// A routine's latest runs, newest first (Improve app 1).
final routineRunsProvider = FutureProvider.autoDispose.family<List<RunSummary>, String>(
  (ref, routineId) => ref.watch(backendProvider).routineRuns(routineId),
);

/// Edit a routine: its name, instructions and when it runs, with its recent runs below
/// (Improve app 1). Event routines (webhook, calendar, message, device) keep their trigger; only
/// a repeating routine's schedule and a one-time routine's time can change here.
class EditRoutineSheet extends ConsumerStatefulWidget {
  const EditRoutineSheet({super.key, required this.routine});
  final Routine routine;

  @override
  ConsumerState<EditRoutineSheet> createState() => _EditRoutineSheetState();
}

class _EditRoutineSheetState extends ConsumerState<EditRoutineSheet> {
  late final _name = TextEditingController(text: widget.routine.name);
  late final _instructions = TextEditingController(text: widget.routine.instructionsMd);
  late final _cron = TextEditingController(text: widget.routine.scheduleCron ?? '');
  late final _timezone = TextEditingController(text: widget.routine.timezone);
  late DateTime _runAt = (widget.routine.nextRunAt ?? DateTime.now().add(const Duration(hours: 1))).toLocal();
  var _runAtChanged = false;
  var _busy = false;

  bool get _schedule => widget.routine.trigger == RoutineTrigger.schedule;
  bool get _once => widget.routine.trigger == RoutineTrigger.once;

  @override
  void dispose() {
    _name.dispose();
    _instructions.dispose();
    _cron.dispose();
    _timezone.dispose();
    super.dispose();
  }

  static bool _cronLooksValid(String cron) => cron.trim().split(RegExp(r'\s+')).length == 5;

  Future<void> _pickTime() async {
    unfocusBeforeModal();
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _runAt.isBefore(now) ? now : _runAt,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_runAt));
    if (time == null) return;
    setState(() {
      _runAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
      _runAtChanged = true;
    });
  }

  Future<void> _save() async {
    final r = widget.routine;
    String? changed(String now, String before) => now.trim() == before.trim() ? null : now.trim();
    final name = changed(_name.text, r.name);
    final instructions = changed(_instructions.text, r.instructionsMd);
    final cron = _schedule ? changed(_cron.text, r.scheduleCron ?? '') : null;
    final timezone = _schedule ? changed(_timezone.text, r.timezone) : null;
    final runAt = _once && _runAtChanged ? _runAt : null;
    if (name == null && instructions == null && cron == null && timezone == null && runAt == null) {
      Navigator.of(context).pop(false);
      return;
    }
    setState(() => _busy = true);
    final ok = await runGuarded(context, () async {
      await ref
          .read(backendProvider)
          .updateRoutine(r.id, name: name, instructions: instructions, scheduleCron: cron, timezone: timezone, runAt: runAt);
      return true;
    });
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok == true) {
      showSuccess(context, context.l10n.routineSaved);
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final valid =
        _name.text.trim().isNotEmpty &&
        _instructions.text.trim().isNotEmpty &&
        (!_schedule || (_cronLooksValid(_cron.text) && _timezone.text.trim().isNotEmpty)) &&
        (!_once || !_runAtChanged || _runAt.isAfter(DateTime.now()));
    final runs = ref.watch(routineRunsProvider(widget.routine.id));
    return FormSheet(
      icon: LucideIcons.pencil,
      title: l10n.routineEditTitle,
      subtitle: l10n.routineEditSubtitle,
      submitLabel: l10n.save,
      submitKey: const Key('saveRoutine'),
      busy: _busy,
      onSubmit: valid && !_busy ? _save : null,
      children: [
        TextField(
          key: const Key('editRoutineName'),
          controller: _name,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(labelText: l10n.routineName),
          onChanged: (_) => setState(() {}),
        ),
        TextField(
          key: const Key('editRoutineInstructions'),
          controller: _instructions,
          minLines: 3,
          maxLines: 8,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(labelText: l10n.routineInstructions, hintText: l10n.routineInstructionsHint, alignLabelWithHint: true),
          onChanged: (_) => setState(() {}),
        ),
        if (_schedule) ...[
          TextField(
            key: const Key('editRoutineCron'),
            controller: _cron,
            decoration: InputDecoration(
              labelText: l10n.cronExpression,
              helperText: _cronLooksValid(_cron.text) ? scheduleWords(context, _cron.text.trim()) : l10n.cronHelp,
            ),
            onChanged: (_) => setState(() {}),
          ),
          TextField(
            key: const Key('editRoutineTimezone'),
            controller: _timezone,
            decoration: InputDecoration(labelText: l10n.timezone),
            onChanged: (_) => setState(() {}),
          ),
        ],
        if (_once)
          ListTile(
            key: const Key('editRoutineRunAt'),
            contentPadding: EdgeInsets.zero,
            leading: const Icon(LucideIcons.calendarClock),
            title: Text(l10n.routineRunsAt),
            trailing: Text(
              '${_runAt.formattedWeekdayDate(context)} · ${_runAt.formattedTime(context)}',
              style: context.textTheme.bodyLarge?.copyWith(color: scheme.primary, fontWeight: FontWeight.w600),
            ),
            onTap: _pickTime,
          ),
        Text(l10n.routineRecentRuns, style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        runs.when(
          loading: () => const SkeletonText(widthFactor: 0.6),
          error: (_, _) => Text(l10n.somethingWentWrong, style: TextStyle(color: scheme.error)),
          data: (list) => list.isEmpty
              ? Text(l10n.routineNoRuns, key: const Key('routineNoRuns'), style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant))
              : Column(
                  key: const Key('routineRuns'),
                  children: [
                    for (final run in list) _RunRow(run: run, botId: widget.routine.botId),
                  ],
                ),
        ),
      ],
    );
  }
}

class _RunRow extends StatelessWidget {
  const _RunRow({required this.run, required this.botId});
  final RunSummary run;
  final String botId;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final (label, color, icon) = runStatusStyle(context, run.status);
    return InkWell(
      key: Key('routineRun-${run.id}'),
      borderRadius: BorderRadius.circular(AppRadius.icon),
      onTap: () {
        final router = GoRouter.maybeOf(context);
        Navigator.of(context).pop();
        router?.push('/bots/$botId/runs/${run.id}');
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
        child: Row(
          children: [
            StatusLabel(text: label, color: color, pill: true, icon: icon),
            const SizedBox(width: AppSpace.sm),
            Expanded(child: TimeAgo(run.createdAt, style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant))),
            Text(
              formatUsd(run.costUsd, context.l10n.localeName),
              style: context.textTheme.labelMedium?.copyWith(fontFeatures: AppText.tabular, color: scheme.onSurfaceVariant),
            ),
            Icon(LucideIcons.chevronRight, size: 16, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
