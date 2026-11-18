import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:casama_cli/src/commands_routines.dart';
import 'package:casama_cli/src/runner.dart';
import 'package:test/test.dart';

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('casama-routines'));
  tearDown(() => dir.deleteSync(recursive: true));

  Future<(int, String, String)> run(List<String> args) async {
    final out = StringBuffer();
    final err = StringBuffer();
    final ctx = CliContext(out, err, configDirOverride: dir);
    final r = CommandRunner<int>('casama', 'test')
      ..addCommand(RoutinesCommand(ctx))
      ..addCommand(ApprovalsCommand(ctx));
    final runs = Command0();
    r.addCommand(runs);
    runs
      ..addSubcommand(RunsShowCommand(ctx))
      ..addSubcommand(RunsUsageCommand(ctx));
    try {
      final code = await r.run(args) ?? 0;
      return (code, out.toString(), err.toString());
    } on UsageException catch (e) {
      err.writeln(e.message);
      return (64, out.toString(), err.toString());
    } on CliError catch (e) {
      err.writeln('${e.code}: ${e.message}');
      return (1, out.toString(), err.toString());
    }
  }

  test('usage errors', () async {
    expect((await run(['routines', 'show'])).$3, contains('Which routine?'));
    expect((await run(['routines', 'create'])).$3, contains('Which bot?'));
    expect(
      (await run(['routines', 'create', 'b', '--instructions', 'x'])).$3,
      contains('--name is required'),
    );
    expect(
      (await run([
        'routines',
        'create',
        'b',
        '--name',
        'n',
        '--instructions',
        'x',
      ])).$3,
      contains('one of --schedule or --at'),
    );
    expect(
      (await run(['routines', 'edit', 'r1'])).$3,
      contains('Nothing to change'),
    );
    expect(
      (await run(['routines', 'edit', 'r1', '--enable', '--disable'])).$3,
      contains('not both'),
    );
    expect(
      (await run(['routines', 'edit', 'r1', '--max-runs', 'x'])).$3,
      contains('whole number'),
    );
    expect(
      (await run(['approvals', 'approve'])).$3,
      contains('Which approval?'),
    );
    expect((await run(['runs', 'show'])).$3, contains('Which run?'));
    expect((await run(['runs', 'usage'])).$3, contains('Which run?'));
  });

  test('delete without --yes prints what would happen', () async {
    final (code, out, _) = await run(['routines', 'delete', 'r1']);
    expect(code, 0);
    expect(out, contains('--yes'));
  });

  test('needs login', () async {
    final (code, _, err) = await run(['routines', 'list']);
    expect(code, 1);
    expect(err, contains('not_logged_in'));
    final (c2, _, e2) = await run(['approvals', 'deny', 'a1']);
    expect(c2, 1);
    expect(e2, contains('not_logged_in'));
  });

  test('helpers', () {
    expect(textOrFile('plain'), 'plain');
    final f = File('${dir.path}/i.md')..writeAsStringSync('do it');
    expect(textOrFile('@${f.path}'), 'do it');
    expect(() => textOrFile('@${dir.path}/none'), throwsA(isA<CliError>()));
    expect(parseCount('3', 'max-runs', 'u'), 3);
    expect(parseWhen('2026-12-31', 'at', 'u'), isNotNull);
    expect(() => parseWhen('soon', 'at', 'u'), throwsA(isA<UsageException>()));
  });
}

class Command0 extends Command<int> {
  @override
  String get name => 'runs';
  @override
  String get description => 'test runs';
}
