import 'dart:convert';

import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:material_ui/material_ui.dart';

/// Google Map Tiles API key for map cards (D-444). Official builds carry it from the gitignored
/// `client/config/maps.json`; builds without one start on MapTiler, then OpenStreetMap.
const kGoogleMapsKey = String.fromEnvironment('CASAMA_GOOGLE_MAPS_KEY');

/// MapTiler key for map cards (D-310, D-428); the second source when Google is out or unset.
const kMapTilerKey = String.fromEnvironment('CASAMA_MAPTILER_KEY');

/// HERE key for map cards (D-444); the third source, after MapTiler. HERE has no hard spending cap
/// (only alerts), so official builds leave it empty unless a usage guard is in place.
const kHereMapsKey = String.fromEnvironment('CASAMA_HERE_MAPS_KEY');

/// Where a map card's tiles come from, in the order they're tried (D-444).
enum MapTileSource { google, mapTiler, here, osm }

/// The first source to try, given which keys a build carries and how far this app session has
/// fallen back (`skip` is the index of the first source not yet given up on).
MapTileSource mapTileSourceFor({
  required String googleKey,
  required String mapTilerKey,
  String hereKey = '',
  required int skip,
}) {
  for (final s in MapTileSource.values) {
    if (s.index < skip) continue;
    if (s == MapTileSource.google && googleKey.isEmpty) continue;
    if (s == MapTileSource.mapTiler && mapTilerKey.isEmpty) continue;
    if (s == MapTileSource.here && hereKey.isEmpty) continue;
    return s;
  }
  return MapTileSource.osm;
}

/// A Google 2D tiles session: every tile request carries its token.
class GoogleTileSession {
  const GoogleTileSession({required this.token, required this.expires});
  final String token;
  final DateTime expires;
}

/// Talks to Google's Map Tiles API: creates sessions (one per light/dark style, reused until close
/// to expiry, as Google asks) and reads the data credit line for what's on screen.
class GoogleTilesClient {
  GoogleTilesClient({required this.apiKey, http.Client? client})
    : _client = client ?? http.Client();

  final String apiKey;
  final http.Client _client;
  final Map<bool, Future<GoogleTileSession?>> _sessions = {};
  final Map<String, String> _credits = {};

  static const _base = 'https://tile.googleapis.com';

  /// The tile URL template for flutter_map.
  String urlTemplate(GoogleTileSession s) =>
      '$_base/v1/2dtiles/{z}/{x}/{y}?session=${s.token}&key=$apiKey';

  /// A live session for the light or dark style; null when Google refuses (bad key, quota, outage),
  /// which moves the card on to the next source.
  Future<GoogleTileSession?> session({required bool dark}) {
    final cached = _sessions[dark];
    if (cached != null) {
      return cached.then((s) {
        if (s != null &&
            s.expires.isAfter(DateTime.now().add(const Duration(hours: 1)))) {
          return s;
        }
        _sessions.remove(dark);
        return session(dark: dark);
      });
    }
    final created = _create(dark);
    _sessions[dark] = created;
    // A failed create isn't cached, so a later card (after the session fallback is reset) retries.
    created.then((s) {
      if (s == null && identical(_sessions[dark], created)) {
        _sessions.remove(dark);
      }
    });
    return created;
  }

  Future<GoogleTileSession?> _create(bool dark) async {
    try {
      final res = await _client
          .post(
            Uri.parse('$_base/v1/createSession?key=$apiKey'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'mapType': 'roadmap',
              'language': 'en-US',
              'region': 'US',
              // 512px tiles with labels sized for a 256-point tile: sharp on dense screens, billed
              // the same as plain tiles.
              'scale': 'scaleFactor2x',
              'highDpi': true,
              if (dark) 'styles': googleDarkStyle,
            }),
          )
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;
      final body = jsonDecode(res.body);
      if (body is! Map) return null;
      final token = body['session'];
      if (token is! String || token.isEmpty) return null;
      final expiry = int.tryParse('${body['expiry']}');
      return GoogleTileSession(
        token: token,
        expires: expiry == null
            ? DateTime.now().add(const Duration(days: 1))
            : DateTime.fromMillisecondsSinceEpoch(expiry * 1000),
      );
    } catch (_) {
      return null;
    }
  }

  /// Google's data credit for the area on screen ("Map data ©2026 Google"), which changes with
  /// the view. Null when it can't be read; the card then shows a plain one.
  Future<String?> credit(
    GoogleTileSession s,
    LatLngBounds bounds,
    int zoom,
  ) async {
    String r(double v) => v.toStringAsFixed(2);
    final key =
        '$zoom:${r(bounds.north)}:${r(bounds.south)}:${r(bounds.east)}:${r(bounds.west)}';
    if (_credits[key] case final c?) return c;
    try {
      final res = await _client
          .get(
            Uri.parse('$_base/tile/v1/viewport').replace(
              queryParameters: {
                'session': s.token,
                'key': apiKey,
                'zoom': '$zoom',
                'north': '${bounds.north.clamp(-90, 90)}',
                'south': '${bounds.south.clamp(-90, 90)}',
                'east': '${bounds.east.clamp(-180, 180)}',
                'west': '${bounds.west.clamp(-180, 180)}',
              },
            ),
          )
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;
      final body = jsonDecode(res.body);
      final c = body is Map ? body['copyright'] : null;
      if (c is! String || c.trim().isEmpty) return null;
      if (_credits.length > 200) _credits.clear();
      return _credits[key] = c.trim();
    } catch (_) {
      return null;
    }
  }
}

/// The app's one Google tiles client, or null when the build has no key.
final GoogleTilesClient? defaultGoogleTiles = kGoogleMapsKey.isEmpty
    ? null
    : GoogleTilesClient(apiKey: kGoogleMapsKey);

/// Google's credit on the map: the Google Maps logo bottom left (outlined, since it sits on the
/// map; 18 points high with the clear space Google asks for) and the data credit bottom right.
class GoogleMapsAttribution extends StatelessWidget {
  const GoogleMapsAttribution({super.key, required this.credit});
  final String? credit;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      children: [
        Positioned(
          left: 10,
          bottom: 5,
          child: Image.asset(
            dark
                ? 'assets/maps/google_maps_logo_dark.png'
                : 'assets/maps/google_maps_logo_light.png',
            height: 18,
            semanticLabel: 'Google Maps',
            excludeFromSemantics: false,
          ),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            color: scheme.surface.withValues(alpha: 0.75),
            child: Text(
              credit ?? 'Map data ©Google',
              key: const Key('googleMapCredit'),
              style: TextStyle(fontSize: 10, color: scheme.onSurface),
            ),
          ),
        ),
      ],
    );
  }
}

/// A dark roadmap for dark mode (Google has no built-in dark 2D style).
const googleDarkStyle = <Map<String, Object?>>[
  {
    'elementType': 'geometry',
    'stylers': [
      {'color': '#242f3e'},
    ],
  },
  {
    'elementType': 'labels.text.stroke',
    'stylers': [
      {'color': '#242f3e'},
    ],
  },
  {
    'elementType': 'labels.text.fill',
    'stylers': [
      {'color': '#a59a8a'},
    ],
  },
  {
    'featureType': 'administrative.locality',
    'elementType': 'labels.text.fill',
    'stylers': [
      {'color': '#d59563'},
    ],
  },
  {
    'featureType': 'poi',
    'elementType': 'labels.text.fill',
    'stylers': [
      {'color': '#d59563'},
    ],
  },
  {
    'featureType': 'poi.park',
    'elementType': 'geometry',
    'stylers': [
      {'color': '#263c3f'},
    ],
  },
  {
    'featureType': 'poi.park',
    'elementType': 'labels.text.fill',
    'stylers': [
      {'color': '#6b9a76'},
    ],
  },
  {
    'featureType': 'road',
    'elementType': 'geometry',
    'stylers': [
      {'color': '#38414e'},
    ],
  },
  {
    'featureType': 'road',
    'elementType': 'geometry.stroke',
    'stylers': [
      {'color': '#212a37'},
    ],
  },
  {
    'featureType': 'road',
    'elementType': 'labels.text.fill',
    'stylers': [
      {'color': '#9ca5b3'},
    ],
  },
  {
    'featureType': 'road.highway',
    'elementType': 'geometry',
    'stylers': [
      {'color': '#746855'},
    ],
  },
  {
    'featureType': 'road.highway',
    'elementType': 'geometry.stroke',
    'stylers': [
      {'color': '#1f2835'},
    ],
  },
  {
    'featureType': 'road.highway',
    'elementType': 'labels.text.fill',
    'stylers': [
      {'color': '#f3d19c'},
    ],
  },
  {
    'featureType': 'transit',
    'elementType': 'geometry',
    'stylers': [
      {'color': '#2f3948'},
    ],
  },
  {
    'featureType': 'water',
    'elementType': 'geometry',
    'stylers': [
      {'color': '#17263c'},
    ],
  },
  {
    'featureType': 'water',
    'elementType': 'labels.text.fill',
    'stylers': [
      {'color': '#515c6d'},
    ],
  },
];
