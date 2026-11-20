import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/widgets.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_tokens.dart';
import '../bot_ui_map.dart';
import 'live_kit.dart';

// Hazards, sports and travel cards (docs/RICH-CARDS-PLAN.md §6.1, §6.5, §6.6).

Color _magColor(double m) => m >= 7
    ? const Color(0xFF8E1B2C)
    : m >= 6
    ? const Color(0xFFD03A2F)
    : m >= 5
    ? const Color(0xFFE07A1F)
    : m >= 4
    ? const Color(0xFFD9A400)
    : const Color(0xFF3BB273);

final quakeComponent = liveCard('Quake', const ['near', 'quakes'], (context, p, ctl) {
  final l = context.l10n;
  final list = p.rows('quakes');
  final near = p.map('near');
  return Consumer(
    builder: (context, ref, _) {
      final u = cardUnitsOf(context, ref);
      return LiveLayout(
        header: LiveHeader(icon: LucideIcons.activity, iconColor: const Color(0xFFE07A1F), title: near.isEmpty ? l.cardQuakesWorld : l.cardQuakesNear(near.s('name') ?? ''), subtitle: l.cardQuakeCount(list.length)),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (list.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.tile),
                child: BotMapCard(
                  spec: MapCardSpec(
                    center: near.isEmpty ? null : LatLng(near.n('lat')!, near.n('lng')!),
                    zoom: near.isEmpty ? 2 : 5,
                    markers: [for (final q in list) (point: LatLng(q.n('lat') ?? 0, q.n('lng') ?? 0), label: 'M${q.n('magnitude')}')],
                    path: const [],
                    height: 180,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            if (list.isEmpty)
              LivePanel(child: Text(l.cardNoQuakes, style: context.cardBody))
            else
              LivePanel(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Column(
                  children: [
                    for (final (i, q) in list.take(6).indexed) ...[
                      if (i > 0) Divider(height: 1, color: context.appColors.hairline),
                      InkWell(
                        onTap: () => openCardLink(q.s('url')),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(color: _magColor(q.n('magnitude') ?? 0), borderRadius: BorderRadius.circular(12)),
                                child: Text((q.n('magnitude') ?? 0).toStringAsFixed(1), style: context.textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(q.s('place') ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: context.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
                                    Text(
                                      [
                                        if (q.t('time') case final t?) cardAgo(context, t),
                                        l.cardDepth(u.dist(q.n('depthKm') ?? 0)),
                                        if (q.n('distanceKm') case final d?) l.cardAway(u.dist(d)),
                                      ].join(' · '),
                                      style: context.cardLabel,
                                    ),
                                  ],
                                ),
                              ),
                              if (q.b('tsunami') == true) LivePill(text: l.cardTsunami, color: context.appColors.negative, icon: LucideIcons.waves),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      );
    },
  );
});

Color _alertColor(String? a) => switch (a) {
  'red' => const Color(0xFFD03A2F),
  'orange' => const Color(0xFFE07A1F),
  _ => const Color(0xFF3BB273),
};

final stormComponent = liveCard('Storm', const ['near', 'storms'], (context, p, ctl) {
  final l = context.l10n;
  final list = p.rows('storms');
  final near = p.map('near');
  return Consumer(
    builder: (context, ref, _) {
      final u = cardUnitsOf(context, ref);
      return LiveLayout(
        header: LiveHeader(icon: LucideIcons.tornado, iconColor: const Color(0xFF5B5FC7), title: l.cardStorms, subtitle: list.isEmpty ? l.cardNoStorms : l.cardStormCount(list.length)),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (list.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.tile),
                child: BotMapCard(
                  spec: MapCardSpec(
                    center: null,
                    zoom: 3,
                    markers: [
                      for (final s in list) (point: LatLng(s.n('lat') ?? 0, s.n('lng') ?? 0), label: s.s('name')),
                      if (!near.isEmpty) (point: LatLng(near.n('lat') ?? 0, near.n('lng') ?? 0), label: near.s('name')),
                    ],
                    path: const [],
                    height: 180,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            for (final s in list.take(4))
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _alertColor(s.s('alert')).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppRadius.tile),
                  border: Border(left: BorderSide(color: _alertColor(s.s('alert')), width: 4)),
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.tornado, color: _alertColor(s.s('alert'))),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.s('name') ?? '', style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                          Text(
                            [
                              if (s.n('windKph') case final w?) u.speed(w),
                              if (s.n('distanceKm') case final d?) l.cardAway(u.dist(d)),
                              ?s.s('countries'),
                            ].join(' · '),
                            style: context.cardLabel,
                          ),
                        ],
                      ),
                    ),
                    LivePill(text: l.cardAlertLevel(s.s('alert') ?? 'green'), color: _alertColor(s.s('alert'))),
                  ],
                ),
              ),
            if (list.isEmpty) LivePanel(child: Text(l.cardNoStormsLong, style: context.cardBody)),
          ],
        ),
      );
    },
  );
});

// ---------------------------------------------------------------------------------------------
// Sports
// ---------------------------------------------------------------------------------------------

final scoreComponent = liveCard('Score', const ['league', 'games'], (context, p, ctl) {
  final l = context.l10n;
  final games = p.rows('games');
  final live = games.where((g) => g.s('state') == 'in').length;
  return LiveLayout(
    header: LiveHeader(
      icon: LucideIcons.trophy,
      iconColor: const Color(0xFFD35400),
      title: p.s('league') ?? l.cardScores,
      subtitle: games.isEmpty ? l.cardNoGames : l.cardGameCount(games.length),
      pill: live > 0 ? l.cardLiveCount(live) : null,
      pillColor: context.appColors.negative,
    ),
    body: games.isEmpty
        ? LivePanel(child: Text(l.cardNoGames, style: context.cardBody))
        : Column(children: [for (final g in games.take(8)) _GameTile(g: g)]),
  );
});

class _GameTile extends StatelessWidget {
  const _GameTile({required this.g});
  final P g;
  @override
  Widget build(BuildContext context) {
    final teams = g.rows('teams');
    final state = g.s('state');
    final race = teams.length > 2;
    final start = g.t('start');
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.tile),
        border: Border.all(color: state == 'in' ? context.appColors.negative.withValues(alpha: 0.5) : context.appColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (state == 'in') ...[const _LiveDot(), const SizedBox(width: 6)],
              Expanded(
                child: Text(
                  state == 'pre' && start != null ? DateFormat.MMMEd(context.l10n.localeName).add_jm().format(start) : (g.s('detail') ?? ''),
                  style: context.textTheme.labelMedium?.copyWith(color: state == 'in' ? context.appColors.negative : context.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600),
                ),
              ),
              if (g.s('venue') case final v?) Flexible(child: Text(v, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.cardLabel)),
            ],
          ),
          const SizedBox(height: 6),
          for (final (i, t) in (race ? teams.take(5) : teams).indexed)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  if (race) SizedBox(width: 22, child: Text('${i + 1}', style: context.cardLabel)),
                  Monogram(text: t.s('abbr') ?? t.s('name') ?? '', url: t.s('logoUrl'), size: 26, color: hexColor(t.s('color'))),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: t.s('name') ?? '', style: TextStyle(fontWeight: t.b('winner') == true ? FontWeight.w800 : FontWeight.w500)),
                          if (t.s('record') case final r?) TextSpan(text: '  $r', style: context.cardLabel),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (state != 'pre' && !race)
                    Text(t.s('score') ?? '', style: context.textTheme.titleMedium?.copyWith(fontWeight: t.b('winner') == true || state == 'in' ? FontWeight.w800 : FontWeight.w500, fontFeatures: AppText.tabular)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _LiveDot extends StatefulWidget {
  const _LiveDot();
  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat(reverse: true);
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dot = Container(width: 8, height: 8, decoration: BoxDecoration(color: context.appColors.negative, shape: BoxShape.circle));
    if (MediaQuery.disableAnimationsOf(context)) return dot;
    return FadeTransition(opacity: Tween(begin: 0.35, end: 1.0).animate(_c), child: dot);
  }
}

final standingsComponent = liveCard('Standings', const ['league', 'groups', 'highlight'], (context, p, ctl) {
  final l = context.l10n;
  final groups = p.rows('groups');
  if (groups.isEmpty) return null;
  final hl = p.s('highlight')?.toLowerCase();
  return LiveLayout(
    header: LiveHeader(icon: LucideIcons.listOrdered, iconColor: const Color(0xFFD35400), title: p.s('league') ?? l.cardStandings, subtitle: l.cardStandings),
    body: Column(
      children: [
        for (final g in groups)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: LivePanel(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (groups.length > 1) Padding(padding: const EdgeInsets.only(bottom: 4), child: Text(g.s('name') ?? '', style: context.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700))),
                  _StandRow(cells: ['#', l.cardTeam, l.cardPlayedShort, l.cardWonShort, l.cardLostShort, l.cardPointsShort], header: true),
                  for (final r in g.rows('rows').take(20))
                    _StandRow(
                      highlight: hl != null && (r.s('team') ?? '').toLowerCase().contains(hl),
                      logo: r.s('logoUrl'),
                      cells: ['${r.i('rank') ?? ''}', r.s('team') ?? '', '${r.i('played') ?? ''}', '${r.i('won') ?? ''}', '${r.i('lost') ?? ''}', r.i('points') != null ? '${r.i('points')}' : (r.s('pct') ?? '')],
                    ),
                ],
              ),
            ),
          ),
      ],
    ),
  );
});

class _StandRow extends StatelessWidget {
  const _StandRow({required this.cells, this.header = false, this.highlight = false, this.logo});
  final List<String> cells;
  final bool header;
  final bool highlight;
  final String? logo;
  @override
  Widget build(BuildContext context) {
    final style = header ? context.cardLabel?.copyWith(fontWeight: FontWeight.w700) : context.textTheme.labelLarge?.copyWith(fontFeatures: AppText.tabular, fontWeight: highlight ? FontWeight.w800 : FontWeight.w500);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
      decoration: highlight ? BoxDecoration(color: context.colorScheme.primary.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(8)) : null,
      child: Row(
        children: [
          SizedBox(width: 24, child: Text(cells[0], style: style)),
          if (!header) ...[Monogram(text: cells[1], url: logo, size: 20), const SizedBox(width: 6)] else const SizedBox(width: 26),
          Expanded(child: Text(cells[1], maxLines: 1, overflow: TextOverflow.ellipsis, style: style)),
          for (final c in cells.skip(2)) SizedBox(width: 34, child: Text(c, textAlign: TextAlign.right, style: style)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------------------------
// Travel
// ---------------------------------------------------------------------------------------------

final flightComponent = liveCard('Flight', const ['flight', 'airline', 'status', 'from', 'to', 'aircraft'], (context, p, ctl) {
  final l = context.l10n;
  final from = p.map('from');
  final to = p.map('to');
  final status = p.s('status') ?? 'scheduled';
  final c = switch (status) {
    'active' || 'en-route' => const Color(0xFF2F7BD3),
    'landed' => context.appColors.positive,
    'cancelled' || 'diverted' => context.appColors.negative,
    _ => (from.i('delay') ?? 0) > 15 ? context.appColors.warning : context.appColors.positive,
  };
  Widget end(P e, CrossAxisAlignment a) {
    final t = placeTime(e.s('estimated') ?? e.s('scheduled'));
    final sched = placeTime(e.s('scheduled'));
    final late = t != null && sched != null && t.isAfter(sched.add(const Duration(minutes: 5)));
    return Column(
      crossAxisAlignment: a,
      children: [
        Text(e.s('code') ?? '—', style: context.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 1)),
        Text(e.s('name') ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: context.cardLabel),
        const SizedBox(height: 4),
        if (t != null) Text(clockOf(context, t), style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: late ? context.appColors.warning : null)),
        if (late) Text(clockOf(context, sched), style: context.cardLabel?.copyWith(decoration: TextDecoration.lineThrough)),
      ],
    );
  }

  return LiveLayout(
    header: LiveHeader(icon: LucideIcons.plane, iconColor: const Color(0xFF2F7BD3), title: '${p.s('flight')}', subtitle: p.s('airline'), pill: _flightWord(l, status), pillColor: c),
    body: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: context.colorScheme.surface, borderRadius: BorderRadius.circular(AppRadius.tile), border: Border.all(color: context.appColors.hairline)),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: end(from, CrossAxisAlignment.start)),
              Column(
                children: [
                  Icon(LucideIcons.plane, color: c),
                  SizedBox(width: 70, child: Divider(color: c.withValues(alpha: 0.4), thickness: 2)),
                ],
              ),
              Expanded(child: end(to, CrossAxisAlignment.end)),
            ],
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: _DashedLine()),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _PassFact(label: l.cardTerminal, value: from.s('terminal') ?? '—'),
              _PassFact(label: l.cardGate, value: from.s('gate') ?? '—'),
              _PassFact(label: l.cardDelay, value: from.i('delay') == null ? '—' : l.cardMinutes(from.i('delay')!)),
              _PassFact(label: l.cardBaggage, value: to.s('baggage') ?? '—'),
            ],
          ),
        ],
      ),
    ),
  );
});

String _flightWord(dynamic l, String s) => switch (s) {
  'active' || 'en-route' => l.cardFlightInAir as String,
  'landed' => l.cardFlightLanded as String,
  'cancelled' => l.cardFlightCancelled as String,
  'diverted' => l.cardFlightDiverted as String,
  'incident' => l.cardFlightIncident as String,
  _ => l.cardFlightScheduled as String,
};

class _PassFact extends StatelessWidget {
  const _PassFact({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(label.toUpperCase(), style: context.textTheme.labelSmall?.copyWith(color: context.colorScheme.onSurfaceVariant, letterSpacing: 0.8)),
      Text(value, style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
    ],
  );
}

class _DashedLine extends StatelessWidget {
  const _DashedLine();
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) => Row(
      children: [
        for (var i = 0; i < (box.maxWidth / 8).floor(); i++)
          Container(width: 4, height: 1.5, margin: const EdgeInsets.only(right: 4), color: context.appColors.hairline),
      ],
    ),
  );
}

final parcelComponent = liveCard('Parcel', const ['tracking', 'carrier', 'status', 'eta', 'events'], (context, p, ctl) {
  final l = context.l10n;
  final status = p.s('status') ?? 'in_transit';
  const order = ['info_received', 'in_transit', 'out_for_delivery', 'delivered'];
  final at = order.indexOf(status);
  final labels = [l.cardParcelOrdered, l.cardParcelInTransit, l.cardParcelOut, l.cardParcelDelivered];
  final events = p.rows('events');
  final eta = p.t('eta');
  final bad = status == 'exception' || status == 'not_found';
  return LiveLayout(
    header: LiveHeader(icon: LucideIcons.package, iconColor: const Color(0xFF8E5B2E), title: p.s('carrier') ?? l.cardParcel, subtitle: p.s('tracking'), pill: bad ? l.cardParcelProblem : null, pillColor: context.appColors.negative),
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LivePanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  for (var i = 0; i < 4; i++) ...[
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: i <= at ? context.appColors.positive : context.colorScheme.surfaceContainerHighest),
                      child: i <= at ? const Icon(LucideIcons.check, size: 14, color: Colors.white) : null,
                    ),
                    if (i < 3) Expanded(child: Container(height: 3, color: i < at ? context.appColors.positive : context.colorScheme.surfaceContainerHighest)),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              Row(children: [for (final (i, t) in labels.indexed) Expanded(child: Text(t, textAlign: i == 0 ? TextAlign.left : (i == 3 ? TextAlign.right : TextAlign.center), style: context.textTheme.labelSmall?.copyWith(fontWeight: i == at ? FontWeight.w800 : FontWeight.w500)))]),
              if (eta != null && status != 'delivered') Padding(padding: const EdgeInsets.only(top: 10), child: Text(l.cardExpected(DateFormat.MMMEd(l.localeName).format(eta)), style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700))),
            ],
          ),
        ),
        const SizedBox(height: 8),
        for (final (i, e) in events.take(5).indexed)
          Padding(
            padding: const EdgeInsets.only(left: 6, bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(padding: const EdgeInsets.only(top: 5), child: Icon(LucideIcons.circleDot, size: 10, color: i == 0 ? context.colorScheme.primary : context.colorScheme.outline)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.s('text') ?? '', style: context.textTheme.bodyMedium?.copyWith(fontWeight: i == 0 ? FontWeight.w600 : null)),
                      Text([if (e.t('time') case final t?) DateFormat.MMMd(l.localeName).add_jm().format(t), ?e.s('place')].join(' · '), style: context.cardLabel),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
});
