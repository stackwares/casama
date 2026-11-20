import 'package:casama/features/admin/vendors_tab.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_test.dart' show harness;
import 'fake_backend.dart';

class _Vendors extends FakeBackend {
  @override
  Future<List<AdminVendor>> adminVendors() async => [
    AdminVendor.fromJson({
      'vendor': 'resend',
      'label': 'Resend',
      'kind': 'quota',
      'unit': 'emails',
      'limit_value': 100,
      'period': 'day',
      'period_start': null,
      'expires_at': null,
      'warn_at': 0.8,
      'enabled': true,
      'balance_warn_below': 5,
      'billing_url': null,
      'impact': null,
      'latest': {
        'checked_at': '2026-11-20T00:00:00Z',
        'used': 82,
        'remaining': 18,
        'limit_value': 100,
        'resets_at': null,
        'status': 'low',
        'source': 'own_count',
        'error': null,
      },
      'history': [],
    }),
  ];
}

void main() {
  testWidgets('overview warns about a low vendor', (tester) async {
    await tester.pumpWidget(
      harness(
        _Vendors(),
        const DefaultTabController(
          length: 2,
          child: Scaffold(body: VendorAttentionBanner(tabIndex: 1)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Vendor services need attention'), findsOneWidget);
  });
  testWidgets('shows vendor reading and warning, opens details', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(_Vendors(), const Scaffold(body: VendorsTab())),
    );
    await tester.pumpAndSettle();
    expect(find.text('Resend'), findsOneWidget);
    expect(find.textContaining('82 / 100 emails'), findsOneWidget);
    await tester.tap(find.text('Resend'));
    await tester.pumpAndSettle();
    expect(find.text('Check now'), findsOneWidget);
    expect(find.text('Monitoring enabled'), findsOneWidget);
  });
}
