// The admin's usage margin (D-395): charged against what the server paid, by kind and workspace.
import 'package:casama/features/admin/admin_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

void main() {
  testWidgets('the owner sees charged, cost and margin, and picks the period', (
    tester,
  ) async {
    await setSize(tester, const Size(900, 2400));
    final backend = FakeBackend();
    await tester.pumpWidget(harness(backend, const AdminScreen()));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('marginCard')));
    await tester.pumpAndSettle();
    expect(find.text('Usage margin'), findsOneWidget);
    String text(String key) => tester.widget<Text>(find.byKey(Key(key))).data!;
    // Charges with no recorded cost are outside the margin and said apart.
    expect(text('marginCharged'), r'$1.40');
    expect(text('marginCost'), r'$1.00');
    expect(text('marginProfit'), r'$0.4000 · 29%');
    expect(
      find.textContaining(r'Plus $0.6000 charged with no cost recorded'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('marginKind-tokens_in')), findsOneWidget);
    expect(
      find.text(r'$1.40 charged · $1.00 cost · 29% margin'),
      findsOneWidget,
    );
    expect(find.text(r'$0.6000 charged · no cost recorded'), findsOneWidget);
    expect(
      find.text(
        r'$1.40 charged · $1.00 cost · 29% margin · $0.6000 with no cost recorded',
      ),
      findsOneWidget,
    );
    expect(find.text('Acme · pro'), findsOneWidget);
    expect(backend.marginDays, [30]);

    await tester.tap(find.text('7 days'));
    await tester.pumpAndSettle();
    expect(backend.marginDays, [30, 7]);
  });

  testWidgets('nobody else gets the card', (tester) async {
    await setSize(tester, const Size(900, 1600));
    final backend = FakeBackend()..isOwner = false;
    await tester.pumpWidget(harness(backend, const AdminScreen()));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('marginCard')), findsNothing);
    expect(backend.marginDays, isEmpty);
  });
}
