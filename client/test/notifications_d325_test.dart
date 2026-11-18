// D-325: reply pushes, the chat on screen, approval buttons, per-kind settings and desktop
// notifications.
import 'package:casama/core/backend.dart';
import 'package:casama/core/chat_focus.dart';
import 'package:casama/core/desktop_notifications.dart';
import 'package:casama/core/providers.dart';
import 'package:casama/core/push.dart';
import 'package:casama/features/inbox/in_app_alert.dart';
import 'package:casama/features/notifications/push_prefs.dart';
import 'package:casama/l10n/generated/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_test.dart' show setSize;
import 'fake_backend.dart';

NotificationView _reply(String id, {String conversation = 'c1', DateTime? readAt, String? pushStatus = 'sent'}) => NotificationView(
  id: id,
  kind: 'reply',
  title: 'Ada',
  body: 'Here is the summary you asked for.',
  link: '/bots/b1/chat?c=$conversation',
  createdAt: DateTime.now(),
  readAt: readAt,
  botId: 'b1',
  conversationId: conversation,
  pushStatus: pushStatus,
);

Widget _app(FakeBackend backend, {String start = '/'}) {
  final router = GoRouter(
    initialLocation: start,
    routes: [
      ShellRoute(
        builder: (_, s, child) => InAppAlertBanner(location: s.uri.path, child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(body: Text('home')),
          ),
          GoRoute(
            path: '/bots/:id/chat',
            builder: (_, s) => Scaffold(body: Text('chat ${s.uri.queryParameters['c']}')),
          ),
        ],
      ),
    ],
  );
  return ProviderScope(
    overrides: [backendProvider.overrideWithValue(backend)],
    child: MaterialApp.router(routerConfig: router, localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales),
  );
}

void main() {
  group('approval buttons on notifications', () {
    test('Approve and Deny answer the approval and open it', () {
      final data = {'approval_id': 'a1', 'risk': 'low', 'link': '/approvals/a1'};
      expect(PushRegistrar.approvalDecision(data, 'approve'), ('a1', true));
      expect(PushRegistrar.approvalDecision(data, 'deny'), ('a1', false));
      expect(PushRegistrar.openTarget(data, 'approve'), '/approvals/a1');
      expect(PushRegistrar.openTarget(data, 'deny'), '/approvals/a1');
    });

    test('a plain tap, another push or a high-risk approval answers nothing', () {
      expect(PushRegistrar.approvalDecision({'approval_id': 'a1', 'risk': 'low'}, null), isNull);
      expect(PushRegistrar.approvalDecision({'approval_id': 'a1', 'risk': 'high'}, 'approve'), isNull);
      expect(PushRegistrar.approvalDecision({'suggestion_id': 's1'}, 'approve'), isNull);
      expect(PushRegistrar.approvalDecision({'approval_id': 'a1'}, 'accept'), isNull);
      expect(PushRegistrar.openTarget({'approval_id': 'a1', 'link': '/approvals/a1'}, 'open'), '/approvals/a1');
    });

    test('a reply push is counted as a reply', () {
      expect(PushRegistrar.pushKind('/bots/b1/chat?c=c1'), 'reply');
      expect(PushRegistrar.pushKind('/bots/b1/chat'), 'mention');
    });
  });

  group('per-kind settings', () {
    test('missing keys are on, hide_reply_text is off', () {
      final p = PushPrefs.fromJson(const {'routines': false});
      expect(p.routines, isFalse);
      expect(p.replies && p.needsYou && p.suggestions && p.account, isTrue);
      expect(p.hideReplyText, isFalse);
      expect(PushPrefs.fromJson(null).toJson(), const PushPrefs().toJson());
      expect(PushPrefs.fromJson(p.copyWith(hideReplyText: true).toJson()).hideReplyText, isTrue);
    });

    testWidgets('the sheet saves what was switched off', (tester) async {
      await setSize(tester, const Size(1000, 900));
      final backend = FakeBackend();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [backendProvider.overrideWithValue(backend), signedInProvider.overrideWith((ref) => Stream.value(true))],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: PushPrefsTile()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('All on'), findsOneWidget);
      await tester.tap(find.byKey(const Key('settingsPushPrefs')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('pushRoutines')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('savePushPrefs')));
      await tester.pumpAndSettle();
      expect(backend.prefs.routines, isFalse);
      expect(backend.prefs.replies, isTrue);
      expect(find.text('Routines and briefs off'), findsOneWidget);
    });
  });

  group('the in-app banner for replies', () {
    testWidgets('a reply from another chat shows and opens its chat', (tester) async {
      await setSize(tester, const Size(1000, 800));
      final backend = FakeBackend();
      await tester.pumpWidget(_app(backend));
      await tester.pumpAndSettle();
      backend.notificationsController.add(_reply('r1'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('inAppAlert')), findsOneWidget);
      expect(find.text('Open'), findsOneWidget);
      await tester.tap(find.byKey(const Key('inAppAlertOpen')));
      await tester.pumpAndSettle();
      expect(find.text('chat c1'), findsOneWidget);
      expect(backend.readNotifications, contains('r1'));
    });

    testWidgets('no banner for a reply already read (its chat was on screen) or with pushes off', (tester) async {
      await setSize(tester, const Size(1000, 800));
      final backend = FakeBackend();
      await tester.pumpWidget(_app(backend));
      await tester.pumpAndSettle();
      backend.notificationsController.add(_reply('r1', readAt: DateTime.now(), pushStatus: 'off'));
      backend.notificationsController.add(_reply('r2', pushStatus: 'off'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('inAppAlert')), findsNothing);
    });

    testWidgets('a reply banner goes sooner than a request', (tester) async {
      await setSize(tester, const Size(1000, 800));
      final backend = FakeBackend();
      await tester.pumpWidget(_app(backend));
      await tester.pumpAndSettle();
      backend.notificationsController.add(_reply('r1'));
      await tester.pumpAndSettle();
      await tester.pump(InAppAlertBanner.replyShowFor + const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('inAppAlert')), findsNothing);
    });
  });

  group('the chat on screen', () {
    final cleared = <Object?>[];
    setUp(() {
      cleared.clear();
      SharedPreferences.setMockInitialValues({});
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(notificationsChannel, (call) async {
        cleared.add(call.arguments);
        return null;
      });
    });
    tearDown(() => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(notificationsChannel, null));

    testWidgets('opening a chat reports it, closing clears it, the background clears it', (tester) async {
      final backend = FakeBackend();
      final reporter = ChatFocusReporter(backend, prefs: await SharedPreferences.getInstance());
      addTearDown(reporter.dispose);
      reporter.open('c1');
      await tester.pump();
      final id = await reporter.clientId();
      expect(id, hasLength(32));
      expect(backend.chatFocus[id], 'c1');

      reporter.didChangeAppLifecycleState(AppLifecycleState.paused);
      await tester.pump();
      expect(backend.chatFocus[id], isNull);

      reporter.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await tester.pump();
      expect(backend.chatFocus[id], 'c1');

      // Another chat opened first: closing the old one leaves the new one.
      reporter.open('c2');
      reporter.close('c1');
      await tester.pump();
      expect(backend.chatFocus[id], 'c2');
      reporter.close('c2');
      await tester.pump();
      expect(backend.chatFocus[id], isNull);
      // The same id across launches.
      expect(await ChatFocusReporter(backend, prefs: await SharedPreferences.getInstance()).clientId(), id);
    });

    testWidgets('the focus is sent again while the chat stays open', (tester) async {
      final backend = FakeBackend();
      final reporter = ChatFocusReporter(backend, prefs: await SharedPreferences.getInstance());
      addTearDown(reporter.dispose);
      reporter.open('c1');
      await tester.pump();
      final id = await reporter.clientId();
      backend.chatFocus.remove(id);
      await tester.pump(ChatFocusReporter.refresh + const Duration(seconds: 1));
      expect(backend.chatFocus[id], 'c1');
    });
  });

  group('desktop notifications (Windows and Linux)', () {
    test('only pushed, unread rows, while the window is away, never the chat on screen', () {
      expect(DesktopNotifier.shouldShow(_reply('r1'), windowInFront: false), isTrue);
      expect(DesktopNotifier.shouldShow(_reply('r1'), windowInFront: true), isFalse);
      expect(DesktopNotifier.shouldShow(_reply('r1'), windowInFront: false, chatOnScreen: 'c1'), isFalse);
      expect(DesktopNotifier.shouldShow(_reply('r1'), windowInFront: false, chatOnScreen: 'c2'), isTrue);
      expect(DesktopNotifier.shouldShow(_reply('r1', pushStatus: 'off'), windowInFront: false), isFalse);
      expect(DesktopNotifier.shouldShow(_reply('r1', pushStatus: 'deferred'), windowInFront: false), isFalse);
      expect(DesktopNotifier.shouldShow(_reply('r1', readAt: DateTime.now()), windowInFront: false), isFalse);
      // A server from before D-325 sends no push_status.
      expect(DesktopNotifier.shouldShow(_reply('r1', pushStatus: null), windowInFront: false), isTrue);
    });
  });
}
