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
    server = Computerd(ComputerdConfig(
      home: home.path,
      token: token,
      port: 0,
      address: '127.0.0.1',
      allowedRoots: [shared.path],
      capabilities: caps,
    ));
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
    final ok = await http.put(base.replace(path: '/files', queryParameters: {'path': 'notes.txt'}), headers: auth, body: 'hi');
    expect(ok.statusCode, 200, reason: ok.body);
    expect(File('${shared.path}/notes.txt').readAsStringSync(), 'hi');

    final outside = await http.get(base.replace(path: '/files', queryParameters: {'path': '${secret.path}/passwords.txt'}), headers: auth);
    expect(outside.statusCode, 403);
    expect(jsonDecode(outside.body)['code'], 'outside_allowed_folders');
    final dots = await http.get(base.replace(path: '/files', queryParameters: {'path': '../Private/passwords.txt'}), headers: auth);
    expect(dots.statusCode, 403);
    Link('${shared.path}/sneaky').createSync(secret.path);
    final link = await http.get(base.replace(path: '/files', queryParameters: {'path': 'sneaky/passwords.txt'}), headers: auth);
    expect(link.statusCode, 403);
  });

  test('commands need the matching capability and run in the shared folder', () async {
    await start({'browser'});
    final shell = await http.post(base.resolve('/exec'), headers: auth, body: jsonEncode({'cmd': 'ls ~'}));
    expect(shell.statusCode, 403);
    expect(jsonDecode(shell.body)['code'], 'capability_not_allowed');
    final files = await http.get(base.replace(path: '/files/list', queryParameters: {'path': ''}), headers: auth);
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
}
