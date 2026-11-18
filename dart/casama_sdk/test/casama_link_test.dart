import 'dart:io';

import 'package:casama_sdk/casama_link.dart';
import 'package:test/test.dart';

import 'fake_link_cloud.dart';

/// Casama Link for a self-hosted server (D-296): the calls to Casama Cloud, the settings a
/// stack gets when remote access turns on and off, and the whole switch with a stand-in cloud and
/// a stand-in installer.
void main() {
  late FakeLinkCloud cloud;
  late Directory dir;
  late File env;
  final installs = <Map<String, String>>[];

  const localEnv = '''
# Casama self-host settings
CASAMA_SITE=:80
CASAMA_PUBLIC_URL=http://localhost:8080
HTTP_PORT=8080
JWT_SECRET=keep-me
CASAMA_PAGES_URL=http://localhost:8790
EMAIL_AUTOCONFIRM=true
CASAMA_CLOUD_URL=
CASAMA_CLOUD_KEY=
''';

  RemoteAccessSetup setup({int exitCode = 0}) => RemoteAccessSetup(
    stackDir: dir,
    defaultCloudUrl: cloud.url,
    instanceName: 'Home Mac',
    platform: 'macos',
    version: '0.1.0',
    client: cloud.client,
    sleep: (_) async {},
    connectTimeout: const Duration(milliseconds: 200),
    runInstaller: (onLine) async {
      // What the stack would start with.
      installs.add(parseStackEnv(env.readAsStringSync()));
      onLine('==> Starting the stack');
      return exitCode;
    },
  );

  setUp(() {
    cloud = FakeLinkCloud();
    installs.clear();
    dir = Directory.systemTemp.createTempSync('casama-link');
    env = File('${dir.path}/infra/compose/.env')
      ..createSync(recursive: true)
      ..writeAsStringSync(localEnv);
  });
  tearDown(() => dir.deleteSync(recursive: true));

  group('the calls to Casama Cloud', () {
    test('link: start, wait while pending, collect the key once', () async {
      final c = CasamaLinkClient(
        cloudUrl: '${cloud.url}/',
        client: cloud.client,
      );
      final code = await c.startLink(
        instanceId: newInstanceId(),
        instanceName: 'Home Mac',
      );
      expect(code.userCode, 'K7QM-2XFD');
      expect(
        code.verificationUrl.toString(),
        'https://app.example.test/link?code=K7QM-2XFD',
      );
      expect(code.interval, const Duration(seconds: 3));
      expect(await c.pollLink(code.deviceCode), isNull);
      final waits = <Duration>[];
      final linked = await c.waitForLink(
        code,
        sleep: (d) async => waits.add(d),
      );
      expect(linked.key, 'kcc_linked-key');
      expect(linked.workspace, 'Home');
      expect(linked.scopes, ['remote_access', 'push']);
      expect(waits, isEmpty, reason: 'the second poll was already approved');
      // The key is handed over once.
      await expectLater(
        c.pollLink(code.deviceCode),
        throwsA(
          isA<LinkException>().having((e) => e.code, 'code', 'link_expired'),
        ),
      );
    });

    test(
      'a wait can be cancelled, and survives a moment without network',
      () async {
        final c = CasamaLinkClient(
          cloudUrl: cloud.url,
          client: cloud.client,
        );
        final code = await c.startLink(
          instanceId: newInstanceId(),
          instanceName: 'x',
        );
        cloud.pollsBeforeApproval = 2;
        var polls = 0;
        final linked = await c.waitForLink(
          code,
          sleep: (_) async {
            // No network for one poll, then back.
            cloud.down = ++polls == 1;
          },
        );
        expect(linked.key, isNotEmpty);
        final again = await c.startLink(
          instanceId: newInstanceId(),
          instanceName: 'x',
        );
        cloud.keyHanded = false;
        cloud.pollsBeforeApproval = 99;
        await expectLater(
          c.waitForLink(again, cancelled: () => true, sleep: (_) async {}),
          throwsA(
            isA<LinkException>().having((e) => e.code, 'code', 'cancelled'),
          ),
        );
      },
    );

    test(
      'address, status and release, with refusals as stable codes',
      () async {
        final c = CasamaLinkClient(
          cloudUrl: cloud.url,
          client: cloud.client,
        );
        cloud.key = 'kcc_k';
        expect(await c.info('kcc_k', 'id-12345678'), isNull);
        final a = await c.address(
          'kcc_k',
          instanceId: 'id-12345678',
          instanceName: 'Home Mac',
          platform: 'macos',
        );
        expect(a.address, 'https://k7qm2xfd9abc.link.test');
        expect(a.pagesAddress, 'https://k7qm2xfd9abc-p.link.test');
        expect(a.generation, 1);
        expect(cloud.lastServerInfo, {
          'instance_id': 'id-12345678',
          'instance_name': 'Home Mac',
          'platform': 'macos',
        });
        final info = await c.info('kcc_k', 'id-12345678');
        expect(info!.status, 'active');
        expect(info.connected, isTrue);
        cloud.connected = false;
        expect((await c.info('kcc_k', 'id-12345678'))!.connected, isFalse);
        await c.release('kcc_k', 'id-12345678');
        expect((await c.info('kcc_k', 'id-12345678'))!.status, 'released');

        cloud.refuseAddress = 402;
        await expectLater(
          c.address('kcc_k', instanceId: 'id-12345678'),
          throwsA(
            isA<LinkException>()
                .having((e) => e.code, 'code', 'plan_limit')
                .having(
                  (e) => e.message,
                  'message',
                  contains('Your plan connects 1 server'),
                ),
          ),
        );
        await expectLater(
          c.address('kcc_wrong', instanceId: 'id-12345678'),
          throwsA(
            isA<LinkException>().having((e) => e.status, 'status', 401),
          ),
        );
        cloud.down = true;
        await expectLater(
          c.whoami('kcc_k'),
          throwsA(
            isA<LinkException>().having(
              (e) => e.code,
              'code',
              'unreachable',
            ),
          ),
        );
      },
    );

    test('instance ids are random UUIDs', () {
      final a = newInstanceId(), b = newInstanceId();
      expect(
        a,
        matches(
          RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          ),
        ),
      );
      expect(a, isNot(b));
    });
  });

  group('the stack\'s settings', () {
    final address = const RemoteAddress(
      address: 'https://abc.link.test',
      pagesAddress: 'https://abc-p.link.test',
      generation: 1,
    );

    test(
      'on: the address becomes public, the old one stays local, sign-ups close',
      () {
        final before = parseStackEnv(localEnv);
        final on = RemoteAccessSettings.on(
          before,
          cloudUrl: 'https://cloud.test',
          key: 'kcc_k',
          instanceId: 'id-1',
          address: address,
        );
        expect(on, containsPair('CASAMA_REMOTE_ACCESS', 'on'));
        expect(
          on,
          containsPair('CASAMA_PUBLIC_URL', 'https://abc.link.test'),
        );
        expect(
          on,
          containsPair('CASAMA_PAGES_URL', 'https://abc-p.link.test'),
        );
        expect(on, containsPair('CASAMA_LOCAL_URL', 'http://localhost:8080'));
        expect(on, containsPair('DISABLE_SIGNUP', 'true'));
        expect(
          on,
          containsPair('TRUSTED_CLIENT_IP_HEADER', 'cf-connecting-ip'),
        );
        expect(on, containsPair('AUTH_RATE_LIMIT_HEADER', 'cf-connecting-ip'));
        expect(
          on,
          containsPair(
            'SIGNUP_HOOK_URI',
            'https://abc.link.test/hooks/auth/before-user-created',
          ),
        );
        expect(on, containsPair('CASAMA_CLOUD_KEY', 'kcc_k'));
        expect(on[RemoteAccessSettings.savedKey], isNotEmpty);
      },
    );

    test('off restores exactly what was there, and keeps the link', () {
      final before = parseStackEnv(localEnv);
      final on = {
        ...before,
        ...RemoteAccessSettings.on(
          before,
          cloudUrl: 'https://cloud.test',
          key: 'kcc_k',
          instanceId: 'id-1',
          address: address,
        ),
      };
      final off = {...on, ...RemoteAccessSettings.off(on)};
      for (final k in RemoteAccessSettings.changed) {
        expect(off[k], before[k] ?? '', reason: k);
      }
      expect(off['CASAMA_REMOTE_ACCESS'], 'off');
      expect(off['CASAMA_LOCAL_URL'], '');
      expect(off[RemoteAccessSettings.savedKey], '');
      expect(off['CASAMA_CLOUD_KEY'], 'kcc_k');
      expect(off['CASAMA_INSTANCE_ID'], 'id-1');
    });

    test(
      'with invitations, sign-ups go through the hook instead of closing',
      () {
        final before = parseStackEnv(localEnv);
        final on = RemoteAccessSettings.on(
          before,
          cloudUrl: 'https://cloud.test',
          key: 'kcc_k',
          instanceId: 'id-1',
          address: address,
          invites: true,
        );
        expect(on, containsPair('DISABLE_SIGNUP', 'false'));
        expect(on, containsPair('SIGNUP_HOOK_ENABLED', 'true'));
        expect(on, containsPair('SIGNUP_INVITED_ONLY', 'true'));
        final now = {...before, ...on};
        expect(RemoteAccessSettings.invitesOn(now), isTrue);
        // Off puts all three back as they were (unset here).
        final off = {...now, ...RemoteAccessSettings.off(now)};
        expect(off['DISABLE_SIGNUP'], '');
        expect(off['SIGNUP_HOOK_ENABLED'], '');
        expect(off['SIGNUP_INVITED_ONLY'], '');
        expect(RemoteAccessSettings.invitesOn(off), isFalse);

        // Closed, the default, doesn't lean on the hook being set up.
        final closed = RemoteAccessSettings.on(
          before,
          cloudUrl: 'https://cloud.test',
          key: 'kcc_k',
          instanceId: 'id-1',
          address: address,
        );
        expect(closed, containsPair('DISABLE_SIGNUP', 'true'));
        expect(closed, containsPair('SIGNUP_INVITED_ONLY', 'false'));
        expect(closed.containsKey('SIGNUP_HOOK_ENABLED'), isFalse);
        expect(RemoteAccessSettings.invitesOn({...before, ...closed}), isFalse);
      },
    );

    test('turning it on twice keeps the first "before"', () {
      final before = parseStackEnv(localEnv);
      final once = {
        ...before,
        ...RemoteAccessSettings.on(
          before,
          cloudUrl: 'https://cloud.test',
          key: 'kcc_k',
          instanceId: 'id-1',
          address: address,
        ),
      };
      final again = RemoteAccessSettings.on(
        once,
        cloudUrl: 'https://cloud.test',
        key: 'kcc_k',
        instanceId: 'id-1',
        address: address,
      );
      expect(again.containsKey(RemoteAccessSettings.savedKey), isFalse);
      final twice = {...once, ...again};
      expect(twice['CASAMA_LOCAL_URL'], 'http://localhost:8080');
      expect(
        {...twice, ...RemoteAccessSettings.off(twice)}['CASAMA_PUBLIC_URL'],
        'http://localhost:8080',
      );
    });

    test('a lost "before" still brings the server back to its own machine', () {
      final off = RemoteAccessSettings.off({
        'CASAMA_REMOTE_ACCESS': 'on',
        'CASAMA_PUBLIC_URL': 'https://abc.link.test',
        'CASAMA_LOCAL_URL': 'http://localhost:8080',
        RemoteAccessSettings.savedKey: 'not-base64!',
      });
      expect(off['CASAMA_PUBLIC_URL'], 'http://localhost:8080');
      expect(off['DISABLE_SIGNUP'], '');
    });

    test('knows a server that already has a public address', () {
      expect(
        RemoteAccessSettings.hasOwnPublicAddress({
          'CASAMA_PUBLIC_URL': 'https://casama.example.com',
        }),
        isTrue,
      );
      expect(
        RemoteAccessSettings.hasOwnPublicAddress({
          'CASAMA_PUBLIC_URL': 'http://localhost:8080',
        }),
        isFalse,
      );
      expect(
        RemoteAccessSettings.hasOwnPublicAddress({
          'CASAMA_PUBLIC_URL': 'http://localhost',
        }),
        isFalse,
      );
      // Its own Casama Link address doesn't count: turning it on again must work.
      expect(
        RemoteAccessSettings.hasOwnPublicAddress({
          'CASAMA_PUBLIC_URL': 'https://abc.link.test',
          'CASAMA_REMOTE_ACCESS': 'on',
        }),
        isFalse,
      );
    });

    test(
      'updating the .env replaces keys where they stand and leaves the rest',
      () async {
        env.writeAsStringSync(
          '# top\nA=1\nB=2\nA=old-duplicate\n\n# keep\nC=3\n',
        );
        await updateStackEnv(env, {'A': 'new', 'D': 'x=y', 'C': ''});
        expect(
          env.readAsStringSync(),
          '# top\nA=new\nB=2\n\n# keep\nC=\nD=x=y\n',
        );
        expect(parseStackEnv(env.readAsStringSync()), {
          'A': 'new',
          'B': '2',
          'C': '',
          'D': 'x=y',
        });
        if (!Platform.isWindows) {
          expect(env.statSync().modeString(), 'rw-------');
        }
      },
    );
  });

  group('turning remote access on and off', () {
    test(
      'links, gets the address, switches the stack and waits for the connector',
      () async {
        final steps = <RemoteSetupProgress>[];
        await setup().turnOn().forEach(steps.add);
        expect(steps.map((s) => s.step), [
          RemoteSetupStep.linking,
          RemoteSetupStep.address,
          RemoteSetupStep.restarting,
          RemoteSetupStep.restarting,
          RemoteSetupStep.connecting,
          RemoteSetupStep.ready,
        ]);
        expect(steps.first.code!.userCode, 'K7QM-2XFD');
        expect(steps.last.address, cloud.address);
        expect(steps[3].detail, '==> Starting the stack');

        // The stack restarted with the whole switch in place, and nothing else touched.
        final started = installs.single;
        expect(started['CASAMA_REMOTE_ACCESS'], 'on');
        expect(started['CASAMA_PUBLIC_URL'], cloud.address);
        expect(started['CASAMA_PAGES_URL'], cloud.pagesAddress);
        expect(started['CASAMA_LOCAL_URL'], 'http://localhost:8080');
        expect(started['CASAMA_CLOUD_URL'], cloud.url);
        expect(started['CASAMA_CLOUD_KEY'], 'kcc_linked-key');
        expect(started['DISABLE_SIGNUP'], 'true');
        expect(started['JWT_SECRET'], 'keep-me');
        expect(started['HTTP_PORT'], '8080');
        expect(
          env.readAsStringSync(),
          startsWith('# Casama self-host settings\n'),
        );
        // The cloud was told which server this is, with the same id it keeps.
        expect(
          cloud.lastServerInfo!['instance_id'],
          started['CASAMA_INSTANCE_ID'],
        );
        expect(cloud.lastServerInfo, containsPair('instance_name', 'Home Mac'));
      },
    );

    test(
      'a linked server isn\'t asked to link again, and keeps its address',
      () async {
        await setup().turnOn().drain<void>();
        final id = installs.single['CASAMA_INSTANCE_ID'];
        cloud.calls.clear();
        final steps = await setup().turnOn().toList();
        expect(
          steps.map((s) => s.step),
          isNot(contains(RemoteSetupStep.linking)),
        );
        expect(cloud.calls.where((c) => c.contains('/sign-in/')), isEmpty);
        expect(installs.last['CASAMA_INSTANCE_ID'], id);
        expect(installs.last['CASAMA_PUBLIC_URL'], cloud.address);
        // Still knows what "before" was.
        await setup().turnOff().drain<void>();
        expect(installs.last['CASAMA_PUBLIC_URL'], 'http://localhost:8080');
      },
    );

    test('invitations stay as they were until told otherwise', () async {
      await setup().turnOn(invites: true).drain<void>();
      expect(installs.last['SIGNUP_INVITED_ONLY'], 'true');
      expect(installs.last['DISABLE_SIGNUP'], 'false');
      // Turned on again (a relink, a repair): still by invitation.
      await setup().turnOn().drain<void>();
      expect(installs.last['SIGNUP_INVITED_ONLY'], 'true');
      await setup().turnOn(invites: false).drain<void>();
      expect(installs.last['SIGNUP_INVITED_ONLY'], 'false');
      expect(installs.last['DISABLE_SIGNUP'], 'true');
    });

    test(
      'turning off releases the address and puts the settings back',
      () async {
        await setup().turnOn().drain<void>();
        final steps = await setup().turnOff().toList();
        expect(steps.last.step, RemoteSetupStep.off);
        expect(cloud.status, 'released');
        final after = installs.last;
        expect(after['CASAMA_REMOTE_ACCESS'], 'off');
        expect(after['CASAMA_PUBLIC_URL'], 'http://localhost:8080');
        expect(after['CASAMA_PAGES_URL'], 'http://localhost:8790');
        expect(after['DISABLE_SIGNUP'], '');
        expect(after['TRUSTED_CLIENT_IP_HEADER'], '');
        // The link stays, so the next time gives the same address.
        expect(after['CASAMA_CLOUD_KEY'], 'kcc_linked-key');
        await setup().turnOn().drain<void>();
        expect(installs.last['CASAMA_PUBLIC_URL'], cloud.address);
      },
    );

    test(
      'off works with no network: the server comes back to this machine anyway',
      () async {
        await setup().turnOn().drain<void>();
        cloud.down = true;
        await setup().turnOff().drain<void>();
        expect(installs.last['CASAMA_REMOTE_ACCESS'], 'off');
        expect(installs.last['CASAMA_PUBLIC_URL'], 'http://localhost:8080');
      },
    );

    test('a refusal leaves the stack untouched', () async {
      cloud.refuseAddress = 402;
      await expectLater(
        setup().turnOn().drain<void>(),
        throwsA(
          isA<LinkException>().having((e) => e.code, 'code', 'plan_limit'),
        ),
      );
      expect(installs, isEmpty);
      final now = parseStackEnv(env.readAsStringSync());
      expect(now['CASAMA_PUBLIC_URL'], 'http://localhost:8080');
      expect(now['CASAMA_REMOTE_ACCESS'], isNull);
      // The link itself was kept: the key is handed over only once.
      expect(now['CASAMA_CLOUD_KEY'], 'kcc_linked-key');
    });

    test(
      'a server with its own domain is told it doesn\'t need this',
      () async {
        env.writeAsStringSync('CASAMA_PUBLIC_URL=https://casama.example.com\n');
        await expectLater(
          setup().turnOn().drain<void>(),
          throwsA(
            isA<LinkException>().having(
              (e) => e.code,
              'code',
              'has_address',
            ),
          ),
        );
        expect(cloud.calls, isEmpty);
      },
    );

    test('a key that can\'t hold an address is explained; a revoked one links again', () async {
      cloud.key = 'kcc_computers-only';
      cloud.remoteScope = false;
      env.writeAsStringSync(
        '${localEnv}CASAMA_CLOUD_KEY=kcc_computers-only\nCASAMA_CLOUD_URL=${cloud.url}\n',
      );
      await expectLater(
        setup().turnOn().drain<void>(),
        throwsA(
          isA<LinkException>().having((e) => e.code, 'code', 'key_scope'),
        ),
      );
      expect(installs, isEmpty);

      // Revoked at the cloud: the server links again by itself.
      cloud
        ..key = 'kcc_something-newer'
        ..remoteScope = true;
      final steps = await setup().turnOn().toList();
      expect(steps.first.step, RemoteSetupStep.linking);
      expect(installs.single['CASAMA_CLOUD_KEY'], 'kcc_linked-key');
    });

    test(
      'a connector that never connects is named, with the usual cause',
      () async {
        cloud.connected = false;
        await expectLater(
          setup().turnOn().drain<void>(),
          throwsA(
            isA<LinkException>()
                .having((e) => e.code, 'code', 'not_connected')
                .having((e) => e.message, 'message', contains('7844')),
          ),
        );
        // The switch itself is done, so trying again only has to wait for the connector.
        expect(installs.single['CASAMA_REMOTE_ACCESS'], 'on');
      },
    );

    test(
      'an installer that fails is reported, with the settings kept',
      () async {
        await expectLater(
          setup(exitCode: 1).turnOn().drain<void>(),
          throwsA(
            isA<LinkException>().having(
              (e) => e.code,
              'code',
              'install_failed',
            ),
          ),
        );
        expect(
          parseStackEnv(env.readAsStringSync())['CASAMA_PUBLIC_URL'],
          cloud.address,
        );
      },
    );

    test('a server that was never installed says so', () async {
      env.deleteSync();
      await expectLater(
        setup().turnOn().drain<void>(),
        throwsA(
          isA<LinkException>().having(
            (e) => e.code,
            'code',
            'not_installed',
          ),
        ),
      );
    });
  });
}
