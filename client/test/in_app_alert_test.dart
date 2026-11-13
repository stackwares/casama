// Fix 16: an approval (or another notification that needs the person) arriving while the app is
// open shows a banner on every platform, not only a badge.
import 'package:casama_app/core/backend.dart';
import 'package:casama_app/core/providers.dart';
import 'package:casama_app/features/home/home_shell.dart';
import 'package:casama_app/features/inbox/in_app_alert.dart';
import 'package:casama_app/l10n/generated/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

NotificationView _n(String id, String kind, {String? link, String title = 'Ada needs approval'}) => NotificationView(
  id: id,
  kind: kind,
  title: title,
  body: 'Send the invoice to Acme?',
  link: link,
  createdAt: DateTime.now(),
);

Widget _app(FakeBackend backend, {String start = '/'}) {
  final router = GoRouter(
    initialLocation: start,
    routes: [
      ShellRoute(
        builder: (_, s, child) => InAppAlertBanner(location: s.uri.path, child: child),
        routes: [
          GoRoute(path: '/', builder: (_, _) => const Scaffold(body: Text('home'))),
          GoRoute(path: '/approvals/:id', builder: (_, s) => Scaffold(body: Text('approval ${s.pathParameters['id']}'))),
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
  testWidgets('an approval that arrives shows a banner that opens it', (tester) async {
    await setSize(tester, const Size(1000, 800));
    final backend = FakeBackend();
    await tester.pumpWidget(_app(backend));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('inAppAlert')), findsNothing);
    backend.notificationsController.add(_n('n9', 'approval_request', link: '/approvals/a9'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('inAppAlert')), findsOneWidget);
    expect(find.text('Ada needs approval'), findsOneWidget);
    await tester.tap(find.byKey(const Key('inAppAlertOpen')));
    await tester.pumpAndSettle();
    expect(find.text('approval a9'), findsOneWidget);
    expect(find.byKey(const Key('inAppAlert')), findsNothing);
    expect(backend.readNotifications, contains('n9'));
  });

  testWidgets('it hides itself, can be dismissed, and skips plain updates', (tester) async {
    await setSize(tester, const Size(1000, 800));
    final backend = FakeBackend();
    await tester.pumpWidget(_app(backend));
    await tester.pumpAndSettle();
    // A plain reply is a badge, not a banner.
    backend.notificationsController.add(_n('n1', 'bot_message', title: 'Ada replied'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('inAppAlert')), findsNothing);

    backend.notificationsController.add(_n('n2', 'takeover', title: 'Ada needs your hands'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('inAppAlert')), findsOneWidget);
    await tester.tap(find.byKey(const Key('inAppAlertDismiss')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('inAppAlert')), findsNothing);

    backend.notificationsController.add(_n('n3', 'secret', title: 'Ada needs a key'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('inAppAlert')), findsOneWidget);
    await tester.pump(InAppAlertBanner.showFor + const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('inAppAlert')), findsNothing);
  });

  testWidgets('no banner for the screen already open', (tester) async {
    await setSize(tester, const Size(1000, 800));
    final backend = FakeBackend();
    await tester.pumpWidget(_app(backend, start: '/approvals/a9'));
    await tester.pumpAndSettle();
    backend.notificationsController.add(_n('n9', 'approval_request', link: '/approvals/a9'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('inAppAlert')), findsNothing);
  });

  testWidgets('the app shell carries the banner', (tester) async {
    await setSize(tester, const Size(1200, 900));
    final backend = FakeBackend();
    await tester.pumpWidget(harness(backend, const HomeShell(location: '/settings/privacy', child: Text('screen'))));
    await tester.pumpAndSettle();
    backend.notificationsController.add(_n('n9', 'approval_request', link: '/approvals/a9'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('inAppAlert')), findsOneWidget);
  });
}
