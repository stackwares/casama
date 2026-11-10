import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kasama_app/features/computer/computer_screen.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:kasama_app/app.dart';
import 'package:kasama_app/core/backend.dart';
import 'package:kasama_app/core/providers.dart';
import 'package:kasama_app/features/auth/sign_in_screen.dart';
import 'package:kasama_app/features/chat/chat_controller.dart';
import 'package:kasama_app/features/chat/chat_screen.dart';
import 'package:kasama_app/features/timeline/timeline_screen.dart';
import 'package:kasama_app/l10n/generated/app_localizations.dart';
import 'package:kasama_app/ui/floating_tab_chrome.dart';

import 'fake_backend.dart';
import 'package:kasama_app/core/local_cache.dart';

Widget harness(FakeBackend backend, Widget child, {LocalCache cache = const NoCache()}) => ProviderScope(
  overrides: [backendProvider.overrideWithValue(backend), localCacheProvider.overrideWithValue(cache)],
  child: MaterialApp(localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales, home: child),
);

Future<void> setSize(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('sign-in validates email and password', (tester) async {
    await tester.pumpWidget(harness(FakeBackend()..signedIn = false, const SignInScreen()));
    await tester.tap(find.byKey(const Key('submit')));
    await tester.pump();
    expect(find.text('Enter a valid email address'), findsOneWidget);
    expect(find.text('Use at least 6 characters'), findsOneWidget);
    await tester.tap(find.byKey(const Key('toggleMode')));
    await tester.pump();
    expect(find.text('Create your account'), findsOneWidget);
  });

  testWidgets('chat streams text, folds tool steps into cards, and can stop a run', (tester) async {
    await setSize(tester, const Size(500, 900));
    final backend = FakeBackend();
    await tester.pumpWidget(harness(backend, const ChatScreen(botId: botId, conversationId: convId)));
    await tester.pumpAndSettle();
    expect(find.text('Say hello to Ada.'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('messageInput')), 'Research example.com');

    await tester.pump();
    await tester.tap(find.byKey(const Key('sendButton')));
    await tester.pump();
    expect(backend.sent, ['Research example.com']);
    expect(find.text('Research example.com'), findsOneWidget);
    expect(find.byKey(const Key('stopButton')), findsOneWidget);

    backend.runEventsController
      ..add(ev(1, 'run.started', {'trigger': 'chat', 'model': 'm', 'computer_id': null}))
      ..add(
        ev(2, 'tool.started', {
          'call_id': 'c1',
          'tool': 'shell.exec',
          'args_redacted': {'command': 'ls -la'},
        }),
      )
      ..add(ev(3, 'tool.output', {'call_id': 'c1', 'chunk': 'report.md\n'}))
      ..add(ev(4, 'tool.completed', {'call_id': 'c1', 'result_preview': 'exit code 0', 'artifact_path': null, 'duration_ms': 42}))
      ..add(ev(5, 'message.delta', {'message_id': 'a1', 'text': 'Here is '}))
      ..add(ev(6, 'message.delta', {'message_id': 'a1', 'text': 'the **report**.'}))
      ..add(ev(7, 'usage', {'tokens_in': 1000, 'tokens_out': 50, 'cost_usd': 0.0021}));
    await tester.pump();
    // Tool steps read in plain words, with the command and how long it took.
    expect(find.text('Ran a command'), findsOneWidget);
    expect(find.textContaining('ls -la'), findsOneWidget);
    expect(find.text('42 ms'), findsOneWidget);
    expect(find.textContaining('\$0.0021 · 1050 tokens'), findsOneWidget);

    // Expanding the card shows the streamed output.
    await tester.tap(find.text('Ran a command'));
    await tester.pump(const Duration(milliseconds: 400));
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
  });

  testWidgets('a failed run shows the reason and orphaned partial text is dropped on completion', (tester) async {
    final container = ProviderContainer(overrides: [backendProvider.overrideWithValue(FakeBackend())]);
    addTearDown(container.dispose);
    final c = container.read(chatControllerProvider(botId).notifier);
    c.apply(ev(1, 'message.delta', {'message_id': 'crashed', 'text': 'partial'}));
    c.apply(ev(2, 'message.delta', {'message_id': 'final', 'text': 'Full answer'}));
    c.apply(
      ev(3, 'message.completed', {
        'message_id': 'final',
        'content': [
          {'type': 'text', 'text': 'Full answer'},
        ],
      }),
    );
    c.apply(ev(4, 'run.completed', {'final_message_id': 'final'}));
    final texts = container.read(chatControllerProvider(botId)).entries.whereType<MessageEntry>().map((m) => m.text);
    expect(texts, ['Full answer']);

    c.apply(ev(5, 'run.failed', {'error_code': 'budget_exceeded', 'message': 'This run reached its budget of \$1.'}));
    final last = container.read(chatControllerProvider(botId)).entries.last as NoticeEntry;
    expect(last.kind, NoticeKind.failed);
  });

  testWidgets('timeline filters events and offers restore on checkpoints', (tester) async {
    final backend = FakeBackend()
      ..storedEvents = [
        ev(1, 'run.started', {'trigger': 'chat', 'model': 'm', 'computer_id': null}),
        ev(2, 'checkpoint.created', {'checkpoint_id': '66666666-6666-4666-8666-666666666666', 'label': 'Before: rm -rf old'}),
        ev(3, 'tool.started', {
          'call_id': 'c1',
          'tool': 'shell.exec',
          'args_redacted': {'command': 'rm -rf old'},
        }),
        ev(4, 'message.delta', {'message_id': 'a', 'text': 'Done'}),
        ev(5, 'run.completed', {'final_message_id': 'a'}),
      ];
    await tester.pumpWidget(harness(backend, const RunTimelineScreen(botId: botId, runId: runId)));
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

  testWidgets('phone layout uses the floating tab bar and lists bots with cost', (tester) async {
    await setSize(tester, const Size(400, 800));
    await tester.pumpWidget(ProviderScope(overrides: [backendProvider.overrideWithValue(FakeBackend())], child: const KasamaApp()));
    await tester.pumpAndSettle();
    expect(find.byType(FloatingTabChrome), findsOneWidget);
    expect(find.text('Ada'), findsOneWidget);
    expect(find.textContaining('\$0.0123 today'), findsOneWidget);
  });

  testWidgets('desktop layout shows bots, chat and computer side by side', (tester) async {
    await setSize(tester, const Size(1600, 1000));
    await tester.pumpWidget(ProviderScope(overrides: [backendProvider.overrideWithValue(FakeBackend())], child: const KasamaApp()));
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
    await tester.drag(find.byKey(const Key('computerPanelResize')), const Offset(-120, 0));
    await tester.pumpAndSettle();
    expect(panelWidth(), inInclusiveRange(500, 540)); // minus the drag start threshold
    // Never narrower than 360.
    await tester.drag(find.byKey(const Key('computerPanelResize')), const Offset(600, 0));
    await tester.pumpAndSettle();
    expect(panelWidth(), 360);
  });

  testWidgets('onboarding advances after creating a workspace', (tester) async {
    await setSize(tester, const Size(500, 1000));
    final backend = FakeBackend()..hasOrg = false;
    await tester.pumpWidget(ProviderScope(overrides: [backendProvider.overrideWithValue(backend)], child: const KasamaApp()));
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
        ChatMessageView(id: '1', role: 'user', text: 'First question', createdAt: DateTime(2026, 1, 1, 10)),
        ChatMessageView(id: '2', role: 'assistant', text: 'First answer', createdAt: DateTime(2026, 1, 1, 10, 1)),
      ];
    await tester.pumpWidget(harness(backend, const ChatScreen(botId: botId, conversationId: convId)));
    await tester.pumpAndSettle();
    final q = tester.getTopLeft(find.text('First question')).dy;
    final a = tester.getTopLeft(find.textContaining('First answer')).dy;
    expect(q, lessThan(a));
  });
}
