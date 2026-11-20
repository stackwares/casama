import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/widgets.dart';
import '../../../../theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../theme/app_tokens.dart';
import 'live_kit.dart';

// Weather and sky cards (docs/RICH-CARDS-PLAN.md §6.1, §7.1–7.5).

/// The words for a condition code from the server.
String condWord(AppLocalizations l, String? code) => switch (code) {
  'clear' => l.cardCondClear,
  'mostly_clear' => l.cardCondMostlyClear,
  'partly_cloudy' => l.cardCondPartlyCloudy,
  'cloudy' => l.cardCondCloudy,
  'fog' => l.cardCondFog,
  'drizzle' => l.cardCondDrizzle,
  'light_rain' => l.cardCondLightRain,
  'rain' => l.cardCondRain,
  'heavy_rain' => l.cardCondHeavyRain,
  'showers' => l.cardCondShowers,
  'thunder' => l.cardCondThunder,
  'light_snow' => l.cardCondLightSnow,
  'snow' => l.cardCondSnow,
  'heavy_snow' => l.cardCondHeavySnow,
  'sleet' => l.cardCondSleet,
  'hail' => l.cardCondHail,
  _ => l.cardCondCloudy,
};

/// A condition's icon, and its color on a light card.
(IconData, Color) condIcon(String? code, {bool day = true}) => switch (code) {
  'clear' => day ? (LucideIcons.sun, const Color(0xFFF5A623)) : (LucideIcons.moon, const Color(0xFF8E9AC7)),
  'mostly_clear' => day ? (LucideIcons.cloudSun, const Color(0xFFF2B33D)) : (LucideIcons.cloudMoon, const Color(0xFF8E9AC7)),
  'partly_cloudy' => day ? (LucideIcons.cloudSun, const Color(0xFF8AA4C2)) : (LucideIcons.cloudMoon, const Color(0xFF8E9AC7)),
  'cloudy' => (LucideIcons.cloudy, const Color(0xFF8D99A6)),
  'fog' => (LucideIcons.cloudFog, const Color(0xFF9AA3AD)),
  'drizzle' => (LucideIcons.cloudDrizzle, const Color(0xFF4A90D9)),
  'light_rain' => (LucideIcons.cloudRain, const Color(0xFF4A90D9)),
  'rain' => (LucideIcons.cloudRain, const Color(0xFF2F7BD3)),
  'heavy_rain' => (LucideIcons.cloudRainWind, const Color(0xFF2563C4)),
  'showers' => day ? (LucideIcons.cloudSunRain, const Color(0xFF3D86D6)) : (LucideIcons.cloudMoonRain, const Color(0xFF3D86D6)),
  'thunder' => (LucideIcons.cloudLightning, const Color(0xFF7B5CD6)),
  'light_snow' || 'snow' || 'heavy_snow' => (LucideIcons.cloudSnow, const Color(0xFF6FA8DC)),
  'sleet' || 'hail' => (LucideIcons.cloudHail, const Color(0xFF6F8FB8)),
  _ => (LucideIcons.cloud, const Color(0xFF8D99A6)),
};

/// The sky behind a weather card: by condition and time of day.
LinearGradient skyFor(String? code, bool day) {
  List<Color> c;
  if (!day) {
    c = switch (code) {
      'clear' || 'mostly_clear' => [const Color(0xFF1E2A5A), const Color(0xFF0B1130)],
      'thunder' => [const Color(0xFF2B2346), const Color(0xFF0F0B1E)],
      _ => [const Color(0xFF283148), const Color(0xFF111726)],
    };
  } else {
    c = switch (code) {
      'clear' => [const Color(0xFF55B1FF), const Color(0xFF1F6FD8)],
      'mostly_clear' => [const Color(0xFF64B4F8), const Color(0xFF2C73CF)],
      'partly_cloudy' => [const Color(0xFF7CA9D8), const Color(0xFF3F6C9F)],
      'cloudy' || 'fog' => [const Color(0xFF8E9BAA), const Color(0xFF5A6574)],
      'thunder' || 'hail' => [const Color(0xFF555A78), const Color(0xFF262A40)],
      'light_snow' || 'snow' || 'heavy_snow' || 'sleet' => [const Color(0xFFB6C9DE), const Color(0xFF7A90AA)],
      _ => [const Color(0xFF5F7187), const Color(0xFF2E3C4E)],
    };
  }
  return LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: c);
}

String _placeLine(P place) => [place.s('region'), place.s('country')].whereType<String>().join(', ');

/// "Today", "Tomorrow" or "Sat, Nov 22" for a place's date.
String dayLabel(BuildContext context, String date, {String? today}) {
  final l = context.l10n;
  final d = DateTime.tryParse(date);
  if (d == null) return date;
  final t = today == null ? DateTime.now() : (DateTime.tryParse(today) ?? DateTime.now());
  final diff = DateTime(d.year, d.month, d.day).difference(DateTime(t.year, t.month, t.day)).inDays;
  if (diff == 0) return l.cardToday;
  if (diff == 1) return l.cardTomorrow;
  return DateFormat.MMMEd(l.localeName).format(d);
}

String _weekday(BuildContext context, String date, String? today) {
  final d = DateTime.tryParse(date);
  if (d == null) return date;
  if (today != null && date == today) return context.l10n.cardToday;
  return DateFormat.E(context.l10n.localeName).format(d);
}

// ---------------------------------------------------------------------------------------------
// Weather
// ---------------------------------------------------------------------------------------------

final weatherComponent = liveCard('Weather', const ['place', 'when', 'now', 'day', 'hours', 'days', 'sunrise', 'sunset', 'alerts'], (context, p, ctl) {
  return Consumer(builder: (context, ref, _) => _Weather(p: p, ctl: ctl, units: cardUnitsOf(context, ref)));
});

class _Weather extends StatefulWidget {
  const _Weather({required this.p, required this.ctl, required this.units});
  final P p;
  final LiveCardController ctl;
  final CardUnits units;
  @override
  State<_Weather> createState() => _WeatherState();
}

class _WeatherState extends State<_Weather> {
  bool _week = false;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = widget.p;
    final u = widget.units;
    final place = p.map('place');
    final now = p.map('now');
    final day = p.map('day');
    final when = p.s('when') ?? 'now';
    final isNow = when == 'now' && !now.isEmpty;
    final code = isNow ? now.s('code') : day.s('code');
    final isDay = isNow ? (now.b('isDay') ?? true) : true;
    final (icon, _) = condIcon(code, day: isDay);
    final hours = p.rows('hours');
    final days = p.rows('days');
    final alerts = p.rows('alerts');
    final today = days.isEmpty ? null : days.first.s('date');
    final temp = isNow ? now.n('temp') : day.n('high');
    final dateLabel = isNow ? l.cardNow : dayLabel(context, when, today: today);
    final selected = _week ? 'week' : (widget.ctl.view ?? (isNow ? 'now' : (when == today ? 'today' : 'tomorrow')));
    const ink = Colors.white;
    final sub = Colors.white.withValues(alpha: 0.82);

    final hero = Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (temp != null)
                HeroNumber(
                  value: u.deg(temp).toDouble(),
                  format: (v) => '${v.round()}°',
                  color: ink,
                  style: context.textTheme.displayLarge?.copyWith(fontSize: 64, letterSpacing: -2),
                ),
              Text(condWord(l, code), style: context.textTheme.titleMedium?.copyWith(color: ink, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(
                [
                  if (day.n('high') != null) l.cardHighLow(u.degText(day.n('high')!), u.degText(day.n('low') ?? 0)),
                  if (isNow && now.n('feels') != null) l.cardFeelsLike(u.degText(now.n('feels')!)),
                ].join('  ·  '),
                style: context.textTheme.bodySmall?.copyWith(color: sub, fontFeatures: AppText.tabular),
              ),
            ],
          ),
        ),
        _ConditionArt(icon: icon, code: code),
      ],
    );

    final chips = <Widget>[
      if ((isNow ? hours.firstOrNull?.n('chance') : day.n('chance')) != null)
        FactChip(onDark: true, icon: LucideIcons.umbrella, label: l.cardRainChance, value: '${(isNow ? hours.first.n('chance') : day.n('chance'))!.round()}%')
      else if (day.n('precipMm') != null)
        FactChip(onDark: true, icon: LucideIcons.droplets, label: l.cardRain, value: u.rain(day.n('precipMm')!)),
      if ((isNow ? now.n('windKph') : day.n('windKph')) != null)
        FactChip(onDark: true, icon: LucideIcons.wind, label: l.cardWind, value: u.speed((isNow ? now.n('windKph') : day.n('windKph'))!)),
      if ((isNow ? now.n('uv') : day.n('uv')) != null) FactChip(onDark: true, icon: LucideIcons.sun, label: l.cardUv, value: _uvWords(l, (isNow ? now.n('uv') : day.n('uv'))!)),
      if (isNow && now.n('humidity') != null) FactChip(onDark: true, icon: LucideIcons.droplet, label: l.cardHumidity, value: '${now.n('humidity')!.round()}%'),
      if (placeTime(p.s('sunset')) case final ss?) FactChip(onDark: true, icon: LucideIcons.sunset, label: l.cardSunset, value: clockOf(context, ss)),
    ];

    return Container(
      decoration: BoxDecoration(gradient: skyFor(code, isDay), borderRadius: BorderRadius.circular(AppRadius.tile + 4)),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(child: _SkyLayer(code: code, day: isDay)),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                LiveHeader(
                  onDark: true,
                  icon: LucideIcons.mapPin,
                  title: place.s('name') ?? l.cardWeather,
                  subtitle: [_placeLine(place), dateLabel].where((s) => s.isNotEmpty).join(' · '),
                ),
                const SizedBox(height: 10),
                Padding(padding: const EdgeInsets.only(right: 4), child: hero),
                if (alerts.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  for (final a in alerts.take(2)) _AlertStrip(event: a.s('event') ?? '', severity: a.s('severity')),
                ],
                const SizedBox(height: 12),
                if (_week)
                  _ForecastRows(days: days, units: u, onDark: true, today: today)
                else if (hours.isNotEmpty)
                  _HourStrip(hours: hours, units: u),
                const SizedBox(height: 10),
                if (!_week && chips.isNotEmpty) Wrap(spacing: 6, runSpacing: 6, children: chips),
                const SizedBox(height: 10),
                ViewChips(
                  onDark: true,
                  options: [('now', l.cardNow), ('today', l.cardToday), ('tomorrow', l.cardTomorrow), if (days.length > 2) ('week', l.cardNextDays(days.length))],
                  selected: selected,
                  onSelect: (v) {
                    if (v == 'week') return setState(() => _week = true);
                    setState(() => _week = false);
                    widget.ctl.setView(v);
                  },
                ),
                const LiveFooter(onDark: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _uvWords(AppLocalizations l, double uv) {
  final v = uv.round();
  final w = v <= 2 ? l.cardUvLow : v <= 5 ? l.cardUvModerate : v <= 7 ? l.cardUvHigh : v <= 10 ? l.cardUvVeryHigh : l.cardUvExtreme;
  return '$v $w';
}

/// The condition's icon, large, with a soft glow; it bobs gently unless motion is reduced.
class _ConditionArt extends StatelessWidget {
  const _ConditionArt({required this.icon, required this.code});
  final IconData icon;
  final String? code;
  @override
  Widget build(BuildContext context) {
    final art = Container(
      width: 92,
      height: 92,
      alignment: Alignment.center,
      decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [Colors.white.withValues(alpha: 0.30), Colors.white.withValues(alpha: 0.0)])),
      child: Icon(icon, size: 62, color: Colors.white, shadows: const [Shadow(color: Color(0x40000000), blurRadius: 12, offset: Offset(0, 4))]),
    );
    if (MediaQuery.disableAnimationsOf(context)) return art;
    return _Bob(child: art);
  }
}

class _Bob extends StatefulWidget {
  const _Bob({required this.child});
  final Widget child;
  @override
  State<_Bob> createState() => _BobState();
}

class _BobState extends State<_Bob> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (context, child) => Transform.translate(offset: Offset(0, -3 + 6 * Curves.easeInOut.transform(_c.value)), child: child),
    child: widget.child,
  );
}

/// Faint rain streaks, snow dots or stars over the sky, drawn once (no animation cost).
class _SkyLayer extends StatelessWidget {
  const _SkyLayer({required this.code, required this.day});
  final String? code;
  final bool day;
  @override
  Widget build(BuildContext context) => IgnorePointer(child: CustomPaint(painter: _SkyPainter(code, day)));
}

class _SkyPainter extends CustomPainter {
  _SkyPainter(this.code, this.day);
  final String? code;
  final bool day;
  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(7);
    final c = code ?? '';
    if (!day && (c == 'clear' || c == 'mostly_clear' || c == 'partly_cloudy')) {
      final paint = Paint()..color = Colors.white.withValues(alpha: 0.55);
      for (var i = 0; i < 40; i++) {
        canvas.drawCircle(Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height * 0.6), rnd.nextDouble() * 1.1 + 0.3, paint);
      }
    } else if (c.contains('rain') || c == 'showers' || c == 'drizzle' || c == 'thunder') {
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: 0.10)
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < 46; i++) {
        final x = rnd.nextDouble() * size.width;
        final y = rnd.nextDouble() * size.height;
        canvas.drawLine(Offset(x, y), Offset(x - 5, y + 14), paint);
      }
    } else if (c.contains('snow') || c == 'sleet') {
      final paint = Paint()..color = Colors.white.withValues(alpha: 0.28);
      for (var i = 0; i < 36; i++) {
        canvas.drawCircle(Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height), rnd.nextDouble() * 1.8 + 0.8, paint);
      }
    } else if (day && c == 'clear') {
      final center = Offset(size.width * 0.92, -size.height * 0.1);
      canvas.drawCircle(center, size.width * 0.45, Paint()..shader = RadialGradient(colors: [Colors.white.withValues(alpha: 0.22), Colors.white.withValues(alpha: 0)]).createShader(Rect.fromCircle(center: center, radius: size.width * 0.45)));
    }
  }

  @override
  bool shouldRepaint(_SkyPainter o) => o.code != code || o.day != day;
}

class _AlertStrip extends StatelessWidget {
  const _AlertStrip({required this.event, this.severity});
  final String event;
  final String? severity;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 4),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(color: severityColor(severity).withValues(alpha: 0.9), borderRadius: BorderRadius.circular(10)),
    child: Row(
      children: [
        const Icon(LucideIcons.triangleAlert, size: 15, color: Colors.white),
        const SizedBox(width: 8),
        Expanded(child: Text(event, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textTheme.labelLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w600))),
      ],
    ),
  );
}

Color severityColor(String? s) => switch (s) {
  'extreme' => const Color(0xFF8E1B2C),
  'severe' => const Color(0xFFD03A2F),
  'moderate' => const Color(0xFFE07A1F),
  'minor' => const Color(0xFFC9A227),
  _ => const Color(0xFF6B7280),
};

class _HourStrip extends StatelessWidget {
  const _HourStrip({required this.hours, required this.units});
  final List<P> hours;
  final CardUnits units;
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: hours.length,
        separatorBuilder: (_, _) => const SizedBox(width: 4),
        itemBuilder: (context, i) {
          final h = hours[i];
          final t = placeTime(h.s('t'));
          final (icon, _) = condIcon(h.s('code'), day: h.b('isDay') ?? true);
          final chance = h.n('chance');
          final mm = h.n('mm') ?? 0;
          final wet = (chance ?? 0) >= 30 || mm >= 0.3;
          return Container(
            width: 52,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: i == 0 ? 0.24 : 0.10), borderRadius: BorderRadius.circular(14)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(i == 0 ? l.cardNow : (t == null ? '' : hourOf(context, t)), style: context.textTheme.labelSmall?.copyWith(color: Colors.white.withValues(alpha: 0.85), fontWeight: FontWeight.w600)),
                Icon(icon, size: 20, color: Colors.white),
                Text(units.degText(h.n('temp') ?? 0), style: context.textTheme.labelLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w700, fontFeatures: AppText.tabular)),
                Text(
                  wet ? (chance != null ? '${chance.round()}%' : units.rain(mm)) : ' ',
                  style: context.textTheme.labelSmall?.copyWith(color: const Color(0xFFBFE0FF), fontWeight: FontWeight.w600, fontSize: 10),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ForecastRows extends StatelessWidget {
  const _ForecastRows({required this.days, required this.units, this.onDark = false, this.today});
  final List<P> days;
  final CardUnits units;
  final bool onDark;
  final String? today;
  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) return const SizedBox.shrink();
    final lo = days.map((d) => d.n('low') ?? 0).reduce(math.min);
    final hi = days.map((d) => d.n('high') ?? 0).reduce(math.max);
    final fg = onDark ? Colors.white : context.colorScheme.onSurface;
    final sub = onDark ? Colors.white.withValues(alpha: 0.75) : context.colorScheme.onSurfaceVariant;
    return Column(
      children: [
        for (final d in days)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                SizedBox(width: 74, child: Text(_weekday(context, d.s('date') ?? '', today), style: context.textTheme.labelLarge?.copyWith(color: fg, fontWeight: FontWeight.w600))),
                Builder(
                  builder: (context) {
                    final (icon, color) = condIcon(d.s('code'));
                    return Icon(icon, size: 20, color: onDark ? Colors.white : color);
                  },
                ),
                SizedBox(
                  width: 42,
                  child: Text(
                    (d.n('chance') ?? 0) >= 20 ? '${d.n('chance')!.round()}%' : '',
                    textAlign: TextAlign.center,
                    style: context.textTheme.labelSmall?.copyWith(color: onDark ? const Color(0xFFBFE0FF) : const Color(0xFF2F7BD3), fontWeight: FontWeight.w700),
                  ),
                ),
                SizedBox(width: 34, child: Text(units.degText(d.n('low') ?? 0), textAlign: TextAlign.right, style: context.textTheme.labelLarge?.copyWith(color: sub, fontFeatures: AppText.tabular))),
                const SizedBox(width: 8),
                Expanded(
                  child: RangeBar(
                    min: lo,
                    max: hi,
                    lo: d.n('low') ?? 0,
                    hi: d.n('high') ?? 0,
                    colors: [_tempColor(d.n('low') ?? 0), _tempColor(d.n('high') ?? 0)],
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(width: 34, child: Text(units.degText(d.n('high') ?? 0), style: context.textTheme.labelLarge?.copyWith(color: fg, fontWeight: FontWeight.w700, fontFeatures: AppText.tabular))),
              ],
            ),
          ),
      ],
    );
  }
}

/// Cold blue to hot red, by °C.
Color _tempColor(double c) {
  const stops = [(-10.0, Color(0xFF6C8CFF)), (5.0, Color(0xFF4FC3F7)), (15.0, Color(0xFF7ED957)), (24.0, Color(0xFFFFC94D)), (32.0, Color(0xFFFF8A3D)), (40.0, Color(0xFFE5484D))];
  if (c <= stops.first.$1) return stops.first.$2;
  for (var i = 1; i < stops.length; i++) {
    if (c <= stops[i].$1) {
      final (a, ca) = stops[i - 1];
      final (b, cb) = stops[i];
      return Color.lerp(ca, cb, (c - a) / (b - a))!;
    }
  }
  return stops.last.$2;
}

// ---------------------------------------------------------------------------------------------
// Forecast
// ---------------------------------------------------------------------------------------------

final forecastComponent = liveCard('Forecast', const ['place', 'days', 'today'], (context, p, ctl) {
  final l = context.l10n;
  final place = p.map('place');
  final days = p.rows('days');
  if (days.isEmpty) return null;
  return Consumer(
    builder: (context, ref, _) => LiveLayout(
      header: LiveHeader(icon: LucideIcons.calendarDays, iconColor: const Color(0xFF2F7BD3), title: place.s('name') ?? l.cardWeather, subtitle: l.cardNextDays(days.length)),
      body: LivePanel(padding: const EdgeInsets.fromLTRB(12, 8, 12, 8), child: _ForecastRows(days: days, units: cardUnitsOf(context, ref), today: p.s('today'))),
    ),
  );
});

// ---------------------------------------------------------------------------------------------
// Weather alerts
// ---------------------------------------------------------------------------------------------

final weatherAlertComponent = liveCard('WeatherAlert', const ['place', 'alerts'], (context, p, ctl) {
  final l = context.l10n;
  final alerts = p.rows('alerts');
  final worst = alerts.isEmpty ? null : alerts.first.s('severity');
  return LiveLayout(
    header: LiveHeader(
      icon: alerts.isEmpty ? LucideIcons.circleCheck : LucideIcons.triangleAlert,
      iconColor: alerts.isEmpty ? context.appColors.positive : severityColor(worst),
      title: p.map('place').s('name') ?? l.cardWeatherAlerts,
      subtitle: alerts.isEmpty ? l.cardNoAlerts : l.cardAlertCount(alerts.length),
    ),
    body: alerts.isEmpty
        ? LivePanel(child: Text(l.cardNoAlertsLong, style: context.cardBody))
        : Column(children: [for (final a in alerts) _AlertTile(a: a)]),
  );
});

class _AlertTile extends StatelessWidget {
  const _AlertTile({required this.a});
  final P a;
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = severityColor(a.s('severity'));
    final until = a.t('end');
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadius.tile), border: Border(left: BorderSide(color: c, width: 4))),
      child: Material(
        color: c.withValues(alpha: 0.08),
        child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          title: Text(a.s('event') ?? '', style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: c)),
          subtitle: Text(
            [if (until != null) l.cardUntil(DateFormat.MMMEd(l.localeName).add_jm().format(until)), ?a.s('issuer')].join(' · '),
            style: context.cardLabel,
          ),
          children: [
            if (a.s('headline') case final h?) Text(h, style: context.cardBody?.copyWith(fontWeight: FontWeight.w600)),
            if (a.s('area') case final ar?) Padding(padding: const EdgeInsets.only(top: 6), child: Text(ar, style: context.cardLabel)),
            if (a.s('instruction') case final ins?) Padding(padding: const EdgeInsets.only(top: 8), child: Text(ins, style: context.cardBody)),
          ],
        ),
      ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------------------------
// Air quality
// ---------------------------------------------------------------------------------------------

const _aqiBands = [(50.0, Color(0xFF3BB273)), (100.0, Color(0xFFF2C94C)), (150.0, Color(0xFFF2994A)), (200.0, Color(0xFFEB5757)), (300.0, Color(0xFF9B51E0))];

Color aqiColor(num v) {
  for (final (to, c) in _aqiBands) {
    if (v <= to) return c;
  }
  return const Color(0xFF7E0023);
}

final airQualityComponent = liveCard('AirQuality', const ['place', 'aqi', 'scale', 'dominant', 'pollutants', 'hours', 'pollen', 'uv'], (context, p, ctl) {
  final l = context.l10n;
  final aqi = p.n('aqi');
  if (aqi == null) return null;
  final band = aqi <= 50
      ? l.cardAqiGood
      : aqi <= 100
      ? l.cardAqiModerate
      : aqi <= 150
      ? l.cardAqiSensitive
      : aqi <= 200
      ? l.cardAqiUnhealthy
      : aqi <= 300
      ? l.cardAqiVeryUnhealthy
      : l.cardAqiHazardous;
  final advice = aqi <= 50
      ? l.cardAqiAdviceGood
      : aqi <= 100
      ? l.cardAqiAdviceModerate
      : aqi <= 150
      ? l.cardAqiAdviceSensitive
      : l.cardAqiAdviceBad;
  final color = aqiColor(aqi);
  final hours = p.rows('hours');
  final pollen = p.rows('pollen').where((x) => (x.n('value') ?? 0) > 0).toList();
  String pol(String id) => switch (id) {
    'pm2_5' => 'PM2.5',
    'pm10' => 'PM10',
    'o3' => 'O₃',
    'no2' => 'NO₂',
    'so2' => 'SO₂',
    'co' => 'CO',
    _ => id,
  };
  return LiveLayout(
    header: LiveHeader(icon: LucideIcons.wind, iconColor: color, title: p.map('place').s('name') ?? l.cardAirQuality, subtitle: l.cardAirQuality),
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LivePanel(
          child: Row(
            children: [
              Gauge(
                value: math.min(aqi, 300),
                max: 300,
                bands: _aqiBands,
                size: 136,
                center: Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text('${aqi.round()}', style: context.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700, fontFeatures: AppText.tabular)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LivePill(text: band, color: color),
                    const SizedBox(height: 8),
                    Text(advice, style: context.cardBody),
                    if (p.s('dominant') case final d?) Padding(padding: const EdgeInsets.only(top: 6), child: Text(l.cardAqiMainPollutant(pol(d)), style: context.cardLabel)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final x in p.rows('pollutants')) FactChip(icon: LucideIcons.circleDot, label: pol(x.s('id') ?? ''), value: '${(x.n('value') ?? 0).round()} ${x.s('unit') ?? ''}'),
            if (p.n('uv') != null) FactChip(icon: LucideIcons.sun, label: l.cardUv, value: _uvWords(l, p.n('uv')!)),
            for (final x in pollen.take(3)) FactChip(icon: LucideIcons.flower2, label: l.cardPollen(x.s('kind') ?? ''), value: '${(x.n('value') ?? 0).round()}'),
          ],
        ),
        if (hours.length > 3) ...[
          const SizedBox(height: 12),
          Text(l.cardNext24h, style: context.cardLabel),
          const SizedBox(height: 4),
          Sparkline(points: [for (final h in hours) h.n('aqi') ?? 0], color: color, height: 44),
        ],
      ],
    ),
  );
});

// ---------------------------------------------------------------------------------------------
// Sun and moon
// ---------------------------------------------------------------------------------------------

final sunMoonComponent = liveCard('SunMoon', const ['place', 'date', 'sun', 'moon'], (context, p, ctl) {
  final l = context.l10n;
  final sun = p.map('sun');
  final moon = p.map('moon');
  final rise = placeTime(sun.s('sunrise'));
  final set = placeTime(sun.s('sunset'));
  final mins = sun.i('dayMinutes');
  final change = sun.n('changeMinutes');
  String dur(int m) => l.cardDuration(m ~/ 60, m % 60);
  final today = p.s('date') == DateFormat('yyyy-MM-dd').format(DateTime.now());
  return LiveLayout(
    header: LiveHeader(icon: LucideIcons.sunrise, iconColor: const Color(0xFFF5A623), title: p.map('place').s('name') ?? l.cardSunMoon, subtitle: p.s('date') == null ? null : dayLabel(context, p.s('date')!)),
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LivePanel(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
          gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFFE7C2), Color(0xFFFFF6EA)]),
          child: Column(
            children: [
              SizedBox(height: 90, child: CustomPaint(size: const Size(double.infinity, 90), painter: _SunArcPainter(rise: rise, set: set, now: today ? _placeNow(sun.s('sunrise')) : null))),
              const SizedBox(height: 8),
              Row(
                children: [
                  _SunTime(icon: LucideIcons.sunrise, label: l.cardSunrise, value: rise == null ? '—' : clockOf(context, rise)),
                  _SunTime(icon: LucideIcons.hourglass, label: l.cardDayLength, value: mins == null ? '—' : dur(mins), note: change == null || change == 0 ? null : '${change > 0 ? '+' : '−'}${change.abs().toStringAsFixed(1)} min'),
                  _SunTime(icon: LucideIcons.sunset, label: l.cardSunset, value: set == null ? '—' : clockOf(context, set)),
                ],
              ),
              if (placeTime(sun.s('goldenEveningStart')) case final g?)
                Padding(padding: const EdgeInsets.only(top: 8), child: Text(l.cardGoldenHour(clockOf(context, g)), style: context.textTheme.labelMedium?.copyWith(color: const Color(0xFF9A5B00), fontWeight: FontWeight.w600))),
            ],
          ),
        ),
        const SizedBox(height: 8),
        LivePanel(
          gradient: const LinearGradient(colors: [Color(0xFF1E2A5A), Color(0xFF0B1130)]),
          child: Row(
            children: [
              SizedBox(width: 54, height: 54, child: CustomPaint(painter: _MoonPainter(moon.n('phase') ?? 0))),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_moonName(l, moon.s('name')), style: context.textTheme.titleSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                    Text(l.cardMoonLit(moon.i('illumination') ?? 0), style: context.textTheme.labelMedium?.copyWith(color: Colors.white70)),
                    Text(
                      [
                        if (placeTime(moon.s('rise')) case final r?) l.cardMoonrise(clockOf(context, r)),
                        if (placeTime(moon.s('set')) case final s?) l.cardMoonset(clockOf(context, s)),
                      ].join('  ·  '),
                      style: context.textTheme.labelSmall?.copyWith(color: Colors.white60),
                    ),
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

/// The place's own time now, read from the offset of one of its times.
DateTime? _placeNow(String? isoWithOffset) {
  final m = RegExp(r'([+-])(\d{2}):?(\d{2})$').firstMatch(isoWithOffset ?? '');
  if (m == null) return null;
  final off = Duration(hours: int.parse(m[2]!), minutes: int.parse(m[3]!)) * (m[1] == '-' ? -1 : 1);
  final u = DateTime.now().toUtc().add(off);
  return DateTime(u.year, u.month, u.day, u.hour, u.minute);
}

String _moonName(AppLocalizations l, String? n) => switch (n) {
  'new_moon' => l.cardMoonNew,
  'waxing_crescent' => l.cardMoonWaxingCrescent,
  'first_quarter' => l.cardMoonFirstQuarter,
  'waxing_gibbous' => l.cardMoonWaxingGibbous,
  'full_moon' => l.cardMoonFull,
  'waning_gibbous' => l.cardMoonWaningGibbous,
  'last_quarter' => l.cardMoonLastQuarter,
  _ => l.cardMoonWaningCrescent,
};

class _SunTime extends StatelessWidget {
  const _SunTime({required this.icon, required this.label, required this.value, this.note});
  final IconData icon;
  final String label;
  final String value;
  final String? note;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Icon(icon, size: 16, color: const Color(0xFFB86E00)),
        Text(label, style: context.textTheme.labelSmall?.copyWith(color: const Color(0xFF7A5A2E))),
        Text(value, style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: const Color(0xFF3B2A12), fontFeatures: AppText.tabular)),
        if (note != null) Text(note!, style: context.textTheme.labelSmall?.copyWith(color: const Color(0xFF7A5A2E))),
      ],
    ),
  );
}

class _SunArcPainter extends CustomPainter {
  _SunArcPainter({this.rise, this.set, this.now});
  final DateTime? rise, set, now;
  @override
  void paint(Canvas canvas, Size size) {
    final base = size.height - 6;
    final horizon = Paint()
      ..color = const Color(0xFFB98B4E).withValues(alpha: 0.5)
      ..strokeWidth = 1.2;
    canvas.drawLine(Offset(0, base), Offset(size.width, base), horizon);
    final rect = Rect.fromLTWH(size.width * 0.08, base - (size.height - 14), size.width * 0.84, (size.height - 14) * 2);
    final path = Path()..addArc(rect, math.pi, math.pi);
    final dash = Paint()
      ..color = const Color(0xFFE29A2E).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final m in path.computeMetrics()) {
      for (double d = 0; d < m.length; d += 8) {
        canvas.drawPath(m.extractPath(d, math.min(d + 4, m.length)), dash);
      }
    }
    if (rise != null && set != null && now != null) {
      final t = (now!.difference(rise!).inSeconds / set!.difference(rise!).inSeconds);
      if (t >= 0 && t <= 1) {
        final a = math.pi + t * math.pi;
        final c = rect.center + Offset(math.cos(a) * rect.width / 2, math.sin(a) * rect.height / 2);
        canvas.drawCircle(c, 14, Paint()..color = const Color(0xFFFFC447).withValues(alpha: 0.35));
        canvas.drawCircle(c, 8, Paint()..color = const Color(0xFFF5A623));
      }
    }
  }

  @override
  bool shouldRepaint(_SunArcPainter o) => o.now != now || o.rise != rise;
}

/// The moon as it looks: the lit part drawn from its phase (0 new, 0.5 full).
class _MoonPainter extends CustomPainter {
  _MoonPainter(this.phase);
  final double phase;
  @override
  void paint(Canvas canvas, Size size) {
    final r = size.shortestSide / 2;
    final c = size.center(Offset.zero);
    canvas.drawCircle(c, r + 4, Paint()..color = Colors.white.withValues(alpha: 0.08));
    canvas.drawCircle(c, r, Paint()..color = const Color(0xFF2E3658));
    final lit = Paint()..color = const Color(0xFFF3EEDB);
    final p = phase % 1;
    final waxing = p < 0.5;
    final k = math.cos(p * 2 * math.pi); // 1 new, -1 full
    final path = Path()..moveTo(c.dx, c.dy - r);
    // The limb: a half circle on the lit side.
    path.arcToPoint(Offset(c.dx, c.dy + r), radius: Radius.circular(r), clockwise: waxing);
    // The terminator: an ellipse whose width follows the phase.
    final w = (r * k).abs();
    path.arcToPoint(Offset(c.dx, c.dy - r), radius: Radius.elliptical(math.max(w, 0.01), r), clockwise: waxing ? k > 0 : k < 0);
    canvas.drawPath(path, lit);
  }

  @override
  bool shouldRepaint(_MoonPainter o) => o.phase != phase;
}
