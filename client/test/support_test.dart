import 'package:casama/core/providers.dart';
import 'package:casama/features/settings/support_screen.dart';
import 'package:casama/l10n/generated/app_localizations.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'app_test.dart' show setSize;
import 'fake_backend.dart';

Widget _app(
  FakeBackend backend,
  Widget home, {
  List<Uri>? launched,
  bool launches = true,
}) => ProviderScope(
  overrides: [
    backendProvider.overrideWithValue(backend),
    supportLaunchProvider.overrideWithValue((uri) async {
      launched?.add(uri);
      return launches;
    }),
  ],
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  ),
);

void main() {
  testWidgets(
    'the Help page offers Casama Help, a person, the guides and copyable ids',
    (tester) async {
      await setSize(tester, const Size(800, 1400));
      final backend = FakeBackend();
      final launched = <Uri>[];
      await tester.pumpWidget(
        _app(backend, const SupportScreen(), launched: launched),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('supportAssistantCard')), findsOneWidget);
      expect(
        find.text('Write to our team at support@casama.ai'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('supportDocs')));
      await tester.pumpAndSettle();
      expect(launched.single.toString(), 'https://docs.casama.ai');

      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String;
          }
          return null;
        },
      );
      await tester.tap(find.byKey(const Key('supportAccountId')));
      await tester.pumpAndSettle();
      expect(copied, 'me');
      await tester.tap(find.byKey(const Key('supportCopyAll')));
      await tester.pumpAndSettle();
      expect(copied, contains('Account ID: me'));
      expect(copied, contains('App: Casama'));
    },
  );

  testWidgets('Casama Cloud gets a Status row that opens status.casama.ai', (
    tester,
  ) async {
    await setSize(tester, const Size(800, 1400));
    final launched = <Uri>[];
    await tester.pumpWidget(
      _app(_CloudBackend(), const SupportScreen(), launched: launched),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('supportStatus')));
    await tester.tap(find.byKey(const Key('supportStatus')));
    await tester.pumpAndSettle();
    expect(launched.single.toString(), 'https://status.casama.ai');
  });

  testWidgets('another server: no Casama Cloud Status row', (tester) async {
    await setSize(tester, const Size(800, 1400));
    await tester.pumpWidget(_app(FakeBackend(), const SupportScreen()));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('supportStatus')), findsNothing);
  });

  testWidgets('no assistant on the server: the page leads with writing to us', (
    tester,
  ) async {
    await setSize(tester, const Size(800, 1200));
    final backend = FakeBackend()..support = null;
    await tester.pumpWidget(_app(backend, const SupportScreen()));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('supportAssistantCard')), findsNothing);
    expect(find.byKey(const Key('supportContact')), findsOneWidget);
  });

  testWidgets(
    'Casama Help answers with sources, then hands off to a person with the conversation',
    (tester) async {
      await setSize(tester, const Size(800, 1200));
      final backend = FakeBackend();
      backend.supportReplies.add(
        SupportChatReply(
          reply: 'Tap **Restore Purchases** on the Billing page.',
          sources: [
            SupportSource(
              title: 'Payments › Restore',
              url: 'https://docs.casama.ai/guide/payments#restore',
            ),
          ],
          handoff: SupportChatReplyHandoff(
            topic: SupportTopic.billing,
            summary: 'Paid for Plus on iOS, plan still Free.',
          ),
        ),
      );
      await tester.pumpWidget(_app(backend, const SupportChatScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('supportStarter-0')));
      await tester.pumpAndSettle();

      final asked = backend.supportAsked.single;
      expect(asked.messages.single.content, "My purchase didn't go through");
      expect(asked.platform, isNotEmpty);
      expect(find.text('Restore'), findsOneWidget);
      expect(find.byKey(const Key('supportHandoff')), findsOneWidget);

      await tester.tap(find.byKey(const Key('supportHandoffSend')));
      await tester.pumpAndSettle();
      // The sheet starts on the assistant's summary and topic.
      expect(
        find.descendant(
          of: find.byKey(const Key('supportMessage')),
          matching: find.text('Paid for Plus on iOS, plan still Free.'),
        ),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('supportSend')));
      await tester.pumpAndSettle();
      final ticket = backend.supportTickets.single;
      expect(ticket.topic, SupportTopic.billing);
      expect(ticket.transcript!.map((m) => m.role), [
        SupportMessageRoleEnum.user,
        SupportMessageRoleEnum.assistant,
      ]);
      expect(find.textContaining('C-TEST42'), findsOneWidget);
    },
  );

  testWidgets("a limit from the server shows a notice that leads to a person", (
    tester,
  ) async {
    await setSize(tester, const Size(800, 1200));
    final backend = FakeBackend();
    backend.supportError = DioException(
      requestOptions: RequestOptions(path: '/v1/support/chat'),
      response: Response(
        requestOptions: RequestOptions(path: '/v1/support/chat'),
        statusCode: 429,
        data: {
          'type': 'about:blank',
          'title': 'Too Many Requests',
          'status': 429,
          'code': 'support_limit',
          'detail': "You've reached today's limit for the assistant.",
        },
      ),
    );
    await tester.pumpWidget(
      _app(backend, const SupportChatScreen(initial: 'help')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('supportNotice')), findsOneWidget);
    expect(find.textContaining("today's limit"), findsOneWidget);
    await tester.tap(find.text('Ask a person'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('supportSend')), findsOneWidget);
  });

  testWidgets('on a phone, sending a message shows the confirmation, not a crash', (
    tester,
  ) async {
    await setSize(tester, const Size(390, 844));
    final backend = FakeBackend();
    await tester.pumpWidget(
      _app(
        backend,
        Builder(
          builder: (c) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => showContactSupport(c),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    // Gibberish keeps Send off and says what to add.
    await tester.enterText(find.byKey(const Key('supportMessage')), 'asdf sdfkj lkjh');
    await tester.pump();
    expect(find.text('Add a sentence or two: what you were doing and what went wrong.'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('supportSend')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('supportSend')));
    await tester.pumpAndSettle();
    expect(backend.supportTickets, isEmpty);
    await tester.enterText(
      find.byKey(const Key('supportMessage')),
      'The app froze when I opened a chat with my bot',
    );
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('supportSend')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('supportSend')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(backend.supportTickets.single.message, 'The app froze when I opened a chat with my bot');
    expect(find.textContaining('C-TEST42'), findsOneWidget);
    await tester.tap(find.byKey(const Key('supportSentClose')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('supportSentClose')), findsNothing);
  });

  testWidgets(
    'without server tickets, the message opens the mail app, or is copied when there is none',
    (tester) async {
      await setSize(tester, const Size(800, 1200));
      final backend = FakeBackend()..support = null;
      final launched = <Uri>[];
      await tester.pumpWidget(
        _app(
          backend,
          Builder(
            builder: (c) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => showContactSupport(c),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
          launched: launched,
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('supportTopic-broken')));
      await tester.enterText(
        find.byKey(const Key('supportMessage')),
        'The app froze when I opened a chat with my bot',
      );
      await tester.pump();
      await tester.ensureVisible(find.byKey(const Key('supportSend')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('supportSend')),
        warnIfMissed: true,
      );
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      final uri = launched.single;
      expect(uri.scheme, 'mailto');
      expect(uri.path, 'support@casama.ai');
      final query = Uri.decodeComponent(uri.query);
      expect(query, contains("subject=Casama: Something's not working"));
      expect(query, contains('The app froze'));
      expect(query, contains('Account ID: me'));
      expect(query, isNot(contains('+')));
    },
  );

  testWidgets(
    'Casama Help sends features: [places], renders up to 2 deduplicated Go to chips before sources, and pushes over Help with Back preserved',
    (tester) async {
      await setSize(tester, const Size(800, 1200));
      final backend = FakeBackend();
      final launched = <Uri>[];
      backend.supportReplies.add(
        SupportChatReply(
          reply:
              'Tap [Billing → Restore Purchases](casama://app/settings/billing?highlight=restore) or check privacy.',
          sources: [
            SupportSource(
              title: 'Payments › Restore',
              url: 'https://docs.casama.ai/guide/payments#restore',
            ),
          ],
          places: [
            SupportPlace(
              id: 'billing_restore',
              label: 'Restore Purchases',
              route: '/settings/billing?highlight=restore',
              url: 'casama://app/settings/billing?highlight=restore',
            ),
            SupportPlace(
              id: 'billing_restore',
              label: 'Restore Purchases',
              route: '/settings/billing?highlight=restore',
              url: 'casama://app/settings/billing?highlight=restore',
            ),
            SupportPlace(
              id: 'privacy',
              label: 'Privacy & data',
              route: '/settings/privacy',
              url: 'casama://app/settings/privacy',
            ),
            SupportPlace(
              id: 'billing',
              label: 'Billing',
              route: '/settings/billing',
              url: 'casama://app/settings/billing',
            ),
          ],
          handoff: null,
        ),
      );
      final router = GoRouter(
        initialLocation: '/support',
        routes: [
          GoRoute(
            path: '/support',
            builder: (_, _) => const SupportChatScreen(),
          ),
          GoRoute(
            path: '/settings/billing',
            builder: (_, s) => Scaffold(
              appBar: AppBar(title: const Text('Billing Target')),
              body: Text('highlight:${s.uri.queryParameters['highlight']}'),
            ),
          ),
          GoRoute(
            path: '/settings/privacy',
            builder: (_, _) => const Scaffold(body: Text('Privacy Target')),
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            backendProvider.overrideWithValue(backend),
            supportLaunchProvider.overrideWithValue((uri) async {
              launched.add(uri);
              return true;
            }),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('supportStarter-0')));
      await tester.pumpAndSettle();

      final asked = backend.supportAsked.single;
      expect(asked.features, ['places']);

      // Deduplicated and capped at 2 Go to chips, placed above sources.
      final restoreChip = find.byKey(const Key('supportPlace-billing_restore'));
      final privacyChip = find.byKey(const Key('supportPlace-privacy'));
      final billingChip = find.byKey(const Key('supportPlace-billing'));
      final sourceChip = find.text('Restore');
      expect(restoreChip, findsOneWidget);
      expect(privacyChip, findsOneWidget);
      expect(billingChip, findsNothing);
      expect(sourceChip, findsOneWidget);
      expect(
        tester.getTopLeft(restoreChip).dy,
        lessThan(tester.getTopLeft(sourceChip).dy),
      );

      // Tapping Go to chip pushes Billing with ?highlight=restore over Help.
      await tester.tap(restoreChip);
      await tester.pumpAndSettle();
      expect(find.text('highlight:restore'), findsOneWidget);

      // Back returns to Help with the conversation preserved.
      router.pop();
      await tester.pumpAndSettle();
      expect(restoreChip, findsOneWidget);

      // An external place (route: null) opens via supportLaunchProvider.
      backend.supportReplies.add(
        SupportChatReply(
          reply: 'Manage your Apple subscription directly.',
          sources: const [],
          places: [
            SupportPlace(
              id: 'store_subscriptions_apple',
              label: 'Apple subscriptions',
              route: null,
              url: 'https://apps.apple.com/account/subscriptions',
            ),
          ],
          handoff: null,
        ),
      );
      await tester.enterText(
        find.byType(TextField).last,
        'How do I cancel on iPhone?',
      );
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('supportPlace-store_subscriptions_apple')),
      );
      await tester.pumpAndSettle();
      expect(
        launched.map((u) => u.toString()),
        contains('https://apps.apple.com/account/subscriptions'),
      );
    },
  );
}

class _CloudBackend extends FakeBackend {
  @override
  String get apiUrl => 'https://api.casama.ai';
}
