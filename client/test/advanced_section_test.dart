// Expert options fold under one "Advanced" row per screen and stay open once opened (D-182).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama_app/features/settings/settings_screen.dart';
import 'package:casama_app/l10n/generated/app_localizations.dart';
import 'package:casama_app/ui/advanced_section.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

Widget _host({bool forceOpen = false}) => ProviderScope(
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: ListView(
        children: [
          AdvancedSection(id: 'test', summary: 'Secret things', forceOpen: forceOpen, children: const [Text('Expert option')]),
        ],
      ),
    ),
  ),
);

void main() {
  testWidgets('folded by default with a summary; a tap opens it and remembers on this device', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();
    expect(find.text('Advanced'), findsOneWidget);
    expect(find.text('Secret things'), findsOneWidget);
    expect(find.text('Expert option'), findsNothing);

    await tester.tap(find.byKey(const Key('advanced-test')));
    await tester.pumpAndSettle();
    expect(find.text('Expert option'), findsOneWidget);
    expect(find.text('Secret things'), findsNothing);
    expect((await SharedPreferences.getInstance()).getStringList('advanced.open'), ['test']);

    await tester.tap(find.byKey(const Key('advanced-test')));
    await tester.pumpAndSettle();
    expect(find.text('Expert option'), findsNothing);
    expect((await SharedPreferences.getInstance()).getStringList('advanced.open'), isEmpty);
  });

  testWidgets('a section opened before starts open', (tester) async {
    SharedPreferences.setMockInitialValues({
      'advanced.open': ['test'],
    });
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();
    expect(find.text('Expert option'), findsOneWidget);
  });

  testWidgets('forceOpen shows it open without remembering', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(_host(forceOpen: true));
    await tester.pumpAndSettle();
    expect(find.text('Expert option'), findsOneWidget);
    expect((await SharedPreferences.getInstance()).getStringList('advanced.open'), isNull);
  });

  testWidgets('Settings keeps secrets, computers, devices and bot steps under Advanced', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await setSize(tester, const Size(430, 2400));
    await tester.pumpWidget(harness(FakeBackend(), const SettingsScreen()));
    await tester.pumpAndSettle();
    for (final everyday in ['Model keys', 'Skills', 'People', 'Quiet hours']) {
      expect(find.text(everyday), findsWidgets, reason: everyday);
    }
    for (final key in ['settingsSecrets', 'settingsComputers', 'settingsDevices', 'showBotSteps']) {
      expect(find.byKey(Key(key)), findsNothing, reason: key);
    }
    // Color scheme, fonts and background live on the Themes page now.
    expect(find.byKey(const Key('settingsThemes')), findsOneWidget);
    expect(find.byKey(const Key('settingsFonts')), findsNothing);

    await tester.ensureVisible(find.byKey(const Key('advanced-settings')));
    await tester.tap(find.byKey(const Key('advanced-settings')));
    await tester.pumpAndSettle();
    for (final key in ['settingsSecrets', 'settingsComputers', 'settingsDevices', 'showBotSteps']) {
      expect(find.byKey(Key(key)), findsOneWidget, reason: key);
    }
  });
}
