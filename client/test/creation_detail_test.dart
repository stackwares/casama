// One thing in the Library (D-274, LIBRARY-PLAN §5.3): open a page through a view link, export its
// PDF, change who can see it, rename, pin, delete with Undo, and Change it. Replaces the Pages
// screen's test: its actions live here now.
import 'package:casama_app/core/backend.dart';
import 'package:casama_app/core/providers.dart';
import 'package:casama_app/features/bots/bot_profile_screen.dart';
import 'package:casama_app/features/chat/chat_screen.dart';
import 'package:casama_app/features/library/creation_detail.dart';
import 'package:casama_app/features/library/library_screen.dart';
import 'package:casama_app/features/pages/pages_screen.dart';
import 'package:casama_app/features/search/search_view.dart';
import 'package:casama_app/l10n/generated/app_localizations.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_test.dart' show setSize;
import 'fake_backend.dart';

late GoRouter _current;

Widget _app(FakeBackend backend, String initial, {List<Uri>? opened}) {
  _current = GoRouter(
    initialLocation: initial,
    routes: [
      GoRoute(
        path: '/library',
        builder: (_, s) => LibraryScreen(botId: s.uri.queryParameters['bot']),
      ),
      GoRoute(
        path: '/library/:id',
        builder: (_, s) =>
            CreationDetailScreen(creationId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/bots/:botId/chat',
        builder: (_, s) => ChatScreen(
          botId: s.pathParameters['botId']!,
          conversationId: s.uri.queryParameters['c'],
          draft: s.uri.queryParameters['draft'],
        ),
      ),
      GoRoute(
        path: '/bots/:botId/settings',
        builder: (_, s) => BotProfileScreen(botId: s.pathParameters['botId']!),
      ),
      GoRoute(
        path: '/search',
        builder: (_, _) => const Scaffold(body: SearchView()),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      backendProvider.overrideWithValue(backend),
      if (opened != null)
        pageOpenerProvider.overrideWithValue((Uri u) async => opened.add(u)),
    ],
    child: MaterialApp.router(
      routerConfig: _current,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

FakeBackend _backend() => FakeBackend()
  ..creationList = [
    fakeCreation(
      'c-game',
      title: 'Space Dodger',
      label: 'Game',
      pageId: 'page-1',
    ),
    fakeCreation(
      'c-logo',
      kind: CreationKind.image,
      title: 'Logo',
      mediaId: 'media-logo',
      mime: 'image/png',
      runId: 'run-1',
    ),
    fakeCreation(
      'c-logo2',
      kind: CreationKind.image,
      title: 'Logo, take 2',
      mediaId: 'media-logo2',
      mime: 'image/png',
      runId: 'run-1',
    ),
  ];

Future<void> _menu(WidgetTester tester, String key) async {
  await tester.tap(find.byKey(const Key('creationMenu')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(Key(key)));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    'a game plays in the browser through a view link, and its PDF exports',
    (tester) async {
      await setSize(tester, const Size(500, 1100));
      final backend = _backend();
      final opened = <Uri>[];
      await tester.pumpWidget(_app(backend, '/library/c-game', opened: opened));
      await tester.pumpAndSettle();
      expect(find.text('Play'), findsOneWidget);
      expect(find.textContaining('Made by Ada'), findsOneWidget);
      await tester.tap(find.byKey(const Key('creationOpen')));
      await tester.pumpAndSettle();
      expect(
        opened.single.toString(),
        'https://pages.example.com/v/tok-page-1',
      );
      // Opening counts toward Recently opened.
      expect(
        backend.creationUpdates.any(
          (u) => u.$1 == 'c-game' && u.$2['opened'] == true,
        ),
        isTrue,
      );
      await _menu(tester, 'creationPdf');
      expect(backend.pageActions.last, 'pdf:page-1');
    },
  );

  testWidgets('going public warns first, then shows the link', (tester) async {
    await setSize(tester, const Size(500, 1100));
    final backend = _backend();
    await tester.pumpWidget(_app(backend, '/library/c-game'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('creationMenu')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('creationVisibility')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('creationVisibility-public')));
    await tester.pumpAndSettle();
    expect(find.text('Make this page public?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('confirmPublic')));
    await tester.pumpAndSettle();
    expect(backend.creationUpdates.last.$2['visibility'], 'public');
    expect(
      tester
          .widget<SelectableText>(find.byKey(const Key('creationPublicUrl')))
          .data,
      'https://pages.example.com/c/tok-c-game',
    );
  });

  testWidgets('rename and pin', (tester) async {
    await setSize(tester, const Size(500, 1100));
    final backend = _backend();
    await tester.pumpWidget(_app(backend, '/library/c-game'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('creationTitle')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('creationTitleField')),
      'Space Dodger 2',
    );
    await tester.tap(find.byKey(const Key('saveCreationTitle')));
    await tester.pumpAndSettle();
    expect(backend.creationUpdates.last.$2['title'], 'Space Dodger 2');
    expect(find.text('Space Dodger 2'), findsWidgets);
    await _menu(tester, 'creationPin');
    expect(backend.creationUpdates.last.$2['pinned'], true);
  });

  testWidgets('delete hides it at once, and Undo brings it back', (
    tester,
  ) async {
    await setSize(tester, const Size(1400, 1000));
    final backend = _backend();
    await tester.pumpWidget(_app(backend, '/library'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('creation-c-game')));
    await tester.pumpAndSettle();
    await _menu(tester, 'creationDelete');
    expect(backend.deletedCreations, ['c-game']);
    expect(find.byKey(const Key('creation-c-game')), findsNothing);
    await tester.tap(find.byKey(const Key('undoDeleteCreation')));
    await tester.pumpAndSettle();
    expect(backend.restoredCreations, ['c-game']);
    expect(find.byKey(const Key('creation-c-game')), findsOneWidget);
  });

  testWidgets(
    'Change it opens the chat it came from with the request started',
    (tester) async {
      await setSize(tester, const Size(900, 1000));
      await tester.pumpWidget(_app(_backend(), '/library/c-game'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('creationChangeIt')));
      await tester.pumpAndSettle();
      expect(_current.state.uri.path, '/bots/$botId/chat');
      expect(_current.state.uri.queryParameters['c'], convId);
      final input = tester
          .widget<TextField>(find.byKey(const Key('messageInput')))
          .controller!
          .text;
      expect(input, 'About “Space Dodger”: ');
    },
  );

  testWidgets('what the same run made shows alongside', (tester) async {
    await setSize(tester, const Size(500, 1200));
    await tester.pumpWidget(_app(_backend(), '/library/c-logo'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('creationSiblings')), findsOneWidget);
    expect(find.byKey(const Key('creation-c-logo2')), findsOneWidget);
  });

  testWidgets('search has a Library scope that finds things by title', (
    tester,
  ) async {
    await setSize(tester, const Size(900, 1000));
    await tester.pumpWidget(_app(_backend(), '/search'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'dodger');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('result-creation-c-game')), findsOneWidget);
    await tester.tap(find.byKey(const Key('result-creation-c-game')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('creationDetail-c-game')), findsOneWidget);
  });

  testWidgets("the bot profile's Library tile opens what that bot made", (
    tester,
  ) async {
    await setSize(tester, const Size(500, 1100));
    final backend = _backend();
    await tester.pumpWidget(_app(backend, '/bots/$botId/settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('botTile-library')));
    await tester.pumpAndSettle();
    expect(_current.state.uri.toString(), '/library?bot=$botId');
    expect(backend.creationQueries.last.$2, botId);
  });

  testWidgets('a page card in the chat shows in the Library on a long-press', (
    tester,
  ) async {
    await setSize(tester, const Size(900, 1000));
    final backend = _backend()
      ..storedMessages = [
        ChatMessageView(
          id: 'a1',
          role: 'assistant',
          text: 'Done. Drag to steer.',
          createdAt: DateTime(2026, 11, 1),
          attachments: const [
            AttachmentRef(
              path: 'page:page-1',
              name: 'Space Dodger',
              mimeType: 'text/html',
              size: 0,
            ),
          ],
        ),
      ];
    await tester.pumpWidget(_app(backend, '/bots/$botId/chat?c=$convId'));
    await tester.pumpAndSettle();
    await tester.longPress(find.byKey(const Key('pageCard-page-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('showInLibrary')));
    await tester.pumpAndSettle();
    expect(_current.state.uri.path, '/library/c-game');
  });
}
