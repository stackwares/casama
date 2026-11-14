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

/// Projects (D-113): a goal the lead bot plans and works in sessions until it's met.

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
                icon: LucideIcons.target,
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
                          icon: LucideIcons.target,
                          title: p.title,
                          subtitle: [
                            projectStatusLabel(context, p.status),
                            if (p.budgetUsd != null) '${formatUsd(p.spentUsd, context.l10n.localeName)} / ${formatUsd(p.budgetUsd!, context.l10n.localeName)}' else formatUsd(p.spentUsd, context.l10n.localeName),
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
    final valid = _title.text.trim().isNotEmpty && _goal.text.trim().isNotEmpty && _lead != null;
    VoidCallback? submit;
    return FormSheet(
      icon: LucideIcons.target,
      title: l10n.newProject,
      subtitle: l10n.newProjectHelp,
      submitLabel: l10n.startPlanning,
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
                      goal: _goal.text.trim(),
                      doneCriteria: _done.text.trim(),
                      leadBotId: _lead!,
                      budgetUsd: double.tryParse(_budget.text.trim()),
                    ),
              );
              if (!context.mounted) return;
              setState(() => _busy = false);
              if (p != null) Navigator.pop(context, p.id);
            },
      children: [
        TextField(key: const Key('projectTitle'), controller: _title, textInputAction: TextInputAction.next, autofocus: true, decoration: InputDecoration(labelText: l10n.projectTitle), onChanged: (_) => setState(() {})),
        TextField(key: const Key('projectGoal'), controller: _goal, minLines: 2, maxLines: 6, decoration: InputDecoration(labelText: l10n.projectGoal, hintText: l10n.projectGoalHint), onChanged: (_) => setState(() {})),
        TextField(key: const Key('projectDone'), controller: _done, minLines: 1, maxLines: 4, decoration: InputDecoration(labelText: l10n.projectDoneWhen, helperText: l10n.projectDoneHint)),
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
        final budget = p.budgetUsd;
        return SubPage(
          title: p.title,
          subtitle: projectStatusLabel(context, p.status),
          actions: [
            if (p.conversationId != null)
              IconButton(
                key: const Key('projectThread'),
                tooltip: l10n.projectThread,
                icon: const Icon(LucideIcons.messagesSquare),
                onPressed: () => context.push('/bots/${p.leadBotId}/chat?c=${p.conversationId}'),
              ),
          ],
          children: [
            if (p.statusReason != null) FormNote(p.statusReason!, icon: LucideIcons.info),
            if (p.planStatus == ProjectDetailPlanStatusEnum.proposed)
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
                if (p.status == ProjectStatus.active)
                  OutlinedButton.icon(
                    key: const Key('pauseProject'),
                    onPressed: () => _act(context, ref, () => backend.updateProject(projectId, status: 'paused')),
                    icon: const Icon(LucideIcons.pause, size: 18),
                    label: Text(l10n.pause),
                  ),
                if ((p.status == ProjectStatus.paused || p.status == ProjectStatus.blocked) && p.planStatus == ProjectDetailPlanStatusEnum.approved)
                  OutlinedButton.icon(
                    key: const Key('resumeProject'),
                    onPressed: () => _act(context, ref, () => backend.updateProject(projectId, status: 'active')),
                    icon: const Icon(LucideIcons.play, size: 18),
                    label: Text(l10n.resume),
                  ),
              ],
            ),
            SectionHeader(title: l10n.projectGoal),
            AppCard(padding: const EdgeInsets.all(AppSpace.md), child: ChatMarkdown(data: p.goalMd)),
            if (budget != null) ...[
              SectionHeader(title: l10n.projectBudget),
              LinearProgressIndicator(key: const Key('projectSpend'), value: (p.spentUsd / budget).clamp(0, 1).toDouble()),
              const SizedBox(height: AppSpace.xs),
              Text('${formatUsd(p.spentUsd, context.l10n.localeName)} / ${formatUsd(budget, context.l10n.localeName)}', style: const TextStyle(fontFeatures: AppText.tabular)),
            ],
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
            if (p.planMd.isNotEmpty) ...[
              SectionHeader(title: l10n.projectPlan),
              AppCard(padding: const EdgeInsets.all(AppSpace.md), child: ChatMarkdown(data: p.planMd)),
            ],
            SectionHeader(title: l10n.tickets),
            GroupedCard(
              children: [
                for (final t in tickets)
                  GroupedTile(
                    icon: t.status == TaskStatus.done ? LucideIcons.circleCheck : LucideIcons.circle,
                    title: t.title,
                    subtitle: t.status.value,
                    onTap: () => context.push('/tasks'),
                  ),
              ],
            ),
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
