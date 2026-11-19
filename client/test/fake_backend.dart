import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart' show DioException, RequestOptions, Response;

import 'package:casama/core/backend.dart';
import 'package:casama/features/watch/watch_key_store.dart';
// The generated client's gallery models share names with core/gallery_models.dart (D-315).
import 'package:casama_sdk/casama_sdk.dart' hide GalleryItem, GalleryRef, GalleryAccess, GalleryNeeds, GalleryInput, GalleryChange, GalleryStats, GalleryAccessDiff, GalleryInstalledItem, GalleryMissing, GalleryInstallResult, GalleryRequest, GallerySubmission;

const orgId = '11111111-1111-4111-8111-111111111111';
const botId = '22222222-2222-4222-8222-222222222222';
const runId = '33333333-3333-4333-8333-333333333333';
const convId = '44444444-4444-4444-8444-444444444444';
const computerId = '55555555-5555-4555-8555-555555555555';

Map<String, dynamic> eventJson(
  int seq,
  String type,
  Map<String, dynamic> payload,
) => {
  'v': 1,
  'run_id': runId,
  'seq': seq,
  'ts': '2026-11-10T09:00:00.000Z',
  'bot_id': botId,
  'type': type,
  'payload': payload,
};

RunEventItem ev(int seq, String type, Map<String, dynamic> payload) =>
    RunEventItem.fromJson(eventJson(seq, type, payload));

/// In-memory backend for widget tests.
class FakeBackend implements Backend {
  var signedIn = true;
  final _auth = StreamController<bool>.broadcast();
  final runEventsController = StreamController<RunEventItem>.broadcast();
  final sent = <String>[];
  var cancelled = false;
  List<ChatMessageView> storedMessages = [];
  List<RunEventItem> storedEvents = [];

  @override
  String? defaultModelFor(String provider) =>
      const {'openrouter': 'deepseek/deepseek-v4.1-flash-1017', 'openai': 'gpt-6-luna'}[provider];

  @override
  Stream<bool> get signedInChanges => _auth.stream;
  @override
  bool get isSignedIn => signedIn;
  @override
  String? get userEmail => 'tester@example.com';
  /// Who is signed in; a test of a second account on the same phone changes it.
  String? signedInAs = 'me';
  @override
  String? get userId => signedInAs;
  @override
  Future<void> signIn(String email, String password) async {
    signedIn = true;
    _auth.add(true);
  }

  /// False: the server wants the address confirmed first (no session yet).
  var signUpSignsIn = true;
  @override
  Future<bool> signUp(String email, String password) async => signUpSignsIn;
  String? magicLinkEmail;
  @override
  Future<void> sendMagicLink(String email) async => magicLinkEmail = email;
  String? verifiedCode;
  Object? verifyCodeError;
  @override
  Future<void> verifyEmailCode(String email, String code) async {
    if (verifyCodeError != null) throw verifyCodeError!;
    verifiedCode = code;
  }

  final providerSignIns = <String>[];
  @override
  Future<void> signInWithProvider(String provider) async =>
      providerSignIns.add(provider);
  @override
  Future<void> signOut() async {
    // Like the real one (D-410): the watches this phone signed in go while the session works.
    if (_watchesInPlay) await WatchKeyStore.signingOut(userId, deleteWatchKey);
    signedIn = false;
    _auth.add(false);
  }

  /// Whether this test has watches at all. The records are in SharedPreferences, which a widget
  /// test that never set it up can't read, so tests without watches don't go there.
  bool get _watchesInPlay => watchKeys.isNotEmpty || watchKeysRegistered.isNotEmpty;

  /// The session ended by itself (signed out from another device, a changed password): nothing
  /// is taken back on the way out.
  void endSession() {
    signedIn = false;
    _auth.add(false);
  }

  var hasOrg = true;

  /// The signed-in person's role in the workspace.
  var orgRole = OrgRole.owner;
  var createdOrgs = 0;

  @override
  Future<List<OrganizationWithRole>> organizations() async => !hasOrg
      ? const []
      : [
          OrganizationWithRole(
            id: orgId,
            name: orgName,
            slug: 'test-org',
            plan: 'selfhost',
            region: 'local',
            icon: orgIcon,
            color: orgColor,
            createdAt: DateTime(2026),
            role: orgRole,
            suspended: orgSuspended,
            requireAppLock: requireAppLockValue,
          ),
          ...extraOrgs,
        ];
  var orgName = 'Test Org';
  String? orgIcon;
  String? orgColor;
  final extraOrgs = <OrganizationWithRole>[];
  final links = <InviteLink>[];
  final joined = <String>[];
  @override
  Future<Organization> updateOrg(
    String orgId, {
    String? name,
    String? icon,
    String? color,
  }) async {
    orgName = name ?? orgName;
    orgIcon = icon ?? orgIcon;
    orgColor = color ?? orgColor;
    return Organization(
      id: orgId,
      name: orgName,
      slug: 'test-org',
      plan: 'selfhost',
      region: 'local',
      icon: orgIcon,
      color: orgColor,
      createdAt: DateTime(2026),
    );
  }

  @override
  Future<List<InviteLink>> inviteLinks(String orgId) async => List.of(links);
  @override
  Future<CreatedInviteLink> createInviteLink(
    String orgId, {
    String role = 'member',
    int? expiresInDays,
    int? maxUses,
  }) async {
    final id = 'l${links.length + 1}';
    final r = role == 'admin'
        ? InviteLinkRoleEnum.admin
        : InviteLinkRoleEnum.member;
    links.add(
      InviteLink(
        id: id,
        orgId: orgId,
        role: r,
        tokenHint: 'kjoin_abcd',
        expiresAt: null,
        maxUses: maxUses,
        uses: 0,
        revokedAt: null,
        createdAt: DateTime(2026),
      ),
    );
    return CreatedInviteLink(
      id: id,
      orgId: orgId,
      role: role == 'admin'
          ? CreatedInviteLinkRoleEnum.admin
          : CreatedInviteLinkRoleEnum.member,
      tokenHint: 'kjoin_abcd',
      expiresAt: null,
      maxUses: maxUses,
      uses: 0,
      revokedAt: null,
      createdAt: DateTime(2026),
      token: 'kjoin_abcdefghijklmnop',
      url: 'https://app.example.com/join/kjoin_abcdefghijklmnop',
    );
  }

  @override
  Future<void> revokeInviteLink(String orgId, String linkId) async =>
      links.removeWhere((l) => l.id == linkId);
  @override
  Future<OrganizationWithRole> acceptInviteLink(String token) async {
    joined.add(token);
    final o = OrganizationWithRole(
      id: '99999999-0000-4000-8000-000000000001',
      name: 'Friends',
      slug: 'friends',
      plan: 'selfhost',
      region: 'local',
      createdAt: DateTime(2026),
      role: OrgRole.member,
    );
    extraOrgs.add(o);
    return o;
  }

  @override
  Future<List<WorkspaceBadge>> workspaceBadges() async => [
    WorkspaceBadge(orgId: orgId, approvals: 1, unread: 2),
  ];
  bool orgSuspended = false;
  @override
  Future<Organization> createOrganization(String name) async {
    createdOrgs++;
    hasOrg = true;
    return Organization(
      id: orgId,
      name: name,
      slug: 'test-org',
      plan: 'selfhost',
      region: 'local',
      createdAt: DateTime(2026),
    );
  }

  @override
  Future<void> acceptInvite(String token) async {}
  @override
  Future<Invite> invite(
    String orgId,
    String email, {
    bool admin = false,
  }) async => throw UnimplementedError();

  // --- joining (D-165) ---
  var defaultApproval = false;
  var defaultResets = 0;
  final joinRequestList = <JoinRequest>[];
  final decided = <String>[];
  final pendingInviteList = <PendingInvite>[];
  final invitedEmails = <String>[];
  final revokedInvites = <String>[];
  final resentInvites = <String>[];
  var joinDomainList = <String>[];
  var myDomain = 'acme.dev';
  var joinableList = <JoinableWorkspace>[];
  final domainJoins = <String>[];
  var codesMade = 0;
  CreatedInviteLink _created(
    String token, {
    bool isDefault = false,
    InviteLinkKindEnum kind = InviteLinkKindEnum.link,
  }) => CreatedInviteLink.fromJson({
    'id': isDefault ? 'default' : 'code$codesMade',
    'org_id': orgId,
    'role': 'member',
    'token_hint': token.substring(0, 4),
    'expires_at': null,
    'max_uses': null,
    'uses': 0,
    'revoked_at': null,
    'created_at': DateTime(2026).toIso8601String(),
    'kind': kind.value,
    'requires_approval': isDefault && defaultApproval,
    'is_default': isDefault,
    'token': token,
    'url': 'https://app.example.com/join/$token',
  });
  String get _defaultToken => 'kjoin_default${defaultResets}abcdefghijk';
  @override
  Future<CreatedInviteLink> defaultInvite(String orgId) async =>
      _created(_defaultToken, isDefault: true);
  @override
  Future<CreatedInviteLink> updateDefaultInvite(
    String orgId, {
    bool? requiresApproval,
    bool reset = false,
  }) async {
    if (reset) defaultResets++;
    defaultApproval = requiresApproval ?? defaultApproval;
    return _created(_defaultToken, isDefault: true);
  }

  @override
  Future<CreatedInviteLink> createInviteCode(
    String orgId, {
    String role = 'member',
  }) async {
    codesMade++;
    return _created('7F3Q-9XWD', kind: InviteLinkKindEnum.code);
  }

  final friendsOrg = OrganizationWithRole(
    id: '99999999-0000-4000-8000-000000000001',
    name: 'Friends',
    slug: 'friends',
    plan: 'selfhost',
    region: 'local',
    createdAt: DateTime(2026),
    role: OrgRole.member,
  );
  @override
  Future<InvitePreview> previewInvite(String invite) async {
    if (invite.contains('bad')) throw Exception('invite_invalid');
    return InvitePreview.fromJson({
      'kind': invite.contains('kinv_')
          ? 'email'
          : (invite.contains('kjoin_') ? 'link' : 'code'),
      'workspace': {
        'name': 'Friends',
        'icon': 'heart',
        'color': '#ec4899',
        'member_count': 4,
      },
      'role': 'member',
      'inviter_name': 'Sam',
      'requires_approval': invite.contains('gate'),
      'email_hint': invite.contains('kinv_') ? 'm•••@example.com' : null,
      'already_member': false,
    });
  }

  @override
  Future<JoinResult> joinWithInvite(String invite) async {
    joined.add(invite);
    if (invite.contains('gate')) {
      return JoinResult(
        status: JoinResultStatusEnum.requested,
        organization: null,
        workspaceName: 'Friends',
      );
    }
    if (!extraOrgs.any((o) => o.id == friendsOrg.id)) extraOrgs.add(friendsOrg);
    return JoinResult(
      status: JoinResultStatusEnum.joined,
      organization: friendsOrg,
      workspaceName: 'Friends',
    );
  }

  @override
  Future<List<JoinRequest>> joinRequests(String orgId) async =>
      joinRequestList.where((r) => !decided.contains(r.id)).toList();
  @override
  Future<JoinRequest> decideJoinRequest(
    String orgId,
    String requestId,
    bool approve,
  ) async {
    decided.add('$requestId:${approve ? 'approve' : 'decline'}');
    decided.add(requestId);
    return joinRequestList.firstWhere((r) => r.id == requestId);
  }

  @override
  Future<List<PendingInvite>> pendingInvites(String orgId) async =>
      pendingInviteList.where((i) => !revokedInvites.contains(i.id)).toList();
  @override
  Future<List<Invite>> inviteMany(
    String orgId,
    List<String> emails, {
    bool admin = false,
  }) async {
    invitedEmails.addAll(emails);
    return [
      for (final (i, e) in emails.indexed)
        Invite(
          id: 'inv$i',
          orgId: orgId,
          email: e,
          role: admin ? OrgRole.admin : OrgRole.member,
          expiresAt: DateTime(2026, 2),
          emailSent: true,
        ),
    ];
  }

  @override
  Future<Invite> resendInvite(String orgId, String inviteId) async {
    resentInvites.add(inviteId);
    return Invite(
      id: inviteId,
      orgId: orgId,
      email: 'x@example.com',
      role: OrgRole.member,
      expiresAt: DateTime(2026, 2),
      emailSent: true,
    );
  }

  @override
  Future<void> revokeInvite(String orgId, String inviteId) async =>
      revokedInvites.add(inviteId);
  @override
  Future<JoinDomains> joinDomains(String orgId) async => JoinDomains(
    items: List.of(joinDomainList),
    myDomain: myDomain,
    canUse: myDomain != 'gmail.com',
  );
  @override
  Future<JoinDomains> setJoinDomain(
    String orgId,
    bool enabled, {
    String? domain,
  }) async {
    joinDomainList = enabled ? [myDomain] : [];
    return joinDomains(orgId);
  }

  @override
  Future<List<JoinableWorkspace>> joinableWorkspaces() async =>
      List.of(joinableList);
  @override
  Future<OrganizationWithRole> joinByDomain(String orgId) async {
    domainJoins.add(orgId);
    joinableList = joinableList.where((w) => w.id != orgId).toList();
    hasOrg = true;
    if (!extraOrgs.any((o) => o.id == friendsOrg.id)) extraOrgs.add(friendsOrg);
    return friendsOrg;
  }

  @override
  Future<List<Credential>> credentials(String orgId) async => noKeys
      ? const []
      : [
          Credential(
            id: 'cred',
            orgId: orgId,
            provider: ProviderId.openrouter,
            label: 'Main',
            baseUrl: null,
            keyHint: '1234',
            lastTestedAt: null,
            lastTestOk: null,
            ownerUserId: null,
            status: CredentialStatus.ok,
            account: null,
            fallbackOnLimit: false,
            embeddingModel: null,
            createdAt: DateTime(2026),
          ),
          ...extraCredentials,
        ];

  /// Extra keys for a test (for example a ChatGPT plan).
  List<Credential> extraCredentials = [];
  @override
  Set<String> serverVoice = {};
  @override
  KeyProviders keyProviders = KeyProviders.fallback;

  @override
  bool chatGptSignIn = true;
  @override
  bool canConnectChatGpt = false;
  final connectedChatGpt = <String>[];
  @override
  Future<Credential> connectChatGpt(
    String orgId, {
    String? credentialId,
  }) async {
    connectedChatGpt.add(credentialId ?? orgId);
    return chatGptCredential(orgId);
  }

  final credentialUpdates = <String, bool?>{};
  @override
  Future<Credential> updateCredential(
    String credentialId, {
    String? label,
    bool? fallbackOnLimit,
  }) async {
    credentialUpdates[credentialId] = fallbackOnLimit;
    return chatGptCredential('org', fallbackOnLimit: fallbackOnLimit ?? false);
  }

  final deletedCredentials = <String>[];
  @override
  Future<void> deleteCredential(String credentialId) async =>
      deletedCredentials.add(credentialId);
  @override
  Future<Credential> addCredential(
    String orgId,
    ProviderId provider,
    String label, {
    String? apiKey,
    String? baseUrl,
  }) async => throw UnimplementedError();
  @override
  Future<CredentialTestResult> testCredential(
    String credentialId, {
    String? model,
  }) async => CredentialTestResult(ok: true, model: 'm', latencyMs: 12);
  @override
  Future<ModelOptionList> models(String credentialId) async => ModelOptionList(
    items: [
      ModelOption(
        id: 'deepseek/deepseek-v4.1-flash-1017',
        name: 'DeepSeek: DeepSeek V4.1 Flash 1017',
        featured: true,
      ),
      ModelOption(
        id: 'meta/muse-ember',
        name: 'Meta: Muse Ember',
        featured: true,
      ),
      ModelOption(
        id: 'openai/gpt-6-luna',
        name: 'OpenAI: GPT-6 Luna',
        featured: true,
      ),
      ModelOption(
        id: 'anthropic/claude-sonnet-5.5',
        name: 'Anthropic: Claude Sonnet 5.5',
        featured: true,
      ),
      ModelOption(id: 'acme/other', name: 'Acme: Other'),
    ],
    source_: ModelOptionListSource_Enum.live,
  );

  Bot bot({
    BotStatusEnum status = BotStatusEnum.idle,
    String id = botId,
    String name = 'Ada',
    DateTime? createdAt,
  }) => Bot(
    id: id,
    orgId: orgId,
    name: name,
    avatarUrl: null,
    personaMd: '',
    modelPolicy: ModelPolicy(
      primary: ModelChoice(credentialId: 'cred', model: 'fixture'),
    ),
    autonomy: Autonomy.askRisky,
    visibility: Visibility.team,
    budget: BotBudget(perRunUsd: 1, dailyUsd: 10),
    status: status,
    defaultComputerId: defaultComputer,
    folderId: botFolder,
    archivedAt: null,
    setupStatus: setupStatus,
    sortKey: 0,
    createdAt: createdAt ?? DateTime(2026),
    lastMessage: id == botId ? lastMessage : null,
  );

  /// Ada's last message, shown on the chats list.
  BotLastMessage? lastMessage;
  String? botFolder;
  final archived = <String>{};
  final revisions = <BotRevision>[
    BotRevision(
      id: 'rev-1',
      snapshot: const {
        'name': 'Ada',
        'persona_md': 'Be brief.',
        'autonomy': 'ask_always',
      },
      changedFields: const ['persona_md', 'autonomy'],
      changedByBot: 'bot-2',
      createdAt: DateTime(2026, 11, 9, 10),
    ),
  ];
  BotRevision? restored;
  final mcpActions = <String>[];
  bool mcpApprovals = false;
  @override
  Future<McpAuthRequestInfo> mcpAuthRequest(String id) async =>
      McpAuthRequestInfo(
        id: id,
        clientName: 'Phone AI',
        redirectHost: 'ai.example',
        expiresAt: DateTime(2030),
      );
  @override
  Future<String> decideMcpAuthRequest(
    String id, {
    required String orgId,
    required bool approve,
  }) async {
    mcpActions.add('${approve ? 'allow' : 'refuse'}:$orgId');
    return 'https://ai.example/callback?code=x';
  }

  @override
  Future<List<McpKey>> mcpKeys(String orgId) async => storedMcpKeys;
  List<McpKey> storedMcpKeys = const [];
  @override
  Future<CreatedMcpKey> createMcpKey(String orgId, String name) async {
    mcpActions.add('key:$name');
    return CreatedMcpKey(
      id: 'k1',
      name: name,
      hint: 'abcd',
      lastUsedAt: null,
      createdAt: DateTime(2026),
      key: 'ksk_secret_abcd',
      mcpUrl: 'http://api/mcp',
    );
  }

  @override
  Future<void> revokeMcpKey(String orgId, String keyId) async =>
      mcpActions.add('revoke:$keyId');
  @override
  Future<bool> mcpDecideApprovals(String orgId) async => mcpApprovals;
  @override
  Future<void> setMcpDecideApprovals(String orgId, bool allowed) async =>
      mcpApprovals = allowed;
  final watcherList = <Watcher>[
    Watcher(
      id: 'w1',
      botId: botId,
      name: 'Price drop',
      kind: WatcherKindEnum.pageChange,
      target: const {'url': 'https://shop.example/item'},
      conditionMd: 'the price changes',
      status: WatcherStatusEnum.active,
      checkEverySeconds: 900,
      firedCount: 2,
      lastCheckedAt: null,
      lastError: null,
      expiresAt: null,
      conversationId: null,
      createdAt: DateTime(2026),
    ),
  ];
  final watcherActions = <String>[];
  @override
  Future<List<Watcher>> watchers(String botId) async => List.of(watcherList);
  @override
  Future<void> setWatcherPaused(String id, bool paused) async =>
      watcherActions.add('${paused ? 'pause' : 'resume'}:$id');
  @override
  Future<void> deleteWatcher(String id) async =>
      watcherActions.add('delete:$id');
  final rules = <ActionRule>[];
  @override
  Future<List<ActionRule>> actionRules(String orgId, {String? botId}) async =>
      List.of(rules);
  @override
  Future<void> createActionRule(
    String orgId, {
    String? botId,
    required String category,
    required String rule,
    List<String> domains = const [],
    double? maxAmount,
  }) async {
    rules.add(
      ActionRule(
        id: 'rule${rules.length + 1}',
        orgId: orgId,
        botId: botId,
        matchKind: ActionRuleMatchKindEnum.category,
        matchValue: category,
        target: domains.isEmpty && maxAmount == null
            ? null
            : ActionRuleTarget(domains: domains, maxAmount: maxAmount),
        rule: ActionRuleRuleEnum.values.firstWhere((r) => r.value == rule),
        preview: domains.isEmpty
            ? '$category: $rule'
            : 'Sends messages to anyone at ${domains.join(' or ')} without asking',
        createdAt: DateTime(2026),
      ),
    );
  }

  @override
  Future<void> deleteActionRule(String id) async =>
      rules.removeWhere((r) => r.id == id);
  BotCheckins checkins = BotCheckins(
    enabled: false,
    briefTime: '08:00',
    scanEveryHours: 3,
    dailyCapUsd: 1,
  );
  final suggestionActions = <String>[];
  @override
  Future<BotCheckins> botCheckins(String botId) async => checkins;
  @override
  Future<BotCheckins> setBotCheckins(
    String botId,
    BotCheckins settings,
  ) async => checkins = settings;
  @override
  Future<ForYou> forYou(String orgId) async => ForYou(
    briefs: [
      ForYouBrief(
        botId: botId,
        conversationId: convId,
        text: 'Today: 10:00 Standup.',
        createdAt: DateTime(2026, 11, 10, 8),
      ),
    ],
    suggestions: [
      if (!suggestionActions.any((a) => a.endsWith(':s1')))
        Suggestion(
          id: 's1',
          botId: botId,
          title: 'Reply to Ana',
          bodyMd: 'She asked twice.',
          proposedAction: null,
          sources: const [],
          urgency: SuggestionUrgencyEnum.urgent,
          expiresAt: DateTime(2026, 11, 12),
          createdAt: DateTime(2026, 11, 10),
        ),
    ],
    approvals: const [],
  );
  @override
  Future<AcceptedSuggestion> acceptSuggestion(String id) async {
    final error = acceptError;
    if (error != null) throw error;
    suggestionActions.add('accept:$id');
    return AcceptedSuggestion(conversationId: convId, runId: 'r-s');
  }

  // Widgets (D-405)
  /// What [glance] answers; null is a server from before widgets (404).
  Map<String, Object?>? glanceJson;

  /// The ETag sent with each glance answer; a matching If-None-Match answers unchanged.
  String glanceEtag = '"g1"';

  /// Each glance call's If-None-Match, in order.
  final glanceCalls = <String?>[];

  /// Fails the glance calls while set (offline).
  Object? glanceError;
  @override
  Future<GlanceData?> glance(String orgId, {String? ifNoneMatch}) async {
    glanceCalls.add(ifNoneMatch);
    final error = glanceError;
    if (error != null) throw error;
    final json = glanceJson;
    if (json == null) return null;
    if (ifNoneMatch != null && ifNoneMatch == glanceEtag) return GlanceData.unchanged(ifNoneMatch);
    return GlanceData.fromJson(json, etag: glanceEtag);
  }

  /// Whether the server has widget keys (false answers null, as a 404 does).
  bool widgetKeysSupported = true;

  /// Keys made, as (org, platform, label); deleted ids; privacy changes; push tokens.
  final widgetKeysCreated = <(String, String, String?)>[];
  final widgetKeysDeleted = <String>[];
  final widgetKeyPrivacy = <(String, bool)>[];
  final widgetPushTokens = <(String, String, String)>[];
  @override
  Future<NewWidgetKey?> createWidgetKey(String orgId, String platform, {String? label}) async {
    if (!widgetKeysSupported) return null;
    widgetKeysCreated.add((orgId, platform, label));
    final n = widgetKeysCreated.length;
    return NewWidgetKey(id: 'wk$n', key: 'cwk_secret$n', createdAt: DateTime(2026, 11, 18));
  }

  @override
  Future<void> deleteWidgetKey(String id) async => widgetKeysDeleted.add(id);

  @override
  Future<void> setWidgetKeyPrivate(String id, bool private) async => widgetKeyPrivacy.add((id, private));

  @override
  Future<void> registerWidgetPushToken(String widgetKey, String token, {required String kind, bool? sandbox}) async =>
      widgetPushTokens.add((widgetKey, token, kind));

  // Watches (D-410)
  /// The signed-in watches [listWatchKeys] answers (all workspaces; filtered by org).
  List<WatchKeyView> watchKeys = [];

  /// Registrations, as (org, fingerprint, name); deleted ids.
  final watchKeysRegistered = <(String, String, String)>[];
  final watchKeysDeleted = <String>[];

  /// The key each fingerprint has, as the server keeps one row per key (its id stays when the same
  /// watch is registered again, for another workspace say).
  final _watchKeyIds = <String, String>{};
  var _watchKeysMade = 0;

  /// Fails registrations while set.
  Object? watchRegisterError;

  /// False: a server from before `DELETE /v1/watch-keys` (Sign Out Everywhere falls back).
  var watchDeleteAllSupported = true;

  /// How many times every watch key was deleted in one go.
  var watchKeysDeletedAll = 0;

  /// Fails looking a code up or allowing it while set (no connection, too many tries).
  Object? watchCodeError;

  /// Allowing a code answers "this watch is signed in to another account" while true.
  var watchCodeTaken = false;

  /// What [watchPrefs] answers; null is a server from before watches.
  WatchPrefsView? storedWatchPrefs = const WatchPrefsView(quickReplies: ['On my way', 'Thanks', 'Yes', 'No']);
  final watchPrefsUpdates = <({WatchAllowance? allow, bool? showDetails, List<String>? quickReplies})>[];

  /// Codes a watch shows, by normalized code; claimed codes, as (code, org).
  final watchCodes = <String, WatchCodeView>{};
  final watchCodesClaimed = <(String, String)>[];

  @override
  Future<List<WatchKeyView>> listWatchKeys(String orgId) async => [for (final k in watchKeys) if (k.orgId == orgId) k];

  /// Workspaces whose watch keys can't be asked for right now (offline), and ones the person has
  /// left (the server answers 404 org_not_found).
  final watchListDown = <String>{};
  final watchOrgsLeft = <String>{};

  @override
  Future<Set<String>?> watchKeyIdsIn(String orgId) async {
    if (watchListDown.contains(orgId)) throw Exception('offline');
    if (watchOrgsLeft.contains(orgId)) return null;
    return {for (final k in watchKeys) if (k.orgId == orgId) k.id};
  }

  /// Fails deleting watch keys while set, one by one and all at once (offline, a slow server).
  Object? watchDeleteError;

  @override
  Future<WatchKeyView> registerWatchKey({
    required String orgId,
    required String fingerprint,
    required WatchSystem platform,
    required String name,
    String? model,
    String? appVersion,
    String? osVersion,
  }) async {
    final error = watchRegisterError;
    if (error != null) throw error;
    watchKeysRegistered.add((orgId, fingerprint, name));
    // The same watch again keeps its key (and id); a key that was removed is made anew.
    final had = _watchKeyIds[fingerprint];
    final id = had != null && watchKeys.any((k) => k.id == had) ? had : 'watch${++_watchKeysMade}';
    _watchKeyIds[fingerprint] = id;
    final key = WatchKeyView(
      id: id,
      orgId: orgId,
      platform: platform,
      name: name,
      model: model,
      createdAt: DateTime.utc(2026, 11, 19),
    );
    watchKeys = [for (final k in watchKeys) if (k.id != id) k, key];
    return key;
  }

  @override
  Future<void> deleteWatchKey(String id) async {
    // No session, no delete: the server answers 401.
    if (!signedIn) throw Exception('401: not signed in');
    final error = watchDeleteError;
    if (error != null) throw error;
    watchKeysDeleted.add(id);
    watchKeys = [for (final k in watchKeys) if (k.id != id) k];
  }

  @override
  Future<int?> deleteAllWatchKeys() async {
    if (!signedIn) throw Exception('401: not signed in');
    final error = watchDeleteError;
    if (error != null) throw error;
    if (!watchDeleteAllSupported) return null;
    watchKeysDeletedAll++;
    final n = watchKeys.length;
    watchKeys = [];
    return n;
  }

  @override
  Future<WatchPrefsView?> watchPrefs() async => storedWatchPrefs;

  /// While set, a settings save waits here (taken by that save); completing it with an error
  /// fails the save.
  Completer<void>? watchPrefsGate;

  /// Fails every settings save while set (offline).
  Object? watchPrefsError;

  @override
  Future<WatchPrefsView> updateWatchPrefs({WatchAllowance? allow, bool? showDetails, List<String>? quickReplies}) async {
    watchPrefsUpdates.add((allow: allow, showDetails: showDetails, quickReplies: quickReplies));
    final gate = watchPrefsGate;
    watchPrefsGate = null;
    if (gate != null) await gate.future;
    final error = watchPrefsError;
    if (error != null) throw error;
    final now = storedWatchPrefs ?? const WatchPrefsView();
    return storedWatchPrefs = now.copyWith(
      allow: allow,
      showDetails: showDetails,
      // Empty goes back to the built-in list.
      quickReplies: quickReplies == null ? null : (quickReplies.isEmpty ? const ['On my way', 'Thanks', 'Yes', 'No'] : quickReplies),
    );
  }

  /// How many times a code was looked up (each one spends a try on the server).
  var watchCodeLookups = 0;

  @override
  Future<WatchCodeView?> watchCodeInfo(String code) async {
    watchCodeLookups++;
    final error = watchCodeError;
    if (error != null) throw error;
    return watchCodes[code];
  }

  @override
  Future<WatchKeyView?> claimWatchCode(String code, String orgId) async {
    final error = watchCodeError;
    if (error != null) throw error;
    if (watchCodeTaken && watchCodes.containsKey(code)) throw const WatchKeyTaken();
    final info = watchCodes.remove(code);
    if (info == null) return null;
    watchCodesClaimed.add((code, orgId));
    final key = WatchKeyView(
      id: 'code-watch${watchCodesClaimed.length}',
      orgId: orgId,
      platform: info.platform,
      name: info.name,
      model: info.model,
      pairedBy: 'code',
      createdAt: DateTime.utc(2026, 11, 19),
    );
    watchKeys = [...watchKeys, key];
    return key;
  }

  @override
  Future<void> dismissSuggestion(
    String id, {
    bool dontSuggestAgain = false,
  }) async =>
      suggestionActions.add('${dontSuggestAgain ? 'never' : 'dismiss'}:$id');

  /// Fails Do it when set (a limit reached: the suggestion stays open).
  Object? acceptError;

  /// Where suggestions stand, by id; the rest read from [suggestionActions] (open until acted on).
  final suggestionStateOverrides = <String, SuggestionState>{};
  @override
  Future<Map<String, SuggestionState>> suggestionStates(List<String> ids) async => {
    for (final id in ids)
      id: suggestionStateOverrides[id] ??
          (suggestionActions.contains('accept:$id')
              ? SuggestionState(status: SuggestionStatus.accepted, resolvedAt: DateTime.now(), conversationId: convId)
              : suggestionActions.any((a) => a.endsWith(':$id'))
              ? SuggestionState(status: SuggestionStatus.dismissed, resolvedAt: DateTime.now())
              : const SuggestionState(status: SuggestionStatus.pending)),
  };
  ProjectDetail projectDetail = ProjectDetail(
    id: 'p1',
    orgId: orgId,
    slug: 'launch',
    title: 'Launch site',
    goalMd: 'Put the launch page live.',
    doneCriteriaMd: 'Public page',
    status: ProjectStatus.planning,
    planStatus: ProjectDetailPlanStatusEnum.proposed,
    statusReason: null,
    leadBotId: botId,
    ownerUserId: null,
    conversationId: null,
    budgetUsd: 50,
    spentUsd: 12.5,
    deadlineAt: null,
    planMd: 'Build, then ship.',
    sessions: 0,
    createdAt: DateTime(2026),
    milestones: [
      ProjectMilestone(
        id: 'm1',
        name: 'Build',
        position: 1,
        requiresSignoff: true,
        status: ProjectMilestoneStatusEnum.awaitingSignoff,
        ticketsDone: 1,
        ticketsTotal: 1,
      ),
    ],
    runs: const [],
  );
  final projectActions = <String>[];

  /// The workspace's projects; the one in [projectDetail] when not set.
  List<Project>? projectList;
  @override
  Future<List<Project>> projects(String orgId) async =>
      projectList ?? [Project.fromJson(projectDetail.toJson())];
  @override
  Future<Project> createProject(
    String orgId, {
    required String title,
    String goal = '',
    String doneCriteria = '',
    required String leadBotId,
    double? budgetUsd,
    bool autonomous = false,
    String? conversationId,
  }) async {
    projectActions.add(
      autonomous
          ? 'create:$title:$budgetUsd'
          : 'create-light:$title${conversationId == null ? '' : ':$conversationId'}',
    );
    return Project.fromJson(projectDetail.toJson());
  }

  @override
  Future<ProjectDetail> project(String projectId) async => projectDetail;
  @override
  Future<void> updateProject(
    String projectId, {
    String? status,
    double? budgetUsd,
    bool? autonomous,
    String? goal,
    String? doneCriteria,
  }) async => projectActions.add(
    autonomous == null
        ? 'status:$status'
        : 'autonomous:$autonomous${goal == null ? '' : ':$goal'}',
  );
  @override
  Future<void> approveProjectPlan(String projectId) async =>
      projectActions.add('approve');
  @override
  Future<void> signOffMilestone(String projectId, String milestoneId) async =>
      projectActions.add('signoff:$milestoneId');
  final shares = <bool>[];
  ({String credentialId, String model, bool memories, bool routines})? imported;
  BotTemplateFile template() => BotTemplateFile(
    format: BotTemplateFileFormatEnum.casamaPeriodBot,
    version: 1,
    name: 'Invoicer',
    personaMd: 'You chase unpaid invoices politely.',
    autonomy: BotTemplateFileAutonomyEnum.askRisky,
    skills: [
      BotTemplateFileSkillsInner(
        name: 'dunning',
        description: 'Follow-up cadence',
        bodyMd: '1. Day 7',
      ),
    ],
    routines: [
      BotTemplateFileRoutinesInner(
        name: 'Weekly chase',
        instructionsMd: 'Chase.',
        scheduleCron: '0 9 * * 1',
      ),
    ],
    connections: [
      BotTemplateFileConnectionsInner(kind: 'composio', name: 'Gmail'),
    ],
    memories: [
      BotTemplateFileMemoriesInner(
        kind: BotTemplateFileMemoriesInnerKindEnum.fact,
        content: 'Acme pays late',
      ),
    ],
  );
  @override
  Future<BotTemplateFile> exportBot(
    String botId, {
    bool memories = false,
  }) async => template();
  @override
  Future<BotShareLink> createBotShare(
    String botId, {
    bool memories = false,
  }) async {
    shares.add(memories);
    return BotShareLink(
      token: 't0k3n',
      url: 'https://app.example/import/t0k3n',
      expiresAt: null,
    );
  }

  @override
  Future<BotTemplateFile> getBotShare(String token) async => template();
  @override
  Future<ImportBotResponse> importBot(
    String orgId,
    BotTemplateFile template, {
    required String credentialId,
    required String model,
    bool memories = true,
    bool routines = true,
  }) async {
    imported = (
      credentialId: credentialId,
      model: model,
      memories: memories,
      routines: routines,
    );
    importedTemplate = template;
    return ImportBotResponse(
      botId: 'bot-new',
      skills: 1,
      routines: routines ? 1 : 0,
      memories: memories ? 1 : 0,
      connectionsToAdd: [
        for (final c
            in template.connections ??
                const <BotTemplateFileConnectionsInner>[])
          ImportBotResponseConnectionsToAddInner(kind: c.kind, name: c.name),
      ],
    );
  }

  QuietHoursView quiet = const QuietHoursView(
    enabled: false,
    start: '22:00',
    end: '07:00',
  );
  final botQuiets = <String, BotQuietView>{};
  @override
  Future<QuietHoursView> quietHours() async => quiet;
  @override
  Future<void> setQuietHours(QuietHoursView hours) async => quiet = hours;
  PushPrefs prefs = const PushPrefs();
  @override
  Future<PushPrefs> pushPrefs() async => prefs;
  @override
  Future<void> setPushPrefs(PushPrefs value) async => prefs = value;
  @override
  Future<BotQuietView> botQuiet(String botId) async =>
      botQuiets[botId] ?? const BotQuietView(mode: 'default');
  @override
  Future<void> setBotQuiet(String botId, BotQuietView value) async =>
      botQuiets[botId] = value;

  final botMayCalls = <String, bool>{};
  @override
  Future<bool> botMayCall(String botId) async => botMayCalls[botId] ?? true;
  @override
  Future<void> setBotMayCall(String botId, bool mayCall) async => botMayCalls[botId] = mayCall;

  // About you (D-169)
  AboutYouView about = const AboutYouView(displayName: 'Test Person');
  final facts = <UserFactView>[];
  final profileShared = <String, bool>{};
  var _factSeq = 0;
  @override
  Future<AboutYouView> aboutYou() async => about;
  // Reports and blocks (D-301)
  final reports = <(ReportTarget, String, ReportReason, String?)>[];
  final blocked = <String, String>{};
  @override
  Future<void> report(ReportTarget kind, String targetId, ReportReason reason, {String? note}) async {
    reports.add((kind, targetId, reason, note));
    if (kind == ReportTarget.user) blocked[targetId] = 'Someone';
  }
  @override
  Future<List<BlockedPerson>> blockedPeople() async => [
    for (final e in blocked.entries) BlockedPerson(userId: e.key, name: e.value, blockedAt: DateTime.utc(2026, 11, 15)),
  ];
  @override
  Future<void> block(String userId) async => blocked[userId] = 'Someone';
  @override
  Future<void> unblock(String userId) async => blocked.remove(userId);
  List<ContentReport> contentReports = [];
  final reviewed = <(String, bool, bool)>[];
  @override
  Future<List<ContentReport>> adminContentReports({String status = 'open'}) async => contentReports;

  AdminDomains adminDomainsData = AdminDomains(
    counts: AdminDomainsCounts(connected: 0, registered: 0, liveHosts: 0, suspended: 0),
    balanceUsd: null,
    orders: const [],
    domains: const [],
  );
  final adminDomainActions = <String>[];
  @override
  Future<AdminDomains> adminDomains() async => adminDomainsData;
  @override
  Future<void> adminSuspendDomain(String id) async => adminDomainActions.add('suspend:$id');
  @override
  Future<void> adminUnsuspendDomain(String id) async => adminDomainActions.add('unsuspend:$id');
  @override
  Future<DomainOrder> adminRetryDomainOrder(String id) async {
    adminDomainActions.add('retry:$id');
    return _order(id, 'bakery.com', 'refunding');
  }

  @override
  Future<DomainOrder> adminApproveDomainOrder(String id) async {
    adminDomainActions.add('approve:$id');
    return _order(id, 'bakery.com', 'registering');
  }
  @override
  Future<void> reviewContentReport(String id, {required bool actioned, bool suspendWorkspace = false}) async {
    reviewed.add((id, actioned, suspendWorkspace));
    contentReports = contentReports.where((r) => r.id != id).toList();
  }
  List<ReportedCreation> reportedLinks = [];
  final takenDown = <String>[];
  @override
  Future<List<ReportedCreation>> adminReportedLinks() async => reportedLinks;
  @override
  Future<void> takeDownLink(String creationId, bool down) async => down ? takenDown.add(creationId) : takenDown.remove(creationId);
  List<SupportTicketRow> tickets = [];
  final closedTickets = <String>[];
  @override
  Future<List<SupportTicketRow>> adminSupportTickets({String status = 'open'}) async => tickets;
  @override
  Future<SupportWebStats> adminSupportWebStats() async => throw UnimplementedError();
  @override
  Future<void> setSupportTicketClosed(String reference, bool closed) async => closed ? closedTickets.add(reference) : closedTickets.remove(reference);
  // Account emails (D-302)
  bool tipsEmails = true;
  @override
  Future<bool> emailTips() async => tipsEmails;
  @override
  Future<void> setEmailTips(bool on) async => tipsEmails = on;
  // Monthly gallery picks and workspace gallery rules (D-315)
  bool? galleryDigestEmails = false;
  @override
  Future<bool?> emailGalleryDigest() async => galleryDigestEmails;
  @override
  Future<void> setEmailGalleryDigest(bool on) async => galleryDigestEmails = on;
  // Casama's monthly email (D-408)
  @override
  bool newsletterAvailable = false;
  NewsletterChoice newsletterChoice = const NewsletterChoice(subscribed: false, asked: false);
  final newsletterCalls = <({bool? subscribed, String from})>[];
  @override
  Future<NewsletterChoice?> newsletter() async => newsletterAvailable ? newsletterChoice : null;
  @override
  Future<NewsletterChoice?> setNewsletter({bool? subscribed, String from = 'settings'}) async {
    newsletterCalls.add((subscribed: subscribed, from: from));
    newsletterChoice = NewsletterChoice(subscribed: subscribed ?? newsletterChoice.subscribed, asked: true);
    return newsletterAvailable ? newsletterChoice : null;
  }
  List<GalleryItem> gallerySetItems = const [];
  @override
  Future<List<GalleryItem>> gallerySets() async => gallerySetItems;
  WorkspaceGalleryPolicy galleryPolicyValue = const WorkspaceGalleryPolicy();
  final savedGalleryPolicies = <WorkspaceGalleryPolicy>[];
  @override
  Future<WorkspaceGalleryPolicy> galleryPolicy(String orgId) async => galleryPolicyValue;
  @override
  Future<WorkspaceGalleryPolicy> setGalleryPolicy(String orgId, WorkspaceGalleryPolicy policy) async {
    savedGalleryPolicies.add(policy);
    return galleryPolicyValue = policy;
  }
  List<WorkspaceGalleryApproval> galleryApprovalList = [];
  final galleryDecisions = <(String, bool)>[];
  @override
  Future<List<WorkspaceGalleryApproval>> galleryApprovals(String orgId, {String? status}) async => [
    for (final a in galleryApprovalList)
      if (status == null || a.status == status) a,
  ];
  @override
  Future<WorkspaceGalleryApproval> decideGalleryApproval(String approvalId, {required bool approve}) async {
    galleryDecisions.add((approvalId, approve));
    final a = galleryApprovalList.firstWhere((x) => x.id == approvalId);
    final decided = WorkspaceGalleryApproval(
      id: a.id,
      orgId: a.orgId,
      type: a.type,
      itemId: a.itemId,
      name: a.name,
      requestedBy: a.requestedBy,
      requestedByName: a.requestedByName,
      reason: a.reason,
      status: approve ? 'approved' : 'denied',
      createdAt: a.createdAt,
      decidedAt: DateTime.now(),
    );
    galleryApprovalList = [for (final x in galleryApprovalList) x.id == approvalId ? decided : x];
    return decided;
  }
  // Help & support (D-298)
  SupportConfig? support = SupportConfig(assistant: true, tickets: true, email: 'support@casama.ai', docsUrl: 'https://docs.casama.ai');
  final supportAsked = <SupportChatRequest>[];
  final supportTickets = <SupportTicketRequest>[];
  /// The next answers, oldest first; the default echoes a generic reply.
  final supportReplies = <SupportChatReply>[];
  Object? supportError;
  @override
  Future<SupportConfig?> supportConfig() async => support;
  @override
  Future<SupportChatReply> askSupport(SupportChatRequest request) async {
    supportAsked.add(request);
    if (supportError != null) throw supportError!;
    return supportReplies.isNotEmpty ? supportReplies.removeAt(0) : SupportChatReply(reply: 'Here is how.', sources: const [], handoff: null);
  }
  @override
  Future<SupportTicket> sendSupportTicket(SupportTicketRequest request) async {
    supportTickets.add(request);
    return SupportTicket(reference: 'C-TEST42', replyTo: userEmail ?? 'tester@example.com');
  }
  // Invite friends (D-211)
  Referral referralState = Referral(
    enabled: true,
    code: 'K7M2QX',
    link: 'https://casama.ai/i/K7M2QX',
    rewardUsd: 2,
    welcomeUsd: 2,
    rewardCap: 20,
    invited: 3,
    rewarded: 2,
    pending: 1,
    earnedUsd: 4,
    invitedBy: null,
    redeemUntil: DateTime.now().add(const Duration(days: 5)),
  );
  final redeemedReferrals = <String>[];
  static Never _referralProblem(int status, String code, String detail) {
    final req = RequestOptions(path: '/v1/me/referral/redeem');
    throw DioException(
      requestOptions: req,
      response: Response(
        requestOptions: req,
        statusCode: status,
        data: {'type': 'about:blank', 'title': 'Error', 'status': status, 'code': code, 'detail': detail},
      ),
    );
  }
  @override
  Future<Referral> referral() async => referralState;
  @override
  Future<Referral> redeemReferral(String code) async {
    redeemedReferrals.add(code);
    if (code.toUpperCase().replaceAll(RegExp('[^0-9A-Z]'), '') != 'ANA234') {
      _referralProblem(404, 'referral_not_found', "That invite code doesn't exist.");
    }
    return referralState = Referral(
      enabled: referralState.enabled,
      code: referralState.code,
      link: referralState.link,
      rewardUsd: referralState.rewardUsd,
      welcomeUsd: referralState.welcomeUsd,
      rewardCap: referralState.rewardCap,
      invited: referralState.invited,
      rewarded: referralState.rewarded,
      pending: referralState.pending,
      earnedUsd: referralState.earnedUsd,
      invitedBy: ReferralInvitedBy(name: 'Ana', welcomeEarnedUsd: null),
      redeemUntil: null,
    );
  }
  @override
  Future<ReferralPreview> previewReferral(String code) async {
    if (code.toUpperCase() != 'ANA234') {
      _referralProblem(404, 'referral_not_found', 'Not found');
    }
    return ReferralPreview(inviterName: 'Ana', rewardUsd: 2, welcomeUsd: 2);
  }
  @override
  Future<void> saveAboutYou(AboutYouView value) async =>
      about = (value.preferredName?.trim().isNotEmpty ?? false)
      ? value.copyWith(nameAsked: true)
      : value;
  // Profile photo (D-202)
  var photoUploads = 0;
  @override
  Future<AboutYouView> setProfilePhoto(Uint8List bytes, String contentType) async {
    photoUploads++;
    return about = _withPhoto('photo-$photoUploads');
  }

  @override
  Future<AboutYouView> removeProfilePhoto() async => about = _withPhoto(null, tried: true);

  @override
  Future<AboutYouView> importProfilePhoto({bool replace = false}) async {
    if (!about.providerPhoto) return about;
    if (!replace && (about.photoId != null || about.photoImportTried)) return about;
    return about = _withPhoto('google-photo', tried: true);
  }

  AboutYouView _withPhoto(String? id, {bool? tried}) => AboutYouView(
    displayName: about.displayName,
    preferredName: about.preferredName,
    pronouns: about.pronouns,
    about: about.about,
    replyStyle: about.replyStyle,
    learn: about.learn,
    nameAsked: about.nameAsked,
    photoId: id,
    providerPhoto: about.providerPhoto,
    photoImportTried: tried ?? about.photoImportTried,
  );

  @override
  String photoUrl(String photoId) => 'http://localhost:8787/v1/photos/$photoId';

  /// Tests start agreed, so the consent step stays out of the way unless a test clears it.
  DateTime? aiConsent = DateTime.utc(2026, 1, 1);
  @override
  DateTime? get aiConsentAt => aiConsent;
  @override
  Future<void> setAiConsent(bool allowed) async {
    aiConsent = allowed ? DateTime.now().toUtc() : null;
  }

  var nameAskedMarked = false;
  @override
  Future<void> markNameAsked() async {
    nameAskedMarked = true;
    about = about.copyWith(nameAsked: true);
  }

  @override
  Future<List<UserFactView>> userFacts() async => [...facts];
  @override
  Future<void> addUserFacts(List<({String kind, String content})> list) async {
    for (final f in list) {
      facts.add(
        UserFactView(
          id: 'fact-${++_factSeq}',
          kind: f.kind,
          content: f.content,
          updatedAt: DateTime(2026, 11, 11),
        ),
      );
    }
  }

  @override
  Future<void> updateUserFact(
    String id, {
    String? content,
    bool? pinned,
  }) async {
    final i = facts.indexWhere((f) => f.id == id);
    if (i < 0) return;
    final f = facts[i];
    facts[i] = UserFactView(
      id: f.id,
      kind: f.kind,
      content: content ?? f.content,
      pinned: pinned ?? f.pinned,
      updatedAt: f.updatedAt,
    );
  }

  @override
  Future<void> deleteUserFact(String id) async =>
      facts.removeWhere((f) => f.id == id);
  @override
  Future<bool> profileSharedIn(String orgId) async =>
      profileShared[orgId] ?? false;
  @override
  Future<void> setProfileSharedIn(String orgId, bool share) async =>
      profileShared[orgId] = share;
  final edits = <(String, String)>[];
  final branchSwitches = <String>[];
  List<String> siblings = const [];
  @override
  Future<SendMessageResponse> editMessage(
    String conversationId,
    String messageId,
    String text,
  ) async {
    edits.add((messageId, text));
    return SendMessageResponse(
      messageId: 'm-edit',
      runId: 'run-edit',
      conversationId: conversationId,
    );
  }

  final deletedMessages = <String>[];
  @override
  Future<void> deleteMessage(String conversationId, String messageId) async {
    deletedMessages.add(messageId);
    storedMessages = [for (final m in storedMessages) if (m.id != messageId) m];
  }

  /// Reactions by message id (D-331): what reactions() returns and set/removeReaction change.
  final storedReactions = <String, List<ReactionGroup>>{};
  final reactionCalls = <String>[];
  Object? reactionError;
  var reactionReads = 0;
  @override
  Future<Map<String, List<ReactionGroup>>> reactions(String conversationId, List<String> messageIds) async {
    reactionReads++;
    return {for (final id in messageIds) if (storedReactions[id]?.isNotEmpty ?? false) id: storedReactions[id]!};
  }

  @override
  Future<List<ReactionGroup>> setReaction(String conversationId, String messageId, String emoji) async {
    reactionCalls.add('set $messageId $emoji');
    if (reactionError case final e?) throw e;
    return storedReactions[messageId] = ReactionGroup.withMine(storedReactions[messageId] ?? const [], emoji, me: userId);
  }

  @override
  Future<List<ReactionGroup>> removeReaction(String conversationId, String messageId) async {
    reactionCalls.add('remove $messageId');
    if (reactionError case final e?) throw e;
    return storedReactions[messageId] = ReactionGroup.withMine(storedReactions[messageId] ?? const [], null, me: userId);
  }

  List<ReactionPerson> storedReactionPeople = const [];
  @override
  Future<List<ReactionPerson>> reactionPeople(String conversationId, String messageId) async => storedReactionPeople;

  @override
  Future<void> switchBranch(String conversationId, String messageId) async =>
      branchSwitches.add(messageId);
  @override
  Future<List<String>> messageSiblings(
    String conversationId,
    String messageId,
  ) async => siblings;
  @override
  String? traceUrlTemplate;
  String? runTraceId;

  /// What [run] reports, for a chat whose last run failed before it started.
  RunStatus runStatus = RunStatus.completed;
  RunError? runError;
  /// Thrown by every run read while set (the server unreachable, say).
  Object? runReadError;
  /// Holds [run] until completed, and which bot it reports (a group chat's member, D-118).
  Completer<void>? runGate;
  /// The run's newest event as the server reports it (Run.lastSeq).
  int runLastSeq = 1;
  String? runBotId;
  @override
  Future<Run> run(String runId) async {
    await runGate?.future;
    final fail = runReadError;
    if (fail != null) throw fail;
    return _run(runId);
  }

  Run _run(String runId) => Run(
    id: runId,
    botId: runBotId ?? botId,
    conversationId: convId,
    parentRunId: null,
    trigger: 'chat',
    status: runStatuses[runId] ?? runStatus,
    tokensIn: 100,
    tokensOut: 10,
    costUsd: 0.01,
    lastSeq: runLastSeq,
    startedAt: DateTime(2026),
    endedAt: DateTime(2026),
    error: runError,
    traceId: runTraceId,
    createdAt: DateTime(2026),
  );
  /// What [runUsage] reports (D-307); each call is counted.
  RunUsage? usageOfRun;
  final usageAsked = <String>[];
  @override
  Future<RunUsage> runUsage(String runId) async {
    usageAsked.add(runId);
    return usageOfRun ??
        RunUsage(
          runId: runId,
          status: RunStatus.completed,
          costUsd: 0.042,
          chargedUsd: 0.042,
          tokensIn: 15000,
          tokensOut: 3200,
          durationMs: 32000,
          toolCalls: 4,
          subruns: 0,
          items: [
            RunUsageItemsInner(kind: 'tokens_in', model: 'fixture-model', source_: RunUsageItemsInnerSource_Enum.key, billable: true, quantity: 15000, costUsd: 0.03),
            RunUsageItemsInner(kind: 'tokens_out', model: 'fixture-model', source_: RunUsageItemsInnerSource_Enum.key, billable: true, quantity: 3200, costUsd: 0.012),
          ],
        );
  }
  /// What [botStarters] returns (D-338); null throws, like an older server. Each call is counted.
  ChatStarters? starters;
  final startersAsked = <String>[];
  @override
  Future<ChatStarters> botStarters(String botId) async {
    startersAsked.add(botId);
    final s = starters;
    if (s == null) throw UnsupportedError('no starters');
    return s;
  }
  BotSetupStatusEnum setupStatus = BotSetupStatusEnum.done;
  var setupStarted = 0;
  @override
  Future<String> startBotSetup(String botId) async {
    setupStarted++;
    return 'setup-conv';
  }

  @override
  Future<void> skipBotSetup(String botId) async =>
      setupStatus = BotSetupStatusEnum.skipped;
  final sentSkills = <List<String>>[];
  final catalogInstalls = <(String, String?)>[];
  final githubInstalls = <(String, String)>[];
  String? appliedUpdate;
  @override
  Future<SkillCatalog> skillCatalog() async => SkillCatalog(
    categories: const ['work', 'data'],
    items: [
      CatalogSkill(
        id: 'meeting-notes',
        name: 'meeting-notes',
        description: 'Summarize meetings',
        category: 'work',
        icon: 'notebook-pen',
        files: const [],
        skillMd: '---\nname: meeting-notes\ndescription: Summarize meetings\n---\n\n# Meeting notes\n\nList the decisions.',
      ),
      CatalogSkill(
        id: 'csv-cleanup',
        name: 'csv-cleanup',
        description: 'Clean CSV files',
        category: 'data',
        icon: 'sheet',
        files: const ['scripts/clean.py'],
      ),
    ],
  );
  @override
  Future<void> installCatalogSkill(
    String orgId,
    String catalogId, {
    String? botId,
  }) async {
    catalogInstalls.add((catalogId, botId));
    skillViews = [
      ...skillViews,
      SkillView(
        id: 'cat-$catalogId-$botId',
        name: catalogId,
        description: '',
        bodyMd: 'x',
        enabled: true,
        botId: botId,
        source: 'catalog',
        sourceRef: {'id': catalogId},
      ),
    ];
  }

  var galleryAvailable = true;
  List<GalleryItem> galleryItems = const [];
  final galleryInstalls = <(String, String?)>[];

  @override
  Future<GalleryPage> gallery({String? type, String? query}) async {
    final q = query?.trim().toLowerCase() ?? '';
    return GalleryPage(
      available: galleryAvailable,
      items: [
        for (final item in galleryItems)
          if ((type == null || item.type == type) &&
              (q.isEmpty ||
                  item.name.toLowerCase().contains(q) ||
                  item.tags.any((t) => t.contains(q))))
            item,
      ],
    );
  }

  @override
  Future<GalleryItem> galleryItem(String type, String id) async =>
      galleryItems.firstWhere((item) => item.type == type && item.id == id);

  @override
  Future<void> installGallerySkill(
    String orgId,
    String galleryId, {
    String? botId,
  }) async {
    galleryInstalls.add((galleryId, botId));
    skillViews = [
      ...skillViews,
      SkillView(
        id: 'gal-$galleryId-$botId',
        name: galleryId,
        description: '',
        bodyMd: 'x',
        enabled: true,
        botId: botId,
        source: 'gallery',
        sourceRef: {'id': galleryId},
      ),
    ];
  }

  // Gallery v2 (D-315)
  Map<String, GalleryStats> galleryStatsMap = const {};
  final galleryUses = <String>[];
  final galleryItemInstalls = <(String, String, Map<String, String>?)>[];
  /// The bot each item or set install went to, by `<type>/<id>`.
  final galleryInstallBots = <String, String?>{};
  /// What the next item install answers with: missing apps, a pending approval, bad inputs.
  GalleryInstallResult galleryInstallResult = const GalleryInstallResult();
  Map<String, String>? galleryInputErrors;
  List<GalleryInstalledItem> galleryInstalledItems = [];
  final galleryUpdates = <(String, bool)>[];
  final galleryRemovals = <String>[];
  List<GalleryRequest> galleryRequestList = [];
  final galleryVotes = <(String, bool)>[];
  List<GallerySubmission> gallerySubmissionList = [];
  final gallerySubmitted = <Map<String, Object?>>[];
  List<GalleryMyItem> galleryMyItemList = const [];

  @override
  Future<GalleryPage> galleryEverything() async =>
      GalleryPage(available: galleryAvailable, items: List.of(galleryItems));

  @override
  Future<Map<String, GalleryStats>> galleryStats() async => galleryStatsMap;

  @override
  Future<void> galleryUsed(String type, String id) async {
    galleryUses.add('$type/$id');
  }

  @override
  Future<GalleryInstallResult> installGalleryItem(
    String orgId,
    String type,
    String id, {
    Map<String, String>? inputs,
    String? botId,
  }) async {
    final errors = galleryInputErrors;
    if (errors != null) {
      galleryInputErrors = null;
      throw GalleryInputsInvalid(errors);
    }
    // As the server: 400 bot_required for a routine or plugin without a bot.
    if ((type == 'routine' || type == 'plugin') && botId == null) {
      throw const GalleryInputsInvalid({'bot_id': 'Required'});
    }
    galleryItemInstalls.add(('$type/$id', orgId, inputs));
    galleryInstallBots['$type/$id'] = botId;
    return galleryInstallResult;
  }

  @override
  Future<GalleryInstallResult> installGallerySet(String orgId, String id, {String? botId}) async {
    galleryItemInstalls.add(('set/$id', orgId, null));
    galleryInstallBots['set/$id'] = botId;
    return galleryInstallResult;
  }

  @override
  Future<List<GalleryInstalledItem>> galleryInstalled(String orgId) async =>
      List.of(galleryInstalledItems);

  @override
  Future<void> updateGalleryInstalled(
    String orgId,
    String type,
    String id, {
    bool acceptAccess = false,
  }) async {
    final item = galleryInstalledItems.firstWhere(
      (i) => i.type == type && i.id == id,
    );
    if (item.asksFirst && !acceptAccess) {
      throw GalleryAccessChanged(item.accessAdded, breaking: item.breaking);
    }
    galleryUpdates.add(('$type/$id', acceptAccess));
    galleryInstalledItems = [
      for (final i in galleryInstalledItems)
        if (i == item)
          GalleryInstalledItem(
            type: i.type,
            id: i.id,
            name: i.name,
            installedVersion: i.latestVersion ?? i.installedVersion,
            latestVersion: i.latestVersion,
          )
        else
          i,
    ];
  }

  @override
  Future<void> removeGalleryInstalled(
    String orgId,
    String type,
    String id,
  ) async {
    galleryRemovals.add('$type/$id');
    galleryInstalledItems = [
      for (final i in galleryInstalledItems)
        if (!(i.type == type && i.id == id)) i,
    ];
  }

  @override
  Future<List<GalleryRequest>> galleryRequests({String sort = 'top'}) async {
    final list = List.of(galleryRequestList);
    if (sort == 'top') {
      list.sort((a, b) => b.votes.compareTo(a.votes));
    } else {
      list.sort(
        (a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)),
      );
    }
    return list;
  }

  @override
  Future<GalleryRequest> createGalleryRequest({
    required String kind,
    required String title,
    String? details,
  }) async {
    final request = GalleryRequest(
      id: 'req-${galleryRequestList.length + 1}',
      kind: kind,
      title: title,
      details: details,
      votes: 1,
      voted: true,
      mine: true,
      createdAt: DateTime.now(),
    );
    // As the server: a title like an existing one answers with that one (200), now voted.
    final similar = galleryRequestList.where((r) => r.title.toLowerCase() == title.toLowerCase()).firstOrNull;
    if (similar != null) {
      final voted = similar.copyWith(votes: similar.voted ? similar.votes : similar.votes + 1, voted: true);
      galleryRequestList = [for (final r in galleryRequestList) r.id == similar.id ? voted : r];
      return voted.copyWith(similar: true);
    }
    galleryRequestList = [...galleryRequestList, request];
    return request;
  }

  @override
  Future<void> voteGalleryRequest(String id, {required bool vote}) async {
    galleryVotes.add((id, vote));
  }

  @override
  Future<GallerySubmission> submitToGallery({
    required String type,
    String? id,
    required Map<String, Object?> item,
    required Map<String, String> files,
    GalleryRef? remixOf,
  }) async {
    gallerySubmitted.add({
      'type': type,
      'id': id,
      'item': item,
      'files': files,
      if (remixOf != null) 'remix_of': remixOf.toJson(),
    });
    final sub = GallerySubmission(
      id: 'sub-${gallerySubmitted.length}',
      type: type,
      itemId: id ?? 'new',
      name: item['name'] as String?,
      prUrl: 'https://github.com/stackwares/casama-gallery/pull/1',
    );
    gallerySubmissionList = [...gallerySubmissionList, sub];
    return sub;
  }

  @override
  Future<List<GallerySubmission>> gallerySubmissions() async =>
      List.of(gallerySubmissionList);

  @override
  Future<List<GalleryMyItem>> galleryMyItems() async => galleryMyItemList;

  @override
  Future<GitHubSkillPreview> previewGitHubSkill(
    String orgId,
    String url,
  ) async => GitHubSkillPreview(
    repo: 'acme/skills',
    path: 'pr-labels',
    ref: null,
    commit: 'a' * 40,
    name: 'pr-labels',
    description: 'Label pull requests',
    skillMd: '---\nname: pr-labels\n---\nSteps',
    files: [
      SkillPreviewFile(
        path: 'label.sh',
        size: 21,
        executable: true,
        text: 'echo label',
      ),
    ],
  );
  @override
  Future<void> installGitHubSkill(
    String orgId,
    String url,
    String commit, {
    String? botId,
  }) async => githubInstalls.add((url, commit));
  @override
  Future<SkillUpdateCheck> checkSkillUpdate(String skillId) async =>
      SkillUpdateCheck(
        currentCommit: 'a' * 40,
        latestCommit: 'b' * 40,
        hasUpdate: true,
        diff: const ['- old step', '+ new step'],
        filesAdded: const [],
        filesRemoved: const ['label.sh'],
        filesChanged: const [],
      );
  @override
  Future<void> applySkillUpdate(String skillId, String commit) async =>
      appliedUpdate = commit;
  final searches = <String>[];
  final searchKinds = <List<String>?>[];
  var searchFindsNothing = false;
  @override
  Future<SearchResponse> search(String orgId, String query, {List<String>? kinds}) async {
    searches.add(query);
    searchKinds.add(kinds);
    bool wanted(String kind) => !searchFindsNothing && (kinds == null || kinds.contains(kind));
    return SearchResponse(
      query: query,
      items: [
        SearchResult(
          kind: SearchKind.message,
          id: 'msg-1',
          title: 'Invoices',
          snippet: 'Please draft the «invoice» for Northwind',
          botId: botId,
          conversationId: convId,
          createdAt: DateTime(2026, 11, 9),
        ),
        SearchResult(
          kind: SearchKind.ticket,
          id: 't1',
          title: 'Send invoice',
          snippet: '',
          botId: null,
          conversationId: null,
          createdAt: DateTime(2026, 11, 9),
        ),
      ].where((r) => wanted(r.kind.value)).toList(),
      files: [
        if (wanted('file'))
          FileSearchResult(
            computerId: 'comp-1',
            computerName: 'Team computer',
            path: 'docs/invoice.md',
            match: FileSearchResultMatchEnum.name,
          ),
      ],
      filesSearched: wanted('file') ? 1 : 0,
    );
  }

  final secretAnswers = <(String, String?)>[];
  @override
  Future<void> fulfillSecretRequest(String requestId, String value) async =>
      secretAnswers.add((requestId, value));
  @override
  Future<void> declineSecretRequest(String requestId) async =>
      secretAnswers.add((requestId, null));

  final mcpAnswers = <(String, String, Map<String, Object?>?)>[];
  @override
  Future<void> answerMcpQuestion(String questionId, String action, [Map<String, Object?>? content]) async =>
      mcpAnswers.add((questionId, action, content));

  /// What the server says about each secret request; pending when not listed.
  final secretStatuses = <String, String>{};
  @override
  Future<String> secretRequestStatus(String requestId) async =>
      secretStatuses[requestId] ?? 'pending';

  // Device connections (D-149).
  final deviceSourcesSaved = <String, DeviceSource>{};
  final uploadedReadings = <(String, DeviceReadingInput, String?)>[];

  /// Health uploads are refused with 409 health_needs_encryption, like a server where no owned workspace has encryption on.
  bool healthNeedsEncryption = false;
  final pendingDeviceRequests = <DeviceRequest>[];
  final deviceAnswers = <(String, bool, Map<String, Object?>?)>[];
  final grants = <DeviceGrant>[];
  final deviceRequestsController = StreamController<String>.broadcast();

  @override
  Future<List<DeviceSource>> deviceSources() async =>
      deviceSourcesSaved.values.toList();
  @override
  Future<DeviceSource> saveDeviceSource(
    String key, {
    required String name,
    required String platform,
    required Map<String, DeviceKindSettings> kinds,
  }) async => deviceSourcesSaved[key] = DeviceSource(
    id: 'src-$key',
    deviceKey: key,
    name: name,
    platform: DeviceSourcePlatformEnum.values.firstWhere(
      (p) => p.value == platform,
    ),
    kinds: kinds,
    lastSeenAt: DateTime.now(),
    createdAt: DateTime.now(),
  );
  @override
  Future<void> deleteDeviceSource(String key) async =>
      deviceSourcesSaved.remove(key);
  @override
  Future<int> uploadDeviceReadings(
    String key,
    List<DeviceReadingInput> readings, {
    String? requestId,
  }) async {
    if (healthNeedsEncryption &&
        readings.any((r) => r.kind == DeviceKind.health)) {
      final req = RequestOptions(path: '/v1/devices/$key/readings');
      throw DioException(
        requestOptions: req,
        response: Response(
          requestOptions: req,
          statusCode: 409,
          data: {
            'type': 'about:blank',
            'title': 'Conflict',
            'status': 409,
            'code': 'health_needs_encryption',
            'detail': 'Health data is stored only with encryption at rest on.',
          },
        ),
      );
    }
    for (final r in readings) {
      uploadedReadings.add((key, r, requestId));
    }
    if (requestId != null) {
      pendingDeviceRequests.removeWhere((r) => r.id == requestId);
    }
    return readings.length;
  }

  @override
  Future<List<DeviceRequest>> deviceRequests(String key) async =>
      List.of(pendingDeviceRequests);
  @override
  Future<void> answerDeviceRequest(
    String id, {
    required bool ok,
    Map<String, Object?>? result,
    String? error,
  }) async {
    deviceAnswers.add((id, ok, result));
    pendingDeviceRequests.removeWhere((r) => r.id == id);
  }

  @override
  Future<List<DeviceGrant>> deviceGrants({String? botId, bool allKinds = false}) async => grants
      .where((g) => botId == null || g.botId == botId)
      .where((g) => allKinds || (g.kind != DeviceKind.browserTab && g.kind != DeviceKind.browserHistory))
      .toList();

  /// System permissions per device (D-376): what [devicePermissions] lists, what devices reported,
  /// what cards asked for, and Not now.
  final permissionDevices = <DevicePermissions>[];
  final reportedPermissions = <String, Map<String, String>>{};
  final permissionAsks = <(String, String, String, String?)>[];
  final permissionSnoozes = <(String, String, List<String>)>[];

  @override
  Future<List<DevicePermissions>> devicePermissions() async => List.of(permissionDevices);
  @override
  Future<void> reportDevicePermissions(String deviceRef, Map<String, String> states) async =>
      reportedPermissions[deviceRef] = Map.of(states);
  @override
  Future<String> askDevicePermission(String deviceRef, String permission, String action, {String? botId}) async {
    permissionAsks.add((deviceRef, permission, action, botId));
    return deviceRef.startsWith('computer:') ? 'socket' : 'notification';
  }
  @override
  Future<void> snoozeDevicePermissions(String deviceRef, String botId, List<String> permissions) async =>
      permissionSnoozes.add((deviceRef, botId, permissions));

  /// The tab a paired browser shares, for quick ask on Windows and Linux (D-323 E3).
  BrowserTabSummary? sharedTab;
  @override
  Future<BrowserTabSummary?> browserTab() async => sharedTab;
  @override
  Future<List<DeviceGrant>> setDeviceGrant(
    String botId,
    DeviceKind kind,
    bool allowed,
  ) async {
    grants.removeWhere((g) => g.botId == botId && g.kind == kind);
    if (allowed) {
      grants.add(
        DeviceGrant(
          botId: botId,
          botName: 'Pal',
          kind: kind,
          createdAt: DateTime(2026),
        ),
      );
    }
    return deviceGrants(botId: botId, allKinds: true);
  }

  @override
  Stream<String> watchDeviceRequests() => deviceRequestsController.stream;

  final lessLiked = <String>[];
  @override
  Future<void> lessLikeThis(String notificationId) async =>
      lessLiked.add(notificationId);

  final reportedEvents = <(String, DeviceEventInput)>[];
  final places = <DevicePlace>[];
  @override
  Future<int> reportDeviceEvents(
    String key,
    List<DeviceEventInput> events,
  ) async {
    for (final e in events) {
      reportedEvents.add((key, e));
    }
    return 0;
  }

  @override
  Future<List<DevicePlace>> devicePlaces() async => List.of(places);
  @override
  Future<DevicePlace> saveDevicePlace({
    required String name,
    required double latitude,
    required double longitude,
    int? radiusM,
  }) async {
    places.removeWhere((p) => p.name.toLowerCase() == name.toLowerCase());
    final p = DevicePlace(
      id: 'place-$name',
      name: name,
      latitude: latitude,
      longitude: longitude,
      radiusM: radiusM ?? 150,
      createdAt: DateTime(2027),
    );
    places.add(p);
    return p;
  }

  @override
  Future<void> deleteDevicePlace(String id) async =>
      places.removeWhere((p) => p.id == id);

  @override
  Future<List<BotFolder>> botFolders(String orgId) async => [
    if (botFolder != null) BotFolder(id: botFolder!, name: botFolder!),
  ];
  @override
  Future<void> setBotFolder(
    String orgId,
    String botId,
    String? folderName,
  ) async => botFolder = folderName;
  @override
  Future<List<Bot>> archivedBots(String orgId) async => [
    if (archived.contains(botId)) bot(),
  ];
  @override
  Future<void> setBotArchived(String botId, bool value) async =>
      value ? archived.add(botId) : archived.remove(botId);
  @override
  Future<List<BotRevision>> botRevisions(String botId) async => revisions;
  @override
  Future<void> restoreBotRevision(String botId, BotRevision revision) async =>
      restored = revision;

  String? defaultComputer;

  @override
  Future<List<Bot>> bots(String orgId) async {
    if (offline) throw Exception('offline');
    return [if (!archived.contains(botId)) bot(), ...extraBots];
  }

  /// More bots, for group chat tests.
  final extraBots = <Bot>[];
  @override
  Future<Bot> createBot(
    String orgId, {
    required String name,
    required String credentialId,
    required String model,
    String persona = '',
    String? templateId,
    String? avatarUrl,
  }) async {
    createdBotTemplate = templateId;
    createdBotAvatar = avatarUrl;
    createdBot = (name: name, model: model);
    return bot();
  }

  String? createdBotTemplate;
  String? createdBotAvatar;
  ({String name, String model})? createdBot;

  /// Set to true to simulate a workspace without model keys.
  bool noKeys = false;

  @override
  Future<List<Template>> templates() async => [
    Template(
      id: 'daily-briefing',
      name: 'Daily briefing',
      description: 'A morning summary of what changed.',
      autonomy: TemplateAutonomyEnum.askRisky,
      skills: const ['briefing'],
      routines: [
        TemplateRoutinesInner(
          name: 'Morning summary',
          scheduleCron: '0 7 * * *',
        ),
      ],
      persona: 'You prepare short briefings.',
      category: TemplateCategoryEnum.work,
      icon: 'newspaper',
      mascot: 'sleepy',
      starters: const ['Brief me on AI news'],
    ),
    Template(
      id: 'writer',
      name: 'Writer',
      description: 'Drafts and edits documents.',
      autonomy: TemplateAutonomyEnum.askRisky,
      skills: const [],
      routines: const [],
    ),
  ];

  /// The last bot update saved: the bot's id and the fields sent.
  ({String botId, String? name, String? persona, String? autonomy})? botUpdate;
  @override
  Future<void> updateBot(
    String botId, {
    String? name,
    String? persona,
    String? autonomy,
    Map<String, Object?>? modelPolicy,
    String? avatarUrl,
  }) async => botUpdate = (
    botId: botId,
    name: name,
    persona: persona,
    autonomy: autonomy,
  );
  @override
  bool wallpapersEnabled = false;
  @override
  Future<List<WallpaperPhoto>> searchWallpapers({
    String? query,
    int page = 1,
  }) async => const [];
  final wallpaperDownloads = <String>[];
  @override
  Future<void> trackWallpaperDownload(String downloadLocation) async =>
      wallpaperDownloads.add(downloadLocation);

  @override
  Future<UsageReport> usage(String orgId, {String period = 'day', UsageFilter filter = UsageFilter.none}) async =>
      UsageReport(
        period: period == 'day'
            ? UsageReportPeriodEnum.day
            : UsageReportPeriodEnum.month,
        since: DateTime(2026),
        totalCostUsd: 0.0123,
        byBot: [
          UsageReportByBotInner(
            botId: botId,
            name: 'Ada',
            costUsd: 0.0123,
            tokensIn: 1000,
            tokensOut: 200,
          ),
        ],
      );

  /// Chats deleted, by id, and bots whose chats were all deleted.
  final deletedConversations = <String>[];
  final clearedBots = <String>[];

  /// Whether the person may delete the fake chat (they started it, or manage the bot).
  var canDeleteChats = true;

  /// General and topics (D-253): the fake chat as General, and topics listed after it.
  var fakeChatIsGeneral = false;
  List<Conversation> topics = [];
  @override
  Future<List<Conversation>> conversations(String botId) async => [
    if (!deletedConversations.contains(convId) && !clearedBots.contains(botId))
      Conversation(
        id: convId,
        botId: botId,
        title: 'Hello',
        lastMessageAt: null,
        createdAt: DateTime(2026),
        kind: ConversationKindEnum.direct,
        botIds: [botId],
        canDelete: canDeleteChats,
        isMain: fakeChatIsGeneral,
      ),
    ...topics,
  ];
  /// Renames and pins: (id, title, pinned).
  final conversationUpdates = <(String, String?, bool?)>[];
  @override
  Future<Conversation> updateConversation(String conversationId, {String? title, bool? pinned}) async {
    conversationUpdates.add((conversationId, title, pinned));
    final i = topics.indexWhere((c) => c.id == conversationId);
    if (i >= 0) {
      topics[i] = Conversation.fromJson({
        ...topics[i].toJson(),
        if (title != null) 'title': title.trim().isEmpty ? null : title.trim(),
        'pinned': ?pinned,
      });
      return topics[i];
    }
    return (await conversations(botId)).firstWhere((c) => c.id == conversationId);
  }

  /// Chat exports asked for: (conversation, format) (D-282).
  final conversationExports = <(String, String)>[];
  @override
  Future<Uint8List> exportConversation(String conversationId, {String format = 'markdown'}) async {
    conversationExports.add((conversationId, format));
    return Uint8List.fromList(utf8.encode(format == 'json' ? '{"title":"Chat"}' : '# Chat\n'));
  }

  /// Read-only link changes: (conversation, public) (D-282).
  final conversationShares = <(String, bool)>[];
  @override
  Future<String?> shareConversation(String conversationId, {required bool public}) async {
    conversationShares.add((conversationId, public));
    return public ? 'https://pages.example.com/t/tok-$conversationId-${conversationShares.length}' : null;
  }

  /// Chats deleted together with what was made in them (D-274).
  final deletedWithCreations = <String>[];
  @override
  Future<void> deleteConversation(String conversationId, {bool withCreations = false}) async {
    deletedConversations.add(conversationId);
    if (withCreations) deletedWithCreations.add(conversationId);
  }
  @override
  Future<(int, int)> deleteBotConversations(String botId) async {
    clearedBots.add(botId);
    return (1, 0);
  }
  @override
  Future<Conversation> createConversation(String botId) async => Conversation(
    id: convId,
    botId: botId,
    title: null,
    lastMessageAt: null,
    createdAt: DateTime(2026),
    kind: ConversationKindEnum.direct,
    botIds: [botId],
  );

  // Bot-to-bot switch (D-133)
  var fullAccessOn = false;
  @override
  Future<bool> fullAccess(String orgId) async => fullAccessOn;
  @override
  Future<void> setFullAccess(String orgId, bool on) async => fullAccessOn = on;
  var botToBot = true;
  @override
  Future<bool> allowBotToBot(String orgId) async => botToBot;

  // Secret store (D-145)
  var secretStoreState = SecretStoreSettings(
    provider: SecretStoreSettingsProviderEnum.vault,
    siteUrl: null,
    projectId: null,
    environment: null,
    secretPath: null,
  );
  SetSecretStoreRequest? setStore;
  @override
  Future<SecretStoreSettings> secretStore(String orgId) async =>
      secretStoreState;
  @override
  Future<SecretStoreSettings> setSecretStore(
    String orgId,
    SetSecretStoreRequest request,
  ) async {
    setStore = request;
    return secretStoreState = SecretStoreSettings(
      provider: SecretStoreSettingsProviderEnum.infisical,
      siteUrl: request.siteUrl,
      projectId: request.projectId,
      environment: request.environment ?? 'prod',
      secretPath: request.secretPath ?? '/',
    );
  }

  @override
  Future<SecretStoreSettings> removeSecretStore(String orgId) async =>
      secretStoreState = SecretStoreSettings(
        provider: SecretStoreSettingsProviderEnum.vault,
        siteUrl: null,
        projectId: null,
        environment: null,
        secretPath: null,
      );

  // Linked agents (D-143)
  final linkList = <BotLink>[];
  final linkActions = <String>[];
  BotLink _link(
    String id,
    String name,
    BotLinkStatusEnum status, {
    String? peer,
  }) => BotLink(
    id: id,
    botId: botId,
    name: name,
    status: status,
    peerBotName: peer,
    remoteUrl: null,
    exchanges: 1,
    createdAt: DateTime.utc(2026, 11, 3),
    activatedAt: null,
  );
  @override
  Future<List<BotLink>> botLinks(String botId) async => List.of(linkList);
  @override
  Future<CreatedBotLink> createBotLink(String botId, String name) async {
    linkActions.add('invite:$name');
    linkList.add(
      _link('lk-${linkList.length + 1}', name, BotLinkStatusEnum.pending),
    );
    return CreatedBotLink.fromJson({
      ...linkList.last.toJson(),
      'invite': 'casama-link:abc123',
    });
  }

  @override
  Future<BotLink> acceptBotLink(
    String invite,
    String botId,
    String name,
  ) async {
    linkActions.add('accept:$invite:$name');
    linkList.add(
      _link(
        'lk-${linkList.length + 1}',
        name,
        BotLinkStatusEnum.active,
        peer: 'Ben',
      ),
    );
    return linkList.last;
  }

  @override
  Future<BotLink> revokeBotLink(String id) async {
    linkActions.add('revoke:$id');
    final i = linkList.indexWhere((l) => l.id == id);
    linkList[i] = BotLink.fromJson({
      ...linkList[i].toJson(),
      'status': 'revoked',
    });
    return linkList[i];
  }

  @override
  Future<List<LinkExchange>> linkExchanges(String id) async => [
    LinkExchange(
      id: 'ex-1',
      direction: LinkExchangeDirectionEnum.out_,
      request: 'Find a dinner slot for 4 next week',
      response: 'Thursday at 7pm works.',
      status: LinkExchangeStatusEnum.answered,
      createdAt: DateTime.utc(2026, 11, 3),
    ),
  ];

  // Payments (D-142)
  var pay = PaymentSettings(
    connected: false,
    provider: null,
    monthlyCapUsd: 500,
    botMonthlyCapUsd: 200,
    spentThisMonthUsd: 0,
    webhookUrl: null,
  );
  SetPaymentSettingsRequest? setPay;
  @override
  Future<PaymentSettings> paymentSettings(String orgId) async => pay;
  @override
  Future<PaymentSettings> setPaymentSettings(
    String orgId,
    SetPaymentSettingsRequest request,
  ) async {
    setPay = request;
    return pay = PaymentSettings(
      connected: true,
      provider: PaymentSettingsProviderEnum.stripe,
      monthlyCapUsd: request.monthlyCapUsd ?? 500,
      botMonthlyCapUsd: request.botMonthlyCapUsd ?? 200,
      spentThisMonthUsd: 0,
      webhookUrl: 'https://api.example.com/hooks/payments/$orgId',
    );
  }

  @override
  Future<PaymentSettings> removePaymentSettings(String orgId) async =>
      pay = PaymentSettings(
        connected: false,
        provider: null,
        monthlyCapUsd: 500,
        botMonthlyCapUsd: 200,
        spentThisMonthUsd: 0,
        webhookUrl: null,
      );
  @override
  Future<List<PaymentRequest>> paymentRequests(String orgId) async => [
    PaymentRequest(
      id: 'pr-1',
      botId: botId,
      merchant: 'Amtrak',
      amountCents: 8950,
      currency: 'USD',
      reason: 'Two tickets NYC to Boston',
      status: PaymentRequestStatusEnum.used,
      last4: '4242',
      spentCents: 9200,
      expiresAt: DateTime.utc(2026, 11, 3, 19),
      createdAt: DateTime.utc(2026, 11, 3, 18),
    ),
  ];

  // Calls for you (D-141)
  var tel = TelephonySettings(
    connected: false,
    accountSid: null,
    fromNumber: null,
    allowPersonalNumbers: false,
    dailyCap: 10,
  );
  SetTelephonyRequest? setTel;
  final callLog = <String>[];
  var outbound = OutboundCall(
    id: 'call-9',
    botId: botId,
    number: '+14155550199',
    purpose: 'Book a table for 2 at 7pm',
    status: OutboundCallStatusEnum.inProgress,
    transcript: [
      OutboundCallTranscriptInner(
        role: OutboundCallTranscriptInnerRoleEnum.bot,
        text: "Hi, I'm Max, an AI assistant calling for Ana.",
      ),
      OutboundCallTranscriptInner(
        role: OutboundCallTranscriptInnerRoleEnum.callee,
        text: 'Sure, what time?',
      ),
    ],
    seconds: null,
    startedAt: DateTime.utc(2026, 11, 3, 18),
    endedAt: null,
    createdAt: DateTime.utc(2026, 11, 3, 18),
  );
  @override
  Future<TelephonySettings> telephony(String orgId) async => tel;
  @override
  Future<TelephonySettings> setTelephony(
    String orgId,
    SetTelephonyRequest request,
  ) async {
    setTel = request;
    return tel = TelephonySettings(
      connected: true,
      accountSid: request.accountSid,
      fromNumber: request.fromNumber,
      allowPersonalNumbers: request.allowPersonalNumbers ?? false,
      dailyCap: request.dailyCap ?? 10,
    );
  }

  @override
  Future<TelephonySettings> removeTelephony(String orgId) async =>
      tel = TelephonySettings(
        connected: false,
        accountSid: null,
        fromNumber: null,
        allowPersonalNumbers: false,
        dailyCap: 10,
      );
  @override
  Future<OutboundCall> outboundCall(String id) async => outbound;
  @override
  Future<OutboundCall> endOutboundCall(String id) async {
    callLog.add('end:$id');
    return outbound = OutboundCall.fromJson({
      ...outbound.toJson(),
      'status': 'ended_by_user',
    });
  }

  @override
  Future<OutboundCall> takeOverOutboundCall(String id, {String? phone}) async {
    callLog.add('takeover:$id:$phone');
    return outbound = OutboundCall.fromJson({
      ...outbound.toJson(),
      'status': 'taken_over',
    });
  }

  // Agent-to-agent (D-140)
  var a2aOn = false;
  var a2aPublished = false;
  @override
  Future<bool> a2aEnabled(String orgId) async => a2aOn;
  @override
  Future<void> setA2aEnabled(String orgId, bool enabled) async =>
      a2aOn = enabled;
  // Casama for Chrome (D-323)
  var chromeExtensionOn = true;
  var chromeActOn = true;
  @override
  Future<({bool extension, bool act})> chromeSettings(String orgId) async =>
      (extension: chromeExtensionOn, act: chromeActOn);
  @override
  Future<void> setChromeSettings(String orgId, {bool? extension, bool? act}) async {
    chromeExtensionOn = extension ?? chromeExtensionOn;
    chromeActOn = act ?? chromeActOn;
  }

  BotA2a _a2a(String botId) => BotA2a(
    workspaceEnabled: a2aOn,
    published: a2aPublished,
    agentCardUrl:
        'https://api.example.com/a2a/$botId/.well-known/agent-card.json',
  );
  @override
  Future<BotA2a> botA2a(String botId) async => _a2a(botId);
  @override
  Future<BotA2a> setBotA2a(String botId, bool published) async {
    a2aPublished = published;
    return _a2a(botId);
  }

  // Encryption at rest (D-136)
  var encryptionMode = EncryptionStatusModeEnum.off;
  final encryptionActions = <String>[];
  EncryptionStatus _enc() => EncryptionStatus(
    mode: encryptionMode,
    available: true,
    key: encryptionMode == EncryptionStatusModeEnum.off
        ? null
        : EncryptionStatusKeyEnum.serverKey,
    since: null,
    rotatedAt: encryptionActions.contains('rotate')
        ? DateTime.utc(2026, 11, 2)
        : null,
  );
  @override
  Future<EncryptionStatus> encryption(String orgId) async => _enc();
  @override
  Future<EncryptionStatus> setEncryption(String orgId, bool enabled) async {
    encryptionActions.add('set:$enabled');
    encryptionMode = enabled
        ? EncryptionStatusModeEnum.encrypting
        : EncryptionStatusModeEnum.decrypting;
    return _enc();
  }

  @override
  Future<EncryptionStatus> rotateEncryptionKey(String orgId) async {
    encryptionActions.add('rotate');
    return _enc();
  }

  @override
  Future<void> setAllowBotToBot(String orgId, bool allowed) async =>
      botToBot = allowed;

  // Bot sharing (D-131)
  SetBotAccessRequest? savedAccess;
  @override
  Future<BotAccess> botAccess(String botId) async => BotAccess(
    visibility: BotAccessVisibilityEnum.private,
    createdBy: 'me',
    entries: [
      BotAccessEntry(
        userId: 'u-ana',
        email: 'ana@acme.test',
        role: null,
        access: BotAccessEntryAccessEnum.chat,
      ),
    ],
    canAdmin: true,
    yourAccess: BotAccessYourAccessEnum.admin,
  );
  @override
  Future<BotAccess> setBotAccess(
    String botId,
    SetBotAccessRequest request,
  ) async {
    savedAccess = request;
    return botAccess(botId);
  }

  List<WorkspaceMember> workspaceMembers = [
    WorkspaceMember(
      userId: 'me',
      email: 'me@acme.test',
      role: WorkspaceMemberRoleEnum.owner,
    ),
    WorkspaceMember(
      userId: 'u-ana',
      email: 'ana@acme.test',
      role: WorkspaceMemberRoleEnum.member,
    ),
    WorkspaceMember(
      userId: 'u-ben',
      email: 'ben@acme.test',
      role: WorkspaceMemberRoleEnum.member,
    ),
  ];
  @override
  Future<List<WorkspaceMember>> members(String orgId) async => workspaceMembers;

  // Welcome chat (D-129)
  var welcomeCalls = 0;
  @override
  Future<WelcomeChat> startWelcome({String? firstName}) async {
    welcomeCalls++;
    hasOrg = true;
    return WelcomeChat(
      orgId: orgId,
      botId: botId,
      conversationId: convId,
      created: true,
    );
  }

  // Password managers (D-128)
  final pmList = <PasswordManager>[];
  final pmActions = <String>[];
  @override
  Future<List<PasswordManager>> passwordManagers(String orgId) async =>
      List.of(pmList);
  @override
  Future<PasswordManager> connectPasswordManager(
    CreatePasswordManagerRequest request,
  ) async {
    pmActions.add('connect:${request.provider.value}:${request.scope.value}');
    final pm = PasswordManager(
      id: 'pm-1',
      scope: PasswordManagerScopeEnum.values.byName(request.scope.name),
      provider:
          request.provider ==
              CreatePasswordManagerRequestProviderEnum.n1password
          ? PasswordManagerProviderEnum.n1password
          : PasswordManagerProviderEnum.bitwarden,
      name: request.name,
      url: request.url,
      allowedVaults: const [],
      allowedBotIds: null,
      status: PasswordManagerStatusEnum.ok,
      lastError: null,
      createdAt: DateTime(2026, 11, 10),
    );
    pmList.add(pm);
    return pm;
  }

  @override
  Future<List<PasswordManagerVault>> passwordManagerVaults(String id) async => [
    PasswordManagerVault(
      id: 'v-work',
      name: 'Work',
      allowed: false,
      logins: null,
    ),
    PasswordManagerVault(
      id: 'v-home',
      name: 'Home',
      allowed: false,
      logins: null,
    ),
  ];
  @override
  Future<void> setPasswordManagerVaults(String id, List<String> vaults) async =>
      pmActions.add('vaults:$id:${vaults.join(',')}');
  @override
  Future<void> deletePasswordManager(String id) async {
    pmActions.add('delete:$id');
    pmList.removeWhere((p) => p.id == id);
  }

  // Step replay (D-127)
  final replayList = <Replay>[
    Replay(
      id: 'rp-1',
      botId: botId,
      name: 'file-expense',
      description: 'File an expense',
      params: [ReplayParamInfo(name: 'amount', default_: '42.50')],
      steps: [
        ReplayStepsInner(tool: 'desktop.click'),
        ReplayStepsInner(tool: 'desktop.type'),
      ],
      source_: ReplaySource_Enum.teach,
      runs: 3,
      failures: 1,
      lastFailure: 'step 2: couldn\'t find button "Submit"',
      lastRunAt: null,
      updatedAt: DateTime(2026, 11, 10),
    ),
  ];
  final replayActions = <String>[];
  @override
  Future<List<Replay>> replays(String botId) async => List.of(replayList);
  @override
  Future<RunReplayResponse> runReplay(
    String id,
    Map<String, String> params,
  ) async {
    replayActions.add('run:$id:${params['amount']}');
    return RunReplayResponse(conversationId: convId, runId: runId);
  }

  @override
  Future<void> deleteReplay(String id) async {
    replayActions.add('delete:$id');
    replayList.removeWhere((r) => r.id == id);
  }

  @override
  Future<Replay> replayFromTeach(
    String teachId,
    String name, {
    String? description,
  }) async {
    replayActions.add('fromTeach:$teachId:$name');
    return replayList.first;
  }

  // Self-improving skills (D-126)
  final proposals = <SkillProposal>[];
  final proposalActions = <String>[];
  @override
  Future<List<SkillProposal>> skillProposals(
    String orgId, {
    String? botId,
  }) async => List.of(proposals);
  @override
  Future<void> acceptSkillProposal(String id, {String? bodyMd}) async {
    proposalActions.add('accept:$id');
    proposals.removeWhere((p) => p.id == id);
  }

  @override
  Future<void> dismissSkillProposal(String id) async {
    proposalActions.add('dismiss:$id');
    proposals.removeWhere((p) => p.id == id);
  }

  @override
  Future<SkillStats> skillStats(String skillId) async => SkillStats(
    uses: 4,
    successes: 3,
    failures: 1,
    corrections: 0,
    successRate: 0.75,
    lastFailureAt: DateTime(2026, 11, 9),
    lastFailureRunId: null,
    revisions: [
      SkillStatsRevisionsInner(
        id: 'rev-a',
        description: 'd',
        bodyMd: 'Old steps',
        byBot: true,
        createdAt: DateTime(2026, 11, 8),
      ),
    ],
  );

  // Knowledge sources (D-125)
  final knowledgeList = <KnowledgeSource>[];
  final knowledgeActions = <String>[];
  CreateKnowledgeSourceRequest? addedKnowledge;
  @override
  Future<List<KnowledgeSource>> knowledgeSources(
    String orgId, {
    String? botId,
  }) async => List.of(knowledgeList);
  @override
  Future<KnowledgeSource> addKnowledgeSource(
    CreateKnowledgeSourceRequest request,
  ) async {
    addedKnowledge = request;
    final k = KnowledgeSource(
      id: 'ks-${knowledgeList.length + 1}',
      botId: request.botId,
      kind: KnowledgeSourceKindEnum.values.byName(request.kind.name),
      name: request.name,
      config: const {},
      status: KnowledgeSourceStatusEnum.ready,
      error: null,
      documents: request.files?.length ?? 3,
      chunks: 12,
      lastSyncedAt: null,
      createdAt: DateTime(2026, 11, 10),
    );
    knowledgeList.add(k);
    return k;
  }

  @override
  Future<void> resyncKnowledgeSource(String id) async =>
      knowledgeActions.add('sync:$id');
  @override
  Future<void> deleteKnowledgeSource(String id) async {
    knowledgeActions.add('delete:$id');
    knowledgeList.removeWhere((k) => k.id == id);
  }

  // Chat apps (D-134)
  final channelList = <Channel>[];
  final channelActions = <String>[];
  CreateChannelRequest? createdChannel;
  @override
  Future<List<Channel>> channels(String botId) async => List.of(channelList);

  /// Casama's Slack app (D-277): the install address, or null when the server has none (409).
  String? slackInstall;
  final slackInstallAsks = <String>[];
  @override
  Future<String?> slackInstallUrl(String botId) async {
    slackInstallAsks.add(botId);
    return slackInstall;
  }
  @override
  Future<Channel> createChannel(CreateChannelRequest request) async {
    createdChannel = request;
    final id = 'ch-${channelList.length + 1}';
    final ch = Channel(
      id: id,
      botId: request.botId,
      kind: request.kind,
      name: request.name,
      config: request.config ?? const {},
      allowedSenders: request.allowedSenders,
      enabled: true,
      webhookUrl: request.kind == ChannelKind.imessage
          ? null
          : 'https://api.example.com/hooks/channels/$id',
      verifyToken: request.kind == ChannelKind.whatsapp ? 'verify-123' : null,
      lastInboundAt: null,
      lastError: null,
      createdAt: DateTime.utc(2026, 11, 1),
    );
    channelList.add(ch);
    return ch;
  }

  @override
  Future<Channel> updateChannel(
    String id, {
    String? name,
    List<String>? allowedSenders,
    bool? enabled,
  }) async {
    channelActions.add(
      [
        'update:$id',
        if (allowedSenders != null) 'senders:${allowedSenders.join(',')}',
        if (enabled != null) 'enabled:$enabled',
      ].join(' '),
    );
    final i = channelList.indexWhere((c) => c.id == id);
    final c = channelList[i];
    channelList[i] = Channel.fromJson({
      ...c.toJson(),
      'allowed_senders': ?allowedSenders,
      'enabled': ?enabled,
    });
    return channelList[i];
  }

  @override
  Future<void> deleteChannel(String id) async {
    channelActions.add('delete:$id');
    channelList.removeWhere((c) => c.id == id);
  }

  @override
  Future<List<ChannelEvent>> channelEvents(String id) async => [
    ChannelEvent(
      id: 'ev-1',
      direction: ChannelEventDirectionEnum.in_,
      status: ChannelEventStatusEnum.ignored,
      sender: 'stranger@example.com',
      preview: 'Buy now',
      detail: "Sender isn't on the allowed list",
      createdAt: DateTime.utc(2026, 11, 1, 9),
    ),
    ChannelEvent(
      id: 'ev-2',
      direction: ChannelEventDirectionEnum.out_,
      status: ChannelEventStatusEnum.sent,
      sender: 'ana@example.com',
      preview: 'Done!',
      detail: null,
      createdAt: DateTime.utc(2026, 11, 1, 8),
    ),
  ];

  // Routines and skills as files (D-124)
  final fileActions = <String>[];
  GitSyncStatus gitStatus = GitSyncStatus(
    configured: false,
    repo: null,
    branch: null,
    path: null,
    enabled: false,
    hasToken: true,
    webhookUrl: null,
    webhookSecret: null,
    lastSyncedAt: null,
    lastCommit: null,
    lastError: null,
    openPrUrl: null,
  );
  @override
  Future<Uint8List> exportWorkspaceFiles(String orgId) async {
    fileActions.add('export');
    return Uint8List.fromList([80, 75]);
  }

  @override
  Future<WorkspaceFilesResult> importWorkspaceFiles(
    String orgId,
    Uint8List zip, {
    bool dryRun = false,
  }) async {
    fileActions.add(dryRun ? 'dry' : 'import');
    return WorkspaceFilesResult(
      created: const ['ada/routines/weekly.md'],
      updated: const ['ada/routines/brief.md'],
      deleted: const [],
      unchanged: 2,
      errors: const ['ada/routines/bad.md: bad cron'],
      dryRun: dryRun,
    );
  }

  @override
  Future<GitSyncStatus> gitSync(String orgId) async => gitStatus;
  @override
  Future<GitSyncStatus> setGitSync(
    String orgId, {
    required String repo,
    String? branch,
    String? path,
    bool enabled = true,
  }) async {
    fileActions.add('git:$repo:$branch:$path');
    gitStatus = GitSyncStatus(
      configured: true,
      repo: repo,
      branch: branch,
      path: path,
      enabled: enabled,
      hasToken: true,
      webhookUrl: 'https://api.example.com/hooks/git-sync/o',
      webhookSecret: 'sec-1',
      lastSyncedAt: null,
      lastCommit: null,
      lastError: null,
      openPrUrl: null,
    );
    return gitStatus;
  }

  @override
  Future<GitSyncStatus> runGitSync(String orgId) async {
    fileActions.add('run');
    return gitStatus;
  }

  @override
  Future<GitSyncStatus> deleteGitSync(String orgId) async => gitStatus;

  // Import an agent (D-122)
  BotTemplateFile? importedTemplate;
  final importActions = <String>[];
  @override
  Future<AgentImportPlan> startAgentImport(
    String orgId, {
    Uint8List? zip,
    Map<String, Uint8List>? files,
  }) async {
    importActions.add(
      zip != null ? 'zip:${zip.length}' : 'files:${files?.keys.join(',')}',
    );
    return agentPlan();
  }

  AgentImportPlan agentPlan() => AgentImportPlan(
    id: 'imp-1',
    kind: AgentImportPlanKindEnum.openclaw,
    template: BotTemplateFile(
      format: BotTemplateFileFormatEnum.casamaPeriodBot,
      version: 1,
      name: 'Juno',
      description: 'Imported from OpenClaw',
      personaMd: 'You are Juno.',
      autonomy: BotTemplateFileAutonomyEnum.askRisky,
      skills: [
        BotTemplateFileSkillsInner(
          name: 'triage',
          description: 'Triage the inbox',
          bodyMd: 'Sort.',
        ),
      ],
      routines: [
        BotTemplateFileRoutinesInner(
          name: 'Brief',
          instructionsMd: 'Brief me',
          scheduleCron: '0 7 * * *',
        ),
      ],
      memories: [
        BotTemplateFileMemoriesInner(
          kind: BotTemplateFileMemoriesInnerKindEnum.preference,
          content: 'Prefers mornings',
        ),
        BotTemplateFileMemoriesInner(
          kind: BotTemplateFileMemoriesInnerKindEnum.fact,
          content: 'Old address',
        ),
      ],
      connections: const [],
    ),
    sources: AgentImportPlanSources(
      skills: const ['workspace/skills/triage/SKILL.md'],
      routines: const ['cron/jobs.json'],
      memories: const ['USER.md', 'MEMORY.md'],
    ),
    leftovers: [
      AgentImportPlanLeftoversInner(path: 'workspace/notes/plan.md', size: 8),
    ],
    skipped: [AgentImportPlanSkippedInner(path: '.env', reason: 'secrets')],
    notes: const [
      '"Reminder" ran once at a set time; not imported as a routine',
    ],
  );
  @override
  Future<int> writeAgentImportFiles(String importId, String botId) async {
    importActions.add('files:$importId:$botId');
    return 1;
  }

  final pasted = <String>[];
  @override
  Future<String> pasteImportPrompt(PasteImportSource source) async =>
      'Describe yourself (${source.value}). NAME: … INSTRUCTIONS: …';
  @override
  Future<AgentImportPlan> pasteBotImport(
    String orgId,
    PasteImportSource source,
    String text,
  ) async {
    pasted.add('${source.value}:$text');
    return AgentImportPlan(
      id: 'paste-1',
      kind: AgentImportPlanKindEnum.grokBot,
      template: BotTemplateFile(
        format: BotTemplateFileFormatEnum.casamaPeriodBot,
        version: 1,
        name: 'Scout',
        description: 'Imported from Grok Bot',
        personaMd: 'Find leads.',
        autonomy: BotTemplateFileAutonomyEnum.askRisky,
        skills: const [],
        routines: [
          BotTemplateFileRoutinesInner(
            name: 'Send me five new leads',
            instructionsMd: 'Send me five new leads',
            scheduleCron: '0 9 * * 1-5',
          ),
        ],
        memories: const [],
        connections: [
          BotTemplateFileConnectionsInner(kind: 'app', name: 'HubSpot'),
        ],
      ),
      sources: AgentImportPlanSources(
        skills: const [],
        routines: const ['SCHEDULE, line 3'],
        memories: const [],
      ),
      leftovers: const [],
      skipped: const [],
      notes: const ['"New reply" runs on an event, so it wasn\'t brought over.'],
    );
  }

  @override
  Future<String> memoryImportPrompt() async => 'FACT: … PREFERENCE: …';
  @override
  Future<List<ImportedMemoryItem>> parseMemoryImport(String text) async => [
    ImportedMemoryItem(
      kind: ImportedMemoryItemKindEnum.fact,
      content: 'Has a dog',
    ),
    ImportedMemoryItem(
      kind: ImportedMemoryItemKindEnum.preference,
      content: 'Metric units',
    ),
  ];
  final savedMemories = <ImportedMemoryItem>[];
  @override
  Future<int> saveImportedMemories(
    String botId,
    List<ImportedMemoryItem> memories,
  ) async {
    savedMemories.addAll(memories);
    return memories.length;
  }

  // Plugins (D-121)
  final pluginList = <Plugin>[];
  final pluginActions = <String>[];
  PluginPreview pluginPreview() => PluginPreview(
    name: 'weather',
    version: '1.0.0',
    description: 'Forecasts',
    repo: 'acme/agent-plugins',
    path: 'plugins/weather',
    commit: '1' * 40,
    skills: [
      PluginPreviewSkillsInner(
        name: 'plan-trip',
        description: 'Plan around the weather',
      ),
    ],
    servers: [
      PluginServerInfo(
        key: 'forecast',
        type: PluginServerInfoTypeEnum.stdio,
        command: './bin/forecast',
        args: const [],
        url: null,
      ),
    ],
    secrets: [
      PluginSecretInfo(
        name: 'WEATHER_KEY',
        description: 'API key',
        server: 'forecast',
      ),
    ],
    hosts: const [],
    warnings: const [],
  );
  Plugin installed(String commit, {String? deviceId}) => Plugin(
    id: 'plugin-1',
    botId: botId,
    name: 'weather',
    version: commit.startsWith('2') ? '2.0.0' : '1.0.0',
    description: 'Forecasts',
    repo: 'acme/agent-plugins',
    path: 'plugins/weather',
    commit: commit,
    skills: [PluginSkillsInner(id: 'sk-1', name: 'plan-trip')],
    servers: [
      InstalledPluginServer(
        key: 'forecast',
        type: InstalledPluginServerTypeEnum.stdio,
        command: './bin/forecast',
        args: const [],
        url: null,
        integrationId: 'int-1',
        status: InstalledPluginServerStatusEnum.ok,
        error: null,
        tools: [
          InstalledPluginServerAllOfTools(
            name: 'forecast',
            risk: InstalledPluginServerAllOfToolsRiskEnum.low,
          ),
        ],
      ),
    ],
    hosts: const [],
    secrets: const [],
    runsOn: deviceId == null
        ? null
        : PluginRunsOn(deviceId: deviceId, deviceName: device?.name ?? 'This computer', ownerUserId: 'me', online: device?.online ?? true),
    installedAt: DateTime(2026, 11, 10),
    updatedAt: DateTime(2026, 11, 10),
  );
  @override
  Future<List<Plugin>> plugins(String botId) async => List.of(pluginList);
  @override
  Future<PluginPreview> previewPlugin(String orgId, String url, {String? commit}) async {
    pluginActions.add(commit == null ? 'preview:$url' : 'preview:$url@$commit');
    return pluginPreview();
  }

  /// The plugin directory (D-241); tests add entries.
  final directoryPlugins = <DirectoryPlugin>[];
  @override
  Future<List<DirectoryPlugin>> pluginDirectory() async => List.of(directoryPlugins);

  /// Routine ideas (D-241); tests add entries.
  final routineIdeaList = <RoutineIdea>[];
  @override
  Future<List<RoutineIdea>> routineIdeas() async => List.of(routineIdeaList);

  /// Remote app settings (D-241); tests replace them.
  RemoteAppConfig remoteConfig = RemoteAppConfig(
    minVersions: RemoteAppConfigMinVersions(),
    updateUrls: RemoteAppConfigUpdateUrls(),
    maintenance: null,
    announcements: const [],
    flags: const {},
  );
  @override
  Future<RemoteAppConfig> appConfig() async => remoteConfig;
  @override
  Future<RemoteAppConfig> adminAppConfig() async => remoteConfig;

  /// Admin's JSON settings (D-373, D-374), saved as given.
  final adminJsonSettings = <AdminJsonSettingKind, Map<String, dynamic>>{};
  @override
  Future<AdminJsonSetting> adminJsonSetting(AdminJsonSettingKind kind) async =>
      AdminJsonSetting(saved: adminJsonSettings[kind] ?? {}, builtIn: const {'default_models': {'openrouter': 'fixture-main'}});
  @override
  Future<AdminJsonSetting> saveAdminJsonSetting(AdminJsonSettingKind kind, Map<String, dynamic> value) async {
    adminJsonSettings[kind] = value;
    return adminJsonSetting(kind);
  }
  @override
  Future<RemoteAppConfig> setAdminAppConfig(Map<String, dynamic> settings) async =>
      remoteConfig = RemoteAppConfig.fromJson(
        jsonDecode(jsonEncode({'min_versions': {}, 'update_urls': {}, 'maintenance': null, 'announcements': [], 'flags': {}, ...settings}))
            as Map<String, dynamic>,
      );

  /// The gallery's content lists (D-372); null answers like an older server (an error).
  GalleryLists? galleryListsValue;
  @override
  Future<GalleryLists> galleryLists() async => galleryListsValue ?? (throw StateError('no lists on this server'));

  /// Email copy (D-372); tests read what was saved.
  Map<String, Object?> emailCopy = {};
  @override
  Future<EmailCopySettings> adminEmailCopy() async => EmailCopySettings(copy: emailCopy, defaults: const {'welcome': {'subject': 'Welcome to Casama'}});
  @override
  Future<EmailCopySettings> setAdminEmailCopy(Map<String, dynamic> copy) async {
    emailCopy = copy;
    return adminEmailCopy();
  }

  @override
  Future<Plugin> installPlugin(
    String orgId,
    String botId,
    String url,
    String commit,
    Map<String, String> secrets, {
    String? deviceId,
  }) async {
    pluginActions.add('install:$commit:${secrets['WEATHER_KEY']}${deviceId == null ? '' : ':on:$deviceId'}');
    pluginList.add(installed(commit, deviceId: deviceId));
    return pluginList.last;
  }

  @override
  Future<PluginUpdatePreview> pluginUpdate(String id) async =>
      PluginUpdatePreview(
        upToDate: false,
        fromCommit: '1' * 40,
        toCommit: '2' * 40,
        fromVersion: '1.0.0',
        toVersion: '2.0.0',
        skillsAdded: const [],
        skillsRemoved: const [],
        skillsChanged: const ['plan-trip'],
        serversAdded: const ['tides'],
        serversRemoved: const [],
        serversChanged: const [],
        hostsAdded: const [],
        secretsAdded: const [],
        preview: pluginPreview(),
      );
  @override
  Future<Plugin> updatePlugin(
    String id,
    String commit, {
    Map<String, String> secrets = const {},
  }) async {
    pluginActions.add('update:$commit');
    pluginList[0] = installed(commit);
    return pluginList[0];
  }

  @override
  Future<void> uninstallPlugin(String id) async {
    pluginActions.add('uninstall:$id');
    pluginList.clear();
  }

  @override
  Future<Plugin> updatePluginSettings(String id, Map<String, String> settings) async {
    pluginActions.add('settings:$id:${settings.entries.map((e) => '${e.key}=${e.value}').join(',')}');
    final i = pluginList.indexWhere((p) => p.id == id);
    final json = pluginList[i].toJson();
    json['settings'] = [
      for (final s in (json['settings'] as List? ?? const []))
        {...(s as Map).cast<String, dynamic>(), if (settings.containsKey(s['name'])) 'value': settings[s['name']]},
    ];
    pluginList[i] = Plugin.fromJson(jsonDecode(jsonEncode(json)) as Map<String, dynamic>);
    return pluginList[i];
  }

  // Packs (docs/PLUGINS-AND-PACKS-PLAN.md)
  final packActions = <String>[];

  /// What the last install sent: skip, inputs, secrets, settings and bot.
  Map<String, Object?>? lastPackInstall;
  final installedPacks = <Pack>[];
  final galleryPackList = <GalleryPack>[];

  /// The next install waits for an admin (202).
  var packApprovalPending = false;

  /// The next install fails with this.
  Object? packInstallError;
  late PackPreview packPreviewValue = PackPreview.fromJson(packPreviewJson());
  PackUpdatePreview? packUpdateValue;
  var packRemoveKept = 0;
  var packFindings = <PackSecretFinding>[];
  PackShareView? packShareValue;

  static Map<String, dynamic> packPreviewJson({bool reviewed = false, bool withBot = true}) => {
    'name': 'trip-kit',
    'title': 'Trip kit',
    'version': '1.0.0',
    'description': 'Plan trips with a bot that knows the weather',
    'summary': 'A trip planner with weather and deals',
    'icon': 'plane',
    'author': 'Acme',
    'license': 'MIT',
    'homepage': null,
    'source': {'kind': 'github', 'repo': 'acme/trip-kit', 'path': '', 'url': 'https://github.com/acme/trip-kit', 'gallery_id': null},
    'commit': '1' * 40,
    'reviewed': reviewed,
    'bots': [
      if (withBot)
        {
          'id': 'planner',
          'name': 'Trip planner',
          'description': 'Plans trips',
          'icon': 'plane',
          'mascot': '',
          'autonomy': 'ask_risky',
          'persona': 'You plan trips.',
          'starters': ['Plan a weekend'],
          'skills': ['plan-trip'],
          'routines': ['deals'],
          'tools': ['forecast'],
        },
    ],
    'routines': [
      {'id': 'deals', 'name': 'Weekly deals', 'description': 'Looks for deals', 'instructions_md': 'Find deals.', 'schedule_cron': '0 9 * * 1', 'bot': withBot ? 'planner' : null, 'runs_per_week': 1},
    ],
    'skills': [
      {'name': 'plan-trip', 'description': 'Plan around the weather', 'scope': 'bot', 'bots': ['planner'], 'runs_scripts': false},
      {'name': 'budget', 'description': 'Keeps a budget', 'scope': 'workspace', 'bots': [], 'runs_scripts': true},
    ],
    'apps': [
      {'id': 'flights', 'name': 'Flights', 'description': 'Flight search', 'host': 'api.flights.example', 'url': 'https://api.flights.example', 'auth': ['api_key'], 'capabilities': ['read'], 'color': '#3366ff'},
    ],
    'looks': [
      {'type': 'scheme', 'id': 'sunset', 'name': 'Sunset', 'document': {'name': 'Sunset'}},
    ],
    'includes': [],
    'servers': [
      {'key': 'forecast', 'type': 'stdio', 'command': './bin/forecast', 'args': [], 'url': null},
    ],
    'secrets': [
      {'name': 'WEATHER_KEY', 'description': 'API key', 'server': 'forecast'},
    ],
    'settings': [
      {'name': 'UNITS', 'label': 'Units', 'description': 'metric or imperial', 'server': 'forecast', 'default': 'metric'},
    ],
    'inputs': [
      {'key': 'city', 'label': 'Home city', 'type': 'text'},
    ],
    'needs_apps': [],
    'examples': [],
    'reach': {'runs_code': true, 'computer': true, 'hosts': ['api.weather.example'], 'secrets': ['WEATHER_KEY'], 'settings': ['UNITS'], 'runs_per_week': 1, 'computers': 1},
    'warnings': [],
    'installed': null,
  };

  static Map<String, dynamic> packJson({String id = 'pack-1', bool edited = true, Map<String, dynamic>? source}) => {
    'id': id,
    'org_id': orgId,
    'name': 'trip-kit',
    'title': 'Trip kit',
    'version': '1.0.0',
    'description': 'Plan trips',
    'summary': 'A trip planner with weather and deals',
    'icon': 'plane',
    'source': source ?? {'kind': 'github', 'repo': 'acme/trip-kit', 'path': '', 'url': 'https://github.com/acme/trip-kit', 'gallery_id': null},
    'commit': '1' * 40,
    'reviewed': false,
    'items': [
      {'kind': 'bot', 'id': 'planner', 'name': 'Trip planner', 'target_id': botId, 'bot_id': botId, 'edited': edited},
      {'kind': 'skill', 'id': 'plan-trip', 'name': 'plan-trip', 'target_id': 'sk-1', 'bot_id': botId, 'edited': false},
      {'kind': 'routine', 'id': 'deals', 'name': 'Weekly deals', 'target_id': 'r-1', 'bot_id': botId, 'edited': false},
    ],
    'installed_at': '2026-11-10T09:00:00.000Z',
    'updated_at': '2026-11-10T09:00:00.000Z',
  };

  @override
  Future<PackPreview> previewPack(String orgId, PackFrom from) async {
    packActions.add('preview:${from.url ?? from.galleryId ?? from.shareToken ?? 'files:${from.files?.length}'}');
    return packPreviewValue;
  }

  @override
  Future<PackInstallResult> installPack(
    String orgId,
    PackFrom from, {
    List<PackItemRef> skip = const [],
    Map<String, String>? inputs,
    Map<String, String>? secrets,
    Map<String, String>? settings,
    String? botId,
    String? deviceId,
  }) async {
    lastPackInstall = {
      'device_id': ?deviceId,
      'url': from.url,
      'commit': from.commit,
      'gallery_id': from.galleryId,
      'share_token': from.shareToken,
      'skip': [for (final s in skip) '${s.kind.value}:${s.id}'],
      'inputs': inputs,
      'secrets': secrets,
      'settings': settings,
      'bot_id': botId,
    };
    packActions.add('install');
    if (packInstallError case final e?) throw e;
    if (packApprovalPending) {
      return PackInstallResult.fromJson({
        'status': 'approval_pending',
        'approval_id': '66666666-6666-4666-8666-666666666666',
        'items': [],
        'missing': {'apps': [], 'skills': []},
        'looks': [],
      });
    }
    final pack = Pack.fromJson(packJson(edited: false));
    installedPacks.add(pack);
    final skipped = {for (final s in skip) '${s.kind.value}:${s.id}'};
    String status(String kind, String id) => skipped.contains('$kind:$id') ? 'skipped' : 'installed';
    return PackInstallResult.fromJson({
      'status': 'installed',
      'approval_id': null,
      'pack': packJson(edited: false),
      'items': [
        {'kind': 'bot', 'id': 'planner', 'name': 'Trip planner', 'status': status('bot', 'planner'), 'target_id': botId, 'error': null},
        {'kind': 'skill', 'id': 'budget', 'name': 'budget', 'status': status('skill', 'budget'), 'target_id': null, 'error': skipped.contains('skill:budget') ? 'Left out' : null},
        {'kind': 'app', 'id': 'flights', 'name': 'Flights', 'status': 'failed', 'target_id': null, 'error': 'Plan limit reached'},
        {'kind': 'look', 'id': 'sunset', 'name': 'Sunset', 'status': 'device', 'target_id': null, 'error': null},
      ],
      'missing': {
        'apps': [
          {'id': 'flights', 'name': 'Flights'},
        ],
        'skills': [],
      },
      'looks': [
        {'type': 'scheme', 'id': 'sunset', 'name': 'Sunset', 'document': {'name': 'Sunset'}},
      ],
    });
  }

  @override
  Future<List<Pack>> packs(String orgId) async => List.of(installedPacks);

  @override
  Future<Pack> pack(String id) async => installedPacks.firstWhere((p) => p.id == id);

  @override
  Future<PackUpdatePreview> packUpdate(String id) async {
    packActions.add('check:$id');
    return packUpdateValue ??
        PackUpdatePreview.fromJson({
          'up_to_date': true,
          'can_check': true,
          'from_commit': '1' * 40,
          'to_commit': '1' * 40,
          'from_version': '1.0.0',
          'to_version': '1.0.0',
          for (final k in ['bots', 'routines', 'skills', 'apps', 'looks', 'servers']) k: {'added': [], 'removed': [], 'changed': []},
          'hosts_added': [],
          'secrets_added': [],
          'schedules_changed': [],
          'runs_per_week': {'from': 1, 'to': 1},
          'reach_grew': false,
          'edited': [],
        });
  }

  @override
  Future<PackInstallResult> updatePack(
    String id,
    String commit, {
    List<PackItemRef> takeTheirs = const [],
    bool confirmReach = false,
    Map<String, String>? secrets,
    Map<String, String>? settings,
  }) async {
    packActions.add(
      'update:$id:$commit:theirs=${takeTheirs.map((t) => '${t.kind.value}:${t.id}').join(',')}:reach=$confirmReach:secrets=${secrets?.keys.join(',') ?? ''}',
    );
    if ((packUpdateValue?.reachGrew ?? false) && !confirmReach) {
      throw const PackError('pack_reach_grew', 'The new version can reach more than the one you have.');
    }
    return PackInstallResult.fromJson({
      'status': 'installed',
      'approval_id': null,
      'pack': packJson(),
      'items': [],
      'missing': {'apps': [], 'skills': []},
      'looks': [],
    });
  }

  @override
  Future<int> removePack(String id, {bool deleteBots = false}) async {
    packActions.add('remove:$id:${deleteBots ? 'delete' : 'keep'}');
    installedPacks.removeWhere((p) => p.id == id);
    return packRemoveKept;
  }

  ExportPackRequest? lastPackExport;
  @override
  Future<PackExport> exportPack(String orgId, ExportPackRequest request) async {
    lastPackExport = request;
    packActions.add('export:${request.name}:${request.botIds.join(',')}');
    return PackExport(
      name: request.name,
      files: [PackExportFile(path: 'com.casama/pack.json', text: '{}', base64: null, executable: false)],
      findings: packFindings,
    );
  }

  @override
  Future<PackShare> sharePack(String orgId, SharePackRequest request) async {
    packActions.add('share:${request.name}:ignore=${request.ignoreFindings ?? false}');
    if (packFindings.isNotEmpty && request.ignoreFindings != true) {
      throw const PackError('pack_has_secrets', 'Some lines look like keys.');
    }
    return PackShare(
      id: '77777777-7777-4777-8777-777777777777',
      url: 'https://app.casama.ai/packs/share/tok-1234567890',
      token: 'tok-1234567890',
      expiresAt: DateTime(2026, 12, 17),
      findings: packFindings,
    );
  }

  @override
  Future<PackShareView> packShare(String token) async {
    packActions.add('share-view:$token');
    return packShareValue ??
        PackShareView(id: '77777777-7777-4777-8777-777777777777', preview: packPreviewValue, expiresAt: DateTime(2026, 12, 17));
  }

  @override
  Future<void> revokePackShare(String token) async {
    packActions.add('revoke:$token');
  }

  @override
  Future<List<GalleryPack>> galleryPacks() async => List.of(galleryPackList);

  // Teach a task (D-120)
  final teachSteps = <AddTeachStepRequest>[];
  final teachActions = <String>[];
  TeachSessionStatusEnum teachStatus = TeachSessionStatusEnum.recording;
  TeachDraft? teachDraft;
  String? teachErrorCode;
  String? teachErrorMessage;
  ({String name, String description, String body, bool tryNow})? savedTeach;
  TeachStep teachStep(int seq, AddTeachStepRequest r, {String? secret}) =>
      TeachStep(
        seq: seq,
        kind: TeachStepKindEnum.values.byName(r.kind.name),
        x: r.x,
        y: r.y,
        button: r.button,
        text: secret != null ? null : r.text,
        key: r.key,
        dx: r.dx,
        dy: r.dy,
        secretName: secret,
        password: false,
        url: 'https://finance.example.com',
        hasScreenshot: true,
        createdAt: DateTime(2026, 11, 10),
      );
  TeachSession teachSession() => TeachSession(
    id: 'teach-1',
    botId: botId,
    computerId: computerId,
    status: teachStatus,
    conversationId: null,
    draft: teachDraft,
    skillId: null,
    steps: [
      for (var i = 0; i < teachSteps.length; i++)
        teachStep(i + 1, teachSteps[i]),
    ],
    startedAt: DateTime(2026, 11, 10),
    stoppedAt: null,
    errorCode: teachErrorCode,
    errorMessage: teachErrorMessage,
  );
  @override
  Future<TeachSession> startTeach(String computerId, String botId) async {
    teachActions.add('start:$botId');
    return teachSession();
  }

  @override
  Future<TeachSession> teach(String id) async => teachSession();
  @override
  Future<TeachStep> addTeachStep(String id, AddTeachStepRequest step) async {
    teachSteps.add(step);
    return teachStep(teachSteps.length, step);
  }

  @override
  Future<TeachStep> markTeachSecret(String id, int seq, String name) async {
    teachActions.add('secret:$seq:$name');
    return teachStep(seq, teachSteps[seq - 1], secret: name);
  }

  @override
  Future<TeachSession> stopTeach(String id) async {
    teachActions.add('stop');
    teachStatus = TeachSessionStatusEnum.drafting;
    return teachSession();
  }

  @override
  Future<SaveTeachResponse> saveTeach(
    String id, {
    required String name,
    required String description,
    required String body,
    bool tryNow = false,
  }) async {
    savedTeach = (
      name: name,
      description: description,
      body: body,
      tryNow: tryNow,
    );
    return SaveTeachResponse(
      skillId: 'skill-9',
      conversationId: tryNow ? convId : null,
      runId: tryNow ? runId : null,
    );
  }

  @override
  Future<void> cancelTeach(String id) async => teachActions.add('cancel');

  final pageList = <BotPage>[
    BotPage(
      id: 'page-1',
      botId: botId,
      title: 'Weekly sales',
      visibility: BotPageVisibilityEnum.private,
      version: 3,
      expiresAt: null,
      refreshRoutineId: 'rt-1',
      conversationId: null,
      canManage: true,
      updatedAt: DateTime(2026, 11, 10, 9),
      createdAt: DateTime(2026, 11, 1),
    ),
  ];
  final pageActions = <String>[];
  @override
  Future<List<BotPage>> pages(String orgId, {String? botId}) async =>
      List.of(pageList);
  @override
  Future<String> pageViewLink(String id, {bool pdf = false}) async {
    pageActions.add('${pdf ? 'pdf' : 'view'}:$id');
    return 'https://pages.example.com/v/tok-$id';
  }

  @override
  Future<String?> setPageVisibility(
    String id,
    BotPageVisibilityEnum visibility, {
    int? expiresInDays,
  }) async {
    pageActions.add('${visibility.name}:$id');
    return visibility == BotPageVisibilityEnum.public
        ? 'https://pages.example.com/s/public-$id'
        : null;
  }

  @override
  Future<void> deletePage(String id) async {
    pageActions.add('delete:$id');
    pageList.removeWhere((p) => p.id == id);
  }

  // Sites: none by default, so the Library shows no Publish to the Web.
  @override
  SitesConfig? sitesConfig;
  List<Site> siteList = [];
  final siteActions = <String>[];

  /// Address names that are taken, with the server's words.
  Map<String, String> takenSiteLabels = {};

  @override
  Future<List<Site>> sites(String orgId) async => List.of(siteList);

  @override
  Future<SiteAddressCheck> checkSiteAddress(String orgId, String label) async {
    siteActions.add('check:$label');
    final taken = takenSiteLabels[label];
    return SiteAddressCheck(
      label: label,
      available: taken == null,
      reason: taken == null ? null : 'taken',
      message: taken,
      url: 'https://$label.${sitesConfig?.zone ?? 'sites.example'}',
    );
  }

  @override
  Future<Site> publishSite(String pageId, {String? label, bool? indexable}) async {
    siteActions.add('publish:$pageId:${label ?? ''}:${indexable ?? ''}');
    final i = siteList.indexWhere((x) => x.pageId == pageId);
    final old = i < 0 ? null : siteList[i];
    final name = label ?? old?.label ?? 'site';
    final site = fakeSite(
      pageId,
      label: name,
      zone: sitesConfig?.zone ?? 'sites.example',
      indexable: indexable ?? old?.indexable ?? false,
      canIndex: old?.canIndex ?? true,
      hosts: old?.hosts ?? [fakeSiteHost('$name.${sitesConfig?.zone ?? 'sites.example'}')],
    );
    if (i < 0) {
      siteList.add(site);
    } else {
      siteList[i] = site;
    }
    return site;
  }

  @override
  Future<void> unpublishSite(String pageId) async {
    siteActions.add('unpublish:$pageId');
    siteList.removeWhere((x) => x.pageId == pageId);
  }

  // Domains: off by default (sitesConfig is null), so Settings shows no Domains row.
  List<Domain> domainList = [];
  final domainActions = <String>[];

  /// Names another workspace has proved: connecting them answers this claim record.
  Map<String, ConnectDomainResultClaim> domainClaims = {};

  /// Thrown by connectDomain and checkDomain when set (a 400, 409 or 429 from the server).
  Object? connectDomainError;
  Object? checkDomainError;

  Domain _domainById(String id) => domainList.firstWhere((d) => d.id == id);

  void _putDomain(Domain d) {
    final i = domainList.indexWhere((x) => x.id == d.id);
    if (i < 0) {
      domainList.add(d);
    } else {
      domainList[i] = d;
    }
  }

  @override
  Future<List<Domain>> domains(String orgId) async => List.of(domainList);

  @override
  Future<ConnectDomainResult> connectDomain(String orgId, String name, {String? pageId}) async {
    domainActions.add('connect:$name:${pageId ?? ''}');
    final error = connectDomainError;
    if (error != null) throw error;
    final claim = domainClaims[name];
    if (claim != null) return ConnectDomainResult(domain: null, claim: claim);
    final d = fakeDomain('d-${domainList.length + 1}', name: name, pageId: pageId);
    domainList.add(d);
    return ConnectDomainResult(domain: d, claim: null);
  }

  @override
  Future<Domain> domain(String id) async {
    domainActions.add('get:$id');
    return _domainById(id);
  }

  @override
  Future<Domain> checkDomain(String id) async {
    domainActions.add('check:$id');
    final error = checkDomainError;
    if (error != null) throw error;
    return _domainById(id);
  }

  @override
  Future<Domain> setDomainSite(String id, String? pageId) async {
    domainActions.add('site:$id:${pageId ?? ''}');
    String? title;
    for (final s in siteList) {
      if (s.pageId == pageId) title = s.title;
    }
    final d = _domainById(id).copyWith(pageId: pageId, pageTitle: title);
    _putDomain(d);
    return d;
  }

  @override
  Future<Domain> setDomainPrimaryHost(String id, String hostname) async {
    domainActions.add('primary:$id:$hostname');
    final old = _domainById(id);
    final d = old.copyWith(
      hosts: [for (final h in old.hosts) h.copyWith(isPrimary: h.hostname == hostname)],
    );
    _putDomain(d);
    return d;
  }

  @override
  Future<void> deleteDomain(String id) async {
    domainActions.add('delete:$id');
    domainList.removeWhere((d) => d.id == id);
  }

  // Buying and keeping a domain.
  /// Search answers by query; anything else answers nothing.
  Map<String, List<DomainSearchResult>> domainSearchResults = {};
  DomainContact? savedDomainContact;
  String defaultDomainEmail = 'ada@example.com';

  /// The checkout's payment page; null means the saved payment method was charged.
  String? domainCheckoutUrl = 'https://pay.example/checkout';

  /// The statuses getDomainOrder answers in turn (the last one repeats).
  List<String> domainOrderStatuses = ['registered', 'done'];
  String? domainOrderFailure;
  String? domainOrderDomainId;

  /// Thrown by the call of that name when set (a 4xx from the server).
  Object? domainCheckoutError;
  Object? saveDomainContactError;
  Object? renewDomainError;
  Object? addDomainRecordError;
  Object? transferOutError;
  String transferCode = 'EPP-CODE-123';
  Map<String, List<DnsRecordItem>> domainRecordLists = {};

  DomainOrder _order(String id, String name, String status, {String kind = 'register'}) => DomainOrder(
    id: id,
    kind: kind,
    name: name,
    priceUsd: 14.5,
    status: status,
    failure: status == 'refunded' || status == 'needs_attention' ? domainOrderFailure : null,
    needsApproval: false,
    domainId: status == 'done' || status == 'registered' ? domainOrderDomainId : null,
    createdAt: DateTime(2026, 11, 16),
    paidAt: null,
    refundedAt: status == 'refunded' ? DateTime(2026, 11, 16) : null,
  );
  final _orderPolls = <String, int>{};

  @override
  Future<DomainSearchList> searchDomains(String orgId, String q) async {
    domainActions.add('search:$q');
    return DomainSearchList(query: q, items: domainSearchResults[q] ?? const [], tlds: const ['com', 'net']);
  }

  @override
  Future<DomainContactState> domainContact(String orgId) async =>
      DomainContactState(contact: savedDomainContact, defaultEmail: defaultDomainEmail);

  @override
  Future<DomainContactState> saveDomainContact(String orgId, DomainContact contact) async {
    domainActions.add('contact:${contact.email}');
    final error = saveDomainContactError;
    if (error != null) throw error;
    savedDomainContact = contact;
    return domainContact(orgId);
  }

  @override
  Future<DomainCheckoutResult> domainCheckout(
    String orgId,
    String name, {
    String? pageId,
    bool autoRenew = true,
  }) async {
    domainActions.add('checkout:$name:${pageId ?? ''}:$autoRenew');
    final error = domainCheckoutError;
    if (error != null) throw error;
    return DomainCheckoutResult(
      order: _order('order-1', name, domainCheckoutUrl == null ? 'paid' : 'checkout'),
      checkoutUrl: domainCheckoutUrl,
    );
  }

  @override
  Future<DomainOrder> domainOrder(String id) async {
    final n = _orderPolls[id] = (_orderPolls[id] ?? -1) + 1;
    domainActions.add('order:$id');
    final status = domainOrderStatuses[n.clamp(0, domainOrderStatuses.length - 1)];
    return _order(id, 'bakery.com', status);
  }

  @override
  Future<Domain> setDomainAutoRenew(String id, bool autoRenew) async {
    domainActions.add('autoRenew:$id:$autoRenew');
    final d = _domainById(id).copyWith(autoRenew: autoRenew);
    _putDomain(d);
    return d;
  }

  @override
  Future<Domain> lockDomain(String id) async {
    domainActions.add('lock:$id');
    final d = _domainById(id).copyWith(locked: true);
    _putDomain(d);
    return d;
  }

  @override
  Future<DomainCheckoutResult> renewDomain(String id) async {
    domainActions.add('renew:$id');
    final error = renewDomainError;
    if (error != null) throw error;
    return DomainCheckoutResult(
      order: _order('order-renew', _domainById(id).name, domainCheckoutUrl == null ? 'paid' : 'checkout', kind: 'renew'),
      checkoutUrl: domainCheckoutUrl,
    );
  }

  @override
  Future<List<DnsRecordItem>> domainRecords(String id) async => List.of(domainRecordLists[id] ?? const []);

  @override
  Future<DnsRecordItem> addDomainRecord(String id, DnsRecordInput record) async {
    domainActions.add('addRecord:$id:${record.type}:${record.host}:${record.answer}');
    final error = addDomainRecordError;
    if (error != null) throw error;
    final list = domainRecordLists[id] ??= [];
    final item = DnsRecordItem(
      id: 'rec-${list.length + 1}',
      host: record.host,
      type: record.type,
      answer: record.answer,
      ttl: record.ttl ?? 300,
      priority: record.priority,
      managed: false,
    );
    list.add(item);
    return item;
  }

  @override
  Future<DnsRecordItem> updateDomainRecord(String id, String recordId, DnsRecordPatch record) async {
    domainActions.add('updateRecord:$id:$recordId:${record.answer}');
    final list = domainRecordLists[id]!;
    final i = list.indexWhere((r) => r.id == recordId);
    final old = list[i];
    final item = DnsRecordItem(
      id: old.id,
      host: record.host ?? old.host,
      type: record.type ?? old.type,
      answer: record.answer ?? old.answer,
      ttl: record.ttl ?? old.ttl,
      priority: record.priority ?? old.priority,
      managed: old.managed,
    );
    list[i] = item;
    return item;
  }

  @override
  Future<void> deleteDomainRecord(String id, String recordId) async {
    domainActions.add('deleteRecord:$id:$recordId');
    domainRecordLists[id]?.removeWhere((r) => r.id == recordId);
  }

  @override
  Future<void> resendDomainVerification(String id) async => domainActions.add('verifyEmail:$id');

  @override
  Future<String> transferOutDomain(String id, String confirmName) async {
    domainActions.add('transferOut:$id:$confirmName');
    final error = transferOutError;
    if (error != null) throw error;
    _putDomain(_domainById(id).copyWith(locked: false));
    return transferCode;
  }

  final groups = <Conversation>[];
  @override
  Future<List<Conversation>> groupChats(String orgId) async => groups;
  @override
  Future<Conversation> createGroupChat(
    String leadBotId,
    List<String> botIds, {
    String? title,
  }) async {
    final c = Conversation(
      id: 'group-${groups.length + 1}',
      botId: leadBotId,
      title: title,
      lastMessageAt: null,
      createdAt: DateTime(2026),
      kind: ConversationKindEnum.group,
      botIds: [leadBotId, ...botIds],
    );
    groups.add(c);
    return c;
  }

  @override
  Future<List<ChatMessageView>> messages(String conversationId, {int? limit, String? before, String? around}) async {
    if (offline) throw Exception('offline');
    messageRequests.add((limit: limit, before: before, around: around));
    if (limit == null) return storedMessages;
    return pageOfThread(storedMessages, (m) => m.id, limit: limit, before: before, around: around);
  }

  /// What each thread read asked for (paging tests).
  final messageRequests = <({int? limit, String? before, String? around})>[];

  /// Simulates no network for bots and messages (offline cache tests).
  bool offline = false;
  /// The run in progress in a conversation, if any.
  String? activeRunId;
  @override
  Future<String?> activeRun(String conversationId) async => activeRunId;

  /// Runs a group message started, by message id.
  final runsByMessage = <String, String>{};
  @override
  Future<String?> runForMessage(String messageId) async => runsByMessage[messageId];
  final sentAttachments = <List<AttachmentRef>>[];
  /// Thrown by the next send, once (the server unreachable, say).
  Object? failNextSend;
  /// Thrown by the next sends, one each, in order (a server restarting, say).
  final failSends = <Object>[];
  /// The idempotency key of every send call, failed ones included.
  final sendKeys = <String?>[];
  @override
  Future<SendMessageResponse> send(
    String conversationId,
    String text, {
    List<AttachmentRef> attachments = const [],
    Map<String, Object?>? uiAction,
    List<String> skills = const [],
    String? idempotencyKey,
  }) async {
    sendKeys.add(idempotencyKey);
    final fail = failNextSend;
    if (fail != null) {
      failNextSend = null;
      throw fail;
    }
    if (failSends.isNotEmpty) throw failSends.removeAt(0);
    sent.add(text);
    sentSkills.add(skills);
    sentAttachments.add(attachments);
    if (uiAction != null) sentUiActions.add(uiAction);
    return SendMessageResponse(
      // Each message gets its own id, as on the server.
      messageId: sent.length == 1 ? 'm1' : 'm1-${sent.length}',
      runId: runId,
      conversationId: conversationId,
    );
  }

  @override
  Future<void> cancelRun(String runId) async {
    if (runAlreadyFinished) throw const RunAlreadyFinished();
    cancelled = true;
  }

  /// The server answers Stop with "already finished" (the chat missed the run's end).
  var runAlreadyFinished = false;
  /// Each watchRun call: which run, and after which seq (the chat reconnecting picks up there).
  final watchRunCalls = <({String runId, int afterSeq})>[];
  @override
  Stream<RunEventItem> watchRun(String runId, {int afterSeq = 0}) {
    watchRunCalls.add((runId: runId, afterSeq: afterSeq));
    return runEventsController.stream;
  }
  @override
  Future<List<RunEventItem>> runEvents(String runId) async => storedEvents;

  /// The island (D-324): what activeRuns answers, each run's newest events, and the calls made.
  List<ActiveRun> activeRunsValue = [];
  final activeRunsCalls = <List<String>>[];
  Object? activeRunsError;
  /// Holds activeRuns (or runEventsAfter) until completed: a slow or hung request.
  Completer<void>? activeRunsGate;
  Completer<void>? runEventsAfterGate;
  @override
  Future<List<ActiveRun>> activeRuns(String orgId, List<String> botIds) async {
    activeRunsCalls.add(botIds);
    await activeRunsGate?.future;
    if (activeRunsError != null) throw activeRunsError!;
    return [for (final r in activeRunsValue) if (botIds.contains(r.botId)) r];
  }

  final runEventsAfterValue = <String, List<RunEventItem>>{};
  final runEventsAfterCalls = <(String, int)>[];
  @override
  Future<List<RunEventItem>> runEventsAfter(String runId, int afterSeq, {int limit = 40}) async {
    runEventsAfterCalls.add((runId, afterSeq));
    await runEventsAfterGate?.future;
    return runEventsAfterValue[runId] ?? const [];
  }

  /// How each run ended, for the tracker's one read after a run leaves the list.
  final runStatuses = <String, RunStatus>{};
  final liveTokens = <(String, String, String)>[];
  @override
  Future<void> registerLiveToken(String runId, String platform, String token, {String? pushToken}) async => liveTokens.add((runId, platform, token));

  /// Push-to-start tokens by token: (platform, push token).
  final startTokens = <String, (String, String?, bool)>{};

  @override
  Future<void> registerLiveStartToken(String platform, String token, {String? pushToken, bool enabled = true}) async =>
      startTokens[token] = (platform, pushToken, enabled);

  @override
  Future<void> removeLiveStartToken(String token) async => startTokens.remove(token);
  @override
  Future<List<RunSummary>> runs(String botId) async => [
    RunSummary(
      id: runId,
      status: 'completed',
      trigger: 'chat',
      createdAt: DateTime.now(),
      costUsd: 0.001,
    ),
  ];

  @override
  Future<List<Memory>> memories(String botId) async => [
    Memory(
      id: 'mem1',
      kind: MemoryKindEnum.preference,
      content: 'Likes teal',
      importance: 0.8,
      pinned: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    ...extraMemories,
  ];

  /// Memories beyond the first, including ones added by hand: (kind, content).
  final extraMemories = <Memory>[];
  final addedMemories = <(String, String)>[];
  @override
  Future<void> addMemory(String botId, String content, {String kind = 'fact'}) async {
    addedMemories.add((kind, content));
    extraMemories.add(Memory(
      id: 'added-${addedMemories.length}',
      kind: kind == 'preference' ? MemoryKindEnum.preference : MemoryKindEnum.fact,
      content: content,
      importance: 0.6,
      pinned: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
  }
  @override
  Future<void> updateMemory(
    String botId,
    String id, {
    String? content,
    bool? pinned,
  }) async {}
  @override
  Future<void> deleteMemory(String botId, String id) async {}

  // Memory backends (D-137)
  MemoryBackend backend = MemoryBackend(
    provider: MemoryBackendProviderEnum.postgres,
    baseUrl: null,
    workspace: null,
    updatedAt: null,
  );
  SetMemoryBackendRequest? setBackend;
  @override
  Future<MemoryBackend> memoryBackend(String orgId) async => backend;
  @override
  Future<MemoryBackend> setMemoryBackend(
    String orgId,
    SetMemoryBackendRequest request,
  ) async {
    setBackend = request;
    return backend = MemoryBackend(
      provider: request.provider == SetMemoryBackendRequestProviderEnum.honcho
          ? MemoryBackendProviderEnum.honcho
          : MemoryBackendProviderEnum.supermemory,
      baseUrl: request.baseUrl,
      workspace: request.workspace,
      updatedAt: DateTime.utc(2026, 11, 3),
    );
  }

  @override
  Future<MemoryBackend> removeMemoryBackend(String orgId) async =>
      backend = MemoryBackend(
        provider: MemoryBackendProviderEnum.postgres,
        baseUrl: null,
        workspace: null,
        updatedAt: null,
      );
  @override
  Future<List<SkillView>> skills(String orgId) async => skillViews;
  List<SkillView> skillViews = const [];
  @override
  Future<void> saveSkill(
    String orgId, {
    String? id,
    String? botId,
    required String name,
    required String description,
    required String bodyMd,
    bool enabled = true,
  }) async {}
  @override
  Future<void> deleteSkill(String id) async {}

  // --- Phase 4 ---------------------------------------------------------------

  final decisions = <String, String>{};
  List<Approval> pendingApprovals = [
    Approval(
      id: 'appr1',
      botId: botId,
      runId: runId,
      toolName: 'shell.exec',
      argsRedacted: const {'cmd': 'rm -rf /data/old'},
      summary: 'Run a destructive shell command',
      risk: Risk.high,
      status: ApprovalStatusEnum.pending,
      decidedAt: null,
      expiresAt: DateTime.now().add(const Duration(hours: 24)),
      createdAt: DateTime.now(),
    ),
  ];
  final notificationsController =
      StreamController<NotificationView>.broadcast();
  List<NotificationView> storedNotifications = [
    NotificationView(
      id: 'n1',
      kind: 'approval',
      title: 'Ada needs approval',
      body: 'Run a destructive shell command',
      link: '/approvals/appr1',
      createdAt: DateTime.now(),
    ),
  ];
  var notificationsRead = false;
  final devices = <String>[];
  final routineList = <Routine>[];
  final routinesRun = <String>[];
  final integrationList = <Integration>[];
  final attached = <String>{};
  final secretList = <Secret>[];

  @override
  Future<List<Approval>> approvals(
    String orgId, {
    bool pendingOnly = true,
  }) async =>
      pendingApprovals.where((a) => !decisions.containsKey(a.id)).toList();
  @override
  Future<Approval> decideApproval(
    String approvalId, {
    required bool approve,
    bool alwaysAllow = false,
  }) async {
    decisions[approvalId] = approve
        ? (alwaysAllow ? 'always' : 'approved')
        : 'denied';
    return pendingApprovals.firstWhere((a) => a.id == approvalId);
  }

  @override
  Future<List<NotificationView>> notifications() async => storedNotifications;
  @override
  Future<void> markNotificationsRead() async => notificationsRead = true;
  final readNotifications = <String>[];
  @override
  Future<void> markNotificationRead(String id) async =>
      readNotifications.add(id);
  @override
  Stream<NotificationView> watchNotifications() =>
      notificationsController.stream;

  /// What happened in a conversation from elsewhere: a run started (D-224), reactions changed (D-331).
  final activity = StreamController<ConversationActivity>.broadcast();

  /// A run started in a conversation from elsewhere (D-224): its id.
  late final conversationActivity = _RunActivity(activity);
  final watchedConversations = <String>[];
  @override
  Stream<ConversationActivity> watchConversation(String conversationId) {
    watchedConversations.add(conversationId);
    return activity.stream;
  }

  /// Another device changed the workspace's bots (D-225).
  final botsChangedController = StreamController<void>.broadcast();
  var botsChangedListeners = 0;
  @override
  Stream<void> watchBotsChanged(String orgId) {
    botsChangedListeners++;
    return botsChangedController.stream;
  }
  @override
  Future<void> registerDevice(String platform, String token) async =>
      devices.add('$platform:$token');

  /// The latest chat focus each install reported (D-325), by client id.
  final chatFocus = <String, String?>{};
  @override
  Future<void> setChatFocus(String clientId, String? conversationId) async =>
      chatFocus[clientId] = conversationId;

  @override
  Future<List<Routine>> routines(String botId) async => routineList;
  MessageTriggerConfig? createdMessageTrigger;
  @override
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
  }) async {
    createdCalendar = calendar;
    createdMessageTrigger = message;
    final r = CreatedRoutine(
      id: 'r${routineList.length + 1}',
      botId: botId,
      name: name,
      instructionsMd: instructions,
      scheduleCron: trigger == 'schedule' ? cron : null,
      timezone: timezone ?? 'America/Chicago',
      trigger: RoutineTrigger.values.firstWhere((t) => t.value == trigger),
      notify: true,
      enabled: true,
      nextRunAt: trigger == 'schedule'
          ? DateTime(2026, 11, 11, 7)
          : (trigger == 'once' ? runAt : null),
      lastRunAt: null,
      endsAt: trigger == 'once' ? null : endsAt,
      maxRuns: trigger == 'once' ? null : maxRuns,
      runCount: 0,
      conversationId: null,
      createdAt: DateTime.now(),
      webhookUrl:
          const [
            'schedule',
            'once',
            'calendar_event',
            'message',
          ].contains(trigger)
          ? null
          : 'http://localhost/hooks/custom/r1',
      webhookSecret:
          const [
            'schedule',
            'once',
            'calendar_event',
            'message',
          ].contains(trigger)
          ? null
          : 'whsec_test',
    );
    routineList.add(Routine.fromJson(r.toJson()));
    return r;
  }

  @override
  Future<void> setRoutineEnabled(String routineId, bool enabled) async {}
  final routineEnds = <String, (DateTime?, int?)>{};
  @override
  Future<void> setRoutineEnd(String routineId, {DateTime? endsAt, int? maxRuns}) async {
    routineEnds[routineId] = (endsAt, maxRuns);
    final i = routineList.indexWhere((r) => r.id == routineId);
    if (i >= 0) {
      routineList[i] = Routine.fromJson({...routineList[i].toJson(), 'ends_at': endsAt?.toUtc().toIso8601String(), 'max_runs': maxRuns, 'run_count': 0});
    }
  }
  final deletedRoutines = <String>[];
  @override
  Future<void> deleteRoutine(String routineId) async {
    deletedRoutines.add(routineId);
    routineList.removeWhere((r) => r.id == routineId);
  }

  final uploads = <String, Uint8List>{};
  /// Routine changes saved from the edit sheet: (id, fields).
  final routineUpdates = <(String, Map<String, Object?>)>[];
  @override
  Future<void> updateRoutine(String routineId, {String? name, String? instructions, String? scheduleCron, String? timezone, DateTime? runAt}) async {
    routineUpdates.add((routineId, {'name': name, 'instructions': instructions, 'schedule_cron': scheduleCron, 'timezone': timezone, 'run_at': runAt}));
    final i = routineList.indexWhere((r) => r.id == routineId);
    if (i >= 0) {
      routineList[i] = Routine.fromJson({
        ...routineList[i].toJson(),
        'name': ?name,
        'instructions_md': ?instructions,
        'schedule_cron': ?scheduleCron,
        'timezone': ?timezone,
        if (runAt != null) 'next_run_at': runAt.toUtc().toIso8601String(),
      });
    }
  }

  /// What [routineRuns] returns.
  List<RunSummary> routineRunList = [];
  @override
  Future<List<RunSummary>> routineRuns(String routineId) async => routineRunList;

  @override
  Future<String> runRoutine(String routineId) async {
    routinesRun.add(routineId);
    return runId;
  }

  @override
  Future<List<Integration>> integrations(String orgId) async => integrationList;
  CalendarTriggerConfig? createdCalendar;
  @override
  Future<Integration> createIntegration(
    String orgId, {
    required String kind,
    required String name,
    required Map<String, Object?> config,
    String? secret,
  }) async {
    final i = Integration(
      id: 'i${integrationList.length + 1}',
      orgId: orgId,
      kind: IntegrationKind.values.firstWhere((k) => k.value == kind),
      name: name,
      status: IntegrationStatusEnum.pending,
      error: null,
      tools: const [],
      toolsCachedAt: null,
      createdAt: DateTime.now(),
    );
    integrationList.add(i);
    return i;
  }

  @override
  Future<IntegrationTestResult> testIntegration(String integrationId) async {
    tested.add(integrationId);
    return IntegrationTestResult(ok: true, tools: const ['add', 'subtract']);
  }

  final tested = <String>[];
  @override
  Future<Set<String>> botIntegrationIds(String botId) async => attached;
  @override
  Future<void> setBotIntegration(
    String botId,
    String integrationId,
    bool enabled,
  ) async =>
      enabled ? attached.add(integrationId) : attached.remove(integrationId);

  // Built-in apps
  static CatalogApp catalogApp(
    String id,
    String name,
    List<CatalogAppAuthEnum> auth, {
    bool popular = true,
    String color = '635BFF',
    bool? oauthAvailable,
  }) => CatalogApp(
    id: id,
    name: name,
    description: '$name for your bots.',
    category: CatalogAppCategoryEnum.payments,
    color: color,
    homepage: 'https://$id.com',
    url: 'https://mcp.$id.com',
    auth: auth,
    apiKey: auth.contains(CatalogAppAuthEnum.apiKey)
        ? CatalogAppApiKey(
            label: 'Secret key',
            url: 'https://dashboard.$id.com/keys',
            steps: const ['Open the dashboard.', 'Copy the key.'],
          )
        : null,
    capabilities: const ['Look up customers', 'Create invoices'],
    popular: popular,
    oauthAvailable: oauthAvailable ?? auth.contains(CatalogAppAuthEnum.oauth),
  );
  final catalog = [
    catalogApp('stripe', 'Stripe', [
      CatalogAppAuthEnum.oauth,
      CatalogAppAuthEnum.apiKey,
    ]),
    catalogApp('notion', 'Notion', [CatalogAppAuthEnum.oauth], color: '000000'),
    catalogApp(
      'cloudflare',
      'Cloudflare Docs',
      [CatalogAppAuthEnum.none],
      popular: false,
      color: 'F38020',
    ),
  ];
  final connectCalls = <(String app, String method, String? key)>[];
  final deleted = <String>[];
  var pendingPolls = 1;
  Integration _connected(String appId, String auth) {
    final i = Integration(
      id: 'app-$appId',
      orgId: orgId,
      kind: IntegrationKind.mcp,
      name: appId,
      status: IntegrationStatusEnum.ok,
      error: null,
      tools: [
        IntegrationToolsInner(
          name: 'list_customers',
          description: 'List customers',
          risk: Risk.low,
        ),
        IntegrationToolsInner(
          name: 'create_refund',
          description: 'Refund a payment',
          risk: Risk.high,
        ),
      ],
      toolsCachedAt: DateTime(2026),
      createdAt: DateTime(2026),
      appId: appId,
      auth: IntegrationAuthEnum.values.firstWhere((a) => a.value == auth),
      botIds: const [],
      riskOverrides: const {},
    );
    integrationList.removeWhere((x) => x.id == i.id);
    integrationList.add(i);
    return i;
  }

  @override
  Future<AppCatalog> appCatalog() async =>
      AppCatalog(apps: catalog, redirectUri: catalogRedirectUri);
  String catalogRedirectUri = 'http://localhost/oauth/callback';
  @override
  Future<ConnectAppResponse> connectApp(
    String orgId, {
    required String appId,
    required String method,
    String? apiKey,
    String? integrationId,
    bool returnToApp = false,
  }) async {
    connectCalls.add((appId, method, apiKey));
    if (method == 'managed') {
      // Like the server: the workspace's one Composio connection, and a sign-in page to open. The
      // person hasn't approved anything yet, so Composio lists the account as waiting.
      final hub = integrationList.where((i) => i.kind == IntegrationKind.composio).firstOrNull ??
          await createIntegration(orgId, kind: 'composio', name: 'apps', config: {'managed': true});
      providerAccountList.add(ProviderAccount(app: appId, status: ProviderAccountStatusEnum.pending));
      return ConnectAppResponse(
        status: ConnectAppResponseStatusEnum.authorize,
        authorizeUrl: 'https://composio.example/signin/$appId',
        integration: hub,
      );
    }
    if (method == 'oauth') {
      return ConnectAppResponse(
        status: ConnectAppResponseStatusEnum.authorize,
        authorizeUrl: 'https://auth.$appId.com/authorize',
        flowId: 'flow-$appId',
      );
    }
    return ConnectAppResponse(
      status: ConnectAppResponseStatusEnum.connected,
      integration: _connected(appId, method),
    );
  }

  @override
  Future<ConnectFlowStatus> connectStatus(String flowId) async {
    if (pendingPolls-- > 0) {
      return ConnectFlowStatus(status: ConnectFlowStatusStatusEnum.pending);
    }
    return ConnectFlowStatus(
      status: ConnectFlowStatusStatusEnum.connected,
      integration: _connected(flowId.replaceFirst('flow-', ''), 'oauth'),
    );
  }

  @override
  Future<void> deleteIntegration(String integrationId) async {
    deleted.add(integrationId);
    integrationList.removeWhere((i) => i.id == integrationId);
  }

  final toolRisks = <String, Map<String, String>>{};
  @override
  Future<Integration> setToolRisks(
    String integrationId,
    Map<String, String> risks,
  ) async {
    toolRisks[integrationId] = risks;
    return integrationList.firstWhere((i) => i.id == integrationId);
  }

  @override
  Future<List<ProviderApp>> providerApps(
    String integrationId, {
    String? query,
  }) async => [
    ProviderApp(slug: 'gmail', name: 'Gmail', description: 'Email', logo: null),
  ];
  final providerConnects = <String>[];
  @override
  Future<String> connectProviderApp(String integrationId, String app, {bool returnToApp = false}) async {
    providerConnects.add(app);
    return 'https://connect.example.com/$app';
  }

  @override
  Future<List<ProviderAccount>> providerAccounts(String integrationId) async =>
      [
        for (final a in providerConnects)
          ProviderAccount(app: a, status: ProviderAccountStatusEnum.connected),
        ...providerAccountList,
      ];

  /// More accounts the hub lists, with their own status (a managed sign-in adds a waiting one).
  final providerAccountList = <ProviderAccount>[];

  @override
  Future<List<Secret>> secrets(String orgId) async => secretList;
  @override
  Future<void> createSecret(
    String orgId, {
    required String name,
    required String value,
    required List<String> hosts,
    bool totp = false,
  }) async => secretList.add(
    Secret(
      id: 's${secretList.length + 1}',
      orgId: orgId,
      name: name,
      allowedHosts: hosts,
      allowedBotIds: null,
      kind: totp ? SecretKind.totp : SecretKind.plain,
      createdAt: DateTime.now(),
    ),
  );
  @override
  Future<void> deleteSecret(String secretId) async =>
      secretList.removeWhere((s) => s.id == secretId);

  final taskList = <Task>[
    Task(
      id: 't1',
      title: 'Summarize the release notes',
      detailsMd: '',
      status: TaskStatus.todo,
      priority: TaskPriority.high,
      assigneeBotId: botId,
      assigneeUserId: null,
      createdByBotId: botId,
      createdByUserId: null,
      resultMd: null,
      dueAt: null,
      labels: const [],
      position: 1,
      reviewRequired: false,
      conversationId: null,
      projectId: null,
      milestoneId: null,
      parentTaskId: null,
      comments: 1,
      updatedAt: DateTime(2026),
      createdAt: DateTime(2026),
    ),
  ];
  final taskCommentList = <String, List<TaskComment>>{
    't1': [
      TaskComment(
        id: 'c1',
        taskId: 't1',
        authorType: TaskCommentAuthorTypeEnum.bot,
        authorUserId: null,
        authorBotId: botId,
        bodyMd: 'Started reading.',
        createdAt: DateTime(2026),
      ),
    ],
  };
  @override
  Future<List<Task>> tasks(String orgId, {String? projectId}) async =>
      List.of(taskList);
  @override
  Future<Task> createTask(
    String orgId, {
    required String title,
    String? details,
    String? priority,
    String? assigneeBotId,
    bool? reviewRequired,
  }) async {
    final t = taskList.first.rebuild(
      id: 't${taskList.length + 1}',
      title: title,
      detailsMd: details ?? '',
      assigneeBotId: assigneeBotId,
      priority: TaskPriority.values.firstWhere(
        (p) => p.value == (priority ?? 'none'),
      ),
      reviewRequired: reviewRequired ?? false,
      comments: 0,
    );
    taskList.add(t);
    return t;
  }

  @override
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
  }) async {
    final i = taskList.indexWhere((t) => t.id == taskId);
    final t = taskList[i];
    taskList[i] = t.rebuild(
      title: title ?? t.title,
      detailsMd: details ?? t.detailsMd,
      status: status == null
          ? t.status
          : TaskStatus.values.firstWhere((s) => s.value == status),
      priority: priority == null
          ? t.priority
          : TaskPriority.values.firstWhere((p) => p.value == priority),
      assigneeBotId: assigneeBotId ?? t.assigneeBotId,
      assigneeUserId: assigneeUserId ?? t.assigneeUserId,
      reviewRequired: reviewRequired ?? t.reviewRequired,
      position: position ?? t.position.toDouble(),
    );
    return taskList[i];
  }

  @override
  Future<void> deleteTask(String taskId) async =>
      taskList.removeWhere((t) => t.id == taskId);
  @override
  Future<List<TaskComment>> taskComments(String taskId) async =>
      List.of(taskCommentList[taskId] ?? const []);
  @override
  Future<TaskComment> addTaskComment(String taskId, String body) async {
    final c = TaskComment(
      id: 'c${DateTime.now().microsecondsSinceEpoch}',
      taskId: taskId,
      authorType: TaskCommentAuthorTypeEnum.user,
      authorUserId: 'me',
      authorBotId: null,
      bodyMd: body,
      createdAt: DateTime(2026),
    );
    (taskCommentList[taskId] ??= []).add(c);
    return c;
  }

  // --- Phase 6: admin -------------------------------------------------------

  var isOwner = true;
  Map<String, num>? setLimits;

  /// What [adminMargin] reports (D-395); the days asked for are kept.
  AdminMargin? margin;
  final marginDays = <int>[];

  @override
  Future<AdminMargin> adminMargin({int days = 30}) async {
    marginDays.add(days);
    return margin ??
        AdminMargin(
          days: days,
          chargedUsd: 2.0,
          chargedTrackedUsd: 1.4,
          upstreamUsd: 1.0,
          byDay: [AdminMarginByDayInner(date: '2026-11-18', chargedUsd: 2.0, chargedTrackedUsd: 1.4, upstreamUsd: 1.0)],
          byKind: [
            AdminMarginByKindInner(kind: 'tokens_in', chargedUsd: 1.4, chargedTrackedUsd: 1.4, upstreamUsd: 1.0),
            AdminMarginByKindInner(kind: 'computer_seconds', chargedUsd: 0.6, chargedTrackedUsd: 0, upstreamUsd: 0),
          ],
          topOrgs: [AdminMarginTopOrgsInner(orgId: 'o1', name: 'Acme', planCode: 'pro', chargedUsd: 2.0, chargedTrackedUsd: 1.4, upstreamUsd: 1.0)],
        );
  }

  @override
  Future<AdminOverview?> adminOverview() async => isOwner
      ? AdminOverview(
          version: '0.6.0',
          users: 3,
          orgs: 2,
          bots: 4,
          runs24h: 12,
          failedRuns24h: 1,
          cost24hUsd: 0.42,
          computersRunning: 1,
          devicesOnline: 1,
        )
      : null;
  @override
  Future<List<AdminUser>> adminUsers() async => [
    AdminUser(
      id: 'u1',
      email: 'owner@example.com',
      createdAt: DateTime(2026),
      lastSignInAt: null,
      orgs: 1,
    ),
  ];
  AdminOrg _org(Map<String, num> limits) => AdminOrg(
    id: orgId,
    name: 'Test Org',
    planCode: 'selfhost',
    limits: limits,
    members: 2,
    bots: 1,
    cost30dUsd: 1.5,
    suspendedAt: suspendedReason == null ? null : '2026-11-10T00:00:00Z',
    suspendedReason: suspendedReason,
  );
  String? suspendedReason;
  @override
  Future<AdminOrg> suspendOrg(String orgId, String reason) async {
    suspendedReason = reason;
    return _org(setLimits ?? const {});
  }

  @override
  Future<AdminOrg> unsuspendOrg(String orgId) async {
    suspendedReason = null;
    return _org(setLimits ?? const {});
  }

  @override
  Future<List<AbuseEvent>> adminAbuseEvents() async => [
    AbuseEvent(
      id: '99999999-9999-4999-8999-999999999999',
      orgId: orgId,
      orgName: 'Test Org',
      computerId: null,
      kind: 'mining_pool',
      action: 'workspace_suspended',
      detail: const {'target': 'xmr.nanopool.org:443'},
      createdAt: '2026-11-10T00:00:00Z',
    ),
  ];
  int adminOrgsCalls = 0;
  @override
  Future<List<AdminOrg>> adminOrgs() async {
    adminOrgsCalls++;
    return [_org(setLimits ?? const {})];
  }

  @override
  Future<AdminOrg> setOrgLimits(String orgId, Map<String, num> limits) async {
    setLimits = limits;
    return _org(limits);
  }

  @override
  Future<List<AdminService>> adminServices() async => [
    AdminService(
      name: 'Database',
      configured: true,
      healthy: true,
      detail: 'Postgres (Supabase)',
    ),
  ];
  @override
  Future<UpdateNotice> adminUpdates() async => UpdateNotice(
    current: '0.6.0',
    latest: '0.9.1',
    updateAvailable: true,
    url: 'https://example.com/r',
  );
  var connectionSettings = ConnectionSettings(
    composio: ConnectionSettingsComposioEnum.server,
    google: ConnectionSettingsGoogleEnum.composio,
    composioKey: true,
    googleDirectAvailable: true,
  );
  @override
  Future<ConnectionSettings> adminConnectionSettings() async =>
      connectionSettings;
  CloudModels cloudModels = CloudModels(
    chat: 'deepseek/deepseek-v4.1-flash-1017',
    background: 'deepseek/deepseek-v4.1-flash-1017',
    image: 'google/gemini-nano-banana-2.1',
    imageResolution: CloudModelsImageResolutionEnum.n1k,
    live: 'gemini-3.8-live',
    tts: 'gemini-3.8-flash-lite-tts',
    stt: 'gpt-4o-mini-transcribe',
    embedding: 'text-embedding-3-small',
    video: 'gemini-omni-1.2-flash',
  );
  @override
  Future<CloudModels> adminCloudModels() async => cloudModels;

  /// What the Admin screen's capacity card shows (D-252).
  ServerCapacity capacity = ServerCapacity(budgetMb: 9216, latest: null, days: const [], refusals30d: 0, fullInWeeks: null, alerts: const []);
  @override
  Future<ServerCapacity> adminCapacity() async => capacity;
  @override
  Future<CloudModels> setAdminCloudModels(CloudModels models) async =>
      cloudModels = models;
  var pricing = AdminPricing(
    billingEnabled: true,
    plans: [
      AdminPlan(
        code: 'free',
        name: 'Free',
        interval: AdminPlanIntervalEnum.none,
        active: true,
        sort: 0,
        priceLabel: null,
        limits: const {'max_bots': 2, 'seats': 1, 'monthly_credits_usd': 1},
        creditGate: true,
        storeProductIds: const {},
        dodoProductId: null,
        paywallDefault: false,
        paywallPopular: false,
        workspaces: 12,
      ),
      AdminPlan(
        code: 'pro',
        name: 'Pro',
        interval: AdminPlanIntervalEnum.month,
        active: true,
        sort: 20,
        priceLabel: r'$39/mo',
        limits: const {'max_bots': 20, 'seats': 5, 'monthly_credits_usd': 20, 'cloud_daily_usd': 5},
        creditGate: false,
        storeProductIds: const {'app_store': 'ai.casama.pro.monthly', 'google_play': 'casama_pro:monthly'},
        dodoProductId: 'pdt_pro',
        paywallDefault: false,
        paywallPopular: true,
        workspaces: 3,
      ),
    ],
    packs: [
      AdminCreditPack(
        code: 'credits_10',
        name: r'$10 of credits',
        creditsUsd: 10,
        active: true,
        priceLabel: r'$10',
        storeProductIds: const {'app_store': 'ai.casama.credits.10', 'google_play': 'casama_credits_10'},
        dodoProductId: 'pdt_c10',
      ),
    ],
    settings: BillingSettings(markup: 1.3),
  );
  final savedPlans = <String, SavePlanRequest>{};
  final savedPacks = <String, SaveCreditPackRequest>{};
  final savedMarkups = <num>[];
  @override
  Future<AdminPricing> adminPricing() async => pricing;
  @override
  Future<AdminPlan> saveAdminPlan(String code, SavePlanRequest plan) async {
    savedPlans[code] = plan;
    final old = pricing.plans.firstWhere((p) => p.code == code);
    final next = old.copyWith(
      name: plan.name ?? old.name,
      active: plan.active ?? old.active,
      sort: plan.sort ?? old.sort,
      priceLabel: plan.priceLabel ?? old.priceLabel,
      limits: plan.limits ?? old.limits,
      creditGate: plan.creditGate ?? old.creditGate,
      storeProductIds: plan.storeProductIds ?? old.storeProductIds,
      dodoProductId: plan.dodoProductId ?? old.dodoProductId,
      paywallDefault: plan.paywallDefault ?? old.paywallDefault,
      paywallPopular: plan.paywallPopular ?? old.paywallPopular,
    );
    // One plan opens the paywall, as on the server.
    pricing = pricing.copyWith(plans: [
      for (final p in pricing.plans)
        p.code == code ? next : plan.paywallDefault == true ? p.copyWith(paywallDefault: false) : p,
    ]);
    return next;
  }

  @override
  Future<AdminCreditPack> saveAdminCreditPack(String code, SaveCreditPackRequest pack) async {
    savedPacks[code] = pack;
    final old = pricing.packs.firstWhere((p) => p.code == code);
    final next = old.copyWith(
      name: pack.name ?? old.name,
      creditsUsd: pack.creditsUsd ?? old.creditsUsd,
      active: pack.active ?? old.active,
      priceLabel: pack.priceLabel ?? old.priceLabel,
      storeProductIds: pack.storeProductIds ?? old.storeProductIds,
      dodoProductId: pack.dodoProductId ?? old.dodoProductId,
    );
    pricing = pricing.copyWith(packs: [for (final p in pricing.packs) p.code == code ? next : p]);
    return next;
  }

  @override
  Future<BillingSettings> setAdminBillingSettings(BillingSettings settings) async {
    savedMarkups.add(settings.markup);
    pricing = pricing.copyWith(settings: settings);
    return settings;
  }
  @override
  Future<ConnectionSettings> setAdminConnectionSettings({
    bool? serverComposio,
    bool? googleDirect,
  }) async => connectionSettings = ConnectionSettings(
    composio: serverComposio == null
        ? connectionSettings.composio
        : serverComposio
        ? ConnectionSettingsComposioEnum.server
        : ConnectionSettingsComposioEnum.own,
    google: googleDirect == null
        ? connectionSettings.google
        : googleDirect
        ? ConnectionSettingsGoogleEnum.direct
        : ConnectionSettingsGoogleEnum.composio,
    composioKey: connectionSettings.composioKey,
    googleDirectAvailable: connectionSettings.googleDirectAvailable,
  );

  // --- Phase 8: privacy and SSO --------------------------------------------

  var exported = 0;
  String? deletedWith;
  var retention = 180;
  String? ssoEmail;
  final sentUiActions = <Map<String, Object?>>[];

  /// What the app last told the server about the person's analytics choice, newest last.
  final analyticsOptOutCalls = <bool>[];
  bool workspaceAnalyticsOff = false;

  @override
  Future<void> setAnalyticsOptOut(bool optOut) async => analyticsOptOutCalls.add(optOut);

  final relayedAnalytics = <({String platform, List<({String name, Map<String, Object> properties})> events})>[];
  @override
  Future<void> relayAnalytics(String platform, List<({String name, Map<String, Object> properties})> events) async =>
      relayedAnalytics.add((platform: platform, events: events));

  @override
  Future<bool> orgAnalyticsOptOut(String orgId) async => workspaceAnalyticsOff;

  @override
  Future<void> setOrgAnalyticsOptOut(String orgId, bool optOut) async => workspaceAnalyticsOff = optOut;

  @override
  Future<Uint8List> exportMyData() async {
    exported++;
    return Uint8List.fromList(List.filled(2048, 7));
  }

  @override
  Future<AccountDeletion> deleteAccount(String confirmEmail) async {
    deletedWith = confirmEmail;
    return AccountDeletion(
      purgeAfter: DateTime.utc(2026, 11, 17),
      workspacesDeleted: const ['Test Org'],
    );
  }

  @override
  Future<int> retentionDays(String orgId) async => retention;

  // Two-step sign-in
  final twoStep = <TwoStepFactor>[];
  @override
  bool twoStepCodeNeeded = false;
  @override
  bool twoStepVerified = false;
  bool requireTwoStepValue = false;
  @override
  Future<List<TwoStepFactor>> twoStepFactors() async => List.of(twoStep);
  @override
  Future<TwoStepEnrollment> startTwoStep() async => const TwoStepEnrollment(
    factorId: 'f-new',
    secret: 'JBSWY3DPEHPK3PXP',
    uri: 'otpauth://totp/Casama:tester@example.com?secret=JBSWY3DPEHPK3PXP&issuer=Casama',
    qrSvg: '<svg xmlns="http://www.w3.org/2000/svg" width="10" height="10"><rect width="10" height="10"/></svg>',
  );
  @override
  Future<void> verifyTwoStep(String factorId, String code) async {
    if (code != '123456') throw Exception('Invalid code');
    twoStep.add(
      TwoStepFactor(
        id: factorId,
        name: 'Authenticator 1',
        createdAt: DateTime(2026),
      ),
    );
    twoStepVerified = true;
  }

  @override
  Future<void> passTwoStep(String code) async {
    if (code != '123456') throw Exception('Invalid code');
    twoStepCodeNeeded = false;
    twoStepVerified = true;
  }

  @override
  Future<void> removeTwoStep(String factorId) async =>
      twoStep.removeWhere((f) => f.id == factorId);
  @override
  Future<void> renameTwoStep(String factorId, String name) async {
    final i = twoStep.indexWhere((f) => f.id == factorId);
    if (i >= 0) {
      twoStep[i] = TwoStepFactor(
        id: factorId,
        name: '$name · 1',
        createdAt: twoStep[i].createdAt,
      );
    }
  }

  @override
  Future<bool> requireTwoStep(String orgId) async => requireTwoStepValue;
  @override
  Future<bool> setRequireTwoStep(String orgId, bool value) async =>
      requireTwoStepValue = value;
  bool requireAppLockValue = false;
  @override
  Future<bool> requireAppLock(String orgId) async => requireAppLockValue;
  @override
  Future<bool> setRequireAppLock(String orgId, bool value) async => requireAppLockValue = value;
  @override
  Future<int> setRetentionDays(String orgId, int days) async =>
      retention = days;
  @override
  Future<void> signInWithSso(String email) async => ssoEmail = email;

  // --- passkeys ---------------------------------------------------------------

  var authMethodsValue = const AuthMethods();
  @override
  Future<AuthMethods> authMethods() async => authMethodsValue;
  var passkeySignIns = 0;

  /// False: the person closes the system sheet.
  var passkeySheetFinishes = true;
  @override
  Future<bool> signInWithPasskey() async {
    if (!passkeySheetFinishes) return false;
    passkeySignIns++;
    signedIn = true;
    _auth.add(true);
    return true;
  }

  /// What the passkey check for the app lock answers (D-375); [PasskeyProblem] when it's an error.
  Object? passkeyConfirm = true;
  var passkeyConfirms = 0;
  @override
  Future<bool?> confirmWithPasskey() async {
    passkeyConfirms++;
    final answer = passkeyConfirm;
    if (answer is Exception) throw answer;
    return answer as bool?;
  }

  final passkeyList = <PasskeyInfo>[];
  @override
  Future<List<PasskeyInfo>> passkeys() async => List.of(passkeyList);
  @override
  Future<bool> addPasskey() async {
    if (!passkeySheetFinishes) return false;
    passkeyList.add(
      PasskeyInfo(
        id: 'pk${passkeyList.length + 1}',
        name: 'iCloud Keychain',
        createdAt: DateTime(2026),
      ),
    );
    return true;
  }

  @override
  Future<void> renamePasskey(String id, String name) async {
    final i = passkeyList.indexWhere((p) => p.id == id);
    if (i >= 0) {
      passkeyList[i] = PasskeyInfo(
        id: id,
        name: name,
        createdAt: passkeyList[i].createdAt,
      );
    }
  }

  @override
  Future<void> removePasskey(String id) async =>
      passkeyList.removeWhere((p) => p.id == id);

  // --- password and email -------------------------------------------------------

  String? passwordResetEmail;
  @override
  Future<void> sendPasswordReset(String email) async =>
      passwordResetEmail = email;
  @override
  Future<void> verifyPasswordResetCode(String email, String code) async {
    if (code != '123456') throw Exception('That code is wrong or has expired.');
    signedIn = true;
    _auth.add(true);
    _setNewPasswordNeeded(true);
  }

  var _newPasswordNeeded = false;
  final _newPasswordChanges = StreamController<bool>.broadcast();
  void _setNewPasswordNeeded(bool v) {
    _newPasswordNeeded = v;
    _newPasswordChanges.add(v);
  }

  @override
  bool get newPasswordNeeded => _newPasswordNeeded;
  set newPasswordNeeded(bool v) => _setNewPasswordNeeded(v);
  @override
  Stream<bool> get newPasswordNeededChanges => _newPasswordChanges.stream;
  @override
  void skipNewPassword() => _setNewPasswordNeeded(false);

  String? password;

  /// The session is old: changing the password needs this code first.
  String? reauthCode;
  var reauthCodesSent = 0;
  @override
  Future<void> setPassword(String password, {String? code}) async {
    if (reauthCode != null && code != reauthCode) {
      throw const ReauthenticationNeeded();
    }
    this.password = password;
    _setNewPasswordNeeded(false);
  }

  @override
  Future<void> sendReauthenticationCode() async => reauthCodesSent++;

  @override
  String? pendingEmail;
  @override
  Future<void> changeEmail(String email) async => pendingEmail = email;

  var signedOutEverywhere = false;
  @override
  Future<void> signOutEverywhere() async {
    signedOutEverywhere = true;
    // Like the real one (D-410): every watch the person has, where the server can; else the ones
    // this phone signed in.
    if (_watchesInPlay) {
      var all = false;
      try {
        all = await deleteAllWatchKeys() != null;
      } catch (_) {}
      await WatchKeyStore.signingOut(userId, (id) async {
        if (!all) await deleteWatchKey(id);
      });
    }
    signedIn = false;
    _auth.add(false);
  }

  // --- Phase 7: billing -----------------------------------------------------

  var billingEnabled = false;
  var planCode = 'free';
  var billingSource = BillingSummarySource_Enum.default_;

  /// Whether the owner can still start a plan's free trial (D-249).
  var trialAvailable = false;
  final checkouts = <String>[];
  final verified = <String>[];
  final linkKeyNames = <String>[];

  /// Replaces the plans and credit packs [plans] returns (null keeps the default free + pro).
  List<Plan>? catalogPlans;
  List<CreditPack>? catalogPacks;
  num packCredits = 0;

  /// Holds [billing] until completed, like a slow network.
  Completer<void>? billingGate;

  @override
  Future<BillingSummary> billing(String orgId) async {
    await billingGate?.future;
    final plan = catalogPlans?.where((p) => p.code == planCode).firstOrNull;
    if (plan != null) {
      return (await _billing(orgId)).copyWith(
        planName: plan.name,
        interval: plan.interval.value,
        limits: plan.limits,
      );
    }
    return _billing(orgId);
  }

  Future<BillingSummary> _billing(String orgId) async => BillingSummary(
    enabled: billingEnabled,
    planCode: billingEnabled ? planCode : 'selfhost',
    planName: billingEnabled
        ? (planCode == 'pro' ? 'Pro' : 'Free')
        : 'Self-hosted',
    interval: planCode == 'pro' ? 'month' : 'none',
    limits: planCode == 'pro'
        ? const {
            'max_bots': 20,
            'computer_hours': 100,
            'monthly_credits_usd': 20,
          }
        : const {'max_bots': 2},
    unlimited: !billingEnabled,
    validUntil: planCode == 'pro' ? DateTime.utc(2026, 12, 10) : null,
    source_: billingSource,
    cancelAtPeriodEnd: false,
    trialAvailable: trialAvailable,
    creditsUsd: billingEnabled ? 1.0 + packCredits : 0,
    subscriptions: const [],
    providers: const [
      BillingSource.dodo,
      BillingSource.appStore,
      BillingSource.googlePlay,
    ],
  );
  @override
  Future<PlanCatalog> plans() async => PlanCatalog(
    enabled: billingEnabled,
    plans: catalogPlans ?? [
      Plan(
        code: 'free',
        name: 'Free',
        interval: PlanIntervalEnum.none,
        limits: const {'max_bots': 2},
        priceLabel: null,
        web: false,
        storeProductIds: const {},
      ),
      Plan(
        code: 'pro',
        name: 'Pro',
        interval: PlanIntervalEnum.month,
        limits: const {
          'max_bots': 20,
          'computer_hours': 100,
          'monthly_credits_usd': 20,
        },
        priceLabel: null,
        web: true,
        storeProductIds: const {
          'app_store': 'dev.casama.pro.monthly',
          'google_play': 'casama_pro:monthly',
        },
      ),
    ],
    packs: catalogPacks ?? [
      CreditPack(
        code: 'credits_10',
        name: r'$10 of credits',
        creditsUsd: 10,
        web: true,
      ),
    ],
  );
  @override
  Future<String?> checkoutUrl(
    String orgId, {
    String? planCode,
    String? packCode,
  }) async {
    checkouts.add(planCode ?? packCode!);
    // A web subscriber changing plans is moved in place (D-248).
    if (planCode != null && billingSource == BillingSummarySource_Enum.dodo && this.planCode != 'free') {
      this.planCode = planCode;
      return null;
    }
    return 'https://checkout.example.com/${planCode ?? packCode}';
  }

  /// Extra people set through Billing (D-249).
  var extraSeats = 0;
  @override
  Future<BillingSummary> setExtraSeats(String orgId, int extra) async {
    extraSeats = extra;
    return (await billing(orgId)).copyWith(extraSeats: extra);
  }

  @override
  Future<String> billingPortalUrl(String orgId) async =>
      'https://portal.example.com/cus_1';
  @override
  Future<BillingSummary> verifyPurchase(
    String orgId, {
    required String source,
    required String productId,
    String? transactionId,
    String? purchaseToken,
  }) async {
    verified.add('$source:$productId:${transactionId ?? purchaseToken}');
    // A credit pack adds credits and leaves the plan alone (D-244).
    final pack = catalogPacks?.where((p) => p.storeProductIds?[source] == productId).firstOrNull;
    if (pack != null) {
      packCredits += pack.creditsUsd;
      return billing(orgId);
    }
    planCode = catalogPlans?.where((p) => p.storeProductIds[source] == productId).firstOrNull?.code ?? 'pro';
    billingSource = source == 'app_store'
        ? BillingSummarySource_Enum.appStore
        : BillingSummarySource_Enum.googlePlay;
    return billing(orgId);
  }

  @override
  Future<BillingUsage> billingUsage(String orgId) async => BillingUsage(
    periodStart: DateTime.utc(2026, 11),
    items: [
      BillingUsageItem(
        kind: 'computer_seconds',
        instance: 'home-server',
        quantity: 7200,
        costUsd: 0.1,
      ),
    ],
    totalUsd: 0.1,
    credits: const [],
  );
  @override
  Future<List<LinkKey>> linkKeys(String orgId) async => [
    for (final (i, n) in linkKeyNames.indexed)
      LinkKey(
        id: 'k$i',
        instanceName: n,
        keyHint: 'kcc_abcd…wxyz',
        scopes: const ['computers', 'models'],
        lastUsedAt: null,
        createdAt: DateTime(2026),
      ),
  ];
  @override
  Future<CreatedLinkKey> createLinkKey(
    String orgId,
    String instanceName,
  ) async {
    linkKeyNames.add(instanceName);
    return CreatedLinkKey(
      id: 'k${linkKeyNames.length - 1}',
      instanceName: instanceName,
      keyHint: 'kcc_abcd…wxyz',
      scopes: const ['computers', 'models'],
      lastUsedAt: null,
      createdAt: DateTime(2026),
      key: 'kcc_secret_shown_once',
    );
  }

  @override
  Future<void> revokeLinkKey(String orgId, String keyId) async =>
      linkKeyNames.removeAt(int.parse(keyId.substring(1)));

  // --- Casama Link (D-296) ------------------------------------------------
  @override
  bool signInCodes = true;
  @override
  bool signUpsOpen = true;
  @override
  bool signUpsByInvitation = false;

  // --- Casama Cloud's waitlist and invite gate (D-427) -----------------------
  @override
  PublicConfigSignupGate? signupGate;

  final waitlistJoins = <WaitlistJoin>[];
  @override
  Future<void> joinWaitlist(WaitlistJoin join) async => waitlistJoins.add(join);

  /// Codes that exist, with what their preview says.
  Map<String, InviteCodePreview> inviteCodes = {
    'SHOWHN-DEC8': InviteCodePreview(
      kind: InviteCodePreviewKindEnum.campaign,
      label: 'Show HN',
      inviterName: null,
      available: true,
      welcomeUsd: 0,
    ),
  };
  static Never _waitlistProblem(int status, String code, String detail) {
    final req = RequestOptions(path: '/v1/waitlist/redeem');
    throw DioException(
      requestOptions: req,
      response: Response(
        requestOptions: req,
        statusCode: status,
        data: {'type': 'about:blank', 'title': 'Error', 'status': status, 'code': code, 'detail': detail},
      ),
    );
  }

  @override
  Future<InviteCodePreview> previewInviteCode(String code) async =>
      inviteCodes[code] ?? _waitlistProblem(404, 'invite_not_found', "That invite code doesn't exist.");

  /// (code, email or provider) for each claim.
  final inviteRedeems = <(String, String)>[];
  @override
  Future<InviteRedeemed> redeemInviteForEmail(String code, String email, {bool? newsletter}) async {
    inviteRedeems.add((code, email));
    final p = inviteCodes[code] ?? _waitlistProblem(404, 'invite_not_found', "That invite code doesn't exist.");
    return InviteRedeemed(
      outcome: p.available ? InviteRedeemedOutcomeEnum.admitted : InviteRedeemedOutcomeEnum.waitlisted,
      kind: InviteRedeemedKindEnum.campaign,
    );
  }

  Set<String> inviteProviders = {'apple', 'google'};
  @override
  bool inviteSignInAvailable(String provider) => inviteProviders.contains(provider);

  InviteSignInResult inviteSignInResult = InviteSignInResult.signedIn;
  @override
  Future<InviteSignInResult> signInWithInvite(String provider, String code) async {
    inviteRedeems.add((code, provider));
    if (inviteSignInResult == InviteSignInResult.signedIn) {
      signedIn = true;
      _auth.add(true);
    }
    return inviteSignInResult;
  }

  /// (email, code) for each invite sign-in email.
  final inviteMagicLinks = <(String, String)>[];
  @override
  Future<void> sendMagicLinkWithInvite(String email, String inviteCode) async =>
      inviteMagicLinks.add((email, inviteCode));

  WaitlistStats waitlistStats = WaitlistStats(
    waiting: 42,
    queued: 3,
    admitted: 120,
    joined: 97,
    firstChat: 61,
    listedToday: 9,
    admittedToday: 5,
    emailsToday: 4,
    bySource: [
      WaitlistStatsBySourceInner(key: 'waitlist', listed: 30, admitted: 80, joined: 70, firstChat: 40),
      WaitlistStatsBySourceInner(key: 'app_ios', listed: 12, admitted: 40, joined: 27, firstChat: 21),
    ],
    byVia: const [],
  );
  SignupGate signupGateSetting = SignupGate(
    mode: SignupGateModeEnum.inviteOnly,
    opensAt: null,
    invitesPerPerson: 3,
    dailyAdmit: 0,
    dailyEmailsMax: 25,
  );
  int? batchHourUtc;
  WaitlistLastBatch? lastBatch;
  List<WaitlistEntry> waitlistEntries = [
    WaitlistEntry(
      id: 'e1',
      email: 'ana@example.com',
      status: WaitlistEntryStatusEnum.waiting,
      source_: 'waitlist',
      ref: null,
      selfHosting: true,
      note: 'Sort my inbox',
      priority: 0,
      inviteCode: null,
      admittedVia: null,
      admittedAt: null,
      joinedAt: null,
      createdAt: DateTime.utc(2026, 11, 18),
    ),
    WaitlistEntry(
      id: 'e2',
      email: 'ben@example.com',
      status: WaitlistEntryStatusEnum.admitted,
      source_: 'app_ios',
      ref: null,
      selfHosting: false,
      note: null,
      priority: 0,
      inviteCode: null,
      admittedVia: 'admin',
      admittedAt: DateTime.utc(2026, 11, 18),
      joinedAt: null,
      createdAt: DateTime.utc(2026, 11, 17),
    ),
  ];
  final waitlistQueries = <String?>[];
  AdminSignupGate get _adminGate => AdminSignupGate(
    state: SignupGateState(gate: signupGateSetting, closed: signupGateSetting.mode == SignupGateModeEnum.inviteOnly),
    batchHourUtc: batchHourUtc,
  );

  @override
  Future<AdminWaitlist> adminWaitlist({String? status, String? query, int limit = 50, int offset = 0}) async {
    waitlistQueries.add(query);
    final q = query?.trim().toLowerCase() ?? '';
    return AdminWaitlist(
      stats: waitlistStats,
      gate: _adminGate,
      items: [for (final e in waitlistEntries) if (q.isEmpty || e.email.contains(q)) e],
      lastBatch: lastBatch,
    );
  }

  final waitlistAdmits = <int?>[];
  @override
  Future<int> adminAdmitWaitlist({int? count, List<String>? ids}) async {
    waitlistAdmits.add(count ?? ids?.length);
    return count ?? ids?.length ?? 0;
  }

  final waitlistAdded = <(List<String>, bool)>[];
  @override
  Future<WaitlistChanged> adminAddWaitlistEntries(List<String> emails, {bool notify = false}) async {
    waitlistAdded.add((emails, notify));
    return WaitlistChanged(count: emails.length);
  }

  final waitlistRemoved = <String>[];
  @override
  Future<void> adminRemoveWaitlistEntry(String id) async {
    waitlistRemoved.add(id);
    waitlistEntries = [for (final e in waitlistEntries) if (e.id != id) e];
  }

  @override
  Future<AdminSignupGate> adminSignupGate() async => _adminGate;

  final signupGateChanges = <Map<String, Object?>>[];
  @override
  Future<AdminSignupGate> adminSetSignupGate(Map<String, Object?> changes) async {
    signupGateChanges.add(changes);
    final g = signupGateSetting;
    final mode = changes['mode'];
    signupGateSetting = SignupGate(
      mode: mode == null ? g.mode : (mode == 'open' ? SignupGateModeEnum.open : SignupGateModeEnum.inviteOnly),
      opensAt: changes.containsKey('opens_at') ? DateTime.tryParse('${changes['opens_at']}') : g.opensAt,
      invitesPerPerson: (changes['invites_per_person'] as int?) ?? g.invitesPerPerson,
      dailyAdmit: (changes['daily_admit'] as int?) ?? g.dailyAdmit,
      dailyEmailsMax: (changes['daily_emails_max'] as int?) ?? g.dailyEmailsMax,
    );
    if (changes['batch_hour_utc'] is int) batchHourUtc = changes['batch_hour_utc'] as int;
    return _adminGate;
  }

  List<InviteCampaign> inviteCampaigns = [
    InviteCampaign(
      code: 'SELFHOST-2026',
      label: 'Self-hosters',
      maxUses: 60,
      used: 12,
      perDay: 30,
      startsAt: null,
      expiresAt: null,
      disabled: false,
      createdAt: DateTime.utc(2026, 11, 19),
      link: 'https://casama.ai/invite/SELFHOST-2026',
    ),
  ];
  @override
  Future<List<InviteCampaign>> adminInviteCampaigns() async => inviteCampaigns;

  final createdCampaigns = <CreateInviteCampaignRequest>[];
  @override
  Future<InviteCampaign> adminCreateInviteCampaign(CreateInviteCampaignRequest request) async {
    createdCampaigns.add(request);
    final c = InviteCampaign(
      code: request.code,
      label: request.label,
      maxUses: request.maxUses,
      used: 0,
      perDay: request.perDay,
      startsAt: request.startsAt,
      expiresAt: request.expiresAt,
      disabled: false,
      createdAt: DateTime.utc(2026, 11, 19),
      link: 'https://casama.ai/invite/${request.code}',
    );
    inviteCampaigns = [...inviteCampaigns, c];
    return c;
  }

  final updatedCampaigns = <(String, UpdateInviteCampaignRequest)>[];
  @override
  Future<InviteCampaign> adminUpdateInviteCampaign(String code, UpdateInviteCampaignRequest request) async {
    updatedCampaigns.add((code, request));
    final old = inviteCampaigns.firstWhere((c) => c.code == code);
    final c = InviteCampaign(
      code: old.code,
      label: request.label ?? old.label,
      maxUses: request.maxUses ?? old.maxUses,
      used: old.used,
      perDay: old.perDay,
      startsAt: old.startsAt,
      expiresAt: old.expiresAt,
      disabled: request.disabled ?? old.disabled,
      createdAt: old.createdAt,
      link: old.link,
    );
    inviteCampaigns = [for (final x in inviteCampaigns) x.code == code ? c : x];
    return c;
  }

  @override
  Future<void> setPrivateNotifications(bool on) async {
    final s = remoteAccessStatus;
    if (s == null) return;
    remoteAccessStatus = RemoteAccessStatus(
      state: s.state,
      address: s.address,
      pagesAddress: s.pagesAddress,
      localAddress: s.localAddress,
      linked: s.linked,
      problem: s.problem,
      connections: s.connections,
      checkedAt: s.checkedAt,
      push: s.push,
      privateNotifications: on,
      invites: s.invites,
      liveView: s.liveView,
    );
  }

  /// What a sign-in code's address is: tests set a local one to see the "not reachable" state.
  var signInCodeServer = 'https://k7qm2xfd9abc.link.test';
  var signInCodeReachable = true;
  var signInCodesMade = 0;
  @override
  Future<SignInCode> createSignInCode() async {
    signInCodesMade++;
    final code = 'ksc_code-$signInCodesMade';
    return SignInCode(
      code: code,
      expiresAt: DateTime.now().add(const Duration(minutes: 5)),
      serverUrl: signInCodeServer,
      reachable: signInCodeReachable,
      pairUrl:
          'https://casama.ai/pair#v=1&s=${Uri.encodeComponent(signInCodeServer)}&c=$code',
    );
  }

  /// Codes this device signed in with, and what to throw instead (a used or expired code).
  final redeemedCodes = <(String, String?)>[];
  Object? signInWithCodeError;
  @override
  Future<void> signInWithCode(String code, {String? deviceName}) async {
    if (signInWithCodeError != null) throw signInWithCodeError!;
    redeemedCodes.add((code, deviceName));
    signedIn = true;
    _auth.add(true);
  }

  /// Link codes waiting for approval: code -> server name.
  final linkSignIns = <String, String>{'K7QM-2XFD': 'Home Mac'};
  final approvedLinks = <(String, String)>[];
  @override
  Future<LinkSignInRequest?> linkSignIn(String userCode) async {
    final name = linkSignIns[userCode.toUpperCase()];
    return name == null
        ? null
        : LinkSignInRequest(
            userCode: userCode.toUpperCase(),
            instanceName: name,
            platform: 'macos',
            version: '0.1.0',
            approved: false,
            expiresAt: DateTime.now().add(const Duration(minutes: 15)),
          );
  }

  @override
  Future<String> approveLinkSignIn(String orgId, String userCode) async {
    final name = linkSignIns.remove(userCode.toUpperCase());
    if (name == null) {
      final req = RequestOptions(path: '/v1/orgs/$orgId/link/sign-ins/approve');
      throw DioException(
        requestOptions: req,
        response: Response(
          requestOptions: req,
          statusCode: 404,
          data: {'type': 'about:blank', 'title': 'Error', 'status': 404, 'code': 'link_not_found', 'detail': "That code isn't valid any more. Start again."},
        ),
      );
    }
    approvedLinks.add((orgId, userCode.toUpperCase()));
    linkedServers.add(name);
    return name;
  }

  final linkedServers = <String>[];
  var linkServerLimit = 1;
  @override
  Future<LinkServerList> linkServers(String orgId) async => LinkServerList(
    limit: linkServerLimit,
    items: [
      for (final (i, n) in linkedServers.indexed)
        LinkServer(
          id: 's$i',
          instanceName: n,
          address: 'https://k7qm2xfd9ab$i.link.test',
          pagesAddress: 'https://k7qm2xfd9ab$i-p.link.test',
          status: 'active',
          statusReason: null,
          platform: 'macos',
          version: '0.1.0',
          lastSeenAt: DateTime(2026, 11, 14),
          createdAt: DateTime(2026, 11, 1),
        ),
    ],
  );

  @override
  Future<void> removeLinkServer(String orgId, String serverId) async =>
      linkedServers.removeAt(int.parse(serverId.substring(1)));

  /// This server's remote access as its owner sees it; null: not the owner.
  RemoteAccessStatus? remoteAccessStatus;
  var remoteAccessChecks = 0;
  @override
  Future<RemoteAccessStatus?> remoteAccess({bool check = false}) async {
    if (check) remoteAccessChecks++;
    return remoteAccessStatus;
  }

  // --- Phase 6: companion ---------------------------------------------------

  LocalDevice? device;
  final deviceUpdates = <String>[];
  List<String> allowedCodingAgents = const [];

  /// The server's coding agents (D-370); null is an older server without the list.
  List<CodingAgentInfo>? codingCatalog = [
    for (final (id, label, bin, pre) in const [
      ('claude_code', 'Claude Code', 'claude', true),
      ('codex', 'Codex', 'codex', true),
      ('cursor', 'Cursor', 'cursor-agent', true),
      ('pi', 'Pi', 'pi', true),
      ('t3code', 'T3 Code', 't3', true),
      ('kimi', 'Kimi Code', 'kimi', false),
    ])
      CodingAgentInfo(id: id, label: label, bin: bin, where: const ['my_computer'], needsFolder: false, hint: null, preallowed: pre),
  ];
  @override
  Future<List<CodingAgentInfo>?> codingAgents() async => codingCatalog;

  /// Own agents (D-371) on this computer; null is an older server.
  List<OwnCodingAgentEntry>? ownAgents = [];
  @override
  Future<List<OwnCodingAgentEntry>?> ownCodingAgents(String deviceId) async => ownAgents;
  @override
  Future<List<OwnCodingAgentEntry>> setOwnCodingAgents(String deviceId, List<OwnCodingAgent> agents) async {
    ownAgents = [
      for (final a in agents)
        OwnCodingAgentEntry(id: 'own_${a.key}', key: a.key, label: a.label, bin: a.bin, command: a.command, result: a.result, timeoutMin: a.timeoutMin),
    ];
    return ownAgents!;
  }

  final agentTests = <TestOwnCodingAgentRequest>[];
  CodingAgentTestResult agentTestResult = CodingAgentTestResult(ok: true, exitCode: 0, timedOut: false, reply: 'pong', output: 'pong', command: "x -p 'Reply'");
  @override
  Future<CodingAgentTestResult> testOwnCodingAgent(String deviceId, TestOwnCodingAgentRequest draft) async {
    agentTests.add(draft);
    return agentTestResult;
  }

  LocalDevice _device({
    LocalCapabilities? caps,
    List<String>? roots,
    List<String>? bots,
    bool? enabled,
  }) => LocalDevice(
    id: 'dev1',
    orgId: orgId,
    userId: 'me',
    computerId: 'local-computer',
    name: 'This computer',
    platform: LocalDevicePlatformEnum.macos,
    capabilities: caps ?? device?.capabilities ?? LocalCapabilities(),
    allowedRoots: roots ?? device?.allowedRoots ?? const [],
    allowedBotIds: bots ?? device?.allowedBotIds ?? const [],
    allowedCodingAgents: allowedCodingAgents,
    enabled: enabled ?? device?.enabled ?? true,
    online: true,
    lastSeenAt: null,
    createdAt: DateTime(2026),
  );

  @override
  String get apiUrl => 'http://localhost:8787';
  @override
  Future<List<LocalDevice>> localDevices(String orgId) async => [?device, ...browsers];

  /// Browsers paired in Casama for Chrome (platform chrome, no computer).
  final browsers = <LocalDevice>[];
  @override
  Future<CreatedLocalDevice> createLocalDevice(
    String orgId,
    String name,
    String platform,
  ) async {
    device = _device();
    return CreatedLocalDevice.fromJson({
      ...device!.toJson(),
      'token': 'kdev_test',
    });
  }

  @override
  Future<LocalDevice> updateLocalDevice(
    String id, {
    Set<String>? capabilities,
    List<String>? roots,
    List<String>? botIds,
    bool? enabled,
    List<String>? codingAgents,
  }) async {
    deviceUpdates.add(
      [
        if (capabilities != null)
          'caps:${(capabilities.toList()..sort()).join(',')}',
        if (botIds != null) 'bots:${botIds.join(',')}',
        if (enabled != null) 'enabled:$enabled',
        if (codingAgents != null) 'agents:${codingAgents.join(',')}',
      ].join(' '),
    );
    if (codingAgents != null) allowedCodingAgents = codingAgents;
    device = _device(
      caps: capabilities == null
          ? null
          : LocalCapabilities(
              shell: capabilities.contains('shell'),
              files: capabilities.contains('files'),
              browser: capabilities.contains('browser'),
              desktop: capabilities.contains('desktop'),
              mcp: capabilities.contains('mcp'),
              messages: capabilities.contains('messages'),
            ),
      roots: roots,
      bots: botIds,
      enabled: enabled,
    );
    return device!;
  }

  final localMcpSyncs = <List<LocalMcpServerInfo>>[];
  @override
  Future<List<Integration>> setLocalMcpServers(
    String deviceId,
    List<LocalMcpServerInfo> servers,
  ) async {
    localMcpSyncs.add(servers);
    // Like the API: one local_mcp integration per server, named `<key>_<device id prefix>`.
    final bare = deviceId.replaceAll('-', '');
    final suffix = bare.length > 6 ? bare.substring(0, 6) : bare;
    integrationList.removeWhere((i) => i.kind == IntegrationKind.localMcp && i.device?.id == deviceId);
    final items = [
      for (final s in servers)
        Integration(
          id: 'local-${s.key}',
          orgId: device?.orgId ?? orgId,
          kind: IntegrationKind.localMcp,
          name: '${s.key}_$suffix',
          status: IntegrationStatusEnum.pending,
          error: null,
          tools: const [],
          toolsCachedAt: null,
          createdAt: DateTime.now(),
          device: IntegrationDevice(id: deviceId, computerId: null, ownerUserId: 'u1', label: s.label),
        ),
    ];
    integrationList.addAll(items);
    return items;
  }

  @override
  Future<void> deleteLocalDevice(String id) async {
    if (browsers.any((b) => b.id == id)) {
      browsers.removeWhere((b) => b.id == id);
    } else {
      device = null;
    }
  }

  // --- Phase 6: voice -------------------------------------------------------

  final transcribed = <String>[];
  String transcript = 'water the plants';
  final spoken = <String>[];
  final voiceTools = <String>[];
  final voiceToolArgs = <Map<String, Object?>>[];
  List<(String, String)>? savedTurns;
  int? savedSeconds;
  Map<String, Object?>? botVoice;

  /// Thrown by the next calls to [transcribe], one per call, before it answers normally.
  final transcribeErrors = <Object>[];

  @override
  Future<String> transcribe(String botId, Uint8List audio, String mime) async {
    transcribed.add(mime);
    if (transcribeErrors.isNotEmpty) throw transcribeErrors.removeAt(0);
    return transcript;
  }

  @override
  Future<Uint8List> speech(String messageId) async {
    spoken.add(messageId);
    return Uint8List.fromList([1, 2, 3]);
  }

  final ringing = <PhoneCall>[];
  final callActions = <String>[];
  String? sessionCallId;
  Map<String, int>? lastVoiceUsage;
  @override
  Future<List<PhoneCall>> ringingCalls() async => List.of(ringing);
  @override
  Future<PhoneCall> answerCall(String id) async {
    callActions.add('answer:$id');
    final c = ringing.firstWhere((c) => c.id == id);
    ringing.remove(c);
    return PhoneCall.fromJson({...c.toJson(), 'status': 'answered'});
  }

  @override
  Future<PhoneCall> declineCall(String id) async {
    callActions.add('decline:$id');
    final c = ringing.firstWhere((c) => c.id == id);
    ringing.remove(c);
    return PhoneCall.fromJson({...c.toJson(), 'status': 'declined'});
  }

  @override
  Future<void> registerVoipToken(String token) async =>
      callActions.add('voip:$token');

  /// What [voiceTool] answers for a tool (default: completed, "Found 2 memories").
  final voiceToolResults = <String, VoiceToolResult>{};

  /// When set, [voiceTool] waits for it (to see a tool while it runs).
  Completer<void>? voiceToolGate;

  /// Thrown by [voiceSession] when set (a call that can't start).
  Object? voiceSessionError;

  /// Sessions started, for each one's live call id (live-1, live-2…).
  var voiceSessions = 0;
  @override
  Future<VoiceSession> voiceSession(
    String botId, {
    String? conversationId,
    String? callId,
  }) async {
    sessionCallId = callId;
    final error = voiceSessionError;
    if (error != null) throw error;
    return VoiceSession(
      provider: VoiceSessionProviderEnum.gemini,
      model: 'gemini-3.8-live',
      clientSecret: 'auth_tokens/test',
      expiresAt: DateTime.now().add(const Duration(minutes: 10)),
      connectUrl: 'wss://example.invalid/ws/google.ai.generativelanguage.v1beta.GenerativeService.BidiGenerateContentConstrained',
      setup: null,
      conversationId: conversationId ?? convId,
      tools: 3,
      speakFirst: callId != null,
      liveCallId: 'live-${++voiceSessions}',
      limits: sessionLimits,
    );
  }

  /// Call limits the session carries (D-426); none, as from an older server, by default.
  VoiceSessionLimits? sessionLimits;

  @override
  Future<VoiceToolResult> voiceTool(
    String botId,
    String conversationId,
    String callId,
    String name,
    Map<String, Object?> arguments, {
    String? liveCallId,
  }) async {
    voiceTools.add(name);
    voiceToolArgs.add(arguments);
    await voiceToolGate?.future;
    return voiceToolResults[name] ??
        VoiceToolResult(
          status: VoiceToolResultStatusEnum.completed,
          runId: runId,
          output: 'Found 2 memories',
          approvalId: null,
        );
  }

  @override
  Future<void> saveVoiceTranscript(
    String conversationId,
    List<(String, String)> turns,
    int seconds, {
    String? provider,
    Map<String, int>? usage,
    String? liveCallId,
    List<String>? turnIds,
    String? ended,
  }) async {
    lastCallEnded = ended;
    lastVoiceUsage = usage;
    savedSeconds = seconds;
    endedLiveCalls.add(liveCallId);
    // Turns already posted as they happened (D-327) aren't counted twice.
    for (final (i, t) in turns.indexed) {
      final id = turnIds != null && i < turnIds.length ? turnIds[i] : null;
      if (id != null && !savedTurnIds.add(id)) continue;
      liveTurns.add(t);
    }
    savedTurns = List.of(liveTurns);
  }

  /// How the last call said it ended (call card plan).
  String? lastCallEnded;

  /// Next steps started or dismissed from call cards: (liveCallId, stepId, dismissed).
  final callSteps = <(String, String, bool)>[];
  Object? callStepError;

  @override
  Future<String?> updateCallStep(String liveCallId, String stepId, {bool dismiss = false}) async {
    if (callStepError case final e?) throw e;
    callSteps.add((liveCallId, stepId, dismiss));
    return dismiss ? null : 'run-from-$stepId';
  }

  final deletedCalls = <String>[];
  @override
  Future<void> deleteCall(String liveCallId) async {
    deletedCalls.add(liveCallId);
    storedMessages = [
      for (final m in storedMessages)
        if (m.callId != liveCallId && m.call?.liveCallId != liveCallId) m,
    ];
  }

  /// Turns saved while calls went on and at hang-up (D-327), each once.
  final liveTurns = <(String, String)>[];
  final savedTurnIds = <String>{};

  /// How many turn posts failed on purpose before one goes through (retries, D-327).
  var failTurnPosts = 0;
  var turnPosts = 0;
  @override
  Future<void> saveVoiceTurns(
    String liveCallId,
    List<(String, String, String)> turns,
  ) async {
    turnPosts++;
    if (failTurnPosts > 0) {
      failTurnPosts--;
      throw StateError('offline');
    }
    for (final (id, role, text) in turns) {
      if (savedTurnIds.add(id)) liveTurns.add((role, text));
    }
    savedTurns = List.of(liveTurns);
  }

  /// Heartbeats sent (D-327), and whether the server says the call already ended.
  final heartbeats = <String>[];
  var heartbeatEnded = false;
  @override
  Future<bool> voiceHeartbeat(
    String liveCallId, {
    Map<String, int>? usage,
  }) async {
    heartbeats.add(liveCallId);
    return heartbeatEnded;
  }

  /// The live call ids hang-ups ended (null for a call without one).
  final endedLiveCalls = <String?>[];

  @override
  Future<void> updateBotVoice(String botId, Map<String, Object?> voice) async =>
      botVoice = {...?botVoice, ...voice}..removeWhere((_, v) => v == null);
  @override
  Future<Map<String, Object?>> loadBotVoice(String botId) async => {
    ...?botVoice,
  };

  // --- Phase 5 ---------------------------------------------------------------

  final createdComputers = <String>[];
  final computerUpdates = <String>[];
  final deletedComputers = <String>[];
  var leaseHeld = false;
  String? releasedNote;
  final dismissed = <String>[];
  List<TakeoverRequest> openTakeovers = [];

  /// Another person has the screen.
  var leaseHeldByOther = false;

  Lease _lease() => Lease(
    computerId: computerId,
    holderType: leaseHeld || leaseHeldByOther ? LeaseHolderTypeEnum.user : LeaseHolderTypeEnum.bot,
    holderId: leaseHeld ? 'me' : leaseHeldByOther ? 'someone' : null,
    mode: LeaseModeEnum.control,
    expiresAt: leaseHeld
        ? DateTime.now().add(const Duration(minutes: 15))
        : null,
    you: leaseHeld,
    allowShell: leaseHeld && leaseAllowShell,
  );

  /// The last allowShell sent with takeLease.
  bool leaseAllowShell = false;

  @override
  Future<Computer> createComputer(
    String orgId, {
    required String name,
    required bool private,
    String? ownerBotId,
    String profile = 'headless',
  }) async {
    createdComputers.add('$name:$profile:$ownerBotId');
    return (await computers(orgId)).first;
  }

  @override
  Future<Computer> updateComputer(
    String computerId, {
    String? name,
    String? profile,
    int? maxDesktops,
    int? idleSleepMinutes,
  }) async {
    computerUpdates.add(
      '${name ?? ''}${profile ?? ''}${maxDesktops == null ? '' : 'desktops:$maxDesktops'}${idleSleepMinutes == null ? '' : 'sleep:$idleSleepMinutes'}',
    );
    if (idleSleepMinutes != null) computerSleepMinutes = idleSleepMinutes;
    return (await computers(orgId)).first;
  }

  @override
  Future<void> deleteComputer(String computerId) async =>
      deletedComputers.add(computerId);
  @override
  Future<void> setBotComputer(String botId, String? computerId) async =>
      defaultComputer = computerId;

  /// Set to have live view refused (a server reached from away whose plan has no live video).
  Object? streamSessionError;

  @override
  Future<StreamSession> streamSession(
    String computerId, {
    String mode = 'control',
  }) async => streamSessionError != null
      ? throw streamSessionError!
      : StreamSession(
    signalingUrl: 'ws://localhost/v1/computers/$computerId/stream?token=t',
    token: 't',
    mode: StreamMode.values.firstWhere((m) => m.value == mode),
    expiresAt: DateTime.now().add(const Duration(minutes: 5)),
    iceServers: [
      IceServer(
        urls: const ['turn:localhost:3478?transport=udp'],
        username: 'u',
        credential: 'c',
      ),
    ],
    iceTransportPolicy: StreamSessionIceTransportPolicyEnum.relay,
    screenshotUrl: 'http://localhost/v1/computers/$computerId/screenshot',
  );

  @override
  Future<Lease> lease(String computerId) async => _lease();
  @override
  Future<Lease> takeLease(String computerId, {bool allowShell = false}) async {
    leaseHeld = true;
    leaseAllowShell = allowShell;
    return _lease();
  }

  @override
  Future<Lease> releaseLease(String computerId, {String? note}) async {
    leaseHeld = false;
    releasedNote = note;
    return _lease();
  }

  @override
  Future<List<TakeoverRequest>> takeovers(String orgId) async => openTakeovers;
  @override
  Future<void> dismissTakeover(String takeoverId, {String? note}) async {
    dismissed.add(takeoverId);
    openTakeovers = openTakeovers.where((t) => t.id != takeoverId).toList();
  }

  /// The team computer's state; tests change it to see the list update.
  ComputerState teamComputerState = ComputerState.sleeping;
  @override
  Future<List<Computer>> computers(String orgId) async => [
    Computer(
      id: computerId,
      orgId: orgId,
      kind: ComputerKindEnum.team,
      name: 'Team computer',
      ownerBotId: null,
      lastActiveAt: null,
      error: null,
      provider: 'docker',
      profile: ComputerProfileEnum.headless,
      state: teamComputerState,
      size: ComputerSize(cpus: 1),
      hasSnapshot: true,
      maxDesktops: 1,
      createdAt: DateTime(2026),
      idleSleepMinutes: computerSleepMinutes,
      operation: computerOperation,
      updateAvailableSince: computerUpdateSince,
    ),
  ];

  // Managing a computer (D-239).
  int computerSleepMinutes = 5;
  ComputerOperation? computerOperation;
  final computerActions = <String>[];
  ComputerVitals? vitals;
  ComputerStorage? storage;
  List<ComputerProcess>? processes;
  List<Checkpoint> restorePoints = const [];
  ComputerUsage computerUsageData = ComputerUsage(monthStart: '2026-11-01', seconds: 0, costUsd: 0, days: const []);
  List<ComputerHistoryEntry> history = const [];
  List<ComputerBotUse> computerBotUses = const [];
  Uint8List? archive;

  @override
  Future<Computer> restartComputer(String id) async {
    computerActions.add('restart');
    return (await computers(orgId)).first;
  }

  /// An update waiting for the team computer (D-360), and whether a command is running on it.
  DateTime? computerUpdateSince;
  var computerBusy = false;
  @override
  Future<Computer> applyComputerUpdate(String id, {bool force = false}) async {
    if (computerBusy && !force) {
      final req = RequestOptions(path: '/v1/computers/$id/apply-update');
      throw DioException(
        requestOptions: req,
        response: Response(
          requestOptions: req,
          statusCode: 409,
          data: {'type': 'about:blank', 'title': 'Error', 'status': 409, 'code': 'computer_busy', 'detail': 'A command is still running on this computer.'},
        ),
      );
    }
    computerActions.add(force ? 'update+force' : 'update');
    computerUpdateSince = null;
    return (await computers(orgId)).first;
  }

  @override
  Future<Computer> resetComputer(String id, {required bool erase, bool checkpoint = true}) async {
    computerActions.add('${erase ? 'erase' : 'reset'}${checkpoint ? '+checkpoint' : ''}');
    computerOperation = ComputerOperation(
      kind: erase ? ComputerOperationKindEnum.erase : ComputerOperationKindEnum.resetSystem,
      step: checkpoint ? ComputerOperationStepEnum.saving : ComputerOperationStepEnum.wiping,
      checkpointId: null,
      error: null,
      startedAt: DateTime.now(),
      finishedAt: null,
    );
    return (await computers(orgId)).first;
  }

  @override
  Future<ComputerVitals?> computerVitals(String id) async => vitals;
  @override
  Future<ComputerStorage?> computerStorage(String id) async => storage;
  @override
  Future<CleanStorageResult> cleanComputerStorage(String id) async {
    computerActions.add('clean');
    final before = storage;
    storage = ComputerStorage(
      usedBytes: (before?.usedBytes ?? 0) - (before?.cleanableBytes ?? 0),
      limitBytes: before?.limitBytes ?? 0,
      categories: before?.categories ?? const [],
      cleanableBytes: 0,
    );
    return CleanStorageResult(freedBytes: before?.cleanableBytes ?? 0, storage: storage!);
  }

  @override
  Future<List<ComputerProcess>?> computerProcesses(String id) async => processes;
  @override
  Future<void> stopComputerProcess(String id, int pid) async {
    computerActions.add('stop:$pid');
    processes = processes?.where((p) => p.pid != pid).toList();
  }

  @override
  Future<ComputerUsage> computerUsage(String id) async => computerUsageData;
  @override
  Future<List<ComputerHistoryEntry>> computerHistory(String id) async => history;
  @override
  Future<List<ComputerBotUse>> computerBots(String id) async => computerBotUses;
  @override
  Future<Checkpoint> createCheckpoint(String id, String label) async {
    computerActions.add('checkpoint:$label');
    final cp = Checkpoint(id: 'cp-${restorePoints.length + 1}', computerId: id, runId: null, label: label, size: 0, createdAt: DateTime.now());
    restorePoints = [cp, ...restorePoints];
    return cp;
  }

  @override
  Future<Uint8List?> downloadComputerArchive(String id) async {
    computerActions.add('archive');
    return archive;
  }
  @override
  Future<Computer> startComputer(String id) async =>
      (await computers(orgId)).first;
  @override
  Future<Computer> stopComputer(String id) async =>
      (await computers(orgId)).first;
  @override
  Future<List<ComputerFileEntry>> listFiles(
    String computerId,
    String path,
  ) async => const [];
  /// Office files that "convert" to a PDF in tests, by path.
  final pdfPreviews = <String, Uint8List>{};
  @override
  Future<Uint8List?> computerFilePdf(String computerId, String path) async =>
      pdfPreviews[path];

  /// Thumbnails of computer files by path (D-226), and every path asked for.
  final thumbnails = <String, ComputerThumbnail>{};
  final thumbnailRequests = <String>[];
  @override
  Future<ComputerThumbnail?> computerThumbnail(
    String computerId,
    String path, {
    int size = 480,
  }) async {
    thumbnailRequests.add(path);
    return thumbnails[path];
  }

  /// Chat media bytes by id.
  final chatMediaFiles = <String, Uint8List>{};
  @override
  Future<Uint8List> chatMedia(String id) async =>
      chatMediaFiles[id] ?? (throw StateError('no media $id'));
  @override
  String chatMediaUrl(String id) => 'http://localhost:8787/v1/media/$id';
  @override
  String chatMediaPosterUrl(String id) => 'http://localhost:8787/v1/media/$id/poster';
  @override
  Map<String, String> get authHeaders => const {'Authorization': 'Bearer test'};

  // The Library (D-274).
  List<Creation> creationList = [];
  final creationBytes = <String, Uint8List>{};
  final creationUpdates = <(String, Map<String, Object?>)>[];
  final deletedCreations = <String>[];
  final restoredCreations = <String>[];
  /// Library list requests: (kind, bot, conversation, q, cursor).
  final creationQueries = <(CreationKind?, String?, String?, String?, String?)>[];

  /// Creations moved between projects: (creation, project or null).
  final creationMoves = <(String, String?)>[];
  /// Fails the Library list when set (load failed with Try Again).
  Object? creationsError;
  /// Holds the Library list until completed, when set (the loading state).
  Completer<void>? creationsGate;
  @override
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
  }) async {
    creationQueries.add((kind, botId, conversationId, q, cursor));
    await creationsGate?.future;
    final error = creationsError;
    if (error != null) throw error;
    final visible = creationList.where((c) => deleted ? c.deletedAt != null : c.deletedAt == null).toList();
    final words = q?.trim().toLowerCase() ?? '';
    final items = visible
        .where((c) => kind == null || c.kind == kind)
        .where((c) => botId == null || c.botId == botId)
        .where((c) => conversationId == null || c.conversationId == conversationId)
        .where((c) => projectId == null || c.projectId == projectId)
        .where((c) => words.isEmpty || c.title.toLowerCase().contains(words) || (c.botName ?? '').toLowerCase().contains(words))
        .toList();
    final start = cursor == null ? 0 : int.parse(cursor);
    final page = items.skip(start).take(limit).toList();
    final next = start + page.length < items.length ? '${start + page.length}' : null;
    return CreationList(items: page, nextCursor: next, kinds: {for (final c in visible) c.kind}.toList());
  }

  @override
  Future<CreationDetail> creation(String id) async {
    final c = creationList.firstWhere((x) => x.id == id);
    return CreationDetail.fromJson({
      ...c.toJson(),
      'siblings': [for (final s in creationList) if (s.id != id && s.runId != null && s.runId == c.runId) s.toJson()],
    });
  }

  @override
  Future<Creation> updateCreation(String id, {String? title, bool? pinned, bool? opened, CreationVisibilityEnum? visibility}) async {
    creationUpdates.add((id, {'title': title, 'pinned': pinned, 'opened': opened, 'visibility': visibility?.value}));
    final i = creationList.indexWhere((x) => x.id == id);
    creationList[i] = Creation.fromJson({
      ...creationList[i].toJson(),
      'title': ?title,
      'pinned': ?pinned,
      'visibility': ?visibility?.value,
      if (visibility == CreationVisibilityEnum.public) 'public_url': 'https://pages.example.com/c/tok-$id',
    });
    return creationList[i];
  }

  /// Creations duplicated (D-291).
  final duplicatedCreations = <String>[];
  @override
  Future<Creation> duplicateCreation(String id) async {
    duplicatedCreations.add(id);
    final c = creationList.firstWhere((x) => x.id == id);
    final copy = Creation.fromJson({
      ...c.toJson(),
      'id': '$id-copy',
      'title': '${c.title} (copy)',
      'pinned': false,
      'visibility': 'private',
      'public_url': null,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
    creationList = [copy, ...creationList];
    return copy;
  }

  @override
  Future<Creation> moveCreation(String id, String? projectId) async {
    creationMoves.add((id, projectId));
    final i = creationList.indexWhere((x) => x.id == id);
    final title = (await projects(orgId)).where((p) => p.id == projectId).firstOrNull?.title;
    creationList[i] = Creation.fromJson({
      ...creationList[i].toJson(),
      'project_id': projectId,
      'project_title': title,
    });
    return creationList[i];
  }

  @override
  Future<void> deleteCreation(String id) async {
    deletedCreations.add(id);
    final i = creationList.indexWhere((x) => x.id == id);
    if (i >= 0) creationList[i] = Creation.fromJson({...creationList[i].toJson(), 'deleted_at': DateTime.now().toUtc().toIso8601String()});
  }

  @override
  Future<void> restoreCreation(String id) async {
    restoredCreations.add(id);
    final i = creationList.indexWhere((x) => x.id == id);
    if (i >= 0) creationList[i] = Creation.fromJson({...creationList[i].toJson(), 'deleted_at': null});
  }

  @override
  String creationContentUrl(String id) => 'http://localhost:8787/v1/creations/$id/content';
  @override
  String creationCoverUrl(String id) => 'http://localhost:8787/v1/creations/$id/cover';
  @override
  Future<Uint8List> creationContent(String id) async => creationBytes[id] ?? Uint8List.fromList(utf8.encode('hello'));

  @override
  Future<Uint8List> downloadFile(String computerId, String path) async =>
      uploads[path] ?? Uint8List.fromList(utf8.encode('# Hello\n\nfile $path'));
  @override
  Future<void> uploadFile(
    String computerId,
    String path,
    Uint8List bytes,
  ) async => uploads[path] = bytes;
  @override
  Future<void> deleteFile(String computerId, String path) async {}
  @override
  Future<List<Checkpoint>> checkpoints(String computerId) async => restorePoints;
  @override
  Future<void> restoreCheckpoint(
    String computerId,
    String checkpointId,
  ) async => computerActions.add('restore:$checkpointId');
  /// What [screenshot] returns: null fails, empty bytes means nothing on screen.
  Uint8List? screen;
  @override
  Future<Uint8List?> screenshot(String computerId) async => screen;
  @override
  Future<(Uri, Map<String, String>)> terminal(
    String computerId, {
    int cols = 100,
    int rows = 30,
  }) async => (Uri.parse('ws://localhost/terminal'), <String, String>{});
}

/// A connected ChatGPT plan owned by [owner] (the fake's user is 'me').
Credential chatGptCredential(
  String orgId, {
  String owner = 'me',
  CredentialStatus status = CredentialStatus.ok,
  bool fallbackOnLimit = false,
}) => Credential(
  id: 'plan',
  orgId: orgId,
  provider: ProviderId.chatgpt,
  label: 'ChatGPT plan',
  baseUrl: null,
  keyHint: null,
  lastTestedAt: null,
  lastTestOk: null,
  ownerUserId: owner,
  status: status,
  account: 'me@example.com',
  fallbackOnLimit: fallbackOnLimit,
  embeddingModel: null,
  createdAt: DateTime(2026),
);

extension on Task {
  Task rebuild({
    String? id,
    String? title,
    String? detailsMd,
    TaskStatus? status,
    TaskPriority? priority,
    String? assigneeBotId,
    String? assigneeUserId,
    bool? reviewRequired,
    double? position,
    int? comments,
  }) => Task(
    id: id ?? this.id,
    title: title ?? this.title,
    detailsMd: detailsMd ?? this.detailsMd,
    status: status ?? this.status,
    priority: priority ?? this.priority,
    assigneeBotId: assigneeBotId ?? this.assigneeBotId,
    assigneeUserId: assigneeUserId ?? this.assigneeUserId,
    createdByBotId: createdByBotId,
    createdByUserId: createdByUserId,
    resultMd: resultMd,
    dueAt: dueAt,
    labels: labels,
    position: position ?? this.position,
    reviewRequired: reviewRequired ?? this.reviewRequired,
    conversationId: conversationId,
    projectId: projectId,
    milestoneId: milestoneId,
    parentTaskId: parentTaskId,
    comments: comments ?? this.comments,
    updatedAt: updatedAt,
    createdAt: createdAt,
  );
}


/// A creation for Library tests (D-274).
/// A published site for [pageId] at `https://<label>.sites.example`.
Site fakeSite(
  String pageId, {
  String label = 'space-dodger',
  String zone = 'sites.example',
  bool indexable = false,
  bool canIndex = true,
  List<SiteHost>? hosts,
}) => Site(
  pageId: pageId,
  title: 'Space Dodger',
  label: label,
  addressUrl: 'https://$label.$zone',
  url: 'https://$label.$zone',
  live: true,
  indexable: indexable,
  badge: true,
  canIndex: canIndex,
  hosts: hosts ?? [fakeSiteHost('$label.$zone')],
  createdAt: DateTime(2026, 11, 16),
);

/// One host of a site; [status] is the server's word for its state.
SiteHost fakeSiteHost(
  String hostname, {
  String kind = 'address',
  String status = 'active',
  bool primary = true,
}) => SiteHost(
  id: 'host-$hostname',
  hostname: hostname,
  kind: kind,
  isPrimary: primary,
  status: status,
  statusReason: null,
  domainId: null,
  live: status == 'active',
  url: 'https://$hostname',
);

/// A connected domain; [state] is the chip's word. Its records are a www CNAME (found) and the
/// bare domain's ownership TXT (not found yet).
Domain fakeDomain(
  String id, {
  String name = 'bakery.com',
  String state = 'waiting_dns',
  String? pageId,
  String? pageTitle,
  String? dnsProvider,
  List<SiteHost>? hosts,
  List<DomainRecord>? records,
  List<DomainEvent>? events,
}) => Domain(
  id: id,
  name: name,
  kind: 'connected',
  target: 'd-abc123.sites.example',
  dnsProvider: dnsProvider,
  pageId: pageId,
  pageTitle: pageTitle ?? (pageId == null ? null : 'Space Dodger'),
  state: state,
  live: state == 'live',
  registrantVerified: null,
  hosts: hosts ??
      [
        fakeSiteHost('www.$name', kind: 'custom', status: state == 'live' ? 'active' : 'pending_dns'),
        fakeSiteHost(name, kind: 'custom', status: 'pending_dns', primary: false),
      ],
  records: records ??
      [
        fakeDomainRecord('www.$name', type: 'CNAME', value: 'd-abc123.sites.example', ok: true),
        fakeDomainRecord(
          name,
          type: 'TXT',
          recordName: '_cf-custom-hostname.$name',
          value: 'proof-123',
          purpose: 'proof',
          ok: false,
        ),
      ],
  expiresAt: null,
  autoRenew: false,
  registrarStatus: null,
  renewPriceUsd: null,
  locked: false,
  transferAfter: null,
  checkedAt: null,
  createdAt: DateTime(2026, 11, 16),
  events: events,
);

/// A bought domain: no records to add, renewing on [expiresAt] at \$18.50.
Domain fakeRegisteredDomain(
  String id, {
  String name = 'bakery.com',
  String state = 'live',
  String registrarStatus = 'active',
  DateTime? expiresAt,
  bool autoRenew = true,
  bool locked = true,
  DateTime? transferAfter,
  bool registrantVerified = true,
}) => fakeDomain(id, name: name, state: state, records: const []).copyWith(
  kind: 'registered',
  expiresAt: expiresAt ?? DateTime(2027, 11, 16),
  autoRenew: autoRenew,
  registrarStatus: registrarStatus,
  renewPriceUsd: 18.5,
  locked: locked,
  transferAfter: transferAfter ?? DateTime(2027, 1, 15),
  registrantVerified: registrantVerified,
);

/// One record to add for [host]; [ok] is what DNS shows now (null: unknown).
DomainRecord fakeDomainRecord(
  String host, {
  String type = 'CNAME',
  String? recordName,
  String value = 'd-abc123.sites.example',
  String purpose = 'point',
  bool required = true,
  bool? ok,
}) => DomainRecord(
  host: host,
  type: type,
  name: recordName ?? host,
  value: value,
  purpose: purpose,
  required_: required,
  seen: ok == null ? null : (ok ? [value] : const []),
  ok: ok,
);

Creation fakeCreation(
  String id, {
  CreationKind kind = CreationKind.page,
  String title = 'Space Dodger',
  String? label,
  String? bot = botId,
  String? botName = 'Ada',
  String? conversation = convId,
  String? runId,
  String? pageId,
  String? mediaId,
  String? mime,
  bool hasCover = false,
  bool pinned = false,
  DateTime? createdAt,
}) => Creation(
  id: id,
  orgId: orgId,
  botId: bot,
  botName: botName,
  madeFor: 'me',
  conversationId: conversation,
  runId: runId,
  kind: kind,
  label: label,
  title: title,
  pageId: pageId ?? (kind == CreationKind.page ? 'page-$id' : null),
  mediaId: mediaId,
  mime: mime,
  size: 1024,
  width: null,
  height: null,
  durationS: null,
  hasCover: hasCover,
  hasPreview: false,
  version: 1,
  visibility: CreationVisibilityEnum.private,
  pinned: pinned,
  lastOpenedAt: null,
  canChange: true,
  deletedAt: null,
  createdAt: createdAt ?? DateTime.now(),
  updatedAt: createdAt ?? DateTime.now(),
);

/// Adds a run start to [FakeBackend.activity], as tests from before reactions did.
class _RunActivity {
  _RunActivity(this._out);
  final StreamController<ConversationActivity> _out;
  void add(String? runId) => _out.add(ConversationActivity.run(runId));
}
