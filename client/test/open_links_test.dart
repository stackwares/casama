import 'package:casama/core/open_links.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  group('openLinkTarget', () {
    String? t(String s) => openLinkTarget(Uri.parse(s));

    test('the route is the rest of the path', () {
      expect(t('https://casama.ai/open/settings/billing'), '/settings/billing');
      expect(t('/open/settings/billing'), '/settings/billing');
      expect(t('/open/join/abc_DEF-123'), '/join/abc_DEF-123');
    });

    test('keeps the query and the fragment', () {
      expect(t('/open/link?code=ABCD-EFGH'), '/link?code=ABCD-EFGH');
      expect(t('/open/pair#v=1&s=x'), '/pair#v=1&s=x');
    });

    test('bare /open goes home', () {
      expect(t('/open'), '/bots');
      expect(t('/open/'), '/bots');
    });

    test('drops a trailing slash and extra leading slashes', () {
      expect(t('/open/settings/billing/'), '/settings/billing');
      expect(t('/open//evil.example/x'), '/evil.example/x');
    });

    test('other paths are not open links', () {
      expect(t('/settings/billing'), isNull);
      expect(t('/opener'), isNull);
      expect(t('/bots/open/x'), isNull);
    });
  });

  group('macLinkLocation', () {
    String? m(String s) => macLinkLocation(Uri.parse(s));

    test('casama://app/<route> opens the route', () {
      expect(m('casama://app/settings/billing'), '/settings/billing');
      expect(
        m('casama://app/join/tok?server=https%3A%2F%2Fx.example'),
        '/join/tok?server=https%3A%2F%2Fx.example',
      );
      expect(m('casama://app'), '/bots');
      expect(m('casama://app/'), '/bots');
    });

    test('casama.ai links the app handles', () {
      expect(
        m('https://casama.ai/open/settings/billing'),
        '/open/settings/billing',
      );
      expect(
        m('https://casama.ai/gallery/theme/lagoon'),
        '/gallery/theme/lagoon',
      );
      expect(m('https://casama.ai/i/ABC123'), '/i/ABC123');
      expect(m('https://casama.ai/pair#v=1'), '/pair#v=1');
    });

    test('leaves sign-in returns, sign-in codes and other links alone', () {
      expect(m('casama://app/login-callback?code=x'), isNull);
      expect(m('casama://pair?s=x&c=y'), isNull);
      expect(m('casama-auth://callback'), isNull);
      expect(m('https://casama.ai/pricing'), isNull);
      expect(m('https://evil.example/open/settings'), isNull);
    });
  });

  test('keepThroughSignIn skips the places sign-in already ends at', () {
    expect(keepThroughSignIn('/settings/billing'), isTrue);
    expect(keepThroughSignIn('/import/tok'), isTrue);
    expect(keepThroughSignIn('/bots'), isFalse);
    expect(keepThroughSignIn('/sign-in'), isFalse);
    expect(keepThroughSignIn('/link?code=x'), isFalse);
  });

  // go_router runs the top-level redirect before any route has to match, which the app's router
  // relies on: nothing matches /open/… itself.
  testWidgets(
    'a top-level redirect turns an unmatched /open link into its route',
    (tester) async {
      final router = GoRouter(
        initialLocation: '/open/settings/billing?x=1',
        redirect: (_, s) => openLinkTarget(s.uri),
        routes: [
          GoRoute(path: '/bots', builder: (_, _) => const Text('bots')),
          GoRoute(
            path: '/settings/billing',
            builder: (_, s) => Text('billing ${s.uri.query}'),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      expect(find.text('billing x=1'), findsOneWidget);

      router.go('/open');
      await tester.pumpAndSettle();
      expect(find.text('bots'), findsOneWidget);
    },
  );
}
