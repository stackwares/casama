import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/widgets.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_tokens.dart';
import 'live_kit.dart';

// Flight fares (docs/FLIGHT-SEARCH-PLAN.md §5): real prices from Kiwi.com or Google Flights, sorted
// and filtered on the device, with a Book button that opens the provider's page in the browser.

const _planeBlue = Color(0xFF2F7BD3);

final faresComponent = liveCard('Fares', const [
  'from',
  'to',
  'depart',
  'return',
  'nights',
  'travellers',
  'cabin',
  'currency',
  'sort',
  'roundTrip',
  'outboundOnly',
  'cheapest',
  'fastest',
  'options',
  'typical',
  'searchUrl',
], (context, p, ctl) => _Fares(p: p));

enum _Sort { best, cheapest, fastest }

class _Fares extends StatefulWidget {
  const _Fares({required this.p});
  final P p;

  @override
  State<_Fares> createState() => _FaresState();
}

class _FaresState extends State<_Fares> {
  late _Sort _sort = switch (widget.p.s('sort')) {
    'cheapest' => _Sort.cheapest,
    'fastest' => _Sort.fastest,
    _ => _Sort.best,
  };
  bool _direct = false;
  bool _all = false;

  P get p => widget.p;

  List<P> get _options {
    final all = p.rows('options');
    final list = [
      for (final o in all)
        if (!_direct ||
            (o.map('out').i('stops') ?? 0) == 0 &&
                (o.map('back').isEmpty || (o.map('back').i('stops') ?? 0) == 0))
          o,
    ];
    switch (_sort) {
      case _Sort.cheapest:
        list.sort((a, b) => (a.n('price') ?? 0).compareTo(b.n('price') ?? 0));
      case _Sort.fastest:
        list.sort((a, b) {
          final m = (a.i('minutes') ?? 0).compareTo(b.i('minutes') ?? 0);
          return m != 0 ? m : (a.n('price') ?? 0).compareTo(b.n('price') ?? 0);
        });
      case _Sort.best:
        break;
    }
    return list;
  }

  String _date(String? iso) {
    if (iso == null) return '';
    final locale = context.l10n.localeName;
    if (iso.length == 7) {
      final d = DateTime.tryParse('$iso-01');
      return d == null ? iso : DateFormat.yMMMM(locale).format(d);
    }
    final d = DateTime.tryParse(iso);
    return d == null ? iso : DateFormat.MMMd(locale).format(d);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final from = p.map('from');
    final to = p.map('to');
    final cur = p.s('currency');
    final t = p.map('travellers');
    final people =
        (t.i('adults') ?? 1) + (t.i('children') ?? 0) + (t.i('infants') ?? 0);
    final dates = [
      _date(p.s('depart')),
      if (p.s('return') != null) _date(p.s('return')),
    ].join(' – ');
    final nights = p.i('nights');
    final cabin = switch (p.s('cabin')) {
      'premium' => l.cardFaresPremium,
      'business' => l.cardFaresBusiness,
      'first' => l.cardFaresFirst,
      _ => l.cardFaresEconomy,
    };
    final subtitle = [
      if (nights != null) '$dates · ${l.cardFaresNights(nights)}' else dates,
      l.cardFaresTravellers(people),
      cabin,
    ].join(' · ');
    final options = _options;
    final cheapest = p.n('cheapest');
    final fastest = p.i('fastest');
    final shown = _all ? options : options.take(3).toList();
    final typical = p.map('typical');
    final level = switch (typical.s('level')) {
      'low' => (l.cardFaresLevelLow, context.appColors.positive),
      'high' => (l.cardFaresLevelHigh, context.appColors.warning),
      'typical' => (
        l.cardFaresLevelTypical,
        context.colorScheme.onSurfaceVariant,
      ),
      _ => null,
    };

    return LiveLayout(
      header: LiveHeader(
        icon: LucideIcons.plane,
        iconColor: _planeBlue,
        title: '${from.s('label') ?? '—'} → ${to.s('label') ?? '—'}',
        subtitle: subtitle,
        pill: cheapest == null
            ? null
            : l.cardFaresFromPrice(fmtFare(context, cheapest, cur)),
        pillColor: _planeBlue,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (typical.n('low') != null && typical.n('high') != null) ...[
            Row(
              children: [
                Icon(
                  LucideIcons.chartNoAxesColumn,
                  size: 14,
                  color: context.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    l.cardFaresTypical(
                      fmtFare(context, typical.n('low')!, cur),
                      fmtFare(context, typical.n('high')!, cur),
                    ),
                    style: context.cardLabel,
                  ),
                ),
                if (level != null) LivePill(text: level.$1, color: level.$2),
              ],
            ),
            const SizedBox(height: 10),
          ],
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final (s, label) in [
                (_Sort.best, l.cardFaresBest),
                (_Sort.cheapest, l.cardFaresCheapest),
                (_Sort.fastest, l.cardFaresFastest),
              ])
                ChoiceChip(
                  key: Key('faresSort-${s.name}'),
                  label: Text(label),
                  selected: _sort == s,
                  onSelected: (_) => setState(() => _sort = s),
                  visualDensity: VisualDensity.compact,
                ),
              FilterChip(
                key: const Key('faresDirect'),
                label: Text(l.cardFaresDirectOnly),
                selected: _direct,
                onSelected: (v) => setState(() => _direct = v),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (options.isEmpty)
            LivePanel(
              child: Text(l.cardFaresNoDirect, style: context.cardLabel),
            )
          else
            for (final o in shown) ...[
              _FareRow(
                o: o,
                currency: cur,
                cheapest: cheapest != null && o.n('price') == cheapest,
                fastest: fastest != null && o.i('minutes') == fastest,
              ),
              const SizedBox(height: 8),
            ],
          if (options.length > 3)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                key: const Key('faresMore'),
                onPressed: () => setState(() => _all = !_all),
                child: Text(
                  _all
                      ? l.cardFaresShowFewer
                      : l.cardFaresShowAll(options.length),
                ),
              ),
            ),
          if (p.b('outboundOnly') == true) ...[
            Text(l.cardFaresOutboundOnly, style: context.cardLabel),
            if (p.s('searchUrl') case final u?)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => openCardLink(u),
                  icon: const Icon(LucideIcons.externalLink, size: 14),
                  label: Text(l.cardFaresSeeAll),
                ),
              ),
          ] else
            Text(l.cardFaresCheck, style: context.cardLabel),
        ],
      ),
    );
  }
}

/// A fare in the card's currency, without cents.
String fmtFare(BuildContext context, num v, String? currency) {
  final cur = (currency ?? '').toUpperCase();
  try {
    return NumberFormat.simpleCurrency(
      locale: context.l10n.localeName,
      name: cur.isEmpty ? null : cur,
      decimalDigits: 0,
    ).format(v);
  } catch (_) {
    return '${NumberFormat.decimalPattern(context.l10n.localeName).format(v.round())} $cur';
  }
}

class _FareRow extends StatelessWidget {
  const _FareRow({
    required this.o,
    required this.currency,
    required this.cheapest,
    required this.fastest,
  });
  final P o;
  final String? currency;
  final bool cheapest;
  final bool fastest;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final airlines = o.texts('airlines');
    final link = o.s('link');
    return LivePanel(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          fmtFare(context, o.n('price') ?? 0, currency),
                          style: context.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            fontFeatures: AppText.tabular,
                          ),
                        ),
                        if (cheapest)
                          LivePill(
                            text: l.cardFaresCheapest,
                            color: context.appColors.positive,
                          ),
                        if (fastest)
                          LivePill(text: l.cardFaresFastest, color: _planeBlue),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      airlines.isEmpty ? '—' : airlines.join(' + '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.cardLabel,
                    ),
                  ],
                ),
              ),
              if (link != null) ...[
                const SizedBox(width: 8),
                FilledButton.tonalIcon(
                  key: Key('faresBook-${o.s('id')}'),
                  onPressed: () => openCardLink(link),
                  icon: const Icon(LucideIcons.externalLink, size: 14),
                  label: Text(l.cardFaresBook),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          _Leg(leg: o.map('out')),
          if (!o.map('back').isEmpty) ...[
            const SizedBox(height: 6),
            _Leg(leg: o.map('back'), back: true),
          ],
          if (!o.map('bags').isEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  LucideIcons.briefcase,
                  size: 13,
                  color: context.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  l.cardFaresBags(
                    o.map('bags').i('cabin') ?? 0,
                    o.map('bags').i('checked') ?? 0,
                  ),
                  style: context.textTheme.labelSmall?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Leg extends StatelessWidget {
  const _Leg({required this.leg, this.back = false});
  final P leg;
  final bool back;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final dep = placeTime(leg.s('depart'));
    final arr = placeTime(leg.s('arrive'));
    final nextDay =
        dep != null &&
        arr != null &&
        DateUtils.dateOnly(arr).isAfter(DateUtils.dateOnly(dep));
    final stops = leg.i('stops') ?? 0;
    final via = leg.texts('via');
    final minutes = leg.i('minutes') ?? 0;
    final muted = context.colorScheme.onSurfaceVariant;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(
            back ? LucideIcons.planeLanding : LucideIcons.planeTakeoff,
            size: 14,
            color: muted,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: dep == null ? '—' : clockOf(context, dep)),
                    const TextSpan(text: ' → '),
                    TextSpan(text: arr == null ? '—' : clockOf(context, arr)),
                    if (nextDay)
                      TextSpan(
                        text: ' +1',
                        style: TextStyle(
                          color: context.appColors.warning,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
                style: context.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontFeatures: AppText.tabular,
                ),
              ),
              Text(
                [
                  '${leg.s('from') ?? ''}–${leg.s('to') ?? ''}',
                  if (stops == 0)
                    l.cardFaresDirect
                  else
                    '${l.cardFaresStops(stops)}${via.isEmpty ? '' : ' (${via.join(', ')})'}',
                  _duration(minutes),
                ].join(' · '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.labelMedium?.copyWith(color: muted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

String _duration(int m) => m % 60 == 0
    ? '${m ~/ 60}h'
    : '${m ~/ 60}h ${(m % 60).toString().padLeft(2, '0')}m';
