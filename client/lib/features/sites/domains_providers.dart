import 'package:casama_sdk/casama_sdk.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../core/remote_content.dart';

/// Whether people can connect a domain they own on this server (`sites.custom_domains`).
final customDomainsProvider = Provider<bool>(
  (ref) => ref.watch(backendProvider).sitesConfig?.customDomains ?? false,
);

/// A workspace's domains (`GET /v1/orgs/{id}/domains`), keyed by workspace id.
final orgDomainsProvider = FutureProvider.autoDispose
    .family<List<Domain>, String>(
      (ref, orgId) => ref.watch(backendProvider).domains(orgId),
    );

/// The words for a domain's chip; anything the app doesn't know yet needs attention.
String domainStateLabel(AppLocalizations l10n, String state) => switch (state) {
  'live' => l10n.domainStateLive,
  'waiting_dns' => l10n.domainStateWaitingDns,
  'waiting_cert' => l10n.domainStateWaitingCert,
  'paused' => l10n.domainStatePaused,
  _ => l10n.domainStateNeedsAttention,
};

/// A domain's history line in plain words.
String domainEventLabel(AppLocalizations l10n, String kind) => switch (kind) {
  'connected' => l10n.domainEventConnected,
  'proved' => l10n.domainEventProved,
  'live' => l10n.domainEventLive,
  'needs_dns' => l10n.domainEventNeedsDns,
  'failed' => l10n.domainEventFailed,
  'disconnected' => l10n.domainEventDisconnected,
  'paused' => l10n.domainEventPaused,
  'resumed' => l10n.domainEventResumed,
  'removed' => l10n.domainEventRemoved,
  'claim' => l10n.domainEventClaim,
  'claim_attempt' => l10n.domainEventClaimAttempt,
  'over_limit' => l10n.domainEventOverLimit,
  'suspended' => l10n.domainEventSuspended,
  _ => l10n.domainEventOther,
};

/// The DNS companies the server recognises from a domain's nameservers, by their own names.
const dnsProviderNames = <String, String>{
  'cloudflare': 'Cloudflare',
  'godaddy': 'GoDaddy',
  'namecheap': 'Namecheap',
  'namecom': 'Name.com',
  'google': 'Google',
  'route53': 'Amazon Route 53',
  'dnsimple': 'DNSimple',
  'porkbun': 'Porkbun',
  'squarespace': 'Squarespace',
  'hover': 'Hover',
  'gandi': 'Gandi',
  'ns1': 'NS1',
  'vercel': 'Vercel',
  'netlify': 'Netlify',
};

/// The line above a domain's records, written for its DNS company when it's known.
String domainRecordsIntro(AppLocalizations l10n, String? provider, {String? name}) {
  if (provider == 'cloudflare') return l10n.domainRecordsAtCloudflare;
  // The server sends the name with the id (D-372); this list is for older servers.
  final known = name ?? remoteName('dns_providers', provider) ?? dnsProviderNames[provider];
  return known == null ? l10n.domainRecordsGeneric : l10n.domainRecordsAt(known);
}

/// A small coloured chip with a domain's or host's state.
class DomainStateChip extends StatelessWidget {
  const DomainStateChip({super.key, required this.label, required this.tone});

  /// Builds the chip for a domain's [state] (live, waiting_dns, waiting_cert, paused…).
  factory DomainStateChip.forState(
    BuildContext context,
    String state, {
    Key? key,
  }) {
    final colors = context.appColors;
    final tone = switch (state) {
      'live' => colors.positive,
      'waiting_dns' || 'waiting_cert' => colors.info,
      'paused' => colors.warning,
      _ => colors.negative,
    };
    return DomainStateChip(
      key: key,
      label: domainStateLabel(context.l10n, state),
      tone: tone,
    );
  }

  final String label;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: context.textTheme.labelSmall?.copyWith(
          color: tone,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// One copyable value: a label over the text, with a Copy button beside it.
class CopyableValue extends StatelessWidget {
  const CopyableValue({
    super.key,
    required this.label,
    required this.value,
    this.copyKey,
  });
  final String label;
  final String value;
  final Key? copyKey;

  Future<void> _copy(BuildContext context) async {
    final l10n = context.l10n;
    try {
      await Clipboard.setData(ClipboardData(text: value));
    } catch (_) {}
    if (context.mounted) {
      showToast(context, l10n.copied, kind: ToastKind.success);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: context.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              SelectableText(
                value,
                style: context.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          key: copyKey,
          tooltip: context.l10n.copy,
          icon: Icon(
            LucideIcons.copy,
            size: 18,
            color: scheme.onSurfaceVariant,
          ),
          onPressed: () => _copy(context),
        ),
      ],
    );
  }
}
