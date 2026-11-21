import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/analytics.dart';
import '../../../../core/backend.dart';
import '../../../../core/providers.dart';
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
  'affiliate',
  'compare',
], (context, p, ctl) => _Fares(p: p, cardId: ctl.ref));

/// The person's active price watches (FLIGHT-SEARCH-PLAN §9); empty when the server is older.
final fareWatchesProvider = FutureProvider<List<Map<String, Object?>>>((ref) async {
  try {
    return await ref.watch(backendProvider).fareWatches();
  } catch (_) {
    return const [];
  }
});

enum _Sort { best, cheapest, fastest }

class _Fares extends ConsumerStatefulWidget {
  const _Fares({required this.p, this.cardId});
  final P p;
  final String? cardId;

  @override
  ConsumerState<_Fares> createState() => _FaresState();
}

class _FaresState extends ConsumerState<_Fares> {
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
          if (p.map('compare').s('url') case final u? when u.startsWith('https://'))
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const Key('faresCompare'),
                onPressed: () => openCardLink(u),
                icon: const Icon(LucideIcons.externalLink, size: 14),
                label: Text(l.cardFaresCompare(p.map('compare').s('name') ?? 'Aviasales')),
              ),
            ),
          if (p.b('affiliate') == true) ...[
            const SizedBox(height: 4),
            Text(l.cardFaresAffiliate, key: const Key('faresAffiliate'), style: context.cardLabel),
          ],
          if (widget.cardId case final id? when cheapest != null) ...[
            const SizedBox(height: 8),
            _WatchRow(cardId: id, currency: cur, cheapest: cheapest),
          ],
        ],
      ),
    );
  }
}

/// "Watch price", or "Watching · ends Apr 2" with Stop (FLIGHT-SEARCH-PLAN §9).
class _WatchRow extends ConsumerStatefulWidget {
  const _WatchRow({required this.cardId, required this.currency, required this.cheapest});
  final String cardId;
  final String? currency;
  final num cheapest;

  @override
  ConsumerState<_WatchRow> createState() => _WatchRowState();
}

class _WatchRowState extends ConsumerState<_WatchRow> {
  bool _busy = false;

  Future<void> _start() async {
    final l = context.l10n;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final below = await showDialog<double?>(
      context: context,
      builder: (_) => _WatchDialog(currency: widget.currency, cheapest: widget.cheapest),
    );
    if (below == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref.read(backendProvider).watchFares(widget.cardId, below: below > 0 ? below : null);
      ref.invalidate(fareWatchesProvider);
      messenger?.showSnackBar(SnackBar(content: Text(l.cardFaresWatchStarted)));
      Analytics.log('fare_watch_started', {'target': below > 0});
    } on FareWatchFull {
      messenger?.showSnackBar(SnackBar(content: Text(l.cardFaresWatchFull)));
    } catch (_) {
      messenger?.showSnackBar(SnackBar(content: Text(l.cardFaresWatchFailed)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _stop() async {
    final l = context.l10n;
    final messenger = ScaffoldMessenger.maybeOf(context);
    setState(() => _busy = true);
    try {
      await ref.read(backendProvider).unwatchFares(widget.cardId);
      ref.invalidate(fareWatchesProvider);
      messenger?.showSnackBar(SnackBar(content: Text(l.cardFaresWatchStopped)));
      Analytics.log('fare_watch_stopped', {'where': 'card'});
    } catch (_) {
      messenger?.showSnackBar(SnackBar(content: Text(l.cardFaresWatchFailed)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final watches = ref.watch(fareWatchesProvider).value ?? const [];
    final w = watches.where((x) => x['card_id'] == widget.cardId).firstOrNull;
    if (w == null) {
      return Align(
        alignment: Alignment.centerLeft,
        child: OutlinedButton.icon(
          key: const Key('faresWatch'),
          onPressed: _busy ? null : _start,
          icon: const Icon(LucideIcons.bellPlus, size: 16),
          label: Text(l.cardFaresWatch),
        ),
      );
    }
    final ends = DateTime.tryParse('${w['ends_at']}');
    final date = ends == null ? '' : DateFormat.MMMd(l.localeName).format(ends.toLocal());
    final below = w['below'];
    return LivePanel(
      child: Row(
        children: [
          const Icon(LucideIcons.bellRing, size: 16, color: _planeBlue),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              below is num
                  ? l.cardFaresWatchingBelow(fmtFare(context, below, widget.currency), date)
                  : l.cardFaresWatching(date),
              style: context.cardLabel,
            ),
          ),
          TextButton(
            key: const Key('faresWatchStop'),
            onPressed: _busy ? null : _stop,
            child: Text(l.cardFaresWatchStop),
          ),
        ],
      ),
    );
  }
}

/// Asks for an optional target price; answers 0 for "any big drop", null when cancelled.
class _WatchDialog extends StatefulWidget {
  const _WatchDialog({required this.currency, required this.cheapest});
  final String? currency;
  final num cheapest;

  @override
  State<_WatchDialog> createState() => _WatchDialogState();
}

class _WatchDialogState extends State<_WatchDialog> {
  final _target = TextEditingController();

  @override
  void dispose() {
    _target.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AlertDialog(
      title: Text(l.cardFaresWatchTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.cardFaresWatchBody),
          const SizedBox(height: 16),
          TextField(
            key: const Key('faresWatchTarget'),
            controller: _target,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: l.cardFaresWatchTarget,
              helperText: l.cardFaresWatchAnyDrop,
              suffixText: widget.currency,
              hintText: (widget.cheapest * 0.9).round().toString(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(
          key: const Key('faresWatchStart'),
          onPressed: () {
            final v = double.tryParse(_target.text.replaceAll(RegExp(r'[^0-9.]'), ''));
            Navigator.of(context).pop(v ?? 0);
          },
          child: Text(l.cardFaresWatchStart),
        ),
      ],
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
