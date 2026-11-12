// The Inbox: one list with All, Needs you, Briefs and Pages filters.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:casama_app/core/backend.dart';
import 'package:casama_app/core/local_cache.dart';
import 'package:casama_app/core/providers.dart';
import 'package:casama_app/core/router.dart';
import 'package:casama_app/features/inbox/inbox_screen.dart';
import 'package:casama_app/features/pages/pages_screen.dart';
import 'package:casama_app/l10n/generated/app_localizations.dart';
import 'package:casama_app/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

/// The fake's approval (appr1), brief and suggestion (s1), plus a takeover, a skill idea, two
/// notifications (one about appr1) and a page published a few minutes ago.
FakeBackend busyBackend() => FakeBackend()
  ..openTakeovers = [
    TakeoverRequest(
      id: 'tk1',
      botId: botId,
      runId: runId,
      computerId: computerId,
      reason: 'Please sign in to the site',
      status: TakeoverRequestStatusEnum.pending,
      note: null,
      expiresAt: DateTime.now().add(const Duration(hours: 24)),
      createdAt: DateTime.now(),
    ),
  ]
  ..proposals.add(
    SkillProposal(
      id: 'p1',
      botId: botId,
      kind: SkillProposalKindEnum.new_,
      skillId: null,
      name: 'weekly-sales-report',
      description: 'Make the weekly sales report',
      bodyMd: '1. Query sales for 7 days.',
      previousBodyMd: null,
      tools: const [],
      reason: "You've asked for this 3 times.",
      status: SkillProposalStatusEnum.pending,
      createdAt: DateTime.now(),
    ),
  )
  ..storedNotifications = [
    NotificationView(id: 'n1', kind: 'approval', title: 'Ada needs approval', body: 'Run a destructive shell command', link: '/approvals/appr1', createdAt: DateTime.now()),
    NotificationView(id: 'n5', kind: 'routine', title: 'Morning summary is ready', body: 'Three things changed', createdAt: DateTime.now().subtract(const Duration(hours: 1))),
  ]
  ..pageList.add(
    BotPage(
      id: 'page-2',
      botId: botId,
      title: 'Launch tracker',
      visibility: BotPageVisibilityEnum.workspace,
      version: 1,
      expiresAt: null,
      refreshRoutineId: null,
      conversationId: null,
      canManage: true,
      updatedAt: DateTime.now(),
      createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
  );

/// Nothing waiting, no briefs, notifications or pages.
class QuietBackend extends FakeBackend {
  QuietBackend() {
    pendingApprovals = [];
    storedNotifications = [];
    pageList.clear();
  }

  @override
  Future<ForYou> forYou(String orgId) async => ForYou(briefs: const [], suggestions: const [], approvals: const []);
}

bool selected(WidgetTester tester, String filter) => tester.widget<ChoiceChip>(find.byKey(Key('inboxFilter-$filter'))).selected;

void main() {
  testWidgets('the filter chips fit a small phone and count what needs you', (tester) async {
    await setSize(tester, const Size(375, 667));
    await tester.pumpWidget(harness(busyBackend(), const InboxScreen()));
    await tester.pumpAndSettle();
    for (final f in ['all', 'needsYou', 'briefs', 'pages']) {
      expect(find.byKey(Key('inboxFilter-$f')), findsOneWidget);
    }
    // The approval, the takeover, the suggestion and the skill idea.
    expect(find.text('Needs you (4)'), findsOneWidget);
    expect(selected(tester, 'all'), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('All lists what needs you first, then briefs, notifications and new pages, newest first', (tester) async {
    await setSize(tester, const Size(900, 3000));
    final opened = <Uri>[];
    await tester.pumpWidget(harness(busyBackend(), const InboxScreen(), overrides: [pageOpenerProvider.overrideWithValue((Uri u) async => opened.add(u))]));
    await tester.pumpAndSettle();
    final takeover = find.byKey(const Key('takeover-tk1'));
    final approval = find.byKey(const Key('approval-appr1'));
    final updates = find.text('Updates');
    final page = find.byKey(const Key('pageUpdate-page-2'));
    final note = find.byKey(const Key('notification-n5'));
    final brief = find.byKey(const Key('brief-$botId'));
    for (final f in [takeover, approval, find.byKey(const Key('suggestion-s1')), find.byKey(const Key('proposal-p1')), updates, page, note, brief]) {
      expect(f, findsOneWidget);
    }
    double top(Finder f) => tester.getTopLeft(f).dy;
    expect(top(takeover), lessThan(top(approval)));
    expect(top(approval), lessThan(top(updates)));
    expect(top(updates), lessThan(top(page)));
    expect(top(page), lessThan(top(note)));
    expect(top(note), lessThan(top(brief)));
    // The pending approval's own notice isn't listed twice, and older pages stay under Pages.
    expect(find.byKey(const Key('notification-n1')), findsNothing);
    expect(find.byKey(const Key('pageUpdate-page-1')), findsNothing);

    expect(find.text('Ada published Launch tracker'), findsOneWidget);
    await tester.tap(page);
    await tester.pumpAndSettle();
    expect(opened.single.toString(), 'https://pages.example.com/v/tok-page-2');
  });

  testWidgets('Needs you shows only what waits on a decision, approved in place', (tester) async {
    await setSize(tester, const Size(900, 3000));
    final backend = busyBackend();
    await tester.pumpWidget(harness(backend, const InboxScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('inboxFilter-needsYou')));
    await tester.pumpAndSettle();
    expect(selected(tester, 'needsYou'), isTrue);
    for (final k in ['takeover-tk1', 'approval-appr1', 'suggestion-s1', 'proposal-p1']) {
      expect(find.byKey(Key(k)), findsOneWidget);
    }
    for (final k in ['brief-$botId', 'notification-n5', 'pageUpdate-page-2']) {
      expect(find.byKey(Key(k)), findsNothing);
    }
    expect(find.text('Updates'), findsNothing);

    await tester.tap(find.byKey(const Key('approve')));
    await tester.pumpAndSettle();
    expect(backend.decisions, {'appr1': 'approved'});
    expect(find.byKey(const Key('approval-appr1')), findsNothing);
    expect(find.text('Needs you (3)'), findsOneWidget);
  });

  testWidgets('Briefs shows only morning briefs', (tester) async {
    await setSize(tester, const Size(900, 2000));
    await tester.pumpWidget(harness(busyBackend(), const InboxScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('inboxFilter-briefs')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('brief-$botId')), findsOneWidget);
    expect(find.text('Today: 10:00 Standup.'), findsOneWidget);
    for (final k in ['approval-appr1', 'suggestion-s1', 'notification-n5', 'pageUpdate-page-2']) {
      expect(find.byKey(Key(k)), findsNothing);
    }
  });

  testWidgets('Pages lists every page and opens it through a view link', (tester) async {
    await setSize(tester, const Size(900, 1200));
    final opened = <Uri>[];
    await tester.pumpWidget(harness(busyBackend(), const InboxScreen(), overrides: [pageOpenerProvider.overrideWithValue((Uri u) async => opened.add(u))]));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('inboxFilter-pages')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('page-page-1')), findsOneWidget);
    expect(find.byKey(const Key('page-page-2')), findsOneWidget);
    expect(find.byKey(const Key('approval-appr1')), findsNothing);
    await tester.tap(find.text('Weekly sales'));
    await tester.pumpAndSettle();
    expect(opened.single.toString(), 'https://pages.example.com/v/tok-page-1');
  });

  testWidgets('each filter has its own empty state', (tester) async {
    await setSize(tester, const Size(500, 900));
    await tester.pumpWidget(harness(QuietBackend(), const InboxScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Nothing for you right now'), findsOneWidget);
    expect(find.text('Needs you'), findsOneWidget);
    await tester.tap(find.byKey(const Key('inboxFilter-needsYou')));
    await tester.pumpAndSettle();
    expect(find.text('Nothing needs you right now'), findsOneWidget);
    await tester.tap(find.byKey(const Key('inboxFilter-briefs')));
    await tester.pumpAndSettle();
    expect(find.text('No morning briefs yet'), findsOneWidget);
    await tester.tap(find.byKey(const Key('inboxFilter-pages')));
    await tester.pumpAndSettle();
    expect(find.text('No pages yet'), findsOneWidget);
  });

  testWidgets('/inbox?tab=0 (the old Approvals tab) opens Needs you; /inbox opens All', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await setSize(tester, const Size(430, 932));
    final container = ProviderContainer(retry: (_, _) => null, overrides: [backendProvider.overrideWithValue(FakeBackend()), localCacheProvider.overrideWithValue(const NoCache())]);
    addTearDown(container.dispose);
    final router = container.read(routerProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(theme: AppTheme.light(), routerConfig: router, localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales),
      ),
    );
    Future<void> settle() async {
      for (var i = 0; i < 15; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    await settle();
    router.go('/inbox?tab=0');
    await settle();
    expect(selected(tester, 'needsYou'), isTrue);
    expect(find.byKey(const Key('approval-appr1')), findsOneWidget);
    expect(find.byKey(const Key('brief-$botId')), findsNothing);

    router.go('/inbox');
    await settle();
    expect(selected(tester, 'all'), isTrue);
    expect(find.byKey(const Key('brief-$botId')), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(minutes: 1));
  });
}
