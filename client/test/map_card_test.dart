// A bot's Map card (D-310): the A2UI Map component shows a native map with its pins, and opens
// full screen. Tiles aren't loaded in tests; the card and its markers are what's checked.
import 'dart:async';

import 'package:casama/features/chat/chat_screen.dart';
import 'package:casama/features/chat/widgets/bot_ui_map.dart';
import 'package:casama/l10n/generated/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
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
  _FallbackTestTileProvider({required this.mapTilerStatusCode});
  final int mapTilerStatusCode;
  final List<String> requestedUrls = [];

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    final url = getTileUrl(coordinates, options);
    requestedUrls.add(url);
    if (url.contains('api.maptiler.com')) {
      return _ErrorImageProvider(
        NetworkImageLoadException(
          statusCode: mapTilerStatusCode,
          uri: Uri.parse(url),
        ),
      );
    }
    return MemoryImage(TileProvider.transparentImage);
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

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

  testWidgets(
    'stays on MapTiler when a single tile returns 404',
    (tester) async {
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
    },
  );
}
