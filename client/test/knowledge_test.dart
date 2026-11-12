import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama_app/features/bots/knowledge_screen.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

void main() {
  testWidgets('add files and a website as knowledge, resync and delete', (tester) async {
    await setSize(tester, const Size(900, 1400));
    final backend = FakeBackend();
    await tester.pumpWidget(harness(
      backend,
      KnowledgeScreen(botId: botId, pickFiles: () async => [('returns.md', Uint8List.fromList('# Returns'.codeUnits))]),
    ));
    await tester.pumpAndSettle();
    expect(find.text('No knowledge yet'), findsOneWidget);

    await tester.tap(find.byKey(const Key('addKnowledge')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pickKnowledgeFiles')));
    await tester.pumpAndSettle();
    expect(find.text('returns.md · 1 KB'), findsOneWidget);
    await tester.tap(find.byKey(const Key('saveKnowledge')));
    await tester.pumpAndSettle();
    expect(backend.addedKnowledge!.files!.single.name, 'returns.md');
    expect(backend.addedKnowledge!.botId, botId);
    expect(find.text('returns.md'), findsOneWidget);

    await tester.tap(find.byKey(const Key('addKnowledge')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Website'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('knowledgeUrl')), 'https://help.example.com');
    await tester.enterText(find.byKey(const Key('knowledgeName')), 'Help site');
    await tester.pump();
    await tester.tap(find.byKey(const Key('saveKnowledge')));
    await tester.pumpAndSettle();
    expect(backend.addedKnowledge!.url, 'https://help.example.com');
    expect(find.textContaining('3 documents, 12 passages'), findsOneWidget);

    await tester.tap(find.byKey(const Key('resync-ks-2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('deleteKnowledge-ks-1')));
    await tester.pumpAndSettle();
    expect(backend.knowledgeActions, ['sync:ks-2', 'delete:ks-1']);
    expect(find.text('returns.md'), findsNothing);
  });
}
