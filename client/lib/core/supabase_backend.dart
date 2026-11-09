import 'dart:async';
import 'dart:typed_data';

import 'package:kasama_sdk/kasama_sdk.dart' hide AuthException;
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'backend.dart';

const _terminal = {'run.completed', 'run.failed', 'run.cancelled'};

/// Backend on Supabase (auth, reads, simple writes, Realtime) and the Kasama API (commands).
class SupabaseBackend implements Backend {
  SupabaseBackend(this.supabase, this.api);

  final sb.SupabaseClient supabase;
  final KasamaClient api;

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

  // --- bots -----------------------------------------------------------------

  @override
  Future<List<Bot>> bots(String orgId) async => (await api.bots.listBots(orgId: orgId)).data!.items;

  @override
  Future<Bot> createBot(String orgId, {required String name, required String credentialId, required String model, String persona = ''}) async =>
      (await api.bots.createBot(
        createBotRequest: CreateBotRequest(
          orgId: orgId,
          name: name,
          personaMd: persona,
          modelPolicy: ModelPolicy(primary: ModelChoice(credentialId: credentialId, model: model)),
        ),
      ))
          .data!;

  @override
  Future<void> updateBot(String botId, {String? name, String? persona, String? autonomy}) async {
    await supabase.from('bots').update({
      'name': ?name,
      'persona_md': ?persona,
      'autonomy': ?autonomy,
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
  Future<SendMessageResponse> send(String conversationId, String text) async =>
      (await api.chat.sendMessage(id: conversationId, sendMessageRequest: SendMessageRequest(text: text))).data!;

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
