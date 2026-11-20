import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

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
  static const grace = Duration(seconds: 45);

  static bool recentlyVerified(String? userId) =>
      userId != null &&
      userId == lastVerifiedBy &&
      lastVerified != null &&
      DateTime.now().difference(lastVerified!) < grace;

  static void verified(String? userId) {
    lastVerified = DateTime.now();
    lastVerifiedBy = userId;
  }

  static void forgetVerification() {
    lastVerified = null;
    lastVerifiedBy = null;
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

  static bool protectedPath(String path, {String method = 'GET'}) =>
      path.startsWith('/v1/admin/') &&
      (path != '/v1/admin/overview' || method.toUpperCase() != 'GET');
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
