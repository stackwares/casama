import 'package:dio/dio.dart';
import 'dart:async';
import 'dart:typed_data';

import 'package:kasama_sdk/kasama_sdk.dart' hide AuthException;
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'backend.dart';

const _terminal = {'run.completed', 'run.failed', 'run.cancelled'};

/// Backend on Supabase (auth, reads, simple writes, Realtime) and the Kasama API (commands).
class SupabaseBackend implements Backend {
  SupabaseBackend(this.supabase, this.api, {this.config});

  final sb.SupabaseClient supabase;
  final KasamaClient api;
  final PublicConfig? config;

  /// Used when the server is older than the default-model setting (D-064).
  static const _fallbackModels = {'openrouter': 'openai/gpt-6-luna', 'openai': 'gpt-6-luna'};

  @override
  String? defaultModelFor(String provider) => config?.defaultModels[provider] ?? _fallbackModels[provider];

  /// How run events arrived (Realtime broadcast vs API catch-up); used by integration tests.
  int realtimeEvents = 0;
  int catchUpEvents = 0;

  /// Builds the API client so it always uses the current Supabase access token.
  static Future<KasamaClient> connectApi(String apiUrl, sb.SupabaseClient supabase) {
    return KasamaClient.connect(
      apiUrl,
      sessions: CallbackSessionStore(() async {
        final s = supabase.auth.currentSession;
        if (s == null) return null;
        return AuthSession(
          accessToken: s.accessToken,
          refreshToken: s.refreshToken ?? '',
          // supabase_flutter refreshes tokens itself; never ask the SDK to.
          expiresAt: DateTime.now().add(const Duration(days: 1)),
          userId: s.user.id,
          email: s.user.email,
        );
      }),
    );
  }

  // --- auth -----------------------------------------------------------------

  @override
  Stream<bool> get signedInChanges => supabase.auth.onAuthStateChange.map((e) => e.session != null);
  @override
  bool get isSignedIn => supabase.auth.currentSession != null;
  @override
  String? get userEmail => supabase.auth.currentUser?.email;

  @override
  Future<void> signIn(String email, String password) => supabase.auth.signInWithPassword(email: email, password: password);

  @override
  Future<bool> signUp(String email, String password) async {
    final r = await supabase.auth.signUp(email: email, password: password);
    return r.session != null;
  }

  @override
  Future<void> sendMagicLink(String email) => supabase.auth.signInWithOtp(email: email);

  @override
  Future<void> signInWithProvider(String provider) async {
    await supabase.auth.signInWithOAuth(provider == 'apple' ? sb.OAuthProvider.apple : sb.OAuthProvider.google);
  }

  @override
  Future<void> signOut() => supabase.auth.signOut();

  // --- workspaces -----------------------------------------------------------

  @override
  Future<List<OrganizationWithRole>> organizations() async => (await api.workspaces.listOrgs()).data!.items;

  @override
  Future<Organization> createOrganization(String name) async =>
      (await api.workspaces.createOrg(createOrganizationRequest: CreateOrganizationRequest(name: name))).data!;

  @override
  Future<void> acceptInvite(String token) async => api.workspaces.acceptInvite(token: token);

  @override
  Future<Invite> invite(String orgId, String email, {bool admin = false}) async => (await api.workspaces.createInvite(
        id: orgId,
        createInviteRequest: CreateInviteRequest(email: email, role: admin ? InviteRole.admin : InviteRole.member),
      ))
          .data!;

  // --- keys -----------------------------------------------------------------

  @override
  Future<List<Credential>> credentials(String orgId) async => (await api.credentials.listCredentials(orgId: orgId)).data!.items;

  @override
  Future<Credential> addCredential(String orgId, ProviderId provider, String label, {String? apiKey, String? baseUrl}) async =>
      (await api.credentials.createCredential(
        createCredentialRequest:
            CreateCredentialRequest(orgId: orgId, provider: provider, label: label, apiKey: apiKey, baseUrl: baseUrl),
      ))
          .data!;

  @override
  Future<CredentialTestResult> testCredential(String credentialId, {String? model}) async =>
      (await api.credentials.testCredential(id: credentialId, testCredentialRequest: TestCredentialRequest(model: model))).data!;

  @override
  Future<ModelOptionList> models(String credentialId) async =>
      (await api.credentials.listCredentialModels(id: credentialId)).data!;

  // --- bots -----------------------------------------------------------------

  @override
  Future<List<Bot>> bots(String orgId) async => (await api.bots.listBots(orgId: orgId)).data!.items;

  @override
  Future<Bot> createBot(String orgId,
          {required String name, required String credentialId, required String model, String persona = '', String? templateId}) async =>
      (await api.bots.createBot(
        createBotRequest: CreateBotRequest(
          orgId: orgId,
          name: name,
          personaMd: persona,
          modelPolicy: ModelPolicy(primary: ModelChoice(credentialId: credentialId, model: model)),
          templateId: templateId,
        ),
      ))
          .data!;

  @override
  Future<List<Template>> templates() async => (await api.bots.listTemplates()).data!.items;

  @override
  Future<void> updateBot(String botId, {String? name, String? persona, String? autonomy, Map<String, Object?>? modelPolicy}) async {
    await supabase.from('bots').update({
      'name': ?name,
      'persona_md': ?persona,
      'autonomy': ?autonomy,
      'model_policy': ?modelPolicy,
    }).eq('id', botId);
  }

  @override
  Future<UsageReport> usage(String orgId, {String period = 'day'}) async => (await api.usage.getUsage(orgId: orgId, period: period)).data!;

  // --- chat -----------------------------------------------------------------

  @override
  Future<List<Conversation>> conversations(String botId) async => (await api.chat.listConversations(id: botId)).data!.items;

  @override
  Future<Conversation> createConversation(String botId) async =>
      (await api.chat.createConversation(createConversationRequest: CreateConversationRequest(botId: botId))).data!;

  static String _text(Object? content) {
    if (content is! List) return '';
    return content.whereType<Map>().where((p) => p['type'] == 'text').map((p) => '${p['text'] ?? ''}').join();
  }

  static List<AttachmentRef> _files(Object? content) {
    if (content is! List) return const [];
    return [
      for (final p in content.whereType<Map>())
        if (p['type'] == 'file' && p['path'] is String)
          AttachmentRef(
            path: p['path'] as String,
            name: '${p['name'] ?? (p['path'] as String).split('/').last}',
            mimeType: '${p['mime_type'] ?? ''}',
            size: (p['size'] as num?)?.toInt() ?? 0,
          ),
    ];
  }
  static List<UiPart> _ui(Object? content) => content is! List
      ? const []
      : [
          for (final p in content.whereType<Map>())
            if (p['type'] == 'ui' && p['surface_id'] is String && p['messages'] is List)
              UiPart(surfaceId: p['surface_id'] as String, messages: List<Object?>.from(p['messages'] as List)),
        ];

  static String? _uiAction(Object? content) {
    if (content is! List) return null;
    for (final p in content.whereType<Map>()) {
      if (p['type'] == 'ui_action' && p['surface_id'] is String) return p['surface_id'] as String;
    }
    return null;
  }


  @override
  Future<List<ChatMessageView>> messages(String conversationId) async {
    final rows = await supabase
        .from('messages')
        .select('id, role, content, run_id, created_at')
        .eq('conversation_id', conversationId)
        .inFilter('role', ['user', 'assistant'])
        .order('created_at', ascending: true)
        .limit(500);
    return [
      for (final r in rows)
        ChatMessageView(
          id: r['id'] as String,
          role: r['role'] as String,
          text: _text(r['content']),
          createdAt: DateTime.parse(r['created_at'] as String),
          runId: r['run_id'] as String?,
          attachments: _files(r['content']),
          ui: _ui(r['content']),
          uiActionSurface: _uiAction(r['content']),
        ),
    ];
  }

  @override
  Future<String?> activeRun(String conversationId) async {
    final rows = await supabase
        .from('runs')
        .select('id')
        .eq('conversation_id', conversationId)
        .inFilter('status', ['queued', 'running', 'waiting_approval', 'waiting_takeover'])
        .order('created_at', ascending: false)
        .limit(1);
    return rows.isEmpty ? null : rows.first['id'] as String;
  }

  @override
  Future<SendMessageResponse> send(String conversationId, String text, {List<AttachmentRef> attachments = const [], Map<String, Object?>? uiAction}) async =>
      (await api.chat.sendMessage(
        id: conversationId,
        sendMessageRequest: SendMessageRequest(
          text: text,
          attachments: attachments.isEmpty
              ? null
              : [for (final a in attachments) MessageAttachment(path: a.path, name: a.name, mimeType: a.mimeType, size: a.size)],
          uiAction: uiAction == null
              ? null
              : UiActionPart(
                  surfaceId: '${uiAction['surface_id']}',
                  name: '${uiAction['name']}',
                  context: Map<String, Object?>.from(uiAction['context'] as Map? ?? const {}),
                ),
        ),
      ))
          .data!;

  @override
  Future<void> cancelRun(String runId) async => api.runs.cancelRun(id: runId);

  @override
  Future<List<RunEventItem>> runEvents(String runId, {int afterSeq = 0}) async {
    final page = (await api.runs.listRunEvents(id: runId, afterSeq: afterSeq, limit: 1000)).data!;
    return page.items.map((e) => RunEventItem.fromJson(e.toJson())).toList();
  }

  /// Live events: Realtime broadcasts on the private run:{id} topic, merged with catch-up from
  /// the API and ordered by seq. Gaps are filled from the API; ends after a terminal event.
  @override
  Stream<RunEventItem> watchRun(String runId, {int afterSeq = 0}) {
    final buffer = RunEventBuffer(lastSeq: afterSeq);
    late final StreamController<RunEventItem> out;
    sb.RealtimeChannel? channel;
    Timer? poll;
    var closed = false;
    var catchingUp = false;

    Future<void> close() async {
      if (closed) return;
      closed = true;
      poll?.cancel();
      if (channel != null) await supabase.removeChannel(channel!);
      await out.close();
    }

    void deliver(Iterable<RunEventItem> items) {
      for (final item in items) {
        for (final ready in buffer.add(item)) {
          if (closed) return;
          out.add(ready);
          if (_terminal.contains(ready.type)) {
            unawaited(close());
            return;
          }
        }
      }
    }

    Future<void> catchUp() async {
      if (catchingUp || closed) return;
      catchingUp = true;
      try {
        final items = await runEvents(runId, afterSeq: buffer.lastSeq);
        final before = buffer.lastSeq;
        deliver(items);
        catchUpEvents += buffer.lastSeq - before;
      } catch (_) {
        // Next poll retries.
      } finally {
        catchingUp = false;
      }
    }

    out = StreamController<RunEventItem>(
      onListen: () {
        channel = supabase
            .channel('run:$runId', opts: const sb.RealtimeChannelConfig(private: true))
            .onBroadcast(
              event: 'run_event',
              callback: (message) {
                final data = message['payload'] is Map ? message['payload'] as Map : message;
                try {
                  final before = buffer.lastSeq;
                  deliver([RunEventItem.fromJson(Map<String, dynamic>.from(data))]);
                  if (buffer.lastSeq > before) realtimeEvents++;
                } catch (_) {}
                if (buffer.hasGap) unawaited(catchUp());
              },
            )
            .subscribe((status, _) {
          if (status == sb.RealtimeSubscribeStatus.subscribed) unawaited(catchUp());
        });
        unawaited(catchUp());
        // Safety net when Realtime is unavailable or a broadcast was missed.
        poll = Timer.periodic(const Duration(seconds: 2), (_) => unawaited(catchUp()));
      },
      onCancel: close,
    );
    return out.stream;
  }

  @override
  Future<List<RunSummary>> runs(String botId) async {
    final rows = await supabase
        .from('runs')
        .select('id, status, trigger, created_at, cost_usd')
        .eq('bot_id', botId)
        .order('created_at', ascending: false)
        .limit(50);
    return [
      for (final r in rows)
        RunSummary(
          id: r['id'] as String,
          status: r['status'] as String,
          trigger: r['trigger'] as String,
          createdAt: DateTime.parse(r['created_at'] as String),
          costUsd: double.tryParse('${r['cost_usd']}') ?? 0,
        ),
    ];
  }

  // --- memory and skills ----------------------------------------------------

  @override
  Future<List<Memory>> memories(String botId) async => (await api.memory.listMemories(id: botId)).data!.items;

  @override
  Future<void> updateMemory(String id, {String? content, bool? pinned}) async {
    await supabase.from('memories').update({
      'content': ?content,
      'pinned': ?pinned,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', id);
  }

  @override
  Future<void> deleteMemory(String id) async => supabase.from('memories').delete().eq('id', id);

  @override
  Future<List<SkillView>> skills(String orgId) async {
    final rows = await supabase.from('skills').select().eq('org_id', orgId).order('name', ascending: true);
    return [
      for (final r in rows)
        SkillView(
          id: r['id'] as String,
          name: r['name'] as String,
          description: r['description'] as String,
          bodyMd: r['body_md'] as String,
          enabled: r['enabled'] as bool,
          botId: r['bot_id'] as String?,
        ),
    ];
  }

  @override
  Future<void> saveSkill(String orgId,
      {String? id, String? botId, required String name, required String description, required String bodyMd, bool enabled = true}) async {
    final row = {'org_id': orgId, 'bot_id': botId, 'name': name, 'description': description, 'body_md': bodyMd, 'enabled': enabled};
    if (id == null) {
      await supabase.from('skills').insert(row);
    } else {
      await supabase.from('skills').update(row).eq('id', id);
    }
  }

  @override
  Future<void> deleteSkill(String id) async => supabase.from('skills').delete().eq('id', id);

  // --- approvals and notifications ------------------------------------------

  @override
  Future<List<Approval>> approvals(String orgId, {bool pendingOnly = true}) async =>
      (await api.approvals.listApprovals(orgId: orgId, status: pendingOnly ? 'pending' : null)).data!.items;

  @override
  Future<Approval> decideApproval(String approvalId, {required bool approve, bool alwaysAllow = false}) async =>
      (await api.approvals.decideApproval(
        id: approvalId,
        approvalDecisionRequest: ApprovalDecisionRequest(
          decision: approve ? ApprovalDecisionRequestDecisionEnum.approved : ApprovalDecisionRequestDecisionEnum.denied,
          alwaysAllow: approve && alwaysAllow ? true : null,
        ),
      ))
          .data!;

  static NotificationView _notification(Map row) {
    final payload = row['payload'] is Map ? row['payload'] as Map : const {};
    return NotificationView(
      id: row['id'] as String,
      kind: row['kind'] as String,
      title: '${payload['title'] ?? ''}',
      body: '${payload['body'] ?? ''}',
      link: payload['link'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
      readAt: row['read_at'] == null ? null : DateTime.parse(row['read_at'] as String),
    );
  }

  @override
  Future<List<NotificationView>> notifications() async {
    final rows = await supabase
        .from('notifications')
        .select('id, kind, payload, read_at, created_at')
        .order('created_at', ascending: false)
        .limit(100);
    return [for (final r in rows) _notification(r)];
  }

  @override
  Future<void> markNotificationsRead() async {
    await supabase.from('notifications').update({'read_at': DateTime.now().toUtc().toIso8601String()}).isFilter('read_at', null);
  }

  @override
  Future<void> markNotificationRead(String id) async {
    await supabase.from('notifications').update({'read_at': DateTime.now().toUtc().toIso8601String()}).eq('id', id).isFilter('read_at', null);
  }

  @override
  Stream<NotificationView> watchNotifications() {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return const Stream.empty();
    late final StreamController<NotificationView> out;
    sb.RealtimeChannel? channel;
    out = StreamController<NotificationView>(
      onListen: () {
        channel = supabase
            .channel('user:$userId', opts: const sb.RealtimeChannelConfig(private: true))
            .onBroadcast(
              event: 'notification',
              callback: (message) {
                final data = message['payload'] is Map ? message['payload'] as Map : message;
                try {
                  out.add(_notification(data));
                } catch (_) {}
              },
            )
            .subscribe();
      },
      onCancel: () async {
        if (channel != null) await supabase.removeChannel(channel!);
      },
    );
    return out.stream;
  }

  @override
  Future<void> registerDevice(String platform, String token) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;
    await supabase.from('devices').upsert(
      {'user_id': userId, 'platform': platform, 'fcm_token': token, 'last_seen_at': DateTime.now().toUtc().toIso8601String()},
      onConflict: 'fcm_token',
    );
  }

  // --- routines -------------------------------------------------------------

  @override
  Future<List<Routine>> routines(String botId) async => (await api.routines.listRoutines(id: botId)).data!.items;

  @override
  Future<CreatedRoutine> createRoutine(String botId,
          {required String name, required String instructions, required String trigger, String? cron, String? timezone, DateTime? runAt}) async =>
      (await api.routines.createRoutine(
        createRoutineRequest: CreateRoutineRequest(
          botId: botId,
          name: name,
          instructions: instructions,
          trigger: RoutineTrigger.values.firstWhere((t) => t.value == trigger),
          scheduleCron: trigger == 'schedule' ? cron : null,
          runAt: trigger == 'once' ? runAt?.toUtc() : null,
          timezone: timezone,
        ),
      ))
          .data!;

  @override
  Future<void> deleteRoutine(String routineId) async => api.routines.deleteRoutine(id: routineId);

  @override
  Future<void> setRoutineEnabled(String routineId, bool enabled) async =>
      api.routines.updateRoutine(id: routineId, updateRoutineRequest: UpdateRoutineRequest(enabled: enabled));

  @override
  Future<String> runRoutine(String routineId) async => (await api.routines.runRoutine(id: routineId)).data!.runId;

  // --- integrations and secrets ---------------------------------------------

  @override
  Future<List<Integration>> integrations(String orgId) async => (await api.integrations.listIntegrations(orgId: orgId)).data!.items;

  @override
  Future<Integration> createIntegration(String orgId,
          {required String kind, required String name, required Map<String, Object?> config, String? secret}) async =>
      (await api.integrations.createIntegration(
        createIntegrationRequest: CreateIntegrationRequest(
          orgId: orgId,
          kind: IntegrationKind.values.firstWhere((k) => k.value == kind),
          name: name,
          config: config,
          secret: secret,
        ),
      ))
          .data!;

  @override
  Future<IntegrationTestResult> testIntegration(String integrationId) async =>
      (await api.integrations.testIntegration(id: integrationId)).data!;

  @override
  Future<Set<String>> botIntegrationIds(String botId) async {
    final rows = await supabase.from('bot_integrations').select('integration_id').eq('bot_id', botId);
    return {for (final r in rows) r['integration_id'] as String};
  }

  @override
  Future<void> setBotIntegration(String botId, String integrationId, bool enabled) async {
    if (enabled) {
      await api.integrations.attachIntegration(id: botId, attachIntegrationRequest: AttachIntegrationRequest(integrationId: integrationId));
    } else {
      await supabase.from('bot_integrations').delete().eq('bot_id', botId).eq('integration_id', integrationId);
    }
  }

  @override
  Future<List<Secret>> secrets(String orgId) async => (await api.secrets.listSecrets(orgId: orgId)).data!.items;

  @override
  Future<void> createSecret(String orgId, {required String name, required String value, required List<String> hosts}) async =>
      api.secrets.createSecret(createSecretRequest: CreateSecretRequest(orgId: orgId, name: name, value: value, allowedHosts: hosts));

  @override
  Future<void> deleteSecret(String secretId) async => api.secrets.deleteSecret(id: secretId);

  // --- task board -----------------------------------------------------------

  @override
  Future<List<Task>> tasks(String orgId) async => (await api.tasks.listTasks(orgId: orgId)).data!.items;

  @override
  Future<void> setTaskStatus(String taskId, String status) async {
    await supabase
        .from('tasks')
        .update({'status': status, 'updated_at': DateTime.now().toUtc().toIso8601String()}).eq('id', taskId);
  }

  // --- owner admin console (Phase 6) ---------------------------------------

  @override
  Future<AdminOverview?> adminOverview() async {
    try {
      return (await api.admin.adminOverview()).data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) return null;
      rethrow;
    }
  }

  @override
  Future<List<AdminUser>> adminUsers() async => (await api.admin.adminUsers()).data!.items;
  @override
  Future<List<AdminOrg>> adminOrgs() async => (await api.admin.adminOrgs()).data!.items;
  @override
  Future<AdminOrg> setOrgLimits(String orgId, Map<String, num> limits) async =>
      (await api.admin.setOrgLimits(id: orgId, setOrgLimitsRequest: SetOrgLimitsRequest(limits: limits))).data!;
  @override
  Future<List<AdminService>> adminServices() async => (await api.admin.adminServices()).data!.items;
  @override
  Future<UpdateNotice> adminUpdates() async => (await api.admin.adminUpdates()).data!;

  // --- privacy and SSO (Phase 8) ------------------------------------------

  @override
  Future<Uint8List> exportMyData() async => (await api.privacy.exportMyData()).data!;
  @override
  Future<AccountDeletion> deleteAccount(String confirmEmail) async {
    final r = (await api.privacy.deleteMyAccount(deleteAccountRequest: DeleteAccountRequest(confirmEmail: confirmEmail))).data!;
    await supabase.auth.signOut().catchError((_) {});
    return r;
  }

  @override
  Future<int> retentionDays(String orgId) async => (await api.privacy.getOrgSettings(id: orgId)).data!.runEventRetentionDays;
  @override
  Future<int> setRetentionDays(String orgId, int days) async => (await api.privacy.updateOrgSettings(
        id: orgId,
        updateOrgSettingsRequest: UpdateOrgSettingsRequest(runEventRetentionDays: days),
      ))
          .data!
          .runEventRetentionDays;
  @override
  Future<void> signInWithSso(String email) async {
    await supabase.auth.signInWithSSO(domain: email.split('@').last.trim().toLowerCase());
  }

  // --- billing (Phase 7) ---------------------------------------------------

  @override
  Future<BillingSummary> billing(String orgId) async => (await api.billing.getBilling(id: orgId)).data!;
  @override
  Future<PlanCatalog> plans() async => (await api.billing.listPlans()).data!;
  @override
  Future<String> checkoutUrl(String orgId, {String? planCode, String? packCode}) async =>
      (await api.billing.createCheckout(id: orgId, checkoutRequest: CheckoutRequest(planCode: planCode, packCode: packCode)))
          .data!
          .url;
  @override
  Future<String> billingPortalUrl(String orgId) async =>
      (await api.billing.billingPortal(id: orgId, portalRequest: PortalRequest())).data!.url;
  @override
  Future<BillingSummary> verifyPurchase(String orgId,
          {required String source, required String productId, String? transactionId, String? purchaseToken}) async =>
      (await api.billing.verifyPurchase(
        id: orgId,
        purchaseRequest: PurchaseRequest(
          source_: source == 'app_store' ? PurchaseRequestSource_Enum.appStore : PurchaseRequestSource_Enum.googlePlay,
          productId: productId,
          transactionId: transactionId,
          purchaseToken: purchaseToken,
        ),
      ))
          .data!;
  @override
  Future<BillingUsage> billingUsage(String orgId) async => (await api.billing.billingUsage(id: orgId)).data!;
  @override
  Future<List<ConnectKey>> connectKeys(String orgId) async => (await api.billing.listConnectKeys(id: orgId)).data!.items;
  @override
  Future<CreatedConnectKey> createConnectKey(String orgId, String instanceName) async =>
      (await api.billing.createConnectKey(id: orgId, createConnectKeyRequest: CreateConnectKeyRequest(instanceName: instanceName)))
          .data!;
  @override
  Future<void> revokeConnectKey(String orgId, String keyId) => api.billing.revokeConnectKey(id: orgId, keyId: keyId);

  // --- desktop companion (Phase 6) -----------------------------------------

  @override
  String get apiUrl => api.baseUrl;

  @override
  Future<List<LocalDevice>> localDevices(String orgId) async => (await api.localComputer.listLocalDevices(orgId: orgId)).data!.items;

  @override
  Future<CreatedLocalDevice> createLocalDevice(String orgId, String name, String platform) async => (await api.localComputer.createLocalDevice(
        createLocalDeviceRequest: CreateLocalDeviceRequest(
          orgId: orgId,
          name: name,
          platform: CreateLocalDeviceRequestPlatformEnum.values.firstWhere((p) => p.value == platform),
        ),
      ))
          .data!;

  @override
  Future<LocalDevice> updateLocalDevice(String id, {Set<String>? capabilities, List<String>? roots, List<String>? botIds, bool? enabled}) async =>
      (await api.localComputer.updateLocalDevice(
        id: id,
        updateLocalDeviceRequest: UpdateLocalDeviceRequest(
          capabilities: capabilities == null
              ? null
              : LocalCapabilities(
                  shell: capabilities.contains('shell'),
                  files: capabilities.contains('files'),
                  browser: capabilities.contains('browser'),
                  desktop: capabilities.contains('desktop'),
                ),
          allowedRoots: roots,
          allowedBotIds: botIds,
          enabled: enabled,
        ),
      ))
          .data!;

  @override
  Future<void> deleteLocalDevice(String id) async => api.localComputer.deleteLocalDevice(id: id);

  // --- voice (Phase 6) -------------------------------------------------------

  @override
  Future<String> transcribe(String botId, Uint8List audio, String mime) async => (await api.transcribe(botId, audio, mime: mime)).text;

  @override
  Future<Uint8List> speech(String messageId) async => (await api.voice.messageSpeech(id: messageId)).data!;

  @override
  Future<VoiceSession> voiceSession(String botId, {String? conversationId}) async =>
      (await api.voice.createVoiceSession(voiceSessionRequest: VoiceSessionRequest(botId: botId, conversationId: conversationId))).data!;

  @override
  Future<VoiceToolResult> voiceTool(String botId, String conversationId, String callId, String name, Map<String, Object?> arguments) async =>
      (await api.voice.voiceTool(
        voiceToolRequest: VoiceToolRequest(botId: botId, conversationId: conversationId, callId: callId, name: name, arguments: arguments),
      ))
          .data!;

  @override
  Future<void> saveVoiceTranscript(String conversationId, List<(String, String)> turns, int seconds) async =>
      api.voice.saveVoiceTranscript(
        voiceTranscriptRequest: VoiceTranscriptRequest(
          conversationId: conversationId,
          seconds: seconds,
          turns: [
            for (final (role, text) in turns)
              VoiceTranscriptRequestTurnsInner(role: VoiceTranscriptRequestTurnsInnerRoleEnum.values.firstWhere((r) => r.value == role), text: text),
          ],
        ),
      );

  @override
  Future<void> updateBotVoice(String botId, Map<String, Object?> voice) async {
    await supabase.from('bots').update({'voice': voice}).eq('id', botId);
  }

  // --- computer management and live view (Phase 5) -------------------------

  @override
  Future<Computer> createComputer(String orgId, {required String name, required bool private, String? ownerBotId, String profile = 'headless'}) async =>
      (await api.computers.createComputer(
        createComputerRequest: CreateComputerRequest(
          orgId: orgId,
          name: name,
          kind: private ? CreateComputerRequestKindEnum.private : CreateComputerRequestKindEnum.team,
          ownerBotId: ownerBotId,
          profile: CreateComputerRequestProfileEnum.values.firstWhere((p) => p.value == profile),
        ),
      ))
          .data!;

  @override
  Future<Computer> updateComputer(String computerId, {String? name, String? profile}) async => (await api.computers.updateComputer(
        id: computerId,
        updateComputerRequest: UpdateComputerRequest(
          name: name,
          profile: profile == null ? null : UpdateComputerRequestProfileEnum.values.firstWhere((p) => p.value == profile),
        ),
      ))
          .data!;

  @override
  Future<void> deleteComputer(String computerId) async => api.computers.deleteComputer(id: computerId);

  @override
  Future<void> setBotComputer(String botId, String? computerId) async {
    await supabase.from('bots').update({'default_computer_id': computerId}).eq('id', botId);
  }

  @override
  Future<StreamSession> streamSession(String computerId, {String mode = 'control'}) async => (await api.computers.createStreamSession(
        id: computerId,
        streamSessionRequest: StreamSessionRequest(mode: StreamMode.values.firstWhere((m) => m.value == mode)),
      ))
          .data!;

  @override
  Future<Lease> lease(String computerId) async => (await api.computers.getLease(id: computerId)).data!;

  @override
  Future<Lease> takeLease(String computerId, {bool allowShell = false}) async =>
      (await api.computers.takeLease(id: computerId, takeLeaseRequest: TakeLeaseRequest(allowShell: allowShell))).data!;

  @override
  Future<Lease> releaseLease(String computerId, {String? note}) async =>
      (await api.computers.releaseLease(id: computerId, releaseLeaseRequest: ReleaseLeaseRequest(note: note))).data!;

  @override
  Future<List<TakeoverRequest>> takeovers(String orgId) async => (await api.computers.listTakeovers(orgId: orgId)).data!.items;

  @override
  Future<void> dismissTakeover(String takeoverId, {String? note}) async =>
      api.computers.dismissTakeover(id: takeoverId, releaseLeaseRequest: ReleaseLeaseRequest(note: note));

  // --- computers ------------------------------------------------------------

  @override
  Future<List<Computer>> computers(String orgId) async => (await api.computers.listComputers(orgId: orgId)).data!.items;

  @override
  Future<Computer> startComputer(String id) async => (await api.computers.startComputer(id: id)).data!;

  @override
  Future<Computer> stopComputer(String id) async => (await api.computers.stopComputer(id: id)).data!;

  @override
  Future<List<ComputerFileEntry>> listFiles(String computerId, String path) async =>
      (await api.computers.listComputerFiles(id: computerId, path: path.isEmpty ? null : path)).data!.entries;

  @override
  Future<Uint8List> downloadFile(String computerId, String path) async =>
      Uint8List.fromList(await api.downloadComputerFile(computerId, path));

  @override
  Future<void> uploadFile(String computerId, String path, Uint8List bytes) async => api.uploadComputerFile(computerId, path, bytes);

  @override
  Future<void> deleteFile(String computerId, String path) async => api.computers.deleteComputerFile(id: computerId, path: path);

  @override
  Future<List<Checkpoint>> checkpoints(String computerId) async => (await api.computers.listCheckpoints(id: computerId)).data!.items;

  @override
  Future<void> restoreCheckpoint(String computerId, String checkpointId) async =>
      api.computers.restoreCheckpoint(id: computerId, cid: checkpointId);

  @override
  Future<Uint8List?> screenshot(String computerId) async {
    try {
      return (await api.computers.computerScreenshot(id: computerId)).data;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<(Uri, Map<String, String>)> terminal(String computerId, {int cols = 100, int rows = 30}) async {
    final (uri, headers) = await api.terminalEndpoint(computerId, cols: cols, rows: rows);
    // Browsers cannot set WebSocket headers, so the token also travels as a query parameter.
    final token = supabase.auth.currentSession?.accessToken;
    return (uri.replace(queryParameters: {...uri.queryParameters, 'access_token': ?token}), headers);
  }
}
