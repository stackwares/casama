import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:a2ui_flutter/a2ui_flutter.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:json_schema_builder/json_schema_builder.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/link_browser.dart';
import '../../../../core/providers.dart';
import '../../../../core/widgets.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_tokens.dart';

// Live data cards (docs/RICH-CARDS-PLAN.md §5): the parts every card shares. A card is built from
// its props (filled by the server for data cards, by the bot for composed ones); data cards carry
// a `live` block and refresh themselves through the API without the model.

/// Loose readers for a card's props: missing or wrong-typed values read as null.
extension type const P(Map<Object?, Object?> m) {
  static P of(Object? v) => P(v is Map ? Map<Object?, Object?>.from(v) : const {});
  Object? operator [](String k) => m[k];
  String? s(String k) {
    final v = m[k];
    final t = switch (v) {
      final String s => s.trim(),
      final num n => n.toString(),
      _ => null,
    };
    return t == null || t.isEmpty ? null : t;
  }

  double? n(String k) => switch (m[k]) {
    final num v => v.toDouble(),
    final String v => double.tryParse(v),
    _ => null,
  };
  int? i(String k) => n(k)?.round();
  bool? b(String k) => m[k] is bool ? m[k] as bool : null;
  P map(String k) => P.of(m[k]);
  List<P> rows(String k) => [if (m[k] case final List l) for (final x in l) if (x is Map) P.of(x)];
  List<String> texts(String k) => [
    if (m[k] case final List l)
      for (final x in l)
        if (x is String && x.trim().isNotEmpty) x.trim() else if (x is num) '$x',
  ];
  List<num> nums(String k) => [if (m[k] case final List l) for (final x in l) if (x is num) x];
  DateTime? t(String k) => parseCardTime(s(k));
  bool get isEmpty => m.isEmpty;
}

DateTime? parseCardTime(String? s) {
  if (s == null) return null;
  final d = DateTime.tryParse(s);
  return d == null ? null : (d.isUtc ? d.toLocal() : d);
}

/// The wall-clock time of an ISO time with an offset, in that offset's place (not the device's).
/// "2026-11-21T14:00+08:00" reads 14:00 wherever the phone is.
DateTime? placeTime(String? iso) {
  if (iso == null || iso.length < 16) return null;
  return DateTime.tryParse(iso.substring(0, 16));
}

// ---------------------------------------------------------------------------------------------
// Units
// ---------------------------------------------------------------------------------------------

class CardUnits {
  const CardUnits({this.temp = 'C', this.wind = 'kph', this.precip = 'mm', this.distance = 'km'});
  final String temp;
  final String wind;
  final String precip;
  final String distance;

  static CardUnits forLocale(Locale? l) {
    final c = l?.countryCode;
    return c == 'US' || c == 'LR' || c == 'MM' ? const CardUnits(temp: 'F', wind: 'mph', precip: 'in', distance: 'mi') : const CardUnits();
  }

  CardUnits merge(Map<Object?, Object?>? m) => m == null
      ? this
      : CardUnits(
          temp: m['temp'] as String? ?? temp,
          wind: m['wind'] as String? ?? wind,
          precip: m['precip'] as String? ?? precip,
          distance: m['distance'] as String? ?? distance,
        );

  Map<String, String> toJson() => {'temp': temp, 'wind': wind, 'precip': precip, 'distance': distance};

  /// Degrees in the person's unit, from Celsius.
  int deg(num c) => (temp == 'F' ? c * 9 / 5 + 32 : c).round();
  String degText(num c) => '${deg(c)}°';
  String speed(num kph) => switch (wind) {
    'mph' => '${(kph / 1.609).round()} mph',
    'ms' => '${(kph / 3.6).round()} m/s',
    'kn' => '${(kph / 1.852).round()} kn',
    _ => '${kph.round()} km/h',
  };
  String rain(num mm) => precip == 'in' ? '${(mm / 25.4).toStringAsFixed(2)} in' : '${mm >= 10 ? mm.round() : mm.toStringAsFixed(1)} mm';
  String dist(num km) => distance == 'mi' ? '${NumberFormat.decimalPattern().format((km / 1.609).round())} mi' : '${NumberFormat.decimalPattern().format(km.round())} km';
}

/// The person's card preferences from the server (home city, units), with the locale's units
/// until they load or when the server is older.
final cardPrefsProvider = FutureProvider<Map<String, Object?>>((ref) async {
  try {
    return await ref.watch(backendProvider).cardPrefs();
  } catch (_) {
    return const {};
  }
});

CardUnits cardUnitsOf(BuildContext context, WidgetRef ref) {
  final base = CardUnits.forLocale(Localizations.maybeLocaleOf(context) ?? ui.PlatformDispatcher.instance.locale);
  final saved = ref.watch(cardPrefsProvider).value?['units'];
  return base.merge(saved is Map ? Map<Object?, Object?>.from(saved) : null);
}

// ---------------------------------------------------------------------------------------------
// Numbers
// ---------------------------------------------------------------------------------------------

String fmtMoney(BuildContext context, num v, String? currency, {bool compact = false}) {
  final locale = context.l10n.localeName;
  final cur = (currency ?? '').toUpperCase();
  final digits = v.abs() >= 1000 ? 2 : (v.abs() >= 1 ? 2 : (v.abs() >= 0.01 ? 4 : 6));
  try {
    if (compact && v.abs() >= 100000) return NumberFormat.compactSimpleCurrency(locale: locale, name: cur.isEmpty ? null : cur).format(v);
    return NumberFormat.simpleCurrency(locale: locale, name: cur.isEmpty ? null : cur, decimalDigits: cur == 'JPY' || cur == 'KRW' ? 0 : digits).format(v);
  } catch (_) {
    return '${NumberFormat.decimalPatternDigits(locale: locale, decimalDigits: digits).format(v)} $cur';
  }
}

String fmtNum(BuildContext context, num v, {int digits = 2}) => NumberFormat.decimalPatternDigits(locale: context.l10n.localeName, decimalDigits: digits).format(v);
String fmtCompact(BuildContext context, num v) => NumberFormat.compact(locale: context.l10n.localeName).format(v);
String fmtPct(num v) => '${v >= 0 ? '+' : '−'}${v.abs().toStringAsFixed(2)}%';

/// "2 min ago", "3 h ago", or the date.
String cardAgo(BuildContext context, DateTime t) {
  final l = context.l10n;
  final d = DateTime.now().difference(t);
  if (d.inSeconds < 50) return l.cardJustNow;
  if (d.inMinutes < 60) return l.cardMinutesAgo(d.inMinutes);
  if (d.inHours < 24) return l.cardHoursAgo(d.inHours);
  return DateFormat.MMMd(l.localeName).add_jm().format(t);
}

String clockOf(BuildContext context, DateTime t) => MediaQuery.alwaysUse24HourFormatOf(context) ? DateFormat.Hm().format(t) : DateFormat.jm(context.l10n.localeName).format(t);
String hourOf(BuildContext context, DateTime t) => MediaQuery.alwaysUse24HourFormatOf(context) ? DateFormat.H().format(t) : DateFormat.j(context.l10n.localeName).format(t).replaceAll(' ', '').toLowerCase();

// ---------------------------------------------------------------------------------------------
// The host: refreshing, views, pinning
// ---------------------------------------------------------------------------------------------

typedef LiveBuilder = Widget? Function(BuildContext context, P props, LiveCardController ctl);

/// One of Casama's live or composed cards as an A2UI component. [props] are its own fields; the
/// shared `live`, `summary` and `source` are added.
ComponentImplementation liveCard(String name, List<String> props, LiveBuilder build) {
  final all = {...props, 'live', 'summary', 'source'};
  return ComponentImplementation(
    name: name,
    schema: Schema.fromMap(<String, Object?>{
      'type': 'object',
      'properties': <String, Object?>{
        'component': <String, Object?>{'const': name},
        for (final p in all) p: const <String, Object?>{},
      },
      'required': const <Object?>['component'],
    }),
    builder: (context, node, resolved, buildChild) => LiveCardHost(
      key: ValueKey('live-${node.instanceId}'),
      name: name,
      initial: {for (final p in all) p: resolved.value(p)},
      build: build,
      act: (event, values, label) => node.context?.dispatchAction({
        'event': {'name': event, 'context': values, 'userMessage': label},
      }),
    ),
  );
}

class LiveCardController extends InheritedWidget {
  const LiveCardController({super.key, required this.state, required super.child, required this.version});
  final LiveCardHostState state;
  final int version;

  static LiveCardController? of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<LiveCardController>();

  P get props => state.props;
  P get live => props.map('live');
  String? get ref => live.s('ref');
  bool get refreshing => state.refreshing;
  String? get error => state.error;
  String? get view => state.view;
  bool get pinned => state.pinned;
  Future<void> refresh({bool force = false}) => state.refresh(force: force);
  Future<void> setView(String? view) => state.setView(view);
  void act(String event, Map<String, Object?> values, String label) => state.widget.act(event, values, label);

  @override
  bool updateShouldNotify(LiveCardController old) => old.version != version;
}

class LiveCardHost extends ConsumerStatefulWidget {
  const LiveCardHost({super.key, required this.name, required this.initial, required this.build, required this.act});
  final String name;
  final Map<String, Object?> initial;
  final LiveBuilder build;
  final void Function(String event, Map<String, Object?> values, String label) act;

  @override
  ConsumerState<LiveCardHost> createState() => LiveCardHostState();
}

/// How long after showing a card it keeps refreshing on its own.
const _autoFor = Duration(minutes: 30);

class LiveCardHostState extends ConsumerState<LiveCardHost> with WidgetsBindingObserver {
  late P props = P(Map<Object?, Object?>.from(widget.initial));
  bool refreshing = false;
  String? error;
  String? view;
  bool pinned = false;
  int _version = 0;
  Timer? _timer;
  final _mounted = DateTime.now();
  final boundary = GlobalKey();
  AppLifecycleState _life = AppLifecycleState.resumed;

  P get live => props.map('live');
  String? get cardId => live.s('ref');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (cardId != null) {
      // A card shown a while ago catches up once when it comes on screen; it then ticks along
      // while it stays on screen, for half an hour (§4.4). Cards older than a week stay as they were.
      final fetched = live.t('fetchedAt');
      final old = fetched != null && DateTime.now().difference(fetched) > const Duration(days: 7);
      if (!old) {
        Future<void>.delayed(const Duration(milliseconds: 400), () {
          if (mounted && _due) refresh();
        });
        _timer = Timer.periodic(const Duration(seconds: 20), (_) {
          if (!mounted) return;
          if (DateTime.now().difference(_mounted) > _autoFor) {
            _timer?.cancel();
            return;
          }
          if (_life == AppLifecycleState.resumed && _due && !refreshing) refresh();
          // The footer's "2 min ago" moves on.
          setState(() => _version++);
        });
      }
    }
  }

  bool get _due {
    final stale = live.t('staleAfter');
    return stale != null && DateTime.now().isAfter(stale) && error == null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) => _life = state;

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> refresh({bool force = false}) async {
    final id = cardId;
    if (id == null || refreshing) return;
    setState(() {
      refreshing = true;
      _version++;
    });
    try {
      final r = await ref.read(backendProvider).refreshLiveCard(id, view: view, force: force);
      if (!mounted) return;
      final card = r['card'];
      setState(() {
        if (card is Map) props = P(Map<Object?, Object?>.from(card));
        error = r['error'] as String?;
        pinned = r['pinned'] == true || pinned;
        refreshing = false;
        _version++;
      });
      if (force) HapticFeedback.selectionClick();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = context.l10n.cardCouldntUpdate;
        refreshing = false;
        _version++;
      });
    }
  }

  Future<void> setView(String? v) async {
    if (v == view) return;
    setState(() {
      view = v;
      _version++;
    });
    if (cardId != null) await refresh();
  }

  Future<void> pin() async {
    final id = cardId;
    if (id == null) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final l10n = context.l10n;
    final units = cardUnitsOf(context, ref);
    try {
      if (pinned) {
        await ref.read(backendProvider).unpinLiveCard(id);
        setState(() {
          pinned = false;
          _version++;
        });
        messenger?.showSnackBar(SnackBar(content: Text(l10n.cardUnpinned)));
      } else {
        final r = await ref.read(backendProvider).pinLiveCard(id, units: units.toJson());
        setState(() {
          pinned = true;
          _version++;
        });
        messenger?.showSnackBar(SnackBar(content: Text(r['status'] == 'waiting' ? l10n.cardPinnedWaiting : l10n.cardPinned)));
      }
    } catch (_) {
      messenger?.showSnackBar(SnackBar(content: Text(l10n.cardPinFailed)));
    }
  }

  Future<void> report() async {
    final id = cardId;
    if (id == null) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final l10n = context.l10n;
    try {
      await ref.read(backendProvider).reportLiveCard(id);
      messenger?.showSnackBar(SnackBar(content: Text(l10n.cardReported)));
    } catch (_) {}
  }

  Future<void> copy() async {
    final text = [props.s('summary'), _sourceLine()].whereType<String>().join('\n');
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(context.l10n.cardCopied)));
  }

  String? _sourceLine() {
    final name = live.map('source').s('name') ?? props.map('source').s('name');
    return name == null ? null : '— $name';
  }

  /// The card as a picture, shared through the system's share sheet.
  Future<void> shareImage() async {
    try {
      final b = boundary.currentContext?.findRenderObject();
      if (b is! RenderRepaintBoundary) return;
      final image = await b.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) return;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile.fromData(data.buffer.asUint8List(), mimeType: 'image/png', name: 'casama-${widget.name.toLowerCase()}.png')],
          text: props.s('summary'),
        ),
      );
    } catch (_) {
      await copy();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = LiveCardController(state: this, version: _version, child: Builder(builder: (context) => widget.build(context, props, LiveCardController.of(context)!) ?? const SizedBox.shrink()));
    final summary = props.s('summary');
    return Semantics(
      label: summary,
      container: true,
      child: RepaintBoundary(key: boundary, child: controller),
    );
  }
}

// ---------------------------------------------------------------------------------------------
// Layout parts
// ---------------------------------------------------------------------------------------------

/// A card's top line: an icon tile, title and subtitle, an optional pill, and the ⋯ menu.
class LiveHeader extends StatelessWidget {
  const LiveHeader({super.key, required this.icon, required this.title, this.subtitle, this.pill, this.pillColor, this.iconColor, this.onDark = false, this.leading});
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? pill;
  final Color? pillColor;
  final Color? iconColor;
  final bool onDark;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final fg = onDark ? Colors.white : scheme.onSurface;
    final sub = onDark ? Colors.white.withValues(alpha: 0.78) : scheme.onSurfaceVariant;
    return Row(
      children: [
        leading ??
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: onDark ? Colors.white.withValues(alpha: 0.18) : (iconColor ?? scheme.primary).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, size: 17, color: onDark ? Colors.white : (iconColor ?? scheme.primary)),
            ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textTheme.titleSmall?.copyWith(fontFamily: AppFonts.sans, fontWeight: FontWeight.w600, color: fg, height: 1.2)),
              if (subtitle != null)
                Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textTheme.labelMedium?.copyWith(color: sub, height: 1.25)),
            ],
          ),
        ),
        if (pill != null) ...[const SizedBox(width: 8), LivePill(text: pill!, color: pillColor, onDark: onDark)],
        const LiveMenu(),
      ],
    );
  }
}

class LivePill extends StatelessWidget {
  const LivePill({super.key, required this.text, this.color, this.onDark = false, this.icon});
  final String text;
  final Color? color;
  final bool onDark;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = color ?? (onDark ? Colors.white : context.colorScheme.onSurfaceVariant);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: onDark ? Colors.white.withValues(alpha: 0.18) : c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 12, color: onDark ? Colors.white : c), const SizedBox(width: 4)],
          Text(text, style: context.textTheme.labelSmall?.copyWith(color: onDark ? Colors.white : c, fontWeight: FontWeight.w600, letterSpacing: 0.2)),
        ],
      ),
    );
  }
}

/// The ⋯ menu: refresh, pin to widgets, copy, share as a picture, report wrong data.
class LiveMenu extends StatelessWidget {
  const LiveMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final ctl = LiveCardController.of(context);
    if (ctl == null) return const SizedBox.shrink();
    final l = context.l10n;
    final s = ctl.state;
    final hasRef = ctl.ref != null;
    final pinnable = hasRef && _pinnable.contains(s.widget.name);
    return SizedBox(
      width: 32,
      height: 32,
      child: PopupMenuButton<String>(
        tooltip: l.cardMore,
        padding: EdgeInsets.zero,
        iconSize: 18,
        icon: Icon(LucideIcons.ellipsis, size: 18, color: context.colorScheme.onSurfaceVariant),
        onSelected: (v) => switch (v) {
          'refresh' => ctl.refresh(force: true),
          'pin' => s.pin(),
          'copy' => s.copy(),
          'share' => s.shareImage(),
          'report' => s.report(),
          _ => null,
        },
        itemBuilder: (_) => [
          if (hasRef) PopupMenuItem(value: 'refresh', child: _MenuRow(LucideIcons.refreshCw, l.cardRefresh)),
          if (pinnable) PopupMenuItem(value: 'pin', child: _MenuRow(ctl.pinned ? LucideIcons.pinOff : LucideIcons.pin, ctl.pinned ? l.cardUnpin : l.cardPin)),
          PopupMenuItem(value: 'copy', child: _MenuRow(LucideIcons.copy, l.cardCopy)),
          PopupMenuItem(value: 'share', child: _MenuRow(LucideIcons.share2, l.cardShareImage)),
          if (hasRef) PopupMenuItem(value: 'report', child: _MenuRow(LucideIcons.flag, l.cardReport)),
        ],
      ),
    );
  }
}

const _pinnable = {'Weather', 'Forecast', 'Quote', 'Watchlist', 'Currency', 'AirQuality', 'Score', 'Flight', 'Parcel', 'SunMoon'};

class _MenuRow extends StatelessWidget {
  const _MenuRow(this.icon, this.text);
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Row(children: [Icon(icon, size: 16), const SizedBox(width: 10), Text(text)]);
}

/// Source, freshness and ↻ at the bottom of a data card; a composed card names where it's from.
class LiveFooter extends StatelessWidget {
  const LiveFooter({super.key, this.onDark = false, this.note});
  final bool onDark;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final ctl = LiveCardController.of(context);
    if (ctl == null) return const SizedBox.shrink();
    final l = context.l10n;
    final live = ctl.live;
    final src = live.map('source');
    final composed = ctl.props.map('source');
    final name = src.s('name') ?? composed.s('name');
    final url = src.s('url') ?? composed.s('url');
    final fetched = live.t('fetchedAt');
    final stale = live.b('stale') == true || ctl.error != null;
    final delayed = live.i('delayed');
    final color = onDark ? Colors.white.withValues(alpha: 0.75) : context.colorScheme.onSurfaceVariant;
    final style = context.textTheme.labelSmall?.copyWith(color: color, height: 1.3);
    final parts = <String>[
      ?note,
      if (fetched != null) (stale ? l.cardStale(cardAgo(context, fetched)) : l.cardUpdated(cardAgo(context, fetched))),
      if (delayed != null && delayed > 0) l.cardDelayed(delayed),
    ];
    if (name == null && parts.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          if (stale) ...[Icon(LucideIcons.triangleAlert, size: 12, color: onDark ? Colors.amber.shade200 : context.appColors.warning), const SizedBox(width: 4)],
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  if (name != null)
                    TextSpan(
                      text: name,
                      style: style?.copyWith(fontWeight: FontWeight.w600, decoration: url != null ? TextDecoration.underline : null, decorationColor: color.withValues(alpha: 0.4)),
                      recognizer: null,
                    ),
                  if (name != null && parts.isNotEmpty) const TextSpan(text: '  ·  '),
                  TextSpan(text: parts.join('  ·  ')),
                ],
              ),
              style: style,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (url != null)
            _FooterButton(icon: LucideIcons.externalLink, tooltip: l.cardOpenSource, color: color, onTap: () => openWebLink(Uri.parse(url))),
          if (ctl.ref != null)
            ctl.refreshing
                ? SizedBox(width: 28, height: 28, child: Padding(padding: const EdgeInsets.all(7), child: CircularProgressIndicator(strokeWidth: 1.6, color: color)))
                : _FooterButton(icon: LucideIcons.refreshCw, tooltip: l.cardRefresh, color: color, onTap: () => ctl.refresh(force: true)),
        ],
      ),
    );
  }
}

class _FooterButton extends StatelessWidget {
  const _FooterButton({required this.icon, required this.tooltip, required this.color, required this.onTap});
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: InkResponse(onTap: onTap, radius: 18, child: SizedBox(width: 28, height: 28, child: Icon(icon, size: 14, color: color))),
  );
}

/// A rounded surface inside the card: the place for a card's main picture.
class LivePanel extends StatelessWidget {
  const LivePanel({super.key, required this.child, this.padding = const EdgeInsets.all(14), this.color, this.gradient});
  final Widget child;
  final EdgeInsets padding;
  final Color? color;
  final Gradient? gradient;
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: gradient == null ? (color ?? context.colorScheme.surface) : null,
      gradient: gradient,
      borderRadius: BorderRadius.circular(AppRadius.tile),
      border: gradient == null ? Border.all(color: context.appColors.hairline) : null,
    ),
    child: child,
  );
}

/// The usual card: header, body, optional buttons, footer.
class LiveLayout extends StatelessWidget {
  const LiveLayout({super.key, required this.header, required this.body, this.footer = const LiveFooter(), this.gap = 12});
  final Widget header;
  final Widget body;
  final Widget? footer;
  final double gap;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [header, SizedBox(height: gap), body, ?footer],
  );
}

/// A big number that counts to its new value when it changes (instant with reduced motion).
class HeroNumber extends StatelessWidget {
  const HeroNumber({super.key, required this.value, required this.format, this.style, this.color});
  final double value;
  final String Function(double v) format;
  final TextStyle? style;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final base = (style ?? context.textTheme.displaySmall)?.copyWith(fontFeatures: AppText.tabular, color: color, fontWeight: FontWeight.w600, height: 1.05);
    if (MediaQuery.disableAnimationsOf(context)) return Text(format(value), style: base);
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text(format(v), style: base),
    );
  }
}

/// ▲ +2.14% in green or ▼ −0.80% in red; never color alone.
class ChangePill extends StatelessWidget {
  const ChangePill({super.key, required this.pct, this.goodWhenUp = true, this.label, this.big = false});
  final double pct;
  final bool goodWhenUp;
  final String? label;
  final bool big;
  @override
  Widget build(BuildContext context) {
    final c = changeColor(context, pct, goodWhenUp: goodWhenUp);
    final up = pct >= 0;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: big ? 10 : 7, vertical: big ? 4 : 2),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.13), borderRadius: BorderRadius.circular(AppRadius.pill)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(up ? LucideIcons.arrowUpRight : LucideIcons.arrowDownRight, size: big ? 15 : 12, color: c),
          const SizedBox(width: 2),
          Text(label ?? fmtPct(pct), style: (big ? context.textTheme.labelLarge : context.textTheme.labelSmall)?.copyWith(color: c, fontWeight: FontWeight.w700, fontFeatures: AppText.tabular)),
        ],
      ),
    );
  }
}

/// Up/good green, down/bad red; some people read red as up (Settings → Cards).
Color changeColor(BuildContext context, double pct, {bool goodWhenUp = true}) {
  final a = context.appColors;
  if (pct.abs() < 0.005) return context.colorScheme.onSurfaceVariant;
  final good = (pct > 0) == goodWhenUp;
  return good ? a.positive : a.negative;
}

/// A line chart without axes: gradient fill, a dotted baseline, the last point marked. Scrub with
/// a finger to read values.
class Sparkline extends StatefulWidget {
  const Sparkline({super.key, required this.points, this.baseline, this.color, this.height = 56, this.label});
  final List<double> points;
  final double? baseline;
  final Color? color;
  final double height;
  final String Function(int index)? label;
  @override
  State<Sparkline> createState() => _SparklineState();
}

class _SparklineState extends State<Sparkline> {
  int? _at;

  @override
  Widget build(BuildContext context) {
    final pts = widget.points;
    if (pts.length < 2) return SizedBox(height: widget.height);
    final color = widget.color ?? context.colorScheme.primary;
    return LayoutBuilder(
      builder: (context, box) {
        void hit(Offset p) {
          final i = ((p.dx / box.maxWidth) * (pts.length - 1)).round().clamp(0, pts.length - 1);
          if (i != _at) {
            HapticFeedback.selectionClick();
            setState(() => _at = i);
          }
        }

        return GestureDetector(
          onHorizontalDragStart: widget.label == null ? null : (d) => hit(d.localPosition),
          onHorizontalDragUpdate: widget.label == null ? null : (d) => hit(d.localPosition),
          onHorizontalDragEnd: widget.label == null ? null : (_) => setState(() => _at = null),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: MediaQuery.disableAnimationsOf(context) ? 1 : 0, end: 1),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                builder: (context, t, _) => CustomPaint(
                  size: Size(box.maxWidth, widget.height),
                  painter: _SparkPainter(pts, widget.baseline, color, t, _at, context.colorScheme.surface),
                ),
              ),
              if (_at != null && widget.label != null)
                Positioned(
                  left: ((_at! / (pts.length - 1)) * box.maxWidth - 50).clamp(0, math.max(0, box.maxWidth - 100)),
                  top: -26,
                  child: Container(
                    width: 100,
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(color: context.colorScheme.inverseSurface, borderRadius: BorderRadius.circular(8)),
                    child: Text(widget.label!(_at!), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textTheme.labelSmall?.copyWith(color: context.colorScheme.onInverseSurface, fontFeatures: AppText.tabular)),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _SparkPainter extends CustomPainter {
  _SparkPainter(this.pts, this.baseline, this.color, this.t, this.at, this.bg);
  final List<double> pts;
  final double? baseline;
  final Color color;
  final double t;
  final int? at;
  final Color bg;

  @override
  void paint(Canvas canvas, Size size) {
    var lo = pts.reduce(math.min);
    var hi = pts.reduce(math.max);
    if (baseline != null) {
      lo = math.min(lo, baseline!);
      hi = math.max(hi, baseline!);
    }
    final span = (hi - lo).abs() < 1e-9 ? 1.0 : hi - lo;
    double y(double v) => size.height - 4 - (v - lo) / span * (size.height - 8);
    double x(int i) => i / (pts.length - 1) * size.width;
    final n = math.max(2, (pts.length * t).ceil());
    final path = Path()..moveTo(x(0), y(pts[0]));
    for (var i = 1; i < n; i++) {
      final px = x(i - 1), py = y(pts[i - 1]), cx = x(i), cy = y(pts[i]);
      final mx = (px + cx) / 2;
      path.cubicTo(mx, py, mx, cy, cx, cy);
    }
    final fill = Path.from(path)
      ..lineTo(x(n - 1), size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [color.withValues(alpha: 0.28), color.withValues(alpha: 0.0)]).createShader(Offset.zero & size),
    );
    if (baseline != null) {
      final by = y(baseline!);
      final dash = Paint()
        ..color = color.withValues(alpha: 0.35)
        ..strokeWidth = 1;
      for (double dx = 0; dx < size.width; dx += 6) {
        canvas.drawLine(Offset(dx, by), Offset(math.min(dx + 3, size.width), by), dash);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    final last = at ?? (n - 1);
    final p = Offset(x(last), y(pts[last]));
    if (at != null) {
      canvas.drawLine(Offset(p.dx, 0), Offset(p.dx, size.height), Paint()..color = color.withValues(alpha: 0.3));
    }
    canvas.drawCircle(p, 5.5, Paint()..color = bg);
    canvas.drawCircle(p, 3.5, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_SparkPainter o) => o.pts != pts || o.t != t || o.at != at || o.color != color;
}

/// A low–high bar on a shared scale with an optional marker (a day's temperatures, 52 weeks).
class RangeBar extends StatelessWidget {
  const RangeBar({super.key, required this.min, required this.max, required this.lo, required this.hi, this.marker, this.colors, this.height = 6});
  final double min, max, lo, hi;
  final double? marker;
  final List<Color>? colors;
  final double height;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final span = (max - min).abs() < 1e-9 ? 1.0 : max - min;
      final a = ((lo - min) / span).clamp(0.0, 1.0) * box.maxWidth;
      final b = ((hi - min) / span).clamp(0.0, 1.0) * box.maxWidth;
      return SizedBox(
        height: math.max(height, 12),
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            Container(height: height, decoration: BoxDecoration(color: context.colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(height))),
            Positioned(
              left: a,
              width: math.max(height, b - a),
              child: Container(
                height: height,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: colors ?? [context.colorScheme.primary, context.colorScheme.tertiary]),
                  borderRadius: BorderRadius.circular(height),
                ),
              ),
            ),
            if (marker != null)
              Positioned(
                left: (((marker! - min) / span).clamp(0.0, 1.0) * box.maxWidth - 5).clamp(0.0, math.max(0.0, box.maxWidth - 10)),
                child: Container(width: 10, height: 10, decoration: BoxDecoration(color: context.colorScheme.surface, shape: BoxShape.circle, border: Border.all(color: context.colorScheme.onSurface, width: 2))),
              ),
          ],
        ),
      );
    },
  );
}

/// A semicircle gauge with colored bands and a needle.
class Gauge extends StatelessWidget {
  const Gauge({super.key, required this.value, required this.max, required this.bands, this.size = 150, this.center});
  final double value;
  final double max;
  final List<(double, Color)> bands;
  final double size;
  final Widget? center;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size * 0.62,
    child: Stack(
      alignment: Alignment.bottomCenter,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: MediaQuery.disableAnimationsOf(context) ? value : 0, end: value),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
          builder: (context, v, _) => CustomPaint(size: Size(size, size * 0.62), painter: _GaugePainter(v, max, bands, context.colorScheme.onSurface, context.colorScheme.surfaceContainerHighest)),
        ),
        ?center,
      ],
    ),
  );
}

class _GaugePainter extends CustomPainter {
  _GaugePainter(this.value, this.max, this.bands, this.ink, this.track);
  final double value, max;
  final List<(double, Color)> bands;
  final Color ink, track;
  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2 - 8;
    final c = Offset(size.width / 2, size.height - 4);
    final rect = Rect.fromCircle(center: c, radius: r);
    final stroke = 12.0;
    canvas.drawArc(rect, math.pi, math.pi, false, Paint()..color = track..style = PaintingStyle.stroke..strokeWidth = stroke..strokeCap = StrokeCap.round);
    var from = 0.0;
    for (final (to, color) in bands) {
      final a = math.pi + (from / max).clamp(0, 1) * math.pi;
      final sweep = ((to - from) / max).clamp(0, 1) * math.pi;
      canvas.drawArc(rect, a, sweep, false, Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = stroke);
      from = to;
    }
    final angle = math.pi + (value / max).clamp(0.0, 1.0) * math.pi;
    final tip = c + Offset(math.cos(angle), math.sin(angle)) * (r - 2);
    canvas.drawCircle(tip, 8, Paint()..color = Colors.white);
    canvas.drawCircle(tip, 8, Paint()..color = ink..style = PaintingStyle.stroke..strokeWidth = 2.5);
  }

  @override
  bool shouldRepaint(_GaugePainter o) => o.value != value;
}

/// Small facts as chips: an icon, a label and a value.
class FactChip extends StatelessWidget {
  const FactChip({super.key, required this.icon, required this.label, required this.value, this.onDark = false, this.color});
  final IconData icon;
  final String label;
  final String value;
  final bool onDark;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    final fg = onDark ? Colors.white : context.colorScheme.onSurface;
    final sub = onDark ? Colors.white.withValues(alpha: 0.75) : context.colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: onDark ? Colors.white.withValues(alpha: 0.14) : context.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color ?? sub),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: context.textTheme.labelSmall?.copyWith(color: sub, height: 1.1)),
              Text(value, style: context.textTheme.labelLarge?.copyWith(color: fg, fontWeight: FontWeight.w600, fontFeatures: AppText.tabular, height: 1.2)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Segmented choices for a card's views (Now · Hourly · 7 days; 1D · 1W · 1M…).
class ViewChips extends StatelessWidget {
  const ViewChips({super.key, required this.options, required this.selected, required this.onSelect, this.onDark = false});
  final List<(String, String)> options;
  final String selected;
  final ValueChanged<String> onSelect;
  final bool onDark;
  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final (value, label) in options)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Material(
                color: value == selected ? (onDark ? Colors.white : scheme.onSurface) : (onDark ? Colors.white.withValues(alpha: 0.14) : scheme.surfaceContainerHighest.withValues(alpha: 0.7)),
                shape: const StadiumBorder(),
                child: InkWell(
                  customBorder: const StadiumBorder(),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onSelect(value);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Text(
                      label,
                      style: context.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: value == selected ? (onDark ? Colors.black87 : scheme.surface) : (onDark ? Colors.white : scheme.onSurfaceVariant),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A picture from the web with a soft placeholder; nothing for links that aren't https.
class CardImage extends StatelessWidget {
  const CardImage({super.key, required this.url, this.width, this.height, this.radius = 12, this.fit = BoxFit.cover, this.fallback});
  final String? url;
  final double? width, height;
  final double radius;
  final BoxFit fit;
  final Widget? fallback;
  @override
  Widget build(BuildContext context) {
    final u = url;
    final empty = fallback ?? Container(width: width, height: height, color: context.colorScheme.surfaceContainerHighest);
    if (u == null || !u.startsWith('https://')) return ClipRRect(borderRadius: BorderRadius.circular(radius), child: empty);
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.network(u, width: width, height: height, fit: fit, errorBuilder: (_, _, _) => empty, frameBuilder: (context, child, frame, sync) => sync || frame != null ? child : SizedBox(width: width, height: height, child: empty)),
    );
  }
}

/// A logo or crest, or the first letters on a tinted circle.
class Monogram extends StatelessWidget {
  const Monogram({super.key, required this.text, this.url, this.size = 34, this.color});
  final String text;
  final String? url;
  final double size;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    final c = color ?? context.colorScheme.primary;
    final letters = text.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
    final fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: c.withValues(alpha: 0.14), shape: BoxShape.circle),
      child: Text(letters.isEmpty ? '?' : letters.substring(0, math.min(letters.length, size > 30 ? 3 : 2)).toUpperCase(), style: context.textTheme.labelSmall?.copyWith(color: c, fontWeight: FontWeight.w800, fontSize: size * 0.3)),
    );
    final u = url;
    if (u == null || !u.startsWith('https://')) return fallback;
    return ClipOval(child: Image.network(u, width: size, height: size, fit: BoxFit.contain, errorBuilder: (_, _, _) => fallback));
  }
}

/// A hex color like "552583" or "#552583".
Color? hexColor(String? hex) {
  if (hex == null) return null;
  final h = hex.replaceAll('#', '');
  if (h.length != 6) return null;
  final v = int.tryParse(h, radix: 16);
  return v == null ? null : Color(0xFF000000 | v);
}

/// The card's own text style helpers.
extension CardText on BuildContext {
  TextStyle? get cardLabel => textTheme.labelMedium?.copyWith(color: colorScheme.onSurfaceVariant);
  TextStyle? get cardBody => textTheme.bodyMedium?.copyWith(height: 1.45);
}

/// A tappable row that opens a link.
Future<void> openCardLink(String? url) async {
  final u = url == null ? null : Uri.tryParse(url);
  if (u == null || !(u.scheme == 'https' || u.scheme == 'http')) return;
  await openWebLink(u);
}
