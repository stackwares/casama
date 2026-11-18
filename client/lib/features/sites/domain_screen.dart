import 'dart:async';

import 'package:casama_sdk/casama_sdk.dart';
import 'package:dio/dio.dart' show DioException;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/date_format.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/app_card.dart';
import '../../ui/form_sheet.dart';
import '../../ui/page.dart';
import 'bought_domain_section.dart';
import 'connect_domain_screen.dart' show showDomainSitePicker;
import 'domains_providers.dart';
import 'sites_providers.dart';

/// A domain's screen (SITES-AND-DOMAINS-PLAN §7.16): its state, the site it shows, its hosts
/// (and which is primary), the records to add with what DNS shows now, **Check Again**, its
/// history and **Disconnect**. While it waits for DNS or a certificate it looks again every 30
/// seconds.
class DomainScreen extends ConsumerStatefulWidget {
  const DomainScreen({super.key, required this.domainId});
  final String domainId;

  /// How often an open screen looks again while the domain is still being set up.
  static const pollEvery = Duration(seconds: 30);

  @override
  ConsumerState<DomainScreen> createState() => _DomainScreenState();
}

class _DomainScreenState extends ConsumerState<DomainScreen> {
  AsyncValue<Domain> _domain = const AsyncLoading();
  Timer? _poll;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _load({bool quiet = false}) async {
    if (!quiet && !_domain.hasValue) {
      setState(() => _domain = const AsyncLoading());
    }
    try {
      final d = await ref.read(backendProvider).domain(widget.domainId);
      if (mounted) _show(d);
    } catch (e, st) {
      // A failed background look keeps what's on screen.
      if (mounted && !(quiet && _domain.hasValue)) {
        setState(() => _domain = AsyncError(e, st));
      }
    }
  }

  /// Shows [d], keeping the history from the last full read when an answer leaves it out.
  void _show(Domain d) {
    final old = _domain.value;
    final next = d.events == null && old != null && old.id == d.id
        ? d.copyWith(events: old.events)
        : d;
    setState(() => _domain = AsyncData(next));
    final waiting = next.state == 'waiting_dns' || next.state == 'waiting_cert';
    if (waiting && _poll == null) {
      _poll = Timer.periodic(DomainScreen.pollEvery, (_) => _load(quiet: true));
    } else if (!waiting) {
      _poll?.cancel();
      _poll = null;
    }
  }

  void _changed(Domain d) {
    _show(d);
    final orgId = ref.read(currentOrgIdProvider);
    if (orgId != null) ref.invalidate(orgDomainsProvider(orgId));
  }

  Future<void> _check() async {
    if (_checking) return;
    setState(() => _checking = true);
    try {
      final d = await ref.read(backendProvider).checkDomain(widget.domainId);
      if (mounted) _changed(d);
      // The check's answer has no history; read it again for the newest lines.
      if (mounted) unawaited(_load(quiet: true));
    } catch (e, st) {
      if (!mounted) return;
      if (e is DioException && e.response?.statusCode == 429) {
        showToast(
          context,
          problemOf(e)?.detail ?? context.l10n.domainCheckTooSoon,
          kind: ToastKind.info,
        );
      } else {
        showError(context, e, st);
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _pickSite(Domain d) async {
    final orgId = ref.read(currentOrgIdProvider);
    if (orgId == null) return;
    List<Site> sites;
    try {
      sites = await ref.read(backendProvider).sites(orgId);
    } catch (_) {
      sites = const [];
    }
    if (!mounted) return;
    final picked = await showDomainSitePicker(
      context,
      sites: sites,
      current: d.pageId,
    );
    if (picked == null || picked.$1 == d.pageId || !mounted) return;
    final next = await runGuarded(
      context,
      () => ref.read(backendProvider).setDomainSite(d.id, picked.$1),
    );
    if (next != null && mounted) _changed(next);
  }

  Future<void> _makePrimary(Domain d, SiteHost h) async {
    final next = await runGuarded(
      context,
      () => ref.read(backendProvider).setDomainPrimaryHost(d.id, h.hostname),
    );
    if (next != null && mounted) _changed(next);
  }

  Future<void> _disconnect(Domain d) async {
    final l10n = context.l10n;
    final ok = await showConfirm(
      context: context,
      title: l10n.domainDisconnectTitle(d.name),
      message: l10n.domainDisconnectBody,
      confirmLabel: l10n.disconnect,
      destructive: true,
      confirmKey: const Key('confirmDisconnectDomain'),
    );
    if (!ok || !mounted) return;
    final done = await runGuarded(context, () async {
      await ref.read(backendProvider).deleteDomain(d.id);
      return true;
    });
    if (done != true || !mounted) return;
    final orgId = ref.read(currentOrgIdProvider);
    if (orgId != null) ref.invalidate(orgDomainsProvider(orgId));
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/settings/domains');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // Kept loaded so the site picker and the list refresh can read the workspace.
    ref.watch(currentOrgIdProvider);
    return SubPage(
      title: _domain.value?.name ?? l10n.settingsDomains,
      body: AsyncView(
        value: _domain,
        onRetry: _load,
        data: (d) => RefreshIndicator(
          onRefresh: () => _load(quiet: true),
          child: PageColumn(children: _sections(context, d)),
        ),
      ),
    );
  }

  List<Widget> _sections(BuildContext context, Domain d) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final muted = context.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final events = d.events ?? const <DomainEvent>[];
    final bought = d.kind == 'registered';
    return [
      Row(
        children: [
          Expanded(
            child: SelectableText(
              d.name,
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          DomainStateChip.forState(
            context,
            d.state,
            key: const Key('domainScreenState'),
          ),
        ],
      ),
      SectionHeader(title: l10n.domainSite),
      GroupedCard(
        children: [
          GroupedTile(
            key: const Key('domainSite'),
            icon: LucideIcons.layoutTemplate,
            title: d.pageTitle ?? l10n.domainSiteNone,
            subtitle: d.pageId == null ? l10n.domainSiteNoneHelp : null,
            onTap: () => _pickSite(d),
          ),
        ],
      ),
      if (d.hosts.isNotEmpty) ...[
        SectionHeader(title: l10n.domainHosts),
        GroupedCard(
          children: [
            for (final h in d.hosts)
              GroupedTile(
                key: Key('domainHost-${h.hostname}'),
                icon: h.isPrimary ? LucideIcons.star : LucideIcons.globe,
                title: h.hostname,
                subtitle: h.isPrimary ? l10n.domainPrimary : null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (h.live && !h.isPrimary)
                      TextButton(
                        key: Key('domainMakePrimary-${h.hostname}'),
                        onPressed: () => _makePrimary(d, h),
                        child: Text(l10n.domainMakePrimary),
                      ),
                    DomainStateChip(
                      key: Key('domainHostStatus-${h.hostname}'),
                      label: siteHostStatusLabel(l10n, h.status),
                      tone: h.status == 'active'
                          ? context.appColors.positive
                          : h.status.startsWith('pending')
                          ? context.appColors.info
                          : context.appColors.warning,
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpace.xs),
        FormNote(l10n.domainPrimaryHelp),
      ],
      // A bought domain's records are set by Casama; it has DNS Records instead.
      if (bought)
        BoughtDomainSection(
          domain: d,
          onChanged: _changed,
          onReload: () => _load(quiet: true),
        )
      else ...[
        SectionHeader(title: l10n.domainRecordsTitle),
        if (d.records.isEmpty) Text(l10n.domainRecordsNone, style: muted),
      ],
      if (!bought && d.records.isNotEmpty) ...[
        Text(
          domainRecordsIntro(l10n, d.dnsProvider, name: d.dnsProviderName),
          key: const Key('domainRecordsIntro'),
        ),
        const SizedBox(height: AppSpace.sm),
        for (final (i, r) in d.records.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.sm),
            child: _RecordCard(index: i, record: r),
          ),
      ],
      const SizedBox(height: AppSpace.xs),
      Align(
        alignment: Alignment.centerLeft,
        child: OutlinedButton.icon(
          key: const Key('domainCheckAgain'),
          onPressed: _checking ? null : _check,
          icon: _checking
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(LucideIcons.refreshCw, size: 18),
          label: Text(l10n.domainCheckAgain),
        ),
      ),
      if (d.state != 'live') ...[
        const SizedBox(height: AppSpace.xs),
        Text(l10n.domainChecksItself, style: muted),
      ],
      if (events.isNotEmpty) ...[
        SectionHeader(title: l10n.domainHistory),
        GroupedCard(
          children: [
            for (final (i, e) in events.indexed)
              GroupedTile(
                key: Key('domainEvent-$i'),
                icon: LucideIcons.history,
                title: domainEventLabel(l10n, e.kind),
                subtitle: [
                  if (e.detail['host'] is String) e.detail['host'] as String,
                  '${e.createdAt.toLocal().formattedDate(context)} · '
                      '${e.createdAt.toLocal().formattedTime(context)}',
                ].join(' · '),
                showChevron: false,
              ),
          ],
        ),
      ],
      // A bought domain stays with the workspace; choosing no site is how it shows nothing.
      if (!bought) ...[
        const SizedBox(height: AppSpace.lg),
        GroupedCard(
          children: [
            GroupedTile(
              key: const Key('domainDisconnect'),
              icon: LucideIcons.unlink,
              title: l10n.disconnect,
              destructive: true,
              showChevron: false,
              onTap: () => _disconnect(d),
            ),
          ],
        ),
      ],
      const SizedBox(height: AppSpace.lg),
    ];
  }
}

/// One record to add: its type, name and value with Copy, and what DNS shows now beside it.
class _RecordCard extends StatelessWidget {
  const _RecordCard({required this.index, required this.record});
  final int index;
  final DomainRecord record;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final colors = context.appColors;
    final r = record;
    final forward = r.type.toUpperCase() == 'FORWARD';
    final Widget? seen = switch (r.ok) {
      true => Row(
        key: Key('domainRecordOk-$index'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.circleCheck, size: 16, color: colors.positive),
          const SizedBox(width: 4),
          Text(
            l10n.domainRecordFound,
            style: context.textTheme.labelMedium?.copyWith(
              color: colors.positive,
            ),
          ),
        ],
      ),
      false => Text(
        l10n.domainRecordNotFound,
        key: Key('domainRecordMissing-$index'),
        style: context.textTheme.labelMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      null => null,
    };
    return AppCard(
      key: Key('domainRecord-$index'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                r.type,
                style: context.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (!r.required_) ...[
                const SizedBox(width: AppSpace.xs),
                Text(
                  l10n.domainRecordOptional,
                  key: Key('domainRecordOptional-$index'),
                  style: context.textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
              const Spacer(),
              ?seen,
            ],
          ),
          const SizedBox(height: AppSpace.xs),
          if (forward) ...[
            Text(
              l10n.domainRecordForward(r.name, r.value),
              key: Key('domainRecordForward-$index'),
            ),
            const SizedBox(height: AppSpace.xs),
          ],
          CopyableValue(
            label: l10n.domainRecordName,
            value: r.name,
            copyKey: Key('domainRecordCopyName-$index'),
          ),
          CopyableValue(
            label: l10n.domainRecordValue,
            value: r.value,
            copyKey: Key('domainRecordCopyValue-$index'),
          ),
        ],
      ),
    );
  }
}
