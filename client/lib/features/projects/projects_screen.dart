import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/number_format.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../core/haptics.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/app_card.dart';
import '../../ui/form_sheet.dart';
import '../../ui/glow_button.dart';
import '../../ui/page.dart';
import '../chat/widgets/chat_markdown.dart';
import '../library/creation_tile.dart';
import 'project_tile.dart';

/// Projects (D-113, D-295): the home for one piece of work, with its chat, plan, to-dos, files and
/// what was made for it. Worked on together in its chat, or planned by the lead bot for approval
/// and then worked on by itself in sessions.

// Kept when Tasks closes, so it opens with what it showed; Tasks refreshes it as it opens.
final projectsProvider = FutureProvider<List<Project>>((ref) async {
  final org = ref.watch(currentOrgProvider);
  if (org == null) return const [];
  return ref.watch(backendProvider).projects(org.id);
});
final projectProvider = FutureProvider.autoDispose.family<ProjectDetail, String>((ref, id) => ref.watch(backendProvider).project(id));
final projectTasksProvider = FutureProvider.autoDispose.family<List<Task>, String>((ref, id) async {
  final org = ref.watch(currentOrgProvider);
  if (org == null) return const [];
  return ref.watch(backendProvider).tasks(org.id, projectId: id);
});

/// The newest things made in a project, for its strip (the Library lists them all).
final projectCreationsProvider = FutureProvider.autoDispose.family<List<Creation>, String>((ref, id) async {
  final org = ref.watch(currentOrgProvider);
  if (org == null) return const [];
  return (await ref.watch(backendProvider).creations(org.id, projectId: id, limit: 12)).items;
});

String projectStatusLabel(BuildContext context, ProjectStatus s) {
  final l10n = context.l10n;
  return switch (s) {
    ProjectStatus.planning => l10n.projectPlanning,
    ProjectStatus.active => l10n.projectActive,
    ProjectStatus.paused => l10n.projectPaused,
    ProjectStatus.blocked => l10n.projectBlocked,
    ProjectStatus.done => l10n.projectDone,
    ProjectStatus.cancelled => l10n.projectCancelled,
  };
}

class ProjectsScreen extends ConsumerWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return SubPage(
      title: l10n.projects,
      actions: [IconButton(key: const Key('newProject'), tooltip: l10n.newProject, icon: const Icon(LucideIcons.plus), onPressed: () => showNewProject(context, ref))],
      body: AsyncView(
        value: ref.watch(projectsProvider),
        onRetry: () => ref.invalidate(projectsProvider),
        loading: const SkeletonPage(children: [SkeletonGroupedCard(count: 5)]),
        data: (items) => items.isEmpty
            ? EmptyState(
                icon: LucideIcons.folderKanban,
                title: l10n.noProjects,
                message: l10n.projectsHelp,
                action: GlowButton.icon(onPressed: () => showNewProject(context, ref), icon: const Icon(LucideIcons.plus, size: 18), label: Text(l10n.newProject)),
              )
            : PageColumn(
                children: [
                  GroupedCard(
                    children: [
                      for (final p in items)
                        GroupedTile(
                          key: Key('project-${p.id}'),
                          // One that works by itself has a goal to hit; the rest are folders of work.
                          icon: projectIsAutonomous(p) ? LucideIcons.target : LucideIcons.folderKanban,
                          title: p.title,
                          subtitle: [
                            projectStatusLabel(context, p.status),
                            if ((p.creationsCount ?? 0) > 0) l10n.projectThings(p.creationsCount!),
                            if (p.budgetUsd != null) '${formatUsd(p.spentUsd, context.l10n.localeName)} / ${formatUsd(p.budgetUsd!, context.l10n.localeName)}' else if (projectIsAutonomous(p)) formatUsd(p.spentUsd, context.l10n.localeName),
                          ].join(' · '),
                          onTap: () => context.push('/projects/${p.id}'),
                        ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}

Future<void> showNewProject(BuildContext context, WidgetRef ref) async {
  final id = await showAdaptiveSheet<String>(context: context, dialogMaxWidth: 640, builder: (_) => const _NewProject());
  ref.invalidate(projectsProvider);
  if (id != null && context.mounted) GoRouter.maybeOf(context)?.push('/projects/$id');
}

class _NewProject extends ConsumerStatefulWidget {
  const _NewProject();

  @override
  ConsumerState<_NewProject> createState() => _NewProjectState();
}

class _NewProjectState extends ConsumerState<_NewProject> {
  final _title = TextEditingController();
  final _goal = TextEditingController();
  final _done = TextEditingController();
  final _budget = TextEditingController();
  String? _lead;
  // Off: a project you work on together in its chat. On: the bot plans it for approval (D-113).
  var _alone = false;
  var _busy = false;

  @override
  void dispose() {
    _title.dispose();
    _goal.dispose();
    _done.dispose();
    _budget.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bots = ref.watch(botsProvider).value ?? const <Bot>[];
    _lead ??= bots.firstOrNull?.id;
    final lead = bots.where((b) => b.id == _lead).firstOrNull;
    final valid = _title.text.trim().isNotEmpty && _lead != null && (!_alone || _goal.text.trim().isNotEmpty);
    VoidCallback? submit;
    return FormSheet(
      icon: LucideIcons.folderKanban,
      title: l10n.newProject,
      subtitle: l10n.newProjectHelp,
      submitLabel: _alone ? l10n.startPlanning : l10n.createProject,
      submitKey: const Key('createProject'),
      // Also run by the keyboard's Done key on the last field.
      onSubmit: submit = !valid || _busy
          ? null
          : () async {
              final org = ref.read(currentOrgProvider);
              if (org == null) return;
              setState(() => _busy = true);
              final p = await runGuarded(
                context,
                () => ref.read(backendProvider).createProject(
                      org.id,
                      title: _title.text.trim(),
                      goal: _alone ? _goal.text.trim() : '',
                      doneCriteria: _alone ? _done.text.trim() : '',
                      leadBotId: _lead!,
                      budgetUsd: _alone ? double.tryParse(_budget.text.trim()) : null,
                      autonomous: _alone,
                    ),
              );
              if (!context.mounted) return;
              setState(() => _busy = false);
              if (p != null) {
                // Its new chat is a topic under the bot's General.
                ref.invalidate(conversationsProvider(_lead!));
                Navigator.pop(context, p.id);
              }
            },
      children: [
        TextField(
          key: const Key('projectTitle'),
          controller: _title,
          textInputAction: _alone ? TextInputAction.next : TextInputAction.done,
          autofocus: true,
          decoration: InputDecoration(labelText: l10n.projectName, hintText: l10n.projectNameHint),
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) {
            if (!_alone) submit?.call();
          },
        ),
        // With one bot there's nothing to pick.
        if (bots.length > 1)
        DropdownButtonFormField<String>(
          key: const Key('projectLead'),
          initialValue: _lead,
          isExpanded: true,
          decoration: InputDecoration(labelText: l10n.projectLead),
          items: [for (final b in bots) DropdownMenuItem(value: b.id, child: Text(b.name))],
          onChanged: hapticOnChanged((v) => setState(() => _lead = v), haptic: HapticsHelper.selection),
        ),
        FormSwitch(
          key: const Key('projectAlone'),
          icon: LucideIcons.sparkles,
          title: l10n.projectWorksAlone(lead?.name ?? l10n.theBot),
          subtitle: l10n.projectWorksAloneHelp,
          value: _alone,
          onChanged: (v) => setState(() => _alone = v),
        ),
        if (_alone) ...[
          TextField(key: const Key('projectGoal'), controller: _goal, minLines: 2, maxLines: 6, decoration: InputDecoration(labelText: l10n.projectGoal, hintText: l10n.projectGoalHint), onChanged: (_) => setState(() {})),
          TextField(key: const Key('projectDone'), controller: _done, minLines: 1, maxLines: 4, decoration: InputDecoration(labelText: l10n.projectDoneWhen, helperText: l10n.projectDoneHint)),
          TextField(
            key: const Key('projectBudget'),
            controller: _budget,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => submit?.call(),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: l10n.projectBudget, prefixText: r'$ ', helperText: l10n.projectBudgetHint),
          ),
        ],
      ],
    );
  }
}

/// Switching "work on it by itself" on for a project: its goal, what done looks like and a budget,
/// then the bot plans it for approval. Pops true when planning started.
class _WorkAlone extends ConsumerStatefulWidget {
  const _WorkAlone({required this.project, required this.botName});
  final ProjectDetail project;
  final String botName;

  @override
  ConsumerState<_WorkAlone> createState() => _WorkAloneState();
}

class _WorkAloneState extends ConsumerState<_WorkAlone> {
  late final _goal = TextEditingController(text: widget.project.goalMd);
  late final _done = TextEditingController(text: widget.project.doneCriteriaMd);
  late final _budget = TextEditingController(text: widget.project.budgetUsd?.toString() ?? '');
  var _busy = false;

  @override
  void dispose() {
    _goal.dispose();
    _done.dispose();
    _budget.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    VoidCallback? submit;
    return FormSheet(
      icon: LucideIcons.sparkles,
      title: l10n.projectWorksAlone(widget.botName),
      subtitle: l10n.projectWorksAloneHelp,
      submitLabel: l10n.startPlanning,
      submitKey: const Key('startPlanning'),
      busy: _busy,
      onSubmit: submit = _goal.text.trim().isEmpty || _busy
          ? null
          : () async {
              setState(() => _busy = true);
              final ok = await runGuarded(context, () async {
                await ref.read(backendProvider).updateProject(
                      widget.project.id,
                      autonomous: true,
                      goal: _goal.text.trim(),
                      doneCriteria: _done.text.trim(),
                      budgetUsd: double.tryParse(_budget.text.trim()),
                    );
                return true;
              });
              if (!context.mounted) return;
              setState(() => _busy = false);
              if (ok == true) Navigator.pop(context, true);
            },
      children: [
        TextField(key: const Key('projectGoal'), controller: _goal, autofocus: true, minLines: 2, maxLines: 6, decoration: InputDecoration(labelText: l10n.projectGoal, hintText: l10n.projectGoalHint), onChanged: (_) => setState(() {})),
        TextField(key: const Key('projectDone'), controller: _done, minLines: 1, maxLines: 4, decoration: InputDecoration(labelText: l10n.projectDoneWhen, helperText: l10n.projectDoneHint)),
        TextField(
          key: const Key('projectBudget'),
          controller: _budget,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => submit?.call(),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: l10n.projectBudget, prefixText: r'$ ', helperText: l10n.projectBudgetHint),
        ),
      ],
    );
  }
}

class ProjectScreen extends ConsumerWidget {
  const ProjectScreen({super.key, required this.projectId});
  final String projectId;

  Future<void> _act(BuildContext context, WidgetRef ref, Future<void> Function() f) async {
    await runGuarded(context, f);
    ref
      ..invalidate(projectProvider(projectId))
      ..invalidate(projectsProvider);
  }

  /// On asks for the goal and a budget first, then the bot plans; off stops it starting anything.
  Future<void> _setAlone(BuildContext context, WidgetRef ref, ProjectDetail p, String botName, bool on) async {
    if (!on) {
      await _act(context, ref, () => ref.read(backendProvider).updateProject(projectId, autonomous: false));
      return;
    }
    // A plan approved earlier still stands, so there's nothing to ask.
    if (p.goalMd.trim().isNotEmpty && p.planStatus == ProjectDetailPlanStatusEnum.approved) {
      await _act(context, ref, () => ref.read(backendProvider).updateProject(projectId, autonomous: true));
      return;
    }
    await showAdaptiveSheet<bool>(context: context, dialogMaxWidth: 640, builder: (_) => _WorkAlone(project: p, botName: botName));
    ref
      ..invalidate(projectProvider(projectId))
      ..invalidate(projectsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final backend = ref.read(backendProvider);
    return AsyncView(
      value: ref.watch(projectProvider(projectId)),
      onRetry: () => ref.invalidate(projectProvider(projectId)),
      loading: const SubPage(title: '', body: _ProjectSkeleton()),
      data: (p) {
        final tickets = ref.watch(projectTasksProvider(projectId)).value ?? const <Task>[];
        final made = ref.watch(projectCreationsProvider(projectId)).value ?? const <Creation>[];
        final budget = p.budgetUsd;
        final autonomous = projectDetailIsAutonomous(p);
        final canSteer = p.canSteer ?? true;
        final closed = p.status == ProjectStatus.done || p.status == ProjectStatus.cancelled;
        final botName = ref.watch(botProvider(p.leadBotId))?.name ?? l10n.theBot;
        final folder = p.folder;
        return SubPage(
          title: p.title,
          subtitle: projectStatusLabel(context, p.status),
          actions: [
            IconButton(
              key: const Key('projectThread'),
              tooltip: l10n.projectThread,
              icon: const Icon(LucideIcons.messagesSquare),
              // One started from General has no chat of its own: General is where it's talked about.
              onPressed: () => context.push(p.conversationId == null ? '/bots/${p.leadBotId}/chat' : '/bots/${p.leadBotId}/chat?c=${p.conversationId}'),
            ),
          ],
          children: [
            if (p.statusReason != null) FormNote(p.statusReason!, icon: LucideIcons.info),
            if (autonomous && p.planStatus == ProjectDetailPlanStatusEnum.proposed)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpace.md),
                child: GlowButton.icon(
                  key: const Key('approvePlan'),
                  onPressed: () => _act(context, ref, () => backend.approveProjectPlan(projectId)),
                  icon: const Icon(LucideIcons.check, size: 18),
                  label: Text(l10n.approvePlan),
                ),
              ),
            Wrap(
              spacing: AppSpace.sm,
              children: [
                if (autonomous && p.status == ProjectStatus.active)
                  OutlinedButton.icon(
                    key: const Key('pauseProject'),
                    onPressed: () => _act(context, ref, () => backend.updateProject(projectId, status: 'paused')),
                    icon: const Icon(LucideIcons.pause, size: 18),
                    label: Text(l10n.pause),
                  ),
                if (autonomous && (p.status == ProjectStatus.paused || p.status == ProjectStatus.blocked) && p.planStatus == ProjectDetailPlanStatusEnum.approved)
                  OutlinedButton.icon(
                    key: const Key('resumeProject'),
                    onPressed: () => _act(context, ref, () => backend.updateProject(projectId, status: 'active')),
                    icon: const Icon(LucideIcons.play, size: 18),
                    label: Text(l10n.resume),
                  ),
                // Worked on together, nothing waits on a plan: paused or blocked just carries on.
                if (!autonomous && canSteer && (p.status == ProjectStatus.paused || p.status == ProjectStatus.blocked))
                  OutlinedButton.icon(
                    key: const Key('resumeProject'),
                    onPressed: () => _act(context, ref, () => backend.updateProject(projectId, status: 'active')),
                    icon: const Icon(LucideIcons.play, size: 18),
                    label: Text(l10n.resume),
                  ),
                // Worked on together: the person says when it's finished, and can pick it up again.
                if (!autonomous && canSteer && p.status == ProjectStatus.active)
                  OutlinedButton.icon(
                    key: const Key('finishProject'),
                    onPressed: () => _act(context, ref, () => backend.updateProject(projectId, status: 'done')),
                    icon: const Icon(LucideIcons.circleCheck, size: 18),
                    label: Text(l10n.projectMarkDone),
                  ),
                if (!autonomous && canSteer && p.status == ProjectStatus.done)
                  OutlinedButton.icon(
                    key: const Key('reopenProject'),
                    onPressed: () => _act(context, ref, () => backend.updateProject(projectId, status: 'active')),
                    icon: const Icon(LucideIcons.rotateCcw, size: 18),
                    label: Text(l10n.projectReopen),
                  ),
              ],
            ),
            SectionHeader(
              title: l10n.projectMade,
              trailing: made.isEmpty
                  ? null
                  : TextButton(key: const Key('projectSeeAll'), onPressed: () => context.push('/library?project=$projectId'), child: Text(l10n.projectSeeAll)),
            ),
            if (made.isEmpty)
              AppCard(
                key: const Key('projectMadeEmpty'),
                padding: const EdgeInsets.all(AppSpace.md),
                child: Text(l10n.projectMadeEmpty(botName), style: context.textTheme.bodyMedium?.copyWith(color: context.colorScheme.onSurfaceVariant)),
              )
            else
              SizedBox(
                height: 160 * 3 / 4 + 64 * MediaQuery.textScalerOf(context).scale(1),
                child: ListView.separated(
                  key: const Key('projectMade'),
                  scrollDirection: Axis.horizontal,
                  itemCount: made.length,
                  separatorBuilder: (_, _) => const SizedBox(width: AppSpace.xs),
                  itemBuilder: (context, i) => SizedBox(
                    width: 160,
                    child: CreationTile(creation: made[i], onTap: () => context.push('/library/${made[i].id}')),
                  ),
                ),
              ),
            if (p.goalMd.trim().isNotEmpty) ...[
              SectionHeader(title: l10n.projectGoal),
              AppCard(padding: const EdgeInsets.all(AppSpace.md), child: ChatMarkdown(data: p.goalMd)),
            ],
            if (budget != null) ...[
              SectionHeader(title: l10n.projectBudget),
              LinearProgressIndicator(key: const Key('projectSpend'), value: (p.spentUsd / budget).clamp(0, 1).toDouble()),
              const SizedBox(height: AppSpace.xs),
              Text('${formatUsd(p.spentUsd, context.l10n.localeName)} / ${formatUsd(budget, context.l10n.localeName)}', style: const TextStyle(fontFeatures: AppText.tabular)),
            ],
            if (p.milestones.isNotEmpty) ...[
              SectionHeader(title: l10n.milestones),
              GroupedCard(
                children: [
                  for (final m in p.milestones)
                    GroupedTile(
                      key: Key('milestone-${m.id}'),
                      icon: m.status == ProjectMilestoneStatusEnum.done ? LucideIcons.circleCheck : LucideIcons.flag,
                      iconColor: m.status == ProjectMilestoneStatusEnum.done ? colors.positive : null,
                      title: m.name,
                      subtitle: '${m.ticketsDone.humanizedCount(context.l10n.localeName)}/${m.ticketsTotal.humanizedCount(context.l10n.localeName)}${m.requiresSignoff ? ' · ${l10n.needsSignoff}' : ''}',
                      trailing: m.status == ProjectMilestoneStatusEnum.awaitingSignoff
                          ? TextButton(
                              key: Key('signoff-${m.id}'),
                              onPressed: () => _act(context, ref, () => backend.signOffMilestone(projectId, m.id)),
                              child: Text(l10n.signOff),
                            )
                          : null,
                    ),
                ],
              ),
            ],
            if (p.planMd.isNotEmpty) ...[
              SectionHeader(title: l10n.projectPlan),
              AppCard(padding: const EdgeInsets.all(AppSpace.md), child: ChatMarkdown(data: p.planMd)),
            ],
            if (tickets.isNotEmpty) ...[
              SectionHeader(title: autonomous ? l10n.tickets : l10n.projectTodos),
              GroupedCard(
                children: [
                  for (final t in tickets)
                    GroupedTile(
                      icon: t.status == TaskStatus.done ? LucideIcons.circleCheck : LucideIcons.circle,
                      iconColor: t.status == TaskStatus.done ? colors.positive : null,
                      title: t.title,
                      subtitle: t.status.value,
                      onTap: () => context.push('/tasks'),
                    ),
                ],
              ),
            ],
            const SizedBox(height: AppSpace.lg),
            GroupedCard(
              children: [
                // The folder the bot keeps this project's working files in (code, drafts, assets).
                if (folder != null)
                  GroupedTile(
                    key: const Key('projectFiles'),
                    icon: LucideIcons.folderOpen,
                    title: l10n.projectFiles,
                    subtitle: l10n.projectFilesHelp(folder, botName),
                    onTap: () => context.push(Uri(path: '/computer', queryParameters: {'bot': p.leadBotId, 'tab': 'files', 'path': folder}).toString()),
                  ),
                if (canSteer && !closed)
                  GroupedTile(
                    key: const Key('projectAlone'),
                    icon: LucideIcons.sparkles,
                    title: l10n.projectWorksAlone(botName),
                    subtitle: autonomous ? l10n.projectWorksAloneOn : l10n.projectWorksAloneOff,
                    showChevron: false,
                    onTap: () {
                      HapticsHelper.light();
                      _setAlone(context, ref, p, botName, !autonomous);
                    },
                    trailing: Switch(key: const Key('projectAloneSwitch'), value: autonomous, onChanged: hapticOnChanged((v) => _setAlone(context, ref, p, botName, v))),
                  ),
              ],
            ),
            if (p.runs.isNotEmpty) ...[
              SectionHeader(title: l10n.projectTimeline),
              GroupedCard(
                children: [
                  for (final r in p.runs)
                    GroupedTile(
                      icon: LucideIcons.activity,
                      title: '${r.trigger} · ${r.status}',
                      subtitle: '${formatUsd(r.costUsd, context.l10n.localeName)} · ${relativeTime(r.createdAt, context)}',
                      onTap: () => context.push('/bots/${r.botId}/runs/${r.id}'),
                    ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}

/// A project still loading: the pause button, the goal card, then the milestones and tickets
/// cards, in the order the page shows them.
class _ProjectSkeleton extends StatelessWidget {
  const _ProjectSkeleton();

  @override
  Widget build(BuildContext context) {
    return SkeletonPage(
      children: [
        const Align(alignment: AlignmentDirectional.centerStart, child: SkeletonBone(width: 112, height: 44, radius: AppRadius.pill)),
        const SkeletonSectionHeader(width: 56),
        SkeletonCard(child: SkeletonText(style: context.textTheme.bodyMedium, lines: 3, widthFactor: 0.8)),
        const SkeletonSectionHeader(width: 88),
        const SkeletonGroupedCard(count: 3),
        const SkeletonSectionHeader(width: 64),
        const SkeletonGroupedCard(count: 3),
      ],
    );
  }
}
