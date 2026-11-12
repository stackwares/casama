import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama_app/features/settings/password_managers_screen.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

void main() {
  testWidgets('connect 1Password, choose vaults, and remove it', (tester) async {
    await setSize(tester, const Size(900, 1400));
    final backend = FakeBackend();
    await tester.pumpWidget(harness(backend, const PasswordManagersScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('addPasswordManager')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('pmName')), 'Team 1Password');
    await tester.enterText(find.byKey(const Key('pmUrl')), 'https://op-connect.acme.test');
    await tester.enterText(find.byKey(const Key('pmToken')), 'tok');
    await tester.pump();
    await tester.tap(find.byKey(const Key('connectPm')));
    await tester.pumpAndSettle();
    expect(backend.pmActions, ['connect:1password:personal']);
    await tester.tap(find.byKey(const Key('vault-v-work')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('saveVaults')));
    await tester.pumpAndSettle();
    expect(backend.pmActions.last, 'vaults:pm-1:v-work');
    expect(find.textContaining('1Password · Just me'), findsOneWidget);
    await tester.tap(find.byKey(const Key('deletePm-pm-1')));
    await tester.pumpAndSettle();
    expect(find.text('No password managers connected'), findsOneWidget);
  });
}
