import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:casama_app/core/server_address.dart';
import 'package:casama_app/features/selfhost/local_server.dart';
import 'package:casama_app/features/selfhost/local_server_sheet.dart';
import 'package:casama_app/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeProcess implements Process {
  FakeProcess(this.lines, this.code, {this.hang = false});
  final List<String> lines;
  final int code;
  final bool hang;
  final _exit = Completer<int>();
  final _out = StreamController<List<int>>();
  var killed = false;
  @override
  Stream<List<int>> get stdout {
    for (final l in lines) {
      _out.add(utf8.encode('$l\n'));
    }
    if (!hang) unawaited(_out.close());
    return _out.stream;
  }

  @override
  Stream<List<int>> get stderr => const Stream.empty();
  @override
  Future<int> get exitCode => hang ? _exit.future : Future.value(code);
  @override
  IOSink get stdin => throw UnimplementedError();
  @override
  int get pid => 1;
  @override
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]) {
    killed = true;
    if (!_exit.isCompleted) _exit.complete(-15);
    unawaited(_out.close());
    return true;
  }
}

class FakeRunner implements ProcessRunner {
  FakeRunner({this.docker = true, this.installCode = 0, this.hang = false});
  final bool docker;
  final int installCode;
  final bool hang;
  final calls = <String>[];
  FakeProcess? last;
  @override
  Future<ProcessResult> run(String exe, List<String> args, {String? cwd}) async {
    calls.add('$exe ${args.join(' ')}');
    if (exe == 'docker' && !docker) throw const ProcessException('docker', [], 'not found');
    return ProcessResult(1, 0, '', '');
  }

  @override
  Future<Process> start(String exe, List<String> args, {String? cwd}) async {
    calls.add('$exe ${args.join(' ')} @${cwd!.split('/').last}'.replaceAll(RegExp(r'/\S*/local-settings.env'), 'SETTINGS'));
    return last = FakeProcess(['\x1B[1m==> Starting the stack\x1B[0m', 'Casama is running'], installCode, hang: hang);
  }
}

List<int> bundle() {
  final a = Archive()..addFile(ArchiveFile('casama-main/install.sh', 9, utf8.encode('#!/bin/sh')));
  return GZipEncoder().encode(TarEncoder().encode(a));
}

/// One-click local server (D-147).
void main() {
  late Directory tmp;
  setUp(() => tmp = Directory.systemTemp.createTempSync('kls'));
  tearDown(() => tmp.deleteSync(recursive: true));

  final requests = <Uri>[];
  setUp(requests.clear);

  LocalServerManager manager(FakeRunner r, {bool up = false, Set<int> busy = const {}, String bundleUrl = 'https://example.test/casama.tar.gz', String? sha}) {
    var installed = false;
    final client = MockClient((req) async {
      requests.add(req.url);
      if (req.url.host == 'api.github.com') return sha == null ? http.Response('rate limited', 403) : http.Response(sha, 200);
      if (req.url.path.endsWith('.tar.gz')) return http.Response.bytes(bundle(), 200);
      if (req.url.path == '/readyz') return http.Response('', (up || installed) ? 200 : 503);
      return http.Response('', 404);
    });
    return LocalServerManager(
      runner: _Hook(r, () => installed = true),
      client: client,
      home: () async => tmp,
      portFree: (p) async => !busy.contains(p),
      bundleUrl: bundleUrl,
      healthTimeout: const Duration(seconds: 5),
    );
  }

  test('checks Docker, unpacks the bundle, runs the installer for this machine and waits for it', () async {
    final r = FakeRunner();
    final steps = await manager(r).start().toList();
    expect(steps.map((s) => s.step).toSet(), containsAll([LocalServerStep.checking, LocalServerStep.downloading, LocalServerStep.installing, LocalServerStep.ready]));
    expect(steps.last.detail, 'http://localhost:8080');
    expect(r.calls, contains('bash install.sh --local --http-port 8080 --pull latest --settings SETTINGS @casama-main'));
    final lines = steps.where((s) => s.step == LocalServerStep.installing).map((s) => s.detail);
    expect(lines, containsAll(['==> Starting the stack', 'Casama is running']));
    expect(File('${tmp.path}/casama-main/install.sh').existsSync(), isTrue);
    expect(File('${tmp.path}/local-settings.env').readAsStringSync(), 'HTTPS_PORT=8443\nPAGES_PORT=8790\nCASAMA_PAGES_URL=http://localhost:8790\nTURN_HOST_PORT=3478\n');
  });

  test('downloads the commit the published images were built from, and pulls those images', () async {
    final sha = 'a' * 12 + 'b' * 28;
    final r = FakeRunner();
    final steps = await manager(r, bundleUrl: '', sha: sha).start().toList();
    expect(steps.last.step, LocalServerStep.ready);
    expect(requests.map((u) => '$u'), contains('https://github.com/stackwares/casama/archive/$sha.tar.gz'));
    expect(r.calls, contains('bash install.sh --local --http-port 8080 --pull aaaaaaaaaaaa --settings SETTINGS @casama-main'));
    expect(jsonDecode(File('${tmp.path}/local-server.json').readAsStringSync())['images'], 'aaaaaaaaaaaa');
  });

  test('without the GitHub API it falls back to the tag\'s archive and the latest images', () async {
    final r = FakeRunner();
    await manager(r, bundleUrl: '').start().toList();
    expect(requests.map((u) => '$u'), contains('https://github.com/stackwares/casama/archive/refs/tags/selfhost.tar.gz'));
    expect(r.calls, contains('bash install.sh --local --http-port 8080 --pull latest --settings SETTINGS @casama-main'));
  });

  test('moves off ports that are taken, and keeps the same ports and bundle on later starts', () async {
    final steps = await manager(FakeRunner(), busy: {8080, 8081, 443, 8443, 3478}).start().toList();
    expect(steps.last.detail, 'http://localhost:8082');
    expect(File('${tmp.path}/local-settings.env').readAsStringSync(), contains('HTTPS_PORT=8444\n'));
    expect(File('${tmp.path}/local-settings.env').readAsStringSync(), contains('TURN_HOST_PORT=3479\n'));
    // Later the stack itself holds those ports; the saved ones are reused and nothing is downloaded.
    requests.clear();
    final r = FakeRunner();
    final again = await manager(r, busy: {8082, 8444, 8790, 3479}).start().toList();
    expect(again.last.detail, 'http://localhost:8082');
    expect(r.calls, contains('bash install.sh --local --http-port 8082 --pull latest --settings SETTINGS @casama-main'));
    expect(requests.where((u) => u.path.endsWith('.tar.gz')), isEmpty);
  });

  test('cancelling stops the installer', () async {
    final r = FakeRunner(hang: true);
    final seen = Completer<void>();
    final sub = manager(r).start().listen((p) {
      if (p.detail == 'Casama is running' && !seen.isCompleted) seen.complete();
    });
    await seen.future;
    await sub.cancel();
    expect(r.last!.killed, isTrue);
    expect(r.calls, contains('pkill -TERM -P 1'));
  });

  test('says what to do when Docker is missing, and reconnects when a server already runs', () async {
    final missing = await manager(FakeRunner(docker: false)).start().toList();
    expect(missing.first.step, LocalServerStep.checking);
    expect(missing.last.step, LocalServerStep.failed);
    expect(missing.last.detail, contains('Install Docker Desktop'));
    final r = FakeRunner();
    final again = await manager(r, up: true).start().toList();
    expect(again.last.step, LocalServerStep.ready);
    expect(r.calls, isEmpty);
  });

  test('a failed installer is reported', () async {
    final steps = await manager(FakeRunner(installCode: 3)).start().toList();
    expect(steps.last.step, LocalServerStep.failed);
    expect(steps.last.detail, contains('exit 3'));
  });

  testWidgets('the sheet starts the server, saves its address and reconnects', (tester) async {
    SharedPreferences.setMockInitialValues({});
    String? switched;
    onChangeServer = (u) async => switched = u;
    addTearDown(() => onChangeServer = null);
    final m = await tester.runAsync(() async => manager(FakeRunner(), up: true));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [localServerManagerProvider.overrideWithValue(m!)],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Builder(
            builder: (c) => Scaffold(
              body: TextButton(
                onPressed: () => showModalBottomSheet<void>(context: c, builder: (_) => const LocalServerSheet()),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Run Casama on This Computer'), findsWidgets);
    await tester.runAsync(() async {
      await tester.tap(find.byKey(const Key('startLocalServer')));
      for (var i = 0; i < 20 && switched == null; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    });
    await tester.pumpAndSettle();
    expect(switched, 'http://localhost:8080');
    expect((await SharedPreferences.getInstance()).getString('casama.server_url'), 'http://localhost:8080');
    expect(find.byType(LocalServerSheet), findsNothing);
  });
}

class _Hook implements ProcessRunner {
  _Hook(this.inner, this.onInstall);
  final FakeRunner inner;
  final void Function() onInstall;
  @override
  Future<ProcessResult> run(String exe, List<String> args, {String? cwd}) => inner.run(exe, args, cwd: cwd);
  @override
  Future<Process> start(String exe, List<String> args, {String? cwd}) async {
    final p = await inner.start(exe, args, cwd: cwd);
    if (p is FakeProcess && p.code == 0) onInstall();
    return p;
  }
}
