import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama/features/app_lock/app_lock.dart';
import 'package:casama/core/backend.dart';
import 'package:casama/core/providers.dart';
import 'package:casama/core/server_address.dart';
import 'package:casama/features/auth/sign_in_screen.dart';
import 'package:casama/features/privacy/privacy_screen.dart';
import 'package:casama/ui/highlight_target.dart';
import 'package:casama/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';
import 'fake_unlockers.dart';

void main() {
  testWidgets('exports data, changes retention and deletes the account after typing the email', (tester) async {
    await setSize(tester, const Size(800, 1000));
    final backend = FakeBackend();
    final saved = <String>[];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          backendProvider.overrideWithValue(backend), unlockersProvider.overrideWithValue(FakeUnlockers()),
          saveExportProvider.overrideWithValue((Uint8List b, String name, {Rect? origin}) async => saved.add('$name:${b.length}')),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: PrivacyScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('exportData')));
    await tester.pumpAndSettle();
    expect(backend.exported, 1);
    expect(saved.single, matches(RegExp(r'^casama-export-\d{4}-\d\d-\d\d\.zip:2048$')));

    await tester.tap(find.byKey(const Key('retention')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('90 days').last);
    await tester.pumpAndSettle();
    expect(backend.retention, 90);

    await tester.tap(find.byKey(const Key('deleteAccount')));
    await tester.pumpAndSettle();
    final confirm = find.byKey(const Key('confirmDelete'));
    expect(tester.widget<FilledButton>(confirm).onPressed, isNull);
    await tester.enterText(find.byKey(const Key('confirmEmail')), 'tester@example.com');
    await tester.pump();
    await tester.tap(confirm);
    await tester.pumpAndSettle();
    expect(backend.deletedWith, 'tester@example.com');
    expect(find.text('Account Scheduled for Deletion'), findsOneWidget);
  });

  testWidgets('the usage-data switches tell the server: the person (off, then on) and the workspace admin', (tester) async {
    await setSize(tester, const Size(800, 1000));
    SharedPreferences.setMockInitialValues({});
    final backend = FakeBackend();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [backendProvider.overrideWithValue(backend), unlockersProvider.overrideWithValue(FakeUnlockers())],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: PrivacyScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final mine = find.byKey(const Key('shareAnalyticsSwitch'));
    expect(tester.widget<Switch>(mine).value, isTrue);
    await tester.tap(mine);
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(mine).value, isFalse);
    expect(backend.analyticsOptOutCalls, [true]);
    await tester.tap(mine);
    await tester.pumpAndSettle();
    expect(backend.analyticsOptOutCalls, [true, false]);

    final workspace = find.byKey(const Key('workspaceAnalyticsSwitch'));
    expect(tester.widget<Switch>(workspace).value, isTrue);
    await tester.tap(workspace);
    await tester.pumpAndSettle();
    expect(backend.workspaceAnalyticsOff, isTrue);
    expect(tester.widget<Switch>(workspace).value, isFalse);
  });

  testWidgets('sign-in offers SSO and switching to a self-hosted server', (tester) async {
    await setSize(tester, const Size(800, 1200));
    SharedPreferences.setMockInitialValues({});
    final backend = FakeBackend()
      ..signedIn = false
      ..authMethodsValue = const AuthMethods(sso: true);
    String? switchedTo;
    onChangeServer = (url) async => switchedTo = url;
    addTearDown(() => onChangeServer = null);
    await tester.pumpWidget(harness(backend, const SignInScreen()));
    await tester.tap(find.byKey(const Key('openSignIn')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('moreSignInOptions')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('ssoSignIn')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('ssoEmail')), 'ana@acme.com');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(backend.ssoEmail, 'ana@acme.com');

    await tester.tap(find.byKey(const Key('changeServer')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('serverUrl')), 'casama.example.com/');
    await tester.tap(find.byKey(const Key('serverConnect')));
    await tester.pumpAndSettle();
    expect(switchedTo, 'https://casama.example.com');
  });

  test('server addresses are normalized and remembered', () async {
    SharedPreferences.setMockInitialValues({});
    expect(ServerAddress.normalize('localhost:8090'), 'http://localhost:8090');
    expect(ServerAddress.normalize(' https://k.example.com// '), 'https://k.example.com');
    expect((await ServerAddress.load()).apiUrl, 'http://localhost:8787');
    await ServerAddress.save('k.example.com');
    expect((await ServerAddress.load()).apiUrl, 'https://k.example.com');
  });

  testWidgets('PrivacyScreen ?highlight= targets the matching control without executing destructive or export actions', (tester) async {
    await setSize(tester, const Size(800, 1000));
    final backend = FakeBackend();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          backendProvider.overrideWithValue(backend),
          unlockersProvider.overrideWithValue(FakeUnlockers()),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: PrivacyScreen(highlight: 'delete'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final activeTargets = tester
        .widgetList<HighlightTarget>(find.byType(HighlightTarget))
        .where((w) => w.active)
        .toList();
    expect(activeTargets, hasLength(1));
    expect(
      find.descendant(
        of: find.byWidget(activeTargets.single),
        matching: find.byKey(const Key('deleteAccount')),
      ),
      findsOneWidget,
    );
    expect(backend.exported, 0);
    expect(backend.deletedWith, isNull);
  });
}
