import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:kasama_api/kasama_api.dart';

import 'auth.dart';
import 'signup_proof.dart';

/// Stores and loads a session (file for the CLI, secure storage for the app).
abstract interface class SessionStore {
  Future<AuthSession?> load();
  Future<void> save(AuthSession session);
  Future<void> clear();
}

/// Session store backed by another auth library (the app uses supabase_flutter, which refreshes tokens itself).
class CallbackSessionStore implements SessionStore {
  CallbackSessionStore(this.loader);
  final Future<AuthSession?> Function() loader;
  @override
  Future<AuthSession?> load() => loader();
  @override
  Future<void> save(AuthSession session) async {}
  @override
  Future<void> clear() async {}
}

class MemorySessionStore implements SessionStore {
  AuthSession? _session;
  @override
  Future<AuthSession?> load() async => _session;
  @override
  Future<void> save(AuthSession session) async => _session = session;
  @override
  Future<void> clear() async => _session = null;
}

/// Entry point: holds the API client and keeps the bearer token fresh.
class KasamaClient {
  KasamaClient._(this.baseUrl, this.api, this.config, this.auth, this.sessions);

  final String baseUrl;
  final KasamaApi api;
  final PublicConfig config;
  final AuthClient auth;
  final SessionStore sessions;

  /// Connects to an API server and loads its public configuration.
  static Future<KasamaClient> connect(String baseUrl, {SessionStore? sessions}) async {
    final dio = Dio(BaseOptions(baseUrl: baseUrl, connectTimeout: const Duration(seconds: 10), receiveTimeout: const Duration(seconds: 60)));
    final api = KasamaApi(dio: dio, interceptors: const []);
    final config = (await api.getSystemApi().getConfig()).data!;
    final auth = AuthClient(supabaseUrl: config.supabaseUrl, anonKey: config.supabaseAnonKey);
    final client = KasamaClient._(baseUrl, api, config, auth, sessions ?? MemorySessionStore());
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final secure = options.extra['secure'];
          if (secure is List && secure.isNotEmpty) {
            final session = await client.currentSession();
            if (session != null) options.headers['Authorization'] = 'Bearer ${session.accessToken}';
          }
          handler.next(options);
        },
      ),
    );
    return client;
  }

  WorkspacesApi get workspaces => api.getWorkspacesApi();
  SystemApi get system => api.getSystemApi();
  BotsApi get bots => api.getBotsApi();
  ChatApi get chat => api.getChatApi();
  RunsApi get runs => api.getRunsApi();
  CredentialsApi get credentials => api.getCredentialsApi();
  MemoryApi get memory => api.getMemoryApi();
  UsageApi get usage => api.getUsageApi();
  ComputersApi get computers => api.getComputersApi();
  ApprovalsApi get approvals => api.getApprovalsApi();
  IntegrationsApi get integrations => api.getIntegrationsApi();
  RoutinesApi get routines => api.getRoutinesApi();
  SecretsApi get secrets => api.getSecretsApi();
  TasksApi get tasks => api.getTasksApi();
  VoiceApi get voice => api.getVoiceApi();
  LocalComputerApi get localComputer => api.getLocalComputerApi();
  AdminApi get admin => api.getAdminApi();
  SearchApi get search => api.getSearchApi();
  SkillsApi get skills => api.getSkillsApi();
  ProjectsApi get projects => api.getProjectsApi();
  CheckinsApi get checkins => api.getCheckinsApi();
  ActionRulesApi get actionRules => api.getActionRulesApi();
  WatchersApi get watchers => api.getWatchersApi();
  PagesApi get pages => api.getPagesApi();
  TeachApi get teach => api.getTeachApi();
  PluginsApi get plugins => api.getPluginsApi();
  ImportApi get imports => api.getImportApi();
  FilesApi get files => api.getFilesApi();
  KnowledgeApi get knowledge => api.getKnowledgeApi();
  ChannelsApi get channels => api.getChannelsApi();
  EncryptionApi get encryption => api.getEncryptionApi();
  ReplaysApi get replays => api.getReplaysApi();
  PasswordManagersApi get passwordManagers => api.getPasswordManagersApi();
  McpApi get mcp => api.getMcpApi();

  /// Wallpaper photo search, when the server has a photo source (D-087).
  AppearanceApi get appearance => api.getAppearanceApi();

  /// Plans, entitlements, purchases and Cloud Connect keys (Phase 7).
  BillingApi get billing => api.getBillingApi();

  /// Data export, account deletion and workspace retention (Phase 8).
  PrivacyApi get privacy => api.getPrivacyApi();

  Future<Map<String, String>> _authHeader() async {
    final session = await currentSession();
    return {if (session != null) 'authorization': 'Bearer ${session.accessToken}'};
  }

  /// Uploads raw bytes to a path in a computer.
  Future<UploadResult> uploadComputerFile(String computerId, String path, List<int> bytes) async {
    final res = await api.dio.put<Map<String, dynamic>>(
      '/v1/computers/$computerId/files',
      queryParameters: {'path': path},
      data: Stream.fromIterable([bytes]),
      options: Options(headers: {...await _authHeader(), 'content-type': 'application/octet-stream', 'content-length': bytes.length}),
    );
    return UploadResult.fromJson(res.data!);
  }

  /// Dictation: sends a recording and returns its text (uses the org's own speech-to-text key).
  Future<Transcription> transcribe(String botId, List<int> audio, {required String mime, String? language}) async {
    final res = await api.dio.post<Map<String, dynamic>>(
      '/v1/voice/transcribe',
      queryParameters: {'bot_id': botId, 'language': ?language},
      data: Stream.fromIterable([audio]),
      options: Options(headers: {...await _authHeader(), 'content-type': mime, 'content-length': audio.length}),
    );
    return Transcription.fromJson(res.data!);
  }

  /// Downloads a file from a computer.
  Future<List<int>> downloadComputerFile(String computerId, String path) async {
    final res = await api.dio.get<List<int>>(
      '/v1/computers/$computerId/files',
      queryParameters: {'path': path},
      options: Options(responseType: ResponseType.bytes, headers: await _authHeader()),
    );
    return res.data!;
  }

  /// WebSocket URL and headers for a computer's interactive terminal.
  Future<(Uri, Map<String, String>)> terminalEndpoint(String computerId, {int cols = 120, int rows = 32}) async {
    final base = Uri.parse(baseUrl);
    final uri = base.replace(scheme: base.scheme == 'https' ? 'wss' : 'ws', path: '/v1/computers/$computerId/terminal', queryParameters: {'cols': '$cols', 'rows': '$rows'});
    return (uri, await _authHeader());
  }

  /// Returns the stored session, refreshing it when it is about to expire.
  Future<AuthSession?> currentSession() async {
    final session = await sessions.load();
    if (session == null || !session.isExpired) return session;
    final refreshed = await auth.refresh(session.refreshToken);
    await sessions.save(refreshed);
    return refreshed;
  }

  Future<AuthSession> signIn(String email, String password) async {
    final session = await auth.signInWithPassword(email: email, password: password);
    await sessions.save(session);
    return session;
  }

  /// Signs up, carrying a sign-up proof when the server asks for one (D-094).
  Future<AuthSession?> signUp(String email, String password) async {
    final proof = await signupProof(api, config);
    final session = await auth.signUp(email: email, password: password, data: proof == null ? null : {'signup_proof': proof});
    if (session != null) await sessions.save(session);
    return session;
  }

  Future<void> signOut() => sessions.clear();
}

/// Extracts the problem+json body from a failed API call, if any.
Problem? problemOf(Object error) {
  if (error is DioException) {
    var data = error.response?.data;
    // Binary endpoints (audio, files) receive the error body as bytes or text; decode it too.
    if (data is List<int>) {
      try {
        data = utf8.decode(data);
      } catch (_) {}
    }
    if (data is String && data.startsWith('{')) {
      try {
        data = jsonDecode(data);
      } catch (_) {}
    }
    if (data is Map<String, dynamic> && data['code'] is String) {
      try {
        return Problem.fromJson(data);
      } catch (_) {}
    }
  }
  return null;
}
