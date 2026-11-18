import 'package:casama_sdk/casama_sdk.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/app_card.dart';
import '../../ui/motion.dart';
import '../chat/widgets/reply_usage.dart' show usageKindIcon, usageKindLabel;

/// What usage on the server's keys was charged against what it cost (D-395), over [days]. Null
/// on a server without the margin report (an older one).
final adminMarginProvider = FutureProvider.autoDispose
    .family<AdminMargin?, int>(
      (ref, days) => ref
          .watch(backendProvider)
          .adminMargin(days: days)
          .then<AdminMargin?>((m) => m, onError: (_) => null),
    );

/// Margin of [charged] over [cost] as a share of what was charged, or null with nothing charged.
double? marginShare(num charged, num cost) =>
    charged > 0 ? (charged - cost) / charged : null;

/// The admin's view of the markup at work: charged, what it cost the server, the margin, by kind
/// and by workspace (D-395, D-400). Anything charged without a recorded cost is counted apart and
/// kept out of the margin.
class MarginCard extends ConsumerStatefulWidget {
  const MarginCard({super.key});

  @override
  ConsumerState<MarginCard> createState() => _MarginCardState();
}

class _MarginCardState extends ConsumerState<MarginCard> {
  var _days = 30;

  // Its data loads after the screen: it slides in rather than pushing what's around it.
  @override
  Widget build(BuildContext context) => ShowHide(child: _card(context));

  Widget? _card(BuildContext context) {
    final async = ref.watch(adminMarginProvider(_days));
    // Keep the card while another period loads, so the switch doesn't make it jump.
    final m = async.value;
    if (m == null && !async.isLoading) return null;
    final l10n = context.l10n;
    final locale = l10n.localeName;
    final scheme = context.colorScheme;
    final colors = context.appColors;
    final muted = context.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    String pct(double? share) =>
        share == null ? '–' : '${(share * 100).toStringAsFixed(0)}%';
    String usd(num v) => formatUsd(v, locale);

    Widget stat(String label, String value, {Color? color, Key? key}) =>
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                key: key,
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontFeatures: AppText.tabular,
                  color: color,
                ),
              ),
              Text(label, style: muted),
            ],
          ),
        );

    final Widget body;
    if (m == null) {
      body = const Padding(
        padding: EdgeInsets.all(AppSpace.lg),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (m.chargedUsd <= 0 && m.upstreamUsd <= 0) {
      body = Text(l10n.adminMarginEmpty, style: muted);
    } else {
      final margin = m.chargedTrackedUsd - m.upstreamUsd;
      final untracked = m.chargedUsd - m.chargedTrackedUsd;
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              stat(
                l10n.adminMarginCharged,
                usd(m.chargedTrackedUsd),
                key: const Key('marginCharged'),
              ),
              stat(
                l10n.adminMarginCost,
                usd(m.upstreamUsd),
                key: const Key('marginCost'),
              ),
              stat(
                l10n.adminMarginProfit,
                '${usd(margin)} · ${pct(marginShare(m.chargedTrackedUsd, m.upstreamUsd))}',
                color: margin < 0 ? colors.negative : colors.positive,
                key: const Key('marginProfit'),
              ),
            ],
          ),
          if (untracked > 0) ...[
            const SizedBox(height: AppSpace.sm),
            Text(l10n.adminMarginUntracked(usd(untracked)), style: muted),
          ],
        ],
      );
    }

    // The margin is over what has a cost per row; anything charged without one is said apart.
    String row(num charged, num tracked, num cost) {
      final untracked = charged - tracked;
      if (tracked <= 0 && cost <= 0) {
        return l10n.adminMarginRowUntracked(usd(charged));
      }
      return [
        l10n.adminMarginRow(
          usd(tracked),
          usd(cost),
          pct(marginShare(tracked, cost)),
        ),
        if (untracked > 0) l10n.adminMarginRowNoCost(usd(untracked)),
      ].join(' · ');
    }

    return Column(
      key: const Key('marginCard'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: l10n.adminMarginTitle),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<int>(
                segments: [
                  for (final d in const [7, 30, 90])
                    ButtonSegment(
                      value: d,
                      label: Text(l10n.adminMarginDays(d)),
                    ),
                ],
                selected: {_days},
                showSelectedIcon: false,
                onSelectionChanged: (s) => setState(() => _days = s.first),
              ),
              const SizedBox(height: AppSpace.md),
              body,
              const SizedBox(height: AppSpace.sm),
              Text(l10n.adminMarginNote, style: muted),
            ],
          ),
        ),
        if (m != null && m.byKind.isNotEmpty) ...[
          SectionHeader(title: l10n.adminMarginByKind),
          GroupedCard(
            children: [
              for (final k in m.byKind)
                GroupedTile(
                  key: Key('marginKind-${k.kind}'),
                  icon: usageKindIcon(k.kind),
                  title: usageKindLabel(context, k.kind),
                  subtitle: row(
                    k.chargedUsd,
                    k.chargedTrackedUsd,
                    k.upstreamUsd,
                  ),
                ),
            ],
          ),
        ],
        if (m != null && m.topOrgs.isNotEmpty) ...[
          SectionHeader(title: l10n.adminMarginTopOrgs),
          GroupedCard(
            children: [
              for (final o in m.topOrgs)
                GroupedTile(
                  key: Key('marginOrg-${o.orgId}'),
                  icon: LucideIcons.boxes,
                  title: [o.name, ?o.planCode].join(' · '),
                  subtitle: row(
                    o.chargedUsd,
                    o.chargedTrackedUsd,
                    o.upstreamUsd,
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
