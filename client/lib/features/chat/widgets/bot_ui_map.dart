import 'dart:async';

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
import 'map_tiles.dart';

export 'map_tiles.dart' show kGoogleMapsKey, kHereMapsKey, kMapTilerKey, MapTileSource;

/// Tiles come from Google, then MapTiler, then HERE, then OpenStreetMap (D-444). Once a source fails in this
/// app session (quota 429, blocked key, outage), every map card skips it for the rest of the
/// session instead of retrying it on each new card. The value is the index in [MapTileSource] of
/// the first source not yet given up on.
final ValueNotifier<int> _sessionTileFallback = ValueNotifier<int>(0);

@visibleForTesting
void resetMapTileFallbackForTest() => _sessionTileFallback.value = 0;

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
class BotMapCard extends StatelessWidget {
  const BotMapCard({
    super.key,
    required this.spec,
    this.mapTilerKey = kMapTilerKey,
    this.hereKey = kHereMapsKey,
    this.googleTiles,
    this.useGoogle = true,
    this.tileProvider,
    this.tileFallback,
  });

  final MapCardSpec spec;
  final String mapTilerKey;
  final String hereKey;

  /// Google's tiles client; defaults to the app's own (null when the build has no Google key).
  final GoogleTilesClient? googleTiles;

  /// Tests that don't care about Google turn it off so the default client isn't used.
  final bool useGoogle;
  final TileProvider? tileProvider;
  final ValueNotifier<int>? tileFallback;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fallback = tileFallback ?? _sessionTileFallback;
    final google = useGoogle ? (googleTiles ?? defaultGoogleTiles) : null;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.tile),
      child: SizedBox(
        height: spec.height,
        child: Stack(
          children: [
            Positioned.fill(
              child: _MapView(
                spec: spec,
                flags:
                    InteractiveFlag.pinchZoom |
                    InteractiveFlag.pinchMove |
                    InteractiveFlag.doubleTapZoom |
                    InteractiveFlag.scrollWheelZoom,
                mapTilerKey: mapTilerKey,
                hereKey: hereKey,
                google: google,
                tileProvider: tileProvider,
                fallback: fallback,
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
                        spec: spec,
                        flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                        mapTilerKey: mapTilerKey,
                        hereKey: hereKey,
                        google: google,
                        tileProvider: tileProvider,
                        fallback: fallback,
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

class _MapView extends StatefulWidget {
  const _MapView({
    required this.spec,
    required this.flags,
    required this.mapTilerKey,
    required this.hereKey,
    required this.google,
    required this.tileProvider,
    required this.fallback,
  });

  final MapCardSpec spec;
  final int flags;
  final String mapTilerKey;
  final String hereKey;
  final GoogleTilesClient? google;
  final TileProvider? tileProvider;
  final ValueNotifier<int> fallback;

  @override
  State<_MapView> createState() => _MapViewState();
}

class _MapViewState extends State<_MapView> {
  /// Google's data credit for the current view, refreshed as the map moves.
  String? _googleCredit;
  Timer? _creditDebounce;
  String? _creditSession;
  final _controller = MapController();

  /// The Google session for the current theme, asked for once per theme, not on every rebuild.
  Future<GoogleTileSession?>? _session;
  bool? _sessionDark;

  Future<GoogleTileSession?> _sessionFor(GoogleTilesClient google, bool dark) {
    if (_session == null || _sessionDark != dark) {
      _sessionDark = dark;
      _session = google.session(dark: dark);
    }
    return _session!;
  }

  @override
  void dispose() {
    _creditDebounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  /// Gives up on [source] for the rest of the app session; the next card or rebuild uses the next
  /// source in line.
  void _giveUp(MapTileSource source) {
    final next = source.index + 1;
    if (widget.fallback.value >= next) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.fallback.value < next) widget.fallback.value = next;
    });
  }

  ErrorTileCallBack _tileError(MapTileSource source) =>
      (TileImage tile, Object error, StackTrace? _) {
        // A single missing tile shouldn't abandon a source; 401/403/429/5xx or connection
        // failures move to the next one.
        if (error is NetworkImageLoadException && error.statusCode == 404) return;
        _giveUp(source);
      };

  void _refreshCredit(GoogleTileSession session) {
    _creditDebounce?.cancel();
    _creditDebounce = Timer(const Duration(milliseconds: 400), () async {
      final google = widget.google;
      if (!mounted || google == null) return;
      final MapCamera camera;
      try {
        camera = _controller.camera;
      } catch (_) {
        return; // the map isn't on screen yet
      }
      final credit = await google.credit(
        session,
        camera.visibleBounds,
        camera.zoom.round(),
      );
      if (mounted && credit != null && credit != _googleCredit) {
        setState(() => _googleCredit = credit);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ValueListenableBuilder<int>(
      valueListenable: widget.fallback,
      builder: (context, skip, _) {
        final source = mapTileSourceFor(
          googleKey: widget.google == null ? '' : 'set',
          mapTilerKey: widget.mapTilerKey,
          hereKey: widget.hereKey,
          skip: skip,
        );
        if (source != MapTileSource.google) return _map(context, source, null);
        return FutureBuilder<GoogleTileSession?>(
          key: ValueKey(dark),
          future: _sessionFor(widget.google!, dark),
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              // No tiles yet: the pins and route draw on an empty map for a moment.
              return _map(context, source, null);
            }
            final session = snap.data;
            if (session == null) {
              _giveUp(MapTileSource.google);
              return _map(context, source, null);
            }
            return _map(context, source, session);
          },
        );
      },
    );
  }

  Widget _map(
    BuildContext context,
    MapTileSource source,
    GoogleTileSession? session,
  ) {
    final spec = widget.spec;
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
    final onGoogle = source == MapTileSource.google;
    // The session often arrives after the map is up, so ask for the first credit here.
    if (session != null && _creditSession != session.token) {
      _creditSession = session.token;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _refreshCredit(session),
      );
    }
    final onMapTiler = source == MapTileSource.mapTiler;
    final onHere = source == MapTileSource.here;
    return FlutterMap(
      mapController: _controller,
      options: MapOptions(
        initialCenter:
            spec.center ??
            (points.isNotEmpty ? points.first : const LatLng(0, 0)),
        initialZoom: spec.zoom,
        initialCameraFit: fit,
        interactionOptions: InteractionOptions(flags: widget.flags),
        onPositionChanged: session == null
            ? null
            : (_, _) => _refreshCredit(session),
      ),
      children: [
        if (!onGoogle || session != null)
          TileLayer(
            key: ValueKey('$source:${session?.token}'),
            urlTemplate: switch (source) {
              MapTileSource.google => widget.google!.urlTemplate(session!),
              MapTileSource.mapTiler =>
                'https://api.maptiler.com/maps/${dark ? 'streets-v2-dark' : 'streets-v2'}/256/{z}/{x}/{y}{r}.png?key=${widget.mapTilerKey}',
              // 512px tiles drawn at 256 points: sharp on dense screens, billed as one tile.
              MapTileSource.here =>
                'https://maps.hereapi.com/v3/base/mc/{z}/{x}/{y}/png8?style=${dark ? 'explore.night' : 'explore.day'}&size=512&ppi=400&apiKey=${widget.hereKey}',
              MapTileSource.osm => 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            },
            retinaMode: onMapTiler && RetinaMode.isHighDensity(context),
            userAgentPackageName: 'ai.casama.app',
            maxZoom: onGoogle ? 20 : 19,
            tileProvider: widget.tileProvider,
            errorTileCallback: source == MapTileSource.osm
                ? null
                : _tileError(source),
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
        if (onGoogle)
          GoogleMapsAttribution(credit: _googleCredit)
        else
          RichAttributionWidget(
            alignment: AttributionAlignment.bottomLeft,
            showFlutterMapAttribution: false,
            attributions: [
              if (onHere)
                TextSourceAttribution(
                  '© ${DateTime.now().year} HERE',
                  onTap: () => openWebLink(
                    Uri.parse('https://legal.here.com/en-gb/terms'),
                  ),
                ),
              if (onMapTiler)
                TextSourceAttribution(
                  'MapTiler',
                  onTap: () => openWebLink(
                    Uri.parse('https://www.maptiler.com/copyright/'),
                  ),
                ),
              if (!onHere)
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
