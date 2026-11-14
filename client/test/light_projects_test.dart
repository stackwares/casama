// Light projects (D-295): a project needs only a name, the Library has a Projects shelf and can be
// narrowed to one project, a project's page shows what was made for it and where its files are, a
// thing can be moved between projects, a topic can become a project, and working by itself is a
// switch.
import 'package:casama_app/core/local_cache.dart';
import 'package:casama_app/core/providers.dart';
import 'package:casama_app/features/chat/chat_screen.dart';
import 'package:casama_app/features/library/creation_detail.dart';
import 'package:casama_app/features/library/library_screen.dart';
import 'package:casama_app/features/projects/projects_screen.dart';
import 'package:casama_app/l10n/generated/app_localizations.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

Creation _in(String? projectId, String? projectTitle, Creation c) =>
    Creation.fromJson({
      ...c.toJson(),
      'project_id': projectId,
      'project_title': projectTitle,
    });

Project _project(
  String id,
  String title, {
  bool autonomous = false,
  ProjectStatus status = ProjectStatus.active,
  int count = 0,
  Creation? latest,
}) => Project(
  id: id,
  orgId: orgId,
  slug: title.toLowerCase().replaceAll(' ', '-'),
  title: title,
  goalMd: '',
  doneCriteriaMd: '',
  status: status,
  planStatus: ProjectPlanStatusEnum.draft,
  statusReason: null,
  leadBotId: botId,
  ownerUserId: 'me',
  conversationId: null,
  budgetUsd: null,
  spentUsd: 0,
  deadlineAt: null,
  planMd: '',
  sessions: 0,
  createdAt: DateTime(2026),
  autonomous: autonomous,
  creationsCount: count,
  latestCreation: latest,
  canSteer: true,
);

/// A project worked on together: no goal, no budget, nothing to approve.
ProjectDetail _light({
  ProjectStatus status = ProjectStatus.active,
  String plan = '',
}) => ProjectDetail(
  id: 'p1',
  orgId: orgId,
  slug: 'space-dodger',
  title: 'Space Dodger',
  goalMd: '',
  doneCriteriaMd: '',
  status: status,
  planStatus: ProjectDetailPlanStatusEnum.draft,
  statusReason: null,
  leadBotId: botId,
  ownerUserId: 'me',
  conversationId: 't-game',
  budgetUsd: null,
  spentUsd: 0.4,
  deadlineAt: null,
  planMd: plan,
  sessions: 0,
  createdAt: DateTime(2026),
  autonomous: false,
  personal: true,
  folder: 'workspace/projects/space-dodger',
  creationsCount: 1,
  canSteer: true,
  milestones: const [],
  runs: const [],
);

late GoRouter _current;

/// Where the app is: the pushed screen when one is on top, else the routed location.
String _location() {
  final config = _current.routerDelegate.currentConfiguration;
  final last = config.matches.last;
  return (last is ImperativeRouteMatch ? last.matches.uri : config.uri)
      .toString();
}

Widget _app(FakeBackend backend, String initial) {
  _current = GoRouter(
    initialLocation: initial,
    routes: [
      GoRoute(
        path: '/library',
        builder: (_, s) => LibraryScreen(
          key: ValueKey(s.uri.query),
          projectId: s.uri.queryParameters['project'],
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
        path: '/projects',
        builder: (_, _) => const ProjectsScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (_, s) =>
                ProjectScreen(projectId: s.pathParameters['id']!),
          ),
        ],
      ),
      GoRoute(
        path: '/bots/:botId/chat',
        builder: (_, s) => ChatScreen(
          botId: s.pathParameters['botId']!,
          conversationId: s.uri.queryParameters['c'],
        ),
      ),
      GoRoute(
        path: '/computer',
        builder: (_, s) => Scaffold(
          body: Text(
            'files ${s.uri.queryParameters['tab']} ${s.uri.queryParameters['path']}',
          ),
        ),
      ),
      GoRoute(
        path: '/quick-ask',
        builder: (_, _) => const Scaffold(body: Text('ask')),
      ),
    ],
  );
  return ProviderScope(
    // A fresh app each time one is pumped, so nothing is kept from the one before.
    key: UniqueKey(),
    overrides: [
      backendProvider.overrideWithValue(backend),
      localCacheProvider.overrideWithValue(const NoCache()),
    ],
    child: MaterialApp.router(
      routerConfig: _current,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('a new project needs only a name', (tester) async {
    await setSize(tester, const Size(900, 1200));
    final backend = FakeBackend();
    await tester.pumpWidget(harness(backend, const ProjectsScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('newProject')));
    await tester.pumpAndSettle();
    // No goal or budget is asked for until the bot is to work on it by itself.
    expect(find.byKey(const Key('projectGoal')), findsNothing);
    expect(find.byKey(const Key('projectBudget')), findsNothing);
    expect(find.text('Create Project'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('projectTitle')),
      'Space Dodger',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('createProject')));
    await tester.pumpAndSettle();
    expect(backend.projectActions, ['create-light:Space Dodger']);
  });

  testWidgets(
    'the Library has a Projects shelf; a card opens the project, and the Library narrows to one',
    (tester) async {
      await setSize(tester, const Size(430, 932));
      final game = _in(
        'p1',
        'Space Dodger',
        fakeCreation('c-game', title: 'Space Dodger, the game', label: 'Game'),
      );
      final backend = FakeBackend()
        ..creationList = [
          game,
          fakeCreation(
            'c-logo',
            kind: CreationKind.image,
            title: 'Bakery logo',
            mediaId: 'media-logo',
            mime: 'image/png',
          ),
        ]
        ..projectList = [
          _project('p1', 'Space Dodger', count: 1, latest: game),
          _project('p2', 'Old site', status: ProjectStatus.cancelled),
        ]
        ..projectDetail = _light();
      await tester.pumpWidget(_app(backend, '/library'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('projectShelf')), findsOneWidget);
      expect(find.byKey(const Key('projectTile-p1')), findsOneWidget);
      expect(find.text('1 thing'), findsOneWidget);
      // A cancelled project has no place on the shelf.
      expect(find.byKey(const Key('projectTile-p2')), findsNothing);
      // What is in a project stays in the grid too: nothing disappears into a folder.
      expect(find.byKey(const Key('creation-c-game')), findsOneWidget);
      expect(find.byKey(const Key('creation-c-logo')), findsOneWidget);

      await tester.tap(find.byKey(const Key('projectTile-p1')));
      await tester.pumpAndSettle();
      expect(_location(), '/projects/p1');
      expect(find.text('Made in this project'), findsOneWidget);
      await tester.tap(find.byKey(const Key('projectSeeAll')));
      await tester.pumpAndSettle();
      expect(_location(), '/library?project=p1');
      expect(find.byKey(const Key('creation-c-game')), findsOneWidget);
      expect(find.byKey(const Key('creation-c-logo')), findsNothing);
      // Narrowed to one project, the shelf of all of them steps aside.
      expect(find.byKey(const Key('projectShelf')), findsNothing);
    },
  );

  testWidgets('a workspace with no projects has no shelf', (tester) async {
    await setSize(tester, const Size(430, 932));
    final backend = FakeBackend()
      ..creationList = [fakeCreation('c-game')]
      ..projectList = [];
    await tester.pumpWidget(_app(backend, '/library'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('creation-c-game')), findsOneWidget);
    expect(find.byKey(const Key('projectShelf')), findsNothing);
  });

  testWidgets(
    'a project worked on together shows what was made and where its files are, and its person finishes it',
    (tester) async {
      await setSize(tester, const Size(900, 1600));
      final backend = FakeBackend()
        ..projectDetail = _light(plan: 'Build, then polish.')
        ..creationList = [
          _in(
            'p1',
            'Space Dodger',
            fakeCreation('c-game', title: 'The game', label: 'Game'),
          ),
          fakeCreation('c-other', title: 'Something else'),
        ];
      await tester.pumpWidget(_app(backend, '/projects/p1'));
      await tester.pumpAndSettle();
      // Only what is filed under it; nothing about approval, sessions or a budget.
      expect(find.byKey(const Key('projectMade')), findsOneWidget);
      expect(find.byKey(const Key('creation-c-game')), findsOneWidget);
      expect(find.byKey(const Key('creation-c-other')), findsNothing);
      expect(find.byKey(const Key('approvePlan')), findsNothing);
      expect(find.byKey(const Key('pauseProject')), findsNothing);
      expect(find.byKey(const Key('projectSpend')), findsNothing);
      expect(find.text('Build, then polish.'), findsOneWidget);
      expect(
        find.text("workspace/projects/space-dodger on Ada's computer"),
        findsOneWidget,
      );
      expect(
        tester
            .widget<Switch>(find.byKey(const Key('projectAloneSwitch')))
            .value,
        isFalse,
      );

      await tester.tap(find.byKey(const Key('finishProject')));
      await tester.pumpAndSettle();
      expect(backend.projectActions, ['status:done']);

      await tester.tap(find.byKey(const Key('projectFiles')));
      await tester.pumpAndSettle();
      expect(
        find.text('files files workspace/projects/space-dodger'),
        findsOneWidget,
      );
    },
  );

  testWidgets('a project with nothing made yet says where things will show', (
    tester,
  ) async {
    await setSize(tester, const Size(900, 1600));
    final backend = FakeBackend()..projectDetail = _light();
    await tester.pumpWidget(_app(backend, '/projects/p1'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('projectMadeEmpty')), findsOneWidget);
    expect(find.byKey(const Key('projectSeeAll')), findsNothing);
    // A finished one can be picked up again.
    backend.projectDetail = _light(status: ProjectStatus.done);
    await tester.pumpWidget(_app(backend, '/projects/p1'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('finishProject')), findsNothing);
    await tester.tap(find.byKey(const Key('reopenProject')));
    await tester.pumpAndSettle();
    expect(backend.projectActions, ['status:active']);
  });

  testWidgets(
    'switching "work on it by itself" on asks for the goal first, then plans; off is one tap',
    (tester) async {
      await setSize(tester, const Size(900, 1600));
      final backend = FakeBackend()..projectDetail = _light();
      await tester.pumpWidget(_app(backend, '/projects/p1'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('projectAloneSwitch')));
      await tester.pumpAndSettle();
      // Nothing changes until there's a goal.
      expect(backend.projectActions, isEmpty);
      expect(find.byKey(const Key('projectGoal')), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('projectGoal')),
        'Ship the game',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('startPlanning')));
      await tester.pumpAndSettle();
      expect(backend.projectActions, ['autonomous:true:Ship the game']);

      // The other way: a project that works by itself (the fake's default) is switched off.
      final other = FakeBackend();
      await tester.pumpWidget(_app(other, '/projects/p1'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('projectAloneSwitch')));
      expect(
        tester
            .widget<Switch>(find.byKey(const Key('projectAloneSwitch')))
            .value,
        isTrue,
      );
      await tester.tap(find.byKey(const Key('projectAloneSwitch')));
      await tester.pumpAndSettle();
      expect(other.projectActions, ['autonomous:false']);
    },
  );

  testWidgets('a thing is moved into a project, and out again', (tester) async {
    await setSize(tester, const Size(430, 932));
    final backend = FakeBackend()
      ..creationList = [
        fakeCreation(
          'c-logo',
          kind: CreationKind.image,
          title: 'Ship sprite',
          mediaId: 'media-logo',
          mime: 'image/png',
        ),
      ]
      ..projectList = [_project('p1', 'Space Dodger')];
    await tester.pumpWidget(_app(backend, '/library/c-logo'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('creationProject')), findsNothing);
    await tester.tap(find.byKey(const Key('creationMenu')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('creationMove')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('moveToProject-p1')));
    await tester.pumpAndSettle();
    expect(backend.creationMoves, [('c-logo', 'p1')]);
    // It now says which project it's in.
    expect(find.byKey(const Key('creationProject')), findsOneWidget);
    expect(find.text('Space Dodger'), findsOneWidget);

    await tester.tap(find.byKey(const Key('creationMenu')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('creationMove')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('moveToProject-none')));
    await tester.pumpAndSettle();
    expect(backend.creationMoves.last, ('c-logo', null));
    expect(find.byKey(const Key('creationProject')), findsNothing);
  });

  testWidgets(
    'a topic becomes a project from the chat menu; General never offers it',
    (tester) async {
      await setSize(tester, const Size(430, 932));
      Conversation topic(String id, String title, {String? projectId}) =>
          Conversation(
            id: id,
            botId: botId,
            title: title,
            lastMessageAt: DateTime.now().subtract(const Duration(hours: 1)),
            createdAt: DateTime(2026),
            kind: ConversationKindEnum.direct,
            botIds: const [botId],
            isMain: false,
            parentConversationId: convId,
            projectId: projectId,
          );
      final backend = FakeBackend()
        ..fakeChatIsGeneral = true
        ..topics = [
          topic('t-game', 'Space game'),
          topic('t-site', 'Bakery site', projectId: 'p9'),
        ];
      // General stays everything's home.
      await tester.pumpWidget(_app(backend, '/bots/$botId/chat?c=$convId'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('chatMoreMenu')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('makeProject')), findsNothing);
      expect(find.byKey(const Key('openProject')), findsNothing);

      // A topic that already is a project's chat leads to the project.
      await tester.pumpWidget(_app(backend, '/bots/$botId/chat?c=t-site'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('topicProject')), findsOneWidget);
      await tester.tap(find.byKey(const Key('chatMoreMenu')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('makeProject')), findsNothing);
      expect(find.byKey(const Key('openProject')), findsOneWidget);

      // Any other topic can become one, named after the topic to start with.
      await tester.pumpWidget(_app(backend, '/bots/$botId/chat?c=t-game'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('topicProject')), findsNothing);
      await tester.tap(find.byKey(const Key('chatMoreMenu')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('makeProject')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('makeProjectName')))
            .controller
            ?.text,
        'Space game',
      );
      await tester.tap(find.byKey(const Key('makeProjectSubmit')));
      await tester.pumpAndSettle();
      expect(backend.projectActions, ['create-light:Space game:t-game']);
      expect(_location(), '/projects/p1');
    },
  );
}
