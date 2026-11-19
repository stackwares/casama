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
    'signing out marks the watches whose key went; one whose key could not be deleted stays signed in for the bridge to tell; a sign-out that failed undoes the marks',
    () async {
      WatchRecord record(
        String fp,
        String keyId,
        String user, {
        WatchRemoval? removal,
      }) => WatchRecord(
        fingerprint: fp * 64,
        platform: WatchSystem.wearos,
        name: 'Watch',
        keyId: keyId,
        orgId: orgId,
        userId: user,
        removal: removal,
      );
      await WatchKeyStore.save([
        record('a', 'k1', 'me'),
        record('b', 'k2', 'me'),
        record('c', 'k3', 'someone-else'),
        // Waiting since an earlier sign-out (their watches were told then).
        record('d', 'k4', 'me', removal: WatchRemoval.pending),
        record('e', 'k5', 'me', removal: WatchRemoval.pending),
      ]);
      final asked = <String>[];
      await WatchKeyStore.signingOut('me', (id) async {
        asked.add(id);
        if (id == 'k2' || id == 'k5') throw Exception('offline');
      });
      expect(asked, [
        'k1',
        'k2',
        'k4',
        'k5',
      ], reason: "another account's key is not ours");
      expect((await WatchKeyStore.load()).map((r) => (r.keyId, r.removal)), [
        ('k1', WatchRemoval.done),
        // Not marked: the bridge must still see a signed-in watch to tell.
        ('k2', null),
        ('k3', null),
        // k4's key went and its watch was told long ago: finished. k5 keeps waiting.
        ('k5', WatchRemoval.pending),
      ]);
      await WatchKeyStore.signOutFailed('me');
      expect((await WatchKeyStore.load()).map((r) => (r.keyId, r.removal)), [
        ('k1', null),
        ('k2', null),
        ('k3', null),
        ('k5', WatchRemoval.pending),
      ]);
    },
  );

  test(
    "the first builds' device-wide Show details flag becomes the signed-in person's, once",
    () async {
      SharedPreferences.setMockInitialValues({
        WatchDetailsSettled.legacyKey: true,
      });
      expect(await WatchDetailsSettled.check(null), isFalse);
      expect(await WatchDetailsSettled.check('me'), isTrue);
      expect(
        await WatchDetailsSettled.check('someone-else'),
        isFalse,
        reason: 'it was one person who made that visit',
      );
      expect(await WatchDetailsSettled.check('me'), isTrue);
    },
  );

  test(
    "fake backend, as the server: the key ids of a workspace, none, a workspace left, and one that can't be asked",
    () async {
      final backend = FakeBackend();
      final key = await backend.registerWatchKey(
        orgId: orgId,
        fingerprint: _fp,
        platform: WatchSystem.watchos,
        name: 'Watch',
      );
      expect(await backend.watchKeyIdsIn(orgId), {key.id});
      expect(await backend.watchKeyIdsIn('other'), isEmpty);
      backend.watchOrgsLeft.add('other');
      expect(await backend.watchKeyIdsIn('other'), isNull);
      backend.watchListDown.add(orgId);
      await expectLater(backend.watchKeyIdsIn(orgId), throwsException);
      // Deleting can fail while signed in (offline).
      backend.watchDeleteError = Exception('offline');
      await expectLater(backend.deleteWatchKey(key.id), throwsException);
      await expectLater(backend.deleteAllWatchKeys(), throwsException);
      expect((await backend.listWatchKeys(orgId)).single.id, key.id);
    },
  );

  test('fake backend, as the server: the same watch keeps its key, and deleting needs a session', () async {
    final backend = FakeBackend();
    Future<WatchKeyView> register(String org) => backend.registerWatchKey(
      orgId: org,
      fingerprint: _fp,
      platform: WatchSystem.watchos,
      name: 'Watch',
    );
    final first = await register(orgId);
    final moved = await register('other');
    expect(moved.id, first.id);
    expect(await backend.listWatchKeys(orgId), isEmpty);
    expect((await backend.listWatchKeys('other')).single.id, first.id);

    backend.signedIn = false;
    await expectLater(backend.deleteWatchKey(first.id), throwsException);
    await expectLater(backend.deleteAllWatchKeys(), throwsException);
    backend.signedIn = true;
    expect(await backend.deleteAllWatchKeys(), 1);
    expect(await backend.listWatchKeys('other'), isEmpty);
    // A removed watch that signs in again gets a new key.
    expect((await register(orgId)).id, isNot(first.id));
    backend.watchDeleteAllSupported = false;
    expect(await backend.deleteAllWatchKeys(), isNull);
  });

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
