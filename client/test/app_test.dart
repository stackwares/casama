import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;
import 'package:casama_sdk/casama_sdk.dart' show WelcomeChat;
import 'package:casama_app/features/computer/computer_screen.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:casama_app/app.dart';
import 'package:casama_app/core/backend.dart';
import 'package:casama_app/core/providers.dart';
import 'package:casama_app/features/auth/floating_mascots.dart';
import 'package:casama_app/features/auth/sign_in_screen.dart';
import 'package:casama_app/ui/mascot.dart';
import 'package:casama_app/features/chat/chat_controller.dart';
import 'package:casama_app/features/chat/chat_screen.dart';
import 'package:casama_app/features/chat/chat_detail.dart';
import 'package:casama_app/features/chat/widgets/chat_widgets.dart'
    show ToolGroupCard;
import 'package:casama_app/features/timeline/timeline_screen.dart';
import 'package:casama_app/l10n/generated/app_localizations.dart';
import 'package:casama_app/ui/floating_tab_chrome.dart';

import 'fake_backend.dart';

import 'package:casama_app/core/local_cache.dart';

Widget harness(
  FakeBackend backend,
  Widget child, {
  LocalCache cache = const NoCache(),
  List<dynamic> overrides = const [],
}) => ProviderScope(
  overrides: [
    backendProvider.overrideWithValue(backend),
    localCacheProvider.overrideWithValue(cache),
    ...overrides,
  ],
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  ),
);

Future<void> setSize(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets(
    'the sign-in screen shows the bots and one button that opens the ways in',
    (tester) async {
      await setSize(tester, const Size(390, 844));
      // Apple sign-in shows on Apple platforms and the web.
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      await tester.pumpWidget(
        harness(FakeBackend()..signedIn = false, const SignInScreen()),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(FloatingMascots), findsOneWidget);
      expect(find.byType(MascotImage), findsAtLeastNWidgets(10));
      expect(find.byKey(const Key('email')), findsNothing);
      await tester.tap(find.byKey(const Key('openSignIn')));
      await tester.pumpAndSettle();
      // Apple and Google up front; email folded away until asked for.
      expect(find.text('Continue with Apple'), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.byKey(const Key('email')), findsNothing);
      expect(find.byKey(const Key('ssoSignIn')), findsNothing);
      await tester.tap(find.byKey(const Key('continueWithEmail')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('email')), findsOneWidget);
      debugDefaultTargetPlatformOverride = null;
    },
  );

  testWidgets(
    'the sign-in button fits on a small phone with the largest text size',
    (tester) async {
      await setSize(tester, const Size(320, 640));
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(
        harness(FakeBackend()..signedIn = false, const SignInScreen()),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
      final button = tester.getRect(find.byKey(const Key('openSignIn')));
      final label = tester.getRect(find.text("Let's go"));
      expect(button.height, greaterThanOrEqualTo(56));
      expect(
        button.contains(label.topLeft) &&
            button.contains(label.bottomRight - const Offset(1, 1)),
        isTrue,
      );
    },
  );

  testWidgets(
    'email sign-in sends a magic link first, with a password one tap away',
    (tester) async {
      // The code step is taller than the default test window.
      await setSize(tester, const Size(500, 1100));
      final backend = FakeBackend()..signedIn = false;
      await tester.pumpWidget(harness(backend, const SignInScreen()));
      await tester.tap(find.byKey(const Key('openSignIn')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('continueWithEmail')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('password')), findsNothing);
      await tester.tap(find.byKey(const Key('sendMagicLink')));
      await tester.pump();
      expect(find.text('Enter a valid email address'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('email')), 'ana@example.com');
      await tester.tap(find.byKey(const Key('sendMagicLink')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(backend.magicLinkEmail, 'ana@example.com');
      // The next step: the code from the email, typed here; another email waits a minute.
      expect(find.byKey(const Key('checkInbox')), findsOneWidget);
      expect(find.textContaining('ana@example.com'), findsOneWidget);
      expect(
        tester
            .widget<TextButton>(find.byKey(const Key('resendLink')))
            .onPressed,
        isNull,
      );
      // A wrong code says so plainly, not in Supabase's words.
      backend.verifyCodeError = const AuthException(
        'Token has expired or is invalid',
        code: 'otp_expired',
      );
      await tester.enterText(find.byKey(const Key('emailCode')), '111111');
      await tester.pump();
      expect(
        find.text(
          'That code is wrong or has expired. Check the latest email, or send a new one.',
        ),
        findsOneWidget,
      );
      backend.verifyCodeError = null;
      await tester.enterText(find.byKey(const Key('emailCode')), '123456');
      await tester.pump();
      expect(backend.verifiedCode, '123456');
      await tester.pump(const Duration(seconds: 61));
      expect(
        tester
            .widget<TextButton>(find.byKey(const Key('resendLink')))
            .onPressed,
        isNotNull,
      );
      await tester.pump(const Duration(seconds: 5));
      await tester.tap(find.byKey(const Key('changeEmail')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.byKey(const Key('usePassword')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('password')), findsOneWidget);
      expect(find.byKey(const Key('submit')), findsOneWidget);
    },
  );

  testWidgets('a quick second tap on Google opens one browser, not two', (
    tester,
  ) async {
    final backend = FakeBackend()..signedIn = false;
    await tester.pumpWidget(harness(backend, const SignInScreen()));
    await tester.tap(find.byKey(const Key('openSignIn')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('googleSignIn')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('googleSignIn')));
    await tester.pump(const Duration(seconds: 3));
    expect(backend.providerSignIns, ['google']);
  });

  testWidgets('sign-in validates email and password', (tester) async {
    await tester.pumpWidget(
      harness(FakeBackend()..signedIn = false, const SignInScreen()),
    );
    await tester.tap(find.byKey(const Key('openSignIn')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('continueWithEmail')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('usePassword')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('submit')));
    await tester.pump();
    expect(find.text('Enter a valid email address'), findsOneWidget);
    expect(find.text('Use at least 6 characters'), findsOneWidget);
    await tester.tap(find.byKey(const Key('toggleMode')));
    await tester.pump();
    expect(find.text('Create your account'), findsOneWidget);
  });

  testWidgets(
    'while the bot works, typing turns Stop into Send and the message goes out',
    (tester) async {
      await setSize(tester, const Size(500, 900));
      final backend = FakeBackend();
      await tester.pumpWidget(
        harness(
          backend,
          const ChatScreen(botId: botId, conversationId: convId),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('messageInput')),
        'Research example.com',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('sendButton')));
      await tester.pump();
      expect(find.byKey(const Key('stopButton')), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('messageInput')),
        'only the pricing page',
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byKey(const Key('stopButton')), findsNothing);
      await tester.tap(find.byKey(const Key('sendButton')));
      await tester.pump();
      expect(backend.sent, ['Research example.com', 'only the pricing page']);
      expect(find.text('only the pricing page'), findsOneWidget);
    },
  );

  testWidgets('the password can be shown and hidden again', (tester) async {
    await tester.pumpWidget(
      harness(FakeBackend()..signedIn = false, const SignInScreen()),
    );
    await tester.tap(find.byKey(const Key('openSignIn')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('continueWithEmail')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('usePassword')));
    await tester.pumpAndSettle();
    bool hidden() => tester
        .widget<EditableText>(
          find.descendant(
            of: find.byKey(const Key('password')),
            matching: find.byType(EditableText),
          ),
        )
        .obscureText;
    expect(hidden(), isTrue);
    await tester.tap(find.byKey(const Key('revealToggle')));
    await tester.pump();
    expect(hidden(), isFalse);
    await tester.tap(find.byKey(const Key('revealToggle')));
    await tester.pump();
    expect(hidden(), isTrue);
  });

  testWidgets(
    'chat streams text, folds tool steps into cards, and can stop a run',
    (tester) async {
      await setSize(tester, const Size(500, 900));
      final backend = FakeBackend();
      // The steps show when they're turned on (D-162); simple chats are in simple_chat_test.dart.
      await tester.pumpWidget(
        harness(
          backend,
          const ChatScreen(botId: botId, conversationId: convId),
          overrides: [showBotStepsProvider.overrideWith(StepsShown.new)],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Say hello to Ada.'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('messageInput')),
        'Research example.com',
      );

      await tester.pump();
      await tester.tap(find.byKey(const Key('sendButton')));
      await tester.pump();
      expect(backend.sent, ['Research example.com']);
      expect(find.text('Research example.com'), findsOneWidget);
      expect(find.byKey(const Key('stopButton')), findsOneWidget);

      backend.runEventsController
        ..add(
          ev(1, 'run.started', {
            'trigger': 'chat',
            'model': 'm',
            'computer_id': null,
          }),
        )
        ..add(
          ev(2, 'tool.started', {
            'call_id': 'c1',
            'tool': 'shell.exec',
            'args_redacted': {'command': 'ls -la'},
          }),
        )
        ..add(ev(3, 'tool.output', {'call_id': 'c1', 'chunk': 'report.md\n'}))
        ..add(
          ev(4, 'tool.completed', {
            'call_id': 'c1',
            'result_preview': 'exit code 0',
            'artifact_path': null,
            'duration_ms': 42,
          }),
        )
        ..add(ev(5, 'message.delta', {'message_id': 'a1', 'text': 'Here is '}))
        ..add(
          ev(6, 'message.delta', {
            'message_id': 'a1',
            'text': 'the **report**.',
          }),
        )
        ..add(
          ev(7, 'usage', {
            'tokens_in': 1000,
            'tokens_out': 50,
            'cost_usd': 0.0021,
          }),
        );
      await tester.pump();
      // Tool steps read in plain words. The command stays folded until the row is opened.
      expect(find.text('Worked on its computer'), findsOneWidget);
      expect(find.textContaining('ls -la'), findsNothing);
      expect(find.textContaining('shell.exec'), findsNothing);
      expect(find.text('42 ms'), findsOneWidget);
      // The run's cost isn't shown under the composer.
      expect(find.textContaining('1,050 tokens'), findsNothing);

      // Expanding the card shows the command and the streamed output.
      await tester.tap(find.text('Worked on its computer'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.textContaining('ls -la'), findsOneWidget);
      expect(find.textContaining('report.md'), findsWidgets);

      await tester.tap(find.byKey(const Key('stopButton')));
      await tester.pump();
      expect(backend.cancelled, isTrue);

      backend.runEventsController
        ..add(
          ev(8, 'message.completed', {
            'message_id': 'a1',
            'content': [
              {'type': 'text', 'text': 'Here is the **report**.'},
            ],
          }),
        )
        ..add(ev(9, 'run.completed', {'final_message_id': 'a1'}));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('sendButton')), findsOneWidget);
    },
  );

  testWidgets(
    'a finished reply that is only a card shows the card (welcome chat)',
    (tester) async {
      final container = ProviderContainer(
        overrides: [backendProvider.overrideWithValue(FakeBackend())],
      );
      addTearDown(container.dispose);
      final c = container.read(chatControllerProvider(botId).notifier);
      final card = {
        'type': 'ui',
        'surface_id': 'ui_scope',
        'messages': [
          {
            'version': '1.0',
            'createSurface': {'surfaceId': 'ui_scope', 'catalogId': 'basic'},
          },
        ],
      };
      c.apply(
        ev(1, 'message.completed', {
          'message_id': 'w2',
          'content': [card],
        }),
      );
      // A later ui.shown for the same surface (model replies send both) does not duplicate it.
      c.apply(
        ev(2, 'ui.shown', {
          'surface_id': 'ui_scope',
          'messages': card['messages'],
        }),
      );
      final entries = container.read(chatControllerProvider(botId)).entries;
      expect(entries.whereType<UiEntry>().map((u) => u.surfaceId), [
        'ui_scope',
      ]);
      expect(entries.whereType<MessageEntry>(), isEmpty);
    },
  );

  testWidgets(
    'a failed run shows the reason and orphaned partial text is dropped on completion',
    (tester) async {
      final container = ProviderContainer(
        overrides: [backendProvider.overrideWithValue(FakeBackend())],
      );
      addTearDown(container.dispose);
      final c = container.read(chatControllerProvider(botId).notifier);
      c.apply(
        ev(1, 'message.delta', {'message_id': 'crashed', 'text': 'partial'}),
      );
      c.apply(
        ev(2, 'message.delta', {'message_id': 'final', 'text': 'Full answer'}),
      );
      c.apply(
        ev(3, 'message.completed', {
          'message_id': 'final',
          'content': [
            {'type': 'text', 'text': 'Full answer'},
          ],
        }),
      );
      c.apply(ev(4, 'run.completed', {'final_message_id': 'final'}));
      final texts = container
          .read(chatControllerProvider(botId))
          .entries
          .whereType<MessageEntry>()
          .map((m) => m.text);
      expect(texts, ['Full answer']);

      c.apply(
        ev(5, 'run.failed', {
          'error_code': 'budget_exceeded',
          'message': 'This run reached its budget of \$1.',
        }),
      );
      final last =
          container.read(chatControllerProvider(botId)).entries.last
              as NoticeEntry;
      expect(last.kind, NoticeKind.failed);
    },
  );

  testWidgets('a card shows on its own, without a ui.show step row', (
    tester,
  ) async {
    await setSize(tester, const Size(500, 900));
    final backend = FakeBackend();
    await tester.pumpWidget(
      harness(backend, const ChatScreen(botId: botId, conversationId: convId)),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('messageInput')), 'set me up');
    await tester.pump();
    await tester.tap(find.byKey(const Key('sendButton')));
    await tester.pump();
    final card = [
      {
        'version': '1.0',
        'createSurface': {
          'surfaceId': 'ui_q',
          'catalogId':
              'https://a2ui.org/specification/v1_0/catalogs/basic/catalog.json',
        },
      },
      {
        'version': '1.0',
        'updateComponents': {
          'surfaceId': 'ui_q',
          'components': [
            {'id': 'root', 'component': 'Text', 'text': 'Question one?'},
          ],
        },
      },
    ];
    backend.runEventsController
      ..add(
        ev(1, 'tool.started', {
          'call_id': 'u1',
          'tool': 'ui.show',
          'args_redacted': <String, dynamic>{},
        }),
      )
      ..add(ev(2, 'ui.shown', {'surface_id': 'ui_q', 'messages': card}))
      ..add(
        ev(3, 'tool.completed', {
          'call_id': 'u1',
          'result_preview': 'shown',
          'duration_ms': 2,
          'artifact_path': null,
        }),
      );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Question one?'), findsOneWidget);
    expect(find.byType(ToolGroupCard), findsNothing);
  });

  testWidgets(
    'a run that failed for want of a model offers to add a key, in the chat and its details',
    (tester) async {
      await setSize(tester, const Size(500, 900));
      final backend = FakeBackend();
      await tester.pumpWidget(
        harness(
          backend,
          const ChatScreen(botId: botId, conversationId: convId),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('messageInput')),
        'who are you?',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('sendButton')));
      await tester.pump();
      backend.runEventsController.add(
        ev(1, 'run.failed', {
          'error_code': 'no_model_configured',
          'message': 'This bot has no model.',
        }),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('noticeFix')), findsOneWidget);
      expect(find.text('Add a model key'), findsOneWidget);
      await tester.tap(find.byKey(const Key('errorDetails')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('errorFix')), findsOneWidget);
    },
  );

  testWidgets('timeline filters events and offers restore on checkpoints', (
    tester,
  ) async {
    final backend = FakeBackend()
      ..storedEvents = [
        ev(1, 'run.started', {
          'trigger': 'chat',
          'model': 'm',
          'computer_id': null,
        }),
        ev(2, 'checkpoint.created', {
          'checkpoint_id': '66666666-6666-4666-8666-666666666666',
          'label': 'Before: rm -rf old',
        }),
        ev(3, 'tool.started', {
          'call_id': 'c1',
          'tool': 'shell.exec',
          'args_redacted': {'command': 'rm -rf old'},
        }),
        ev(4, 'message.delta', {'message_id': 'a', 'text': 'Done'}),
        ev(5, 'run.completed', {'final_message_id': 'a'}),
      ];
    await tester.pumpWidget(
      harness(backend, const RunTimelineScreen(botId: botId, runId: runId)),
    );
    await tester.pumpAndSettle();
    expect(find.text('run.started'), findsOneWidget);
    expect(find.text('message.delta'), findsNothing);
    expect(find.text('Restore'), findsOneWidget);
    await tester.tap(find.text('Tools'));
    await tester.pumpAndSettle();
    expect(find.text('run.started'), findsNothing);
    expect(find.text('tool.started'), findsOneWidget);
    expect(find.text('checkpoint.created'), findsOneWidget);
  });

  testWidgets(
    'phone layout uses the floating tab bar and lists bots with cost',
    (tester) async {
      await setSize(tester, const Size(400, 800));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [backendProvider.overrideWithValue(FakeBackend())],
          child: const CasamaApp(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(FloatingTabChrome), findsOneWidget);
      expect(find.text('Ada'), findsOneWidget);
      expect(find.textContaining('\$0.0123 today'), findsOneWidget);
    },
  );

  testWidgets('desktop layout shows bots, chat and computer side by side', (
    tester,
  ) async {
    await setSize(tester, const Size(1600, 1000));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [backendProvider.overrideWithValue(FakeBackend())],
        child: const CasamaApp(),
      ),
    );
    await tester.pumpAndSettle();
    // The sidebar lists the bots; the content asks to pick one.
    expect(find.byKey(const Key('sidebar-bot-$botId')), findsOneWidget);
    expect(find.text('Select a bot to chat'), findsOneWidget);
    await tester.tap(find.text('Ada'));
    await tester.pumpAndSettle();
    expect(find.byType(ChatScreen), findsOneWidget);
    expect(find.text('Team computer'), findsOneWidget);
    expect(find.text('Asleep'), findsOneWidget);
    // Asleep: the button wakes it.
    expect(find.text('Wake up'), findsOneWidget);

    // The computer panel is resized by dragging its left edge.
    double panelWidth() => tester.getSize(find.byType(ComputerScreen)).width;
    expect(panelWidth(), 420);
    await tester.drag(
      find.byKey(const Key('computerPanelResize')),
      const Offset(-120, 0),
    );
    await tester.pumpAndSettle();
    // The edge follows the pointer exactly, with no start threshold eating the first pixels.
    expect(panelWidth(), 540);
    // Grabbing again right away keeps dragging (it isn't a double click), and never below 360.
    await tester.drag(
      find.byKey(const Key('computerPanelResize')),
      const Offset(600, 0),
    );
    await tester.pumpAndSettle();
    expect(panelWidth(), 360);
    // A double click puts the default width back.
    await tester.tap(find.byKey(const Key('computerPanelResize')));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.byKey(const Key('computerPanelResize')));
    await tester.pumpAndSettle();
    expect(panelWidth(), 420);
  });

  testWidgets('onboarding advances after creating a workspace', (tester) async {
    await setSize(tester, const Size(500, 1000));
    final backend = _NoWelcome()..hasOrg = false;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [backendProvider.overrideWithValue(backend)],
        child: const CasamaApp(),
      ),
    );
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    // New people land in the welcome chat (D-129); the wizard is behind "Set up manually".
    await tester.tap(find.byKey(const Key('setUpManually')));
    await tester.pumpAndSettle();
    expect(find.text('Set up your workspace'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('workspaceName')), 'New Org');
    await tester.tap(find.byKey(const Key('createWorkspace')));
    await tester.pumpAndSettle();
    expect(backend.createdOrgs, 1);
    // Step 1 is complete (check icon) once the workspace exists.
    expect(find.byIcon(LucideIcons.check), findsWidgets);
  });

  testWidgets('stored messages render oldest first', (tester) async {
    await setSize(tester, const Size(500, 900));
    final backend = FakeBackend()
      ..storedMessages = [
        ChatMessageView(
          id: '1',
          role: 'user',
          text: 'First question',
          createdAt: DateTime(2026, 1, 1, 10),
        ),
        ChatMessageView(
          id: '2',
          role: 'assistant',
          text: 'First answer',
          createdAt: DateTime(2026, 1, 1, 10, 1),
        ),
      ];
    await tester.pumpWidget(
      harness(backend, const ChatScreen(botId: botId, conversationId: convId)),
    );
    await tester.pumpAndSettle();
    final q = tester.getTopLeft(find.text('First question')).dy;
    final a = tester.getTopLeft(find.textContaining('First answer')).dy;
    expect(q, lessThan(a));
  });
}

class _NoWelcome extends FakeBackend {
  @override
  Future<WelcomeChat> startWelcome({String? firstName}) =>
      Completer<WelcomeChat>().future;
}

/// Chats showing the bot's steps (the detailed view, D-162).
class StepsShown extends ShowBotSteps {
  @override
  bool build() => true;
}
