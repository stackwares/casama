import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kasama_app/core/server_address.dart';
import 'package:kasama_app/features/selfhost/local_server.dart';
import 'package:kasama_app/features/selfhost/local_server_sheet.dart';
import 'package:kasama_app/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeProcess implements Process {
  FakeProcess(this.lines, this.code);
  final List<String> lines;
  final int code;
  @override
  Stream<List<int>> get stdout => Stream.fromIterable(lines.map((l) => utf8.encode('$l\n')));
  @override
  Stream<List<int>> get stderr => const Stream.empty();
  @override
  Future<int> get exitCode => Future.value(code);
  @override
  IOSink get stdin => throw UnimplementedError();
  @override
  int get pid => 1;
  @override
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]) => true;
}

class FakeRunner implements ProcessRunner {
  FakeRunner({this.docker = true, this.installCode = 0});
  final bool docker;
  final int installCode;
  final calls = <String>[];
  @override
  Future<ProcessResult> run(String exe, List<String> args, {String? cwd}) async {
    calls.add('$exe ${args.join(' ')}');
    if (exe == 'docker' && !docker) throw const ProcessException('docker', [], 'not found');
    return ProcessResult(1, 0, '', '');
  }

  @override
  Future<Process> start(String exe, List<String> args, {String? cwd}) async {
    calls.add('$exe ${args.join(' ')} @${cwd!.split('/').last}');
    return FakeProcess(['Starting the stack', 'Kasama is running'], installCode);
  }
}

List<int> bundle() {
  final a = Archive()..addFile(ArchiveFile('kasama-main/install.sh', 9, utf8.encode('#!/bin/sh')));
  return GZipEncoder().encode(TarEncoder().encode(a));
}

/// One-click local server (D-147).
void main() {
  late Directory tmp;
  setUp(() => tmp = Directory.systemTemp.createTempSync('kls'));
  tearDown(() => tmp.deleteSync(recursive: true));

  LocalServerManager manager(FakeRunner r, {bool up = false}) {
    var installed = false;
    final client = MockClient((req) async {
      if (req.url.path.endsWith('.tar.gz')) return http.Response.bytes(bundle(), 200);
      if (req.url.path == '/readyz') return http.Response('', (up || installed) ? 200 : 503);
      return http.Response('', 404);
    });
    return LocalServerManager(
      runner: _Hook(r, () => installed = true),
      client: client,
      home: () async => tmp,
      bundleUrl: 'https://example.test/kasama.tar.gz',
      healthTimeout: const Duration(seconds: 5),
    );
  }

  test('checks Docker, unpacks the bundle, runs the installer for this machine and waits for it', () async {
    final r = FakeRunner();
    final steps = await manager(r).start().toList();
    expect(steps.map((s) => s.step).toSet(), containsAll([LocalServerStep.checking, LocalServerStep.downloading, LocalServerStep.installing, LocalServerStep.ready]));
    expect(steps.last.detail, 'http://localhost:8080');
    expect(r.calls, contains('bash install.sh --local --http-port 8080 @kasama-main'));
    expect(steps.where((s) => s.step == LocalServerStep.installing).map((s) => s.detail), contains('Kasama is running'));
    expect(File('${tmp.path}/kasama-main/install.sh').existsSync(), isTrue);
  });

  test('says what to do when Docker is missing, and reconnects when a server already runs', () async {
    final missing = await manager(FakeRunner(docker: false)).start().toList();
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
    expect(find.text('Run Kasama on this computer'), findsWidgets);
    await tester.runAsync(() async {
      await tester.tap(find.byKey(const Key('startLocalServer')));
      for (var i = 0; i < 20 && switched == null; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    });
    await tester.pumpAndSettle();
    expect(switched, 'http://localhost:8080');
    expect((await SharedPreferences.getInstance()).getString('kasama.server_url'), 'http://localhost:8080');
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
