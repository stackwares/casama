/// Gallery v2 (D-315) shapes for chat and workspace controls: the cards a bot shows in chat
/// (`gallery_suggestion`, `gallery_draft`) and the workspace's gallery policy. Every field but the
/// item's kind and id is optional, so older and newer agents both parse.
library;

import 'gallery_models.dart';

Map<String, dynamic>? _map(Object? v) =>
    v is Map ? v.cast<String, dynamic>() : null;

List<String> _strings(Object? v) => [
  for (final s in (v is List ? v : const [])) '$s',
];

/// A part's kind. Message parts name it in `type`; the spec's chat part names it in `kind`.
String? _partKind(Map<String, dynamic> p) =>
    (p['kind'] ?? p['type']) as String?;

/// A card a bot put in its reply (D-315): a gallery item it suggests, or a skill it drafted.
sealed class GalleryChatPart {
  const GalleryChatPart();

  /// Which card this is within its message, for keys and remembering what was done with it.
  String get key;
}

/// "This might help": a gallery item with why the bot thinks so. Add runs the install flow.
class GallerySuggestionPart extends GalleryChatPart {
  const GallerySuggestionPart({
    required this.type,
    required this.id,
    required this.name,
    this.description,
    this.icon,
    this.access,
    this.needs,
    this.reason = '',
  });

  final String type;
  final String id;
  final String name;
  final String? description;
  final String? icon;
  final GalleryAccess? access;
  final GalleryNeeds? needs;
  final String reason;

  @override
  String get key => '$type/$id';

  static GallerySuggestionPart? fromJson(Map<String, dynamic> p) {
    final item = _map(p['item']);
    if (item == null || item['type'] is! String || item['id'] is! String) {
      return null;
    }
    final id = item['id'] as String;
    return GallerySuggestionPart(
      type: item['type'] as String,
      id: id,
      name: item['name'] as String? ?? id,
      description: item['description'] as String?,
      icon: item['icon'] as String?,
      access: GalleryAccess.fromJson(item['access']),
      needs: GalleryNeeds.fromJson(item['needs']),
      reason: p['reason'] as String? ?? '',
    );
  }
}

/// A skill the bot wrote up from the chat ("Make this a skill"): save it or send it to the gallery.
class GalleryDraftPart extends GalleryChatPart {
  const GalleryDraftPart({
    required this.type,
    required this.name,
    this.id,
    this.description = '',
    this.item = const {},
    this.files = const {},
  });

  /// `skill` for now.
  final String type;
  final String name;

  /// The skill id the bot picked (`weekly-report`); see [skillName].
  final String? id;
  final String description;

  /// The item.json fields as the bot drafted them.
  final Map<String, Object?> item;

  /// The folder's files by name (`SKILL.md`).
  final Map<String, String> files;

  @override
  String get key => 'draft/$type/$name';

  /// The name a saved skill gets: the bot's id, else the title as lowercase words joined by dashes.
  String get skillName {
    final from = (id != null && id!.isNotEmpty ? id! : name).toLowerCase();
    final slug = from
        .replaceAll(RegExp(r'[^a-z0-9_-]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^[-_]+|-+$'), '');
    final cut = slug.length > 63 ? slug.substring(0, 63) : slug;
    return cut.isEmpty ? 'skill' : cut;
  }

  /// The instructions without SKILL.md's front matter, or the item's `instructions_md`.
  String get instructions {
    final md = files['SKILL.md'] ?? files.values.firstOrNull;
    if (md != null) return stripFrontMatter(md).trim();
    return '${item['instructions_md'] ?? ''}'.trim();
  }

  static GalleryDraftPart? fromJson(Map<String, dynamic> p) {
    final draft = _map(p['draft']);
    if (draft == null) return null;
    final item = _map(draft['item']) ?? const <String, dynamic>{};
    final name = item['name'] as String? ?? draft['name'] as String?;
    if (name == null || name.trim().isEmpty) return null;
    final files = _map(draft['files']) ?? const <String, dynamic>{};
    return GalleryDraftPart(
      type: draft['type'] as String? ?? 'skill',
      name: name.trim(),
      id: draft['id'] as String? ?? item['id'] as String?,
      description: '${item['description'] ?? draft['description'] ?? ''}'
          .trim(),
      item: Map<String, Object?>.from(item),
      files: {
        for (final e in files.entries)
          if (e.value is String) e.key: e.value as String,
      },
    );
  }
}

/// Markdown with any leading `---` front matter block removed.
String stripFrontMatter(String md) {
  final m = RegExp(r'^\s*---\r?\n[\s\S]*?\r?\n---\s*(\r?\n|$)').firstMatch(md);
  return m == null ? md : md.substring(m.end);
}

/// The gallery cards stored in a message's content parts, in order.
List<GalleryChatPart> galleryPartsOf(Object? content) => content is! List
    ? const []
    : [
        for (final raw in content)
          if (_map(raw) case final Map<String, dynamic> p)
            if (switch (_partKind(p)) {
                  'gallery_suggestion' => GallerySuggestionPart.fromJson(p),
                  'gallery_draft' => GalleryDraftPart.fromJson(p),
                  _ => null,
                }
                case final GalleryChatPart part)
              part,
      ];

/// How a workspace lets members add from the gallery (D-315).
enum GalleryPolicyMode {
  /// Anyone adds anything not blocked.
  open('open'),

  /// Adding asks an admin first, for what [WorkspaceGalleryPolicy.approvalFor] covers.
  approval('approval'),

  /// Only items on the allow list.
  allowlist('allowlist');

  const GalleryPolicyMode(this.value);
  final String value;

  static GalleryPolicyMode of(Object? v) =>
      values.where((m) => m.value == v).firstOrNull ?? GalleryPolicyMode.open;
}

/// The workspace's gallery rules: mode, allow and block lists (item keys `<type>/<id>`), and what
/// asks first in approval mode (`runs_code`, `apps`, `all`).
class WorkspaceGalleryPolicy {
  const WorkspaceGalleryPolicy({
    this.mode = GalleryPolicyMode.open,
    this.allow = const [],
    this.block = const [],
    this.approvalFor = const ['all'],
  });

  final GalleryPolicyMode mode;
  final List<String> allow;
  final List<String> block;
  final List<String> approvalFor;

  WorkspaceGalleryPolicy copyWith({
    GalleryPolicyMode? mode,
    List<String>? allow,
    List<String>? block,
    List<String>? approvalFor,
  }) => WorkspaceGalleryPolicy(
    mode: mode ?? this.mode,
    allow: allow ?? this.allow,
    block: block ?? this.block,
    approvalFor: approvalFor ?? this.approvalFor,
  );

  factory WorkspaceGalleryPolicy.fromJson(Object? j) {
    final m = _map(j) ?? const <String, dynamic>{};
    final p = _map(m['policy']) ?? m;
    return WorkspaceGalleryPolicy(
      mode: GalleryPolicyMode.of(p['mode']),
      allow: _strings(p['allow']),
      block: _strings(p['block']),
      approvalFor: p['approval_for'] is List
          ? _strings(p['approval_for'])
          : const ['all'],
    );
  }

  Map<String, Object?> toJson() => {
    'mode': mode.value,
    'allow': allow,
    'block': block,
    'approval_for': approvalFor,
  };
}
