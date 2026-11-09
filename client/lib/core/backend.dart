import 'dart:async';
import 'dart:typed_data';

import 'package:kasama_sdk/kasama_sdk.dart';

/// A message as shown in a conversation (final messages only; live text comes from run events).
class ChatMessageView {
  const ChatMessageView({required this.id, required this.role, required this.text, required this.createdAt, this.runId});
  final String id;
  final String role;
  final String text;
  final DateTime createdAt;
  final String? runId;
}

class SkillView {
  const SkillView({
    required this.id,
    required this.name,
    required this.description,
    required this.bodyMd,
    required this.enabled,
    this.botId,
  });
  final String id;
  final String name;
  final String description;
  final String bodyMd;
  final bool enabled;
  final String? botId;
}

class NotificationView {
  const NotificationView({required this.id, required this.kind, required this.title, required this.body, this.link, required this.createdAt, this.readAt});
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

/// Everything the app reads and writes. Reads and simple edits go to Supabase under RLS;
/// commands go to the Kasama API. Widget tests use a fake.
abstract class Backend {
  // Auth
  Stream<bool> get signedInChanges;
  bool get isSignedIn;
  String? get userEmail;
  Future<void> signIn(String email, String password);
  Future<bool> signUp(String email, String password);
  Future<void> sendMagicLink(String email);
  Future<void> signInWithProvider(String provider);
  Future<void> signOut();

  /// The server's default model for a provider (GPT-6 Luna on OpenRouter and OpenAI), if any.
  String? defaultModelFor(String provider);

  // Workspaces
  Future<List<OrganizationWithRole>> organizations();
  Future<Organization> createOrganization(String name);
  Future<void> acceptInvite(String token);
  Future<Invite> invite(String orgId, String email, {bool admin = false});

  // Model keys
  Future<List<Credential>> credentials(String orgId);
  Future<Credential> addCredential(String orgId, ProviderId provider, String label, {String? apiKey, String? baseUrl});
  Future<CredentialTestResult> testCredential(String credentialId, {String? model});

  // Bots
  Future<List<Bot>> bots(String orgId);
  Future<Bot> createBot(String orgId, {required String name, required String credentialId, required String model, String persona, String? templateId});
  Future<List<Template>> templates();
  Future<void> updateBot(String botId, {String? name, String? persona, String? autonomy});
  Future<UsageReport> usage(String orgId, {String period});

  // Chat
  Future<List<Conversation>> conversations(String botId);
  Future<Conversation> createConversation(String botId);
  Future<List<ChatMessageView>> messages(String conversationId);
  Future<String?> activeRun(String conversationId);
  Future<SendMessageResponse> send(String conversationId, String text);
  Future<void> cancelRun(String runId);
  Stream<RunEventItem> watchRun(String runId, {int afterSeq = 0});
  Future<List<RunEventItem>> runEvents(String runId);
  Future<List<RunSummary>> runs(String botId);

  // Memory and skills
  Future<List<Memory>> memories(String botId);
  Future<void> updateMemory(String id, {String? content, bool? pinned});
  Future<void> deleteMemory(String id);
  Future<List<SkillView>> skills(String orgId);
  Future<void> saveSkill(String orgId, {String? id, String? botId, required String name, required String description, required String bodyMd, bool enabled = true});
  Future<void> deleteSkill(String id);

  // Approvals and notifications
  Future<List<Approval>> approvals(String orgId, {bool pendingOnly = true});
  Future<Approval> decideApproval(String approvalId, {required bool approve, bool alwaysAllow = false});
  Future<List<NotificationView>> notifications();
  Future<void> markNotificationsRead();
  /// New notifications for the signed-in user, live.
  Stream<NotificationView> watchNotifications();
  Future<void> registerDevice(String platform, String token);

  // Routines
  Future<List<Routine>> routines(String botId);
  Future<CreatedRoutine> createRoutine(String botId, {required String name, required String instructions, required String trigger, String? cron, String? timezone});
  Future<void> setRoutineEnabled(String routineId, bool enabled);
  Future<String> runRoutine(String routineId);

  // Integrations and secrets
  Future<List<Integration>> integrations(String orgId);
  Future<Integration> createIntegration(String orgId, {required String kind, required String name, required Map<String, Object?> config, String? secret});
  Future<IntegrationTestResult> testIntegration(String integrationId);
  Future<Set<String>> botIntegrationIds(String botId);
  Future<void> setBotIntegration(String botId, String integrationId, bool enabled);
  Future<List<Secret>> secrets(String orgId);
  Future<void> createSecret(String orgId, {required String name, required String value, required List<String> hosts});
  Future<void> deleteSecret(String secretId);

  // Task board
  Future<List<Task>> tasks(String orgId);
  Future<void> setTaskStatus(String taskId, String status);

  // Owner admin console (Phase 6). Null when the user is not the instance owner.
  Future<AdminOverview?> adminOverview();
  Future<List<AdminUser>> adminUsers();
  Future<List<AdminOrg>> adminOrgs();
  Future<AdminOrg> setOrgLimits(String orgId, Map<String, num> limits);
  Future<List<AdminService>> adminServices();
  Future<UpdateNotice> adminUpdates();

  // Billing (Phase 7). `BillingSummary.enabled` is false on self-hosted servers (no paywall).
  Future<BillingSummary> billing(String orgId);
  Future<PlanCatalog> plans();
  Future<String> checkoutUrl(String orgId, {String? planCode, String? packCode});
  Future<String> billingPortalUrl(String orgId);
  Future<BillingSummary> verifyPurchase(String orgId,
      {required String source, required String productId, String? transactionId, String? purchaseToken});
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
  Future<void> deleteLocalDevice(String id);

  // Voice (Phase 6)
  Future<String> transcribe(String botId, Uint8List audio, String mime);
  Future<Uint8List> speech(String messageId);
  Future<VoiceSession> voiceSession(String botId, {String? conversationId});
  Future<VoiceToolResult> voiceTool(String botId, String conversationId, String callId, String name, Map<String, Object?> arguments);
  Future<void> saveVoiceTranscript(String conversationId, List<(String, String)> turns, int seconds);
  Future<void> updateBotVoice(String botId, Map<String, Object?> voice);

  // Computers: management (Phase 5)
  Future<Computer> createComputer(String orgId, {required String name, required bool private, String? ownerBotId, String profile});
  Future<Computer> updateComputer(String computerId, {String? name, String? profile});
  Future<void> deleteComputer(String computerId);
  Future<void> setBotComputer(String botId, String? computerId);

  // Live view and take control (Phase 5)
  Future<StreamSession> streamSession(String computerId, {String mode});
  Future<Lease> lease(String computerId);
  Future<Lease> takeLease(String computerId, {bool allowShell});
  Future<Lease> releaseLease(String computerId, {String? note});
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
