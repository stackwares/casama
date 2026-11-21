import 'dart:async';
import 'dart:typed_data';

// The generated client's gallery models share names with core/gallery_models.dart (D-315).
import 'package:casama_sdk/casama_sdk.dart' hide GalleryRef, GalleryAccess, GalleryNeeds, GalleryInput, GalleryChange, GalleryStats, GalleryAccessDiff, GalleryInstalledItem, GalleryMissing, GalleryInstallResult, GalleryRequest, GallerySubmission;

import 'gallery_models.dart';
import 'key_providers.dart';
import 'gallery_parts.dart';
import '../features/widgets/glance.dart';
import '../features/watch/watch_models.dart';

export 'gallery_models.dart';
export '../features/widgets/glance.dart';
export '../features/watch/watch_models.dart';
export 'gallery_parts.dart';
export 'key_providers.dart';

/// The six reactions offered first (D-331), in order. The server sends its list (D-372); this one
/// is the fallback (remoteQuickReactions).
const quickReactions = ['👍', '❤️', '😂', '😮', '😢', '👎'];

/// The reactions on a message with one emoji (D-331): how many, whether one is yours, and who.
class ReactionGroup {
  const ReactionGroup({required this.emoji, required this.count, this.mine = false, this.users = const [], this.bots = const []});
  final String emoji;
  final int count;

  /// You reacted with it.
  final bool mine;

  /// People and bots who reacted with it (chat-app senders count but aren't listed).
  final List<String> users;
  final List<String> bots;

  @override
  bool operator ==(Object other) =>
      other is ReactionGroup && other.emoji == emoji && other.count == count && other.mine == mine && _sameList(other.users, users) && _sameList(other.bots, bots);

  @override
  int get hashCode => Object.hash(emoji, count, mine, Object.hashAll(users), Object.hashAll(bots));

  Map<String, Object?> toJson() => {'emoji': emoji, 'count': count, 'mine': mine, 'users': users, 'bots': bots};
  static ReactionGroup fromJson(Map<String, dynamic> j) => ReactionGroup(
    emoji: j['emoji'] as String,
    count: (j['count'] as num?)?.toInt() ?? 1,
    mine: j['mine'] == true,
    users: [for (final u in (j['users'] as List? ?? const [])) '$u'],
    bots: [for (final b in (j['bots'] as List? ?? const [])) '$b'],
  );

  /// Groups single reactions by emoji, most first (ties: the first one added first).
  static List<ReactionGroup> group(Iterable<({String emoji, String? userId, String? botId})> rows, {String? me}) {
    final order = <String>[];
    final count = <String, int>{};
    final mine = <String>{};
    final users = <String, List<String>>{};
    final bots = <String, List<String>>{};
    for (final r in rows) {
      if (!count.containsKey(r.emoji)) order.add(r.emoji);
      count[r.emoji] = (count[r.emoji] ?? 0) + 1;
      if (r.userId case final u?) (users[r.emoji] ??= []).add(u);
      if (r.botId case final b?) (bots[r.emoji] ??= []).add(b);
      if (me != null && r.userId == me) mine.add(r.emoji);
    }
    final sorted = [...order]..sort((a, b) {
      final c = count[b]!.compareTo(count[a]!);
      return c != 0 ? c : order.indexOf(a).compareTo(order.indexOf(b));
    });
    return [
      for (final e in sorted) ReactionGroup(emoji: e, count: count[e]!, mine: mine.contains(e), users: users[e] ?? const [], bots: bots[e] ?? const []),
    ];
  }

  /// [groups] with your reaction set to [emoji] (null removes it): the change shown before the
  /// server answers.
  static List<ReactionGroup> withMine(List<ReactionGroup> groups, String? emoji, {String? me}) {
    final out = <ReactionGroup>[];
    for (final g in groups) {
      if (!g.mine) {
        out.add(g);
        continue;
      }
      if (g.count > 1) out.add(ReactionGroup(emoji: g.emoji, count: g.count - 1, users: [for (final u in g.users) if (u != me) u], bots: g.bots));
    }
    if (emoji == null) return out;
    final at = out.indexWhere((g) => g.emoji == emoji);
    if (at >= 0) {
      final g = out[at];
      out[at] = ReactionGroup(emoji: g.emoji, count: g.count + 1, mine: true, users: [...g.users, ?me], bots: g.bots);
    } else {
      out.add(ReactionGroup(emoji: emoji, count: 1, mine: true, users: [?me]));
    }
    return out;
  }

  /// Your emoji among [groups], if any.
  static String? mineOf(List<ReactionGroup> groups) {
    for (final g in groups) {
      if (g.mine) return g.emoji;
    }
    return null;
  }
}

bool _sameList(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// One reaction with who sent it, for the who-reacted sheet (D-331).
class ReactionPerson {
  const ReactionPerson({required this.emoji, required this.name, this.userId, this.botId, this.avatarUrl});
  final String emoji;
  final String name;
  final String? userId;
  final String? botId;
  final String? avatarUrl;
}

/// Something happened in an open conversation (D-224, D-331): a run started there ([runId]; null
/// after Realtime reconnects), a message's reactions changed ([reactionMessageId]), or a person
/// sent a message there ([messageId], D-413: from another device it may join the run already
/// working, so no run starts to tell this one).
class ConversationActivity {
  const ConversationActivity.run(this.runId) : reactionMessageId = null, messageId = null, changedMessageId = null;
  const ConversationActivity.reaction(String messageId) : runId = null, reactionMessageId = messageId, messageId = null, changedMessageId = null;
  const ConversationActivity.message(String this.messageId) : runId = null, reactionMessageId = null, changedMessageId = null;

  /// A message the server rewrote, or a card it posted (a call's card and its summary).
  const ConversationActivity.changed(String this.changedMessageId) : runId = null, reactionMessageId = null, messageId = null;
  final String? runId;
  final String? reactionMessageId;
  final String? messageId;
  final String? changedMessageId;
  bool get isReaction => reactionMessageId != null;
}

/// A thumbnail of a video, image or PDF on a bot's computer (D-226).
class ComputerThumbnail {
  const ComputerThumbnail({required this.bytes, this.duration, this.modifiedMs});
  final Uint8List bytes;

  /// A video's length, when the computer could read it.
  final Duration? duration;

  /// The file's modified time (ms since the epoch), when known.
  final int? modifiedMs;
}

/// A message as shown in a conversation (final messages only; live text comes from run events).
/// A file attached to a message, stored on the bot's computer ([path] is under its home folder).
class AttachmentRef {
  const AttachmentRef({
    required this.path,
    required this.name,
    required this.mimeType,
    required this.size,
    this.width,
    this.height,
    this.durationS,
  });

  /// A path on the bot's computer, or `media:<id>` for media kept with the chat (served by
  /// [Backend.chatMediaUrl]), such as a generated image or video.
  final String path;
  final String name;
  final String mimeType;
  final int size;

  /// The picture's or video's own size and a clip's length, when known (to reserve space).
  final int? width;
  final int? height;
  final double? durationS;

  bool get isImage => mimeType.startsWith('image/');

  /// Kept with the chat rather than on a computer.
  bool get isChatMedia => path.startsWith('media:');

  /// The chat media id for a `media:` path.
  String? get mediaId => isChatMedia ? path.substring('media:'.length) : null;

  /// A page the bot published (`page:<id>`), shown as a card that opens it; [name] is its title.
  bool get isPage => path.startsWith('page:');

  /// The page id for a `page:` path.
  String? get pageId => isPage ? path.substring('page:'.length) : null;

  Map<String, Object?> toJson() => {
    'path': path,
    'name': name,
    'mime_type': mimeType,
    'size': size,
    if (width != null) 'width': width,
    if (height != null) 'height': height,
    if (durationS != null) 'duration_s': durationS,
  };
  static AttachmentRef fromJson(Map<String, dynamic> j) => AttachmentRef(
    path: j['path'] as String,
    name: j['name'] as String,
    mimeType: j['mime_type'] as String,
    size: (j['size'] as num).toInt(),
    width: (j['width'] as num?)?.toInt(),
    height: (j['height'] as num?)?.toInt(),
    durationS: (j['duration_s'] as num?)?.toDouble(),
  );
}

/// The file parts of a message's content (`{type: "file", path, name, mime_type, size, ...}`),
/// from loaded history and from a live `message.completed`.
List<AttachmentRef> attachmentsOf(Object? content) {
  if (content is! List) return const [];
  return [
    for (final p in content.whereType<Map>())
      if (p['type'] == 'file' && p['path'] is String)
        AttachmentRef(
          path: p['path'] as String,
          name: '${p['name'] ?? (p['path'] as String).split('/').last}',
          mimeType: '${p['mime_type'] ?? ''}',
          size: (p['size'] as num?)?.toInt() ?? 0,
          width: (p['width'] as num?)?.toInt(),
          height: (p['height'] as num?)?.toInt(),
          durationS: (p['duration_s'] as num?)?.toDouble(),
        )
      // A page the bot published during the run: a card under its reply that opens it.
      else if (p['type'] == 'page' && p['page_id'] is String)
        AttachmentRef(
          path: 'page:${p['page_id']}',
          name: '${p['title'] ?? ''}',
          mimeType: 'text/html',
          size: 0,
        ),
  ];
}

/// An app mentioned in a message (`{ type: "app", ... }`, D-434).
class MessageAppMention {
  const MessageAppMention({
    required this.integrationId,
    required this.label,
    this.toolkit,
    this.appId,
    this.source,
  });

  final String integrationId;
  final String label;
  final String? toolkit;
  final String? appId;
  final String? source;

  AppMentionRef toRef() => AppMentionRef(integrationId: integrationId, toolkit: toolkit);

  Map<String, Object?> toJson() => {
    'integration_id': integrationId,
    'label': label,
    if (toolkit != null) 'toolkit': toolkit,
    if (appId != null) 'app_id': appId,
    if (source != null) 'source': source,
  };

  factory MessageAppMention.fromJson(Map<String, dynamic> j) => MessageAppMention(
    integrationId: j['integration_id'] as String? ?? '',
    label: j['label'] as String? ?? '',
    toolkit: j['toolkit'] as String?,
    appId: j['app_id'] as String?,
    source: j['source'] as String?,
  );

  @override
  bool operator ==(Object other) =>
      other is MessageAppMention &&
      other.integrationId == integrationId &&
      other.toolkit == toolkit &&
      other.label == label;

  @override
  int get hashCode => Object.hash(integrationId, toolkit, label);
}

/// Extracts `{ type: "app", ... }` parts from a message's stored content JSON (D-434).
List<MessageAppMention> appMentionsOf(Object? content) {
  if (content is! List) return const [];
  return [
    for (final p in content)
      if (p is Map && p['type'] == 'app' && p['integration_id'] is String && p['label'] is String)
        MessageAppMention(
          integrationId: p['integration_id'] as String,
          label: p['label'] as String,
          toolkit: p['toolkit'] as String?,
          appId: p['app_id'] as String?,
          source: p['source'] as String?,
        ),
  ];
}

/// Where a pack comes from: a GitHub link (with the previewed commit), a reviewed pack from the
/// plugin directory, a shared link, or the files of a pack someone picked.
class PackFrom {
  const PackFrom({this.url, this.commit, this.galleryId, this.shareToken, this.files});
  final String? url;
  final String? commit;
  final String? galleryId;
  final String? shareToken;
  final List<PackFileInput>? files;

  /// The same source pinned to [commit] (what the preview showed).
  PackFrom pinned(String? commit) => PackFrom(
    url: url,
    commit: url == null ? this.commit : (commit ?? this.commit),
    galleryId: galleryId,
    shareToken: shareToken,
    files: files,
  );
}

/// A pack request the server turned down with a reason the app acts on: `pack_installed`,
/// `pack_reach_grew`, `pack_has_secrets`, `pack_not_a_pack` and the like.
class PackError implements Exception {
  const PackError(this.code, this.message, {this.errors = const []});
  final String code;
  final String message;

  /// The problem's `errors`: for `pack_reach_grew` what it adds, for `pack_has_secrets` the lines.
  final List<({String path, String message})> errors;

  @override
  String toString() => message;
}

/// One item from the open gallery (D-184). [document] is the theme, scheme or wallpaper JSON.
class GalleryItem {
  const GalleryItem({
    required this.id,
    required this.type,
    required this.name,
    required this.authorName,
    required this.license,
    this.authorUrl,
    this.tags = const [],
    this.featured = false,
    this.category,
    this.icon,
    this.description,
    this.document,
    this.skillMd,
    this.requires = const [],
    this.version = 1,
    this.retired = false,
    this.added,
    this.updated,
    this.changelog = const [],
    this.pick,
    this.examples = const [],
    this.access,
    this.needs,
    this.inputs = const [],
    this.remixOf,
    this.replacedBy,
    this.minApp,
    this.season,
    this.tested,
    this.source,
    this.stats,
    this.authorHandle,
    this.cover,
  });

  final String id;
  final String type;
  final String name;
  final String authorName;
  final String? authorUrl;
  final String license;
  final List<String> tags;
  final bool featured;
  final String? category;

  /// A skill's Lucide icon name and one-line description.
  final String? icon;
  final String? description;

  /// A look's document (theme, scheme or wallpaper). Lists carry it, so cards draw previews.
  final Map<String, Object?>? document;
  final String? skillMd;

  factory GalleryItem.fromJson(Map<String, dynamic> j) {
    final author = j['author'];
    final authorMap = author is Map
        ? author.cast<String, dynamic>()
        : const <String, dynamic>{};
    final document = j['document'];
    return GalleryItem(
      id: j['id'] as String,
      type: j['type'] as String,
      name: j['name'] as String,
      authorName: authorMap['name'] as String? ?? '',
      authorUrl: authorMap['url'] as String?,
      license: j['license'] as String? ?? '',
      tags: [for (final t in (j['tags'] as List? ?? const [])) '$t'],
      featured: j['featured'] == true,
      category: j['category'] as String?,
      icon: j['icon'] as String?,
      description: j['description'] as String?,
      document: document is Map ? document.cast<String, Object?>() : null,
      skillMd: j['skill_md'] as String?,
      requires: [for (final r in (j['requires'] as List? ?? const [])) '$r'],
      version: (j['version'] as num?)?.toInt() ?? 1,
      retired: j['retired'] == true,
      added: j['added'] as String?,
      updated: j['updated'] as String?,
      changelog: GalleryChange.listOf(j['changelog']),
      pick: j['pick'] as String?,
      examples: [for (final e in (j['examples'] as List? ?? const [])) '$e'],
      access: GalleryAccess.fromJson(j['access']),
      needs: GalleryNeeds.fromJson(j['needs']),
      inputs: [
        for (final i in (j['inputs'] as List? ?? const []))
          if (GalleryInput.fromJson(i) case final GalleryInput input) input,
      ],
      remixOf: GalleryRef.fromJson(j['remix_of']),
      replacedBy: GalleryRef.fromJson(j['replaced_by']),
      minApp: j['min_app'] as String?,
      season: GallerySeason.fromJson(j['season']),
      tested: GalleryTested.fromJson(j['tested']),
      source: j['source'] as String?,
      stats: GalleryStats.fromJson(j['stats']),
      authorHandle: authorMap['handle'] as String?,
      cover: switch (j['cover']) {
        final String c when c.startsWith('https://') => c,
        _ => null,
      },
    );
  }

  // Gallery v2 (D-315). All optional: older servers and catalogs leave them out.
  final int version;
  final bool retired;

  /// `YYYY-MM-DD` the item joined the gallery, and of its latest change.
  final String? added;
  final String? updated;
  final List<GalleryChange> changelog;

  /// Why it's a pick (featured items).
  final String? pick;

  /// Sample prompts to try it with.
  final List<String> examples;
  final GalleryAccess? access;
  final GalleryNeeds? needs;
  final List<GalleryInput> inputs;
  final GalleryRef? remixOf;
  final GalleryRef? replacedBy;

  /// The lowest app version that can use it.
  final String? minApp;
  final GallerySeason? season;
  final GalleryTested? tested;

  /// The extra catalog it came from; null for the default one.
  final String? source;
  final GalleryStats? stats;
  final String? authorHandle;

  /// The item's painted cover picture (gallery `cover.webp`), as an https URL, when it has one.
  final String? cover;

  /// `<type>/<id>`, as stats and installs name it.
  String get key => '$type/$id';

  /// A copy carrying [stats] (from the public stats list).
  GalleryItem withStats(GalleryStats? stats) => GalleryItem(
    id: id,
    type: type,
    name: name,
    authorName: authorName,
    license: license,
    authorUrl: authorUrl,
    tags: tags,
    featured: featured,
    category: category,
    icon: icon,
    description: description,
    document: document,
    skillMd: skillMd,
    requires: requires,
    version: version,
    retired: retired,
    added: added,
    updated: updated,
    changelog: changelog,
    pick: pick,
    examples: examples,
    access: access,
    needs: needs,
    inputs: inputs,
    remixOf: remixOf,
    replacedBy: replacedBy,
    minApp: minApp,
    season: season,
    tested: tested,
    source: source,
    stats: stats,
    authorHandle: authorHandle,
    cover: cover,
  );

  /// What the item needs that older apps couldn't draw, as the gallery's checker worked it out:
  /// `mesh`, `doodles`, `scheme-colors` (D-201).
  final List<String> requires;

  /// What this app draws from the gallery. Items needing anything else are hidden.
  static const supportedFeatures = {'mesh', 'doodles', 'scheme-colors'};

  /// Whether this app can draw the item.
  bool get supported => requires.every(supportedFeatures.contains);
}

class GalleryPage {
  const GalleryPage({required this.available, required this.items});
  final bool available;
  final List<GalleryItem> items;
}

/// An interactive UI a bot showed (D-086): one A2UI surface and the messages that build it.
class UiPart {
  const UiPart({required this.surfaceId, required this.messages});
  final String surfaceId;
  final List<Object?> messages;
}

/// The interactive UIs (A2UI surfaces) stored in a message's content parts.
List<UiPart> uiPartsOf(Object? content) => content is! List
    ? const []
    : [
        for (final p in content.whereType<Map>())
          if (p['type'] == 'ui' &&
              p['surface_id'] is String &&
              p['messages'] is List)
            UiPart(
              surfaceId: p['surface_id'] as String,
              messages: List<Object?>.from(p['messages'] as List),
            ),
      ];

class ChatMessageView {
  const ChatMessageView({
    required this.id,
    required this.role,
    required this.text,
    required this.createdAt,
    this.runId,
    this.attachments = const [],
    this.apps = const [],
    this.ui = const [],
    this.uiActionSurface,
    this.siblingIndex = 1,
    this.siblingCount = 1,
    this.botId,
    this.routineName,
    this.suggestion,
    this.suggestionList = const [],
    this.topic,
    this.gallery = const [],
    this.call,
    this.callId,
  });

  /// A call's card (D-327 §8, call card plan).
  final MessageCall? call;

  /// The live call a spoken turn belongs to: it's shown in that call's card, not as a bubble.
  final String? callId;

  /// Set on the message a routine posts to start its run (D-155): shown as a line, not a bubble.
  final String? routineName;

  /// A suggestion the bot posted in General (D-253), shown as a card with Do it / Not now.
  final MessageSuggestion? suggestion;

  /// Several suggestions in one card (D-257), each with its own Do it.
  final List<MessageSuggestion> suggestionList;

  /// A topic's result posted back to General (D-253), with a link to the topic.
  final MessageTopic? topic;

  /// Gallery cards in a bot's reply (D-315): an item it suggests, or a skill it drafted.
  final List<GalleryChatPart> gallery;

  /// For the offline cache (D-112): text, attachments and versions; bot UIs are left out.
  Map<String, Object?> toJson() => {
    'id': id,
    'role': role,
    'text': text,
    'created_at': createdAt.toIso8601String(),
    'run_id': runId,
    'attachments': [for (final a in attachments) a.toJson()],
    if (apps.isNotEmpty) 'apps': [for (final a in apps) a.toJson()],
    'sibling_index': siblingIndex,
    'sibling_count': siblingCount,
    'bot_id': botId,
    'routine_name': routineName,
    if (suggestion case final s?) 'suggestion': {'id': s.id, 'title': s.title, 'body': s.body},
    if (topic case final t?) 'topic': {'conversation_id': t.conversationId, 'title': t.title},
    if (suggestionList.isNotEmpty) 'suggestions': [for (final s in suggestionList) {'id': s.id, 'title': s.title, 'body': s.body}],
    if (call case final c?) 'call': c.raw,
    'call_id': ?callId,
  };
  static ChatMessageView fromJson(Map<String, dynamic> j) => ChatMessageView(
    id: j['id'] as String,
    role: j['role'] as String,
    text: j['text'] as String? ?? '',
    createdAt: DateTime.parse(j['created_at'] as String),
    runId: j['run_id'] as String?,
    attachments: [
      for (final a in (j['attachments'] as List? ?? const []))
        AttachmentRef.fromJson(a as Map<String, dynamic>),
    ],
    apps: [
      for (final a in (j['apps'] as List? ?? const []))
        MessageAppMention.fromJson(a as Map<String, dynamic>),
    ],
    siblingIndex: (j['sibling_index'] as num?)?.toInt() ?? 1,
    siblingCount: (j['sibling_count'] as num?)?.toInt() ?? 1,
    botId: j['bot_id'] as String?,
    routineName: j['routine_name'] as String?,
    suggestion: switch (j['suggestion']) {
      {'id': final String id, 'title': final String title} && final Map m => MessageSuggestion(id: id, title: title, body: m['body'] as String? ?? ''),
      _ => null,
    },
    suggestionList: [
      for (final i in (j['suggestions'] as List? ?? const []))
        if (i case {'id': final String id, 'title': final String title}) MessageSuggestion(id: id, title: title, body: i['body'] as String? ?? ''),
    ],
    topic: switch (j['topic']) {
      {'conversation_id': final String id, 'title': final String title} => MessageTopic(conversationId: id, title: title),
      _ => null,
    },
    call: j['call'] is Map ? MessageCall.fromContent([j['call']]) : null,
    callId: j['call_id'] as String?,
  );

  final String id;
  final String role;
  final String text;
  final DateTime createdAt;

  /// Its place among edited versions of the same message (D-108).
  final int siblingIndex;
  final int siblingCount;

  /// The bot that wrote it (group chats show it; D-118).
  final String? botId;
  final String? runId;
  final List<AttachmentRef> attachments;

  /// Apps mentioned in this message (D-434).
  final List<MessageAppMention> apps;

  /// Interactive UIs in a bot's reply.
  final List<UiPart> ui;

  /// The bot UI this message answers, when it was sent from one.
  final String? uiActionSurface;
}

/// A suggestion posted in General (D-253).
class MessageSuggestion {
  const MessageSuggestion({required this.id, required this.title, this.body = ''});
  final String id;
  final String title;
  final String body;
}

/// Where a suggestion stands (D-247): still open, done, put away, or past its time.
enum SuggestionStatus { pending, accepted, dismissed, expired }

class SuggestionState {
  const SuggestionState({required this.status, this.resolvedAt, this.conversationId});
  final SuggestionStatus status;
  final DateTime? resolvedAt;

  /// The topic it started, when it was done.
  final String? conversationId;

  bool get open => status == SuggestionStatus.pending;
}

/// A call's card in its chat (D-327 §8, call card plan): how it ended, what it was about, what's
/// left to do, what was done on it, and how many turns its transcript has.
class MessageCall {
  const MessageCall({
    required this.seconds,
    this.tasks = const [],
    this.liveCallId,
    this.kind = 'app',
    this.ended = 'hung_up',
    this.startedAt,
    this.endedAt,
    this.turns = 0,
    this.actions = const [],
    this.summaryStatus = 'skipped',
    this.summary,
    this.steps = const [],
    this.reason,
    this.raw = const {},
  });
  final int seconds;
  final List<MessageCallTask> tasks;
  final String? liveCallId;

  /// app | phone (the bot rang, D-135).
  final String kind;

  /// hung_up | bot_hung_up | dropped | idle | silent | limit | missed | failed.
  final String ended;
  final DateTime? startedAt;
  final DateTime? endedAt;

  /// How many turns the call's transcript has (some may not be loaded yet).
  final int turns;
  final List<MessageCallAction> actions;

  /// pending | ready | skipped | failed.
  final String summaryStatus;
  final String? summary;
  final List<MessageCallStep> steps;

  /// A missed ring: why the bot called.
  final String? reason;

  /// The part as it came, for the offline cache.
  final Map<String, Object?> raw;

  bool get missed => ended == 'missed';
  bool get summaryPending => summaryStatus == 'pending';
  List<MessageCallStep> get openSteps => [for (final s in steps) if (s.state == 'open') s];

  static MessageCall? fromContent(Object? content) {
    if (content is! List) return null;
    for (final p in content) {
      if (p case {'type': 'call', 'seconds': final num seconds}) {
        final tasks = p['tasks'];
        final actions = p['actions'];
        final steps = p['next_steps'];
        final summary = p['summary'];
        return MessageCall(
          seconds: seconds.toInt(),
          raw: Map<String, Object?>.from(p),
          liveCallId: p['live_call_id'] as String?,
          kind: p['kind'] as String? ?? 'app',
          ended: p['ended'] as String? ?? 'hung_up',
          startedAt: DateTime.tryParse(p['started_at'] as String? ?? '')?.toLocal(),
          endedAt: DateTime.tryParse(p['ended_at'] as String? ?? '')?.toLocal(),
          turns: (p['turns'] as num?)?.toInt() ?? 0,
          reason: p['reason'] as String?,
          summaryStatus: summary is Map ? summary['status'] as String? ?? 'skipped' : 'skipped',
          summary: summary is Map ? summary['text'] as String? : null,
          tasks: [
            if (tasks is List)
              for (final t in tasks)
                if (t case {'run_id': final String runId})
                  MessageCallTask(runId: runId, task: t['task'] as String? ?? '', status: t['status'] as String? ?? ''),
          ],
          actions: [
            if (actions is List)
              for (final a in actions)
                if (a case {'run_id': final String runId, 'label': final String label})
                  MessageCallAction(
                    runId: runId,
                    tool: a['tool'] as String? ?? '',
                    label: label,
                    ok: a['ok'] != false,
                    targetKind: (a['target'] as Map?)?['kind'] as String? ?? 'run',
                    targetId: (a['target'] as Map?)?['id'] as String?,
                  ),
          ],
          steps: [
            if (steps is List)
              for (final s in steps)
                if (s case {'id': final String id, 'label': final String label})
                  MessageCallStep(
                    id: id,
                    label: label,
                    task: s['task'] as String? ?? label,
                    doable: s['doable'] == true,
                    state: s['state'] as String? ?? 'open',
                    runId: s['run_id'] as String?,
                  ),
          ],
        );
      }
    }
    return null;
  }
}

/// One job started on a call: its run, the task in the person's words, and how it stood when the
/// call ended.
class MessageCallTask {
  const MessageCallTask({required this.runId, required this.task, required this.status});
  final String runId;
  final String task;
  final String status;
}

/// Something the bot did with a quick tool on a call ("Remembered: …"), and what it opens.
class MessageCallAction {
  const MessageCallAction({
    required this.runId,
    required this.tool,
    required this.label,
    required this.ok,
    required this.targetKind,
    this.targetId,
  });
  final String runId;
  final String tool;
  final String label;
  final bool ok;

  /// memory | routine | task | run.
  final String targetKind;
  final String? targetId;
}

/// A next step from a call's summary; a tap starts it as a chat run.
class MessageCallStep {
  const MessageCallStep({
    required this.id,
    required this.label,
    required this.task,
    required this.doable,
    required this.state,
    this.runId,
  });
  final String id;
  final String label;
  final String task;
  final bool doable;

  /// open | started | dismissed.
  final String state;
  final String? runId;
}

/// A topic's result posted back to General (D-253).
class MessageTopic {
  const MessageTopic({required this.conversationId, required this.title});
  final String conversationId;
  final String title;
}

class SkillView {
  const SkillView({
    required this.id,
    required this.name,
    required this.description,
    required this.bodyMd,
    required this.enabled,
    this.botId,
    this.source = 'manual',
    this.sourceRef = const {},
    this.category,
  });
  final String id;
  final String name;
  final String description;
  final String bodyMd;
  final bool enabled;
  final String? botId;

  /// manual, catalog, github or bot (D-104).
  final String source;
  final Map<String, Object?> sourceRef;

  /// The catalog category it came from (work, writing, …), for its icon.
  final String? category;
}

class NotificationView {
  const NotificationView({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    this.link,
    required this.createdAt,
    this.readAt,
    this.whyRule,
    this.whyData = const [],
    this.urgency,
    this.heldReason,
    this.botId,
    this.conversationId,
    this.runId,
    this.pushStatus,
    this.sender,
    this.channelId,
  });

  /// Hosted mail: sender address and channel id for one-tap Allow on `mail_unknown_sender`.
  final String? sender;
  final String? channelId;

  /// The conversation a reply is in (D-325).
  final String? conversationId;

  /// The run a request (an approval, a takeover) or a reply belongs to.
  final String? runId;

  /// `sent`, `deferred`, `held` or `off` (no push: turned off, or the chat was on screen).
  final String? pushStatus;

  /// A reply-ready or couldn't-finish notice (D-325): read in its chat, not listed in the inbox.
  bool get isReply => kind == 'reply';

  /// The bot it is about, when there is one (per-bot badges in the sidebar).
  final String? botId;

  /// The same notification, read at [at].
  NotificationView read(DateTime at) => NotificationView(
    id: id,
    kind: kind,
    title: title,
    body: body,
    link: link,
    createdAt: createdAt,
    readAt: readAt ?? at,
    whyRule: whyRule,
    whyData: whyData,
    urgency: urgency,
    heldReason: heldReason,
    botId: botId,
    conversationId: conversationId,
    runId: runId,
    pushStatus: pushStatus,
  );

  /// Where tapping it goes: an approval asked in a chat opens that chat, where its card waits;
  /// anything else follows [link].
  String? get openLink {
    final bot = botId, conversation = conversationId;
    if ((kind == 'approval_request' || kind == 'approval') && bot != null && bot.isNotEmpty && conversation != null && conversation.isNotEmpty) {
      return '/bots/${Uri.encodeComponent(bot)}/chat?c=${Uri.encodeQueryComponent(conversation)}';
    }
    return link;
  }

  /// Requests the person answers (approvals, takeovers): counted from the pending list, not as
  /// unread notifications, and marked read on the server once answered anywhere.
  bool get isRequest =>
      kind == 'approval_request' || kind == 'approval' || kind == 'takeover';

  /// Waits on the person: a request, a secret the bot asked for, a link to accept, or anything
  /// sent as urgent. These get the in-app banner when they arrive while the app is open.
  bool get needsAction =>
      isRequest || kind == 'secret' || kind == 'link_exchange' || urgency == 'urgent';

  /// Attention rules (D-153): why a proactive message was sent, and whether it waited for the brief.
  final String? whyRule;
  final List<String> whyData;
  final String? urgency;
  final String? heldReason;
  final String id;
  final String kind;
  final String title;
  final String body;
  final String? link;
  final DateTime createdAt;
  final DateTime? readAt;
}

class RunSummary {
  const RunSummary({
    required this.id,
    required this.status,
    required this.trigger,
    required this.createdAt,
    required this.costUsd,
  });
  final String id;
  final String status;
  final String trigger;
  final DateTime createdAt;
  final double costUsd;
}

/// A run that hasn't ended, as the island's run tracker sees it (D-324): one row of the small
/// query it makes every few seconds while a bot works.
class ActiveRun {
  const ActiveRun({
    required this.id,
    required this.botId,
    required this.status,
    required this.trigger,
    required this.createdAt,
    this.startedAt,
    this.conversationId,
    this.parentRunId,
    this.routineId,
    this.createdBy,
    this.costUsd = 0,
    this.lastSeq = 0,
  });
  final String id;
  final String botId;

  /// queued, running, waiting_approval or waiting_takeover.
  final String status;

  /// What started it: chat, mention, voice, replay and teach are a person; schedule, webhook,
  /// watcher and the rest are automation; subagent and delegation are sub-runs.
  final String trigger;
  final DateTime createdAt;
  final DateTime? startedAt;
  final String? conversationId;

  /// Set on a sub-run (a helper a bot asked), which the island folds into its parent.
  final String? parentRunId;

  /// Set when a routine started it. A routine's run keeps its owner as [createdBy].
  final String? routineId;

  /// The person it runs for; null for runs with nobody behind them.
  final String? createdBy;
  final double costUsd;

  /// The number of its newest event: it changes whenever the run does something.
  final int lastSeq;
}

/// An authenticator app registered for two-step sign-in (D-093).
class TwoStepFactor {
  const TwoStepFactor({
    required this.id,
    required this.name,
    required this.createdAt,
  });
  final String id;
  final String name;
  final DateTime createdAt;
}

/// A new authenticator being set up: scan the QR code (SVG) or type the key, then verify a code.
/// Sign-in methods the server turns on beyond email, Google and Apple.
class AuthMethods {
  const AuthMethods({this.sso = false, this.passkeys = false});
  final bool sso;
  final bool passkeys;
}

/// Changing the password needs a code from the account's email first (the session is old).
class ReauthenticationNeeded implements Exception {
  const ReauthenticationNeeded();
}

/// One of the person's passkeys.
class PasskeyInfo {
  const PasskeyInfo({
    required this.id,
    required this.name,
    required this.createdAt,
    this.lastUsedAt,
  });
  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime? lastUsedAt;
}

class TwoStepEnrollment {
  const TwoStepEnrollment({
    required this.factorId,
    required this.secret,
    required this.uri,
    required this.qrSvg,
  });
  final String factorId;
  final String secret;
  final String uri;
  final String qrSvg;
}

/// Everything the app reads and writes. Reads and simple edits go to Supabase under RLS;
/// commands go to the Casama API. Widget tests use a fake.
/// Quiet hours (D-109): "HH:MM" local times; the window may cross midnight.
class QuietHoursView {
  const QuietHoursView({
    required this.enabled,
    required this.start,
    required this.end,
  });
  final bool enabled;
  final String start;
  final String end;
  Map<String, Object?> toJson() => {
    'enabled': enabled,
    'start': start,
    'end': end,
  };
  static QuietHoursView? fromJson(Object? j) => j is Map
      ? QuietHoursView(
          enabled: j['enabled'] == true,
          start: '${j['start'] ?? '22:00'}',
          end: '${j['end'] ?? '07:00'}',
        )
      : null;
}

/// Which kinds of notification push to this person's devices (D-325). Every kind still lands in
/// the inbox; off only stops the push. Stored as `profiles.push_prefs`, where a missing key is on
/// (and `hide_reply_text` is off).
class PushPrefs {
  const PushPrefs({
    this.replies = true,
    this.needsYou = true,
    this.routines = true,
    this.suggestions = true,
    this.account = true,
    this.hideReplyText = false,
  });
  final bool replies;
  final bool needsYou;
  final bool routines;
  final bool suggestions;
  final bool account;

  /// Reply pushes say "`bot` replied" instead of the reply's words.
  final bool hideReplyText;

  PushPrefs copyWith({bool? replies, bool? needsYou, bool? routines, bool? suggestions, bool? account, bool? hideReplyText}) => PushPrefs(
    replies: replies ?? this.replies,
    needsYou: needsYou ?? this.needsYou,
    routines: routines ?? this.routines,
    suggestions: suggestions ?? this.suggestions,
    account: account ?? this.account,
    hideReplyText: hideReplyText ?? this.hideReplyText,
  );

  Map<String, Object?> toJson() => {
    'replies': replies,
    'needs_you': needsYou,
    'routines': routines,
    'suggestions': suggestions,
    'account': account,
    'hide_reply_text': hideReplyText,
  };

  static PushPrefs fromJson(Object? j) => j is Map
      ? PushPrefs(
          replies: j['replies'] != false,
          needsYou: j['needs_you'] != false,
          routines: j['routines'] != false,
          suggestions: j['suggestions'] != false,
          account: j['account'] != false,
          hideReplyText: j['hide_reply_text'] == true,
        )
      : const PushPrefs();
}

/// About you (D-169): what bots call the person and what the person shared about themselves.
/// Casama's monthly email (D-408): on or off, and whether the app already asked.
class NewsletterChoice {
  const NewsletterChoice({required this.subscribed, required this.asked});
  final bool subscribed;
  final bool asked;
}

class AboutYouView {
  const AboutYouView({
    this.displayName,
    this.preferredName,
    this.pronouns,
    this.about = '',
    this.replyStyle = '',
    this.learn = true,
    this.nameAsked = true,
    this.photoId,
    this.providerPhoto = false,
    this.photoImportTried = true,
  });
  final String? displayName;
  final String? preferredName;
  final String? pronouns;
  final String about;
  final String replyStyle;

  /// Whether bots may save what they learn about the person in chat.
  final bool learn;

  /// The one-time "What should bots call you?" card was answered or dismissed.
  final bool nameAsked;

  /// Profile photo (D-202): the current photo's id (see [Backend.photoUrl]), or null.
  final String? photoId;

  /// Google shared a photo at sign-in that "Use my Google photo" can copy.
  final bool providerPhoto;

  /// The sign-in photo was already copied once, or the person removed their photo.
  final bool photoImportTried;

  /// The name bots use: the preferred name, else the first word of the sign-in name.
  String get name {
    final p = preferredName?.trim() ?? '';
    if (p.isNotEmpty) return p;
    final d = displayName?.trim() ?? '';
    return d.isEmpty ? '' : d.split(RegExp(r'\s+')).first;
  }

  AboutYouView copyWith({
    String? preferredName,
    String? pronouns,
    String? about,
    String? replyStyle,
    bool? learn,
    bool? nameAsked,
  }) => AboutYouView(
    displayName: displayName,
    preferredName: preferredName ?? this.preferredName,
    pronouns: pronouns ?? this.pronouns,
    about: about ?? this.about,
    replyStyle: replyStyle ?? this.replyStyle,
    learn: learn ?? this.learn,
    nameAsked: nameAsked ?? this.nameAsked,
    photoId: photoId,
    providerPhoto: providerPhoto,
    photoImportTried: photoImportTried,
  );
}

/// A fact a bot learned about the person (About you, D-169); private to them.
class UserFactView {
  const UserFactView({
    required this.id,
    required this.kind,
    required this.content,
    this.pinned = false,
    required this.updatedAt,
  });
  final String id;

  /// fact or preference.
  final String kind;
  final String content;
  final bool pinned;
  final DateTime updatedAt;
}

/// One person's quiet-hours choice for one bot: default, always or custom.
class BotQuietView {
  const BotQuietView({required this.mode, this.hours});
  final String mode;
  final QuietHoursView? hours;
}

/// A sidebar folder of bots (D-100).
class BotFolder {
  const BotFolder({required this.id, required this.name, this.sortKey = 0});
  final String id;
  final String name;
  final double sortKey;
}

/// A bot's settings before one change (D-100): what changed, who changed it, and the old values.
class BotRevision {
  const BotRevision({
    required this.id,
    required this.snapshot,
    required this.changedFields,
    this.changedByUser,
    this.changedByBot,
    required this.createdAt,
  });
  final String id;
  final Map<String, Object?> snapshot;
  final List<String> changedFields;
  final String? changedByUser;
  final String? changedByBot;
  final DateTime createdAt;
}

/// Stop was pressed for a run that had already ended: the chat missed its last event.
class RunAlreadyFinished implements Exception {
  const RunAlreadyFinished();
}

/// One page of a whole thread (oldest first), cut the way the server's conversation_thread does:
/// for a server from before paging, and for tests.
List<T> pageOfThread<T>(List<T> all, String Function(T) idOf, {required int limit, String? before, String? around}) {
  var rows = all;
  if (before != null) {
    final i = rows.indexWhere((r) => idOf(r) == before);
    rows = i < 0 ? <T>[] : rows.sublist(0, i);
  }
  var n = limit;
  if (around != null) {
    final i = rows.indexWhere((r) => idOf(r) == around);
    if (i >= 0 && rows.length - i + limit ~/ 2 > n) n = rows.length - i + limit ~/ 2;
  }
  return rows.length > n ? rows.sublist(rows.length - n) : rows;
}

/// Lists the server owner edits as JSON in Admin without a release (D-373, D-374).
enum AdminJsonSettingKind {
  /// Default, small, featured and test models, price rows and image prices.
  modelCatalog('/v1/admin/model-catalog'),

  /// Voice, call, computer and media prices, and what domains are on sale.
  priceTables('/v1/admin/price-tables'),

  /// Sites the browser guard keeps out on top of its own lists.
  browserGuard('/v1/admin/browser-guard'),

  /// Silence, longest call, warnings and ring limits for live calls (D-426).
  callLimits('/v1/admin/call-limits');

  const AdminJsonSettingKind(this.path);
  final String path;
}

/// One of those lists: what's saved (the editable part) and the values in code beside it.
class AdminJsonSetting {
  const AdminJsonSetting({required this.saved, required this.builtIn});
  final Map<String, dynamic> saved;
  final Map<String, dynamic> builtIn;
}

// --- Casama Cloud's waitlist and invite gate (D-427) ---------------------------------------------

/// What a person types on Join the Waitlist (WAITLIST-PLAN §5.2).
class WaitlistJoin {
  const WaitlistJoin({required this.email, this.note, this.selfHosting = false, this.newsletter = false});
  final String email;

  /// "What would you have a bot do first?", one optional line.
  final String? note;
  final bool selfHosting;

  /// A yes to Casama's monthly email; never assumed.
  final bool newsletter;
}

/// How an Apple or Google sign-in with an invite code ended (§7.3).
enum InviteSignInResult {
  /// The code let the address in and the app signed in with the same token.
  signedIn,

  /// The code is real but its invites are gone: the address is on the waitlist, ahead of the line.
  waitlisted,

  /// The person closed the system sheet.
  cancelled,

  /// This device has no system sheet for that provider (the web, Windows, Linux, a Mac build
  /// without the entitlement): the token can't come first, so the email path is the way in.
  unavailable,
}

/// The gate setting as Admin shows it: the generated state plus the daily batch hour, which newer
/// servers send (null on servers that don't).
class AdminSignupGate {
  const AdminSignupGate({required this.state, this.batchHourUtc});
  final SignupGateState state;
  final int? batchHourUtc;

  SignupGate get gate => state.gate;
  bool get closed => state.closed;
}

/// The daily batch's last run, when the server reports one.
class WaitlistLastBatch {
  const WaitlistLastBatch({this.at, this.count, this.skippedDetail});
  final DateTime? at;
  final int? count;

  /// Why the day was skipped (the server's sentence), when it was.
  final String? skippedDetail;
}

/// Admin → Waitlist: the numbers, the gate and a page of entries.
class AdminWaitlist {
  const AdminWaitlist({required this.stats, required this.gate, required this.items, this.lastBatch});
  final WaitlistStats stats;
  final AdminSignupGate gate;
  final List<WaitlistEntry> items;
  final WaitlistLastBatch? lastBatch;
}

/// What [Backend.screenPicture] got.
enum ScreenPictureStatus {
  /// A new picture, in [ScreenPicture.bytes].
  fresh,

  /// The same as the picture with the ETag that was sent.
  unchanged,

  /// The computer sleeps; it wasn't woken.
  asleep,

  /// Awake, but nothing to show (a headless computer with no page open).
  nothing,

  /// Couldn't be fetched this time.
  failed,
}

class ScreenPicture {
  const ScreenPicture(this.status, {this.bytes, this.etag});
  final ScreenPictureStatus status;
  final Uint8List? bytes;
  final String? etag;
}

abstract class Backend {
  // Auth
  Stream<bool> get signedInChanges;
  bool get isSignedIn;
  String? get userEmail;
  String? get userId;
  Future<void> signIn(String email, String password);
  Future<bool> signUp(String email, String password);

  /// Emails a sign-in link that also carries a 6-digit code, for another device or the desktop app.
  Future<void> sendMagicLink(String email);

  /// Signs in with the 6-digit code from a sign-in email.
  Future<void> verifyEmailCode(String email, String code);
  Future<void> signInWithProvider(String provider);
  Future<void> signOut();

  /// What the server offers on the sign-in screen beyond email, Google and Apple.
  Future<AuthMethods> authMethods();

  /// Signs in with a passkey. False when the person closed the system sheet.
  Future<bool> signInWithPasskey();

  /// Checks with one of the person's passkeys that it's them, and leaves the session as it is
  /// (the app lock on the web, D-375). True when the Auth server accepted a passkey of the
  /// signed-in account; false for another account's or a refused one; null when the person closed
  /// the sheet. Throws `PasskeyProblem` when this device has no passkey to offer.
  Future<bool?> confirmWithPasskey();

  /// The admin console's passkey check (D-452): one of the person's passkeys, recorded by the
  /// API on this sign-in session; the session itself stays as it is. When the check was made;
  /// null when the person closed the sheet. Throws when the passkey wasn't this account's or the
  /// server refused it, and `PasskeyProblem` when this device has no passkey to offer.
  Future<DateTime?> adminPasskeyCheck();

  // Passkeys on this account
  Future<List<PasskeyInfo>> passkeys();

  /// Makes a passkey on this device. False when the person closed the system sheet.
  Future<bool> addPasskey();
  Future<void> renamePasskey(String id, String name);
  Future<void> removePasskey(String id);

  // Password and email
  /// Emails a reset link that also carries a 6-digit code.
  Future<void> sendPasswordReset(String email);

  /// Signs in with the code from a reset email; the app then asks for a new password.
  Future<void> verifyPasswordResetCode(String email, String code);

  /// True after a reset link or code until a new password is chosen (or skipped).
  bool get newPasswordNeeded;
  Stream<bool> get newPasswordNeededChanges;
  void skipNewPassword();

  /// Sets or changes the password. Throws [ReauthenticationNeeded] when the session is too old
  /// to change it without a code: [sendReauthenticationCode] emails one, then call again with it.
  Future<void> setPassword(String password, {String? code});
  Future<void> sendReauthenticationCode();

  /// The address waiting for confirmation after [changeEmail], if any.
  String? get pendingEmail;

  /// Starts an email change; both addresses get a confirmation link.
  Future<void> changeEmail(String email);

  /// Signs out this device and every other one, and every watch the person signed in (D-410).
  Future<void> signOutEverywhere();

  /// The server's default model for a provider (GPT-6 Luna on OpenRouter and OpenAI), if any.
  String? defaultModelFor(String provider);

  // Workspaces
  Future<List<OrganizationWithRole>> organizations();
  Future<Organization> createOrganization(String name);
  Future<void> acceptInvite(String token);
  // Spaces (D-099)
  Future<Organization> updateOrg(
    String orgId, {
    String? name,
    String? icon,
    String? color,
    WorkspaceModelDefault? modelDefault,
    bool clearModelDefault = false,
  });
  Future<List<InviteLink>> inviteLinks(String orgId);
  Future<CreatedInviteLink> createInviteLink(
    String orgId, {
    String role = 'member',
    int? expiresInDays,
    int? maxUses,
  });
  Future<void> revokeInviteLink(String orgId, String linkId);
  Future<OrganizationWithRole> acceptInviteLink(String token);
  Future<List<WorkspaceBadge>> workspaceBadges();
  Future<Invite> invite(String orgId, String email, {bool admin = false});
  // Joining (D-165)
  /// The workspace's standing invite link (admins); made on first use.
  Future<CreatedInviteLink> defaultInvite(String orgId);
  Future<CreatedInviteLink> updateDefaultInvite(
    String orgId, {
    bool? requiresApproval,
    bool reset = false,
  });

  /// A short code (XXXX-XXXX) valid for 48 hours.
  Future<CreatedInviteLink> createInviteCode(
    String orgId, {
    String role = 'member',
  });

  /// What a link, code or email invite opens; works signed out.
  Future<InvitePreview> previewInvite(String invite);
  Future<JoinResult> joinWithInvite(String invite);
  Future<List<JoinRequest>> joinRequests(String orgId);
  Future<JoinRequest> decideJoinRequest(
    String orgId,
    String requestId,
    bool approve,
  );
  Future<List<PendingInvite>> pendingInvites(String orgId);
  Future<List<Invite>> inviteMany(
    String orgId,
    List<String> emails, {
    bool admin = false,
  });
  Future<Invite> resendInvite(String orgId, String inviteId);
  Future<void> revokeInvite(String orgId, String inviteId);
  Future<JoinDomains> joinDomains(String orgId);
  Future<JoinDomains> setJoinDomain(
    String orgId,
    bool enabled, {
    String? domain,
  });
  Future<List<JoinableWorkspace>> joinableWorkspaces();
  Future<OrganizationWithRole> joinByDomain(String orgId);

  // Model keys
  Future<List<Credential>> credentials(String orgId);
  Future<Credential> addCredential(
    String orgId,
    ProviderId provider,
    String label, {
    String? apiKey,
    String? baseUrl,
  });
  Future<CredentialTestResult> testCredential(
    String credentialId, {
    String? model,
  });

  /// Models the key can use, recommended first (live from the provider, or Casama's short list).
  Future<ModelOptionList> models(String credentialId);
  Future<Credential> updateCredential(
    String credentialId, {
    String? label,
    bool? fallbackOnLimit,
  });

  /// Deletes a key and its Vault secret; a ChatGPT sign-in is revoked first.
  Future<void> deleteCredential(String credentialId);

  /// Voice features the server's own keys cover (live, read_aloud, dictation): the voice sheet hides
  /// those provider choices, as on Casama Cloud.
  Set<String> get serverVoice;

  /// The model-key providers from the server (D-374): the add-key form's groups and hints, the keys
  /// worth adding on Casama Cloud, and the keys that run chat. The app's own copy for older servers.
  KeyProviders get keyProviders;

  /// Whether workspaces on this server may bring their own model keys and ChatGPT plans
  /// (docs/OWN-KEYS-PLAN.md §6). Always true on self-hosted servers.
  bool get ownProviders;

  // ChatGPT plan sign-in (D-091)
  /// Whether this server lets people connect a ChatGPT plan.
  bool get chatGptSignIn;

  /// Whether this device can run the sign-in (the desktop apps; phones and the web can't).
  bool get canConnectChatGpt;

  /// Opens the browser to sign in with ChatGPT and returns the connected plan.
  Future<Credential> connectChatGpt(String orgId, {String? credentialId});

  // Bots
  Future<List<Bot>> bots(String orgId);

  /// Group chats (D-118).
  Future<List<Conversation>> groupChats(String orgId);
  Future<Conversation> createGroupChat(
    String leadBotId,
    List<String> botIds, {
    String? title,
  });
  /// [followWorkspace] makes the bot follow the workspace's "Who runs your bots" choice instead of
  /// pinning [credentialId] (Casama Cloud with own providers, when nobody picked a key, D-465).
  Future<Bot> createBot(
    String orgId, {
    required String name,
    required String credentialId,
    required String model,
    String persona,
    String? templateId,
    String? avatarUrl,
    bool followWorkspace,
  });
  Future<List<Template>> templates();

  /// [avatarUrl]: `mascot:<name>` for a cloud bot, '' to go back to initials, null to leave it.
  Future<void> updateBot(
    String botId, {
    String? name,
    String? persona,
    String? autonomy,
    Map<String, Object?>? modelPolicy,
    String? avatarUrl,
  });
  Future<UsageReport> usage(String orgId, {String period, UsageFilter filter});

  // Bot pictures (docs/BOT-PICTURES-PLAN.md)
  /// Gives a bot a picture of its own: [square] is the cropped picture, [original] the picture
  /// before cropping (kept for Re-crop) and [crop] where the frame sat on it.
  Future<Bot> setBotPicture(
    String botId,
    Uint8List square, {
    Uint8List? original,
    BotPictureCrop? crop,
    String source = 'upload',
  });

  /// Back to the mascot the bot had before its picture, or its initials.
  Future<Bot> removeBotPicture(String botId);

  /// The bot's recent pictures (the one in use first), or the drawn ones not used yet.
  Future<List<BotPicture>> botPictures(String botId, {bool candidates = false});

  /// Switches to one of [botPictures] (also Undo).
  Future<Bot> useBotPicture(String botId, String imageId);

  /// The picture before it was cropped, for Re-crop.
  Future<Uint8List> botPictureOriginal(String botId, String imageId);

  /// Draws one or two candidates with AI; they don't change the bot until one is used.
  Future<List<BotPicture>> drawBotPictures(
    String botId, {
    required BotPictureStyle style,
    String? description,
    int count = 2,
  });

  /// Where a bot picture is served: 128 px for small avatars, 512 px for big ones.
  String botImageUrl(String imageId, {bool small = false});

  // Workspace pictures (docs/WORKSPACE-PICTURES-PLAN.md)
  Future<Organization> setWorkspacePicture(
    String orgId,
    Uint8List square, {
    Uint8List? original,
    BotPictureCrop? crop,
    String source = 'upload',
  });
  Future<Organization> removeWorkspacePicture(String orgId);
  Future<List<BotPicture>> workspacePictures(String orgId, {bool candidates = false});
  Future<Organization> useWorkspacePicture(String orgId, String imageId);
  Future<Uint8List> workspacePictureOriginal(String orgId, String imageId);
  Future<List<BotPicture>> drawWorkspacePictures(
    String orgId, {
    required BotPictureStyle style,
    String? description,
    int count = 2,
  });
  String workspaceImageUrl(String imageId, {bool small = false});

  /// Workspace search (D-103), including files on awake computers. [kinds] scopes it (D-235):
  /// message, chat, memory, skill, routine, ticket or file; files only when `file` is listed.
  Future<SearchResponse> search(String orgId, String query, {List<String>? kinds});

  // Bot folders, archive and settings history (D-100)
  Future<List<BotFolder>> botFolders(String orgId);

  /// Moves a bot into the named folder (created when new); null takes it out of folders.
  Future<void> setBotFolder(String orgId, String botId, String? folderName);
  Future<List<Bot>> archivedBots(String orgId);
  Future<void> setBotArchived(String botId, bool archived);

  /// Starts (or reruns) the setup interview; returns its conversation (D-105).
  Future<String> startBotSetup(String botId);
  Future<void> skipBotSetup(String botId);
  // Share a bot as a template (D-110)
  Future<BotTemplateFile> exportBot(String botId, {bool memories = false});
  Future<BotShareLink> createBotShare(String botId, {bool memories = false});
  Future<BotTemplateFile> getBotShare(String token);
  Future<ImportBotResponse> importBot(
    String orgId,
    BotTemplateFile template, {
    required String credentialId,
    required String model,
    bool memories = true,
    bool routines = true,
  });
  // Quiet hours (D-109)
  Future<QuietHoursView> quietHours();
  Future<void> setQuietHours(QuietHoursView hours);
  // Which kinds push (D-325)
  Future<PushPrefs> pushPrefs();
  Future<void> setPushPrefs(PushPrefs prefs);
  Future<BotQuietView> botQuiet(String botId);
  Future<void> setBotQuiet(String botId, BotQuietView value);

  /// Whether this bot may phone the signed-in person (D-426); yes unless they turned it off.
  Future<bool> botMayCall(String botId);
  Future<void> setBotMayCall(String botId, bool mayCall);
  // Invite friends (D-211)
  Future<Referral> referral();
  Future<Referral> redeemReferral(String code);
  Future<ReferralPreview> previewReferral(String code);
  // Gift codes for free plans (docs/COMP-PLANS-PLAN.md); redeemed on the web and desktop only.
  Future<CompCodePreview> previewCompCode(String code);
  Future<RedeemedComp> redeemCompCode(String code, String orgId);
  // Reports and blocks (D-301)
  Future<void> report(ReportTarget kind, String targetId, ReportReason reason, {String? note});
  Future<List<BlockedPerson>> blockedPeople();
  Future<void> block(String userId);
  Future<void> unblock(String userId);
  // Admin console: what people reported, in the app and on public links (D-301, D-281)
  Future<List<ContentReport>> adminContentReports({String status = 'open'});

  /// Admin → Domains (SITES-AND-DOMAINS-PLAN §7.16): counts, the registrar balance, orders and domains.
  Future<AdminDomains> adminDomains();
  Future<void> adminSuspendDomain(String id);
  // Hosted bot mail (BOT-EMAIL-PLAN)
  Future<List<AdminMailAddress>> adminMailAddresses();

  /// Mails every workspace sent in the last 24 hours, and the day's ceiling (null: none).
  Future<({int sent, int? ceiling})> adminMailSending();
  Future<AdminMailAddress> setMailAddressStatus(String id, String status);
  Future<List<String>> adminMailReservedNames();
  Future<List<String>> setMailReservedNames(List<String> names);
  // Admin checks (D-452): the owner's 6-digit admin PIN, kept on the server only
  Future<AdminPinState> adminPinState();
  Future<AdminPinState> setAdminPin(String pin);
  Future<AdminPinState> removeAdminPin();
  /// Checks the PIN; the API records it on this sign-in session. When; throws when wrong.
  Future<DateTime> adminPinCheck(String pin);
  // Device keys (D-453): the screen lock as the whole admin check
  Future<List<AdminDeviceKey>> adminDeviceKeys();
  Future<AdminDeviceKey> addAdminDeviceKey(String name, String publicKey);
  Future<List<AdminDeviceKey>> removeAdminDeviceKey(String id);
  /// A one-time challenge for this device's key; null when the server no longer has the key.
  Future<({String id, String challenge})?> adminDeviceChallenge(String keyId);
  /// Sends the signed challenge; the API records the check on this sign-in session. When.
  Future<DateTime> adminDeviceCheck(String challengeId, String signature);
  Future<void> adminUnsuspendDomain(String id);
  Future<DomainOrder> adminRetryDomainOrder(String id);
  Future<DomainOrder> adminApproveDomainOrder(String id);
  Future<void> reviewContentReport(String id, {required bool actioned, bool suspendWorkspace = false});
  Future<List<ReportedCreation>> adminReportedLinks();
  Future<void> takeDownLink(String creationId, bool down);
  // Support ticket log (D-303)
  Future<List<SupportTicketRow>> adminSupportTickets({String status = 'open'});
  Future<SupportWebStats> adminSupportWebStats();
  Future<void> setSupportTicketClosed(String reference, bool closed);
  // Account emails (D-302): tips and news can be turned off
  Future<bool> emailTips();
  Future<void> setEmailTips(bool on);

  /// Monthly gallery picks by email (D-315); null on a server that doesn't send them.
  Future<bool?> emailGalleryDigest();
  Future<void> setEmailGalleryDigest(bool on);

  /// Casama's monthly email (D-408): whether this server sends it (Casama Cloud). False on
  /// self-hosted servers, where the switch, the sign-up box and the card stay hidden.
  bool get newsletterAvailable;

  /// The person's choice; null when this server doesn't send it.
  Future<NewsletterChoice?> newsletter();

  /// Turns it on or off; [subscribed] left out only records that the app asked (the card was
  /// closed). [from]: settings, signup or card.
  Future<NewsletterChoice?> setNewsletter({bool? subscribed, String from = 'settings'});
  // Help & support (D-298)
  /// What this server offers for help; null on a server older than D-298.
  Future<SupportConfig?> supportConfig();
  Future<SupportChatReply> askSupport(SupportChatRequest request);
  Future<SupportTicket> sendSupportTicket(SupportTicketRequest request);
  // About you (D-169)
  Future<AboutYouView> aboutYou();
  Future<void> saveAboutYou(AboutYouView value);
  Future<void> markNameAsked();
  // AI providers (App Store 5.1.2(i), D-421)
  /// When the person agreed that what they share with bots goes to outside AI providers, or null.
  /// Kept in the account, so it follows them to every device.
  DateTime? get aiConsentAt;
  Future<void> setAiConsent(bool allowed);
  // Profile photo (D-202)
  /// Sets the person's photo from a JPEG, PNG or WebP of at most 1 MB.
  Future<AboutYouView> setProfilePhoto(Uint8List bytes, String contentType);
  Future<AboutYouView> removeProfilePhoto();

  /// Copies the Google sign-in photo: once by itself, or again when [replace]d on request.
  Future<AboutYouView> importProfilePhoto({bool replace = false});

  /// Where a profile photo is served, for showing it.
  String photoUrl(String photoId);
  Future<List<UserFactView>> userFacts();
  Future<void> addUserFacts(List<({String kind, String content})> facts);
  Future<void> updateUserFact(String id, {String? content, bool? pinned});
  Future<void> deleteUserFact(String id);

  /// Whether bots in this workspace use "About me" and learned facts (on by default only where the
  /// person is the only member).
  Future<bool> profileSharedIn(String orgId);
  Future<void> setProfileSharedIn(String orgId, bool share);
  Future<List<BotRevision>> botRevisions(String botId);

  /// Puts back the settings from before [revision]; the current ones become a new revision.
  Future<void> restoreBotRevision(String botId, BotRevision revision);

  // Appearance
  /// Whether the server can search wallpaper photos (Unsplash; D-087).
  bool get wallpapersEnabled;

  /// A trace viewer link with {trace_id} in it, when the server has one (D-107).
  String? get traceUrlTemplate;

  /// One run (its status, totals and trace id).
  Future<Run> run(String runId);

  /// What a run and its subruns cost, by what was metered (D-307): the usage line under a reply.
  Future<RunUsage> runUsage(String runId);

  /// Starter requests for an empty chat with a bot, written for this person (D-338).
  Future<ChatStarters> botStarters(String botId);
  Future<List<WallpaperPhoto>> searchWallpapers({String? query, int page = 1});

  /// Tells the photo source a photo was chosen.
  Future<void> trackWallpaperDownload(String downloadLocation);

  // Chat
  Future<List<Conversation>> conversations(String botId);
  Future<Conversation> createConversation(String botId);

  /// Deletes a chat with its messages and media (the person who started it or a bot manager).
  /// Renames a chat (an empty title goes back to the automatic one) or pins it (Improve app 2).
  Future<Conversation> updateConversation(String conversationId, {String? title, bool? pinned});

  /// Deletes a chat; what was made there stays in the Library unless [withCreations] (D-274).
  Future<void> deleteConversation(String conversationId, {bool withCreations = false});

  /// Deletes every direct chat with [botId] this person may delete; returns (deleted, skipped).
  Future<(int, int)> deleteBotConversations(String botId);

  /// The chat's shown branch as a download (D-282): `markdown` (default) or `json`. Only what
  /// this person can see.
  Future<Uint8List> exportConversation(String conversationId, {String format = 'markdown'});

  /// Makes a public read-only link to the chat ([public] true; a new link each time) or stops it
  /// (false). Returns the link, or null when stopped (D-282).
  Future<String?> shareConversation(String conversationId, {required bool public});
  /// The branch being shown, oldest first. With [limit], a page of it (Fix 10): the newest
  /// [limit] messages, the [limit] just before the message [before], or the newest back to the
  /// message [around] and half a page before it (a search hit).
  Future<List<ChatMessageView>> messages(String conversationId, {int? limit, String? before, String? around});
  Future<String?> activeRun(String conversationId);

  /// The newest run a group chat message started (D-118): group messages carry no run id of
  /// their own, the runs point back at them.
  Future<String?> runForMessage(String messageId);

  /// [skills]: skills picked with / in the composer (D-104). [apps]: apps picked with @ in the
  /// composer (D-434). [idempotencyKey]: a UUID for this message, the same on every try, so a
  /// repeat after a lost answer doesn't post it twice.
  Future<SendMessageResponse> send(
    String conversationId,
    String text, {
    List<AttachmentRef> attachments = const [],
    Map<String, Object?>? uiAction,
    List<String> skills = const [],
    List<AppMentionRef> apps = const [],
    String? idempotencyKey,
  });
  /// Asks the run to stop. Throws [RunAlreadyFinished] when it has already ended (or is gone).
  Future<void> cancelRun(String runId);

  /// Edits a sent message: forks there and reruns (D-108).
  Future<SendMessageResponse> editMessage(
    String conversationId,
    String messageId,
    String text, {
    List<AppMentionRef> apps = const [],
  });

  /// Deletes one message; the ones after it join the one before it (Add 11).
  Future<void> deleteMessage(String conversationId, String messageId);

  /// Reactions on these messages (D-331), by message id; messages without any are left out.
  Future<Map<String, List<ReactionGroup>>> reactions(String conversationId, List<String> messageIds);

  /// Sets your reaction to a message, replacing the one you had; returns its reactions.
  Future<List<ReactionGroup>> setReaction(String conversationId, String messageId, String emoji);

  /// Takes your reaction to a message back; returns its reactions.
  Future<List<ReactionGroup>> removeReaction(String conversationId, String messageId);

  /// Everyone who reacted to a message, oldest first, with names (the who-reacted sheet).
  Future<List<ReactionPerson>> reactionPeople(String conversationId, String messageId);

  /// Shows the branch containing [messageId].
  Future<void> switchBranch(String conversationId, String messageId);

  /// A message and its edited versions, oldest first.
  Future<List<String>> messageSiblings(String conversationId, String messageId);
  Stream<RunEventItem> watchRun(String runId, {int afterSeq = 0});
  Future<List<RunEventItem>> runEvents(String runId);
  Future<List<RunSummary>> runs(String botId);

  /// The runs of [botIds] in workspace [orgId] that haven't ended, sub-runs included, newest
  /// first (D-324). The island asks this every few seconds while a bot works, so it stays one
  /// small indexed query.
  Future<List<ActiveRun>> activeRuns(String orgId, List<String> botIds);

  /// A run's events after [afterSeq], oldest first, at most [limit]: enough to say what a run
  /// that no open chat follows is doing now (D-324).
  Future<List<RunEventItem>> runEventsAfter(String runId, int afterSeq, {int limit = 40});

  /// Tells the server where to send a run's live updates while the app is closed (D-324): an
  /// iPhone Live Activity's push token, or an Android phone's push token. [pushToken]: an
  /// iPhone's own Firebase token, which Firebase needs beside the activity's. A server without
  /// live updates ignores it.
  Future<void> registerLiveToken(String runId, String platform, String token, {String? pushToken});

  /// Push-to-start (D-324, Phase 6): where to start a run's live view on this phone when it was
  /// started on another device. [token]: an iPhone's Live Activity push-to-start token (with the
  /// phone's own Firebase token as [pushToken]), or an Android phone's push token. [enabled] false:
  /// the person turned it off on this phone; the row stays, so a shared phone keeps following the
  /// account signed in on it last, not an earlier one.
  Future<void> registerLiveStartToken(String platform, String token, {String? pushToken, bool enabled = true});

  /// This phone's start token goes (signing out).
  Future<void> removeLiveStartToken(String token);

  // Memory and skills
  Future<List<Memory>> memories(String botId);
  Future<void> updateMemory(
    String botId,
    String id, {
    String? content,
    bool? pinned,
  });
  Future<void> deleteMemory(String botId, String id);

  /// A memory written by hand (Improve app 3): [kind] is `fact` or `preference`.
  Future<void> addMemory(String botId, String content, {String kind = 'fact'});
  // Memory backends (D-137)
  Future<MemoryBackend> memoryBackend(String orgId);
  Future<MemoryBackend> setMemoryBackend(
    String orgId,
    SetMemoryBackendRequest request,
  );
  Future<MemoryBackend> removeMemoryBackend(String orgId);
  Future<List<SkillView>> skills(String orgId);
  Future<void> saveSkill(
    String orgId, {
    String? id,
    String? botId,
    required String name,
    required String description,
    required String bodyMd,
    bool enabled = true,
  });
  Future<void> deleteSkill(String id);
  // Skills library (D-104)
  Future<SkillCatalog> skillCatalog();
  Future<void> installCatalogSkill(
    String orgId,
    String catalogId, {
    String? botId,
  });
  // Gallery (D-184)
  Future<GalleryPage> gallery({String? type, String? query});
  Future<GalleryItem> galleryItem(String type, String id);
  Future<void> installGallerySkill(
    String orgId,
    String galleryId, {
    String? botId,
  });

  // Gallery v2 (D-315)
  /// Every kind in one list (looks, skills, apps, bots, routines, plugins and sets). Servers older
  /// than D-315 answer with looks and skills only.
  Future<GalleryPage> galleryEverything();

  /// Public use numbers by `<type>/<id>`; empty when the server shares none.
  Future<Map<String, GalleryStats>> galleryStats();

  /// Counts a look applied on this device (best effort).
  Future<void> galleryUsed(String type, String id);

  /// Installs any kind with its answers; skills it needs come along, apps come back as missing.
  /// Throws [GalleryInputsInvalid] when the server turns answers down.
  Future<GalleryInstallResult> installGalleryItem(
    String orgId,
    String type,
    String id, {
    Map<String, String>? inputs,
    String? botId,
  });
  /// Installs a starter set; [botId] is where its routines and plugins go (else the bot the
  /// set brings, else they're skipped). Its looks come back `device`, for the app to apply.
  Future<GalleryInstallResult> installGallerySet(
    String orgId,
    String id, {
    String? botId,
  });
  Future<List<GalleryInstalledItem>> galleryInstalled(String orgId);

  /// Throws [GalleryAccessChanged] when the update asks first and [acceptAccess] is false.
  Future<void> updateGalleryInstalled(
    String orgId,
    String type,
    String id, {
    bool acceptAccess = false,
  });
  Future<void> removeGalleryInstalled(String orgId, String type, String id);

  /// The requests board, `top` or `new` first.
  Future<List<GalleryRequest>> galleryRequests({String sort = 'top'});

  /// A new request, or the existing one with a similar title.
  Future<GalleryRequest> createGalleryRequest({
    required String kind,
    required String title,
    String? details,
  });
  Future<void> voteGalleryRequest(String id, {required bool vote});

  /// Sends an item to the gallery; the server opens a pull request. Returns where it stands.
  Future<GallerySubmission> submitToGallery({
    required String type,
    String? id,
    required Map<String, Object?> item,
    required Map<String, String> files,
    GalleryRef? remixOf,
  });
  Future<List<GallerySubmission>> gallerySubmissions();

  /// The person's merged gallery items with their full numbers.
  Future<List<GalleryMyItem>> galleryMyItems();

  /// The gallery's starter sets (D-315), as items of type `set`; empty when the server has none.
  Future<List<GalleryItem>> gallerySets();

  /// The workspace's gallery rules (D-315); admins and owners change them.
  Future<WorkspaceGalleryPolicy> galleryPolicy(String orgId);
  Future<WorkspaceGalleryPolicy> setGalleryPolicy(String orgId, WorkspaceGalleryPolicy policy);

  /// Adds waiting on an admin's yes (D-315): admins see everyone's, members their own.
  Future<List<WorkspaceGalleryApproval>> galleryApprovals(
    String orgId, {
    String? status,
  });

  /// Approves (the install runs) or declines an add that waits.
  Future<WorkspaceGalleryApproval> decideGalleryApproval(
    String approvalId, {
    required bool approve,
  });
  Future<GitHubSkillPreview> previewGitHubSkill(String orgId, String url);
  Future<void> installGitHubSkill(
    String orgId,
    String url,
    String commit, {
    String? botId,
  });
  Future<SkillUpdateCheck> checkSkillUpdate(String skillId);
  Future<void> applySkillUpdate(String skillId, String commit);

  // Approvals and notifications
  Future<List<Approval>> approvals(String orgId, {bool pendingOnly = true});
  Future<Approval> decideApproval(
    String approvalId, {
    required bool approve,
    bool alwaysAllow = false,
  });
  Future<List<NotificationView>> notifications();
  Future<void> markNotificationsRead();
  Future<void> markNotificationRead(String id);

  /// New notifications for the signed-in user, live.
  Stream<NotificationView> watchNotifications();

  /// One event each time the workspace's bots change on any device (added, renamed, archived,
  /// moved, deleted, a status change), and after Realtime reconnects (D-225). No details: the
  /// listener refetches its list.
  Stream<void> watchBotsChanged(String orgId);

  /// What happens in this conversation from any device or trigger: a run starting (D-224; its id,
  /// or null after Realtime reconnects, when something may have happened meanwhile) or a
  /// message's reactions changing (D-331).
  Stream<ConversationActivity> watchConversation(String conversationId);
  Future<void> registerDevice(String platform, String token);

  /// The chat on screen on this install, or null (D-325): replies to it don't push to any of the
  /// person's devices. [clientId] names this install; the server ignores a focus after 45 s.
  Future<void> setChatFocus(String clientId, String? conversationId);

  // Routines
  Future<List<Routine>> routines(String botId);
  Future<CreatedRoutine> createRoutine(
    String botId, {
    required String name,
    required String instructions,
    required String trigger,
    String? cron,
    String? timezone,
    DateTime? runAt,
    CalendarTriggerConfig? calendar,
    MessageTriggerConfig? message,
    DateTime? endsAt,
    int? maxRuns,
  });
  Future<void> setRoutineEnabled(String routineId, bool enabled);

  /// When a repeating or event routine ends on its own (D-262): at [endsAt], after [maxRuns] more
  /// runs, both, or (both null) never.
  Future<void> setRoutineEnd(String routineId, {DateTime? endsAt, int? maxRuns});
  Future<void> deleteRoutine(String routineId);
  Future<String> runRoutine(String routineId);

  /// Changes what a routine does and when (D-262's full update): only the fields given change.
  Future<void> updateRoutine(String routineId, {String? name, String? instructions, String? scheduleCron, String? timezone, DateTime? runAt});

  /// A routine's latest runs, newest first.
  Future<List<RunSummary>> routineRuns(String routineId);

  // Integrations and secrets
  Future<List<Integration>> integrations(String orgId);
  Future<Integration> createIntegration(
    String orgId, {
    required String kind,
    required String name,
    required Map<String, Object?> config,
    String? secret,
  });
  Future<IntegrationTestResult> testIntegration(String integrationId);
  Future<Set<String>> botIntegrationIds(String botId);
  Future<void> setBotIntegration(
    String botId,
    String integrationId,
    bool enabled,
  );

  // Built-in apps (D-089)
  Future<AppCatalog> appCatalog();

  /// Connects an app: done at once with an API key, or a sign-in to open for OAuth.
  Future<ConnectAppResponse> connectApp(
    String orgId, {
    required String appId,
    required String method,
    String? apiKey,
    String? integrationId,
    // Signing in from the sign-in sheet: the server ends on casama-auth://done so the sheet closes.
    bool returnToApp = false,
  });
  Future<ConnectFlowStatus> connectStatus(String flowId);
  Future<void> deleteIntegration(String integrationId);
  Future<Integration> setToolRisks(
    String integrationId,
    Map<String, String> risks,
  );
  Future<List<ProviderApp>> providerApps(String integrationId, {String? query});
  Future<String> connectProviderApp(String integrationId, String app, {bool returnToApp = false});
  Future<List<ProviderAccount>> providerAccounts(String integrationId);
  Future<List<Secret>> secrets(String orgId);

  /// [totp]: a sign-in code seed (otpauth:// link or base32 key) bots use as {{totp:NAME}} (D-102).
  Future<void> createSecret(
    String orgId, {
    required String name,
    required String value,
    required List<String> hosts,
    bool totp = false,
  });
  Future<void> deleteSecret(String secretId);

  // Task board
  Future<List<Task>> tasks(String orgId, {String? projectId});
  // Hosted MCP (D-117)
  Future<McpAuthRequestInfo> mcpAuthRequest(String id);
  Future<String> decideMcpAuthRequest(
    String id, {
    required String orgId,
    required bool approve,
  });
  Future<List<McpKey>> mcpKeys(String orgId);
  Future<CreatedMcpKey> createMcpKey(String orgId, String name);
  Future<void> revokeMcpKey(String orgId, String keyId);
  /// AI apps connected with OAuth: the caller's own, or everyone's for admins.
  Future<List<McpConnection>> mcpConnections(String orgId);
  /// Disconnects an app at once ([userId]: whose; default the caller's own).
  Future<void> revokeMcpConnection(String orgId, String clientId, {String? userId});
  Future<bool> mcpDecideApprovals(String orgId);
  Future<void> setMcpDecideApprovals(String orgId, bool allowed);
  // Full access switch (D-394)
  Future<bool> fullAccess(String orgId);
  Future<void> setFullAccess(String orgId, bool on);
  // Bot-to-bot switch (D-133)
  Future<bool> allowBotToBot(String orgId);
  // Secret store (D-145)
  Future<SecretStoreSettings> secretStore(String orgId);
  Future<SecretStoreSettings> setSecretStore(
    String orgId,
    SetSecretStoreRequest request,
  );
  Future<SecretStoreSettings> removeSecretStore(String orgId);
  // Linked agents (D-143)
  Future<List<BotLink>> botLinks(String botId);
  Future<CreatedBotLink> createBotLink(String botId, String name);
  Future<BotLink> acceptBotLink(String invite, String botId, String name);
  Future<BotLink> revokeBotLink(String id);
  Future<List<LinkExchange>> linkExchanges(String id);
  // Payments (D-142)
  Future<PaymentSettings> paymentSettings(String orgId);
  Future<PaymentSettings> setPaymentSettings(
    String orgId,
    SetPaymentSettingsRequest request,
  );
  Future<PaymentSettings> removePaymentSettings(String orgId);
  Future<List<PaymentRequest>> paymentRequests(String orgId);
  // Calls for you (D-141)
  Future<TelephonySettings> telephony(String orgId);
  Future<TelephonySettings> setTelephony(
    String orgId,
    SetTelephonyRequest request,
  );
  Future<TelephonySettings> removeTelephony(String orgId);
  Future<OutboundCall> outboundCall(String id);
  Future<OutboundCall> endOutboundCall(String id);
  Future<OutboundCall> takeOverOutboundCall(String id, {String? phone});
  // Agent-to-agent (D-140)
  Future<bool> a2aEnabled(String orgId);
  Future<void> setA2aEnabled(String orgId, bool enabled);

  /// Casama for Chrome (D-323): whether members may use the extension, and whether bots may work
  /// in members' own browsers (Act).
  Future<({bool extension, bool act})> chromeSettings(String orgId);
  Future<void> setChromeSettings(String orgId, {bool? extension, bool? act});
  Future<BotA2a> botA2a(String botId);
  Future<BotA2a> setBotA2a(String botId, bool published);
  // Encryption at rest (D-136)
  Future<EncryptionStatus> encryption(String orgId);
  Future<EncryptionStatus> setEncryption(String orgId, bool enabled);
  Future<EncryptionStatus> rotateEncryptionKey(String orgId);
  Future<void> setAllowBotToBot(String orgId, bool allowed);
  // Bot sharing (D-131)
  Future<BotAccess> botAccess(String botId);
  Future<BotAccess> setBotAccess(String botId, SetBotAccessRequest request);
  Future<List<WorkspaceMember>> members(String orgId);
  // Welcome chat (D-129)
  Future<WelcomeChat> startWelcome({String? firstName});
  // Password managers (D-128)
  Future<List<PasswordManager>> passwordManagers(String orgId);
  Future<PasswordManager> connectPasswordManager(
    CreatePasswordManagerRequest request,
  );
  Future<List<PasswordManagerVault>> passwordManagerVaults(String id);
  Future<void> setPasswordManagerVaults(String id, List<String> vaults);
  Future<void> deletePasswordManager(String id);
  // Step replay (D-127)
  Future<List<Replay>> replays(String botId);
  Future<RunReplayResponse> runReplay(String id, Map<String, String> params);
  Future<void> deleteReplay(String id);
  Future<Replay> replayFromTeach(
    String teachId,
    String name, {
    String? description,
  });
  // Self-improving skills (D-126)
  Future<List<SkillProposal>> skillProposals(String orgId, {String? botId});
  Future<void> acceptSkillProposal(String id, {String? bodyMd});
  Future<void> dismissSkillProposal(String id);
  Future<SkillStats> skillStats(String skillId);
  // Knowledge sources (D-125)
  Future<List<KnowledgeSource>> knowledgeSources(String orgId, {String? botId});
  Future<KnowledgeSource> addKnowledgeSource(
    CreateKnowledgeSourceRequest request,
  );
  Future<void> resyncKnowledgeSource(String id);
  Future<void> deleteKnowledgeSource(String id);
  // Chat apps (D-134)
  Future<List<Channel>> channels(String botId);
  Future<Channel> createChannel(CreateChannelRequest request);
  Future<Channel> updateChannel(
    String id, {
    String? name,
    List<String>? allowedSenders,
    bool? enabled,
  });
  Future<void> deleteChannel(String id);
  Future<List<ChannelEvent>> channelEvents(String id);
  // Hosted bot mail (BOT-EMAIL-PLAN)
  Future<MailAddress?> mailAddress(String botId);
  Future<MailAddress> claimMailAddress(String botId, String name, {String surface = 'profile'});
  Future<MailNameAvailability> checkMailName(String botId, String name);
  Future<MailAddress> updateMailAddress(String botId, {String? status, bool? notifyNewSenders});
  Future<MailAddress> moveMailAddress(String botId, String toBotId);
  Future<MailAddress> releaseMailAddress(String botId);
  Future<MailMessageList> mailMessages(
    String botId, {
    String? verdict,
    String? tag,
    String? sender,
    String? q,
    int? limit,
    String? cursor,
  });
  Future<MailMessageDetail> mailMessage(String botId, String messageId);
  Future<Uint8List> downloadMailFile(String botId, String messageId, int index);
  Future<MailAddress> blockMailSender(String botId, String sender);
  Future<MailAddress> unblockMailSender(String botId, String sender);

  /// Deletes kept mail (BOT-EMAIL-NEXT-PLAN §3.3): one mail, several by id, or everything that
  /// arrived or went out before [before]. Its text, original and files go.
  Future<DeleteMailMessagesResult> deleteMail(String botId, {List<String>? ids, DateTime? before});

  /// Slack's sign-in address for adding Casama's Slack app to a Slack workspace for [botId]
  /// (D-277), or null when this server has no Slack app (409).
  Future<String?> slackInstallUrl(String botId);
  // Routines and skills as files (D-124)
  Future<Uint8List> exportWorkspaceFiles(String orgId);
  Future<WorkspaceFilesResult> importWorkspaceFiles(
    String orgId,
    Uint8List zip, {
    bool dryRun = false,
  });
  Future<GitSyncStatus> gitSync(String orgId);
  Future<GitSyncStatus> setGitSync(
    String orgId, {
    required String repo,
    String? branch,
    String? path,
    bool enabled = true,
  });
  Future<GitSyncStatus> runGitSync(String orgId);
  Future<GitSyncStatus> deleteGitSync(String orgId);
  // Import an agent (D-122)
  Future<AgentImportPlan> startAgentImport(
    String orgId, {
    Uint8List? zip,
    Map<String, Uint8List>? files,
  });
  Future<int> writeAgentImportFiles(String importId, String botId);
  // Paste a bot's setup (D-415)
  Future<String> pasteImportPrompt(PasteImportSource source);
  Future<AgentImportPlan> pasteBotImport(String orgId, PasteImportSource source, String text);
  Future<String> memoryImportPrompt();
  Future<List<ImportedMemoryItem>> parseMemoryImport(String text);
  Future<int> saveImportedMemories(
    String botId,
    List<ImportedMemoryItem> memories,
  );
  // Plugins (D-121)
  Future<List<Plugin>> plugins(String botId);
  /// [commit]: preview that commit (a reviewed one from the plugin directory) instead of the latest.
  Future<PluginPreview> previewPlugin(String orgId, String url, {String? commit});

  /// Reviewed plugins from the open gallery, each pinned to its reviewed commit (D-241).
  Future<List<DirectoryPlugin>> pluginDirectory();

  /// Routine ideas from the open gallery, to fill in a new routine (D-241).
  Future<List<RoutineIdea>> routineIdeas();

  /// The server owner's remote settings: minimum versions, maintenance, announcements, flags (D-241).
  Future<RemoteAppConfig> appConfig();

  /// The remote settings as the owner edits them, and replacing them (owner only, D-241).
  Future<RemoteAppConfig> adminAppConfig();
  Future<RemoteAppConfig> setAdminAppConfig(Map<String, dynamic> settings);

  /// The gallery's content lists: search words and empty-state starters (D-372).
  Future<GalleryLists> galleryLists();

  /// The words of the welcome emails and gallery digest, and replacing them (owner only, D-372).
  Future<EmailCopySettings> adminEmailCopy();
  Future<EmailCopySettings> setAdminEmailCopy(Map<String, dynamic> copy);

  /// A list the owner edits as JSON (owner only, D-373, D-374). The server checks a save in full
  /// and refuses it with what's wrong.
  Future<AdminJsonSetting> adminJsonSetting(AdminJsonSettingKind kind);
  Future<AdminJsonSetting> saveAdminJsonSetting(AdminJsonSettingKind kind, Map<String, dynamic> value);
  /// [deviceId]: run its stdio servers on this paired computer of the person's own instead of
  /// the bot's computer (D-344).
  Future<Plugin> installPlugin(
    String orgId,
    String botId,
    String url,
    String commit,
    Map<String, String> secrets, {
    String? deviceId,
  });
  Future<PluginUpdatePreview> pluginUpdate(String id);
  Future<Plugin> updatePlugin(
    String id,
    String commit, {
    Map<String, String> secrets = const {},
  });
  Future<void> uninstallPlugin(String id);

  /// A plugin's plain settings (not secret), changed later (docs/PLUGINS-AND-PACKS-PLAN.md F.34).
  Future<Plugin> updatePluginSettings(String id, Map<String, String> settings);

  // Packs (docs/PLUGINS-AND-PACKS-PLAN.md): bots, skills, routines, apps and looks in one plugin.
  /// Everything a pack would add, before anything is created. Throws [PackError] (for example
  /// `pack_not_a_pack`).
  Future<PackPreview> previewPack(String orgId, PackFrom from);

  /// Installs a pack pinned to the previewed commit. A result with status `approval_pending`
  /// waits for an admin. Throws [GalleryInputsInvalid] for answers the server turns down and
  /// [PackError] `pack_installed` when the workspace already has it.
  Future<PackInstallResult> installPack(
    String orgId,
    PackFrom from, {
    List<PackItemRef> skip = const [],
    Map<String, String>? inputs,
    Map<String, String>? secrets,
    Map<String, String>? settings,
    String? botId,
    /// Run the pack's plugin tools on this computer of the person's own (D-344).
    String? deviceId,
  });
  Future<List<Pack>> packs(String orgId);
  Future<Pack> pack(String id);

  /// What a newer version changes, item by item.
  Future<PackUpdatePreview> packUpdate(String id);

  /// Throws [PackError] `pack_reach_grew` when the update reaches further and [confirmReach] is
  /// false.
  Future<PackInstallResult> updatePack(
    String id,
    String commit, {
    List<PackItemRef> takeTheirs = const [],
    bool confirmReach = false,
    Map<String, String>? secrets,
    Map<String, String>? settings,
  });

  /// Removes a pack; returns how many items stayed because they were edited.
  Future<int> removePack(String id, {bool deleteBots = false});

  /// A pack's files made from this workspace, with lines that look like keys.
  Future<PackExport> exportPack(String orgId, ExportPackRequest request);

  /// A link to a pack made from this workspace. Throws [PackError] `pack_has_secrets` when lines
  /// look like keys and `ignoreFindings` isn't set.
  Future<PackShare> sharePack(String orgId, SharePackRequest request);
  Future<PackShareView> packShare(String token);
  Future<void> revokePackShare(String token);

  /// The Packs shelf: reviewed packs and starter sets.
  Future<List<GalleryPack>> galleryPacks();
  // Teach a task by showing it (D-120)
  Future<TeachSession> startTeach(String computerId, String botId);
  Future<TeachSession> teach(String id);
  Future<TeachStep> addTeachStep(String id, AddTeachStepRequest step);
  Future<TeachStep> markTeachSecret(String id, int seq, String name);
  Future<TeachSession> stopTeach(String id);
  Future<SaveTeachResponse> saveTeach(
    String id, {
    required String name,
    required String description,
    required String body,
    bool tryNow = false,
  });
  Future<void> cancelTeach(String id);
  // Pages (D-119): opened in the system browser, never embedded.
  Future<List<BotPage>> pages(String orgId, {String? botId});
  Future<String> pageViewLink(String id, {bool pdf = false});

  /// Returns the new public link when made public.
  Future<String?> setPageVisibility(
    String id,
    BotPageVisibilityEnum visibility, {
    int? expiresInDays,
  });
  Future<void> deletePage(String id);
  // Sites (SITES-AND-DOMAINS-PLAN §7.16): a page at its own web address.
  /// The server's sites settings; null or a null zone when it has no site addresses.
  SitesConfig? get sitesConfig;

  /// The workspace's published sites.
  Future<List<Site>> sites(String orgId);

  /// Whether an address name is free, and the server's words when it isn't.
  Future<SiteAddressCheck> checkSiteAddress(String orgId, String label);

  /// Publishes a page at [label], or changes a published site (search engines).
  Future<Site> publishSite(String pageId, {String? label, bool? indexable});

  /// Takes the page off every address it has.
  Future<void> unpublishSite(String pageId);

  // Domains (SITES-AND-DOMAINS-PLAN §7.3–§7.5, §7.16): a domain the workspace owns, on a site.
  /// The workspace's domains.
  Future<List<Domain>> domains(String orgId);

  /// Connects [name] (bakery.com, www.bakery.com or shop.bakery.com), optionally showing the
  /// site of [pageId]. Answers the domain, or the claim record to add when another workspace
  /// proved it first.
  Future<ConnectDomainResult> connectDomain(String orgId, String name, {String? pageId});

  /// One domain, with what DNS shows for each record and its history.
  Future<Domain> domain(String id);

  /// Looks at the domain's DNS now (the server answers 429 within 10 seconds of the last look).
  Future<Domain> checkDomain(String id);

  /// Shows the site of [pageId] on the domain; null shows none.
  Future<Domain> setDomainSite(String id, String? pageId);

  /// Makes [hostname] the host visitors land on; it must be live.
  Future<Domain> setDomainPrimaryHost(String id, String hostname);

  /// Disconnects the domain from the workspace.
  Future<void> deleteDomain(String id);

  // Buying and keeping a domain (SITES-AND-DOMAINS-PLAN §7.7–§7.10).
  /// Names for [q] with availability and prices.
  Future<DomainSearchList> searchDomains(String orgId, String q);

  /// The workspace's registrant details, and the email to start from when there are none.
  Future<DomainContactState> domainContact(String orgId);

  /// Saves the workspace's registrant details (a 400 says which field is wrong).
  Future<DomainContactState> saveDomainContact(String orgId, DomainContact contact);

  /// Starts buying [name]: a checkout URL to open, or none when the saved payment method was charged.
  Future<DomainCheckoutResult> domainCheckout(
    String orgId,
    String name, {
    String? pageId,
    bool autoRenew = true,
  });

  /// One domain order, to follow it to the end.
  Future<DomainOrder> domainOrder(String id);

  /// Turns **Renew automatically** on or off.
  Future<Domain> setDomainAutoRenew(String id, bool autoRenew);

  /// Locks a bought domain again after a transfer code was issued.
  Future<Domain> lockDomain(String id);

  /// Renews a bought domain for a year: a checkout URL, or none when it was charged.
  Future<DomainCheckoutResult> renewDomain(String id);

  /// A bought domain's DNS records, read live from the registrar.
  Future<List<DnsRecordItem>> domainRecords(String id);
  Future<DnsRecordItem> addDomainRecord(String id, DnsRecordInput record);
  Future<DnsRecordItem> updateDomainRecord(String id, String recordId, DnsRecordPatch record);
  Future<void> deleteDomainRecord(String id, String recordId);

  /// Asks the registrar to send the registrant email again.
  Future<void> resendDomainVerification(String id);

  /// Unlocks the domain and answers its transfer code, once (owner, fresh sign-in).
  Future<String> transferOutDomain(String id, String confirmName);
  // Watchers (D-116)
  Future<List<Watcher>> watchers(String botId);
  Future<void> setWatcherPaused(String id, bool paused);
  Future<void> deleteWatcher(String id);
  // Action rules (D-115)
  Future<List<ActionRule>> actionRules(String orgId, {String? botId});
  Future<void> createActionRule(
    String orgId, {
    String? botId,
    required String category,
    required String rule,
    List<String> domains = const [],
    double? maxAmount,
  });
  Future<void> deleteActionRule(String id);
  // Check-ins (D-114)
  Future<BotCheckins> botCheckins(String botId);
  Future<BotCheckins> setBotCheckins(String botId, BotCheckins settings);
  Future<ForYou> forYou(String orgId);
  Future<AcceptedSuggestion> acceptSuggestion(String id);

  // Widgets (D-405)
  /// What the person's widgets show in [orgId]. With [ifNoneMatch] (the last answer's ETag) an
  /// unchanged glance comes back as [GlanceData.unchanged]. Null when the server is older and has
  /// no glance: the app then builds a small one itself.
  Future<GlanceData?> glance(String orgId, {String? ifNoneMatch});

  /// A key this device's widgets fetch the glance with (§8.3). Null when the server has no widget
  /// keys yet.
  Future<NewWidgetKey?> createWidgetKey(String orgId, String platform, {String? label});

  /// Takes a widget key back (sign-out). A key already gone is fine.
  Future<void> deleteWidgetKey(String id);

  /// Whether the key's glance is made private on the server (the app lock, §10).
  Future<void> setWidgetKeyPrivate(String id, bool private);

  /// Where the server sends refresh pushes for this key's widgets: an Android phone's Firebase
  /// token (`fcm`) or a WidgetKit push token (`apns_widgets`). Sent with the widget key itself.
  Future<void> registerWidgetPushToken(String widgetKey, String token, {required String kind, bool? sandbox});

  // Bot widgets (docs/BOT-WIDGET-PLAN.md)
  /// What bots keep on the person's Canvas widgets in [orgId], with the bots allowed to write and
  /// where a Canvas widget is placed. With [ifNoneMatch] (the last list's `version`) an unchanged
  /// list answers null. A server from before bot widgets answers an empty list.
  Future<CanvasList?> canvases(String orgId, {String? ifNoneMatch});

  /// Where a canvas's picture or built-in painting is served (needs [authHeaders]).
  String canvasPictureUrl(String canvasId, String hash);

  /// A canvas's picture as JPEG bytes (for the Mac's widgets); null when it is gone.
  Future<Uint8List?> canvasPicture(String canvasId, String hash);

  /// Pauses a canvas or shows it again ([status] `shown` or `paused`), or hides it on a locked phone.
  Future<Canvas> updateCanvas(String id, {CanvasUpdateStatusEnum? status, bool? hideWhenLocked});

  /// Clears a canvas (also **Not now** on a bot's first preview). One already gone is fine.
  Future<void> clearCanvas(String id);

  /// Lets [botId] show things on the person's widgets (**Show on my widgets**: what it left
  /// waiting shows), or stops it (what it showed is cleared).
  Future<CanvasGrantSaved> setCanvasGrant(String botId, bool allowed);

  // Live data cards (docs/RICH-CARDS-PLAN.md). Raw JSON: a card is an A2UI component.
  /// Fetches a live card again (through the server's shared cache), or another of its [view]s (a
  /// day, a chart range). [force] is the person's ↻. Answers `{id, card, fetched_at, error, pinned}`.
  Future<Map<String, Object?>> refreshLiveCard(String id, {String? view, bool force = false});

  /// The latest saved data of the live cards on screen, by id.
  Future<List<Map<String, Object?>>> liveCards(List<String> ids);

  /// Pins a live card to the person's widgets; answers the canvas id and its status (`waiting`
  /// until the bot may show things on widgets).
  Future<Map<String, Object?>> pinLiveCard(String id, {Map<String, String>? units});

  Future<void> unpinLiveCard(String id);

  /// Reports wrong data on a card (no words are sent).
  Future<void> reportLiveCard(String id);

  /// The person's home city and units for cards: `{home_place, units}`.
  Future<Map<String, Object?>> cardPrefs();

  /// Saves the home city (a place from [searchPlaces]; [clearHome] removes it) and/or units.
  Future<Map<String, Object?>> updateCardPrefs({Map<String, Object?>? homePlace, bool clearHome = false, Map<String, String>? units});

  /// Cities matching [query], for picking a home city.
  Future<List<Map<String, Object?>>> searchPlaces(String query);

  // Watches (D-410)
  /// The person's signed-in watches in [orgId], most recently used first. Empty when the server
  /// has no watch keys yet.
  Future<List<WatchKeyView>> listWatchKeys(String orgId);

  /// The ids of the person's watch keys in [orgId], for checking this phone's records against the
  /// server. Unlike [listWatchKeys] it tells "none" from "couldn't ask": null when the person is no
  /// longer in that workspace, and it throws when the server can't say (offline, or a server from
  /// before watches).
  Future<Set<String>?> watchKeyIdsIn(String orgId);

  /// Signs a watch in from the phone: registers the fingerprint of the key the watch made (§8.2).
  /// Registering the same fingerprint again updates it (another workspace, a new name).
  Future<WatchKeyView> registerWatchKey({
    required String orgId,
    required String fingerprint,
    required WatchSystem platform,
    required String name,
    String? model,
    String? appVersion,
    String? osVersion,
  });

  /// Removes a watch: its key stops working at once. A key already gone is fine.
  Future<void> deleteWatchKey(String id);

  /// Removes every watch the person has signed in, in every workspace (Sign Out Everywhere): how
  /// many went. Null when the server can't do it in one go (an older server); the caller then
  /// removes the ones it knows.
  Future<int?> deleteAllWatchKeys();

  /// The person's watch settings. Null when the server has none yet.
  Future<WatchPrefsView?> watchPrefs();

  /// Changes the person's watch settings. An empty [quickReplies] goes back to the built-in list.
  Future<WatchPrefsView> updateWatchPrefs({WatchAllowance? allow, bool? showDetails, List<String>? quickReplies});

  /// Which watch shows [code] (already normalized), before allowing it. Null for a wrong or
  /// expired code.
  Future<WatchCodeView?> watchCodeInfo(String code);

  /// Allows the watch showing [code]: it is signed in to [orgId] as the person. Null for a wrong,
  /// expired or used code. Throws [WatchKeyTaken] when that watch is still signed in to another
  /// account.
  Future<WatchKeyView?> claimWatchCode(String code, String orgId);
  Future<void> dismissSuggestion(String id, {bool dontSuggestAgain = false});

  /// Where each of these suggestions stands; ones that aren't yours are left out.
  Future<Map<String, SuggestionState>> suggestionStates(List<String> ids);
  // Projects (D-113, D-295)
  Future<List<Project>> projects(String orgId);

  /// A project you work on together in its chat, or with [autonomous] one its lead bot plans for
  /// your approval and then works on by itself (that needs a [goal]). [conversationId] makes a
  /// topic of yours the project's chat. [cover] is a painted cover's name (`sailboat`).
  Future<Project> createProject(
    String orgId, {
    required String title,
    String goal,
    String doneCriteria,
    required String leadBotId,
    double? budgetUsd,
    bool autonomous,
    String? conversationId,
    String? cover,
  });
  Future<ProjectDetail> project(String projectId);

  /// [status] pauses, resumes, cancels or finishes it; [autonomous] switches working by itself on
  /// or off (on needs a goal: the one it has, or [goal]).
  Future<void> updateProject(
    String projectId, {
    String? status,
    double? budgetUsd,
    bool? autonomous,
    String? goal,
    String? doneCriteria,
  });

  /// Picks a painted cover for a project ([cover] is its name, such as `sailboat`), or none.
  Future<void> setProjectCover(String projectId, String? cover);
  Future<void> approveProjectPlan(String projectId);
  Future<void> signOffMilestone(String projectId, String milestoneId);
  // Ticket board (D-098)
  Future<Task> createTask(
    String orgId, {
    required String title,
    String? details,
    String? priority,
    String? assigneeBotId,
    bool? reviewRequired,
  });

  /// Changes a ticket; assigning a new bot starts its work.
  Future<Task> updateTask(
    String taskId, {
    String? title,
    String? details,
    String? status,
    String? priority,
    String? assigneeBotId,
    String? assigneeUserId,
    bool? reviewRequired,
    double? position,
  });
  Future<void> deleteTask(String taskId);
  Future<List<TaskComment>> taskComments(String taskId);

  /// A comment on a bot's ticket wakes that bot.
  Future<TaskComment> addTaskComment(String taskId, String body);

  // Owner admin console (Phase 6). Null when the user is not the instance owner.
  Future<AdminOverview?> adminOverview();

  /// Usage on the server's keys charged against what it cost the server, over [days] (D-395).
  Future<AdminMargin> adminMargin({int days = 30});
  Future<List<AdminUser>> adminUsers();
  Future<List<AdminOrg>> adminOrgs();

  /// Suspends a workspace: its computers stop and its bots stop running; data is kept (D-094).
  Future<AdminOrg> suspendOrg(String orgId, String reason);
  Future<AdminOrg> unsuspendOrg(String orgId);
  Future<List<AbuseEvent>> adminAbuseEvents();
  Future<AdminOrg> setOrgLimits(String orgId, Map<String, num> limits);
  Future<List<AdminService>> adminServices();
  Future<List<AdminVendor>> adminVendors();
  Future<AdminVendor> setAdminVendor(String vendor, VendorSettings settings);
  Future<AdminVendor> checkAdminVendor(String vendor);
  Future<UpdateNotice> adminUpdates();

  /// How apps without their own sign-in connect (D-173): the server's Composio account or people's own.
  Future<ConnectionSettings> adminConnectionSettings();
  /// Leave a choice null to keep it. [googleDirect]: Google's apps use Google's own MCP servers
  /// instead of the server's Composio account (D-166; self-hosted only).
  Future<ConnectionSettings> setAdminConnectionSettings({
    bool? serverComposio,
    bool? googleDirect,
  });

  /// The models Casama Cloud runs. The instance owner can change them without a restart (D-188).
  Future<CloudModels> adminCloudModels();

  /// Server capacity for the Admin screen (D-252): memory, computers' share of the budget, 30-day peaks.
  Future<ServerCapacity> adminCapacity();
  Future<CloudModels> setAdminCloudModels(CloudModels models);

  /// Model access switch (docs/OWN-KEYS-PLAN.md §3.3): own providers on Cloud, and Casama's models
  /// on or off per plan.
  Future<AdminModelAccess> adminModelAccess();
  Future<AdminModelAccess> setAdminModelAccess(AdminModelAccess access);

  // Pricing editor (D-244): plans, credit packs and the usage markup, for the instance owner.
  Future<AdminPricing> adminPricing();
  Future<AdminPlan> saveAdminPlan(String code, SavePlanRequest plan);
  Future<AdminCreditPack> saveAdminCreditPack(String code, SaveCreditPackRequest pack);
  Future<BillingSettings> setAdminBillingSettings(BillingSettings settings);

  // Privacy and SSO (Phase 8)
  Future<Uint8List> exportMyData();

  /// Tells the server whether this person opted out of usage analytics (server events and rollups).
  Future<void> setAnalyticsOptOut(bool optOut);

  /// Whether the signed-in account is marked internal/test by the server (`GET /v1/me`).
  Future<bool> isInternalAccount();

  /// Windows and Linux: hands catalog events to the server, which forwards them to Google Analytics 4
  /// (D-399; there's no Firebase Analytics there and the GA4 secret can't ship in the app).
  Future<void> relayAnalytics(String platform, List<({String name, Map<String, Object> properties})> events);

  /// Whether the workspace turned usage analytics off (admins).
  Future<bool> orgAnalyticsOptOut(String orgId);
  Future<void> setOrgAnalyticsOptOut(String orgId, bool optOut);
  Future<AccountDeletion> deleteAccount(String confirmEmail);
  // Two-step sign-in (D-093)
  Future<List<TwoStepFactor>> twoStepFactors();

  /// The account has two-step sign-in but this session hasn't passed the second step yet.
  bool get twoStepCodeNeeded;

  /// This session passed the second step (aal2).
  bool get twoStepVerified;
  Future<TwoStepEnrollment> startTwoStep();

  /// Finishes setting up [factorId] with a code from the app.
  Future<void> verifyTwoStep(String factorId, String code);

  /// Signing in: passes the second step with a code.
  Future<void> passTwoStep(String code);
  Future<void> removeTwoStep(String factorId);

  /// Renames one of your authenticator apps.
  Future<void> renameTwoStep(String factorId, String name);
  Future<bool> requireTwoStep(String orgId);
  Future<bool> setRequireTwoStep(String orgId, bool value);

  /// The workspace requires the app lock on its members' devices (D-375).
  Future<bool> requireAppLock(String orgId);
  Future<bool> setRequireAppLock(String orgId, bool value);

  Future<int> retentionDays(String orgId);
  Future<int> setRetentionDays(String orgId, int days);

  /// Enterprise SSO: opens the identity provider for the email's domain.
  Future<void> signInWithSso(String email);

  // Billing (Phase 7). `BillingSummary.enabled` is false on self-hosted servers (no paywall).
  Future<BillingSummary> billing(String orgId);
  /// Saved resets use the same authenticated contract as other billing actions.
  LimitResetsApi get limitResets;
  Future<PlanCatalog> plans();
  /// A checkout page to open, or null when an existing web subscription was moved to [planCode]
  /// in place (D-248).
  Future<String?> checkoutUrl(
    String orgId, {
    String? planCode,
    String? packCode,
  });
  Future<String> billingPortalUrl(String orgId);

  /// Extra people beyond the plan's seats, on a Pro or Max web subscription (D-249).
  Future<BillingSummary> setExtraSeats(String orgId, int extra);
  Future<BillingSummary> verifyPurchase(
    String orgId, {
    required String source,
    required String productId,
    String? transactionId,
    String? purchaseToken,
  });
  Future<BillingUsage> billingUsage(String orgId);
  Future<List<LinkKey>> linkKeys(String orgId);
  Future<CreatedLinkKey> createLinkKey(String orgId, String instanceName);
  Future<void> revokeLinkKey(String orgId, String keyId);

  // Casama Link (D-296)
  /// Whether this server makes scan-to-sign-in codes.
  bool get signInCodes;

  /// False when the server takes no new accounts (a self-hosted server with remote access on).
  bool get signUpsOpen;

  /// A one-time code that signs another device in to this account, shown as a QR code.
  Future<SignInCode> createSignInCode();

  /// Signs this device in with a code scanned from a signed-in one.
  Future<void> signInWithCode(String code, {String? deviceName});

  /// The server a link code belongs to, or null when the code isn't valid (any more).
  Future<LinkSignInRequest?> linkSignIn(String userCode);

  /// Links the server showing [userCode] to the workspace; returns the server's name.
  Future<String> approveLinkSignIn(String orgId, String userCode);

  /// Servers linked to the workspace, with the number its plan connects.
  Future<LinkServerList> linkServers(String orgId);
  Future<void> removeLinkServer(String orgId, String serverId);

  /// This server's own public address through Casama Link; null for anyone but the instance
  /// owner. [check] looks again now (Casama Cloud, the connector, the address from outside).
  Future<RemoteAccessStatus?> remoteAccess({bool check = false});

  /// Whether new accounts here are only for emails someone on the server invited.
  bool get signUpsByInvitation;

  // Casama Cloud's waitlist and invite gate (D-427)
  /// Set while this server takes new accounts only from its waitlist and invite codes (Casama
  /// Cloud, `signup_gate` in /v1/config). Null when sign-ups are open; self-hosted servers never send it.
  PublicConfigSignupGate? get signupGate;

  /// Puts an address on the waitlist (solves the sign-up puzzle first). The same answer every time.
  Future<void> joinWaitlist(WaitlistJoin join);

  /// Who an invite code is from (a campaign's label or the member's first name) and whether it has
  /// an invite left. Throws a 404 problem for a code that doesn't exist.
  Future<InviteCodePreview> previewInviteCode(String code);

  /// Claims an invite code for an email address; afterwards that address can sign up any way.
  Future<InviteRedeemed> redeemInviteForEmail(String code, String email, {bool? newsletter});

  /// Whether this device can get an Apple or Google ID token from the system sheet before signing
  /// in, which an invite needs (§7.3). False where only the browser flow exists.
  bool inviteSignInAvailable(String provider);

  /// Apple or Google with an invite code: the system sheet first, then the code and its token to the
  /// server, and only when it lets the address in, the sign-in with the same token and nonce.
  Future<InviteSignInResult> signInWithInvite(String provider, String code);

  /// A sign-in email for a new account that carries [inviteCode] in its sign-up data, so the server
  /// lets it in on the spot (§2.1 rule 4).
  Future<void> sendMagicLinkWithInvite(String email, String inviteCode);

  // Admin → Waitlist (owner only)
  Future<AdminWaitlist> adminWaitlist({String? status, String? query, int limit = 50, int offset = 0});

  /// Lets in the next [count] in line, or the entries [ids]; returns how many.
  Future<int> adminAdmitWaitlist({int? count, List<String>? ids});

  /// Adds and admits addresses by hand; [notify] sends each the "You're in" email.
  Future<WaitlistChanged> adminAddWaitlistEntries(List<String> emails, {bool notify = false});
  Future<void> adminRemoveWaitlistEntry(String id);
  Future<AdminSignupGate> adminSignupGate();

  /// Changes some of mode, opens_at, invites_per_person, daily_admit, daily_emails_max,
  /// batch_hour_utc (JSON names; a null opens_at clears it).
  Future<AdminSignupGate> adminSetSignupGate(Map<String, Object?> changes);
  Future<List<InviteCampaign>> adminInviteCampaigns();
  Future<InviteCampaign> adminCreateInviteCampaign(CreateInviteCampaignRequest request);
  Future<InviteCampaign> adminUpdateInviteCampaign(String code, UpdateInviteCampaignRequest request);

  /// Private notifications on this server (its owner): with it on, the push relay on Casama Cloud
  /// is given no text, and the app loads what happened from the server itself.
  Future<void> setPrivateNotifications(bool on);

  // Desktop companion (Phase 6)
  /// The API's base URL (the companion opens its WebSocket there).
  String get apiUrl;
  Future<List<LocalDevice>> localDevices(String orgId);
  Future<CreatedLocalDevice> createLocalDevice(
    String orgId,
    String name,
    String platform,
  );
  Future<LocalDevice> updateLocalDevice(
    String id, {
    Set<String>? capabilities,
    List<String>? roots,
    List<String>? botIds,
    bool? enabled,
    List<String>? codingAgents,
  });

  /// Registers this computer's local MCP servers (no secrets) as local_mcp integrations (D-096).
  Future<List<Integration>> setLocalMcpServers(
    String deviceId,
    List<LocalMcpServerInfo> servers,
  );

  /// The coding agents bots can use (D-370). Null when the server is older and has no list; an
  /// entry this app can't read is skipped.
  Future<List<CodingAgentInfo>?> codingAgents();

  /// The person's own coding agents on this computer (D-371). Null when the server has none.
  Future<List<OwnCodingAgentEntry>?> ownCodingAgents(String deviceId);
  Future<List<OwnCodingAgentEntry>> setOwnCodingAgents(
    String deviceId,
    List<OwnCodingAgent> agents,
  );

  /// Runs an agent on this computer with a tiny task and returns what it printed (D-371).
  Future<CodingAgentTestResult> testOwnCodingAgent(
    String deviceId,
    TestOwnCodingAgentRequest draft,
  );
  Future<void> deleteLocalDevice(String id);

  // Voice (Phase 6)
  Future<String> transcribe(String botId, Uint8List audio, String mime);
  Future<Uint8List> speech(String messageId);
  Future<VoiceSession> voiceSession(
    String botId, {
    String? conversationId,
    String? callId,
  });
  // Phone-call voice (D-135)
  Future<List<PhoneCall>> ringingCalls();
  Future<PhoneCall> answerCall(String id);
  Future<PhoneCall> declineCall(String id);

  /// iOS PushKit token, so calls ring through CallKit.
  Future<void> registerVoipToken(String token);
  Future<VoiceToolResult> voiceTool(
    String botId,
    String conversationId,
    String callId,
    String name,
    Map<String, Object?> arguments, {
    String? liveCallId,
  });
  /// Ends a call: its length and usage, and any turns not saved yet. With [liveCallId] (D-327) the
  /// server's record of the call ends too, and [turnIds] (one per turn) keep turns from saving twice.
  Future<void> saveVoiceTranscript(
    String conversationId,
    List<(String, String)> turns,
    int seconds, {
    String? provider,
    Map<String, int>? usage,
    String? liveCallId,
    List<String>? turnIds,
    String? ended,
  });

  /// A next step on a call's card (call card plan): starts it as a chat run (its id), or with
  /// [dismiss] puts it away.
  Future<String?> updateCallStep(String liveCallId, String stepId, {bool dismiss = false});

  /// Deletes a call from its chat: its card and every turn of its transcript.
  Future<void> deleteCall(String liveCallId);

  /// Saves finished turns of a live call while it goes on (D-327): (id, role, text), each saved
  /// once by its id however often it's sent.
  Future<void> saveVoiceTurns(
    String liveCallId,
    List<(String, String, String)> turns,
  );

  /// Keeps a live call's server record open (D-327). True when the server already ended the call.
  Future<bool> voiceHeartbeat(String liveCallId, {Map<String, int>? usage});

  /// Changes some of a bot's voice settings; a null value clears that setting, others are kept.
  Future<void> updateBotVoice(String botId, Map<String, Object?> voice);

  /// A bot's voice settings (providers, voices, tools on calls).
  Future<Map<String, Object?>> loadBotVoice(String botId);

  // Computers: management (Phase 5)
  Future<Computer> createComputer(
    String orgId, {
    required String name,
    required bool private,
    String? ownerBotId,
    String profile,
  });
  Future<Computer> updateComputer(
    String computerId, {
    String? name,
    String? profile,
    int? maxDesktops,
    int? idleSleepMinutes,
  });
  Future<void> deleteComputer(String computerId);
  Future<void> setBotComputer(String botId, String? computerId);

  // Live view and take control (Phase 5)
  Future<StreamSession> streamSession(String computerId, {String mode});
  Future<Lease> lease(String computerId);
  Future<Lease> takeLease(String computerId, {bool allowShell});
  Future<Lease> releaseLease(String computerId, {String? note});
  // Secret requests from bots (D-101): the value goes to Vault through the API, nowhere else.
  Future<void> fulfillSecretRequest(String requestId, String value);
  Future<void> declineSecretRequest(String requestId);
  /// pending | fulfilled | declined | expired | cancelled; expired when it can't be seen.
  Future<String> secretRequestStatus(String requestId);
  /// Answers a connected MCP server's question (D-363): accept (with [content]), decline or cancel.
  Future<void> answerMcpQuestion(String questionId, String action, [Map<String, Object?>? content]);

  // Device connections (D-149): data this person shares from their devices.
  Future<List<DeviceSource>> deviceSources();
  Future<DeviceSource> saveDeviceSource(
    String key, {
    required String name,
    required String platform,
    required Map<String, DeviceKindSettings> kinds,
  });
  Future<void> deleteDeviceSource(String key);
  Future<int> uploadDeviceReadings(
    String key,
    List<DeviceReadingInput> readings, {
    String? requestId,
  });
  Future<List<DeviceRequest>> deviceRequests(String key);
  Future<void> answerDeviceRequest(
    String id, {
    required bool ok,
    Map<String, Object?>? result,
    String? error,
  });
  /// [allKinds]: include Casama for Chrome's kinds (browser_tab, browser_history), which builds
  /// before D-323 can't read, so the server leaves them out unless asked.
  Future<List<DeviceGrant>> deviceGrants({String? botId, bool allKinds = false});

  /// System permissions on each of the person's own devices, as each last reported them (D-376).
  Future<List<DevicePermissions>> devicePermissions();

  /// This device's permissions as they are now, under [deviceRef] (`computer:<id>`, `source:<id>`).
  Future<void> reportDevicePermissions(String deviceRef, Map<String, String> states);

  /// Asks one of the person's devices to prompt for [permission], open its settings or restart
  /// Casama ([action]: request, open_settings, relaunch). Returns how it went: socket (a computer
  /// got it at once) or notification (a phone gets one to tap).
  Future<String> askDevicePermission(String deviceRef, String permission, String action, {String? botId});

  /// Not now: [botId] doesn't ask for these on this device for 24 hours.
  Future<void> snoozeDevicePermissions(String deviceRef, String botId, List<String> permissions);

  /// The tab in front of the person's paired Casama for Chrome, for quick ask where the app can't
  /// read the browser itself (Windows, Linux; D-323 E3). Null when no browser shares its tab.
  Future<BrowserTabSummary?> browserTab();
  Future<List<DeviceGrant>> setDeviceGrant(
    String botId,
    DeviceKind kind,
    bool allowed,
  );

  /// Fires when a run asks one of this person's devices for something (its request id).
  Stream<String> watchDeviceRequests();

  /// "Less like this" on a proactive message (D-153): saved as the bot's memory.
  Future<void> lessLikeThis(String notificationId);

  // Device triggers (D-151).
  Future<int> reportDeviceEvents(String key, List<DeviceEventInput> events);
  Future<List<DevicePlace>> devicePlaces();
  Future<DevicePlace> saveDevicePlace({
    required String name,
    required double latitude,
    required double longitude,
    int? radiusM,
  });
  Future<void> deleteDevicePlace(String id);
  Future<List<TakeoverRequest>> takeovers(String orgId);
  Future<void> dismissTakeover(String takeoverId, {String? note});

  // Computers
  Future<List<Computer>> computers(String orgId);
  Future<Computer> startComputer(String id);
  Future<Computer> stopComputer(String id);
  Future<List<ComputerFileEntry>> listFiles(String computerId, String path);
  Future<Uint8List> downloadFile(String computerId, String path);

  /// A Word, Excel or PowerPoint file on the computer as a PDF, for the preview; null when the
  /// file can't be turned into one.
  Future<Uint8List?> computerFilePdf(String computerId, String path);

  /// A small picture of a video's first frame, an image or a PDF's first page on the computer
  /// (D-226). Null when there is none, including whenever the computer is asleep or offline: it
  /// is never woken for this.
  Future<ComputerThumbnail?> computerThumbnail(String computerId, String path, {int size = 480});

  // Chat media: generated images and videos kept with the chat, at `media:<id>`.
  Future<Uint8List> chatMedia(String id);

  /// Where a chat media file is served (needs [authHeaders]); supports range requests.
  String chatMediaUrl(String id);

  /// A chat video's poster, a JPEG still (needs [authHeaders]); 404 when the server can't make one.
  String chatMediaPosterUrl(String id);

  /// The current sign-in, for players and images that load straight from the API.
  Map<String, String> get authHeaders;

  // The Library (D-274): everything bots made.

  /// A page of the workspace's creations, newest first (or recently opened), with the kinds that
  /// exist for the filter chips. [deleted] lists what was deleted in the last 30 days.
  Future<CreationList> creations(
    String orgId, {
    CreationKind? kind,
    String? botId,
    String? conversationId,
    String? projectId,
    String? q,
    String? cursor,
    bool recentlyOpened = false,
    bool deleted = false,
    int limit = 60,
  });

  /// One creation with the others from the same run.
  Future<CreationDetail> creation(String id);

  /// Files a creation under a project, or takes it out of one ([projectId] null) (D-295).
  Future<Creation> moveCreation(String id, String? projectId);

  /// Renames, pins, marks it opened (Recently opened) or changes who can see it (D-281). Making it
  /// public returns `public_url` once.
  Future<Creation> updateCreation(String id, {String? title, bool? pinned, bool? opened, CreationVisibilityEnum? visibility});

  /// A private copy for this person that shares the stored bytes (D-291).
  Future<Creation> duplicateCreation(String id);

  /// Hides it now; restorable for 30 days.
  Future<void> deleteCreation(String id);
  Future<void> restoreCreation(String id);

  /// Where its bytes and its cover are served (need [authHeaders]); content supports ranges.
  String creationContentUrl(String id);
  String creationCoverUrl(String id);

  /// Its bytes (pictures, documents and files to preview or save).
  Future<Uint8List> creationContent(String id);
  Future<void> uploadFile(String computerId, String path, Uint8List bytes);
  Future<void> deleteFile(String computerId, String path);
  Future<List<Checkpoint>> checkpoints(String computerId);
  Future<void> restoreCheckpoint(String computerId, String checkpointId);
  /// What's on the computer's screen as a PNG. Empty bytes when there is nothing to show (a
  /// headless computer with no page open); null when it could not be fetched.
  Future<Uint8List?> screenshot(String computerId);

  /// The screen card's picture (SCREEN-CARD-PLAN): a small JPEG [width] wide that doesn't wake the
  /// computer or count as using it, unless [wake] (the call's tile, which the bot asked for). Pass
  /// the last [etag] to get [ScreenPictureStatus.unchanged] instead of the same picture again.
  Future<ScreenPicture> screenPicture(String computerId, {int width = 480, String? etag, bool wake = false});
  Future<(Uri, Map<String, String>)> terminal(
    String computerId, {
    int cols,
    int rows,
  });

  // Managing a computer (D-240). The reads return null while the computer sleeps: looking
  // never wakes it.
  Future<Computer> restartComputer(String id);

  /// Restarts the computer on the newer system (D-360); 409 computer_busy while a command runs,
  /// unless [force].
  Future<Computer> applyComputerUpdate(String id, {bool force = false});

  /// Starts a reset in the background; follow [Computer.operation].
  Future<Computer> resetComputer(String id, {required bool erase, bool checkpoint = true});
  Future<ComputerVitals?> computerVitals(String id);
  Future<ComputerStorage?> computerStorage(String id);
  Future<CleanStorageResult> cleanComputerStorage(String id);
  Future<List<ComputerProcess>?> computerProcesses(String id);
  Future<void> stopComputerProcess(String id, int pid);
  Future<ComputerUsage> computerUsage(String id);
  Future<List<ComputerHistoryEntry>> computerHistory(String id);
  Future<List<ComputerBotUse>> computerBots(String id);
  Future<Checkpoint> createCheckpoint(String id, String label);

  /// Every file in ~/workspace as one zip; null when there are none.
  Future<Uint8List?> downloadComputerArchive(String id);
}

/// What Settings → Usage is narrowed to (D-353): one bot, model, source or person. Null is all.
class UsageFilter {
  const UsageFilter({this.botId, this.model, this.source, this.userId});
  static const none = UsageFilter();

  final String? botId;
  final String? model;
  final UsageSource? source;
  final String? userId;

  bool get isEmpty => botId == null && model == null && source == null && userId == null;

  UsageFilter copyWith({String? Function()? botId, String? Function()? model, UsageSource? Function()? source, String? Function()? userId}) => UsageFilter(
    botId: botId == null ? this.botId : botId(),
    model: model == null ? this.model : model(),
    source: source == null ? this.source : source(),
    userId: userId == null ? this.userId : userId(),
  );

  @override
  bool operator ==(Object other) => other is UsageFilter && other.botId == botId && other.model == model && other.source == source && other.userId == userId;

  @override
  int get hashCode => Object.hash(botId, model, source, userId);

  @override
  String toString() => 'UsageFilter(bot: $botId, model: $model, source: $source, user: $userId)';
}

