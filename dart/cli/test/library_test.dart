import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:casama_cli/src/commands_library.dart';
import 'package:casama_cli/src/runner.dart';
import 'package:test/test.dart';

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('casama-library-test'));
  tearDown(() => dir.deleteSync(recursive: true));

  Future<(int, String, String)> run(List<String> args) async {
    final out = StringBuffer();
    final err = StringBuffer();
    final ctx = CliContext(out, err, configDirOverride: dir);
    final runner = CommandRunner<int>('casama', 'test')
      ..argParser.addFlag('json', negatable: false)
      ..addCommand(ProjectsCommand(ctx))
      ..addCommand(LibraryCommand(ctx))
      ..addCommand(_ComputerHolder(ctx));
    int code;
    try {
      final top = runner.parse(args);
      ctx.json = top['json'] as bool;
      code = await runner.runCommand(top) ?? 0;
    } on UsageException catch (e) {
      err.writeln(e);
      code = 64;
    } on CliError catch (e) {
      code = ctx.fail(e.code, e.message);
    }
    return (code, out.toString(), err.toString());
  }

  test('commands need their targets', () async {
    for (final (args, text) in [
      (['projects', 'show'], 'Which project?'),
      (['projects', 'create'], 'called'),
      (['projects', 'create', 'Site'], '--bot'),
      (['projects', 'edit'], 'Which project?'),
      (['projects', 'edit', 'p1'], 'Nothing to change'),
      (['projects', 'approve-plan'], 'Which project?'),
      (['projects', 'signoff', 'p1'], 'milestone id'),
      (['library', 'show'], 'Which creation?'),
      (['library', 'download'], 'Which creation?'),
      (['library', 'rename', 'c1'], 'new title'),
      (['library', 'duplicate'], 'Which creation?'),
      (['library', 'restore'], 'Which creation?'),
      (['library', 'delete'], 'Which creation?'),
      (['library', 'list', '--limit', '500'], '1 to 100'),
      (['library', 'list', '--kind', 'banana'], 'banana'),
      (['computer', 'kill'], 'PID'),
      (['computer', 'kill', 'abc'], 'PID'),
    ]) {
      final (code, _, err) = await run(args);
      expect(code, 64, reason: '$args');
      expect(err, contains(text), reason: '$args');
    }
  });

  test('bad numbers and dates in projects edit are usage errors', () async {
    final (c1, _, e1) = await run([
      'projects',
      'edit',
      'p1',
      '--budget',
      'lots',
    ]);
    expect(c1, 64);
    expect(e1, contains('--budget'));
    final (c2, _, e2) = await run([
      'projects',
      'edit',
      'p1',
      '--deadline',
      'soon',
    ]);
    expect(c2, 64);
    expect(e2, contains('2026-12-31'));
  });

  test('library delete without --yes says what would happen', () async {
    final (code, out, _) = await run(['library', 'delete', 'c1']);
    expect(code, 0);
    expect(out, contains('--yes'));
    expect(out, contains('c1'));
    final (code2, out2, _) = await run(['--json', 'library', 'delete', 'c1']);
    expect(code2, 0);
    expect(jsonDecode(out2)['confirm'], '--yes');
  });

  test('network commands need a login', () async {
    final (code, _, err) = await run([
      '--json',
      'projects',
      'list',
      '--org',
      'crumb',
    ]);
    expect(code, 1);
    expect(jsonDecode(err)['error'], 'not_logged_in');
  });

  test('creationFileName', () {
    expect(creationFileName('Report', 'application/pdf'), 'Report.pdf');
    expect(creationFileName('notes.md', 'text/markdown'), 'notes.md');
    expect(creationFileName('a/b:c', 'text/html; charset=utf-8'), 'a_b_c.html');
    expect(creationFileName('..', null), 'creation');
    expect(creationFileName('Thing', 'application/x-weird'), 'Thing');
  });

  test('formatBytes', () {
    expect(formatBytes(512), '512 B');
    expect(formatBytes(2048), '2.0 KB');
    expect(formatBytes(5 * 1024 * 1024 * 1024), '5.0 GB');
  });

  test('textOption reads @file', () {
    final f = File('${dir.path}/plan.md')..writeAsStringSync('hello');
    expect(textOption('@${f.path}'), 'hello');
    expect(textOption('plain'), 'plain');
    expect(textOption(null), isNull);
    expect(() => textOption('@${dir.path}/missing'), throwsA(isA<CliError>()));
  });
}

/// Stands in for ComputerCommand: only the new subcommands, since the real one is not registered yet.
class _ComputerHolder extends Command<int> {
  _ComputerHolder(CliContext ctx) {
    addSubcommand(ComputerRestartCommand(ctx));
    addSubcommand(ComputerResetCommand(ctx));
    addSubcommand(ComputerProcessesCommand(ctx));
    addSubcommand(ComputerKillCommand(ctx));
    addSubcommand(ComputerScreenshotCommand(ctx));
    addSubcommand(ComputerVitalsCommand(ctx));
    addSubcommand(ComputerStorageCommand(ctx));
    addSubcommand(ComputerStorageCleanCommand(ctx));
    addSubcommand(ComputerHistoryCommand(ctx));
    addSubcommand(ComputerUpdateCommand(ctx));
    addSubcommand(ComputerCheckpointCommand(ctx));
    addSubcommand(ComputerUsageCommand(ctx));
  }
  @override
  String get name => 'computer';
  @override
  String get description => 'test';
}
