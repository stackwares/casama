// While a person has a bot's screen and the bot waits for it, the chat offers Hand Back right there.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama/features/chat/chat_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

Future<FakeBackend> _pausedForPerson(
  WidgetTester tester, {
  bool mine = true,
}) async {
  await setSize(tester, const Size(500, 900));
  final backend = FakeBackend()
    ..leaseHeld = mine
    ..leaseHeldByOther = !mine;
  await tester.pumpWidget(
    harness(backend, const ChatScreen(botId: botId, conversationId: convId)),
  );
  await tester.pumpAndSettle();
  await tester.enterText(
    find.byKey(const Key('messageInput')),
    'Book the table on the site',
  );
  await tester.pump();
  await tester.tap(find.byKey(const Key('sendButton')));
  await tester.pump();
  backend.runEventsController
    ..add(
      ev(1, 'run.started', {
        'trigger': 'chat',
        'model': 'm',
        'computer_id': computerId,
      }),
    )
    ..add(
      ev(2, 'tool.started', {
        'call_id': 'c1',
        'tool': 'browser.open',
        'args_redacted': <String, Object?>{},
      }),
    )
    ..add(
      ev(3, 'lease.changed', {
        'computer_id': computerId,
        'holder_type': 'user',
        'mode': 'control',
      }),
    );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  return backend;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    'your screen: Hand Back on the pause notice releases it, then the buttons go',
    (tester) async {
      final backend = await _pausedForPerson(tester);
      expect(find.textContaining('a person is in control'), findsOneWidget);
      expect(find.byKey(const Key('chatHandBack')), findsOneWidget);
      expect(find.byKey(const Key('chatAllowShell')), findsOneWidget);
      expect(find.byKey(const Key('chatOpenLive')), findsNothing);

      await tester.tap(find.byKey(const Key('chatHandBack')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(backend.leaseHeld, isFalse);
      expect(backend.releasedNote, isNull);
      expect(find.byKey(const Key('chatHandBack')), findsNothing);

      // The bot picks up again: the notice says so and no buttons come back.
      backend.runEventsController.add(
        ev(4, 'lease.changed', {
          'computer_id': computerId,
          'holder_type': 'bot',
          'mode': 'control',
        }),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('The bot is back in control'), findsOneWidget);
      expect(find.byKey(const Key('chatHandBack')), findsNothing);
      await tester.pump(const Duration(seconds: 3));
    },
  );

  testWidgets(
    'your screen: let it use terminal and files keeps the screen and hides that button',
    (tester) async {
      final backend = await _pausedForPerson(tester);
      await tester.tap(find.byKey(const Key('chatAllowShell')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(backend.leaseHeld, isTrue);
      expect(backend.leaseAllowShell, isTrue);
      expect(find.byKey(const Key('chatAllowShell')), findsNothing);
      expect(find.byKey(const Key('chatHandBack')), findsOneWidget);
      await tester.pump(const Duration(seconds: 6));
    },
  );

  testWidgets(
    'tapping "Waiting for you to hand back the screen" hands it back',
    (tester) async {
      final backend = await _pausedForPerson(tester);
      expect(find.byKey(const Key('workingHandBack')), findsOneWidget);
      await tester.tap(find.byKey(const Key('workingHandBack')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(backend.leaseHeld, isFalse);
      await tester.pump(const Duration(seconds: 3));
    },
  );

  testWidgets(
    'someone else has the screen: no Hand Back, Open Live View instead',
    (tester) async {
      final backend = await _pausedForPerson(tester, mine: false);
      expect(find.byKey(const Key('chatHandBack')), findsNothing);
      expect(find.byKey(const Key('chatAllowShell')), findsNothing);
      expect(find.text('Someone else is in control'), findsOneWidget);
      expect(find.byKey(const Key('chatOpenLive')), findsOneWidget);
      expect(backend.leaseHeldByOther, isTrue);
    },
  );

  testWidgets('screen already back with the bot: the notice has no buttons', (
    tester,
  ) async {
    final backend = await _pausedForPerson(tester);
    backend.leaseHeld = false;
    await tester.pump(const Duration(seconds: 21));
    expect(find.byKey(const Key('chatHandBack')), findsNothing);
  });
}
