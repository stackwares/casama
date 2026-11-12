import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama_app/core/backend.dart';
import 'package:casama_app/core/providers.dart';
import 'package:casama_app/features/chat/chat_controller.dart';
import 'package:casama_app/features/chat/chat_screen.dart';
import 'package:casama_app/features/files/file_preview.dart';
import 'package:casama_app/features/integrations/integrations_screen.dart';
import 'package:casama_app/l10n/generated/app_localizations.dart';
import 'package:casama_app/theme/app_theme.dart';

import 'fake_backend.dart';

Widget _app(FakeBackend backend, Widget child) => ProviderScope(
      overrides: [backendProvider.overrideWithValue(backend)],
      child: MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    );

void main() {
  test('file links a bot writes resolve to paths on its computer', () {
    expect(computerPathFromLink('sandbox:/home/casama/workspace/chief_one_page_intro.txt'), 'chief_one_page_intro.txt');
    expect(computerPathFromLink('workspace/reports/q3.md'), 'reports/q3.md');
    expect(computerPathFromLink('/home/casama/workspace/a b.pdf'), 'a b.pdf');
    expect(computerPathFromLink('file:///home/casama/notes.txt'), '~/notes.txt');
    expect(computerPathFromLink('~/workspace/x.csv'), 'x.csv');
    expect(computerPathFromLink('~/.config/app.json'), '~/.config/app.json');
    expect(computerPathFromLink('report.md'), 'report.md');
    expect(computerPathFromLink('/etc/hosts'), '/etc/hosts');
    expect(computerPathFromLink('https://example.com/a.md'), isNull);
    expect(computerPathFromLink('mailto:a@b.c'), isNull);
    expect(computerPathFromLink('#section'), isNull);
  });

  test('integration names become identifiers', () {
    expect(integrationSlug('GitHub tools'), 'github_tools');
    expect(integrationSlug('  My MCP-Server!  '), 'my_mcp_server');
    expect(integrationSlug('123 api'), 'x_123_api');
    expect(integrationSlug('???'), '');
  });

  testWidgets('attachments show on the message, are sent with it, and a bot file link opens a preview', (tester) async {
    tester.view.physicalSize = const Size(500, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final backend = FakeBackend()
      ..uploads['uploads/notes.md'] = Uint8List.fromList('# Notes\n\nhello'.codeUnits)
      ..storedMessages = [
        ChatMessageView(
          id: '1',
          role: 'user',
          text: 'Summarize this',
          createdAt: DateTime(2026, 1, 1, 10),
          attachments: const [AttachmentRef(path: 'workspace/uploads/notes.md', name: 'notes.md', mimeType: 'text/markdown', size: 16)],
        ),
        ChatMessageView(
          id: '2',
          role: 'assistant',
          text: 'Done. See [summary.md](sandbox:/home/casama/workspace/summary.md).',
          createdAt: DateTime(2026, 1, 1, 10, 1),
        ),
      ];
    await tester.pumpWidget(_app(backend, const ChatScreen(botId: botId, conversationId: convId)));
    await tester.pumpAndSettle();
    expect(find.text('notes.md'), findsOneWidget);

    // The attachment opens in the preview, rendered as Markdown.
    await tester.tap(find.byKey(const Key('attachment-workspace/uploads/notes.md')));
    await tester.pumpAndSettle();
    expect(find.byType(FilePreview), findsOneWidget);
    expect(find.text('Notes'), findsOneWidget);
    expect(find.byKey(const Key('fileSave')), findsOneWidget);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    // Sending passes attachments through the controller.
    final container = ProviderScope.containerOf(tester.element(find.byType(ChatScreen)));
    await container.read(chatControllerProvider(botId).notifier).send('', attachments: const [
      AttachmentRef(path: 'workspace/uploads/photo.png', name: 'photo.png', mimeType: 'image/png', size: 2048),
    ]);
    await tester.pump();
    expect(backend.sentAttachments.last.single.path, 'workspace/uploads/photo.png');
  });
}
