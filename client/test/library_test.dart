// The Library, Phase 2 (D-274, LIBRARY-PLAN §5): a third place between Chats and Tasks, filter
// chips, a grid with drawn covers, the empty state, search, and the ways in from elsewhere.
import 'package:casama_app/app.dart';
import 'package:casama_app/core/providers.dart';
import 'package:casama_app/features/library/creation_detail.dart';
import 'package:casama_app/features/library/library_screen.dart';
import 'package:casama_app/l10n/generated/app_localizations.dart';
import 'package:casama_app/ui/floating_tab_chrome.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_test.dart' show setSize;
import 'fake_backend.dart';

FakeBackend _withThings() => FakeBackend()
  ..creationList = [
    fakeCreation('c-game', title: 'Space Dodger', label: 'Game', pinned: true),
    fakeCreation(
      'c-logo',
      kind: CreationKind.image,
      title: 'Logo, round 2',
      mediaId: 'media-logo',
      mime: 'image/png',
      botName: 'Milo',
    ),
    fakeCreation(
      'c-teaser',
      kind: CreationKind.video,
      title: 'Launch teaser',
      mediaId: 'media-teaser',
      mime: 'video/mp4',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    fakeCreation(
      'c-report',
      kind: CreationKind.document,
      title: 'Q4 report',
      mime: 'application/pdf',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
  ];

GoRouter _router(String initial) => GoRouter(
  initialLocation: initial,
  routes: [
    GoRoute(
      path: '/library',
      builder: (_, s) => LibraryScreen(
        kind: CreationKind.values
            .where((k) => k.value == s.uri.queryParameters['kind'])
            .firstOrNull,
        botId: s.uri.queryParameters['bot'],
      ),
      routes: [
        GoRoute(
          path: ':id',
          builder: (_, s) =>
              CreationDetailScreen(creationId: s.pathParameters['id']!),
        ),
      ],
    ),
    GoRoute(
      path: '/quick-ask',
      builder: (_, s) => Text('ask ${s.uri.queryParameters['text']}'),
    ),
  ],
);

Widget _app(FakeBackend backend, GoRouter router) => ProviderScope(
  overrides: [backendProvider.overrideWithValue(backend)],
  child: MaterialApp.router(
    routerConfig: router,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
  ),
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    'from a cold start on a phone, one tap reaches the Library and a second opens a thing',
    (tester) async {
      await setSize(tester, const Size(400, 860));
      final backend = _withThings();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [backendProvider.overrideWithValue(backend)],
          child: const CasamaApp(),
        ),
      );
      await tester.pumpAndSettle();
      final bar = find.byType(FloatingTabChrome);
      // Chats, Library, Tasks, in that order.
      final xs = [
        for (final l in ['Chats', 'Library', 'Tasks'])
          tester.getCenter(find.descendant(of: bar, matching: find.text(l))).dx,
      ];
      expect(xs[0] < xs[1] && xs[1] < xs[2], isTrue);

      await tester.tap(
        find.descendant(of: bar, matching: find.text('Library')),
      );
      await tester.pumpAndSettle();
      expect(find.byType(LibraryScreen), findsOneWidget);
      expect(find.byKey(const Key('creation-c-logo')), findsOneWidget);

      await tester.tap(find.byKey(const Key('creation-c-logo')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('creationDetail-c-logo')), findsOneWidget);
      expect(find.text('Logo, round 2'), findsWidgets);
    },
  );

  testWidgets(
    'chips show only the kinds the workspace has, and filter by kind',
    (tester) async {
      await setSize(tester, const Size(700, 1200));
      final backend = _withThings();
      await tester.pumpWidget(_app(backend, _router('/library')));
      await tester.pumpAndSettle();
      for (final k in ['all', 'page', 'image', 'video', 'document']) {
        expect(find.byKey(Key('libraryKind-$k')), findsOneWidget, reason: k);
      }
      expect(find.byKey(const Key('libraryKind-audio')), findsNothing);
      expect(find.byKey(const Key('libraryKind-file')), findsNothing);

      await tester.tap(find.byKey(const Key('libraryKind-image')));
      await tester.pumpAndSettle();
      expect(backend.creationQueries.last.$1, CreationKind.image);
      expect(find.byKey(const Key('creation-c-logo')), findsOneWidget);
      expect(find.byKey(const Key('creation-c-game')), findsNothing);
    },
  );

  testWidgets(
    'pinned things sit on their own shelf; the rest fall under day headings',
    (tester) async {
      await setSize(tester, const Size(700, 1600));
      await tester.pumpWidget(_app(_withThings(), _router('/library')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('libraryHeading-pinned')), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('This week'), findsOneWidget);
      expect(find.text('Earlier'), findsOneWidget);
      expect(
        tester.getTopLeft(find.byKey(const Key('creation-c-game'))).dy,
        lessThan(
          tester.getTopLeft(find.byKey(const Key('creation-c-logo'))).dy,
        ),
      );
    },
  );

  testWidgets('anything without a cover gets a drawn one', (tester) async {
    await setSize(tester, const Size(700, 1200));
    await tester.pumpWidget(_app(_withThings(), _router('/library')));
    await tester.pumpAndSettle();
    for (final id in ['c-game', 'c-logo', 'c-teaser']) {
      expect(find.byKey(Key('drawnCover-$id')), findsOneWidget, reason: id);
    }
  });

  testWidgets('search passes the words to the Library', (tester) async {
    await setSize(tester, const Size(700, 1200));
    final backend = _withThings();
    await tester.pumpWidget(_app(backend, _router('/library')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('librarySearch')), 'teaser');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(backend.creationQueries.last.$4, 'teaser');
    expect(find.byKey(const Key('creation-c-teaser')), findsOneWidget);
    expect(find.byKey(const Key('creation-c-game')), findsNothing);

    await tester.enterText(
      find.byKey(const Key('librarySearch')),
      'nothing like it',
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('libraryNoMatch')), findsOneWidget);
  });

  testWidgets(
    'an empty Library offers three starters that open quick ask, not sent',
    (tester) async {
      await setSize(tester, const Size(700, 1200));
      await tester.pumpWidget(_app(FakeBackend(), _router('/library')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('libraryEmpty')), findsOneWidget);
      expect(find.text('What should we make first?'), findsOneWidget);
      expect(find.byKey(const Key('libraryStarter-else')), findsOneWidget);
      await tester.tap(find.byKey(const Key('libraryStarter-game')));
      await tester.pumpAndSettle();
      expect(
        find.text('ask Make me a small game I can play in the browser.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('a Library that fails to load says so with Try Again', (
    tester,
  ) async {
    await setSize(tester, const Size(700, 1200));
    final backend = _withThings()..creationsError = Exception('down');
    await tester.pumpWidget(_app(backend, _router('/library')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('creation-c-logo')), findsNothing);
    backend.creationsError = null;
    await tester.tap(find.text('Try Again'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('creation-c-logo')), findsOneWidget);
  });

  testWidgets('a wide window opens the picked thing beside the grid', (
    tester,
  ) async {
    await setSize(tester, const Size(1400, 1000));
    await tester.pumpWidget(_app(_withThings(), _router('/library')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('creation-c-game')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('creationDetail-c-game')), findsOneWidget);
    expect(find.byKey(const Key('libraryGrid')), findsOneWidget);
    await tester.tap(find.byKey(const Key('closeCreationPane')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('creationDetail-c-game')), findsNothing);
  });

  testWidgets('more loads on scroll, 60 at a time', (tester) async {
    await setSize(tester, const Size(400, 860));
    final backend = FakeBackend()
      ..creationList = [
        for (var i = 0; i < 70; i++)
          fakeCreation(
            'c$i',
            title: 'Thing $i',
            createdAt: DateTime.now().subtract(Duration(minutes: i)),
          ),
      ];
    await tester.pumpWidget(_app(backend, _router('/library')));
    await tester.pumpAndSettle();
    expect(backend.creationQueries.length, 1);
    await tester.fling(
      find.byKey(const Key('libraryGrid')),
      const Offset(0, -20000),
      3000,
    );
    await tester.pumpAndSettle();
    expect(backend.creationQueries.last.$5, '60');
    await tester.scrollUntilVisible(
      find.byKey(const Key('creation-c69')),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byKey(const Key('creation-c69')), findsOneWidget);
  });

  testWidgets(
    'old Pages links land on the Library filtered to sites and games',
    (tester) async {
      await setSize(tester, const Size(400, 860));
      final backend = _withThings();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [backendProvider.overrideWithValue(backend)],
          child: const CasamaApp(),
        ),
      );
      await tester.pumpAndSettle();
      final router = GoRouter.of(
        tester.element(find.byType(FloatingTabChrome)),
      );
      router.go('/pages?bot=$botId');
      await tester.pumpAndSettle();
      expect(router.state.uri.path, '/library');
      expect(router.state.uri.queryParameters, {'kind': 'page', 'bot': botId});
      expect(backend.creationQueries.last.$1, CreationKind.page);
      expect(backend.creationQueries.last.$2, botId);
    },
  );
}
