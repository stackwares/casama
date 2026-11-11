import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/display_text.dart';
import '../../core/number_format.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../core/haptics.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/bottom_padding.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/edge_fade.dart';
import '../../ui/reveal_when_selected.dart';
import '../../ui/app_card.dart';
import '../../ui/form_sheet.dart';
import '../../ui/page.dart';
import '../../ui/tab_reselect.dart';
import '../projects/projects_screen.dart' show projectsProvider;

/// The Tasks tab, the ticket board (D-098): filters, a ticket sheet, and on tablets and desktops
/// one column per status with drag to move. Phones get one list grouped by status instead, where a
/// long press moves a ticket.
class BoardScreen extends ConsumerStatefulWidget {
  const BoardScreen({super.key});

  static const statuses = [TaskStatus.todo, TaskStatus.inProgress, TaskStatus.inReview, TaskStatus.blocked, TaskStatus.done];

  @override
  ConsumerState<BoardScreen> createState() => _BoardScreenState();
}

enum _Owner { all, mine, bots }

String statusLabel(BuildContext context, TaskStatus s) {
  final l10n = context.l10n;
  return switch (s) {
    TaskStatus.todo => l10n.taskTodo,
    TaskStatus.inProgress => l10n.taskDoing,
    TaskStatus.inReview => l10n.taskInReview,
    TaskStatus.blocked => l10n.taskBlocked,
    TaskStatus.done => l10n.taskDone,
  };
}

String priorityLabel(BuildContext context, TaskPriority p) {
  final l10n = context.l10n;
  return switch (p) {
    TaskPriority.urgent => l10n.priorityUrgent,
    TaskPriority.high => l10n.priorityHigh,
    TaskPriority.medium => l10n.priorityMedium,
    TaskPriority.low => l10n.priorityLow,
    TaskPriority.none => l10n.priorityNone,
  };
}

Color _statusColor(BuildContext context, TaskStatus s) {
  final colors = context.appColors;
  return switch (s) {
    TaskStatus.todo => context.colorScheme.onSurfaceVariant,
    TaskStatus.inProgress => colors.working,
    TaskStatus.inReview => colors.waiting,
    TaskStatus.blocked => colors.negative,
    TaskStatus.done => colors.positive,
  };
}

/// [tasks] in [s], in board order.
List<Task> _inStatus(Iterable<Task> tasks, TaskStatus s) => tasks.where((t) => t.status == s).toList()..sort((a, b) => a.position.compareTo(b.position));

class _BoardScreenState extends ConsumerState<BoardScreen> {
  var _owner = _Owner.all;
  TaskPriority? _priority;
  String? _project;

  bool _keep(Task t, String? me, String? project) {
    if (_owner == _Owner.mine && t.assigneeUserId != me) return false;
    if (_owner == _Owner.bots && t.assigneeBotId == null) return false;
    if (_priority != null && t.priority != _priority) return false;
    if (project != null && t.projectId != project) return false;
    return true;
  }

  void _clearFilters() => setState(() {
    _owner = _Owner.all;
    _priority = null;
    _project = null;
  });

  /// Phones: a long press offers the other statuses, since columns don't fit to drag between.
  Future<void> _moveSheet(Task t, List<Task> items) async {
    final to = await showAdaptiveSheet<TaskStatus>(context: context, contentPadsBottom: true, builder: (_) => _MoveSheet(task: t));
    if (to == null || !mounted) return;
    await _move(t, to, items.where((x) => x.status == to).toList());
  }

  Future<void> _move(Task t, TaskStatus to, List<Task> column) async {
    if (t.status == to) return;
    // New arrivals go to the bottom of the column.
    final position = column.isEmpty ? 1.0 : column.map((x) => x.position.toDouble()).reduce((a, b) => a > b ? a : b) + 1;
    await runGuarded(context, () => ref.read(backendProvider).updateTask(t.id, status: to.value, position: position));
    ref.invalidate(tasksProvider);
  }

  Future<void> _newTicket() async {
    final org = ref.read(currentOrgProvider);
    if (org == null) return;
    final created = await showAdaptiveSheet<bool>(context: context, builder: (_) => _TicketForm(orgId: org.id));
    if (created == true) ref.invalidate(tasksProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final me = ref.watch(backendProvider).userId;
    final compact = AppBreakpoints.of(MediaQuery.sizeOf(context).width) == WindowSize.compact;
    // Above the phone's floating tab bar (the shell sets it as the bottom padding).
    final barInset = compact ? MediaQuery.paddingOf(context).bottom : 0.0;
    final projects = ref.watch(projectsProvider);
    // A project that's gone (deleted, or another workspace's) stops filtering.
    final project = projects.hasValue ? projects.value!.where((p) => p.id == _project).firstOrNull?.id : _project;
    // Tapping Tasks again scrolls the tickets to the top (TabReselect); so does the iOS status bar.
    return PrimaryScrollController(
      controller: TabReselect.tasks,
      child: SubPage(
      title: l10n.navTasks,
      actions: [
        _ProjectFilter(selected: project, onChanged: (id) => setState(() => _project = id)),
        IconButton(key: const Key('newTicket'), tooltip: l10n.newTicket, icon: const Icon(LucideIcons.plus), onPressed: _newTicket),
      ],
      maxWidth: double.infinity,
      body: AsyncView(
        value: ref.watch(tasksProvider),
        onRetry: () => ref.invalidate(tasksProvider),
        data: (items) {
          final shown = items.where((t) => _keep(t, me, project)).toList();
          final filters = [
            for (final (o, label) in [(_Owner.all, l10n.filterAll), (_Owner.mine, l10n.filterMine), (_Owner.bots, l10n.filterBots)])
              RevealWhenSelected(selected: _owner == o, child: ChoiceChip(key: Key('filter-${o.name}'), label: Text(label), selected: _owner == o, onSelected: (_) => setState(() => _owner = o))),
            DropdownButton<TaskPriority?>(
              key: const Key('filterPriority'),
              value: _priority,
              hint: Text(l10n.priority),
              underline: const SizedBox.shrink(),
              items: [
                DropdownMenuItem<TaskPriority?>(value: null, child: Text(l10n.priority)),
                for (final p in TaskPriority.values) DropdownMenuItem(value: p, child: Text(priorityLabel(context, p))),
              ],
              onChanged: hapticOnChanged((p) => setState(() => _priority = p), haptic: HapticsHelper.selection),
            ),
          ];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (compact)
                // One line of filters that scrolls sideways, so the tickets get the height.
                EdgeFade(child: SingleChildScrollView(
                  key: const Key('ticketFilters'),
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(AppSpace.gutter, 0, AppSpace.gutter, AppSpace.xs),
                  child: Row(spacing: AppSpace.xs, children: filters),
                ))
              else
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpace.lg, 0, AppSpace.lg, AppSpace.sm),
                  child: Wrap(spacing: AppSpace.sm, runSpacing: AppSpace.xs, crossAxisAlignment: WrapCrossAlignment.center, children: filters),
                ),
              if (items.isEmpty)
                Expanded(
                  child: EmptyState(icon: LucideIcons.squareKanban, title: l10n.noTickets, message: l10n.noTicketsHelp),
                )
              else if (compact && shown.isEmpty)
                Expanded(
                  child: EmptyState(
                    icon: LucideIcons.listFilter,
                    title: l10n.noMatchingTickets,
                    message: l10n.noMatchingTicketsHelp,
                    action: TextButton(key: const Key('clearFilters'), onPressed: _clearFilters, child: Text(l10n.clearFilters)),
                  ),
                )
              else if (compact)
                Expanded(child: _GroupedList(tasks: shown, bottom: AppSpace.xxl + barInset, onLongPress: (t) { HapticsHelper.medium(); _moveSheet(t, items); }))
              else
                Expanded(
                  child: EdgeFade(child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.fromLTRB(AppSpace.md, 0, AppSpace.md, BottomPadding.of(context, minimum: AppSpace.md)),
                    children: [
                      for (final s in BoardScreen.statuses)
                        _Column(
                          status: s,
                          tasks: _inStatus(shown, s),
                          onDrop: (t) => _move(t, s, shown.where((x) => x.status == s).toList()),
                        ),
                    ],
                  )),
                ),
            ],
          );
        },
      ),
      ),
    );
  }
}

/// The project filter in the header: all projects or one, and the way to manage them.
class _ProjectFilter extends ConsumerWidget {
  const _ProjectFilter({required this.selected, required this.onChanged});

  /// The project shown, or null for all of them.
  final String? selected;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final projects = ref.watch(projectsProvider).value ?? const <Project>[];
    final current = projects.where((p) => p.id == selected).firstOrNull;
    final compact = AppBreakpoints.of(MediaQuery.sizeOf(context).width) == WindowSize.compact;
    final fill = context.isDark ? scheme.surfaceContainer : scheme.surfaceContainerLowest;
    final on = current != null;
    Widget check(bool selected) => Icon(selected ? LucideIcons.check : null, size: 18);
    return MenuAnchor(
      alignmentOffset: const Offset(0, 6),
      menuChildren: [
        MenuItemButton(key: const Key('projectFilter-all'), leadingIcon: check(current == null), onPressed: () => onChanged(null), child: Text(l10n.allProjects)),
        for (final p in projects)
          MenuItemButton(
            key: Key('projectFilter-${p.id}'),
            leadingIcon: check(p.id == current?.id),
            onPressed: () => onChanged(p.id),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 260),
              child: Text(p.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ),
        const Divider(height: AppSpace.xs),
        MenuItemButton(
          key: const Key('openProjects'),
          leadingIcon: const Icon(LucideIcons.target, size: 18),
          onPressed: () => context.push('/projects'),
          child: Padding(padding: const EdgeInsets.only(right: AppSpace.md), child: Text(l10n.manageProjects)),
        ),
      ],
      builder: (context, controller, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Tooltip(
          message: l10n.filterByProject,
          child: TextButton(
            key: const Key('projectFilter'),
            onPressed: () => controller.isOpen ? controller.close() : controller.open(),
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 36),
              maximumSize: Size(compact ? 168 : 260, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.only(left: 14, right: 10),
              shape: const StadiumBorder(),
              backgroundColor: on ? scheme.primary.withValues(alpha: 0.14) : fill,
              foregroundColor: on ? scheme.primary : scheme.onSurface,
              side: BorderSide(color: on ? scheme.primary.withValues(alpha: 0.4) : context.appColors.hairline),
              textStyle: context.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(child: Text(current?.title ?? l10n.allProjects, maxLines: 1, overflow: TextOverflow.ellipsis)),
                const SizedBox(width: 4),
                const Icon(LucideIcons.chevronDown, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Phones: the tickets in one list, a section per status that has any.
class _GroupedList extends StatelessWidget {
  const _GroupedList({required this.tasks, required this.bottom, required this.onLongPress});
  final List<Task> tasks;
  final double bottom;
  final void Function(Task) onLongPress;

  @override
  Widget build(BuildContext context) {
    final groups = [
      for (final s in BoardScreen.statuses)
        if (_inStatus(tasks, s) case final inStatus when inStatus.isNotEmpty) (s, inStatus),
    ];
    return ListView(
      key: const Key('ticketList'),
      padding: EdgeInsets.fromLTRB(AppSpace.gutter, 0, AppSpace.gutter, bottom),
      children: [
        for (final (i, (s, inStatus)) in groups.indexed) ...[
          _StatusHeader(status: s, count: inStatus.length, first: i == 0),
          for (final t in inStatus) _Card(task: t, onLongPress: () => onLongPress(t)),
        ],
      ],
    );
  }
}

class _StatusHeader extends StatelessWidget {
  const _StatusHeader({required this.status, required this.count, required this.first});
  final TaskStatus status;
  final int count;
  final bool first;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: Key('section-${status.value}'),
      padding: EdgeInsets.fromLTRB(AppSpace.xxs, first ? AppSpace.xs : AppSpace.md, AppSpace.xxs, AppSpace.xs),
      child: Row(
        children: [
          Icon(LucideIcons.circleDot, size: 14, color: _statusColor(context, status)),
          const SizedBox(width: 6),
          Expanded(child: SectionHeader(title: statusLabel(context, status), count: count.humanizedCount(context.l10n.localeName), padding: EdgeInsets.zero)),
        ],
      ),
    );
  }
}

/// "Move to": the statuses a ticket isn't in.
class _MoveSheet extends StatelessWidget {
  const _MoveSheet({required this.task});
  final Task task;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: BottomPadding.of(context)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetTitle(context.l10n.moveTo, subtitle: task.title),
          for (final s in BoardScreen.statuses)
            if (s != task.status)
              ListTile(
                key: Key('moveTo-${s.value}'),
                contentPadding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
                leading: Icon(LucideIcons.circleDot, size: 18, color: _statusColor(context, s)),
                title: Text(statusLabel(context, s)),
                onTap: () => Navigator.pop(context, s),
              ),
          const SizedBox(height: AppSpace.sm),
        ],
      ),
    );
  }
}

class _Column extends ConsumerWidget {
  const _Column({required this.status, required this.tasks, required this.onDrop});
  final TaskStatus status;
  final List<Task> tasks;
  final void Function(Task) onDrop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _statusColor(context, status);
    return DragTarget<Task>(
      onWillAcceptWithDetails: (d) => d.data.status != status,
      onAcceptWithDetails: (d) => onDrop(d.data),
      builder: (context, candidates, _) => Container(
        key: Key('column-${status.value}'),
        width: 280,
        margin: const EdgeInsets.symmetric(horizontal: AppSpace.xs),
        padding: const EdgeInsets.all(AppSpace.sm),
        decoration: BoxDecoration(
          color: candidates.isNotEmpty ? color.withValues(alpha: 0.10) : context.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpace.xs, AppSpace.xs, AppSpace.xs, AppSpace.sm),
              child: Row(
                children: [
                  Icon(LucideIcons.circleDot, size: 14, color: color),
                  const SizedBox(width: 6),
                  Expanded(child: Text(statusLabel(context, status), style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700))),
                  Text(tasks.length.humanizedCount(context.l10n.localeName), style: context.textTheme.bodySmall?.copyWith(fontFeatures: AppText.tabular)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                primary: false,
                children: [
                  for (final t in tasks)
                    LongPressDraggable<Task>(
                      data: t,
                      delay: const Duration(milliseconds: 150),
                      feedback: Material(color: Colors.transparent, child: SizedBox(width: 260, child: _Card(task: t))),
                      childWhenDragging: Opacity(opacity: 0.35, child: _Card(task: t)),
                      child: _Card(task: t),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Card extends ConsumerWidget {
  const _Card({required this.task, this.onLongPress});
  final Task task;

  /// Phones only; on wider windows a long press starts a drag instead.
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final bot = task.assigneeBotId == null ? null : ref.watch(botProvider(task.assigneeBotId!));
    final me = ref.watch(backendProvider).userId;
    return Card(
      key: Key('ticket-${task.id}'),
      margin: const EdgeInsets.only(bottom: AppSpace.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => showAdaptiveSheet<void>(context: context, contentPadsBottom: true, builder: (_) => TicketSheet(taskId: task.id)),
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 6,
            children: [
              Text(task.title, style: context.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  if (task.priority != TaskPriority.none)
                    StatusLabel(text: priorityLabel(context, task.priority), color: task.priority == TaskPriority.urgent ? context.appColors.negative : context.colorScheme.primary, pill: true),
                  if (bot != null) StatusLabel(text: bot.name, color: context.appColors.working, pill: true),
                  if (task.assigneeUserId != null && task.assigneeUserId == me) StatusLabel(text: l10n.assignToMe, color: context.colorScheme.secondary, pill: true),
                  if (task.comments > 0) Text('💬 ${task.comments}', style: context.textTheme.bodySmall),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TicketForm extends ConsumerStatefulWidget {
  const _TicketForm({required this.orgId});
  final String orgId;

  @override
  ConsumerState<_TicketForm> createState() => _TicketFormState();
}

class _TicketFormState extends ConsumerState<_TicketForm> {
  final _title = TextEditingController();
  final _details = TextEditingController();
  var _priority = TaskPriority.none;
  String? _bot;
  var _review = false;

  @override
  void dispose() {
    _title.dispose();
    _details.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bots = ref.watch(botsProvider).value ?? const <Bot>[];
    return FormSheet(
      icon: LucideIcons.squareKanban,
      title: l10n.newTicket,
      submitLabel: l10n.newTicket,
      submitKey: const Key('createTicket'),
      onSubmit: () async {
        if (_title.text.trim().isEmpty) return;
        final ok = await runGuarded(
          context,
          () => ref.read(backendProvider).createTask(
                widget.orgId,
                title: _title.text.trim(),
                details: _details.text.trim(),
                priority: _priority.value,
                assigneeBotId: _bot,
                reviewRequired: _review,
              ),
        );
        if (ok != null && context.mounted) Navigator.pop(context, true);
      },
      children: [
        TextField(key: const Key('ticketTitle'), controller: _title, textInputAction: TextInputAction.next, decoration: InputDecoration(labelText: l10n.ticketTitle)),
        TextField(key: const Key('ticketDetails'), controller: _details, minLines: 2, maxLines: 6, decoration: InputDecoration(labelText: l10n.ticketDetails)),
        DropdownButtonFormField<TaskPriority>(
          isExpanded: true,
          initialValue: _priority,
          decoration: InputDecoration(labelText: l10n.priority),
          items: [for (final p in TaskPriority.values) DropdownMenuItem(value: p, child: Text(priorityLabel(context, p)))],
          onChanged: hapticOnChanged((p) => setState(() => _priority = p ?? _priority), haptic: HapticsHelper.selection),
        ),
        DropdownButtonFormField<String?>(
          isExpanded: true,
          key: const Key('ticketBot'),
          initialValue: _bot,
          decoration: InputDecoration(labelText: l10n.assignee),
          items: [
            DropdownMenuItem<String?>(value: null, child: Text(l10n.unassigned)),
            for (final b in bots) DropdownMenuItem(value: b.id, child: Text(b.name)),
          ],
          onChanged: hapticOnChanged((v) => setState(() => _bot = v), haptic: HapticsHelper.selection),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.reviewRequired),
          subtitle: Text(l10n.reviewRequiredHelp),
          value: _review,
          onChanged: hapticOnChanged((v) => setState(() => _review = v)),
        ),
      ],
    );
  }
}

final _commentsProvider = FutureProvider.family<List<TaskComment>, String>((ref, id) => ref.watch(backendProvider).taskComments(id));

/// One ticket: status, priority, assignment, comments and the bot's thread.
class TicketSheet extends ConsumerStatefulWidget {
  const TicketSheet({super.key, required this.taskId});
  final String taskId;

  @override
  ConsumerState<TicketSheet> createState() => _TicketSheetState();
}

class _TicketSheetState extends ConsumerState<TicketSheet> {
  final _comment = TextEditingController();

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _update({String? status, String? priority, String? bot, bool? review, String? user}) async {
    await runGuarded(
      context,
      () => ref.read(backendProvider).updateTask(widget.taskId, status: status, priority: priority, assigneeBotId: bot, reviewRequired: review, assigneeUserId: user),
    );
    ref.invalidate(tasksProvider);
  }

  Future<void> _send() async {
    final text = _comment.text.trim();
    if (text.isEmpty) return;
    final ok = await runGuarded(context, () => ref.read(backendProvider).addTaskComment(widget.taskId, text));
    if (ok == null) return;
    _comment.clear();
    ref.invalidate(_commentsProvider(widget.taskId));
    ref.invalidate(tasksProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final task = ref.watch(tasksProvider).value?.where((t) => t.id == widget.taskId).firstOrNull;
    if (task == null) return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
    final bots = ref.watch(botsProvider).value ?? const <Bot>[];
    final comments = ref.watch(_commentsProvider(widget.taskId)).value ?? const <TaskComment>[];
    final me = ref.watch(backendProvider).userId;
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.lg, AppSpace.lg, BottomPadding.of(context, minimum: AppSpace.lg)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpace.md,
        children: [
          Text(task.title, style: context.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          if (task.detailsMd.isNotEmpty) Text(task.detailsMd),
          if (task.resultMd.isUsable) AppCard(child: Text(task.resultMd!)),
          Wrap(
            spacing: AppSpace.md,
            runSpacing: AppSpace.sm,
            children: [
              SizedBox(
                width: 220,
                child: DropdownButtonFormField<TaskStatus>(
                  key: const Key('sheetStatus'),
                  isExpanded: true,
                  initialValue: task.status,
                  decoration: InputDecoration(labelText: l10n.ticketStatus),
                  items: [for (final s in BoardScreen.statuses) DropdownMenuItem(value: s, child: Text(statusLabel(context, s)))],
                  onChanged: hapticOnChanged((s) => s == null ? null : _update(status: s.value), haptic: HapticsHelper.selection),
                ),
              ),
              SizedBox(
                width: 220,
                child: DropdownButtonFormField<TaskPriority>(
                  isExpanded: true,
                  initialValue: task.priority,
                  decoration: InputDecoration(labelText: l10n.priority),
                  items: [for (final p in TaskPriority.values) DropdownMenuItem(value: p, child: Text(priorityLabel(context, p)))],
                  onChanged: hapticOnChanged((p) => p == null ? null : _update(priority: p.value), haptic: HapticsHelper.selection),
                ),
              ),
              SizedBox(
                width: 220,
                child: DropdownButtonFormField<String?>(
                  key: const Key('sheetBot'),
                  isExpanded: true,
                  initialValue: task.assigneeBotId,
                  decoration: InputDecoration(labelText: l10n.assignee),
                  items: [
                    DropdownMenuItem<String?>(value: null, child: Text(l10n.unassigned)),
                    for (final b in bots) DropdownMenuItem(value: b.id, child: Text(b.name)),
                  ],
                  onChanged: hapticOnChanged((v) => v == null ? null : _update(bot: v), haptic: HapticsHelper.selection),
                ),
              ),
            ],
          ),
          Row(
            children: [
              if (me != null && task.assigneeUserId != me)
                TextButton.icon(onPressed: () => _update(user: me), icon: const Icon(LucideIcons.user, size: 18), label: Text(l10n.assignToMe)),
              const Spacer(),
              if (task.assigneeBotId != null && task.conversationId != null)
                TextButton.icon(
                  key: const Key('openThread'),
                  onPressed: () {
                    Navigator.of(context).maybePop();
                    context.push('/bots/${task.assigneeBotId}/chat');
                  },
                  icon: const Icon(LucideIcons.messageCircle, size: 18),
                  label: Text(l10n.openThread),
                ),
            ],
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.reviewRequired),
            value: task.reviewRequired,
            onChanged: hapticOnChanged((v) => _update(review: v)),
          ),
          SectionHeader(title: l10n.comments),
          for (final c in comments)
            ListTile(
              key: Key('comment-${c.id}'),
              contentPadding: EdgeInsets.zero,
              leading: Icon(c.authorType == TaskCommentAuthorTypeEnum.bot ? LucideIcons.bot : LucideIcons.user, size: 20),
              title: Text(c.bodyMd),
              subtitle: Text(
                c.authorType == TaskCommentAuthorTypeEnum.bot
                    ? (bots.where((b) => b.id == c.authorBotId).firstOrNull?.name ?? l10n.aBot)
                    : (c.authorUserId == me ? l10n.assignToMe : ''),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('commentField'),
                  controller: _comment,
                  minLines: 1,
                  maxLines: 4,
                  decoration: InputDecoration(hintText: l10n.addComment),
                  onSubmitted: (_) => _send(),
                ),
              ),
              IconButton(key: const Key('sendComment'), tooltip: l10n.sendComment, icon: const Icon(LucideIcons.send), onPressed: _send),
            ],
          ),
          TextButton.icon(
            key: const Key('deleteTicket'),
            style: TextButton.styleFrom(foregroundColor: context.appColors.negative),
            onPressed: () async {
              final ok = await showConfirm(context: context, title: l10n.deleteTicket, confirmLabel: l10n.deleteTicket, destructive: true);
              if (!ok || !context.mounted) return;
              await runGuarded(context, () => ref.read(backendProvider).deleteTask(widget.taskId));
              ref.invalidate(tasksProvider);
              if (context.mounted) Navigator.of(context).maybePop();
            },
            icon: const Icon(LucideIcons.trash2, size: 18),
            label: Text(l10n.deleteTicket),
          ),
        ],
      ),
    );
  }
}
