import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:casama_cli/src/commands_setup.dart';
import 'package:casama_cli/src/runner.dart';
import 'package:test/test.dart';

/// Offline tests for `skills`, `plugins`, `apps`, `secrets`, `knowledge` and `channels`.
void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('casama-setup-test'));
  tearDown(() => dir.deleteSync(recursive: true));

  Future<(int, String, String)> run(
    List<String> args, {
    bool json = false,
  }) async {
    final out = StringBuffer();
    final err = StringBuffer();
    final ctx = CliContext(out, err, configDirOverride: dir)..json = json;
    final runner = CommandRunner<int>('casama', 'test')
      ..addCommand(SkillsCommand(ctx))
      ..addCommand(PluginsCommand(ctx))
      ..addCommand(AppsCommand(ctx))
      ..addCommand(SecretsCommand(ctx))
      ..addCommand(KnowledgeCommand(ctx))
      ..addCommand(ChannelsCommand(ctx));
    try {
      return (await runner.run(args) ?? 0, out.toString(), err.toString());
    } on UsageException catch (e) {
      return (64, out.toString(), e.toString());
    } on CliError catch (e) {
      return (1, out.toString(), '${e.code}: ${e.message}');
    }
  }

  group('usage errors', () {
    for (final (args, hint) in [
      (['skills', 'install'], 'Which skill'),
      (['skills', 'update'], 'Which skill'),
      (['skills', 'stats'], 'Which skill'),
      (['plugins', 'preview'], 'Which plugin'),
      (['plugins', 'settings', 'p1'], 'key=value'),
      (['plugins', 'settings', 'p1', 'novalue'], 'needs a value'),
      (['plugins', 'remove'], 'Which plugin'),
      (['apps', 'connect'], 'Which app'),
      (['apps', 'edit', 'x'], 'Nothing to change'),
      (['apps', 'edit', 'x', '--risk', 'tool=extreme'], 'low, medium or high'),
      (['secrets', 'add'], 'name'),
      (['secrets', 'fulfill'], 'Which request'),
      (['knowledge', 'add'], 'called'),
      (['knowledge', 'add', 'n'], 'exactly one source'),
      (['channels', 'add', 'telegram'], 'kind and a name'),
      (['channels', 'add', 'nope', 'x'], 'Unknown kind'),
      (['channels', 'add', 'slack', 'x'], 'channels slack'),
      (['channels', 'edit', 'c1'], 'Nothing to change'),
      (['channels', 'list'], 'Which bot'),
    ]) {
      test(args.join(' '), () async {
        final (code, _, err) = await run(args);
        expect(code, 64);
        expect(err, contains(hint));
      });
    }
  });

  group('--yes gating prints the dry run before any login or network', () {
    for (final (args, would) in [
      (['plugins', 'remove', 'p1'], 'remove plugin p1'),
      (['apps', 'remove', 'slack'], 'disconnect slack'),
      (['secrets', 'remove', 'KEY'], 'delete secret KEY'),
      (['knowledge', 'remove', 'k1'], 'delete knowledge source k1'),
      (['channels', 'remove', 'c1'], 'delete channel c1'),
    ]) {
      test(args.join(' '), () async {
        final (code, out, _) = await run(args);
        expect(code, 0);
        expect(out, contains('Would $would'));
        expect(out, contains('--yes'));
        final (_, j, _) = await run(args, json: true);
        expect(jsonDecode(j), {'would': would, 'confirm': '--yes'});
      });
    }
  });

  group('missing login', () {
    for (final args in [
      ['skills', 'catalog'],
      ['skills', 'stats', 's1'],
      ['plugins', 'preview', 'https://github.com/a/b'],
      ['apps', 'list'],
      ['secrets', 'requests'],
      ['secrets', 'decline', 'r1'],
      ['knowledge', 'sync', 'k1'],
      ['channels', 'events', 'c1'],
      ['channels', 'remove', 'c1', '--yes'],
      ['plugins', 'remove', 'p1', '--yes'],
    ]) {
      test(args.join(' '), () async {
        final (code, _, err) = await run(args);
        expect(code, 1);
        expect(err, contains('not_logged_in'));
      });
    }
  });

  group('helpers', () {
    test('parsePairs', () {
      expect(parsePairs(['a=1', 'b=x=y', 'c'], 'u'), {
        'a': '1',
        'b': 'x=y',
        'c': null,
      });
      expect(() => parsePairs(['=1'], 'u'), throwsA(isA<UsageException>()));
    });

    test('textArg reads @file and passes other text through', () {
      final f = File('${dir.path}/t.txt')..writeAsStringSync('hello\n');
      expect(textArg('@${f.path}'), 'hello');
      expect(textArg('plain'), 'plain');
      expect(textArg('@'), '@');
      expect(() => textArg('@${dir.path}/nope'), throwsA(isA<CliError>()));
    });

    test('filterCatalog searches id, name, description and category', () {
      final items = [
        {
          'id': 'inbox-digest',
          'name': 'Inbox digest',
          'description': 'Email summary',
          'category': 'email',
        },
        {
          'id': 'pdf',
          'name': 'PDF maker',
          'description': 'Make files',
          'category': 'docs',
        },
      ];
      expect(filterCatalog(items, null), items);
      expect(filterCatalog(items, 'EMAIL').map((i) => i['id']), [
        'inbox-digest',
      ]);
      expect(filterCatalog(items, 'maker').map((i) => i['id']), ['pdf']);
      expect(filterCatalog(items, 'zzz'), isEmpty);
    });

    test('pickMethod prefers oauth, then managed, api_key, none', () {
      Map<String, dynamic> app(List<String> auth, {bool oauth = true}) => {
        'auth': auth,
        'oauth_available': oauth,
      };
      expect(pickMethod(app(['api_key', 'oauth']), null), 'oauth');
      expect(
        pickMethod(app(['api_key', 'oauth'], oauth: false), null),
        'api_key',
      );
      expect(pickMethod(app(['none', 'managed']), null), 'managed');
      expect(pickMethod(app(['oauth']), 'api_key'), isNull);
      expect(pickMethod(app(['oauth', 'api_key']), 'api_key'), 'api_key');
    });

    test('knowledgeBody picks the kind from the options', () {
      final web = knowledgeBody(
        orgId: 'o',
        name: 'Docs',
        url: 'https://x.dev',
        maxPages: 5,
        usage: 'u',
      );
      expect(web, {
        'org_id': 'o',
        'kind': 'website',
        'name': 'Docs',
        'url': 'https://x.dev',
        'max_pages': 5,
      });
      final gh = knowledgeBody(
        orgId: 'o',
        botId: 'b',
        name: 'Repo',
        repo: 'https://github.com/a/b',
        usage: 'u',
      );
      expect(gh['kind'], 'github');
      expect(gh['bot_id'], 'b');
      final f = File('${dir.path}/a.txt')..writeAsStringSync('hi');
      final up = knowledgeBody(
        orgId: 'o',
        name: 'F',
        files: [f.path],
        usage: 'u',
      );
      expect(up['kind'], 'upload');
      expect((up['files'] as List).single, {
        'name': 'a.txt',
        'content_base64': base64.encode(utf8.encode('hi')),
      });
      expect(
        () => knowledgeBody(
          orgId: 'o',
          name: 'x',
          url: 'u',
          repo: 'r',
          usage: 'u',
        ),
        throwsA(isA<UsageException>()),
      );
      expect(
        () =>
            knowledgeBody(orgId: 'o', name: 'x', integration: 'i', usage: 'u'),
        throwsA(isA<UsageException>()),
      );
    });

    test('pluginPreviewText lists skills, tools, secrets and warnings', () {
      final text = pluginPreviewText({
        'name': 'Notes',
        'version': '1.0.0',
        'description': 'Takes notes.',
        'repo': 'a/b',
        'commit': 'abcdef1234567890',
        'skills': [
          {'name': 'note', 'description': 'x'},
        ],
        'servers': [
          {
            'key': 'srv',
            'type': 'stdio',
            'command': 'node',
            'args': ['x.js'],
            'url': null,
          },
        ],
        'secrets': [
          {'name': 'TOKEN', 'description': '', 'server': 'srv'},
        ],
        'hosts': ['api.x.com'],
        'warnings': ['Runs code'],
      });
      expect(text, contains('Notes 1.0.0'));
      expect(text, contains('abcdef12'));
      expect(text, contains('Skills: note'));
      expect(text, contains('srv (node x.js)'));
      expect(text, contains('Needs secrets: TOKEN'));
      expect(text, contains('Can reach: api.x.com'));
      expect(text, contains('Warning: Runs code'));
    });
  });
}
