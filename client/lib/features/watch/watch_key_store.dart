import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'watch_models.dart';

/// Where taking a watch's key back stands once the phone has signed out.
enum WatchRemoval {
  /// The server deleted the key. The bridge only has to tell the watch and forget it.
  done,

  /// The server may still have the key (the session had ended, or the phone was offline): it is
  /// deleted the next time the same account is signed in on this phone.
  pending;

  static WatchRemoval? parse(Object? value) => switch (value) {
    'done' => done,
    'pending' => pending,
    _ => null,
  };
}

/// A watch this phone signed in (D-410, WATCH-PROTOCOL §3): what the watch said about itself, the
/// key id the server gave, and the account and workspace it was made for. Only the fingerprint is
/// kept, never the key, and a fingerprint isn't secret: it lets the phone sign the same watch in to
/// another workspace and remove it when the phone signs out.
class WatchRecord {
  const WatchRecord({
    required this.fingerprint,
    required this.platform,
    required this.name,
    required this.keyId,
    required this.orgId,
    required this.userId,
    this.model,
    this.appVersion,
    this.osVersion,
    this.removal,
  });

  final String fingerprint;
  final WatchSystem platform;
  final String name;
  final String? model;
  final String? appVersion;
  final String? osVersion;
  final String keyId;
  final String orgId;
  final String userId;

  /// Null while the watch is signed in; set once the phone signed out (see [WatchRemoval]).
  final WatchRemoval? removal;

  /// Signed in, as far as this phone knows.
  bool get active => removal == null;

  WatchRecord copyWith({String? keyId, String? orgId, WatchRemoval? removal}) =>
      WatchRecord(
        fingerprint: fingerprint,
        platform: platform,
        name: name,
        model: model,
        appVersion: appVersion,
        osVersion: osVersion,
        keyId: keyId ?? this.keyId,
        orgId: orgId ?? this.orgId,
        userId: userId,
        removal: removal ?? this.removal,
      );

  Map<String, Object?> toJson() => {
    'fingerprint': fingerprint,
    'platform': platform.name,
    'name': name,
    'model': ?model,
    'app_version': ?appVersion,
    'os_version': ?osVersion,
    'key_id': keyId,
    'org_id': orgId,
    'user_id': userId,
    'removal': ?removal?.name,
  };

  static WatchRecord? fromJson(Object? json) {
    if (json is! Map) return null;
    final platform = WatchSystem.parse(json['platform']);
    final fingerprint = json['fingerprint'],
        keyId = json['key_id'],
        orgId = json['org_id'],
        userId = json['user_id'];
    if (platform == null ||
        fingerprint is! String ||
        keyId is! String ||
        orgId is! String ||
        userId is! String) {
      return null;
    }
    return WatchRecord(
      fingerprint: fingerprint,
      platform: platform,
      name: '${json['name'] ?? ''}',
      model: json['model'] as String?,
      appVersion: json['app_version'] as String?,
      osVersion: json['os_version'] as String?,
      keyId: keyId,
      orgId: orgId,
      userId: userId,
      removal: WatchRemoval.parse(json['removal']),
    );
  }
}

/// The watches this phone signed in, in SharedPreferences. Plain Dart so the backend's sign-out can
/// take their keys back while the session still works.
abstract final class WatchKeyStore {
  static const prefKey = 'casama.watch.keys';

  static Future<List<WatchRecord>> load() async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(prefKey);
      if (raw == null) return const [];
      final list = jsonDecode(raw);
      return [
        for (final j in list is List ? list : const [])
          ?WatchRecord.fromJson(j),
      ];
    } catch (_) {
      return const [];
    }
  }

  static Future<void> save(List<WatchRecord> records) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (records.isEmpty) {
        await prefs.remove(prefKey);
      } else {
        await prefs.setString(
          prefKey,
          jsonEncode([for (final r in records) r.toJson()]),
        );
      }
    } catch (_) {}
  }

  /// Adds [record], replacing the one with the same fingerprint.
  static Future<void> upsert(WatchRecord record) async {
    final records = await load();
    await save([
      for (final r in records)
        if (r.fingerprint != record.fingerprint) r,
      record,
    ]);
  }

  /// Forgets the watch whose key is [keyId] (removed in Settings → Watch).
  static Future<void> removeKey(String keyId) async {
    final records = await load();
    if (records.any((r) => r.keyId == keyId)) {
      await save([
        for (final r in records)
          if (r.keyId != keyId) r,
      ]);
    }
  }

  static Future<void> clear() => save(const []);

  /// [userId] is signing out of this phone and the session still works: takes back the keys of
  /// the watches it signed in, with [delete] (which throws when the server didn't delete one).
  /// A record whose key went is marked [WatchRemoval.done]. One whose key couldn't be deleted
  /// (offline, a slow server, a session that had already ended) is left as it was, still signed
  /// in: the watch bridge tells the watches once it sees the sign-out, and keeps that record until
  /// this account is here again (watch_bridge.dart). Marking it here would make it look like a
  /// watch that had been told already. Another account's records are left alone: this session
  /// can't delete their keys.
  static Future<void> signingOut(
    String? userId,
    Future<void> Function(String keyId) delete,
  ) async {
    final records = await load();
    if (!records.any((r) => r.userId == userId)) return;
    final next = <WatchRecord>[];
    for (final r in records) {
      if (r.userId != userId || r.removal == WatchRemoval.done) {
        next.add(r);
        continue;
      }
      try {
        await delete(r.keyId);
        // One still waiting from an earlier sign-out was told then and had only its key left to
        // lose: it is finished. A signed-in one is kept for the bridge to tell.
        if (r.active) next.add(r.copyWith(removal: WatchRemoval.done));
      } catch (_) {
        next.add(r);
      }
    }
    await save(next);
  }

  /// The sign-out [signingOut] prepared for didn't happen, so [userId] is still signed in: the
  /// watches it marked as taken back count as signed in again. One whose key the server did delete
  /// is dropped the next time the bridge checks the list against the server. A record still
  /// waiting from an earlier sign-out stays waiting: its watch was told then.
  static Future<void> signOutFailed(String? userId) async {
    final records = await load();
    bool marked(WatchRecord r) =>
        r.userId == userId && r.removal == WatchRemoval.done;
    if (!records.any(marked)) return;
    await save([
      for (final r in records)
        if (marked(r))
          WatchRecord(
            fingerprint: r.fingerprint,
            platform: r.platform,
            name: r.name,
            model: r.model,
            appVersion: r.appVersion,
            osVersion: r.osVersion,
            keyId: r.keyId,
            orgId: r.orgId,
            userId: r.userId,
          )
        else
          r,
    ]);
  }
}

/// Whether Show details on the watch is settled for a person on this device (§10): the app lock
/// turns it off once, when a watch is signed in or Settings → Watch is first opened with the lock
/// on, and after that it is the person's to change.
abstract final class WatchDetailsSettled {
  static String _key(String userId) => 'casama.watch.details_settled.$userId';

  /// What the first builds kept, once for the whole device, after the first visit to Settings →
  /// Watch. Whoever is signed in when it is next read had that visit: it becomes theirs, so the
  /// app lock doesn't turn Show details off a second time after they turned it back on.
  static const legacyKey = 'casama.watch.details_checked';

  static Future<bool> check(String? userId) async {
    if (userId == null) return false;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_key(userId)) == true) return true;
      if (prefs.getBool(legacyKey) != true) return false;
      await prefs.setBool(_key(userId), true);
      await prefs.remove(legacyKey);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> mark(String? userId) async {
    if (userId == null) return;
    try {
      await (await SharedPreferences.getInstance()).setBool(_key(userId), true);
    } catch (_) {}
  }
}
