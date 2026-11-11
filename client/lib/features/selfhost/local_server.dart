import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../../core/distribution.dart';

/// One-click local server (SPEC: Ops extras; D-147): on a desktop, the app checks for Docker,
/// downloads the self-host bundle, runs its installer for this machine only (`install.sh --local`),
/// waits until the API answers, and connects to it.
bool get localServerSupported => !kIsWeb && !isMacAppStoreBuild && (defaultTargetPlatform == TargetPlatform.macOS || defaultTargetPlatform == TargetPlatform.linux || defaultTargetPlatform == TargetPlatform.windows);

/// The self-host bundle (the repository archive with install.sh and infra/).
const selfhostBundleUrl = String.fromEnvironment('CASAMA_SELFHOST_BUNDLE', defaultValue: 'https://github.com/casama-dev/casama/archive/refs/heads/main.tar.gz');

enum LocalServerStep { checking, downloading, installing, starting, ready, failed }

class LocalServerProgress {
  const LocalServerProgress(this.step, {this.detail, this.fraction});
  final LocalServerStep step;
  final String? detail;
  final double? fraction;
}

/// Runs processes (a seam for tests).
abstract class ProcessRunner {
  Future<ProcessResult> run(String exe, List<String> args, {String? cwd});
  Future<Process> start(String exe, List<String> args, {String? cwd});
}

class SystemProcessRunner implements ProcessRunner {
  @override
  Future<ProcessResult> run(String exe, List<String> args, {String? cwd}) => Process.run(exe, args, workingDirectory: cwd);
  @override
  Future<Process> start(String exe, List<String> args, {String? cwd}) => Process.start(exe, args, workingDirectory: cwd);
}

class LocalServerManager {
  LocalServerManager({
    ProcessRunner? runner,
    http.Client? client,
    Future<Directory> Function()? home,
    this.bundleUrl = selfhostBundleUrl,
    this.port = 8080,
    this.healthTimeout = const Duration(minutes: 15),
  }) : runner = runner ?? SystemProcessRunner(),
       client = client ?? http.Client(),
       home = home ?? (() async => Directory('${(await getApplicationSupportDirectory()).path}/local-server'));

  final ProcessRunner runner;
  final http.Client client;
  final Future<Directory> Function() home;
  final String bundleUrl;
  final int port;
  final Duration healthTimeout;

  String get url => 'http://localhost:$port';

  /// Why Docker can't be used, or null when it's ready.
  Future<String?> dockerProblem() async {
    try {
      final info = await runner.run('docker', ['info', '--format', '{{.ServerVersion}}']);
      if (info.exitCode != 0) return 'Docker is installed but not running. Start Docker Desktop and try again.';
      final compose = await runner.run('docker', ['compose', 'version']);
      if (compose.exitCode != 0) return 'Docker Compose v2 is needed (it comes with Docker Desktop).';
      return null;
    } on ProcessException {
      return 'Docker isn\'t installed. Install Docker Desktop, start it, then try again.';
    }
  }

  /// Downloads and unpacks the bundle once; returns the folder holding install.sh.
  Future<Directory> ensureBundle({void Function(double)? onProgress}) async {
    final root = await home();
    final existing = _findInstaller(root);
    if (existing != null) return existing;
    final res = await client.send(http.Request('GET', Uri.parse(bundleUrl)));
    if (res.statusCode != 200) throw StateError('The server bundle could not be downloaded (${res.statusCode})');
    final total = res.contentLength ?? 0;
    final bytes = BytesBuilder(copy: false);
    await for (final c in res.stream) {
      bytes.add(c);
      if (total > 0) onProgress?.call(bytes.length / total);
    }
    final tar = TarDecoder().decodeBytes(GZipDecoder().decodeBytes(bytes.takeBytes()));
    for (final f in tar.files) {
      final path = '${root.path}/${f.name}';
      if (f.name.contains('..')) continue;
      if (f.isFile) {
        final out = File(path);
        await out.parent.create(recursive: true);
        await out.writeAsBytes(f.content as List<int>);
        if (f.name.endsWith('.sh')) await runner.run('chmod', ['+x', path]);
      }
    }
    final dir = _findInstaller(root);
    if (dir == null) throw StateError('The bundle has no install.sh');
    return dir;
  }

  /// Whether a server already answers on [url] (a second start just reconnects).
  Future<bool> _ready() async {
    try {
      final r = await client.get(Uri.parse('$url/readyz')).timeout(const Duration(seconds: 5));
      return r.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Directory? _findInstaller(Directory root) {
    if (!root.existsSync()) return null;
    if (File('${root.path}/install.sh').existsSync()) return root;
    for (final d in root.listSync().whereType<Directory>()) {
      if (File('${d.path}/install.sh').existsSync()) return d;
    }
    return null;
  }

  /// Runs the whole thing, reporting progress; returns the server's address when it's ready.
  Stream<LocalServerProgress> start() async* {
    yield const LocalServerProgress(LocalServerStep.checking);
    if (await _ready()) {
      yield LocalServerProgress(LocalServerStep.ready, detail: url);
      return;
    }
    final problem = await dockerProblem();
    if (problem != null) {
      yield LocalServerProgress(LocalServerStep.failed, detail: problem);
      return;
    }
    yield const LocalServerProgress(LocalServerStep.downloading, fraction: 0);
    final Directory dir;
    try {
      final progress = StreamController<double>();
      final future = ensureBundle(onProgress: progress.add).whenComplete(progress.close);
      await for (final f in progress.stream) {
        yield LocalServerProgress(LocalServerStep.downloading, fraction: f);
      }
      dir = await future;
    } catch (e) {
      yield LocalServerProgress(LocalServerStep.failed, detail: '$e');
      return;
    }
    yield const LocalServerProgress(LocalServerStep.installing);
    final proc = await runner.start('bash', ['install.sh', '--local', '--http-port', '$port'], cwd: dir.path);
    final lines = StreamController<String>();
    for (final s in [proc.stdout, proc.stderr]) {
      s.transform(utf8.decoder).transform(const LineSplitter()).listen(lines.add, onError: (_) {});
    }
    final exit = proc.exitCode.whenComplete(() => Future<void>.delayed(const Duration(milliseconds: 50), lines.close));
    await for (final l in lines.stream) {
      if (l.trim().isNotEmpty) yield LocalServerProgress(LocalServerStep.installing, detail: l.trim());
    }
    final code = await exit;
    if (code != 0) {
      yield LocalServerProgress(LocalServerStep.failed, detail: 'The installer stopped (exit $code). See its last lines above.');
      return;
    }
    yield const LocalServerProgress(LocalServerStep.starting);
    final until = DateTime.now().add(healthTimeout);
    while (DateTime.now().isBefore(until)) {
      if (await _ready()) {
        yield LocalServerProgress(LocalServerStep.ready, detail: url);
        return;
      }
      await Future<void>.delayed(const Duration(seconds: 2));
    }
    yield const LocalServerProgress(LocalServerStep.failed, detail: 'The server didn\'t answer in time. Run `docker compose ps` in the bundle folder to see why.');
  }
}
