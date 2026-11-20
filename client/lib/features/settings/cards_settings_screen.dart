import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/link_browser.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/app_card.dart';
import '../../ui/form_sheet.dart';
import '../../ui/page.dart';
import '../chat/widgets/cards/live_kit.dart';

/// Settings → Cards (docs/RICH-CARDS-PLAN.md §4.6): the home city bots use when you ask without a
/// place, the units cards show, whether red means up, and where cards' data comes from.
class CardsSettingsScreen extends ConsumerStatefulWidget {
  const CardsSettingsScreen({super.key});
  @override
  ConsumerState<CardsSettingsScreen> createState() => _CardsSettingsScreenState();
}

class _CardsSettingsScreenState extends ConsumerState<CardsSettingsScreen> {
  final _search = TextEditingController();
  Timer? _debounce;
  List<Map<String, Object?>> _found = const [];
  bool _searching = false;
  bool _saving = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onSearch(String q) {
    _debounce?.cancel();
    if (q.trim().length < 2) return setState(() => _found = const []);
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      setState(() => _searching = true);
      try {
        final r = await ref.read(backendProvider).searchPlaces(q.trim());
        if (mounted) setState(() => _found = r);
      } catch (_) {
        if (mounted) setState(() => _found = const []);
      } finally {
        if (mounted) setState(() => _searching = false);
      }
    });
  }

  Future<void> _save({Map<String, Object?>? home, bool clearHome = false, Map<String, String>? units}) async {
    setState(() => _saving = true);
    try {
      await ref.read(backendProvider).updateCardPrefs(homePlace: home, clearHome: clearHome, units: units);
      ref.invalidate(cardPrefsProvider);
      if (home != null || clearHome) {
        _search.clear();
        setState(() => _found = const []);
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(context.l10n.cardsSettingsSaveFailed)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final prefs = ref.watch(cardPrefsProvider).value ?? const {};
    final home = prefs['home_place'] is Map ? P.of(prefs['home_place']) : null;
    final units = cardUnitsOf(context, ref);
    String placeLine(P p) => [p.s('name'), p.s('region'), p.s('country_name') ?? p.s('country')].whereType<String>().toSet().join(', ');
    Widget segment(String label, String value, List<(String, String)> options, String key) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.sm),
      child: Row(
        children: [
          Expanded(child: Text(label, style: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600))),
          SegmentedButton<String>(
            key: Key('cardUnits-$key'),
            showSelectedIcon: false,
            segments: [for (final (v, t) in options) ButtonSegment(value: v, label: Text(t))],
            selected: {value},
            onSelectionChanged: _saving ? null : (s) => _save(units: {...units.toJson(), key: s.first}),
          ),
        ],
      ),
    );
    return SubPage(
      title: l.cardsSettingsTitle,
      children: [
        FormNote(l.cardsSettingsIntro, icon: LucideIcons.cloudSun),
        SectionHeader(title: l.cardsHomeCity),
        if (home != null && !home.isEmpty)
          GroupedTile(
            key: const Key('cardsHomeCity'),
            icon: LucideIcons.house,
            title: placeLine(home),
            subtitle: home.s('tz'),
            trailing: TextButton(onPressed: _saving ? null : () => _save(clearHome: true), child: Text(l.cardsHomeClear)),
          )
        else
          Text(l.cardsHomeNone, style: context.textTheme.bodyMedium?.copyWith(color: context.colorScheme.onSurfaceVariant)),
        const SizedBox(height: AppSpace.sm),
        TextField(
          key: const Key('cardsHomeSearch'),
          controller: _search,
          onChanged: _onSearch,
          decoration: InputDecoration(
            prefixIcon: const Icon(LucideIcons.search, size: 18),
            hintText: l.cardsHomeSearch,
            suffixIcon: _searching ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))) : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.tile)),
          ),
        ),
        for (final f in _found)
          ListTile(
            key: Key('cardsPlace-${f['name']}-${f['lat']}'),
            leading: const Icon(LucideIcons.mapPin, size: 18),
            title: Text(placeLine(P.of(f))),
            subtitle: f['tz'] is String ? Text(f['tz']! as String) : null,
            onTap: _saving ? null : () => _save(home: f),
          ),
        Padding(padding: const EdgeInsets.only(top: AppSpace.xs), child: FormNote(l.cardsHomePrivacy, icon: LucideIcons.shieldCheck)),
        SectionHeader(title: l.cardsUnits),
        segment(l.cardsTemperature, units.temp, const [('C', '°C'), ('F', '°F')], 'temp'),
        segment(l.cardsWind, units.wind, const [('kph', 'km/h'), ('mph', 'mph'), ('ms', 'm/s')], 'wind'),
        segment(l.cardsRain, units.precip, const [('mm', 'mm'), ('in', 'in')], 'precip'),
        segment(l.cardsDistance, units.distance, const [('km', 'km'), ('mi', 'mi')], 'distance'),
        SectionHeader(title: l.cardsPrices),
        ValueListenableBuilder<bool?>(
          valueListenable: cardRedUp,
          builder: (context, v, _) => SwitchListTile(
            key: const Key('cardsRedUp'),
            contentPadding: EdgeInsets.zero,
            title: Text(l.cardsRedUp),
            subtitle: Text(l.cardsRedUpHint),
            value: v ?? redUpByLocale(context),
            onChanged: setCardRedUp,
          ),
        ),
        SectionHeader(title: l.cardsSources),
        Text(l.cardsSourcesIntro, style: context.textTheme.bodySmall?.copyWith(color: context.colorScheme.onSurfaceVariant)),
        const SizedBox(height: AppSpace.xs),
        for (final (name, what, url) in _sources)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(name),
            subtitle: Text(what),
            trailing: const Icon(LucideIcons.externalLink, size: 14),
            onTap: () => openWebLink(Uri.parse(url)),
          ),
      ],
    );
  }
}

/// Where cards' data comes from, with the credit each license asks for.
const _sources = [
  ('MET Norway', 'Weather forecasts · CC BY 4.0', 'https://api.met.no/'),
  ('Open-Meteo', 'Rain chances, air quality, pollen · CC BY 4.0', 'https://open-meteo.com/'),
  ('GeoNames', 'Places and time zones · CC BY 4.0', 'https://www.geonames.org/'),
  ('US National Weather Service', 'Weather alerts in the US', 'https://www.weather.gov/'),
  ('Frankfurter', 'Central bank exchange rates', 'https://frankfurter.dev/'),
  ('CoinGecko', 'Crypto prices', 'https://www.coingecko.com/'),
  ('Yahoo Finance', 'Stock prices on self-hosted servers', 'https://finance.yahoo.com/'),
  ('USGS', 'Earthquakes', 'https://earthquake.usgs.gov/'),
  ('GDACS (EU JRC)', 'Tropical storms', 'https://www.gdacs.org/'),
  ('Wikipedia', 'Encyclopedia summaries · CC BY-SA 4.0', 'https://www.wikipedia.org/'),
  ('Wiktionary', 'Definitions · CC BY-SA', 'https://www.wiktionary.org/'),
  ('Open Library', 'Books', 'https://openlibrary.org/'),
  ('Nager.Date', 'Public holidays', 'https://date.nager.at/'),
  ('ESPN', 'Scores and standings', 'https://www.espn.com/'),
];
