import 'package:fl_chart/fl_chart.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/widgets.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_tokens.dart';
import 'bot_ui_kit.dart';

// Casama's cards for events, schedules, details and numbers (D-337).

// ---------------------------------------------------------------------------------------------
// Event
// ---------------------------------------------------------------------------------------------

/// What a bot's Event component shows.
class EventSpec {
  const EventSpec({
    required this.title,
    required this.start,
    required this.startRaw,
    this.end,
    this.endRaw,
    this.allDay = false,
    this.location,
    this.attendees = const [],
    this.description,
    this.app,
    this.actions = true,
  });
  final String title;
  final DateTime start;
  final String startRaw;
  final DateTime? end;
  final String? endRaw;
  final bool allDay;
  final String? location;
  final List<String> attendees;
  final String? description;
  final String? app;
  final bool actions;

  static EventSpec? fromMap(Map<Object?, Object?> m, {bool actions = true}) {
    final title = cardText(m['title']);
    final start = cardTime(m['start']);
    if (title == null || start == null) return null;
    return EventSpec(
      title: title,
      start: start,
      startRaw: cardText(m['start'])!,
      end: cardTime(m['end']),
      endRaw: cardText(m['end']),
      allDay: m['allDay'] == true || cardIsDateOnly(m['start']),
      location: cardText(m['location']),
      attendees: cardTexts(m['attendees']),
      description: cardText(m['description']),
      app: cardText(m['app']),
      actions: actions && m['actions'] != false,
    );
  }

  /// "Thu, Nov 20 · 2:00 PM – 3:00 PM", or "Thu, Nov 20 · All day".
  String whenLine(BuildContext context) {
    final day = cardDay(context, start);
    if (allDay) {
      final e = end;
      return e != null &&
              !cardSameDay(e, start) &&
              e.difference(start).inDays > 1
          ? '$day – ${cardDay(context, e.subtract(const Duration(days: 1)))}'
          : '$day · ${context.l10n.botCardAllDay}';
    }
    final e = end;
    if (e == null) return '$day · ${cardClock(context, start)}';
    final to = cardSameDay(e, start)
        ? cardClock(context, e)
        : '${cardDay(context, e)} ${cardClock(context, e)}';
    return '$day · ${cardClock(context, start)} – $to';
  }

  Map<String, Object?> toValues() => {
    'title': title,
    'start': startRaw,
    'end': ?endRaw,
    if (allDay) 'allDay': true,
    'location': ?location,
    if (attendees.isNotEmpty) 'attendees': attendees,
    'description': ?description,
  };
}

final eventComponent = casamaCard(
  'Event',
  const [
    'title',
    'start',
    'end',
    'allDay',
    'location',
    'attendees',
    'description',
    'app',
    'actions',
  ],
  (context, props, act) {
    final spec = EventSpec.fromMap(props);
    return spec == null ? null : BotEventCard(spec: spec, onAction: act);
  },
);

/// One event, to add to the calendar or just to show.
class BotEventCard extends StatelessWidget {
  const BotEventCard({
    super.key,
    required this.spec,
    this.onAction,
    this.showHeader = true,
  });
  final EventSpec spec;
  final CardAction? onAction;
  final bool showHeader;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final act = onAction;
    final guests = spec.attendees.length <= 3
        ? spec.attendees.join(', ')
        : '${spec.attendees.take(3).join(', ')} ${l10n.botCardMore(spec.attendees.length - 3)}';
    return CardLayout(
      header: showHeader
          ? CardHeader(
              title: spec.actions ? l10n.botCardNewEvent : l10n.botCardEvent,
              app: spec.app,
              icon: LucideIcons.calendar,
              pill: spec.actions ? l10n.botCardReadyToAdd : null,
            )
          : null,
      body: CardPanel(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              spec.title,
              style: context.textTheme.titleMedium?.copyWith(
                fontFamily: AppFonts.sans,
                fontWeight: FontWeight.w600,
              ),
            ),
            CardFact(icon: LucideIcons.clock, text: spec.whenLine(context)),
            if (spec.location != null)
              CardFact(icon: LucideIcons.mapPin, text: spec.location!),
            if (guests.isNotEmpty)
              CardFact(icon: LucideIcons.users, text: guests),
            if (spec.description != null)
              CardFact(
                icon: LucideIcons.alignLeft,
                text: spec.description!,
                maxLines: 4,
              ),
          ],
        ),
      ),
      buttons: spec.actions && act != null
          ? [
              CardButton(
                key: const Key('eventAdd'),
                label: l10n.botCardAddToCalendar,
                kind: CardButtonKind.primary,
                onPressed: () => act(
                  'event.add',
                  spec.toValues(),
                  l10n.botCardAddToCalendar,
                ),
              ),
              CardButton(
                key: const Key('eventChange'),
                label: l10n.botCardChange,
                onPressed: () => act('event.change', {
                  'title': spec.title,
                }, l10n.botCardChange),
              ),
              CardButton(
                key: const Key('eventSkip'),
                label: l10n.botCardSkip,
                kind: CardButtonKind.quiet,
                onPressed: () =>
                    act('event.skip', {'title': spec.title}, l10n.botCardSkip),
              ),
            ]
          : const [],
    );
  }
}

// ---------------------------------------------------------------------------------------------
// Agenda
// ---------------------------------------------------------------------------------------------

final agendaComponent = casamaCard(
  'Agenda',
  const ['title', 'date', 'events'],
  (context, props, act) {
    final events = [
      for (final m in cardRows(props['events']))
        ?EventSpec.fromMap(m, actions: false),
    ]..sort((a, b) => a.start.compareTo(b.start));
    if (events.isEmpty) return null;
    return BotAgendaCard(
      title: cardText(props['title']),
      events: events.take(40).toList(),
    );
  },
);

/// A day or a week of events.
class BotAgendaCard extends StatelessWidget {
  const BotAgendaCard({super.key, this.title, required this.events});
  final String? title;
  final List<EventSpec> events;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final tt = context.textTheme;
    final oneDay = events.every(
      (e) => cardSameDay(e.start, events.first.start),
    );
    final rows = <Widget>[];
    DateTime? day;
    for (final e in events) {
      if (!oneDay && (day == null || !cardSameDay(day, e.start))) {
        day = e.start;
        rows.add(
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 2),
            child: Text(
              cardDay(context, e.start),
              style: tt.labelLarge?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }
      final sub = [
        if (!e.allDay && e.end != null)
          '${cardClock(context, e.start)} – ${cardClock(context, e.end!)}',
        ?e.location,
      ].join(' · ');
      rows.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 72,
                child: Text(
                  e.allDay
                      ? context.l10n.botCardAllDay
                      : cardClock(context, e.start),
                  style: tt.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontFeatures: AppText.tabular,
                  ),
                ),
              ),
              Container(
                width: 3,
                height: sub.isEmpty ? 18 : 36,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.title,
                      style: tt.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (sub.isNotEmpty)
                      Text(
                        sub,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tt.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    return CardLayout(
      header: CardHeader(
        title:
            title ??
            (oneDay
                ? cardDay(context, events.first.start)
                : context.l10n.botCardAgenda),
        icon: LucideIcons.calendarDays,
      ),
      body: CardPanel(
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: rows,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------------------------
// Schedule
// ---------------------------------------------------------------------------------------------

final scheduleComponent = casamaCard(
  'Schedule',
  const ['kind', 'title', 'when', 'next', 'detail', 'ref'],
  (context, props, act) {
    final title = cardText(props['title']);
    final when = cardText(props['when']);
    if (title == null || when == null) return null;
    final l10n = context.l10n;
    final kind = cardText(props['kind']);
    final (icon, label) = switch (kind) {
      'routine' => (LucideIcons.repeat, l10n.botCardRoutine),
      'watcher' => (LucideIcons.eye, l10n.botCardWatcher),
      _ => (LucideIcons.bellRing, l10n.botCardReminder),
    };
    final next = cardTime(props['next']);
    final detail = cardText(props['detail']);
    // `ref` is the routine's or watcher's own id; `id` is the component's.
    final values = {'ref': ?cardText(props['ref']), 'title': title};
    return CardLayout(
      header: CardHeader(
        title: label,
        icon: icon,
        pill: l10n.botCardScheduled,
        pillColor: context.appColors.positive,
      ),
      body: CardPanel(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: context.textTheme.titleMedium?.copyWith(
                fontFamily: AppFonts.sans,
                fontWeight: FontWeight.w600,
              ),
            ),
            CardFact(icon: LucideIcons.clock, text: when),
            if (next != null)
              CardFact(
                icon: LucideIcons.calendarClock,
                text: l10n.botCardNext(
                  '${cardDay(context, next)}, ${cardClock(context, next)}',
                ),
              ),
            if (detail != null)
              CardFact(icon: LucideIcons.alignLeft, text: detail, maxLines: 4),
          ],
        ),
      ),
      buttons: [
        CardButton(
          key: const Key('scheduleChange'),
          label: l10n.botCardChange,
          onPressed: () => act('schedule.change', values, l10n.botCardChange),
        ),
        CardButton(
          key: const Key('scheduleCancel'),
          label: l10n.botCardCancelIt,
          kind: CardButtonKind.quiet,
          onPressed: () => act('schedule.cancel', values, l10n.botCardCancelIt),
        ),
      ],
    );
  },
);

// ---------------------------------------------------------------------------------------------
// Details
// ---------------------------------------------------------------------------------------------

final detailsComponent = casamaCard(
  'Details',
  const ['title', 'rows', 'footer'],
  (context, props, act) {
    final rows = [
      for (final r in cardRows(props['rows']))
        if (cardText(r['label']) case final label?)
          if (cardText(r['value']) case final value?)
            (label: label, value: value),
    ];
    if (rows.isEmpty) return null;
    final scheme = context.colorScheme;
    final tt = context.textTheme;
    final title = cardText(props['title']);
    final footer = cardText(props['footer']);
    return CardLayout(
      header: title == null
          ? null
          : CardHeader(title: title, icon: LucideIcons.receiptText),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          CardPanel(
            child: CardRows(
              children: [
                for (final r in rows.take(30))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            r.label,
                            style: tt.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpace.sm),
                        Expanded(
                          flex: 3,
                          child: SelectableText(
                            r.value,
                            textAlign: TextAlign.end,
                            style: tt.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (footer != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpace.xs),
              child: Text(
                footer,
                style: tt.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
        ],
      ),
    );
  },
);

// ---------------------------------------------------------------------------------------------
// Stats
// ---------------------------------------------------------------------------------------------

final statsComponent = casamaCard('Stats', const ['title', 'stats', 'chart'], (
  context,
  props,
  act,
) {
  final stats = [
    for (final s in cardRows(props['stats']).take(8))
      if (cardText(s['label']) case final label?)
        if (cardText(s['value']) case final value?)
          (
            label: label,
            value: value,
            unit: cardText(s['unit']),
            change: cardText(s['change']),
            trend: cardText(s['trend']),
            good: cardText(s['good']),
          ),
  ];
  final chart = ChartSpec.of(props['chart']);
  if (stats.isEmpty && chart == null) return null;
  final title = cardText(props['title']);
  return CardLayout(
    header: title == null
        ? null
        : CardHeader(title: title, icon: LucideIcons.chartLine),
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (stats.isNotEmpty)
          LayoutBuilder(
            builder: (context, box) {
              final perRow = box.maxWidth >= 420 ? 3 : 2;
              final width =
                  (box.maxWidth - AppSpace.xs * (perRow - 1)) / perRow;
              return Wrap(
                spacing: AppSpace.xs,
                runSpacing: AppSpace.xs,
                children: [
                  for (final s in stats)
                    SizedBox(
                      width: stats.length == 1 ? box.maxWidth : width,
                      child: _StatTile(
                        label: s.label,
                        value: s.value,
                        unit: s.unit,
                        change: s.change,
                        trend: s.trend,
                        good: s.good,
                      ),
                    ),
                ],
              );
            },
          ),
        if (stats.isNotEmpty && chart != null)
          const SizedBox(height: AppSpace.xs),
        if (chart != null)
          CardPanel(
            padding: const EdgeInsets.fromLTRB(8, 14, 14, 8),
            child: _Chart(spec: chart),
          ),
      ],
    ),
  );
});

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    this.unit,
    this.change,
    this.trend,
    this.good,
  });
  final String label;
  final String value;
  final String? unit;
  final String? change;
  final String? trend;
  final String? good;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final tt = context.textTheme;
    final colors = context.appColors;
    final dir =
        trend ??
        (change?.startsWith('-') == true
            ? 'down'
            : change?.startsWith('+') == true
            ? 'up'
            : null);
    final color = dir == null || dir == 'flat' || good == null
        ? scheme.onSurfaceVariant
        : dir == good
        ? colors.positive
        : colors.negative;
    final arrow = switch (dir) {
      'up' => LucideIcons.trendingUp,
      'down' => LucideIcons.trendingDown,
      _ => LucideIcons.minus,
    };
    return CardPanel(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: tt.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 2),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: value),
                if (unit != null)
                  TextSpan(
                    text: ' $unit',
                    style: tt.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: tt.titleLarge?.copyWith(
              fontFamily: AppFonts.sans,
              fontWeight: FontWeight.w600,
              fontFeatures: AppText.tabular,
            ),
          ),
          if (change != null || dir != null)
            Row(
              children: [
                Icon(arrow, size: 14, color: color),
                if (change != null) ...[
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      change!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: tt.labelMedium?.copyWith(color: color),
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

/// A Stats card's chart: one to four series over shared labels.
class ChartSpec {
  const ChartSpec({
    required this.bar,
    required this.labels,
    required this.series,
    this.unit,
  });
  final bool bar;
  final List<String> labels;
  final List<({String? name, List<double> values})> series;
  final String? unit;

  static ChartSpec? of(Object? v) {
    if (v is! Map) return null;
    final labels = cardTexts(v['labels']);
    if (labels.length < 2) return null;
    final series = [
      for (final s in cardRows(v['series']).take(4))
        if (s['values'] case final List<Object?> values
            when values.length == labels.length &&
                values.every((x) => x is num))
          (
            name: cardText(s['name']),
            values: [for (final x in values) (x! as num).toDouble()],
          ),
    ];
    if (series.isEmpty) return null;
    return ChartSpec(
      bar: v['type'] == 'bar',
      labels: labels.take(60).toList(),
      series: series,
      unit: cardText(v['unit']),
    );
  }
}

class _Chart extends StatelessWidget {
  const _Chart({required this.spec});
  final ChartSpec spec;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final tt = context.textTheme;
    final palette = [
      scheme.primary,
      scheme.tertiary,
      context.appColors.warning,
      scheme.secondary,
    ];
    final all = [for (final s in spec.series) ...s.values];
    final hi = all.reduce((a, b) => a > b ? a : b);
    final lo = all.reduce((a, b) => a < b ? a : b);
    final minY = lo >= 0 ? 0.0 : lo * 1.1;
    final maxY = hi <= 0 ? 1.0 : hi * 1.12;
    final every = (spec.labels.length / 6).ceil().clamp(1, 60);
    String num(double v) => v.abs() >= 1000
        ? '${(v / 1000).toStringAsFixed(v.abs() >= 10000 ? 0 : 1)}k'
        : (v == v.roundToDouble()
              ? v.toStringAsFixed(0)
              : v.toStringAsFixed(1));
    final titles = FlTitlesData(
      topTitles: const AxisTitles(),
      rightTitles: const AxisTitles(),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 36,
          getTitlesWidget: (v, meta) => v == meta.max
              ? const SizedBox.shrink()
              : Text(
                  num(v),
                  style: tt.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 22,
          interval: 1,
          getTitlesWidget: (v, _) {
            final i = v.round();
            if (i < 0 ||
                i >= spec.labels.length ||
                (i % every != 0 && i != spec.labels.length - 1)) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                spec.labels[i],
                style: tt.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            );
          },
        ),
      ),
    );
    final grid = FlGridData(
      drawVerticalLine: false,
      getDrawingHorizontalLine: (_) =>
          FlLine(color: context.appColors.hairline, strokeWidth: 1),
    );
    final chart = spec.bar
        ? BarChart(
            BarChartData(
              minY: minY,
              maxY: maxY,
              borderData: FlBorderData(show: false),
              gridData: grid,
              titlesData: titles,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => scheme.inverseSurface,
                ),
              ),
              barGroups: [
                for (var i = 0; i < spec.labels.length; i++)
                  BarChartGroupData(
                    x: i,
                    barsSpace: 2,
                    barRods: [
                      for (final (k, s) in spec.series.indexed)
                        BarChartRodData(
                          toY: s.values[i],
                          color: palette[k],
                          width:
                              (120 / (spec.labels.length * spec.series.length))
                                  .clamp(3, 18),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(3),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          )
        : LineChart(
            LineChartData(
              minY: minY,
              maxY: maxY,
              borderData: FlBorderData(show: false),
              gridData: grid,
              titlesData: titles,
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => scheme.inverseSurface,
                ),
              ),
              lineBarsData: [
                for (final (k, s) in spec.series.indexed)
                  LineChartBarData(
                    spots: [
                      for (var i = 0; i < s.values.length; i++)
                        FlSpot(i.toDouble(), s.values[i]),
                    ],
                    isCurved: true,
                    preventCurveOverShooting: true,
                    color: palette[k],
                    barWidth: 2.5,
                    dotData: FlDotData(show: spec.labels.length <= 12),
                    belowBarData: BarAreaData(
                      show: spec.series.length == 1,
                      color: palette[k].withValues(alpha: 0.12),
                    ),
                  ),
              ],
            ),
          );
    final named = spec.series.where((s) => s.name != null).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: 160, child: chart),
        if (named.length > 1 || spec.unit != null)
          Padding(
            padding: const EdgeInsets.only(left: 8, top: 6),
            child: Wrap(
              spacing: AppSpace.sm,
              runSpacing: 4,
              children: [
                for (final (k, s) in spec.series.indexed)
                  if (s.name != null && named.length > 1)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: palette[k],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          s.name!,
                          style: tt.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                if (spec.unit != null)
                  Text(
                    spec.unit!,
                    style: tt.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
