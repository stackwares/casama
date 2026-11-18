// Search settings: the field above the list filters rows by title, subtitle, section and extra words.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama/features/settings/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

Future<void> _open(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  await setSize(tester, const Size(430, 2400));
  await tester.pumpWidget(harness(FakeBackend(), const SettingsScreen()));
  await tester.pumpAndSettle();
}

Future<void> _type(WidgetTester tester, String text) async {
  await tester.enterText(find.byKey(const Key('settingsSearch')), text);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a title narrows the list to its row', (tester) async {
    await _open(tester);
    await _type(tester, 'quiet');
    expect(find.byKey(const Key('settingsQuietHours')), findsOneWidget);
    expect(find.byKey(const Key('settingsAppearance')), findsNothing);
    expect(find.byKey(const Key('settingsAccount')), findsNothing);
    expect(find.byKey(const Key('settingsAboutYou')), findsNothing);
  });

  testWidgets('extra words find the row whose page holds the setting', (
    tester,
  ) async {
    await _open(tester);
    await _type(tester, 'Dark Mode');
    expect(find.byKey(const Key('settingsAppearance')), findsOneWidget);
    expect(find.byKey(const Key('settingsQuietHours')), findsNothing);

    await _type(tester, 'password');
    expect(find.byKey(const Key('settingsAccount')), findsOneWidget);
    expect(find.byKey(const Key('settingsSecrets')), findsOneWidget);
  });

  testWidgets('rows folded under Advanced show while searching', (
    tester,
  ) async {
    await _open(tester);
    expect(find.byKey(const Key('settingsComputers')), findsNothing);
    await _type(tester, 'docker');
    expect(find.byKey(const Key('settingsComputers')), findsOneWidget);
  });

  testWidgets('no match says so, and clearing brings everything back', (
    tester,
  ) async {
    await _open(tester);
    await _type(tester, 'zzzz');
    expect(find.text('No settings match “zzzz”.'), findsOneWidget);
    expect(find.byKey(const Key('settingsAboutYou')), findsNothing);

    await tester.tap(find.byKey(const Key('settingsSearchClear')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('settingsAboutYou')), findsOneWidget);
    expect(find.byKey(const Key('settingsAppearance')), findsOneWidget);
    expect(find.byKey(const Key('settingsQuietHours')), findsOneWidget);
    expect(find.text('No settings match “zzzz”.'), findsNothing);
  });
}
