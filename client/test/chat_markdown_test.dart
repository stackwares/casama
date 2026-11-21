import 'package:casama/features/chat/widgets/chat_markdown.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

void _tapSpanContaining(WidgetTester tester, String substring) {
  final found = <InlineSpan>[];
  for (final element in find.byType(RichText).evaluate()) {
    final rich = element.widget as RichText;
    rich.text.visitChildren((span) {
      if (span is TextSpan &&
          (span.text?.contains(substring) ?? false) &&
          span.recognizer != null) {
        found.add(span);
      }
      return true;
    });
  }
  expect(found, isNotEmpty, reason: 'Expected tappable span for "$substring"');
  final recognizer = (found.first as TextSpan).recognizer! as TapGestureRecognizer;
  recognizer.onTap?.call();
}

void _mockLauncher(List<String> launched) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/url_launcher'),
    (call) async {
      if (call.method == 'launch' || call.method == 'launchUrl') {
        final url = (call.arguments as Map)['url'] as String?;
        if (url != null) launched.add(url);
        return true;
      }
      if (call.method == 'canLaunch') return true;
      return null;
    },
  );
}

void main() {
  testWidgets(
    'ChatMarkdown pushes casama://app/... and casama.ai/open/... links in-app, ignores login-callback, and forwards external https links',
    (tester) async {
      final launched = <String>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/url_launcher'),
        (call) async {
          if (call.method == 'launch' || call.method == 'launchUrl') {
            final url = (call.arguments as Map)['url'] as String?;
            if (url != null) launched.add(url);
            return true;
          }
          if (call.method == 'canLaunch') return true;
          return null;
        },
      );
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/url_launcher'),
          null,
        ),
      );

      final tapped = <String>[];
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => Scaffold(
              body: ChatMarkdown(
                selectable: false,
                appLinks: true,
                onLinkTap: tapped.add,
                data: [
                  'Open [Billing Credits](casama://app/settings/billing?highlight=credits).',
                  'Open [Privacy Export](https://casama.ai/open/settings/privacy?highlight=export).',
                  'Ignore [Callback](casama://app/login-callback?token=secret).',
                  'Read [Docs](https://docs.casama.ai/guide).',
                ].join('\n\n'),
              ),
            ),
          ),
          GoRoute(
            path: '/settings/billing',
            builder: (_, s) => Scaffold(
              body: Text('billing:${s.uri.queryParameters['highlight']}'),
            ),
          ),
          GoRoute(
            path: '/settings/privacy',
            builder: (_, s) => Scaffold(
              body: Text('privacy:${s.uri.queryParameters['highlight']}'),
            ),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      // casama://app/... pushes Billing with ?highlight=credits
      _tapSpanContaining(tester, 'Billing Credits');
      await tester.pumpAndSettle();
      expect(find.text('billing:credits'), findsOneWidget);
      expect(tapped, ['casama://app/settings/billing?highlight=credits']);

      router.pop();
      await tester.pumpAndSettle();

      // https://casama.ai/open/... pushes Privacy with ?highlight=export
      _tapSpanContaining(tester, 'Privacy Export');
      await tester.pumpAndSettle();
      expect(find.text('privacy:export'), findsOneWidget);
      expect(tapped.last, 'https://casama.ai/open/settings/privacy?highlight=export');

      router.pop();
      await tester.pumpAndSettle();

      // casama://app/login-callback is ignored
      _tapSpanContaining(tester, 'Callback');
      await tester.pumpAndSettle();
      expect(router.state.uri.toString(), '/');
      expect(tapped, hasLength(2));

      // External https://docs.casama.ai/guide calls openWebLink
      _tapSpanContaining(tester, 'Docs');
      await tester.pumpAndSettle();
      expect(tapped.last, 'https://docs.casama.ai/guide');
      expect(launched, ['https://docs.casama.ai/guide']);
    },
  );

  testWidgets(
    'bot replies (appLinks off) never open app routes: casama://app does nothing, casama.ai/open goes to the browser',
    (tester) async {
      final launched = <String>[];
      _mockLauncher(launched);
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/url_launcher'),
          null,
        ),
      );
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(
              body: ChatMarkdown(
                selectable: false,
                data: 'Tap [here](casama://app/runs/r1/stop) or [there](https://casama.ai/open/runs/r1/stop).',
              ),
            ),
          ),
          GoRoute(
            path: '/runs/:id/stop',
            builder: (_, _) => const Scaffold(body: Text('stopped')),
          ),
        ],
      );
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      _tapSpanContaining(tester, 'here');
      await tester.pumpAndSettle();
      expect(find.text('stopped'), findsNothing);
      expect(router.state.uri.toString(), '/');

      _tapSpanContaining(tester, 'there');
      await tester.pumpAndSettle();
      expect(find.text('stopped'), findsNothing);
      expect(launched, ['https://casama.ai/open/runs/r1/stop']);
    },
  );

  testWidgets('a code panel\'s language and copy button sit above the code, not on its first line', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ChatMarkdown(
            selectable: false,
            data: 'Here:\n\n```python\nfrom datetime import datetime, timedelta\nprint(1)\n```',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final copy = tester.getRect(find.byType(IconButton));
    final firstLine = tester.getRect(find.byWidgetPredicate(
      (w) => w is RichText && w.text.toPlainText().contains('from datetime'),
    ));
    expect(copy.bottom, lessThanOrEqualTo(firstLine.top));
  });
}
