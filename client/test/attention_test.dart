import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama_app/core/backend.dart';
import 'package:casama_app/features/inbox/inbox_screen.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

/// Attention rules (D-153): "Why am I seeing this?" and "Less like this".
void main() {
  testWidgets('the why sheet shows the rule, the data, that it waited for the brief, and takes "less like this"', (tester) async {
    await setSize(tester, const Size(500, 900));
    final backend = FakeBackend();
    final n = NotificationView(
      id: 'n1',
      kind: 'suggestion',
      title: 'Book the dentist',
      body: 'You have time on Friday',
      createdAt: DateTime(2027),
      whyRule: 'A suggestion from Nudge during a check-in scan',
      whyData: const ['calendar', 'health'],
      urgency: 'normal',
      heldReason: 'meeting',
    );
    await tester.pumpWidget(harness(backend, Scaffold(body: WhySheet(notification: n))));
    await tester.pumpAndSettle();
    expect(find.text('A suggestion from Nudge during a check-in scan'), findsOneWidget);
    expect(find.text('Used: calendar, health'), findsOneWidget);
    expect(find.textContaining('in a meeting'), findsOneWidget);
    await tester.tap(find.byKey(const Key('lessLikeThis')));
    await tester.pumpAndSettle();
    expect(backend.lessLiked, ['n1']);
    expect(find.text('Got it, fewer like this'), findsOneWidget);
  });
}
