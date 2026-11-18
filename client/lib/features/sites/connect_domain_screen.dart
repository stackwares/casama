import 'package:casama_sdk/casama_sdk.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/app_card.dart';
import '../../ui/form_sheet.dart';
import '../../ui/glow_button.dart';
import '../../ui/page.dart';
import 'domains_providers.dart';
import 'sites_providers.dart';

/// Opens a list of the workspace's [sites] with **None** first; answers the picked page id in a
/// record (null inside it: none), or null when closed.
Future<(String?,)?> showDomainSitePicker(
  BuildContext context, {
  required List<Site> sites,
  required String? current,
}) => showAdaptiveSheet<(String?,)>(
  context: context,
  builder: (context) {
    final l10n = context.l10n;
    Widget row(String? pageId, String title, {String? subtitle}) => ListTile(
      key: Key('domainSiteOption-${pageId ?? 'none'}'),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle),
      trailing: pageId == current
          ? Icon(LucideIcons.check, color: context.colorScheme.primary)
          : null,
      onTap: () => Navigator.of(context).pop((pageId,)),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpace.md),
        SheetTitle(l10n.domainPickSite),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            children: [
              row(null, l10n.domainSiteNone, subtitle: l10n.domainSiteNoneHelp),
              for (final s in sites) row(s.pageId, s.title, subtitle: s.url),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.md),
      ],
    );
  },
);

/// Connect a Domain You Own (SITES-AND-DOMAINS-PLAN §7.16): type the domain, optionally pick the
/// site it shows, and connect. A domain another workspace proved first answers a claim record to
/// add; otherwise the domain's own screen opens with the records to add.
class ConnectDomainScreen extends ConsumerStatefulWidget {
  const ConnectDomainScreen({super.key, this.pageId});

  /// The site to preselect (the Library's **Use Your Own Domain** passes it).
  final String? pageId;

  @override
  ConsumerState<ConnectDomainScreen> createState() =>
      _ConnectDomainScreenState();
}

class _ConnectDomainScreenState extends ConsumerState<ConnectDomainScreen> {
  final _name = TextEditingController();
  late String? _pageId = widget.pageId;
  bool _busy = false;
  String? _error;
  ConnectDomainResultClaim? _claim;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  /// What they typed, without a scheme, path or trailing dot.
  String get _domain {
    var s = _name.text.trim().toLowerCase();
    s = s.replaceFirst(RegExp(r'^[a-z]+://'), '');
    s = s.split('/').first.split('?').first;
    return s.replaceAll(RegExp(r'\.+$'), '');
  }

  bool get _valid => _domain.contains('.') && !_domain.contains(' ');

  Future<void> _connect(String orgId) async {
    if (!_valid || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await ref
          .read(backendProvider)
          .connectDomain(orgId, _domain, pageId: _pageId);
      if (!mounted) return;
      ref.invalidate(orgDomainsProvider(orgId));
      final domain = result.domain;
      if (domain != null) {
        context.pushReplacement('/settings/domains/${domain.id}');
        return;
      }
      setState(() {
        _busy = false;
        _claim = result.claim;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = errorText(context, e);
      });
    }
  }

  Future<void> _pickSite(List<Site> sites) async {
    final picked = await showDomainSitePicker(
      context,
      sites: sites,
      current: _pageId,
    );
    if (picked != null && mounted) setState(() => _pageId = picked.$1);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final orgId = ref.watch(currentOrgIdProvider);
    final sites = orgId == null
        ? const <Site>[]
        : ref.watch(orgSitesProvider(orgId)).value ?? const <Site>[];
    String siteTitle = l10n.domainSiteNone;
    for (final s in sites) {
      if (s.pageId == _pageId) siteTitle = s.title;
    }
    final claim = _claim;
    return SubPage(
      title: l10n.domainsConnectOwn,
      children: [
        TextField(
          key: const Key('connectDomainField'),
          controller: _name,
          autofocus: true,
          autocorrect: false,
          enableSuggestions: false,
          keyboardType: TextInputType.url,
          decoration: InputDecoration(
            labelText: l10n.domainConnectField,
            hintText: 'bakery.com',
          ),
          onChanged: (_) => setState(() {
            _error = null;
            _claim = null;
          }),
          onSubmitted: (_) => orgId == null ? null : _connect(orgId),
        ),
        const SizedBox(height: AppSpace.xs),
        FormNote(l10n.domainConnectHelp),
        if (sites.isNotEmpty) ...[
          SectionHeader(title: l10n.domainConnectSite),
          GroupedCard(
            children: [
              GroupedTile(
                key: const Key('connectDomainSite'),
                icon: LucideIcons.layoutTemplate,
                title: siteTitle,
                onTap: () => _pickSite(sites),
              ),
            ],
          ),
        ],
        if (claim != null) ...[
          const SizedBox(height: AppSpace.lg),
          AppCard(
            key: const Key('connectDomainClaim'),
            borderColor: context.appColors.warning.withValues(alpha: 0.5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.domainClaimTitle,
                  style: context.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpace.xs),
                Text(l10n.domainClaimBody),
                const SizedBox(height: AppSpace.sm),
                CopyableValue(label: l10n.domainRecordType, value: claim.type),
                CopyableValue(
                  label: l10n.domainRecordName,
                  value: claim.name,
                  copyKey: const Key('connectDomainClaimCopyName'),
                ),
                CopyableValue(
                  label: l10n.domainRecordValue,
                  value: claim.value,
                  copyKey: const Key('connectDomainClaimCopyValue'),
                ),
              ],
            ),
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: AppSpace.md),
          Text(
            _error!,
            key: const Key('connectDomainError'),
            style: context.textTheme.bodyMedium?.copyWith(color: scheme.error),
          ),
        ],
        const SizedBox(height: AppSpace.lg),
        Align(
          alignment: Alignment.centerLeft,
          child: GlowButton.icon(
            key: const Key('connectDomainSubmit'),
            onPressed: orgId == null || !_valid || _busy
                ? null
                : () => _connect(orgId),
            icon: _busy
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(LucideIcons.link, size: 18),
            label: Text(l10n.domainConnect),
          ),
        ),
      ],
    );
  }
}
