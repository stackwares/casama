import 'package:casama_app/features/chat/widgets/chat_markdown.dart';
import 'package:casama_app/features/chat/widgets/chat_widgets.dart';
import 'package:casama_app/features/chat/widgets/mentions.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'app_test.dart' show harness;
import 'fake_backend.dart';

/// @mentions in group chats (D-118) show bold, with the bot's icon, and open its profile.
void main() {
  final backend = FakeBackend();
  final ada = backend.bot(id: 'bot-ada', name: 'Ada');
  final adaL = backend.bot(id: 'bot-adal', name: 'Ada Lovelace');
  final bea = backend.bot(id: 'bot-bea', name: 'Bea');

  test('only members and the whole group count, never an email address', () {
    final scope = MentionScope(bots: [ada, adaL, bea], child: const SizedBox());
    expect(mentionsIn(scope, '@everyone look'), ['everyone']);
    expect(mentionsIn(scope, 'hi @ada and @Ada Lovelace, @TEAM!'), [
      'ada',
      'Ada Lovelace',
      'TEAM',
    ]);
    expect(mentionsIn(scope, 'mail ada@bea.com or @adam or @@bea'), isEmpty);
    expect(scope.botNamed('ADA'), ada);
    expect(scope.botNamed('everyone'), isNull);
  });

  testWidgets(
    'your message shows mentions as pills; a bot\'s opens its profile',
    (tester) async {
      final opened = <Bot>[];
      await tester.pumpWidget(
        harness(
          backend,
          Scaffold(
            body: MentionScope(
              bots: [ada, bea],
              onOpen: opened.add,
              child: const UserBubble(text: '@everyone hi, @Bea please check'),
            ),
          ),
        ),
      );
      expect(find.byType(MentionChip), findsNWidgets(2));
      expect(find.text('@everyone'), findsOneWidget);
      expect(find.text('@Bea'), findsOneWidget);
      final label = tester.widget<Text>(find.text('@Bea'));
      expect(label.style?.fontWeight, FontWeight.w700);
      await tester.tap(find.byKey(const Key('mention-bot-bea')));
      expect(opened, [bea]);
    },
  );

  testWidgets('outside a group chat, nothing changes', (tester) async {
    await tester.pumpWidget(
      harness(backend, const Scaffold(body: UserBubble(text: 'hey @Bea'))),
    );
    expect(find.byType(MentionChip), findsNothing);
    expect(find.text('hey @Bea'), findsOneWidget);
  });

  testWidgets('a bot\'s reply shows mentions too, in its Markdown', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        backend,
        Scaffold(
          body: MentionScope(
            bots: [ada, bea],
            child: const ChatMarkdown(
              data: 'Thanks **@Ada**. Over to @bea; `@Bea` in code stays code.',
            ),
          ),
        ),
      ),
    );
    expect(find.byType(MentionChip), findsNWidgets(2));
    expect(find.text('@Ada'), findsOneWidget);
    // Shown with the member's own spelling.
    expect(find.text('@Bea'), findsOneWidget);
  });
}
