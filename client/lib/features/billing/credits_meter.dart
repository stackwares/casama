import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:casama_sdk/casama_sdk.dart';

import '../../core/backend.dart' show UsageFilter;
import '../../core/billing.dart';
import '../../core/number_format.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../usage/usage_screen.dart';

/// Fewer runs than this this month and the "runs left" guess is too shaky to show.
const _minRunsForEstimate = 3;

/// This month's credits at a glance (D-245): the balance in dollars, a bar of how much of what was
/// there this month is used, and roughly how many more runs it buys at this month's average cost.
/// Credits are dollars (1 credit = $1); exact charges are one level down, in Usage and Billing.
/// Shows nothing on a server without billing.
class CreditsMeter extends ConsumerWidget {
  const CreditsMeter({super.key, this.showBalance = true});

  /// Off where the balance is already written just above (the Billing plan card).
  final bool showBalance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billing = ref.watch(billingProvider).value;
    if (billing == null || !billing.enabled || billing.unlimited) {
      return const SizedBox.shrink();
    }
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final locale = l10n.localeName;
    final balance = billing.creditsUsd.toDouble();
    final left = balance < 0 ? 0.0 : balance;
    final used =
        ref.watch(billingUsageProvider).value?.totalUsd.toDouble() ?? 0;
    final report = ref.watch(usageReportProvider((period: UsagePeriod.month, filter: UsageFilter.none))).value;
    final monthly = billing.limits['monthly_credits_usd'];

    // What was there this month: what's been spent plus what's left. Credits carry over, so this
    // is closer to "when do I run out" than the plan's monthly amount alone.
    final available = used + left;
    final share = available <= 0 ? 0.0 : (used / available).clamp(0.0, 1.0);
    final percent = (share * 100).round();
    final barColor = left <= 0
        ? scheme.error
        : share >= 0.8
        ? context.appColors.warning
        : scheme.primary;

    final runs = report?.runs ?? 0;
    final perRun = runs >= _minRunsForEstimate
        ? report!.totalCostUsd.toDouble() / runs
        : 0.0;
    final runsLeft = perRun > 0 ? (left / perRun).floor() : null;
    final muted = context.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );

    return Column(
      key: const Key('creditsMeter'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: showBalance
                  ? Text(
                      l10n.creditsBalance(
                        balance.humanizedCurrency(
                          locale,
                          'USD',
                          decimalDigits: 2,
                        ),
                      ),
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontFeatures: AppText.tabular,
                      ),
                    )
                  : Text(
                      l10n.creditsThisMonth,
                      style: context.textTheme.labelLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
            ),
            Text(
              l10n.creditsUsedPercent(percent),
              key: const Key('creditsUsedPercent'),
              style: context.textTheme.labelLarge?.copyWith(
                color: barColor,
                fontWeight: FontWeight.w700,
                fontFeatures: AppText.tabular,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.xs),
        Semantics(
          label: l10n.creditsUsedPercent(percent),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: share),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => LinearProgressIndicator(
                value: v,
                minHeight: 10,
                color: barColor,
                backgroundColor: scheme.surfaceContainerHighest.withValues(
                  alpha: 0.7,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpace.xs),
        if (left <= 0)
          Text(
            l10n.creditsOut,
            key: const Key('creditsOut'),
            style: context.textTheme.bodyMedium?.copyWith(
              color: scheme.error,
              fontWeight: FontWeight.w600,
            ),
          )
        else if (runsLeft != null)
          Text(
            l10n.creditsRunsLeft(runsLeft),
            key: const Key('creditsRunsLeft'),
            style: context.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        const SizedBox(height: 2),
        Text(
          monthly != null && monthly > 0
              ? l10n.creditsExplainer(
                  monthly.humanizedCurrency(
                    locale,
                    'USD',
                    decimalDigits: monthly % 1 == 0 ? 0 : 2,
                  ),
                )
              : l10n.creditsExplainerShort,
          style: muted,
        ),
        if (billing.daily case final daily?) ...[
          const SizedBox(height: AppSpace.md),
          _DailyLimit(daily: daily),
        ],
      ],
    );
  }
}

/// The plan's daily cap on the server's keys (D-311). It stops runs on its own, whatever credits
/// are left, so it sits under the credits: without it a workspace with most of its credits left
/// could be told "limit reached" with nothing on screen to explain it.
class _DailyLimit extends StatelessWidget {
  const _DailyLimit({required this.daily});

  final BillingSummaryDaily daily;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final locale = l10n.localeName;
    final used = daily.usedUsd.toDouble();
    final cap = daily.capUsd.toDouble();
    final share = cap <= 0 ? 1.0 : (used / cap).clamp(0.0, 1.0);
    final reached = used >= cap;
    final color = reached
        ? scheme.error
        : share >= 0.8
        ? context.appColors.warning
        : scheme.primary;
    String money(double v) =>
        v.humanizedCurrency(locale, 'USD', decimalDigits: v % 1 == 0 ? 0 : 2);
    final minutes = daily.resetsAt.difference(DateTime.now()).inMinutes;
    final hours = (minutes / 60).ceil();
    final resets = minutes < 60
        ? l10n.creditsDailyResetsSoon
        : l10n.creditsDailyResetsHours(hours);

    return Column(
      key: const Key('dailyLimit'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.creditsDailyLabel,
                style: context.textTheme.labelLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            Text(
              l10n.creditsDailyOf(money(used), money(cap)),
              key: const Key('dailyLimitAmount'),
              style: context.textTheme.labelLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                fontFeatures: AppText.tabular,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.xs),
        Semantics(
          label: l10n.creditsDailyOf(money(used), money(cap)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: share,
              minHeight: 6,
              color: color,
              backgroundColor: scheme.surfaceContainerHighest.withValues(
                alpha: 0.7,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpace.xs),
        if (reached)
          Text(
            '${l10n.creditsDailyReached} $resets',
            key: const Key('dailyLimitReached'),
            style: context.textTheme.bodyMedium?.copyWith(
              color: scheme.error,
              fontWeight: FontWeight.w600,
            ),
          )
        else
          Text(
            '${l10n.creditsDailyExplainer} $resets',
            style: context.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}
