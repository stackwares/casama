import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'watch_models.dart';

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

  WatchRecord copyWith({String? keyId, String? orgId}) => WatchRecord(
    fingerprint: fingerprint,
    platform: platform,
    name: name,
    model: model,
    appVersion: appVersion,
    osVersion: osVersion,
    keyId: keyId ?? this.keyId,
    orgId: orgId ?? this.orgId,
    userId: userId,
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
}
