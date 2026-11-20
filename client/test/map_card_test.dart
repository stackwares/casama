// A bot's Map card (D-310): the A2UI Map component shows a native map with its pins, and opens
// full screen. Tiles aren't loaded in tests; the card and its markers are what's checked.
import 'dart:async';

import 'package:casama/features/chat/chat_screen.dart';
import 'package:casama/features/chat/widgets/bot_ui_map.dart';
import 'package:casama/features/chat/widgets/map_tiles.dart';
import 'package:casama/l10n/generated/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

class _ErrorImageCompleter extends ImageStreamCompleter {
  _ErrorImageCompleter(Object error) {
    scheduleMicrotask(
      () => reportError(exception: error, stack: StackTrace.current),
    );
  }
}

class _ErrorImageProvider extends ImageProvider<_ErrorImageProvider> {
  const _ErrorImageProvider(this.error);
  final Object error;

  @override
  Future<_ErrorImageProvider> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(
    _ErrorImageProvider key,
    ImageDecoderCallback decode,
  ) => _ErrorImageCompleter(error);
}

class _FallbackTestTileProvider extends TileProvider {
  _FallbackTestTileProvider({
    int? mapTilerStatusCode,
    Map<String, int> failures = const {},
  }) : failures = {
         ...failures,
         'api.maptiler.com': ?mapTilerStatusCode,
       };

  /// Host fragment → the status every tile from it fails with.
  final Map<String, int> failures;
  final List<String> requestedUrls = [];

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    final url = getTileUrl(coordinates, options);
    requestedUrls.add(url);
    for (final f in failures.entries) {
      if (url.contains(f.key)) {
        return _ErrorImageProvider(
          NetworkImageLoadException(statusCode: f.value, uri: Uri.parse(url)),
        );
      }
    }
    return MemoryImage(TileProvider.transparentImage);
  }
}

/// A Google tiles client whose createSession and viewport answers come from [sessionStatus].
GoogleTilesClient _google({int sessionStatus = 200, List<Uri>? calls}) =>
    GoogleTilesClient(
      apiKey: 'g-key',
      client: MockClient((req) async {
        calls?.add(req.url);
        if (req.url.path.endsWith('/createSession')) {
          return sessionStatus == 200
              ? http.Response(
                  '{"session":"tok1","expiry":"${DateTime.now().add(const Duration(days: 14)).millisecondsSinceEpoch ~/ 1000}","tileWidth":512}',
                  200,
                )
              : http.Response('{"error":{"message":"quota"}}', sessionStatus);
        }
        if (req.url.path.endsWith('/viewport')) {
          return http.Response('{"copyright":"Map data ©2026 Google"}', 200);
        }
        return http.Response('', 404);
      }),
    );

Widget _cardApp(Widget card) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: card),
);

const _sf = MapCardSpec(
  center: LatLng(37.7749, -122.4194),
  zoom: 12,
  markers: [],
  path: [],
  height: 220,
);

String _layerUrl(WidgetTester tester) =>
    tester.widget<TileLayer>(find.byType(TileLayer)).urlTemplate!;

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    resetMapTileFallbackForTest();
  });

  tearDown(resetMapTileFallbackForTest);

  List<Map<String, Object?>> card(List<Map<String, Object?>> components) => [
    {
      'version': '1.0',
      'createSurface': {
        'surfaceId': 'ui_map',
        'catalogId':
            'https://a2ui.org/specification/v1_0/catalogs/basic/catalog.json',
      },
    },
    {
      'version': '1.0',
      'updateComponents': {'surfaceId': 'ui_map', 'components': components},
    },
  ];

  Future<FakeBackend> showCard(
    WidgetTester tester,
    List<Map<String, Object?>> components,
  ) async {
    await setSize(tester, const Size(500, 900));
    final backend = FakeBackend();
    await tester.pumpWidget(
      harness(backend, const ChatScreen(botId: botId, conversationId: convId)),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('messageInput')),
      'show me SF on a map',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('sendButton')));
    await tester.pump();
    backend.runEventsController.add(
      ev(1, 'ui.shown', {'surface_id': 'ui_map', 'messages': card(components)}),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    return backend;
  }

  testWidgets(
    'a Map component shows a map with its labelled pins fitted in view, and opens full screen',
    (tester) async {
      await showCard(tester, [
        {
          'id': 'root',
          'component': 'Column',
          'children': ['title', 'map'],
        },
        {'id': 'title', 'component': 'Text', 'text': '## San Francisco'},
        {
          'id': 'map',
          'component': 'Map',
          'markers': [
            {'lat': 37.8199, 'lng': -122.4783, 'label': 'Golden Gate Bridge'},
            {'lat': 37.8080, 'lng': -122.4177, 'label': 'Fisherman’s Wharf'},
          ],
        },
      ]);
      expect(find.text('San Francisco'), findsOneWidget);
      expect(find.byType(BotMapCard), findsOneWidget);
      expect(find.byType(FlutterMap), findsOneWidget);
      expect(find.text('Golden Gate Bridge'), findsOneWidget);
      await tester.tap(find.byKey(const Key('mapExpand')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(
        find.descendant(
          of: find.byType(Scaffold).last,
          matching: find.byType(FlutterMap),
        ),
        findsOneWidget,
      );
      expect(find.text('Map'), findsOneWidget);
    },
  );

  testWidgets(
    'a Map with nothing to show draws nothing rather than a blank map',
    (tester) async {
      await showCard(tester, [
        {
          'id': 'root',
          'component': 'Column',
          'children': ['t', 'map'],
        },
        {'id': 't', 'component': 'Text', 'text': 'Here'},
        {
          'id': 'map',
          'component': 'Map',
          'markers': [
            {'lat': 'x', 'lng': 1},
          ],
        },
      ]);
      expect(find.text('Here'), findsOneWidget);
      expect(find.byType(FlutterMap), findsNothing);
    },
  );

  testWidgets(
    'falls back to OpenStreetMap when MapTiler fails with 429 and keeps fallback full screen',
    (tester) async {
      await setSize(tester, const Size(400, 600));
      final tiles = _FallbackTestTileProvider(mapTilerStatusCode: 429);
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: BotMapCard(
              spec: const MapCardSpec(
                center: LatLng(37.7749, -122.4194),
                zoom: 12,
                markers: [],
                path: [],
                height: 220,
              ),
              mapTilerKey: 'test-key',
              tileProvider: tiles,
            ),
          ),
        ),
      );

      // Starts on MapTiler and requests MapTiler tiles first.
      expect(
        tester.widget<TileLayer>(find.byType(TileLayer)).urlTemplate,
        contains('api.maptiler.com'),
      );
      await tester.pump();
      await tester.pump();

      // After MapTiler returns 429, switches to OpenStreetMap with retina off.
      final fallbackLayer = tester.widget<TileLayer>(find.byType(TileLayer));
      expect(fallbackLayer.urlTemplate, contains('tile.openstreetmap.org'));
      expect(fallbackLayer.resolvedRetinaMode, RetinaMode.disabled);
      expect(
        tiles.requestedUrls.any((u) => u.contains('api.maptiler.com')),
        isTrue,
      );
      expect(
        tiles.requestedUrls.any((u) => u.contains('tile.openstreetmap.org')),
        isTrue,
      );

      // Opening full screen keeps the OpenStreetMap fallback active.
      await tester.tap(find.byKey(const Key('mapExpand')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      final fullscreenLayer = tester.widget<TileLayer>(
        find.descendant(
          of: find.byType(Scaffold).last,
          matching: find.byType(TileLayer),
        ),
      );
      expect(fullscreenLayer.urlTemplate, contains('tile.openstreetmap.org'));
    },
  );

  testWidgets('stays on MapTiler when a single tile returns 404', (
    tester,
  ) async {
    await setSize(tester, const Size(400, 600));
    final tiles = _FallbackTestTileProvider(mapTilerStatusCode: 404);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BotMapCard(
            spec: const MapCardSpec(
              center: LatLng(37.7749, -122.4194),
              zoom: 12,
              markers: [],
              path: [],
              height: 220,
            ),
            mapTilerKey: 'test-key',
            tileProvider: tiles,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(
      tester.widget<TileLayer>(find.byType(TileLayer)).urlTemplate,
      contains('api.maptiler.com'),
    );
  });

  testWidgets(
    'keeps OpenStreetMap across newly mounted map cards for the rest of the session',
    (tester) async {
      await setSize(tester, const Size(400, 600));
      final firstTiles = _FallbackTestTileProvider(mapTilerStatusCode: 429);
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: BotMapCard(
              spec: const MapCardSpec(
                center: LatLng(37.7749, -122.4194),
                zoom: 12,
                markers: [],
                path: [],
                height: 220,
              ),
              mapTilerKey: 'test-key',
              tileProvider: firstTiles,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(
        tester.widget<TileLayer>(find.byType(TileLayer)).urlTemplate,
        contains('tile.openstreetmap.org'),
      );

      // Mount a brand-new BotMapCard in the same session with its own tile provider.
      final secondTiles = _FallbackTestTileProvider(mapTilerStatusCode: 429);
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: BotMapCard(
              key: const Key('secondMapCard'),
              spec: const MapCardSpec(
                center: LatLng(35.6762, 139.6503),
                zoom: 11,
                markers: [],
                path: [],
                height: 220,
              ),
              mapTilerKey: 'test-key',
              tileProvider: secondTiles,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(
        tester.widget<TileLayer>(find.byType(TileLayer)).urlTemplate,
        contains('tile.openstreetmap.org'),
      );
      expect(
        secondTiles.requestedUrls.any((u) => u.contains('api.maptiler.com')),
        isFalse,
      );
      expect(
        secondTiles.requestedUrls.any(
          (u) => u.contains('tile.openstreetmap.org'),
        ),
        isTrue,
      );
    },
  );

  testWidgets(
    'starts on Google with its logo and the data credit for the view (D-444)',
    (tester) async {
      await setSize(tester, const Size(400, 600));
      final calls = <Uri>[];
      final tiles = _FallbackTestTileProvider();
      await tester.runAsync(() async {
        await tester.pumpWidget(
          _cardApp(
            BotMapCard(
              spec: _sf,
              mapTilerKey: 'test-key',
              googleTiles: _google(calls: calls),
              tileProvider: tiles,
            ),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await tester.pump();
        // The credit is read 400 ms after the map settles.
        await Future<void>.delayed(const Duration(milliseconds: 600));
      });
      await tester.pump();
      expect(_layerUrl(tester), contains('tile.googleapis.com/v1/2dtiles'));
      expect(_layerUrl(tester), contains('session=tok1'));
      expect(find.bySemanticsLabel('Google Maps'), findsOneWidget);
      expect(find.text('Map data ©2026 Google'), findsOneWidget);
      expect(find.text('OpenStreetMap contributors'), findsNothing);
      expect(calls.where((u) => u.path.endsWith('/createSession')), hasLength(1));
    },
  );

  testWidgets(
    'Google tiles failing with 429 move every card to MapTiler for the session',
    (tester) async {
      await setSize(tester, const Size(400, 600));
      final tiles = _FallbackTestTileProvider(
        failures: {'tile.googleapis.com': 429},
      );
      await tester.runAsync(() async {
        await tester.pumpWidget(
          _cardApp(
            BotMapCard(
              spec: _sf,
              mapTilerKey: 'test-key',
              googleTiles: _google(),
              tileProvider: tiles,
            ),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await tester.pump();
        await tester.pump();
        await tester.pump();
      });
      expect(
        tiles.requestedUrls.any((u) => u.contains('tile.googleapis.com')),
        isTrue,
      );
      expect(_layerUrl(tester), contains('api.maptiler.com'));
    },
  );

  testWidgets('a refused Google session goes straight to MapTiler', (
    tester,
  ) async {
    await setSize(tester, const Size(400, 600));
    final tiles = _FallbackTestTileProvider();
    await tester.runAsync(() async {
      await tester.pumpWidget(
        _cardApp(
          BotMapCard(
            spec: _sf,
            mapTilerKey: 'test-key',
            googleTiles: _google(sessionStatus: 429),
            tileProvider: tiles,
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await tester.pump();
      await tester.pump();
    });
    expect(_layerUrl(tester), contains('api.maptiler.com'));
    expect(
      tiles.requestedUrls.any((u) => u.contains('tile.googleapis.com')),
      isFalse,
    );
  });

  testWidgets(
    'MapTiler failing moves to HERE, and HERE failing moves to OpenStreetMap',
    (tester) async {
      await setSize(tester, const Size(400, 600));
      final tiles = _FallbackTestTileProvider(
        failures: {'api.maptiler.com': 403, 'maps.hereapi.com': 429},
      );
      await tester.pumpWidget(
        _cardApp(
          BotMapCard(
            spec: _sf,
            mapTilerKey: 'test-key',
            hereKey: 'here-key',
            useGoogle: false,
            tileProvider: tiles,
          ),
        ),
      );
      expect(_layerUrl(tester), contains('api.maptiler.com'));
      for (var i = 0; i < 6; i++) {
        await tester.pump();
      }
      expect(
        tiles.requestedUrls.any((u) => u.contains('maps.hereapi.com')),
        isTrue,
      );
      expect(_layerUrl(tester), contains('tile.openstreetmap.org'));
    },
  );

  testWidgets('without a HERE key, MapTiler failing goes to OpenStreetMap', (
    tester,
  ) async {
    await setSize(tester, const Size(400, 600));
    final tiles = _FallbackTestTileProvider(mapTilerStatusCode: 429);
    await tester.pumpWidget(
      _cardApp(
        BotMapCard(
          spec: _sf,
          mapTilerKey: 'test-key',
          useGoogle: false,
          tileProvider: tiles,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(_layerUrl(tester), contains('tile.openstreetmap.org'));
    expect(
      tiles.requestedUrls.any((u) => u.contains('maps.hereapi.com')),
      isFalse,
    );
  });

  test('the source order is Google, MapTiler, HERE, OpenStreetMap', () {
    MapTileSource pick(int skip, {String g = 'g', String m = 'm', String h = 'h'}) =>
        mapTileSourceFor(googleKey: g, mapTilerKey: m, hereKey: h, skip: skip);
    expect(pick(0), MapTileSource.google);
    expect(pick(1), MapTileSource.mapTiler);
    expect(pick(2), MapTileSource.here);
    expect(pick(3), MapTileSource.osm);
    expect(pick(0, g: ''), MapTileSource.mapTiler);
    expect(pick(0, g: '', m: ''), MapTileSource.here);
    expect(pick(0, g: '', m: '', h: ''), MapTileSource.osm);
    expect(pick(1, m: '', h: ''), MapTileSource.osm);
  });
}
