import 'package:casama_sdk/casama_sdk.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/app_card.dart';

/// Server capacity (D-250): null when the server has no capacity report (an older server).
final adminCapacityProvider = FutureProvider.autoDispose<ServerCapacity?>(
  (ref) => ref
      .watch(backendProvider)
      .adminCapacity()
      .then<ServerCapacity?>((c) => c, onError: (_) => null),
);

String _gb(num mb) => '${(mb / 1024).toStringAsFixed(1)} GB';

/// How full the server is: computers against their memory budget now, the daily peak over 30 days
/// with the budget line, when it fills up at the current trend, refusals and recent alerts.
class CapacityCard extends ConsumerWidget {
  const CapacityCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(adminCapacityProvider).value;
    if (c == null) return const SizedBox.shrink();
    final l10n = context.l10n;
    final colors = context.appColors;
    final scheme = context.colorScheme;
    final latest = c.latest;
    final budget = c.budgetMb;
    final used = latest?.computersMemMb ?? 0;
    final share = budget > 0 ? (used / budget).clamp(0.0, 1.0) : 0.0;
    final barColor = share >= 0.9
        ? colors.negative
        : (share >= 0.6 ? colors.warning : colors.positive);
    final weeks = c.fullInWeeks;
    final forecast = budget <= 0
        ? l10n.adminCapacityNoBudget
        : weeks == null
        ? l10n.adminCapacityNoGrowth
        : weeks == 0
        ? l10n.adminCapacityFullNow
        : l10n.adminCapacityFullIn(weeks.round().clamp(1, 999));
    final muted = context.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    return Column(
      key: const Key('capacityCard'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: l10n.adminCapacityTitle),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (latest == null)
                Text(l10n.adminCapacityNoData, style: muted)
              else ...[
                Row(
                  children: [
                    Icon(LucideIcons.memoryStick, size: 18, color: barColor),
                    const SizedBox(width: AppSpace.xs),
                    Expanded(
                      child: Text(
                        budget > 0
                            ? l10n.adminCapacityComputers(
                                _gb(used),
                                _gb(budget),
                              )
                            : l10n.adminCapacityComputersNoBudget(_gb(used)),
                        style: context.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      '${latest.computersRunning}',
                      style: context.textTheme.titleSmall?.copyWith(
                        fontFeatures: AppText.tabular,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      LucideIcons.monitor,
                      size: 16,
                      color: scheme.onSurfaceVariant,
                    ),
                  ],
                ),
                if (budget > 0) ...[
                  const SizedBox(height: AppSpace.xs),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: share,
                      minHeight: 8,
                      color: barColor,
                      backgroundColor: colors.hairline,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpace.sm),
                Wrap(
                  spacing: AppSpace.md,
                  runSpacing: AppSpace.xs,
                  children: [
                    Text(
                      l10n.adminCapacityFree(
                        _gb(latest.memAvailableMb),
                        _gb(latest.memTotalMb),
                      ),
                      style: muted,
                    ),
                    if (latest.diskUsedPct != null)
                      Text(
                        l10n.adminCapacityDisk(latest.diskUsedPct!.round()),
                        style: muted,
                      ),
                    Text(
                      l10n.adminCapacityLoad(
                        latest.load1.toStringAsFixed(1),
                        latest.cpus,
                      ),
                      style: muted,
                    ),
                  ],
                ),
              ],
              if (c.days.length > 1) ...[
                const SizedBox(height: AppSpace.md),
                Text(
                  l10n.adminCapacityPeakChart,
                  style: context.textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpace.xs),
                SizedBox(
                  height: 140,
                  child: _PeakChart(days: c.days.toList(), budgetMb: budget),
                ),
              ],
              const SizedBox(height: AppSpace.sm),
              Row(
                children: [
                  Icon(
                    LucideIcons.trendingUp,
                    size: 16,
                    color: weeks != null && weeks < 6
                        ? colors.warning
                        : scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpace.xs),
                  Expanded(
                    child: Text(
                      forecast,
                      key: const Key('capacityForecast'),
                      style: context.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.xs),
              Text(
                l10n.adminCapacityRefusals(c.refusals30d),
                style: muted?.copyWith(
                  color: c.refusals30d > 0 ? colors.negative : null,
                ),
              ),
              for (final a in c.alerts.take(3)) ...[
                const SizedBox(height: AppSpace.xs),
                Text('${a.day}: ${a.body}', style: muted),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpace.lg),
      ],
    );
  }
}

class _PeakChart extends StatelessWidget {
  const _PeakChart({required this.days, required this.budgetMb});
  final List<ServerCapacityDaysInner> days;
  final int budgetMb;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final peak = days.fold<int>(
      0,
      (m, d) => d.peakComputersMemMb > m ? d.peakComputersMemMb : m,
    );
    final top = (budgetMb > peak ? budgetMb : peak) * 1.1;
    return LineChart(
      LineChartData(
        minY: 0,
        maxY: top <= 0 ? 1024 : top.toDouble(),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: context.appColors.hairline, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          bottomTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 52,
              getTitlesWidget: (v, meta) => v == meta.max
                  ? const SizedBox.shrink()
                  : Text(
                      _gb(v),
                      style: context.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontFeatures: AppText.tabular,
                      ),
                    ),
            ),
          ),
        ),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            if (budgetMb > 0)
              HorizontalLine(
                y: budgetMb.toDouble(),
                color: context.appColors.negative,
                strokeWidth: 1.5,
                dashArray: [6, 4],
              ),
          ],
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => scheme.inverseSurface,
            getTooltipItems: (spots) => [
              for (final s in spots)
                LineTooltipItem(
                  '${days[s.x.toInt()].day}\n${_gb(s.y)}',
                  context.textTheme.labelMedium!.copyWith(
                    color: scheme.onInverseSurface,
                  ),
                ),
            ],
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            isCurved: false,
            color: scheme.primary,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: scheme.primary.withValues(alpha: 0.12),
            ),
            spots: [
              for (final (i, d) in days.indexed)
                FlSpot(i.toDouble(), d.peakComputersMemMb.toDouble()),
            ],
          ),
        ],
      ),
    );
  }
}
