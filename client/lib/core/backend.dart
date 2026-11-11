import 'dart:async';
import 'dart:typed_data';

import 'package:casama_sdk/casama_sdk.dart';

/// A message as shown in a conversation (final messages only; live text comes from run events).
/// A file attached to a message, stored on the bot's computer ([path] is under its home folder).
class AttachmentRef {
  const AttachmentRef({required this.path, required this.name, required this.mimeType, required this.size});
  final String path;
  final String name;
  final String mimeType;
  final int size;

  bool get isImage => mimeType.startsWith('image/');

  Map<String, Object?> toJson() => {'path': path, 'name': name, 'mime_type': mimeType, 'size': size};
  static AttachmentRef fromJson(Map<String, dynamic> j) => AttachmentRef(path: j['path'] as String, name: j['name'] as String, mimeType: j['mime_type'] as String, size: (j['size'] as num).toInt());
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
          if (p['type'] == 'ui' && p['surface_id'] is String && p['messages'] is List)
            UiPart(surfaceId: p['surface_id'] as String, messages: List<Object?>.from(p['messages'] as List)),
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
  });

  /// Set on the message a routine posts to start its run (D-155): shown as a line, not a bubble.
  final String? routineName;

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
  };
  static ChatMessageView fromJson(Map<String, dynamic> j) => ChatMessageView(
    id: j['id'] as String,
    role: j['role'] as String,
    text: j['text'] as String? ?? '',
    createdAt: DateTime.parse(j['created_at'] as String),
    runId: j['run_id'] as String?,
    attachments: [for (final a in (j['attachments'] as List? ?? const [])) AttachmentRef.fromJson(a as Map<String, dynamic>)],
    siblingIndex: (j['sibling_index'] as num?)?.toInt() ?? 1,
    siblingCount: (j['sibling_count'] as num?)?.toInt() ?? 1,
    botId: j['bot_id'] as String?,
    routineName: j['routine_name'] as String?,
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

class SkillView {
  const SkillView({required this.id, required this.name, required this.description, required this.bodyMd, required this.enabled, this.botId, this.source = 'manual', this.sourceRef = const {}});
  final String id;
  final String name;
  final String description;
  final String bodyMd;
  final bool enabled;
  final String? botId;

  /// manual, catalog, github or bot (D-104).
  final String source;
  final Map<String, Object?> sourceRef;
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
  bool get isRequest => kind == 'approval_request' || kind == 'approval' || kind == 'takeover';

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
  const RunSummary({required this.id, required this.status, required this.trigger, required this.createdAt, required this.costUsd});
  final String id;
  final String status;
  final String trigger;
  final DateTime createdAt;
  final double costUsd;
}

/// An authenticator app registered for two-step sign-in (D-093).
class TwoStepFactor {
  const TwoStepFactor({required this.id, required this.name, required this.createdAt});
  final String id;
  final String name;
  final DateTime createdAt;
}

/// A new authenticator being set up: scan the QR code (SVG) or type the key, then verify a code.
class TwoStepEnrollment {
  const TwoStepEnrollment({required this.factorId, required this.secret, required this.uri, required this.qrSvg});
  final String factorId;
  final String secret;
  final String uri;
  final String qrSvg;
}

/// Everything the app reads and writes. Reads and simple edits go to Supabase under RLS;
/// commands go to the Casama API. Widget tests use a fake.
/// Quiet hours (D-109): "HH:MM" local times; the window may cross midnight.
class QuietHoursView {
  const QuietHoursView({required this.enabled, required this.start, required this.end});
  final bool enabled;
  final String start;
  final String end;
  Map<String, Object?> toJson() => {'enabled': enabled, 'start': start, 'end': end};
  static QuietHoursView? fromJson(Object? j) => j is Map ? QuietHoursView(enabled: j['enabled'] == true, start: '${j['start'] ?? '22:00'}', end: '${j['end'] ?? '07:00'}') : null;
}

/// About you (D-169): what bots call the person and what the person shared about themselves.
class AboutYouView {
  const AboutYouView({this.displayName, this.preferredName, this.pronouns, this.about = '', this.replyStyle = '', this.learn = true, this.nameAsked = true});
  final String? displayName;
  final String? preferredName;
  final String? pronouns;
  final String about;
  final String replyStyle;

  /// Whether bots may save what they learn about the person in chat.
  final bool learn;

  /// The one-time "What should bots call you?" card was answered or dismissed.
  final bool nameAsked;

  /// The name bots use: the preferred name, else the first word of the sign-in name.
  String get name {
    final p = preferredName?.trim() ?? '';
    if (p.isNotEmpty) return p;
    final d = displayName?.trim() ?? '';
    return d.isEmpty ? '' : d.split(RegExp(r'\s+')).first;
  }

  AboutYouView copyWith({String? preferredName, String? pronouns, String? about, String? replyStyle, bool? learn}) => AboutYouView(
    displayName: displayName,
    preferredName: preferredName ?? this.preferredName,
    pronouns: pronouns ?? this.pronouns,
    about: about ?? this.about,
    replyStyle: replyStyle ?? this.replyStyle,
    learn: learn ?? this.learn,
    nameAsked: nameAsked,
  );
}

/// A fact a bot learned about the person (About you, D-169); private to them.
class UserFactView {
  const UserFactView({required this.id, required this.kind, required this.content, this.pinned = false, required this.updatedAt});
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
  const BotRevision({required this.id, required this.snapshot, required this.changedFields, this.changedByUser, this.changedByBot, required this.createdAt});
  final String id;
  final Map<String, Object?> snapshot;
  final List<String> changedFields;
  final String? changedByUser;
  final String? changedByBot;
  final DateTime createdAt;
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

  /// The server's default model for a provider (GPT-6 Luna on OpenRouter and OpenAI), if any.
  String? defaultModelFor(String provider);

  // Workspaces
  Future<List<OrganizationWithRole>> organizations();
  Future<Organization> createOrganization(String name);
  Future<void> acceptInvite(String token);
  // Spaces (D-099)
  Future<Organization> updateOrg(String orgId, {String? name, String? icon, String? color});
  Future<List<InviteLink>> inviteLinks(String orgId);
  Future<CreatedInviteLink> createInviteLink(String orgId, {String role = 'member', int? expiresInDays, int? maxUses});
  Future<void> revokeInviteLink(String orgId, String linkId);
  Future<OrganizationWithRole> acceptInviteLink(String token);
  Future<List<WorkspaceBadge>> workspaceBadges();
  Future<Invite> invite(String orgId, String email, {bool admin = false});
  // Joining (D-165)
  /// The workspace's standing invite link (admins); made on first use.
  Future<CreatedInviteLink> defaultInvite(String orgId);
  Future<CreatedInviteLink> updateDefaultInvite(String orgId, {bool? requiresApproval, bool reset = false});
  /// A short code (XXXX-XXXX) valid for 48 hours.
  Future<CreatedInviteLink> createInviteCode(String orgId, {String role = 'member'});
  /// What a link, code or email invite opens; works signed out.
  Future<InvitePreview> previewInvite(String invite);
  Future<JoinResult> joinWithInvite(String invite);
  Future<List<JoinRequest>> joinRequests(String orgId);
  Future<JoinRequest> decideJoinRequest(String orgId, String requestId, bool approve);
  Future<List<PendingInvite>> pendingInvites(String orgId);
  Future<List<Invite>> inviteMany(String orgId, List<String> emails, {bool admin = false});
  Future<Invite> resendInvite(String orgId, String inviteId);
  Future<void> revokeInvite(String orgId, String inviteId);
  Future<JoinDomains> joinDomains(String orgId);
  Future<JoinDomains> setJoinDomain(String orgId, bool enabled, {String? domain});
  Future<List<JoinableWorkspace>> joinableWorkspaces();
  Future<OrganizationWithRole> joinByDomain(String orgId);

  // Model keys
  Future<List<Credential>> credentials(String orgId);
  Future<Credential> addCredential(String orgId, ProviderId provider, String label, {String? apiKey, String? baseUrl});
  Future<CredentialTestResult> testCredential(String credentialId, {String? model});

  /// Models the key can use, recommended first (live from the provider, or Casama's short list).
  Future<ModelOptionList> models(String credentialId);
  Future<Credential> updateCredential(String credentialId, {String? label, bool? fallbackOnLimit});

  /// Deletes a key and its Vault secret; a ChatGPT sign-in is revoked first.
  Future<void> deleteCredential(String credentialId);

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
  Future<Conversation> createGroupChat(String leadBotId, List<String> botIds, {String? title});
  Future<Bot> createBot(String orgId, {required String name, required String credentialId, required String model, String persona, String? templateId, String? avatarUrl});
  Future<List<Template>> templates();

  /// [avatarUrl]: `mascot:<name>` for a cloud bot, '' to go back to initials, null to leave it.
  Future<void> updateBot(String botId, {String? name, String? persona, String? autonomy, Map<String, Object?>? modelPolicy, String? avatarUrl});
  Future<UsageReport> usage(String orgId, {String period});

  /// Workspace search (D-103), including files on awake computers.
  Future<SearchResponse> search(String orgId, String query);

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
  Future<ImportBotResponse> importBot(String orgId, BotTemplateFile template, {required String credentialId, required String model, bool memories = true, bool routines = true});
  // Quiet hours (D-109)
  Future<QuietHoursView> quietHours();
  Future<void> setQuietHours(QuietHoursView hours);
  Future<BotQuietView> botQuiet(String botId);
  Future<void> setBotQuiet(String botId, BotQuietView value);
  // About you (D-169)
  Future<AboutYouView> aboutYou();
  Future<void> saveAboutYou(AboutYouView value);
  Future<void> markNameAsked();
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
  Future<List<ChatMessageView>> messages(String conversationId);
  Future<String?> activeRun(String conversationId);

  /// [skills]: skills picked with / in the composer (D-104).
  Future<SendMessageResponse> send(String conversationId, String text, {List<AttachmentRef> attachments = const [], Map<String, Object?>? uiAction, List<String> skills = const []});
  Future<void> cancelRun(String runId);

  /// Edits a sent message: forks there and reruns (D-108).
  Future<SendMessageResponse> editMessage(String conversationId, String messageId, String text);

  /// Shows the branch containing [messageId].
  Future<void> switchBranch(String conversationId, String messageId);

  /// A message and its edited versions, oldest first.
  Future<List<String>> messageSiblings(String conversationId, String messageId);
  Stream<RunEventItem> watchRun(String runId, {int afterSeq = 0});
  Future<List<RunEventItem>> runEvents(String runId);
  Future<List<RunSummary>> runs(String botId);

  // Memory and skills
  Future<List<Memory>> memories(String botId);
  Future<void> updateMemory(String botId, String id, {String? content, bool? pinned});
  Future<void> deleteMemory(String botId, String id);
  // Memory backends (D-137)
  Future<MemoryBackend> memoryBackend(String orgId);
  Future<MemoryBackend> setMemoryBackend(String orgId, SetMemoryBackendRequest request);
  Future<MemoryBackend> removeMemoryBackend(String orgId);
  Future<List<SkillView>> skills(String orgId);
  Future<void> saveSkill(String orgId, {String? id, String? botId, required String name, required String description, required String bodyMd, bool enabled = true});
  Future<void> deleteSkill(String id);
  // Skills library (D-104)
  Future<SkillCatalog> skillCatalog();
  Future<void> installCatalogSkill(String orgId, String catalogId, {String? botId});
  Future<GitHubSkillPreview> previewGitHubSkill(String orgId, String url);
  Future<void> installGitHubSkill(String orgId, String url, String commit, {String? botId});
  Future<SkillUpdateCheck> checkSkillUpdate(String skillId);
  Future<void> applySkillUpdate(String skillId, String commit);

  // Approvals and notifications
  Future<List<Approval>> approvals(String orgId, {bool pendingOnly = true});
  Future<Approval> decideApproval(String approvalId, {required bool approve, bool alwaysAllow = false});
  Future<List<NotificationView>> notifications();
  Future<void> markNotificationsRead();
  Future<void> markNotificationRead(String id);

  /// New notifications for the signed-in user, live.
  Stream<NotificationView> watchNotifications();
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
  });
  Future<void> setRoutineEnabled(String routineId, bool enabled);
  Future<void> deleteRoutine(String routineId);
  Future<String> runRoutine(String routineId);

  // Integrations and secrets
  Future<List<Integration>> integrations(String orgId);
  Future<Integration> createIntegration(String orgId, {required String kind, required String name, required Map<String, Object?> config, String? secret});
  Future<IntegrationTestResult> testIntegration(String integrationId);
  Future<Set<String>> botIntegrationIds(String botId);
  Future<void> setBotIntegration(String botId, String integrationId, bool enabled);

  // Built-in apps (D-089)
  Future<AppCatalog> appCatalog();

  /// Connects an app: done at once with an API key, or a sign-in to open for OAuth.
  Future<ConnectAppResponse> connectApp(String orgId, {required String appId, required String method, String? apiKey, String? integrationId});
  Future<ConnectFlowStatus> connectStatus(String flowId);
  Future<void> deleteIntegration(String integrationId);
  Future<Integration> setToolRisks(String integrationId, Map<String, String> risks);
  Future<List<ProviderApp>> providerApps(String integrationId, {String? query});
  Future<String> connectProviderApp(String integrationId, String app);
  Future<List<ProviderAccount>> providerAccounts(String integrationId);
  Future<List<Secret>> secrets(String orgId);

  /// [totp]: a sign-in code seed (otpauth:// link or base32 key) bots use as {{totp:NAME}} (D-102).
  Future<void> createSecret(String orgId, {required String name, required String value, required List<String> hosts, bool totp = false});
  Future<void> deleteSecret(String secretId);

  // Task board
  Future<List<Task>> tasks(String orgId, {String? projectId});
  // Hosted MCP (D-117)
  Future<McpAuthRequestInfo> mcpAuthRequest(String id);
  Future<String> decideMcpAuthRequest(String id, {required String orgId, required bool approve});
  Future<List<McpKey>> mcpKeys(String orgId);
  Future<CreatedMcpKey> createMcpKey(String orgId, String name);
  Future<void> revokeMcpKey(String orgId, String keyId);
  Future<bool> mcpDecideApprovals(String orgId);
  Future<void> setMcpDecideApprovals(String orgId, bool allowed);
  // Bot-to-bot switch (D-133)
  Future<bool> allowBotToBot(String orgId);
  // Secret store (D-145)
  Future<SecretStoreSettings> secretStore(String orgId);
  Future<SecretStoreSettings> setSecretStore(String orgId, SetSecretStoreRequest request);
  Future<SecretStoreSettings> removeSecretStore(String orgId);
  // Linked agents (D-143)
  Future<List<BotLink>> botLinks(String botId);
  Future<CreatedBotLink> createBotLink(String botId, String name);
  Future<BotLink> acceptBotLink(String invite, String botId, String name);
  Future<BotLink> revokeBotLink(String id);
  Future<List<LinkExchange>> linkExchanges(String id);
  // Payments (D-142)
  Future<PaymentSettings> paymentSettings(String orgId);
  Future<PaymentSettings> setPaymentSettings(String orgId, SetPaymentSettingsRequest request);
  Future<PaymentSettings> removePaymentSettings(String orgId);
  Future<List<PaymentRequest>> paymentRequests(String orgId);
  // Calls for you (D-141)
  Future<TelephonySettings> telephony(String orgId);
  Future<TelephonySettings> setTelephony(String orgId, SetTelephonyRequest request);
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
  Future<PasswordManager> connectPasswordManager(CreatePasswordManagerRequest request);
  Future<List<PasswordManagerVault>> passwordManagerVaults(String id);
  Future<void> setPasswordManagerVaults(String id, List<String> vaults);
  Future<void> deletePasswordManager(String id);
  // Step replay (D-127)
  Future<List<Replay>> replays(String botId);
  Future<RunReplayResponse> runReplay(String id, Map<String, String> params);
  Future<void> deleteReplay(String id);
  Future<Replay> replayFromTeach(String teachId, String name, {String? description});
  // Self-improving skills (D-126)
  Future<List<SkillProposal>> skillProposals(String orgId, {String? botId});
  Future<void> acceptSkillProposal(String id, {String? bodyMd});
  Future<void> dismissSkillProposal(String id);
  Future<SkillStats> skillStats(String skillId);
  // Knowledge sources (D-125)
  Future<List<KnowledgeSource>> knowledgeSources(String orgId, {String? botId});
  Future<KnowledgeSource> addKnowledgeSource(CreateKnowledgeSourceRequest request);
  Future<void> resyncKnowledgeSource(String id);
  Future<void> deleteKnowledgeSource(String id);
  // Chat apps (D-134)
  Future<List<Channel>> channels(String botId);
  Future<Channel> createChannel(CreateChannelRequest request);
  Future<Channel> updateChannel(String id, {String? name, List<String>? allowedSenders, bool? enabled});
  Future<void> deleteChannel(String id);
  Future<List<ChannelEvent>> channelEvents(String id);
  // Routines and skills as files (D-124)
  Future<Uint8List> exportWorkspaceFiles(String orgId);
  Future<WorkspaceFilesResult> importWorkspaceFiles(String orgId, Uint8List zip, {bool dryRun = false});
  Future<GitSyncStatus> gitSync(String orgId);
  Future<GitSyncStatus> setGitSync(String orgId, {required String repo, String? branch, String? path, bool enabled = true});
  Future<GitSyncStatus> runGitSync(String orgId);
  Future<GitSyncStatus> deleteGitSync(String orgId);
  // Import an agent (D-122)
  Future<AgentImportPlan> startAgentImport(String orgId, {Uint8List? zip, Map<String, Uint8List>? files});
  Future<int> writeAgentImportFiles(String importId, String botId);
  Future<String> memoryImportPrompt();
  Future<List<ImportedMemoryItem>> parseMemoryImport(String text);
  Future<int> saveImportedMemories(String botId, List<ImportedMemoryItem> memories);
  // Plugins (D-121)
  Future<List<Plugin>> plugins(String botId);
  Future<PluginPreview> previewPlugin(String orgId, String url);
  Future<Plugin> installPlugin(String orgId, String botId, String url, String commit, Map<String, String> secrets);
  Future<PluginUpdatePreview> pluginUpdate(String id);
  Future<Plugin> updatePlugin(String id, String commit, {Map<String, String> secrets = const {}});
  Future<void> uninstallPlugin(String id);
  // Teach a task by showing it (D-120)
  Future<TeachSession> startTeach(String computerId, String botId);
  Future<TeachSession> teach(String id);
  Future<TeachStep> addTeachStep(String id, AddTeachStepRequest step);
  Future<TeachStep> markTeachSecret(String id, int seq, String name);
  Future<TeachSession> stopTeach(String id);
  Future<SaveTeachResponse> saveTeach(String id, {required String name, required String description, required String body, bool tryNow = false});
  Future<void> cancelTeach(String id);
  // Pages (D-119): opened in the system browser, never embedded.
  Future<List<BotPage>> pages(String orgId, {String? botId});
  Future<String> pageViewLink(String id, {bool pdf = false});

  /// Returns the new public link when made public.
  Future<String?> setPageVisibility(String id, BotPageVisibilityEnum visibility, {int? expiresInDays});
  Future<void> deletePage(String id);
  // Watchers (D-116)
  Future<List<Watcher>> watchers(String botId);
  Future<void> setWatcherPaused(String id, bool paused);
  Future<void> deleteWatcher(String id);
  // Action rules (D-115)
  Future<List<ActionRule>> actionRules(String orgId, {String? botId});
  Future<void> createActionRule(String orgId, {String? botId, required String category, required String rule, List<String> domains = const [], double? maxAmount});
  Future<void> deleteActionRule(String id);
  // Check-ins (D-114)
  Future<BotCheckins> botCheckins(String botId);
  Future<BotCheckins> setBotCheckins(String botId, BotCheckins settings);
  Future<ForYou> forYou(String orgId);
  Future<AcceptedSuggestion> acceptSuggestion(String id);
  Future<void> dismissSuggestion(String id, {bool dontSuggestAgain = false});
  // Projects (D-113)
  Future<List<Project>> projects(String orgId);
  Future<Project> createProject(String orgId, {required String title, required String goal, String doneCriteria, required String leadBotId, double? budgetUsd});
  Future<ProjectDetail> project(String projectId);
  Future<void> updateProject(String projectId, {String? status, double? budgetUsd});
  Future<void> approveProjectPlan(String projectId);
  Future<void> signOffMilestone(String projectId, String milestoneId);
  // Ticket board (D-098)
  Future<Task> createTask(String orgId, {required String title, String? details, String? priority, String? assigneeBotId, bool? reviewRequired});

  /// Changes a ticket; assigning a new bot starts its work.
  Future<Task> updateTask(String taskId, {String? title, String? details, String? status, String? priority, String? assigneeBotId, String? assigneeUserId, bool? reviewRequired, double? position});
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

  // Privacy and SSO (Phase 8)
  Future<Uint8List> exportMyData();
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
  Future<String> checkoutUrl(String orgId, {String? planCode, String? packCode});
  Future<String> billingPortalUrl(String orgId);
  Future<BillingSummary> verifyPurchase(String orgId, {required String source, required String productId, String? transactionId, String? purchaseToken});
  Future<BillingUsage> billingUsage(String orgId);
  Future<List<ConnectKey>> connectKeys(String orgId);
  Future<CreatedConnectKey> createConnectKey(String orgId, String instanceName);
  Future<void> revokeConnectKey(String orgId, String keyId);

  // Desktop companion (Phase 6)
  /// The API's base URL (the companion opens its WebSocket there).
  String get apiUrl;
  Future<List<LocalDevice>> localDevices(String orgId);
  Future<CreatedLocalDevice> createLocalDevice(String orgId, String name, String platform);
  Future<LocalDevice> updateLocalDevice(String id, {Set<String>? capabilities, List<String>? roots, List<String>? botIds, bool? enabled});

  /// Registers this computer's local MCP servers (no secrets) as local_mcp integrations (D-096).
  Future<List<Integration>> setLocalMcpServers(String deviceId, List<LocalMcpServerInfo> servers);
  Future<void> deleteLocalDevice(String id);

  // Voice (Phase 6)
  Future<String> transcribe(String botId, Uint8List audio, String mime);
  Future<Uint8List> speech(String messageId);
  Future<VoiceSession> voiceSession(String botId, {String? conversationId, String? callId});
  // Phone-call voice (D-135)
  Future<List<PhoneCall>> ringingCalls();
  Future<PhoneCall> answerCall(String id);
  Future<PhoneCall> declineCall(String id);

  /// iOS PushKit token, so calls ring through CallKit.
  Future<void> registerVoipToken(String token);
  Future<VoiceToolResult> voiceTool(String botId, String conversationId, String callId, String name, Map<String, Object?> arguments);
  Future<void> saveVoiceTranscript(String conversationId, List<(String, String)> turns, int seconds, {String? provider, Map<String, int>? usage});
  /// Changes some of a bot's voice settings; a null value clears that setting, others are kept.
  Future<void> updateBotVoice(String botId, Map<String, Object?> voice);

  /// A bot's voice settings (providers, voices, tools on calls).
  Future<Map<String, Object?>> loadBotVoice(String botId);

  // Computers: management (Phase 5)
  Future<Computer> createComputer(String orgId, {required String name, required bool private, String? ownerBotId, String profile});
  Future<Computer> updateComputer(String computerId, {String? name, String? profile, int? maxDesktops});
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

  // Device connections (D-149): data this person shares from their devices.
  Future<List<DeviceSource>> deviceSources();
  Future<DeviceSource> saveDeviceSource(String key, {required String name, required String platform, required Map<String, DeviceKindSettings> kinds});
  Future<void> deleteDeviceSource(String key);
  Future<int> uploadDeviceReadings(String key, List<DeviceReadingInput> readings, {String? requestId});
  Future<List<DeviceRequest>> deviceRequests(String key);
  Future<void> answerDeviceRequest(String id, {required bool ok, Map<String, Object?>? result, String? error});
  Future<List<DeviceGrant>> deviceGrants({String? botId});
  Future<List<DeviceGrant>> setDeviceGrant(String botId, DeviceKind kind, bool allowed);

  /// Fires when a run asks one of this person's devices for something (its request id).
  Stream<String> watchDeviceRequests();

  /// "Less like this" on a proactive message (D-153): saved as the bot's memory.
  Future<void> lessLikeThis(String notificationId);

  // Device triggers (D-151).
  Future<int> reportDeviceEvents(String key, List<DeviceEventInput> events);
  Future<List<DevicePlace>> devicePlaces();
  Future<DevicePlace> saveDevicePlace({required String name, required double latitude, required double longitude, int? radiusM});
  Future<void> deleteDevicePlace(String id);
  Future<List<TakeoverRequest>> takeovers(String orgId);
  Future<void> dismissTakeover(String takeoverId, {String? note});

  // Computers
  Future<List<Computer>> computers(String orgId);
  Future<Computer> startComputer(String id);
  Future<Computer> stopComputer(String id);
  Future<List<ComputerFileEntry>> listFiles(String computerId, String path);
  Future<Uint8List> downloadFile(String computerId, String path);
  Future<void> uploadFile(String computerId, String path, Uint8List bytes);
  Future<void> deleteFile(String computerId, String path);
  Future<List<Checkpoint>> checkpoints(String computerId);
  Future<void> restoreCheckpoint(String computerId, String checkpointId);
  Future<Uint8List?> screenshot(String computerId);
  Future<(Uri, Map<String, String>)> terminal(String computerId, {int cols, int rows});
}
