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
          name: 'Test Org',
          slug: 'test-org',
          plan: 'selfhost',
          region: 'local',
          createdAt: DateTime(2026),
          role: OrgRole.owner,
        ),
      ];
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
        Credential(id: 'cred', orgId: orgId, provider: ProviderId.openrouter, label: 'Main', baseUrl: null, keyHint: '1234', lastTestedAt: null, lastTestOk: null, createdAt: DateTime(2026)),
      ];
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

  Bot bot({BotStatusEnum status = BotStatusEnum.idle}) => Bot(
        id: botId,
        orgId: orgId,
        name: 'Ada',
        avatarUrl: null,
        personaMd: '',
        modelPolicy: ModelPolicy(primary: ModelChoice(credentialId: 'cred', model: 'fixture')),
        autonomy: Autonomy.askRisky,
        visibility: Visibility.team,
        budget: BotBudget(perRunUsd: 1, dailyUsd: 10),
        status: status,
        defaultComputerId: defaultComputer,
        createdAt: DateTime(2026),
      );

  String? defaultComputer;

  @override
  Future<List<Bot>> bots(String orgId) async => [bot()];
  @override
  Future<Bot> createBot(String orgId,
      {required String name, required String credentialId, required String model, String persona = '', String? templateId}) async {
    createdBotTemplate = templateId;
    createdBot = (name: name, model: model);
    return bot();
  }

  String? createdBotTemplate;
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
  Future<void> updateBot(String botId, {String? name, String? persona, String? autonomy}) async {}
  @override
  Future<UsageReport> usage(String orgId, {String period = 'day'}) async => UsageReport(
        period: period == 'day' ? UsageReportPeriodEnum.day : UsageReportPeriodEnum.month,
        since: DateTime(2026),
        totalCostUsd: 0.0123,
        byBot: [UsageReportByBotInner(botId: botId, name: 'Ada', costUsd: 0.0123, tokensIn: 1000, tokensOut: 200)],
      );

  @override
  Future<List<Conversation>> conversations(String botId) async =>
      [Conversation(id: convId, botId: botId, title: 'Hello', lastMessageAt: null, createdAt: DateTime(2026))];
  @override
  Future<Conversation> createConversation(String botId) async => Conversation(id: convId, botId: botId, title: null, lastMessageAt: null, createdAt: DateTime(2026));
  @override
  Future<List<ChatMessageView>> messages(String conversationId) async => storedMessages;
  @override
  Future<String?> activeRun(String conversationId) async => null;
  @override
  Future<SendMessageResponse> send(String conversationId, String text) async {
    sent.add(text);
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
  Future<List<SkillView>> skills(String orgId) async => const [];
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
  final taskStatus = <String, String>{};

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
      {required String name, required String instructions, required String trigger, String? cron, String? timezone}) async {
    final r = CreatedRoutine(
      id: 'r${routineList.length + 1}',
      botId: botId,
      name: name,
      instructionsMd: instructions,
      scheduleCron: cron,
      timezone: timezone ?? 'America/Chicago',
      trigger: RoutineTrigger.values.firstWhere((t) => t.value == trigger),
      notify: true,
      enabled: true,
      nextRunAt: trigger == 'schedule' ? DateTime(2026, 11, 11, 7) : null,
      lastRunAt: null,
      conversationId: null,
      createdAt: DateTime.now(),
      webhookUrl: trigger == 'schedule' ? null : 'http://localhost/hooks/custom/r1',
      webhookSecret: trigger == 'schedule' ? null : 'whsec_test',
    );
    routineList.add(Routine.fromJson(r.toJson()));
    return r;
  }

  @override
  Future<void> setRoutineEnabled(String routineId, bool enabled) async {}
  @override
  Future<String> runRoutine(String routineId) async {
    routinesRun.add(routineId);
    return runId;
  }

  @override
  Future<List<Integration>> integrations(String orgId) async => integrationList;
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

  @override
  Future<List<Secret>> secrets(String orgId) async => secretList;
  @override
  Future<void> createSecret(String orgId, {required String name, required String value, required List<String> hosts}) async =>
      secretList.add(Secret(id: 's${secretList.length + 1}', orgId: orgId, name: name, allowedHosts: hosts, allowedBotIds: null, createdAt: DateTime.now()));
  @override
  Future<void> deleteSecret(String secretId) async => secretList.removeWhere((s) => s.id == secretId);

  @override
  Future<List<Task>> tasks(String orgId) async => [
        Task(
          id: 't1',
          title: 'Summarize the release notes',
          detailsMd: '',
          status: TaskStatusEnum.values.firstWhere((s) => s.value == (taskStatus['t1'] ?? 'todo')),
          assigneeBotId: botId,
          createdByBotId: botId,
          resultMd: null,
          updatedAt: DateTime.now(),
        ),
      ];
  @override
  Future<void> setTaskStatus(String taskId, String status) async => taskStatus[taskId] = status;

  // --- Phase 6: admin -------------------------------------------------------

  var isOwner = true;
  Map<String, num>? setLimits;

  @override
  Future<AdminOverview?> adminOverview() async => isOwner
      ? AdminOverview(version: '0.6.0', users: 3, orgs: 2, bots: 4, runs24h: 12, failedRuns24h: 1, cost24hUsd: 0.42, computersRunning: 1, devicesOnline: 1)
      : null;
  @override
  Future<List<AdminUser>> adminUsers() async => [AdminUser(id: 'u1', email: 'owner@example.com', createdAt: DateTime(2026), lastSignInAt: null, orgs: 1)];
  AdminOrg _org(Map<String, num> limits) =>
      AdminOrg(id: orgId, name: 'Test Org', planCode: 'selfhost', limits: limits, members: 2, bots: 1, cost30dUsd: 1.5);
  @override
  Future<List<AdminOrg>> adminOrgs() async => [_org(setLimits ?? const {})];
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
            ),
      roots: roots,
      bots: botIds,
      enabled: enabled,
    );
    return device!;
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
  Future<Uint8List> downloadFile(String computerId, String path) async => Uint8List(0);
  @override
  Future<void> uploadFile(String computerId, String path, Uint8List bytes) async {}
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
