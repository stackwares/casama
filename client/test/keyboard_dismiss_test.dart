// Scrolling a form or search results puts the keyboard away.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama_app/features/auth/account_screen.dart';
import 'package:casama_app/features/bots/bots_screen.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

void main() {
  testWidgets('dragging the new-bot form puts the keyboard away', (tester) async {
    await setSize(tester, const Size(390, 420));
    await tester.pumpWidget(harness(FakeBackend(), const Scaffold(body: CreateBotSheet())));
    await tester.pumpAndSettle();
    final form = find.descendant(of: find.byType(CreateBotSheet), matching: find.byType(SingleChildScrollView)).first;
    expect(tester.widget<SingleChildScrollView>(form).keyboardDismissBehavior, ScrollViewKeyboardDismissBehavior.onDrag);

    final instructions = find.descendant(of: find.byKey(const Key('botInstructions')), matching: find.byType(EditableText));
    await tester.showKeyboard(find.byKey(const Key('botInstructions')));
    expect(tester.widget<EditableText>(instructions).focusNode.hasFocus, isTrue);

    // Drag in the form's left margin, so the gesture starts on the scroll view itself.
    await tester.dragFrom(tester.getTopLeft(form) + const Offset(6, 300), const Offset(0, -150));
    await tester.pump();
    expect(tester.widget<EditableText>(instructions).focusNode.hasFocus, isFalse);
  });

  testWidgets('the new-password page puts the keyboard away on scroll', (tester) async {
    await setSize(tester, const Size(500, 1000));
    await tester.pumpWidget(harness(FakeBackend()..newPasswordNeeded = true, const NewPasswordScreen()));
    final page = find.descendant(of: find.byType(NewPasswordScreen), matching: find.byType(SingleChildScrollView)).first;
    expect(tester.widget<SingleChildScrollView>(page).keyboardDismissBehavior, ScrollViewKeyboardDismissBehavior.onDrag);
  });
}
