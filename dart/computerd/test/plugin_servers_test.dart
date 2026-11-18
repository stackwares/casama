import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:http/http.dart' as http;
import 'package:casama_computerd/computerd.dart';
import 'package:test/test.dart';

const token = 'test-token-0123456789abcdef';

final fakeServer = Isolate.resolvePackageUriSync(
  Uri.parse('package:casama_computerd/computerd.dart'),
)!.resolve('../test/fixtures/fake_mcp_server.dart').toFilePath();

/// Plugin servers Casama places on a person's own computer (D-344): the package lands in
/// `~/.casama/plugins/<name>`, its variables resolve there, and removing it stops the server.
void main() {
  late Directory home;
  late Directory shared;
  late Computerd server;
  late Uri base;
  final headers = {
    'authorization': 'Bearer $token',
    'content-type': 'application/json',
    'accept': 'application/json, text/event-stream',
  };
  const commit = 'abcdefabcdefabcdefabcdefabcdefabcdefabcd';

  Future<void> start(Set<String> caps) async {
    server = Computerd(
      ComputerdConfig(
        home: home.path,
        token: token,
        port: 0,
        address: '127.0.0.1',
        allowedRoots: [shared.path],
        capabilities: caps,
        mcpServers: {
          'own': LocalMcpServer(
            key: 'own',
            kind: 'stdio',
            command: Platform.resolvedExecutable,
            args: ['run', fakeServer],
          ),
        },
      ),
    );
    await server.start();
    base = Uri.parse('http://127.0.0.1:${server.port}');
  }

  Future<http.Response> putPackage(
    String name,
    List<Map<String, Object>> files,
  ) => http.put(
    base.replace(path: '/plugins/$name'),
    headers: headers,
    body: jsonEncode({'commit': commit, 'files': files}),
  );

  Future<http.Response> putServers(Map<String, Object> servers) => http.put(
    base.replace(path: '/plugin-servers'),
    headers: headers,
    body: jsonEncode({'servers': servers}),
  );

  Future<String> callText(
    String key,
    String tool,
    Map<String, Object> args,
  ) async {
    final res = await http.post(
      base.replace(path: '/mcp/$key'),
      headers: headers,
      body: jsonEncode({
        'jsonrpc': '2.0',
        'id': 1,
        'method': 'tools/call',
        'params': {'name': tool, 'arguments': args},
      }),
    );
    expect(res.statusCode, 200, reason: res.body);
    final msg = const LineSplitter()
        .convert(res.body)
        .where((l) => l.startsWith('data:'))
        .map((l) => jsonDecode(l.substring(5).trim()) as Map)
        .last;
    return '${msg['result']['content'][0]['text']}';
  }

  setUp(() {
    home = Directory.systemTemp.createTempSync('plugin-home');
    shared = Directory('${home.path}/Shared')..createSync();
  });
  tearDown(() async {
    await server.stop();
    home.deleteSync(recursive: true);
  });

  test('a companion takes a plugin package and runs its server in the plugin folder', () async {
    await start({'mcp'});
    final source = File(fakeServer).readAsBytesSync();
    final put = await putPackage('weather', [
      {'path': 'server.dart', 'base64': base64Encode(source)},
      {
        'path': 'bin/start',
        'base64': base64Encode(
          utf8.encode(
            '#!/bin/sh\nexec "\$DART" run "\$PLUGIN_ROOT/server.dart"\n',
          ),
        ),
        'executable': true,
      },
    ]);
    expect(put.statusCode, 200, reason: put.body);
    final root = '${home.path}/.casama/plugins/weather';
    expect(File('$root/.casama-commit').readAsStringSync(), commit);
    final listed = jsonDecode(
      (await http.get(base.replace(path: '/plugins'), headers: headers)).body,
    );
    expect(listed['commits'], {'weather': commit});

    final servers = await putServers({
      'weather_forecast_ab12cd': {
        'plugin': 'weather',
        'command': './bin/start',
        'args': ['--cache', r'${PLUGIN_DATA}/cache'],
        'env': {
          'DART': Platform.resolvedExecutable,
          'API_KEY': 'secret-value',
          'CACHE': r'${PLUGIN_DATA}/cache',
        },
      },
    });
    expect(servers.statusCode, 200, reason: servers.body);
    expect(
      await callText('weather_forecast_ab12cd', 'echo', {'text': 'hi'}),
      'echo: hi',
    );
    expect(
      await callText('weather_forecast_ab12cd', 'env', {'name': 'PLUGIN_ROOT'}),
      root,
    );
    expect(
      await callText('weather_forecast_ab12cd', 'env', {'name': 'CACHE'}),
      '${home.path}/.casama/plugin-data/weather/cache',
    );
    expect(
      await callText('weather_forecast_ab12cd', 'env', {'name': 'API_KEY'}),
      'secret-value',
    );
    expect(
      File(await callText('weather_forecast_ab12cd', 'env', {'name': 'cwd'}))
          .resolveSymbolicLinksSync(),
      Directory(root).resolveSymbolicLinksSync(),
    );
    // The person's own servers stay next to the plugin's.
    expect(await callText('own', 'echo', {'text': 'mine'}), 'echo: mine');

    // Removing the plugin's servers stops them and deletes the package; its data stays.
    expect((await putServers({})).statusCode, 200);
    final gone = await http.post(
      base.replace(path: '/mcp/weather_forecast_ab12cd'),
      headers: headers,
      body: '{"jsonrpc":"2.0","id":1,"method":"tools/list"}',
    );
    expect(gone.statusCode, 404);
    expect(Directory(root).existsSync(), isFalse);
    expect(
      Directory('${home.path}/.casama/plugin-data/weather').existsSync(),
      isTrue,
    );
    expect(await callText('own', 'echo', {'text': 'still'}), 'echo: still');
  });

  test('refuses unsafe names, paths and working folders', () async {
    await start({'mcp'});
    expect((await putPackage('../evil', [])).statusCode, anyOf(400, 404));
    expect(
      (await putPackage('evil', [
        {'path': '../x', 'base64': ''},
      ])).statusCode,
      400,
    );
    expect(
      (await putPackage('evil', [
        {'path': '/etc/x', 'base64': ''},
      ])).statusCode,
      400,
    );
    final cwd = await putServers({
      'x': {'plugin': 'evil', 'command': 'sh', 'cwd': shared.path},
    });
    expect(cwd.statusCode, 400);
    expect(jsonDecode(cwd.body)['code'], 'bad_cwd');
  });

  test(
    'needs the person to allow local tools, and only a companion takes plugins',
    () async {
      await start({'shell'});
      expect((await putServers({})).statusCode, 403);
      await server.stop();
      server = Computerd(
        ComputerdConfig(
          home: home.path,
          token: token,
          port: 0,
          address: '127.0.0.1',
        ),
      );
      await server.start();
      base = Uri.parse('http://127.0.0.1:${server.port}');
      expect((await putServers({})).statusCode, 404);
    },
  );
}
