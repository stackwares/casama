//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

import 'package:dio/dio.dart';
import 'package:kasama_api/src/auth/api_key_auth.dart';
import 'package:kasama_api/src/auth/basic_auth.dart';
import 'package:kasama_api/src/auth/bearer_auth.dart';
import 'package:kasama_api/src/auth/oauth.dart';
import 'package:kasama_api/src/api/action_rules_api.dart';
import 'package:kasama_api/src/api/admin_api.dart';
import 'package:kasama_api/src/api/appearance_api.dart';
import 'package:kasama_api/src/api/approvals_api.dart';
import 'package:kasama_api/src/api/billing_api.dart';
import 'package:kasama_api/src/api/bots_api.dart';
import 'package:kasama_api/src/api/channels_api.dart';
import 'package:kasama_api/src/api/chat_api.dart';
import 'package:kasama_api/src/api/checkins_api.dart';
import 'package:kasama_api/src/api/computers_api.dart';
import 'package:kasama_api/src/api/credentials_api.dart';
import 'package:kasama_api/src/api/files_api.dart';
import 'package:kasama_api/src/api/import_api.dart';
import 'package:kasama_api/src/api/integrations_api.dart';
import 'package:kasama_api/src/api/knowledge_api.dart';
import 'package:kasama_api/src/api/local_computer_api.dart';
import 'package:kasama_api/src/api/mcp_api.dart';
import 'package:kasama_api/src/api/memory_api.dart';
import 'package:kasama_api/src/api/pages_api.dart';
import 'package:kasama_api/src/api/password_managers_api.dart';
import 'package:kasama_api/src/api/plugins_api.dart';
import 'package:kasama_api/src/api/privacy_api.dart';
import 'package:kasama_api/src/api/projects_api.dart';
import 'package:kasama_api/src/api/replays_api.dart';
import 'package:kasama_api/src/api/routines_api.dart';
import 'package:kasama_api/src/api/runs_api.dart';
import 'package:kasama_api/src/api/search_api.dart';
import 'package:kasama_api/src/api/secrets_api.dart';
import 'package:kasama_api/src/api/skills_api.dart';
import 'package:kasama_api/src/api/system_api.dart';
import 'package:kasama_api/src/api/tasks_api.dart';
import 'package:kasama_api/src/api/teach_api.dart';
import 'package:kasama_api/src/api/usage_api.dart';
import 'package:kasama_api/src/api/voice_api.dart';
import 'package:kasama_api/src/api/watchers_api.dart';
import 'package:kasama_api/src/api/webhooks_api.dart';
import 'package:kasama_api/src/api/workspaces_api.dart';

class KasamaApi {
  static const String basePath = r'http://localhost:8787';

  final Dio dio;
  KasamaApi({
    Dio? dio,
    String? basePathOverride,
    List<Interceptor>? interceptors,
  })  : 
        this.dio = dio ??
            Dio(BaseOptions(
              baseUrl: basePathOverride ?? basePath,
              connectTimeout: const Duration(milliseconds: 5000),
              receiveTimeout: const Duration(milliseconds: 3000),
            )) {
    if (interceptors == null) {
      this.dio.interceptors.addAll([
        OAuthInterceptor(),
        BasicAuthInterceptor(),
        BearerAuthInterceptor(),
        ApiKeyAuthInterceptor(),
      ]);
    } else {
      this.dio.interceptors.addAll(interceptors);
    }
  }

  void setOAuthToken(String name, String token) {
    if (this.dio.interceptors.any((i) => i is OAuthInterceptor)) {
      (this.dio.interceptors.firstWhere((i) => i is OAuthInterceptor) as OAuthInterceptor).tokens[name] = token;
    }
  }

  void setBearerAuth(String name, String token) {
    if (this.dio.interceptors.any((i) => i is BearerAuthInterceptor)) {
      (this.dio.interceptors.firstWhere((i) => i is BearerAuthInterceptor) as BearerAuthInterceptor).tokens[name] = token;
    }
  }

  void setBasicAuth(String name, String username, String password) {
    if (this.dio.interceptors.any((i) => i is BasicAuthInterceptor)) {
      (this.dio.interceptors.firstWhere((i) => i is BasicAuthInterceptor) as BasicAuthInterceptor).authInfo[name] = BasicAuthInfo(username, password);
    }
  }

  void setApiKey(String name, String apiKey) {
    if (this.dio.interceptors.any((i) => i is ApiKeyAuthInterceptor)) {
      (this.dio.interceptors.firstWhere((element) => element is ApiKeyAuthInterceptor) as ApiKeyAuthInterceptor).apiKeys[name] = apiKey;
    }
  }

  /// Get ActionRulesApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  ActionRulesApi getActionRulesApi() {
    return ActionRulesApi(dio);
  }

  /// Get AdminApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  AdminApi getAdminApi() {
    return AdminApi(dio);
  }

  /// Get AppearanceApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  AppearanceApi getAppearanceApi() {
    return AppearanceApi(dio);
  }

  /// Get ApprovalsApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  ApprovalsApi getApprovalsApi() {
    return ApprovalsApi(dio);
  }

  /// Get BillingApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  BillingApi getBillingApi() {
    return BillingApi(dio);
  }

  /// Get BotsApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  BotsApi getBotsApi() {
    return BotsApi(dio);
  }

  /// Get ChannelsApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  ChannelsApi getChannelsApi() {
    return ChannelsApi(dio);
  }

  /// Get ChatApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  ChatApi getChatApi() {
    return ChatApi(dio);
  }

  /// Get CheckinsApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  CheckinsApi getCheckinsApi() {
    return CheckinsApi(dio);
  }

  /// Get ComputersApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  ComputersApi getComputersApi() {
    return ComputersApi(dio);
  }

  /// Get CredentialsApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  CredentialsApi getCredentialsApi() {
    return CredentialsApi(dio);
  }

  /// Get FilesApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  FilesApi getFilesApi() {
    return FilesApi(dio);
  }

  /// Get ImportApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  ImportApi getImportApi() {
    return ImportApi(dio);
  }

  /// Get IntegrationsApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  IntegrationsApi getIntegrationsApi() {
    return IntegrationsApi(dio);
  }

  /// Get KnowledgeApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  KnowledgeApi getKnowledgeApi() {
    return KnowledgeApi(dio);
  }

  /// Get LocalComputerApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  LocalComputerApi getLocalComputerApi() {
    return LocalComputerApi(dio);
  }

  /// Get McpApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  McpApi getMcpApi() {
    return McpApi(dio);
  }

  /// Get MemoryApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  MemoryApi getMemoryApi() {
    return MemoryApi(dio);
  }

  /// Get PagesApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  PagesApi getPagesApi() {
    return PagesApi(dio);
  }

  /// Get PasswordManagersApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  PasswordManagersApi getPasswordManagersApi() {
    return PasswordManagersApi(dio);
  }

  /// Get PluginsApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  PluginsApi getPluginsApi() {
    return PluginsApi(dio);
  }

  /// Get PrivacyApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  PrivacyApi getPrivacyApi() {
    return PrivacyApi(dio);
  }

  /// Get ProjectsApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  ProjectsApi getProjectsApi() {
    return ProjectsApi(dio);
  }

  /// Get ReplaysApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  ReplaysApi getReplaysApi() {
    return ReplaysApi(dio);
  }

  /// Get RoutinesApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  RoutinesApi getRoutinesApi() {
    return RoutinesApi(dio);
  }

  /// Get RunsApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  RunsApi getRunsApi() {
    return RunsApi(dio);
  }

  /// Get SearchApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  SearchApi getSearchApi() {
    return SearchApi(dio);
  }

  /// Get SecretsApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  SecretsApi getSecretsApi() {
    return SecretsApi(dio);
  }

  /// Get SkillsApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  SkillsApi getSkillsApi() {
    return SkillsApi(dio);
  }

  /// Get SystemApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  SystemApi getSystemApi() {
    return SystemApi(dio);
  }

  /// Get TasksApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  TasksApi getTasksApi() {
    return TasksApi(dio);
  }

  /// Get TeachApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  TeachApi getTeachApi() {
    return TeachApi(dio);
  }

  /// Get UsageApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  UsageApi getUsageApi() {
    return UsageApi(dio);
  }

  /// Get VoiceApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  VoiceApi getVoiceApi() {
    return VoiceApi(dio);
  }

  /// Get WatchersApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  WatchersApi getWatchersApi() {
    return WatchersApi(dio);
  }

  /// Get WebhooksApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  WebhooksApi getWebhooksApi() {
    return WebhooksApi(dio);
  }

  /// Get WorkspacesApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  WorkspacesApi getWorkspacesApi() {
    return WorkspacesApi(dio);
  }
}
