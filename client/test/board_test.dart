import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kasama_app/features/board/board_screen.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

void main() {
  testWidgets('columns show tickets; a new ticket assigned to a bot is created', (tester) async {
    await setSize(tester, const Size(1500, 900));
    final backend = FakeBackend();
    await tester.pumpWidget(harness(backend, const BoardScreen()));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('column-todo')), findsOneWidget);
    expect(find.descendant(of: find.byKey(const Key('column-todo')), matching: find.text('Summarize the release notes')), findsOneWidget);

    await tester.tap(find.byKey(const Key('newTicket')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('ticketTitle')), 'Fix the login loop');
    await tester.tap(find.byKey(const Key('ticketBot')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ada').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('createTicket')));
    await tester.pumpAndSettle();
    final created = backend.taskList.last;
    expect(created.title, 'Fix the login loop');
    expect(created.assigneeBotId, botId);
    expect(find.text('Fix the login loop'), findsOneWidget);
  });

  testWidgets('dragging a ticket to another column moves it', (tester) async {
    await setSize(tester, const Size(1500, 900));
    final backend = FakeBackend();
    await tester.pumpWidget(harness(backend, const BoardScreen()));
    await tester.pumpAndSettle();
    final card = tester.getCenter(find.byKey(const Key('ticket-t1')));
    final target = tester.getCenter(find.byKey(const Key('column-done')));
    final g = await tester.startGesture(card);
    await tester.pump(const Duration(milliseconds: 400));
    await g.moveTo(target);
    await tester.pump();
    await g.up();
    await tester.pumpAndSettle();
    expect(backend.taskList.first.status.value, 'done');
  });

  testWidgets('the ticket sheet changes status and posts comments', (tester) async {
    await setSize(tester, const Size(1500, 1000));
    final backend = FakeBackend();
    await tester.pumpWidget(harness(backend, const BoardScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('ticket-t1')));
    await tester.pumpAndSettle();
    expect(find.text('Started reading.'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('commentField')), 'Please add the dates.');
    await tester.tap(find.byKey(const Key('sendComment')));
    await tester.pumpAndSettle();
    expect(backend.taskCommentList['t1']!.last.bodyMd, 'Please add the dates.');
    expect(find.text('Please add the dates.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('sheetStatus')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('In review').last);
    await tester.pumpAndSettle();
    expect(backend.taskList.first.status.value, 'in_review');
  });

  testWidgets('filters by owner', (tester) async {
    await setSize(tester, const Size(1500, 900));
    final backend = FakeBackend();
    await tester.pumpWidget(harness(backend, const BoardScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('filter-mine')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('ticket-t1')), findsNothing);
    await tester.tap(find.byKey(const Key('filter-bots')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('ticket-t1')), findsOneWidget);
  });
}
