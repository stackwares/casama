import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:casama_computerd/computerd.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

const token = 'test-token-0123456789abcdef';

/// The fake streamer's absolute path, so the test passes from the package or the workspace root.
final fakeStreamer = Isolate.resolvePackageUriSync(
  Uri.parse('package:casama_computerd/computerd.dart'),
)!.resolve('../test/fixtures/fake_streamer.dart').toFilePath();

/// Live view's streamer reads its relays only when it starts. A viewer away from the server needs
/// a relay outside it (Casama Link, D-296), named by `ice_key`: a running streamer that wasn't
/// given that one starts again; otherwise it is left alone, so nobody watching is dropped.
void main() {
  late Directory home;
  late File log;
  late Computerd server;
  late Uri base;
  final headers = {
    'authorization': 'Bearer $token',
    'content-type': 'application/json',
  };

  setUp(() async {
    home = Directory.systemTemp.createTempSync('computerd-stream');
    log = File('${home.path}/streamer.log');
    // A free port for the fake streamer.
    final probe = await ServerSocket.bind('127.0.0.1', 0);
    final streamPort = probe.port;
    await probe.close();
    server = Computerd(
      ComputerdConfig(
        home: home.path,
        token: token,
        port: 0,
        address: '127.0.0.1',
        streamerCommand: [Platform.resolvedExecutable, fakeStreamer, log.path],
        streamPort: streamPort,
      ),
    );
    await server.start();
    base = Uri.parse('http://127.0.0.1:${server.port}');
  });
  tearDown(() async {
    await http.post(base.resolve('/stream/stop'), headers: headers);
    await server.stop();
    home.deleteSync(recursive: true);
  });

  Future<Map<String, dynamic>> start(Map<String, Object?> body) async {
    final res = await http.post(
      base.resolve('/stream/start'),
      headers: headers,
      body: jsonEncode(body),
    );
    expect(res.statusCode, 200, reason: res.body);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /// One entry per time the streamer started: its process and the relays it was given.
  List<Map<String, dynamic>> starts() => const LineSplitter()
      .convert(log.readAsStringSync())
      .map((l) => jsonDecode(l) as Map<String, dynamic>)
      .toList();

  const home_ = {
    'urls': ['turn:turn:3478?transport=udp'],
    'username': 'home',
    'credential': 'h',
  };
  Map<String, Object?> outside(String user) => {
    'urls': ['turn:turn:3479?transport=udp'],
    'username': user,
    'credential': 'o',
  };

  test('a viewer away from the server starts the streamer again with the relay outside, once', () async {
    // Someone at home is watching: the streamer has the server's own relay only.
    final first = await start({
      'ice_servers': [home_],
    });
    expect(starts(), hasLength(1));
    expect(starts().single['ice'], [home_]);

    // Another viewer at home: the same streamer, the same logins.
    final again = await start({
      'ice_servers': [home_],
    });
    expect(starts(), hasLength(1));
    expect(again['users'], first['users']);

    // A viewer away: the streamer wasn't given that relay, so it starts again with both.
    final away = await start({
      'ice_servers': [home_, outside('a')],
      'ice_key': 'key-a',
    });
    expect(starts(), hasLength(2));
    expect(starts().last['ice'], [home_, outside('a')]);
    expect(starts().last['pid'], isNot(starts().first['pid']));
    expect(away['users'], isNot(first['users']));

    // More viewers, away with the same relay or at home with none named: nobody is dropped.
    await start({
      'ice_servers': [home_, outside('a')],
      'ice_key': 'key-a',
    });
    final homeAgain = await start({
      'ice_servers': [home_],
    });
    expect(starts(), hasLength(2));
    expect(homeAgain['users'], away['users']);

    // The relay's credentials were replaced: the next viewer away brings the new ones.
    await start({
      'ice_servers': [home_, outside('b')],
      'ice_key': 'key-b',
    });
    expect(starts(), hasLength(3));
    expect(starts().last['ice'], [home_, outside('b')]);
  });

  test('a streamer that was stopped starts fresh, with whatever the next viewer brings', () async {
    await start({
      'ice_servers': [home_, outside('a')],
      'ice_key': 'key-a',
    });
    await http.post(base.resolve('/stream/stop'), headers: headers);
    await start({
      'ice_servers': [home_],
    });
    expect(starts(), hasLength(2));
    expect(starts().last['ice'], [home_]);
    // It has no relay outside now, so a viewer away starts it again.
    await start({
      'ice_servers': [home_, outside('a')],
      'ice_key': 'key-a',
    });
    expect(starts(), hasLength(3));
  });
}
