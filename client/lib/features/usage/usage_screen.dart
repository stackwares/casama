import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/billing.dart';
import '../../core/display_text.dart';
import '../../core/number_format.dart';
import '../../core/date_format.dart';
import '../../core/providers.dart';
import '../../core/share.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/advanced_section.dart';
import '../../ui/app_card.dart';
import '../../ui/bot_avatar.dart';
import '../../ui/form_sheet.dart';
import '../../ui/glow_button.dart';
import '../../ui/page.dart';
import '../../ui/segmented.dart';
import '../billing/credits_meter.dart';

enum UsagePeriod { day, week, month, year }

final usageReportProvider = FutureProvider.family<UsageReport?, UsagePeriod>((ref, period) async {
  final org = ref.watch(currentOrgProvider);
  if (org == null) return null;
  return ref.watch(backendProvider).usage(org.id, period: period.name);
});

/// Settings → Usage: what bots cost and used in a period, with charts by day, bot and model;
/// export as CSV, or hand the numbers to a bot to explain (D-087). Tokens and the JSON export fold
/// under Advanced (D-182).
class UsageScreen extends ConsumerStatefulWidget {
  const UsageScreen({super.key});

  @override
  ConsumerState<UsageScreen> createState() => _UsageScreenState();
}

class _UsageScreenState extends ConsumerState<UsageScreen> {
  var _period = UsagePeriod.month;

  String _periodLabel(UsagePeriod p) => switch (p) {
    UsagePeriod.day => context.l10n.periodToday,
    UsagePeriod.week => context.l10n.periodWeek,
    UsagePeriod.month => context.l10n.thisMonth,
    UsagePeriod.year => context.l10n.periodYear,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final report = ref.watch(usageReportProvider(_period));
    return SubPage(
      title: l10n.usage,
      children: [
        // Credits first: what's left and roughly what it buys, in dollars (D-245). Nothing on a
        // server without billing.
        if (ref.watch(billingProvider).value?.enabled == true) ...[
          const AppCard(child: CreditsMeter()),
          const SizedBox(height: AppSpace.md),
        ],
        AppSegmentedControl<UsagePeriod>(
          values: UsagePeriod.values,
          labels: {for (final p in UsagePeriod.values) p: _periodLabel(p)},
          groupValue: _period,
          onValueChanged: (p) => setState(() => _period = p),
        ),
        const SizedBox(height: AppSpace.md),
        AsyncView(
          value: report,
          onRetry: () => ref.invalidate(usageReportProvider(_period)),
          loading: const _ReportSkeleton(),
          data: (r) => r == null ? const SizedBox.shrink() : _Report(report: r, period: _period, periodLabel: _periodLabel(_period)),
        ),
      ],
    );
  }
}

class _Report extends StatelessWidget {
  const _Report({required this.report, required this.period, required this.periodLabel});
  final UsageReport report;
  final UsagePeriod period;
  final String periodLabel;

  int get _tokensIn => report.byBot.fold(0, (n, b) => n + b.tokensIn);
  int get _tokensOut => report.byBot.fold(0, (n, b) => n + b.tokensOut);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final days = report.byDay ?? const [];
    final models = report.byModel ?? const [];
    final kinds = _mergeModelKinds(report.byKind ?? const []);
    final empty = report.byBot.isEmpty && kinds.isEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // What it cost and how often bots ran; tokens are under Advanced (D-182).
        Row(
          spacing: AppSpace.sm,
          children: [
            Expanded(
              child: _Stat(key: const Key('usageSpend'), label: l10n.totalSpend, value: formatUsd(report.totalCostUsd, context.l10n.localeName), icon: LucideIcons.banknote, accent: true),
            ),
            Expanded(
              child: _Stat(label: l10n.runsLabel, value: (report.runs ?? 0).humanizedCount(context.l10n.localeName), icon: LucideIcons.zap),
            ),
          ],
        ),
        if (empty) ...[
          const SizedBox(height: AppSpace.lg),
          AppCard(child: FormNote(l10n.noUsageYet, icon: LucideIcons.chartColumn)),
        ] else ...[
          if (period != UsagePeriod.day && days.isNotEmpty) ...[
            SectionHeader(title: l10n.spendByDay),
            AppCard(child: SizedBox(height: 200, child: _DailyChart(days: _filled(days, period, DateTime.parse(report.since.toIso8601String())), byMonth: period == UsagePeriod.year))),
          ],
          if (report.byBot.isNotEmpty) ...[
            SectionHeader(title: l10n.byBot),
            AppCard(
              child: _Bars(
                rows: [
                  for (final b in report.byBot) (b.name.orPlaceholder(l10n.deletedBot), b.costUsd.toDouble(), ''),
                ],
              ),
            ),
          ],
          if (models.isNotEmpty) ...[
            SectionHeader(title: l10n.byModel),
            AppCard(child: _ModelBreakdown(models: models)),
          ],
          if (kinds.isNotEmpty) ...[
            SectionHeader(title: l10n.everythingMetered),
            GroupedCard(
              children: [
                for (final k in kinds)
                  GroupedTile(
                    icon: _kindIcon(k.kind),
                    title: _kindLabel(context, k.kind),
                    subtitle: _kindQuantity(k.kind, k.quantity, context.l10n.localeName),
                    trailing: Text(formatUsd(k.costUsd, context.l10n.localeName), style: context.textTheme.titleSmall?.copyWith(fontFeatures: AppText.tabular)),
                  ),
              ],
            ),
          ],
        ],
        const SizedBox(height: AppSpace.sm),
        FormNote(l10n.usageHelp),
        const SizedBox(height: AppSpace.md),
        Wrap(
          spacing: AppSpace.sm,
          runSpacing: AppSpace.sm,
          children: [
            GlowButton.icon(
              key: const Key('askAboutUsage'),
              onPressed: empty
                  ? null
                  : () => askBotAbout(context, l10n.usageAskPrompt(periodLabel, usageSummary(context, report))),
              icon: const Icon(LucideIcons.messageCircleQuestion, size: 18),
              label: Text(l10n.askBotAboutUsage),
            ),
            Builder(
              builder: (button) => OutlinedButton.icon(
                key: const Key('exportUsageCsv'),
                onPressed: () => _export(button, csv: true),
                icon: const Icon(LucideIcons.sheet, size: 18),
                label: Text(l10n.exportCsv),
              ),
            ),
          ],
        ),
        AdvancedSection(
          id: 'usage',
          summary: l10n.usageAdvancedSummary,
          children: [
            GroupedCard(
              children: [
                GroupedTile(
                  key: const Key('usageTokensIn'),
                  icon: LucideIcons.arrowDownToLine,
                  title: l10n.tokensIn,
                  trailing: Text(_tokensIn.humanizedCompact(context.l10n.localeName), style: context.textTheme.titleSmall?.copyWith(fontFeatures: AppText.tabular)),
                ),
                GroupedTile(
                  key: const Key('usageTokensOut'),
                  icon: LucideIcons.arrowUpFromLine,
                  title: l10n.tokensOut,
                  trailing: Text(_tokensOut.humanizedCompact(context.l10n.localeName), style: context.textTheme.titleSmall?.copyWith(fontFeatures: AppText.tabular)),
                ),
                Builder(
                  builder: (tile) => GroupedTile(
                    key: const Key('exportUsageJson'),
                    icon: LucideIcons.braces,
                    title: l10n.exportJson,
                    onTap: () => _export(tile, csv: false),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  void _export(BuildContext button, {required bool csv}) {
    final stamp = report.since.toIso8601String().substring(0, 10);
    final name = 'casama-usage-${period.name}-$stamp.${csv ? 'csv' : 'json'}';
    final body = csv ? usageCsv(report) : const JsonEncoder.withIndent('  ').convert(report.toJson());
    shareFiles(
      [XFile.fromData(utf8.encode(body), name: name, mimeType: csv ? 'text/csv' : 'application/json')],
      names: [name],
      origin: shareOrigin(button),
    );
  }
}

/// Every day of the period up to today, zero where nothing was used, so the chart has no gaps.
/// A year is shown by month (each month as its first day). The dates are UTC calendar days.
List<(DateTime, double)> _filled(List<UsageReportByDayInner> days, UsagePeriod period, DateTime since) {
  final byDay = {for (final d in days) d.day: d.costUsd.toDouble()};
  final now = DateTime.now().toUtc();
  if (period == UsagePeriod.year) {
    final byMonth = <String, double>{};
    for (final d in days) {
      final m = d.day.substring(0, 7);
      byMonth[m] = (byMonth[m] ?? 0) + d.costUsd.toDouble();
    }
    return [
      for (var m = 1; m <= now.month; m++)
        (DateTime.utc(now.year, m), byMonth['${now.year}-${m.toString().padLeft(2, '0')}'] ?? 0),
    ];
  }
  final start = DateTime.utc(since.toUtc().year, since.toUtc().month, since.toUtc().day);
  final out = <(DateTime, double)>[];
  for (var d = start; !d.isAfter(now); d = d.add(const Duration(days: 1))) {
    final key = d.toIso8601String().substring(0, 10);
    out.add((d, byDay[key] ?? 0));
  }
  return out;
}

class _DailyChart extends StatelessWidget {
  const _DailyChart({required this.days, required this.byMonth});
  final List<(DateTime, double)> days;

  /// The year view: one bar per month instead of one per day.
  final bool byMonth;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final max = days.fold<double>(0, (m, d) => d.$2 > m ? d.$2 : m);
    final every = (days.length / 8).ceil().clamp(1, 31);
    return BarChart(
      BarChartData(
        maxY: max == 0 ? 1 : max * 1.15,
        alignment: BarChartAlignment.spaceAround,
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: max == 0 ? 0.25 : max / 3,
          getDrawingHorizontalLine: (_) => FlLine(color: context.appColors.hairline, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 52,
              interval: max == 0 ? 0.25 : max / 3,
              getTitlesWidget: (v, meta) => v == meta.max
                  ? const SizedBox.shrink()
                  : Text(formatUsd(v, context.l10n.localeName), style: context.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant, fontFeatures: AppText.tabular)),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= days.length || (i % every != 0 && i != days.length - 1)) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(byMonth ? days[i].$1.formattedMonthInitial(context) : days[i].$1.formattedDayOfMonth(context), style: context.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
                );
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => scheme.inverseSurface,
            getTooltipItem: (group, _, rod, _) => BarTooltipItem(
              '${byMonth ? days[group.x].$1.formattedMonthYear(context) : days[group.x].$1.formattedWeekdayDate(context)}\n${formatUsd(rod.toY, context.l10n.localeName)}',
              context.textTheme.labelMedium!.copyWith(color: scheme.onInverseSurface),
            ),
          ),
        ),
        barGroups: [
          for (final (i, d) in days.indexed)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: d.$2,
                  width: (220 / days.length).clamp(4, 18),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [scheme.primary, scheme.tertiary]),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Labelled horizontal bars, longest first.
class _Bars extends StatelessWidget {
  const _Bars({required this.rows});
  final List<(String, double, String)> rows;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final max = rows.fold<double>(0, (m, r) => r.$2 > m ? r.$2 : m);
    return Column(
      children: [
        for (final (i, r) in rows.indexed) ...[
          if (i > 0) const SizedBox(height: AppSpace.sm),
          Row(
            children: [
              Expanded(child: Text(r.$1, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600))),
              Text(r.$3, style: context.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
              const SizedBox(width: AppSpace.sm),
              Text(formatUsd(r.$2, context.l10n.localeName), style: context.textTheme.labelLarge?.copyWith(fontFeatures: AppText.tabular)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              children: [
                Container(height: 8, color: scheme.surfaceContainerHighest.withValues(alpha: 0.6)),
                FractionallySizedBox(
                  widthFactor: max == 0 ? 0 : (r.$2 / max).clamp(0.02, 1),
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(gradient: LinearGradient(colors: [scheme.primary, scheme.tertiary])),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Model ids to the names people know ("Claude Sonnet 5.5"), from the model lists of the keys this
/// workspace's bots use. An id none of them names is shown as it is.
Map<String, String> _modelNames(WidgetRef ref) {
  final bots = ref.watch(botsProvider).value ?? const <Bot>[];
  final keys = {
    for (final b in bots)
      for (final c in [?b.modelPolicy.primary, ...?b.modelPolicy.fallbacks]) c.credentialId,
  };
  return {
    for (final k in keys)
      for (final o in ref.watch(modelOptionsProvider(k)).value?.items ?? const <ModelOption>[]) o.id: o.name.contains(': ') ? o.name.split(': ').last : o.name,
  };
}

class _ModelBreakdown extends ConsumerWidget {
  const _ModelBreakdown({required this.models});
  final List<UsageReportByModelInner> models;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = context.colorScheme;
    final names = _modelNames(ref);
    // The scheme's accent first, then theme hues that keep their contrast in light and dark.
    final colors = context.appColors;
    final palette = [scheme.primary, colors.warning, scheme.tertiary, colors.positive, colors.info, scheme.secondary];
    final total = models.fold<double>(0, (n, m) => n + m.costUsd.toDouble());
    final legend = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (i, m) in models.indexed)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(color: palette[i % palette.length], shape: BoxShape.circle)),
                const SizedBox(width: AppSpace.xs),
                Expanded(
                  child: Text(
                    m.model.isUsable ? names[m.model] ?? m.model! : context.l10n.otherModel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodyMedium,
                  ),
                ),
                Text(formatUsd(m.costUsd, context.l10n.localeName), style: context.textTheme.labelLarge?.copyWith(fontFeatures: AppText.tabular)),
              ],
            ),
          ),
      ],
    );
    if (total == 0) return legend;
    return LayoutBuilder(
      builder: (context, c) {
        final chart = SizedBox(
          width: 140,
          height: 140,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 38,
              sections: [
                for (final (i, m) in models.indexed)
                  PieChartSectionData(value: m.costUsd.toDouble(), color: palette[i % palette.length], radius: 26, showTitle: false),
              ],
            ),
          ),
        );
        return c.maxWidth > 420
            ? Row(children: [chart, const SizedBox(width: AppSpace.lg), Expanded(child: legend)])
            : Column(children: [chart, const SizedBox(height: AppSpace.md), legend]);
      },
    );
  }
}

/// The report before it loads: the two stat cards, the daily chart and the by-bot bars.
class _ReportSkeleton extends StatelessWidget {
  const _ReportSkeleton();

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;
    Widget stat() => SkeletonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Align(alignment: AlignmentDirectional.centerStart, child: SkeletonBone(width: 18, height: 18, radius: 5)),
          const SizedBox(height: AppSpace.xs),
          SkeletonText(style: text.headlineSmall, widthFactor: 0.5),
          SkeletonText(style: text.labelMedium, widthFactor: 0.4),
        ],
      ),
    );
    return SkeletonScope(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            spacing: AppSpace.sm,
            children: [Expanded(child: stat()), Expanded(child: stat())],
          ),
          const SkeletonSectionHeader(width: 110),
          const SkeletonCard(child: SkeletonBone(height: 200, radius: AppRadius.row)),
          const SkeletonSectionHeader(width: 70),
          SkeletonCard(
            child: Column(
              children: [
                for (final (i, w) in const [0.42, 0.3, 0.5].indexed) ...[
                  if (i > 0) const SizedBox(height: AppSpace.sm),
                  Row(
                    children: [
                      Expanded(child: SkeletonText(style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600), widthFactor: w)),
                      SizedBox(width: 48, child: SkeletonText(style: text.labelLarge)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const SkeletonBone(height: 8, radius: 4),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({super.key, required this.label, required this.value, required this.icon, this.accent = false});
  final String label;
  final String value;
  final IconData icon;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return AppCard(
      padding: const EdgeInsets.all(AppSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: accent ? scheme.primary : scheme.onSurfaceVariant),
          const SizedBox(height: AppSpace.xs),
          Text(value, style: context.textTheme.headlineSmall?.copyWith(fontFeatures: AppText.tabular, color: accent ? scheme.primary : null)),
          Text(label, style: context.textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

/// Model input and output as one "AI models" line, in dollars only; token counts stay under
/// Advanced and in the exports (D-245).
List<UsageReportByKindInner> _mergeModelKinds(List<UsageReportByKindInner> kinds) {
  final out = <UsageReportByKindInner>[];
  for (final k in kinds) {
    final kind = k.kind == 'tokens_in' || k.kind == 'tokens_out' ? _models : k.kind;
    final at = out.indexWhere((x) => x.kind == kind);
    final prev = at < 0 ? null : out[at];
    final merged = UsageReportByKindInner(kind: kind, quantity: (prev?.quantity ?? 0) + k.quantity, costUsd: (prev?.costUsd ?? 0) + k.costUsd);
    if (prev == null) {
      out.add(merged);
    } else {
      out[at] = merged;
    }
  }
  return out;
}

const _models = 'models';

IconData _kindIcon(String kind) => switch (kind) {
  _models => LucideIcons.sparkles,
  'tokens_in' => LucideIcons.arrowDownToLine,
  'tokens_out' => LucideIcons.arrowUpFromLine,
  'computer_seconds' => LucideIcons.monitor,
  'stream_seconds' => LucideIcons.monitorPlay,
  'tts_chars' => LucideIcons.audioLines,
  _ => LucideIcons.gauge,
};

String _kindLabel(BuildContext context, String kind) => switch (kind) {
  _models => context.l10n.kindModels,
  'tokens_in' => context.l10n.kindTokensIn,
  'tokens_out' => context.l10n.kindTokensOut,
  'computer_seconds' => context.l10n.kindComputer,
  'stream_seconds' => context.l10n.kindStream,
  'tts_chars' => context.l10n.kindTts,
  _ => kind,
};

String? _kindQuantity(String kind, num q, String locale) => switch (kind) {
  _models => null,
  'tokens_in' || 'tokens_out' => '${q.humanizedCompact(locale)} tokens',
  'computer_seconds' => '${(q / 3600).humanizedCount(locale, decimalDigits: 2)} h',
  'stream_seconds' => '${(q / 60).humanizedCount(locale, decimalDigits: 0)} min',
  'tts_chars' => '${q.humanizedCompact(locale)} characters',
  _ => q.humanizedCount(locale),
};

/// The report as plain text, for a bot to read.
String usageSummary(BuildContext context, UsageReport r) {
  final l10n = context.l10n;
  final b = StringBuffer()
    ..writeln('Total: ${formatUsd(r.totalCostUsd, l10n.localeName)} since ${r.since.toIso8601String().substring(0, 10)} (${r.runs ?? 0} runs)');
  if (r.byBot.isNotEmpty) {
    b.writeln('By bot:');
    for (final x in r.byBot) {
      b.writeln('- ${x.name ?? l10n.deletedBot}: ${formatUsd(x.costUsd, l10n.localeName)}, ${x.tokensIn} tokens in, ${x.tokensOut} out');
    }
  }
  if ((r.byModel ?? const []).isNotEmpty) {
    b.writeln('By model:');
    for (final m in r.byModel!) {
      b.writeln('- ${m.model ?? l10n.otherModel}: ${formatUsd(m.costUsd, l10n.localeName)}, ${m.tokensIn} in, ${m.tokensOut} out');
    }
  }
  if ((r.byDay ?? const []).isNotEmpty) {
    b.writeln('By day:');
    for (final d in r.byDay!) {
      b.writeln('- ${d.day}: ${formatUsd(d.costUsd, l10n.localeName)}');
    }
  }
  return b.toString().trim();
}

/// One row per day and bot-independent totals: day, cost, tokens in, tokens out; then per bot and
/// per model sections, so it opens cleanly in a spreadsheet.
String usageCsv(UsageReport r) {
  String esc(Object? v) {
    final s = '${v ?? ''}';
    return s.contains(RegExp(r'[",\n]')) ? '"${s.replaceAll('"', '""')}"' : s;
  }

  final rows = <List<Object?>>[
    ['section', 'key', 'cost_usd', 'tokens_in', 'tokens_out'],
    for (final d in r.byDay ?? const <UsageReportByDayInner>[]) ['day', d.day, d.costUsd, d.tokensIn, d.tokensOut],
    for (final b in r.byBot) ['bot', b.name ?? b.botId ?? '', b.costUsd, b.tokensIn, b.tokensOut],
    for (final m in r.byModel ?? const <UsageReportByModelInner>[]) ['model', m.model ?? '', m.costUsd, m.tokensIn, m.tokensOut],
    for (final k in r.byKind ?? const <UsageReportByKindInner>[]) ['metered', k.kind, k.costUsd, k.quantity, ''],
    ['total', r.period.name, r.totalCostUsd, '', ''],
  ];
  return '${rows.map((row) => row.map(esc).join(',')).join('\n')}\n';
}

/// Picks a bot, starts a new chat with it and sends [text], then opens the chat.
Future<void> askBotAbout(BuildContext context, String text) async {
  final container = ProviderScope.containerOf(context, listen: false);
  final bots = await container.read(botsProvider.future);
  if (!context.mounted || bots.isEmpty) return;
  final bot = bots.length == 1
      ? bots.single
      : (await showChoiceSheet<Bot>(
          context,
          icon: LucideIcons.messageCircleQuestionMark,
          title: context.l10n.askWhichBot,
          choices: [
            for (final b in bots)
              Choice(key: Key('askBot-${b.id}'), value: b, label: b.name, leading: BotAvatar(name: b.name, avatar: b.avatarUrl, size: 32, animate: false)),
          ],
        ))?.value;
  if (bot == null || !context.mounted) return;
  final backend = container.read(backendProvider);
  final conv = await runGuarded(context, () async {
    final c = await backend.createConversation(bot.id);
    await backend.send(c.id, text);
    return c;
  });
  if (conv != null && context.mounted) context.push('/bots/${bot.id}/chat?c=${conv.id}');
}
