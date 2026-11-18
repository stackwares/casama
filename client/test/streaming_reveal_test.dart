// Smooth streaming: half-written Markdown is closed or held back, the reveal keeps an even pace
// between the server's batches, and a reply finishing neither pops its last words in nor parses
// itself again.
import 'package:casama/features/chat/chat_controller.dart';
import 'package:casama/features/chat/widgets/chat_markdown.dart';
import 'package:casama/features/chat/widgets/chat_widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_test.dart' show harness;
import 'fake_backend.dart';

void main() {
  group('healStreamingMarkdown', () {
    final cases = <String, String>{
      // Finished Markdown is left alone.
      'plain words': 'plain words',
      'some **bold** and `code`': 'some **bold** and `code`',
      'see [the docs](https://x.y) now': 'see [the docs](https://x.y) now',
      // Open inline markers are closed...
      'some **bold wo': 'some **bold wo**',
      'run `npm inst': 'run `npm inst`',
      'a ~~gone': 'a ~~gone~~',
      '**bold and `code': '**bold and `code`**',
      // ...or dropped while nothing follows them yet.
      'some **': 'some',
      'first line\n**': 'first line',
      // Escaped markers and markers inside code don't count.
      r'price \*\*not bold': r'price \*\*not bold',
      'a `**` literal': 'a `**` literal',
      // A link still being typed waits until it's whole.
      'see [the do': 'see',
      'see [the docs](https://x': 'see',
      'look ![a pic': 'look',
      'a [note] here': 'a [note] here',
      // An open code fence is closed; one with only its opener yet shows nothing.
      'Code:\n```dart\nfinal x = 1;': 'Code:\n```dart\nfinal x = 1;\n```',
      'Code:\n```dart': 'Code:',
      'Code:\n```dart\nx\n```\nafter **bo':
          'Code:\n```dart\nx\n```\nafter **bo**',
      // Tables wait for their separator row, and each row until it ends.
      'Intro\n\n| a | b |': 'Intro',
      'Intro\n\n| a | b |\n|---|---|': 'Intro\n\n| a | b |\n|---|---|',
      'Intro\n\n| a | b |\n|---|---|\n| 1 | 2 |\n| 3 ':
          'Intro\n\n| a | b |\n|---|---|\n| 1 | 2 |',
      'Intro\n\n| a | b |\n|---|-': 'Intro',
    };
    for (final MapEntry(key: input, value: want) in cases.entries) {
      test(
        input.replaceAll('\n', r'\n'),
        () => expect(healStreamingMarkdown(input), want),
      );
    }
  });

  group('RevealPace', () {
    test('keeps an even pace between batches once the rate is known', () {
      final pace = RevealPace();
      // 200 ms batches of 40 characters: 200 characters a second.
      for (var i = 0; i < 20; i++) {
        pace.arrived(40, Duration(milliseconds: 200 * i));
      }
      expect(pace.rate, closeTo(200, 5));
      // Just after a batch lands and just before the next, the speed barely moves.
      final justLanded = pace.speed(50 + 40, live: true);
      final beforeNext = pace.speed(50, live: true);
      expect(justLanded / beforeNext, lessThan(1.3));
      expect(beforeNext, greaterThan(150));
    });

    test('hurries when far behind, and drains a finished reply quickly', () {
      final pace = RevealPace();
      for (var i = 0; i < 10; i++) {
        pace.arrived(20, Duration(milliseconds: 200 * i));
      }
      // 100/s; a 600-character burst gets shown within about half a second.
      expect(pace.speed(600, live: true), greaterThanOrEqualTo(1200));
      expect(pace.speed(100, live: false), greaterThanOrEqualTo(100 / 0.26));
    });
  });

  testWidgets(
    'a reply finishing keeps its text and drains instead of popping in',
    (tester) async {
      Widget reply(String text, {required bool streaming}) => harness(
        FakeBackend(),
        Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: AssistantMessage(
              entry: MessageEntry(
                id: 'm',
                role: 'assistant',
                text: text,
                streaming: streaming,
              ),
            ),
          ),
        ),
      );
      String shown() =>
          tester.widget<ChatMarkdown>(find.byType(ChatMarkdown)).data;

      const first =
          'The valley had eleven dry weeks before the rain came back. ';
      await tester.pumpWidget(reply(first, streaming: true));
      await tester.pump(const Duration(milliseconds: 500));
      final markdown = tester.state(find.byType(ChatMarkdown));

      final full =
          '$first${'Then the river filled again and the fields turned green. ' * 3}'
              .trim();
      await tester.pumpWidget(reply(full, streaming: false));
      await tester.pump();
      // The same Markdown state: nothing was parsed again or reset.
      expect(tester.state(find.byType(ChatMarkdown)), same(markdown));
      // The new words flow in rather than all at once...
      expect(shown().length, lessThan(full.length));
      // ...and are all there shortly after.
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      expect(shown(), full);
      await tester.pumpAndSettle();
    },
  );

  testWidgets('a finished reply from history shows whole right away', (
    tester,
  ) async {
    const text = 'Already written, nothing to reveal.';
    await tester.pumpWidget(
      harness(
        FakeBackend(),
        const Scaffold(
          body: AssistantMessage(
            entry: MessageEntry(id: 'h', role: 'assistant', text: text),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.widget<ChatMarkdown>(find.byType(ChatMarkdown)).data, text);
  });
}
