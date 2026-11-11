import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama_app/features/auth/account_screen.dart';
import 'package:casama_app/features/workspaces/workspace_files.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

/// The text field (by its key) that has keyboard focus right now, if any.
Finder _focused(Key key) => find.descendant(of: find.byKey(key), matching: find.byWidgetPredicate((w) => w is EditableText && w.focusNode.hasFocus));

void main() {
  testWidgets('git sync: Next walks the fields, Done saves', (tester) async {
    await setSize(tester, const Size(900, 1400));
    final backend = FakeBackend();
    await tester.pumpWidget(
      harness(
        backend,
        Scaffold(
          body: SingleChildScrollView(
            child: WorkspaceFilesSection(orgId: orgId, pickZip: () async => Uint8List.fromList([1]), saveZip: (b) async {}),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('gitSync')));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(find.byKey(const Key('gitRepo'))).textInputAction, TextInputAction.next);
    expect(tester.widget<TextField>(find.byKey(const Key('gitPath'))).textInputAction, TextInputAction.done);

    await tester.enterText(find.byKey(const Key('gitRepo')), 'acme/casama-config');
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();
    expect(_focused(const Key('gitBranch')), findsOneWidget);

    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();
    expect(_focused(const Key('gitPath')), findsOneWidget);
    await tester.enterText(find.byKey(const Key('gitPath')), 'casama');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(backend.fileActions.last, 'git:acme/casama-config:main:casama');
  });

  testWidgets('new password: Next skips the show button and lands on the second field', (tester) async {
    await setSize(tester, const Size(500, 1000));
    final backend = FakeBackend()..newPasswordNeeded = true;
    await tester.pumpWidget(harness(backend, const NewPasswordScreen()));
    await tester.enterText(find.byKey(const Key('newPassword')), 'brand-new-pw');
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();
    expect(_focused(const Key('newPasswordAgain')), findsOneWidget);
  });
}
