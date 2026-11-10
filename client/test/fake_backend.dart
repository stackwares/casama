import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';

import 'package:kasama_app/core/backend.dart';
import 'package:kasama_sdk/kasama_sdk.dart';

const orgId = '11111111-1111-4111-8111-111111111111';
const botId = '22222222-2222-4222-8222-222222222222';
const runId = '33333333-3333-4333-8333-333333333333';
const convId = '44444444-4444-4444-8444-444444444444';
const computerId = '55555555-5555-4555-8555-555555555555';

Map<String, dynamic> eventJson(int seq, String type, Map<String, dynamic> payload) => {
      'v': 1,
      'run_id': runId,
      'seq': seq,
      'ts': '2026-11-10T09:00:00.000Z',
      'bot_id': botId,
      'type': type,
      'payload': payload,
    };

RunEventItem ev(int seq, String type, Map<String, dynamic> payload) => RunEventItem.fromJson(eventJson(seq, type, payload));

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
  String? defaultModelFor(String provider) => const {'openrouter': 'openai/gpt-6-luna', 'openai': 'gpt-6-luna'}[provider];

  @override
  Stream<bool> get signedInChanges => _auth.stream;
  @override
  bool get isSignedIn => signedIn;
  @override
  String? get userEmail => 'tester@example.com';
  @override
  String? get userId => 'me';
  @override
  Future<void> signIn(String email, String password) async {
    signedIn = true;
    _auth.add(true);
  }

  @override
  Future<bool> signUp(String email, String password) async => true;
  @override
  Future<void> sendMagicLink(String email) async {}
  @override
  Future<void> signInWithProvider(String provider) async {}
  @override
  Future<void> signOut() async {
    signedIn = false;
    _auth.add(false);
  }

  var hasOrg = true;
  var createdOrgs = 0;

  @override
  Future<List<OrganizationWithRole>> organizations() async => !hasOrg ? const [] : [
        OrganizationWithRole(
          id: orgId,
          name: orgName,
          slug: 'test-org',
          plan: 'selfhost',
          region: 'local',
          icon: orgIcon,
          color: orgColor,
          createdAt: DateTime(2026),
          role: OrgRole.owner,
          suspended: orgSuspended,
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
  Future<Organization> updateOrg(String orgId, {String? name, String? icon, String? color}) async {
    orgName = name ?? orgName;
    orgIcon = icon ?? orgIcon;
    orgColor = color ?? orgColor;
    return Organization(id: orgId, name: orgName, slug: 'test-org', plan: 'selfhost', region: 'local', icon: orgIcon, color: orgColor, createdAt: DateTime(2026));
  }
  @override
  Future<List<InviteLink>> inviteLinks(String orgId) async => List.of(links);
  @override
  Future<CreatedInviteLink> createInviteLink(String orgId, {String role = 'member', int? expiresInDays, int? maxUses}) async {
    final id = 'l${links.length + 1}';
    final r = role == 'admin' ? InviteLinkRoleEnum.admin : InviteLinkRoleEnum.member;
    links.add(InviteLink(id: id, orgId: orgId, role: r, tokenHint: 'kjoin_abcd', expiresAt: null, maxUses: maxUses, uses: 0, revokedAt: null, createdAt: DateTime(2026)));
    return CreatedInviteLink(
      id: id, orgId: orgId, role: role == 'admin' ? CreatedInviteLinkRoleEnum.admin : CreatedInviteLinkRoleEnum.member, tokenHint: 'kjoin_abcd',
      expiresAt: null, maxUses: maxUses, uses: 0, revokedAt: null, createdAt: DateTime(2026),
      token: 'kjoin_abcdefghijklmnop', url: 'https://app.example.com/join/kjoin_abcdefghijklmnop',
    );
  }
  @override
  Future<void> revokeInviteLink(String orgId, String linkId) async => links.removeWhere((l) => l.id == linkId);
  @override
  Future<OrganizationWithRole> acceptInviteLink(String token) async {
    joined.add(token);
    final o = OrganizationWithRole(id: '99999999-0000-4000-8000-000000000001', name: 'Friends', slug: 'friends', plan: 'selfhost', region: 'local', createdAt: DateTime(2026), role: OrgRole.member);
    extraOrgs.add(o);
    return o;
  }
  @override
  Future<List<WorkspaceBadge>> workspaceBadges() async => [WorkspaceBadge(orgId: orgId, approvals: 1, unread: 2)];
  bool orgSuspended = false;
  @override
  Future<Organization> createOrganization(String name) async {
    createdOrgs++;
    hasOrg = true;
    return Organization(id: orgId, name: name, slug: 'test-org', plan: 'selfhost', region: 'local', createdAt: DateTime(2026));
  }
  @override
  Future<void> acceptInvite(String token) async {}
  @override
  Future<Invite> invite(String orgId, String email, {bool admin = false}) async => throw UnimplementedError();

  @override
  Future<List<Credential>> credentials(String orgId) async => noKeys
      ? const []
      : [
        Credential(id: 'cred', orgId: orgId, provider: ProviderId.openrouter, label: 'Main', baseUrl: null, keyHint: '1234', lastTestedAt: null, lastTestOk: null, ownerUserId: null, status: CredentialStatus.ok, account: null, fallbackOnLimit: false, createdAt: DateTime(2026)),
        ...extraCredentials,
      ];
  /// Extra keys for a test (for example a ChatGPT plan).
  List<Credential> extraCredentials = [];
  @override
  bool chatGptSignIn = true;
  @override
  bool canConnectChatGpt = false;
  final connectedChatGpt = <String>[];
  @override
  Future<Credential> connectChatGpt(String orgId, {String? credentialId}) async {
    connectedChatGpt.add(credentialId ?? orgId);
    return chatGptCredential(orgId);
  }
  final credentialUpdates = <String, bool?>{};
  @override
  Future<Credential> updateCredential(String credentialId, {String? label, bool? fallbackOnLimit}) async {
    credentialUpdates[credentialId] = fallbackOnLimit;
    return chatGptCredential('org', fallbackOnLimit: fallbackOnLimit ?? false);
  }
  final deletedCredentials = <String>[];
  @override
  Future<void> deleteCredential(String credentialId) async => deletedCredentials.add(credentialId);
  @override
  Future<Credential> addCredential(String orgId, ProviderId provider, String label, {String? apiKey, String? baseUrl}) async =>
      throw UnimplementedError();
  @override
  Future<CredentialTestResult> testCredential(String credentialId, {String? model}) async =>
      CredentialTestResult(ok: true, model: 'm', latencyMs: 12);
  @override
  Future<ModelOptionList> models(String credentialId) async => ModelOptionList(
        items: [
          ModelOption(id: 'openai/gpt-6-luna', name: 'OpenAI: GPT-6 Luna', featured: true),
          ModelOption(id: 'anthropic/claude-sonnet-5.5', name: 'Anthropic: Claude Sonnet 5.5', featured: true),
          ModelOption(id: 'acme/other', name: 'Acme: Other'),
        ],
        source_: ModelOptionListSource_Enum.live,
      );

  Bot bot({BotStatusEnum status = BotStatusEnum.idle, String id = botId, String name = 'Ada'}) => Bot(
        id: id,
        orgId: orgId,
        name: name,
        avatarUrl: null,
        personaMd: '',
        modelPolicy: ModelPolicy(primary: ModelChoice(credentialId: 'cred', model: 'fixture')),
        autonomy: Autonomy.askRisky,
        visibility: Visibility.team,
        budget: BotBudget(perRunUsd: 1, dailyUsd: 10),
        status: status,
        defaultComputerId: defaultComputer,
        folderId: botFolder,
        archivedAt: null,
        setupStatus: setupStatus,
        sortKey: 0,
        createdAt: DateTime(2026),
      );

  String? botFolder;
  final archived = <String>{};
  final revisions = <BotRevision>[
    BotRevision(
      id: 'rev-1',
      snapshot: const {'name': 'Ada', 'persona_md': 'Be brief.', 'autonomy': 'ask_always'},
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
      McpAuthRequestInfo(id: id, clientName: 'Phone AI', redirectHost: 'ai.example', expiresAt: DateTime(2030));
  @override
  Future<String> decideMcpAuthRequest(String id, {required String orgId, required bool approve}) async {
    mcpActions.add('${approve ? 'allow' : 'refuse'}:$orgId');
    return 'https://ai.example/callback?code=x';
  }
  @override
  Future<List<McpKey>> mcpKeys(String orgId) async => const [];
  @override
  Future<CreatedMcpKey> createMcpKey(String orgId, String name) async {
    mcpActions.add('key:$name');
    return CreatedMcpKey(id: 'k1', name: name, hint: 'abcd', lastUsedAt: null, createdAt: DateTime(2026), key: 'ksk_secret_abcd', mcpUrl: 'http://api/mcp');
  }
  @override
  Future<void> revokeMcpKey(String orgId, String keyId) async => mcpActions.add('revoke:$keyId');
  @override
  Future<bool> mcpDecideApprovals(String orgId) async => mcpApprovals;
  @override
  Future<void> setMcpDecideApprovals(String orgId, bool allowed) async => mcpApprovals = allowed;
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
  Future<void> setWatcherPaused(String id, bool paused) async => watcherActions.add('${paused ? 'pause' : 'resume'}:$id');
  @override
  Future<void> deleteWatcher(String id) async => watcherActions.add('delete:$id');
  final rules = <ActionRule>[];
  @override
  Future<List<ActionRule>> actionRules(String orgId, {String? botId}) async => List.of(rules);
  @override
  Future<void> createActionRule(String orgId, {String? botId, required String category, required String rule, List<String> domains = const [], double? maxAmount}) async {
    rules.add(ActionRule(
      id: 'rule${rules.length + 1}',
      orgId: orgId,
      botId: botId,
      matchKind: ActionRuleMatchKindEnum.category,
      matchValue: category,
      target: domains.isEmpty && maxAmount == null ? null : ActionRuleTarget(domains: domains, maxAmount: maxAmount),
      rule: ActionRuleRuleEnum.values.firstWhere((r) => r.value == rule),
      preview: domains.isEmpty ? '$category: $rule' : 'Sends messages to anyone at ${domains.join(' or ')} without asking',
      createdAt: DateTime(2026),
    ));
  }
  @override
  Future<void> deleteActionRule(String id) async => rules.removeWhere((r) => r.id == id);
  BotCheckins checkins = BotCheckins(enabled: false, briefTime: '08:00', scanEveryHours: 3, dailyCapUsd: 1);
  final suggestionActions = <String>[];
  @override
  Future<BotCheckins> botCheckins(String botId) async => checkins;
  @override
  Future<BotCheckins> setBotCheckins(String botId, BotCheckins settings) async => checkins = settings;
  @override
  Future<ForYou> forYou(String orgId) async => ForYou(
        briefs: [ForYouBrief(botId: botId, conversationId: convId, text: 'Today: 10:00 Standup.', createdAt: DateTime(2026, 11, 10, 8))],
        suggestions: [
          if (!suggestionActions.any((a) => a.endsWith(':s1')))
            Suggestion(id: 's1', botId: botId, title: 'Reply to Ana', bodyMd: 'She asked twice.', proposedAction: null, sources: const [], urgency: SuggestionUrgencyEnum.urgent, expiresAt: DateTime(2026, 11, 12), createdAt: DateTime(2026, 11, 10)),
        ],
        approvals: const [],
      );
  @override
  Future<AcceptedSuggestion> acceptSuggestion(String id) async {
    suggestionActions.add('accept:$id');
    return AcceptedSuggestion(conversationId: convId, runId: 'r-s');
  }
  @override
  Future<void> dismissSuggestion(String id, {bool dontSuggestAgain = false}) async => suggestionActions.add('${dontSuggestAgain ? 'never' : 'dismiss'}:$id');
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
      ProjectMilestone(id: 'm1', name: 'Build', position: 1, requiresSignoff: true, status: ProjectMilestoneStatusEnum.awaitingSignoff, ticketsDone: 1, ticketsTotal: 1),
    ],
    runs: const [],
  );
  final projectActions = <String>[];
  @override
  Future<List<Project>> projects(String orgId) async => [Project.fromJson(projectDetail.toJson())];
  @override
  Future<Project> createProject(String orgId, {required String title, required String goal, String doneCriteria = '', required String leadBotId, double? budgetUsd}) async {
    projectActions.add('create:$title:$budgetUsd');
    return Project.fromJson(projectDetail.toJson());
  }
  @override
  Future<ProjectDetail> project(String projectId) async => projectDetail;
  @override
  Future<void> updateProject(String projectId, {String? status, double? budgetUsd}) async => projectActions.add('status:$status');
  @override
  Future<void> approveProjectPlan(String projectId) async => projectActions.add('approve');
  @override
  Future<void> signOffMilestone(String projectId, String milestoneId) async => projectActions.add('signoff:$milestoneId');
  final shares = <bool>[];
  ({String credentialId, String model, bool memories, bool routines})? imported;
  BotTemplateFile template() => BotTemplateFile(
        format: BotTemplateFileFormatEnum.kasamaPeriodBot,
        version: 1,
        name: 'Invoicer',
        personaMd: 'You chase unpaid invoices politely.',
        autonomy: BotTemplateFileAutonomyEnum.askRisky,
        skills: [BotTemplateFileSkillsInner(name: 'dunning', description: 'Follow-up cadence', bodyMd: '1. Day 7')],
        routines: [BotTemplateFileRoutinesInner(name: 'Weekly chase', instructionsMd: 'Chase.', scheduleCron: '0 9 * * 1')],
        connections: [BotTemplateFileConnectionsInner(kind: 'composio', name: 'Gmail')],
        memories: [BotTemplateFileMemoriesInner(kind: BotTemplateFileMemoriesInnerKindEnum.fact, content: 'Acme pays late')],
      );
  @override
  Future<BotTemplateFile> exportBot(String botId, {bool memories = false}) async => template();
  @override
  Future<BotShareLink> createBotShare(String botId, {bool memories = false}) async {
    shares.add(memories);
    return BotShareLink(token: 't0k3n', url: 'https://app.example/import/t0k3n', expiresAt: null);
  }
  @override
  Future<BotTemplateFile> getBotShare(String token) async => template();
  @override
  Future<ImportBotResponse> importBot(String orgId, BotTemplateFile template,
      {required String credentialId, required String model, bool memories = true, bool routines = true}) async {
    imported = (credentialId: credentialId, model: model, memories: memories, routines: routines);
    importedTemplate = template;
    return ImportBotResponse(botId: 'bot-new', skills: 1, routines: routines ? 1 : 0, memories: memories ? 1 : 0, connectionsToAdd: [for (final c in template.connections ?? const <BotTemplateFileConnectionsInner>[]) ImportBotResponseConnectionsToAddInner(kind: c.kind, name: c.name)]);
  }
  QuietHoursView quiet = const QuietHoursView(enabled: false, start: '22:00', end: '07:00');
  final botQuiets = <String, BotQuietView>{};
  @override
  Future<QuietHoursView> quietHours() async => quiet;
  @override
  Future<void> setQuietHours(QuietHoursView hours) async => quiet = hours;
  @override
  Future<BotQuietView> botQuiet(String botId) async => botQuiets[botId] ?? const BotQuietView(mode: 'default');
  @override
  Future<void> setBotQuiet(String botId, BotQuietView value) async => botQuiets[botId] = value;
  final edits = <(String, String)>[];
  final branchSwitches = <String>[];
  List<String> siblings = const [];
  @override
  Future<SendMessageResponse> editMessage(String conversationId, String messageId, String text) async {
    edits.add((messageId, text));
    return SendMessageResponse(messageId: 'm-edit', runId: 'run-edit', conversationId: conversationId);
  }
  @override
  Future<void> switchBranch(String conversationId, String messageId) async => branchSwitches.add(messageId);
  @override
  Future<List<String>> messageSiblings(String conversationId, String messageId) async => siblings;
  @override
  String? traceUrlTemplate;
  String? runTraceId;
  @override
  Future<Run> run(String runId) async => Run(
        id: runId,
        botId: botId,
        conversationId: convId,
        parentRunId: null,
        trigger: 'chat',
        status: RunStatus.completed,
        tokensIn: 100,
        tokensOut: 10,
        costUsd: 0.01,
        lastSeq: 1,
        startedAt: DateTime(2026),
        endedAt: DateTime(2026),
        error: null,
        traceId: runTraceId,
        createdAt: DateTime(2026),
      );
  BotSetupStatusEnum setupStatus = BotSetupStatusEnum.done;
  var setupStarted = 0;
  @override
  Future<String> startBotSetup(String botId) async {
    setupStarted++;
    return 'setup-conv';
  }
  @override
  Future<void> skipBotSetup(String botId) async => setupStatus = BotSetupStatusEnum.skipped;
  final sentSkills = <List<String>>[];
  final catalogInstalls = <(String, String?)>[];
  final githubInstalls = <(String, String)>[];
  String? appliedUpdate;
  @override
  Future<SkillCatalog> skillCatalog() async => SkillCatalog(
        categories: const ['work', 'data'],
        items: [
          CatalogSkill(id: 'meeting-notes', name: 'meeting-notes', description: 'Summarize meetings', category: 'work', files: const []),
          CatalogSkill(id: 'csv-cleanup', name: 'csv-cleanup', description: 'Clean CSV files', category: 'data', files: const ['scripts/clean.py']),
        ],
      );
  @override
  Future<void> installCatalogSkill(String orgId, String catalogId, {String? botId}) async => catalogInstalls.add((catalogId, botId));
  @override
  Future<GitHubSkillPreview> previewGitHubSkill(String orgId, String url) async => GitHubSkillPreview(
        repo: 'acme/skills',
        path: 'pr-labels',
        ref: null,
        commit: 'a' * 40,
        name: 'pr-labels',
        description: 'Label pull requests',
        skillMd: '---\nname: pr-labels\n---\nSteps',
        files: [SkillPreviewFile(path: 'label.sh', size: 21, executable: true, text: 'echo label')],
      );
  @override
  Future<void> installGitHubSkill(String orgId, String url, String commit, {String? botId}) async => githubInstalls.add((url, commit));
  @override
  Future<SkillUpdateCheck> checkSkillUpdate(String skillId) async => SkillUpdateCheck(
        currentCommit: 'a' * 40,
        latestCommit: 'b' * 40,
        hasUpdate: true,
        diff: const ['- old step', '+ new step'],
        filesAdded: const [],
        filesRemoved: const ['label.sh'],
        filesChanged: const [],
      );
  @override
  Future<void> applySkillUpdate(String skillId, String commit) async => appliedUpdate = commit;
  final searches = <String>[];
  @override
  Future<SearchResponse> search(String orgId, String query) async {
    searches.add(query);
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
        SearchResult(kind: SearchKind.ticket, id: 't1', title: 'Send invoice', snippet: '', botId: null, conversationId: null, createdAt: DateTime(2026, 11, 9)),
      ],
      files: [FileSearchResult(computerId: 'comp-1', computerName: 'Team computer', path: 'docs/invoice.md', match: FileSearchResultMatchEnum.name)],
      filesSearched: 1,
    );
  }
  final secretAnswers = <(String, String?)>[];
  @override
  Future<void> fulfillSecretRequest(String requestId, String value) async => secretAnswers.add((requestId, value));
  @override
  Future<void> declineSecretRequest(String requestId) async => secretAnswers.add((requestId, null));

  @override
  Future<List<BotFolder>> botFolders(String orgId) async => [if (botFolder != null) BotFolder(id: botFolder!, name: botFolder!)];
  @override
  Future<void> setBotFolder(String orgId, String botId, String? folderName) async => botFolder = folderName;
  @override
  Future<List<Bot>> archivedBots(String orgId) async => [if (archived.contains(botId)) bot()];
  @override
  Future<void> setBotArchived(String botId, bool value) async => value ? archived.add(botId) : archived.remove(botId);
  @override
  Future<List<BotRevision>> botRevisions(String botId) async => revisions;
  @override
  Future<void> restoreBotRevision(String botId, BotRevision revision) async => restored = revision;

  String? defaultComputer;

  @override
  Future<List<Bot>> bots(String orgId) async {
    if (offline) throw Exception('offline');
    return [if (!archived.contains(botId)) bot(), ...extraBots];
  }

  /// More bots, for group chat tests.
  final extraBots = <Bot>[];
  @override
  Future<Bot> createBot(String orgId,
      {required String name, required String credentialId, required String model, String persona = '', String? templateId, String? avatarUrl}) async {
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
          routines: [TemplateRoutinesInner(name: 'Morning summary', scheduleCron: '0 7 * * *')],
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
  @override
  Future<void> updateBot(String botId, {String? name, String? persona, String? autonomy, Map<String, Object?>? modelPolicy, String? avatarUrl}) async {}
  @override
  bool wallpapersEnabled = false;
  @override
  Future<List<WallpaperPhoto>> searchWallpapers({String? query, int page = 1}) async => const [];
  final wallpaperDownloads = <String>[];
  @override
  Future<void> trackWallpaperDownload(String downloadLocation) async => wallpaperDownloads.add(downloadLocation);

  @override
  Future<UsageReport> usage(String orgId, {String period = 'day'}) async => UsageReport(
        period: period == 'day' ? UsageReportPeriodEnum.day : UsageReportPeriodEnum.month,
        since: DateTime(2026),
        totalCostUsd: 0.0123,
        byBot: [UsageReportByBotInner(botId: botId, name: 'Ada', costUsd: 0.0123, tokensIn: 1000, tokensOut: 200)],
      );

  @override
  Future<List<Conversation>> conversations(String botId) async =>
      [Conversation(id: convId, botId: botId, title: 'Hello', lastMessageAt: null, createdAt: DateTime(2026), kind: ConversationKindEnum.direct, botIds: [botId])];
  @override
  Future<Conversation> createConversation(String botId) async =>
      Conversation(id: convId, botId: botId, title: null, lastMessageAt: null, createdAt: DateTime(2026), kind: ConversationKindEnum.direct, botIds: [botId]);

  // Bot sharing (D-131)
  SetBotAccessRequest? savedAccess;
  @override
  Future<BotAccess> botAccess(String botId) async => BotAccess(
        visibility: BotAccessVisibilityEnum.private,
        createdBy: 'me',
        entries: [BotAccessEntry(userId: 'u-ana', email: 'ana@acme.test', role: null, access: BotAccessEntryAccessEnum.chat)],
        canAdmin: true,
        yourAccess: BotAccessYourAccessEnum.admin,
      );
  @override
  Future<BotAccess> setBotAccess(String botId, SetBotAccessRequest request) async {
    savedAccess = request;
    return botAccess(botId);
  }
  @override
  Future<List<WorkspaceMember>> members(String orgId) async => [
        WorkspaceMember(userId: 'me', email: 'me@acme.test', role: WorkspaceMemberRoleEnum.owner),
        WorkspaceMember(userId: 'u-ana', email: 'ana@acme.test', role: WorkspaceMemberRoleEnum.member),
        WorkspaceMember(userId: 'u-ben', email: 'ben@acme.test', role: WorkspaceMemberRoleEnum.member),
      ];

  // Welcome chat (D-129)
  var welcomeCalls = 0;
  @override
  Future<WelcomeChat> startWelcome({String? firstName}) async {
    welcomeCalls++;
    hasOrg = true;
    return WelcomeChat(orgId: orgId, botId: botId, conversationId: convId, created: true);
  }

  // Password managers (D-128)
  final pmList = <PasswordManager>[];
  final pmActions = <String>[];
  @override
  Future<List<PasswordManager>> passwordManagers(String orgId) async => List.of(pmList);
  @override
  Future<PasswordManager> connectPasswordManager(CreatePasswordManagerRequest request) async {
    pmActions.add('connect:${request.provider.value}:${request.scope.value}');
    final pm = PasswordManager(
      id: 'pm-1',
      scope: PasswordManagerScopeEnum.values.byName(request.scope.name),
      provider: request.provider == CreatePasswordManagerRequestProviderEnum.n1password ? PasswordManagerProviderEnum.n1password : PasswordManagerProviderEnum.bitwarden,
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
        PasswordManagerVault(id: 'v-work', name: 'Work', allowed: false, logins: null),
        PasswordManagerVault(id: 'v-home', name: 'Home', allowed: false, logins: null),
      ];
  @override
  Future<void> setPasswordManagerVaults(String id, List<String> vaults) async => pmActions.add('vaults:$id:${vaults.join(',')}');
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
      steps: [ReplayStepsInner(tool: 'desktop.click'), ReplayStepsInner(tool: 'desktop.type')],
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
  Future<RunReplayResponse> runReplay(String id, Map<String, String> params) async {
    replayActions.add('run:$id:${params['amount']}');
    return RunReplayResponse(conversationId: convId, runId: runId);
  }
  @override
  Future<void> deleteReplay(String id) async {
    replayActions.add('delete:$id');
    replayList.removeWhere((r) => r.id == id);
  }
  @override
  Future<Replay> replayFromTeach(String teachId, String name, {String? description}) async {
    replayActions.add('fromTeach:$teachId:$name');
    return replayList.first;
  }

  // Self-improving skills (D-126)
  final proposals = <SkillProposal>[];
  final proposalActions = <String>[];
  @override
  Future<List<SkillProposal>> skillProposals(String orgId, {String? botId}) async => List.of(proposals);
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
        revisions: [SkillStatsRevisionsInner(id: 'rev-a', description: 'd', bodyMd: 'Old steps', byBot: true, createdAt: DateTime(2026, 11, 8))],
      );

  // Knowledge sources (D-125)
  final knowledgeList = <KnowledgeSource>[];
  final knowledgeActions = <String>[];
  CreateKnowledgeSourceRequest? addedKnowledge;
  @override
  Future<List<KnowledgeSource>> knowledgeSources(String orgId, {String? botId}) async => List.of(knowledgeList);
  @override
  Future<KnowledgeSource> addKnowledgeSource(CreateKnowledgeSourceRequest request) async {
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
  Future<void> resyncKnowledgeSource(String id) async => knowledgeActions.add('sync:$id');
  @override
  Future<void> deleteKnowledgeSource(String id) async {
    knowledgeActions.add('delete:$id');
    knowledgeList.removeWhere((k) => k.id == id);
  }

  // Routines and skills as files (D-124)
  final fileActions = <String>[];
  GitSyncStatus gitStatus = GitSyncStatus(
      configured: false, repo: null, branch: null, path: null, enabled: false, hasToken: true, webhookUrl: null, webhookSecret: null, lastSyncedAt: null, lastCommit: null, lastError: null, openPrUrl: null);
  @override
  Future<Uint8List> exportWorkspaceFiles(String orgId) async {
    fileActions.add('export');
    return Uint8List.fromList([80, 75]);
  }
  @override
  Future<WorkspaceFilesResult> importWorkspaceFiles(String orgId, Uint8List zip, {bool dryRun = false}) async {
    fileActions.add(dryRun ? 'dry' : 'import');
    return WorkspaceFilesResult(created: const ['ada/routines/weekly.md'], updated: const ['ada/routines/brief.md'], deleted: const [], unchanged: 2, errors: const ['ada/routines/bad.md: bad cron'], dryRun: dryRun);
  }
  @override
  Future<GitSyncStatus> gitSync(String orgId) async => gitStatus;
  @override
  Future<GitSyncStatus> setGitSync(String orgId, {required String repo, String? branch, String? path, bool enabled = true}) async {
    fileActions.add('git:$repo:$branch:$path');
    gitStatus = GitSyncStatus(
        configured: true, repo: repo, branch: branch, path: path, enabled: enabled, hasToken: true, webhookUrl: 'https://api.example.com/hooks/git-sync/o', webhookSecret: 'sec-1', lastSyncedAt: null, lastCommit: null, lastError: null, openPrUrl: null);
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
  Future<AgentImportPlan> startAgentImport(String orgId, {Uint8List? zip, Map<String, Uint8List>? files}) async {
    importActions.add(zip != null ? 'zip:${zip.length}' : 'files:${files?.keys.join(',')}');
    return agentPlan();
  }
  AgentImportPlan agentPlan() => AgentImportPlan(
        id: 'imp-1',
        kind: AgentImportPlanKindEnum.openclaw,
        template: BotTemplateFile(
          format: BotTemplateFileFormatEnum.kasamaPeriodBot,
          version: 1,
          name: 'Juno',
          description: 'Imported from OpenClaw',
          personaMd: 'You are Juno.',
          autonomy: BotTemplateFileAutonomyEnum.askRisky,
          skills: [BotTemplateFileSkillsInner(name: 'triage', description: 'Triage the inbox', bodyMd: 'Sort.')],
          routines: [BotTemplateFileRoutinesInner(name: 'Brief', instructionsMd: 'Brief me', scheduleCron: '0 7 * * *')],
          memories: [
            BotTemplateFileMemoriesInner(kind: BotTemplateFileMemoriesInnerKindEnum.preference, content: 'Prefers mornings'),
            BotTemplateFileMemoriesInner(kind: BotTemplateFileMemoriesInnerKindEnum.fact, content: 'Old address'),
          ],
          connections: const [],
        ),
        sources: AgentImportPlanSources(skills: const ['workspace/skills/triage/SKILL.md'], routines: const ['cron/jobs.json'], memories: const ['USER.md', 'MEMORY.md']),
        leftovers: [AgentImportPlanLeftoversInner(path: 'workspace/notes/plan.md', size: 8)],
        skipped: [AgentImportPlanSkippedInner(path: '.env', reason: 'secrets')],
        notes: const ['"Reminder" ran once at a set time; not imported as a routine'],
      );
  @override
  Future<int> writeAgentImportFiles(String importId, String botId) async {
    importActions.add('files:$importId:$botId');
    return 1;
  }
  @override
  Future<String> memoryImportPrompt() async => 'FACT: … PREFERENCE: …';
  @override
  Future<List<ImportedMemoryItem>> parseMemoryImport(String text) async => [
        ImportedMemoryItem(kind: ImportedMemoryItemKindEnum.fact, content: 'Has a dog'),
        ImportedMemoryItem(kind: ImportedMemoryItemKindEnum.preference, content: 'Metric units'),
      ];
  final savedMemories = <ImportedMemoryItem>[];
  @override
  Future<int> saveImportedMemories(String botId, List<ImportedMemoryItem> memories) async {
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
        skills: [PluginPreviewSkillsInner(name: 'plan-trip', description: 'Plan around the weather')],
        servers: [PluginServerInfo(key: 'forecast', type: PluginServerInfoTypeEnum.stdio, command: './bin/forecast', args: const [], url: null)],
        secrets: [PluginSecretInfo(name: 'WEATHER_KEY', description: 'API key', server: 'forecast')],
        hosts: const [],
        warnings: const [],
      );
  Plugin installed(String commit) => Plugin(
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
            tools: [InstalledPluginServerAllOfTools(name: 'forecast', risk: InstalledPluginServerAllOfToolsRiskEnum.low)],
          ),
        ],
        hosts: const [],
        secrets: const [],
        installedAt: DateTime(2026, 11, 10),
        updatedAt: DateTime(2026, 11, 10),
      );
  @override
  Future<List<Plugin>> plugins(String botId) async => List.of(pluginList);
  @override
  Future<PluginPreview> previewPlugin(String orgId, String url) async {
    pluginActions.add('preview:$url');
    return pluginPreview();
  }
  @override
  Future<Plugin> installPlugin(String orgId, String botId, String url, String commit, Map<String, String> secrets) async {
    pluginActions.add('install:$commit:${secrets['WEATHER_KEY']}');
    pluginList.add(installed(commit));
    return pluginList.last;
  }
  @override
  Future<PluginUpdatePreview> pluginUpdate(String id) async => PluginUpdatePreview(
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
  Future<Plugin> updatePlugin(String id, String commit, {Map<String, String> secrets = const {}}) async {
    pluginActions.add('update:$commit');
    pluginList[0] = installed(commit);
    return pluginList[0];
  }
  @override
  Future<void> uninstallPlugin(String id) async {
    pluginActions.add('uninstall:$id');
    pluginList.clear();
  }

  // Teach a task (D-120)
  final teachSteps = <AddTeachStepRequest>[];
  final teachActions = <String>[];
  TeachSessionStatusEnum teachStatus = TeachSessionStatusEnum.recording;
  TeachDraft? teachDraft;
  ({String name, String description, String body, bool tryNow})? savedTeach;
  TeachStep teachStep(int seq, AddTeachStepRequest r, {String? secret}) => TeachStep(
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
        steps: [for (var i = 0; i < teachSteps.length; i++) teachStep(i + 1, teachSteps[i])],
        startedAt: DateTime(2026, 11, 10),
        stoppedAt: null,
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
  Future<SaveTeachResponse> saveTeach(String id, {required String name, required String description, required String body, bool tryNow = false}) async {
    savedTeach = (name: name, description: description, body: body, tryNow: tryNow);
    return SaveTeachResponse(skillId: 'skill-9', conversationId: tryNow ? convId : null, runId: tryNow ? runId : null);
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
  Future<List<BotPage>> pages(String orgId, {String? botId}) async => List.of(pageList);
  @override
  Future<String> pageViewLink(String id, {bool pdf = false}) async {
    pageActions.add('${pdf ? 'pdf' : 'view'}:$id');
    return 'https://pages.example.com/v/tok-$id';
  }
  @override
  Future<String?> setPageVisibility(String id, BotPageVisibilityEnum visibility, {int? expiresInDays}) async {
    pageActions.add('${visibility.name}:$id');
    return visibility == BotPageVisibilityEnum.public ? 'https://pages.example.com/s/public-$id' : null;
  }
  @override
  Future<void> deletePage(String id) async {
    pageActions.add('delete:$id');
    pageList.removeWhere((p) => p.id == id);
  }

  final groups = <Conversation>[];
  @override
  Future<List<Conversation>> groupChats(String orgId) async => groups;
  @override
  Future<Conversation> createGroupChat(String leadBotId, List<String> botIds, {String? title}) async {
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
  Future<List<ChatMessageView>> messages(String conversationId) async {
    if (offline) throw Exception('offline');
    return storedMessages;
  }

  /// Simulates no network for bots and messages (offline cache tests).
  bool offline = false;
  @override
  Future<String?> activeRun(String conversationId) async => null;
  final sentAttachments = <List<AttachmentRef>>[];
  @override
  Future<SendMessageResponse> send(String conversationId, String text, {List<AttachmentRef> attachments = const [], Map<String, Object?>? uiAction, List<String> skills = const []}) async {
    sent.add(text);
    sentSkills.add(skills);
    sentAttachments.add(attachments);
    if (uiAction != null) sentUiActions.add(uiAction);
    return SendMessageResponse(messageId: 'm1', runId: runId, conversationId: conversationId);
  }

  @override
  Future<void> cancelRun(String runId) async => cancelled = true;
  @override
  Stream<RunEventItem> watchRun(String runId, {int afterSeq = 0}) => runEventsController.stream;
  @override
  Future<List<RunEventItem>> runEvents(String runId) async => storedEvents;
  @override
  Future<List<RunSummary>> runs(String botId) async =>
      [RunSummary(id: runId, status: 'completed', trigger: 'chat', createdAt: DateTime.now(), costUsd: 0.001)];

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
      ];
  @override
  Future<void> updateMemory(String id, {String? content, bool? pinned}) async {}
  @override
  Future<void> deleteMemory(String id) async {}
  @override
  Future<List<SkillView>> skills(String orgId) async => skillViews;
  List<SkillView> skillViews = const [];
  @override
  Future<void> saveSkill(String orgId,
      {String? id, String? botId, required String name, required String description, required String bodyMd, bool enabled = true}) async {}
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
  final notificationsController = StreamController<NotificationView>.broadcast();
  List<NotificationView> storedNotifications = [
    NotificationView(id: 'n1', kind: 'approval', title: 'Ada needs approval', body: 'Run a destructive shell command', link: '/approvals/appr1', createdAt: DateTime.now()),
  ];
  var notificationsRead = false;
  final devices = <String>[];
  final routineList = <Routine>[];
  final routinesRun = <String>[];
  final integrationList = <Integration>[];
  final attached = <String>{};
  final secretList = <Secret>[];

  @override
  Future<List<Approval>> approvals(String orgId, {bool pendingOnly = true}) async =>
      pendingApprovals.where((a) => !decisions.containsKey(a.id)).toList();
  @override
  Future<Approval> decideApproval(String approvalId, {required bool approve, bool alwaysAllow = false}) async {
    decisions[approvalId] = approve ? (alwaysAllow ? 'always' : 'approved') : 'denied';
    return pendingApprovals.firstWhere((a) => a.id == approvalId);
  }

  @override
  Future<List<NotificationView>> notifications() async => storedNotifications;
  @override
  Future<void> markNotificationsRead() async => notificationsRead = true;
  final readNotifications = <String>[];
  @override
  Future<void> markNotificationRead(String id) async => readNotifications.add(id);
  @override
  Stream<NotificationView> watchNotifications() => notificationsController.stream;
  @override
  Future<void> registerDevice(String platform, String token) async => devices.add('$platform:$token');

  @override
  Future<List<Routine>> routines(String botId) async => routineList;
  @override
  Future<CreatedRoutine> createRoutine(String botId,
      {required String name, required String instructions, required String trigger, String? cron, String? timezone, DateTime? runAt, CalendarTriggerConfig? calendar}) async {
    createdCalendar = calendar;
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
      nextRunAt: trigger == 'schedule' ? DateTime(2026, 11, 11, 7) : (trigger == 'once' ? runAt : null),
      lastRunAt: null,
      conversationId: null,
      createdAt: DateTime.now(),
      webhookUrl: trigger == 'schedule' || trigger == 'once' ? null : 'http://localhost/hooks/custom/r1',
      webhookSecret: trigger == 'schedule' || trigger == 'once' ? null : 'whsec_test',
    );
    routineList.add(Routine.fromJson(r.toJson()));
    return r;
  }

  @override
  Future<void> setRoutineEnabled(String routineId, bool enabled) async {}
  final deletedRoutines = <String>[];
  @override
  Future<void> deleteRoutine(String routineId) async {
    deletedRoutines.add(routineId);
    routineList.removeWhere((r) => r.id == routineId);
  }
  final uploads = <String, Uint8List>{};
  @override
  Future<String> runRoutine(String routineId) async {
    routinesRun.add(routineId);
    return runId;
  }

  @override
  Future<List<Integration>> integrations(String orgId) async => integrationList;
  CalendarTriggerConfig? createdCalendar;
  @override
  Future<Integration> createIntegration(String orgId,
      {required String kind, required String name, required Map<String, Object?> config, String? secret}) async {
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
  Future<IntegrationTestResult> testIntegration(String integrationId) async => IntegrationTestResult(ok: true, tools: const ['add', 'subtract']);
  @override
  Future<Set<String>> botIntegrationIds(String botId) async => attached;
  @override
  Future<void> setBotIntegration(String botId, String integrationId, bool enabled) async =>
      enabled ? attached.add(integrationId) : attached.remove(integrationId);

  // Built-in apps
  static CatalogApp catalogApp(String id, String name, List<CatalogAppAuthEnum> auth, {bool popular = true, String color = '635BFF'}) => CatalogApp(
        id: id,
        name: name,
        description: '$name for your bots.',
        category: CatalogAppCategoryEnum.payments,
        color: color,
        homepage: 'https://$id.com',
        url: 'https://mcp.$id.com',
        auth: auth,
        apiKey: auth.contains(CatalogAppAuthEnum.apiKey)
            ? CatalogAppApiKey(label: 'Secret key', url: 'https://dashboard.$id.com/keys', steps: const ['Open the dashboard.', 'Copy the key.'])
            : null,
        capabilities: const ['Look up customers', 'Create invoices'],
        popular: popular,
        oauthAvailable: auth.contains(CatalogAppAuthEnum.oauth),
      );
  final catalog = [
    catalogApp('stripe', 'Stripe', [CatalogAppAuthEnum.oauth, CatalogAppAuthEnum.apiKey]),
    catalogApp('notion', 'Notion', [CatalogAppAuthEnum.oauth], color: '000000'),
    catalogApp('cloudflare', 'Cloudflare Docs', [CatalogAppAuthEnum.none], popular: false, color: 'F38020'),
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
      tools: [IntegrationToolsInner(name: 'list_customers', description: 'List customers', risk: Risk.low), IntegrationToolsInner(name: 'create_refund', description: 'Refund a payment', risk: Risk.high)],
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
  Future<AppCatalog> appCatalog() async => AppCatalog(apps: catalog, redirectUri: 'http://localhost/oauth/callback');
  @override
  Future<ConnectAppResponse> connectApp(String orgId, {required String appId, required String method, String? apiKey, String? integrationId}) async {
    connectCalls.add((appId, method, apiKey));
    if (method == 'oauth') {
      return ConnectAppResponse(status: ConnectAppResponseStatusEnum.authorize, authorizeUrl: 'https://auth.$appId.com/authorize', flowId: 'flow-$appId');
    }
    return ConnectAppResponse(status: ConnectAppResponseStatusEnum.connected, integration: _connected(appId, method));
  }
  @override
  Future<ConnectFlowStatus> connectStatus(String flowId) async {
    if (pendingPolls-- > 0) return ConnectFlowStatus(status: ConnectFlowStatusStatusEnum.pending);
    return ConnectFlowStatus(status: ConnectFlowStatusStatusEnum.connected, integration: _connected(flowId.replaceFirst('flow-', ''), 'oauth'));
  }
  @override
  Future<void> deleteIntegration(String integrationId) async {
    deleted.add(integrationId);
    integrationList.removeWhere((i) => i.id == integrationId);
  }
  final toolRisks = <String, Map<String, String>>{};
  @override
  Future<Integration> setToolRisks(String integrationId, Map<String, String> risks) async {
    toolRisks[integrationId] = risks;
    return integrationList.firstWhere((i) => i.id == integrationId);
  }
  @override
  Future<List<ProviderApp>> providerApps(String integrationId, {String? query}) async =>
      [ProviderApp(slug: 'gmail', name: 'Gmail', description: 'Email', logo: null)];
  final providerConnects = <String>[];
  @override
  Future<String> connectProviderApp(String integrationId, String app) async {
    providerConnects.add(app);
    return 'https://connect.example.com/$app';
  }
  @override
  Future<List<ProviderAccount>> providerAccounts(String integrationId) async =>
      [for (final a in providerConnects) ProviderAccount(app: a, status: ProviderAccountStatusEnum.connected)];

  @override
  Future<List<Secret>> secrets(String orgId) async => secretList;
  @override
  Future<void> createSecret(String orgId, {required String name, required String value, required List<String> hosts, bool totp = false}) async =>
      secretList.add(Secret(
        id: 's${secretList.length + 1}',
        orgId: orgId,
        name: name,
        allowedHosts: hosts,
        allowedBotIds: null,
        kind: totp ? SecretKind.totp : SecretKind.plain,
        createdAt: DateTime.now(),
      ));
  @override
  Future<void> deleteSecret(String secretId) async => secretList.removeWhere((s) => s.id == secretId);

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
      TaskComment(id: 'c1', taskId: 't1', authorType: TaskCommentAuthorTypeEnum.bot, authorUserId: null, authorBotId: botId, bodyMd: 'Started reading.', createdAt: DateTime(2026)),
    ],
  };
  @override
  Future<List<Task>> tasks(String orgId, {String? projectId}) async => List.of(taskList);
  @override
  Future<Task> createTask(String orgId, {required String title, String? details, String? priority, String? assigneeBotId, bool? reviewRequired}) async {
    final t = taskList.first.rebuild(id: 't${taskList.length + 1}', title: title, detailsMd: details ?? '', assigneeBotId: assigneeBotId,
        priority: TaskPriority.values.firstWhere((p) => p.value == (priority ?? 'none')), reviewRequired: reviewRequired ?? false, comments: 0);
    taskList.add(t);
    return t;
  }
  @override
  Future<Task> updateTask(String taskId, {String? title, String? details, String? status, String? priority, String? assigneeBotId, String? assigneeUserId, bool? reviewRequired, double? position}) async {
    final i = taskList.indexWhere((t) => t.id == taskId);
    final t = taskList[i];
    taskList[i] = t.rebuild(
      title: title ?? t.title,
      detailsMd: details ?? t.detailsMd,
      status: status == null ? t.status : TaskStatus.values.firstWhere((s) => s.value == status),
      priority: priority == null ? t.priority : TaskPriority.values.firstWhere((p) => p.value == priority),
      assigneeBotId: assigneeBotId ?? t.assigneeBotId,
      assigneeUserId: assigneeUserId ?? t.assigneeUserId,
      reviewRequired: reviewRequired ?? t.reviewRequired,
      position: position ?? t.position.toDouble(),
    );
    return taskList[i];
  }
  @override
  Future<void> deleteTask(String taskId) async => taskList.removeWhere((t) => t.id == taskId);
  @override
  Future<List<TaskComment>> taskComments(String taskId) async => List.of(taskCommentList[taskId] ?? const []);
  @override
  Future<TaskComment> addTaskComment(String taskId, String body) async {
    final c = TaskComment(id: 'c${DateTime.now().microsecondsSinceEpoch}', taskId: taskId, authorType: TaskCommentAuthorTypeEnum.user, authorUserId: 'me', authorBotId: null, bodyMd: body, createdAt: DateTime(2026));
    (taskCommentList[taskId] ??= []).add(c);
    return c;
  }

  // --- Phase 6: admin -------------------------------------------------------

  var isOwner = true;
  Map<String, num>? setLimits;

  @override
  Future<AdminOverview?> adminOverview() async => isOwner
      ? AdminOverview(version: '0.6.0', users: 3, orgs: 2, bots: 4, runs24h: 12, failedRuns24h: 1, cost24hUsd: 0.42, computersRunning: 1, devicesOnline: 1)
      : null;
  @override
  Future<List<AdminUser>> adminUsers() async => [AdminUser(id: 'u1', email: 'owner@example.com', createdAt: DateTime(2026), lastSignInAt: null, orgs: 1)];
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
  Future<List<AdminService>> adminServices() async =>
      [AdminService(name: 'Database', configured: true, healthy: true, detail: 'Postgres (Supabase)')];
  @override
  Future<UpdateNotice> adminUpdates() async => UpdateNotice(current: '0.6.0', latest: '0.9.1', updateAvailable: true, url: 'https://example.com/r');

  // --- Phase 8: privacy and SSO --------------------------------------------

  var exported = 0;
  String? deletedWith;
  var retention = 180;
  String? ssoEmail;
  final sentUiActions = <Map<String, Object?>>[];

  @override
  Future<Uint8List> exportMyData() async {
    exported++;
    return Uint8List.fromList(List.filled(2048, 7));
  }

  @override
  Future<AccountDeletion> deleteAccount(String confirmEmail) async {
    deletedWith = confirmEmail;
    return AccountDeletion(purgeAfter: DateTime.utc(2026, 11, 17), workspacesDeleted: const ['Test Org']);
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
        uri: 'otpauth://totp/Kasama:tester@example.com?secret=JBSWY3DPEHPK3PXP&issuer=Kasama',
        qrSvg: '<svg xmlns="http://www.w3.org/2000/svg" width="10" height="10"><rect width="10" height="10"/></svg>',
      );
  @override
  Future<void> verifyTwoStep(String factorId, String code) async {
    if (code != '123456') throw Exception('Invalid code');
    twoStep.add(TwoStepFactor(id: factorId, name: 'Authenticator 1', createdAt: DateTime(2026)));
    twoStepVerified = true;
  }
  @override
  Future<void> passTwoStep(String code) async {
    if (code != '123456') throw Exception('Invalid code');
    twoStepCodeNeeded = false;
    twoStepVerified = true;
  }
  @override
  Future<void> removeTwoStep(String factorId) async => twoStep.removeWhere((f) => f.id == factorId);
  @override
  Future<bool> requireTwoStep(String orgId) async => requireTwoStepValue;
  @override
  Future<bool> setRequireTwoStep(String orgId, bool value) async => requireTwoStepValue = value;
  @override
  Future<int> setRetentionDays(String orgId, int days) async => retention = days;
  @override
  Future<void> signInWithSso(String email) async => ssoEmail = email;

  // --- Phase 7: billing -----------------------------------------------------

  var billingEnabled = false;
  var planCode = 'free';
  var billingSource = BillingSummarySource_Enum.default_;
  final checkouts = <String>[];
  final verified = <String>[];
  final connectKeyNames = <String>[];

  @override
  Future<BillingSummary> billing(String orgId) async => BillingSummary(
        enabled: billingEnabled,
        planCode: billingEnabled ? planCode : 'selfhost',
        planName: billingEnabled ? (planCode == 'pro' ? 'Pro' : 'Free') : 'Self-hosted',
        interval: planCode == 'pro' ? 'month' : 'none',
        limits: planCode == 'pro' ? const {'max_bots': 20, 'computer_hours': 100, 'monthly_credits_usd': 20} : const {'max_bots': 2},
        unlimited: !billingEnabled,
        validUntil: planCode == 'pro' ? DateTime.utc(2026, 12, 10) : null,
        source_: billingSource,
        cancelAtPeriodEnd: false,
        creditsUsd: billingEnabled ? 1.0 : 0,
        subscriptions: const [],
        providers: const [BillingSource.dodo, BillingSource.appStore, BillingSource.googlePlay],
      );
  @override
  Future<PlanCatalog> plans() async => PlanCatalog(
        enabled: billingEnabled,
        plans: [
          Plan(code: 'free', name: 'Free', interval: PlanIntervalEnum.none, limits: const {'max_bots': 2}, priceLabel: null, web: false, storeProductIds: const {}),
          Plan(
            code: 'pro',
            name: 'Pro',
            interval: PlanIntervalEnum.month,
            limits: const {'max_bots': 20, 'computer_hours': 100, 'monthly_credits_usd': 20},
            priceLabel: null,
            web: true,
            storeProductIds: const {'app_store': 'dev.kasama.pro.monthly', 'google_play': 'kasama_pro:monthly'},
          ),
        ],
        packs: [CreditPack(code: 'credits_10', name: r'$10 of credits', creditsUsd: 10, web: true)],
      );
  @override
  Future<String> checkoutUrl(String orgId, {String? planCode, String? packCode}) async {
    checkouts.add(planCode ?? packCode!);
    return 'https://checkout.example.com/${planCode ?? packCode}';
  }

  @override
  Future<String> billingPortalUrl(String orgId) async => 'https://portal.example.com/cus_1';
  @override
  Future<BillingSummary> verifyPurchase(String orgId,
      {required String source, required String productId, String? transactionId, String? purchaseToken}) async {
    verified.add('$source:$productId:${transactionId ?? purchaseToken}');
    planCode = 'pro';
    billingSource = source == 'app_store' ? BillingSummarySource_Enum.appStore : BillingSummarySource_Enum.googlePlay;
    return billing(orgId);
  }

  @override
  Future<BillingUsage> billingUsage(String orgId) async => BillingUsage(
        periodStart: DateTime.utc(2026, 11),
        items: [BillingUsageItem(kind: 'computer_seconds', instance: 'home-server', quantity: 7200, costUsd: 0.1)],
        totalUsd: 0.1,
        credits: const [],
      );
  @override
  Future<List<ConnectKey>> connectKeys(String orgId) async => [
        for (final (i, n) in connectKeyNames.indexed)
          ConnectKey(id: 'k$i', instanceName: n, keyHint: 'kcc_abcd…wxyz', scopes: const ['computers', 'models'], lastUsedAt: null, createdAt: DateTime(2026)),
      ];
  @override
  Future<CreatedConnectKey> createConnectKey(String orgId, String instanceName) async {
    connectKeyNames.add(instanceName);
    return CreatedConnectKey(
      id: 'k${connectKeyNames.length - 1}',
      instanceName: instanceName,
      keyHint: 'kcc_abcd…wxyz',
      scopes: const ['computers', 'models'],
      lastUsedAt: null,
      createdAt: DateTime(2026),
      key: 'kcc_secret_shown_once',
    );
  }

  @override
  Future<void> revokeConnectKey(String orgId, String keyId) async => connectKeyNames.removeAt(int.parse(keyId.substring(1)));

  // --- Phase 6: companion ---------------------------------------------------

  LocalDevice? device;
  final deviceUpdates = <String>[];

  LocalDevice _device({LocalCapabilities? caps, List<String>? roots, List<String>? bots, bool? enabled}) => LocalDevice(
        id: 'dev1',
        orgId: orgId,
        userId: 'me',
        computerId: 'local-computer',
        name: 'This computer',
        platform: LocalDevicePlatformEnum.macos,
        capabilities: caps ?? device?.capabilities ?? LocalCapabilities(),
        allowedRoots: roots ?? device?.allowedRoots ?? const [],
        allowedBotIds: bots ?? device?.allowedBotIds ?? const [],
        enabled: enabled ?? device?.enabled ?? true,
        online: true,
        lastSeenAt: null,
        createdAt: DateTime(2026),
      );

  @override
  String get apiUrl => 'http://localhost:8787';
  @override
  Future<List<LocalDevice>> localDevices(String orgId) async => [?device];
  @override
  Future<CreatedLocalDevice> createLocalDevice(String orgId, String name, String platform) async {
    device = _device();
    return CreatedLocalDevice.fromJson({...device!.toJson(), 'token': 'kdev_test'});
  }

  @override
  Future<LocalDevice> updateLocalDevice(String id, {Set<String>? capabilities, List<String>? roots, List<String>? botIds, bool? enabled}) async {
    deviceUpdates.add([if (capabilities != null) 'caps:${(capabilities.toList()..sort()).join(',')}', if (botIds != null) 'bots:${botIds.join(',')}', if (enabled != null) 'enabled:$enabled'].join(' '));
    device = _device(
      caps: capabilities == null
          ? null
          : LocalCapabilities(
              shell: capabilities.contains('shell'),
              files: capabilities.contains('files'),
              browser: capabilities.contains('browser'),
              desktop: capabilities.contains('desktop'),
              mcp: capabilities.contains('mcp'),
            ),
      roots: roots,
      bots: botIds,
      enabled: enabled,
    );
    return device!;
  }

  final localMcpSyncs = <List<LocalMcpServerInfo>>[];
  @override
  Future<List<Integration>> setLocalMcpServers(String deviceId, List<LocalMcpServerInfo> servers) async {
    localMcpSyncs.add(servers);
    return const [];
  }

  @override
  Future<void> deleteLocalDevice(String id) async => device = null;

  // --- Phase 6: voice -------------------------------------------------------

  final transcribed = <String>[];
  final spoken = <String>[];
  final voiceTools = <String>[];
  List<(String, String)>? savedTurns;
  int? savedSeconds;
  Map<String, Object?>? botVoice;

  @override
  Future<String> transcribe(String botId, Uint8List audio, String mime) async {
    transcribed.add(mime);
    return 'water the plants';
  }

  @override
  Future<Uint8List> speech(String messageId) async {
    spoken.add(messageId);
    return Uint8List.fromList([1, 2, 3]);
  }

  @override
  Future<VoiceSession> voiceSession(String botId, {String? conversationId}) async => VoiceSession(
        provider: VoiceSessionProviderEnum.openai,
        model: 'gpt-realtime-2.1',
        clientSecret: 'ek_test',
        expiresAt: DateTime.now().add(const Duration(minutes: 10)),
        connectUrl: 'https://example.invalid/v1/realtime/calls',
        conversationId: conversationId ?? convId,
        tools: 3,
      );

  @override
  Future<VoiceToolResult> voiceTool(String botId, String conversationId, String callId, String name, Map<String, Object?> arguments) async {
    voiceTools.add(name);
    return VoiceToolResult(status: VoiceToolResultStatusEnum.completed, runId: runId, output: 'Found 2 memories', approvalId: null);
  }

  @override
  Future<void> saveVoiceTranscript(String conversationId, List<(String, String)> turns, int seconds) async {
    savedTurns = turns;
    savedSeconds = seconds;
  }

  @override
  Future<void> updateBotVoice(String botId, Map<String, Object?> voice) async => botVoice = voice;

  // --- Phase 5 ---------------------------------------------------------------

  final createdComputers = <String>[];
  final computerUpdates = <String>[];
  final deletedComputers = <String>[];
  var leaseHeld = false;
  String? releasedNote;
  final dismissed = <String>[];
  List<TakeoverRequest> openTakeovers = [];

  Lease _lease() => Lease(
        computerId: computerId,
        holderType: leaseHeld ? LeaseHolderTypeEnum.user : LeaseHolderTypeEnum.bot,
        holderId: leaseHeld ? 'me' : null,
        mode: LeaseModeEnum.control,
        expiresAt: leaseHeld ? DateTime.now().add(const Duration(minutes: 15)) : null,
        you: leaseHeld,
      );

  @override
  Future<Computer> createComputer(String orgId, {required String name, required bool private, String? ownerBotId, String profile = 'headless'}) async {
    createdComputers.add('$name:$profile:$ownerBotId');
    return (await computers(orgId)).first;
  }

  @override
  Future<Computer> updateComputer(String computerId, {String? name, String? profile}) async {
    computerUpdates.add('${name ?? ''}${profile ?? ''}');
    return (await computers(orgId)).first;
  }

  @override
  Future<void> deleteComputer(String computerId) async => deletedComputers.add(computerId);
  @override
  Future<void> setBotComputer(String botId, String? computerId) async => defaultComputer = computerId;

  @override
  Future<StreamSession> streamSession(String computerId, {String mode = 'control'}) async => StreamSession(
        signalingUrl: 'ws://localhost/v1/computers/$computerId/stream?token=t',
        token: 't',
        mode: StreamMode.values.firstWhere((m) => m.value == mode),
        expiresAt: DateTime.now().add(const Duration(minutes: 5)),
        iceServers: [IceServer(urls: const ['turn:localhost:3478?transport=udp'], username: 'u', credential: 'c')],
        iceTransportPolicy: StreamSessionIceTransportPolicyEnum.relay,
        screenshotUrl: 'http://localhost/v1/computers/$computerId/screenshot',
      );

  @override
  Future<Lease> lease(String computerId) async => _lease();
  @override
  Future<Lease> takeLease(String computerId, {bool allowShell = false}) async {
    leaseHeld = true;
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
          state: ComputerState.sleeping,
          size: ComputerSize(cpus: 1),
          hasSnapshot: true,
          createdAt: DateTime(2026),
        ),
      ];
  @override
  Future<Computer> startComputer(String id) async => (await computers(orgId)).first;
  @override
  Future<Computer> stopComputer(String id) async => (await computers(orgId)).first;
  @override
  Future<List<ComputerFileEntry>> listFiles(String computerId, String path) async => const [];
  @override
  Future<Uint8List> downloadFile(String computerId, String path) async => uploads[path] ?? Uint8List.fromList(utf8.encode('# Hello\n\nfile $path'));
  @override
  Future<void> uploadFile(String computerId, String path, Uint8List bytes) async => uploads[path] = bytes;
  @override
  Future<void> deleteFile(String computerId, String path) async {}
  @override
  Future<List<Checkpoint>> checkpoints(String computerId) async => const [];
  @override
  Future<void> restoreCheckpoint(String computerId, String checkpointId) async {}
  @override
  Future<Uint8List?> screenshot(String computerId) async => null;
  @override
  Future<(Uri, Map<String, String>)> terminal(String computerId, {int cols = 100, int rows = 30}) async =>
      (Uri.parse('ws://localhost/terminal'), <String, String>{});
}


/// A connected ChatGPT plan owned by [owner] (the fake's user is 'me').
Credential chatGptCredential(String orgId,
        {String owner = 'me', CredentialStatus status = CredentialStatus.ok, bool fallbackOnLimit = false}) =>
    Credential(
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
  }) =>
      Task(
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
