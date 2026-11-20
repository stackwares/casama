import 'dart:async';
import 'dart:math' as math;

import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:timezone/data/latest_10y.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../../../core/widgets.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_tokens.dart';
import 'live_kit.dart';
import 'live_weather.dart' show dayLabel;

// Time cards (docs/RICH-CARDS-PLAN.md §6.4, §7.7): clocks and countdowns tick on the device, so
// they're always right without the server.

bool _tzReady = false;

/// The wall time now (or at [at]) in an IANA zone; null for a zone the database doesn't know.
DateTime? zoneTime(String zone, [DateTime? at]) {
  if (!_tzReady) {
    tzdata.initializeTimeZones();
    _tzReady = true;
  }
  try {
    final loc = tz.getLocation(zone);
    final t = tz.TZDateTime.from((at ?? DateTime.now()).toUtc(), loc);
    return DateTime(t.year, t.month, t.day, t.hour, t.minute, t.second);
  } catch (_) {
    return null;
  }
}

/// Rebuilds every [period] while on screen.
class Ticker extends StatefulWidget {
  const Ticker({super.key, required this.period, required this.builder});
  final Duration period;
  final WidgetBuilder builder;
  @override
  State<Ticker> createState() => _TickerState();
}

class _TickerState extends State<Ticker> {
  Timer? _t;
  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(widget.period, (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context);
}

// ---------------------------------------------------------------------------------------------
// World clock
// ---------------------------------------------------------------------------------------------

final worldClockComponent = liveCard('WorldClock', const ['title', 'places', 'at'], (context, p, ctl) {
  final l = context.l10n;
  final places = p.rows('places').where((x) => x.s('tz') != null).toList();
  if (places.isEmpty) return null;
  final at = p.t('at');
  return LiveLayout(
    header: LiveHeader(icon: LucideIcons.earth, iconColor: const Color(0xFF6C5CE7), title: p.s('title') ?? (at == null ? l.cardWorldClock : l.cardTimeIn), subtitle: at == null ? l.cardLiveNow : l.cardAtTime(DateFormat.MMMEd(l.localeName).add_jm().format(at))),
    body: Ticker(
      period: Duration(seconds: at == null ? 15 : 3600),
      builder: (context) {
        final here = DateTime.now();
        return LivePanel(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Column(
            children: [
              for (final (i, x) in places.indexed) ...[
                if (i > 0) Divider(height: 1, color: context.appColors.hairline),
                _ClockRow(name: x.s('name') ?? x.s('tz')!, zone: x.s('tz')!, at: at, here: here, country: x.s('country')),
              ],
            ],
          ),
        );
      },
    ),
    footer: null,
  );
});

class _ClockRow extends StatelessWidget {
  const _ClockRow({required this.name, required this.zone, required this.here, this.at, this.country});
  final String name;
  final String zone;
  final DateTime? at;
  final DateTime here;
  final String? country;
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = zoneTime(zone, at ?? here);
    if (t == null) return const SizedBox.shrink();
    final mine = at ?? here;
    final diffH = (t.difference(DateTime(mine.year, mine.month, mine.day, mine.hour, mine.minute, mine.second)).inMinutes / 60);
    final dayDiff = DateTime(t.year, t.month, t.day).difference(DateTime(mine.year, mine.month, mine.day)).inDays;
    final hour = t.hour + t.minute / 60;
    final night = hour < 6 || hour >= 19;
    final offset = diffH == 0 ? l.cardSameTime : '${diffH > 0 ? '+' : '−'}${_hours(diffH.abs())}';
    final dayWord = dayDiff == 0 ? l.cardToday : (dayDiff > 0 ? l.cardTomorrow : l.cardYesterday);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          SizedBox(width: 40, height: 40, child: CustomPaint(painter: _DialPainter(t, night))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                Text('$dayWord · $offset', style: context.cardLabel),
              ],
            ),
          ),
          Text(clockOf(context, t), style: context.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600, fontFeatures: AppText.tabular, color: night ? const Color(0xFF5B5FC7) : null)),
        ],
      ),
    );
  }
}

String _hours(double h) => h == h.roundToDouble() ? '${h.toInt()}h' : '${h.floor()}h ${((h - h.floor()) * 60).round()}m';

/// A small clock face, dark at night.
class _DialPainter extends CustomPainter {
  _DialPainter(this.t, this.night);
  final DateTime t;
  final bool night;
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    canvas.drawCircle(c, r, Paint()..color = night ? const Color(0xFF232A4D) : const Color(0xFFEAF3FF));
    final ink = night ? Colors.white : const Color(0xFF1F3B63);
    for (var i = 0; i < 12; i++) {
      final a = i / 12 * 2 * math.pi;
      canvas.drawCircle(c + Offset(math.sin(a), -math.cos(a)) * (r - 4), i % 3 == 0 ? 1.4 : 0.8, Paint()..color = ink.withValues(alpha: 0.6));
    }
    final h = (t.hour % 12 + t.minute / 60) / 12 * 2 * math.pi;
    final m = t.minute / 60 * 2 * math.pi;
    final hand = Paint()
      ..color = ink
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(c, c + Offset(math.sin(h), -math.cos(h)) * r * 0.5, hand..strokeWidth = 2.4);
    canvas.drawLine(c, c + Offset(math.sin(m), -math.cos(m)) * r * 0.72, hand..strokeWidth = 1.6);
    canvas.drawCircle(c, 2, Paint()..color = const Color(0xFFF5A623));
  }

  @override
  bool shouldRepaint(_DialPainter o) => o.t != t;
}

// ---------------------------------------------------------------------------------------------
// Countdown
// ---------------------------------------------------------------------------------------------

(IconData, List<Color>) _countdownArt(String? art) => switch (art) {
  'new_year' => (LucideIcons.partyPopper, const [Color(0xFF3A1C71), Color(0xFFD76D77)]),
  'birthday' => (LucideIcons.cake, const [Color(0xFFFF6FA5), Color(0xFFFFB36B)]),
  'launch' => (LucideIcons.rocket, const [Color(0xFF0F2027), Color(0xFF2C5364)]),
  'holiday' => (LucideIcons.palmtree, const [Color(0xFF11998E), Color(0xFF38EF7D)]),
  'trip' => (LucideIcons.plane, const [Color(0xFF2193B0), Color(0xFF6DD5ED)]),
  'wedding' => (LucideIcons.heart, const [Color(0xFFB24592), Color(0xFFF15F79)]),
  'exam' => (LucideIcons.graduationCap, const [Color(0xFF4B6CB7), Color(0xFF182848)]),
  'game' => (LucideIcons.trophy, const [Color(0xFFF7971E), Color(0xFFD35400)]),
  _ => (LucideIcons.hourglass, const [Color(0xFF5B5FC7), Color(0xFF8E7CF0)]),
};

final countdownComponent = liveCard('Countdown', const ['title', 'target', 'start', 'art', 'tz'], (context, p, ctl) {
  final target = p.t('target');
  if (target == null) return null;
  final (icon, colors) = _countdownArt(p.s('art'));
  final start = p.t('start');
  return Container(
    decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors), borderRadius: BorderRadius.circular(AppRadius.tile + 4)),
    padding: const EdgeInsets.fromLTRB(16, 12, 10, 16),
    child: Ticker(
      period: const Duration(seconds: 1),
      builder: (context) {
        final l = context.l10n;
        final now = DateTime.now();
        var left = target.difference(now);
        final past = left.isNegative;
        if (past) left = -left;
        final d = left.inDays, h = left.inHours % 24, m = left.inMinutes % 60, s = left.inSeconds % 60;
        final progress = start == null ? null : (now.difference(start).inSeconds / target.difference(start).inSeconds).clamp(0.0, 1.0);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            LiveHeader(onDark: true, icon: icon, title: p.s('title')!, subtitle: DateFormat.yMMMMEEEEd(l.localeName).add_jm().format(target)),
            const SizedBox(height: 16),
            if (past && left.inMinutes < 1)
              Text(l.cardItsTime, style: context.textTheme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w800))
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _Unit(value: d, label: l.cardDays),
                  _Unit(value: h, label: l.cardHoursShort),
                  _Unit(value: m, label: l.cardMinutesShort),
                  _Unit(value: s, label: l.cardSecondsShort),
                ],
              ),
            if (past && left.inMinutes >= 1) Padding(padding: const EdgeInsets.only(top: 6), child: Text(l.cardAgoSuffix, textAlign: TextAlign.center, style: context.textTheme.labelMedium?.copyWith(color: Colors.white70))),
            if (progress != null) ...[
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(value: progress, minHeight: 8, color: Colors.white, backgroundColor: Colors.white24),
              ),
              const SizedBox(height: 4),
              Text(l.cardPercentThere((progress * 100).round()), style: context.textTheme.labelSmall?.copyWith(color: Colors.white70)),
            ],
          ],
        );
      },
    ),
  );
});

class _Unit extends StatelessWidget {
  const _Unit({required this.value, required this.label});
  final int value;
  final String label;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Container(
        constraints: const BoxConstraints(minWidth: 62),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(14)),
        child: Text('$value'.padLeft(2, '0'), textAlign: TextAlign.center, style: context.textTheme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w800, fontFeatures: AppText.tabular)),
      ),
      const SizedBox(height: 4),
      Text(label, style: context.textTheme.labelSmall?.copyWith(color: Colors.white70, fontWeight: FontWeight.w600)),
    ],
  );
}

// ---------------------------------------------------------------------------------------------
// Holidays
// ---------------------------------------------------------------------------------------------

final holidaysComponent = liveCard('Holidays', const ['country', 'holidays', 'today'], (context, p, ctl) {
  final l = context.l10n;
  final list = p.rows('holidays');
  final today = DateTime.tryParse(p.s('today') ?? '') ?? DateTime.now();
  return LiveLayout(
    header: LiveHeader(icon: LucideIcons.calendarHeart, iconColor: const Color(0xFFE0565B), title: l.cardHolidays, subtitle: p.s('country')),
    body: list.isEmpty
        ? LivePanel(child: Text(l.cardNoHolidays, style: context.cardBody))
        : LivePanel(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Column(
              children: [
                for (final (i, h) in list.indexed) ...[
                  if (i > 0) Divider(height: 1, color: context.appColors.hairline),
                  _HolidayRow(h: h, today: today),
                ],
              ],
            ),
          ),
  );
});

class _HolidayRow extends StatelessWidget {
  const _HolidayRow({required this.h, required this.today});
  final P h;
  final DateTime today;
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final d = DateTime.tryParse(h.s('date') ?? '');
    if (d == null) return const SizedBox.shrink();
    final days = DateTime(d.year, d.month, d.day).difference(DateTime(today.year, today.month, today.day)).inDays;
    final long = d.weekday == DateTime.friday || d.weekday == DateTime.monday;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Container(
            width: 46,
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFFE0565B).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Column(
              children: [
                Text(DateFormat.MMM(l.localeName).format(d).toUpperCase(), style: context.textTheme.labelSmall?.copyWith(color: const Color(0xFFE0565B), fontWeight: FontWeight.w800)),
                Text('${d.day}', style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, height: 1.1)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(h.s('name') ?? '', style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                Text([DateFormat.EEEE(l.localeName).format(d), ?h.s('localName')].join(' · '), style: context.cardLabel),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (days >= 0) Text(days == 0 ? l.cardToday : (days == 1 ? l.cardTomorrow : l.cardInDays(days)), style: context.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
              if (long) LivePill(text: l.cardLongWeekend, color: context.appColors.positive),
            ],
          ),
        ],
      ),
    );
  }
}

/// Re-export for other cards.
String placeDay(BuildContext context, String date) => dayLabel(context, date);
