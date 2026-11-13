// General and topics (D-253): the topics bar above General and inside a topic, suggestion cards and
// topic results in General, and the Needs you and Casama rows at the top of the chats.
import 'package:casama_app/core/backend.dart';
import 'package:casama_app/core/local_cache.dart';
import 'package:casama_app/core/providers.dart';
import 'package:casama_app/features/bots/bots_screen.dart';
import 'package:casama_app/features/chat/chat_screen.dart';
import 'package:casama_app/features/inbox/for_you.dart';
import 'package:casama_app/features/inbox/inbox_screen.dart';
import 'package:casama_app/l10n/generated/app_localizations.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_test.dart' show setSize;
import 'fake_backend.dart';

Conversation _topic(
  String id,
  String title, {
  ConversationStatusEnum? status,
  DateTime? at,
}) => Conversation(
  id: id,
  botId: botId,
  title: title,
  lastMessageAt: at ?? DateTime.now().subtract(const Duration(hours: 1)),
  createdAt: DateTime(2026),
  kind: ConversationKindEnum.direct,
  botIds: const [botId],
  isMain: false,
  parentConversationId: convId,
  status: status,
);

Widget _app(FakeBackend backend, GoRouter router) => ProviderScope(
  overrides: [
    backendProvider.overrideWithValue(backend),
    localCacheProvider.overrideWithValue(const NoCache()),
  ],
  child: MaterialApp.router(
    routerConfig: router,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
  ),
);

GoRouter _router(String initial) => _current = GoRouter(
  initialLocation: initial,
  routes: [
    GoRoute(
      path: '/bots',
      builder: (_, _) => const Scaffold(body: BotsList()),
    ),
    GoRoute(
      path: '/bots/:botId/chat',
      builder: (_, s) => ChatScreen(
        botId: s.pathParameters['botId']!,
        conversationId: s.uri.queryParameters['c'],
      ),
    ),
    GoRoute(
      path: '/inbox',
      builder: (_, s) => Scaffold(
        body: Text('inbox ${s.uri.queryParameters['tab'] ?? 'all'}'),
      ),
    ),
  ],
);

late GoRouter _current;
String _location(WidgetTester _) =>
    _current.routerDelegate.currentConfiguration.uri.toString();

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    'General shows chips for the topics going on, needs-you first, and opens one',
    (tester) async {
      await setSize(tester, const Size(430, 932));
      final backend = FakeBackend()
        ..fakeChatIsGeneral = true
        ..topics = [
          _topic('t-trip', 'Japan trip'),
          _topic(
            't-pay',
            'Pay the Acme invoice',
            status: ConversationStatusEnum.needsYou,
          ),
          _topic(
            't-old',
            'Old thing',
            at: DateTime.now().subtract(const Duration(days: 30)),
          ),
        ];
      await tester.pumpWidget(
        _app(backend, _router('/bots/$botId/chat?c=$convId')),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('topicChip-t-pay')), findsOneWidget);
      expect(find.byKey(const Key('topicChip-t-trip')), findsOneWidget);
      // A topic idle for a month waits under Older in All topics, not as a chip.
      expect(find.byKey(const Key('topicChip-t-old')), findsNothing);
      expect(
        tester.getTopLeft(find.byKey(const Key('topicChip-t-pay'))).dx,
        lessThan(
          tester.getTopLeft(find.byKey(const Key('topicChip-t-trip'))).dx,
        ),
      );
      await tester.ensureVisible(find.byKey(const Key('topicChip-t-trip')));
      await tester.tap(find.byKey(const Key('topicChip-t-trip')));
      await tester.pumpAndSettle();
      expect(_location(tester), '/bots/$botId/chat?c=t-trip');
      // In the topic: its title and the way back to General.
      expect(find.byKey(const Key('topicTitle')), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const Key('topicTitle'))).data,
        'Japan trip',
      );
      await tester.tap(find.byKey(const Key('backToGeneral')));
      await tester.pumpAndSettle();
      expect(_location(tester), '/bots/$botId/chat?c=$convId');

      // All topics: General first, the live ones, then Older.
      await tester.ensureVisible(find.byKey(const Key('allTopics')));
      await tester.tap(find.byKey(const Key('allTopics')));
      await tester.pumpAndSettle();
      expect(find.text('Topics'), findsOneWidget);
      expect(find.byKey(const Key('olderTopics')), findsOneWidget);
      expect(
        tester.getTopLeft(find.byKey(const Key('topicRow-$convId'))).dy,
        lessThan(tester.getTopLeft(find.byKey(const Key('topicRow-t-pay'))).dy),
      );
      expect(
        tester.getTopLeft(find.byKey(const Key('topicRow-t-trip'))).dy,
        lessThan(tester.getTopLeft(find.byKey(const Key('topicRow-t-old'))).dy),
      );
    },
  );

  testWidgets(
    'a suggestion in General is a card: Do it opens the topic it starts',
    (tester) async {
      await setSize(tester, const Size(430, 932));
      final backend = FakeBackend()
        ..fakeChatIsGeneral = true
        ..storedMessages = [
          ChatMessageView(
            id: 'm-s1',
            role: 'assistant',
            text: 'Ana asked twice. Want me to reply?',
            createdAt: DateTime(2026, 11, 10),
            suggestion: const MessageSuggestion(
              id: 's1',
              title: 'Reply to Ana',
              body: 'She asked twice.',
            ),
          ),
          ChatMessageView(
            id: 'm-t1',
            role: 'assistant',
            text: 'Booked an Uber for 7:15 tonight.',
            createdAt: DateTime(2026, 11, 10, 9),
            topic: const MessageTopic(
              conversationId: 't-ride',
              title: 'Book a ride',
            ),
          ),
        ];
      await tester.pumpWidget(
        _app(backend, _router('/bots/$botId/chat?c=$convId')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Ana asked twice. Want me to reply?'), findsOneWidget);
      expect(find.byKey(const Key('suggestionCard-s1')), findsOneWidget);
      expect(find.byKey(const Key('topicLink-t-ride')), findsOneWidget);
      expect(find.text('Open Book a ride'), findsOneWidget);

      await tester.tap(find.byKey(const Key('suggestionDoIt-s1')));
      await tester.pumpAndSettle();
      expect(backend.suggestionActions, ['accept:s1']);
      // The fake answers with its one chat as the topic.
      expect(_location(tester), '/bots/$botId/chat?c=$convId');
      expect(find.byKey(const Key('suggestionCard-s1')), findsNothing);
    },
  );

  testWidgets(
    'several suggestions come as one card: a Do it per row, one Not now for the rest (D-257)',
    (tester) async {
      await setSize(tester, const Size(430, 932));
      final backend = FakeBackend()
        ..storedMessages = [
          ChatMessageView(
            id: 'm-list',
            role: 'assistant',
            text: '',
            createdAt: DateTime(2026, 11, 13),
            suggestionList: const [
              MessageSuggestion(
                id: 's1',
                title: 'Reply to Ana',
                body: 'She asked twice. Reply?',
              ),
              MessageSuggestion(
                id: 's2',
                title: 'Check the Cloud bill',
                body: 'At 50% of the cap. Look?',
              ),
            ],
          ),
        ];
      await tester.pumpWidget(
        _app(backend, _router('/bots/$botId/chat?c=$convId')),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('suggestionList-m-list')), findsOneWidget);
      expect(find.text('Found 2 things worth a look'), findsOneWidget);
      expect(find.byKey(const Key('suggestionRow-s1')), findsOneWidget);
      expect(find.byKey(const Key('suggestionRow-s2')), findsOneWidget);
      await tester.tap(find.byKey(const Key('suggestionsNotNow-m-list')));
      await tester.pumpAndSettle();
      // s2 isn't in the fake's For you list, so it already counted as closed; s1 is dismissed now.
      expect(backend.suggestionActions, contains('dismiss:s1'));
      expect(find.byKey(const Key('suggestionsDone-m-list')), findsOneWidget);
    },
  );

  testWidgets('Not now folds the card into a line', (tester) async {
    await setSize(tester, const Size(430, 932));
    final backend = FakeBackend()
      ..storedMessages = [
        ChatMessageView(
          id: 'm-s1',
          role: 'assistant',
          text: 'Want me to reply to Ana?',
          createdAt: DateTime(2026, 11, 10),
          suggestion: const MessageSuggestion(id: 's1', title: 'Reply to Ana'),
        ),
      ];
    await tester.pumpWidget(
      _app(backend, _router('/bots/$botId/chat?c=$convId')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('suggestionNotNow-s1')));
    await tester.pumpAndSettle();
    expect(backend.suggestionActions, ['dismiss:s1']);
    expect(find.byKey(const Key('suggestionDone-s1')), findsOneWidget);
  });

  testWidgets('the chats start with Needs you and the pinned Casama row', (
    tester,
  ) async {
    await setSize(tester, const Size(430, 932));
    await tester.pumpWidget(_app(FakeBackend(), _router('/bots')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('chatsUpdates')), findsOneWidget);
    // The fake has approvals and a suggestion waiting.
    expect(
      find.descendant(
        of: find.byKey(const Key('chatsNeedsYou')),
        matching: find.textContaining('need'),
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('chatsNeedsYou')));
    await tester.pumpAndSettle();
    expect(find.text('inbox 0'), findsOneWidget);
  });

  NotificationView note(String id, String kind, String title, String? link) =>
      NotificationView(
        id: id,
        kind: kind,
        title: title,
        body: '',
        link: link,
        createdAt: DateTime(2026, 11, 13),
        botId: link == null ? null : botId,
      );

  test(
    'Updates leaves out requests and what a bot\'s chat already shows (D-254)',
    () {
      expect(
        isUpdateRowNotification(
          note('a', 'member_joined', 'Ana joined', '/joined/o1'),
        ),
        isTrue,
      );
      expect(
        isUpdateRowNotification(
          note('b', 'call_missed', 'Missed call', '/bots/$botId/call'),
        ),
        isTrue,
      );
      expect(
        isUpdateRowNotification(
          note(
            'c',
            'routine_result',
            'Morning brief',
            '/bots/$botId/chat?c=$convId',
          ),
        ),
        isFalse,
      );
      expect(
        isUpdateRowNotification(
          note('d', 'suggestion', 'Book a ride?', '/bots/$botId/chat'),
        ),
        isFalse,
      );
      expect(
        isUpdateRowNotification(
          note('e', 'approval', 'Ada needs approval', '/approvals/x'),
        ),
        isFalse,
      );
    },
  );

  testWidgets(
    'the Updates screen lists notices and new pages, not chat messages or decisions',
    (tester) async {
      await setSize(tester, const Size(430, 932));
      final backend = FakeBackend()
        ..storedNotifications = [
          note('n-join', 'member_joined', 'Ana joined Acme', '/joined/o1'),
          note(
            'n-brief',
            'routine_result',
            'Your morning brief',
            '/bots/$botId/chat?c=$convId',
          ),
        ];
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            backendProvider.overrideWithValue(backend),
            localCacheProvider.overrideWithValue(const NoCache()),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const InboxScreen(
              initialFilter: InboxFilter.updates,
              title: 'Updates',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Ana joined Acme'), findsOneWidget);
      expect(find.text('Your morning brief'), findsNothing);
      // No decisions here (the fake has a waiting approval and a suggestion; they're in Needs you).
      expect(find.byKey(const Key('inboxFilter-needsYou')), findsNothing);
      // One list: pages moved to the Library (D-274), so Updates has no chips.
      expect(find.byKey(const Key('inboxFilter-updates')), findsNothing);
      expect(find.byKey(const Key('inboxFilter-pages')), findsNothing);
    },
  );

  test('topics split into live and older, General first', () {
    final now = DateTime(2026, 11, 13);
    final general = Conversation(
      id: 'g',
      botId: botId,
      title: null,
      lastMessageAt: DateTime(2025),
      createdAt: DateTime(2025),
      kind: ConversationKindEnum.direct,
      botIds: const [botId],
      isMain: true,
    );
    final split = splitTopics([
      _topic('a', 'Recent', at: DateTime(2026, 11, 12)),
      _topic(
        'b',
        'Working',
        status: ConversationStatusEnum.working,
        at: DateTime(2026, 1, 1),
      ),
      _topic('c', 'Old', at: DateTime(2026, 1, 1)),
      general,
      // A chat app's thread is no topic: listed, but never a chip.
      Conversation(
        id: 'w',
        botId: botId,
        title: 'WhatsApp: Ana',
        lastMessageAt: DateTime(2026, 11, 12, 23),
        createdAt: DateTime(2026, 11, 1),
        kind: ConversationKindEnum.direct,
        botIds: const [botId],
      ),
    ], now: now);
    expect(split.active.map((c) => c.id), ['g', 'b', 'a']);
    expect(split.older.map((c) => c.id), ['c', 'w']);
  });
}
