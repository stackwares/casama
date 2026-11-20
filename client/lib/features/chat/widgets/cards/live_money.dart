import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/widgets.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_tokens.dart';
import 'live_kit.dart';

// Money cards (docs/RICH-CARDS-PLAN.md §6.2, §7.6, §7.8): prices and rates from the server, never
// typed by the model. Delayed quotes say so; nothing here buys or sells.

String _marketWord(BuildContext context, String? s) {
  final l = context.l10n;
  return switch (s) {
    'open' => l.cardMarketOpen,
    'pre' => l.cardMarketPre,
    'post' => l.cardMarketPost,
    '24h' => l.cardMarket24h,
    _ => l.cardMarketClosed,
  };
}

/// A flag emoji for a currency's country (USD 🇺🇸, EUR 🇪🇺, PHP 🇵🇭); nothing for others.
String currencyFlag(String code) {
  if (code.length != 3) return '';
  final cc = code.substring(0, 2).toUpperCase();
  if (code == 'XAU' || code == 'XAG' || code == 'BTC') return '';
  return String.fromCharCodes(cc.codeUnits.map((c) => 0x1F1E6 + c - 65));
}

final quoteComponent = liveCard('Quote', const [
  'symbol', 'name', 'kind', 'exchange', 'currency', 'price', 'change', 'changePct', 'prevClose', 'open', 'dayLow', 'dayHigh', 'low52', 'high52', 'volume', 'marketCap', 'logoUrl', 'marketState', 'asOf', 'delayedMinutes', 'chart',
], (context, p, ctl) {
  final l = context.l10n;
  final price = p.n('price');
  if (price == null) return null;
  final cur = p.s('currency');
  final pct = p.n('changePct') ?? 0;
  final chg = p.n('change') ?? 0;
  final chart = p.map('chart');
  final pts = [
    for (final x in (chart['points'] is List ? chart['points'] as List : const []))
      if (x is List && x.length == 2 && x[1] is num) (x[0] as num, (x[1] as num).toDouble()),
  ];
  final range = chart.s('range') ?? ctl.view ?? '1D';
  final color = changeColor(context, pct);
  final state = p.s('marketState');
  final kind = p.s('kind');
  String when(num t) {
    final d = DateTime.fromMillisecondsSinceEpoch(t.toInt());
    return range == '1D' ? clockOf(context, d) : DateFormat.yMMMd(l.localeName).format(d);
  }

  return LiveLayout(
    header: LiveHeader(
      leading: Monogram(text: p.s('symbol') ?? '', url: p.s('logoUrl'), size: 32),
      icon: LucideIcons.trendingUp,
      title: p.s('name') ?? p.s('symbol') ?? '',
      subtitle: [p.s('symbol'), ?p.s('exchange')].whereType<String>().join(' · '),
      pill: _marketWord(context, state),
      pillColor: state == 'open' || state == '24h' ? context.appColors.positive : null,
    ),
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: HeroNumber(value: price, format: (v) => fmtMoney(context, v, cur), style: context.textTheme.displaySmall?.copyWith(fontSize: 38, letterSpacing: -1)),
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: ChangePill(pct: pct, big: true, label: '${chg >= 0 ? '+' : '−'}${fmtMoney(context, chg.abs(), cur)} (${fmtPct(pct)})'),
                ),
              ),
            ),
          ],
        ),
        Text(kind == 'crypto' && range == '1D' ? l.cardLast24h : l.cardRangeChange(range), style: context.cardLabel),
        const SizedBox(height: 18),
        if (pts.length > 1)
          Sparkline(
            points: [for (final x in pts) x.$2],
            baseline: range == '1D' ? p.n('prevClose') : null,
            color: color,
            height: 110,
            label: (i) => '${fmtMoney(context, pts[i].$2, cur)} · ${when(pts[i].$1)}',
          )
        else
          SizedBox(height: 60, child: Center(child: Text(l.cardNoChart, style: context.cardLabel))),
        const SizedBox(height: 10),
        ViewChips(
          options: [for (final r in const ['1D', '1W', '1M', '3M', '1Y', '5Y']) (r, r)],
          selected: range,
          onSelect: (v) => ctl.setView(v),
        ),
        const SizedBox(height: 12),
        _QuoteStats(p: p, cur: cur),
      ],
    ),
    footer: LiveFooter(note: kind == 'crypto' || kind == 'stock' || kind == 'etf' ? l.cardNotAdvice : null),
  );
});

class _QuoteStats extends StatelessWidget {
  const _QuoteStats({required this.p, this.cur});
  final P p;
  final String? cur;
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final price = p.n('price') ?? 0;
    final rows = <Widget>[
      if (p.n('dayLow') != null && p.n('dayHigh') != null) _RangeRow(label: p.s('kind') == 'crypto' ? l.card24hRange : l.cardDayRange, lo: p.n('dayLow')!, hi: p.n('dayHigh')!, at: price, cur: cur),
      if (p.n('low52') != null && p.n('high52') != null) _RangeRow(label: l.card52wRange, lo: p.n('low52')!, hi: p.n('high52')!, at: price, cur: cur),
    ];
    final facts = <(String, String)>[
      if (p.n('open') != null) (l.cardOpen, fmtMoney(context, p.n('open')!, cur)),
      if (p.n('prevClose') != null && p.s('kind') != 'crypto') (l.cardPrevClose, fmtMoney(context, p.n('prevClose')!, cur)),
      if (p.n('volume') != null) (l.cardVolume, fmtCompact(context, p.n('volume')!)),
      if (p.n('marketCap') != null) (l.cardMarketCap, fmtMoney(context, p.n('marketCap')!, cur, compact: true)),
    ];
    if (rows.isEmpty && facts.isEmpty) return const SizedBox.shrink();
    return LivePanel(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...rows,
          if (facts.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: rows.isEmpty ? 0 : 8),
              child: Wrap(
                spacing: 18,
                runSpacing: 8,
                children: [
                  for (final (k, v) in facts)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [Text(k, style: context.cardLabel), Text(v, style: context.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600, fontFeatures: AppText.tabular))],
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _RangeRow extends StatelessWidget {
  const _RangeRow({required this.label, required this.lo, required this.hi, required this.at, this.cur});
  final String label;
  final double lo, hi, at;
  final String? cur;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: context.cardLabel),
        const SizedBox(height: 4),
        RangeBar(min: lo, max: hi, lo: lo, hi: hi, marker: at, colors: [context.appColors.negative.withValues(alpha: 0.7), context.appColors.positive.withValues(alpha: 0.7)]),
        const SizedBox(height: 2),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(fmtMoney(context, lo, cur), style: context.textTheme.labelSmall?.copyWith(fontFeatures: AppText.tabular)),
            Text(fmtMoney(context, hi, cur), style: context.textTheme.labelSmall?.copyWith(fontFeatures: AppText.tabular)),
          ],
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------------------------
// Watchlist
// ---------------------------------------------------------------------------------------------

final watchlistComponent = liveCard('Watchlist', const ['title', 'quotes'], (context, p, ctl) {
  final l = context.l10n;
  final quotes = p.rows('quotes');
  if (quotes.isEmpty) return null;
  final up = quotes.where((q) => (q.n('changePct') ?? 0) >= 0).length;
  return LiveLayout(
    header: LiveHeader(icon: LucideIcons.chartLine, title: p.s('title') ?? l.cardWatchlist, subtitle: l.cardUpDown(up, quotes.length - up)),
    body: LivePanel(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(
        children: [
          for (final (i, q) in quotes.indexed) ...[
            if (i > 0) Divider(height: 1, color: context.appColors.hairline),
            _WatchRow(q: q),
          ],
        ],
      ),
    ),
    footer: LiveFooter(note: l.cardNotAdvice),
  );
});

class _WatchRow extends StatelessWidget {
  const _WatchRow({required this.q});
  final P q;
  @override
  Widget build(BuildContext context) {
    final pct = q.n('changePct') ?? 0;
    final chart = q.map('chart');
    final pts = [
      for (final x in (chart['points'] is List ? chart['points'] as List : const []))
        if (x is List && x.length == 2 && x[1] is num) (x[1] as num).toDouble(),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Monogram(text: q.s('symbol') ?? '', url: q.s('logoUrl'), size: 30),
          const SizedBox(width: 10),
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(q.s('symbol') ?? '', style: context.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
                Text(q.s('name') ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: context.cardLabel),
              ],
            ),
          ),
          if (pts.length > 1) SizedBox(width: 64, height: 26, child: Sparkline(points: pts, color: changeColor(context, pct), height: 26)),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ConstrainedBox(constraints: const BoxConstraints(maxWidth: 120), child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerRight, child: Text(fmtMoney(context, q.n('price') ?? 0, q.s('currency')), style: context.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700, fontFeatures: AppText.tabular)))),
              const SizedBox(height: 2),
              ChangePill(pct: pct),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------------------------
// Currency
// ---------------------------------------------------------------------------------------------

final currencyComponent = liveCard('Currency', const ['base', 'amount', 'date', 'rates', 'trend'], (context, p, ctl) {
  if (p.rows('rates').isEmpty) return null;
  return _Currency(p: p);
});

class _Currency extends StatefulWidget {
  const _Currency({required this.p});
  final P p;
  @override
  State<_Currency> createState() => _CurrencyState();
}

class _CurrencyState extends State<_Currency> {
  late double _amount = widget.p.n('amount') ?? 1;
  bool _swapped = false;
  late final _field = TextEditingController(text: _fmtInput(_amount));

  static String _fmtInput(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = widget.p;
    final base = p.s('base') ?? 'USD';
    final rates = p.rows('rates');
    final single = rates.length == 1;
    final first = rates.first;
    final from = _swapped && single ? first.s('to')! : base;
    double rateOf(P r) => _swapped && single ? 1 / (r.n('rate') ?? 1) : (r.n('rate') ?? 1);
    final trend = p.map('trend');
    final tp = [
      for (final x in (trend['points'] is List ? trend['points'] as List : const []))
        if (x is List && x.length == 2 && x[1] is num) (x[0] as String, (x[1] as num).toDouble()),
    ];
    final tPct = tp.length > 1 ? (tp.last.$2 / tp.first.$2 - 1) * 100 : null;
    return LiveLayout(
      header: LiveHeader(icon: LucideIcons.arrowLeftRight, iconColor: const Color(0xFF16A085), title: l.cardCurrency, subtitle: p.s('date') == null ? null : l.cardRatesOf(DateFormat.yMMMd(l.localeName).format(DateTime.parse(p.s('date')!)))),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LivePanel(
            padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
            child: Row(
              children: [
                Text('${currencyFlag(from)} $from', style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _field,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                    textAlign: TextAlign.right,
                    style: context.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700, fontFeatures: AppText.tabular),
                    decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                    onChanged: (v) => setState(() => _amount = double.tryParse(v.replaceAll(',', '')) ?? 0),
                  ),
                ),
                if (single)
                  IconButton(
                    tooltip: l.cardSwap,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _swapped = !_swapped);
                    },
                    icon: const Icon(LucideIcons.arrowUpDown, size: 18),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (single)
            _Converted(to: _swapped ? base : first.s('to')!, value: _amount * rateOf(first), rate: rateOf(first), from: from)
          else
            LivePanel(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: Column(
                children: [
                  for (final (i, r) in rates.indexed) ...[
                    if (i > 0) Divider(height: 1, color: context.appColors.hairline),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          Text('${currencyFlag(r.s('to') ?? '')}  ${r.s('to')}', style: context.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerRight, child: Text(fmtMoney(context, _amount * rateOf(r), r.s('to')), style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, fontFeatures: AppText.tabular))),
                                Text('1 $base = ${fmtNum(context, rateOf(r), digits: 4)}', maxLines: 1, overflow: TextOverflow.ellipsis, style: context.cardLabel),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          if (single && tp.length > 1) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Text(l.cardLast30Days, style: context.cardLabel),
                const Spacer(),
                if (tPct != null) ChangePill(pct: tPct, goodWhenUp: true),
              ],
            ),
            const SizedBox(height: 18),
            Sparkline(
              points: [for (final x in tp) x.$2],
              color: const Color(0xFF16A085),
              height: 64,
              label: (i) => '${fmtNum(context, tp[i].$2, digits: 4)} · ${DateFormat.MMMd(l.localeName).format(DateTime.parse(tp[i].$1))}',
            ),
          ],
        ],
      ),
      footer: LiveFooter(note: l.cardReferenceRates),
    );
  }
}

class _Converted extends StatelessWidget {
  const _Converted({required this.to, required this.value, required this.rate, required this.from});
  final String to;
  final double value;
  final double rate;
  final String from;
  @override
  Widget build(BuildContext context) => LivePanel(
    gradient: const LinearGradient(colors: [Color(0xFF16A085), Color(0xFF0E7C66)]),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${currencyFlag(to)} $to', style: context.textTheme.labelLarge?.copyWith(color: Colors.white70, fontWeight: FontWeight.w700)),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: HeroNumber(value: value, format: (v) => fmtMoney(context, v, to), color: Colors.white, style: context.textTheme.displaySmall?.copyWith(fontSize: 36)),
        ),
        Text('1 $from = ${fmtNum(context, rate, digits: 4)} $to  ·  1 $to = ${fmtNum(context, 1 / rate, digits: 4)} $from', style: context.textTheme.labelMedium?.copyWith(color: Colors.white70, fontFeatures: AppText.tabular)),
      ],
    ),
  );
}
