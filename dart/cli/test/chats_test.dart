import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:casama_cli/src/commands_chats.dart';
import 'package:casama_cli/src/runner.dart';
import 'package:test/test.dart';

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('casama-chats-test'));
  tearDown(() => dir.deleteSync(recursive: true));

  Future<(int, String, String)> run(List<String> args) async {
    final out = StringBuffer();
    final err = StringBuffer();
    final ctx = CliContext(out, err, configDirOverride: dir);
    final runner = CommandRunner<int>('casama', 'test')
      ..argParser.addFlag('json', negatable: false)
      ..addCommand(ChatsCommand(ctx))
      ..addCommand(_BotHolder(ctx));
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
      (['chats', 'list'], 'Which bot?'),
      (['chats', 'show'], 'Which conversation?'),
      (['chats', 'rename', 'abc'], 'new title'),
      (['chats', 'branch', 'abc'], 'message id'),
      (['chats', 'message-delete', 'abc'], 'message id'),
      (['chats', 'message-edit', 'abc', 'm'], 'new text'),
      (['bot', 'show'], 'Which bot?'),
      (['bot', 'import'], 'Which file?'),
    ]) {
      final (code, _, err) = await run(args);
      expect(code, 64, reason: '$args');
      expect(err, contains(text), reason: '$args');
    }
  });

  test('delete and clear without --yes only say what would happen', () async {
    final (code, out, _) = await run(['chats', 'delete', 'c1']);
    expect(code, 0);
    expect(out, contains('--yes'));
    final (code2, out2, _) = await run([
      '--json',
      'chats',
      'message-delete',
      'c1',
      'm1',
    ]);
    expect(code2, 0);
    expect(jsonDecode(out2)['confirm'], '--yes');
  });

  test('network commands need a login', () async {
    final (code, _, err) = await run([
      '--json',
      'chats',
      'list',
      'Ada',
      '--org',
      'crumb',
    ]);
    expect(code, 1);
    expect(jsonDecode(err)['error'], 'not_logged_in');
  });

  test('thread messages print who, time and text', () {
    final text = threadMessageText({
      'id': 'm1',
      'role': 'assistant',
      'created_at': '2026-11-19T10:30:00Z',
      'content': [
        {'type': 'text', 'text': 'Hello'},
        {'type': 'text', 'text': ' there\nsecond line'},
      ],
    });
    expect(text, '''bot  2026-11-19 10:30  (m1)
  Hello there
  second line''');
  });

  test('@file text is read, other text is kept', () {
    final f = File('${dir.path}/t.txt')..writeAsStringSync('from file');
    expect(textOrFile('@${f.path}'), 'from file');
    expect(textOrFile('plain'), 'plain');
    expect(() => textOrFile('@${dir.path}/none'), throwsA(isA<CliError>()));
  });
}

class _BotHolder extends Command<int> {
  _BotHolder(CliContext ctx) {
    addSubcommand(BotShowCommand(ctx));
    addSubcommand(BotExportCommand(ctx));
    addSubcommand(BotImportCommand(ctx));
    addSubcommand(BotShareCommand(ctx));
    addSubcommand(BotCheckinsCommand(ctx));
    addSubcommand(BotStartersCommand(ctx));
  }
  @override
  String get name => 'bot';
  @override
  String get description => 'test holder';
}
