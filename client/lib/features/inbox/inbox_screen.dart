import 'dart:async';

import 'dart:convert';

import 'package:flutter/material.dart';
import 'for_you.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/backend.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/app_card.dart';
import '../../ui/bot_avatar.dart';
import '../../ui/page.dart';
import '../../ui/shell_header.dart';
import '../../ui/glow_button.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/form_sheet.dart';

/// Approvals waiting for you, notifications, and the shared task board.
class InboxScreen extends ConsumerWidget {
  /// -1: For you (D-114), 0: approvals, 1: notifications.
  const InboxScreen({super.key, this.initialTab = -1});
  final int initialTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final pending = ref.watch(approvalsProvider).value?.length ?? 0;
    return DefaultTabController(
      length: 3,
      initialIndex: (initialTab + 1).clamp(0, 2),
      child: Scaffold(
        appBar: ShellHeader(
          title: l10n.inbox,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(52),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpace.sm, 0, AppSpace.sm, AppSpace.xs),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  padding: EdgeInsets.zero,
                  tabs: [
                    Tab(key: const Key('tabForYou'), height: 40, text: l10n.forYou),
                    Tab(height: 40, text: pending == 0 ? l10n.approvals : l10n.approvalsCount(pending)),
                    Tab(height: 40, text: l10n.notifications),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: const TabBarView(children: [ForYouList(), ApprovalsList(), NotificationsList()]),
      ),
    );
  }
}

class ApprovalsList extends ConsumerWidget {
  const ApprovalsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final takeovers = ref.watch(takeoversProvider).value ?? const <TakeoverRequest>[];
    return AsyncView(
      value: ref.watch(approvalsProvider),
      onRetry: () => ref.invalidate(approvalsProvider),
      data: (items) => items.isEmpty && takeovers.isEmpty
          ? EmptyState(icon: LucideIcons.shieldCheck, title: l10n.noApprovals, message: l10n.noApprovalsHelp)
          : RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(approvalsProvider);
                ref.invalidate(takeoversProvider);
              },
              child: LayoutBuilder(
                builder: (context, constraints) => ListView(
                  padding: EdgeInsets.fromLTRB(
                    pageSide(constraints.maxWidth),
                    AppSpace.xs,
                    pageSide(constraints.maxWidth),
                    AppSpace.xl + MediaQuery.paddingOf(context).bottom,
                  ),
                  children: [
                    for (final t in takeovers)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpace.sm),
                        child: TakeoverCard(takeover: t),
                      ),
                    for (final (i, a) in items.indexed)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpace.sm),
                        child: ApprovalCard(approval: a).appListItemEntrance(i),
                      ),
                  ],
                ),
              ),
            ),
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
          Wrap(
            alignment: WrapAlignment.end,
            spacing: AppSpace.xs,
            runSpacing: AppSpace.xs,
            children: [
              TextButton.icon(
                onPressed: () => context.push('/bots/${a.botId}/runs/${a.runId}'),
                icon: const Icon(LucideIcons.activity, size: 18),
                label: Text(l10n.viewRun),
              ),
              TextButton(key: const Key('alwaysAllow'), onPressed: _busy ? null : () => _decide(true, always: true), child: Text(l10n.alwaysAllow)),
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

class NotificationsList extends ConsumerWidget {
  const NotificationsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final value = ref.watch(notificationsProvider);
    final hasUnread = (value.value ?? const <NotificationView>[]).any((n) => n.readAt == null);
    return AsyncView(
      value: value,
      onRetry: () => ref.invalidate(notificationsProvider),
      data: (items) => items.isEmpty
          ? EmptyState(icon: LucideIcons.bell, title: l10n.noNotifications, message: l10n.noNotificationsHelp)
          : RefreshIndicator(
              onRefresh: () async => ref.invalidate(notificationsProvider),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final side = pageSide(constraints.maxWidth);
                  return ListView(
                    padding: EdgeInsets.fromLTRB(side, AppSpace.xxs, side, AppSpace.xl + MediaQuery.paddingOf(context).bottom),
                    children: [
                      if (hasUnread)
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: TextButton.icon(
                            onPressed: () => runGuarded(context, ref.read(notificationsProvider.notifier).markAllRead),
                            icon: const Icon(LucideIcons.checkCheck, size: 18),
                            label: Text(l10n.markAllRead),
                          ),
                        ),
                      GroupedCard(children: [for (final n in items) _NotificationRow(notification: n)]),
                    ],
                  );
                },
              ),
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
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: context.isDark ? 0.2 : 0.12),
                borderRadius: BorderRadius.circular(AppRadius.icon),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 19, color: color),
            ),
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
                      Text(relativeTime(n.createdAt, context), style: context.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
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
                    Text(relativeTime(takeover.createdAt, context), style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: AppSpace.xs,
            runSpacing: AppSpace.xs,
            children: [
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
        Text(n.whyRule ?? '', key: const Key('whyRule'), style: context.textTheme.bodyLarge),
        if (n.whyData.isNotEmpty) Text(l10n.whyData(n.whyData.join(', ')), style: context.textTheme.bodyMedium),
        if (n.urgency != null) Text(l10n.whyUrgency(n.urgency!), style: context.textTheme.bodySmall),
        if (held != null) Text(held, key: const Key('whyHeld'), style: context.textTheme.bodySmall),
      ],
    );
  }
}
