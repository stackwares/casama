import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/billing.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/app_card.dart';
import '../billing/paywall.dart';

/// On a cloud computer whose workspace has used the month's computer hours (D-447): says why it
/// won't start, that chat still works, when the hours come back, and offers the way out, before
/// the person taps Start and meets the paywall. A person's own computer never shows it.
class ComputerHoursCard extends ConsumerWidget {
  const ComputerHoursCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hours = ref.watch(billingProvider).value?.computerHours;
    if (hours == null || hours.usedHours < hours.limitHours) {
      return const SizedBox.shrink();
    }
    final l10n = context.l10n;
    final colors = context.appColors;
    final date = DateFormat.MMMMd(l10n.localeName)
        .format(hours.resetsAt.toUtc());
    final reason = l10n.creditsHoursReached(date);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.md,
        AppSpace.xs,
        AppSpace.md,
        AppSpace.xxs,
      ),
      child: AppCard(
        key: const Key('computerHoursCard'),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(LucideIcons.hourglass, size: 18, color: colors.warning),
                const SizedBox(width: AppSpace.xs),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.computerHoursUsedTitle,
                        style: context.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        reason,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                key: const Key('computerHoursUpgrade'),
                onPressed: () => openPaywall(
                  context,
                  reason: reason,
                  source: 'computer_hours',
                ),
                child: Text(l10n.seePlans),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
