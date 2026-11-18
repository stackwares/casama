import 'package:casama/core/nav.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// A page with one button per link.
Widget _page(String title, List<String> links) => Builder(
  builder: (context) => Scaffold(
    body: Column(
      children: [
        Text(title),
        for (final l in links) TextButton(onPressed: () => context.pushOnce(l), child: Text('to $l')),
        TextButton(
          onPressed: () => showModalBottomSheet<void>(
            context: context,
            builder: (sheet) => TextButton(onPressed: () => sheet.pushOnce('/chat'), child: const Text('sheet to /chat')),
          ),
          child: const Text('open sheet'),
        ),
      ],
    ),
  ),
);

GoRouter _router() => GoRouter(
  routes: [
    GoRoute(path: '/', builder: (_, _) => _page('Chats', ['/inbox', '/chat'])),
    // Like a notice in Updates whose link is Updates itself.
    GoRoute(path: '/inbox', builder: (_, _) => _page('Updates', ['/inbox'])),
    // A chat, its bot's profile, and a watcher that opens the chat again.
    GoRoute(path: '/chat', builder: (_, _) => _page('Chat', ['/profile'])),
    GoRoute(path: '/profile', builder: (_, _) => _page('Profile', ['/watchers'])),
    GoRoute(path: '/watchers', builder: (_, _) => _page('Watchers', ['/chat'])),
  ],
);

/// How many pages are open, counting back with pops.
Future<int> _depth(WidgetTester tester, GoRouter router) async {
  var n = 1;
  while (router.canPop()) {
    router.pop();
    await tester.pumpAndSettle();
    n++;
  }
  return n;
}

void main() {
  testWidgets('a link to the page you are on does not stack another copy of it', (tester) async {
    final router = _router();
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    await tester.tap(find.text('to /inbox'));
    await tester.pumpAndSettle();
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('to /inbox'));
      await tester.pumpAndSettle();
    }

    expect(await _depth(tester, router), 2);
  });

  testWidgets('a loop back to an open page goes back to it instead of nesting', (tester) async {
    final router = _router();
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    await tester.tap(find.text('to /chat'));
    await tester.pumpAndSettle();
    for (var round = 0; round < 3; round++) {
      await tester.tap(find.text('to /profile'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('to /watchers'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('to /chat'));
      await tester.pumpAndSettle();
      expect(find.text('Chat'), findsOneWidget);
    }

    expect(await _depth(tester, router), 2);
  });

  testWidgets('a link in a sheet to a page further back closes the sheet and goes back', (tester) async {
    final router = _router();
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    await tester.tap(find.text('to /chat'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('to /profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('open sheet'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('sheet to /chat'));
    await tester.pumpAndSettle();

    expect(find.text('sheet to /chat'), findsNothing);
    expect(find.text('Chat'), findsOneWidget);
    expect(await _depth(tester, router), 2);
  });

  testWidgets('new pages still open on top', (tester) async {
    final router = _router();
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    await tester.tap(find.text('to /chat'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('to /profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('to /watchers'));
    await tester.pumpAndSettle();

    expect(find.text('Watchers'), findsOneWidget);
    expect(await _depth(tester, router), 4);
  });
}
