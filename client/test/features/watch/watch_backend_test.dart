// Watch keys on the phone (D-410): the models read the server's answers (packages/contracts
// fixtures' shape), codes are read however they're typed, the key store keeps fingerprints only,
// and the fake backend round-trips like the server.
import 'package:casama/core/backend.dart';
import 'package:casama/features/watch/watch_key_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../fake_backend.dart';

const _fp = 'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('models read the server answers, missing parts as empty', () {
    final key = WatchKeyView.fromJson({
      'id': 'k1',
      'org_id': orgId,
      'platform': 'wearos',
      'name': 'Pixel Watch 3',
      'model': null,
      'app_version': '0.1.0',
      'os_version': null,
      'paired_by': 'code',
      'has_push': true,
      'last_used_at': '2026-11-19T08:00:00Z',
      'created_at': '2026-11-18T08:00:00Z',
    });
    expect(
      (key.platform, key.model, key.appVersion, key.pairedBy, key.hasPush),
      (WatchSystem.wearos, null, '0.1.0', 'code', true),
    );
    expect(key.lastUsedAt, DateTime.utc(2026, 11, 19, 8));

    final prefs = WatchPrefsView.fromJson({
      'allow': 'low',
      'show_details': false,
      'quick_replies': ['Yes', 'No'],
    });
    expect((prefs.allow, prefs.showDetails), (WatchAllowance.low, false));
    expect(prefs.quickReplies, ['Yes', 'No']);
    // An unknown level reads as the default.
    expect(
      WatchPrefsView.fromJson({'allow': 'everything'}).allow,
      WatchAllowance.medium,
    );

    final code = WatchCodeView.fromJson({
      'platform': 'watchos',
      'name': "Oliver's Apple Watch",
      'model': 'Series 10',
      'expires_at': '2026-11-19T08:10:00Z',
    });
    expect(
      (code.platform, code.name, code.model),
      (WatchSystem.watchos, "Oliver's Apple Watch", 'Series 10'),
    );
  });

  test('codes are read however they are typed', () {
    expect(normalizeWatchCode('KQ7M 2XAB'), 'KQ7M2XAB');
    expect(normalizeWatchCode('kq7m-2xab'), 'KQ7M2XAB');
    expect(normalizeWatchCode(' kq7 m2x ab '), 'KQ7M2XAB');
    expect(normalizeWatchCode('KQ7'), isNull);
    expect(normalizeWatchCode('KQ7M2XABC'), isNull);
  });

  test(
    'the key store keeps one record per fingerprint and forgets by key id',
    () async {
      WatchRecord record(String keyId, String org) => WatchRecord(
        fingerprint: _fp,
        platform: WatchSystem.watchos,
        name: 'Watch',
        keyId: keyId,
        orgId: org,
        userId: 'me',
        model: 'S10',
      );
      await WatchKeyStore.upsert(record('k1', 'o1'));
      await WatchKeyStore.upsert(record('k2', 'o2'));
      final saved = await WatchKeyStore.load();
      expect(saved.map((r) => (r.keyId, r.orgId, r.model)), [
        ('k2', 'o2', 'S10'),
      ]);
      expect(
        saved.single.toJson().containsKey('key'),
        isFalse,
        reason: 'never the key itself',
      );
      await WatchKeyStore.removeKey('k2');
      expect(await WatchKeyStore.load(), isEmpty);
      // A broken saved value reads as nothing, not an error.
      SharedPreferences.setMockInitialValues({
        WatchKeyStore.prefKey: '{not json',
      });
      expect(await WatchKeyStore.load(), isEmpty);
    },
  );

  test(
    'fake backend: register, list by workspace, prefs, codes, delete',
    () async {
      final backend = FakeBackend();
      final key = await backend.registerWatchKey(
        orgId: orgId,
        fingerprint: _fp,
        platform: WatchSystem.watchos,
        name: 'Watch',
        model: 'S10',
      );
      expect((await backend.listWatchKeys(orgId)).map((k) => k.id), [key.id]);
      expect(await backend.listWatchKeys('other'), isEmpty);

      final prefs = await backend.updateWatchPrefs(
        allow: WatchAllowance.none,
        quickReplies: ['Later'],
      );
      expect(prefs.allow, WatchAllowance.none);
      expect(prefs.quickReplies, ['Later']);
      expect((await backend.watchPrefs())!.allow, WatchAllowance.none);
      expect(
        (await backend.updateWatchPrefs(quickReplies: const [])).quickReplies,
        isNotEmpty,
        reason: 'empty is the built-in list',
      );

      backend.watchCodes['ABCD2345'] = WatchCodeView(
        platform: WatchSystem.wearos,
        name: 'Pixel',
        expiresAt: DateTime.utc(2026, 11, 19, 9),
      );
      expect((await backend.watchCodeInfo('ABCD2345'))!.name, 'Pixel');
      final claimed = await backend.claimWatchCode('ABCD2345', orgId);
      expect(claimed!.pairedBy, 'code');
      expect(
        await backend.claimWatchCode('ABCD2345', orgId),
        isNull,
        reason: 'one use',
      );

      await backend.deleteWatchKey(key.id);
      expect((await backend.listWatchKeys(orgId)).map((k) => k.id), [
        claimed.id,
      ]);
    },
  );
}
