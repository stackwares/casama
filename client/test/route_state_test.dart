import 'package:casama/ui/route_focus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('the not-found page can read the route without throwing', (
    tester,
  ) async {
    String? seen = 'unset';
    final router = GoRouter(
      initialLocation: '/nowhere',
      routes: [GoRoute(path: '/', builder: (_, _) => const Text('home'))],
      errorBuilder: (context, _) {
        seen = routerStateOf(context)?.uri.path;
        return Text(routeFocus(context) ?? 'missing');
      },
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    expect(tester.takeException(), isNull);
    expect(seen, isNull);
    expect(find.text('missing'), findsOneWidget);
  });

  testWidgets('a matched page reads its route', (tester) async {
    final router = GoRouter(
      initialLocation: '/?focus=abc',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => Text(routeFocus(context) ?? 'missing'),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    expect(find.text('abc'), findsOneWidget);
  });
}
