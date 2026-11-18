import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:casama_sdk/casama_link.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:qr/qr.dart';

import 'commands_selfhost.dart' show composeArgs, selfhostDir;
import 'runner.dart';

/// What the remote commands run and call. Tests replace these; nothing else does.
class RemoteDeps {
  /// `docker compose …` and friends.
  Future<ProcessResult> Function(String exe, List<String> args) run =
      Process.run;

  /// Runs the stack's installer again in [dir], giving each line it prints to [onLine].
  Future<int> Function(Directory dir, void Function(String line) onLine)
  installer = _runInstaller;
  http.Client? client;
  Future<void> Function(Uri url) openBrowser = _openBrowser;
  Future<void> Function(Duration) sleep = Future<void>.delayed;
}

RemoteDeps remoteDeps = RemoteDeps();

Future<int> _runInstaller(
  Directory dir,
  void Function(String line) onLine,
) async {
  final proc = await Process.start('bash', [
    p.join(dir.path, 'install.sh'),
  ], workingDirectory: dir.path);
  final done = <Future<void>>[];
  for (final s in [proc.stdout, proc.stderr]) {
    done.add(
      s.transform(utf8.decoder).transform(const LineSplitter()).forEach(onLine),
    );
  }
  final code = await proc.exitCode;
  await Future.wait(done);
  return code;
}

Future<void> _openBrowser(Uri url) async {
  final cmd = Platform.isMacOS
      ? 'open'
      : (Platform.isWindows ? 'explorer' : 'xdg-open');
  try {
    await Process.run(cmd, [url.toString()]);
  } catch (_) {
    // No browser here (a server reached over SSH): the link was printed, any device will do.
  }
}

/// `casama selfhost remote …`: Casama Link remote access for a self-hosted server (D-296).
class RemoteCommand extends KCommand {
  RemoteCommand(super.ctx) {
    addSubcommand(_On(ctx));
    addSubcommand(_Link(ctx));
    addSubcommand(_Off(ctx));
    addSubcommand(_RemoteStatus(ctx));
  }
  @override
  String get name => 'remote';
  @override
  String get description =>
      'Give this server a public address through Casama Link: no domain, no open ports.';
}

RemoteAccessSetup _setup(Directory d, {String? cloud, String? name}) =>
    RemoteAccessSetup(
      stackDir: d,
      runInstaller: (onLine) => remoteDeps.installer(d, onLine),
      defaultCloudUrl:
          cloud ?? Platform.environment['CASAMA_CLOUD_URL'] ?? casamaCloudUrl,
      instanceName: (name ?? Platform.localHostname).trim().isEmpty
          ? 'Casama server'
          : (name ?? Platform.localHostname).trim(),
      platform: Platform.operatingSystem,
      version: cliVersion,
      client: remoteDeps.client,
      sleep: remoteDeps.sleep,
    );

/// How many accounts the server has, or null when its database doesn't answer.
Future<int?> _accounts(Directory d) async {
  try {
    final r = await remoteDeps.run('docker', [
      ...composeArgs(d),
      'exec',
      '-T',
      'db',
      'psql',
      '-U',
      'postgres',
      '-tAc',
      'select count(*) from auth.users',
    ]);
    return r.exitCode == 0 ? int.tryParse('${r.stdout}'.trim()) : null;
  } on ProcessException {
    return null;
  }
}

class _On extends KCommand {
  _On(super.ctx) {
    argParser
      ..addOption(
        'name',
        help: 'What to call this server in Casama Cloud (default: this machine\'s name).',
      )
      ..addOption(
        'cloud',
        help: 'Casama Cloud address, for a cloud you run yourself (or CASAMA_CLOUD_URL).',
      )
      ..addFlag(
        'relink',
        negatable: false,
        help: 'Link again even when this server already has a key.',
      )
      ..addFlag(
        'invites',
        defaultsTo: null,
        help:
            'Let people you invited make an account while it is on (--no-invites closes sign-ups). '
            'Left out: closed for a new address, unchanged for one that is on.',
      )
      ..addFlag(
        'no-browser',
        negatable: false,
        help: 'Only print the link; don\'t try to open a browser.',
      )
      ..addFlag(
        'verbose',
        abbr: 'v',
        negatable: false,
        help: 'Show the installer\'s output while the server restarts.',
      );
  }
  @override
  String get name => 'on';
  @override
  String get description =>
      'Link this server to Casama Cloud (approve a code in a browser) and give it a public address.';
  @override
  Future<int> run() async {
    final a = argResults!;
    final d = selfhostDir(this);
    final setup = _setup(
      d,
      cloud: a['cloud'] as String?,
      name: a['name'] as String?,
    );
    final env = await _guard(setup.readEnv);
    final say = ctx.json ? ctx.err : ctx.out;

    // Sign-ups close when the address opens. Before that, whoever signs up first owns the server,
    // so the owner's account has to be there already.
    if (!RemoteAccessSettings.isOn(env)) {
      final accounts = await _accounts(d);
      if (accounts == null) {
        throw CliError(
          'not_running',
          'The server isn\'t running. Start it with `casama selfhost up`, then try again.',
        );
      }
      if (accounts == 0) {
        final local = env['CASAMA_PUBLIC_URL'] ?? 'this server';
        throw CliError(
          'no_account',
          'Create your account on this server first (open the Casama app with the server $local, or run `casama signup`). '
              'Remote access closes sign-ups, and until then the first account to sign up owns the server.',
        );
      }
    }

    String? address;
    await _guard(() async {
      await for (final s in setup.turnOn(
        relink: a['relink'] as bool,
        invites: a['invites'] as bool?,
      )) {
        switch (s.step) {
          case RemoteSetupStep.linking:
            final code = s.code!;
            say
              ..writeln('Link this server to Casama Cloud:')
              ..writeln()
              ..writeln('  1. Open ${code.verificationUrl}')
              ..writeln(
                '  2. Check that the page shows the code ${code.userCode}, then choose Link.',
              )
              ..writeln()
              ..writeln(
                'Waiting for you to approve it (the code works for ${code.expiresIn.inMinutes} minutes)…',
              );
            if (!(a['no-browser'] as bool)) {
              unawaited(remoteDeps.openBrowser(code.verificationUrl));
            }
          case RemoteSetupStep.address:
            say.writeln('Linked. Getting an address…');
          case RemoteSetupStep.restarting:
            if (s.detail == null) {
              say.writeln(
                'Restarting the server with its address ${s.address}…',
              );
            } else if (a['verbose'] as bool) {
              say.writeln('  ${s.detail}');
            }
          case RemoteSetupStep.connecting:
            say.writeln('Connecting…');
          case RemoteSetupStep.ready:
            address = s.address;
          case RemoteSetupStep.off:
            break;
        }
      }
    });
    final after = await setup.readEnv();
    return ctx.emit(
      {
        'remote_access': 'on',
        'address': address,
        'pages_address': after['CASAMA_PAGES_URL'],
        'local_address': after['CASAMA_LOCAL_URL'],
        'invites': RemoteAccessSettings.invitesOn(after),
      },
      [
        '',
        'Remote access is on.',
        '',
        '  Address: $address',
        if ((after['CASAMA_LOCAL_URL'] ?? '').isNotEmpty)
          '  On this machine the server still answers at ${after['CASAMA_LOCAL_URL']}.',
        '',
        'On your phone: open Casama, tap Sign in > More options > Server and enter the address,',
        'or run `casama pair` here and scan the code.',
        RemoteAccessSettings.invitesOn(after)
            ? 'People you invite can make an account; nobody else can.'
            : 'New sign-ups are closed while remote access is on (--invites lets invited people in).',
      ].join('\n'),
    );
  }
}

/// `casama selfhost remote link`: the link alone, for a server that has its own address and only
/// wants its notifications to reach the apps from the stores.
class _Link extends KCommand {
  _Link(super.ctx) {
    argParser
      ..addOption(
        'name',
        help:
            'What to call this server in Casama Cloud (default: this machine\'s name).',
      )
      ..addOption(
        'cloud',
        help:
            'Casama Cloud address, for a cloud you run yourself (or CASAMA_CLOUD_URL).',
      )
      ..addFlag(
        'relink',
        negatable: false,
        help: 'Link again even when this server already has a key.',
      )
      ..addFlag(
        'no-browser',
        negatable: false,
        help: 'Only print the link; don\'t try to open a browser.',
      )
      ..addFlag(
        'verbose',
        abbr: 'v',
        negatable: false,
        help: 'Show the installer\'s output while the server restarts.',
      );
  }
  @override
  String get name => 'link';
  @override
  String get description =>
      'Link this server to Casama Cloud without an address, so its notifications reach the apps from the App Store and Google Play.';
  @override
  Future<int> run() async {
    final a = argResults!;
    final d = selfhostDir(this);
    final setup = _setup(
      d,
      cloud: a['cloud'] as String?,
      name: a['name'] as String?,
    );
    await _guard(setup.readEnv);
    final say = ctx.json ? ctx.err : ctx.out;
    var asked = false;
    await _guard(() async {
      await for (final s in setup.link(relink: a['relink'] as bool)) {
        switch (s.step) {
          case RemoteSetupStep.linking:
            asked = true;
            final code = s.code!;
            say
              ..writeln('Link this server to Casama Cloud:')
              ..writeln()
              ..writeln('  1. Open ${code.verificationUrl}')
              ..writeln(
                '  2. Check that the page shows the code ${code.userCode}, then choose Link.',
              )
              ..writeln()
              ..writeln(
                'Waiting for you to approve it (the code works for ${code.expiresIn.inMinutes} minutes)…',
              );
            if (!(a['no-browser'] as bool)) {
              unawaited(remoteDeps.openBrowser(code.verificationUrl));
            }
          case RemoteSetupStep.restarting:
            if (s.detail == null) {
              say.writeln('Linked. Restarting the server so it uses the link…');
            } else if (a['verbose'] as bool) {
              say.writeln('  ${s.detail}');
            }
          case RemoteSetupStep.address:
          case RemoteSetupStep.connecting:
          case RemoteSetupStep.ready:
          case RemoteSetupStep.off:
            break;
        }
      }
    });
    return ctx.emit(
      {'linked': true, 'changed': asked},
      [
        asked
            ? 'This server is linked to Casama Cloud.'
            : 'This server is already linked to Casama Cloud.',
        'Its notifications reach the Casama apps from the App Store and Google Play through Casama Cloud.',
        'To keep their text on this server, turn on Private Notifications in the app (Settings > Casama Link).',
      ].join('\n'),
    );
  }
}

class _Off extends KCommand {
  _Off(super.ctx) {
    argParser.addFlag(
      'verbose',
      abbr: 'v',
      negatable: false,
      help: 'Show the installer\'s output while the server restarts.',
    );
  }
  @override
  String get name => 'off';
  @override
  String get description =>
      'Turn remote access off: the address stops answering and the server is on this machine only again.';
  @override
  Future<int> run() async {
    final d = selfhostDir(this);
    final setup = _setup(d);
    final env = await _guard(setup.readEnv);
    if (!RemoteAccessSettings.isOn(env)) {
      return ctx.emit({
        'remote_access': 'off',
      }, 'Remote access is already off.');
    }
    final say = ctx.json ? ctx.err : ctx.out;
    await _guard(() async {
      await for (final s in setup.turnOff()) {
        if (s.step == RemoteSetupStep.restarting) {
          if (s.detail == null) {
            say.writeln('Restarting the server without its address…');
          } else if (argResults!['verbose'] as bool) {
            say.writeln('  ${s.detail}');
          }
        }
      }
    });
    final after = await setup.readEnv();
    return ctx.emit(
      {'remote_access': 'off', 'local_address': after['CASAMA_PUBLIC_URL']},
      'Remote access is off. The server answers only at ${after['CASAMA_PUBLIC_URL']} again, and keeps its link to Casama Cloud:\n'
      'turning it on again gives it the same address.',
    );
  }
}

class _RemoteStatus extends KCommand {
  _RemoteStatus(super.ctx);
  @override
  String get name => 'status';
  @override
  String get description =>
      'Show the address and where it stops when it isn\'t working.';
  @override
  Future<int> run() async {
    final d = selfhostDir(this);
    final setup = _setup(d);
    final env = await _guard(setup.readEnv);
    final key = env['CASAMA_CLOUD_KEY'] ?? '';
    final id = env['CASAMA_INSTANCE_ID'] ?? '';
    final linked = key.isNotEmpty && id.isNotEmpty;
    if (!RemoteAccessSettings.isOn(env)) {
      return ctx.emit(
        {'remote_access': 'off', 'linked': linked},
        'Remote access is off.${linked ? ' This server is linked to Casama Cloud; `casama selfhost remote on` gives it its address back.' : ' Turn it on with `casama selfhost remote on`.'}',
      );
    }
    final address = env['CASAMA_PUBLIC_URL'] ?? '';
    final cloud = CasamaLinkClient(
      cloudUrl: (env['CASAMA_CLOUD_URL'] ?? '').isNotEmpty
          ? env['CASAMA_CLOUD_URL']!
          : casamaCloudUrl,
      client: remoteDeps.client,
    );

    // The four places it can stop, in the order a request travels back: Casama Cloud's record, the
    // connector on this server, and the address as the outside world sees it.
    RemoteInfo? info;
    String? cloudProblem;
    try {
      info = await cloud.info(key, id);
      if (info == null) cloudProblem = 'Casama Cloud has no address for this server. Run `casama selfhost remote on` again.';
    } on LinkException catch (e) {
      cloudProblem = e.status == 401
          ? 'Casama Cloud no longer accepts this server\'s key (it was revoked). Run `casama selfhost remote on --relink`.'
          : e.message;
    }
    var answers = false;
    if (address.isNotEmpty) {
      final client = remoteDeps.client ?? http.Client();
      try {
        final res = await client
            .get(Uri.parse('$address/readyz'))
            .timeout(const Duration(seconds: 15));
        answers = res.statusCode == 200;
      } catch (_) {
        answers = false;
      } finally {
        if (remoteDeps.client == null) client.close();
      }
    }
    final String state;
    final String? problem;
    if (cloudProblem != null) {
      state = 'needs_attention';
      problem = cloudProblem;
    } else if (info!.status == 'suspended') {
      state = 'needs_attention';
      problem =
          'Remote access was turned off for this server by Casama Cloud${info.reason == null ? '' : ' (${info.reason})'}.';
    } else if (info.status == 'released') {
      state = 'needs_attention';
      problem = 'This server was removed from its workspace in Casama Cloud. Run `casama selfhost remote on` to connect it again.';
    } else if (!info.connected) {
      state = 'offline';
      problem =
          'The connector on this server isn\'t connected. Check `casama selfhost logs connector`; a network that blocks outbound port 7844 '
          '(a VPN or a strict firewall) is the usual cause.';
    } else if (!answers) {
      state = 'offline';
      problem =
          'The connector is connected, but $address doesn\'t answer yet. A new address can take a minute; if it stays this way, check `casama selfhost status`.';
    } else {
      state = 'online';
      problem = null;
    }
    return ctx.emit(
      {
        'remote_access': 'on',
        'state': state,
        'address': address,
        'local_address': env['CASAMA_LOCAL_URL'],
        'connector': info?.connector,
        'answers': answers,
        'problem': problem,
        'live_view': info?.liveView,
      },
      [
        'Remote access is on: $address',
        if ((env['CASAMA_LOCAL_URL'] ?? '').isNotEmpty)
          'On this machine: ${env['CASAMA_LOCAL_URL']}',
        problem == null
            ? 'It is working: the address answers from outside.'
            : 'It is not working: $problem',
        if (info?.liveView == 'included')
          'Live view away from this computer: included in your plan.',
        if (info?.liveView == 'plan')
          'Live view away from this computer: screenshots, about one a second. Live video comes with Plus and up on Casama Cloud.',
      ].join('\n'),
    );
  }
}

/// `casama pair`: a code a phone scans to sign in to the account this CLI is signed in as, on the
/// server it points at (D-296). Works for any server, Casama Cloud included.
class PairCommand extends KCommand {
  PairCommand(super.ctx);
  @override
  String get name => 'pair';
  @override
  String get description =>
      'Show a code your phone scans to sign in to this account (works for a few minutes).';
  @override
  Future<int> run() async {
    final c = await ctx.authedClient();
    final code = (await c.signInCodes.createSignInCode()).data!;
    final minutes = code.expiresAt
        .difference(DateTime.now())
        .inMinutes
        .clamp(1, 60);
    return ctx.emit(
      {
        'pair_url': code.pairUrl,
        'server_url': code.serverUrl,
        'reachable': code.reachable,
        'expires_at': code.expiresAt.toUtc().toIso8601String(),
      },
      [
        if (!code.reachable) ...[
          'Note: ${code.serverUrl} only answers on this machine or network. A phone somewhere else needs',
          'remote access first: `casama selfhost remote on`.',
          '',
        ],
        terminalQr(code.pairUrl),
        'Scan this with your phone\'s camera, or in Casama: Sign in > Scan a code.',
        'It signs the phone in to your account on ${code.serverUrl} and works once, for $minutes minutes.',
        'Don\'t share it: anyone who scans it is signed in as you.',
      ].join('\n'),
    );
  }
}

/// [data] as a QR code drawn with half-height blocks, dark on a white background whatever the
/// terminal's colours (most phone cameras don't read a light-on-dark code).
String terminalQr(String data) {
  final qr = QrCode.fromData(
    data: data,
    errorCorrectLevel: QrErrorCorrectLevel.L,
  );
  final image = QrImage(qr);
  const quiet = 2;
  final size = image.moduleCount + quiet * 2;
  bool dark(int x, int y) {
    final mx = x - quiet, my = y - quiet;
    return mx >= 0 &&
        my >= 0 &&
        mx < image.moduleCount &&
        my < image.moduleCount &&
        image.isDark(my, mx);
  }

  final out = StringBuffer();
  for (var y = 0; y < size; y += 2) {
    out.write('\x1B[47m\x1B[30m');
    for (var x = 0; x < size; x++) {
      final top = dark(x, y), bottom = y + 1 < size && dark(x, y + 1);
      out.write(top ? (bottom ? '█' : '▀') : (bottom ? '▄' : ' '));
    }
    out.writeln('\x1B[0m');
  }
  return out.toString();
}

/// LinkException -> the CLI's error, so it prints (and exits) like every other failure.
Future<T> _guard<T>(Future<T> Function() fn) async {
  try {
    return await fn();
  } on LinkException catch (e) {
    throw CliError(e.code, e.message);
  }
}
