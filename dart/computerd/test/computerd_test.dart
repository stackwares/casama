import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:kasama_computerd/computerd.dart';
import 'package:test/test.dart';

const token = 'test-token-0123456789abcdef';

void main() {
  late Directory home;
  late Computerd server;
  late Uri base;
  final auth = {'authorization': 'Bearer $token'};

  setUp(() async {
    home = Directory.systemTemp.createTempSync('computerd-home');
    server = Computerd(ComputerdConfig(home: home.path, token: token, port: 0, address: '127.0.0.1'));
    await server.start();
    base = Uri.parse('http://127.0.0.1:${server.port}');
  });
  tearDown(() async {
    await server.stop();
    for (var i = 0; i < 10 && home.existsSync(); i++) {
      try {
        home.deleteSync(recursive: true);
      } on FileSystemException {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
    }
  });

  Future<List<Map<String, dynamic>>> exec(Map<String, Object?> body) async {
    final res = await http.post(base.resolve('/exec'), headers: {...auth, 'content-type': 'application/json'}, body: jsonEncode(body));
    expect(res.statusCode, 200, reason: res.body);
    return const LineSplitter().convert(res.body).map((l) => jsonDecode(l) as Map<String, dynamic>).toList();
  }

  test('health needs no token; everything else does', () async {
    final h = await http.get(base.resolve('/health'));
    expect(jsonDecode(h.body)['ok'], isTrue);
    final denied = await http.get(base.resolve('/files/list'));
    expect(denied.statusCode, 401);
  });

  test('exec streams output and reports the exit code', () async {
    final lines = await exec({'cmd': 'echo hello; echo oops >&2; exit 3'});
    expect(lines.first['type'], 'start');
    expect(lines.where((l) => l['type'] == 'stdout').map((l) => l['data']).join(), 'hello\n');
    expect(lines.where((l) => l['type'] == 'stderr').map((l) => l['data']).join(), 'oops\n');
    expect(lines.last, containsPair('code', 3));
  });

  test('exec runs in the workspace and hides the daemon token', () async {
    final lines = await exec({'cmd': r'pwd; echo "token=${COMPUTERD_TOKEN:-none}"'});
    final out = lines.where((l) => l['type'] == 'stdout').map((l) => l['data']).join();
    expect(out, contains('/workspace'));
    expect(out, contains('token=none'));
  });

  test('exec times out', () async {
    final lines = await exec({'cmd': 'sleep 5', 'timeout_ms': 300});
    expect(lines.last['timed_out'], isTrue);
  });

  test('a running exec can be killed', () async {
    final client = http.Client();
    final req = http.Request('POST', base.resolve('/exec'))
      ..headers.addAll({...auth, 'content-type': 'application/json'})
      ..body = jsonEncode({'cmd': 'echo started; sleep 30'});
    final res = await client.send(req);
    final id = res.headers['x-exec-id']!;
    final lines = res.stream.transform(utf8.decoder).transform(const LineSplitter());
    final collected = <Map<String, dynamic>>[];
    final done = Completer<void>();
    lines.listen((l) {
      collected.add(jsonDecode(l) as Map<String, dynamic>);
      if (collected.last['type'] == 'stdout') {
        http.post(base.resolve('/exec/$id/kill'), headers: auth);
      }
    }, onDone: done.complete);
    await done.future.timeout(const Duration(seconds: 10));
    expect(collected.last, containsPair('killed', true));
    client.close();
  });

  test('files: write, read, list, search, delete', () async {
    final put = await http.put(base.resolve('/files?path=notes/a.txt'), headers: auth, body: 'Line one\nThe Teal line\n');
    expect(put.statusCode, 200, reason: put.body);
    final get = await http.get(base.resolve('/files?path=notes/a.txt'), headers: auth);
    expect(get.body, 'Line one\nThe Teal line\n');
    final list = jsonDecode((await http.get(base.resolve('/files/list?path=notes'), headers: auth)).body);
    expect((list['entries'] as List).single['name'], 'a.txt');
    final search = jsonDecode((await http.post(base.resolve('/files/search'),
            headers: {...auth, 'content-type': 'application/json'}, body: jsonEncode({'query': 'teal'})))
        .body);
    expect((search['matches'] as List).single['line'], 2);
    expect((await http.delete(base.resolve('/files?path=notes'), headers: auth)).statusCode, 200);
    expect((await http.get(base.resolve('/files?path=notes/a.txt'), headers: auth)).statusCode, 404);
    expect((await http.delete(base.resolve('/files?path=~'), headers: auth)).statusCode, 400);
  });

  test('archive and restore round-trip the home directory', () async {
    await http.put(base.resolve('/files?path=keep.txt'), headers: auth, body: 'v1');
    final archive = await http.post(base.resolve('/archive'), headers: {...auth, 'content-type': 'application/json'}, body: '{}');
    expect(archive.statusCode, 200);
    expect(archive.bodyBytes.length, greaterThan(20));

    await http.put(base.resolve('/files?path=keep.txt'), headers: auth, body: 'v2');
    await http.put(base.resolve('/files?path=extra.txt'), headers: auth, body: 'new');
    final restore = await http.post(base.resolve('/restore'), headers: auth, body: archive.bodyBytes);
    expect(restore.statusCode, 200, reason: restore.body);
    expect((await http.get(base.resolve('/files?path=keep.txt'), headers: auth)).body, 'v1');
    expect((await http.get(base.resolve('/files?path=extra.txt'), headers: auth)).statusCode, 404);
  });

  test('terminal runs an interactive shell over WebSocket', () async {
    final ws = await WebSocket.connect('ws://127.0.0.1:${server.port}/terminal', headers: auth);
    final output = StringBuffer();
    final sawMarker = Completer<void>();
    ws.listen((m) {
      output.write(m is List<int> ? utf8.decode(m, allowMalformed: true) : m);
      if (output.toString().contains('MARK-42') && !sawMarker.isCompleted) sawMarker.complete();
    });
    ws.add(utf8.encode('echo MARK-\$((40+2))\n'));
    await sawMarker.future.timeout(const Duration(seconds: 10));
    await ws.close();
  });

  test('desktop endpoints say when there is no display', () async {
    if (Platform.environment['DISPLAY'] != null) return;
    expect((await http.get(base.resolve('/screenshot'), headers: auth)).statusCode, 501);
  });
}
