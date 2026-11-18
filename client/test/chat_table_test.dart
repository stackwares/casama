import 'package:casama/features/chat/widgets/chat_markdown.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'app_test.dart' show harness;
import 'fake_backend.dart';

Widget _bubble(String md) => Scaffold(
  body: Center(
    child: SizedBox(width: 340, child: ChatMarkdown(data: md)),
  ),
);

const _wide = '''
| # | From | App | Ask | Reply draft | Status |
|---|------|-----|-----|-------------|--------|
| 1 | angela@example.com | NexTalk | Status of a hardship refund for three months | Confirmed and escalated, no amount promised | Draft |
| 2 | kim@example.com | Stein AI | What personal data is stored about me | Answered from the privacy section | Draft |
''';

void main() {
  testWidgets(
    'a table wider than the bubble scrolls sideways and opens full screen',
    (tester) async {
      await tester.pumpWidget(harness(FakeBackend(), _bubble(_wide)));
      await tester.pumpAndSettle();

      expect(find.byType(ChatTable), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'no overflow');
      final scroll = tester.widget<SingleChildScrollView>(
        find.descendant(
          of: find.byType(ChatTable),
          matching: find.byType(SingleChildScrollView),
        ),
      );
      expect(scroll.scrollDirection, Axis.horizontal);
      expect(scroll.controller!.position.maxScrollExtent, greaterThan(0));

      await tester.drag(find.text('NexTalk'), const Offset(-300, 0));
      await tester.pumpAndSettle();
      expect(scroll.controller!.offset, greaterThan(0));

      await tester.tap(find.text('View full table'));
      await tester.pumpAndSettle();
      expect(find.text('Table'), findsOneWidget);
      expect(find.text('Stein AI'), findsWidgets);
    },
  );

  testWidgets('a table that fits has no full-screen button', (tester) async {
    await tester.pumpWidget(
      harness(FakeBackend(), _bubble('| A | B |\n|---|---|\n| 1 | 2 |\n')),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ChatTable), findsOneWidget);
    expect(find.text('View full table'), findsNothing);
  });
}
