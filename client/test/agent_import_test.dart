import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kasama_app/core/providers.dart';
import 'package:kasama_app/features/bots/agent_import.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

void main() {
  testWidgets('import an agent: pick a ZIP, review and untick, then import with its files', (tester) async {
    await setSize(tester, const Size(900, 1800));
    final backend = FakeBackend();
    await tester.pumpWidget(
      harness(
        backend,
        Consumer(
          builder: (context, ref, _) {
            ref.watch(currentOrgProvider);
            return Scaffold(
              body: TextButton(
                onPressed: () => importAgentFolder(context, ref, pickZip: () async => Uint8List.fromList([1, 2, 3])),
                child: const Text('go'),
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('importAgentZip')));
    await tester.pumpAndSettle();
    expect(backend.importActions, ['zip:3']);
    expect(find.text('You are Juno.'), findsOneWidget);
    expect(find.textContaining('ran once at a set time'), findsOneWidget);
    expect(find.textContaining('.env (secrets)'), findsOneWidget);

    await tester.tap(find.byKey(const Key('importMemory-1')));
    await tester.enterText(find.byKey(const Key('agentImportName')), 'Juno Two');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('agentImportGo')));
    await tester.pumpAndSettle();
    final t = backend.importedTemplate!;
    expect(t.name, 'Juno Two');
    expect(t.memories!.map((m) => m.content), ['Prefers mornings']);
    expect(t.skills!.single.name, 'triage');
    expect(t.routines!.single.scheduleCron, '0 7 * * *');
    expect(backend.importActions.last, 'files:imp-1:bot-new');
  });

  testWidgets('memory from ChatGPT or Claude: copy the prompt, paste the answer, keep some', (tester) async {
    await setSize(tester, const Size(900, 1400));
    final backend = FakeBackend();
    await tester.pumpWidget(
      harness(
        backend,
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) => const MemoryImportSheet(botId: botId),
              ),
              child: const Text('go'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    expect(find.text('FACT: … PREFERENCE: …'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('memoryAnswer')), 'FACT: Has a dog\nPREFERENCE: Metric units');
    await tester.pump();
    await tester.tap(find.byKey(const Key('memoryImportSubmit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('memoryItem-0')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('memoryImportSubmit')));
    await tester.pumpAndSettle();
    expect(backend.savedMemories.map((m) => m.content), ['Metric units']);
  });
}
