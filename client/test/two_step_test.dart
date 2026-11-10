import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kasama_app/core/providers.dart';
import 'package:kasama_app/features/auth/two_step_screen.dart';
import 'package:kasama_app/l10n/generated/app_localizations.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

void main() {
  testWidgets('sets up an authenticator app, then removes it', (tester) async {
    await setSize(tester, const Size(900, 1600));
    final backend = FakeBackend();
    await tester.pumpWidget(harness(backend, const TwoStepSettingsScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Set up an authenticator app'), findsOneWidget);

    await tester.tap(find.byKey(const Key('startTwoStep')));
    await tester.pumpAndSettle();
    expect(find.textContaining('JBSWY3DPEHPK3PXP'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('enrollCode')), '000000');
    await tester.tap(find.byKey(const Key('verifyTwoStep')));
    await tester.pumpAndSettle();
    expect(backend.twoStep, isEmpty);

    await tester.enterText(find.byKey(const Key('enrollCode')), '123456');
    await tester.tap(find.byKey(const Key('verifyTwoStep')));
    await tester.pumpAndSettle();
    expect(backend.twoStep.single.id, 'f-new');
    expect(find.text('Add another authenticator'), findsOneWidget);

    await tester.tap(find.byKey(const Key('removeFactor-f-new')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove').last);
    await tester.pumpAndSettle();
    expect(backend.twoStep, isEmpty);
  });

  testWidgets('owners can require it for the workspace', (tester) async {
    await setSize(tester, const Size(900, 1600));
    final backend = FakeBackend();
    await tester.pumpWidget(harness(backend, const TwoStepSettingsScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('requireTwoStep')));
    await tester.pumpAndSettle();
    expect(backend.requireTwoStepValue, isTrue);
  });

  testWidgets('the sign-in code screen passes the second step', (tester) async {
    await setSize(tester, const Size(500, 900));
    final backend = FakeBackend()..twoStepCodeNeeded = true;
    final router = GoRouter(
      initialLocation: '/two-step',
      routes: [
        GoRoute(path: '/two-step', builder: (_, _) => const TwoStepPromptScreen()),
        GoRoute(path: '/bots', builder: (_, _) => const Text('bots home')),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [backendProvider.overrideWithValue(backend)],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Enter your code'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('signInCode')), '123456');
    await tester.tap(find.byKey(const Key('submitCode')));
    await tester.pumpAndSettle();
    expect(backend.twoStepVerified, isTrue);
    expect(find.text('bots home'), findsOneWidget);
  });
}
