import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Offline cache (D-112, replacing D-042's deferral): the last bots, conversations and recent
/// messages the app saw, as JSON snapshots in a small drift (SQLite) table, so chats open
/// instantly and stay readable offline. Mobile and desktop; the web app reads live data only.
abstract class LocalCache {
  Future<Object?> read(String key);
  Future<void> write(String key, Object? value);
  Future<void> clear();
}

/// Nothing cached (web, tests, or before sign-in).
class NoCache implements LocalCache {
  const NoCache();
  @override
  Future<Object?> read(String key) async => null;
  @override
  Future<void> write(String key, Object? value) async {}
  @override
  Future<void> clear() async {}
}

/// An in-memory cache (tests).
class MemoryCache implements LocalCache {
  final data = <String, String>{};
  @override
  Future<Object?> read(String key) async => data[key] == null ? null : jsonDecode(data[key]!);
  @override
  Future<void> write(String key, Object? value) async => data[key] = jsonEncode(value);
  @override
  Future<void> clear() async => data.clear();
}

/// A drift database with one table, created by hand so the app needs no code generation.
class _CacheDb extends GeneratedDatabase {
  _CacheDb(super.executor);

  @override
  Iterable<TableInfo<Table, dynamic>> get allTables => const [];

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => customStatement('create table if not exists cache (key text primary key, value text not null, updated_at integer not null)'),
      );
}

class DriftCache implements LocalCache {
  DriftCache(QueryExecutor executor) : _db = _CacheDb(executor);
  DriftCache.open() : this(driftDatabase(name: 'casama_cache'));
  final _CacheDb _db;

  @override
  Future<Object?> read(String key) async {
    final rows = await _db.customSelect('select value from cache where key = ?', variables: [Variable.withString(key)]).get();
    if (rows.isEmpty) return null;
    try {
      return jsonDecode(rows.first.read<String>('value'));
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(String key, Object? value) => _db.customStatement(
        'insert into cache (key, value, updated_at) values (?, ?, ?) on conflict (key) do update set value = excluded.value, updated_at = excluded.updated_at',
        [key, jsonEncode(value), DateTime.now().millisecondsSinceEpoch],
      );

  @override
  Future<void> clear() => _db.customStatement('delete from cache');

  Future<void> close() => _db.close();
}

/// The device's cache on mobile and desktop; nothing on the web.
LocalCache openLocalCache() {
  if (kIsWeb) return const NoCache();
  try {
    return DriftCache.open();
  } catch (_) {
    return const NoCache();
  }
}

/// The app's cache: main.dart installs [openLocalCache]; elsewhere (tests) nothing is cached.
/// Signing out clears it.
final localCacheProvider = Provider<LocalCache>((ref) => const NoCache());

/// Reads that never throw: a missing or broken cache just means "nothing saved".
Future<Object?> cacheRead(LocalCache cache, String key) async {
  try {
    return await cache.read(key);
  } catch (_) {
    return null;
  }
}

Future<void> cacheWrite(LocalCache cache, String key, Object? value) async {
  try {
    await cache.write(key, value);
  } catch (_) {}
}

Future<void> cacheClear(LocalCache cache) async {
  try {
    await cache.clear();
  } catch (_) {}
}
