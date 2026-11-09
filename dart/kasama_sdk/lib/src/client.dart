import 'package:dio/dio.dart';
import 'package:kasama_api/kasama_api.dart';

import 'auth.dart';

/// Stores and loads a session (file for the CLI, secure storage for the app).
abstract interface class SessionStore {
  Future<AuthSession?> load();
  Future<void> save(AuthSession session);
  Future<void> clear();
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
    final dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 60),
    ));
    final api = KasamaApi(dio: dio, interceptors: const []);
    final config = (await api.getSystemApi().getConfig()).data!;
    final auth = AuthClient(supabaseUrl: config.supabaseUrl, anonKey: config.supabaseAnonKey);
    final client = KasamaClient._(baseUrl, api, config, auth, sessions ?? MemorySessionStore());
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) async {
      final secure = options.extra['secure'];
      if (secure is List && secure.isNotEmpty) {
        final session = await client.currentSession();
        if (session != null) options.headers['Authorization'] = 'Bearer ${session.accessToken}';
      }
      handler.next(options);
    }));
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

  Future<AuthSession?> signUp(String email, String password) async {
    final session = await auth.signUp(email: email, password: password);
    if (session != null) await sessions.save(session);
    return session;
  }

  Future<void> signOut() => sessions.clear();
}

/// Extracts the problem+json body from a failed API call, if any.
Problem? problemOf(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map<String, dynamic> && data['code'] is String) {
      try {
        return Problem.fromJson(data);
      } catch (_) {}
    }
  }
  return null;
}
