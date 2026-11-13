import 'dart:async';

import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/backend.dart';
import '../../core/display_text.dart';
import '../../core/number_format.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../core/haptics.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/action_buttons.dart';
import '../../ui/app_card.dart';
import '../../ui/edge_fade.dart';
import '../../ui/reveal_when_selected.dart';
import '../../ui/bot_avatar.dart';
import '../../ui/page.dart';
import '../../ui/tab_reselect.dart';
import '../../ui/shell_header.dart';
import '../../ui/glow_button.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/form_sheet.dart';
import '../library/library_links.dart';
import '../pages/pages_screen.dart';
import '../skills/skill_proposals.dart';
import 'for_you.dart';

/// What the Inbox shows: everything, only what waits on a decision, morning briefs, or updates
/// (D-253: what isn't already in a bot's chat). Pages moved to the Library (D-274).
enum InboxFilter {
  all,
  needsYou,
  briefs,
  updates;

  /// From Chats (D-253): `/inbox?tab=0` is Needs you, `/inbox` the Updates row.
  static InboxFilter fromTab(String? tab) => tab == '0' ? needsYou : updates;
}

/// Requests waiting for you (approvals, takeovers, suggestions, skill ideas), then morning briefs,
/// notifications and new pages in one list, with filter chips.
class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key, this.initialFilter = InboxFilter.all, this.title});
  final InboxFilter initialFilter;

  /// Opened from Chats (D-253): "Needs you", or "Casama" for updates.
  final String? title;

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  late var _filter = widget.initialFilter;

  @override
  void initState() {
    super.initState();
    // What the Inbox showed last time stays while it reloads, so opening it never flashes empty.
    refreshKeptOnOpen(context, [forYouProvider, skillProposalsProvider, pagesProvider(null)]);
  }

  @override
  void didUpdateWidget(InboxScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialFilter != widget.initialFilter) _filter = widget.initialFilter;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final needsYou = ref.watch(needsYouCountProvider);
    String label(InboxFilter f) => switch (f) {
      InboxFilter.all => l10n.filterAll,
      InboxFilter.needsYou => needsYou == 0 ? l10n.inboxNeedsYou : l10n.inboxNeedsYouCount(needsYou),
      InboxFilter.briefs => l10n.inboxBriefs,
      InboxFilter.updates => l10n.inboxUpdates,
    };
    // Opened from Chats (D-253): Needs you and Updates are one list each.
    final chips = switch (widget.initialFilter) {
      InboxFilter.needsYou when widget.title != null => const <InboxFilter>[],
      InboxFilter.updates => const <InboxFilter>[],
      _ => const [InboxFilter.all, InboxFilter.needsYou, InboxFilter.briefs],
    };
    // The iOS status bar scrolls the feed to the top.
    return PrimaryScrollController(
      controller: TabReselect.inbox,
      child: Scaffold(
      appBar: ShellHeader(
        title: widget.title ?? l10n.inbox,
        phoneFallback: '/bots',
        bottom: chips.isEmpty ? null : PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: SizedBox(
            height: 52,
            // Scrolls sideways, so the chips never wrap or overflow on a small phone.
            child: EdgeFade(child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(AppSpace.md, 0, AppSpace.md, AppSpace.xxs),
              child: Row(
                spacing: AppSpace.xs,
                children: [
                  for (final f in chips)
                    RevealWhenSelected(selected: _filter == f, child: ChoiceChip(
                      key: Key('inboxFilter-${f.name}'),
                      showCheckmark: false,
                      label: Text(label(f), style: const TextStyle(fontFeatures: AppText.tabular)),
                      selected: _filter == f,
                      onSelected: (_) => setState(() => _filter = f),
                    )),
                ],
              ),
            )),
          ),
        ),
      ),
      body: _InboxFeed(filter: _filter),
    ),
    );
  }
}

/// Whether [n] asks for a decision that is still waiting in Needs you, so Updates doesn't show it
/// twice. Answered requests stay in Updates.
bool _waitingAbove(NotificationView n, Set<String> approvalIds, Set<String> takeoverIds) {
  if (!n.isRequest || n.link == null) return false;
  final uri = Uri.tryParse(n.link!);
  if (uri == null) return false;
  final path = uri.pathSegments;
  if (path.length == 2 && path.first == 'approvals') return approvalIds.contains(path[1]);
  final takeover = uri.queryParameters['takeover'];
  return takeover != null && takeoverIds.contains(takeover);
}

/// The All, Needs you and Briefs filters of the Inbox.
class _InboxFeed extends ConsumerWidget {
  const _InboxFeed({required this.filter});
  final InboxFilter filter;

  /// How far back published pages show among the updates (the Library lists them all).
  static const _recentPages = Duration(days: 7);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final all = filter == InboxFilter.all;
    // The Updates row (D-253): notices and pages that aren't already in a bot's chat; no decisions.
    final updatesOnly = filter == InboxFilter.updates;
    final withNotes = all || updatesOnly;
    final approvals = ref.watch(approvalsProvider);
    final forYou = ref.watch(forYouProvider);
    final notifications = ref.watch(notificationsProvider);
    final takeovers = ref.watch(takeoversProvider).value ?? const <TakeoverRequest>[];
    final proposals = ref.watch(skillProposalsProvider).value ?? const <SkillProposal>[];
    final pages = withNotes ? ref.watch(pagesProvider(null)).value ?? const <BotPage>[] : const <BotPage>[];
    final bots = ref.watch(botsProvider).value ?? const <Bot>[];
    String botName(String id) => bots.where((b) => b.id == id).firstOrNull?.name ?? '';

    // The lists this filter is made of; the rest fill in when they arrive.
    final sources = <AsyncValue<Object?>>[
      if (filter != InboxFilter.briefs && !updatesOnly) approvals,
      if (!updatesOnly) forYou,
      if (withNotes) notifications,
    ];
    final failed = sources.where((s) => s.hasError && !s.hasValue).toList();
    final AsyncValue<void> state = sources.any((s) => s.isLoading && !s.hasValue)
        ? const AsyncLoading()
        : failed.length == sources.length
        ? AsyncError(failed.first.error!, failed.first.stackTrace ?? StackTrace.current)
        : const AsyncData(null);

    Future<void> refresh() async {
      ref.invalidate(approvalsProvider);
      ref.invalidate(takeoversProvider);
      ref.invalidate(forYouProvider);
      ref.invalidate(skillProposalsProvider);
      if (withNotes) {
        ref.invalidate(notificationsProvider);
        ref.invalidate(pagesProvider(null));
      }
    }

    return AsyncView(
      value: state,
      onRetry: refresh,
      loading: _InboxSkeleton(filter: filter),
      data: (_) {
        final pending = approvals.value ?? const <Approval>[];
        final suggestions = forYou.value?.suggestions ?? const <Suggestion>[];
        final decisions = filter == InboxFilter.briefs || updatesOnly
            ? const <Widget>[]
            : <Widget>[
                for (final t in takeovers)
                  Padding(
                    key: ValueKey(('takeover', t.id)),
                    padding: const EdgeInsets.only(bottom: AppSpace.sm),
                    child: TakeoverCard(takeover: t),
                  ),
                for (final (i, a) in pending.indexed)
                  Padding(
                    key: ValueKey(('approval', a.id)),
                    padding: const EdgeInsets.only(bottom: AppSpace.sm),
                    child: ApprovalCard(approval: a).appListItemEntrance(i),
                  ),
                for (final s in suggestions) SuggestionCard(key: ValueKey(('suggestion', s.id)), s: s, botName: botName(s.botId)),
                for (final p in proposals) SkillProposalCard(key: ValueKey(('proposal', p.id)), proposal: p, botName: botName(p.botId)),
              ];

        // Updates: briefs, notifications and new pages, newest first.
        final approvalIds = {for (final a in pending) a.id};
        final takeoverIds = {for (final t in takeovers) t.id};
        final notes = withNotes
            ? [
                for (final n in notifications.value ?? const <NotificationView>[])
                  if (!_waitingAbove(n, approvalIds, takeoverIds) && (!updatesOnly || isUpdateRowNotification(n))) n,
              ]
            : const <NotificationView>[];
        final since = DateTime.now().subtract(_recentPages);
        final updates = <(DateTime, Object)>[
          if (filter != InboxFilter.needsYou && !updatesOnly)
            for (final b in forYou.value?.briefs ?? const <ForYouBrief>[]) (b.createdAt, b),
          for (final n in notes) (n.createdAt, n),
          for (final p in pages)
            if (p.createdAt.isAfter(since)) (p.createdAt, p),
        ]..sort((a, b) => b.$1.compareTo(a.$1));
        // Rows in a row share one card; a brief breaks the run with its own card.
        final updateWidgets = <Widget>[];
        var rows = <Widget>[];
        void flushRows() {
          if (rows.isEmpty) return;
          updateWidgets.add(Padding(padding: const EdgeInsets.only(bottom: AppSpace.sm), child: GroupedCard(children: rows)));
          rows = [];
        }

        for (final (_, item) in updates) {
          switch (item) {
            case ForYouBrief b:
              flushRows();
              updateWidgets.add(Padding(key: ValueKey(('brief', b.botId)), padding: const EdgeInsets.only(bottom: AppSpace.sm), child: BriefCard(brief: b)));
            case NotificationView n:
              rows.add(_NotificationRow(notification: n));
            case BotPage p:
              rows.add(_PageUpdateRow(page: p, botName: botName(p.botId)));
          }
        }
        flushRows();

        final hasUnread = notes.any((n) => n.readAt == null);
        final children = <Widget>[
          if (failed.isNotEmpty) Padding(padding: const EdgeInsets.only(bottom: AppSpace.sm), child: InlineError(error: failed.first.error!, onRetry: refresh)),
          if (all && decisions.isNotEmpty) SectionHeader(title: l10n.inboxNeedsYou, count: decisions.length.humanizedCount(context.l10n.localeName), padding: const EdgeInsets.fromLTRB(AppSpace.xxs, AppSpace.xs, AppSpace.xxs, AppSpace.xs)),
          ...decisions,
          if (withNotes && updateWidgets.isNotEmpty)
            SectionHeader(
              title: l10n.inboxUpdates,
              padding: EdgeInsets.fromLTRB(AppSpace.xxs, decisions.isEmpty ? AppSpace.xs : AppSpace.lg, AppSpace.xxs, AppSpace.xs),
              trailing: hasUnread
                  ? TextButton.icon(
                      key: const Key('markAllRead'),
                      onPressed: () => runGuarded(context, ref.read(notificationsProvider.notifier).markAllRead),
                      icon: const Icon(LucideIcons.checkCheck, size: 18),
                      label: Text(l10n.markAllRead),
                    )
                  : null,
            ),
          ...updateWidgets,
        ];
        if (children.isEmpty) {
          return switch (filter) {
            InboxFilter.needsYou => EmptyState(icon: LucideIcons.circleCheckBig, title: l10n.inboxNeedsYouEmpty, message: l10n.inboxNeedsYouEmptyHelp),
            InboxFilter.briefs => EmptyState(icon: LucideIcons.sun, title: l10n.noBriefs, message: l10n.forYouEmptyHelp),
            InboxFilter.updates => EmptyState(icon: LucideIcons.bell, title: l10n.updatesEmpty, message: l10n.updatesEmptyHelp),
            _ => EmptyState(icon: LucideIcons.inbox, title: l10n.forYouEmpty, message: l10n.inboxEmptyHelp),
          };
        }
        return RefreshIndicator(
          onRefresh: () {
            HapticsHelper.medium();
            return refresh();
          },
          child: LayoutBuilder(
            builder: (context, constraints) {
              final side = pageSide(constraints.maxWidth);
              return ListView(
                // Ends above the floating tab bar (the shell sets the bottom padding to its height).
                padding: EdgeInsets.fromLTRB(side, AppSpace.xs, side, AppSpace.xl + MediaQuery.paddingOf(context).bottom),
                children: children,
              );
            },
          ),
        );
      },
    );
  }
}

/// "Ada published Weekly sales" among the updates; opens it in the Library (D-274), or in the
/// browser when the Library can't find it.
class _PageUpdateRow extends ConsumerWidget {
  const _PageUpdateRow({required this.page, required this.botName});
  final BotPage page;
  final String botName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final p = page;
    return InkWell(
      key: Key('pageUpdate-${p.id}'),
      onTap: () async {
        final c = await findCreation(ref, pageId: p.id, title: p.title);
        if (!context.mounted) return;
        if (c != null) {
          unawaited(context.push('/library/${c.id}'));
        } else {
          await openBotPage(context, ref, p);
        }
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpace.md, 12, AppSpace.md, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _RowIcon(icon: LucideIcons.fileText, color: scheme.primary),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          l10n.botPublishedPage(botName.isEmpty ? l10n.aBot : botName, p.title),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                        ),
                      ),
                      const SizedBox(width: AppSpace.xs),
                      TimeAgo(p.createdAt, style: context.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    switch (p.visibility) {
                      BotPageVisibilityEnum.public => l10n.pagePublic,
                      BotPageVisibilityEnum.workspace => l10n.pageWorkspace,
                      _ => l10n.pagePrivate,
                    },
                    style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant, height: 1.35),
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

/// The inbox feed still loading, in the filter's shape: approval cards under Needs you, then a
/// card of update rows (All); approval cards alone (Needs you); brief cards (Briefs).
class _InboxSkeleton extends StatelessWidget {
  const _InboxSkeleton({required this.filter});
  final InboxFilter filter;

  @override
  Widget build(BuildContext context) {
    Widget gapped(Widget w) => Padding(padding: const EdgeInsets.only(bottom: AppSpace.sm), child: w);
    return SkeletonPage(
      children: switch (filter) {
        InboxFilter.needsYou => [gapped(const _ApprovalCardSkeleton()), gapped(const _ApprovalCardSkeleton())],
        InboxFilter.briefs => [gapped(const _BriefCardSkeleton()), gapped(const _BriefCardSkeleton())],
        _ => [
          const SkeletonSectionHeader(width: 84, padding: EdgeInsets.fromLTRB(AppSpace.xxs, AppSpace.xs, AppSpace.xxs, AppSpace.xs)),
          gapped(const _ApprovalCardSkeleton()),
          const SkeletonSectionHeader(width: 72),
          gapped(
            SkeletonGroupedCard(
              count: 3,
              row: SkeletonRow(
                leadingSize: 36,
                trailing: SkeletonTrailing.meta,
                subtitleLines: 2,
                padding: const EdgeInsets.fromLTRB(AppSpace.md, 12, AppSpace.md, 12),
                titleStyle: context.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                subtitleStyle: context.textTheme.bodySmall?.copyWith(height: 1.35),
              ),
            ),
          ),
        ],
      },
    );
  }
}

/// An [ApprovalCard] still loading: avatar and request, the risk pill, the arguments box and
/// the buttons.
class _ApprovalCardSkeleton extends StatelessWidget {
  const _ApprovalCardSkeleton();

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;
    return SkeletonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SkeletonBone(width: 36, height: 36, radius: 18),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SkeletonText(style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700, height: 1.3), widthFactor: 0.72),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const SkeletonBone(width: 64, height: 22, radius: AppRadius.pill),
                        const SizedBox(width: AppSpace.xs),
                        Expanded(child: SkeletonText(style: text.bodySmall, widthFactor: 0.6)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          const SkeletonBone(height: 96, radius: 10),
          const SizedBox(height: AppSpace.sm),
          const Row(
            spacing: AppSpace.xs,
            children: [
              Expanded(child: SkeletonBone(height: 44, radius: AppRadius.pill)),
              Expanded(child: SkeletonBone(height: 44, radius: AppRadius.pill)),
            ],
          ),
          const SizedBox(height: AppSpace.xxs),
          const SizedBox(
            height: 40,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: AppSpace.md,
              children: [SkeletonBone(width: 88, height: 12), SkeletonBone(width: 72, height: 12)],
            ),
          ),
        ],
      ),
    );
  }
}

/// A [BriefCard] still loading: the bot's avatar and heading, then a few lines of the brief.
class _BriefCardSkeleton extends StatelessWidget {
  const _BriefCardSkeleton();

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;
    return SkeletonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpace.sm,
        children: [
          Row(
            children: [
              const SkeletonBone(width: 28, height: 28, radius: 14),
              const SizedBox(width: AppSpace.sm),
              Expanded(child: SkeletonText(style: text.titleSmall, widthFactor: 0.5)),
              const SkeletonBone(width: 36, height: 10),
            ],
          ),
          SkeletonText(style: text.bodyMedium, lines: 4, widthFactor: 0.8),
        ],
      ),
    );
  }
}

/// The tinted icon tile at the start of an update row.
class _RowIcon extends StatelessWidget {
  const _RowIcon({required this.icon, required this.color});
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: context.isDark ? 0.2 : 0.12),
        borderRadius: BorderRadius.circular(AppRadius.icon),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 19, color: color),
    );
  }
}

/// One approval request with approve, deny and "always allow".
class ApprovalCard extends ConsumerStatefulWidget {
  const ApprovalCard({super.key, required this.approval, this.onDecided});
  final Approval approval;
  final VoidCallback? onDecided;

  @override
  ConsumerState<ApprovalCard> createState() => _ApprovalCardState();
}

class _ApprovalCardState extends ConsumerState<ApprovalCard> {
  var _busy = false;

  Future<void> _decide(bool approve, {bool always = false}) async {
    final l10n = context.l10n;
    setState(() => _busy = true);
    final ok = await runGuarded(context, () async {
      await ref.read(backendProvider).decideApproval(widget.approval.id, approve: approve, alwaysAllow: always);
      return true;
    });
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok == true) {
      ref.invalidate(approvalsProvider);
      ref.invalidate(notificationsProvider);
      showMessage(context, approve ? l10n.approved : l10n.denied);
      widget.onDecided?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final colors = context.appColors;
    final a = widget.approval;
    final bot = ref.watch(botProvider(a.botId));
    final riskColor = switch (a.risk) {
      Risk.high => colors.negative,
      Risk.medium => colors.warning,
      Risk.low => colors.info,
    };
    final args = const JsonEncoder.withIndent('  ').convert(a.argsRedacted);
    return AppCard(
      key: Key('approval-${a.id}'),
      borderColor: riskColor.withValues(alpha: context.isDark ? 0.35 : 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BotAvatar(name: bot?.name ?? '?', avatar: bot?.avatarUrl, size: 36),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.botWantsTo(bot?.name ?? l10n.aBot, a.summary),
                      style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, height: 1.3),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: AppSpace.xs,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        StatusLabel(
                          text: switch (a.risk) {
                            Risk.high => l10n.riskHigh,
                            Risk.medium => l10n.riskMedium,
                            Risk.low => l10n.riskLow,
                          },
                          color: riskColor,
                          pill: true,
                        ),
                        Text(
                          '${a.toolName} · ${l10n.requestedAgo(relativeTime(a.createdAt, context))}',
                          style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: colors.codeBackground,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colors.hairline),
            ),
            child: SingleChildScrollView(child: SelectableText(args, style: AppText.mono.copyWith(fontSize: 12.5))),
          ),
          const SizedBox(height: AppSpace.sm),
          ActionButtons(
            actions: [
              OutlinedButton.icon(
                key: const Key('deny'),
                onPressed: _busy ? null : () => _decide(false),
                icon: const Icon(LucideIcons.x, size: 18),
                label: Text(l10n.deny),
              ),
              GlowButton.icon(
                key: const Key('approve'),
                onPressed: _busy ? null : () => _decide(true),
                icon: const Icon(LucideIcons.check, size: 18),
                label: Text(l10n.approve),
              ),
            ],
            extra: [
              TextButton(
                key: const Key('alwaysAllow'),
                onPressed: _busy ? null : () => _decide(true, always: true),
                style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                child: Text(l10n.alwaysAllow),
              ),
              TextButton.icon(
                onPressed: () => context.push('/bots/${a.botId}/runs/${a.runId}'),
                style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                icon: const Icon(LucideIcons.activity, size: 18),
                label: Text(l10n.viewRun),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Deep link target for /approvals/:id (push notifications open this).
class ApprovalScreen extends ConsumerWidget {
  const ApprovalScreen({super.key, required this.approvalId});
  final String approvalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return SubPage(
      title: l10n.approval,
      body: AsyncView(
        value: ref.watch(approvalsProvider),
        onRetry: () => ref.invalidate(approvalsProvider),
        loading: const SkeletonPage(children: [_ApprovalCardSkeleton()]),
        data: (items) {
          final match = items.where((a) => a.id == approvalId);
          if (match.isEmpty) {
            return EmptyState(
              icon: LucideIcons.circleCheckBig,
              message: l10n.approvalAlreadyDecided,
              action: FilledButton.tonalIcon(onPressed: () => context.go('/inbox'), icon: const Icon(LucideIcons.inbox, size: 18), label: Text(l10n.openInbox)),
            );
          }
          return PageColumn(children: [ApprovalCard(approval: match.first)]);
        },
      ),
    );
  }
}

class _NotificationRow extends ConsumerWidget {
  const _NotificationRow({required this.notification});
  final NotificationView notification;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = context.colorScheme;
    final colors = context.appColors;
    final n = notification;
    final unread = n.readAt == null;
    final (icon, color) = switch (n.kind) {
      'approval' => (LucideIcons.shieldCheck, colors.warning),
      'routine' || 'routine_result' => (LucideIcons.clock, colors.info),
      'budget' => (LucideIcons.banknote, colors.negative),
      'takeover' => (LucideIcons.hand, colors.waiting),
      _ => (LucideIcons.bell, scheme.primary),
    };
    return InkWell(
      key: Key('notification-${n.id}'),
      onTap: () {
        if (unread) unawaited(ref.read(notificationsProvider.notifier).markRead(n.id).catchError((_) {}));
        if (n.link != null && n.link!.startsWith('/')) context.push(n.link!);
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpace.md, 12, AppSpace.md, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _RowIcon(icon: icon, color: color),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          n.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.bodyLarge?.copyWith(fontWeight: unread ? FontWeight.w700 : FontWeight.w500),
                        ),
                      ),
                      const SizedBox(width: AppSpace.xs),
                      // "Why am I seeing this?" (D-153) on proactive messages.
                      if (n.whyRule != null)
                        InkWell(
                          key: Key('why-${n.id}'),
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => showAdaptiveSheet<void>(context: context, builder: (_) => WhySheet(notification: n)),
                          child: Padding(padding: const EdgeInsets.all(4), child: Icon(LucideIcons.info, size: 16, color: scheme.onSurfaceVariant)),
                        ),
                      TimeAgo(n.createdAt, style: context.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
                      if (unread) ...[
                        const SizedBox(width: 6),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(color: scheme.primary, shape: BoxShape.circle),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    n.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant, height: 1.35),
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

/// A bot asking for a person to take over its screen.
class TakeoverCard extends ConsumerWidget {
  const TakeoverCard({super.key, required this.takeover});
  final TakeoverRequest takeover;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final color = context.appColors.waiting;
    final bot = ref.watch(botProvider(takeover.botId));
    return AppCard(
      key: Key('takeover-${takeover.id}'),
      borderColor: color.withValues(alpha: 0.45),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  BotAvatar(name: bot?.name ?? '?', avatar: bot?.avatarUrl, size: 36),
                  Positioned(
                    right: -4,
                    bottom: -4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(color: scheme.surface, width: 2),
                      ),
                      child: const Icon(LucideIcons.hand, size: 10, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.botNeedsHelp(bot?.name ?? l10n.aBot), style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, height: 1.3)),
                    const SizedBox(height: 4),
                    Text(takeover.reason, style: context.textTheme.bodyMedium?.copyWith(height: 1.4)),
                    const SizedBox(height: 4),
                    TimeAgo(takeover.createdAt, style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          ActionButtons(
            actions: [
              OutlinedButton(
                key: const Key('dismissTakeover'),
                onPressed: () async {
                  await runGuarded(context, () => ref.read(backendProvider).dismissTakeover(takeover.id));
                  ref.invalidate(takeoversProvider);
                },
                child: Text(l10n.dismiss),
              ),
              GlowButton.icon(
                key: const Key('openTakeover'),
                onPressed: () => context.push('/computer/live?c=${takeover.computerId}&takeover=${takeover.id}'),
                icon: const Icon(LucideIcons.mousePointer2, size: 18),
                label: Text(l10n.takeControl),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// "Why am I seeing this?" (D-153): the rule and the data behind a proactive message, whether it
/// waited for the brief, and "Less like this".
class WhySheet extends ConsumerStatefulWidget {
  const WhySheet({super.key, required this.notification});
  final NotificationView notification;
  @override
  ConsumerState<WhySheet> createState() => _WhySheetState();
}

class _WhySheetState extends ConsumerState<WhySheet> {
  var _sent = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final n = widget.notification;
    final held = switch (n.heldReason) {
      'meeting' => l10n.heldMeeting,
      'focus' => l10n.heldFocus,
      'driving' => l10n.heldDriving,
      'daily_cap' => l10n.heldCap,
      'low_urgency' => l10n.heldLow,
      _ => null,
    };
    return FormSheet(
      icon: LucideIcons.info,
      title: l10n.whyTitle,
      submitLabel: _sent ? l10n.lessLikeThisDone : l10n.lessLikeThis,
      submitKey: const Key('lessLikeThis'),
      onSubmit: _sent
          ? null
          : () async {
              final ok = await runGuarded(context, () async {
                await ref.read(backendProvider).lessLikeThis(n.id);
                return true;
              });
              if (ok == true && mounted) setState(() => _sent = true);
            },
      children: [
        if (n.whyRule.isUsable) Text(n.whyRule!, key: const Key('whyRule'), style: context.textTheme.bodyLarge),
        if (n.whyData.isNotEmpty) Text(l10n.whyData(n.whyData.join(', ')), style: context.textTheme.bodyMedium),
        if (n.urgency.isUsable) Text(l10n.whyUrgency(n.urgency!), style: context.textTheme.bodySmall),
        if (held != null) Text(held, key: const Key('whyHeld'), style: context.textTheme.bodySmall),
      ],
    );
  }
}
