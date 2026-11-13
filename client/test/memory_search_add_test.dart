// Improve (app) 3: search within a bot's memory, and add a memory by hand.
import 'package:casama_app/features/memory/memory_screen.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

Memory _m(String id, String content) => Memory(
  id: id,
  kind: MemoryKindEnum.fact,
  content: content,
  importance: 0.5,
  pinned: false,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

void main() {
  testWidgets('typing filters the memories by every word', (tester) async {
    await setSize(tester, const Size(700, 1200));
    final backend = FakeBackend()
      ..extraMemories.addAll([
        _m('m2', 'Fiscal year starts in April'),
        _m('m3', 'Prefers short weekly reports'),
      ]);
    await tester.pumpWidget(harness(backend, const MemoryScreen(botId: botId)));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('memory-m2')), findsOneWidget);
    expect(find.byKey(const Key('memory-m3')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('memorySearch')),
      'april fiscal',
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('memory-m2')), findsOneWidget);
    expect(find.byKey(const Key('memory-m3')), findsNothing);
    expect(find.byKey(const Key('memory-mem1')), findsNothing);

    await tester.enterText(find.byKey(const Key('memorySearch')), 'zebra');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('noMemoriesMatch')), findsOneWidget);

    await tester.tap(find.byKey(const Key('clearMemorySearch')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('memory-m3')), findsOneWidget);
  });

  testWidgets('add a preference by hand', (tester) async {
    await setSize(tester, const Size(700, 1200));
    final backend = FakeBackend();
    await tester.pumpWidget(harness(backend, const MemoryScreen(botId: botId)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('addMemory')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('newMemoryKind')),
        matching: find.text('Preference'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('newMemoryText')),
      'Keep summaries short',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('saveNewMemory')));
    await tester.pumpAndSettle();
    expect(backend.addedMemories, [('preference', 'Keep summaries short')]);
    expect(find.text('Keep summaries short'), findsOneWidget);
  });

  test('memoryMatches ignores case and word order', () {
    final m = _m('x', 'Our fiscal year starts in April');
    expect(memoryMatches(m, 'APRIL fiscal'), isTrue);
    expect(memoryMatches(m, 'april may'), isFalse);
    expect(memoryMatches(m, '   '), isTrue);
  });
}
