import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/backend.dart';
import '../devices/device_events.dart';
import 'desktop_context.dart';

/// Desktop context (D-152): folders the desktop app watches (a new file is a device event that can
/// start a routine, such as "file it" for PDFs in Downloads) and the activity recap (front-app
/// time and window titles, summarised per hour; never screenshots or keystrokes).

/// Files still being written (browsers' partial downloads, hidden files) aren't reported.
@visibleForTesting
bool reportableFile(String name) =>
    name.isNotEmpty && !name.startsWith('.') && !RegExp(r'\.(crdownload|part|partial|download|tmp|opdownload)$', caseSensitive: false).hasMatch(name) && !name.startsWith('~\$');

String _base(String p) => p.replaceAll('\\', '/').split('/').where((s) => s.isNotEmpty).lastOrNull ?? p;

class FolderWatcher {
  FolderWatcher(this.backend);
  final Backend backend;
  final _subs = <StreamSubscription<FileSystemEvent>>[];
  static const pref = 'casama.watched_folders';

  static Future<List<String>> folders() async => (await SharedPreferences.getInstance()).getStringList(pref) ?? const [];
  static Future<void> setFolders(List<String> f) async => (await SharedPreferences.getInstance()).setStringList(pref, f);

  Future<void> start() async {
    await stop();
    for (final f in await folders()) {
      final dir = Directory(f);
      if (!dir.existsSync()) continue;
      _subs.add(
        dir.watch(events: FileSystemEvent.create | FileSystemEvent.move).listen((e) {
          final path = e is FileSystemMoveEvent ? (e.destination ?? e.path) : e.path;
          unawaited(_report(f, path));
        }),
      );
    }
  }

  /// Waits until the file stops growing (a download finishing), then reports it.
  Future<void> _report(String folder, String path, {Duration settle = const Duration(seconds: 2)}) async {
    final name = _base(path);
    if (!reportableFile(name)) return;
    var last = -1;
    for (var i = 0; i < 30; i++) {
      final f = File(path);
      if (!f.existsSync()) return;
      final size = f.lengthSync();
      if (size == last) break;
      last = size;
      await Future<void>.delayed(settle);
    }
    final at = DateTime.now().toUtc();
    await DeviceEventQueue.add({'id': 'file-${path.hashCode & 0xffffffff}-${at.millisecondsSinceEpoch}', 'type': 'file_added', 'at': at.toIso8601String(), 'folder': _base(folder), 'name': name});
    await DeviceEventQueue.flush(backend).catchError((_) => 0);
  }

  Future<void> stop() async {
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
  }
}

/// Hourly buckets of front-app time, kept on this computer until uploaded.
class ActivityTracker {
  ActivityTracker(this.backend, this.reader, {this.now = DateTime.now, this.every = const Duration(seconds: 30)});
  final Backend backend;
  final DesktopContextReader reader;
  final DateTime Function() now;
  final Duration every;
  Timer? _timer;
  static const pref = 'casama.activity';

  static String hourOf(DateTime t) => '${t.year.toString().padLeft(4, '0')}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}T${t.hour.toString().padLeft(2, '0')}';

  void start(String deviceKey) {
    _timer?.cancel();
    _timer = Timer.periodic(every, (_) => unawaited(sample(deviceKey).catchError((_) {})));
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// One sample: adds [every] to the front app (and its window title) in this hour's bucket, and
  /// uploads finished hours.
  Future<void> sample(String deviceKey) async {
    final c = await reader.captureWindow();
    final prefs = await SharedPreferences.getInstance();
    final buckets = Map<String, dynamic>.from(jsonDecode(prefs.getString(pref) ?? '{}') as Map);
    final hour = hourOf(now());
    if (c.app != null) {
      final b = Map<String, dynamic>.from((buckets[hour] as Map?) ?? {});
      final a = Map<String, dynamic>.from((b[c.app] as Map?) ?? {'seconds': 0, 'titles': <String, dynamic>{}});
      a['seconds'] = (a['seconds'] as num) + every.inSeconds;
      final titles = Map<String, dynamic>.from(a['titles'] as Map);
      final t = (c.window ?? '').trim();
      if (t.isNotEmpty) titles[t.length > 120 ? t.substring(0, 120) : t] = ((titles[t] as num?) ?? 0) + every.inSeconds;
      a['titles'] = titles;
      b[c.app!] = a;
      buckets[hour] = b;
    }
    // Finished hours go up as summaries; they stay here until the server has them.
    final done = buckets.keys.where((h) => h != hour).toList()..sort();
    if (done.isNotEmpty) {
      final readings = [for (final h in done) activitySummary(h, Map<String, dynamic>.from(buckets[h] as Map))];
      try {
        await backend.uploadDeviceReadings(deviceKey, readings);
        for (final h in done) {
          buckets.remove(h);
        }
      } catch (_) {
        // Keep at most two days if offline.
        while (buckets.length > 48) {
          buckets.remove((buckets.keys.toList()..sort()).first);
        }
      }
    }
    await prefs.setString(pref, jsonEncode(buckets));
  }
}

/// An hour's bucket as an upload: minutes per app, its top window titles.
@visibleForTesting
DeviceReadingInput activitySummary(String hour, Map<String, dynamic> bucket) {
  final apps = [
    for (final e in bucket.entries)
      () {
        final a = Map<String, dynamic>.from(e.value as Map);
        final titles = Map<String, dynamic>.from(a['titles'] as Map).entries.toList()..sort((x, y) => (y.value as num).compareTo(x.value as num));
        return {
          'app': e.key.length > 100 ? e.key.substring(0, 100) : e.key,
          'minutes': ((a['seconds'] as num) / 60).round(),
          if (titles.isNotEmpty) 'titles': [for (final t in titles.take(3)) t.key],
        };
      }(),
  ]..sort((x, y) => (y['minutes'] as int).compareTo(x['minutes'] as int));
  final total = apps.fold<int>(0, (s, a) => s + (a['minutes'] as int));
  final p = hour.split(RegExp('[-T]')).map(int.parse).toList();
  final start = DateTime(p[0], p[1], p[2], p[3]);
  return DeviceReadingInput(
    kind: DeviceKind.activity,
    periodStart: start.toUtc(),
    periodEnd: start.add(const Duration(minutes: 59, seconds: 59)).toUtc(),
    externalId: 'activity-$hour',
    summary: {'type': 'hour', 'hour': hour, 'total_minutes': total > 60 ? 60 : total, 'apps': apps.take(30).toList()},
  );
}
