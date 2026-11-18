// App screens for features that were in the API only: export a chat and share a read-only link
// to it (D-282), duplicate a Library item (D-291), Slack's one-click install (D-277), and Show in
// Library after publishing opening the page's own item (D-294).
import 'dart:convert';
import 'dart:typed_data';

import 'package:casama/core/providers.dart';
import 'package:casama/features/bots/channels_screen.dart';
import 'package:casama/features/bots/slack_install.dart';
import 'package:casama/features/chat/chat_controller.dart';
import 'package:casama/features/chat/chat_share.dart';
import 'package:casama/features/library/creation_detail.dart';
import 'package:casama/features/library/library_links.dart';
import 'package:casama/l10n/generated/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

/// A router with the Library's routes as plain markers, and [home] at `/`.
Widget _routed(
  FakeBackend backend,
  Widget home, {
  List<dynamic> overrides = const [],
  String initial = '/',
}) {
  final router = GoRouter(
    initialLocation: initial,
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => Scaffold(body: home),
      ),
      GoRoute(
        path: '/library',
        builder: (_, s) => Scaffold(body: Text('library:${s.uri.query}')),
      ),
      GoRoute(
        path: '/library/:id',
        builder: (_, s) => s.pathParameters['id']!.endsWith('-copy')
            ? Scaffold(body: Text('item:${s.pathParameters['id']}'))
            : CreationDetailScreen(creationId: s.pathParameters['id']!),
      ),
    ],
  );
  return ProviderScope(
    overrides: [backendProvider.overrideWithValue(backend), ...overrides],
    child: MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

/// A button that opens the chat's Share or Export sheet, as the chat's … menu does.
class _ShareHost extends ConsumerWidget {
  const _ShareHost({this.canShare = true});
  final bool canShare;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Center(
    child: TextButton(
      key: const Key('openShare'),
      onPressed: () => showChatShareSheet(
        context,
        ref,
        conversationId: convId,
        title: 'Trip: Lisbon / Porto',
        canShare: canShare,
      ),
      child: const Text('Share'),
    ),
  );
}

ToolEntry _publish({
  Map<String, Object?> args = const {'title': 'Space Dodger'},
  String output = '',
  ToolStatus status = ToolStatus.done,
}) => ToolEntry(
  callId: 'call-1',
  tool: 'pages.publish',
  args: args,
  output: output,
  status: status,
  preview: 'Space Dodger',
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('export and share a chat (D-282)', () {
    testWidgets('exports as Markdown and as JSON through the share flow', (
      tester,
    ) async {
      await setSize(tester, const Size(500, 1000));
      final backend = FakeBackend();
      final saved = <(String, String, String)>[];
      await tester.pumpWidget(
        harness(
          backend,
          const Scaffold(body: _ShareHost()),
          overrides: [
            saveChatExportProvider.overrideWithValue(
              (Uint8List b, String name, String mime, {Rect? origin}) async =>
                  saved.add((name, mime, utf8.decode(b))),
            ),
          ],
        ),
      );
      await tester.tap(find.byKey(const Key('openShare')));
      await tester.pumpAndSettle();
      expect(find.text('Share or Export'), findsOneWidget);
      await tester.tap(find.byKey(const Key('chatExportMarkdown')));
      await tester.pumpAndSettle();
      expect(backend.conversationExports.last, (convId, 'markdown'));
      expect(saved.last, ('Trip Lisbon Porto.md', 'text/markdown', '# Chat\n'));

      await tester.tap(find.byKey(const Key('openShare')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('chatExportJson')));
      await tester.pumpAndSettle();
      expect(backend.conversationExports.last, (convId, 'json'));
      expect(saved.last.$1, 'Trip Lisbon Porto.json');
      expect(saved.last.$2, 'application/json');
    });

    testWidgets(
      'a read-only link asks first, then shows it; it can be stopped',
      (tester) async {
        await setSize(tester, const Size(500, 1000));
        final backend = FakeBackend();
        await tester.pumpWidget(
          harness(backend, const Scaffold(body: _ShareHost())),
        );
        await tester.tap(find.byKey(const Key('openShare')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('chatShareLink')));
        await tester.pumpAndSettle();
        expect(find.text('Share this chat with a link?'), findsOneWidget);
        expect(backend.conversationShares, isEmpty);
        await tester.tap(find.byKey(const Key('confirmChatLink')));
        await tester.pumpAndSettle();
        expect(backend.conversationShares.single, (convId, true));
        expect(
          tester
              .widget<SelectableText>(find.byKey(const Key('chatPublicUrl')))
              .data,
          'https://pages.example.com/t/tok-$convId-1',
        );
        expect(find.byKey(const Key('copyChatLink')), findsOneWidget);
        await tester.tap(find.text('Close'));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('openShare')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('chatStopSharing')));
        await tester.pumpAndSettle();
        expect(backend.conversationShares.last, (convId, false));
        expect(find.text('The link no longer works'), findsOneWidget);
      },
    );

    testWidgets('people who can\'t share only get the export', (tester) async {
      await setSize(tester, const Size(500, 1000));
      await tester.pumpWidget(
        harness(
          FakeBackend(),
          const Scaffold(body: _ShareHost(canShare: false)),
        ),
      );
      await tester.tap(find.byKey(const Key('openShare')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('chatExportMarkdown')), findsOneWidget);
      expect(find.byKey(const Key('chatShareLink')), findsNothing);
      expect(find.byKey(const Key('chatStopSharing')), findsNothing);
    });

    test('export file names drop characters file systems refuse', () {
      expect(chatExportFileName('a/b:c?', 'md'), 'abc.md');
      expect(chatExportFileName('  ', 'json'), 'chat.json');
      expect(chatExportFileName(null, 'md'), 'chat.md');
      expect(chatExportFileName('x' * 120, 'md').length, 83);
    });
  });

  testWidgets(
    'Duplicate in an item\'s menu makes a copy and opens it (D-291)',
    (tester) async {
      await setSize(tester, const Size(500, 1100));
      final backend = FakeBackend()
        ..creationList = [fakeCreation('c-game', title: 'Space Dodger')];
      await tester.pumpWidget(
        _routed(backend, const SizedBox(), initial: '/library/c-game'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('creationMenu')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('creationDuplicate')));
      await tester.pumpAndSettle();
      expect(backend.duplicatedCreations, ['c-game']);
      expect(find.text('Made a copy: “Space Dodger (copy)”'), findsOneWidget);
      await tester.tap(find.byKey(const Key('openDuplicate')));
      await tester.pumpAndSettle();
      expect(find.text('item:c-game-copy'), findsOneWidget);
    },
  );

  group('Slack one-click install (D-277)', () {
    testWidgets('hidden when the server has no Slack app', (tester) async {
      await setSize(tester, const Size(900, 1400));
      final backend = FakeBackend();
      await tester.pumpWidget(
        harness(backend, const ChannelsScreen(botId: botId)),
      );
      await tester.pumpAndSettle();
      expect(backend.slackInstallAsks, [botId]);
      expect(find.byKey(const Key('slackInstall')), findsNothing);
      expect(find.text('No chat apps yet'), findsOneWidget);
    });

    testWidgets('Add to Slack opens a fresh sign-in address', (tester) async {
      await setSize(tester, const Size(900, 1400));
      final backend = FakeBackend()
        ..slackInstall = 'https://slack.com/oauth/v2/authorize?state=s1';
      final opened = <Uri>[];
      await tester.pumpWidget(
        harness(
          backend,
          const ChannelsScreen(botId: botId),
          overrides: [
            slackInstallOpenerProvider.overrideWithValue(
              (Uri u) async => opened.add(u),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
      // Empty, the screen still offers both ways in.
      expect(find.byKey(const Key('slackInstall')), findsOneWidget);
      expect(find.byKey(const Key('addChannelInline')), findsOneWidget);
      backend.slackInstall = 'https://slack.com/oauth/v2/authorize?state=s2';
      await tester.tap(find.byKey(const Key('slackInstall')));
      await tester.pumpAndSettle();
      expect(backend.slackInstallAsks.length, 2);
      expect(opened.single.queryParameters['state'], 's2');
      expect(
        find.text('Finish in Slack, then come back here.'),
        findsOneWidget,
      );
    });
  });

  group('Show in Library after publishing (D-294)', () {
    test('finds the page a publish step made', () {
      expect(publishedPageOf([_publish()]), (
        pageId: null,
        title: 'Space Dodger',
      ));
      expect(
        publishedPageOf([
          _publish(args: {'title': 'Space Dodger', 'page_id': 'p-9'}),
        ])?.pageId,
        'p-9',
      );
      expect(
        publishedPageOf([
          _publish(
            output: 'Published "Space Dodger" (page 0b9d5c62-8a57-4a3e-9d64-6f1f0c1e7a21, version 2).',
          ),
        ])?.pageId,
        '0b9d5c62-8a57-4a3e-9d64-6f1f0c1e7a21',
      );
      expect(publishedPageOf([_publish(status: ToolStatus.failed)]), isNull);
    });

    testWidgets('opens the page\'s own item, not the bot\'s pages', (
      tester,
    ) async {
      final backend = FakeBackend()
        ..creationList = [
          fakeCreation('c-other', title: 'Space Dodger notes'),
          fakeCreation('c-game', title: 'Space Dodger'),
        ];
      await tester.pumpWidget(
        _routed(
          backend,
          PublishedInLibraryButton(botId: botId, steps: [_publish()]),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Show in Library'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('creationDetail-c-game')), findsOneWidget);
    });

    testWidgets('prefers the page id when the step knows it', (tester) async {
      final backend = FakeBackend()
        ..creationList = [
          fakeCreation('c-new', title: 'Space Dodger', pageId: 'p-new'),
          fakeCreation('c-old', title: 'Space Dodger', pageId: 'p-old'),
        ];
      await tester.pumpWidget(
        _routed(
          backend,
          PublishedInLibraryButton(
            botId: botId,
            steps: [
              _publish(args: {'title': 'Space Dodger', 'page_id': 'p-old'}),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Show in Library'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('creationDetail-c-old')), findsOneWidget);
    });

    testWidgets('falls back to the bot\'s pages when it isn\'t found', (
      tester,
    ) async {
      await tester.pumpWidget(
        _routed(
          FakeBackend(),
          PublishedInLibraryButton(botId: botId, steps: [_publish()]),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Show in Library'));
      await tester.pumpAndSettle();
      expect(find.text('library:kind=page&bot=$botId'), findsOneWidget);
    });
  });
}
