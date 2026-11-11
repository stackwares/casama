import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama_app/app.dart';
import 'package:casama_app/core/providers.dart';
import 'package:casama_app/features/settings/model_keys_screen.dart';
import 'package:casama_app/features/settings/settings_screen.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

void main() {
  testWidgets('settings shows its groups in two columns on wide windows, one on narrow ones', (tester) async {
    await setSize(tester, const Size(1500, 1200));
    await tester.pumpWidget(harness(FakeBackend(), const SettingsScreen()));
    await tester.pumpAndSettle();
    final workspace = tester.getTopLeft(find.text('Workspace'));
    final appearance = tester.getTopLeft(find.text('Appearance'));
    expect(appearance.dx, greaterThan(workspace.dx + 300));
    expect(appearance.dy, workspace.dy);

    await setSize(tester, const Size(700, 2400));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('Appearance')).dx, tester.getTopLeft(find.text('Workspace')).dx);
    expect(tester.getTopLeft(find.text('Appearance')).dy, greaterThan(tester.getTopLeft(find.text('Workspace')).dy));
  });

  testWidgets('on wide windows a settings page opens beside the settings list, the open row highlighted', (tester) async {
    await setSize(tester, const Size(1600, 1000));
    await tester.pumpWidget(ProviderScope(overrides: [backendProvider.overrideWithValue(FakeBackend())], child: const CasamaApp()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('sidebar-nav-/settings')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Model keys').first);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('settingsPane')), findsOneWidget);
    expect(find.byType(ModelKeysScreen), findsOneWidget);
    // Another row swaps the page beside the list.
    await tester.tap(find.descendant(of: find.byKey(const Key('settingsPane')), matching: find.text('Skills')));
    await tester.pumpAndSettle();
    expect(find.byType(ModelKeysScreen), findsNothing);
    expect(find.byKey(const Key('settingsPane')), findsOneWidget);

    // Narrower windows keep one page at a time.
    await setSize(tester, const Size(1100, 1000));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('settingsPane')), findsNothing);
  });
}
