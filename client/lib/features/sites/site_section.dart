import 'dart:async';

import 'package:casama_sdk/casama_sdk.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/app_card.dart';
import '../pages/pages_screen.dart' show pageOpenerProvider;
import 'publish_site_sheet.dart';
import 'sites_providers.dart';

/// A page's place on the web in the Library (SITES-AND-DOMAINS-PLAN §7.16): **Publish to the
/// Web** while it has no address; once published, the address with Copy and Open, its hosts'
/// states, search engines, **Use Your Own Domain** and **Unpublish**. Nothing at all when the
/// server has no site addresses.
class PageSiteSection extends ConsumerWidget {
  const PageSiteSection({
    super.key,
    required this.pageId,
    required this.title,
    this.onChanged,
  });
  final String pageId;
  final String title;

  /// Publishing makes the page public and unpublishing changes that, so the creation reloads.
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(sitesConfigProvider);
    final orgId = ref.watch(currentOrgIdProvider);
    if (config == null || orgId == null) return const SizedBox.shrink();
    final sites = ref.watch(orgSitesProvider(orgId));
    // Still loading, or the list couldn't load: leave the screen as it was without sites.
    final list = sites.value;
    if (list == null) return const SizedBox.shrink();
    Site? site;
    for (final s in list) {
      if (s.pageId == pageId) site = s;
    }
    final Widget body = site == null
        ? GroupedCard(
            children: [
              GroupedTile(
                key: const Key('publishToWeb'),
                icon: LucideIcons.globe,
                title: context.l10n.sitePublishToWeb,
                subtitle: context.l10n.sitePublishToWebHelp,
                onTap: () => _publish(context, ref, orgId, config.zone!),
              ),
            ],
          )
        : _Published(
            site: site,
            orgId: orgId,
            customDomains: config.customDomains,
            onChanged: onChanged,
          );
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.lg),
      child: body,
    );
  }

  Future<void> _publish(
    BuildContext context,
    WidgetRef ref,
    String orgId,
    String zone,
  ) async {
    final site = await showPublishSiteSheet(
      context,
      orgId: orgId,
      pageId: pageId,
      title: title,
      zone: zone,
    );
    if (site == null) return;
    ref.invalidate(orgSitesProvider(orgId));
    onChanged?.call();
  }
}

class _Published extends ConsumerWidget {
  const _Published({
    required this.site,
    required this.orgId,
    required this.customDomains,
    this.onChanged,
  });
  final Site site;
  final String orgId;
  final bool customDomains;
  final VoidCallback? onChanged;

  String get _address => site.addressUrl ?? site.url ?? '';

  Future<void> _copy(BuildContext context) async {
    final l10n = context.l10n;
    try {
      await Clipboard.setData(ClipboardData(text: _address));
    } catch (_) {}
    if (context.mounted) {
      showToast(context, l10n.copied, kind: ToastKind.success);
    }
  }

  Future<void> _setIndexable(
    BuildContext context,
    WidgetRef ref,
    bool v,
  ) async {
    final done = await runGuarded(
      context,
      () => ref.read(backendProvider).publishSite(site.pageId, indexable: v),
    );
    if (done != null) ref.invalidate(orgSitesProvider(orgId));
  }

  Future<void> _unpublish(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final ok = await showConfirm(
      context: context,
      title: l10n.siteUnpublishTitle,
      message: l10n.siteUnpublishBody,
      confirmLabel: l10n.siteUnpublish,
      destructive: true,
      confirmKey: const Key('confirmUnpublish'),
    );
    if (!ok || !context.mounted) return;
    final done = await runGuarded(context, () async {
      await ref.read(backendProvider).unpublishSite(site.pageId);
      return true;
    });
    if (done != true) return;
    ref.invalidate(orgSitesProvider(orgId));
    onChanged?.call();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final waiting = [
      for (final h in site.hosts)
        if (h.status != 'active') h,
    ];
    return Column(
      key: const Key('siteSection'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.siteOnTheWeb,
          style: context.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpace.xs),
        SelectableText(
          _address,
          key: const Key('siteAddress'),
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpace.xs),
        Wrap(
          spacing: AppSpace.xs,
          runSpacing: AppSpace.xs,
          children: [
            OutlinedButton.icon(
              key: const Key('siteCopy'),
              onPressed: () => _copy(context),
              icon: const Icon(LucideIcons.copy, size: 18),
              label: Text(l10n.copy),
            ),
            OutlinedButton.icon(
              key: const Key('siteOpen'),
              onPressed: _address.isEmpty
                  ? null
                  : () => ref.read(pageOpenerProvider)(Uri.parse(_address)),
              icon: const Icon(LucideIcons.externalLink, size: 18),
              label: Text(l10n.openLink),
            ),
          ],
        ),
        if (waiting.isNotEmpty) ...[
          const SizedBox(height: AppSpace.sm),
          for (final h in waiting)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.xxs),
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      h.hostname,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpace.xs),
                  Chip(
                    key: Key('siteHostStatus-${h.hostname}'),
                    visualDensity: VisualDensity.compact,
                    label: Text(siteHostStatusLabel(l10n, h.status)),
                  ),
                ],
              ),
            ),
        ],
        const SizedBox(height: AppSpace.sm),
        GroupedCard(
          children: [
            GroupedTile(
              key: const Key('siteSearchEngines'),
              icon: LucideIcons.search,
              title: l10n.siteSearchEngines,
              subtitle: site.canIndex
                  ? l10n.siteSearchEnginesHelp
                  : l10n.siteSearchEnginesPaid,
              onTap: site.canIndex
                  ? () => _setIndexable(context, ref, !site.indexable)
                  : null,
              trailing: Switch(
                key: const Key('siteSearchEnginesSwitch'),
                value: site.indexable,
                onChanged: site.canIndex
                    ? (v) => _setIndexable(context, ref, v)
                    : null,
              ),
            ),
            if (customDomains)
              GroupedTile(
                key: const Key('siteUseOwnDomain'),
                icon: LucideIcons.link,
                title: l10n.siteUseOwnDomain,
                onTap: () => unawaited(
                  context.pushOnce(
                    Uri(
                      path: '/settings/domains/connect',
                      queryParameters: {'page_id': site.pageId},
                    ).toString(),
                  ),
                ),
              ),
            GroupedTile(
              key: const Key('siteUnpublish'),
              icon: LucideIcons.globeLock,
              title: l10n.siteUnpublish,
              destructive: true,
              showChevron: false,
              onTap: () => _unpublish(context, ref),
            ),
          ],
        ),
      ],
    );
  }
}
