import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:casama_cli/src/commands_work.dart';
import 'package:casama_cli/src/runner.dart';
import 'package:test/test.dart';

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('casama-work-test'));
  tearDown(() => dir.deleteSync(recursive: true));

  Future<(int, String, String)> run(List<String> args) async {
    final out = StringBuffer();
    final err = StringBuffer();
    final ctx = CliContext(out, err, configDirOverride: dir);
    final runner = CommandRunner<int>('casama', 'test')
      ..argParser.addFlag('json', negatable: false)
      ..addCommand(TasksCommand(ctx))
      ..addCommand(WatchersCommand(ctx));
    // A stand-in `memory` group with the new subcommands.
    runner.addCommand(_Memory(ctx));
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

  test('usage errors exit 64', () async {
    for (final (args, msg) in [
      (['tasks', 'add'], 'What is the task'),
      (['tasks', 'edit'], 'Which task'),
      (['tasks', 'edit', 'x'], 'Nothing to change'),
      (['tasks', 'edit', 'x', '--done', '--status', 'todo'], 'not both'),
      (['tasks', 'edit', 'x', '--status', 'nope'], 'Status is one of'),
      (['tasks', 'add', 'T', '--due', 'soon'], 'date like'),
      (['tasks', 'comment', 'x'], 'comment text'),
      (['tasks', 'done'], 'Which task'),
      (['watchers', 'add', 'bot'], 'bot and the page'),
      (['watchers', 'add', 'bot', 'example'], 'full address'),
      (['watchers', 'add', 'bot', 'https://a.b', '--every', '0'], 'positive'),
      (['watchers', 'edit', 'x'], '--pause or --resume'),
      (['watchers', 'edit', 'x', '--pause', '--resume'], '--pause or --resume'),
      (['memory', 'edit', 'bot', 'm'], 'Nothing to change'),
      (['memory', 'edit', 'bot', 'm', '--pin', '--unpin'], 'not both'),
      (['memory', 'import', 'bot'], 'Pass the bot'),
    ]) {
      final (code, _, err) = await run(args);
      expect(code, 64, reason: args.join(' '));
      expect(err, contains(msg), reason: args.join(' '));
    }
  });

  test('delete without --yes prints the dry run and needs no login', () async {
    final (code, out, _) = await run(['tasks', 'delete', 't1']);
    expect(code, 0);
    expect(out, contains('--yes'));
    final (c2, out2, _) = await run(['--json', 'watchers', 'delete', 'w1']);
    expect(c2, 0);
    expect(jsonDecode(out2), {
      'would': 'delete watcher w1',
      'confirm': '--yes',
    });
    final (c3, out3, _) = await run([
      '--json',
      'memory',
      'delete',
      'bot',
      'm1',
    ]);
    expect(c3, 0);
    expect(jsonDecode(out3)['confirm'], '--yes');
  });

  test('missing login gives not_logged_in', () async {
    for (final args in [
      ['tasks', 'list'],
      ['tasks', 'done', 't1'],
      ['tasks', 'delete', 't1', '--yes'],
      ['watchers', 'list', 'bot'],
      ['memory', 'import-prompt'],
    ]) {
      final (code, _, err) = await run(['--json', ...args]);
      expect(code, 1, reason: args.join(' '));
      expect(jsonDecode(err)['error'], 'not_logged_in');
    }
  });

  test('readTextArg reads @file and passes plain text through', () {
    final f = File('${dir.path}/n.txt')..writeAsStringSync('hello');
    expect(readTextArg('@${f.path}'), 'hello');
    expect(readTextArg('plain'), 'plain');
    expect(() => readTextArg('@${dir.path}/none'), throwsA(isA<CliError>()));
  });

  test('parseDue gives UTC', () {
    UsageException bad(String m) => UsageException(m, '');
    expect(
      parseDue('2026-12-01T10:00:00Z', bad),
      DateTime.utc(2026, 12, 1, 10),
    );
    expect(parseDue('2026-12-01', bad).isUtc, isTrue);
    expect(parseDue('2026-12-01', bad).toLocal().day, 1, reason: 'a bare date keeps its day here');
  });
}

class _Memory extends Command<int> {
  _Memory(CliContext ctx) {
    addSubcommand(MemoryEditCommand(ctx));
    addSubcommand(MemoryDeleteCommand(ctx));
    addSubcommand(MemoryImportCommand(ctx));
    addSubcommand(MemoryImportPromptCommand(ctx));
  }
  @override
  String get name => 'memory';
  @override
  String get description => 'test';
}
