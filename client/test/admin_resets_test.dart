import 'dart:convert';

import 'package:casama/features/admin/resets_tab.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:dio/dio.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_test.dart' show harness;
import 'fake_backend.dart';

class _AdminBackend extends FakeBackend {
  _AdminBackend({this.state});
  final String? state;
  bool enabled = false;
  late final Dio transport = Dio()
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (request, handler) {
          if (request.path.endsWith('/settings')) {
            if (request.method == 'PUT') {
              enabled =
                  (jsonDecode(request.data as String) as Map)['enabled']
                      as bool;
            }
            handler.resolve(
              Response(
                requestOptions: request,
                data: {
                  'enabled': enabled,
                  'per_period': 1,
                  'max_held': 3,
                  'notify_owners': true,
                },
                statusCode: 200,
              ),
            );
          } else {
            handler.resolve(
              Response(
                requestOptions: request,
                data: state == null
                    ? []
                    : [
                        {
                          "id": "11111111-1111-4111-8111-111111111111",
                          "name": "Recovery",
                          "message": "Saved",
                          "audience": {"plan_codes": [], "workspace_ids": []},
                          "starts_at": "2026-11-20T00:00:00Z",
                          "expires_at": "2027-01-01T00:00:00Z",
                          "state": state,
                          "created_by": "11111111-1111-4111-8111-111111111111",
                          "created_at": "2026-11-20T00:00:00Z",
                          "given": 1,
                          "used": 0,
                          "expired": 0,
                          "refilled_usd": 0,
                        },
                      ],
                statusCode: 200,
              ),
            );
          }
        },
      ),
    );
  @override
  LimitResetsApi get limitResets => LimitResetsApi(transport);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets(
    'instance owner can switch resets on without creating a campaign',
    (tester) async {
      final backend = _AdminBackend();
      await tester.pumpWidget(
        harness(backend, const Scaffold(body: ResetsTab())),
      );
      await tester.pumpAndSettle();
      expect(find.text('Enable saved resets'), findsOneWidget);
      expect(backend.enabled, isFalse);
      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();
      expect(backend.enabled, isTrue);
    },
  );
  for (final state in [
    'draft',
    'scheduled',
    'live',
    'paused',
    'ended',
    'cancelled',
  ]) {
    testWidgets('campaign $state exposes only valid lifecycle actions', (
      tester,
    ) async {
      await tester.pumpWidget(
        harness(_AdminBackend(state: state), const Scaffold(body: ResetsTab())),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Pause'),
        state == 'live' ? findsOneWidget : findsNothing,
      );
      expect(
        find.text('Resume'),
        state == 'paused' ? findsOneWidget : findsNothing,
      );
      expect(
        find.text('Schedule'),
        state == 'draft' ? findsOneWidget : findsNothing,
      );
      expect(
        find.text('Delete'),
        state == 'draft' ? findsOneWidget : findsNothing,
      );
    });
  }
}
