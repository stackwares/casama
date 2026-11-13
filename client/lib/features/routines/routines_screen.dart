import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/display_text.dart';
import '../../core/date_format.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../core/haptics.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/bottom_padding.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/advanced_section.dart';
import '../../ui/form_sheet.dart';
import '../../ui/app_card.dart';
import '../../ui/property_row.dart';
import '../../ui/page.dart';
import '../../ui/route_focus.dart';
import '../../ui/segmented.dart';
import '../../ui/shell_header.dart';
import '../../ui/glow_button.dart';
import '../bots/channels_screen.dart' show channelKindName;
import 'cron_words.dart';
import '../../ui/celebration.dart';
import '../../core/analytics.dart';
import 'routine_ideas.dart';
import 'edit_routine_sheet.dart';

/// A bot's routines: one-time, repeating (cron in a timezone), or webhook-triggered.
class RoutinesScreen extends ConsumerWidget {
  const RoutinesScreen({super.key, required this.botId});
  final String botId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    // A search result links here with `?focus=<routine>` (D-235): that card scrolls in and glows.
    final focus = routeFocus(context);
    return Scaffold(
      appBar: ShellHeader(
        title: l10n.routines,
        actions: [HeaderIconButton(key: const Key('newRoutine'), icon: LucideIcons.plus, tooltip: l10n.newRoutine, onPressed: () => _create(context, ref))],
      ),
      body: AsyncView(
        value: ref.watch(routinesProvider(botId)),
        onRetry: () => ref.invalidate(routinesProvider(botId)),
        loading: SkeletonPage(
          children: [for (var i = 0; i < 4; i++) Padding(padding: EdgeInsets.only(top: i == 0 ? 0 : AppSpace.xs), child: _RoutineCardSkeleton(titleWidth: 0.4 + (i % 3) * 0.1))],
        ),
        data: (items) => items.isEmpty
            ? EmptyState(
                icon: LucideIcons.clock,
                title: l10n.noRoutines,
                message: l10n.noRoutinesHelp,
                action: GlowButton.icon(onPressed: () => _create(context, ref), icon: const Icon(LucideIcons.plus), label: Text(l10n.newRoutine)),
              )
            : LayoutBuilder(
                builder: (context, constraints) {
                  final side = AppSpace.gutter + AppBreakpoints.centeringInset(constraints.maxWidth, maxWidth: kPageMaxWidth);
                  return ListView.separated(
                    padding: EdgeInsets.fromLTRB(side, AppSpace.xs, side, AppSpace.xl + MediaQuery.paddingOf(context).bottom),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: AppSpace.xs),
                    itemBuilder: (context, i) => FocusHighlight(
                      active: items[i].id == focus,
                      child: _RoutineCard(routine: items[i]),
                    ).appListItemEntrance(i),
                  );
                },
              ),
      ),
    );
  }

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final created = await showAdaptiveSheet<CreatedRoutine>(
      context: context,
      contentPadsBottom: true,
      builder: (_) => NewRoutineSheet(botId: botId),
    );
    if (created == null || !context.mounted) return;
    ref.invalidate(routinesProvider(botId));
    // A webhook routine opens its address next instead; that's the moment there.
    if (!created.webhookUrl.isUsable) showCelebration(context, context.l10n.celebrateNewRoutine(created.name));
    if (created.webhookUrl.isUsable) {
      final l10n = context.l10n;
      await showAdaptiveSheet<void>(
        context: context,
        builder: (c) {
          final colors = c.appColors;
          Widget field(String label, String value, {Key? key}) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: c.textTheme.labelMedium?.copyWith(color: c.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.codeBackground,
                  borderRadius: BorderRadius.circular(AppRadius.row),
                  border: Border.all(color: colors.hairline),
                ),
                child: SelectableText(value, key: key, style: AppText.mono.copyWith(fontSize: 13)),
              ),
            ],
          );
          return FormSheet(
            icon: LucideIcons.webhook,
            title: l10n.webhookCreated,
            subtitle: l10n.webhookShownOnce,
            submitLabel: l10n.copySecret,
            submitIcon: LucideIcons.copy,
            cancelLabel: l10n.close,
            onSubmit: () {
              Clipboard.setData(ClipboardData(text: created.webhookSecret ?? ''));
              showMessage(c, l10n.copied);
            },
            children: [
              field(l10n.webhookUrl, created.webhookUrl.orPlaceholder()),
              field(l10n.webhookSecret, created.webhookSecret.orPlaceholder(), key: const Key('webhookSecret')),
            ],
          );
        },
      );
    }
  }
}

String _formatWhen(BuildContext context, DateTime t) {
  final local = t.toLocal();
  return '${local.formattedWeekdayDate(context)} · ${local.formattedTime(context)}';
}

/// A [_RoutineCard] still loading: the trigger tile, name, schedule and next-run pill, the switch
/// and the menu button.
class _RoutineCardSkeleton extends StatelessWidget {
  const _RoutineCardSkeleton({required this.titleWidth});
  final double titleWidth;

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;
    return SkeletonCard(
      padding: const EdgeInsets.fromLTRB(AppSpace.md, 14, AppSpace.xs, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonBone(width: 38, height: 38, radius: AppRadius.icon),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                SkeletonText(style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700), widthFactor: titleWidth),
                const SizedBox(height: 2),
                SkeletonText(style: text.bodySmall, widthFactor: 0.7),
                const SizedBox(height: 6),
                const Align(alignment: AlignmentDirectional.centerStart, child: SkeletonBone(width: 150, height: 22, radius: AppRadius.pill)),
              ],
            ),
          ),
          const SizedBox(width: 60, height: 48, child: Center(child: SkeletonBone(width: 52, height: 32, radius: AppRadius.pill))),
          const SizedBox(width: 48, height: 48, child: Center(child: SkeletonBone(width: 4, height: 16, radius: 2))),
        ],
      ),
    );
  }
}

class _RoutineCard extends ConsumerWidget {
  const _RoutineCard({required this.routine});
  final Routine routine;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final ok = await showConfirm(context: context, title: l10n.deleteRoutineTitle(routine.name), message: l10n.deleteRoutineBody, confirmLabel: l10n.delete, destructive: true);
    if (!ok || !context.mounted) return;
    await runGuarded(context, () => ref.read(backendProvider).deleteRoutine(routine.id));
    ref.invalidate(routinesProvider(routine.botId));
  }

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    final saved = await showAdaptiveSheet<bool>(context: context, builder: (_) => EditRoutineSheet(routine: routine));
    if (saved == true) ref.invalidate(routinesProvider(routine.botId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final r = routine;
    final (icon, schedule) = switch (r.trigger) {
      RoutineTrigger.schedule => (LucideIcons.repeat, l10n.routineSchedule(scheduleWords(context, r.scheduleCron.orPlaceholder()), r.timezone)),
      RoutineTrigger.once => (LucideIcons.alarmClock, l10n.routineOnce),
      RoutineTrigger.github => (LucideIcons.codeXml, l10n.routineGithub),
      RoutineTrigger.webhook => (LucideIcons.webhook, l10n.routineWebhook),
      RoutineTrigger.calendarEvent => (LucideIcons.calendarClock, l10n.routineCalendar(r.calendar?.offsetMinutes ?? 0)),
      RoutineTrigger.message => (LucideIcons.mailOpen, l10n.routineMessage),
      RoutineTrigger.device => (LucideIcons.smartphone, l10n.routineDevice(r.device?.event.value.replaceAll('_', ' ') ?? '', r.device?.place ?? r.device?.app ?? r.device?.folder ?? '')),
    };
    final next = r.enabled && r.nextRunAt != null ? l10n.nextRun(_formatWhen(context, r.nextRunAt!)) : null;
    final last = r.lastRunAt != null ? l10n.lastRun(relativeTime(r.lastRunAt!, context)) : null;
    // Routines that end (D-262): when, or how many runs are left.
    final ends = r.endsAt != null ? l10n.routineEndsAt(_formatWhen(context, r.endsAt!)) : null;
    final runsLeft = r.maxRuns != null ? l10n.routineRunsLeft((r.maxRuns! - (r.runCount ?? 0)).clamp(0, r.maxRuns!)) : null;
    final tint = r.enabled ? scheme.primary : scheme.onSurfaceVariant;
    return AppCard(
      key: Key('routine-${r.id}'),
      onTap: () => _edit(context, ref),
      padding: const EdgeInsets.fromLTRB(AppSpace.md, 14, AppSpace.xs, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: tint.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppRadius.icon)),
            alignment: Alignment.center,
            child: Icon(icon, size: 20, color: tint),
          ),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.name, style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(schedule, style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                if (next != null || last != null || ends != null || runsLeft != null || !r.enabled) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: AppSpace.xs,
                    runSpacing: 4,
                    children: [
                      if (!r.enabled) StatusLabel(text: l10n.routineOff, color: scheme.onSurfaceVariant, pill: true),
                      if (next != null) StatusLabel(text: next, color: context.appColors.positive, pill: true, icon: LucideIcons.clock),
                      if (ends != null) StatusLabel(key: Key('routineEndsAt-${r.id}'), text: ends, color: scheme.onSurfaceVariant, pill: true, icon: LucideIcons.flag),
                      if (runsLeft != null) StatusLabel(key: Key('routineRunsLeft-${r.id}'), text: runsLeft, color: scheme.onSurfaceVariant, pill: true, icon: LucideIcons.hash),
                      if (last != null) Text(last, style: context.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Switch(
            key: Key('routineEnabled-${r.id}'),
            value: r.enabled,
            onChanged: hapticOnChanged((v) async {
              await runGuarded(context, () => ref.read(backendProvider).setRoutineEnabled(r.id, v));
              ref.invalidate(routinesProvider(r.botId));
            }),
          ),
          MenuAnchor(
            alignmentOffset: const Offset(-120, 0),
            menuChildren: [
              MenuItemButton(
                key: Key('runRoutine-${r.id}'),
                leadingIcon: const Icon(LucideIcons.play, size: 20),
                onPressed: () async {
                  Analytics.feature('routines_run_now');
                  final runId = await runGuarded(context, () => ref.read(backendProvider).runRoutine(r.id));
                  if (runId != null && context.mounted) {
                    final router = GoRouter.maybeOf(context);
                    HapticsHelper.success();
                    showToast(
                      context,
                      l10n.routineStarted,
                      kind: ToastKind.success,
                      action: router == null ? null : SnackBarAction(label: l10n.viewRun, onPressed: () => router.push('/bots/${r.botId}/runs/$runId')),
                    );
                  }
                },
                child: Text(l10n.runNow),
              ),
              MenuItemButton(
                key: Key('editRoutine-${r.id}'),
                leadingIcon: const Icon(LucideIcons.pencil, size: 20),
                onPressed: () => _edit(context, ref),
                child: Text(l10n.edit),
              ),
              if (r.trigger != RoutineTrigger.once)
                MenuItemButton(
                  key: Key('routineEnd-${r.id}'),
                  leadingIcon: const Icon(LucideIcons.flag, size: 20),
                  onPressed: () async {
                    final saved = await showAdaptiveSheet<bool>(context: context, builder: (_) => RoutineEndSheet(routine: r));
                    if (saved == true) ref.invalidate(routinesProvider(r.botId));
                  },
                  child: Text(l10n.routineChangeEnd),
                ),
              MenuItemButton(
                key: Key('deleteRoutine-${r.id}'),
                leadingIcon: Icon(LucideIcons.trash2, size: 20, color: scheme.error),
                onPressed: () => _delete(context, ref),
                child: Text(l10n.delete, style: TextStyle(color: scheme.error)),
              ),
            ],
            builder: (context, controller, _) => IconButton(
              key: Key('routineMenu-${r.id}'),
              tooltip: l10n.moreActions,
              icon: const Icon(LucideIcons.ellipsisVertical),
              onPressed: () => controller.isOpen ? controller.close() : controller.open(),
            ),
          ),
        ],
      ),
    );
  }
}

/// How often a repeating routine runs, picked without cron (D-182). Each writes a cron string.
const repeatChoices = ['daily', 'weekdays', 'weekly', 'hourly'];

/// The triggers most people use; GitHub and webhooks wait under Advanced (D-182).
const _mainTriggers = ['once', 'schedule', 'calendar_event', 'message'];
const _advancedTriggers = ['github', 'webhook'];

class NewRoutineSheet extends ConsumerStatefulWidget {
  const NewRoutineSheet({super.key, required this.botId});
  final String botId;

  @override
  ConsumerState<NewRoutineSheet> createState() => _NewRoutineSheetState();
}

class _NewRoutineSheetState extends ConsumerState<NewRoutineSheet> {
  final _name = TextEditingController();
  final _instructions = TextEditingController();
  final _cron = TextEditingController(text: '0 9 * * *');
  final _timezone = TextEditingController(text: DateTime.now().timeZoneName.contains('/') ? DateTime.now().timeZoneName : 'America/Chicago');
  var _trigger = 'once';
  // Repeats (D-182): how often and when, written into [_cron]. Null while the cron typed under
  // Advanced is something the picker can't show (it reads as custom, in words).
  String? _repeat = 'daily';
  var _time = const TimeOfDay(hour: 9, minute: 0);
  var _weekday = 1;
  // Calendar triggers (D-132)
  String? _calendarId;
  var _offset = -15;
  var _outsideGuests = false;
  var _videoLink = false;
  final _titleMatch = TextEditingController();
  // Message triggers (D-134)
  MessageTriggerConfigChannelKindEnum? _msgKind = MessageTriggerConfigChannelKindEnum.email;
  final _msgSender = TextEditingController();
  final _msgSubject = TextEditingController();
  final _msgText = TextEditingController();
  DateTime _runAt = DateTime.now().add(const Duration(hours: 1));
  // How a repeating or event routine ends (D-262).
  var _end = RoutineEnd.never;
  DateTime _endsAt = RoutineEnd.defaultDate();
  var _maxRuns = 5;
  var _busy = false;

  @override
  void dispose() {
    for (final c in [_name, _instructions, _cron, _timezone, _titleMatch]) {
      c.dispose();
    }
    super.dispose();
  }

  String _repeatLabel(String key) {
    final l10n = context.l10n;
    return switch (key) {
      'daily' => l10n.routineRepeatDaily,
      'weekdays' => l10n.routineRepeatWeekdays,
      'weekly' => l10n.routineRepeatWeekly,
      _ => l10n.everyHour,
    };
  }

  /// The picker's choice as cron.
  void _writeCron() {
    final (m, h) = (_time.minute, _time.hour);
    _cron.text = switch (_repeat) {
      'hourly' => '0 * * * *',
      'weekdays' => '$m $h * * 1-5',
      'weekly' => '$m $h * * $_weekday',
      _ => '$m $h * * *',
    };
  }

  /// A cron typed by hand: the picker follows when it can show it, and reads as custom otherwise.
  void _readCron() {
    final shape = parseCron(_cron.text);
    _repeat = switch (shape) {
      CronDaily() => 'daily',
      CronWeekly(weekdays: true) => 'weekdays',
      CronWeekly(:final days) when days.length == 1 => 'weekly',
      CronHourly(minute: 0) => 'hourly',
      _ => null,
    };
    if (shape case CronDaily(:final hour, :final minute) || CronWeekly(:final hour, :final minute)) _time = TimeOfDay(hour: hour, minute: minute);
    if (shape case CronWeekly(:final days) when days.length == 1) _weekday = days.single;
  }

  /// Fills the sheet from a gallery idea (D-241); everything stays editable.
  void _useIdea(RoutineIdea idea) {
    setState(() {
      _name.text = idea.name;
      _instructions.text = idea.instructionsMd;
      _cron.text = idea.scheduleCron;
      _trigger = 'schedule';
      _readCron();
    });
  }

  Future<void> _pickRepeatTime() async {
    unfocusBeforeModal();
    final time = await showTimePicker(context: context, initialTime: _time);
    if (time == null || !mounted) return;
    setState(() {
      _time = time;
      _writeCron();
    });
  }

  Future<void> _pickTime() async {
    unfocusBeforeModal();
    final date = await showDatePicker(context: context, initialDate: _runAt, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_runAt));
    if (time == null) return;
    setState(() => _runAt = DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final calendars = (ref.watch(integrationsProvider).value ?? const <Integration>[]).where((i) => i.appId == 'google_calendar' || i.name.contains('calendar') || i.name.contains('outlook')).toList();
    _calendarId ??= calendars.firstOrNull?.id;
    final valid =
        _name.text.trim().isNotEmpty &&
        _instructions.text.trim().isNotEmpty &&
        (_trigger != 'once' || _runAt.isAfter(DateTime.now())) &&
        (_trigger == 'once' || _end != RoutineEnd.onDate || _endsAt.isAfter(DateTime.now())) &&
        (_trigger != 'schedule' || _cron.text.trim().isNotEmpty) &&
        (_trigger != 'calendar_event' || _calendarId != null) &&
        (_trigger != 'message' || _msgKind != null || [_msgSender, _msgSubject, _msgText].any((c) => c.text.trim().isNotEmpty));
    final now = DateTime.now();
    final tomorrow9 = DateTime(now.year, now.month, now.day + 1, 9);
    final quick = <(String, DateTime)>[(l10n.inMinutes(15), now.add(const Duration(minutes: 15))), (l10n.inHours(1), now.add(const Duration(hours: 1))), (l10n.tomorrowAt9, tomorrow9)];
    VoidCallback? create;
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(AppSpace.lg, 0, AppSpace.lg, BottomPadding.of(context, minimum: AppSpace.md)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.newRoutine, style: context.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.3)),
          const SizedBox(height: AppSpace.md),
          RoutineIdeasStrip(onPick: _useIdea),
          TextField(
            key: const Key('routineName'),
            controller: _name,
            textInputAction: TextInputAction.next,
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
            values: _mainTriggers,
            labels: {'once': l10n.triggerOnce, 'schedule': l10n.triggerSchedule, 'calendar_event': l10n.triggerCalendar, 'message': l10n.triggerMessage},
            // An Advanced trigger stays picked (and shown below) until one of these is tapped.
            groupValue: _trigger,
            onValueChanged: (v) => setState(() => _trigger = v),
          ),
          if (_trigger == 'once') ...[
            const SizedBox(height: AppSpace.sm),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [for (final q in quick) ChoiceChip(label: Text(q.$1), selected: (_runAt.difference(q.$2).inMinutes).abs() < 1, onSelected: (_) => setState(() => _runAt = q.$2))],
            ),
            const SizedBox(height: AppSpace.sm),
            GroupedCard(
              children: [
                GroupedTile(
                  key: const Key('routineRunAt'),
                  icon: LucideIcons.calendarClock,
                  title: l10n.routineRunsAt,
                  onTap: _pickTime,
                  trailing: _ValueText(_formatWhen(context, _runAt)),
                ),
              ],
            ),
          ],
          if (_trigger == 'calendar_event') ...[
            const SizedBox(height: AppSpace.sm),
            if (calendars.isEmpty)
              Text(l10n.calendarTriggerNeedsCalendar, key: const Key('noCalendar'))
            else ...[
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final m in const [-30, -15, -5, 0, 15])
                    ChoiceChip(key: Key('offset$m'), label: Text(l10n.calendarOffset(m)), selected: _offset == m, onSelected: (_) => setState(() => _offset = m)),
                ],
              ),
              const SizedBox(height: AppSpace.sm),
              GroupedCard(
                children: [
                  PropertyRow<String>(
                    key: const Key('routineCalendar'),
                    icon: LucideIcons.calendar,
                    title: l10n.calendarTriggerCalendar,
                    value: calendars.where((c) => c.id == _calendarId).firstOrNull?.name ?? '',
                    options: [for (final c in calendars) PropertyOption(value: c.id, label: c.name, selected: c.id == _calendarId)],
                    onSelected: (v) => setState(() => _calendarId = v),
                  ),
                  GroupedTile(
                    icon: LucideIcons.usersRound,
                    title: l10n.calendarOutsideGuests,
                    onTap: () => setState(() => _outsideGuests = !_outsideGuests),
                    trailing: Switch(
                      key: const Key('routineOutsideGuests'),
                      value: _outsideGuests,
                      onChanged: hapticOnChanged((v) => setState(() => _outsideGuests = v), haptic: HapticsHelper.soft),
                    ),
                  ),
                  GroupedTile(
                    icon: LucideIcons.video,
                    title: l10n.calendarVideoLink,
                    onTap: () => setState(() => _videoLink = !_videoLink),
                    trailing: Switch(
                      value: _videoLink,
                      onChanged: hapticOnChanged((v) => setState(() => _videoLink = v), haptic: HapticsHelper.soft),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.sm),
              TextField(
                controller: _titleMatch,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => create?.call(),
                decoration: InputDecoration(labelText: l10n.calendarTitleMatch),
              ),
            ],
          ],
          if (_trigger == 'message') ...[
            const SizedBox(height: AppSpace.sm),
            Text(l10n.messageTriggerHelp),
            const SizedBox(height: AppSpace.sm),
            GroupedCard(
              children: [
                PropertyRow<MessageTriggerConfigChannelKindEnum?>(
                  key: const Key('messageKind'),
                  icon: LucideIcons.messagesSquare,
                  title: l10n.chatAppsKind,
                  value: _msgKind == null ? l10n.messageTriggerAnyApp : _kindName(_msgKind!),
                  options: [
                    PropertyOption(value: null, label: l10n.messageTriggerAnyApp, selected: _msgKind == null),
                    for (final k in MessageTriggerConfigChannelKindEnum.values) PropertyOption(value: k, label: _kindName(k), selected: k == _msgKind),
                  ],
                  onSelected: (v) => setState(() => _msgKind = v),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.sm),
            TextField(
              key: const Key('messageSender'),
              controller: _msgSender,
              textInputAction: TextInputAction.next,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(labelText: l10n.messageTriggerSender),
            ),
            const SizedBox(height: AppSpace.sm),
            TextField(
              key: const Key('messageSubject'),
              controller: _msgSubject,
              textInputAction: TextInputAction.next,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(labelText: l10n.messageTriggerSubject),
            ),
            const SizedBox(height: AppSpace.sm),
            TextField(
              key: const Key('messageText'),
              controller: _msgText,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => create?.call(),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(labelText: l10n.messageTriggerWords),
            ),
          ],
          if (_trigger == 'schedule') ...[
            const SizedBox(height: AppSpace.sm),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final r in repeatChoices)
                  ChoiceChip(
                    key: Key('repeat-$r'),
                    label: Text(_repeatLabel(r)),
                    selected: _repeat == r,
                    onSelected: (_) => setState(() {
                      _repeat = r;
                      _writeCron();
                    }),
                  ),
              ],
            ),
            if (_repeat == null) ...[
              const SizedBox(height: AppSpace.xs),
              Text(
                l10n.routineCustomSchedule(scheduleWords(context, _cron.text)),
                key: const Key('routineCustomSchedule'),
                style: context.textTheme.bodyMedium?.copyWith(color: context.colorScheme.onSurfaceVariant),
              ),
            ] else if (_repeat != 'hourly') ...[
              const SizedBox(height: AppSpace.sm),
              GroupedCard(
                children: [
                  if (_repeat == 'weekly')
                    PropertyRow<int>(
                      key: const Key('routineWeekday'),
                      icon: LucideIcons.calendarDays,
                      title: l10n.routineDay,
                      value: l10n.cronDay(cronDayKey(_weekday)),
                      options: [for (final d in const [1, 2, 3, 4, 5, 6, 0]) PropertyOption(value: d, label: l10n.cronDay(cronDayKey(d)), selected: d == _weekday)],
                      onSelected: (v) => setState(() {
                        _weekday = v;
                        _writeCron();
                      }),
                    ),
                  GroupedTile(
                    key: const Key('routineTime'),
                    icon: LucideIcons.clock,
                    title: l10n.routineTimeLabel,
                    onTap: _pickRepeatTime,
                    trailing: _ValueText(_time.format(context)),
                  ),
                ],
              ),
            ],
            if (_timezone.text.trim().isNotEmpty) ...[
              const SizedBox(height: AppSpace.xs),
              Text(
                l10n.routineTimesIn(_timezone.text.trim()),
                key: const Key('routineTimesIn'),
                style: context.textTheme.bodySmall?.copyWith(color: context.colorScheme.onSurfaceVariant),
              ),
            ],
          ],
          if (_trigger != 'once') ...[
            const SizedBox(height: AppSpace.sm),
            RoutineEndPicker(
              end: _end,
              endsAt: _endsAt,
              maxRuns: _maxRuns,
              onChanged: (end, endsAt, maxRuns) => setState(() {
                _end = end;
                _endsAt = endsAt;
                _maxRuns = maxRuns;
              }),
            ),
          ],
          // GitHub and webhook triggers, the raw cron and the timezone (D-182). It stays open while
          // one of them is in use, so the routine's current setup is never folded away.
          AdvancedSection(
            id: 'routine.editor',
            summary: l10n.routineAdvancedSummary,
            forceOpen: _advancedTriggers.contains(_trigger) || (_trigger == 'schedule' && _repeat == null),
            children: [
              Text(l10n.routineOtherTriggers, style: context.textTheme.labelLarge?.copyWith(color: context.colorScheme.onSurfaceVariant)),
              const SizedBox(height: AppSpace.xs),
              AppSegmentedControl<String>(
                key: const Key('routineAdvancedTrigger'),
                values: _advancedTriggers,
                labels: {'github': l10n.triggerGithub, 'webhook': l10n.triggerWebhook},
                groupValue: _trigger,
                onValueChanged: (v) => setState(() => _trigger = v),
              ),
              if (_trigger == 'schedule') ...[
                const SizedBox(height: AppSpace.sm),
                TextField(
                  key: const Key('routineCron'),
                  controller: _cron,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(labelText: l10n.cronExpression, helperText: l10n.cronHelp),
                  onChanged: (_) => setState(_readCron),
                ),
                const SizedBox(height: AppSpace.sm),
                TextField(
                  key: const Key('routineTimezone'),
                  controller: _timezone,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => create?.call(),
                  decoration: InputDecoration(labelText: l10n.timezone),
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpace.md),
          GlowButton(
            key: const Key('createRoutine'),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            // Also run by the keyboard's Done key on the last field.
            onPressed: create = _busy || !valid
                ? null
                : () async {
                    setState(() => _busy = true);
                    final created = await runGuarded(
                      context,
                      () => ref
                          .read(backendProvider)
                          .createRoutine(
                            widget.botId,
                            name: _name.text.trim(),
                            instructions: _instructions.text.trim(),
                            trigger: _trigger,
                            cron: _cron.text.trim(),
                            runAt: _runAt,
                            timezone: _timezone.text.trim().isEmpty ? null : _timezone.text.trim(),
                            calendar: _trigger == 'calendar_event' && _calendarId != null
                                ? CalendarTriggerConfig(
                                    integrationId: _calendarId!,
                                    offsetMinutes: _offset,
                                    outsideGuests: _outsideGuests ? true : null,
                                    hasVideoLink: _videoLink ? true : null,
                                    titleMatch: _titleMatch.text.trim().isEmpty ? null : _titleMatch.text.trim(),
                                  )
                                : null,
                            message: _trigger == 'message'
                                ? MessageTriggerConfig(
                                    channelKind: _msgKind,
                                    sender: _msgSender.text.trim().isEmpty ? null : _msgSender.text.trim(),
                                    subjectMatch: _msgSubject.text.trim().isEmpty ? null : _msgSubject.text.trim(),
                                    textMatch: _msgText.text.trim().isEmpty ? null : _msgText.text.trim(),
                                  )
                                : null,
                            endsAt: _trigger != 'once' && _end == RoutineEnd.onDate ? _endsAt : null,
                            maxRuns: _trigger != 'once' && _end == RoutineEnd.afterRuns ? _maxRuns : null,
                          ),
                    );
                    if (!context.mounted) return;
                    setState(() => _busy = false);
                    if (created != null) Navigator.of(context).pop(created);
                  },
            child: Text(l10n.create),
          ),
        ],
      ),
    );
  }
}

/// How a repeating or event routine ends (D-262).
enum RoutineEnd {
  never,
  onDate,
  afterRuns;

  /// A week from now, at the end of that day.
  static DateTime defaultDate() {
    final d = DateTime.now().add(const Duration(days: 7));
    return DateTime(d.year, d.month, d.day, 23, 59);
  }
}

const _runChoices = [1, 2, 3, 5, 7, 10, 14, 30];

/// The "Ends" rows: never, on a date (a last day and time), or after a number of runs.
class RoutineEndPicker extends StatelessWidget {
  const RoutineEndPicker({super.key, required this.end, required this.endsAt, required this.maxRuns, required this.onChanged});
  final RoutineEnd end;
  final DateTime endsAt;
  final int maxRuns;
  final void Function(RoutineEnd end, DateTime endsAt, int maxRuns) onChanged;

  Future<void> _pickDate(BuildContext context) async {
    unfocusBeforeModal();
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: endsAt.isAfter(now) ? endsAt : now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 2)),
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(endsAt));
    if (time == null) return;
    onChanged(end, DateTime(date.year, date.month, date.day, time.hour, time.minute), maxRuns);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    String label(RoutineEnd e) => switch (e) {
      RoutineEnd.never => l10n.routineEndsNever,
      RoutineEnd.onDate => l10n.routineEndsOnDate,
      RoutineEnd.afterRuns => l10n.routineEndsAfterRuns,
    };
    final runs = {..._runChoices, maxRuns}.toList()..sort();
    return GroupedCard(
      children: [
        PropertyRow<RoutineEnd>(
          key: const Key('routineEnds'),
          icon: LucideIcons.flag,
          title: l10n.routineEnds,
          value: label(end),
          options: [for (final e in RoutineEnd.values) PropertyOption(value: e, label: label(e), selected: e == end)],
          onSelected: (v) => onChanged(v, endsAt, maxRuns),
        ),
        if (end == RoutineEnd.onDate)
          GroupedTile(
            key: const Key('routineEndDate'),
            icon: LucideIcons.calendarX,
            title: l10n.routineEndDate,
            onTap: () => _pickDate(context),
            trailing: _ValueText(_formatWhen(context, endsAt)),
          ),
        if (end == RoutineEnd.afterRuns)
          PropertyRow<int>(
            key: const Key('routineMaxRuns'),
            icon: LucideIcons.hash,
            title: l10n.routineRunCountLabel,
            value: l10n.routineRunsCount(maxRuns),
            options: [for (final n in runs) PropertyOption(value: n, label: l10n.routineRunsCount(n), selected: n == maxRuns)],
            onSelected: (v) => onChanged(end, endsAt, v),
          ),
      ],
    );
  }
}

/// Changes when an existing routine ends (D-262). A new number of runs counts from now.
class RoutineEndSheet extends ConsumerStatefulWidget {
  const RoutineEndSheet({super.key, required this.routine});
  final Routine routine;

  @override
  ConsumerState<RoutineEndSheet> createState() => _RoutineEndSheetState();
}

class _RoutineEndSheetState extends ConsumerState<RoutineEndSheet> {
  late var _end = widget.routine.endsAt != null
      ? RoutineEnd.onDate
      : widget.routine.maxRuns != null
      ? RoutineEnd.afterRuns
      : RoutineEnd.never;
  late var _endsAt = widget.routine.endsAt?.toLocal() ?? RoutineEnd.defaultDate();
  late var _maxRuns = widget.routine.maxRuns != null ? (widget.routine.maxRuns! - (widget.routine.runCount ?? 0)).clamp(1, 10000) : 5;
  var _busy = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final valid = _end != RoutineEnd.onDate || _endsAt.isAfter(DateTime.now());
    return FormSheet(
      icon: LucideIcons.flag,
      title: l10n.routineEndTitle,
      subtitle: l10n.routineEndSubtitle,
      submitLabel: l10n.save,
      submitKey: const Key('saveRoutineEnd'),
      busy: _busy,
      onSubmit: !valid
          ? null
          : () async {
              setState(() => _busy = true);
              final ok = await runGuarded(context, () async {
                await ref
                    .read(backendProvider)
                    .setRoutineEnd(
                      widget.routine.id,
                      endsAt: _end == RoutineEnd.onDate ? _endsAt : null,
                      maxRuns: _end == RoutineEnd.afterRuns ? _maxRuns : null,
                    );
                return true;
              });
              if (!context.mounted) return;
              setState(() => _busy = false);
              if (ok == true) Navigator.of(context).pop(true);
            },
      children: [
        RoutineEndPicker(
          end: _end,
          endsAt: _endsAt,
          maxRuns: _maxRuns,
          onChanged: (end, endsAt, maxRuns) => setState(() {
            _end = end;
            _endsAt = endsAt;
            _maxRuns = maxRuns;
          }),
        ),
      ],
    );
  }
}

String _kindName(MessageTriggerConfigChannelKindEnum k) => channelKindName(ChannelKind.values.firstWhere((c) => c.value == k.value));

/// The current value at the end of a tappable row, in the accent color with a chevron.
class _ValueText extends StatelessWidget {
  const _ValueText(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(text, style: context.textTheme.bodyLarge?.copyWith(color: scheme.primary, fontWeight: FontWeight.w600)),
        const SizedBox(width: 4),
        Icon(LucideIcons.chevronRight, size: 16, color: scheme.onSurfaceVariant.withValues(alpha: 0.7)),
      ],
    );
  }
}
