import 'dart:convert';
import 'dart:io';

import 'package:casama_cli/casama_cli.dart';
import 'package:casama_cli/src/commands_selfhost.dart' show composeArgs;
import 'package:casama_sdk/casama_link.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../casama_sdk/test/fake_link_cloud.dart';

/// `casama selfhost remote on|off|status` (D-296), with a stand-in Casama Cloud, a stand-in
/// installer and a stand-in `docker` that answers how many accounts the server has.
void main() {
  late Directory dir;
  late File env;
  late FakeLinkCloud cloud;
  late StringBuffer out, err;
  late List<Uri> opened;
  late int installs;
  int? accounts;

  Future<int> cli(List<String> args, {bool json = false}) {
    out = StringBuffer();
    err = StringBuffer();
    return runCli(
      [if (json) '--json', 'selfhost', '--dir', dir.path, 'remote', ...args],
      out: out,
      err: err,
      configDir: dir,
    );
  }

  Map<String, String> settings() => parseStackEnv(env.readAsStringSync());

  setUp(() {
    dir = Directory.systemTemp.createTempSync('casama-remote');
    File(p.join(dir.path, 'install.sh')).writeAsStringSync('#!/bin/sh\n');
    env = File(p.join(dir.path, 'infra', 'compose', '.env'))
      ..createSync(recursive: true)
      ..writeAsStringSync(
        'CASAMA_SITE=:80\nCASAMA_PUBLIC_URL=http://localhost:8080\nJWT_SECRET=keep-me\n',
      );
    cloud = FakeLinkCloud();
    opened = [];
    installs = 0;
    accounts = 1;
    remoteDeps = RemoteDeps()
      ..client = cloud.client
      ..sleep = ((_) async {})
      ..openBrowser = ((url) async => opened.add(url))
      ..installer = ((d, onLine) async {
        installs++;
        onLine('==> Starting the stack');
        return 0;
      })
      ..run = (exe, args) async {
        expect(exe, 'docker');
        expect(args, containsAllInOrder(['exec', '-T', 'db', 'psql']));
        return accounts == null
            ? ProcessResult(0, 1, '', 'service "db" is not running')
            : ProcessResult(0, 0, '$accounts\n', '');
      };
  });
  tearDown(() {
    remoteDeps = RemoteDeps();
    dir.deleteSync(recursive: true);
  });

  test('on: shows the code, opens the browser, switches the server and prints the address', () async {
    expect(
      await cli(['on', '--cloud', cloud.url, '--name', 'Home Mac']),
      0,
      reason: '$err',
    );
    final text = '$out';
    expect(text, contains('Open https://app.example.test/link?code=K7QM-2XFD'));
    expect(text, contains('shows the code K7QM-2XFD'));
    expect(text, contains('Remote access is on.'));
    expect(text, contains('Address: ${cloud.address}'));
    expect(text, contains('still answers at http://localhost:8080'));
    expect(text, contains('New sign-ups are closed'));
    expect(
      text,
      isNot(contains('==> Starting the stack')),
      reason: 'installer output only with --verbose',
    );
    expect(
      opened.single.toString(),
      'https://app.example.test/link?code=K7QM-2XFD',
    );
    expect(installs, 1);
    final s = settings();
    expect(s['CASAMA_REMOTE_ACCESS'], 'on');
    expect(s['CASAMA_PUBLIC_URL'], cloud.address);
    expect(s['CASAMA_LOCAL_URL'], 'http://localhost:8080');
    expect(s['CASAMA_CLOUD_URL'], cloud.url);
    expect(s['DISABLE_SIGNUP'], 'true');
    expect(s['JWT_SECRET'], 'keep-me');
    expect(cloud.lastServerInfo, containsPair('instance_name', 'Home Mac'));
  });

  test('on --json: the result on stdout, the steps on stderr, and no browser when told', () async {
    expect(
      await cli([
        'on',
        '--cloud',
        cloud.url,
        '--no-browser',
        '--verbose',
      ], json: true),
      0,
      reason: '$err',
    );
    expect(jsonDecode('$out'), {
      'remote_access': 'on',
      'address': cloud.address,
      'pages_address': cloud.pagesAddress,
      'local_address': 'http://localhost:8080',
      'invites': false,
    });
    expect('$err', contains('K7QM-2XFD'));
    expect('$err', contains('==> Starting the stack'));
    expect(opened, isEmpty);
  });

  test(
    'on is refused until the owner\'s account exists, and nothing is linked',
    () async {
      accounts = 0;
      expect(await cli(['on', '--cloud', cloud.url]), 1);
      expect('$err', contains('Create your account on this server first'));
      expect('$err', contains('(no_account)'));
      expect(cloud.calls, isEmpty);
      expect(installs, 0);
      expect(settings()['CASAMA_REMOTE_ACCESS'], isNull);

      accounts = null;
      expect(await cli(['on', '--cloud', cloud.url]), 1);
      expect('$err', contains('(not_running)'));
      expect(cloud.calls, isEmpty);
    },
  );

  test(
    'link: a server on its own domain gets the link alone, for notifications',
    () async {
      File('${dir.path}/infra/compose/.env').writeAsStringSync(
        'CASAMA_SITE=casama.example.com\nCASAMA_PUBLIC_URL=https://casama.example.com\nJWT_SECRET=keep-me\n',
      );
      // An address is for servers without one.
      expect(await cli(['on', '--cloud', cloud.url]), 1);
      expect('$err', contains('already has a public address'));
      expect(cloud.calls, isEmpty);

      expect(await cli(['link', '--cloud', cloud.url]), 0, reason: '$err');
      expect('$out', contains('shows the code K7QM-2XFD'));
      expect('$out', contains('This server is linked to Casama Cloud.'));
      expect('$out', contains('Private Notifications'));
      expect(installs, 1);
      final s = settings();
      expect(s['CASAMA_CLOUD_URL'], cloud.url);
      expect(s['CASAMA_CLOUD_KEY'], cloud.key);
      expect(s['CASAMA_INSTANCE_ID'], isNotEmpty);
      // Nothing about who can reach the server changed.
      expect(s['CASAMA_PUBLIC_URL'], 'https://casama.example.com');
      expect(s['CASAMA_REMOTE_ACCESS'], isNull);
      expect(s['DISABLE_SIGNUP'], isNull);
      expect(cloud.calls.where((c) => c.contains('/remote')), isEmpty);

      // Again: nothing to do, and no restart.
      expect(await cli(['link'], json: true), 0, reason: '$err');
      expect(jsonDecode('$out'), {'linked': true, 'changed': false});
      expect(installs, 1);

      // A key that can't send notifications says so, and --relink replaces it.
      cloud.pushScope = false;
      expect(await cli(['link']), 1);
      expect('$err', contains('can\'t send notifications'));
      expect(await cli(['link', '--relink']), 0, reason: '$err');
      expect(installs, 2);
    },
  );

  test('on passes Casama Cloud\'s refusal on in its own words', () async {
    cloud.refuseAddress = 402;
    expect(await cli(['on', '--cloud', cloud.url]), 1);
    expect('$err', contains('Your plan connects 1 server'));
    expect('$err', contains('(plan_limit)'));
    expect(installs, 0);
  });

  test('status: off, working, and where it stops', () async {
    expect(await cli(['status']), 0);
    expect(
      '$out',
      contains(
        'Remote access is off. Turn it on with `casama selfhost remote on`.',
      ),
    );

    await cli(['on', '--cloud', cloud.url]);
    expect(await cli(['status']), 0);
    expect('$out', contains('Remote access is on: ${cloud.address}'));
    expect('$out', contains('It is working'));
    await cli(['status'], json: true);
    expect(jsonDecode('$out'), containsPair('state', 'online'));
    // What the plan gives for live view away from the computer, when Casama Cloud says.
    expect('$out', isNot(contains('Live view away')));
    cloud.liveView = 'plan';
    await cli(['status']);
    expect('$out', contains('Live video comes with Plus and up'));
    cloud.liveView = 'included';
    await cli(['status']);
    expect('$out', contains('Live view away from this computer: included'));
    await cli(['status'], json: true);
    expect(jsonDecode('$out'), containsPair('live_view', 'included'));

    cloud.connected = false;
    await cli(['status']);
    expect(
      '$out',
      contains(
        'It is not working: The connector on this server isn\'t connected.',
      ),
    );
    expect('$out', contains('7844'));

    cloud
      ..connected = true
      ..answers = false;
    await cli(['status'], json: true);
    final j = jsonDecode('$out') as Map<String, dynamic>;
    expect(j['state'], 'offline');
    expect(j['answers'], false);

    cloud
      ..answers = true
      ..status = 'suspended';
    await cli(['status']);
    expect(
      '$out',
      contains('turned off for this server by Casama Cloud (reported)'),
    );

    cloud.key = 'kcc_revoked-and-replaced';
    await cli(['status']);
    expect('$out', contains('no longer accepts this server\'s key'));
  });

  test('off: back to this machine only, and linked for next time', () async {
    await cli(['on', '--cloud', cloud.url]);
    expect(await cli(['off']), 0, reason: '$err');
    expect(
      '$out',
      contains(
        'Remote access is off. The server answers only at http://localhost:8080 again',
      ),
    );
    expect(installs, 2);
    final s = settings();
    expect(s['CASAMA_REMOTE_ACCESS'], 'off');
    expect(s['CASAMA_PUBLIC_URL'], 'http://localhost:8080');
    expect(s['DISABLE_SIGNUP'], '');
    expect(s['CASAMA_CLOUD_KEY'], 'kcc_linked-key');
    expect(cloud.status, 'released');

    expect(await cli(['off']), 0);
    expect('$out', contains('already off'));
    expect(installs, 2);
    expect(await cli(['status']), 0);
    expect('$out', contains('linked to Casama Cloud'));
  });

  test('the stack\'s own commands include the connector while remote access is on', () async {
    // `casama selfhost up`, `down` and `logs` run Docker Compose with these.
    expect(composeArgs(dir), isNot(contains('link')));
    await cli(['on', '--cloud', cloud.url]);
    expect(composeArgs(dir), containsAllInOrder(['--profile', 'link']));
    await cli(['off']);
    expect(composeArgs(dir), isNot(contains('link')));
  });

  test('needs a checkout', () async {
    File(p.join(dir.path, 'install.sh')).deleteSync();
    expect(await cli(['status']), 1);
    expect('$err', contains('No install.sh'));
  });

  test('the terminal QR is a square of half blocks on a white background', () {
    final qr = terminalQr(
      'https://casama.ai/pair#v=1&s=https%3A%2F%2Fk7qm2xfd9abc.link.test&c=ksc_0123456789abcdefghijklmnopqrstuvwxyzABCDEFG',
    );
    final lines = const LineSplitter().convert(qr);
    final width = lines.first.replaceAll(RegExp(r'\x1B\[[0-9;]*m'), '').length;
    expect(
      lines.every(
        (l) => l.startsWith('\x1B[47m\x1B[30m') && l.endsWith('\x1B[0m'),
      ),
      isTrue,
    );
    expect(
      lines.every(
        (l) => l.replaceAll(RegExp(r'\x1B\[[0-9;]*m'), '').length == width,
      ),
      isTrue,
    );
    // Two modules per line of text, and a quiet zone of blanks around the code.
    expect(lines.length, (width / 2).ceil());
    expect(
      lines.first.replaceAll(RegExp(r'\x1B\[[0-9;]*m'), '').trim(),
      isEmpty,
    );
    expect(qr, contains('█'));
  });
}
