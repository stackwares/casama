import 'package:casama/app.dart';
import 'package:casama/core/admin_security.dart';
import 'package:casama/core/providers.dart';
import 'package:casama/core/router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_test.dart' show setSize;
import 'fake_backend.dart';

/// Signing in with the password leaves a session that still owes its two-step code, as Supabase
/// does for an account with an authenticator.
class _TwoStepBackend extends FakeBackend {
  @override
  Future<void> signIn(String email, String password) async {
    twoStepCodeNeeded = true;
    await super.signIn(email, password);
  }
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets(
    'unlocking the console with two-step sign-in stays on the console, not the two-step page',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await setSize(tester, const Size(1200, 900));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      final backend = _TwoStepBackend();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [backendProvider.overrideWithValue(backend)],
          child: const CasamaApp(),
        ),
      );
      await _settle(tester);
      final c = ProviderScope.containerOf(
        tester.element(find.byType(CasamaApp)),
      );
      final router = c.read(routerProvider);
      router.go('/settings/admin');
      await _settle(tester);
      await tester.enterText(find.byKey(const Key('adminPassword')), 'pw');
      await tester.tap(find.byKey(const Key('adminUnlockPassword')));
      await _settle(tester);
      // The sign-in event re-ran the redirects; the open admin form kept the page.
      expect(router.state.uri.path, '/settings/admin');
      expect(find.byKey(const Key('adminTwoStepCode')), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('adminTwoStepCode')),
        '123456',
      );
      await tester.tap(find.byKey(const Key('adminVerifyTwoStep')));
      await _settle(tester);
      expect(router.state.uri.path, '/settings/admin');
      expect(find.byKey(const Key('adminTwoStepCode')), findsNothing);
      expect(find.byKey(const Key('adminPassword')), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      await _settle(tester);
      AdminSecurity.forgetVerification();
    },
  );

  testWidgets('leaving with the code still owed goes to the two-step page', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await setSize(tester, const Size(1200, 900));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    final backend = _TwoStepBackend();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [backendProvider.overrideWithValue(backend)],
        child: const CasamaApp(),
      ),
    );
    await _settle(tester);
    final c = ProviderScope.containerOf(tester.element(find.byType(CasamaApp)));
    final router = c.read(routerProvider);
    router.go('/settings/admin');
    await _settle(tester);
    await tester.enterText(find.byKey(const Key('adminPassword')), 'pw');
    await tester.tap(find.byKey(const Key('adminUnlockPassword')));
    await _settle(tester);
    router.go('/bots');
    await _settle(tester);
    expect(router.state.uri.path, '/two-step');
    await tester.pumpWidget(const SizedBox.shrink());
    await _settle(tester);
  });
}
