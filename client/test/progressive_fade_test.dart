// Pages without an app bar let content dissolve under the status bar instead of slicing it off.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama_app/features/auth/account_screen.dart';
import 'package:casama_app/theme/app_tokens.dart';
import 'package:casama_app/ui/progressive_fade.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

void main() {
  test('the fade reaches 20 past the status bar, and nowhere without one', () {
    expect(ProgressiveFade.reachFor(47), 47 + AppSpace.lg);
    expect(ProgressiveFade.reachFor(47, height: 120), 120);
    expect(ProgressiveFade.reachFor(0), 0);
    expect(ProgressiveFade.reachFor(0, height: 120), 0);
  });

  testWidgets('the new-password page scrolls under the status bar, faded there, and still starts below it', (tester) async {
    // Short enough that the page scrolls.
    await setSize(tester, const Size(390, 400));
    tester.view.padding = const FakeViewPadding(top: 47);
    await tester.pumpWidget(harness(FakeBackend(), const NewPasswordScreen()));
    await tester.pump();
    expect(find.byWidgetPredicate((w) => w is ShaderMask && w.blendMode == BlendMode.dstIn), findsOneWidget);
    final content = find.byKey(const Key('newPasswordScreen'));
    final scroll = find.ancestor(of: content, matching: find.byType(SingleChildScrollView));
    expect(tester.getTopLeft(scroll).dy, 0);
    expect(tester.getTopLeft(content).dy, 47 + AppSpace.lg);
  });
}
