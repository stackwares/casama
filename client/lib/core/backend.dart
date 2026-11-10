import 'dart:async';
import 'dart:typed_data';

import 'package:kasama_sdk/kasama_sdk.dart';

/// A message as shown in a conversation (final messages only; live text comes from run events).
/// A file attached to a message, stored on the bot's computer ([path] is under its home folder).
class AttachmentRef {
  const AttachmentRef({required this.path, required this.name, required this.mimeType, required this.size});
  final String path;
  final String name;
  final String mimeType;
  final int size;

  bool get isImage => mimeType.startsWith('image/');
}

/// An interactive UI a bot showed (D-086): one A2UI surface and the messages that build it.
class UiPart {
  const UiPart({required this.surfaceId, required this.messages});
  final String surfaceId;
  final List<Object?> messages;
}

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
  });
  final String id;
  final String role;
  final String text;
  final DateTime createdAt;
  final String? runId;
  final List<AttachmentRef> attachments;

  /// Interactive UIs in a bot's reply.
  final List<UiPart> ui;

  /// The bot UI this message answers, when it was sent from one.
  final String? uiActionSurface;
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

/// An authenticator app registered for two-step sign-in (D-092).
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
/// commands go to the Kasama API. Widget tests use a fake.
abstract class Backend {
  // Auth
  Stream<bool> get signedInChanges;
  bool get isSignedIn;
  String? get userEmail;
  String? get userId;
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
  /// Models the key can use, recommended first (live from the provider, or Kasama's short list).
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
  Future<Bot> createBot(String orgId,
      {required String name, required String credentialId, required String model, String persona, String? templateId, String? avatarUrl});
  Future<List<Template>> templates();
  /// [avatarUrl]: `mascot:<name>` for a cloud bot, '' to go back to initials, null to leave it.
  Future<void> updateBot(String botId, {String? name, String? persona, String? autonomy, Map<String, Object?>? modelPolicy, String? avatarUrl});
  Future<UsageReport> usage(String orgId, {String period});

  // Appearance
  /// Whether the server can search wallpaper photos (Unsplash; D-087).
  bool get wallpapersEnabled;
  Future<List<WallpaperPhoto>> searchWallpapers({String? query, int page = 1});
  /// Tells the photo source a photo was chosen.
  Future<void> trackWallpaperDownload(String downloadLocation);

  // Chat
  Future<List<Conversation>> conversations(String botId);
  Future<Conversation> createConversation(String botId);
  Future<List<ChatMessageView>> messages(String conversationId);
  Future<String?> activeRun(String conversationId);
  Future<SendMessageResponse> send(String conversationId, String text, {List<AttachmentRef> attachments = const [], Map<String, Object?>? uiAction});
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
  Future<void> markNotificationRead(String id);
  /// New notifications for the signed-in user, live.
  Stream<NotificationView> watchNotifications();
  Future<void> registerDevice(String platform, String token);

  // Routines
  Future<List<Routine>> routines(String botId);
  Future<CreatedRoutine> createRoutine(String botId,
      {required String name, required String instructions, required String trigger, String? cron, String? timezone, DateTime? runAt});
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

  // Privacy and SSO (Phase 8)
  Future<Uint8List> exportMyData();
  Future<AccountDeletion> deleteAccount(String confirmEmail);
  // Two-step sign-in (D-092)
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
