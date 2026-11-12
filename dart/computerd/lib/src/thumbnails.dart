import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

/// Thumbnails of files on a computer (D-226): a video's first frame, an image, a PDF's first
/// page. Made with what the computer already has (Quick Look on a Mac; ffmpeg and pdftoppm
/// elsewhere), one at a time, under a hard time limit, and cached on disk so a chat opened again
/// costs nothing.
enum ThumbnailKind { video, image, pdf }

const _videos = {'mp4', 'm4v', 'mov', 'webm', 'mkv', 'avi', '3gp', 'mpg', 'mpeg', 'wmv', 'ogv'};
const _images = {'jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'tif', 'tiff', 'heic', 'heif'};

ThumbnailKind? thumbnailKindFor(String path) {
  final ext = p.extension(path).toLowerCase().replaceFirst('.', '');
  if (_videos.contains(ext)) return ThumbnailKind.video;
  if (_images.contains(ext)) return ThumbnailKind.image;
  if (ext == 'pdf') return ThumbnailKind.pdf;
  return null;
}

/// What a tool printed and how it ended.
class ToolResult {
  const ToolResult(this.exitCode, this.stdout);
  final int exitCode;
  final Uint8List stdout;
}

/// Finds and runs the tools thumbnails need. Tests replace it so they don't need ffmpeg.
class ThumbnailTools {
  ThumbnailTools({this.extraPath = const [], String? os}) : os = os ?? Platform.operatingSystem;

  /// Searched before PATH (Homebrew on a Mac, where apps start with a minimal PATH).
  final List<String> extraPath;

  /// `macos`, `linux` or `windows`: which tools to use.
  final String os;

  final _found = <String, String?>{};

  /// The tool's full path, or null when it isn't installed.
  String? find(String name) => _found.putIfAbsent(name, () {
    final sep = os == 'windows' ? ';' : ':';
    final dirs = [...extraPath, ...(Platform.environment['PATH'] ?? '/usr/bin:/bin').split(sep)];
    final names = os == 'windows' ? ['$name.exe', name] : [name];
    for (final d in dirs.where((d) => d.isNotEmpty)) {
      for (final n in names) {
        final f = p.join(d, n);
        if (File(f).existsSync()) return f;
      }
    }
    return null;
  });

  /// Runs a tool, killing it at [timeout]. Null when it couldn't start, ran too long or printed
  /// more than a thumbnail ever needs.
  Future<ToolResult?> run(String exe, List<String> args, Duration timeout) async {
    final Process process;
    try {
      process = await Process.start(exe, args);
    } catch (_) {
      return null;
    }
    unawaited(process.stdin.close().catchError((_) {}));
    const maxOut = 8 * 1024 * 1024;
    final out = BytesBuilder(copy: false);
    var killed = false;
    void kill() {
      killed = true;
      process.kill(ProcessSignal.sigkill);
    }

    final timer = Timer(timeout, kill);
    final outDone = process.stdout
        .listen((chunk) {
          if (killed) return;
          if (out.length + chunk.length > maxOut) return kill();
          out.add(chunk);
        })
        .asFuture<void>()
        .catchError((_) {});
    final errDone = process.stderr.drain<void>().catchError((_) {});
    final code = await process.exitCode;
    timer.cancel();
    await outDone;
    await errDone;
    if (killed) return null;
    return ToolResult(code, out.takeBytes());
  }
}

/// A finished thumbnail.
class Thumbnail {
  const Thumbnail({required this.bytes, required this.contentType, required this.modified, this.durationMs});
  final Uint8List bytes;
  final String contentType;
  final DateTime modified;
  final int? durationMs;
}

/// Too many thumbnails are already waiting; ask again later.
class ThumbnailBusy implements Exception {
  const ThumbnailBusy();
}

class ThumbnailService {
  ThumbnailService({
    required this.tools,
    required this.cacheDir,
    this.timeout = const Duration(seconds: 8),
    this.maxEntries = 200,
    this.maxBytes = 50 * 1024 * 1024,
    this.maxWaiting = 6,
  });

  final ThumbnailTools tools;
  final String cacheDir;

  /// The whole job's limit, all tools included; anything slower is killed.
  final Duration timeout;
  final int maxEntries;
  final int maxBytes;

  /// Jobs allowed to wait behind the one running before new ones are turned away.
  final int maxWaiting;

  /// One job at a time, so a chat full of videos can't load the computer.
  Future<void> _tail = Future.value();
  var _waiting = 0;

  /// [file]'s thumbnail no larger than [size] pixels, or null when it can't have one.
  Future<Thumbnail?> thumbnail(File file, int size) async {
    final kind = thumbnailKindFor(file.path);
    if (kind == null) return null;
    final stat = file.statSync();
    final key = _hash('${file.path}|${stat.modified.microsecondsSinceEpoch}|${stat.size}|$size');
    final hit = _lookup(key, stat.modified);
    if (hit != null) return hit.$1;
    if (_waiting >= maxWaiting) throw const ThumbnailBusy();
    _waiting++;
    final done = Completer<void>();
    final previous = _tail;
    _tail = done.future;
    try {
      await previous;
      // Another request may have made it while this one waited.
      final again = _lookup(key, stat.modified);
      if (again != null) return again.$1;
      final made = await _make(file, kind, size, DateTime.now().add(timeout));
      _store(key, made);
      return made == null ? null : Thumbnail(bytes: made.$1, contentType: made.$2, modified: stat.modified, durationMs: made.$3);
    } finally {
      _waiting--;
      done.complete();
    }
  }

  // ---------------------------------------------------------------------------
  // making them

  Duration _left(DateTime deadline) {
    final d = deadline.difference(DateTime.now());
    return d < const Duration(milliseconds: 200) ? const Duration(milliseconds: 200) : d;
  }

  /// (bytes, content type, duration in ms) or null.
  Future<(Uint8List, String, int?)?> _make(File file, ThumbnailKind kind, int size, DateTime deadline) async {
    if (tools.os == 'macos') return _quickLook(file, kind, size, deadline);
    return switch (kind) {
      ThumbnailKind.video || ThumbnailKind.image => _ffmpeg(file, kind, size, deadline),
      ThumbnailKind.pdf => _pdftoppm(file, size, deadline),
    };
  }

  static bool _isImage(Uint8List b) => b.length > 8 && ((b[0] == 0xFF && b[1] == 0xD8) || (b[0] == 0x89 && b[1] == 0x50 && b[2] == 0x4E && b[3] == 0x47));

  Future<(Uint8List, String, int?)?> _ffmpeg(File file, ThumbnailKind kind, int size, DateTime deadline) async {
    final ffmpeg = tools.find('ffmpeg');
    if (ffmpeg == null) return null;
    final scale = "scale=w='min($size,iw)':h='min($size,ih)':force_original_aspect_ratio=decrease";
    List<String> args(String? seek) => [
      '-hide_banner',
      '-loglevel',
      'error',
      '-nostdin',
      if (seek != null) ...['-ss', seek],
      '-i',
      file.path,
      '-frames:v',
      '1',
      '-vf',
      scale,
      '-q:v',
      '6',
      '-f',
      'image2',
      '-c:v',
      'mjpeg',
      'pipe:1',
    ];
    Uint8List? frame;
    // Seeking before the input is fast; a clip shorter than half a second has nothing there.
    for (final seek in kind == ThumbnailKind.video ? ['0.5', '0'] : [null]) {
      final r = await tools.run(ffmpeg, args(seek), _left(deadline));
      if (r != null && r.exitCode == 0 && _isImage(r.stdout)) {
        frame = r.stdout;
        break;
      }
      if (DateTime.now().isAfter(deadline)) break;
    }
    if (frame == null) return null;
    return (frame, 'image/jpeg', kind == ThumbnailKind.video ? await _probe(file, deadline) : null);
  }

  /// A video's length with ffprobe, when it's installed and there's time left.
  Future<int?> _probe(File file, DateTime deadline) async {
    final ffprobe = tools.find('ffprobe');
    if (ffprobe == null || DateTime.now().isAfter(deadline)) return null;
    final r = await tools.run(ffprobe, ['-v', 'error', '-show_entries', 'format=duration', '-of', 'csv=p=0', file.path], _left(deadline));
    return _ms(r == null || r.exitCode != 0 ? null : utf8.decode(r.stdout, allowMalformed: true));
  }

  Future<(Uint8List, String, int?)?> _pdftoppm(File file, int size, DateTime deadline) async {
    final tool = tools.find('pdftoppm');
    if (tool == null) return null;
    final r = await tools.run(tool, [
      '-jpeg',
      '-jpegopt',
      'quality=75',
      '-f',
      '1',
      '-l',
      '1',
      '-scale-to',
      '$size',
      '-singlefile',
      file.path,
      '-',
    ], _left(deadline));
    if (r == null || r.exitCode != 0 || !_isImage(r.stdout)) return null;
    return (r.stdout, 'image/jpeg', null);
  }

  /// macOS: Quick Look draws videos, images and PDFs alike; sips makes the PNG a smaller JPEG.
  Future<(Uint8List, String, int?)?> _quickLook(File file, ThumbnailKind kind, int size, DateTime deadline) async {
    final ql = tools.find('qlmanage');
    if (ql == null) return null;
    final tmp = Directory.systemTemp.createTempSync('casama-ql');
    try {
      final r = await tools.run(ql, ['-t', '-s', '$size', '-o', tmp.path, file.path], _left(deadline));
      final png = File(p.join(tmp.path, '${p.basename(file.path)}.png'));
      if (r == null || !png.existsSync()) return null;
      var bytes = png.readAsBytesSync();
      var type = 'image/png';
      final sips = tools.find('sips');
      if (sips != null && DateTime.now().isBefore(deadline)) {
        final jpg = p.join(tmp.path, 'thumb.jpg');
        final s = await tools.run(sips, ['-s', 'format', 'jpeg', '-s', 'formatOptions', '70', png.path, '--out', jpg], _left(deadline));
        if (s != null && s.exitCode == 0 && File(jpg).existsSync()) {
          bytes = File(jpg).readAsBytesSync();
          type = 'image/jpeg';
        }
      }
      if (!_isImage(bytes)) return null;
      int? duration;
      final mdls = kind == ThumbnailKind.video ? tools.find('mdls') : null;
      if (mdls != null && DateTime.now().isBefore(deadline)) {
        final m = await tools.run(mdls, ['-raw', '-name', 'kMDItemDurationSeconds', file.path], _left(deadline));
        duration = _ms(m == null ? null : utf8.decode(m.stdout, allowMalformed: true));
      }
      // Spotlight doesn't index every folder.
      if (kind == ThumbnailKind.video) duration ??= await _probe(file, deadline);
      return (bytes, type, duration);
    } finally {
      try {
        tmp.deleteSync(recursive: true);
      } catch (_) {}
    }
  }

  static int? _ms(String? seconds) {
    final s = double.tryParse((seconds ?? '').trim());
    return s == null || s <= 0 || s.isNaN || s.isInfinite ? null : (s * 1000).round();
  }

  // ---------------------------------------------------------------------------
  // the disk cache: `<key>.<ms|x>.<jpg|png>`, or `<key>.none` for a file that has no thumbnail

  /// A cached answer: (thumbnail or null for "has none"), or null on a miss.
  (Thumbnail?,)? _lookup(String key, DateTime modified) {
    final dir = Directory(cacheDir);
    if (!dir.existsSync()) return null;
    for (final f in dir.listSync().whereType<File>()) {
      final name = p.basename(f.path);
      if (!name.startsWith('$key.')) continue;
      try {
        f.setLastModifiedSync(DateTime.now()); // kept longest when used most recently
        if (name.endsWith('.none')) return (null,);
        final parts = name.split('.');
        return (
          Thumbnail(
            bytes: f.readAsBytesSync(),
            contentType: parts.last == 'png' ? 'image/png' : 'image/jpeg',
            modified: modified,
            durationMs: int.tryParse(parts[1]),
          ),
        );
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  void _store(String key, (Uint8List, String, int?)? made) {
    try {
      final dir = Directory(cacheDir)..createSync(recursive: true);
      final name = made == null ? '$key.none' : '$key.${made.$3 ?? 'x'}.${made.$2 == 'image/png' ? 'png' : 'jpg'}';
      File(p.join(dir.path, name)).writeAsBytesSync(made?.$1 ?? const []);
      _evict(dir);
    } catch (_) {
      // A full or read-only disk only costs the cache.
    }
  }

  /// Keeps at most [maxEntries] files and [maxBytes], dropping the least recently used.
  void _evict(Directory dir) {
    final files = dir.listSync().whereType<File>().map((f) => (f, f.statSync())).toList()..sort((a, b) => b.$2.modified.compareTo(a.$2.modified));
    var count = 0;
    var bytes = 0;
    for (final (f, s) in files) {
      count++;
      bytes += s.size;
      if (count > maxEntries || bytes > maxBytes) {
        try {
          f.deleteSync();
        } catch (_) {}
      }
    }
  }

  /// FNV-1a, 64 bits, as hex: enough to tell a few hundred cache entries apart.
  static String _hash(String s) {
    var h = 0xcbf29ce484222325;
    for (final b in utf8.encode(s)) {
      h ^= b;
      h *= 0x100000001b3; // wraps at 64 bits
    }
    return (h >>> 32).toRadixString(16).padLeft(8, '0') + (h & 0xFFFFFFFF).toRadixString(16).padLeft(8, '0');
  }
}
