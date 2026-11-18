/// The glance (D-405, docs/WIDGETS-PLAN.md §8.1): one small summary of what a person's widgets
/// show, built by the server (`GET /v1/glance`, `packages/contracts/src/glance.ts`). The app reads
/// only what it needs to decide what to write; the rest passes through to native code untouched,
/// so a field the server adds later reaches the widgets without an app update.
///
/// Plain Dart (no Flutter) so the backend interface can use it.
library;

class GlanceData {
  const GlanceData({
    required this.version,
    required this.orgId,
    required this.needsCount,
    required this.private,
    required this.hideReplyText,
    required this.json,
    this.etag,
    this.unchanged = false,
  });

  /// The server's answer to `If-None-Match`: nothing changed since [version].
  const GlanceData.unchanged(this.version)
    : orgId = '',
      needsCount = 0,
      private = false,
      hideReplyText = false,
      json = const {},
      etag = null,
      unchanged = true;

  /// Reads a glance as the server sends it. Missing parts read as empty, never as an error: a
  /// widget showing less beats a widget showing nothing.
  factory GlanceData.fromJson(Map<String, Object?> json, {String? etag}) {
    final needs = json['needs'];
    final flags = json['flags'];
    return GlanceData(
      version: '${json['version'] ?? ''}',
      orgId: '${json['org_id'] ?? ''}',
      needsCount: needs is Map && needs['count'] is num ? (needs['count'] as num).toInt() : 0,
      private: flags is Map && flags['private'] == true,
      hideReplyText: flags is Map && flags['hide_reply_text'] == true,
      json: json,
      etag: etag,
    );
  }

  /// Bumps when anything in it changes.
  final String version;
  final String orgId;

  /// What the Needs you widget counts (approvals, takeovers, suggestions).
  final int needsCount;

  /// Widgets show counts and general words only.
  final bool private;
  final bool hideReplyText;

  /// The whole glance as the server sent it, passed to native code as is.
  final Map<String, Object?> json;

  /// The `ETag` the server answered with, sent back as `If-None-Match`.
  final String? etag;

  /// A 304: the caller's copy is current, and [json] is empty.
  final bool unchanged;
}

/// [glance] made private (§10): counts, bot names and general words stay; anything written by or
/// about the person goes. The same rules the server uses when it sets `flags.private` itself, so
/// a widget never has to strip anything.
Map<String, Object?> privateGlance(Map<String, Object?> glance) {
  List<Object?> each(Object? list, Map<String, Object?> Function(Map<String, Object?>) edit) => [
    for (final item in list is List ? list : const [])
      if (item is Map) edit(Map<String, Object?>.from(item)) else item,
  ];
  final out = Map<String, Object?>.from(glance);
  final needs = out['needs'];
  if (needs is Map) {
    out['needs'] = {
      ...Map<String, Object?>.from(needs),
      'items': each(needs['items'], (n) => {...n, 'text': ''}),
    };
  }
  out['bots'] = each(out['bots'], (b) => {...b, 'step': null, 'last_text': null});
  out['next'] = each(out['next'], (r) => {...r, 'name': ''});
  final brief = out['brief'];
  if (brief is Map) out['brief'] = {...Map<String, Object?>.from(brief), 'text': null};
  out['lately'] = each(out['lately'], (d) => {...d, 'title': ''});
  out['recent'] = each(out['recent'], (c) => {...c, 'title': ''});
  final tasks = out['tasks'];
  if (tasks is Map) {
    out['tasks'] = {
      ...Map<String, Object?>.from(tasks),
      'items': each(tasks['items'], (t) => {...t, 'title': ''}),
    };
  }
  final flags = out['flags'];
  out['flags'] = {...(flags is Map ? Map<String, Object?>.from(flags) : const <String, Object?>{}), 'private': true};
  return out;
}

/// A widget key as the server hands it over once (§8.3): it reads the glance and creation covers
/// and nothing else.
class NewWidgetKey {
  const NewWidgetKey({required this.id, required this.key, this.createdAt});

  factory NewWidgetKey.fromJson(Map<String, Object?> json) => NewWidgetKey(
    id: '${json['id']}',
    key: '${json['key']}',
    createdAt: DateTime.tryParse('${json['created_at']}'),
  );

  final String id;

  /// Shown once; kept where only the app and its widgets can read it, never in the glance store.
  final String key;
  final DateTime? createdAt;
}
