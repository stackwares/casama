import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama_app/features/workspaces/workspace_files.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

void main() {
  testWidgets('export, import after a preview, and set up git sync with its webhook', (tester) async {
    await setSize(tester, const Size(900, 1400));
    final backend = FakeBackend();
    Uint8List? saved;
    await tester.pumpWidget(harness(
      backend,
      Scaffold(
        body: SingleChildScrollView(
          child: WorkspaceFilesSection(orgId: orgId, pickZip: () async => Uint8List.fromList([1]), saveZip: (b) async => saved = b),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('exportFiles')));
    await tester.pumpAndSettle();
    expect(saved, [80, 75]);

    await tester.tap(find.byKey(const Key('importFiles')));
    await tester.pumpAndSettle();
    expect(find.text('1 new, 1 changed, 2 unchanged'), findsOneWidget);
    expect(find.text('ada/routines/bad.md: bad cron'), findsOneWidget);
    await tester.tap(find.byKey(const Key('applyImport')));
    await tester.pumpAndSettle();
    expect(backend.fileActions, ['export', 'dry', 'import']);

    await tester.tap(find.byKey(const Key('gitSync')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('gitRepo')), 'acme/casama-config');
    await tester.enterText(find.byKey(const Key('gitPath')), 'casama');
    await tester.pump();
    await tester.tap(find.byKey(const Key('saveGitSync')));
    await tester.pumpAndSettle();
    expect(backend.fileActions.last, 'git:acme/casama-config:main:casama');
    expect(find.textContaining('sec-1'), findsOneWidget);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.textContaining('acme/casama-config@main/casama'), findsOneWidget);
    await tester.tap(find.byKey(const Key('gitSyncNow')));
    await tester.pumpAndSettle();
    expect(backend.fileActions.last, 'run');
  });
}
