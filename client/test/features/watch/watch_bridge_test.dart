// The phone's side of signing a watch in (D-410, WATCH-PROTOCOL §3): what it answers signed out,
// with the app lock declined and on success; what a workspace switch and a sign-out do; and that
// a missing native side is a quiet no-op.
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
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      switch (call.method) {
        case 'takeRequests':
          final out = [...held];
          held.clear();
          return out;
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
          return allow;
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

  test('signed out: the watch is told so, and nothing is registered', () async {
    backend.signedIn = false;
    final bridge = await start(container());
    await bridge.handle(MethodCall('request', _request('r1')));
    expect(answers().single, {
      'request_id': 'r1',
      'ok': false,
      'reason': 'signed_out',
    });
    expect(backend.watchKeysRegistered, isEmpty);
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
        'ok': false,
        'reason': 'declined',
      });
      expect(backend.watchKeysRegistered, isEmpty);
    },
  );

  test('app lock on and allowed: signs in', () async {
    final bridge = await start(container(lockOn: true));
    await bridge.handle(MethodCall('request', _request('r1')));
    expect(asked, hasLength(1));
    expect(answers().single['ok'], true);
  });

  test('success: registers the fingerprint for the workspace and answers who and where', () async {
    final bridge = await start(container());
    await bridge.handle(MethodCall('request', _request('r1')));
    expect(backend.watchKeysRegistered, [
      (orgId, _fp1, "Oliver's Apple Watch"),
    ]);
    expect(answers().single, {
      'request_id': 'r1',
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
      expect(
        [for (final a in answers()) (a['request_id'], a['ok'])],
        [('r1', true), ('r2', true)],
      );
      expect((await WatchKeyStore.load()).map((r) => r.platform), [
        WatchSystem.watchos,
        WatchSystem.wearos,
      ]);
    },
  );

  test('a workspace switch signs each watch in to the new one and tells the watches', () async {
    backend.extraOrgs.add(
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
    expect(backend.watchKeysDeleted, [
      'watch1',
    ], reason: 'the old workspace key goes');
    final saved = (await WatchKeyStore.load()).single;
    expect((saved.orgId, saved.keyId), (_org2, 'watch2'));
    final context = calls.singleWhere((c) => c.method == 'setContext');
    expect(context.arguments, {
      'server': 'http://localhost:8787',
      'org_id': _org2,
      'org_name': 'Second',
      'person_name': 'Oliver',
    });
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
      expect(await WatchKeyStore.load(), isEmpty);
      expect(calls.where((c) => c.method == 'signOut'), hasLength(1));
    },
  );

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
