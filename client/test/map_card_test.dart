// A bot's Map card (D-310): the A2UI Map component shows a native map with its pins, and opens
// full screen. Tiles aren't loaded in tests; the card and its markers are what's checked.
import 'package:casama/features/chat/chat_screen.dart';
import 'package:casama/features/chat/widgets/bot_ui_map.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

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
}
