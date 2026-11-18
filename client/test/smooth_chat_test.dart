// A smoother chat: streamed words flow in at a steady pace instead of a batch every 200 ms, and
// "Thinking…" doesn't flash under a finished reply while the run wraps up.
import 'package:casama/features/chat/chat_screen.dart';
import 'package:casama/features/chat/widgets/chat_widgets.dart';
import 'package:casama/ui/motion.dart';
import 'package:casama/ui/shell_header.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

Future<FakeBackend> _openAndSend(WidgetTester tester) async {
  await setSize(tester, const Size(500, 900));
  final backend = FakeBackend();
  await tester.pumpWidget(
    harness(backend, const ChatScreen(botId: botId, conversationId: convId)),
  );
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const Key('messageInput')), 'who are you');
  await tester.pump();
  await tester.tap(find.byKey(const Key('sendButton')));
  await tester.pump();
  backend.runEventsController.add(
    ev(1, 'run.started', {
      'trigger': 'chat',
      'model': 'm',
      'computer_id': null,
    }),
  );
  return backend;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('a batch of words flows in over a moment, whole words at a time', (
    tester,
  ) async {
    const reply =
        'I am Email Bot, the bot that lives in your inbox and drafts replies for you to approve.';
    final backend = await _openAndSend(tester);
    backend.runEventsController.add(
      ev(2, 'message.delta', {'message_id': 'a1', 'text': reply}),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final partial = find.textContaining('I am Email', findRichText: true);
    expect(partial, findsOneWidget);
    expect(
      find.textContaining('to approve.', findRichText: true),
      findsNothing,
      reason: 'not all at once',
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      find.textContaining('to approve.', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets(
    'no Thinking flashes under a finished reply while the run wraps up',
    (tester) async {
      final backend = await _openAndSend(tester);
      backend.runEventsController
        ..add(
          ev(2, 'message.delta', {'message_id': 'a1', 'text': 'Hey again.'}),
        )
        ..add(
          ev(3, 'message.completed', {
            'message_id': 'a1',
            'content': [
              {'type': 'text', 'text': 'Hey again.'},
            ],
          }),
        );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Hey again.', findRichText: true), findsOneWidget);
      expect(find.byType(WorkingIndicator), findsNothing);
      // Still going a while later (more work after the reply): now it says so.
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(WorkingIndicator), findsOneWidget);
      // A step starting shows it at once.
      backend.runEventsController
        ..add(ev(4, 'message.delta', {'message_id': 'a2', 'text': 'Checking.'}))
        ..add(
          ev(5, 'message.completed', {
            'message_id': 'a2',
            'content': [
              {'type': 'text', 'text': 'Checking.'},
            ],
          }),
        )
        ..add(
          ev(6, 'tool.started', {
            'call_id': 'c1',
            'tool': 'web.search',
            'args_redacted': <String, Object?>{},
          }),
        );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byType(WorkingIndicator), findsOneWidget);
    },
  );

  testWidgets('Thinking and the header status shimmer: dim words, a bright shine', (tester) async {
    await _openAndSend(tester);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final line = find.byType(WorkingIndicator);
    expect(line, findsOneWidget);
    expect(find.descendant(of: line, matching: find.byType(Shimmer)), findsOneWidget);
    // The words are dimmer than the shine, or the shine can't be seen, and dimmed by color: the
    // shine keeps the text's opacity, so see-through text would leave it just as faint.
    final shine = tester.widget<Shimmer>(find.descendant(of: line, matching: find.byType(Shimmer))).color;
    final rich = tester.widgetList<Text>(find.descendant(of: line, matching: find.byType(Text))).firstWhere((t) => t.textSpan is TextSpan && (t.textSpan! as TextSpan).children != null);
    final verb = (rich.textSpan! as TextSpan).children!.first as TextSpan;
    expect(verb.style!.color!.a, 1.0);
    expect(verb.style!.color, isNot(shine));
    expect(find.descendant(of: find.byType(ShellHeader), matching: find.byType(Shimmer)), findsOneWidget);
  });
}
