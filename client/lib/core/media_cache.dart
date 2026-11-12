import 'dart:async';
import 'dart:io' show Platform;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// A picture from the web, kept on the device after the first load (see [MediaCache]).
ImageProvider cachedNetworkImage(String url, {Map<String, String>? headers}) =>
    MediaCache.diskEnabled
    ? CachedNetworkImageProvider(
        url,
        headers: headers,
        cacheManager: MediaCache.manager,
      )
    : NetworkImage(url, headers: headers);

/// Pictures and files the chat shows, kept on the device so a chat opened again shows them at
/// once (no download, no waking the bot's computer). Web pictures share it through
/// CachedNetworkImage. Signing out empties it, like the offline cache (D-112).
///
/// Only things that never change under the same name are kept: chat media (`media:<id>`) and
/// files sent into a chat (`…/uploads/<stamp>-<name>`). Anything else on a computer can be
/// rewritten by the bot, so it is always fetched fresh.
class MediaCache {
  MediaCache._();

  static final manager = CacheManager(
    Config(
      'casama_media',
      stalePeriod: const Duration(days: 60),
      maxNrOfCacheObjects: 2000,
    ),
  );

  /// Recent bytes in memory too, so scrolling back and forth never touches the disk.
  static final _memory = <String, Uint8List>{};
  static var _memoryBytes = 0;
  static const _memoryLimit = 64 * 1024 * 1024;

  /// Off under `flutter test` (no platform channels there); memory still works.
  static var diskEnabled =
      kIsWeb || !Platform.environment.containsKey('FLUTTER_TEST');

  /// Whether a computer file (or chat media) can be kept under its name.
  static bool cacheable(String path) =>
      path.startsWith('media:') ||
      path.contains('/uploads/') ||
      path.startsWith('uploads/');

  static String keyFor(String computerId, String path) {
    final p = path.startsWith('workspace/')
        ? path.substring('workspace/'.length)
        : path;
    return path.startsWith('media:') ? path : 'file:$computerId:$p';
  }

  static void _remember(String key, Uint8List bytes) {
    if (bytes.length > _memoryLimit ~/ 4) return;
    final old = _memory.remove(key);
    if (old != null) _memoryBytes -= old.length;
    _memory[key] = bytes;
    _memoryBytes += bytes.length;
    while (_memoryBytes > _memoryLimit && _memory.isNotEmpty) {
      final first = _memory.keys.first;
      _memoryBytes -= _memory.remove(first)!.length;
    }
  }

  /// What's in memory now, without waiting: a card built again (scrolled back to) shows its
  /// picture on its first frame. The same bytes object each time, so a MemoryImage of it hits
  /// Flutter's image cache too.
  static Uint8List? peek(String key) => _memory[key];

  /// [fresh]: skip a disk copy older than the maxAge it was written with.
  static Future<Uint8List?> read(String key, {bool fresh = false}) async {
    final hit = _memory.remove(key);
    if (hit != null) {
      _memory[key] = hit; // most recent last
      return hit;
    }
    if (!diskEnabled) return null;
    try {
      final file = await manager.getFileFromCache(key);
      if (file == null) return null;
      if (fresh && file.validTill.isBefore(DateTime.now())) return null;
      final bytes = await file.file.readAsBytes();
      _remember(key, bytes);
      return bytes;
    } catch (_) {
      return null;
    }
  }

  /// [maxAge]: how long the disk copy is trusted (thumbnails of files that can change, D-226).
  static Future<void> write(
    String key,
    Uint8List bytes, {
    Duration maxAge = const Duration(days: 30),
  }) async {
    _remember(key, bytes);
    if (!diskEnabled) return;
    try {
      await manager.putFile(
        key,
        bytes,
        key: key,
        maxAge: maxAge,
        fileExtension: 'bin',
      );
    } catch (_) {}
  }

  /// Reads [key], or fetches it once and keeps it.
  static Future<Uint8List> getOrFetch(
    String key,
    Future<Uint8List> Function() fetch,
  ) async {
    final cached = await read(key);
    if (cached != null) return cached;
    final bytes = await fetch();
    unawaited(write(key, bytes));
    return bytes;
  }

  static Future<void> clear() async {
    _memory.clear();
    _memoryBytes = 0;
    if (!diskEnabled) return;
    try {
      await manager.emptyCache();
    } catch (_) {}
  }
}
