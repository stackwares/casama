import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:casama_computerd/computerd.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

const token = 'test-token-0123456789abcdef';
final jpeg = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0, 16, 74, 70, 73, 70, 0, 0xFF, 0xD9]);

/// Stand-in tools: records every run and answers like ffmpeg and ffprobe would.
class FakeTools extends ThumbnailTools {
  FakeTools({this.installed = const {'ffmpeg', 'ffprobe'}}) : super(os: 'linux');
  final Set<String> installed;
  final runs = <List<String>>[];

  /// Seeks that print nothing (a clip shorter than the seek).
  final emptyAt = <String>{};

  @override
  String? find(String name) => installed.contains(name) ? '/fake/$name' : null;

  @override
  Future<ToolResult?> run(String exe, List<String> args, Duration timeout) async {
    runs.add([exe, ...args]);
    if (exe.endsWith('ffprobe')) return ToolResult(0, Uint8List.fromList(utf8.encode('3.5\n')));
    final seek = args.contains('-ss') ? args[args.indexOf('-ss') + 1] : null;
    if (emptyAt.contains(seek)) return ToolResult(0, Uint8List(0));
    return ToolResult(0, jpeg);
  }

  int get ffmpegRuns => runs.where((r) => r.first.endsWith('ffmpeg')).length;
}

void main() {
  late Directory home;
  late Directory cache;
  late FakeTools tools;
  late Computerd server;
  late Uri base;
  final auth = {'authorization': 'Bearer $token'};

  Future<void> start({List<String>? roots, Set<String>? caps, FakeTools? fake}) async {
    tools = fake ?? FakeTools();
    server = Computerd(
      ComputerdConfig(
        home: home.path,
        token: token,
        port: 0,
        address: '127.0.0.1',
        allowedRoots: roots,
        capabilities: caps,
        thumbnailTools: tools,
        thumbnailCacheDir: cache.path,
      ),
    );
    await server.start();
    base = Uri.parse('http://127.0.0.1:${server.port}');
  }

  Future<http.Response> thumb(String path, {int? size}) => http.get(
    base.replace(path: '/files/thumbnail', queryParameters: {'path': path, 'size': ?size?.toString()}),
    headers: auth,
  );

  setUp(() {
    home = Directory.systemTemp.createTempSync('thumbs-home');
    cache = Directory('${home.path}/.thumbs');
    Directory('${home.path}/workspace').createSync();
    File('${home.path}/workspace/clip.mp4').writeAsBytesSync([0, 0, 0, 24]);
    File('${home.path}/workspace/notes.txt').writeAsStringSync('hi');
  });
  tearDown(() async {
    await server.stop();
    home.deleteSync(recursive: true);
  });

  test('a video gets its first frame and length; asking again uses the cache', () async {
    await start();
    final res = await thumb('clip.mp4', size: 10000);
    expect(res.statusCode, 200, reason: res.body);
    expect(res.headers['content-type'], 'image/jpeg');
    expect(res.bodyBytes, jpeg);
    expect(res.headers['x-duration-ms'], '3500');
    final mtime = File('${home.path}/workspace/clip.mp4').lastModifiedSync().millisecondsSinceEpoch;
    expect(res.headers['x-file-mtime'], '$mtime');
    // Fast input seek, and the size clamped to 640.
    final ffmpeg = tools.runs.firstWhere((r) => r.first.endsWith('ffmpeg'));
    expect(ffmpeg.sublist(ffmpeg.indexOf('-ss'), ffmpeg.indexOf('-ss') + 3), ['-ss', '0.5', '-i']);
    expect(ffmpeg.join(' '), contains("min(640,iw)"));

    final runs = tools.runs.length;
    final again = await thumb('clip.mp4', size: 10000);
    expect(again.statusCode, 200);
    expect(again.bodyBytes, jpeg);
    expect(again.headers['x-duration-ms'], '3500');
    expect(tools.runs.length, runs, reason: 'a cache hit runs no tool');

    // A changed file is a new thumbnail.
    File('${home.path}/workspace/clip.mp4').setLastModifiedSync(DateTime.now().add(const Duration(minutes: 1)));
    expect((await thumb('clip.mp4', size: 10000)).statusCode, 200);
    expect(tools.ffmpegRuns, 2);
  });

  test('a clip shorter than the seek falls back to its first frame', () async {
    await start(fake: FakeTools()..emptyAt.add('0.5'));
    final res = await thumb('clip.mp4');
    expect(res.statusCode, 200);
    final seeks = tools.runs.where((r) => r.first.endsWith('ffmpeg')).map((r) => r[r.indexOf('-ss') + 1]).toList();
    expect(seeks, ['0.5', '0']);
    expect(tools.runs.firstWhere((r) => r.first.endsWith('ffmpeg')).join(' '), contains('min(480,iw)'));
  });

  test('unsupported files and missing tools answer 404 no_thumbnail without running anything', () async {
    await start(fake: FakeTools(installed: const {}));
    final txt = await thumb('notes.txt');
    expect(txt.statusCode, 404);
    expect(jsonDecode(txt.body)['code'], 'no_thumbnail');
    final noTool = await thumb('clip.mp4');
    expect(noTool.statusCode, 404);
    expect(jsonDecode(noTool.body)['code'], 'no_thumbnail');
    expect(tools.runs, isEmpty);
    final missing = await thumb('gone.mp4');
    expect(missing.statusCode, 404);
    expect(jsonDecode(missing.body)['code'], 'not_found');
  });

  test('a file that has no thumbnail is remembered, so it costs nothing next time', () async {
    final t = FakeTools()..emptyAt.addAll(['0.5', '0']);
    await start(fake: t);
    expect((await thumb('clip.mp4')).statusCode, 404);
    final runs = t.runs.length;
    expect((await thumb('clip.mp4')).statusCode, 404);
    expect(t.runs.length, runs);
  });

  test('companion mode: only inside the shared folders, and only with files allowed', () async {
    final shared = Directory('${home.path}/Shared')..createSync();
    final private = Directory('${home.path}/Private')..createSync();
    File('${shared.path}/trip.mp4').writeAsBytesSync([1]);
    File('${private.path}/secret.mp4').writeAsBytesSync([1]);
    await start(roots: [shared.path], caps: {'files'});
    expect((await thumb('${shared.path}/trip.mp4')).statusCode, 200);
    final outside = await thumb('${private.path}/secret.mp4');
    expect(outside.statusCode, 403);
    expect(jsonDecode(outside.body)['code'], 'outside_allowed_folders');
    expect((await thumb('../Private/secret.mp4')).statusCode, 403);
    expect(tools.ffmpegRuns, 1);
    await server.stop();

    await start(roots: [shared.path], caps: {'shell'});
    final noFiles = await thumb('${shared.path}/trip.mp4');
    expect(noFiles.statusCode, 403);
    expect(jsonDecode(noFiles.body)['code'], 'capability_not_allowed');
    expect(tools.runs, isEmpty);
  });

  test('a tool that runs too long is killed at the limit', () async {
    final sw = Stopwatch()..start();
    final r = await ThumbnailTools().run('sleep', ['30'], const Duration(milliseconds: 300));
    expect(r, isNull);
    expect(sw.elapsed, lessThan(const Duration(seconds: 5)));
  });

  test('which files can have thumbnails', () {
    expect(thumbnailKindFor('/x/Clip.MOV'), ThumbnailKind.video);
    expect(thumbnailKindFor('a/b.webm'), ThumbnailKind.video);
    expect(thumbnailKindFor('photo.heic'), ThumbnailKind.image);
    expect(thumbnailKindFor('report.pdf'), ThumbnailKind.pdf);
    expect(thumbnailKindFor('notes.md'), isNull);
  });
}
