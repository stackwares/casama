import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:kasama_computerd/computerd.dart';
import 'package:test/test.dart';

const token = 'test-token-0123456789abcdef';

/// Companion mode (D-066): computerd on a user's own machine, limited to chosen folders and
/// approved capabilities.
void main() {
  late Directory home;
  late Directory shared;
  late Directory secret;
  late Computerd server;
  late Uri base;
  final auth = {'authorization': 'Bearer $token', 'content-type': 'application/json'};

  Future<void> start(Set<String> caps) async {
    server = Computerd(ComputerdConfig(home: home.path, token: token, port: 0, address: '127.0.0.1', allowedRoots: [shared.path], capabilities: caps));
    await server.start();
    base = Uri.parse('http://127.0.0.1:${server.port}');
  }

  setUp(() {
    home = Directory.systemTemp.createTempSync('companion-home');
    shared = Directory('${home.path}/Shared')..createSync();
    secret = Directory('${home.path}/Private')..createSync();
    File('${secret.path}/passwords.txt').writeAsStringSync('hunter2');
  });
  tearDown(() async {
    await server.stop();
    home.deleteSync(recursive: true);
  });

  test('files stay inside the shared folders, including through symlinks', () async {
    await start({'files'});
    final ok = await http.put(
      base.replace(path: '/files', queryParameters: {'path': 'notes.txt'}),
      headers: auth,
      body: 'hi',
    );
    expect(ok.statusCode, 200, reason: ok.body);
    expect(File('${shared.path}/notes.txt').readAsStringSync(), 'hi');

    final outside = await http.get(
      base.replace(path: '/files', queryParameters: {'path': '${secret.path}/passwords.txt'}),
      headers: auth,
    );
    expect(outside.statusCode, 403);
    expect(jsonDecode(outside.body)['code'], 'outside_allowed_folders');
    final dots = await http.get(
      base.replace(path: '/files', queryParameters: {'path': '../Private/passwords.txt'}),
      headers: auth,
    );
    expect(dots.statusCode, 403);
    Link('${shared.path}/sneaky').createSync(secret.path);
    final link = await http.get(
      base.replace(path: '/files', queryParameters: {'path': 'sneaky/passwords.txt'}),
      headers: auth,
    );
    expect(link.statusCode, 403);
  });

  test('commands need the matching capability and run in the shared folder', () async {
    await start({'browser'});
    final shell = await http.post(base.resolve('/exec'), headers: auth, body: jsonEncode({'cmd': 'ls ~'}));
    expect(shell.statusCode, 403);
    expect(jsonDecode(shell.body)['code'], 'capability_not_allowed');
    final files = await http.get(
      base.replace(path: '/files/list', queryParameters: {'path': ''}),
      headers: auth,
    );
    expect(files.statusCode, 403);
    await server.stop();

    await start({'shell'});
    final pwd = await http.post(base.resolve('/exec'), headers: auth, body: jsonEncode({'cmd': 'pwd'}));
    expect(pwd.statusCode, 200);
    expect(pwd.body, contains(shared.resolveSymbolicLinksSync()));
    final cwd = await http.post(base.resolve('/exec'), headers: auth, body: jsonEncode({'cmd': 'pwd', 'cwd': secret.path}));
    expect(cwd.statusCode, 403);
  });

  test('archives, terminals and the streamer are not available', () async {
    await start({'shell', 'files', 'browser', 'desktop'});
    expect((await http.post(base.resolve('/archive'), headers: auth, body: '{}')).statusCode, 403);
    expect((await http.post(base.resolve('/stream/start'), headers: auth, body: '{}')).statusCode, 403);
  });

  test('iMessage reads new messages and sends replies only with Messages allowed (D-134)', () async {
    final db = '${home.path}/chat.db';
    final mk = await Process.run('sqlite3', [
      db,
      "create table handle (ROWID integer primary key, id text); create table message (ROWID integer primary key, handle_id integer, text text, is_from_me integer);"
          "insert into handle values (1, '+15550001');"
          "insert into message values (1, 1, 'old one', 0), (2, 1, 'mine', 1), (3, 1, 'hello bot', 0);",
    ]);
    expect(mk.exitCode, 0, reason: mk.stderr.toString());
    final log = '${home.path}/sent.txt';
    final script = File('${home.path}/send.sh')..writeAsStringSync('#!/bin/sh\necho "\$1|\$2" >> $log\n');
    await Process.run('chmod', ['+x', script.path]);

    Future<void> startWith(Set<String> caps) async {
      server = Computerd(
        ComputerdConfig(home: home.path, token: token, port: 0, address: '127.0.0.1', allowedRoots: [shared.path], capabilities: caps, imessageDb: db, imessageSendCommand: [script.path]),
      );
      await server.start();
      base = Uri.parse('http://127.0.0.1:${server.port}');
    }

    await startWith({'files'});
    final denied = await http.get(
      base.replace(path: '/imessage/new', queryParameters: {'since': '0'}),
      headers: auth,
    );
    expect(denied.statusCode, 403);
    await server.stop();

    await startWith({'messages'});
    final first = jsonDecode(
      (await http.get(
        base.replace(path: '/imessage/new', queryParameters: {'since': '0'}),
        headers: auth,
      )).body,
    );
    expect(first['latest'], 3);
    expect(first['messages'], isEmpty, reason: 'the first poll is only a baseline');
    final next = jsonDecode(
      (await http.get(
        base.replace(path: '/imessage/new', queryParameters: {'since': '1'}),
        headers: auth,
      )).body,
    );
    expect((next['messages'] as List).map((m) => m['text']), ['hello bot'], reason: 'own messages are skipped');
    expect(next['messages'][0]['handle'], '+15550001');

    final sent = await http.post(
      base.replace(path: '/imessage/send'),
      headers: auth,
      body: jsonEncode({'to': '+15550001', 'text': 'Hi there'}),
    );
    expect(sent.statusCode, 200, reason: sent.body);
    expect(File(log).readAsStringSync().trim(), '+15550001|Hi there');
  });
}
