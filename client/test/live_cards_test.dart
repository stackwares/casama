// Live data cards and composed cards (docs/RICH-CARDS-PLAN.md): every card renders the shapes the
// server sends (fixtures written from the real providers) without errors or overflows, on a phone
// and a wide window; refresh goes through the API and swaps in the new data; Quiz answers.
import 'dart:convert';
import 'dart:io';

import 'package:casama/core/backend.dart';
import 'package:casama/features/chat/chat_screen.dart';
import 'package:casama/features/chat/widgets/cards/live_tools.dart' show convertUnit;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

Map<String, Object?> _load(String name) {
  final f = File('../packages/contracts/fixtures/$name');
  return Map<String, Object?>.from(jsonDecode(f.readAsStringSync()) as Map);
}

Map<String, Object?> _message(String id, List<Map<String, Object?>> components) => {
  'surfaceId': id,
  'messages': [
    {
      'version': '1.0',
      'createSurface': {'surfaceId': id, 'catalogId': 'https://a2ui.org/specification/v1_0/catalogs/basic/catalog.json'},
    },
    {
      'version': '1.0',
      'updateComponents': {'surfaceId': id, 'components': components},
    },
  ],
};

/// Fails with the full diagnostics (which widget overflowed, and where).
void _noErrors(WidgetTester tester) {
  final e = tester.takeException();
  if (e != null) fail(e is FlutterError ? e.toStringDeep() : '$e');
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  final live = _load('live-cards.json');
  final composed = _load('composed-cards.json');

  Future<FakeBackend> show(WidgetTester tester, List<Map<String, Object?>> components, {Size size = const Size(420, 1600)}) async {
    await setSize(tester, size);
    final m = _message('ui_live', components);
    final backend = FakeBackend()
      ..storedMessages = [
        ChatMessageView(
          id: 'msg-1',
          role: 'assistant',
          text: 'Here you go.',
          createdAt: DateTime(2026),
          ui: [UiPart(surfaceId: m['surfaceId']! as String, messages: m['messages']! as List<Object?>)],
        ),
      ];
    await tester.pumpWidget(harness(backend, const ChatScreen(botId: botId, conversationId: convId)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    return backend;
  }

  for (final size in const [Size(390, 2400), Size(1100, 2400)]) {
    for (final entry in {...live, ...composed}.entries) {
      testWidgets('${entry.key} renders at ${size.width.toInt()} wide', (tester) async {
        final card = Map<String, Object?>.from(entry.value! as Map);
        await show(tester, [
          {'id': 'root', ...card},
        ], size: size);
        _noErrors(tester);
        // The card drew something: its summary or its own title is on screen.
        expect(find.byKey(const Key('botUi-ui_live')), findsOneWidget);
        final box = tester.getSize(find.byKey(const Key('botUi-ui_live')));
        expect(box.height, greaterThan(60), reason: '${entry.key} drew nothing');
        // Leave clocks and countdowns ticking off the test.
        await tester.pumpWidget(const SizedBox());
      });
    }
  }

  testWidgets('a Dashboard lays several cards out', (tester) async {
    await show(tester, [
      {'id': 'root', 'component': 'Dashboard', 'title': 'Morning brief', 'children': ['w', 'q', 'c']},
      {'id': 'w', ...Map<String, Object?>.from(live['weather_now']! as Map)},
      {'id': 'q', ...Map<String, Object?>.from(live['quote_crypto']! as Map)},
      {'id': 'c', ...Map<String, Object?>.from(composed['countdown']! as Map)},
    ], size: const Size(1100, 2400));
    _noErrors(tester);
    expect(find.text('Morning brief'), findsOneWidget);
    expect(find.text('San Francisco'), findsWidgets);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a Carousel swipes between cards', (tester) async {
    await show(tester, [
      {'id': 'root', 'component': 'Carousel', 'children': ['a', 'b']},
      {'id': 'a', ...Map<String, Object?>.from(live['fx']! as Map)},
      {'id': 'b', ...Map<String, Object?>.from(live['quote_crypto']! as Map)},
    ]);
    _noErrors(tester);
    expect(find.text('Currency'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('refresh asks the API by id and shows the new numbers', (tester) async {
    final card = Map<String, Object?>.from(live['quote_crypto']! as Map);
    final liveBlock = Map<String, Object?>.from(card['live']! as Map)
      ..['ref'] = '11111111-1111-1111-1111-111111111111'
      ..['staleAfter'] = DateTime.now().add(const Duration(hours: 1)).toIso8601String();
    card['live'] = liveBlock;
    final backend = await show(tester, [
      {'id': 'root', ...card},
    ]);
    backend.onRefreshLiveCard = (id, view) => {
      'id': id,
      'card': {...card, 'price': 123456.0, 'live': liveBlock},
      'fetched_at': DateTime.now().toIso8601String(),
      'error': null,
      'pinned': false,
    };
    await tester.tap(find.byTooltip('Refresh').first);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(backend.liveCardActions, contains('refresh:11111111-1111-1111-1111-111111111111::true'));
    expect(find.textContaining('123,456'), findsWidgets);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a chart range is a view the API fills', (tester) async {
    final card = Map<String, Object?>.from(live['quote_stock']! as Map);
    card['live'] = {...Map<String, Object?>.from(card['live']! as Map), 'ref': '22222222-2222-2222-2222-222222222222', 'staleAfter': DateTime.now().add(const Duration(hours: 1)).toIso8601String()};
    final backend = await show(tester, [
      {'id': 'root', ...card},
    ]);
    backend.onRefreshLiveCard = (id, view) => {'id': id, 'card': card, 'fetched_at': DateTime.now().toIso8601String(), 'error': null, 'pinned': false};
    await tester.tap(find.text('1Y'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(backend.liveCardActions.last, startsWith('refresh:22222222-2222-2222-2222-222222222222:1Y'));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Quiz shows the right answer and tells the bot', (tester) async {
    final backend = await show(tester, [
      {'id': 'root', ...Map<String, Object?>.from(composed['quiz']! as Map)},
    ]);
    await tester.tap(find.text('Samar'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(backend.sentUiActions.last['name'], 'quiz.answer');
    expect((backend.sentUiActions.last['context']! as Map)['correct'], false);
    expect(find.textContaining('Luzon covers'), findsOneWidget);
  });

  test('units convert', () {
    expect(convertUnit(10, 'km', 'mi'), closeTo(6.2137, 0.001));
    expect(convertUnit(100, 'c', 'f'), closeTo(212, 0.001));
    expect(convertUnit(1, 'cup', 'ml'), closeTo(236.588, 0.01));
    expect(convertUnit(1, 'kg', 'km'), isNull);
  });
}
