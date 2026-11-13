import 'dart:async';
import 'dart:typed_data';

import 'package:casama_sdk/casama_sdk.dart';

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
    );
  }

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
    this.ui = const [],
    this.uiActionSurface,
    this.siblingIndex = 1,
    this.siblingCount = 1,
    this.botId,
    this.routineName,
    this.suggestion,
    this.suggestionList = const [],
    this.topic,
  });

  /// Set on the message a routine posts to start its run (D-155): shown as a line, not a bubble.
  final String? routineName;

  /// A suggestion the bot posted in General (D-253), shown as a card with Do it / Not now.
  final MessageSuggestion? suggestion;

  /// Several suggestions in one card (D-257), each with its own Do it.
  final List<MessageSuggestion> suggestionList;

  /// A topic's result posted back to General (D-253), with a link to the topic.
  final MessageTopic? topic;

  /// For the offline cache (D-112): text, attachments and versions; bot UIs are left out.
  Map<String, Object?> toJson() => {
    'id': id,
    'role': role,
    'text': text,
    'created_at': createdAt.toIso8601String(),
    'run_id': runId,
    'attachments': [for (final a in attachments) a.toJson()],
    'sibling_index': siblingIndex,
    'sibling_count': siblingCount,
    'bot_id': botId,
    'routine_name': routineName,
    if (suggestion case final s?) 'suggestion': {'id': s.id, 'title': s.title, 'body': s.body},
    if (topic case final t?) 'topic': {'conversation_id': t.conversationId, 'title': t.title},
    if (suggestionList.isNotEmpty) 'suggestions': [for (final s in suggestionList) {'id': s.id, 'title': s.title, 'body': s.body}],
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
  });

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
  );

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

/// About you (D-169): what bots call the person and what the person shared about themselves.
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

  /// Signs out this device and every other one.
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
  Future<Bot> createBot(
    String orgId, {
    required String name,
    required String credentialId,
    required String model,
    String persona,
    String? templateId,
    String? avatarUrl,
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
  Future<UsageReport> usage(String orgId, {String period});

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
  Future<BotQuietView> botQuiet(String botId);
  Future<void> setBotQuiet(String botId, BotQuietView value);
  // Invite friends (D-211)
  Future<Referral> referral();
  Future<Referral> redeemReferral(String code);
  Future<ReferralPreview> previewReferral(String code);
  // About you (D-169)
  Future<AboutYouView> aboutYou();
  Future<void> saveAboutYou(AboutYouView value);
  Future<void> markNameAsked();
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
  /// The branch being shown, oldest first. With [limit], a page of it (Fix 10): the newest
  /// [limit] messages, the [limit] just before the message [before], or the newest back to the
  /// message [around] and half a page before it (a search hit).
  Future<List<ChatMessageView>> messages(String conversationId, {int? limit, String? before, String? around});
  Future<String?> activeRun(String conversationId);

  /// [skills]: skills picked with / in the composer (D-104).
  Future<SendMessageResponse> send(
    String conversationId,
    String text, {
    List<AttachmentRef> attachments = const [],
    Map<String, Object?>? uiAction,
    List<String> skills = const [],
  });
  /// Asks the run to stop. Throws [RunAlreadyFinished] when it has already ended (or is gone).
  Future<void> cancelRun(String runId);

  /// Edits a sent message: forks there and reruns (D-108).
  Future<SendMessageResponse> editMessage(
    String conversationId,
    String messageId,
    String text,
  );

  /// Deletes one message; the ones after it join the one before it (Add 11).
  Future<void> deleteMessage(String conversationId, String messageId);

  /// Shows the branch containing [messageId].
  Future<void> switchBranch(String conversationId, String messageId);

  /// A message and its edited versions, oldest first.
  Future<List<String>> messageSiblings(String conversationId, String messageId);
  Stream<RunEventItem> watchRun(String runId, {int afterSeq = 0});
  Future<List<RunEventItem>> runEvents(String runId);
  Future<List<RunSummary>> runs(String botId);

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

  /// A run started in this conversation, from any device or trigger (D-224): its id. Null after
  /// Realtime reconnects, when something may have happened meanwhile.
  Stream<String?> watchConversation(String conversationId);
  Future<void> registerDevice(String platform, String token);

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
  Future<bool> mcpDecideApprovals(String orgId);
  Future<void> setMcpDecideApprovals(String orgId, bool allowed);
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
  Future<Plugin> installPlugin(
    String orgId,
    String botId,
    String url,
    String commit,
    Map<String, String> secrets,
  );
  Future<PluginUpdatePreview> pluginUpdate(String id);
  Future<Plugin> updatePlugin(
    String id,
    String commit, {
    Map<String, String> secrets = const {},
  });
  Future<void> uninstallPlugin(String id);
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
  Future<void> dismissSuggestion(String id, {bool dontSuggestAgain = false});
  // Projects (D-113)
  Future<List<Project>> projects(String orgId);
  Future<Project> createProject(
    String orgId, {
    required String title,
    required String goal,
    String doneCriteria,
    required String leadBotId,
    double? budgetUsd,
  });
  Future<ProjectDetail> project(String projectId);
  Future<void> updateProject(
    String projectId, {
    String? status,
    double? budgetUsd,
  });
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
  Future<List<AdminUser>> adminUsers();
  Future<List<AdminOrg>> adminOrgs();

  /// Suspends a workspace: its computers stop and its bots stop running; data is kept (D-094).
  Future<AdminOrg> suspendOrg(String orgId, String reason);
  Future<AdminOrg> unsuspendOrg(String orgId);
  Future<List<AbuseEvent>> adminAbuseEvents();
  Future<AdminOrg> setOrgLimits(String orgId, Map<String, num> limits);
  Future<List<AdminService>> adminServices();
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

  // Pricing editor (D-244): plans, credit packs and the usage markup, for the instance owner.
  Future<AdminPricing> adminPricing();
  Future<AdminPlan> saveAdminPlan(String code, SavePlanRequest plan);
  Future<AdminCreditPack> saveAdminCreditPack(String code, SaveCreditPackRequest pack);
  Future<BillingSettings> setAdminBillingSettings(BillingSettings settings);

  // Privacy and SSO (Phase 8)
  Future<Uint8List> exportMyData();

  /// Tells the server whether this person opted out of usage analytics (server events and rollups).
  Future<void> setAnalyticsOptOut(bool optOut);

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

  Future<int> retentionDays(String orgId);
  Future<int> setRetentionDays(String orgId, int days);

  /// Enterprise SSO: opens the identity provider for the email's domain.
  Future<void> signInWithSso(String email);

  // Billing (Phase 7). `BillingSummary.enabled` is false on self-hosted servers (no paywall).
  Future<BillingSummary> billing(String orgId);
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
  Future<List<ConnectKey>> connectKeys(String orgId);
  Future<CreatedConnectKey> createConnectKey(String orgId, String instanceName);
  Future<void> revokeConnectKey(String orgId, String keyId);

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
  });

  /// Registers this computer's local MCP servers (no secrets) as local_mcp integrations (D-096).
  Future<List<Integration>> setLocalMcpServers(
    String deviceId,
    List<LocalMcpServerInfo> servers,
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
    Map<String, Object?> arguments,
  );
  Future<void> saveVoiceTranscript(
    String conversationId,
    List<(String, String)> turns,
    int seconds, {
    String? provider,
    Map<String, int>? usage,
  });

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
  Future<List<DeviceGrant>> deviceGrants({String? botId});
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
    String? q,
    String? cursor,
    bool recentlyOpened = false,
    bool deleted = false,
    int limit = 60,
  });

  /// One creation with the others from the same run.
  Future<CreationDetail> creation(String id);

  /// Renames, pins or marks it opened (Recently opened).
  Future<Creation> updateCreation(String id, {String? title, bool? pinned, bool? opened});

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
  Future<(Uri, Map<String, String>)> terminal(
    String computerId, {
    int cols,
    int rows,
  });

  // Managing a computer (D-240). The reads return null while the computer sleeps: looking
  // never wakes it.
  Future<Computer> restartComputer(String id);

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
