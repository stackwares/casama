import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/backend.dart';
import '../../../core/media_cache.dart';
import '../../../core/providers.dart';

/// Thumbnails of videos and PDFs that live on a bot's computer (D-226), so a chat card shows a
/// picture instead of a plain tile without downloading the whole file.
///
/// Cheap by design: one request per file at a time, kept in memory and on disk for a day (the bot
/// can rewrite a file under the same name), and a file with no thumbnail (or a computer that's
/// asleep, which the server never wakes for this) isn't asked about again for a couple of minutes.
class ComputerThumbnails {
  ComputerThumbnails._();

  /// Pixels on the longest side: sharp on a 320-point card at 1.5x.
  static const size = 480;
  static const _keep = Duration(days: 1);
  static const _retryAfter = Duration(minutes: 2);

  static final _inFlight = <String, Future<ComputerThumbnail?>>{};
  static final _noneUntil = <String, DateTime>{};

  static String keyFor(String computerId, String path) =>
      'thumb:${MediaCache.keyFor(computerId, path)}:$size';

  /// The thumbnail already in memory, without waiting (see [MediaCache.peek]).
  static ComputerThumbnail? peek(String computerId, String path) {
    final key = keyFor(computerId, path);
    final bytes = MediaCache.peek(key);
    if (bytes == null) return null;
    return ComputerThumbnail(bytes: bytes, duration: _durations[key]);
  }

  /// The thumbnail, or null when there is none (the card keeps its plain look). Never throws.
  /// [cachedOnly]: only what's kept on the device, never the network (cards look there at once
  /// and ask the computer only once they've stayed on screen a moment).
  static Future<ComputerThumbnail?> load(
    Backend backend,
    String computerId,
    String path, {
    bool cachedOnly = false,
  }) {
    final key = keyFor(computerId, path);
    if (cachedOnly) return _cached(key).catchError((_) => null);
    final until = _noneUntil[key];
    if (until != null && DateTime.now().isBefore(until)) {
      return Future.value(null);
    }
    return _inFlight[key] ??= _load(backend, computerId, path, key)
        .catchError((_) => null)
        .whenComplete(() {
          // A block: returning the removed future would make this wait on itself.
          _inFlight.remove(key);
        });
  }

  /// Clip lengths of thumbnails read this session, for [peek].
  static final _durations = <String, Duration?>{};

  static Future<ComputerThumbnail?> _cached(String key) async {
    final cached = await MediaCache.read(key, fresh: true);
    if (cached == null) return null;
    final meta = await MediaCache.read('$key#ms', fresh: true);
    final ms = meta == null ? null : int.tryParse(utf8.decode(meta));
    final duration = ms == null ? null : Duration(milliseconds: ms);
    _durations[key] = duration;
    return ComputerThumbnail(bytes: cached, duration: duration);
  }

  static Future<ComputerThumbnail?> _load(
    Backend backend,
    String computerId,
    String path,
    String key,
  ) async {
    final cached = await _cached(key);
    if (cached != null) return cached;
    final t = await backend.computerThumbnail(computerId, path, size: size);
    if (t == null) {
      _noneUntil[key] = DateTime.now().add(_retryAfter);
      return null;
    }
    _noneUntil.remove(key);
    _durations[key] = t.duration;
    unawaited(MediaCache.write(key, t.bytes, maxAge: _keep));
    if (t.duration case final d?) {
      unawaited(
        MediaCache.write(
          '$key#ms',
          Uint8List.fromList(utf8.encode('${d.inMilliseconds}')),
          maxAge: _keep,
        ),
      );
    }
    return t;
  }

  @visibleForTesting
  static void reset() {
    _inFlight.clear();
    _noneUntil.clear();
    _durations.clear();
  }
}

/// A computer file's thumbnail by (computer id, files API path), for cards built with Riverpod.
final computerThumbnailProvider = FutureProvider.autoDispose
    .family<ComputerThumbnail?, (String, String)>(
      (ref, key) =>
          ComputerThumbnails.load(ref.watch(backendProvider), key.$1, key.$2),
    );
