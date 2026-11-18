import 'dart:convert';
import 'dart:io';

import 'package:casama_cli/casama_cli.dart';
import 'package:casama_cli/src/commands_selfhost.dart' show libraryArchiveArgs;
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// `casama login --magic-code` and `casama org invite` with the default workspace, against a
/// stand-in API and Supabase Auth on one local port.
void main() {
  late Directory dir;
  late HttpServer server;
  late String base;
  late List<String> calls;
  late StringBuffer out, err;

  const org = {
    'id': '11111111-1111-4111-8111-111111111111',
    'name': 'Acme',
    'slug': 'acme',
    'plan': 'free',
    'region': 'local',
    'created_at': '2026-11-15T00:00:00Z',
    'role': 'owner',
  };

  Future<int> cli(List<String> args) {
    out = StringBuffer();
    err = StringBuffer();
    return runCli(
      ['--api', base, '--json', ...args],
      out: out,
      err: err,
      configDir: dir,
    );
  }

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('casama-login');
    calls = [];
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    base = 'http://127.0.0.1:${server.port}';
    server.listen((req) async {
      final body = await utf8.decodeStream(req);
      calls.add('${req.method} ${req.uri.path}');
      Object? reply;
      switch ('${req.method} ${req.uri.path}') {
        case 'GET /v1/config':
          reply = {
            'product_name': 'Casama',
            'api_version': '1',
            'supabase_url': base,
            'supabase_anon_key': 'anon',
            'billing_enabled': false,
            'default_models': <String, String>{},
            'default_reasoning_effort': 'medium',
          };
        case 'POST /auth/v1/verify':
          final b = jsonDecode(body) as Map<String, dynamic>;
          if (b['token'] != '123456' || b['type'] != 'email') {
            req.response.statusCode = 400;
            reply = {'error_description': 'Token has expired or is invalid'};
          } else {
            reply = {
              'access_token': 'at',
              'refresh_token': 'rt',
              'expires_in': 3600,
              'user': {'id': 'u1', 'email': b['email']},
            };
          }
        case 'GET /auth/v1/user':
          reply = {'id': 'u1', 'factors': <Object>[]};
        case 'GET /v1/orgs':
          reply = {
            'items': [org],
          };
        case 'POST /v1/orgs/${'11111111-1111-4111-8111-111111111111'}/invites':
          final b = jsonDecode(body) as Map<String, dynamic>;
          req.response.statusCode = 201;
          reply = {
            'id': '22222222-2222-4222-8222-222222222222',
            'org_id': org['id'],
            'email': b['email'],
            'role': b['role'],
            'expires_at': '2026-11-22T00:00:00Z',
            'email_sent': true,
          };
        default:
          req.response.statusCode = 404;
          reply = {'code': 'not_found'};
      }
      req.response.headers.contentType = ContentType.json;
      req.response.write(jsonEncode(reply));
      await req.response.close();
    });
  });
  tearDown(() async {
    await server.close(force: true);
    dir.deleteSync(recursive: true);
  });

  test('login --magic-code signs in without sending another email', () async {
    expect(
      await cli([
        'login',
        '--email',
        'a@example.com',
        '--magic-code',
        '123456',
      ]),
      0,
      reason: '$err',
    );
    expect(jsonDecode('$out'), {'user_id': 'u1', 'email': 'a@example.com'});
    expect(calls, isNot(contains('POST /auth/v1/otp')));
    expect(calls, contains('POST /auth/v1/verify'));
    expect(File(p.join(dir.path, 'session.json')).existsSync(), isTrue);
  });

  test('login --magic-code with a wrong code fails', () async {
    expect(
      await cli([
        'login',
        '--email',
        'a@example.com',
        '--magic-code',
        '000000',
      ]),
      1,
    );
    expect(File(p.join(dir.path, 'session.json')).existsSync(), isFalse);
  });

  test('org invite uses the default workspace, and says how to set one when there is none', () async {
    expect(
      await cli([
        'login',
        '--email',
        'a@example.com',
        '--magic-code',
        '123456',
      ]),
      0,
      reason: '$err',
    );
    expect(await cli(['org', 'invite', 'b@example.com']), 1);
    expect(jsonDecode('$err')['error'], 'org_required');

    expect(await cli(['org', 'use', 'acme']), 0, reason: '$err');
    expect(
      await cli(['org', 'invite', 'b@example.com', '--role', 'admin']),
      0,
      reason: '$err',
    );
    expect(jsonDecode('$out'), containsPair('email', 'b@example.com'));
    expect(calls.last, 'POST /v1/orgs/${org['id']}/invites');

    // --org still wins over the default.
    expect(await cli(['org', 'invite', 'c@example.com', '--org', 'nope']), 1);
    expect(jsonDecode('$err')['error'], 'org_not_found');
  });

  group('library archive (D-276)', () {
    late Directory checkout;
    setUp(() {
      checkout = Directory(p.join(dir.path, 'checkout'))..createSync();
    });

    test('backup writes library.tar.gz from the library volume, skipping an empty one', () {
      final args = libraryArchiveArgs(checkout, '/backups/x');
      expect(
        args,
        containsAllInOrder([
          'run',
          '--rm',
          '--no-deps',
          '--user',
          'root',
          '-v',
          '/backups/x:/backup',
          '--entrypoint',
          'sh',
          'worker',
          '-c',
        ]),
      );
      expect(
        args.last,
        contains('tar czf /backup/library.tar.gz -C /data/library .'),
      );
      expect(args.last, contains('ls -A /data/library'));
    });

    test('restore unpacks library.tar.gz into the library volume', () {
      final args = libraryArchiveArgs(checkout, '/backups/x', restore: true);
      expect(args, containsAllInOrder(['worker', '-c']));
      expect(args.last, 'tar xzf /backup/library.tar.gz -C /data/library');
    });
  });
}
