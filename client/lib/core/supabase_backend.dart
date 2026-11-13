import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

import 'dart:async';

import 'package:casama_sdk/casama_sdk.dart' hide AuthException, GalleryItem;
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:url_launcher/url_launcher.dart';

import 'apple_sign_in.dart';
import 'desktop_sign_in.dart';
import 'google_sign_in.dart';
import 'passkeys.dart';
import 'web_auth_sheet.dart';
import 'backend.dart';
import 'chatgpt_connect.dart';

const _terminal = {'run.completed', 'run.failed', 'run.cancelled'};
const _finishedStatus = {RunStatus.completed, RunStatus.failed, RunStatus.cancelled};

/// Backend on Supabase (auth, reads, simple writes, Realtime) and the Casama API (commands).
class SupabaseBackend implements Backend {
  SupabaseBackend(this.supabase, this.api, {this.config}) {
    // A reset link or code signs in with a passwordRecovery event: ask for a new password.
    supabase.auth.onAuthStateChange.listen((e) {
      if (e.event == sb.AuthChangeEvent.passwordRecovery) {
        _setNewPasswordNeeded(true);
      }
      if (e.event == sb.AuthChangeEvent.signedOut) _setNewPasswordNeeded(false);
    });
  }

  final sb.SupabaseClient supabase;
  final CasamaClient api;

  /// The server's public settings: saved ones at launch, replaced once the server's arrive (D-158).
  PublicConfig? config;

  /// Used when the server is older than the default-model setting (D-064).
  static const _fallbackModels = {
    'openrouter': 'deepseek/deepseek-v4.1-flash-1017',
    'openai': 'gpt-6-luna',
  };

  @override
  String? defaultModelFor(String provider) =>
      config?.defaultModels[provider] ?? _fallbackModels[provider];

  /// How run events arrived (Realtime broadcast vs API catch-up); used by integration tests.
  int realtimeEvents = 0;
  int catchUpEvents = 0;

  /// Builds the API client so it always uses the current Supabase access token.
  /// Pass the [config] already loaded from this server, so it isn't fetched a second time.
  static Future<CasamaClient> connectApi(
    String apiUrl,
    sb.SupabaseClient supabase, {
    PublicConfig? config,
  }) {
    return CasamaClient.connect(
      apiUrl,
      config: config,
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
  Stream<bool> get signedInChanges =>
      supabase.auth.onAuthStateChange.map((e) => e.session != null);
  @override
  bool get isSignedIn => supabase.auth.currentSession != null;
  @override
  String? get userEmail => supabase.auth.currentUser?.email;

  @override
  String? get userId => supabase.auth.currentUser?.id;

  /// Where sign-in emails and Google, Apple and SSO send people back to: the app itself (the
  /// casama:// scheme, which Supabase picks up), or on the web the site they came from (the
  /// server's site address would be the marketing page, not the web app).
  static const authRedirect = 'casama://app/login-callback';
  static String? get _authRedirect => kIsWeb ? Uri.base.origin : authRedirect;

  @override
  Future<void> signIn(String email, String password) =>
      supabase.auth.signInWithPassword(email: email, password: password);

  /// A sign-up proof when the server asks for one (D-094); the puzzle runs off the UI thread.
  Future<Map<String, Object?>?> _signupData() async {
    final proof = await signupProof(
      api.api,
      config ?? api.config,
      solve: (c, d) => compute(_solvePuzzle, (c, d)),
    );
    return proof == null ? null : {'signup_proof': proof};
  }

  @override
  Future<bool> signUp(String email, String password) async {
    final r = await supabase.auth.signUp(
      email: email,
      password: password,
      data: await _signupData(),
      emailRedirectTo: _authRedirect,
    );
    return r.session != null;
  }

  @override
  Future<void> sendMagicLink(String email) async => supabase.auth.signInWithOtp(
    email: email,
    data: await _signupData(),
    emailRedirectTo: _authRedirect,
  );

  @override
  Future<void> verifyEmailCode(String email, String code) => supabase.auth
      .verifyOTP(email: email, token: code.trim(), type: sb.OtpType.email);

  @override
  Future<void> signInWithProvider(String provider) async {
    // iOS and macOS use Apple's system sheet. If that sheet isn't available (Apple grants it to the
    // Mac App Store build and signed development builds, never a Developer ID one), the web flow
    // still works: in the sign-in window on macOS, in the browser elsewhere.
    if (provider == 'apple' &&
        nativeAppleSignIn &&
        await _signInWithAppleNative()) {
      return;
    }
    // Android, iOS and macOS use Google's own sheet when this server accepts the app's client id.
    if (provider == 'google' && await _signInWithGoogleNative()) return;
    final oauthProvider = provider == 'apple'
        ? sb.OAuthProvider.apple
        : sb.OAuthProvider.google;
    if (_loopback) {
      return _signInThroughLoopback(
        (redirect) async => (await supabase.auth.getOAuthSignInUrl(
          provider: oauthProvider,
          redirectTo: redirect,
        )).url,
      );
    }
    if (webAuthSheetPlatform && await _signInThroughSheet(oauthProvider)) {
      return;
    }
    final opened = await supabase.auth.signInWithOAuth(
      oauthProvider,
      redirectTo: _authRedirect,
      // The default on iOS is the system Safari sheet. A casama:// return leaves that sheet on a
      // blank page, and closeInAppWebView cannot dismiss it. The in-app web view can be closed.
      authScreenLaunchMode:
          !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS
          ? LaunchMode.inAppWebView
          : LaunchMode.platformDefault,
    );
    if (opened && !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      _closeSheetOnSignIn();
    }
  }

  /// macOS: the sign-in page in the system's sign-in window over the app, which hands the
  /// casama:// link straight back. True when it finished (signed in, or the person closed it).
  /// False when the window couldn't open, so the caller opens the browser instead.
  Future<bool> _signInThroughSheet(sb.OAuthProvider provider) async {
    final url = (await supabase.auth.getOAuthSignInUrl(
      provider: provider,
      redirectTo: authRedirect,
    )).url;
    final Uri? callback;
    try {
      callback = await openWebAuthSheet(Uri.parse(url), scheme: 'casama');
    } on WebAuthUnavailable {
      return false;
    } on PlatformException catch (e) {
      throw sb.AuthException(e.message ?? 'The sign-in window closed with an error.');
    }
    if (callback == null) return true;
    final result = oauthCallbackResult(callback);
    if (result.code == null) throw sb.AuthException(result.error!);
    await supabase.auth.exchangeCodeForSession(result.code!);
    return true;
  }

  /// Windows and Linux don't open casama:// links, so the browser comes back to 127.0.0.1.
  static bool get _loopback => !kIsWeb && loopbackSignInPlatform;

  /// Opens the browser at the sign-in page [signInUrl] builds for the loopback address, then
  /// returns: the listener finishes the sign-in in the background (the code is swapped for a
  /// session, which signs the app in), so the buttons don't stay busy if the person gives up.
  Future<void> _signInThroughLoopback(
    Future<String> Function(String redirect) signInUrl,
  ) async {
    final loopback = await LoopbackSignIn.start();
    try {
      final url = Uri.parse(await signInUrl(loopback.redirectUrl));
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw const sb.AuthException('Could not open the browser.');
      }
    } catch (_) {
      await loopback.close();
      rethrow;
    }
    unawaited(
      loopback.wait((query) async {
        final code = query['code'];
        if (code == null) {
          return query['error_description'] ??
              query['error'] ??
              'The sign-in page did not send a sign-in code.';
        }
        try {
          await supabase.auth.exchangeCodeForSession(code);
          return null;
        } on sb.AuthException catch (e) {
          return e.message;
        }
      }),
    );
  }

  /// The casama:// link back signs the person in, but the in-app page stays up blank, so close it
  /// once the session arrives. Gives up after a few minutes so an abandoned sign-in leaves nothing
  /// listening.
  void _closeSheetOnSignIn() {
    late final StreamSubscription<sb.AuthState> sub;
    final timer = Timer(const Duration(minutes: 5), () => sub.cancel());
    sub = supabase.auth.onAuthStateChange.listen((e) {
      if (e.event != sb.AuthChangeEvent.signedIn) return;
      timer.cancel();
      sub.cancel();
      closeInAppWebView();
    });
  }

  /// True when the system sheet finished (signed in, or the person cancelled). False when the
  /// sheet never opened, so the caller opens the browser instead.
  Future<bool> _signInWithAppleNative() async {
    if (!await SignInWithApple.isAvailable()) return false;
    final rawNonce = supabase.auth.generateRawNonce();
    final AuthorizationCredentialAppleID credential;
    try {
      credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: appleNonceHash(rawNonce),
      );
    } on SignInWithAppleAuthorizationException catch (error) {
      if (error.code == AuthorizationErrorCode.canceled) return true;
      if (appleSheetUnavailable(error)) return false;
      rethrow;
    } on SignInWithAppleNotSupportedException {
      return false;
    }
    final idToken = credential.identityToken;
    if (idToken == null) {
      throw const sb.AuthException(
        'Apple did not return a sign-in token. Try again.',
      );
    }
    await supabase.auth.signInWithIdToken(
      provider: sb.OAuthProvider.apple,
      idToken: idToken,
      nonce: rawNonce,
    );
    await _saveAppleName(credential.givenName, credential.familyName);
    return true;
  }

  /// Google's SDK may be set up only once per launch, so its nonce and client are too. Supabase
  /// checks the raw nonce against the hash inside each ID token.
  static String? _googleRawNonce;
  static String? _googleClient;
  static Future<void>? _googleSetUp;

  Future<void> _setUpGoogle(String client) => _googleSetUp ??= () async {
    final raw = _googleRawNonce = supabase.auth.generateRawNonce();
    _googleClient = client;
    final android = defaultTargetPlatform == TargetPlatform.android;
    await GoogleSignIn.instance.initialize(
      clientId: android ? null : client,
      serverClientId: android ? client : null,
      nonce: appleNonceHash(raw),
    );
  }();

  /// True when Google's sheet finished (signed in, or the person cancelled). False when this
  /// platform or server can't use it, or it failed on its own, so the caller opens the browser.
  Future<bool> _signInWithGoogleNative() async {
    final client = googleNativeClient(
      defaultTargetPlatform,
      config?.googleClientIds ?? const [],
    );
    if (client == null) return false;
    // Set up for another server's client earlier in this launch: its token would be refused here.
    if (_googleClient != null && _googleClient != client) return false;
    final String? idToken;
    try {
      await _setUpGoogle(client);
      if (!GoogleSignIn.instance.supportsAuthenticate()) return false;
      final account = await GoogleSignIn.instance.authenticate();
      idToken = account.authentication.idToken;
    } on GoogleSignInException catch (error) {
      if (googleSheetUnavailable(error)) return false;
      return true;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
    if (idToken == null) {
      throw const sb.AuthException(
        'Google did not return a sign-in token. Try again.',
      );
    }
    await supabase.auth.signInWithIdToken(
      provider: sb.OAuthProvider.google,
      idToken: idToken,
      nonce: _googleRawNonce,
    );
    return true;
  }

  /// Apple sends the name once, on the first authorization, and not inside the token. Saving it
  /// must not turn a finished sign-in into an error; the profile copies it from this metadata.
  Future<void> _saveAppleName(String? given, String? family) async {
    final name = appleFullName(given, family);
    if (name == null) return;
    try {
      await supabase.auth.updateUser(
        sb.UserAttributes(
          data: {
            'full_name': name,
            'display_name': name,
            if (given != null && given.trim().isNotEmpty)
              'given_name': given.trim(),
            if (family != null && family.trim().isNotEmpty)
              'family_name': family.trim(),
          },
        ),
      );
    } catch (_) {
      // Already signed in. If this write fails, the profile keeps the email prefix.
    }
  }

  @override
  Future<void> signOut() async {
    // Forget the Google account too, so the next Continue with Google offers every account.
    if (_googleSetUp != null) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {}
    }
    await supabase.auth.signOut();
  }

  /// The Auth server's public settings say which sign-ins are on (SAML SSO, passkeys).
  @override
  Future<AuthMethods> authMethods() async {
    final authUrl = supabase.rest.url.replaceFirst(
      RegExp(r'/rest/v1/?$'),
      '/auth/v1',
    );
    final r = await Dio(BaseOptions(connectTimeout: const Duration(seconds: 10), receiveTimeout: const Duration(seconds: 15))).get<Map<String, dynamic>>(
      '$authUrl/settings',
      options: Options(headers: supabase.headers),
    );
    final s = r.data ?? const {};
    return AuthMethods(
      sso: s['saml_enabled'] == true,
      passkeys: s['passkeys_enabled'] == true && passkeysSupportedHere,
    );
  }

  // --- password and email ---------------------------------------------------

  @override
  Future<void> sendPasswordReset(String email) =>
      supabase.auth.resetPasswordForEmail(email, redirectTo: _authRedirect);

  @override
  Future<void> verifyPasswordResetCode(String email, String code) => supabase
      .auth
      .verifyOTP(email: email, token: code.trim(), type: sb.OtpType.recovery);

  var _newPasswordNeeded = false;
  final _newPasswordChanges = StreamController<bool>.broadcast();
  void _setNewPasswordNeeded(bool v) {
    if (_newPasswordNeeded == v) return;
    _newPasswordNeeded = v;
    _newPasswordChanges.add(v);
  }

  @override
  bool get newPasswordNeeded => _newPasswordNeeded;
  @override
  Stream<bool> get newPasswordNeededChanges => _newPasswordChanges.stream;
  @override
  void skipNewPassword() => _setNewPasswordNeeded(false);

  @override
  Future<void> setPassword(String password, {String? code}) async {
    try {
      await supabase.auth.updateUser(
        sb.UserAttributes(password: password, nonce: code?.trim()),
      );
    } on sb.AuthException catch (e) {
      if (e.code == sb.ErrorCode.reauthenticationNeeded.code) {
        throw const ReauthenticationNeeded();
      }
      rethrow;
    }
    _setNewPasswordNeeded(false);
  }

  @override
  Future<void> sendReauthenticationCode() => supabase.auth.reauthenticate();

  @override
  String? get pendingEmail => supabase.auth.currentUser?.newEmail;

  @override
  Future<void> changeEmail(String email) => supabase.auth.updateUser(
    sb.UserAttributes(email: email.trim()),
    emailRedirectTo: _authRedirect,
  );

  @override
  Future<void> signOutEverywhere() =>
      supabase.auth.signOut(scope: sb.SignOutScope.global);

  // --- passkeys ---------------------------------------------------------------

  final _passkeySheet = PasskeyCeremony();

  // Supabase marks its passkey API beta (D-183); everything that touches it goes through here.
  // ignore: experimental_member_use
  sb.GoTruePasskeyApi get _passkeyApi => supabase.auth.passkey;

  @override
  Future<bool> signInWithPasskey() async {
    final start = await _passkeyApi.startAuthentication();
    final credential = await _passkeySheet.get(start.options);
    if (credential == null) return false;
    await _passkeyApi.verifyAuthentication(
      challengeId: start.challengeId,
      credential: credential,
    );
    return true;
  }

  @override
  Future<List<PasskeyInfo>> passkeys() async => [
    for (final p in await _passkeyApi.list())
      PasskeyInfo(
        id: p.id,
        name: p.friendlyName ?? 'Passkey',
        createdAt: p.createdAt,
        lastUsedAt: p.lastUsedAt,
      ),
  ];

  @override
  Future<bool> addPasskey() async {
    final start = await _passkeyApi.startRegistration(friendlyName: userEmail);
    final credential = await _passkeySheet.create(start.options);
    if (credential == null) return false;
    await _passkeyApi.verifyRegistration(
      challengeId: start.challengeId,
      credential: credential,
    );
    return true;
  }

  @override
  Future<void> renamePasskey(String id, String name) =>
      _passkeyApi.update(passkeyId: id, friendlyName: name);

  @override
  Future<void> removePasskey(String id) => _passkeyApi.delete(passkeyId: id);

  // --- workspaces -----------------------------------------------------------

  @override
  Future<List<OrganizationWithRole>> organizations() async =>
      (await api.workspaces.listOrgs()).data!.items;

  @override
  Future<Organization> createOrganization(String name) async =>
      (await api.workspaces.createOrg(
        createOrganizationRequest: CreateOrganizationRequest(name: name),
      )).data!;

  @override
  Future<void> acceptInvite(String token) async =>
      api.workspaces.acceptInvite(token: token);

  @override
  Future<Organization> updateOrg(
    String orgId, {
    String? name,
    String? icon,
    String? color,
  }) async => (await api.workspaces.updateOrg(
    id: orgId,
    updateOrganizationRequest: UpdateOrganizationRequest(
      name: name,
      icon: icon,
      color: color,
    ),
  )).data!;
  @override
  Future<List<InviteLink>> inviteLinks(String orgId) async =>
      (await api.workspaces.listInviteLinks(id: orgId)).data!.items;
  @override
  Future<CreatedInviteLink> createInviteLink(
    String orgId, {
    String role = 'member',
    int? expiresInDays,
    int? maxUses,
  }) async => (await api.workspaces.createInviteLink(
    id: orgId,
    createInviteLinkRequest: CreateInviteLinkRequest(
      role: CreateInviteLinkRequestRoleEnum.values.firstWhere(
        (r) => r.value == role,
      ),
      expiresInDays: expiresInDays,
      maxUses: maxUses,
    ),
  )).data!;
  @override
  Future<void> revokeInviteLink(String orgId, String linkId) async =>
      api.workspaces.revokeInviteLink(id: orgId, linkId: linkId);
  @override
  Future<OrganizationWithRole> acceptInviteLink(String token) async =>
      (await api.workspaces.acceptInviteLink(token: token)).data!;
  @override
  Future<List<WorkspaceBadge>> workspaceBadges() async =>
      (await api.workspaces.workspaceBadges()).data!.items;

  @override
  Future<Invite> invite(
    String orgId,
    String email, {
    bool admin = false,
  }) async => (await api.workspaces.createInvite(
    id: orgId,
    createInviteRequest: CreateInviteRequest(
      email: email,
      role: admin ? InviteRole.admin : InviteRole.member,
    ),
  )).data!;

  // --- joining (D-165) ------------------------------------------------------

  @override
  Future<CreatedInviteLink> defaultInvite(String orgId) async =>
      (await api.workspaces.getDefaultInvite(id: orgId)).data!;
  @override
  Future<CreatedInviteLink> updateDefaultInvite(
    String orgId, {
    bool? requiresApproval,
    bool reset = false,
  }) async => (await api.workspaces.updateDefaultInvite(
    id: orgId,
    updateDefaultInviteRequest: UpdateDefaultInviteRequest(
      requiresApproval: requiresApproval,
      reset: reset ? true : null,
    ),
  )).data!;
  @override
  Future<CreatedInviteLink> createInviteCode(
    String orgId, {
    String role = 'member',
  }) async => (await api.workspaces.createInviteCode(
    id: orgId,
    createInviteCodeRequest: CreateInviteCodeRequest(
      role: CreateInviteCodeRequestRoleEnum.values.firstWhere(
        (r) => r.value == role,
      ),
    ),
  )).data!;
  @override
  Future<InvitePreview> previewInvite(String invite) async =>
      (await api.workspaces.previewInvite(invite: invite)).data!;
  @override
  Future<JoinResult> joinWithInvite(String invite) async =>
      (await api.workspaces.joinWithInvite(
        joinRequestBody: JoinRequestBody(invite: invite),
      )).data!;
  @override
  Future<List<JoinRequest>> joinRequests(String orgId) async =>
      (await api.workspaces.listJoinRequests(id: orgId)).data!.items;
  @override
  Future<JoinRequest> decideJoinRequest(
    String orgId,
    String requestId,
    bool approve,
  ) async => (await api.workspaces.decideJoinRequest(
    id: orgId,
    requestId: requestId,
    decideJoinRequest: DecideJoinRequest(approve: approve),
  )).data!;
  @override
  Future<List<PendingInvite>> pendingInvites(String orgId) async =>
      (await api.workspaces.listInvites(id: orgId)).data!.items;
  @override
  Future<List<Invite>> inviteMany(
    String orgId,
    List<String> emails, {
    bool admin = false,
  }) async => (await api.workspaces.createInvites(
    id: orgId,
    createInvitesRequest: CreateInvitesRequest(
      emails: emails,
      role: admin
          ? CreateInvitesRequestRoleEnum.admin
          : CreateInvitesRequestRoleEnum.member,
    ),
  )).data!.items;
  @override
  Future<Invite> resendInvite(String orgId, String inviteId) async =>
      (await api.workspaces.resendInvite(id: orgId, inviteId: inviteId)).data!;
  @override
  Future<void> revokeInvite(String orgId, String inviteId) async =>
      api.workspaces.revokeInvite(id: orgId, inviteId: inviteId);
  @override
  Future<JoinDomains> joinDomains(String orgId) async =>
      (await api.workspaces.getJoinDomains(id: orgId)).data!;
  @override
  Future<JoinDomains> setJoinDomain(
    String orgId,
    bool enabled, {
    String? domain,
  }) async => (await api.workspaces.setJoinDomain(
    id: orgId,
    setJoinDomainRequest: SetJoinDomainRequest(
      enabled: enabled,
      domain: domain,
    ),
  )).data!;
  @override
  Future<List<JoinableWorkspace>> joinableWorkspaces() async =>
      (await api.workspaces.listJoinableWorkspaces()).data!.items;
  @override
  Future<OrganizationWithRole> joinByDomain(String orgId) async =>
      (await api.workspaces.joinByDomain(id: orgId)).data!;

  // --- keys -----------------------------------------------------------------

  @override
  Future<List<Credential>> credentials(String orgId) async =>
      (await api.credentials.listCredentials(orgId: orgId)).data!.items;

  @override
  Future<Credential> addCredential(
    String orgId,
    ProviderId provider,
    String label, {
    String? apiKey,
    String? baseUrl,
  }) async => (await api.credentials.createCredential(
    createCredentialRequest: CreateCredentialRequest(
      orgId: orgId,
      provider: provider,
      label: label,
      apiKey: apiKey,
      baseUrl: baseUrl,
    ),
  )).data!;

  @override
  Future<CredentialTestResult> testCredential(
    String credentialId, {
    String? model,
  }) async => (await api.credentials.testCredential(
    id: credentialId,
    testCredentialRequest: TestCredentialRequest(model: model),
  )).data!;

  @override
  Future<ModelOptionList> models(String credentialId) async =>
      (await api.credentials.listCredentialModels(id: credentialId)).data!;

  @override
  Future<Credential> updateCredential(
    String credentialId, {
    String? label,
    bool? fallbackOnLimit,
  }) async => (await api.credentials.updateCredential(
    id: credentialId,
    updateCredentialRequest: UpdateCredentialRequest(
      label: label,
      fallbackOnLimit: fallbackOnLimit,
    ),
  )).data!;

  @override
  Future<void> deleteCredential(String credentialId) async =>
      api.credentials.deleteCredential(id: credentialId);

  @override
  Set<String> get serverVoice => {for (final v in config?.serverVoice ?? const []) v.value};

  @override
  bool get chatGptSignIn => config?.chatgptSignIn ?? false;

  @override
  bool get canConnectChatGpt => chatGptLoopbackSupported;

  @override
  Future<Credential> connectChatGpt(String orgId, {String? credentialId}) =>
      connectChatGptLoopback(
        api.credentials,
        orgId: orgId,
        credentialId: credentialId,
        openBrowser: (url) async {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        },
      );

  // --- bots -----------------------------------------------------------------

  @override
  Future<List<Bot>> bots(String orgId) async =>
      (await api.bots.listBots(orgId: orgId)).data!.items;

  @override
  Future<List<Conversation>> groupChats(String orgId) async =>
      (await api.chat.listGroupChats(orgId: orgId)).data!.items;

  @override
  Future<Conversation> createGroupChat(
    String leadBotId,
    List<String> botIds, {
    String? title,
  }) async => (await api.chat.createConversation(
    createConversationRequest: CreateConversationRequest(
      botId: leadBotId,
      botIds: botIds,
      title: title,
    ),
  )).data!;

  @override
  Future<Bot> createBot(
    String orgId, {
    required String name,
    required String credentialId,
    required String model,
    String persona = '',
    String? templateId,
    String? avatarUrl,
  }) async => (await api.bots.createBot(
    createBotRequest: CreateBotRequest(
      orgId: orgId,
      name: name,
      personaMd: persona,
      modelPolicy: ModelPolicy(
        primary: ModelChoice(credentialId: credentialId, model: model),
      ),
      templateId: templateId,
      avatarUrl: avatarUrl,
    ),
  )).data!;

  @override
  Future<List<Template>> templates() async =>
      (await api.bots.listTemplates()).data!.items;

  @override
  Future<SendMessageResponse> editMessage(
    String conversationId,
    String messageId,
    String text,
  ) async => (await api.chat.editMessage(
    id: conversationId,
    messageId: messageId,
    editMessageRequest: EditMessageRequest(text: text),
  )).data!;

  @override
  Future<void> switchBranch(String conversationId, String messageId) async {
    await api.chat.switchBranch(
      id: conversationId,
      switchBranchRequest: SwitchBranchRequest(messageId: messageId),
    );
  }

  @override
  Future<List<String>> messageSiblings(
    String conversationId,
    String messageId,
  ) async {
    final m = await supabase
        .from('messages')
        .select('role, parent_message_id')
        .eq('id', messageId)
        .single();
    var q = supabase
        .from('messages')
        .select('id')
        .eq('conversation_id', conversationId)
        .eq('role', m['role'] as String);
    final parent = m['parent_message_id'] as String?;
    q = parent == null
        ? q.isFilter('parent_message_id', null)
        : q.eq('parent_message_id', parent);
    final rows = await q
        .order('created_at', ascending: true)
        .order('id', ascending: true);
    return [for (final r in rows) r['id'] as String];
  }

  @override
  Future<SearchResponse> search(String orgId, String query, {List<String>? kinds}) async =>
      (await api.search.search(orgId: orgId, q: query, kinds: kinds?.join(','))).data!;

  @override
  Future<List<BotFolder>> botFolders(String orgId) async {
    final rows = await supabase
        .from('bot_folders')
        .select('id, name, sort_key')
        .eq('org_id', orgId)
        .order('sort_key')
        .order('name');
    return [
      for (final r in rows)
        BotFolder(
          id: r['id'] as String,
          name: r['name'] as String,
          sortKey: (r['sort_key'] as num?)?.toDouble() ?? 0,
        ),
    ];
  }

  @override
  Future<void> setBotFolder(
    String orgId,
    String botId,
    String? folderName,
  ) async {
    String? folderId;
    if (folderName != null) {
      final row = await supabase
          .from('bot_folders')
          .upsert({
            'org_id': orgId,
            'name': folderName,
          }, onConflict: 'org_id,name')
          .select('id')
          .single();
      folderId = row['id'] as String;
    }
    await supabase.from('bots').update({'folder_id': folderId}).eq('id', botId);
    // Folders with no bots left go away.
    final used = await supabase
        .from('bots')
        .select('folder_id')
        .eq('org_id', orgId)
        .not('folder_id', 'is', null);
    final keep = {for (final r in used) r['folder_id'] as String};
    final all = await botFolders(orgId);
    for (final f in all.where((f) => !keep.contains(f.id))) {
      await supabase.from('bot_folders').delete().eq('id', f.id);
    }
  }

  @override
  Future<List<Bot>> archivedBots(String orgId) async =>
      (await api.bots.listBots(orgId: orgId, archived: 'true')).data!.items;

  @override
  Future<void> setBotArchived(String botId, bool archived) async {
    await supabase
        .from('bots')
        .update({
          'archived_at': archived
              ? DateTime.now().toUtc().toIso8601String()
              : null,
        })
        .eq('id', botId);
  }

  @override
  Future<String> startBotSetup(String botId) async =>
      (await api.bots.startBotSetup(id: botId)).data!.conversationId;

  @override
  Future<void> skipBotSetup(String botId) async {
    await supabase
        .from('bots')
        .update({'setup_status': 'skipped'})
        .eq('id', botId);
  }

  String get _uid => supabase.auth.currentUser!.id;

  @override
  Future<BotTemplateFile> exportBot(
    String botId, {
    bool memories = false,
  }) async => (await api.bots.exportBot(
    id: botId,
    memories: memories ? 'true' : null,
  )).data!;

  @override
  Future<BotShareLink> createBotShare(
    String botId, {
    bool memories = false,
  }) async => (await api.bots.createBotShare(
    id: botId,
    createBotShareRequest: CreateBotShareRequest(includeMemories: memories),
  )).data!;

  @override
  Future<BotTemplateFile> getBotShare(String token) async =>
      (await api.bots.getBotShare(token: token)).data!;

  @override
  Future<ImportBotResponse> importBot(
    String orgId,
    BotTemplateFile template, {
    required String credentialId,
    required String model,
    bool memories = true,
    bool routines = true,
  }) async => (await api.bots.importBot(
    importBotRequest: ImportBotRequest(
      orgId: orgId,
      template: template,
      credentialId: credentialId,
      model: model,
      includeMemories: memories,
      includeRoutines: routines,
    ),
  )).data!;

  @override
  Future<QuietHoursView> quietHours() async {
    final r = await supabase
        .from('profiles')
        .select('quiet_hours')
        .eq('user_id', _uid)
        .maybeSingle();
    // On by default (D-254), the same as a new profile on the server.
    return QuietHoursView.fromJson(r?['quiet_hours']) ??
        const QuietHoursView(enabled: true, start: '22:00', end: '07:00');
  }

  @override
  Future<void> setQuietHours(QuietHoursView hours) async {
    await supabase
        .from('profiles')
        .update({'quiet_hours': hours.toJson()})
        .eq('user_id', _uid);
  }

  @override
  Future<BotQuietView> botQuiet(String botId) async {
    final r = await supabase
        .from('user_bot_settings')
        .select('quiet, quiet_hours')
        .eq('user_id', _uid)
        .eq('bot_id', botId)
        .maybeSingle();
    return BotQuietView(
      mode: (r?['quiet'] as String?) ?? 'default',
      hours: QuietHoursView.fromJson(r?['quiet_hours']),
    );
  }

  @override
  Future<void> setBotQuiet(String botId, BotQuietView value) async {
    await supabase.from('user_bot_settings').upsert({
      'user_id': _uid,
      'bot_id': botId,
      'quiet': value.mode,
      'quiet_hours': value.hours?.toJson(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  // About you (D-169): through the API, which seals the text with the person's own key when a
  // workspace of theirs encrypts (D-136).
  static AboutYouView _about(AboutYou a) => AboutYouView(
    displayName: a.displayName,
    preferredName: a.preferredName,
    pronouns: a.pronouns,
    about: a.about,
    replyStyle: a.replyStyle,
    learn: a.learn,
    nameAsked: a.nameAsked,
    photoId: a.photoId,
    providerPhoto: a.providerPhoto ?? false,
    photoImportTried: a.photoImportTried ?? true,
  );

  @override
  Future<AboutYouView> setProfilePhoto(
    Uint8List bytes,
    String contentType,
  ) async => _about(
    (await api.aboutYou.setProfilePhoto(
      setProfilePhotoRequest: SetProfilePhotoRequest(
        contentType: SetProfilePhotoRequestContentTypeEnum.values.firstWhere(
          (t) => t.value == contentType,
        ),
        data: base64Encode(bytes),
      ),
    )).data!,
  );

  @override
  Future<AboutYouView> removeProfilePhoto() async =>
      _about((await api.aboutYou.deleteProfilePhoto()).data!);

  @override
  Future<AboutYouView> importProfilePhoto({bool replace = false}) async =>
      _about(
        (await api.aboutYou.importProfilePhoto(
          importProfilePhotoRequest: ImportProfilePhotoRequest(
            replace: replace,
          ),
        )).data!,
      );

  @override
  String photoUrl(String photoId) =>
      '${api.baseUrl.replaceAll(RegExp(r'/+$'), '')}/v1/photos/$photoId';

  @override
  Future<Referral> referral() async =>
      (await api.referrals.getReferral()).data!;
  @override
  Future<Referral> redeemReferral(String code) async =>
      (await api.referrals.redeemReferral(
        redeemReferralRequest: RedeemReferralRequest(code: code),
      )).data!;
  @override
  Future<ReferralPreview> previewReferral(String code) async =>
      (await api.referrals.previewReferral(code: code)).data!;

  @override
  Future<AboutYouView> aboutYou() async =>
      _about((await api.aboutYou.getAboutYou()).data!);

  @override
  Future<void> saveAboutYou(AboutYouView value) async {
    await api.aboutYou.updateAboutYou(
      updateAboutYouRequest: UpdateAboutYouRequest(
        preferredName: value.preferredName?.trim() ?? '',
        pronouns: value.pronouns?.trim() ?? '',
        about: value.about.trim(),
        replyStyle: value.replyStyle.trim(),
        learn: value.learn,
      ),
    );
  }

  @override
  Future<void> markNameAsked() async {
    await api.aboutYou.updateAboutYou(
      updateAboutYouRequest: UpdateAboutYouRequest(nameAsked: true),
    );
  }

  @override
  Future<List<UserFactView>> userFacts() async => [
    for (final f in (await api.aboutYou.listUserFacts()).data!.items)
      UserFactView(
        id: f.id,
        kind: f.kind.value,
        content: f.content,
        pinned: f.pinned,
        updatedAt: f.updatedAt,
      ),
  ];

  @override
  Future<void> addUserFacts(List<({String kind, String content})> facts) async {
    if (facts.isEmpty) return;
    await api.aboutYou.addUserFacts(
      addUserFactsRequest: AddUserFactsRequest(
        items: [
          for (final f in facts)
            AddUserFactsRequestItemsInner(
              kind: f.kind == 'preference'
                  ? AddUserFactsRequestItemsInnerKindEnum.preference
                  : AddUserFactsRequestItemsInnerKindEnum.fact,
              content: f.content.trim().length > 500
                  ? f.content.trim().substring(0, 500)
                  : f.content.trim(),
            ),
        ],
      ),
    );
  }

  @override
  Future<void> updateUserFact(
    String id, {
    String? content,
    bool? pinned,
  }) async {
    await api.aboutYou.updateUserFact(
      id: id,
      updateUserFactRequest: UpdateUserFactRequest(
        content: content?.trim(),
        pinned: pinned,
      ),
    );
  }

  @override
  Future<void> deleteUserFact(String id) async {
    await api.aboutYou.deleteUserFact(id: id);
  }

  @override
  Future<bool> profileSharedIn(String orgId) async =>
      (await api.aboutYou.getProfileSpace(orgId: orgId)).data!.shared;

  @override
  Future<void> setProfileSharedIn(String orgId, bool share) async {
    await api.aboutYou.setProfileSpace(
      orgId: orgId,
      setProfileSpaceRequest: SetProfileSpaceRequest(shared: share),
    );
  }

  @override
  Future<List<BotRevision>> botRevisions(String botId) async {
    final rows = await supabase
        .from('bot_revisions')
        .select(
          'id, snapshot, changed_fields, changed_by_user, changed_by_bot, created_at',
        )
        .eq('bot_id', botId)
        .order('created_at', ascending: false)
        .limit(100);
    return [
      for (final r in rows)
        BotRevision(
          id: r['id'] as String,
          snapshot: Map<String, Object?>.from(r['snapshot'] as Map),
          changedFields: [
            for (final f in (r['changed_fields'] as List? ?? const []))
              f as String,
          ],
          changedByUser: r['changed_by_user'] as String?,
          changedByBot: r['changed_by_bot'] as String?,
          createdAt: DateTime.parse(r['created_at'] as String),
        ),
    ];
  }

  @override
  Future<void> restoreBotRevision(String botId, BotRevision revision) async {
    final s = revision.snapshot;
    await supabase
        .from('bots')
        .update({
          for (final f in revision.changedFields)
            if (const {
              'name',
              'persona_md',
              'model_policy',
              'autonomy',
              'budget',
              'default_computer_id',
              'archived_at',
            }.contains(f))
              f: s[f],
        })
        .eq('id', botId);
  }

  @override
  Future<void> updateBot(
    String botId, {
    String? name,
    String? persona,
    String? autonomy,
    Map<String, Object?>? modelPolicy,
    String? avatarUrl,
  }) async {
    await supabase
        .from('bots')
        .update({
          if (avatarUrl != null)
            'avatar_url': avatarUrl.isEmpty ? null : avatarUrl,
          'name': ?name,
          'persona_md': ?persona,
          'autonomy': ?autonomy,
          'model_policy': ?modelPolicy,
        })
        .eq('id', botId);
  }

  @override
  Future<UsageReport> usage(String orgId, {String period = 'day'}) async =>
      (await api.usage.getUsage(orgId: orgId, period: period)).data!;

  @override
  bool get wallpapersEnabled => config?.wallpapersEnabled ?? false;
  @override
  String? get traceUrlTemplate => config?.traceUrlTemplate;
  @override
  Future<Run> run(String runId) async =>
      (await api.runs.getRun(id: runId)).data!;

  @override
  Future<List<WallpaperPhoto>> searchWallpapers({
    String? query,
    int page = 1,
  }) async => (await api.appearance.searchWallpapers(
    q: query == null || query.trim().isEmpty ? null : query.trim(),
    page: page,
  )).data!.items;

  @override
  Future<void> trackWallpaperDownload(String downloadLocation) async =>
      api.appearance.trackWallpaperDownload(
        wallpaperDownloadRequest: WallpaperDownloadRequest(
          downloadLocation: downloadLocation,
        ),
      );

  // --- chat -----------------------------------------------------------------

  @override
  Future<List<Conversation>> conversations(String botId) async =>
      (await api.chat.listConversations(id: botId)).data!.items;

  @override
  Future<Conversation> updateConversation(String conversationId, {String? title, bool? pinned}) async =>
      (await api.chat.updateConversation(
        id: conversationId,
        updateConversationRequest: UpdateConversationRequest(title: title, pinned: pinned),
      )).data!;

  @override
  Future<void> deleteConversation(String conversationId, {bool withCreations = false}) async {
    await api.chat.deleteConversation(id: conversationId, withCreations: withCreations ? 'true' : null);
  }

  @override
  Future<(int, int)> deleteBotConversations(String botId) async {
    final r = (await api.chat.deleteBotConversations(id: botId)).data!;
    return (r.deleted, r.skipped);
  }

  @override
  Future<Conversation> createConversation(String botId) async =>
      (await api.chat.createConversation(
        createConversationRequest: CreateConversationRequest(botId: botId),
      )).data!;

  static String _text(Object? content) {
    if (content is! List) return '';
    return content
        .whereType<Map>()
        .where((p) => p['type'] == 'text')
        .map((p) => '${p['text'] ?? ''}')
        .join();
  }

  static List<AttachmentRef> _files(Object? content) => attachmentsOf(content);

  static List<UiPart> _ui(Object? content) => uiPartsOf(content);

  static String? _uiAction(Object? content) {
    if (content is! List) return null;
    for (final p in content.whereType<Map>()) {
      if (p['type'] == 'ui_action' && p['surface_id'] is String) {
        return p['surface_id'] as String;
      }
    }
    return null;
  }

  @override
  Future<List<ChatMessageView>> messages(String conversationId, {int? limit, String? before, String? around}) async {
    // The branch being shown (D-108), oldest first; a page of it when [limit] is given (Fix 10).
    var paged = limit != null;
    List<dynamic> all;
    try {
      all = await supabase.rpc(
        'conversation_thread',
        params: {
          'p_conversation': conversationId,
          if (paged) 'p_limit': limit,
          if (paged && before != null) 'p_before': before,
          if (paged && around != null) 'p_around': around,
        },
      );
    } on sb.PostgrestException catch (e) {
      // A server from before paging has no such function: read the whole branch, page it here.
      if (!paged || e.code != 'PGRST202') rethrow;
      paged = false;
      all = await supabase.rpc('conversation_thread', params: {'p_conversation': conversationId});
    }
    // A workspace that encrypts content (D-136): Postgres has ciphertext, so read the thread through the API.
    if (all.any(
      (r) =>
          r is Map &&
          r['content'] is Map &&
          (r['content'] as Map).containsKey(r'$enc'),
    )) {
      all = (await api.chat.getConversationThread(
        id: conversationId,
        limit: paged ? limit : null,
        before: paged ? before : null,
        around: paged ? around : null,
      )).data!.items;
    }
    var rows = all
        .map((r) => Map<String, dynamic>.from(r as Map))
        .where((r) => r['role'] == 'user' || r['role'] == 'assistant')
        .toList();
    if (limit != null && !paged) rows = pageOfThread(rows, (r) => r['id'] as String, limit: limit, before: before, around: around);
    return [
      for (final r
          in limit == null && rows.length > 500 ? rows.sublist(rows.length - 500) : rows)
        ChatMessageView(
          siblingIndex: (r['sibling_index'] as num?)?.toInt() ?? 1,
          siblingCount: (r['sibling_count'] as num?)?.toInt() ?? 1,
          botId: r['bot_id'] as String?,
          id: r['id'] as String,
          role: r['role'] as String,
          text: _text(r['content']),
          createdAt: DateTime.parse(r['created_at'] as String),
          runId: r['run_id'] as String?,
          attachments: _files(r['content']),
          ui: _ui(r['content']),
          uiActionSurface: _uiAction(r['content']),
          routineName: _routineName(r['content']),
          suggestion: _suggestion(r['content']),
          suggestionList: _suggestionList(r['content']),
          topic: _topic(r['content']),
        ),
    ];
  }

  /// General and topics (D-253): a suggestion card or a topic's result in the message's parts.
  static List<MessageSuggestion> _suggestionList(Object? content) {
    if (content is! List) return const [];
    for (final p in content) {
      if (p case {'type': 'suggestions', 'items': final List<Object?> items}) {
        return [
          for (final i in items)
            if (i case {'suggestion_id': final String id, 'title': final String title})
              MessageSuggestion(id: id, title: title, body: (i as Map)['body'] as String? ?? ''),
        ];
      }
    }
    return const [];
  }

  static MessageSuggestion? _suggestion(Object? content) {
    if (content is! List) return null;
    for (final p in content) {
      if (p case {'type': 'suggestion', 'suggestion_id': final String id, 'title': final String title}) {
        return MessageSuggestion(id: id, title: title, body: p['body'] as String? ?? '');
      }
    }
    return null;
  }

  static MessageTopic? _topic(Object? content) {
    if (content is! List) return null;
    for (final p in content) {
      if (p case {'type': 'topic', 'conversation_id': final String id}) {
        return MessageTopic(conversationId: id, title: p['title'] as String? ?? '');
      }
    }
    return null;
  }

  static String? _routineName(Object? content) {
    if (content is! List) return null;
    for (final p in content.whereType<Map>()) {
      if (p['routine'] case {'name': final String name}) return name;
    }
    return null;
  }

  @override
  Future<String?> activeRun(String conversationId) async {
    final rows = await supabase
        .from('runs')
        .select('id')
        .eq('conversation_id', conversationId)
        .inFilter('status', [
          'queued',
          'running',
          'waiting_approval',
          'waiting_takeover',
        ])
        .order('created_at', ascending: false)
        .limit(1);
    return rows.isEmpty ? null : rows.first['id'] as String;
  }

  @override
  Future<SendMessageResponse> send(
    String conversationId,
    String text, {
    List<AttachmentRef> attachments = const [],
    Map<String, Object?>? uiAction,
    List<String> skills = const [],
  }) async => (await api.chat.sendMessage(
    id: conversationId,
    sendMessageRequest: SendMessageRequest(
      text: text,
      skills: skills.isEmpty ? null : skills,
      attachments: attachments.isEmpty
          ? null
          : [
              for (final a in attachments)
                MessageAttachment(
                  path: a.path,
                  name: a.name,
                  mimeType: a.mimeType,
                  size: a.size,
                ),
            ],
      uiAction: uiAction == null
          ? null
          : UiActionPart(
              surfaceId: '${uiAction['surface_id']}',
              name: '${uiAction['name']}',
              context: Map<String, Object?>.from(
                uiAction['context'] as Map? ?? const {},
              ),
            ),
    ),
  )).data!;

  @override
  Future<void> cancelRun(String runId) async {
    try {
      await api.runs.cancelRun(id: runId);
    } on DioException catch (e) {
      // 409 run_finished, or 404 when the run (its chat) was deleted.
      final code = e.response?.statusCode;
      if (code == 409 || code == 404) throw const RunAlreadyFinished();
      rethrow;
    }
  }

  @override
  Future<List<RunEventItem>> runEvents(String runId, {int afterSeq = 0}) async {
    final page = (await api.runs.listRunEvents(
      id: runId,
      afterSeq: afterSeq,
      limit: 1000,
    )).data!;
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
    DateTime? finishedSince;

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
        final page = (await api.runs.listRunEvents(
          id: runId,
          afterSeq: buffer.lastSeq,
          limit: 1000,
        )).data!;
        final before = buffer.lastSeq;
        deliver(page.items.map((e) => RunEventItem.fromJson(e.toJson())));
        catchUpEvents += buffer.lastSeq - before;
        // The server says the run is over, but its last event never came through (a gap held
        // back, a phone that slept through it): stop following it, or the chat keeps a Stop
        // button for a run that has ended. Only once it has stayed finished for a while: the
        // worker marks the run finished a moment before it writes the last event.
        if (!closed && page.items.length < 1000 && _finishedStatus.contains(page.runStatus)) {
          final since = finishedSince ??= DateTime.now();
          if (DateTime.now().difference(since) >= const Duration(milliseconds: 1500)) unawaited(close());
        } else {
          finishedSince = null;
        }
      } on DioException catch (e) {
        // The run is gone (its chat was deleted): nothing left to follow.
        if (e.response?.statusCode == 404) unawaited(close());
      } catch (_) {
        // Next poll retries.
      } finally {
        catchingUp = false;
      }
    }

    out = StreamController<RunEventItem>(
      onListen: () {
        channel = supabase
            .channel(
              'run:$runId',
              opts: const sb.RealtimeChannelConfig(private: true),
            )
            .onBroadcast(
              event: 'run_event',
              callback: (message) {
                final data = message['payload'] is Map
                    ? message['payload'] as Map
                    : message;
                // Sealed events (D-136) arrive as ids only: fetch them from the API.
                if (data['sealed'] == true) {
                  unawaited(catchUp());
                  return;
                }
                try {
                  final before = buffer.lastSeq;
                  deliver([
                    RunEventItem.fromJson(Map<String, dynamic>.from(data)),
                  ]);
                  if (buffer.lastSeq > before) realtimeEvents++;
                } catch (_) {}
                if (buffer.hasGap) unawaited(catchUp());
              },
            )
            .subscribe((status, _) {
              if (status == sb.RealtimeSubscribeStatus.subscribed) {
                unawaited(catchUp());
              }
            });
        unawaited(catchUp());
        // Safety net when Realtime is unavailable or a broadcast was missed.
        poll = Timer.periodic(
          const Duration(seconds: 2),
          (_) => unawaited(catchUp()),
        );
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
  Future<List<Memory>> memories(String botId) async =>
      (await api.memory.listMemories(id: botId)).data!.items;

  @override
  Future<void> updateMemory(
    String botId,
    String id, {
    String? content,
    bool? pinned,
  }) async {
    // Through the API: it seals content when the workspace encrypts (D-136) and reaches the memory backend (D-137).
    await api.memory.updateMemory(
      id: botId,
      memoryId: id,
      updateMemoryRequest: UpdateMemoryRequest(
        content: content,
        pinned: pinned,
      ),
    );
  }

  @override
  Future<void> deleteMemory(String botId, String id) async {
    await api.memory.deleteMemory(id: botId, memoryId: id);
  }

  @override
  Future<MemoryBackend> memoryBackend(String orgId) async =>
      (await api.memory.getMemoryBackend(id: orgId)).data!;

  @override
  Future<MemoryBackend> setMemoryBackend(
    String orgId,
    SetMemoryBackendRequest request,
  ) async => (await api.memory.setMemoryBackend(
    id: orgId,
    setMemoryBackendRequest: request,
  )).data!;

  @override
  Future<MemoryBackend> removeMemoryBackend(String orgId) async =>
      (await api.memory.deleteMemoryBackend(id: orgId)).data!;

  @override
  Future<List<SkillView>> skills(String orgId) async {
    final rows = await supabase
        .from('skills')
        .select()
        .eq('org_id', orgId)
        .order('name', ascending: true);
    return [
      for (final r in rows)
        SkillView(
          id: r['id'] as String,
          name: r['name'] as String,
          description: r['description'] as String,
          bodyMd: r['body_md'] as String,
          enabled: r['enabled'] as bool,
          botId: r['bot_id'] as String?,
          source: (r['source'] as String?) ?? 'manual',
          sourceRef: Map<String, Object?>.from(
            (r['source_ref'] as Map?) ?? const {},
          ),
          category: r['category'] as String?,
        ),
    ];
  }

  @override
  Future<void> saveSkill(
    String orgId, {
    String? id,
    String? botId,
    required String name,
    required String description,
    required String bodyMd,
    bool enabled = true,
  }) async {
    final row = {
      'org_id': orgId,
      'bot_id': botId,
      'name': name,
      'description': description,
      'body_md': bodyMd,
      'enabled': enabled,
    };
    if (id == null) {
      await supabase.from('skills').insert(row);
    } else {
      await supabase.from('skills').update(row).eq('id', id);
    }
  }

  @override
  Future<void> deleteSkill(String id) async =>
      supabase.from('skills').delete().eq('id', id);

  @override
  Future<SkillCatalog> skillCatalog() async =>
      (await api.skills.getSkillCatalog()).data!;

  @override
  Future<GalleryPage> gallery({String? type, String? query}) async {
    try {
      final data = await _gallery(
        '/v1/gallery',
        query: {'type': ?type, 'q': ?query},
      );
      final items = data['items'];
      return GalleryPage(
        available: data['available'] == true,
        items: [
          for (final item in items is List ? items : const [])
            GalleryItem.fromJson((item as Map).cast<String, dynamic>()),
        ],
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return const GalleryPage(available: false, items: []);
      }
      rethrow;
    }
  }

  @override
  Future<GalleryItem> galleryItem(String type, String id) async {
    final data = await _gallery('/v1/gallery/$type/$id');
    return GalleryItem.fromJson(data);
  }

  @override
  Future<void> installGallerySkill(
    String orgId,
    String galleryId, {
    String? botId,
  }) async {
    await _galleryPost('/v1/skills/install', {
      'org_id': orgId,
      'gallery_id': galleryId,
      'bot_id': ?botId,
    });
  }

  Future<Map<String, dynamic>> _gallery(
    String path, {
    Map<String, String?> query = const {},
  }) async {
    final res = await _galleryDio().get<Map<String, dynamic>>(
      path,
      queryParameters: {
        for (final e in query.entries)
          if (e.value != null && e.value!.isNotEmpty) e.key: e.value,
      },
    );
    return res.data ?? const {};
  }

  Future<void> _galleryPost(String path, Map<String, Object?> body) async {
    await _galleryDio().post<void>(
      path,
      data: {
        for (final e in body.entries)
          if (e.value != null) e.key: e.value,
      },
    );
  }

  Dio _galleryDio() {
    final token = supabase.auth.currentSession?.accessToken;
    return Dio(
      BaseOptions(
        baseUrl: api.baseUrl,
        headers: {if (token != null) 'Authorization': 'Bearer $token'},
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 20),
      ),
    );
  }

  @override
  Future<void> installCatalogSkill(
    String orgId,
    String catalogId, {
    String? botId,
  }) async {
    await api.skills.installCatalogSkill(
      installCatalogSkillRequest: InstallCatalogSkillRequest(
        orgId: orgId,
        catalogId: catalogId,
        botId: botId,
      ),
    );
  }

  @override
  Future<GitHubSkillPreview> previewGitHubSkill(
    String orgId,
    String url,
  ) async => (await api.skills.previewGitHubSkill(
    gitHubSkillPreviewRequest: GitHubSkillPreviewRequest(
      orgId: orgId,
      url: url,
    ),
  )).data!;

  @override
  Future<void> installGitHubSkill(
    String orgId,
    String url,
    String commit, {
    String? botId,
  }) async {
    await api.skills.installGitHubSkill(
      installGitHubSkillRequest: InstallGitHubSkillRequest(
        orgId: orgId,
        url: url,
        commit: commit,
        botId: botId,
      ),
    );
  }

  @override
  Future<SkillUpdateCheck> checkSkillUpdate(String skillId) async =>
      (await api.skills.checkSkillUpdate(id: skillId)).data!;

  @override
  Future<void> applySkillUpdate(String skillId, String commit) async {
    await api.skills.applySkillUpdate(
      id: skillId,
      applySkillUpdateRequest: ApplySkillUpdateRequest(commit: commit),
    );
  }

  // --- approvals and notifications ------------------------------------------

  @override
  Future<List<Approval>> approvals(
    String orgId, {
    bool pendingOnly = true,
  }) async => (await api.approvals.listApprovals(
    orgId: orgId,
    status: pendingOnly ? 'pending' : null,
  )).data!.items;

  @override
  Future<Approval> decideApproval(
    String approvalId, {
    required bool approve,
    bool alwaysAllow = false,
  }) async => (await api.approvals.decideApproval(
    id: approvalId,
    approvalDecisionRequest: ApprovalDecisionRequest(
      decision: approve
          ? ApprovalDecisionRequestDecisionEnum.approved
          : ApprovalDecisionRequestDecisionEnum.denied,
      alwaysAllow: approve && alwaysAllow ? true : null,
    ),
  )).data!;

  static NotificationView _notification(Map row) {
    final payload = row['payload'] is Map ? row['payload'] as Map : const {};
    return NotificationView(
      id: row['id'] as String,
      kind: row['kind'] as String,
      title: '${payload['title'] ?? ''}',
      body: '${payload['body'] ?? ''}',
      link: payload['link'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
      readAt: row['read_at'] == null
          ? null
          : DateTime.parse(row['read_at'] as String),
      whyRule: payload['why'] is Map
          ? '${(payload['why'] as Map)['rule'] ?? ''}'
          : null,
      whyData: payload['why'] is Map && (payload['why'] as Map)['data'] is List
          ? [for (final d in (payload['why'] as Map)['data'] as List) '$d']
          : const [],
      urgency: (row['urgency'] ?? payload['urgency']) as String?,
      heldReason: row['held_reason'] as String?,
      botId: payload['bot_id'] as String?,
    );
  }

  @override
  Future<List<NotificationView>> notifications() async {
    final rows = await supabase
        .from('notifications')
        .select('id, kind, payload, read_at, created_at, urgency, held_reason')
        .order('created_at', ascending: false)
        .limit(100);
    return [for (final r in rows) _notification(r)];
  }

  @override
  Future<void> markNotificationsRead() async {
    await supabase
        .from('notifications')
        .update({'read_at': DateTime.now().toUtc().toIso8601String()})
        .isFilter('read_at', null);
  }

  @override
  Future<void> markNotificationRead(String id) async {
    await supabase
        .from('notifications')
        .update({'read_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', id)
        .isFilter('read_at', null);
  }

  @override
  Stream<NotificationView> watchNotifications() =>
      _userEvents('notification').expand((data) {
        try {
          return [_notification(data)];
        } catch (_) {
          return <NotificationView>[];
        }
      });

  @override
  Stream<String?> watchConversation(String conversationId) {
    sb.RealtimeChannel? channel;
    late final StreamController<String?> out;
    out = StreamController<String?>(
      onListen: () {
        var joined = false;
        channel = supabase
            .channel('conversation:$conversationId', opts: const sb.RealtimeChannelConfig(private: true))
            .onBroadcast(
              event: 'conversation_activity',
              callback: (message) {
                final data = message['payload'] is Map ? message['payload'] as Map : message;
                final run = data['run_id'];
                out.add(run is String ? run : null);
              },
            )
            .subscribe((status, _) {
              if (status != sb.RealtimeSubscribeStatus.subscribed) return;
              // Joined again after a dropped connection: a run may have started meanwhile.
              if (joined) out.add(null);
              joined = true;
            });
      },
      onCancel: () async {
        final c = channel;
        channel = null;
        if (c != null) await supabase.removeChannel(c);
      },
    );
    return out.stream;
  }

  @override
  Stream<void> watchBotsChanged(String orgId) {
    sb.RealtimeChannel? channel;
    late final StreamController<void> out;
    out = StreamController<void>(
      onListen: () {
        var joined = false;
        channel = supabase
            .channel('org:$orgId', opts: const sb.RealtimeChannelConfig(private: true))
            .onBroadcast(event: 'bots_changed', callback: (_) => out.add(null))
            .subscribe((status, _) {
              if (status != sb.RealtimeSubscribeStatus.subscribed) return;
              // Joined again after a dropped connection: something may have changed meanwhile.
              // The first join needs nothing; the list was just loaded.
              if (joined) out.add(null);
              joined = true;
            });
      },
      onCancel: () async {
        final c = channel;
        channel = null;
        if (c != null) await supabase.removeChannel(c);
      },
    );
    return out.stream;
  }

  // One subscription to the person's private topic, shared by every event kind on it
  // (notifications, device requests): a second join of the same topic would replace the first.
  final _userTopic = <String, StreamController<Map>>{};
  sb.RealtimeChannel? _userChannel;
  String? _userChannelFor;

  Stream<Map> _userEvents(String event) {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return const Stream.empty();
    final c = _userTopic.putIfAbsent(
      event,
      () => StreamController<Map>.broadcast(onCancel: _maybeCloseUserChannel),
    );
    if (_userChannel == null || _userChannelFor != userId) {
      final old = _userChannel;
      if (old != null) unawaited(supabase.removeChannel(old));
      _userChannelFor = userId;
      var ch = supabase.channel(
        'user:$userId',
        opts: const sb.RealtimeChannelConfig(private: true),
      );
      for (final name in const ['notification', 'device_request']) {
        ch = ch.onBroadcast(
          event: name,
          callback: (message) {
            final data = message['payload'] is Map
                ? message['payload'] as Map
                : message;
            _userTopic[name]?.add(data);
          },
        );
      }
      _userChannel = ch..subscribe();
    }
    return c.stream;
  }

  void _maybeCloseUserChannel() {
    if (_userTopic.values.any((c) => c.hasListener)) return;
    final ch = _userChannel;
    _userChannel = null;
    _userChannelFor = null;
    if (ch != null) unawaited(supabase.removeChannel(ch));
  }

  @override
  Future<List<PhoneCall>> ringingCalls() async =>
      (await api.voice.listRingingCalls()).data!.items;

  @override
  Future<PhoneCall> answerCall(String id) async =>
      (await api.voice.answerVoiceCall(id: id)).data!;

  @override
  Future<PhoneCall> declineCall(String id) async =>
      (await api.voice.declineVoiceCall(id: id)).data!;

  @override
  Future<void> registerVoipToken(String token) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null || token.isEmpty) return;
    await supabase.from('voip_tokens').upsert({
      'user_id': userId,
      'token': token,
      'last_seen_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'token');
  }

  @override
  Future<void> registerDevice(String platform, String token) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;
    final row = {
      'user_id': userId,
      'platform': platform,
      'fcm_token': token,
      'last_seen_at': DateTime.now().toUtc().toIso8601String(),
    };
    // Android draws suggestion pushes itself, with Do it / Not now buttons (D-247). A server
    // from before that has no such column, so it gets the plain row.
    if (platform != 'android') {
      await supabase.from('devices').upsert(row, onConflict: 'fcm_token');
      return;
    }
    try {
      await supabase.from('devices').upsert({...row, 'data_pushes': true}, onConflict: 'fcm_token');
    } catch (_) {
      await supabase.from('devices').upsert(row, onConflict: 'fcm_token');
    }
  }

  // --- routines -------------------------------------------------------------

  @override
  Future<List<Routine>> routines(String botId) async =>
      (await api.routines.listRoutines(id: botId)).data!.items;

  @override
  Future<CreatedRoutine> createRoutine(
    String botId, {
    required String name,
    required String instructions,
    required String trigger,
    String? cron,
    String? timezone,
    DateTime? runAt,
    CalendarTriggerConfig? calendar,
    MessageTriggerConfig? message,
    DateTime? endsAt,
    int? maxRuns,
  }) async => (await api.routines.createRoutine(
    createRoutineRequest: CreateRoutineRequest(
      botId: botId,
      name: name,
      instructions: instructions,
      trigger: RoutineTrigger.values.firstWhere((t) => t.value == trigger),
      scheduleCron: trigger == 'schedule' ? cron : null,
      runAt: trigger == 'once' ? runAt?.toUtc() : null,
      timezone: timezone,
      calendar: trigger == 'calendar_event' ? calendar : null,
      message: trigger == 'message' ? message : null,
      endsAt: trigger == 'once' ? null : endsAt?.toUtc(),
      maxRuns: trigger == 'once' ? null : maxRuns,
    ),
  )).data!;

  @override
  Future<void> deleteRoutine(String routineId) async =>
      api.routines.deleteRoutine(id: routineId);

  @override
  Future<void> setRoutineEnabled(String routineId, bool enabled) async =>
      api.routines.updateRoutine(
        id: routineId,
        updateRoutineRequest: UpdateRoutineRequest(enabled: enabled),
      );

  // Sent as raw JSON: the generated request drops nulls, and null is how an end is removed.
  @override
  Future<void> setRoutineEnd(String routineId, {DateTime? endsAt, int? maxRuns}) async =>
      api.api.dio.patch<Object>(
        '/v1/routines/$routineId',
        data: {'ends_at': endsAt?.toUtc().toIso8601String(), 'max_runs': maxRuns},
        options: Options(headers: authHeaders, contentType: 'application/json'),
      );

  @override
  Future<String> runRoutine(String routineId) async =>
      (await api.routines.runRoutine(id: routineId)).data!.runId;

  @override
  Future<void> updateRoutine(String routineId, {String? name, String? instructions, String? scheduleCron, String? timezone, DateTime? runAt}) async =>
      api.routines.updateRoutine(
        id: routineId,
        updateRoutineRequest: UpdateRoutineRequest(name: name, instructions: instructions, scheduleCron: scheduleCron, timezone: timezone, runAt: runAt?.toUtc()),
      );

  @override
  Future<List<RunSummary>> routineRuns(String routineId) async {
    final rows = await supabase
        .from('runs')
        .select('id, status, trigger, created_at, cost_usd')
        .eq('routine_id', routineId)
        .order('created_at', ascending: false)
        .limit(10);
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

  // --- integrations and secrets ---------------------------------------------

  @override
  Future<List<Integration>> integrations(String orgId) async =>
      (await api.integrations.listIntegrations(orgId: orgId)).data!.items;

  @override
  Future<Integration> createIntegration(
    String orgId, {
    required String kind,
    required String name,
    required Map<String, Object?> config,
    String? secret,
  }) async => (await api.integrations.createIntegration(
    createIntegrationRequest: CreateIntegrationRequest(
      orgId: orgId,
      kind: IntegrationKind.values.firstWhere((k) => k.value == kind),
      name: name,
      config: config,
      secret: secret,
    ),
  )).data!;

  @override
  Future<IntegrationTestResult> testIntegration(String integrationId) async =>
      (await api.integrations.testIntegration(id: integrationId)).data!;

  @override
  Future<AppCatalog> appCatalog() async =>
      (await api.integrations.listApps()).data!;

  @override
  Future<ConnectAppResponse> connectApp(
    String orgId, {
    required String appId,
    required String method,
    String? apiKey,
    String? integrationId,
    bool returnToApp = false,
  }) async => (await api.integrations.connectApp(
    connectAppRequest: ConnectAppRequest(
      orgId: orgId,
      appId: appId,
      method: ConnectAppRequestMethodEnum.values.firstWhere(
        (m) => m.value == method,
      ),
      apiKey: apiKey,
      integrationId: integrationId,
      returnToApp: returnToApp ? true : null,
    ),
  )).data!;

  @override
  Future<ConnectFlowStatus> connectStatus(String flowId) async =>
      (await api.integrations.connectStatus(id: flowId)).data!;

  @override
  Future<void> deleteIntegration(String integrationId) async =>
      api.integrations.deleteIntegration(id: integrationId);

  @override
  Future<Integration> setToolRisks(
    String integrationId,
    Map<String, String> risks,
  ) async => (await api.integrations.updateIntegration(
    id: integrationId,
    updateIntegrationRequest: UpdateIntegrationRequest(
      riskOverrides: {
        for (final e in risks.entries)
          e.key: UpdateIntegrationRequestRiskOverridesEnum.values.firstWhere(
            (r) => r.value == e.value,
          ),
      },
    ),
  )).data!;

  @override
  Future<List<ProviderApp>> providerApps(
    String integrationId, {
    String? query,
  }) async => (await api.integrations.listProviderApps(
    id: integrationId,
    q: query == null || query.trim().isEmpty ? null : query.trim(),
  )).data!.items;

  @override
  Future<String> connectProviderApp(String integrationId, String app, {bool returnToApp = false}) async =>
      (await api.integrations.connectProviderApp(
        id: integrationId,
        providerConnectRequest: ProviderConnectRequest(app: app, returnToApp: returnToApp ? true : null),
      )).data!.redirectUrl;

  @override
  Future<List<ProviderAccount>> providerAccounts(String integrationId) async =>
      (await api.integrations.listProviderAccounts(id: integrationId))
          .data!
          .items;

  @override
  Future<Set<String>> botIntegrationIds(String botId) async {
    final rows = await supabase
        .from('bot_integrations')
        .select('integration_id')
        .eq('bot_id', botId);
    return {for (final r in rows) r['integration_id'] as String};
  }

  @override
  Future<void> setBotIntegration(
    String botId,
    String integrationId,
    bool enabled,
  ) async {
    if (enabled) {
      await api.integrations.attachIntegration(
        id: botId,
        attachIntegrationRequest: AttachIntegrationRequest(
          integrationId: integrationId,
        ),
      );
    } else {
      await supabase
          .from('bot_integrations')
          .delete()
          .eq('bot_id', botId)
          .eq('integration_id', integrationId);
    }
  }

  @override
  Future<List<Secret>> secrets(String orgId) async =>
      (await api.secrets.listSecrets(orgId: orgId)).data!.items;

  @override
  Future<void> createSecret(
    String orgId, {
    required String name,
    required String value,
    required List<String> hosts,
    bool totp = false,
  }) async => api.secrets.createSecret(
    createSecretRequest: CreateSecretRequest(
      orgId: orgId,
      name: name,
      value: value,
      allowedHosts: hosts,
      kind: totp ? SecretKind.totp : SecretKind.plain,
    ),
  );

  @override
  Future<void> deleteSecret(String secretId) async =>
      api.secrets.deleteSecret(id: secretId);

  // --- task board -----------------------------------------------------------

  @override
  Future<List<Task>> tasks(String orgId, {String? projectId}) async =>
      (await api.tasks.listTasks(
        orgId: orgId,
        projectId: projectId,
      )).data!.items;

  @override
  Future<McpAuthRequestInfo> mcpAuthRequest(String id) async =>
      (await api.mcp.getMcpAuthRequest(id: id)).data!;

  @override
  Future<String> decideMcpAuthRequest(
    String id, {
    required String orgId,
    required bool approve,
  }) async => (await api.mcp.decideMcpAuthRequest(
    id: id,
    mcpConsentRequest: McpConsentRequest(orgId: orgId, approve: approve),
  )).data!.redirectUrl;

  @override
  Future<List<McpKey>> mcpKeys(String orgId) async =>
      (await api.mcp.listMcpKeys(id: orgId)).data!.items;

  @override
  Future<CreatedMcpKey> createMcpKey(String orgId, String name) async =>
      (await api.mcp.createMcpKey(
        id: orgId,
        createMcpKeyRequest: CreateMcpKeyRequest(name: name),
      )).data!;

  @override
  Future<void> revokeMcpKey(String orgId, String keyId) async {
    await api.mcp.revokeMcpKey(id: orgId, keyId: keyId);
  }

  @override
  Future<bool> mcpDecideApprovals(String orgId) async =>
      (await api.privacy.getOrgSettings(id: orgId)).data!.mcpDecideApprovals;

  @override
  Future<void> setMcpDecideApprovals(String orgId, bool allowed) async {
    await api.privacy.updateOrgSettings(
      id: orgId,
      updateOrgSettingsRequest: UpdateOrgSettingsRequest(
        mcpDecideApprovals: allowed,
      ),
    );
  }

  @override
  Future<bool> allowBotToBot(String orgId) async =>
      (await api.privacy.getOrgSettings(id: orgId)).data!.allowBotToBot;

  @override
  Future<SecretStoreSettings> secretStore(String orgId) async =>
      (await api.secrets.getSecretStore(id: orgId)).data!;

  @override
  Future<SecretStoreSettings> setSecretStore(
    String orgId,
    SetSecretStoreRequest request,
  ) async => (await api.secrets.setSecretStore(
    id: orgId,
    setSecretStoreRequest: request,
  )).data!;

  @override
  Future<SecretStoreSettings> removeSecretStore(String orgId) async =>
      (await api.secrets.deleteSecretStore(id: orgId)).data!;

  @override
  Future<List<BotLink>> botLinks(String botId) async =>
      (await api.links.listBotLinks(id: botId)).data!.items;

  @override
  Future<CreatedBotLink> createBotLink(String botId, String name) async =>
      (await api.links.createBotLink(
        id: botId,
        createBotLinkRequest: CreateBotLinkRequest(name: name),
      )).data!;

  @override
  Future<BotLink> acceptBotLink(
    String invite,
    String botId,
    String name,
  ) async => (await api.links.acceptBotLink(
    acceptBotLinkRequest: AcceptBotLinkRequest(
      invite: invite,
      botId: botId,
      name: name,
    ),
  )).data!;

  @override
  Future<BotLink> revokeBotLink(String id) async =>
      (await api.links.revokeBotLink(id: id)).data!;

  @override
  Future<List<LinkExchange>> linkExchanges(String id) async =>
      (await api.links.listLinkExchanges(id: id)).data!.items;

  @override
  Future<PaymentSettings> paymentSettings(String orgId) async =>
      (await api.payments.getPaymentSettings(id: orgId)).data!;

  @override
  Future<PaymentSettings> setPaymentSettings(
    String orgId,
    SetPaymentSettingsRequest request,
  ) async => (await api.payments.setPaymentSettings(
    id: orgId,
    setPaymentSettingsRequest: request,
  )).data!;

  @override
  Future<PaymentSettings> removePaymentSettings(String orgId) async =>
      (await api.payments.deletePaymentSettings(id: orgId)).data!;

  @override
  Future<List<PaymentRequest>> paymentRequests(String orgId) async =>
      (await api.payments.listPaymentRequests(id: orgId)).data!.items;

  @override
  Future<TelephonySettings> telephony(String orgId) async =>
      (await api.telephony.getTelephony(id: orgId)).data!;

  @override
  Future<TelephonySettings> setTelephony(
    String orgId,
    SetTelephonyRequest request,
  ) async => (await api.telephony.setTelephony(
    id: orgId,
    setTelephonyRequest: request,
  )).data!;

  @override
  Future<TelephonySettings> removeTelephony(String orgId) async =>
      (await api.telephony.deleteTelephony(id: orgId)).data!;

  @override
  Future<OutboundCall> outboundCall(String id) async =>
      (await api.telephony.getOutboundCall(id: id)).data!;

  @override
  Future<OutboundCall> endOutboundCall(String id) async =>
      (await api.telephony.endOutboundCall(id: id)).data!;

  @override
  Future<OutboundCall> takeOverOutboundCall(String id, {String? phone}) async =>
      (await api.telephony.takeOverOutboundCall(
        id: id,
        takeOverCallRequest: TakeOverCallRequest(phone: phone),
      )).data!;

  @override
  Future<bool> a2aEnabled(String orgId) async =>
      (await api.privacy.getOrgSettings(id: orgId)).data!.a2aEnabled;

  @override
  Future<void> setA2aEnabled(String orgId, bool enabled) async {
    await api.privacy.updateOrgSettings(
      id: orgId,
      updateOrgSettingsRequest: UpdateOrgSettingsRequest(a2aEnabled: enabled),
    );
  }

  @override
  Future<BotA2a> botA2a(String botId) async =>
      (await api.a2a.getBotA2a(id: botId)).data!;

  @override
  Future<BotA2a> setBotA2a(String botId, bool published) async =>
      (await api.a2a.setBotA2a(
        id: botId,
        setBotA2aRequest: SetBotA2aRequest(published: published),
      )).data!;

  @override
  Future<EncryptionStatus> encryption(String orgId) async =>
      (await api.encryption.getEncryption(id: orgId)).data!;

  @override
  Future<EncryptionStatus> setEncryption(String orgId, bool enabled) async =>
      (await api.encryption.setEncryption(
        id: orgId,
        setEncryptionRequest: SetEncryptionRequest(enabled: enabled),
      )).data!;

  @override
  Future<EncryptionStatus> rotateEncryptionKey(String orgId) async =>
      (await api.encryption.rotateEncryptionKey(id: orgId)).data!;

  @override
  Future<void> setAllowBotToBot(String orgId, bool allowed) async {
    await api.privacy.updateOrgSettings(
      id: orgId,
      updateOrgSettingsRequest: UpdateOrgSettingsRequest(
        allowBotToBot: allowed,
      ),
    );
  }

  @override
  Future<BotAccess> botAccess(String botId) async =>
      (await api.bots.getBotAccess(id: botId)).data!;

  @override
  Future<BotAccess> setBotAccess(
    String botId,
    SetBotAccessRequest request,
  ) async => (await api.bots.setBotAccess(
    id: botId,
    setBotAccessRequest: request,
  )).data!;

  @override
  Future<List<WorkspaceMember>> members(String orgId) async =>
      (await api.workspaces.listMembers(id: orgId)).data!.items;

  @override
  Future<WelcomeChat> startWelcome({String? firstName}) async =>
      (await api.bots.startWelcome(
        startWelcomeRequest: StartWelcomeRequest(firstName: firstName),
      )).data!;

  @override
  Future<List<PasswordManager>> passwordManagers(String orgId) async =>
      (await api.passwordManagers.listPasswordManagers(orgId: orgId))
          .data!
          .items;

  @override
  Future<PasswordManager> connectPasswordManager(
    CreatePasswordManagerRequest request,
  ) async => (await api.passwordManagers.createPasswordManager(
    createPasswordManagerRequest: request,
  )).data!;

  @override
  Future<List<PasswordManagerVault>> passwordManagerVaults(String id) async =>
      (await api.passwordManagers.listPasswordManagerVaults(id: id))
          .data!
          .items;

  @override
  Future<void> setPasswordManagerVaults(String id, List<String> vaults) async {
    await api.passwordManagers.updatePasswordManager(
      id: id,
      updatePasswordManagerRequest: UpdatePasswordManagerRequest(
        allowedVaults: vaults,
      ),
    );
  }

  @override
  Future<void> deletePasswordManager(String id) async {
    await api.passwordManagers.deletePasswordManager(id: id);
  }

  @override
  Future<List<Replay>> replays(String botId) async =>
      (await api.replays.listReplays(botId: botId)).data!.items;

  @override
  Future<RunReplayResponse> runReplay(
    String id,
    Map<String, String> params,
  ) async => (await api.replays.runReplay(
    id: id,
    runReplayRequest: RunReplayRequest(params: params),
  )).data!;

  @override
  Future<void> deleteReplay(String id) async {
    await api.replays.deleteReplay(id: id);
  }

  @override
  Future<Replay> replayFromTeach(
    String teachId,
    String name, {
    String? description,
  }) async => (await api.replays.replayFromTeach(
    id: teachId,
    replayFromTeachRequest: ReplayFromTeachRequest(
      name: name,
      description: description,
    ),
  )).data!;

  @override
  Future<List<SkillProposal>> skillProposals(
    String orgId, {
    String? botId,
  }) async => (await api.skills.listSkillProposals(
    orgId: orgId,
    botId: botId,
  )).data!.items;

  @override
  Future<void> acceptSkillProposal(String id, {String? bodyMd}) async {
    await api.skills.acceptSkillProposal(
      id: id,
      acceptSkillProposalRequest: AcceptSkillProposalRequest(bodyMd: bodyMd),
    );
  }

  @override
  Future<void> dismissSkillProposal(String id) async {
    await api.skills.dismissSkillProposal(id: id);
  }

  @override
  Future<SkillStats> skillStats(String skillId) async =>
      (await api.skills.getSkillStats(id: skillId)).data!;

  @override
  Future<List<KnowledgeSource>> knowledgeSources(
    String orgId, {
    String? botId,
  }) async => (await api.knowledge.listKnowledgeSources(
    orgId: orgId,
    botId: botId,
  )).data!.items;

  @override
  Future<KnowledgeSource> addKnowledgeSource(
    CreateKnowledgeSourceRequest request,
  ) async => (await api.knowledge.createKnowledgeSource(
    createKnowledgeSourceRequest: request,
  )).data!;

  @override
  Future<void> resyncKnowledgeSource(String id) async {
    await api.knowledge.resyncKnowledgeSource(id: id);
  }

  @override
  Future<void> deleteKnowledgeSource(String id) async {
    await api.knowledge.deleteKnowledgeSource(id: id);
  }

  @override
  Future<List<Channel>> channels(String botId) async =>
      (await api.channels.listChannels(botId: botId)).data!.items;

  @override
  Future<Channel> createChannel(CreateChannelRequest request) async =>
      (await api.channels.createChannel(createChannelRequest: request)).data!;

  @override
  Future<Channel> updateChannel(
    String id, {
    String? name,
    List<String>? allowedSenders,
    bool? enabled,
  }) async => (await api.channels.updateChannel(
    id: id,
    updateChannelRequest: UpdateChannelRequest(
      name: name,
      allowedSenders: allowedSenders,
      enabled: enabled,
    ),
  )).data!;

  @override
  Future<void> deleteChannel(String id) async {
    await api.channels.deleteChannel(id: id);
  }

  @override
  Future<List<ChannelEvent>> channelEvents(String id) async =>
      (await api.channels.listChannelEvents(id: id)).data!.items;

  @override
  Future<Uint8List> exportWorkspaceFiles(String orgId) async => base64Decode(
    (await api.files.exportWorkspaceFiles(id: orgId)).data!.zipBase64,
  );

  @override
  Future<WorkspaceFilesResult> importWorkspaceFiles(
    String orgId,
    Uint8List zip, {
    bool dryRun = false,
  }) async => (await api.files.importWorkspaceFiles(
    id: orgId,
    importWorkspaceFilesRequest: ImportWorkspaceFilesRequest(
      zipBase64: base64Encode(zip),
      dryRun: dryRun,
    ),
  )).data!;

  @override
  Future<GitSyncStatus> gitSync(String orgId) async =>
      (await api.files.getGitSync(id: orgId)).data!;

  @override
  Future<GitSyncStatus> setGitSync(
    String orgId, {
    required String repo,
    String? branch,
    String? path,
    bool enabled = true,
  }) async => (await api.files.setGitSync(
    id: orgId,
    setGitSyncRequest: SetGitSyncRequest(
      repo: repo,
      branch: branch,
      path: path,
      enabled: enabled,
    ),
  )).data!;

  @override
  Future<GitSyncStatus> runGitSync(String orgId) async =>
      (await api.files.runGitSync(id: orgId)).data!;

  @override
  Future<GitSyncStatus> deleteGitSync(String orgId) async =>
      (await api.files.deleteGitSync(id: orgId)).data!;

  @override
  Future<AgentImportPlan> startAgentImport(
    String orgId, {
    Uint8List? zip,
    Map<String, Uint8List>? files,
  }) async => (await api.imports.startAgentImport(
    startAgentImportRequest: StartAgentImportRequest(
      orgId: orgId,
      zipBase64: zip == null ? null : base64Encode(zip),
      files: files == null
          ? null
          : [
              for (final e in files.entries)
                StartAgentImportRequestFilesInner(
                  path: e.key,
                  contentBase64: base64Encode(e.value),
                ),
            ],
    ),
  )).data!;

  @override
  Future<int> writeAgentImportFiles(String importId, String botId) async =>
      (await api.imports.writeAgentImportFiles(
        id: importId,
        writeAgentImportFilesRequest: WriteAgentImportFilesRequest(
          botId: botId,
        ),
      )).data!.written;

  @override
  Future<String> memoryImportPrompt() async =>
      (await api.imports.getMemoryImportPrompt()).data!.prompt;

  @override
  Future<List<ImportedMemoryItem>> parseMemoryImport(String text) async =>
      (await api.imports.parseMemoryImport(
        parseMemoryImportRequest: ParseMemoryImportRequest(text: text),
      )).data!.memories;

  // Saved through the memory import route, which takes the same two kinds and seals the text.
  @override
  Future<void> addMemory(String botId, String content, {String kind = 'fact'}) async => saveImportedMemories(botId, [
    ImportedMemoryItem(kind: kind == 'preference' ? ImportedMemoryItemKindEnum.preference : ImportedMemoryItemKindEnum.fact, content: content),
  ]);

  @override
  Future<int> saveImportedMemories(
    String botId,
    List<ImportedMemoryItem> memories,
  ) async => (await api.imports.saveImportedMemories(
    id: botId,
    saveImportedMemoriesRequest: SaveImportedMemoriesRequest(
      memories: memories,
    ),
  )).data!.saved;

  @override
  Future<List<Plugin>> plugins(String botId) async =>
      (await api.plugins.listPlugins(botId: botId)).data!.items;

  @override
  Future<PluginPreview> previewPlugin(String orgId, String url, {String? commit}) async =>
      (await api.plugins.previewPlugin(
        previewPluginRequest: PreviewPluginRequest(orgId: orgId, url: url, commit: commit),
      )).data!;

  @override
  Future<List<DirectoryPlugin>> pluginDirectory() async =>
      (await api.plugins.listPluginDirectory()).data!.items;

  @override
  Future<List<RoutineIdea>> routineIdeas() async =>
      (await api.routines.listRoutineIdeas()).data!.items;

  @override
  Future<RemoteAppConfig> appConfig() async => (await api.system.getAppConfig()).data!;

  @override
  Future<RemoteAppConfig> adminAppConfig() async => (await api.admin.adminAppConfig()).data!;

  @override
  Future<RemoteAppConfig> setAdminAppConfig(Map<String, dynamic> settings) async =>
      (await api.admin.adminSetAppConfig(requestBody: settings)).data!;

  @override
  Future<Plugin> installPlugin(
    String orgId,
    String botId,
    String url,
    String commit,
    Map<String, String> secrets,
  ) async => (await api.plugins.installPlugin(
    installPluginRequest: InstallPluginRequest(
      orgId: orgId,
      botId: botId,
      url: url,
      commit: commit,
      secrets: secrets,
    ),
  )).data!;

  @override
  Future<PluginUpdatePreview> pluginUpdate(String id) async =>
      (await api.plugins.getPluginUpdate(id: id)).data!;

  @override
  Future<Plugin> updatePlugin(
    String id,
    String commit, {
    Map<String, String> secrets = const {},
  }) async => (await api.plugins.updatePlugin(
    id: id,
    updatePluginRequest: UpdatePluginRequest(commit: commit, secrets: secrets),
  )).data!;

  @override
  Future<void> uninstallPlugin(String id) async {
    await api.plugins.uninstallPlugin(id: id);
  }

  @override
  Future<TeachSession> startTeach(String computerId, String botId) async =>
      (await api.teach.startTeach(
        startTeachRequest: StartTeachRequest(
          computerId: computerId,
          botId: botId,
        ),
      )).data!;

  @override
  Future<TeachSession> teach(String id) async =>
      (await api.teach.getTeach(id: id)).data!;

  @override
  Future<TeachStep> addTeachStep(String id, AddTeachStepRequest step) async =>
      (await api.teach.addTeachStep(id: id, addTeachStepRequest: step)).data!;

  @override
  Future<TeachStep> markTeachSecret(String id, int seq, String name) async =>
      (await api.teach.markTeachSecret(
        id: id,
        seq: seq,
        markTeachSecretRequest: MarkTeachSecretRequest(secretName: name),
      )).data!;

  @override
  Future<TeachSession> stopTeach(String id) async =>
      (await api.teach.stopTeach(id: id)).data!;

  @override
  Future<SaveTeachResponse> saveTeach(
    String id, {
    required String name,
    required String description,
    required String body,
    bool tryNow = false,
  }) async => (await api.teach.saveTeach(
    id: id,
    saveTeachRequest: SaveTeachRequest(
      name: name,
      description: description,
      body: body,
      tryNow: tryNow,
    ),
  )).data!;

  @override
  Future<void> cancelTeach(String id) async {
    await api.teach.cancelTeach(id: id);
  }

  @override
  Future<List<BotPage>> pages(String orgId, {String? botId}) async =>
      (await api.pages.listPages(orgId: orgId, botId: botId)).data!.items;

  @override
  Future<String> pageViewLink(String id, {bool pdf = false}) async =>
      (await api.pages.createPageViewLink(
        id: id,
        pageViewLinkRequest: PageViewLinkRequest(
          format: pdf
              ? PageViewLinkRequestFormatEnum.pdf
              : PageViewLinkRequestFormatEnum.html,
        ),
      )).data!.url;

  @override
  Future<String?> setPageVisibility(
    String id,
    BotPageVisibilityEnum visibility, {
    int? expiresInDays,
  }) async => (await api.pages.updatePage(
    id: id,
    updatePageRequest: UpdatePageRequest(
      visibility: UpdatePageRequestVisibilityEnum.values.byName(
        visibility.name,
      ),
      expiresInDays: expiresInDays,
    ),
  )).data!.publicUrl;

  @override
  Future<void> deletePage(String id) async {
    await api.pages.deletePage(id: id);
  }

  @override
  Future<List<Watcher>> watchers(String botId) async =>
      (await api.watchers.listWatchers(botId: botId)).data!.items;

  @override
  Future<void> setWatcherPaused(String id, bool paused) async {
    await api.watchers.updateWatcher(
      id: id,
      updateWatcherRequest: UpdateWatcherRequest(
        status: paused
            ? UpdateWatcherRequestStatusEnum.paused
            : UpdateWatcherRequestStatusEnum.active,
      ),
    );
  }

  @override
  Future<void> deleteWatcher(String id) async {
    await api.watchers.deleteWatcher(id: id);
  }

  @override
  Future<List<ActionRule>> actionRules(String orgId, {String? botId}) async =>
      (await api.actionRules.listActionRules(
        orgId: orgId,
        botId: botId,
      )).data!.items;

  @override
  Future<void> createActionRule(
    String orgId, {
    String? botId,
    required String category,
    required String rule,
    List<String> domains = const [],
    double? maxAmount,
  }) async {
    final limited = domains.isNotEmpty || maxAmount != null;
    await api.actionRules.createActionRule(
      createActionRuleRequest: CreateActionRuleRequest(
        orgId: orgId,
        botId: botId,
        matchKind: CreateActionRuleRequestMatchKindEnum.category,
        matchValue: category,
        target: limited
            ? ActionRuleTarget(
                domains: domains.isEmpty ? null : domains,
                maxAmount: maxAmount,
              )
            : null,
        rule: CreateActionRuleRequestRuleEnum.values.firstWhere(
          (r) => r.value == rule,
        ),
      ),
    );
  }

  @override
  Future<void> deleteActionRule(String id) async {
    await api.actionRules.deleteActionRule(id: id);
  }

  @override
  Future<BotCheckins> botCheckins(String botId) async =>
      (await api.checkins.getBotCheckins(id: botId)).data!;

  @override
  Future<BotCheckins> setBotCheckins(
    String botId,
    BotCheckins settings,
  ) async => (await api.checkins.setBotCheckins(
    id: botId,
    botCheckins: settings,
  )).data!;

  @override
  Future<ForYou> forYou(String orgId) async =>
      (await api.checkins.getForYou(orgId: orgId)).data!;

  @override
  Future<AcceptedSuggestion> acceptSuggestion(String id) async =>
      (await api.checkins.acceptSuggestion(id: id)).data!;

  @override
  Future<void> dismissSuggestion(
    String id, {
    bool dontSuggestAgain = false,
  }) async {
    await api.checkins.dismissSuggestion(
      id: id,
      dismissSuggestionRequest: DismissSuggestionRequest(
        dontSuggestAgain: dontSuggestAgain,
      ),
    );
  }

  @override
  Future<List<Project>> projects(String orgId) async =>
      (await api.projects.listProjects(orgId: orgId)).data!.items;

  @override
  Future<Project> createProject(
    String orgId, {
    required String title,
    required String goal,
    String doneCriteria = '',
    required String leadBotId,
    double? budgetUsd,
  }) async => (await api.projects.createProject(
    createProjectRequest: CreateProjectRequest(
      orgId: orgId,
      title: title,
      goalMd: goal,
      doneCriteriaMd: doneCriteria,
      leadBotId: leadBotId,
      budgetUsd: budgetUsd,
    ),
  )).data!;

  @override
  Future<ProjectDetail> project(String projectId) async =>
      (await api.projects.getProject(id: projectId)).data!;

  @override
  Future<void> updateProject(
    String projectId, {
    String? status,
    double? budgetUsd,
  }) async {
    await api.projects.updateProject(
      id: projectId,
      updateProjectRequest: UpdateProjectRequest(
        status: status == null
            ? null
            : UpdateProjectRequestStatusEnum.values.firstWhere(
                (s) => s.value == status,
              ),
        budgetUsd: budgetUsd,
      ),
    );
  }

  @override
  Future<void> approveProjectPlan(String projectId) async {
    await api.projects.approveProjectPlan(id: projectId);
  }

  @override
  Future<void> signOffMilestone(String projectId, String milestoneId) async {
    await api.projects.signOffMilestone(
      id: projectId,
      milestoneId: milestoneId,
    );
  }

  @override
  Future<Task> createTask(
    String orgId, {
    required String title,
    String? details,
    String? priority,
    String? assigneeBotId,
    bool? reviewRequired,
  }) async => (await api.tasks.createTask(
    createTaskRequest: CreateTaskRequest(
      orgId: orgId,
      title: title,
      detailsMd: details,
      priority: priority == null
          ? null
          : TaskPriority.values.firstWhere((p) => p.value == priority),
      assigneeBotId: assigneeBotId,
      reviewRequired: reviewRequired,
    ),
  )).data!;

  @override
  Future<Task> updateTask(
    String taskId, {
    String? title,
    String? details,
    String? status,
    String? priority,
    String? assigneeBotId,
    String? assigneeUserId,
    bool? reviewRequired,
    double? position,
  }) async => (await api.tasks.updateTask(
    id: taskId,
    updateTaskRequest: UpdateTaskRequest(
      title: title,
      detailsMd: details,
      status: status == null
          ? null
          : TaskStatus.values.firstWhere((s) => s.value == status),
      priority: priority == null
          ? null
          : TaskPriority.values.firstWhere((p) => p.value == priority),
      assigneeBotId: assigneeBotId,
      assigneeUserId: assigneeUserId,
      reviewRequired: reviewRequired,
      position: position,
    ),
  )).data!;

  @override
  Future<void> deleteTask(String taskId) async =>
      api.tasks.deleteTask(id: taskId);

  @override
  Future<List<TaskComment>> taskComments(String taskId) async =>
      (await api.tasks.listTaskComments(id: taskId)).data!.items;

  @override
  Future<TaskComment> addTaskComment(String taskId, String body) async =>
      (await api.tasks.createTaskComment(
        id: taskId,
        createTaskCommentRequest: CreateTaskCommentRequest(bodyMd: body),
      )).data!;

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
  Future<List<AdminUser>> adminUsers() async =>
      (await api.admin.adminUsers()).data!.items;
  @override
  Future<List<AdminOrg>> adminOrgs() async =>
      (await api.admin.adminOrgs()).data!.items;
  @override
  Future<AdminOrg> setOrgLimits(String orgId, Map<String, num> limits) async =>
      (await api.admin.setOrgLimits(
        id: orgId,
        setOrgLimitsRequest: SetOrgLimitsRequest(limits: limits),
      )).data!;
  @override
  Future<AdminOrg> suspendOrg(String orgId, String reason) async =>
      (await api.admin.suspendOrg(
        id: orgId,
        suspendOrgRequest: SuspendOrgRequest(reason: reason),
      )).data!;
  @override
  Future<AdminOrg> unsuspendOrg(String orgId) async =>
      (await api.admin.unsuspendOrg(id: orgId)).data!;
  @override
  Future<List<AbuseEvent>> adminAbuseEvents() async =>
      (await api.admin.adminAbuseEvents()).data!.items;
  @override
  Future<List<AdminService>> adminServices() async =>
      (await api.admin.adminServices()).data!.items;
  @override
  Future<UpdateNotice> adminUpdates() async =>
      (await api.admin.adminUpdates()).data!;
  @override
  Future<ConnectionSettings> adminConnectionSettings() async =>
      (await api.admin.adminConnectionSettings()).data!;
  @override
  Future<CloudModels> adminCloudModels() async =>
      (await api.admin.adminCloudModels()).data!;
  @override
  Future<ServerCapacity> adminCapacity() async => (await api.admin.adminCapacity()).data!;
  @override
  Future<CloudModels> setAdminCloudModels(CloudModels models) async =>
      (await api.admin.setAdminCloudModels(cloudModels: models)).data!;
  @override
  Future<AdminPricing> adminPricing() async => (await api.admin.adminPricing()).data!;
  @override
  Future<AdminPlan> saveAdminPlan(String code, SavePlanRequest plan) async =>
      (await api.admin.savePlan(code: code, savePlanRequest: plan)).data!;
  @override
  Future<AdminCreditPack> saveAdminCreditPack(String code, SaveCreditPackRequest pack) async =>
      (await api.admin.saveCreditPack(code: code, saveCreditPackRequest: pack)).data!;
  @override
  Future<BillingSettings> setAdminBillingSettings(BillingSettings settings) async =>
      (await api.admin.setBillingSettings(billingSettings: settings)).data!;
  @override
  Future<ConnectionSettings> setAdminConnectionSettings({
    bool? serverComposio,
    bool? googleDirect,
  }) async => (await api.admin.setAdminConnectionSettings(
    setConnectionSettingsRequest: SetConnectionSettingsRequest(
      composio: serverComposio == null
          ? null
          : serverComposio
          ? SetConnectionSettingsRequestComposioEnum.server
          : SetConnectionSettingsRequestComposioEnum.own,
      google: googleDirect == null
          ? null
          : googleDirect
          ? SetConnectionSettingsRequestGoogleEnum.direct
          : SetConnectionSettingsRequestGoogleEnum.composio,
    ),
  )).data!;

  // --- privacy and SSO (Phase 8) ------------------------------------------

  @override
  Future<Uint8List> exportMyData() async =>
      (await api.privacy.exportMyData()).data!;
  @override
  Future<void> setAnalyticsOptOut(bool optOut) async {
    await api.privacy.setAnalyticsOptOut(
      setAnalyticsOptOutRequest: SetAnalyticsOptOutRequest(optOut: optOut),
    );
  }

  @override
  Future<bool> orgAnalyticsOptOut(String orgId) async =>
      (await api.privacy.getOrgSettings(id: orgId)).data!.analyticsOptOut ?? false;
  @override
  Future<void> setOrgAnalyticsOptOut(String orgId, bool optOut) async {
    await api.privacy.updateOrgSettings(
      id: orgId,
      updateOrgSettingsRequest: UpdateOrgSettingsRequest(analyticsOptOut: optOut),
    );
  }
  @override
  Future<AccountDeletion> deleteAccount(String confirmEmail) async {
    final r = (await api.privacy.deleteMyAccount(
      deleteAccountRequest: DeleteAccountRequest(confirmEmail: confirmEmail),
    )).data!;
    await supabase.auth.signOut().catchError((_) {});
    return r;
  }

  // --- two-step sign-in (D-093) ---------------------------------------------

  @override
  Future<List<TwoStepFactor>> twoStepFactors() async => [
    for (final f in (await supabase.auth.mfa.listFactors()).totp)
      TwoStepFactor(
        id: f.id,
        name: f.friendlyName ?? 'Authenticator',
        createdAt: f.createdAt,
      ),
  ];

  @override
  bool get twoStepCodeNeeded {
    if (supabase.auth.currentSession == null) return false;
    final l = supabase.auth.mfa.getAuthenticatorAssuranceLevel();
    return l.currentLevel == sb.AuthenticatorAssuranceLevels.aal1 &&
        l.nextLevel == sb.AuthenticatorAssuranceLevels.aal2;
  }

  @override
  bool get twoStepVerified =>
      supabase.auth.currentSession != null &&
      supabase.auth.mfa.getAuthenticatorAssuranceLevel().currentLevel ==
          sb.AuthenticatorAssuranceLevels.aal2;

  @override
  Future<TwoStepEnrollment> startTwoStep() async {
    // Friendly names must be unique per account; unfinished setups are cleared first.
    final all = (await supabase.auth.mfa.listFactors()).all;
    for (final f in all.where((f) => f.status == sb.FactorStatus.unverified)) {
      await supabase.auth.mfa.unenroll(f.id);
    }
    final n = all.where((f) => f.status == sb.FactorStatus.verified).length + 1;
    final r = await supabase.auth.mfa.enroll(
      factorType: sb.FactorType.totp,
      issuer: config?.productName ?? 'Casama',
      friendlyName:
          'Authenticator $n · ${DateTime.now().millisecondsSinceEpoch}',
    );
    final totp = r.totp!;
    return TwoStepEnrollment(
      factorId: r.id,
      secret: totp.secret,
      uri: totp.uri,
      qrSvg: totp.qrCode,
    );
  }

  @override
  Future<void> verifyTwoStep(String factorId, String code) async {
    await supabase.auth.mfa.challengeAndVerify(
      factorId: factorId,
      code: code.trim(),
    );
  }

  @override
  Future<void> passTwoStep(String code) async {
    final factors = (await supabase.auth.mfa.listFactors()).totp;
    if (factors.isEmpty) return;
    Object? lastError;
    // Any of the person's authenticators may have produced the code.
    for (final f in factors) {
      try {
        await supabase.auth.mfa.challengeAndVerify(
          factorId: f.id,
          code: code.trim(),
        );
        return;
      } catch (e) {
        lastError = e;
      }
    }
    throw lastError!;
  }

  @override
  Future<void> renameTwoStep(String factorId, String name) async {
    await api.privacy.renameTwoStepFactor(
      id: factorId,
      renameTwoStepFactorRequest: RenameTwoStepFactorRequest(name: name),
    );
  }

  @override
  Future<void> removeTwoStep(String factorId) async {
    await supabase.auth.mfa.unenroll(factorId);
    await supabase.auth.refreshSession();
  }

  @override
  Future<bool> requireTwoStep(String orgId) async =>
      (await api.privacy.getOrgSettings(id: orgId)).data!.requireMfa;

  @override
  Future<bool> setRequireTwoStep(String orgId, bool value) async =>
      (await api.privacy.updateOrgSettings(
        id: orgId,
        updateOrgSettingsRequest: UpdateOrgSettingsRequest(requireMfa: value),
      )).data!.requireMfa;

  @override
  Future<int> retentionDays(String orgId) async =>
      (await api.privacy.getOrgSettings(id: orgId)).data!.runEventRetentionDays;
  @override
  Future<int> setRetentionDays(String orgId, int days) async =>
      (await api.privacy.updateOrgSettings(
        id: orgId,
        updateOrgSettingsRequest: UpdateOrgSettingsRequest(
          runEventRetentionDays: days,
        ),
      )).data!.runEventRetentionDays;
  @override
  Future<void> signInWithSso(String email) async {
    final domain = email.split('@').last.trim().toLowerCase();
    if (_loopback) {
      return _signInThroughLoopback(
        (redirect) =>
            supabase.auth.getSSOSignInUrl(domain: domain, redirectTo: redirect),
      );
    }
    await supabase.auth.signInWithSSO(domain: domain, redirectTo: _authRedirect);
  }

  // --- billing (Phase 7) ---------------------------------------------------

  @override
  Future<BillingSummary> billing(String orgId) async =>
      (await api.billing.getBilling(id: orgId)).data!;
  @override
  Future<PlanCatalog> plans() async => (await api.billing.listPlans()).data!;
  @override
  Future<String?> checkoutUrl(
    String orgId, {
    String? planCode,
    String? packCode,
  }) async {
    final r = (await api.billing.createCheckout(
      id: orgId,
      checkoutRequest: CheckoutRequest(planCode: planCode, packCode: packCode),
    )).data!;
    return r.changed == true ? null : r.url;
  }
  @override
  Future<BillingSummary> setExtraSeats(String orgId, int extra) async =>
      (await api.billing.setBillingSeats(id: orgId, seatsRequest: SeatsRequest(extra: extra))).data!;
  @override
  Future<String> billingPortalUrl(String orgId) async =>
      (await api.billing.billingPortal(
        id: orgId,
        portalRequest: PortalRequest(),
      )).data!.url;
  @override
  Future<BillingSummary> verifyPurchase(
    String orgId, {
    required String source,
    required String productId,
    String? transactionId,
    String? purchaseToken,
  }) async => (await api.billing.verifyPurchase(
    id: orgId,
    purchaseRequest: PurchaseRequest(
      source_: source == 'app_store'
          ? PurchaseRequestSource_Enum.appStore
          : PurchaseRequestSource_Enum.googlePlay,
      productId: productId,
      transactionId: transactionId,
      purchaseToken: purchaseToken,
    ),
  )).data!;
  @override
  Future<BillingUsage> billingUsage(String orgId) async =>
      (await api.billing.billingUsage(id: orgId)).data!;
  @override
  Future<List<ConnectKey>> connectKeys(String orgId) async =>
      (await api.billing.listConnectKeys(id: orgId)).data!.items;
  @override
  Future<CreatedConnectKey> createConnectKey(
    String orgId,
    String instanceName,
  ) async => (await api.billing.createConnectKey(
    id: orgId,
    createConnectKeyRequest: CreateConnectKeyRequest(
      instanceName: instanceName,
    ),
  )).data!;
  @override
  Future<void> revokeConnectKey(String orgId, String keyId) =>
      api.billing.revokeConnectKey(id: orgId, keyId: keyId);

  // --- desktop companion (Phase 6) -----------------------------------------

  @override
  String get apiUrl => api.baseUrl;

  @override
  Future<List<LocalDevice>> localDevices(String orgId) async =>
      (await api.localComputer.listLocalDevices(orgId: orgId)).data!.items;

  @override
  Future<CreatedLocalDevice> createLocalDevice(
    String orgId,
    String name,
    String platform,
  ) async => (await api.localComputer.createLocalDevice(
    createLocalDeviceRequest: CreateLocalDeviceRequest(
      orgId: orgId,
      name: name,
      platform: CreateLocalDeviceRequestPlatformEnum.values.firstWhere(
        (p) => p.value == platform,
      ),
    ),
  )).data!;

  @override
  Future<List<Integration>> setLocalMcpServers(
    String deviceId,
    List<LocalMcpServerInfo> servers,
  ) async => (await api.localComputer.setLocalMcpServers(
    id: deviceId,
    setLocalMcpServersRequest: SetLocalMcpServersRequest(servers: servers),
  )).data!.items;

  @override
  Future<LocalDevice> updateLocalDevice(
    String id, {
    Set<String>? capabilities,
    List<String>? roots,
    List<String>? botIds,
    bool? enabled,
  }) async => (await api.localComputer.updateLocalDevice(
    id: id,
    updateLocalDeviceRequest: UpdateLocalDeviceRequest(
      capabilities: capabilities == null
          ? null
          : LocalCapabilities(
              shell: capabilities.contains('shell'),
              files: capabilities.contains('files'),
              browser: capabilities.contains('browser'),
              desktop: capabilities.contains('desktop'),
              mcp: capabilities.contains('mcp'),
              messages: capabilities.contains('messages'),
            ),
      allowedRoots: roots,
      allowedBotIds: botIds,
      enabled: enabled,
    ),
  )).data!;

  @override
  Future<void> deleteLocalDevice(String id) async =>
      api.localComputer.deleteLocalDevice(id: id);

  // --- voice (Phase 6) -------------------------------------------------------

  @override
  Future<String> transcribe(String botId, Uint8List audio, String mime) async =>
      (await api.transcribe(botId, audio, mime: mime)).text;

  @override
  Future<Uint8List> speech(String messageId) async =>
      (await api.voice.messageSpeech(id: messageId)).data!;

  @override
  Future<VoiceSession> voiceSession(
    String botId, {
    String? conversationId,
    String? callId,
  }) async => (await api.voice.createVoiceSession(
    voiceSessionRequest: VoiceSessionRequest(
      botId: botId,
      conversationId: conversationId,
      callId: callId,
    ),
  )).data!;

  @override
  Future<VoiceToolResult> voiceTool(
    String botId,
    String conversationId,
    String callId,
    String name,
    Map<String, Object?> arguments,
  ) async => (await api.voice.voiceTool(
    voiceToolRequest: VoiceToolRequest(
      botId: botId,
      conversationId: conversationId,
      callId: callId,
      name: name,
      arguments: arguments,
    ),
  )).data!;

  @override
  Future<void> saveVoiceTranscript(
    String conversationId,
    List<(String, String)> turns,
    int seconds, {
    String? provider,
    Map<String, int>? usage,
  }) async => api.voice.saveVoiceTranscript(
    voiceTranscriptRequest: VoiceTranscriptRequest(
      conversationId: conversationId,
      seconds: seconds,
      provider: VoiceTranscriptRequestProviderEnum.values
          .where((p) => p.value == provider)
          .firstOrNull,
      usage: usage == null
          ? null
          : VoiceTranscriptRequestUsage(
              inputAudioTokens: usage['input_audio_tokens'] ?? 0,
              inputTextTokens: usage['input_text_tokens'] ?? 0,
              outputAudioTokens: usage['output_audio_tokens'] ?? 0,
              outputTextTokens: usage['output_text_tokens'] ?? 0,
            ),
      turns: [
        for (final (role, text) in turns)
          VoiceTranscriptRequestTurnsInner(
            role: VoiceTranscriptRequestTurnsInnerRoleEnum.values.firstWhere(
              (r) => r.value == role,
            ),
            text: text,
          ),
      ],
    ),
  );

  @override
  Future<void> updateBotVoice(String botId, Map<String, Object?> voice) async {
    final merged = {...await loadBotVoice(botId), ...voice}
      ..removeWhere((_, v) => v == null);
    await supabase.from('bots').update({'voice': merged}).eq('id', botId);
  }

  @override
  Future<Map<String, Object?>> loadBotVoice(String botId) async {
    final row = await supabase
        .from('bots')
        .select('voice')
        .eq('id', botId)
        .maybeSingle();
    final v = row?['voice'];
    return v is Map ? v.cast<String, Object?>() : <String, Object?>{};
  }

  // --- computer management and live view (Phase 5) -------------------------

  @override
  Future<Computer> createComputer(
    String orgId, {
    required String name,
    required bool private,
    String? ownerBotId,
    String profile = 'headless',
  }) async => (await api.computers.createComputer(
    createComputerRequest: CreateComputerRequest(
      orgId: orgId,
      name: name,
      kind: private
          ? CreateComputerRequestKindEnum.private
          : CreateComputerRequestKindEnum.team,
      ownerBotId: ownerBotId,
      profile: CreateComputerRequestProfileEnum.values.firstWhere(
        (p) => p.value == profile,
      ),
    ),
  )).data!;

  @override
  Future<Computer> updateComputer(
    String computerId, {
    String? name,
    String? profile,
    int? maxDesktops,
    int? idleSleepMinutes,
  }) async => (await api.computers.updateComputer(
    id: computerId,
    updateComputerRequest: UpdateComputerRequest(
      name: name,
      maxDesktops: maxDesktops,
      idleSleepMinutes: idleSleepMinutes,
      profile: profile == null
          ? null
          : UpdateComputerRequestProfileEnum.values.firstWhere(
              (p) => p.value == profile,
            ),
    ),
  )).data!;

  @override
  Future<void> deleteComputer(String computerId) async =>
      api.computers.deleteComputer(id: computerId);

  @override
  Future<void> setBotComputer(String botId, String? computerId) async {
    await supabase
        .from('bots')
        .update({'default_computer_id': computerId})
        .eq('id', botId);
  }

  @override
  Future<StreamSession> streamSession(
    String computerId, {
    String mode = 'control',
  }) async => (await api.computers.createStreamSession(
    id: computerId,
    streamSessionRequest: StreamSessionRequest(
      mode: StreamMode.values.firstWhere((m) => m.value == mode),
    ),
  )).data!;

  @override
  Future<Lease> lease(String computerId) async =>
      (await api.computers.getLease(id: computerId)).data!;

  @override
  Future<Lease> takeLease(String computerId, {bool allowShell = false}) async =>
      (await api.computers.takeLease(
        id: computerId,
        takeLeaseRequest: TakeLeaseRequest(allowShell: allowShell),
      )).data!;

  @override
  Future<Lease> releaseLease(String computerId, {String? note}) async =>
      (await api.computers.releaseLease(
        id: computerId,
        releaseLeaseRequest: ReleaseLeaseRequest(note: note),
      )).data!;

  @override
  Future<void> fulfillSecretRequest(String requestId, String value) async {
    await api.secrets.fulfillSecretRequest(
      id: requestId,
      fulfillSecretRequestBody: FulfillSecretRequestBody(value: value),
    );
  }

  @override
  Future<void> declineSecretRequest(String requestId) async {
    await api.secrets.declineSecretRequest(id: requestId);
  }

  @override
  Future<String> secretRequestStatus(String requestId) async {
    final row = await supabase
        .from('secret_requests')
        .select('status, expires_at')
        .eq('id', requestId)
        .maybeSingle();
    if (row == null) return 'expired';
    final status = row['status'] as String? ?? 'expired';
    final expires = DateTime.tryParse('${row['expires_at']}');
    if (status == 'pending' && expires != null && expires.isBefore(DateTime.now())) {
      return 'expired';
    }
    return status;
  }

  @override
  Future<List<DeviceSource>> deviceSources() async =>
      (await api.devices.listDeviceSources()).data!.items;

  @override
  Future<DeviceSource> saveDeviceSource(
    String key, {
    required String name,
    required String platform,
    required Map<String, DeviceKindSettings> kinds,
  }) async => (await api.devices.saveDeviceSource(
    key: key,
    saveDeviceSourceRequest: SaveDeviceSourceRequest(
      name: name,
      platform: SaveDeviceSourceRequestPlatformEnum.values.firstWhere(
        (p) => p.value == platform,
      ),
      kinds: SaveDeviceSourceRequestKinds.fromJson({
        for (final e in kinds.entries) e.key: e.value.toJson(),
      }),
    ),
  )).data!;

  @override
  Future<void> deleteDeviceSource(String key) async =>
      api.devices.deleteDeviceSource(key: key);

  @override
  Future<int> uploadDeviceReadings(
    String key,
    List<DeviceReadingInput> readings, {
    String? requestId,
  }) async => (await api.devices.uploadDeviceReadings(
    key: key,
    uploadDeviceReadingsRequest: UploadDeviceReadingsRequest(
      readings: readings,
      requestId: requestId,
    ),
  )).data!.stored;

  @override
  Future<List<DeviceRequest>> deviceRequests(String key) async =>
      (await api.devices.listDeviceRequests(key: key)).data!.items;

  @override
  Future<void> answerDeviceRequest(
    String id, {
    required bool ok,
    Map<String, Object?>? result,
    String? error,
  }) async => api.devices.answerDeviceRequest(
    id: id,
    deviceRequestResult: DeviceRequestResult(
      ok: ok,
      result: result,
      error: error,
    ),
  );

  @override
  Future<List<DeviceGrant>> deviceGrants({String? botId}) async =>
      (await api.devices.listDeviceGrants(botId: botId)).data!.items;

  @override
  Future<List<DeviceGrant>> setDeviceGrant(
    String botId,
    DeviceKind kind,
    bool allowed,
  ) async => (await api.devices.setDeviceGrant(
    setDeviceGrantRequest: SetDeviceGrantRequest(
      botId: botId,
      kind: kind,
      allowed: allowed,
    ),
  )).data!.items;

  @override
  Future<int> reportDeviceEvents(
    String key,
    List<DeviceEventInput> events,
  ) async => (await api.devices.reportDeviceEvents(
    key: key,
    reportDeviceEventsRequest: ReportDeviceEventsRequest(events: events),
  )).data!.runs;

  @override
  Future<List<DevicePlace>> devicePlaces() async =>
      (await api.devices.listDevicePlaces()).data!.items;

  @override
  Future<DevicePlace> saveDevicePlace({
    required String name,
    required double latitude,
    required double longitude,
    int? radiusM,
  }) async => (await api.devices.saveDevicePlace(
    saveDevicePlaceRequest: SaveDevicePlaceRequest(
      name: name,
      latitude: latitude,
      longitude: longitude,
      radiusM: radiusM,
    ),
  )).data!;

  @override
  Future<void> deleteDevicePlace(String id) async =>
      api.devices.deleteDevicePlace(id: id);

  @override
  Future<void> lessLikeThis(String notificationId) async =>
      api.notifications.lessLikeThis(id: notificationId);

  @override
  Stream<String> watchDeviceRequests() =>
      _userEvents('device_request')
          .map((m) => '${m['id'] ?? ''}')
          .where((id) => id.isNotEmpty);

  @override
  Future<List<TakeoverRequest>> takeovers(String orgId) async =>
      (await api.computers.listTakeovers(orgId: orgId)).data!.items;

  @override
  Future<void> dismissTakeover(String takeoverId, {String? note}) async =>
      api.computers.dismissTakeover(
        id: takeoverId,
        releaseLeaseRequest: ReleaseLeaseRequest(note: note),
      );

  // --- computers ------------------------------------------------------------

  @override
  Future<List<Computer>> computers(String orgId) async =>
      (await api.computers.listComputers(orgId: orgId)).data!.items;

  @override
  Future<Computer> startComputer(String id) async =>
      (await api.computers.startComputer(id: id)).data!;

  @override
  Future<Computer> stopComputer(String id) async =>
      (await api.computers.stopComputer(id: id)).data!;

  @override
  Future<List<ComputerFileEntry>> listFiles(
    String computerId,
    String path,
  ) async => (await api.computers.listComputerFiles(
    id: computerId,
    path: path.isEmpty ? null : path,
  )).data!.entries;

  @override
  Future<Uint8List> downloadFile(String computerId, String path) async =>
      Uint8List.fromList(await api.downloadComputerFile(computerId, path));

  @override
  Future<Uint8List?> computerFilePdf(String computerId, String path) async {
    // 415: not an Office file; 422: the computer couldn't convert it (D-205).
    final res = await api.computers.computerFilePdfPreview(
      id: computerId,
      path: path,
      validateStatus: (s) => s != null && (s < 300 || s == 415 || s == 422),
    );
    if (res.statusCode != null && res.statusCode! >= 300) return null;
    return res.data;
  }

  @override
  Future<ComputerThumbnail?> computerThumbnail(
    String computerId,
    String path, {
    int size = 480,
  }) async {
    try {
      // 404: no thumbnail for this file; 409: the computer is asleep or offline (D-226).
      final res = await api.computers.computerFileThumbnail(
        id: computerId,
        path: path,
        size: size,
        validateStatus: (s) => s != null && (s < 300 || s == 404 || s == 409),
      );
      final bytes = res.data;
      if ((res.statusCode ?? 500) >= 300 || bytes == null || bytes.isEmpty) {
        return null;
      }
      int? header(String name) => int.tryParse(res.headers.value(name) ?? '');
      final ms = header('x-duration-ms');
      return ComputerThumbnail(
        bytes: bytes,
        duration: ms == null ? null : Duration(milliseconds: ms),
        modifiedMs: header('x-file-mtime'),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Uint8List> chatMedia(String id) async {
    final res = await api.api.dio.get<List<int>>(
      '/v1/media/$id',
      options: Options(
        responseType: ResponseType.bytes,
        headers: authHeaders,
        receiveTimeout: const Duration(seconds: 120),
      ),
    );
    return Uint8List.fromList(res.data!);
  }

  @override
  String chatMediaUrl(String id) =>
      '${api.baseUrl.replaceAll(RegExp(r'/+$'), '')}/v1/media/$id';

  @override
  String chatMediaPosterUrl(String id) => '${chatMediaUrl(id)}/poster';

  @override
  Future<CreationList> creations(
    String orgId, {
    CreationKind? kind,
    String? botId,
    String? conversationId,
    String? q,
    String? cursor,
    bool recentlyOpened = false,
    bool deleted = false,
    int limit = 60,
  }) async => (await api.creations.listCreations(
    orgId: orgId,
    kind: kind,
    botId: botId,
    conversationId: conversationId,
    q: (q == null || q.trim().isEmpty) ? null : q.trim(),
    cursor: cursor,
    sort: recentlyOpened ? 'opened' : null,
    deleted: deleted ? 'true' : null,
    limit: limit,
  )).data!;

  @override
  Future<CreationDetail> creation(String id) async => (await api.creations.getCreation(id: id)).data!;

  @override
  Future<Creation> updateCreation(String id, {String? title, bool? pinned, bool? opened}) async =>
      (await api.creations.updateCreation(
        id: id,
        updateCreationRequest: UpdateCreationRequest(title: title, pinned: pinned, opened: opened),
      )).data!;

  @override
  Future<void> deleteCreation(String id) async => api.creations.deleteCreation(id: id);

  @override
  Future<void> restoreCreation(String id) async => api.creations.restoreCreation(id: id);

  @override
  String creationContentUrl(String id) => '${api.baseUrl.replaceAll(RegExp(r'/+$'), '')}/v1/creations/$id/content';

  @override
  String creationCoverUrl(String id) => '${api.baseUrl.replaceAll(RegExp(r'/+$'), '')}/v1/creations/$id/cover';

  @override
  Future<Uint8List> creationContent(String id) async {
    final res = await api.api.dio.get<List<int>>(
      '/v1/creations/$id/content',
      options: Options(responseType: ResponseType.bytes, headers: authHeaders, receiveTimeout: const Duration(seconds: 120)),
    );
    return Uint8List.fromList(res.data!);
  }

  @override
  Map<String, String> get authHeaders {
    final token = supabase.auth.currentSession?.accessToken;
    return {if (token != null) 'Authorization': 'Bearer $token'};
  }

  @override
  Future<void> uploadFile(
    String computerId,
    String path,
    Uint8List bytes,
  ) async => api.uploadComputerFile(computerId, path, bytes);

  @override
  Future<void> deleteFile(String computerId, String path) async =>
      api.computers.deleteComputerFile(id: computerId, path: path);

  @override
  Future<List<Checkpoint>> checkpoints(String computerId) async =>
      (await api.computers.listCheckpoints(id: computerId)).data!.items;

  @override
  Future<void> restoreCheckpoint(
    String computerId,
    String checkpointId,
  ) async => api.computers.restoreCheckpoint(id: computerId, cid: checkpointId);

  /// Null when the computer is asleep (409): reading never wakes it.
  Future<T?> _whileRunning<T>(Future<Response<T>> Function() call) async {
    try {
      return (await call()).data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) return null;
      rethrow;
    }
  }

  @override
  Future<Computer> restartComputer(String id) async =>
      (await api.computers.restartComputer(id: id)).data!;

  @override
  Future<Computer> resetComputer(String id, {required bool erase, bool checkpoint = true}) async =>
      (await api.computers.resetComputer(
        id: id,
        resetComputerRequest: ResetComputerRequest(
          mode: erase ? ResetComputerRequestModeEnum.erase : ResetComputerRequestModeEnum.system,
          checkpoint: checkpoint,
        ),
      )).data!;

  @override
  Future<ComputerVitals?> computerVitals(String id) =>
      _whileRunning(() => api.computers.computerVitals(id: id));

  @override
  Future<ComputerStorage?> computerStorage(String id) =>
      _whileRunning(() => api.computers.computerStorage(id: id));

  @override
  Future<CleanStorageResult> cleanComputerStorage(String id) async =>
      (await api.computers.cleanComputerStorage(id: id)).data!;

  @override
  Future<List<ComputerProcess>?> computerProcesses(String id) async =>
      (await _whileRunning(() => api.computers.listComputerProcesses(id: id)))?.items;

  @override
  Future<void> stopComputerProcess(String id, int pid) async =>
      api.computers.stopComputerProcess(id: id, pid: pid);

  @override
  Future<ComputerUsage> computerUsage(String id) async =>
      (await api.computers.computerUsage(id: id)).data!;

  @override
  Future<List<ComputerHistoryEntry>> computerHistory(String id) async =>
      (await api.computers.computerHistory(id: id)).data!.items;

  @override
  Future<List<ComputerBotUse>> computerBots(String id) async =>
      (await api.computers.computerBots(id: id)).data!.items;

  @override
  Future<Checkpoint> createCheckpoint(String id, String label) async =>
      (await api.computers.createCheckpoint(
        id: id,
        createCheckpointRequest: CreateCheckpointRequest(label: label),
      )).data!;

  @override
  Future<Uint8List?> downloadComputerArchive(String id) async {
    try {
      return (await api.computers.downloadComputerArchive(id: id)).data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) return null;
      rethrow;
    }
  }

  @override
  Future<Uint8List?> screenshot(String computerId) async {
    try {
      return (await api.computers.computerScreenshot(id: computerId)).data;
    } on DioException catch (e) {
      // Nothing on screen (no desktop, no page open): say so, so the last picture is cleared.
      if (e.response?.statusCode == 409) return Uint8List(0);
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<(Uri, Map<String, String>)> terminal(
    String computerId, {
    int cols = 100,
    int rows = 30,
  }) async {
    final (uri, headers) = await api.terminalEndpoint(
      computerId,
      cols: cols,
      rows: rows,
    );
    // Browsers cannot set WebSocket headers, so the token also travels as a query parameter.
    final token = supabase.auth.currentSession?.accessToken;
    return (
      uri.replace(
        queryParameters: {...uri.queryParameters, 'access_token': ?token},
      ),
      headers,
    );
  }
}

String _solvePuzzle((String, int) p) => solveSignupChallenge(p.$1, p.$2);
