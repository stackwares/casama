@TestOn('mac-os || linux')
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kasama_app/features/companion/companion.dart';
import 'package:kasama_app/features/companion/companion_io.dart';

/// The real companion against a stand-in API: tunnel frames in, computerd answers out.
void main() {
  test('answers tunnel requests from its embedded computerd, within its limits', () async {
    final root = Directory.systemTemp.createTempSync('companion-io');
    File('${root.path}/hello.txt').writeAsStringSync('hi there');
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final frames = StreamController<Map<String, dynamic>>.broadcast();
    final connected = Completer<WebSocket>();
    server.listen((req) async {
      expect(req.headers.value('authorization'), 'Device kdev_test');
      final ws = await WebSocketTransformer.upgrade(req);
      ws.listen((m) => frames.add(jsonDecode(m as String) as Map<String, dynamic>));
      connected.complete(ws);
    });
    final c = IoCompanion();
    await c.start(
      apiUrl: 'http://127.0.0.1:${server.port}',
      deviceToken: 'kdev_test',
      settings: CompanionSettings(capabilities: {'shell', 'files'}, roots: [root.path]),
    );
    final ws = await connected.future;

    Future<(int, String)> call(String id, String method, String path, {Object? json}) async {
      final done = Completer<(int, String)>();
      var status = 0;
      final body = StringBuffer();
      late StreamSubscription<Map<String, dynamic>> sub;
      sub = frames.stream.where((f) => f['id'] == id).listen((f) {
        if (f['type'] == 'response') status = f['status'] as int;
        if (f['type'] == 'chunk') body.write(utf8.decode(base64Decode(f['data'] as String)));
        if (f['type'] == 'end' || f['type'] == 'error') {
          sub.cancel();
          done.complete((status, f['type'] == 'error' ? 'ERROR ${f['message']}' : body.toString()));
        }
      });
      ws.add(jsonEncode({
        'type': 'request',
        'id': id,
        'method': method,
        'path': path,
        'headers': {if (json != null) 'content-type': 'application/json'},
        if (json != null) 'body': base64Encode(utf8.encode(jsonEncode(json))),
        'activity': {'run_id': 'r1', 'bot': 'Ada', 'tool': 'shell.exec', 'summary': 'cat hello.txt'},
      }));
      return done.future.timeout(const Duration(seconds: 20));
    }

    final exec = await call('1', 'POST', '/exec', json: {'cmd': 'cat hello.txt'});
    expect(exec.$1, 200);
    expect(exec.$2, contains('hi there'));
    expect(exec.$2, contains('"type":"exit"'));
    expect(c.activity.value?.bot, 'Ada');

    final outside = await call('2', 'GET', '/files?path=%2Fetc%2Fhosts');
    expect(outside.$1, 403);

    await c.stop();
    await server.close(force: true);
    root.deleteSync(recursive: true);
  });
}
