import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama_sdk/casama_sdk.dart' show Integration;
import 'package:casama_app/core/providers.dart';
import 'package:casama_app/features/integrations/connect_app_sheet.dart';

import 'fake_backend.dart';

class _CountingBackend extends FakeBackend {
  var integrationLoads = 0;
  @override
  Future<List<Integration>> integrations(String orgId) async {
    integrationLoads++;
    return const [];
  }
}

void main() {
  test('a sign-in that finishes after its sheet closed still refreshes the connections', () async {
    final backend = _CountingBackend()..pendingPolls = 2;
    final container = ProviderContainer(
      overrides: [backendProvider.overrideWithValue(backend)],
    );
    addTearDown(container.dispose);
    final sub = container.listen(integrationsProvider, (_, _) {});
    addTearDown(sub.close);
    await container.read(integrationsProvider.future);
    final before = backend.integrationLoads;
    finishInBackground(
      container,
      'flow-sentry',
      every: const Duration(milliseconds: 10),
    );
    await Future<void>.delayed(const Duration(milliseconds: 120));
    await container.read(integrationsProvider.future);
    expect(backend.integrationLoads, greaterThan(before));
  });
}
