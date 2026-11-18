import 'dart:convert';
import 'dart:io';

import 'package:casama_cli/casama_cli.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// The repository root (this test runs from dart/cli).
// `dart test` runs from dart/ (CI, the docs) or from dart/cli, so look upward for the checkout.
final repoRoot = () {
  var dir = Directory.current.absolute.path;
  while (!Directory(p.join(dir, 'packages', 'plugin-check')).existsSync()) {
    final up = p.dirname(dir);
    if (up == dir) throw StateError('No Casama checkout above ${Directory.current.path}');
    dir = up;
  }
  return dir;
}();

bool hasNode() {
  try {
    return Process.runSync('node', ['--version']).exitCode == 0;
  } catch (_) {
    return false;
  }
}

void main() {
  late Directory tmp;
  late Directory config;
  setUp(() {
    tmp = Directory.systemTemp.createTempSync('casama-init-test');
    config = Directory(p.join(tmp.path, '.config'))..createSync();
  });
  tearDown(() => tmp.deleteSync(recursive: true));

  Future<(int, String, String)> run(List<String> args) async {
    final out = StringBuffer();
    final err = StringBuffer();
    final code = await runCli(args, out: out, err: err, configDir: config);
    return (code, out.toString(), err.toString());
  }

  bool exists(String dir, String rel) => File(p.join(dir, rel)).existsSync();

  test(
    'plugin: files, valid manifest, and it passes plugin-check --strict',
    () async {
      final dir = p.join(tmp.path, 'My Weather Plugin');
      final (code, out, err) = await run(['init', 'plugin', dir]);
      expect(code, 0, reason: err);
      expect(out, contains('Created plugin "my-weather-plugin"'));
      for (final rel in [
        'plugin.json',
        'mcp.json',
        'server/server.mjs',
        'skills/my-weather-plugin/SKILL.md',
        'README.md',
        'AGENTS.md',
        '.github/workflows/plugin-check.yml',
      ]) {
        expect(exists(dir, rel), isTrue, reason: rel);
      }
      final manifest = jsonDecode(
        File(p.join(dir, 'plugin.json')).readAsStringSync(),
      );
      expect(manifest['name'], 'my-weather-plugin');
      expect(manifest['version'], '0.1.0');
      final agents = File(p.join(dir, 'AGENTS.md')).readAsStringSync();
      expect(agents, contains('https://docs.casama.ai/llms.txt'));
      expect(agents, contains('https://docs.casama.ai/develop/plugins.md'));
      expect(agents, contains('/plugin install casama-dev@casama'));
      expect(agents, contains('https://api.casama.ai/mcp/docs'));

      if (!hasNode()) {
        markTestSkipped('node is not on PATH');
        return;
      }
      final check = Process.runSync(
        'node',
        ['packages/plugin-check/src/main.ts', dir, '--strict'],
        workingDirectory: repoRoot,
        environment: {'NO_COLOR': '1'},
      );
      expect(check.exitCode, 0, reason: '${check.stdout}\n${check.stderr}');

      // The server answers tools/list.
      final server = await Process.start('node', [
        p.join(dir, 'server/server.mjs'),
      ]);
      server.stdin.writeln(
        jsonEncode({'jsonrpc': '2.0', 'id': 1, 'method': 'tools/list'}),
      );
      await server.stdin.close();
      final reply = await server.stdout.transform(utf8.decoder).join();
      await server.exitCode;
      final tools = (jsonDecode(reply.trim())['result']['tools'] as List)
          .cast<Map>();
      expect(tools.single['name'], 'hello');
    },
  );

  test('skill: SKILL.md with front matter named after the folder', () async {
    final dir = p.join(tmp.path, 'weekly-report');
    final (code, _, err) = await run(['init', 'skill', dir]);
    expect(code, 0, reason: err);
    expect(exists(dir, 'AGENTS.md'), isTrue);
    final skill = File(p.join(dir, 'SKILL.md')).readAsStringSync();
    expect(skill, startsWith('---\nname: weekly-report\ndescription: '));
  });

  test('bot: a casama.bot template', () async {
    final dir = p.join(tmp.path, 'bots');
    final (code, _, err) = await run([
      'init',
      'bot',
      dir,
      '--name',
      'Invoice Chaser',
    ]);
    expect(code, 0, reason: err);
    expect(exists(dir, 'AGENTS.md'), isTrue);
    final t = jsonDecode(
      File(p.join(dir, 'invoice-chaser.casama-bot.json')).readAsStringSync(),
    );
    expect(t['format'], 'casama.bot');
    expect(t['version'], 1);
    expect(t['name'], 'Invoice Chaser');
    expect(t['autonomy'], 'ask_risky');
  });

  test('routine: a routine file with a schedule', () async {
    final dir = p.join(tmp.path, 'Weekly Chase');
    final (code, _, err) = await run(['init', 'routine', dir]);
    expect(code, 0, reason: err);
    expect(exists(dir, 'AGENTS.md'), isTrue);
    final r = File(p.join(dir, 'weekly-chase.md')).readAsStringSync();
    expect(r, startsWith('---\nname: Weekly chase\nschedule: 0 9 * * 1\n'));
  });

  test(
    'refuses to overwrite without --force, and --json lists the files',
    () async {
      final dir = p.join(tmp.path, 'twice');
      expect((await run(['init', 'skill', dir])).$1, 0);
      final (code, _, err) = await run(['init', 'skill', dir]);
      expect(code, 1);
      expect(err, contains('file_exists'));
      final (forced, out, _) = await run([
        '--json',
        'init',
        'skill',
        dir,
        '--force',
      ]);
      expect(forced, 0);
      final j = jsonDecode(out);
      expect(j['files'], ['SKILL.md', 'AGENTS.md']);
      expect(j['overwritten'], ['SKILL.md', 'AGENTS.md']);
    },
  );

  test('rejects an invalid plugin name and a missing kind', () async {
    final (code, _, err) = await run([
      'init',
      'plugin',
      tmp.path,
      '--name',
      'Bad Name',
    ]);
    expect(code, 64);
    expect(err, contains('Try "bad-name"'));
    expect((await run(['init'])).$1, 64);
  });

  test('pack: a plugin with a com.casama folder that passes plugin-check --strict', () async {
    final dir = p.join(tmp.path, 'team-kit');
    final (code, _, err) = await run(['init', 'pack', dir]);
    expect(code, 0, reason: err);
    for (final rel in [
      'plugin.json',
      'com.casama/pack.json',
      'com.casama/bots/helper.json',
      'com.casama/routines/weekly-check.json',
    ]) {
      expect(exists(dir, rel), isTrue, reason: rel);
    }
    expect(File(p.join(dir, 'AGENTS.md')).readAsStringSync(), contains('casama.pack'));
    // The folder reads back as the files the API takes, without dot folders.
    Directory(p.join(dir, '.git')).createSync();
    File(p.join(dir, '.git', 'HEAD')).writeAsStringSync('x');
    final files = packFolderFiles(dir).map((f) => f.path).toList();
    expect(files, contains('com.casama/pack.json'));
    expect(files.any((f) => f.startsWith('.git/')), isFalse);
    if (!hasNode()) {
      markTestSkipped('node is not on PATH');
      return;
    }
    final check = Process.runSync(
      'node',
      ['packages/plugin-check/src/main.ts', dir, '--strict'],
      workingDirectory: repoRoot,
      environment: {'NO_COLOR': '1'},
    );
    expect(check.exitCode, 0, reason: '${check.stdout}\n${check.stderr}');
    expect(check.stdout, contains('A pack'));
  });
}
