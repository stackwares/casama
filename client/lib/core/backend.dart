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
  Future<Bot> createBot(String orgId, {required String name, required String credentialId, required String model, String persona});
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
