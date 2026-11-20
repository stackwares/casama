import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';

/// Mounted only while the native admin screen is available. Never persists an unlock.
class AdminSecurity {
  static Future<bool> Function(bool sensitive)? authenticate;
  static bool Function()? isUnlocked;
  static void Function()? lock;

  /// Owner actions outside the console (approving an admin bot card, making a sign-in code): a
  /// fresh sign-in in a dialog over whatever screen is open. Set once by the app.
  static Future<bool> Function()? confirmAnywhere;

  /// Admin sign-in forms on screen. While one is, the router leaves a session that still owes its
  /// two-step code where it is, so the form can ask for the code itself. Opening one needs no
  /// redirect; the last one closing wakes the router (after the frame) to send such a session on.
  static int openAuthForms = 0;
  static final authFormsClosed = ChangeNotifier();
  static void authFormOpened() => openAuthForms++;
  static void authFormClosed() {
    openAuthForms--;
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    if (openAuthForms == 0) scheduleMicrotask(authFormsClosed.notifyListeners);
  }

  /// The last fresh sign-in through an admin form, and whose. The server accepts a write for 60
  /// seconds after one, so the app doesn't ask again within [grace].
  static DateTime? lastVerified;
  static String? lastVerifiedBy;

  /// How the last fresh check was made ('pin', 'passkey', 'password'): changing the PIN takes a
  /// passkey or password, never the PIN (D-452).
  static String? lastVerifiedMethod;
  static const grace = Duration(seconds: 45);

  static bool recentlyVerified(String? userId) =>
      userId != null &&
      userId == lastVerifiedBy &&
      lastVerified != null &&
      DateTime.now().difference(lastVerified!) < grace;

  static void verified(String? userId, {String method = 'password'}) {
    lastVerified = DateTime.now();
    lastVerifiedBy = userId;
    lastVerifiedMethod = method;
  }

  static void forgetVerification() {
    lastVerified = null;
    lastVerifiedBy = null;
    lastVerifiedMethod = null;
  }

  /// The last passkey or PIN check the server recorded, and on which sign-in session (D-452). It
  /// outlives the console's lock: it's what the server will still accept, for the Face ID unlock.
  static DateTime? checkAt;
  static String? checkSession;

  static void checked(DateTime at) {
    checkAt = at;
    checkSession = _claims()?['session_id'] as String?;
  }

  /// An emailed code is remembered across a lock (reading the email in another app locks the
  /// console on a phone), so the code field is still there on return.
  static String? codeSentTo;
  static DateTime? codeSentAt;
  static bool codeSentFor(String? userId) =>
      userId != null &&
      userId == codeSentTo &&
      codeSentAt != null &&
      DateTime.now().difference(codeSentAt!) < const Duration(minutes: 10);

  /// The signed-in session's access token. Set once by the app's backend.
  static String? Function()? accessToken;

  /// Sign-ins the server counts (apps/server/src/api/admin-security.ts); a refresh never does.
  static const _interactiveMethods = {
    'password',
    'otp',
    'totp',
    'oauth',
    'sso/saml',
    'magiclink',
    'passkey',
  };

  /// The server's read window for the admin console (`ADMIN_READ_WINDOW_SECONDS`).
  static const serverReadWindow = Duration(minutes: 5);

  /// How long the server will still accept this session's latest real sign-in for admin reads,
  /// read from the token's signed `amr` (D-450). Null without a token or a real sign-in in it.
  static Map<String, dynamic>? _claims() {
    final token = accessToken?.call();
    if (token == null) return null;
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final claims = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      return claims is Map<String, dynamic> ? claims : null;
    } catch (_) {
      return null;
    }
  }

  /// How long the server will still accept this session's last passkey or PIN check for admin
  /// reads (D-452). Null without one on this session.
  static Duration? checkWindowLeft({DateTime? now}) {
    final at = checkAt;
    final session = _claims()?['session_id'];
    if (at == null || session == null || session != checkSession) return null;
    final left = serverReadWindow - (now ?? DateTime.now()).difference(at);
    return left.isNegative ? Duration.zero : left;
  }

  static Duration? serverWindowLeft({DateTime? now}) {
    final token = accessToken?.call();
    if (token == null) return null;
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final claims = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      final amr = claims is Map ? claims['amr'] : null;
      if (amr is! List) return null;
      int? newest;
      for (final e in amr) {
        if (e is! Map || !_interactiveMethods.contains(e['method'])) continue;
        final t = e['timestamp'];
        if (t is num && (newest == null || t > newest)) newest = t.toInt();
      }
      if (newest == null) return null;
      final at = DateTime.fromMillisecondsSinceEpoch(newest * 1000);
      final left = serverReadWindow - (now ?? DateTime.now()).difference(at);
      return left.isNegative ? Duration.zero : left;
    } catch (_) {
      return null;
    }
  }

  /// System sheets open (a passkey, Face ID). Some pause the app while they're up (Android's
  /// Credential Manager); that isn't leaving it, so nothing locks meanwhile.
  static int systemSheets = 0;

  /// Runs a system sheet without it counting as leaving the app. Waits briefly for the app to come
  /// back to the foreground afterwards; still away then, the console locks.
  static Future<T> duringSystemSheet<T>(Future<T> Function() run) async {
    systemSheets++;
    try {
      return await run();
    } finally {
      final back = await _foreground();
      systemSheets--;
      if (!back) lock?.call();
    }
  }

  static Future<bool> _foreground() async {
    final binding = WidgetsBinding.instance;
    final state = binding.lifecycleState;
    if (state == null || state == AppLifecycleState.resumed) return true;
    final done = Completer<bool>();
    final listener = AppLifecycleListener(
      onResume: () => done.isCompleted ? null : done.complete(true),
    );
    final timer = Timer(
      const Duration(seconds: 3),
      () => done.isCompleted ? null : done.complete(false),
    );
    try {
      return await done.future;
    } finally {
      timer.cancel();
      listener.dispose();
    }
  }

  /// Admin paths the console uses while locked (D-452): the overview probe, whether a PIN is set,
  /// and the checks that unlock it.
  static bool _openWhileLocked(String path, String method) =>
      (method == 'GET' && (path == '/v1/admin/overview' || path == '/v1/admin/pin')) ||
      (method == 'POST' && path.startsWith('/v1/admin/checks/'));

  static bool protectedPath(String path, {String method = 'GET'}) =>
      path.startsWith('/v1/admin/') && !_openWhileLocked(path, method.toUpperCase());
}

/// Only freshness rejections are replayed. A timeout or server error can have already
/// performed the action, so it must never trigger another mutation.
class AdminSecurityInterceptor extends Interceptor {
  AdminSecurityInterceptor(
    this.dio, {
    required this.token,
    required this.userId,
  });

  final Dio dio;
  final String? Function() token;
  final String? Function() userId;
  static const _retried = 'adminSecurityRetried';

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!AdminSecurity.protectedPath(
      options.uri.path,
      method: options.method,
    )) {
      handler.next(options);
      return;
    }
    final identity = userId();
    final authenticate = AdminSecurity.authenticate;
    final sensitive = !{
      'GET',
      'HEAD',
      'OPTIONS',
    }.contains(options.method.toUpperCase());
    if (identity == null ||
        AdminSecurity.isUnlocked?.call() != true ||
        (sensitive &&
            options.extra[_retried] != true &&
            !AdminSecurity.recentlyVerified(identity) &&
            (authenticate == null || !await authenticate(true))) ||
        identity != userId() ||
        AdminSecurity.isUnlocked?.call() != true) {
      handler.reject(
        DioException(requestOptions: options, type: DioExceptionType.cancel),
      );
      return;
    }
    final currentToken = token();
    if (currentToken == null) {
      handler.reject(
        DioException(requestOptions: options, type: DioExceptionType.cancel),
      );
      return;
    }
    options.headers['Authorization'] = 'Bearer $currentToken';
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    final body = err.response?.data;
    final code = body is Map ? body['code'] : null;
    // In the console, its own lock confirms. Elsewhere (an admin bot approval, a sign-in code)
    // a dialog over the current screen does; the server answers these before any side effect.
    final inConsole = AdminSecurity.protectedPath(
      options.uri.path,
      method: options.method,
    );
    final console = AdminSecurity.authenticate;
    final anywhere = AdminSecurity.confirmAnywhere;
    final Future<bool> Function(bool)? authenticate = inConsole
        ? console
        : anywhere == null
        ? null
        : (_) => anywhere();
    bool stillOpen() => !inConsole || AdminSecurity.isUnlocked?.call() == true;
    if (options.extra[_retried] == true ||
        err.response?.statusCode != 403 ||
        !{
          'admin_reauthentication_required',
          'admin_confirmation_required',
        }.contains(code) ||
        authenticate == null ||
        !stillOpen()) {
      handler.next(err);
      return;
    }
    final identity = userId();
    try {
      if (identity == null ||
          !await authenticate(code == 'admin_confirmation_required') ||
          identity != userId() ||
          !stillOpen()) {
        handler.next(err);
        return;
      }
      options.extra[_retried] = true;
      options.headers['Authorization'] = 'Bearer ${token()}';
      handler.resolve(await dio.fetch<dynamic>(options));
    } on DioException catch (e) {
      handler.next(e);
    } catch (_) {
      handler.next(err);
    }
  }
}
