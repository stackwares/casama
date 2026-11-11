import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama_app/core/providers.dart';
import 'package:casama_app/core/server_address.dart';
import 'package:casama_app/features/auth/sign_in_screen.dart';
import 'package:casama_app/features/privacy/privacy_screen.dart';
import 'package:casama_app/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

void main() {
  testWidgets('exports data, changes retention and deletes the account after typing the email', (tester) async {
    await setSize(tester, const Size(800, 1000));
    final backend = FakeBackend();
    final saved = <String>[];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          backendProvider.overrideWithValue(backend),
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
    expect(find.text('Account scheduled for deletion'), findsOneWidget);
  });

  testWidgets('sign-in offers SSO and switching to a self-hosted server', (tester) async {
    await setSize(tester, const Size(800, 1200));
    SharedPreferences.setMockInitialValues({});
    final backend = FakeBackend()..signedIn = false;
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
}
