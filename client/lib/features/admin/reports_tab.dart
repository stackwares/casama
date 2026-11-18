import 'package:casama_sdk/casama_sdk.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/app_card.dart';
import '../../ui/form_sheet.dart';
import '../../ui/page.dart';
import '../moderation/report_sheet.dart';

final _contentReportsProvider = FutureProvider.autoDispose<List<ContentReport>>(
  (r) => r.watch(backendProvider).adminContentReports(),
);
final _reportedLinksProvider =
    FutureProvider.autoDispose<List<ReportedCreation>>(
      (r) => r.watch(backendProvider).adminReportedLinks(),
    );
final _ticketsProvider = FutureProvider.autoDispose
    .family<List<SupportTicketRow>, String>(
      (r, status) =>
          r.watch(backendProvider).adminSupportTickets(status: status),
    );
final _supportWebProvider = FutureProvider.autoDispose<SupportWebStats>(
  (r) => r.watch(backendProvider).adminSupportWebStats(),
);

String _when(DateTime d) =>
    d.toLocal().toIso8601String().replaceFirst('T', ' ').substring(0, 16);

/// Admin console > Reports (D-301): what people reported inside the app, then public links people
/// reported (D-281). Each report can be acted on (optionally suspending the workspace) or dismissed.
class ReportsTab extends ConsumerWidget {
  const ReportsTab({super.key});

  String _kind(BuildContext context, ReportTargetKind k) => switch (k) {
    ReportTargetKind.message => context.l10n.reportKindReply,
    ReportTargetKind.bot => context.l10n.reportKindBot,
    ReportTargetKind.user => context.l10n.reportKindPerson,
    ReportTargetKind.galleryItem => context.l10n.reportKindGallery,
    ReportTargetKind.workspace => context.l10n.reportKindWorkspace,
  };

  Future<void> _review(
    BuildContext context,
    WidgetRef ref,
    ContentReport r,
  ) async {
    final l10n = context.l10n;
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              key: const Key('reviewActioned'),
              leading: const Icon(LucideIcons.check),
              title: Text(l10n.reportMarkActioned),
              onTap: () => Navigator.pop(c, 'actioned'),
            ),
            if (r.targetOrgId != null)
              ListTile(
                key: const Key('reviewSuspend'),
                leading: Icon(
                  LucideIcons.ban,
                  color: context.colorScheme.error,
                ),
                title: Text(l10n.reportSuspendWorkspace(r.targetOrgName ?? '')),
                onTap: () => Navigator.pop(c, 'suspend'),
              ),
            ListTile(
              key: const Key('reviewDismiss'),
              leading: const Icon(LucideIcons.x),
              title: Text(l10n.reportDismiss),
              onTap: () => Navigator.pop(c, 'dismiss'),
            ),
          ],
        ),
      ),
    );
    if (choice == null || !context.mounted) return;
    final ok = await runGuarded(context, () async {
      await ref
          .read(backendProvider)
          .reviewContentReport(
            r.id,
            actioned: choice != 'dismiss',
            suspendWorkspace: choice == 'suspend',
          );
      return true;
    });
    if (ok == true) ref.invalidate(_contentReportsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final reports = ref.watch(_contentReportsProvider);
    final links = ref.watch(_reportedLinksProvider);
    return AsyncView<List<ContentReport>>(
      value: reports,
      onRetry: () => ref.invalidate(_contentReportsProvider),
      loading: const SkeletonPage(
        children: [
          SkeletonGroupedCard(
            count: 4,
            row: SkeletonRow(trailing: SkeletonTrailing.none),
          ),
        ],
      ),
      data: (items) => PageColumn(
        children: [
          SectionHeader(title: l10n.reportsInApp, count: '${items.length}'),
          if (items.isEmpty)
            AppCard(
              child: FormNote(l10n.reportsNone, icon: LucideIcons.shieldCheck),
            )
          else
            GroupedCard(
              children: [
                for (final r in items)
                  GroupedTile(
                    key: Key('contentReport-${r.id}'),
                    icon: LucideIcons.flag,
                    iconColor: r.sameTarget >= 3
                        ? scheme.error
                        : context.appColors.warning,
                    title:
                        '${_kind(context, r.targetKind)} · ${reportReasonLabel(context, r.reason)}${r.sameTarget > 1 ? ' · ${l10n.reportsCount(r.sameTarget)}' : ''}',
                    subtitle: [
                      if (r.snapshot case final String s when s.isNotEmpty)
                        s.length > 160 ? '${s.substring(0, 160)}…' : s,
                      if (r.note case final String n when n.isNotEmpty) '“$n”',
                      [
                        ?r.targetOrgName,
                        ?r.reporterEmail,
                        _when(r.createdAt),
                      ].join(' · '),
                    ].join('\n'),
                    onTap: () => _review(context, ref, r),
                  ),
              ],
            ),
          const SizedBox(height: AppSpace.md),
          SectionHeader(title: l10n.reportsPublicLinks),
          links.when(
            loading: () => const SkeletonGroupedCard(
              count: 2,
              row: SkeletonRow(trailing: SkeletonTrailing.none),
            ),
            error: (e, _) => AppCard(
              child: FormNote(
                errorText(context, e),
                icon: LucideIcons.circleAlert,
              ),
            ),
            data: (list) => list.isEmpty
                ? AppCard(
                    child: FormNote(
                      l10n.reportsNoLinks,
                      icon: LucideIcons.shieldCheck,
                    ),
                  )
                : GroupedCard(
                    children: [
                      for (final c in list)
                        GroupedTile(
                          key: Key('reportedLink-${c.id}'),
                          icon: c.takenDown
                              ? LucideIcons.eyeOff
                              : LucideIcons.link,
                          title: c.title,
                          subtitle:
                              '${c.orgName} · ${l10n.reportsCount(c.reports)} · ${c.lastReason}',
                          showChevron: false,
                          trailing: TextButton(
                            onPressed: () async {
                              final ok = await runGuarded(context, () async {
                                await ref
                                    .read(backendProvider)
                                    .takeDownLink(c.id, !c.takenDown);
                                return true;
                              });
                              if (ok == true) {
                                ref.invalidate(_reportedLinksProvider);
                              }
                            },
                            child: Text(
                              c.takenDown
                                  ? l10n.reportsRestore
                                  : l10n.reportsTakeDown,
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

/// Admin console > Support (D-303): messages people sent from Help & support. The messages
/// themselves are in the support inbox; this is the list to keep track of them.
class SupportTicketsTab extends ConsumerStatefulWidget {
  const SupportTicketsTab({super.key});

  @override
  ConsumerState<SupportTicketsTab> createState() => _SupportTicketsTabState();
}

class _SupportTicketsTabState extends ConsumerState<SupportTicketsTab> {
  var _status = 'open';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AsyncView<List<SupportTicketRow>>(
      value: ref.watch(_ticketsProvider(_status)),
      onRetry: () => ref.invalidate(_ticketsProvider(_status)),
      loading: const SkeletonPage(
        children: [
          SkeletonGroupedCard(
            count: 4,
            row: SkeletonRow(trailing: SkeletonTrailing.none),
          ),
        ],
      ),
      data: (items) => PageColumn(
        children: [
          if (ref.watch(_supportWebProvider).value case final SupportWebStats w) ...[
            AppCard(
              key: const Key('supportWebCard'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${l10n.supportWebTitle} · ${w.on_ ? l10n.supportWebOn : l10n.supportWebOff}',
                    style: context.textTheme.titleSmall,
                  ),
                  const SizedBox(height: AppSpace.xs),
                  Text(
                    l10n.supportWebToday(
                      w.messagesToday,
                      w.usdToday.toStringAsFixed(2),
                      w.dailyBudgetUsd.toStringAsFixed(2),
                    ),
                  ),
                  Text(l10n.supportWebPaused(w.pausedAddresses)),
                  if (w.gaps.isNotEmpty)
                    ExpansionTile(
                      key: const Key('supportWebGaps'),
                      tilePadding: EdgeInsets.zero,
                      title: Text(l10n.supportWebGaps(w.gaps.length)),
                      children: [
                        for (final g in w.gaps)
                          ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(g.question),
                            subtitle: Text(
                              [?g.page, _when(g.createdAt)].join(' · '),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.sm),
          ],
          SegmentedButton<String>(
            segments: [
              ButtonSegment(value: 'open', label: Text(l10n.ticketsOpen)),
              ButtonSegment(value: 'closed', label: Text(l10n.ticketsClosed)),
              ButtonSegment(value: 'all', label: Text(l10n.ticketsAll)),
            ],
            selected: {_status},
            showSelectedIcon: false,
            onSelectionChanged: (s) => setState(() => _status = s.first),
          ),
          const SizedBox(height: AppSpace.sm),
          if (items.isEmpty)
            AppCard(child: FormNote(l10n.ticketsNone, icon: LucideIcons.inbox))
          else
            GroupedCard(
              children: [
                for (final t in items)
                  GroupedTile(
                    key: Key('ticket-${t.reference}'),
                    icon: t.status == SupportTicketRowStatusEnum.open
                        ? LucideIcons.mail
                        : LucideIcons.mailCheck,
                    title: '${t.reference} · ${t.subject}',
                    subtitle: [
                      t.topic,
                      ?t.userEmail,
                      ?t.orgName,
                      _when(t.createdAt),
                    ].join(' · '),
                    showChevron: false,
                    trailing: TextButton(
                      key: Key('ticketToggle-${t.reference}'),
                      onPressed: () async {
                        final ok = await runGuarded(context, () async {
                          await ref
                              .read(backendProvider)
                              .setSupportTicketClosed(
                                t.reference,
                                t.status == SupportTicketRowStatusEnum.open,
                              );
                          return true;
                        });
                        if (ok == true) {
                          ref.invalidate(_ticketsProvider(_status));
                        }
                      },
                      child: Text(
                        t.status == SupportTicketRowStatusEnum.open
                            ? l10n.ticketClose
                            : l10n.ticketReopen,
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
