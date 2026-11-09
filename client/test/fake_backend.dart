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
  Future<List<Credential>> credentials(String orgId) async => [
        Credential(id: 'cred', orgId: orgId, provider: ProviderId.openrouter, label: 'Main', baseUrl: null, keyHint: '1234', lastTestedAt: null, lastTestOk: null, createdAt: DateTime(2026)),
      ];
  @override
  Future<Credential> addCredential(String orgId, ProviderId provider, String label, {String? apiKey, String? baseUrl}) async =>
      throw UnimplementedError();
  @override
  Future<CredentialTestResult> testCredential(String credentialId, {String? model}) async =>
      CredentialTestResult(ok: true, model: 'm', latencyMs: 12);

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
        createdAt: DateTime(2026),
      );

  @override
  Future<List<Bot>> bots(String orgId) async => [bot()];
  @override
  Future<Bot> createBot(String orgId, {required String name, required String credentialId, required String model, String persona = ''}) async =>
      bot();
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
