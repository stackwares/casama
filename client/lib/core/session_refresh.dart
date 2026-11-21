import 'dart:async';

import 'package:dio/dio.dart';

/// On a 401 from the Casama API, refreshes the session once and sends the call again once.
///
/// The access token can be older than its hour after the app sat in the background, before
/// Supabase's own refresh timer runs again. [refresh] returns the new access token, or throws:
/// a network error leaves the session alone (the 401 reaches the caller), anything else means the
/// session is gone, so [signOut] runs and the app goes to sign-in. Concurrent 401s share one
/// refresh. Calls that sent no token, already retried, or stream their body aren't retried.
class SessionRefreshInterceptor extends Interceptor {
  SessionRefreshInterceptor(
    this._dio, {
    required this.refresh,
    required this.signOut,
    required this.isNetworkError,
  });

  final Dio _dio;
  final Future<String?> Function() refresh;
  final Future<void> Function() signOut;
  final bool Function(Object error) isNetworkError;

  static const _retried = 'casama_session_refreshed';
  Future<String?>? _inflight;

  static String? _token(RequestOptions o) =>
      (o.headers['Authorization'] ?? o.headers['authorization']) as String?;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    if (err.response?.statusCode != 401 ||
        options.extra[_retried] == true ||
        _token(options) == null ||
        options.data is Stream) {
      handler.next(err);
      return;
    }
    String? token;
    try {
      token = await (_inflight ??= refresh().whenComplete(
        () => _inflight = null,
      ));
    } catch (e) {
      if (!isNetworkError(e)) await _signOut();
      handler.next(err);
      return;
    }
    if (token == null) {
      await _signOut();
      handler.next(err);
      return;
    }
    try {
      options.extra[_retried] = true;
      options.headers.remove('authorization');
      options.headers['Authorization'] = 'Bearer $token';
      handler.resolve(await _dio.fetch<dynamic>(options));
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  Future<void> _signOut() async {
    try {
      await signOut();
    } catch (_) {}
  }
}
