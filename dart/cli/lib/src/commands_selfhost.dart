import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:kasama_api/kasama_api.dart';
import 'package:path/path.dart' as p;

import 'runner.dart';

/// `kasama selfhost …`: install and operate a self-hosted stack (Phase 8, D-076). Wraps
/// install.sh and `docker compose` for the repository checkout given by --dir (or
/// KASAMA_SELFHOST_DIR, or the current directory).
class SelfhostCommand extends KCommand {
  SelfhostCommand(super.ctx) {
    argParser.addOption('dir', help: 'Kasama checkout with install.sh (or KASAMA_SELFHOST_DIR).');
    addSubcommand(_Init(ctx));
    for (final c in [
      ('up', 'Start the stack.', ['up', '-d', '--remove-orphans']),
      ('down', 'Stop the stack (data is kept).', ['down']),
      ('status', 'Show services and health.', ['ps']),
    ]) {
      addSubcommand(_Compose(ctx, c.$1, c.$2, c.$3));
    }
    addSubcommand(_Logs(ctx));
    addSubcommand(_Upgrade(ctx));
    addSubcommand(_Backup(ctx));
    addSubcommand(_Restore(ctx));
  }
  @override
  String get name => 'selfhost';
  @override
  String get description => 'Install and run Kasama on your own server.';
}

Directory _dir(Command<int> c) {
  final given = c.parent?.argResults?['dir'] as String?;
  final path = given ?? Platform.environment['KASAMA_SELFHOST_DIR'] ?? Directory.current.path;
  final d = Directory(path);
  if (!File(p.join(d.path, 'install.sh')).existsSync()) {
    throw CliError('not_a_checkout', 'No install.sh in ${d.path}. Clone github.com/stackwares/kasama and pass --dir.');
  }
  return d;
}

List<String> _composeArgs(Directory d) => [
      'compose',
      '-f',
      p.join(d.path, 'infra', 'compose', 'docker-compose.yml'),
      '--env-file',
      p.join(d.path, 'infra', 'compose', '.env'),
    ];

Future<int> _run(String exe, List<String> args, {String? cwd}) async {
  final proc = await Process.start(exe, args, workingDirectory: cwd, mode: ProcessStartMode.inheritStdio);
  return proc.exitCode;
}

class _Init extends KCommand {
  _Init(super.ctx) {
    argParser
      ..addOption('domain', help: 'Public domain (automatic HTTPS).')
      ..addFlag('local', negatable: false, help: 'This machine only, plain HTTP.')
      ..addOption('http-port', defaultsTo: '80')
      ..addFlag('with-desktop', negatable: false, help: 'Also build the desktop computer image.')
      ..addFlag('monitoring', negatable: false, help: 'Prometheus and Grafana.');
  }
  @override
  String get name => 'init';
  @override
  String get description => 'Generate secrets, build images and start the stack (runs install.sh).';
  @override
  Future<int> run() async {
    final d = _dir(this);
    final a = argResults!;
    return _run('bash', [
      p.join(d.path, 'install.sh'),
      if (a['domain'] != null) ...['--domain', a['domain'] as String],
      if (a['local'] as bool) '--local',
      '--http-port',
      a['http-port'] as String,
      if (a['with-desktop'] as bool) '--with-desktop',
      if (a['monitoring'] as bool) '--monitoring',
    ], cwd: d.path);
  }
}

class _Compose extends KCommand {
  _Compose(super.ctx, this.name, this.description, this.args);
  @override
  final String name;
  @override
  final String description;
  final List<String> args;
  @override
  Future<int> run() async {
    final d = _dir(this);
    return _run('docker', [..._composeArgs(d), ...args]);
  }
}

class _Logs extends KCommand {
  _Logs(super.ctx) {
    argParser.addFlag('follow', abbr: 'f', negatable: false);
  }
  @override
  String get name => 'logs';
  @override
  String get description => 'Show service logs (default: api and worker).';
  @override
  Future<int> run() async {
    final d = _dir(this);
    final services = argResults!.rest.isEmpty ? ['api', 'worker'] : argResults!.rest;
    return _run('docker', [..._composeArgs(d), 'logs', '--tail', '200', if (argResults!['follow'] as bool) '-f', ...services]);
  }
}

class _Upgrade extends KCommand {
  @override
  String get name => 'upgrade';
  @override
  String get description => 'Pull the latest release, rebuild and restart (keeps .env and data).';
  _Upgrade(super.ctx);
  @override
  Future<int> run() async {
    final d = _dir(this);
    final pull = await _run('git', ['-C', d.path, 'pull', '--ff-only']);
    if (pull != 0) return pull;
    return _run('bash', [p.join(d.path, 'install.sh')], cwd: d.path);
  }
}

class _Backup extends KCommand {
  _Backup(super.ctx) {
    argParser.addOption('out', defaultsTo: 'kasama-backups', help: 'Folder for the backup files.');
  }
  @override
  String get name => 'backup';
  @override
  String get description => 'Back up the database, computer archives and .env.';
  @override
  Future<int> run() async {
    final d = _dir(this);
    final stamp = DateTime.now().toUtc().toIso8601String().replaceAll(RegExp(r'[:.]'), '-').substring(0, 19);
    final out = Directory(p.join(argResults!['out'] as String, stamp))..createSync(recursive: true);
    final dump = File(p.join(out.path, 'postgres.dump'));
    final proc = await Process.start('docker', [..._composeArgs(d), 'exec', '-T', 'db', 'pg_dump', '-U', 'postgres', '-Fc', 'postgres']);
    final sink = dump.openWrite();
    await Future.wait([proc.stdout.pipe(sink), stderr.addStream(proc.stderr)]);
    if (await proc.exitCode != 0) throw CliError('backup_failed', 'pg_dump failed');
    final objects = await _run('docker', [
      ..._composeArgs(d),
      'run', '--rm', '--no-deps', '-v', '${p.absolute(out.path)}:/backup', '--entrypoint', 'tar', 'supervisor',
      'czf', '/backup/objects.tar.gz', '-C', '/data/objects', '.',
    ]);
    if (objects != 0) throw CliError('backup_failed', 'could not archive computer snapshots');
    File(p.join(d.path, 'infra', 'compose', '.env')).copySync(p.join(out.path, 'env'));
    await File(p.join(out.path, 'env')).setLastModified(DateTime.now());
    return ctx.emit({'path': out.path}, 'Backup written to ${out.path} (database, computer archives, .env). Keep it private.');
  }
}

class _Restore extends KCommand {
  @override
  String get name => 'restore';
  @override
  String get description => 'Restore a backup folder made by `selfhost backup` (replaces current data).';
  @override
  String get invocation => 'kasama selfhost restore <backup-folder>';
  _Restore(super.ctx);
  @override
  Future<int> run() async {
    final d = _dir(this);
    if (argResults!.rest.length != 1) throw UsageException('Give the backup folder.', usage);
    final from = Directory(argResults!.rest.first);
    final dump = File(p.join(from.path, 'postgres.dump'));
    if (!dump.existsSync()) throw CliError('not_a_backup', 'No postgres.dump in ${from.path}');
    await _run('docker', [..._composeArgs(d), 'stop', 'api', 'worker']);
    final proc = await Process.start('docker', [
      ..._composeArgs(d), 'exec', '-T', 'db', 'pg_restore', '-U', 'postgres', '-d', 'postgres', '--clean', '--if-exists', '--no-owner',
    ]);
    await Future.wait([dump.openRead().pipe(proc.stdin), stderr.addStream(proc.stderr), stdout.addStream(proc.stdout)]);
    await proc.exitCode; // pg_restore warns about Supabase-owned objects; the data is restored.
    final tar = File(p.join(from.path, 'objects.tar.gz'));
    if (tar.existsSync()) {
      await _run('docker', [
        ..._composeArgs(d),
        'run', '--rm', '--no-deps', '-v', '${p.absolute(from.path)}:/backup', '--entrypoint', 'tar', 'supervisor',
        'xzf', '/backup/objects.tar.gz', '-C', '/data/objects',
      ]);
    }
    await _run('docker', [..._composeArgs(d), 'up', '-d']);
    return ctx.emit({'restored': from.path}, 'Restored ${from.path}.');
  }
}

/// `kasama account export|delete` (Phase 8 privacy, D-072).
class AccountCommand extends KCommand {
  AccountCommand(super.ctx) {
    addSubcommand(_Export(ctx));
    addSubcommand(_Delete(ctx));
  }
  @override
  String get name => 'account';
  @override
  String get description => 'Export your data or delete your account.';
}

class _Export extends KCommand {
  _Export(super.ctx) {
    argParser.addOption('out', abbr: 'o', help: 'ZIP file to write (default kasama-export-<date>.zip).');
  }
  @override
  String get name => 'export';
  @override
  String get description => 'Download everything you can see as a ZIP of JSON files.';
  @override
  Future<int> run() async {
    final c = await ctx.authedClient();
    final bytes = (await c.privacy.exportMyData()).data!;
    final path = argResults!['out'] as String? ?? 'kasama-export-${DateTime.now().toIso8601String().substring(0, 10)}.zip';
    File(path).writeAsBytesSync(bytes);
    return ctx.emit({'path': path, 'bytes': bytes.length}, 'Wrote $path (${(bytes.length / 1024).toStringAsFixed(1)} KB).');
  }
}

class _Delete extends KCommand {
  _Delete(super.ctx) {
    argParser.addOption('confirm', help: "Your account's email, to confirm.");
  }
  @override
  String get name => 'delete';
  @override
  String get description => 'Delete your account and workspaces you solely own (after a grace period).';
  @override
  Future<int> run() async {
    final c = await ctx.authedClient();
    final email = argResults!['confirm'] as String? ??
        (() {
          stderr.write('This deletes your account. Type your email to confirm: ');
          return stdin.readLineSync() ?? '';
        })();
    final r = (await c.privacy.deleteMyAccount(deleteAccountRequest: DeleteAccountRequest(confirmEmail: email.trim()))).data!;
    await c.signOut().catchError((_) {});
    return ctx.emit(
      r.toJson(),
      'Your account is scheduled for deletion on ${r.purgeAfter.toLocal()}.'
      '${r.workspacesDeleted.isEmpty ? '' : ' Workspaces deleted with it: ${r.workspacesDeleted.join(', ')}.'}',
    );
  }
}
