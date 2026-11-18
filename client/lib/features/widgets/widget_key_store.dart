import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Which widget key this device holds (D-405 §8.3): its id, and the account, workspace and phone
/// push token it was made for. The key itself never comes here: native code keeps it where only
/// the app and its widgets can read it (the keychain group on Apple devices, an app-private file on
/// Android), so signing out can take it back by id.
class WidgetKeyRecord {
  const WidgetKeyRecord({required this.id, required this.userId, required this.orgId, this.pushToken});

  final String id;
  final String userId;
  final String orgId;

  /// The Android phone's Firebase token registered for this key, if any.
  final String? pushToken;

  Map<String, Object?> toJson() => {'id': id, 'user_id': userId, 'org_id': orgId, 'push_token': ?pushToken};

  static WidgetKeyRecord? fromJson(Object? json) {
    if (json is! Map || json['id'] is! String || json['user_id'] is! String || json['org_id'] is! String) return null;
    return WidgetKeyRecord(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      orgId: json['org_id'] as String,
      pushToken: json['push_token'] as String?,
    );
  }
}

abstract final class WidgetKeyStore {
  static const prefKey = 'casama.widgets.key';

  static Future<WidgetKeyRecord?> load() async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(prefKey);
      return raw == null ? null : WidgetKeyRecord.fromJson(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  static Future<void> save(WidgetKeyRecord record) async {
    try {
      await (await SharedPreferences.getInstance()).setString(prefKey, jsonEncode(record.toJson()));
    } catch (_) {}
  }

  static Future<void> clear() async {
    try {
      await (await SharedPreferences.getInstance()).remove(prefKey);
    } catch (_) {}
  }
}
