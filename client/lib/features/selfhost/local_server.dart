import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../../core/distribution.dart';

/// One-click local server (SPEC: Ops extras; D-147, D-216): on a Mac or Linux desktop, the app
/// checks for Docker, downloads the self-host bundle pinned to the published images, runs its
/// installer for this machine only (`install.sh --local --pull <images>`), waits until the API
/// answers, and connects to it. Windows has no bash or OpenSSL out of the box, so it isn't offered
/// there yet.
bool get localServerSupported => !kIsWeb && !isMacAppStoreBuild && (defaultTargetPlatform == TargetPlatform.macOS || defaultTargetPlatform == TargetPlatform.linux);

/// The repository the bundle and images come from, and the tag that marks the commit whose images
/// are published (moved by scripts/publish-images.sh).
const selfhostRepo = 'stackwares/casama';
const selfhostTag = 'selfhost';

/// A build-time override for the bundle (a tar.gz holding install.sh); its images are `latest`.
const selfhostBundleOverride = String.fromEnvironment('CASAMA_SELFHOST_BUNDLE');

enum LocalServerStep { checking, downloading, installing, starting, ready, failed }

class LocalServerProgress {
  const LocalServerProgress(this.step, {this.detail, this.fraction});
  final LocalServerStep step;
  final String? detail;
  final double? fraction;
}

/// Which source to download and which image tag goes with it.
class SelfhostRelease {
  const SelfhostRelease(this.bundleUrl, this.images);
  final String bundleUrl;
  final String images;
}

/// The host ports the stack publishes (all on loopback).
class LocalServerPorts {
  const LocalServerPorts({this.http = 8080, this.https = 8443, this.pages = 8790, this.turn = 3478});
  final int http;
  final int https;
  final int pages;
  final int turn;

  Map<String, Object> toJson() => {'http': http, 'https': https, 'pages': pages, 'turn': turn};
  static LocalServerPorts fromJson(Map<String, dynamic> j) =>
      LocalServerPorts(http: j['http'] as int, https: j['https'] as int, pages: j['pages'] as int, turn: j['turn'] as int);
}

/// Runs processes (a seam for tests).
abstract class ProcessRunner {
  Future<ProcessResult> run(String exe, List<String> args, {String? cwd});
  Future<Process> start(String exe, List<String> args, {String? cwd});
}

class SystemProcessRunner implements ProcessRunner {
  /// Apps opened from Finder or a desktop launcher get a bare PATH (/usr/bin:/bin:…), which misses
  /// `docker` and Docker Desktop's credential helper, so add the places they're installed.
  static Map<String, String> get environment {
    final env = Map<String, String>.of(Platform.environment);
    final home = env['HOME'] ?? '';
    final extra = [
      '/usr/local/bin',
      '/opt/homebrew/bin',
      if (home.isNotEmpty) '$home/.docker/bin',
      '/Applications/Docker.app/Contents/Resources/bin',
      if (home.isNotEmpty) '$home/Applications/Docker.app/Contents/Resources/bin',
      '/snap/bin',
    ];
    final path = (env['PATH'] ?? '/usr/bin:/bin:/usr/sbin:/sbin').split(':');
    env['PATH'] = [...path, ...extra.where((p) => !path.contains(p))].join(':');
    return env;
  }

  @override
  Future<ProcessResult> run(String exe, List<String> args, {String? cwd}) => Process.run(exe, args, workingDirectory: cwd, environment: environment);
  @override
  Future<Process> start(String exe, List<String> args, {String? cwd}) => Process.start(exe, args, workingDirectory: cwd, environment: environment);
}

/// Whether nothing listens on [port] (TCP and UDP, on loopback and on every interface).
Future<bool> systemPortFree(int port) async {
  for (final a in [InternetAddress.loopbackIPv4, InternetAddress.anyIPv4]) {
    try {
      await (await ServerSocket.bind(a, port)).close();
      (await RawDatagramSocket.bind(a, port)).close();
    } on SocketException {
      return false;
    }
  }
  return true;
}

class LocalServerManager {
  LocalServerManager({
    ProcessRunner? runner,
    http.Client? client,
    Future<Directory> Function()? home,
    Future<bool> Function(int port)? portFree,
    this.bundleUrl = selfhostBundleOverride,
    this.healthTimeout = const Duration(minutes: 15),
  }) : runner = runner ?? SystemProcessRunner(),
       client = client ?? http.Client(),
       portFree = portFree ?? systemPortFree,
       home = home ?? (() async => Directory('${(await getApplicationSupportDirectory()).path}/local-server'));

  final ProcessRunner runner;
  final http.Client client;
  final Future<Directory> Function() home;
  final Future<bool> Function(int port) portFree;

  /// A fixed bundle (tests, CASAMA_SELFHOST_BUNDLE); empty means the published release.
  final String bundleUrl;
  final Duration healthTimeout;

  LocalServerPorts _ports = const LocalServerPorts();
  String get url => 'http://localhost:${_ports.http}';

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

  /// The commit whose images are published, so the bundle's compose file matches them exactly.
  Future<SelfhostRelease> release() async {
    if (bundleUrl.isNotEmpty) return SelfhostRelease(bundleUrl, 'latest');
    try {
      final r = await client
          .get(Uri.parse('https://api.github.com/repos/$selfhostRepo/commits/$selfhostTag'), headers: {'Accept': 'application/vnd.github.sha'})
          .timeout(const Duration(seconds: 15));
      final sha = r.body.trim();
      if (r.statusCode == 200 && RegExp(r'^[0-9a-f]{40}$').hasMatch(sha)) {
        return SelfhostRelease('https://github.com/$selfhostRepo/archive/$sha.tar.gz', sha.substring(0, 12));
      }
    } catch (_) {}
    // GitHub's API limits anonymous calls per address; the tag's archive pairs with `latest`.
    return const SelfhostRelease('https://github.com/$selfhostRepo/archive/refs/tags/$selfhostTag.tar.gz', 'latest');
  }

  /// Downloads and unpacks [url] into [root]; returns the folder holding install.sh.
  Future<Directory> download(Directory root, String url, {void Function(double)? onProgress}) async {
    final res = await client.send(http.Request('GET', Uri.parse(url)));
    if (res.statusCode != 200) throw StateError('The server bundle could not be downloaded (${res.statusCode})');
    final total = res.contentLength ?? 0;
    final bytes = BytesBuilder(copy: false);
    await for (final c in res.stream) {
      bytes.add(c);
      if (total > 0) onProgress?.call(bytes.length / total);
    }
    final tar = TarDecoder().decodeBytes(GZipDecoder().decodeBytes(bytes.takeBytes()));
    for (final f in tar.files) {
      if (f.name.contains('..') || f.name.startsWith('/')) continue;
      final path = '${root.path}/${f.name}';
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

  /// The first free port from [from], skipping [taken].
  Future<int> _free(int from, Set<int> taken) async {
    for (var p = from; p < from + 100; p++) {
      if (!taken.contains(p) && await portFree(p)) return p;
    }
    throw StateError('No free port near $from');
  }

  Future<LocalServerPorts> _pickPorts() async {
    final taken = <int>{};
    Future<int> pick(int from) async {
      final p = await _free(from, taken);
      taken.add(p);
      return p;
    }

    return LocalServerPorts(http: await pick(8080), https: await pick(8443), pages: await pick(8790), turn: await pick(3478));
  }

  File _state(Directory root) => File('${root.path}/local-server.json');

  /// What the first install chose (ports and image tag), so later starts keep the same server.
  Future<({LocalServerPorts ports, String images})?> _saved(Directory root) async {
    try {
      final j = jsonDecode(await _state(root).readAsString()) as Map<String, dynamic>;
      return (ports: LocalServerPorts.fromJson(j['ports'] as Map<String, dynamic>), images: j['images'] as String);
    } catch (_) {
      return null;
    }
  }

  /// Stops the installer and the docker commands it started.
  Future<void> _stop(Process proc) async {
    try {
      await runner.run('pkill', ['-TERM', '-P', '${proc.pid}']);
    } catch (_) {}
    proc.kill();
  }

  /// The installer while it runs.
  Process? _proc;

  /// Runs the whole thing, reporting progress; ends with [LocalServerStep.ready] and the server's
  /// address. Cancelling the subscription stops the installer straight away (a generator would
  /// only stop at its next line of output, and an image pull can be quiet for minutes).
  Stream<LocalServerProgress> start() {
    StreamSubscription<LocalServerProgress>? sub;
    late final StreamController<LocalServerProgress> out;
    out = StreamController<LocalServerProgress>(
      onListen: () => sub = _run().listen(out.add, onError: out.addError, onDone: out.close),
      onCancel: () async {
        final p = _proc;
        _proc = null;
        if (p != null) await _stop(p);
        unawaited(sub?.cancel());
      },
    );
    return out.stream;
  }

  Stream<LocalServerProgress> _run() async* {
    yield const LocalServerProgress(LocalServerStep.checking);
    final root = await home();
    final saved = await _saved(root);
    if (saved != null) _ports = saved.ports;
    if (await _ready()) {
      yield LocalServerProgress(LocalServerStep.ready, detail: url);
      return;
    }
    final problem = await dockerProblem();
    if (problem != null) {
      yield LocalServerProgress(LocalServerStep.failed, detail: problem);
      return;
    }

    // The bundle holds the .env with every key and the data's passwords, so once it's there it's
    // reused as it is, with the images it was installed with.
    var dir = _findInstaller(root);
    var images = saved?.images ?? 'latest';
    if (dir == null) {
      yield const LocalServerProgress(LocalServerStep.downloading, fraction: 0);
      try {
        final rel = await release();
        images = rel.images;
        await root.create(recursive: true);
        final progress = StreamController<double>();
        final future = download(root, rel.bundleUrl, onProgress: progress.add).whenComplete(progress.close);
        await for (final f in progress.stream) {
          yield LocalServerProgress(LocalServerStep.downloading, fraction: f);
        }
        dir = await future;
      } catch (e) {
        yield LocalServerProgress(LocalServerStep.failed, detail: '$e');
        return;
      }
    }
    if (saved == null) {
      try {
        _ports = await _pickPorts();
      } catch (e) {
        yield LocalServerProgress(LocalServerStep.failed, detail: '$e');
        return;
      }
    }
    await _state(root).writeAsString(jsonEncode({'ports': _ports.toJson(), 'images': images}));
    final settings = File('${root.path}/local-settings.env');
    await settings.writeAsString(
      [
        'HTTPS_PORT=${_ports.https}',
        'PAGES_PORT=${_ports.pages}',
        'CASAMA_PAGES_URL=http://localhost:${_ports.pages}',
        'TURN_HOST_PORT=${_ports.turn}',
        '',
      ].join('\n'),
    );

    yield const LocalServerProgress(LocalServerStep.installing);
    final proc = await runner.start('bash', [
      'install.sh',
      '--local',
      '--http-port',
      '${_ports.http}',
      '--pull',
      images,
      '--settings',
      settings.path,
    ], cwd: dir.path);
    _proc = proc;
    final lines = StreamController<String>();
    for (final s in [proc.stdout, proc.stderr]) {
      s.transform(utf8.decoder).transform(const LineSplitter()).listen(lines.add, onError: (_) {});
    }
    final exit = proc.exitCode.whenComplete(() => Future<void>.delayed(const Duration(milliseconds: 50), lines.close));
    await for (final l in lines.stream) {
      // The installer's headings are bold (ANSI); the sheet shows plain text.
      final text = l.replaceAll(RegExp(r'\x1B\[[0-9;]*m'), '').trim();
      if (text.isNotEmpty) yield LocalServerProgress(LocalServerStep.installing, detail: text);
    }
    final code = await exit;
    if (_proc == proc) _proc = null;
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
    yield LocalServerProgress(LocalServerStep.failed, detail: 'The server didn\'t answer in time. Run `docker compose ps` in ${dir.path}/infra/compose to see why.');
  }
}
