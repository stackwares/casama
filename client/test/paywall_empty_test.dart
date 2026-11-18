import 'package:casama/core/billing.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'app_test.dart' show setSize;
import 'billing_test.dart' show FakeStore, pumpPaywall;
import 'fake_backend.dart';

/// A store that answers with no products (signed out of it, or it couldn't be reached).
class _EmptyStore extends FakeStore {
  _EmptyStore() : super('google_play', country: 'USA');
  @override
  Future<List<StoreProduct>> products(Set<String> ids) async => const [];
}

/// A backend whose plan catalog fails until [fail] is cleared.
class _FlakyPlans extends FakeBackend {
  var fail = true;
  @override
  Future<PlanCatalog> plans() async {
    if (fail) throw Exception('offline');
    return super.plans();
  }
}

void main() {
  testWidgets('a server that sells no plans says so instead of a blank paywall', (tester) async {
    await setSize(tester, const Size(430, 1400));
    // As the server answers with billing off: enabled false, no plans.
    final backend = FakeBackend()
      ..billingEnabled = false
      ..catalogPlans = const [];
    await pumpPaywall(tester, backend);
    expect(find.byKey(const Key('paywallEmpty-notSold')), findsOneWidget);
    expect(find.text('No plans on this server'), findsOneWidget);
    expect(find.byKey(const Key('paywallRetry')), findsNothing);
  });

  testWidgets('plans that fail to load offer Try Again, which brings the cards back', (tester) async {
    await setSize(tester, const Size(430, 1400));
    final backend = _FlakyPlans()..billingEnabled = true;
    await pumpPaywall(tester, backend);
    expect(find.byKey(const Key('paywallEmpty-failed')), findsOneWidget);
    expect(find.text("Plans didn't load"), findsOneWidget);
    backend.fail = false;
    await tester.tap(find.byKey(const Key('paywallRetry')));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byKey(const Key('paywallEmpty-failed')), findsNothing);
    expect(find.byKey(const Key('paywallTier-pro')), findsOneWidget);
  });

  testWidgets('on Android, a Play Store with no products says to check Google Play, never shows web prices', (tester) async {
    await setSize(tester, const Size(430, 1400));
    await pumpPaywall(tester, FakeBackend()..billingEnabled = true, store: _EmptyStore(), platform: TargetPlatform.android);
    expect(find.byKey(const Key('paywallEmpty-store')), findsOneWidget);
    expect(find.text("Google Play isn't showing plans"), findsOneWidget);
    expect(find.byKey(const Key('paywallTier-pro')), findsNothing);
  });
}
