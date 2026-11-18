import 'dart:convert';
import 'dart:io';

import 'package:casama_cli/casama_cli.dart';
import 'package:test/test.dart';

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('casama-cli-test'));
  tearDown(() => dir.deleteSync(recursive: true));

  Future<(int, String, String)> run(List<String> args) async {
    final out = StringBuffer();
    final err = StringBuffer();
    final code = await runCli(args, out: out, err: err, configDir: dir);
    return (code, out.toString(), err.toString());
  }

  test('config saves the API URL', () async {
    final (code, out, _) = await run(['--json', 'config', '--api-url', 'https://api.example.com']);
    expect(code, 0);
    expect(jsonDecode(out)['api_url'], 'https://api.example.com');
    final (_, again, _) = await run(['--json', 'config']);
    expect(jsonDecode(again)['api_url'], 'https://api.example.com');
  });

  test('usage errors exit with 64', () async {
    final (code, _, err) = await run(['org', 'create']);
    expect(code, 64);
    expect(err, contains('Organization name is required'));
  });

  test('network errors are reported as JSON with --json', () async {
    final (code, _, err) = await run(['--api', 'http://127.0.0.1:9', '--json', 'whoami']);
    expect(code, 1);
    expect(jsonDecode(err)['error'], 'network_error');
  });

  test('an error without a problem body names the status', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((r) => r
      ..response.statusCode = 404
      ..response.write('not here')
      ..response.close());
    try {
      final (code, _, err) = await run(['--api', 'http://127.0.0.1:${server.port}', '--json', 'whoami']);
      expect(code, 1);
      expect(jsonDecode(err)['error'], 'http_404');
    } finally {
      await server.close(force: true);
    }
  });

  test('logout without a session succeeds', () async {
    final (code, out, _) = await run(['logout']);
    expect(code, 0);
    expect(out, contains('Logged out'));
  });

  test('sites and domains need a target', () async {
    final (code, _, err) = await run(['domains', 'connect']);
    expect(code, 64);
    expect(err, contains('Which domain?'));
    final (code2, _, err2) = await run(['sites', 'publish']);
    expect(code2, 64);
    expect(err2, contains('Which page?'));
  });

  test('domains list needs a login', () async {
    final (code, _, err) = await run(['--json', 'domains', 'list', '--org', 'crumb']);
    expect(code, 1);
    expect(jsonDecode(err)['error'], 'not_logged_in');
  });
}
