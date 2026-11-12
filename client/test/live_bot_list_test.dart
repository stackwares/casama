import 'package:casama_app/core/providers.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_backend.dart';

// D-225: a bot made on another device shows up here without a reload.
void main() {
  test(
    'another device adding a bot refetches the list once per burst, in place',
    () async {
      final backend = FakeBackend();
      final container = ProviderContainer(
        overrides: [backendProvider.overrideWithValue(backend)],
      );
      addTearDown(container.dispose);
      final sub = container.listen(botsProvider, (_, _) {});
      addTearDown(sub.close);
      await container.read(organizationsProvider.future);
      await Future<void>.delayed(Duration.zero);

      expect((await container.read(botsProvider.future)).map((b) => b.name), [
        'Ada',
      ]);
      expect(backend.botsChangedListeners, 1);

      // A bot made on the phone; the database announces it, sometimes several times in a row.
      backend.extraBots.add(backend.bot(id: 'b2', name: 'Grace'));
      for (var i = 0; i < 3; i++) {
        backend.botsChangedController.add(null);
      }
      await Future<void>.delayed(
        BotsNotifier.changeSettle + const Duration(milliseconds: 100),
      );

      final bots = container.read(botsProvider);
      expect(bots.value?.map((b) => b.name), ['Ada', 'Grace']);
      expect(bots.isLoading, isFalse, reason: 'updated in place, no reload');
      expect(
        backend.botsChangedListeners,
        1,
        reason: 'still the one subscription',
      );
    },
  );

  test('a bot status change elsewhere shows up too', () async {
    final backend = FakeBackend();
    final container = ProviderContainer(
      overrides: [backendProvider.overrideWithValue(backend)],
    );
    addTearDown(container.dispose);
    final sub = container.listen(botsProvider, (_, _) {});
    addTearDown(sub.close);
    await container.read(organizationsProvider.future);
    await Future<void>.delayed(Duration.zero);
    await container.read(botsProvider.future);

    backend.extraBots.add(
      backend.bot(id: 'b3', name: 'Linus', status: BotStatusEnum.working),
    );
    backend.botsChangedController.add(null);
    await Future<void>.delayed(
      BotsNotifier.changeSettle + const Duration(milliseconds: 100),
    );
    expect(
      container.read(botsProvider).value?.last.status,
      BotStatusEnum.working,
    );
  });
}
