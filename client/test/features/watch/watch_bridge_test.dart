// The phone's side of signing a watch in (D-410, WATCH-PROTOCOL §3): what it answers with the app
// lock declined and on success, and that a request waits while nobody is signed in; what a
// workspace switch, a sign-out, Sign Out Everywhere and a session that ended by itself do; and
// that a missing native side is a quiet no-op.
import 'dart:async';

import 'package:casama/core/backend.dart';
import 'package:casama/core/local_cache.dart';
import 'package:casama/core/providers.dart';
import 'package:casama/features/app_lock/app_lock.dart';
import 'package:casama/features/watch/watch_bridge.dart';
import 'package:casama/features/watch/watch_key_store.dart';
import 'package:casama_sdk/casama_sdk.dart' show OrganizationWithRole, OrgRole;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../fake_backend.dart';

const _fp1 = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _fp2 = 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
const _org2 = '66666666-6666-4666-8666-666666666666';

class _LockOn extends AppLockSettingsNotifier {
  @override
  AppLockSettings build() => const AppLockSettings(enabled: true, userId: 'me');
}

Map<String, Object?> _request(
  String id, {
  String fingerprint = _fp1,
  String platform = 'watchos',
  String name = "Oliver's Apple Watch",
}) => {
  'request_id': id,
  'platform': platform,
  'fingerprint': fingerprint,
  'name': name,
  'model': 'Apple Watch Series 10, 46 mm',
  'app_version': '0.1.0',
  'os_version': '12.0',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel(watchChannelName);
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  late FakeBackend backend;
  late List<MethodCall> calls;
  late List<Object?> held;
  late List<String> asked;
  late List<String> notices;
  late List<String> opened;
  var allow = true;

  /// While set, the app lock's question stays up until it is completed.
  Completer<bool>? question;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppLockSettingsNotifier.resetForTest();
    backend = FakeBackend()
      ..about = const AboutYouView(displayName: 'Oliver Martinez');
    calls = [];
    held = [];
    asked = [];
    notices = [];
    opened = [];
    allow = true;
    question = null;
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      switch (call.method) {
        // As native code does: held until answered, one per watch.
        case 'takeRequests':
          return [...held];
        case 'answer':
          final args = Map<Object?, Object?>.from(call.arguments as Map);
          held.removeWhere(
            (r) =>
                r is Map &&
                (r['request_id'] == args['request_id'] ||
                    r['fingerprint'] == args['fingerprint']),
          );
        case 'status':
          return {'supported': true, 'paired': true, 'installed': false};
      }
      return null;
    });
  });

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  ProviderContainer container({bool lockOn = false}) {
    final c = ProviderContainer(
      overrides: [
        backendProvider.overrideWithValue(backend),
        localCacheProvider.overrideWithValue(const NoCache()),
        watchBridgeSupportedProvider.overrideWithValue(true),
        watchLockAskProvider.overrideWithValue((name) async {
          asked.add(name);
          return question?.future ?? allow;
        }),
        watchNoticeProvider.overrideWithValue(notices.add),
        watchOpenProvider.overrideWithValue(opened.add),
        if (lockOn) appLockSettingsProvider.overrideWith(_LockOn.new),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  /// The bridge, started, with the first round of startup work done.
  Future<WatchBridge> start(ProviderContainer c) async {
    // Kept alive the way the app root keeps it: a provider nobody listens to is paused.
    final bridge = c.listen(watchBridgeProvider, (_, _) {}).read()!;
    await c.read(signedInProvider.future);
    while (backend.signedIn && c.read(currentOrgProvider) == null) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    await pumpEventQueue();
    return bridge;
  }

  List<Map<Object?, Object?>> answers() => [
    for (final call in calls)
      if (call.method == 'answer')
        Map<Object?, Object?>.from(call.arguments as Map),
  ];

  /// Waits (real time) until [done], for work that follows a sign-in or a workspace switch.
  Future<void> until(bool Function() done) async {
    for (var i = 0; i < 200 && !done(); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 25));
    }
  }

  void addSecondOrg() => backend.extraOrgs.add(
    OrganizationWithRole(
      id: _org2,
      name: 'Second',
      slug: 'second',
      plan: 'selfhost',
      region: 'local',
      createdAt: DateTime(2026),
      role: OrgRole.owner,
    ),
  );

  test('signed out: the request waits, and signing in on the phone signs the watch in', () async {
    backend.signedIn = false;
    held = [_request('r1')];
    final bridge = await start(container());
    await bridge.handle(MethodCall('request', _request('r1')));
    await bridge.takeRequests();
    expect(answers(), isEmpty, reason: 'left with native code, not refused');
    expect(held, hasLength(1));
    expect(backend.watchKeysRegistered, isEmpty);

    await backend.signIn('a@example.com', 'pw');
    await until(() => answers().isNotEmpty);
    expect(answers().single['request_id'], 'r1');
    expect(answers().single['ok'], true);
    expect(backend.watchKeysRegistered, hasLength(1));
    expect(held, isEmpty);
  });

  test(
    'app lock on: the phone asks first, and a no answers declined',
    () async {
      allow = false;
      final bridge = await start(container(lockOn: true));
      await bridge.handle(MethodCall('request', _request('r1')));
      expect(asked, ["Oliver's Apple Watch"]);
      expect(answers().single, {
        'request_id': 'r1',
        'fingerprint': _fp1,
        'ok': false,
        'reason': 'declined',
      });
      expect(backend.watchKeysRegistered, isEmpty);
      expect(backend.watchPrefsUpdates, isEmpty);
    },
  );

  test(
    'app lock on and allowed: signs in, with Show details off first, once',
    () async {
      final bridge = await start(container(lockOn: true));
      await bridge.handle(MethodCall('request', _request('r1')));
      expect(asked, hasLength(1));
      expect(answers().single['ok'], true);
      // The watch starts with general words only (§10).
      expect(backend.watchPrefsUpdates.single.showDetails, false);
      expect(backend.storedWatchPrefs!.showDetails, isFalse);

      // The person turns it back on; a second watch doesn't turn it off again.
      await backend.updateWatchPrefs(showDetails: true);
      await bridge.handle(
        MethodCall('request', _request('r2', fingerprint: _fp2)),
      );
      expect(answers().last['ok'], true);
      expect(backend.storedWatchPrefs!.showDetails, isTrue);
    },
  );

  test(
    'app lock on, and an earlier build already settled Show details on this device: left as the person set it',
    () async {
      // What the first builds kept after the first visit to Settings → Watch.
      SharedPreferences.setMockInitialValues({
        WatchDetailsSettled.legacyKey: true,
      });
      final bridge = await start(container(lockOn: true));
      await bridge.handle(MethodCall('request', _request('r1')));
      expect(answers().single['ok'], true);
      expect(backend.watchPrefsUpdates, isEmpty);
      expect(backend.storedWatchPrefs!.showDetails, isTrue);
      // It is this person's now, not the whole device's.
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(WatchDetailsSettled.legacyKey), isNull);
      expect(await WatchDetailsSettled.check('me'), isTrue);
      expect(await WatchDetailsSettled.check('someone-else'), isFalse);
    },
  );

  test('no app lock: Show details is left alone', () async {
    final bridge = await start(container());
    await bridge.handle(MethodCall('request', _request('r1')));
    expect(backend.watchPrefsUpdates, isEmpty);
  });

  test('a watch that asks again joins the sign-in under way: one question, one key, the newest request answered', () async {
    question = Completer<bool>();
    final bridge = await start(container(lockOn: true));
    final first = bridge.handle(
      MethodCall('request', {..._request('r1'), 'at': 1000}),
    );
    await pumpEventQueue();
    // Try again on the watch, and the same one once more from takeRequests.
    held = [
      {..._request('r2'), 'at': 2000},
    ];
    await bridge.handle(MethodCall('request', {..._request('r2'), 'at': 2000}));
    await bridge.takeRequests();
    expect(asked, hasLength(1), reason: 'one sheet');
    expect(answers(), isEmpty);

    question!.complete(true);
    await first;
    expect(backend.watchKeysRegistered, hasLength(1));
    expect(answers().single['request_id'], 'r2');
    expect(answers().single['ok'], true);
    expect(held, isEmpty);
  });

  test(
    'the workspace is the one selected when the question is answered',
    () async {
      addSecondOrg();
      question = Completer<bool>();
      final c = container(lockOn: true);
      addTearDown(() => c.read(selectedOrgIdProvider.notifier).select(null));
      final bridge = await start(c);
      final asking = bridge.handle(MethodCall('request', _request('r1')));
      await pumpEventQueue();
      expect(asked, hasLength(1));
      // The app is opened into another workspace while the question waits.
      c.read(selectedOrgIdProvider.notifier).select(_org2);
      await pumpEventQueue();
      question!.complete(true);
      await asking;
      expect(backend.watchKeysRegistered.single.$1, _org2);
      expect(answers().single['org_id'], _org2);
      expect((await WatchKeyStore.load()).single.orgId, _org2);
    },
  );

  test('success: registers the fingerprint for the workspace and answers who and where', () async {
    final bridge = await start(container());
    await bridge.handle(MethodCall('request', _request('r1')));
    expect(backend.watchKeysRegistered, [
      (orgId, _fp1, "Oliver's Apple Watch"),
    ]);
    expect(answers().single, {
      'request_id': 'r1',
      'fingerprint': _fp1,
      'ok': true,
      'server': 'http://localhost:8787',
      'org_id': orgId,
      'org_name': 'Test Org',
      'person_name': 'Oliver',
    });
    expect(notices, ["Oliver's Apple Watch is signed in"]);
    expect(asked, isEmpty, reason: 'no app lock, no question');
    final saved = (await WatchKeyStore.load()).single;
    expect(
      (saved.fingerprint, saved.keyId, saved.orgId, saved.userId),
      (_fp1, 'watch1', orgId, 'me'),
    );
    // The same request again (live and from takeRequests) is answered once.
    await bridge.handle(MethodCall('request', _request('r1')));
    expect(answers(), hasLength(1));
  });

  test('a bad request answers error and registers nothing', () async {
    final bridge = await start(container());
    await bridge.handle(
      MethodCall('request', _request('r1', fingerprint: 'not-hex')),
    );
    await bridge.handle(
      MethodCall('request', _request('r2', platform: 'tizen')),
    );
    expect([for (final a in answers()) a['reason']], ['error', 'error']);
    expect(backend.watchKeysRegistered, isEmpty);
  });

  test('a server failure answers error', () async {
    backend.watchRegisterError = Exception('offline');
    final bridge = await start(container());
    await bridge.handle(MethodCall('request', _request('r1')));
    expect(answers().single, {
      'request_id': 'r1',
      'fingerprint': _fp1,
      'ok': false,
      'reason': 'error',
    });
  });

  test(
    'requests held while the app was closed are answered at startup',
    () async {
      held = [
        _request('r1'),
        _request(
          'r2',
          fingerprint: _fp2,
          platform: 'wearos',
          name: 'Pixel Watch 3',
        ),
      ];
      final c = container();
      await start(c);
      // At launch they wait for the workspaces to load.
      for (var i = 0; i < 100 && answers().length < 2; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      expect(calls.where((c) => c.method == 'takeRequests'), isNotEmpty);
      // Each once, though they are taken more than once at startup.
      expect([
        for (final a in answers()) (a['request_id'], a['ok']),
      ], unorderedEquals([('r1', true), ('r2', true)]));
      expect(
        (await WatchKeyStore.load()).map((r) => r.platform),
        unorderedEquals([WatchSystem.watchos, WatchSystem.wearos]),
      );
      expect(held, isEmpty, reason: 'answered, so native code let them go');
    },
  );

  test('a workspace switch signs each watch in to the new one and tells the watches', () async {
    addSecondOrg();
    final c = container();
    addTearDown(() => c.read(selectedOrgIdProvider.notifier).select(null));
    final bridge = await start(c);
    await bridge.handle(MethodCall('request', _request('r1')));
    calls.clear();

    c.read(selectedOrgIdProvider.notifier).select(_org2);
    await pumpEventQueue();
    await pumpEventQueue();

    expect(backend.watchKeysRegistered.last, (
      _org2,
      _fp1,
      "Oliver's Apple Watch",
    ));
    // The server keeps the watch's one key and moves it: same id, nothing to delete.
    expect(backend.watchKeysDeleted, isEmpty);
    expect(backend.watchKeys.single.orgId, _org2);
    final saved = (await WatchKeyStore.load()).single;
    expect((saved.orgId, saved.keyId), (_org2, 'watch1'));
    final context = calls.singleWhere((c) => c.method == 'setContext');
    expect(context.arguments, {
      'server': 'http://localhost:8787',
      'org_id': _org2,
      'org_name': 'Second',
      'person_name': 'Oliver',
    });
  });

  test('a watch removed on another device is forgotten, never signed in again by a switch', () async {
    addSecondOrg();
    final c = container();
    addTearDown(() => c.read(selectedOrgIdProvider.notifier).select(null));
    final bridge = await start(c);
    await bridge.handle(MethodCall('request', _request('r1')));
    await bridge.handle(
      MethodCall('request', _request('r2', fingerprint: _fp2)),
    );
    calls.clear();
    // Removed from the web app: the server no longer has the first watch's key.
    backend.watchKeys = [
      for (final k in backend.watchKeys)
        if (k.id != 'watch1') k,
    ];

    c.read(selectedOrgIdProvider.notifier).select(_org2);
    await until(() => calls.any((c) => c.method == 'setContext'));

    expect(
      [for (final r in backend.watchKeysRegistered.skip(2)) (r.$1, r.$2)],
      [(_org2, _fp2)],
      reason: 'only the watch the server still has follows',
    );
    expect(backend.watchKeys.map((k) => k.id), ['watch2']);
    final saved = (await WatchKeyStore.load()).single;
    expect((saved.fingerprint, saved.orgId), (_fp2, _org2));
  });

  test(
    'a watch the server already moved (the answer never reached the phone) follows it: not forgotten, not registered again',
    () async {
      addSecondOrg();
      final c = container();
      addTearDown(() => c.read(selectedOrgIdProvider.notifier).select(null));
      final bridge = await start(c);
      await bridge.handle(MethodCall('request', _request('r1')));
      calls.clear();
      // An earlier switch reached the server, then the app was closed before it could note it.
      backend.watchKeys = [
        for (final k in backend.watchKeys)
          WatchKeyView(
            id: k.id,
            orgId: _org2,
            platform: k.platform,
            name: k.name,
            createdAt: k.createdAt,
          ),
      ];
      expect((await WatchKeyStore.load()).single.orgId, orgId);

      c.read(selectedOrgIdProvider.notifier).select(_org2);
      await until(() => calls.any((c) => c.method == 'setContext'));

      expect(
        backend.watchKeysRegistered,
        hasLength(1),
        reason: 'only the sign-in',
      );
      expect(backend.watchKeysDeleted, isEmpty);
      final saved = (await WatchKeyStore.load()).single;
      expect((saved.keyId, saved.orgId, saved.active), ('watch1', _org2, true));
      // The watch is told where it is, as after any move.
      expect(
        (calls.singleWhere((c) => c.method == 'setContext').arguments
            as Map)['org_id'],
        _org2,
      );
    },
  );

  test(
    'Settings → Watch opening follows a watch the server moved to another workspace',
    () async {
      addSecondOrg();
      final bridge = await start(container());
      await bridge.handle(MethodCall('request', _request('r1')));
      backend.watchKeys = [
        for (final k in backend.watchKeys)
          WatchKeyView(
            id: k.id,
            orgId: _org2,
            platform: k.platform,
            name: k.name,
            createdAt: k.createdAt,
          ),
      ];
      await bridge.prune();
      final saved = (await WatchKeyStore.load()).single;
      expect((saved.keyId, saved.orgId), ('watch1', _org2));
    },
  );

  test(
    "a watch is forgotten only when every workspace answered: one that can't be asked keeps it",
    () async {
      addSecondOrg();
      final bridge = await start(container());
      await bridge.handle(MethodCall('request', _request('r1')));
      // Gone from its workspace's list, but the other workspace can't be asked: it may be there.
      backend.watchKeys = [];
      backend.watchListDown.add(_org2);
      await bridge.prune();
      expect((await WatchKeyStore.load()).single.keyId, 'watch1');

      // Its own workspace can't be asked: nothing is known.
      backend.watchListDown
        ..clear()
        ..add(orgId);
      await bridge.prune();
      expect((await WatchKeyStore.load()).single.keyId, 'watch1');

      // Everyone answers, and nobody has it.
      backend.watchListDown.clear();
      await bridge.prune();
      expect(await WatchKeyStore.load(), isEmpty);
    },
  );

  test(
    'a watch in a workspace the person has left is kept (its key can still be taken back at sign-out)',
    () async {
      final bridge = await start(container());
      await bridge.handle(MethodCall('request', _request('r1')));
      // The server says the person isn't in that workspace any more; it lists nothing for it.
      backend.watchOrgsLeft.add(orgId);
      await bridge.prune();
      expect((await WatchKeyStore.load()).single.keyId, 'watch1');
    },
  );

  test(
    'Settings → Watch opening forgets a watch the server no longer has',
    () async {
      final bridge = await start(container());
      await bridge.handle(MethodCall('request', _request('r1')));
      backend.watchKeys = [];
      await bridge.prune();
      expect(await WatchKeyStore.load(), isEmpty);
    },
  );

  test('a move that failed offline is tried again on resume', () async {
    addSecondOrg();
    final c = container();
    addTearDown(() => c.read(selectedOrgIdProvider.notifier).select(null));
    final bridge = await start(c);
    await bridge.handle(MethodCall('request', _request('r1')));
    calls.clear();

    backend.watchRegisterError = Exception('offline');
    c.read(selectedOrgIdProvider.notifier).select(_org2);
    await pumpEventQueue();
    await pumpEventQueue();
    expect((await WatchKeyStore.load()).single.orgId, orgId);
    expect(calls.where((c) => c.method == 'setContext'), isEmpty);

    backend.watchRegisterError = null;
    await bridge.catchUp();
    expect((await WatchKeyStore.load()).single.orgId, _org2);
    expect(backend.watchKeys.single.orgId, _org2);
    expect(calls.where((c) => c.method == 'setContext'), hasLength(1));
  });

  test(
    'signing out of the phone removes its watches and signs them out',
    () async {
      final c = container();
      final bridge = await start(c);
      await bridge.handle(MethodCall('request', _request('r1')));
      await bridge.handle(
        MethodCall('request', _request('r2', fingerprint: _fp2)),
      );
      calls.clear();
      // The provider hears the sign-out.
      final sub = c.listen(signedInProvider, (_, _) {});
      addTearDown(sub.close);
      await backend.signOut();
      await pumpEventQueue();
      await pumpEventQueue();
      expect(backend.watchKeysDeleted, unorderedEquals(['watch1', 'watch2']));
      expect(backend.watchKeys, isEmpty);
      expect(await WatchKeyStore.load(), isEmpty);
      expect(calls.where((c) => c.method == 'signOut'), hasLength(1));
    },
  );

  test('Sign Out Everywhere takes back every watch the person has, while the session works', () async {
    final c = container();
    final bridge = await start(c);
    await bridge.handle(MethodCall('request', _request('r1')));
    // One this phone never signed in: by code, in another workspace.
    backend.watchKeys = [
      ...backend.watchKeys,
      WatchKeyView(
        id: 'lost',
        orgId: _org2,
        platform: WatchSystem.wearos,
        name: 'Lost watch',
        pairedBy: 'code',
        createdAt: DateTime.utc(2026, 11, 1),
      ),
    ];
    calls.clear();
    final sub = c.listen(signedInProvider, (_, _) {});
    addTearDown(sub.close);
    await backend.signOutEverywhere();
    await pumpEventQueue();
    await pumpEventQueue();
    expect(backend.watchKeysDeletedAll, 1);
    expect(backend.watchKeys, isEmpty, reason: 'the lost watch too');
    expect(await WatchKeyStore.load(), isEmpty);
    expect(calls.where((c) => c.method == 'signOut'), hasLength(1));
  });

  test('Sign Out Everywhere on an older server removes the watches this phone knows', () async {
    backend.watchDeleteAllSupported = false;
    final c = container();
    final bridge = await start(c);
    await bridge.handle(MethodCall('request', _request('r1')));
    final sub = c.listen(signedInProvider, (_, _) {});
    addTearDown(sub.close);
    await backend.signOutEverywhere();
    await pumpEventQueue();
    await pumpEventQueue();
    expect(backend.watchKeysDeletedAll, 0);
    expect(backend.watchKeysDeleted, ['watch1']);
    expect(await WatchKeyStore.load(), isEmpty);
  });

  test(
    "signing out while the keys can't be deleted (offline): the watches are still told, and the keys go when the account is back",
    () async {
      final c = container();
      final bridge = await start(c);
      await bridge.handle(MethodCall('request', _request('r1')));
      await bridge.handle(
        MethodCall('request', _request('r2', fingerprint: _fp2)),
      );
      calls.clear();
      final sub = c.listen(signedInProvider, (_, _) {});
      addTearDown(sub.close);

      backend.watchDeleteError = Exception('offline');
      await backend.signOut();
      await pumpEventQueue();
      await pumpEventQueue();
      expect(
        calls.where((c) => c.method == 'signOut'),
        hasLength(1),
        reason: 'the watches are told whether or not their keys went',
      );
      expect(backend.watchKeysDeleted, isEmpty);
      expect(backend.watchKeys, hasLength(2), reason: 'still on the server');
      expect(
        [for (final r in await WatchKeyStore.load()) (r.keyId, r.removal)],
        unorderedEquals([
          ('watch1', WatchRemoval.pending),
          ('watch2', WatchRemoval.pending),
        ]),
        reason: 'kept, to be taken back later',
      );

      // The same account is back and the server can be reached: the keys go, nothing is said twice.
      backend.watchDeleteError = null;
      await backend.signIn('a@example.com', 'pw');
      await until(() => backend.watchKeysDeleted.length == 2);
      expect(backend.watchKeysDeleted, unorderedEquals(['watch1', 'watch2']));
      await pumpEventQueue();
      expect(await WatchKeyStore.load(), isEmpty);
      expect(calls.where((c) => c.method == 'signOut'), hasLength(1));
    },
  );

  test(
    'signing out with a watch still waiting from an earlier sign-out: its key goes too, and the watches are told once',
    () async {
      final c = container();
      final bridge = await start(c);
      await bridge.handle(MethodCall('request', _request('r1')));
      calls.clear();
      final sub = c.listen(signedInProvider, (_, _) {});
      addTearDown(sub.close);
      // A watch from an earlier sign-out is still waiting for its key to be taken back.
      await WatchKeyStore.save([
        ...await WatchKeyStore.load(),
        const WatchRecord(
          fingerprint: _fp2,
          platform: WatchSystem.wearos,
          name: 'Pixel Watch',
          keyId: 'old',
          orgId: orgId,
          userId: 'me',
          removal: WatchRemoval.pending,
        ),
      ]);
      await backend.signOut();
      await pumpEventQueue();
      await pumpEventQueue();
      expect(backend.watchKeysDeleted, unorderedEquals(['watch1', 'old']));
      expect(await WatchKeyStore.load(), isEmpty);
      expect(calls.where((c) => c.method == 'signOut'), hasLength(1));
    },
  );

  test(
    "Sign Out Everywhere while the keys can't be deleted: the watch is still told, and its key goes when the account is back",
    () async {
      final c = container();
      final bridge = await start(c);
      await bridge.handle(MethodCall('request', _request('r1')));
      calls.clear();
      final sub = c.listen(signedInProvider, (_, _) {});
      addTearDown(sub.close);

      backend.watchDeleteError = Exception('offline');
      await backend.signOutEverywhere();
      await pumpEventQueue();
      await pumpEventQueue();
      expect(calls.where((c) => c.method == 'signOut'), hasLength(1));
      expect(backend.watchKeysDeletedAll, 0);
      expect(backend.watchKeysDeleted, isEmpty);
      final waiting = (await WatchKeyStore.load()).single;
      expect((waiting.keyId, waiting.removal), (
        'watch1',
        WatchRemoval.pending,
      ));

      backend.watchDeleteError = null;
      await backend.signIn('a@example.com', 'pw');
      await until(() => backend.watchKeysDeleted.isNotEmpty);
      expect(backend.watchKeysDeleted, ['watch1']);
      await pumpEventQueue();
      expect(await WatchKeyStore.load(), isEmpty);
      expect(calls.where((c) => c.method == 'signOut'), hasLength(1));
    },
  );

  test(
    "another account signing in on this phone never deletes a waiting watch's key and sends nothing for it",
    () async {
      final c = container();
      final bridge = await start(c);
      await bridge.handle(MethodCall('request', _request('r1')));
      final sub = c.listen(signedInProvider, (_, _) {});
      addTearDown(sub.close);
      backend.watchDeleteError = Exception('offline');
      await backend.signOut();
      await pumpEventQueue();
      await pumpEventQueue();
      backend.watchDeleteError = null;
      calls.clear();

      // Someone else signs in, uses the app, and signs out again.
      backend.signedInAs = 'someone-else';
      await backend.signIn('b@example.com', 'pw');
      await bridge.catchUp();
      await pumpEventQueue();
      expect(backend.watchKeysDeleted, isEmpty);
      await backend.signOut();
      await pumpEventQueue();
      await pumpEventQueue();
      expect(backend.watchKeysDeleted, isEmpty);
      expect(
        calls.where((c) => c.method == 'signOut' || c.method == 'setContext'),
        isEmpty,
        reason: "nothing goes to a watch for someone else's sign-in or sign-out",
      );
      final waiting = (await WatchKeyStore.load()).single;
      expect((waiting.keyId, waiting.userId, waiting.removal), (
        'watch1',
        'me',
        WatchRemoval.pending,
      ));

      // The first account is back: now its key goes.
      backend.signedInAs = 'me';
      await backend.signIn('a@example.com', 'pw');
      await until(() => backend.watchKeysDeleted.isNotEmpty);
      expect(backend.watchKeysDeleted, ['watch1']);
      await pumpEventQueue();
      expect(await WatchKeyStore.load(), isEmpty);
    },
  );

  test('a session that ended by itself: the watch is told, and its key goes when the account is back', () async {
    final c = container();
    final bridge = await start(c);
    await bridge.handle(MethodCall('request', _request('r1')));
    calls.clear();
    final sub = c.listen(signedInProvider, (_, _) {});
    addTearDown(sub.close);

    // Signed out from another device: this phone had no chance to delete the key.
    backend.endSession();
    await pumpEventQueue();
    await pumpEventQueue();
    expect(backend.watchKeysDeleted, isEmpty);
    expect(backend.watchKeys, hasLength(1), reason: 'still on the server');
    final waiting = (await WatchKeyStore.load()).single;
    expect(
      (waiting.keyId, waiting.removal),
      ('watch1', WatchRemoval.pending),
      reason: 'kept, not forgotten',
    );
    expect(calls.where((c) => c.method == 'signOut'), hasLength(1));

    // A second sign-out event doesn't tell the watches again.
    await bridge.signedOut();
    expect(calls.where((c) => c.method == 'signOut'), hasLength(1));

    await backend.signIn('a@example.com', 'pw');
    await until(() => backend.watchKeysDeleted.isNotEmpty);
    expect(backend.watchKeysDeleted, ['watch1']);
    await pumpEventQueue();
    expect(await WatchKeyStore.load(), isEmpty);
  });

  test('the same watch asking again when the account is back ends up signed in, its key not taken back after', () async {
    final c = container();
    final bridge = await start(c);
    await bridge.handle(MethodCall('request', _request('r1')));
    calls.clear();
    final sub = c.listen(signedInProvider, (_, _) {});
    addTearDown(sub.close);
    backend.endSession();
    await pumpEventQueue();
    await pumpEventQueue();
    expect((await WatchKeyStore.load()).single.removal, WatchRemoval.pending);

    // Back in, and the watch (which never heard the sign-out) asks again with the same key,
    // while the old key is being taken back.
    await backend.signIn('a@example.com', 'pw');
    await bridge.handle(MethodCall('request', _request('r2')));
    await until(() => answers().isNotEmpty);
    await bridge.catchUp();
    expect(answers().single['ok'], true);
    // Whichever came first, the record and the server agree on one working key.
    final saved = (await WatchKeyStore.load()).single;
    expect(saved.active, isTrue);
    expect(backend.watchKeys.single.id, saved.keyId);
  });

  test(
    'open goes to the app route; links that leave the app are ignored',
    () async {
      final bridge = await start(container());
      await bridge.handle(const MethodCall('open', {'link': '/approvals/a1'}));
      await bridge.handle(const MethodCall('open', {'link': '//evil.example'}));
      await bridge.handle(
        const MethodCall('open', {'link': 'https://evil.example'}),
      );
      expect(opened, ['/approvals/a1']);
    },
  );

  test('status reads what native code says', () async {
    final bridge = await start(container());
    final s = await bridge.status();
    expect((s?.supported, s?.paired, s?.installed), (true, true, false));
  });

  test('no native side: every call is a quiet no-op', () async {
    messenger.setMockMethodCallHandler(channel, null);
    final c = container();
    final bridge = await start(c);
    expect(await bridge.status(), isNull);
    await bridge.takeRequests();
    // A request still gets handled; its answer just has nowhere to go.
    await bridge.handle(MethodCall('request', _request('r1')));
    expect(backend.watchKeysRegistered, hasLength(1));
    await bridge.signedOut();
  });

  test('off the phones, there is no bridge', () {
    final c = ProviderContainer(
      overrides: [
        backendProvider.overrideWithValue(backend),
        watchBridgeSupportedProvider.overrideWithValue(false),
      ],
    );
    addTearDown(c.dispose);
    expect(c.read(watchBridgeProvider), isNull);
  });
}
