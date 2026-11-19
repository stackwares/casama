import '../../../theme/app_colors.dart';

import 'package:a2ui_flutter/a2ui_flutter.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:json_schema_builder/json_schema_builder.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../theme/app_tokens.dart';
import '../../../core/link_browser.dart';

/// MapTiler key for map cards; builds without one use OpenStreetMap's own tiles, which are fine
/// for a self-built app's light use but not for the store apps (D-310).
const kMapTilerKey = String.fromEnvironment('CASAMA_MAPTILER_KEY');

/// A place on a map card, read from a bot's `{lat, lng}`.
LatLng? _point(Object? v) {
  if (v is! Map) return null;
  final lat = v['lat'], lng = v['lng'] ?? v['lon'];
  if (lat is! num || lng is! num) return null;
  if (lat.abs() > 90 || lng.abs() > 180) return null;
  return LatLng(lat.toDouble(), lng.toDouble());
}

/// What a bot's Map component asks for, parsed and checked.
class MapCardSpec {
  const MapCardSpec({
    required this.center,
    required this.zoom,
    required this.markers,
    required this.path,
    required this.height,
  });
  final LatLng? center;
  final double zoom;
  final List<({LatLng point, String? label})> markers;
  final List<LatLng> path;
  final double height;

  static MapCardSpec of(ComponentProps props) {
    final markers = [
      for (final m in props.list('markers'))
        if (_point(m) case final p?)
          (
            point: p,
            label: (m as Map)['label'] is String ? m['label'] as String : null,
          ),
    ];
    final path = [for (final p in props.list('path')) ?_point(p)];
    return MapCardSpec(
      center: _point(props.value('center')),
      zoom: (props.number('zoom') ?? 12).clamp(1, 18).toDouble(),
      markers: markers.take(50).toList(),
      path: path.take(500).toList(),
      height: (props.number('height') ?? 220).clamp(140, 420).toDouble(),
    );
  }

  /// Everything the map should show, for fitting the view when there's no center.
  List<LatLng> get points => [for (final m in markers) m.point, ...path];

  bool get isEmpty => center == null && points.isEmpty;
}

/// The A2UI `Map` component, Casama's own addition to the basic catalog (D-310).
final mapComponent = ComponentImplementation(
  name: 'Map',
  schema: Schema.fromMap(const <String, Object?>{
    'type': 'object',
    'properties': <String, Object?>{
      'component': <String, Object?>{'const': 'Map'},
      'center': <String, Object?>{'type': 'object'},
      'zoom': <String, Object?>{'type': 'number'},
      'markers': <String, Object?>{'type': 'array'},
      'path': <String, Object?>{'type': 'array'},
      'height': <String, Object?>{'type': 'number'},
    },
    'required': <Object?>['component'],
  }),
  builder: (context, node, props, buildChild) {
    final spec = MapCardSpec.of(props);
    if (spec.isEmpty) return const SizedBox.shrink();
    return BotMapCard(spec: spec);
  },
);

/// A map in a bot's card: one finger scrolls the chat past it, two fingers move and zoom it, and
/// the corner button opens it full screen.
class BotMapCard extends StatefulWidget {
  const BotMapCard({
    super.key,
    required this.spec,
    this.mapTilerKey = kMapTilerKey,
    this.tileProvider,
  });

  final MapCardSpec spec;
  final String mapTilerKey;
  final TileProvider? tileProvider;

  @override
  State<BotMapCard> createState() => _BotMapCardState();
}

class _BotMapCardState extends State<BotMapCard> {
  final ValueNotifier<bool> _osmFallback = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _osmFallback.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.tile),
      child: SizedBox(
        height: widget.spec.height,
        child: Stack(
          children: [
            Positioned.fill(
              child: _MapView(
                spec: widget.spec,
                flags:
                    InteractiveFlag.pinchZoom |
                    InteractiveFlag.pinchMove |
                    InteractiveFlag.doubleTapZoom |
                    InteractiveFlag.scrollWheelZoom,
                mapTilerKey: widget.mapTilerKey,
                tileProvider: widget.tileProvider,
                osmFallback: _osmFallback,
              ),
            ),
            Positioned(
              top: AppSpace.xs,
              right: AppSpace.xs,
              child: IconButton.filledTonal(
                key: const Key('mapExpand'),
                tooltip: l10n.mapFullScreen,
                icon: const Icon(LucideIcons.maximize2, size: 18),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    fullscreenDialog: true,
                    builder: (context) => Scaffold(
                      appBar: AppBar(title: Text(l10n.mapTitle)),
                      body: _MapView(
                        spec: widget.spec,
                        flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                        mapTilerKey: widget.mapTilerKey,
                        tileProvider: widget.tileProvider,
                        osmFallback: _osmFallback,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapView extends StatelessWidget {
  const _MapView({
    required this.spec,
    required this.flags,
    required this.mapTilerKey,
    required this.tileProvider,
    required this.osmFallback,
  });

  final MapCardSpec spec;
  final int flags;
  final String mapTilerKey;
  final TileProvider? tileProvider;
  final ValueNotifier<bool> osmFallback;

  void _handleMapTilerError(TileImage tile, Object error, StackTrace? _) {
    // A single missing tile shouldn't abandon MapTiler; 401/403/429/5xx or
    // connection failures trigger the OpenStreetMap fallback.
    if (error is NetworkImageLoadException && error.statusCode == 404) return;
    if (osmFallback.value) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!osmFallback.value) osmFallback.value = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final points = spec.points;
    // No center given: fit the pins and the route, or sit on the one pin.
    final fit = spec.center == null && points.length > 1
        ? CameraFit.coordinates(
            coordinates: points,
            padding: const EdgeInsets.all(36),
            maxZoom: 16,
          )
        : null;
    return ValueListenableBuilder<bool>(
      valueListenable: osmFallback,
      builder: (context, useOsmFallback, _) {
        final useMapTiler = mapTilerKey.isNotEmpty && !useOsmFallback;
        return FlutterMap(
          options: MapOptions(
            initialCenter:
                spec.center ??
                (points.isNotEmpty ? points.first : const LatLng(0, 0)),
            initialZoom: spec.zoom,
            initialCameraFit: fit,
            interactionOptions: InteractionOptions(flags: flags),
          ),
          children: [
            TileLayer(
              key: ValueKey(useMapTiler),
              urlTemplate: useMapTiler
                  ? 'https://api.maptiler.com/maps/${dark ? 'streets-v2-dark' : 'streets-v2'}/256/{z}/{x}/{y}{r}.png?key=$mapTilerKey'
                  : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              retinaMode: useMapTiler && RetinaMode.isHighDensity(context),
              userAgentPackageName: 'ai.casama.app',
              maxZoom: 19,
              tileProvider: tileProvider,
              errorTileCallback: useMapTiler ? _handleMapTilerError : null,
            ),
            if (spec.path.length > 1)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: spec.path,
                    strokeWidth: 4,
                    color: scheme.primary,
                  ),
                ],
              ),
            if (spec.markers.isNotEmpty)
              MarkerLayer(
                markers: [
                  for (final m in spec.markers)
                    Marker(
                      point: m.point,
                      width: 160,
                      height: 64,
                      alignment: Alignment.topCenter,
                      child: _Pin(label: m.label),
                    ),
                ],
              ),
            RichAttributionWidget(
              alignment: AttributionAlignment.bottomLeft,
              showFlutterMapAttribution: false,
              attributions: [
                if (useMapTiler)
                  TextSourceAttribution(
                    'MapTiler',
                    onTap: () => openWebLink(
                      Uri.parse('https://www.maptiler.com/copyright/'),
                    ),
                  ),
                TextSourceAttribution(
                  'OpenStreetMap contributors',
                  onTap: () => openWebLink(
                    Uri.parse('https://www.openstreetmap.org/copyright'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// A pin with its label above it; the pin's point is at the bottom of the marker box.
class _Pin extends StatelessWidget {
  const _Pin({this.label});
  final String? label;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (label != null && label!.trim().isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(AppRadius.icon),
              boxShadow: const [
                BoxShadow(blurRadius: 4, color: Color(0x33000000)),
              ],
            ),
            child: Text(
              label!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.labelMedium?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        Icon(Icons.location_on, size: 32, color: scheme.primary),
      ],
    );
  }
}
