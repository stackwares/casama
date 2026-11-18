/// Casama on the wrist (D-410, docs/WATCH-PLAN.md §6.10, §8.2): the phone's side of watch keys,
/// as `packages/contracts/src/watch.ts` describes them. Hand-written rather than generated: these
/// routes may be newer than the generated client, and the screen needs only a few fields. Named
/// `*View` (and `WatchSystem`, `WatchAllowance`) so they never clash with the generated client's
/// `WatchKey`, `WatchPrefs` and friends once it is regenerated.
///
/// Plain Dart (no Flutter) so the backend interface can use it.
library;

/// Which watch system a watch runs.
enum WatchSystem {
  watchos,
  wearos;

  static WatchSystem? parse(Object? value) => switch (value) {
    'watchos' => watchos,
    'wearos' => wearos,
    _ => null,
  };
}

/// How much a person lets their watches allow (§6.10).
enum WatchAllowance {
  /// Low risk in one tap, medium with a hold (the default).
  medium,
  low,
  none;

  static WatchAllowance parse(Object? value) => switch (value) {
    'low' => low,
    'none' => none,
    _ => medium,
  };
}

DateTime? _time(Object? v) => v is String ? DateTime.tryParse(v) : null;
String? _text(Object? v) => v is String && v.isNotEmpty ? v : null;

/// A signed-in watch as the phone lists it (never its key or fingerprint).
class WatchKeyView {
  const WatchKeyView({
    required this.id,
    required this.orgId,
    required this.platform,
    required this.name,
    required this.createdAt,
    this.model,
    this.appVersion,
    this.osVersion,
    this.pairedBy = 'phone',
    this.hasPush = false,
    this.lastUsedAt,
  });

  final String id;
  final String orgId;
  final WatchSystem platform;
  final String name;
  final String? model;
  final String? appVersion;
  final String? osVersion;

  /// `phone` or `code`.
  final String pairedBy;
  final bool hasPush;
  final DateTime? lastUsedAt;
  final DateTime createdAt;

  factory WatchKeyView.fromJson(Map<String, Object?> j) => WatchKeyView(
    id: '${j['id'] ?? ''}',
    orgId: '${j['org_id'] ?? ''}',
    platform: WatchSystem.parse(j['platform']) ?? WatchSystem.watchos,
    name: '${j['name'] ?? ''}',
    model: _text(j['model']),
    appVersion: _text(j['app_version']),
    osVersion: _text(j['os_version']),
    pairedBy: j['paired_by'] == 'code' ? 'code' : 'phone',
    hasPush: j['has_push'] == true,
    lastUsedAt: _time(j['last_used_at']),
    createdAt:
        _time(j['created_at']) ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
  );
}

/// The person's watch settings, the same for all their watches.
class WatchPrefsView {
  const WatchPrefsView({
    this.allow = WatchAllowance.medium,
    this.showDetails = true,
    this.quickReplies = const [],
  });

  final WatchAllowance allow;

  /// Off: watches show counts and general words only (with the app lock, §10).
  final bool showDetails;

  /// 1 to 6 short answers, each up to [maxQuickReplyLength] characters.
  final List<String> quickReplies;

  static const maxQuickReplies = 6;
  static const maxQuickReplyLength = 40;

  factory WatchPrefsView.fromJson(Map<String, Object?> j) => WatchPrefsView(
    allow: WatchAllowance.parse(j['allow']),
    showDetails: j['show_details'] != false,
    quickReplies: [
      for (final r
          in (j['quick_replies'] is List
              ? j['quick_replies'] as List
              : const []))
        if (r is String) r,
    ],
  );

  WatchPrefsView copyWith({
    WatchAllowance? allow,
    bool? showDetails,
    List<String>? quickReplies,
  }) => WatchPrefsView(
    allow: allow ?? this.allow,
    showDetails: showDetails ?? this.showDetails,
    quickReplies: quickReplies ?? this.quickReplies,
  );
}

/// The watch showing a code, as the phone sees it before allowing it.
class WatchCodeView {
  const WatchCodeView({
    required this.platform,
    required this.name,
    required this.expiresAt,
    this.model,
  });

  final WatchSystem platform;
  final String name;
  final String? model;
  final DateTime expiresAt;

  factory WatchCodeView.fromJson(Map<String, Object?> j) => WatchCodeView(
    platform: WatchSystem.parse(j['platform']) ?? WatchSystem.watchos,
    name: '${j['name'] ?? ''}',
    model: _text(j['model']),
    expiresAt:
        _time(j['expires_at']) ??
        DateTime.now().add(const Duration(minutes: 10)),
  );
}

/// The code as the person typed it ("KQ7M 2XAB", "kq7m-2xab"), as the server reads it, or null
/// when it can't be one: eight letters and digits.
String? normalizeWatchCode(String input) {
  final code = input.toUpperCase().replaceAll(RegExp(r'[^0-9A-Z]'), '');
  return code.length == 8 ? code : null;
}
